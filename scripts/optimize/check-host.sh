#!/usr/bin/env bash
# Check OS + Vast.ai host daemon. Read-only.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

os_verified="false"
vast_verified="false"
os_messages=()
vast_messages=()

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  os_messages+=("${PRETTY_NAME:-${ID:-unknown} ${VERSION_ID:-}}")
  if [[ "${ID:-}" == "ubuntu" && ( "${VERSION_ID:-}" == "22.04" || "${VERSION_ID:-}" == "24.04" ) ]]; then
    os_verified="true"
  elif [[ "${ID:-}" == "ubuntu" ]]; then
    os_messages+=("Vast.ai recommends Ubuntu 22.04 or 24.04.")
  else
    os_messages+=("Not Ubuntu. Official host path is Ubuntu Server 22.04/24.04.")
  fi
else
  os_messages+=("Cannot detect OS.")
fi

if have_cmd systemctl && systemctl list-unit-files --type=service --no-legend 2>/dev/null | grep -q '^vastai.service'; then
  state="$(systemctl is-active vastai 2>/dev/null || echo inactive)"
  vast_messages+=("vastai.service is ${state}.")
  if [[ "$state" == "active" ]]; then
    vast_verified="true"
  fi
else
  vast_messages+=("vastai.service is not installed. Copy the installer from https://cloud.vast.ai/host/setup/")
fi

if [[ -f /var/lib/vastai_kaalia/api_key ]]; then
  vast_messages+=("api_key is present.")
else
  vast_messages+=("Missing /var/lib/vastai_kaalia/api_key — the machine will not appear on the Vast dashboard.")
  vast_verified="false"
fi

if [[ -f /var/lib/vastai_kaalia/machine_id ]]; then
  vast_messages+=("machine_id is present.")
fi

os_message="$(IFS=' '; echo "${os_messages[*]}")"
vast_message="$(IFS=' '; echo "${vast_messages[*]}")"

if [[ "${1:-}" == "--json" ]]; then
  printf '{%s,%s}\n' \
    "$(emit_check os "$os_verified" "$os_message")" \
    "$(emit_check vast "$vast_verified" "$vast_message")"
else
  if [[ "$os_verified" == "true" ]]; then ok "OS: $os_message"; else warn "OS: $os_message"; fi
  if [[ "$vast_verified" == "true" ]]; then ok "Vast: $vast_message"; else warn "Vast: $vast_message"; fi
fi
