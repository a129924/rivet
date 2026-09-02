# 暫定 Bounded Context Source Layout Baseline

## Goal

建立可被 Git 追蹤、但不含行為的最小 Swift source layout，讓三個既有 Bounded Context 各自擁有 source location。

## Non-Goal

不驗證或實作 GitHub infrastructure；不建立 Swift code、SwiftPM target、product、module、tests、interface 或 cross-BC contract；不調整 BC Map，亦不將 `Presentation Session` 建為 BC。

## In-Scope

- `PRInbox`、`PRReader`、`GitHubIntegration` 三個空白 BC layout folders，以及各自唯一的 `.gitkeep`。
- 本 topic 的四份正式 planning artifacts。
- 僅修正 `scripts/check-swift-format.sh` 的目錄 lint 為 `--recursive`，讓既有 pre-commit gate 可正確檢查本 topic 的 source directories。
- 在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile`，僅準備既有 renderer check 所需的本地、ignored dependency。
- layout 完成後由獨立 Reviewer 驗證；其明示核可後執行已授權的 topic delivery actions，然後交還 human review。

## Out-Of-Scope

- `Package.swift`、所有 Swift source、測試、GitHub API feasibility 實驗。
- 新增、重命名或調整 Bounded Context、source target、module、依賴方向、資料契約或 failure contract。
- 修改既有架構文件、圖、README、`AGENTS.md` 或 `.gitignore`。
- 任何產品 Swift 行為、BC contract、SwiftPM target、product、module 或 GitHub integration。
- 修改 `scripts/check-swift-format.sh` 以外的既有 tracked path，或提交 lockfile、`surfaces/pr-reader-webview/node_modules/` 或其他本地 dependency 產物。
- 未經 REVIEW-002 明示核可的 commit、push、向 `main` 開 Draft PR、release，或進入下一個產品 slice。

## ReadOnly

Layout Implementation 僅可讀取 `AGENTS.md`、`README.md`、設計原則、架構與三份既有 BC 文件、本 topic planning artifacts、`scripts/check-swift-format.sh`、既有 renderer check 與必要時的 `.gitignore`。`requirements.md`、`technical-spec.md` 與本 plan 在 Layout Implementation 開始後一律為 ReadOnly。

Human 明示授權後，僅 Plan-Creator 可受限更新 `.step.md` 的 `Current Phase`、既有 Ledger steps 的 `status` 與 `validation evidence`、`Blockers`、`Last Updated`。每筆更新必須可追溯至已明示的上游角色結果；不得改變 BC/path、scope、Written、Deleted、Modify、acceptance 或 Human Check，亦不得將 ledger status/evidence 視為 approval、verdict、routing 或 gate pass。

## Written

Plan-Creator 只可建立或更新本 topic 四份 artifacts。Implementer 只可 create-only 接觸：

- `Sources/`
- `Sources/BoundedContexts/`
- `Sources/BoundedContexts/PRInbox/.gitkeep`
- `Sources/BoundedContexts/PRReader/.gitkeep`
- `Sources/BoundedContexts/GitHubIntegration/.gitkeep`

三個 `.gitkeep` 必須空白。

為準備既有 renderer check，Implementer 只可在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile`；它只可建立被 `.gitignore` 排除的本地 `node_modules/`，不得修改或提交 lockfile，亦不得提交任何 dependency 產物。

## Deleted

無；不得刪除任何檔案或資料夾。

## Modify

唯一允許修改的既有 tracked path 為 `scripts/check-swift-format.sh`。僅將既有目錄 lint 調整為使用 `--recursive`；不得變更其他 formatter 行為、設定或 path。Planning Artifact Creation 僅能變更本 topic 四份 artifacts。

## TestCase

- 四份 planning artifacts 在 Layout Implementation 前已建立；實作 phase 不改動 `requirements.md`、`technical-spec.md` 或本 plan。`.step.md` 僅可依明示 human 授權，於受限 ledger 維護例外內更新。
- 三個指定 `.gitkeep` 存在、空白，且在正確的 BC directory。
- `Sources/BoundedContexts/` 只含 `PRInbox`、`PRReader`、`GitHubIntegration`；每個 directory 只含 `.gitkeep`。
- 不存在 `PresentationSession` 或其他未確認 BC directory，亦沒有 Swift source、target、module、test 或 contract。
- Layout Implementation 不寫入、修改或刪除任何未列入 `Written`、`Modify` 或本地 dependency 準備例外的 repo path。
- `scripts/check-swift-format.sh` 的目錄 lint 使用 `--recursive`，formatter 成功完成。
- 在 `surfaces/pr-reader-webview/` 執行 frozen lockfile install 後，renderer check 與完整 pre-commit hook 成功完成；install 不變更 lockfile，且 `node_modules/` 維持 ignored、未追蹤。
- staged commit 範圍只包含三個 `.gitkeep`、四份 topic artifacts 與 `scripts/check-swift-format.sh`。
- 獨立 Reviewer 確認沒有 scope、contract 或 workflow drift。

## Stop Conditions

- hook 修正需要寫入 `scripts/check-swift-format.sh` 以外的 tracked path。
- dependency install 改變 lockfile，或產生可追蹤檔案。
- formatter、renderer check、pre-commit 或獨立 Tester／Reviewer 回報 scope、contract 或 workflow drift。

## Human Check Gate

REVIEW-002 明示 `approved` 後，可執行一次已授權的單一 topic commit、push branch 與向 `main` 開 Draft PR。這些 delivery actions 不屬於 implementation 變更或產品 scope。Draft PR 建立後唯一下一狀態是 human review；不得 merge、release 或進入下一個產品 slice。
