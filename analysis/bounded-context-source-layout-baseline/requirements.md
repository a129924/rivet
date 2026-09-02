# 暫定 Bounded Context Source Layout Baseline：需求

## Goal

建立可由 Git 追蹤、但不含行為的最小 Swift source layout，讓已確認的 PR Inbox、PR Reader 與 GitHub Integration 各自有明確的 source location。

## Non-Goal

- 不驗證或實作 GitHub infrastructure。
- 不建立 Swift 程式碼、SwiftPM target、product、module、測試、介面或 cross-BC contract。
- 不變更 Bounded Context Map，且不建立 `PresentationSession` 目錄。

## In-Scope

- 建立三個已確認 BC 的空白 source layout folders。
- 在每個 folder 建立唯一且空白的 `.gitkeep`。
- 建立本 topic 的正式 analysis 與 plan artifacts，記錄此受限 implementation contract。
- 僅為使既有 pre-commit gate 能正確檢查本 topic 的空白 Swift source directories，修正 `scripts/check-swift-format.sh` 的目錄 lint 為遞迴檢查。
- 在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile`，僅作為既有 renderer check 的本地、ignored dependency 準備；不得納入 commit。

## Out-Of-Scope

- `Package.swift`、GitHub API feasibility、Swift source、測試與外部契約。
- 新增、重命名或調整 Bounded Context、target、module、依賴方向、資料契約或 failure contract。
- 修改 README、`AGENTS.md`、架構文件、圖或 `.gitignore`。
- 任何產品 Swift 行為、BC contract、SwiftPM target、product、module 或 GitHub integration。
- 除 `scripts/check-swift-format.sh` 外的既有 tracked path；亦不得提交 lockfile 或 `surfaces/pr-reader-webview/node_modules/`。
- 未經 REVIEW-002 明示核可的 commit、push、向 `main` 開 Draft PR、release，或進入下一個產品 slice。

## Acceptance Criteria

- `Sources/BoundedContexts/` 只包含 `PRInbox`、`PRReader` 與 `GitHubIntegration` 三個本 topic 建立的 BC directories。
- 每個 BC directory 只包含一個空白 `.gitkeep`。
- source layout 不含 Swift source、target、module、test 或 contract。
- formatter 對目錄 lint 使用 `--recursive`；renderer check 可在 frozen lockfile 準備後執行，且該準備不變更 lockfile 或產生可追蹤檔案。
- formatter、renderer check 與完整 pre-commit hook 均通過；commit 範圍僅包含原七個 topic 檔案與 `scripts/check-swift-format.sh`。
- 獨立 Reviewer 明示核可後，建立單一 topic commit、push branch 並向 `main` 開 Draft PR，然後停止於 human review。

## Delivery Actions

單一 topic commit、push branch 與向 `main` 開 Draft PR 不屬於 implementation 變更或產品 scope。它們只可在 REVIEW-002 明示 `approved` 後，作為 Human 已授權的 topic delivery actions 執行；Draft PR 建立後停止於 human review，不得 merge 或 release。

## Stop Conditions

- formatter 修正需要修改 `scripts/check-swift-format.sh` 以外的 tracked path。
- dependency installation 變更 lockfile，或產生未被忽略的可追蹤檔案。
- formatter、renderer check 或 pre-commit 發現 scope、contract 或 workflow drift。
