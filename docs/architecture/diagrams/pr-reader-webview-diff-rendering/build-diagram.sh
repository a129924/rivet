#!/usr/bin/env bash
set -euo pipefail

diagram_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
canvas_skill_dir="${ARCHITECTURE_CANVAS_SKILL_DIR:-$HOME/.codex/skills/architecture-canvas}"
archify_skill_dir="${ARCHIFY_SKILL_DIR:-$HOME/.codex/skills/archify}"
canvas_target="$diagram_dir/index.html"
dataflow_target="$diagram_dir/diff-render-flow.html"
failure_point="${PR_READER_BUILD_FAIL_AT:-}"
temporary_paths=()
preserve_recovery_material=0

cleanup() {
  local status=$?
  trap - EXIT

  if (( preserve_recovery_material )); then
    printf '交易回復失敗；保留同資料夾復原材料，請依錯誤訊息人工復原。\n' >&2
  else
    local temporary_path
    for temporary_path in "${temporary_paths[@]-}"; do
      [[ -z "$temporary_path" ]] || rm -f -- "$temporary_path"
    done
  fi

  exit "$status"
}
trap cleanup EXIT

require_file() {
  if [[ ! -f "$1" ]]; then
    printf '缺少必要檔案：%s\n' "$1" >&2
    exit 1
  fi
}

allocate_temporary_file() {
  local variable_name="$1"
  local label="$2"
  local temporary_path
  temporary_path="$(mktemp "$diagram_dir/.pr-reader-diff-${label}.XXXXXX")"
  # The tool owns the named path, while the generator owns its contents.
  rm -f -- "$temporary_path"
  temporary_paths+=("$temporary_path")
  printf -v "$variable_name" '%s' "$temporary_path"
}

sha256() {
  shasum -a 256 "$1" | awk '{print $1}'
}

assert_regular_file() {
  if [[ ! -s "$1" ]]; then
    printf '預期非空的一般檔案：%s\n' "$1" >&2
    return 1
  fi
}

fail_at() {
  local expected="$1"
  if [[ "$failure_point" == "$expected" ]]; then
    printf '受控失敗注入：%s\n' "$expected" >&2
    return 1
  fi
  return 0
}

build_canvas_candidate() {
  local raw_output="$1"
  local enhanced_output="$2"
  local repeated_output="$3"

  node "$canvas_skill_dir/scripts/build.js" \
    --scene "$diagram_dir/scene.js" \
    --out "$raw_output" \
    --title "PR Reader — WebView 差異宣告邊界" \
    --kicker "PR READER — WEBVIEW 差異宣告邊界" \
    --sub "<b>所有權</b> · <b>依賴</b> · <b>邊界</b>" \
    --slug "pr-reader-webview-diff-rendering"
  node "$diagram_dir/enhance-accessibility.js" --input "$raw_output" --output "$enhanced_output"
  node "$diagram_dir/verify-accessibility.js" --input "$enhanced_output"
  node "$diagram_dir/enhance-accessibility.js" --input "$enhanced_output" --output "$repeated_output"
  cmp -s "$enhanced_output" "$repeated_output"
}

build_dataflow_candidate() {
  local output="$1"
  node "$archify_skill_dir/bin/archify.mjs" deliver dataflow \
    "$diagram_dir/diff-render-flow.dataflow.json" "$output" --quality showcase --json
}

restore_target() {
  local target="$1"
  local backup="$2"
  local expected_hash="$3"
  local restore_path=""

  if [[ "$(sha256 "$target")" == "$expected_hash" ]]; then
    return 0
  fi

  allocate_temporary_file restore_path "restore"
  if ! cp -p -- "$backup" "$restore_path"; then
    printf '無法建立復原副本：%s\n' "$target" >&2
    return 1
  fi
  if ! mv -f -- "$restore_path" "$target"; then
    printf '無法以原子 rename 復原：%s\n' "$target" >&2
    return 1
  fi
  if [[ "$(sha256 "$target")" != "$expected_hash" ]]; then
    printf '復原 hash 不一致：%s\n' "$target" >&2
    return 1
  fi
}

rollback_pair() {
  local canvas_original_hash="$1"
  local dataflow_original_hash="$2"
  local canvas_backup="$3"
  local dataflow_backup="$4"
  local rollback_failed=0

  restore_target "$canvas_target" "$canvas_backup" "$canvas_original_hash" || rollback_failed=1
  restore_target "$dataflow_target" "$dataflow_backup" "$dataflow_original_hash" || rollback_failed=1

  if (( rollback_failed )); then
    preserve_recovery_material=1
    printf '交易回復未完成；原始副本仍保留於：%s、%s\n' "$canvas_backup" "$dataflow_backup" >&2
    return 1
  fi
  return 0
}

abort_commit() {
  local reason="$1"
  local canvas_original_hash="$2"
  local dataflow_original_hash="$3"
  local canvas_backup="$4"
  local dataflow_backup="$5"

  printf '交付交易失敗：%s；開始以 backup/restore 回復。\n' "$reason" >&2
  if rollback_pair "$canvas_original_hash" "$dataflow_original_hash" "$canvas_backup" "$dataflow_backup"; then
    printf '交付交易已回復；既有輸出保持不變。\n' >&2
  fi
  exit 1
}

