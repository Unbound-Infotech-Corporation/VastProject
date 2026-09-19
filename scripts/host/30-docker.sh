#!/usr/bin/env bash
# Install Docker Engine (official Ubuntu apt repo) and NVIDIA Container Toolkit
# (official NVIDIA apt repo). Vast's host installer can also install these;
# this script is for preparing the host before pasting the dashboard command,
# or for machines that already have the daemon and need the stack rebuilt.
#
# Sources:
#   https://docs.docker.com/engine/install/ubuntu/
#   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
#
# Does not format disks. Does not set Docker data-root onto a wiped device.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

require_ubuntu
require_root_or_sudo

codename="$(ubuntu_codename)"
arch="$(dpkg --print-architecture)"

if ! is_command docker; then
  log "Installing Docker Engine from download.docker.com (${DOCKER_DOCS})"
  ${SUDO} apt-get update
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg
  ${SUDO} install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    ${SUDO} curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    ${SUDO} chmod a+r /etc/apt/keyrings/docker.asc
  fi
  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" \
    | ${SUDO} tee /etc/apt/sources.list.d/docker.list >/dev/null
  ${SUDO} apt-get update
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ${SUDO} systemctl enable --now docker
  ok "Docker Engine installed."
else
  ok "Docker already present: $(docker --version)"
fi

if [[ "${EUID}" -ne 0 && -n "${SUDO}" ]]; then
  ${SUDO} usermod -aG docker "${USER}" || true
  warn "Added ${USER} to the docker group. Log out/in for it to take effect."
fi

if ! is_command nvidia-ctk; then
  log "Installing NVIDIA Container Toolkit (${NVIDIA_CTK_DOCS})"
  ${SUDO} apt-get update
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | ${SUDO} gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | ${SUDO} tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
  ${SUDO} apt-get update
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-container-toolkit
  ok "nvidia-container-toolkit installed."
else
  ok "nvidia-ctk already present: $(nvidia-ctk --version 2>/dev/null | head -1 || echo yes)"
fi

log "Configuring Docker to use the NVIDIA runtime (nvidia-ctk runtime configure --runtime=docker)"
${SUDO} nvidia-ctk runtime configure --runtime=docker
${SUDO} systemctl restart docker
ok "Docker restarted with NVIDIA runtime."

warn "GPU-in-Docker smoke test (optional, pulls an NVIDIA image):"
echo "  docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi"
echo "Do not run this while the host is rented."
