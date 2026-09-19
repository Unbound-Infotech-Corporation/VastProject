#!/usr/bin/env bash
# Check Docker storage against Vast.ai host expectations:
# XFS + project quotas (pquota/prjquota) on /var/lib/docker.
# Does not format or wipe anything.

set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

target="${DOCKER_ROOT:-/var/lib/docker}"
verified="false"
messages=()

if [[ ! -d "$target" ]]; then
  messages+=("${target} does not exist yet (Docker not installed or not mounted).")
else
  fstype="$(findmnt -n -o FSTYPE --target "$target" 2>/dev/null || true)"
  opts="$(findmnt -n -o OPTIONS --target "$target" 2>/dev/null || true)"
  source="$(findmnt -n -o SOURCE --target "$target" 2>/dev/null || true)"
  avail="$(df -h --output=avail "$target" 2>/dev/null | tail -n1 | tr -d ' ' || true)"

  if [[ "$fstype" == "xfs" ]]; then
    messages+=("${target} is XFS on ${source:-unknown} (${avail:-?} free).")
  elif [[ -z "$fstype" ]]; then
    messages+=("Could not determine filesystem for ${target}.")
  else
    messages+=("${target} is ${fstype}, not XFS. Vast.ai requires XFS with pquota for Docker storage quotas.")
  fi

  if [[ "$opts" == *pquota* || "$opts" == *prjquota* ]]; then
    messages+=("Project quotas are enabled (${opts}).")
  else
    messages+=("pquota/prjquota is NOT in mount options (${opts:-unknown}). Docker --storage-opt quotas will fail.")
  fi

  if [[ "$opts" == *noatime* ]]; then
    messages+=("noatime is set.")
  else
    messages+=("noatime is not set (optional performance tweak).")
  fi

  if [[ "$fstype" == "xfs" && ( "$opts" == *pquota* || "$opts" == *prjquota* ) ]]; then
    verified="true"
  fi
fi

message="$(IFS=' '; echo "${messages[*]}")"
if [[ "${1:-}" == "--json" ]]; then
  printf '{%s}\n' "$(emit_check storage "$verified" "$message")"
else
  if [[ "$verified" == "true" ]]; then ok "Storage: $message"; else warn "Storage: $message"; fi
fi
