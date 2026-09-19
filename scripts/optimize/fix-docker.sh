#!/usr/bin/env bash
# Safe Docker tweaks for Vast.ai hosts:
# - configure NVIDIA runtime via official nvidia-ctk
# - ensure overlay2 is set without wiping /var/lib/docker
# Does not format disks or delete images.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

if ! have_cmd docker; then
  die "Docker is not installed. Run scripts/bootstrap-host.sh or the Vast.ai installer."
fi

if have_cmd nvidia-ctk; then
  log "Configuring Docker NVIDIA runtime (nvidia-ctk runtime configure --runtime=docker)..."
  sudo_cmd nvidia-ctk runtime configure --runtime=docker
else
  warn "nvidia-ctk not found; skipping runtime configure. Install NVIDIA Container Toolkit first."
fi

daemon_json="/etc/docker/daemon.json"
log "Merging overlay2 storage-driver into ${daemon_json} (existing keys are preserved)."

sudo_cmd python3 - <<'PY'
import json, os, tempfile, shutil
path = "/etc/docker/daemon.json"
data = {}
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read().strip()
        if raw:
            data = json.loads(raw)
if not isinstance(data, dict):
    raise SystemExit("daemon.json is not a JSON object; refusing to overwrite.")
data.setdefault("storage-driver", "overlay2")
data.setdefault("log-driver", "json-file")
data.setdefault("log-opts", {"max-size": "10m", "max-file": "3"})
# Only add storage-opts when /var/lib/docker is already XFS+pquota.
# overlay2.override_kernel_check plus --storage-opt quotas fail on ext4.
def docker_root_is_xfs_pquota():
    import subprocess
    try:
        fstype = subprocess.check_output(
            ["findmnt", "-n", "-o", "FSTYPE", "--target", "/var/lib/docker"],
            text=True,
        ).strip()
        opts = subprocess.check_output(
            ["findmnt", "-n", "-o", "OPTIONS", "--target", "/var/lib/docker"],
            text=True,
        ).strip()
    except Exception:
        return False
    return fstype == "xfs" and ("pquota" in opts or "prjquota" in opts)

if docker_root_is_xfs_pquota():
    data.setdefault("storage-opts", ["overlay2.override_kernel_check=true"])
fd, tmp = tempfile.mkstemp(prefix="daemon.json.", dir="/tmp")
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.chmod(tmp, 0o644)
shutil.copy(tmp, path)
os.unlink(tmp)
print("wrote", path)
PY

log "Restarting Docker..."
sudo_cmd systemctl restart docker
ok "Docker runtime/config updated."

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-docker.sh" "${1:-}"
