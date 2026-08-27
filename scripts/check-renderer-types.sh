#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
renderer_dir="$root_dir/surfaces/pr-reader-webview"

if ! find "$renderer_dir/src" -type f \
  \( -name '*.ts' -o -name '*.tsx' -o -name '*.mts' -o -name '*.cts' \) \
  -print -quit 2>/dev/null | grep -q .; then
  exit 0
fi

cd "$renderer_dir"
tsc --noEmit --project tsconfig.json
