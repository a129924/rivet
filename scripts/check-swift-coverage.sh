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

cd "$root_dir"
swift test --enable-code-coverage

coverage_path="$(swift test --show-code-coverage-path | tail -n 1)"
if [[ -d "$coverage_path" ]]; then
  coverage_profile="$(find "$coverage_path" -maxdepth 1 -type f -name '*.profdata' -print -quit)"
elif [[ -f "$coverage_path" && "$coverage_path" == *.profdata ]]; then
  coverage_profile="$coverage_path"
else
  coverage_profile="$(find .build -type f -path '*/codecov/*.profdata' -print -quit)"
fi

if [[ -z "${coverage_profile:-}" || ! -f "$coverage_profile" ]]; then
  echo "error: SwiftPM did not produce a coverage profile." >&2
  exit 1
fi

bin_path="$(swift test --show-bin-path)"
test_binary="$(find "$bin_path" -type f -path '*.xctest/Contents/MacOS/*' -perm -u+x -print -quit)"

if [[ -z "${test_binary:-}" || ! -f "$test_binary" ]]; then
  echo "error: SwiftPM did not produce a test bundle binary." >&2
  exit 1
fi

coverage_report="$(xcrun llvm-cov report "$test_binary" -instr-profile="$coverage_profile" "$root_dir/Sources")"
line_coverage="$(awk '$1 == "TOTAL" { gsub(/%/, "", $NF); print $NF }' <<<"$coverage_report")"

if [[ -z "$line_coverage" ]]; then
  echo "error: llvm-cov did not report total line coverage." >&2
  exit 1
fi

printf 'Swift line coverage: %s%%\n' "$line_coverage"
awk -v actual="$line_coverage" -v minimum="$minimum_coverage" 'BEGIN { exit !(actual >= minimum) }' || {
  echo "error: Swift line coverage must be at least ${minimum_coverage}%." >&2
  exit 1
}
