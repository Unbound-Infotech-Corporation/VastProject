#!/usr/bin/env bash
# Check Docker + NVIDIA Container Toolkit. Read-only.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

verified="false"
messages=()
daemon_json="/etc/docker/daemon.json"

if ! have_cmd docker; then
  messages+=("docker is not installed.")
else
  if docker info >/dev/null 2>&1 || sudo_n docker info >/dev/null 2>&1; then
    messages+=("Docker daemon is running.")
  else
    messages+=("Docker is installed but the daemon is not running or not reachable.")
  fi

  runtime_ok="false"
  if [[ -f "$daemon_json" ]]; then
    if grep -q 'nvidia-container-runtime\|"nvidia"' "$daemon_json"; then
      runtime_ok="true"
      messages+=("daemon.json lists an nvidia runtime.")
    else
      messages+=("daemon.json exists but does not list the nvidia runtime. Run: sudo nvidia-ctk runtime configure --runtime=docker")
    fi
    if grep -q 'overlay2' "$daemon_json"; then
      messages+=("overlay2 storage driver is configured.")
    fi
  else
    messages+=("${daemon_json} is missing.")
  fi

  if have_cmd nvidia-ctk; then
    messages+=("nvidia-ctk is installed ($(nvidia-ctk --version 2>/dev/null | head -n1 | tr -d '\r')).")
  else
    messages+=("nvidia-ctk is not installed (NVIDIA Container Toolkit).")
  fi

  if have_cmd docker && [[ "$runtime_ok" == "true" ]] && have_cmd nvidia-ctk; then
    verified="true"
  fi
fi

message="$(IFS=' '; echo "${messages[*]}")"
if [[ "${1:-}" == "--json" ]]; then
  printf '{%s}\n' "$(emit_check docker "$verified" "$message")"
else
  if [[ "$verified" == "true" ]]; then ok "Docker: $message"; else warn "Docker: $message"; fi
fi
