#!/usr/bin/env bash
# Shared helpers for Vast Host Setup scripts.
# Safe by default: no disk wipes, no silent destructive ops.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log()  { echo -e "${CYAN}[vast-host]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }
die()  { err "$*"; exit 1; }

is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

# Prefer sudo when not root. Prompts if needed (install/fix scripts).
sudo_cmd() {
  if is_root; then
    "$@"
  else
    sudo "$@"
  fi
}

# Never prompt — used by dashboard/status checks.
sudo_n() {
  if is_root; then
    "$@"
  else
    sudo -n "$@"
  fi
}

confirm() {
  local prompt="${1:-Continue?}"
  local reply
  if [[ "${ASSUME_YES:-}" == "1" ]]; then
    return 0
  fi
  read -r -p "$(echo -e "${YELLOW}${prompt} [y/N]${NC} ")" reply
  [[ "${reply}" =~ ^[Yy]([Ee][Ss])?$ ]]
}

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || die "These scripts are for Linux hosts only (got $(uname -s))."
}

ubuntu_version() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${VERSION_ID:-unknown}"
  else
    echo "unknown"
  fi
}

ubuntu_codename() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-unknown}}"
  else
    echo "unknown"
  fi
}

require_ubuntu_2204_or_2404() {
  require_linux
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS (missing /etc/os-release)."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || die "Ubuntu 22.04 or 24.04 is required (detected ${ID:-unknown})."
  case "${VERSION_ID:-}" in
    22.04|24.04) ;;
    20.04)
      warn "Ubuntu 20.04 works for some GPUs but Vast.ai recommends 22.04/24.04."
      confirm "Continue on Ubuntu 20.04 anyway?" || die "Aborted."
      ;;
    *)
      die "Unsupported Ubuntu ${VERSION_ID:-unknown}. Vast.ai recommends 22.04 or 24.04. See https://cloud.vast.ai/host/setup/"
      ;;
  esac
}

script_dir() {
  local src="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  cd "$(dirname "$src")" && pwd
}

repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "${here}/.." && pwd
}

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Print a check result as JSON object fields (no wrapping braces).
emit_check() {
  local key="$1"
  local verified="$2"
  local message="$3"
  printf '"%s":{"verified":%s,"message":"%s"}' \
    "$(json_escape "$key")" \
    "$verified" \
    "$(json_escape "$message")"
}

print_safety_banner() {
  cat <<'EOF'
┌──────────────────────────────────────────────────────────────────────────┐
│  SAFETY  These scripts never format or wipe a disk unless you pass       │
│          --confirm-wipe /dev/DISK and type the device path again.        │
│          Do not run this against a machine you cannot afford to break.   │
│          Official Vast.ai host docs: https://cloud.vast.ai/host/setup/   │
└──────────────────────────────────────────────────────────────────────────┘
EOF
}
