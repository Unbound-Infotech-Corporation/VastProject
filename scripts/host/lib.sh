#!/usr/bin/env bash
# Shared helpers for Vast host bootstrap scripts.
# These scripts never wipe disks unless prepare-docker-xfs.sh is run
# with explicit destructive flags.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

HOST_DOCS_SETUP="https://cloud.vast.ai/host/setup/"
HOST_DOCS_OVERVIEW="https://docs.vast.ai/host/hosting-overview"
HOST_DOCS_VERIFY="https://docs.vast.ai/host/verification-stages"
HOST_DOCS_SSH="https://docs.vast.ai/host/disable-ssh-password-login"
HOST_DOCS_KERNEL="https://docs.vast.ai/host/upgrade-kernel"
HOST_DOCS_SELFTEST="https://docs.vast.ai/host/how-to-self-test"
DOCKER_DOCS="https://docs.docker.com/engine/install/ubuntu/"
NVIDIA_CTK_DOCS="https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
NVIDIA_DRIVER_DOCS="https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/"

log() { printf '%b\n' "${CYAN}[vast-host]${NC} $*"; }
ok() { printf '%b\n' "${GREEN}[ok]${NC} $*"; }
warn() { printf '%b\n' "${YELLOW}[warn]${NC} $*"; }
err() { printf '%b\n' "${RED}[error]${NC} $*" >&2; }
die() { err "$*"; exit 1; }

require_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS. /etc/os-release missing."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    die "This bootstrap supports Ubuntu Server only (found ID=${ID:-unknown})."
  fi
  case "${VERSION_ID:-}" in
    22.04|24.04) ok "Ubuntu ${VERSION_ID} (${VERSION_CODENAME:-}) is a Vast-supported host OS." ;;
    *)
      die "Ubuntu ${VERSION_ID:-unknown} is not in Vast's documented host list (22.04 LTS / 24.04 LTS). See ${HOST_DOCS_VERIFY}"
      ;;
  esac
  if [[ "${VARIANT_ID:-}" == "desktop" ]] || dpkg -l ubuntu-desktop 2>/dev/null | grep -q '^ii'; then
    warn "Desktop packages detected. Vast verification docs require Ubuntu Server, not Desktop."
  fi
}

require_root_or_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    SUDO=""
    return
  fi
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    SUDO="sudo"
    return
  fi
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
    return
  fi
  die "This step needs root or sudo."
}

confirm() {
  local prompt="${1:-Continue?}"
  local answer
  if [[ "${VAST_ASSUME_YES:-}" == "1" ]]; then
    log "VAST_ASSUME_YES=1 — ${prompt} (auto-yes)"
    return 0
  fi
  read -r -p "$(printf '%b' "${YELLOW}${prompt} [y/N] ${NC}")" answer
  [[ "${answer}" == "y" || "${answer}" == "Y" ]]
}

print_safety_banner() {
  cat <<EOF
${RED}${BOLD}
╔══════════════════════════════════════════════════════════════════════╗
║  SAFETY — READ THIS BEFORE TOUCHING DISKS OR RUNNING INSTALLERS      ║
╠══════════════════════════════════════════════════════════════════════╣
║  • These scripts do NOT wipe, format, or repartition disks by        ║
║    default. Disk wipe lives ONLY in prepare-docker-xfs.sh and        ║
║    requires --i-understand-this-wipes-disks plus the exact device.   ║
║  • Do NOT run this against a rented SuperMicro, a production OS      ║
║    disk, or any device you have not identified with lsblk/blkid.     ║
║  • Vast host installer command is unique to YOUR host account.       ║
║    Copy it from ${HOST_DOCS_SETUP}                                   ║
║    Do not invent installer flags.                                    ║
║  • Host account must be separate from any Vast client/renter account.║
║  • This environment will not SSH or wipe physical machines.          ║
╚══════════════════════════════════════════════════════════════════════╝
${NC}
EOF
}

ubuntu_codename() {
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
}

is_command() {
  command -v "$1" >/dev/null 2>&1
}
