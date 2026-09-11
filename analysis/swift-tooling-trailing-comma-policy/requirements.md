# Swift Tooling Trailing Comma Policy：需求

## Goal

明確指定 Xcode 內建 Swift formatter（`swift format`）為 trailing comma 的唯一格式權威，避免它與 SwiftLint `trailing_comma` rule 產生重複或衝突的判定；保留現有 SwiftLint 其他 rules 與 pre-commit hook。

## In Scope

- 在根 `.swiftlint.yml` 明確停用 SwiftLint `trailing_comma` rule。
- 更新 `docs/toolchain.md`，說明 trailing comma 由 Xcode 內建 Swift formatter（`swift format`）決定，以及它與 SwiftLint 的共存責任。
- 驗證 SwiftLint rules 顯示 `trailing_comma` disabled，並通過既有 format、SwiftLint 與 pre-commit checks。

## Out of Scope

- `.pre-commit-config.yaml`、Xcode Swift formatter（`swift format`）設定、Swift source／tests、package manifests／lockfiles、Node dependencies。
- 其他 SwiftLint rules、其他 formatting policy、HTTPHeaders artifacts、BC 文件、architecture docs 或 diagrams。

## Success Criteria

- 根 `.swiftlint.yml` 唯一新增／調整的 lint policy 是顯式停用 `trailing_comma`；其餘 SwiftLint rules 不變。
- `docs/toolchain.md` 明確將 trailing comma authority 指向 Xcode 內建 Swift formatter（`swift format`），並說明 SwiftLint 不再檢查該 rule。
- `swiftlint rules` 確認 `trailing_comma` 為 disabled。
- `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `pre-commit run --all-files` 全部通過。
