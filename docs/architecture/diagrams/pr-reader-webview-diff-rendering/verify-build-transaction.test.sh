#!/usr/bin/env bash
set -euo pipefail

diagram_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
verifier="$diagram_dir/verify-build-transaction.sh"
build_entry="$diagram_dir/build-diagram.sh"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/pr-reader-diff-verifier-test.XXXXXX")"
fake_bin="$test_dir/bin"
fake_build_entry="$test_dir/build-with-failing-mktemp.sh"

cleanup() {
  rm -rf -- "$test_dir"
}
trap cleanup EXIT

assert_output_line() {
  local marker="$1"
  local output_file="$2"

  if ! grep -Fqx -- "$marker" "$output_file"; then
    printf '缺少預期測試輸出標記：%s\n' "$marker" >&2
    sed -n '1,240p' "$output_file" >&2
    exit 1
  fi
}

mkdir -p -- "$fake_bin"
printf '#!/usr/bin/env bash\nprintf "受控 mktemp 失敗\\n" >&2\nexit 73\n' > "$fake_bin/mktemp"
printf '#!/usr/bin/env bash\nPATH="%s:$PATH" exec bash "%s" "$@"\n' "$fake_bin" "$build_entry" > "$fake_build_entry"
chmod +x "$fake_bin/mktemp" "$fake_build_entry"

output_file="$test_dir/verifier-output.txt"
if PR_READER_BUILD_ENTRY="$fake_build_entry" bash "$verifier" >"$output_file" 2>&1; then
  printf 'verifier 不得把任意 prebuild mktemp 失敗視為受控 rollback。\n' >&2
  exit 1
fi

assert_output_line '受控 mktemp 失敗' "$output_file"
assert_output_line 'before-commit：缺少預期輸出標記：受控失敗注入：before-commit' "$output_file"
printf 'verifier 已拒絕受控 mktemp prebuild 失敗，未產生 false green。\n'
