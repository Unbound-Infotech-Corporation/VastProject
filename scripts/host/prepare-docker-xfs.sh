#!/usr/bin/env bash
# DANGEROUS: formats a block device as XFS and mounts it at /var/lib/docker.
#
# This is the ONLY script in this repo that will wipe a disk.
# It never runs from the dashboard API.
# It never SSHes anywhere.
# It refuses to run unless every confirmation flag is present.
#
# Vast host setup: Docker on a dedicated XFS volume; system on /.
# Official layout from https://cloud.vast.ai/host/setup/ :
#   EFI >= 256 MB, root (ext4) >= 80 GB, remaining disks for Docker (XFS).
# Verification: dedicated Docker SSD >= 200 GB, root free >= 20 GB.
#
# Docker overlay2 project quotas require XFS mounted with pquota
# (Docker storage-driver documentation).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<EOF
${RED}${BOLD}THIS SCRIPT WIPES THE TARGET BLOCK DEVICE.${NC}

Usage:
  $0 --i-understand-this-wipes-disks --device /dev/DISK --yes-wipe-device DISKNAME

Example:
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
  $0 --i-understand-this-wipes-disks --device /dev/nvme1n1 --yes-wipe-device nvme1n1

Refuses to run if:
  - any required flag is missing
  - the device is the OS disk (mounted at / or /boot)
  - the device name does not exactly match --yes-wipe-device
  - Docker has running containers (unless --force-with-running-docker)

Does not run over SSH to another host. Does not pick a disk for you.
EOF
}

WIPE_ACK=0
DEVICE=""
YES_NAME=""
FORCE_DOCKER=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --i-understand-this-wipes-disks) WIPE_ACK=1; shift ;;
    --device) DEVICE="${2:-}"; shift 2 ;;
    --yes-wipe-device) YES_NAME="${2:-}"; shift 2 ;;
    --force-with-running-docker) FORCE_DOCKER=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

print_safety_banner

if [[ "${WIPE_ACK}" -ne 1 || -z "${DEVICE}" || -z "${YES_NAME}" ]]; then
  usage
  die "Refusing to run without explicit wipe flags."
fi

require_ubuntu
require_root_or_sudo

if [[ ! -b "${DEVICE}" ]]; then
  die "${DEVICE} is not a block device."
fi

base="$(basename "${DEVICE}")"
if [[ "${base}" != "${YES_NAME}" ]]; then
  die "Device basename '${base}' does not match --yes-wipe-device '${YES_NAME}'."
fi

# Refuse whole-disk aliases that are the system disk.
os_source="$(findmnt -n -o SOURCE / || true)"
boot_source="$(findmnt -n -o SOURCE /boot || true)"
if [[ "${DEVICE}" == "${os_source}" || "${DEVICE}" == "${boot_source}" ]]; then
  die "Refusing to wipe the mounted OS/boot device."
fi

# Also refuse if any partition of this disk is mounted on / or /boot.
while read -r name mount; do
  if [[ "${mount}" == "/" || "${mount}" == "/boot" || "${mount}" == "/boot/efi" ]]; then
    die "Refusing: ${name} is mounted on ${mount}."
  fi
done < <(lsblk -nrpo NAME,MOUNTPOINT "${DEVICE}" | awk '$2 != ""')

if is_command docker && [[ "${FORCE_DOCKER}" -ne 1 ]]; then
  running="$(docker ps -q 2>/dev/null || true)"
  if [[ -n "${running}" ]]; then
    die "Docker has running containers. Stop rentals / containers first, or pass --force-with-running-docker (still wipes)."
  fi
fi

echo
${SUDO} lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL "${DEVICE}"
echo
warn "ALL DATA ON ${DEVICE} WILL BE DESTROYED."
if ! confirm "Type-confirm by answering y to wipe ${DEVICE} (${YES_NAME})?"; then
  die "Aborted. No disks were changed."
fi

part="${DEVICE}"
# If this is a whole disk, create a single GPT partition.
if [[ "${DEVICE}" =~ nvme[0-9]+n[0-9]+$ || "${DEVICE}" =~ vd[a-z]$ || "${DEVICE}" =~ sd[a-z]$ ]]; then
  log "Creating a single GPT partition on ${DEVICE}..."
  ${SUDO} sgdisk --zap-all "${DEVICE}"
  ${SUDO} sgdisk --new=1:0:0 --typecode=1:8300 "${DEVICE}"
  ${SUDO} partprobe "${DEVICE}" || true
  sleep 2
  if [[ "${DEVICE}" =~ nvme ]]; then
    part="${DEVICE}p1"
  else
    part="${DEVICE}1"
  fi
fi

if [[ ! -b "${part}" ]]; then
  die "Partition ${part} did not appear."
fi

log "Formatting ${part} as XFS..."
${SUDO} mkfs.xfs -f "${part}"

uuid="$(${SUDO} blkid -s UUID -o value "${part}")"
[[ -n "${uuid}" ]] || die "Could not read UUID after mkfs."

${SUDO} mkdir -p /var/lib/docker
fstab_line="UUID=${uuid}  /var/lib/docker  xfs  rw,auto,pquota,nofail,noatime  0  0"

if grep -q ' /var/lib/docker ' /etc/fstab; then
  warn "/etc/fstab already has a /var/lib/docker line. Leaving it untouched."
  warn "Add this yourself if needed:"
  echo "  ${fstab_line}"
else
  echo "${fstab_line}" | ${SUDO} tee -a /etc/fstab >/dev/null
  ok "Appended fstab entry with pquota,noatime."
fi

${SUDO} systemctl stop docker 2>/dev/null || true
${SUDO} mount /var/lib/docker
${SUDO} systemctl start docker 2>/dev/null || true

ok "Mounted $(findmnt -n -o SOURCE,FSTYPE,OPTIONS /var/lib/docker)"
df -h /var/lib/docker
echo "Confirm pquota appears in mount options before listing the machine."
