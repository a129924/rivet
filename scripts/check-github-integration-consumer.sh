#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$root_dir/Tests/GitHubIntegrationConsumer"
fixture_build_dir="$fixture_dir/.build"
RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"

cleanup_scratch() {
  local status=$?
  trap - EXIT

  rm -rf -- "$RIVET_CONSUMER_BUILD_PATH"
  if [[ -e "$RIVET_CONSUMER_BUILD_PATH" || -L "$RIVET_CONSUMER_BUILD_PATH" ]]; then
    echo "error: consumer scratch cleanup did not remove its exact path" >&2
    exit 1
  fi

  exit "$status"
}

trap cleanup_scratch EXIT

if [[ -L "$fixture_build_dir" ]]; then
  echo "error: consumer fixture .build must not be a symlink" >&2
  exit 1
fi

if [[ -e "$fixture_build_dir" && ! -d "$fixture_build_dir" ]]; then
  echo "error: consumer fixture .build must be a directory" >&2
  exit 1
fi

if [[ -d "$fixture_build_dir" ]]; then
  if ! git -C "$root_dir" check-ignore --no-index -q -- Tests/GitHubIntegrationConsumer/.build; then
    echo "error: consumer fixture .build is not ignored generated output" >&2
    exit 1
  fi

  rm -rf -- "$fixture_build_dir"
fi

if [[ -e "$fixture_build_dir" || -L "$fixture_build_dir" ]]; then
  echo "error: consumer fixture .build must be absent before validation" >&2
  exit 1
fi

(
  cd "$fixture_dir"
  swift test --scratch-path "$RIVET_CONSUMER_BUILD_PATH"
)

if [[ -e "$fixture_build_dir" || -L "$fixture_build_dir" ]]; then
  echo "error: consumer fixture .build must be absent after validation" >&2
  exit 1
fi
