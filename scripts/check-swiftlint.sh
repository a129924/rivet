#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! find "$root_dir/Sources" "$root_dir/Tests" -type f -name '*.swift' -print -quit 2>/dev/null | grep -q .; then
  exit 0
fi

developer_dir="$(xcode-select -p)"
if [[ "$developer_dir" != */Xcode.app/Contents/Developer ]]; then
  echo "error: Xcode must be selected before running SwiftLint." >&2
  echo "Run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer" >&2
  exit 2
fi

cd "$root_dir"
swiftlint lint --strict
