# 暫定 Bounded Context Source Layout Baseline：執行 Ledger

## Topic

`bounded-context-source-layout-baseline`

## Current Phase

PR review-fix review；PLAN-004 已由獨立 Plan-Reviewer 核可，三份 BC 文件的受限 remediation 已完成並經 Tester PASS 驗證。commit `94b6506` 早於本次 review gate 的 historical workflow deviation 如實保留；不得倒填或宣稱 prior approval。

## Locked Scope

- 僅可建立 `Sources/BoundedContexts/PRInbox/.gitkeep`、`Sources/BoundedContexts/PRReader/.gitkeep` 與 `Sources/BoundedContexts/GitHubIntegration/.gitkeep`；三檔必須空白。
- 不得將此 layout 解讀為 Swift target、module、dependency、interface、contract 或 infrastructure 決策。
- 不得新增 `PresentationSession` 或其他未確認 Bounded Context，亦不得新增 Swift source、test、contract 或既有檔案修改；本次 human 明示授權、僅限加上 `--recursive` 的 `scripts/check-swift-format.sh` 修正除外。
- Human 僅授權為既有 pre-commit gate 修正 `scripts/check-swift-format.sh` 的目錄 lint 為 `--recursive`，以及在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile` 準備 ignored local dependency；不得提交 lockfile 或 `node_modules/`。
- Human 另授權三份既有 BC 文件各加入一行對應的暫定 source location baseline，並明示不代表 target、module、dependency 或 contract；不得變更 BC responsibility、Map、圖或既有 architecture/path decision。
- C thread 的 PR Inbox-only 要求與 Human 已鎖定的三 BC decision 衝突，為 non-actionable finding；不得以此調整 architecture 或 source paths。

## Ledger

| ID | status | owner role | completion condition | validation evidence |
| --- | --- | --- | --- | --- |
| PLAN-001 | complete | Plan-Creator | `requirements.md`、`technical-spec.md`、plan 與本 ledger 已建立，並記錄已鎖定範圍與 human boundary。 | 四份 topic planning artifacts 位於既定 `analysis/` 與 `plan/` 路徑；須由獨立 Plan-Reviewer 檢視。 |
| PLAN-002 | complete | Plan-Reviewer | 獨立檢查 planning artifacts 與既有架構邊界、scope 及 ledger schema；明示回報結果予 Dispatcher。 | Plan-Reviewer 已明示 approved；其獨立書面結果為 Dispatcher 已引用的 evidence。 |
| PLAN-003 | complete | Plan-Reviewer | 獨立檢查本次 pre-commit gate scope amendment 是否僅限 `scripts/check-swift-format.sh` 的 `--recursive` 修正與 local ignored dependency 準備，並明示回報結果予 Dispatcher。 | Plan-Reviewer 已明示 approved；amendment 保持既定受限範圍。 |
| PLAN-004 | complete | Plan-Reviewer | 獨立檢查 PR review remediation amendment 是否僅限三份 BC 文件的單行 source location baseline、historical workflow deviation audit correction 與第二個 remediation commit 交付界線，並明示回報結果予 Dispatcher。 | Plan-Reviewer 已明示 approved；remediation amendment 維持受限範圍。 |
| IMPL-001 | complete | Implementer | Dispatcher 依 PLAN-002 的明示結果派遣後，僅在 feature worktree 建立三個指定且空白的 `.gitkeep`。 | Implementer 已建立 `PRInbox`、`PRReader` 與 `GitHubIntegration` 的三個指定 `.gitkeep`；受限路徑的 git diff 與目錄／空白檔檢查結果可供獨立角色引用。 |
| IMPL-002 | complete | Implementer | PLAN-003 核可後，僅修正指定 formatter 呼叫並執行 frozen lockfile local dependency 準備；再執行指定 gate。 | Implementer 僅加入 `--recursive`；`bun install --frozen-lockfile` 成功，指定 checks 已通過。 |
| IMPL-003 | complete | Implementer | PLAN-004 核可後，僅在三份既有 BC 文件各加入一行對應的暫定 source location baseline；不得定義 target、module、dependency 或 contract。 | Implementer 已在 PR Inbox、PR Reader 與 GitHub Integration 各自既有 BC 文件加入一行受限 baseline 說明。 |
| TEST-002 | complete | Tester | IMPL-002 後，獨立檢查 formatter、renderer check、完整 pre-commit、staged scope 與 ignored dependency。 | Tester 明示 PASS：staged scope 為 8 個允許 paths，lockfiles 未變更、`node_modules/` 為 ignored，且 pre-commit 通過。 |
| TEST-003 | complete | Tester | IMPL-003 後，獨立檢查三份 BC 文件的受限 baseline、未新增 target／module／dependency／contract，及 remediation scope。 | Tester 明示 PASS：三份文件各僅有一行對應的暫定 source location baseline，且無 scope、contract 或 tracked-path drift。 |
| REVIEW-002 | pending | Reviewer | TEST-003 後，獨立判定 PR review remediation 與驗證結果是否有 scope、contract 或 workflow drift。 | 尚待獨立 Reviewer verdict；不得將 ledger status 或 evidence 視為核可。 |
| TEST-001 | complete | Tester | IMPL-001 完成後，檢查三個指定 `.gitkeep`、目錄集合及未授權檔案不存在。 | Tester 已明示 PASS：指定檔案存在且空白、目錄集合正確、無未授權 source／target／module／test／contract／BC。 |
| REVIEW-001 | needs-rework | Reviewer | TEST-001 完成後，獨立判定本 topic 是否有 scope、contract 或 workflow drift，並回報分類予 Dispatcher。 | Reviewer 明示 `needs-rework`：ledger 的 phase 與 PLAN-002／IMPL-001／TEST-001 狀態未反映既有 evidence，構成 workflow drift；未提供 reviewer approved verdict。 |
| HUMAN-001 | pending | Human | REVIEW-002 明示 `approved` 後完成單一 topic commit、push branch 與向 `main` 開 Draft PR；Draft PR 建立後交還 human review。 | Human 的 Draft PR review、明示確認或指示。 |

## Blockers

- Human 已明示授權本次 pre-commit gate scope expansion，以及 REVIEW-002 明示 `approved` 後的單一 topic commit、push branch 與向 `main` 開 Draft PR。
- REVIEW-001 的 `needs-rework` 為本次 amendment 前的歷史 evidence，不再是 delivery blocker；不得將其重寫為 approved 或完成。
- 若 formatter 修正需修改 `scripts/check-swift-format.sh` 以外的 tracked path，或 dependency install 改變 lockfile／產生可追蹤檔案，立即停止並交回 Dispatcher。
- 若要求寫入未列入本 topic 的路徑、修改既有檔案、刪除內容、新增 BC 或 Swift contract，立即停止並交回 Dispatcher。
- 若發現 scope、contract 或 workflow drift，停止前進；由 Dispatcher 派遣相應獨立角色處理。
- REVIEW-002 尚待獨立 Reviewer verdict；未明示 approved 前不得建立 remediation commit、push 或處理 threads。
- historical workflow deviation：`94b6506` 在本次 review gate 前已建立；此為 audit correction 的範圍，不得倒填、宣稱 prior approval、rewrite history 或 force push。後續僅可建立第二個 remediation commit。

## Human Check

- PR review remediation 已經 PLAN-004 核可並由獨立 Implementer、Tester 完成受限工作；尚待獨立 Reviewer verdict。
- REVIEW-002 明示 approved 後，才可建立第二個 remediation commit、push branch 並處理已核可的 PR threads；不得 rewrite history、force push、merge、release 或進入產品 slice。

## Ledger Interpretation

- 本 ledger 的 `status` 與 `validation evidence` 僅記錄追蹤結構與預期證據；不構成 approval、verdict、routing、gate pass 或工作完成宣告。
- 僅 Dispatcher 可依獨立角色的明示結果決定前進、回修、停止或交還 human check。

## Last Updated

2026-09-02 — Plan-Creator：依受限 ledger exception，同步既有明示 evidence：PLAN-004 為 complete、IMPL-003 為 complete、TEST-003 為 complete，並將 Current Phase 更新為 PR review-fix review；REVIEW-002 與 HUMAN-001 維持 pending。如實保留 `94b6506` 早於 review gate 的 historical workflow deviation，不倒填 prior approval。本次未進行 review、approval、verdict、implementation、測試、Git 或 PR/thread actions。
