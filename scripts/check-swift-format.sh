#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
targets=()

for directory in Sources Tests packages/RivetHTTPClient/Sources packages/RivetHTTPClient/Tests; do
  if [[ -d "$root_dir/$directory" ]]; then
    targets+=("$directory")
  fi
done

if [[ ${#targets[@]} -gt 0 ]]; then
  cd "$root_dir"
  swift format lint --strict --recursive "${targets[@]}"
fi
