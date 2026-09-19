#!/usr/bin/env bash
# Non-destructive preflight for Ubuntu 22.04/24.04 Vast hosts.
# Never formats disks. Never SSHes anywhere.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

print_safety_banner
require_ubuntu

log "Architecture: $(uname -m)"
log "Kernel: $(uname -r)"
log "Hostname: $(hostname)"

if [[ -d /sys/firmware/efi ]]; then
  ok "UEFI firmware detected."
else
  warn "Legacy BIOS detected. Vast host setup documents an EFI partition of at least 256 MB when using UEFI."
fi

if mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
  warn "Secure Boot appears enabled. Vast verification docs require Secure Boot disabled. See ${HOST_DOCS_VERIFY}"
else
  ok "Secure Boot does not report as enabled (or mokutil unavailable)."
fi

if [[ -e /dev/nvidia0 ]] || is_command nvidia-smi; then
  ok "NVIDIA device or nvidia-smi present."
else
  warn "No NVIDIA device node or nvidia-smi yet. Install a currently supported driver for the GPU before listing."
fi

root_avail_kb="$(df -Pk / | awk 'NR==2 {print $4}')"
root_avail_gb=$((root_avail_kb / 1024 / 1024))
if (( root_avail_gb < 20 )); then
  warn "Root has ${root_avail_gb} GiB free. Vast verification requires at least 20 GB free on /."
else
  ok "Root has ${root_avail_gb} GiB free."
fi

if mount | grep -q ' /var/lib/docker '; then
  docker_fs="$(findmnt -n -o FSTYPE /var/lib/docker 2>/dev/null || true)"
  docker_opts="$(findmnt -n -o OPTIONS /var/lib/docker 2>/dev/null || true)"
  log "Docker data mount: fstype=${docker_fs:-unknown} opts=${docker_opts:-unknown}"
  if [[ "${docker_fs}" == "xfs" ]]; then
    ok "Docker data is on XFS (Vast host setup recommends XFS for Docker)."
  else
    warn "Docker data is not on XFS. Official host setup uses a separate XFS volume for Docker."
  fi
else
  warn "/var/lib/docker is not a dedicated mount. Vast verification requires a dedicated SSD for Docker (200 GB+)."
fi

if is_command sshd; then
  pw="$(sudo sshd -T 2>/dev/null | awk '/^passwordauthentication / {print $2}' || true)"
  if [[ "${pw}" == "no" ]]; then
    ok "sshd PasswordAuthentication is no."
  else
    warn "sshd PasswordAuthentication is '${pw:-unknown}'. Verification fails if password login is enabled. See ${HOST_DOCS_SSH}"
  fi
fi

cat <<EOF

Preflight summary
-----------------
OS check passed for Ubuntu 22.04/24.04.
Next: run 10-ubuntu-prep.sh, then NVIDIA, Docker, Vast daemon.
Official sources:
  ${HOST_DOCS_SETUP}
  ${HOST_DOCS_VERIFY}
  ${HOST_DOCS_OVERVIEW}

EOF
