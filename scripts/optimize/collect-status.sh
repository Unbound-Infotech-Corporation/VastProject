#!/usr/bin/env bash
# Collect host readiness as a single JSON object for the dashboard API.

set -euo pipefail
opt_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${opt_dir}/../lib.sh"

run_json() {
  local script="$1"
  if [[ -x "$script" ]]; then
    "$script" --json 2>/dev/null || echo '{}'
  else
    echo '{}'
  fi
}

storage="$(run_json "${opt_dir}/check-storage.sh")"
gpu="$(run_json "${opt_dir}/check-gpu.sh")"
docker="$(run_json "${opt_dir}/check-docker.sh")"
network="$(run_json "${opt_dir}/check-network.sh")"
host="$(run_json "${opt_dir}/check-host.sh")"

python3 - "$storage" "$gpu" "$docker" "$network" "$host" <<'PY'
import json, sys
storage, gpu, docker, network, host = (json.loads(s or "{}") for s in sys.argv[1:])
out = {}
for blob in (storage, gpu, docker, network, host):
    out.update(blob)
# Guarantee keys the API expects
for key in ("storage", "gpu", "docker", "network", "os", "vast"):
    out.setdefault(key, {"verified": False, "message": "Check did not return a result."})
print(json.dumps(out))
PY
