#!/usr/bin/env bash
# Compatibility wrapper. Prefer deploy.sh or scripts/host/bootstrap.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${ROOT}/deploy.sh"
