#!/usr/bin/env bash
# Guided Vast host bootstrap for Ubuntu 22.04 / 24.04.
# Run on the machine you intend to list. Does not SSH. Does not wipe disks.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

print_safety_banner
require_ubuntu

cat <<EOF
${BOLD}Guided path: new Ubuntu Server → rent-ready on Vast.ai${NC}

  0  Preflight (this machine only)
  1  Ubuntu prep (packages, hold NVIDIA unattended upgrades)
  2  NVIDIA driver (ubuntu-drivers) + persistence mode
  3  Docker Engine + NVIDIA Container Toolkit
  4  Vast host daemon (paste dashboard command — do not invent flags)
  5  Firewall for the installer-written port range

Disk wipe is NOT in this list. If you still need a dedicated XFS Docker volume:
  ${SCRIPT_DIR}/prepare-docker-xfs.sh --help

Official docs:
  ${HOST_DOCS_SETUP}
  ${HOST_DOCS_VERIFY}
  ${HOST_DOCS_SSH}
  ${HOST_DOCS_KERNEL}
  ${HOST_DOCS_SELFTEST}

EOF

if ! confirm "Run preflight now?"; then
  die "Aborted."
fi
bash "${SCRIPT_DIR}/00-preflight.sh"

if confirm "Run Ubuntu prep (apt packages + NVIDIA hold)?"; then
  bash "${SCRIPT_DIR}/10-ubuntu-prep.sh"
fi

if confirm "Install / verify NVIDIA driver?"; then
  bash "${SCRIPT_DIR}/20-nvidia-driver.sh"
fi

if confirm "Install Docker + NVIDIA Container Toolkit?"; then
  bash "${SCRIPT_DIR}/30-docker.sh"
fi

if confirm "Install Vast host daemon (you must have the dashboard command/key)?"; then
  bash "${SCRIPT_DIR}/40-vast-daemon.sh"
fi

if confirm "Open UFW for the Vast port range?"; then
  bash "${SCRIPT_DIR}/50-network.sh"
fi

cat <<EOF

${GREEN}Bootstrap steps finished (or skipped).${NC}

Remaining human steps (cannot be done safely from this repo):
  • Forward the same TCP+UDP port range on the WAN router to this host.
  • Disable SSH password login only after a key works: ${HOST_DOCS_SSH}
  • List the machine from the host account, then self-test: ${HOST_DOCS_SELFTEST}
  • Do not run personal workloads on a listed machine.

Then start the optimizer dashboard from the repo root:
  ./deploy.sh
  open http://<this-host>:5000
EOF
