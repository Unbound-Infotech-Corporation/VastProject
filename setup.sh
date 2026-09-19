#!/usr/bin/env bash
# Back-compat wrapper for the guided CLI installer.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${ROOT}/scripts/vast-host-setup" "$@"
