#!/usr/bin/env bash
set -euo pipefail

diagram_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_entry="$diagram_dir/build-diagram.sh"
canvas_target="$diagram_dir/index.html"
dataflow_target="$diagram_dir/diff-render-flow.html"

sha256() {
  shasum -a 256 "$1" | awk '{print $1}'
}

assert_no_temporary_residue() {
  local residue
  residue="$(find "$diagram_dir" -maxdepth 1 -type f -name '.pr-reader-diff-*' -print -quit)"
  if [[ -n "$residue" ]]; then
    printf '遺留 temporary artifact：%s\n' "$residue" >&2
    exit 1
  fi
}

assert_unchanged_after_failure() {
  local failure_point="$1"
  local canvas_before="$2"
  local dataflow_before="$3"

  if PR_READER_BUILD_FAIL_AT="$failure_point" bash "$build_entry"; then
    printf '受控失敗注入意外成功：%s\n' "$failure_point" >&2
    exit 1
  fi
  [[ "$(sha256 "$canvas_target")" == "$canvas_before" ]]
  [[ "$(sha256 "$dataflow_target")" == "$dataflow_before" ]]
  assert_no_temporary_residue
}

canvas_before="$(sha256 "$canvas_target")"
dataflow_before="$(sha256 "$dataflow_target")"

# The second point occurs after the first committed target was renamed. It
# proves the documented backup/restore policy rather than pretending that two
# file replacements form one atomic filesystem operation.
assert_unchanged_after_failure before-commit "$canvas_before" "$dataflow_before"
assert_unchanged_after_failure after-canvas-rename "$canvas_before" "$dataflow_before"

printf '兩個受控失敗點均保留既有 canvas 與 dataflow hash，且無 temporary residue。\n'
