#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$root_dir/scripts/check-swift-coverage.sh"
(cd "$root_dir/surfaces/pr-reader-webview" && bun run test:coverage)
