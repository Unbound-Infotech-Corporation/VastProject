#!/usr/bin/env bash
# Conservative network tweaks for a Vast.ai host.
# Does not open the host to the internet blindly; only applies well-known sysctls
# and optional UFW allows when VAST_PORT_RANGE is set (e.g. 50000:50100).

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

sysctl_file="/etc/sysctl.d/99-vast-host.conf"
log "Writing conservative sysctl defaults to ${sysctl_file}"

sudo_cmd tee "$sysctl_file" >/dev/null <<'EOF'
# Vast Host Setup — conservative defaults. Review before enabling in production.
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.core.somaxconn = 1024
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 1024 65000
EOF

sudo_cmd sysctl --system >/dev/null

port_file="/var/lib/vastai_kaalia/host_port_range"
range="${VAST_PORT_RANGE:-}"
if [[ -z "$range" && -f "$port_file" ]]; then
  range="$(tr -d '\n' < "$port_file")"
fi

if [[ -n "$range" ]]; then
  # Accept 50000-50100 or 50000:50100
  ufw_range="${range//-/:}"
  if have_cmd ufw; then
    log "Allowing SSH and Vast port range ${ufw_range} in UFW (TCP+UDP)."
    sudo_cmd ufw allow 22/tcp || true
    sudo_cmd ufw allow "${ufw_range}/tcp" || true
    sudo_cmd ufw allow "${ufw_range}/udp" || true
    warn "UFW rules added but ufw was not enabled automatically. Run 'sudo ufw enable' yourself after reviewing."
  fi
else
  warn "No VAST_PORT_RANGE and no ${port_file}. Skip firewall opens. Set the range in the Vast installer, then re-run."
fi

ok "Network sysctl applied. Router must still forward the instance port range (TCP+UDP) to this host."
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-network.sh" "${1:-}"
