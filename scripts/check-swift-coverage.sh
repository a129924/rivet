#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
minimum_coverage=90
developer_dir="$(xcode-select -p)"

if [[ "$developer_dir" != */Xcode.app/Contents/Developer ]]; then
  echo "error: Xcode must be selected before collecting Swift coverage." >&2
  echo "Run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer" >&2
  exit 2
fi

package_paths=()

if find "$root_dir/Sources" "$root_dir/Tests" -type f -name '*.swift' -print -quit 2>/dev/null | grep -q .; then
  package_paths+=("$root_dir")
fi

for manifest in "$root_dir"/packages/*/Package.swift; do
  [[ -f "$manifest" ]] || continue
  package_path="${manifest%/Package.swift}"

  if find "$package_path/Sources" "$package_path/Tests" -type f -name '*.swift' -print -quit 2>/dev/null | grep -q .; then
    package_paths+=("$package_path")
  fi
done

if [[ ${#package_paths[@]} -eq 0 ]]; then
  exit 0
fi

for package_path in "${package_paths[@]}"; do
  swift test --package-path "$package_path" --enable-code-coverage

  coverage_profile="$(find "$package_path/.build" -type f -path '*/codecov/*.profdata' -print -quit)"

  if [[ -z "${coverage_profile:-}" || ! -f "$coverage_profile" ]]; then
    echo "error: SwiftPM did not produce a coverage profile for $package_path." >&2
    exit 1
  fi

  bin_path="$(swift build --package-path "$package_path" --show-bin-path)"
  test_binary="$(find "$bin_path" -type f -path '*.xctest/Contents/MacOS/*' -perm -u+x -print -quit)"

  if [[ -z "${test_binary:-}" || ! -f "$test_binary" ]]; then
    echo "error: SwiftPM did not produce a test bundle binary for $package_path." >&2
    exit 1
  fi

  coverage_report="$(xcrun llvm-cov report "$test_binary" -instr-profile="$coverage_profile" "$package_path/Sources")"
  line_coverage="$(awk '$1 == "TOTAL" { gsub(/%/, "", $(NF - 3)); print $(NF - 3) }' <<<"$coverage_report")"

  if [[ -z "$line_coverage" ]]; then
    echo "error: llvm-cov did not report total line coverage for $package_path." >&2
    exit 1
  fi

  printf 'Swift line coverage (%s): %s%%\n' "$package_path" "$line_coverage"
  awk -v actual="$line_coverage" -v minimum="$minimum_coverage" 'BEGIN { exit !(actual >= minimum) }' || {
    echo "error: Swift line coverage must be at least ${minimum_coverage}% for $package_path." >&2
    exit 1
  }
done
