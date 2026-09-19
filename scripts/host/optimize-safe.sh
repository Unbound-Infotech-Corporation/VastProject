#!/usr/bin/env bash
# Allowlisted, non-destructive host fixes used by the dashboard API.
# Never formats disks. Never runs the Vast installer. Never SSHes.
#
# Usage: optimize-safe.sh <gpu|docker|network|storage|all> [--dry-run]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

COMPONENT="${1:-}"
DRY_RUN=0
if [[ "${2:-}" == "--dry-run" || "${VAST_DRY_RUN:-}" == "1" ]]; then
  DRY_RUN=1
fi

run() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "DRY-RUN: $*"
    return 0
  fi
  # shellcheck disable=SC2086
  eval "$@"
}

optimize_gpu() {
  if ! is_command nvidia-smi; then
    echo "SKIP gpu: nvidia-smi not installed"
    return 0
  fi
  run "nvidia-smi -pm 1"
  echo "GPU persistence mode requested (nvidia-smi -pm 1)."
}

optimize_docker() {
  if ! is_command nvidia-ctk; then
    echo "SKIP docker: nvidia-ctk not installed"
    return 0
  fi
  if ! is_command docker; then
    echo "SKIP docker: docker not installed"
    return 0
  fi
  run "nvidia-ctk runtime configure --runtime=docker"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "DRY-RUN: systemctl restart docker"
  else
    if [[ "${EUID}" -eq 0 ]]; then
      systemctl restart docker
    elif command -v sudo >/dev/null 2>&1; then
      sudo systemctl restart docker
    else
      echo "WARN: configured runtime but could not restart docker (no root)."
    fi
  fi
  echo "Docker NVIDIA runtime configured via nvidia-ctk."
}

optimize_network() {
  range_file="/var/lib/vastai_kaalia/host_port_range"
  if [[ ! -f "${range_file}" ]]; then
    echo "SKIP network: ${range_file} missing (run Vast installer first)"
    return 0
  fi
  range="$(tr -d '[:space:]' < "${range_file}")"
  if [[ ! "${range}" =~ ^[0-9]+-[0-9]+$ ]]; then
    echo "SKIP network: invalid range '${range}'"
    return 0
  fi
  start="${range%-*}"
  end="${range#*-}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "DRY-RUN: ufw allow ${start}:${end}/tcp and udp"
    return 0
  fi
  if ! is_command ufw; then
    echo "SKIP network: ufw not installed"
    return 0
  fi
  if [[ "${EUID}" -eq 0 ]]; then
    ufw allow OpenSSH || ufw allow 22/tcp
    ufw allow "${start}:${end}/tcp"
    ufw allow "${start}:${end}/udp"
  elif command -v sudo >/dev/null 2>&1; then
    sudo ufw allow OpenSSH || sudo ufw allow 22/tcp
    sudo ufw allow "${start}:${end}/tcp"
    sudo ufw allow "${start}:${end}/udp"
  else
    echo "SKIP network: no sudo"
    return 0
  fi
  echo "UFW rules requested for ${range} TCP+UDP."
}

optimize_storage() {
  echo "Storage optimize is report-only. Disk wipe is not available via this script."
  if findmnt /var/lib/docker >/dev/null 2>&1; then
    echo "Docker mount: $(findmnt -n -o SOURCE,FSTYPE,OPTIONS /var/lib/docker)"
  else
    echo "No dedicated /var/lib/docker mount. Use scripts/host/prepare-docker-xfs.sh only after identifying a spare disk."
  fi
}

case "${COMPONENT}" in
  gpu) optimize_gpu ;;
  docker) optimize_docker ;;
  network) optimize_network ;;
  storage) optimize_storage ;;
  all)
    optimize_storage
    optimize_gpu
    optimize_docker
    optimize_network
    ;;
  *)
    echo "Usage: $0 <gpu|docker|network|storage|all> [--dry-run]" >&2
    exit 2
    ;;
esac
