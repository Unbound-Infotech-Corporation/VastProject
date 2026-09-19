#!/usr/bin/env bash
# Install a currently supported NVIDIA driver using Ubuntu's documented
# ubuntu-drivers path. Vast does not require a specific version
# (https://cloud.vast.ai/host/setup/ — latest compatible recommended).
# After install, enable persistence mode with nvidia-smi -pm 1.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

require_ubuntu
require_root_or_sudo

print_safety_banner

if is_command nvidia-smi && nvidia-smi >/dev/null 2>&1; then
  ok "nvidia-smi already works:"
  nvidia-smi
  log "Enabling persistence mode (nvidia-smi -pm 1)..."
  ${SUDO} nvidia-smi -pm 1 || warn "Could not enable persistence mode."
  exit 0
fi

if ! confirm "Install NVIDIA driver via ubuntu-drivers autoinstall (reboot will be required)?"; then
  die "Aborted. Install a supported driver manually, then re-run. See ${NVIDIA_DRIVER_DOCS}"
fi

${SUDO} apt-get update
${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y ubuntu-drivers-common

log "Detected recommended drivers:"
${SUDO} ubuntu-drivers devices || true

log "Running ubuntu-drivers autoinstall..."
${SUDO} ubuntu-drivers autoinstall

mapfile -t nvidia_pkgs < <(dpkg-query -W -f='${Package}\n' 'nvidia-*' 'libnvidia-*' 2>/dev/null || true)
if ((${#nvidia_pkgs[@]})); then
  ${SUDO} apt-mark hold "${nvidia_pkgs[@]}" || true
fi

warn "A reboot is required before nvidia-smi will work. After reboot, run:"
echo "  nvidia-smi -q"
echo "  sudo nvidia-smi -pm 1"
echo "Vast host setup: test with nvidia-smi -q before continuing."
