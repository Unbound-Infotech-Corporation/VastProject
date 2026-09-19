#!/usr/bin/env bash
# Prepare Ubuntu Server 22.04/24.04 for Vast hosting.
# Aligns with public Vast docs: keep the kernel patched, do not auto-update
# NVIDIA drivers mid-rental. Does not wipe disks. Does not disable SSH passwords
# until a working key is confirmed (see official disable-ssh-password-login).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

require_ubuntu
require_root_or_sudo

log "Updating package indexes..."
${SUDO} apt-get update

log "Installing host-maintenance packages (no NVIDIA/Docker yet)..."
${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg lsb-release software-properties-common \
  apt-transport-https build-essential pkg-config \
  python3 python3-venv \
  pciutils usbutils lshw dmidecode \
  smartmontools hdparm \
  htop iotop iftop \
  net-tools iproute2 iputils-ping dnsutils \
  openssh-server \
  ubuntu-drivers-common \
  jq

# Hold NVIDIA userspace packages so unattended upgrades cannot swap drivers
# during a rental. Kernel security updates stay available (required by
# https://docs.vast.ai/host/upgrade-kernel ).
log "Holding NVIDIA packages against unattended upgrades (driver swaps mid-rental drop jobs)..."
mapfile -t nvidia_pkgs < <(dpkg-query -W -f='${Package}\n' 'nvidia-*' 'libnvidia-*' 2>/dev/null || true)
if ((${#nvidia_pkgs[@]})); then
  ${SUDO} apt-mark hold "${nvidia_pkgs[@]}" || true
  ok "Held ${#nvidia_pkgs[@]} NVIDIA packages."
else
  log "No NVIDIA packages installed yet; hold will be re-applied after driver install."
fi

pref_file="/etc/apt/preferences.d/vast-hold-nvidia"
if [[ ! -f "${pref_file}" ]]; then
  ${SUDO} tee "${pref_file}" >/dev/null <<'EOF'
# Prevent unattended NVIDIA driver swaps. Kernel security updates are still allowed.
# Vast: disable auto driver updates so rentals are not interrupted
# (https://docs.vast.ai/host/hosting-overview).
Package: nvidia-* libnvidia-*
Pin: release *
Pin-Priority: 50
EOF
  ok "Wrote ${pref_file}"
fi

if ${SUDO} sshd -T 2>/dev/null | grep -qi '^passwordauthentication yes'; then
  warn "SSH password login is still enabled."
  warn "Do NOT disable it from this script. Confirm a working key first, then follow:"
  warn "  ${HOST_DOCS_SSH}"
fi

ok "Ubuntu prep complete. Review ${HOST_DOCS_KERNEL} before kernel upgrades (reboot stops rentals)."
