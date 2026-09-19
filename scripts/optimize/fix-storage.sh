#!/usr/bin/env bash
# Storage optimizer.
# Safe default: remount noatime / suggest fstab pquota on an EXISTING XFS docker volume.
# Destructive format is opt-in only:
#   --confirm-wipe /dev/DISK   (must match a second typed confirmation)
# Never wipes the root/OS disk.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

target="${DOCKER_ROOT:-/var/lib/docker}"
wipe_dev=""

usage() {
  cat <<EOF
Usage: $0 [--confirm-wipe /dev/DISK]

Safe actions (default):
  - If ${target} is already XFS, add pquota + noatime to the matching fstab line
    and remount (no format).
  - Print next steps if Docker is still on ext4 / the root filesystem.

Destructive (explicit only):
  --confirm-wipe /dev/DISK
      Formats THAT disk as XFS and mounts it on ${target}.
      THIS DESTROYS ALL DATA ON THE DEVICE.
      Refuses if the device backs / or /boot or /home.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --confirm-wipe)
      wipe_dev="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --json)
      shift
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

root_source="$(findmnt -n -o SOURCE --target / 2>/dev/null || true)"
boot_source="$(findmnt -n -o SOURCE --target /boot 2>/dev/null || true)"

device_is_os() {
  local dev="$1"
  [[ -n "$root_source" && "$root_source" == *"${dev##*/}"* ]] && return 0
  [[ -n "$boot_source" && "$boot_source" == *"${dev##*/}"* ]] && return 0
  # Also refuse whole-disk if a partition of it is mounted on /
  if lsblk -n -o NAME,MOUNTPOINT "$dev" 2>/dev/null | grep -qE '[[:space:]](/|/boot|/home)$'; then
    return 0
  fi
  return 1
}

if [[ -n "$wipe_dev" ]]; then
  [[ -b "$wipe_dev" ]] || die "${wipe_dev} is not a block device."
  if device_is_os "$wipe_dev"; then
    die "Refusing to wipe ${wipe_dev}: it appears to hold / , /boot, or /home."
  fi
  echo
  err "DESTRUCTIVE: This will DESTROY ALL DATA on ${wipe_dev} and format it as XFS."
  warn "Current block devices:"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
  echo
  if [[ "${ASSUME_YES:-}" == "1" ]]; then
    die "Refusing --confirm-wipe with ASSUME_YES=1. Type the device path interactively."
  fi
  local_confirm=""
  read -r -p "Type the device path exactly to continue (${wipe_dev}): " local_confirm
  [[ "$local_confirm" == "$wipe_dev" ]] || die "Confirmation did not match. Aborted."
  confirm "Last chance: format ${wipe_dev} as XFS and mount at ${target}?" || die "Aborted."

  if systemctl is-active --quiet docker; then
    log "Stopping Docker before moving ${target}..."
    sudo_cmd systemctl stop docker docker.socket || sudo_cmd systemctl stop docker || true
  fi

  if findmnt "$target" >/dev/null 2>&1; then
    sudo_cmd umount "$target" || die "Could not unmount ${target}."
  fi

  part="${wipe_dev}"
  # If a whole disk was given and has no partition table, create one GPT partition.
  if [[ "$wipe_dev" =~ ^/dev/(sd[a-z]|nvme[0-9]+n[0-9]+|vd[a-z])$ ]]; then
    log "Creating a single GPT partition on ${wipe_dev}..."
    sudo_cmd parted -s "$wipe_dev" mklabel gpt mkpart primary 1MiB 100%
    if [[ "$wipe_dev" == *nvme* ]]; then
      part="${wipe_dev}p1"
    else
      part="${wipe_dev}1"
    fi
    sudo_cmd udevadm settle || sleep 2
  fi

  log "Formatting ${part} as XFS..."
  sudo_cmd mkfs.xfs -f "$part"
  sudo_cmd mkdir -p "$target"
  uuid="$(sudo_cmd blkid -s UUID -o value "$part")"
  [[ -n "$uuid" ]] || die "Could not read UUID for ${part}."

  fstab_line="UUID=${uuid}  ${target}  xfs  rw,auto,pquota,noatime,nofail  0  0"
  if grep -qE "[[:space:]]${target}[[:space:]]" /etc/fstab; then
    warn "/etc/fstab already has an entry for ${target}. Leaving it untouched; add this line manually if needed:"
    echo "$fstab_line"
  else
    log "Appending ${target} to /etc/fstab"
    echo "$fstab_line" | sudo_cmd tee -a /etc/fstab >/dev/null
  fi
  sudo_cmd mount "$target"
  ok "Mounted XFS+pquota at ${target}."
  warn "Start Docker after verifying: sudo systemctl start docker"
else
  fstype="$(findmnt -n -o FSTYPE --target "$target" 2>/dev/null || true)"
  source="$(findmnt -n -o SOURCE --target "$target" 2>/dev/null || true)"
  if [[ "$fstype" != "xfs" ]]; then
    warn "${target} is ${fstype:-unknown} on ${source:-unknown}."
    warn "Vast.ai requires a dedicated XFS volume with pquota for Docker quotas."
    warn "This script will NOT format a disk unless you pass --confirm-wipe /dev/DISK."
    warn "Preferred: create the XFS partition during Ubuntu install (see docs/HOST_INSTALL.md)."
  else
    log "Existing XFS at ${target}. Ensuring pquota,noatime in fstab (no format)."
    uuid="$(findmnt -n -o UUID --target "$target" 2>/dev/null || true)"
    if [[ -n "$uuid" ]] && grep -q "$uuid" /etc/fstab; then
      sudo_cmd python3 - "$uuid" "$target" <<'PY'
import sys, pathlib
uuid, target = sys.argv[1], sys.argv[2]
path = pathlib.Path("/etc/fstab")
lines = path.read_text().splitlines()
out = []
for line in lines:
    if line.strip().startswith("#") or uuid not in line:
        out.append(line)
        continue
    parts = line.split()
    if len(parts) < 4:
        out.append(line)
        continue
    opts = parts[3].split(",")
    for extra in ("pquota", "noatime"):
        if extra not in opts and not (extra == "pquota" and "prjquota" in opts):
            opts.append(extra)
    parts[3] = ",".join(opts)
    out.append("\t".join(parts) if "\t" in line else "  ".join(parts))
path.write_text("\n".join(out) + "\n")
print("updated fstab for", uuid)
PY
      sudo_cmd mount -o remount,pquota,noatime "$target" 2>/dev/null || \
        warn "Remount with pquota failed (often needs a reboot). Reboot after reviewing /etc/fstab."
    else
      warn "Could not find a UUID fstab entry for ${target}. Add one manually:"
      echo "UUID=<uuid>  ${target}  xfs  rw,auto,pquota,noatime,nofail  0  0"
    fi
  fi
fi

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-storage.sh" --json
