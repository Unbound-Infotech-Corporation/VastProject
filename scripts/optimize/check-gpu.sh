#!/usr/bin/env bash
# Check NVIDIA driver / persistence mode. Read-only.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

verified="false"
messages=()

if ! have_cmd nvidia-smi; then
  messages+=("nvidia-smi not found. Install NVIDIA drivers first (ubuntu-drivers install --gpgpu).")
else
  if smi_out="$(nvidia-smi --query-gpu=name,driver_version,persistence_mode --format=csv,noheader 2>/dev/null)"; then
    gpu_count="$(printf '%s\n' "$smi_out" | sed '/^$/d' | wc -l | tr -d ' ')"
    driver="$(printf '%s\n' "$smi_out" | head -n1 | awk -F',' '{print $2}' | xargs)"
    persistence="$(printf '%s\n' "$smi_out" | awk -F',' '{print $3}' | xargs | sort -u | tr '\n' ',' | sed 's/,$//')"
    names="$(printf '%s\n' "$smi_out" | awk -F',' '{print $1}' | xargs | tr '\n' ',' | sed 's/,$//')"
    messages+=("${gpu_count} GPU(s): ${names}. Driver ${driver}. Persistence: ${persistence}.")
    if printf '%s\n' "$smi_out" | grep -qi "Enabled"; then
      if ! printf '%s\n' "$smi_out" | grep -qi "Disabled"; then
        verified="true"
      else
        messages+=("Some GPUs still have persistence mode disabled.")
      fi
    else
      messages+=("Persistence mode is disabled. Enable with: sudo nvidia-smi -pm 1")
    fi
  else
    messages+=("nvidia-smi failed. Drivers may be installed but the kernel module is not loaded (reboot often required).")
  fi
fi

message="$(IFS=' '; echo "${messages[*]}")"
if [[ "${1:-}" == "--json" ]]; then
  printf '{%s}\n' "$(emit_check gpu "$verified" "$message")"
else
  if [[ "$verified" == "true" ]]; then ok "GPU: $message"; else warn "GPU: $message"; fi
fi
