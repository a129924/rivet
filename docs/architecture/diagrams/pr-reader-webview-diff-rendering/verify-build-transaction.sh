#!/usr/bin/env bash
set -euo pipefail

diagram_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_entry="${PR_READER_BUILD_ENTRY:-$diagram_dir/build-diagram.sh}"
canvas_target="$diagram_dir/index.html"
dataflow_target="$diagram_dir/diff-render-flow.html"

require_file() {
  if [[ ! -f "$1" ]]; then
    printf '缺少必要檔案：%s\n' "$1" >&2
    exit 1
  fi
}

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

assert_exact_output_line() {
  local scenario="$1"
  local marker="$2"
  local output_file="$3"

  if ! grep -Fqx -- "$marker" "$output_file"; then
    printf '%s：缺少預期輸出標記：%s\n' "$scenario" "$marker" >&2
    printf '%s：實際輸出如下：\n' "$scenario" >&2
    sed -n '1,240p' "$output_file" >&2
    exit 1
  fi
}

assert_failed_build_has_markers() {
  local scenario="$1"
  local injection_marker="$2"
  local recovery_marker="$3"
  local canvas_before="$4"
  local dataflow_before="$5"
  shift 5
  local output_file
  local build_status

  output_file="$(mktemp "${TMPDIR:-/tmp}/pr-reader-diff-build-output.XXXXXX")"
  if "$@" >"$output_file" 2>&1; then
    rm -f -- "$output_file"
    printf '%s：受控失敗注入意外成功。\n' "$scenario" >&2
    exit 1
  else
    build_status=$?
  fi

  if (( build_status == 0 )); then
    rm -f -- "$output_file"
    printf '%s：預期非零退出，卻取得零退出。\n' "$scenario" >&2
    exit 1
  fi

  assert_exact_output_line "$scenario" "$injection_marker" "$output_file"
  assert_exact_output_line "$scenario" "$recovery_marker" "$output_file"
  rm -f -- "$output_file"
  [[ "$(sha256 "$canvas_target")" == "$canvas_before" ]]
  [[ "$(sha256 "$dataflow_target")" == "$dataflow_before" ]]
  assert_no_temporary_residue
}

require_file "$build_entry"
require_file "$canvas_target"
require_file "$dataflow_target"

canvas_before="$(sha256 "$canvas_target")"
dataflow_before="$(sha256 "$dataflow_target")"

assert_failed_build_has_markers \
  before-commit \
  '受控失敗注入：before-commit' \
  '交付交易尚未開始；無需回復。' \
  "$canvas_before" "$dataflow_before" \
  env PR_READER_BUILD_FAIL_AT=before-commit bash "$build_entry"

# The final three scenarios begin after the transaction has created its
# backups. They must expose both the exact injection signal and an explicit
# rollback signal; a generic prebuild error is not acceptable evidence.
assert_failed_build_has_markers \
  after-canvas-rename \
  '受控失敗注入：after-canvas-rename' \
  '交付交易已回復；既有輸出保持不變。' \
  "$canvas_before" "$dataflow_before" \
  env PR_READER_BUILD_FAIL_AT=after-canvas-rename bash "$build_entry"
assert_failed_build_has_markers \
  SIGINT \
  '受控中斷注入：after-canvas-rename（SIGINT）' \
  '交付交易在完成前結束；開始以 backup/restore 回復。' \
  "$canvas_before" "$dataflow_before" \
  env PR_READER_BUILD_INTERRUPT_AT=after-canvas-rename PR_READER_BUILD_INTERRUPT_SIGNAL=INT bash "$build_entry"
assert_failed_build_has_markers \
  SIGTERM \
  '受控中斷注入：after-canvas-rename（SIGTERM）' \
  '交付交易在完成前結束；開始以 backup/restore 回復。' \
  "$canvas_before" "$dataflow_before" \
  env PR_READER_BUILD_INTERRUPT_AT=after-canvas-rename PR_READER_BUILD_INTERRUPT_SIGNAL=TERM bash "$build_entry"

printf '每個受控失敗／中斷均已證明精確注入與回復訊號，並保留既有 canvas 與 dataflow hash，且無 temporary residue。\n'
