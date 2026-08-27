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
