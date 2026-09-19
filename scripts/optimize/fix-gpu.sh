#!/usr/bin/env bash
# Safe GPU tweaks: enable NVIDIA persistence mode.
# Never uninstalls or reinstalls drivers.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

if ! have_cmd nvidia-smi; then
  die "nvidia-smi not found. Install drivers with scripts/bootstrap-host.sh before optimizing GPU."
fi

log "Enabling NVIDIA persistence mode (nvidia-smi -pm 1)..."
if sudo_cmd nvidia-smi -pm 1; then
  ok "Persistence mode requested."
else
  die "nvidia-smi -pm 1 failed."
fi

if have_cmd nvidia-persistenced || [[ -x /usr/bin/nvidia-persistenced ]]; then
  if systemctl list-unit-files nvidia-persistenced.service >/dev/null 2>&1; then
    sudo_cmd systemctl enable --now nvidia-persistenced >/dev/null 2>&1 || \
      warn "Could not enable nvidia-persistenced.service (optional)."
  fi
fi

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-gpu.sh" "${1:-}"
