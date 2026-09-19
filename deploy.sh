#!/usr/bin/env bash
# Back-compat wrapper. Prefer: ./scripts/vast-host-setup
# or ./scripts/install-dashboard.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${ROOT}/scripts/install-dashboard.sh" "$@"
