# Swift Tooling Trailing Comma Policy

## Summary

將 trailing comma 的格式判定收斂為 Xcode 內建 Swift formatter（`swift format`）的單一責任，並在 SwiftLint 顯式停用重複的 `trailing_comma` rule。既有 SwiftLint rules 與 pre-commit workflow 維持不變。

## Implementation Changes

- 在根 `.swiftlint.yml` 的 top-level `disabled_rules` 加入 `trailing_comma`，不修改任何其他 rule、設定或 exclusion。
- 在 `docs/toolchain.md` 記錄 Xcode 內建 Swift formatter（`swift format`）是 trailing comma authority、SwiftLint `trailing_comma` 已停用，以及兩者與現有 pre-commit hooks 的共存方式。

### Swift Implementation Handoff

#### Goal

讓 Xcode 內建 Swift formatter（`swift format`）成為 trailing comma 的唯一格式權威，移除 SwiftLint 對同一政策的重複檢查。

#### Non-Goal

不改變其他 lint／format rule、hook 行為、Swift source／tests、dependency 或 package configuration。

#### In-Scope

- 根 `.swiftlint.yml` 顯式停用 `trailing_comma`。
- `docs/toolchain.md` 的 authority 與共存說明。
- 指定 format、lint 與 pre-commit acceptance checks。

#### Out-Of-Scope

- `.pre-commit-config.yaml`、Xcode Swift formatter（`swift format`）設定、Swift source／tests、Package manifests／lockfiles、Node dependencies、HTTPHeaders artifacts、BC／architecture docs 或 diagrams。
- 任何其他 SwiftLint rule 或 formatting policy。

#### ReadOnly

- 除下列 Modify targets 外的所有 repository files，特別是 `.pre-commit-config.yaml`、Xcode Swift formatter（`swift format`）設定、source、tests、manifests、lockfiles、dependencies、HTTPHeaders artifacts、BC 文件與 architecture docs／diagrams。

#### Modify

- `.swiftlint.yml`：僅在 top-level `disabled_rules` 明確加入 `trailing_comma`，保留其餘 SwiftLint rules 與設定。
- `docs/toolchain.md`：說明 Xcode 內建 Swift formatter（`swift format`）的 trailing comma authority、已停用的 SwiftLint rule 及既有 hooks 的共存。

#### Written

無新增檔案；僅修改既有 Modify targets。

#### Deleted

無。不得刪除、搬移或更名任何檔案、rule、hook 或 dependency。

#### TestCase

- `swiftlint rules` 顯示 `trailing_comma` disabled。
- `scripts/check-swift-format.sh` 通過。
- `scripts/check-swiftlint.sh` 通過。
- `pre-commit run --all-files` 通過，且現有 hooks 仍執行。

## Assumptions

- 現有 `scripts/check-swift-format.sh` 是本 topic 所稱 Xcode Swift formatter（`swift format`）check 的執行入口。
- 這個 topic 只釐清既有工具的 policy authority；不導入、升級或替換 formatter／linter。
