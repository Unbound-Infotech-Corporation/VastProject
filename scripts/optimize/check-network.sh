#!/usr/bin/env bash
# Check host networking / Vast.ai port-range hints. Read-only.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

verified="false"
messages=()
port_file="/var/lib/vastai_kaalia/host_port_range"
ip_file="/var/lib/vastai_kaalia/host_ipaddr"

forward="$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo unknown)"
if [[ "$forward" == "1" ]]; then
  messages+=("net.ipv4.ip_forward=1.")
else
  messages+=("net.ipv4.ip_forward=${forward} (Docker/NAT often needs 1).")
fi

if [[ -f "$port_file" ]]; then
  range="$(tr -d '\n' < "$port_file")"
  messages+=("Vast host port range: ${range}. Forward TCP+UDP on the router to this machine. Vast recommends a continuous range (3 ports/GPU min, 100/GPU preferred).")
  verified="true"
else
  messages+=("No ${port_file} yet (set during Vast installer). Open a continuous TCP+UDP range — at least 3 ports per GPU, 100 recommended.")
fi

if [[ -f "$ip_file" ]]; then
  messages+=("Host public IP override: $(tr -d '\n' < "$ip_file").")
fi

if have_cmd ufw && { ufw status 2>/dev/null || sudo_n ufw status 2>/dev/null; } | grep -qi "Status: active"; then
  messages+=("UFW is active — ensure SSH and the Vast port range are allowed (TCP and UDP).")
else
  messages+=("UFW is inactive or missing. Router/firewall still must forward the instance port range.")
fi

# Consider network "verified" only when a port range is recorded; otherwise warn.
if [[ ! -f "$port_file" ]]; then
  verified="false"
fi

message="$(IFS=' '; echo "${messages[*]}")"
if [[ "${1:-}" == "--json" ]]; then
  printf '{%s}\n' "$(emit_check network "$verified" "$message")"
else
  if [[ "$verified" == "true" ]]; then ok "Network: $message"; else warn "Network: $message"; fi
fi
