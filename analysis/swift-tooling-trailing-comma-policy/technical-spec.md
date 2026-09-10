# Swift Tooling Trailing Comma Policy：技術規格

## Locked Contract

- Xcode 內建 Swift formatter（`swift format`）是 trailing comma 的格式權威。
- 根 `.swiftlint.yml` 在 top-level `disabled_rules` 明確列出 `trailing_comma`；不調整其他 SwiftLint rule、existing exclusion 或 threshold。
- `.pre-commit-config.yaml` 保持不變；既有 Swift format 與 SwiftLint hooks 繼續共存。
- `docs/toolchain.md` 必須如實說明：Xcode 內建 Swift formatter（`swift format`）決定 trailing comma；SwiftLint 的 `trailing_comma` rule 已停用，以避免雙重／衝突檢查；其他 SwiftLint rules 和既有 hook 保持有效。

## Authorized Modify Targets

- `.swiftlint.yml`
- `docs/toolchain.md`

所有其他 config、source、tests、manifests、lockfiles、dependencies、HTTPHeaders artifacts、BC 文件、architecture docs 與 diagrams 均為 read-only。

## Required Verification

- `swiftlint rules` 顯示 `trailing_comma` disabled。
- `scripts/check-swift-format.sh` 通過。
- `scripts/check-swiftlint.sh` 通過。
- `pre-commit run --all-files` 通過，且既有 hooks 維持啟用。
