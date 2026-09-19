#!/usr/bin/env bash
# Prepare Ubuntu 22.04/24.04 as a Vast.ai GPU host.
#
# Installs (official documented paths only):
#   - base packages
#   - NVIDIA drivers via ubuntu-drivers --gpgpu  (Ubuntu Server docs)
#   - Docker Engine via Docker's apt repository   (docs.docker.com)
#   - NVIDIA Container Toolkit via NVIDIA apt repo + nvidia-ctk
#     runtime configure --runtime=docker          (NVIDIA docs)
#
# Does NOT install the Vast.ai host daemon (that requires a one-hour
# authorization key from https://cloud.vast.ai/host/setup/).
# Does NOT format disks.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SKIP_DRIVERS=0
SKIP_DOCKER=0
SKIP_TOOLKIT=0
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $0 [options]

Prepare this Ubuntu 22.04/24.04 machine for Vast.ai hosting.

Options:
  --skip-drivers    Skip NVIDIA driver install
  --skip-docker     Skip Docker Engine install
  --skip-toolkit    Skip NVIDIA Container Toolkit
  --dry-run         Print planned steps only
  -y, --yes         Do not prompt (non-destructive steps only)
  -h, --help        Show this help

Official references:
  Vast host setup:     https://cloud.vast.ai/host/setup/
  Vast hosting overview: https://docs.vast.ai/host/hosting-overview
  Ubuntu NVIDIA:       https://ubuntu.com/server/docs/how-to/graphics/install-nvidia-drivers/
  Docker Engine:       https://docs.docker.com/engine/install/ubuntu/
  NVIDIA toolkit:      https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-drivers) SKIP_DRIVERS=1; shift ;;
    --skip-docker)  SKIP_DOCKER=1; shift ;;
    --skip-toolkit) SKIP_TOOLKIT=1; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -y|--yes)       ASSUME_YES=1; export ASSUME_YES; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "Unknown option: $1" ;;
  esac
done

print_safety_banner
require_ubuntu_2204_or_2404

log "Detected $(. /etc/os-release && echo "${PRETTY_NAME}") ($(uname -m))"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  dry-run: $*"
  else
    "$@"
  fi
}

if [[ "$DRY_RUN" != "1" ]]; then
  confirm "Install host prerequisites on this machine?" || die "Aborted."
fi

log "Installing base packages..."
run sudo_cmd apt-get update
run sudo_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl gnupg2 lsb-release software-properties-common \
  apt-transport-https xfsprogs parted pciutils jq python3 \
  ubuntu-drivers-common
if [[ "$DRY_RUN" == "1" ]]; then
  echo "  dry-run: apt-get install linux-headers-$(uname -r) (best-effort)"
else
  sudo_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y "linux-headers-$(uname -r)" \
    || warn "linux-headers-$(uname -r) not available; install matching headers before building NVIDIA DKMS modules."
fi

# Vast hosting overview: disable auto-updates so a driver update does not
# interrupt an active rental. We only mask unattended-upgrades after asking.
if systemctl list-unit-files unattended-upgrades.service >/dev/null 2>&1; then
  if [[ "$DRY_RUN" == "1" ]] || confirm "Disable unattended-upgrades? (Vast recommends this so rentals are not interrupted)"; then
    run sudo_cmd systemctl disable --now unattended-upgrades || true
    ok "unattended-upgrades disabled."
  fi
fi

if [[ "$SKIP_DRIVERS" -eq 0 ]]; then
  log "Installing NVIDIA drivers via ubuntu-drivers (official Ubuntu Server method)..."
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  dry-run: sudo ubuntu-drivers list --gpgpu"
    echo "  dry-run: sudo ubuntu-drivers install --gpgpu"
  else
    sudo_cmd ubuntu-drivers list --gpgpu || warn "ubuntu-drivers list --gpgpu returned non-zero (continuing)."
    if confirm "Install the recommended GPGPU/server NVIDIA driver now? (reboot will be required)"; then
      sudo_cmd ubuntu-drivers install --gpgpu
      ok "Driver packages installed. Reboot before relying on nvidia-smi."
    else
      warn "Skipped driver install. Vast.ai: install and test drivers with nvidia-smi -q before the host installer."
    fi
  fi
else
  warn "Skipping NVIDIA drivers (--skip-drivers)."
fi

if [[ "$SKIP_DOCKER" -eq 0 ]]; then
  log "Installing Docker Engine from Docker's official apt repository..."
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  dry-run: add download.docker.com apt source and install docker-ce"
  else
    # Official uninstall of conflicting distro packages (docs.docker.com).
    sudo_cmd apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc 2>/dev/null || true

    sudo_cmd install -m 0755 -d /etc/apt/keyrings
    sudo_cmd curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo_cmd chmod a+r /etc/apt/keyrings/docker.asc

    codename="$(ubuntu_codename)"
    arch="$(dpkg --print-architecture)"
    sudo_cmd tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${codename}
Components: stable
Architectures: ${arch}
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    sudo_cmd apt-get update
    sudo_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo_cmd systemctl enable --now docker
    if [[ -n "${SUDO_USER:-}" ]]; then
      sudo_cmd usermod -aG docker "$SUDO_USER" || true
    elif [[ "${USER:-root}" != "root" ]]; then
      sudo_cmd usermod -aG docker "$USER" || true
    fi
    ok "Docker Engine installed."
  fi
else
  warn "Skipping Docker (--skip-docker)."
fi

if [[ "$SKIP_TOOLKIT" -eq 0 ]]; then
  log "Installing NVIDIA Container Toolkit (official NVIDIA apt repo)..."
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  dry-run: add nvidia-container-toolkit repo and nvidia-ctk runtime configure --runtime=docker"
  else
    sudo_cmd apt-get update
    sudo_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg2
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
      sudo_cmd gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo_cmd tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
    sudo_cmd apt-get update
    sudo_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-container-toolkit
    if have_cmd nvidia-ctk; then
      sudo_cmd nvidia-ctk runtime configure --runtime=docker
      sudo_cmd systemctl restart docker
      ok "nvidia-ctk configured Docker runtime."
    else
      warn "nvidia-ctk missing after package install."
    fi
  fi
else
  warn "Skipping NVIDIA Container Toolkit (--skip-toolkit)."
fi

echo
ok "Bootstrap finished."
echo
cat <<'EOF'
Next steps
----------
1. Reboot if NVIDIA drivers were just installed, then verify:
     nvidia-smi -q
2. Confirm Docker storage is XFS + pquota (see docs/HOST_INSTALL.md).
   This script does not format disks.
3. Install the Vast.ai host daemon with a key from the official console:
     https://cloud.vast.ai/host/setup/
     sudo ./scripts/install-vast-daemon.sh --auth-key YOUR_KEY
4. Run optimizer checks:
     ./scripts/optimize/collect-status.sh
5. Optionally install the dashboard:
     ./scripts/install-dashboard.sh

The Vast installer also installs Docker and nvidia-ctk if they are missing.
Pre-installing them here is optional and uses the same public documented commands.
EOF
