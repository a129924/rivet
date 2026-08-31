# Vendored Build macOS Apps skills

## Source

- Upstream repository: https://github.com/openai/plugins
- Plugin path: `plugins/build-macos-apps`
- Plugin version: `0.1.4`
- Pinned upstream commit: `33bd9529725fcee78c9e51fcbaa93cd963c3a47b`

## Included skills

This directory vendors the complete `skills/` directory from the pinned plugin
revision. It contains the following project-local Codex skills:

- `appkit-interop`
- `build-run-debug`
- `liquid-glass`
- `packaging-notarization`
- `signing-entitlements`
- `swiftpm-macos`
- `swiftui-patterns`
- `telemetry`
- `test-triage`
- `view-refactor`
- `window-management`

## Synchronization

To update, select a new `main` commit from the upstream repository, replace the
vendored skill directories with `plugins/build-macos-apps/skills/` from that
exact revision, update the plugin version and commit above, then validate each
`SKILL.md`, reject unsafe symbolic links, and commit the result together.

No user-level Codex plugin configuration, plugin manifest, cache, or product
runtime dependency is vendored here.

## Local overlays

本 repository 在保留上方 pinned upstream 的前提下，對下列 vendored skills
採用有意識的本地 overlay；它們不是 upstream 原文，也不代表已同步到其他
upstream revision。

- `build-run-debug`：優先使用 caller 或專案既有入口；GUI app relaunch 必須
  驗證目標 process，待其停止後以既有 `.app` bundle 或 caller 指定方法啟動，
  不用 `open -n` 建立平行 instance。
- `swiftui-patterns`：將 Git/bootstrap 與固定檔案樹改為 caller 明確要求時才採用。
- `telemetry`：使用現有 launch method；缺少所需入口時才建議轉介。
- `window-management`：接受可用 launch method，不強制特定 build/run skill。

每次更新上游 pin 或替換 vendored skill 前，先比較這些 overlay 與新 upstream
內容，逐項決定保留、調整或移除，並在本檔更新結果；不得假設 overlay 已被
上游吸收。
