#!/usr/bin/env bash
# Run optimizer checks or safe applies for one component or all.
# Usage: run.sh <Storage|GPU|Docker|Network|All> [--apply] [--json]

set -euo pipefail
opt_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${opt_dir}/../lib.sh"

component="${1:-}"
apply="false"
json="false"
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply="true"; shift ;;
    --json) json="true"; shift ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "$component" ]] || die "Usage: $0 <Storage|GPU|Docker|Network|All> [--apply] [--json]"

run_one() {
  local name="$1"
  local check=""
  local fix=""
  case "$name" in
    Storage) check="${opt_dir}/check-storage.sh"; fix="${opt_dir}/fix-storage.sh" ;;
    GPU)     check="${opt_dir}/check-gpu.sh";     fix="${opt_dir}/fix-gpu.sh" ;;
    Docker)  check="${opt_dir}/check-docker.sh";  fix="${opt_dir}/fix-docker.sh" ;;
    Network) check="${opt_dir}/check-network.sh"; fix="${opt_dir}/fix-network.sh" ;;
    *) die "Unknown component: $name" ;;
  esac
  if [[ "$apply" == "true" ]]; then
    # Storage apply from the dashboard/API never wipes disks (no --confirm-wipe).
    "$fix"
  else
    "$check"
  fi
}

exit_code=0
if [[ "$component" == "All" ]]; then
  for c in Storage GPU Docker Network; do
    run_one "$c" || exit_code=1
  done
else
  run_one "$component" || exit_code=$?
fi

if [[ "$json" == "true" ]]; then
  "${opt_dir}/collect-status.sh" || true
fi

exit "$exit_code"
