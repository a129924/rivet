# 暫定 Bounded Context Source Layout Baseline：執行 Ledger

## Topic

`bounded-context-source-layout-baseline`

## Current Phase

REVIEW-003 independent review；PLAN-005、PLAN-006 與 TEST-004 的既有 evidence 已同步。commit `94b6506` 與 `09043bf` 均早於 REVIEW-002；REVIEW-002 為 historical deviation、未執行，不得倒填或宣稱 prior approval。

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
| PLAN-005 | complete | Plan-Creator | 依 Human 對 PR review 的明示授權，僅修訂四份 artifacts，記錄既已授權 BC-document remediation、historical audit 與 delivery consistency；不得改變三 BC baseline、paths、contract 或 C thread 結論。 | 四份 artifacts 的本次 planning-audit amendment 已限定於既有授權範圍；此 ledger evidence 不構成 approval。 |
| PLAN-006 | complete | Plan-Reviewer | 獨立審查 PLAN-005 的 planning-audit amendment 是否如實標記 REVIEW-002 為未執行的 historical deviation，並維持新的 REVIEW-003 delivery boundary。 | Plan-Reviewer 已明示 approved；amendment 如實保留 REVIEW-002 的 historical-deviation-not-run 與 REVIEW-003 delivery boundary。 |
| IMPL-001 | complete | Implementer | Dispatcher 依 PLAN-002 的明示結果派遣後，僅在 feature worktree 建立三個指定且空白的 `.gitkeep`。 | Implementer 已建立 `PRInbox`、`PRReader` 與 `GitHubIntegration` 的三個指定 `.gitkeep`；受限路徑的 git diff 與目錄／空白檔檢查結果可供獨立角色引用。 |
| IMPL-002 | complete | Implementer | PLAN-003 核可後，僅修正指定 formatter 呼叫並執行 frozen lockfile local dependency 準備；再執行指定 gate。 | Implementer 僅加入 `--recursive`；`bun install --frozen-lockfile` 成功，指定 checks 已通過。 |
| IMPL-003 | complete | Implementer | PLAN-004 核可後，僅在三份既有 BC 文件各加入一行對應的暫定 source location baseline；不得定義 target、module、dependency 或 contract。 | Implementer 已在 PR Inbox、PR Reader 與 GitHub Integration 各自既有 BC 文件加入一行受限 baseline 說明。 |
| TEST-002 | complete | Tester | IMPL-002 後，獨立檢查 formatter、renderer check、完整 pre-commit、staged scope 與 ignored dependency。 | Tester 明示 PASS：staged scope 為 8 個允許 paths，lockfiles 未變更、`node_modules/` 為 ignored，且 pre-commit 通過。 |
| TEST-003 | complete | Tester | IMPL-003 後，獨立檢查三份 BC 文件的受限 baseline、未新增 target／module／dependency／contract，及 remediation scope。 | Tester 明示 PASS：三份文件各僅有一行對應的暫定 source location baseline，且無 scope、contract 或 tracked-path drift。 |
| REVIEW-002 | historical-deviation-not-run | Reviewer | 原定於 TEST-003 後獨立判定 PR review remediation 與驗證結果是否有 scope、contract 或 workflow drift。 | 未執行；commit `94b6506` 與 `09043bf` 均早於此 review gate。此條目不是 approved、pending gate 或 delivery authorization。 |
| TEST-001 | complete | Tester | IMPL-001 完成後，檢查三個指定 `.gitkeep`、目錄集合及未授權檔案不存在。 | Tester 已明示 PASS：指定檔案存在且空白、目錄集合正確、無未授權 source／target／module／test／contract／BC。 |
| REVIEW-001 | needs-rework | Reviewer | TEST-001 完成後，獨立判定本 topic 是否有 scope、contract 或 workflow drift，並回報分類予 Dispatcher。 | Reviewer 明示 `needs-rework`：ledger 的 phase 與 PLAN-002／IMPL-001／TEST-001 狀態未反映既有 evidence，構成 workflow drift；未提供 reviewer approved verdict。 |
| TEST-004 | complete | Tester | PLAN-006 核可後，獨立驗證四份 planning artifacts 的 audit consistency：既授權 remediation、兩個 commit-before-review deviation、C thread non-actionable 結論與 REVIEW-003 delivery boundary 均一致。 | Tester 已明示 PASS：四份 artifacts 的 audit consistency 維持既授權 remediation、兩個 commit-before-review deviation、C thread non-actionable 結論與 REVIEW-003 delivery boundary；此 evidence 不構成 approval、verdict 或 delivery authorization。 |
| REVIEW-003 | pending | Reviewer | TEST-004 後，獨立判定 planning-audit amendment 與 audit-correction delivery 範圍是否有 scope、contract 或 workflow drift。 | 尚待獨立 Reviewer verdict；只有明示 `approved` 才可進行新的 audit-correction delivery。 |
| DELIVERY-001 | pending | Implementer | REVIEW-003 明示 `approved` 後，僅以四份 planning artifacts 建立單一新的 audit-correction commit、push branch 並處理已核可的 PR threads；不得重做、改寫或 force push 既有 commits。 | 尚待 REVIEW-003；delivery evidence 必須保留既有 `94b6506`／`09043bf` 歷史不變，且不可新增其他 tracked path。 |
| HUMAN-001 | pending | Human | DELIVERY-001 完成 audit-correction commit、push 與 thread resolution 後，PR 交還 human review。 | Human 的 PR review、明示確認或指示；不得命令或暗示重做既有 commits。 |

