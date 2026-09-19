#!/usr/bin/env bash
# Install the Vast.ai host manager using ONLY the publicly documented command.
#
# Official source: https://cloud.vast.ai/host/setup/
# Documented shape (also recorded by host-community writeups of that page):
#   wget https://console.vast.ai/install -O install
#   sudo python3 install YOUR_AUTH_KEY --interactive
#   history -d $((HISTCMD-1))
#
# Documented extra flag: --reset-machine
# We do not invent other flags. Prefer copying the exact command from the
# Vast console (the authorization key expires in about one hour).

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

AUTH_KEY=""
RESET_MACHINE=0
INTERACTIVE=1
INSTALL_URL="https://console.vast.ai/install"

usage() {
  cat <<EOF
Usage: $0 [--auth-key KEY] [--reset-machine] [--non-interactive]

Downloads the official Vast.ai host installer and runs it with your
authorization key. Get a fresh key from:

  https://cloud.vast.ai/host/setup/

The key is valid for about one hour. Host and client accounts must be separate.

Options:
  --auth-key KEY       Authorization key from the Vast host setup page
  --reset-machine      Pass the documented --reset-machine flag
  --non-interactive    Omit --interactive (only if you know you want that)
  --url URL            Override installer URL (default: ${INSTALL_URL})
  -h, --help           Show this help

If you would rather run Vast's copied command yourself, do that instead.
This wrapper only exists so you do not have to retype the documented lines.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auth-key)
      AUTH_KEY="${2:-}"
      shift 2
      ;;
    --reset-machine)
      RESET_MACHINE=1
      shift
      ;;
    --non-interactive)
      INTERACTIVE=0
      shift
      ;;
    --url)
      INSTALL_URL="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

print_safety_banner

if [[ -z "$AUTH_KEY" ]]; then
  echo
  log "Create/use a dedicated HOST account (not your renter account)."
  log "Open https://cloud.vast.ai/host/setup/ , accept the hosting agreement,"
  log "and copy a fresh authorization key (expires ~1 hour)."
  echo
  read -r -p "Paste the authorization key only (not the whole wget line): " AUTH_KEY
fi

# Keys from the console are opaque tokens; reject shell metacharacters.
if [[ ! "$AUTH_KEY" =~ ^[A-Za-z0-9._~+/-]+=*$ ]]; then
  die "Auth key contains characters we will not pass to the installer. Copy the key only, or run the console command yourself."
fi

if [[ ! "$INSTALL_URL" =~ ^https://([a-z0-9.-]+\.)?vast\.ai/ ]]; then
  die "Refusing installer URL '${INSTALL_URL}'. Expected an https://…vast.ai/… URL."
fi

confirm "Download ${INSTALL_URL} and run the official installer with this key?" || die "Aborted."

workdir="$(mktemp -d /tmp/vast-host-install.XXXXXX)"
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

log "Downloading official installer..."
if have_cmd wget; then
  wget -q "${INSTALL_URL}" -O "${workdir}/install"
elif have_cmd curl; then
  curl -fsSL "${INSTALL_URL}" -o "${workdir}/install"
else
  die "Need wget or curl to download ${INSTALL_URL}."
fi
[[ -s "${workdir}/install" ]] || die "Downloaded installer is empty."

args=("$AUTH_KEY")
if [[ "$INTERACTIVE" -eq 1 ]]; then
  args+=(--interactive)
fi
if [[ "$RESET_MACHINE" -eq 1 ]]; then
  args+=(--reset-machine)
fi

log "Running: sudo python3 install <key> ${args[*]:1}"
sudo_cmd python3 "${workdir}/install" "${args[@]}"

# Drop the key from this shell's history if we can.
if have_cmd history; then
  history -d $((HISTCMD-1)) 2>/dev/null || true
fi

echo
ok "Installer finished. The machine should appear on https://cloud.vast.ai/ within minutes."
echo "Check:  sudo systemctl status vastai"
echo "Logs:   sudo tail -f /var/lib/vastai_kaalia/kaalia.log"
echo "Key:    sudo test -f /var/lib/vastai_kaalia/api_key && echo present"
echo
warn "If you see connections to :0 in kaalia.log, the api_key is missing — copy a fresh command from the setup page."
