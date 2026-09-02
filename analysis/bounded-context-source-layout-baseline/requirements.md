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
- 僅為回應 PR review，於三份既有 BC 文件各加入其暫定 source location baseline；此記錄不代表 Swift target、module、依賴方向或 contract。

## Out-Of-Scope

- `Package.swift`、GitHub API feasibility、Swift source、測試與外部契約。
- 新增、重命名或調整 Bounded Context、target、module、依賴方向、資料契約或 failure contract。
- 修改 README、`AGENTS.md`、圖或 `.gitignore`。
- 修改三份明列 BC 文件以外的架構文件，或變更任何 BC responsibility、Bounded Context Map、architecture path decision 或圖。
- 本次 PR review 已明示授權的既有例外僅為 `docs/architecture/bounded-contexts/pr-inbox.md`、`docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/architecture/bounded-contexts/github-integration.md` 的受限回寫；除該既授權 remediation 外，不得將 BC 文件或其他架構文件納入本 topic。
- 任何產品 Swift 行為、BC contract、SwiftPM target、product、module 或 GitHub integration。
- 除 `scripts/check-swift-format.sh` 外的既有 tracked path；亦不得提交 lockfile 或 `surfaces/pr-reader-webview/node_modules/`。
- commit `94b6506` 與 `09043bf` 均早於 REVIEW-002；不得倒填、改寫或宣稱兩者曾經 REVIEW-002 核可。
- 未經獨立 REVIEW-003 明示核可的 audit-correction delivery（commit、push、PR thread resolution）、release，或進入下一個產品 slice。

## Acceptance Criteria

- `Sources/BoundedContexts/` 只包含 `PRInbox`、`PRReader` 與 `GitHubIntegration` 三個本 topic 建立的 BC directories。
- 每個 BC directory 只包含一個空白 `.gitkeep`。
- source layout 不含 Swift source、target、module、test 或 contract。
- formatter 對目錄 lint 使用 `--recursive`；renderer check 可在 frozen lockfile 準備後執行，且該準備不變更 lockfile 或產生可追蹤檔案。
- formatter、renderer check 與完整 pre-commit hook 均通過；原始 delivery commit 範圍僅包含原七個 topic 檔案與 `scripts/check-swift-format.sh`，既授權 remediation commit 才另含三份 BC 文件的受限單行回寫。
- 獨立 Reviewer 明示核可後，建立單一 topic commit、push branch 並向 `main` 開 Draft PR，然後停止於 human review。

## Delivery Actions

既有 topic delivery 已形成 commit `94b6506` 與 remediation commit `09043bf`；兩者均早於未執行的 REVIEW-002，均為必須如實保留的 historical workflow deviations。後續僅限第三個 audit-correction delivery；它只可在新的獨立 REVIEW-003 明示 `approved` 後執行，且 commit 僅可包含四份 topic artifacts，完成後交還 human review，不得 merge 或 release。

## Stop Conditions

- formatter 修正需要修改 `scripts/check-swift-format.sh` 以外的 tracked path。
- dependency installation 變更 lockfile，或產生未被忽略的可追蹤檔案。
- formatter、renderer check 或 pre-commit 發現 scope、contract 或 workflow drift。
- BC 文件回寫需要超出暫定 source location baseline 的內容。
- planning amendment 未經獨立 Plan-Reviewer 明示核可。

## PR Review Remediation

- `docs/architecture/bounded-contexts/pr-inbox.md`、`pr-reader.md` 與 `github-integration.md` 各僅可加入一行，記錄其對應的暫定 source location：`Sources/BoundedContexts/PRInbox/`、`PRReader/`、`GitHubIntegration/`。
- 每一行必須明示此 baseline 不代表 target、module、dependency 或 contract；不得改變既有 BC responsibility、Map、圖或 path decision。
- commit `94b6506` 與 `09043bf` 均早於未執行的 REVIEW-002；兩者皆為 historical workflow deviations，必須如實保留，不得倒填或宣稱已獲先前 approval。
- 僅在新的獨立 REVIEW-003 明示核可後，才可建立第三個 audit-correction delivery commit；它僅可包含四份 topic artifacts，不得改寫已 push history 或 force push。
- C thread 要求僅保留 PR Inbox 的建議，與 Human 已鎖定的三 BC decision 衝突，因此為 non-actionable finding；不得以此調整 architecture 或 source paths。
