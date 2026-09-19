#!/usr/bin/env bash
# Open the host port range already configured by the Vast installer.
# Does not invent Vast port-range flags. Reads /var/lib/vastai_kaalia/host_port_range
# if present. Verification docs: 5 ports/GPU minimum, 100 recommended
# (https://docs.vast.ai/host/verification-stages). Self-test still needs at
# least 3 direct open ports even with --ignore-requirements.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

require_ubuntu
require_root_or_sudo

range_file="/var/lib/vastai_kaalia/host_port_range"
range="${VAST_PORT_RANGE:-}"

if [[ -z "${range}" && -f "${range_file}" ]]; then
  range="$(tr -d '[:space:]' < "${range_file}")"
  log "Read port range from ${range_file}: ${range}"
fi

if [[ -z "${range}" ]]; then
  cat <<EOF
${YELLOW}No port range configured.${NC}

The Vast installer prompts for a continuous TCP+UDP range.
Verification: 5 ports per GPU minimum, 100 per GPU recommended.
  ${HOST_DOCS_VERIFY}

After the installer writes the range you can inspect:
  ${range_file}

Forward that same range (TCP and UDP) on the router to this machine's
private IPv4. The host needs a public IPv4 — CGNAT will not verify.

Re-run this script after the installer, or set VAST_PORT_RANGE=START-END
EOF
  exit 0
fi

if [[ ! "${range}" =~ ^[0-9]+-[0-9]+$ ]]; then
  die "Port range '${range}' is not START-END. Refusing to open arbitrary firewall rules."
fi

start="${range%-*}"
end="${range#*-}"
if (( start < 1024 || end > 65535 || start >= end )); then
  die "Refusing range ${range}. Use a high, continuous range (for example 40000-40099)."
fi

span=$((end - start + 1))
log "Opening UFW for SSH and ${range} TCP+UDP (${span} ports)."

${SUDO} ufw allow OpenSSH || ${SUDO} ufw allow 22/tcp
${SUDO} ufw allow "${start}:${end}/tcp"
${SUDO} ufw allow "${start}:${end}/udp"

if confirm "Enable UFW now? Existing sessions stay up if SSH is already allowed."; then
  ${SUDO} ufw --force enable
fi

${SUDO} ufw status verbose || true
ok "Host firewall updated. Confirm the same range is forwarded on the WAN router."
echo "Public IPv4 is required. See ${HOST_DOCS_VERIFY}"