## Blockers

- Human 已明示授權本次 pre-commit gate scope expansion、三份 BC 文件 remediation，以及本次 planning-audit amendment；這些授權不構成 REVIEW-003 approval 或 audit-correction delivery authorization。
- REVIEW-001 的 `needs-rework` 為本次 amendment 前的歷史 evidence，不再是 delivery blocker；不得將其重寫為 approved 或完成。
- 若 formatter 修正需修改 `scripts/check-swift-format.sh` 以外的 tracked path，或 dependency install 改變 lockfile／產生可追蹤檔案，立即停止並交回 Dispatcher。
- 若要求寫入未列入本 topic 的路徑、修改既有檔案、刪除內容、新增 BC 或 Swift contract，立即停止並交回 Dispatcher。
- 若發現 scope、contract 或 workflow drift，停止前進；由 Dispatcher 派遣相應獨立角色處理。
- REVIEW-002 為未執行的 historical deviation；不得標記為 approved 或 pending gate。PLAN-006、TEST-004 與 REVIEW-003 未完成前，不得建立 audit-correction commit、push 或處理 threads。
- historical workflow deviation：`94b6506` 與 `09043bf` 均在 REVIEW-002 前已建立；不得倒填、宣稱 prior approval、rewrite history 或 force push。後續僅可建立新的 audit-correction commit，且必須在 REVIEW-003 明示 approved 後。

## Human Check

- planning-audit amendment 已由 Plan-Creator 受限記錄；PLAN-006 與 TEST-004 的既有結果已同步，尚待 REVIEW-003 的獨立結果。
- 僅 REVIEW-003 明示 approved 後，才可建立新的 audit-correction commit、push branch 並處理已核可的 PR threads；不得重做、rewrite 或 force push `94b6506`／`09043bf`，亦不得 merge、release 或進入產品 slice。

## Ledger Interpretation

- 本 ledger 的 `status` 與 `validation evidence` 僅記錄追蹤結構與預期證據；不構成 approval、verdict、routing、gate pass 或工作完成宣告。
- 僅 Dispatcher 可依獨立角色的明示結果決定前進、回修、停止或交還 human check。

## Last Updated

2026-09-02 — Plan-Creator：依受限 ledger exception，僅同步既有 evidence：PLAN-005 為 complete、PLAN-006 已由 Plan-Reviewer 明示 approved、TEST-004 已由 Tester 明示 PASS，並將 Current Phase 設為 REVIEW-003 independent review。REVIEW-003、DELIVERY-001 與 HUMAN-001 維持 pending；REVIEW-002 仍為 historical-deviation-not-run，`94b6506` 與 `09043bf` 的既有歷史不變。本次同步不構成 review、approval、verdict、routing 或 delivery authorization；未進行 implementation、測試、Git 或 PR/thread actions。