case "$failure_point" in
  ""|before-commit|after-canvas-rename) ;;
  *)
    printf '未知的 PR_READER_BUILD_FAIL_AT 值：%s\n' "$failure_point" >&2
    exit 2
    ;;
esac

require_file "$canvas_skill_dir/scripts/validate.js"
require_file "$canvas_skill_dir/scripts/build.js"
require_file "$archify_skill_dir/bin/archify.mjs"
require_file "$diagram_dir/scene.js"
require_file "$diagram_dir/enhance-accessibility.js"
require_file "$diagram_dir/verify-accessibility.js"
require_file "$diagram_dir/diff-render-flow.dataflow.json"
require_file "$canvas_target"
require_file "$dataflow_target"

allocate_temporary_file canvas_raw_first "canvas-raw-first"
allocate_temporary_file canvas_candidate_first "canvas-candidate-first"
allocate_temporary_file canvas_repeated_first "canvas-repeated-first"
allocate_temporary_file dataflow_candidate_first "dataflow-candidate-first"
allocate_temporary_file canvas_raw_second "canvas-raw-second"
allocate_temporary_file canvas_candidate_second "canvas-candidate-second"
allocate_temporary_file canvas_repeated_second "canvas-repeated-second"
allocate_temporary_file dataflow_candidate_second "dataflow-candidate-second"
allocate_temporary_file canvas_backup "canvas-backup"
allocate_temporary_file dataflow_backup "dataflow-backup"

# Both temporary paths live beside their eventual committed target, so every
# successful mv below is a same-filesystem, single-file atomic rename.
node "$canvas_skill_dir/scripts/validate.js" "$diagram_dir/scene.js"
node "$archify_skill_dir/bin/archify.mjs" validate dataflow \
  "$diagram_dir/diff-render-flow.dataflow.json" --quality showcase --json

build_canvas_candidate "$canvas_raw_first" "$canvas_candidate_first" "$canvas_repeated_first"
build_dataflow_candidate "$dataflow_candidate_first"
build_canvas_candidate "$canvas_raw_second" "$canvas_candidate_second" "$canvas_repeated_second"
build_dataflow_candidate "$dataflow_candidate_second"

assert_regular_file "$canvas_candidate_first"
assert_regular_file "$dataflow_candidate_first"
assert_regular_file "$canvas_candidate_second"
assert_regular_file "$dataflow_candidate_second"
cmp -s "$canvas_candidate_first" "$canvas_candidate_second"
cmp -s "$dataflow_candidate_first" "$dataflow_candidate_second"

canvas_new_hash="$(sha256 "$canvas_candidate_first")"
dataflow_new_hash="$(sha256 "$dataflow_candidate_first")"
canvas_repeat_hash="$(sha256 "$canvas_candidate_second")"
dataflow_repeat_hash="$(sha256 "$dataflow_candidate_second")"
[[ "$canvas_new_hash" == "$canvas_repeat_hash" ]]
[[ "$dataflow_new_hash" == "$dataflow_repeat_hash" ]]
printf '候選一致性 hash：canvas=%s dataflow=%s\n' "$canvas_new_hash" "$dataflow_new_hash"

if ! fail_at before-commit; then
  exit 1
fi

canvas_original_hash="$(sha256 "$canvas_target")"
dataflow_original_hash="$(sha256 "$dataflow_target")"
cp -p -- "$canvas_target" "$canvas_backup"
cp -p -- "$dataflow_target" "$dataflow_backup"
[[ "$(sha256 "$canvas_backup")" == "$canvas_original_hash" ]]
[[ "$(sha256 "$dataflow_backup")" == "$dataflow_original_hash" ]]

# POSIX has no atomic multi-file rename. Keep exact backups until both
# individual atomic renames and their target hashes are proven, then restore
# both from those backups on any commit-phase failure.
if ! mv -f -- "$canvas_candidate_first" "$canvas_target"; then
  abort_commit "canvas atomic rename 失敗" "$canvas_original_hash" "$dataflow_original_hash" "$canvas_backup" "$dataflow_backup"
fi
if ! fail_at after-canvas-rename; then
  abort_commit "canvas rename 後的受控失敗" "$canvas_original_hash" "$dataflow_original_hash" "$canvas_backup" "$dataflow_backup"
fi
if ! mv -f -- "$dataflow_candidate_first" "$dataflow_target"; then
  abort_commit "dataflow atomic rename 失敗" "$canvas_original_hash" "$dataflow_original_hash" "$canvas_backup" "$dataflow_backup"
fi
if [[ "$(sha256 "$canvas_target")" != "$canvas_new_hash" || "$(sha256 "$dataflow_target")" != "$dataflow_new_hash" ]]; then
  abort_commit "commit 後 hash 驗證失敗" "$canvas_original_hash" "$dataflow_original_hash" "$canvas_backup" "$dataflow_backup"
fi

printf '已以兩次單檔 atomic rename 交付一致的 canvas 與 dataflow：%s\n' "$diagram_dir"
