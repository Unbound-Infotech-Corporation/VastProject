#!/usr/bin/env bash
# Install the Vast.ai host daemon using the command from YOUR host dashboard.
#
# Official source: https://cloud.vast.ai/host/setup/
# The installer URL and authorization key are account-specific and expire.
# This script does not invent installer flags. It either:
#   1. Runs the exact command you paste (VAST_INSTALL_CMD), or
#   2. Downloads https://console.vast.ai/install (the public installer URL
#      documented by community host guides that cite the dashboard) and
#      runs: python3 install <KEY>
#      with no extra flags unless you pass them yourself in VAST_INSTALL_ARGS.
#
# Never formats disks.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

require_ubuntu
require_root_or_sudo

print_safety_banner

cat <<EOF
${BOLD}Vast host daemon${NC}

1. Create a *host* account (not your renter/client account).
   ${HOST_DOCS_OVERVIEW}
2. Open ${HOST_DOCS_SETUP} and accept the hosting agreement.
3. Copy the install command shown there. It contains a short-lived key.

This script will not guess flags such as --interactive. If the dashboard
command includes flags, paste the whole command.

EOF

if [[ -n "${VAST_INSTALL_CMD:-}" ]]; then
  log "Using VAST_INSTALL_CMD from the environment."
  if ! confirm "Run the pasted Vast installer command now?"; then
    die "Aborted."
  fi
  # Intentionally eval only the operator-supplied dashboard command.
  # shellcheck disable=SC2086
  bash -lc "${VAST_INSTALL_CMD}"
  ok "Installer command finished. Check https://cloud.vast.ai/host/machines/"
  exit 0
fi

if [[ -z "${VAST_HOST_KEY:-}" ]]; then
  read -r -p "Paste the host authorization key from ${HOST_DOCS_SETUP} (or leave empty to abort): " VAST_HOST_KEY
fi

if [[ -z "${VAST_HOST_KEY:-}" ]]; then
  die "No key provided. Copy the command from ${HOST_DOCS_SETUP} and re-run with VAST_INSTALL_CMD='...' or VAST_HOST_KEY=..."
fi

if [[ "${VAST_HOST_KEY}" == *[[:space:]]* ]]; then
  die "Key looks like a full command. Export VAST_INSTALL_CMD instead of VAST_HOST_KEY."
fi

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT
cd "${workdir}"

log "Downloading public installer from https://console.vast.ai/install"
curl -fsSL https://console.vast.ai/install -o install
if [[ ! -s install ]]; then
  die "Failed to download installer. Paste the exact dashboard command via VAST_INSTALL_CMD."
fi

log "Running: sudo python3 install <key> ${VAST_INSTALL_ARGS:-}"
# VAST_INSTALL_ARGS is optional and empty by default — no invented flags.
# shellcheck disable=SC2086
${SUDO} python3 install "${VAST_HOST_KEY}" ${VAST_INSTALL_ARGS:-}

ok "Installer finished."
if [[ -f /var/lib/vastai_kaalia/machine_id ]]; then
  ok "machine_id present."
else
  warn "machine_id not found under /var/lib/vastai_kaalia — re-copy a fresh command from the dashboard."
fi
if [[ -f /var/lib/vastai_kaalia/api_key ]]; then
  ok "api_key present (do not print it)."
else
  warn "api_key missing — the machine will not appear on the host dashboard until the installer writes it."
fi

echo "List the machine from the Vast host UI or CLI after networking is forwarded."
echo "Self-test: ${HOST_DOCS_SELFTEST}"
