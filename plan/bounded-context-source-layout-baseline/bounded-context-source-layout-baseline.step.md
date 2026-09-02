# 暫定 Bounded Context Source Layout Baseline：執行 Ledger

## Topic

`bounded-context-source-layout-baseline`

## Current Phase

REVIEW-007 independent review。PLAN-014 已由 Plan-Reviewer 明示 `approved`，TEST-008 已由 Tester 明示 PASS；第五次 planning-audit amendment 僅受 Human 明示授權範圍拘束。尚待 REVIEW-007 獨立 verdict。不得倒填、rewrite history、force push 或宣稱 prior approval。

## Locked Scope

- 僅可建立 `Sources/BoundedContexts/PRInbox/.gitkeep`、`Sources/BoundedContexts/PRReader/.gitkeep` 與 `Sources/BoundedContexts/GitHubIntegration/.gitkeep`；三檔必須空白。
- 不得將此 layout 解讀為 Swift target、module、dependency、interface、contract 或 infrastructure 決策。
- 不得新增 `PresentationSession` 或其他未確認 Bounded Context，亦不得新增 Swift source、test、contract 或既有檔案修改；本次 human 明示授權、僅限加上 `--recursive` 的 `scripts/check-swift-format.sh` 修正除外。
- Human 僅授權為既有 pre-commit gate 修正 `scripts/check-swift-format.sh` 的目錄 lint 為 `--recursive`，以及在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile` 準備 ignored local dependency；不得提交 lockfile 或 `node_modules/`。
- Human 另授權三份既有 BC 文件各加入一行對應的暫定 source location baseline，並明示不代表 target、module、dependency 或 contract；不得變更 BC responsibility、Map、圖或既有 architecture/path decision。
- C thread 的 PR Inbox-only 要求與 Human 已鎖定的三 BC decision 衝突，為 non-actionable finding；不得以此調整 architecture 或 source paths。
- Human 第三次 audit authorization 僅允許四份 topic artifacts 如實記錄 `768f6be` 早於未執行的 REVIEW-004，並建立 REVIEW-005 → DELIVERY-003 → HUMAN-003；不得修改其他路徑、重開三 BC／source path／module／contract，或 backfill、rewrite history、force push。
- Human 第四次 audit authorization 僅允許四份 topic artifacts 如實記錄 `1b44fd0` 早於未執行的 REVIEW-005，並建立 PLAN-011 → PLAN-012 → TEST-007 → REVIEW-006 → DELIVERY-004 → HUMAN-004；不得修改其他路徑、重開三 BC／source path／module／contract，或 backfill、rewrite history、force push。
- Human 第五次 audit authorization 僅允許四份 topic artifacts 如實記錄 `a1e5b4a` 早於未執行的 REVIEW-006，並建立 PLAN-013 → PLAN-014 → TEST-008 → REVIEW-007 → DELIVERY-005 → HUMAN-005；不得修改其他路徑、重開三 BC／source path／module／contract，或 backfill、rewrite history、force push。

## Ledger

| ID | status | verdict | owner role | completion condition | validation evidence |
| --- | --- | --- | --- | --- | --- |
| PLAN-001 | complete | — | Plan-Creator | 四份 topic planning artifacts 已建立，並記錄已鎖定範圍與 human boundary。 | 四份 artifacts 位於既定 `analysis/` 與 `plan/` 路徑。 |
| PLAN-002 | complete | approved | Plan-Reviewer | 獨立檢查初始 planning artifacts、架構邊界、scope 及 ledger schema。 | Plan-Reviewer 已明示 `approved`。 |
| PLAN-003 | complete | approved | Plan-Reviewer | 獨立檢查 pre-commit gate scope amendment。 | Plan-Reviewer 已明示 `approved`。 |
| PLAN-004 | complete | approved | Plan-Reviewer | 獨立檢查 PR review remediation amendment。 | Plan-Reviewer 已明示 `approved`。 |
| PLAN-005 | complete | — | Plan-Creator | 記錄既授權 BC-document remediation、historical audit 與 delivery consistency。 | Amendment 僅限既有授權範圍。 |
| PLAN-006 | complete | approved | Plan-Reviewer | 獨立審查 PLAN-005 的 REVIEW-002 historical deviation 與 REVIEW-003 boundary。 | Plan-Reviewer 已明示 `approved`。 |
| IMPL-001 | complete | — | Implementer | 僅建立三個指定且空白的 `.gitkeep`。 | 指定三個 `.gitkeep` 已建立。 |
| IMPL-002 | complete | — | Implementer | 僅修正 formatter 呼叫並準備 frozen-lockfile local dependency。 | 僅加入 `--recursive`；指定 checks 已通過。 |
| IMPL-003 | complete | — | Implementer | 僅在三份 BC 文件各加入一行對應 baseline。 | 三份文件各有一行受限 baseline。 |
| TEST-001 | complete | — | Tester | 檢查三個 `.gitkeep`、目錄集合及未授權檔案。 | Tester 明示 PASS。 |
| REVIEW-001 | historical-deviation-needs-rework | needs-rework | Reviewer | 原定於 TEST-001 後獨立判定 workflow drift。 | `94b6506` 早於此 gate；Reviewer 歷史上明示 `needs-rework`，不得宣稱 approved。 |
| TEST-002 | complete | — | Tester | 檢查 formatter、renderer check、pre-commit、staged scope 與 ignored dependency。 | Tester 明示 PASS：8 個允許 paths、lockfiles 未變更、`node_modules/` ignored、pre-commit 通過。 |
| TEST-003 | complete | — | Tester | 檢查三份 BC 文件的受限 baseline 與 remediation scope。 | Tester 明示 PASS：無 scope、contract 或 tracked-path drift。 |
| REVIEW-002 | historical-deviation-not-run | — | Reviewer | 原定於 TEST-003 後獨立判定 PR review remediation。 | `09043bf` 早於此 gate；未執行，不是 approval 或 delivery authorization。 |
| TEST-004 | complete | — | Tester | 驗證第一次 planning-audit amendment 一致性。 | Tester 明示 PASS；PASS 不構成 verdict。 |
| REVIEW-003 | historical-deviation-not-run | — | Reviewer | 原定於 TEST-004 後獨立判定第一次 audit-correction delivery。 | `ed2bbcf` 早於此 gate；未執行，不是 approval 或 delivery authorization。 |
| DELIVERY-001 | historical-deviation-not-run | — | Implementer | 原定於 REVIEW-003 `approved` 後建立第一個 audit-correction delivery。 | 先前 gate 未執行；不得將既有 commit 倒填為此 delivery。 |
| HUMAN-001 | historical-superseded | — | Human | 原定於 DELIVERY-001 後交還 human review。 | 由 HUMAN-002 取代；不構成既有 delivery 已獲 human approval。 |
| PLAN-007 | complete | — | Plan-Creator | 依第二次 human authorization，僅修訂四份 artifacts，記錄三個 historical deviations、獨立 verdict 與新 gate。 | 本次 amendment 僅觸及四份 artifacts；不構成 approval。 |
| PLAN-008 | complete | approved | Plan-Reviewer | 獨立審查 PLAN-007 是否符合第二次 audit amendment 的受限 scope 與歷史記錄。 | Plan-Reviewer 已明示 `approved`。 |
| TEST-005 | complete | — | Tester | PLAN-008 可前進後，獨立驗證四份 artifacts 的 historical audit、verdict schema 與 gate consistency。 | Tester 明示 PASS；PASS 不構成 verdict。 |
| REVIEW-004 | historical-deviation-not-run | — | Reviewer | 原定於 TEST-005 後，獨立判定第二次 amendment 與 DELIVERY-002 範圍是否有 scope、contract 或 workflow drift。 | `768f6be` 早於此 gate；未執行，不是 approval 或 delivery authorization。 |
| DELIVERY-002 | historical-superseded | — | Implementer | 原定於 REVIEW-004 `approved` 後，僅以四份 artifacts 建立單一 commit、push 並處理已核可 threads。 | REVIEW-004 未執行；不得將 `768f6be` 倒填為此 delivery。 |
| HUMAN-002 | historical-superseded | — | Human | 原定於 DELIVERY-002 後，PR 交還 human review。 | 由 HUMAN-003 取代；不構成既有 delivery 已獲 human approval。 |
| PLAN-009 | complete | — | Plan-Creator | 依第三次 human authorization，僅修訂四份 artifacts，記錄 `768f6be` 的 REVIEW-004 historical deviation 與新 gate。 | 本次 amendment 僅觸及四份 artifacts；不構成 approval。 |
| PLAN-010 | complete | approved | Plan-Reviewer | 獨立審查 PLAN-009 是否符合第三次 audit amendment 的受限 scope 與歷史記錄。 | Plan-Reviewer 已明示 `approved`。 |
| TEST-006 | complete | — | Tester | PLAN-010 可前進後，獨立驗證四份 artifacts 的 historical audit、verdict schema 與 gate consistency。 | Tester 明示 PASS；PASS 不構成 verdict。 |
| REVIEW-005 | historical-deviation-not-run | — | Reviewer | 原定於 TEST-006 後，獨立判定第三次 amendment 與 DELIVERY-003 範圍是否有 scope、contract 或 workflow drift。 | `1b44fd0` 早於此 gate；未執行，不是 approval 或 delivery authorization。 |
| DELIVERY-003 | historical-superseded | — | Implementer | 原定於 REVIEW-005 `approved` 後，僅以四份 artifacts 建立單一 commit、push 並處理已核可 threads。 | REVIEW-005 未執行；不得將 `1b44fd0` 倒填為此 delivery。 |
| HUMAN-003 | historical-superseded | — | Human | 原定於 DELIVERY-003 後，PR 交還 human review。 | 由 HUMAN-004 取代；不構成既有 delivery 已獲 human approval。 |
| PLAN-011 | complete | — | Plan-Creator | 依第四次 human authorization，僅修訂四份 artifacts，記錄 `1b44fd0` 的 REVIEW-005 historical deviation 與新 flow。 | 本次 amendment 僅觸及四份 artifacts；不構成 approval。 |
| PLAN-012 | complete | approved | Plan-Reviewer | 獨立審查 PLAN-011 是否符合第四次 audit amendment 的受限 scope 與歷史記錄。 | Plan-Reviewer 已明示 `approved`。 |
| TEST-007 | complete | — | Tester | PLAN-012 明示 `approved` 後，獨立驗證四份 artifacts 的 historical audit、verdict schema 與 gate consistency。 | Tester 明示 PASS；PASS 不構成 verdict。 |
| REVIEW-006 | historical-deviation-not-run | — | Reviewer | 原定於 TEST-007 後，獨立判定第四次 amendment 與 DELIVERY-004 範圍是否有 scope、contract 或 workflow drift。 | `a1e5b4a` 早於此 gate；未執行，不是 approval 或 delivery authorization。 |
| DELIVERY-004 | historical-superseded | — | Implementer | 原定於 REVIEW-006 `approved` 後，僅以四份 artifacts 建立單一 commit、push 並處理已核可 threads。 | REVIEW-006 未執行；不得將 `a1e5b4a` 倒填為此 delivery。 |
| HUMAN-004 | historical-superseded | — | Human | 原定於 DELIVERY-004 後，PR 交還 human review。 | 由 HUMAN-005 取代；不構成既有 delivery 已獲 human approval。 |
| PLAN-013 | complete | — | Plan-Creator | 依第五次 human authorization，僅修訂四份 artifacts，記錄 `a1e5b4a` 的 REVIEW-006 historical deviation 與新 flow。 | 本次 amendment 僅觸及四份 artifacts；不構成 approval。 |
| PLAN-014 | complete | approved | Plan-Reviewer | 獨立審查 PLAN-013 是否符合第五次 audit amendment 的受限 scope 與歷史記錄。 | Plan-Reviewer 已明示 `approved`。 |
| TEST-008 | complete | — | Tester | PLAN-014 明示 `approved` 後，獨立驗證四份 artifacts 的 historical audit、verdict schema 與 gate consistency。 | Tester 明示 PASS；PASS 不構成 verdict。 |
| REVIEW-007 | pending | — | Reviewer | TEST-008 後，獨立判定第五次 amendment 與 DELIVERY-005 範圍是否有 scope、contract 或 workflow drift。 | 僅明示 `approved` 可進入 DELIVERY-005。 |
| DELIVERY-005 | pending | — | Implementer | REVIEW-007 明示 `approved` 後，僅以四份 artifacts 建立單一 commit、push 並處理已核可 threads。 | 不得改寫既有 commits 或新增其他 tracked path。 |
| HUMAN-005 | pending | — | Human | DELIVERY-005 後，PR 交還 human review。 | 尚待 Human review；不得 merge、release 或進入產品 slice。 |

## Blockers

- Human 已明示授權本次 pre-commit gate scope expansion、三份 BC 文件 remediation，以及五次 planning-audit amendment；這些授權不構成 REVIEW-007 approval，亦不構成 DELIVERY-005 authorization。
- REVIEW-001 的 `needs-rework` 為歷史 evidence；不得將其重寫為 approved 或完成。
- 若 formatter 修正需修改 `scripts/check-swift-format.sh` 以外的 tracked path，或 dependency install 改變 lockfile／產生可追蹤檔案，立即停止並交回 Dispatcher。
- 若要求寫入未列入本 topic 的路徑、修改既有檔案、刪除內容、新增 BC 或 Swift contract，立即停止並交回 Dispatcher。
- 若發現 scope、contract 或 workflow drift，停止前進；由 Dispatcher 派遣相應獨立角色處理。
- REVIEW-002、REVIEW-003、REVIEW-004、REVIEW-005 與 REVIEW-006 均為未執行的 historical deviations；不得標記為 approved 或 pending gate。REVIEW-007 明示 `approved` 前，不得建立 DELIVERY-005、push 或處理 threads。
- historical workflow deviations：`94b6506` 早於 REVIEW-001（歷史 verdict `needs-rework`）；`09043bf`、`ed2bbcf`、`768f6be`、`1b44fd0` 與 `a1e5b4a` 分別早於未執行的 REVIEW-002、REVIEW-003、REVIEW-004、REVIEW-005 與 REVIEW-006。不得倒填、宣稱 prior approval、rewrite history 或 force push；後續僅可在 REVIEW-007 明示 `approved` 後建立 DELIVERY-005。

## Human Check

- PLAN-014 已明示 `approved`，TEST-008 已明示 PASS；尚待 REVIEW-007 的獨立 verdict。
- 僅 REVIEW-007 明示 `approved` 後，才可建立 DELIVERY-005、push branch 並處理已核可的 PR threads；不得重做、rewrite 或 force push `94b6506`／`09043bf`／`ed2bbcf`／`768f6be`／`1b44fd0`／`a1e5b4a`，亦不得 merge、release 或進入產品 slice。

## Ledger Interpretation

- 本 ledger 的 `status` 與 `validation evidence` 僅記錄追蹤結構與預期證據；不構成 approval、verdict、routing、gate pass 或工作完成宣告。`verdict` 僅可記錄獨立角色明示的 `approved`、`needs-rework`、`blocked` 或 `human-check`；未執行與非-verdict steps 均為 `—`，Tester PASS 不得填入。
- 僅 Dispatcher 可依獨立角色的明示結果決定前進、回修、停止或交還 human check。

## Last Updated

2026-09-02 — Plan-Creator：依第二次 Human 明示授權，僅修訂四份 topic artifacts。新增獨立 `verdict` 欄；如實記錄 `94b6506` 早於 REVIEW-001 且其歷史 verdict 為 `needs-rework`、`09043bf` 早於未執行 REVIEW-002、`ed2bbcf` 早於未執行 REVIEW-003；並將 REVIEW-003 與 DELIVERY-001 標為 historical-deviation-not-run。新增 PLAN-007、PLAN-008、TEST-005、REVIEW-004、DELIVERY-002、HUMAN-002，Current Phase 設為 PLAN-008。未進行 implementation、測試、Git 或 PR/thread actions；本次同步不構成 approval、verdict、routing 或 delivery authorization。

2026-09-02 — Plan-Creator：僅同步既有獨立結果：PLAN-008 為 Plan-Reviewer 明示 `approved`，TEST-005 為 Tester 明示 PASS。Current Phase 更新為 REVIEW-004；REVIEW-004、DELIVERY-002 與 HUMAN-002 維持 pending。未變更 scope、其他 artifacts、Git 或 PR/thread state；Tester PASS 不構成 verdict。

2026-09-02 — Plan-Creator：依第三次 Human 明示授權，僅修訂四份 topic artifacts。如實記錄 `768f6be` 早於未執行 REVIEW-004；將 REVIEW-004 標為 `historical-deviation-not-run`，並將未取得 gate authorization 的 DELIVERY-002 與 HUMAN-002 標為 historical-superseded，不將 `768f6be` 倒填為 DELIVERY-002。新增 PLAN-009、PLAN-010、TEST-006、REVIEW-005、DELIVERY-003、HUMAN-003，Current Phase 設為 PLAN-010。未進行 implementation、測試、Git 或 PR/thread actions；本次同步不構成 approval、verdict、routing 或 delivery authorization。

2026-09-02 — Plan-Creator：僅同步既有獨立結果：PLAN-010 為 Plan-Reviewer 明示 `approved`，TEST-006 為 Tester 明示 PASS。Current Phase 更新為 REVIEW-005；REVIEW-005、DELIVERY-003 與 HUMAN-003 維持 pending。未變更 scope、其他 artifacts、Git 或 PR/thread state；Tester PASS 不構成 verdict，且未回填任何 verdict。

2026-09-02 — Plan-Creator：依第四次 Human 明示授權，僅修訂四份 topic artifacts。如實記錄 `1b44fd0` 早於未執行 REVIEW-005；將 REVIEW-005 標為 `historical-deviation-not-run`，並將未取得 gate authorization 的 DELIVERY-003 與 HUMAN-003 標為 historical-superseded，不將 `1b44fd0` 倒填為 DELIVERY-003。新增 PLAN-011、PLAN-012、TEST-007、REVIEW-006、DELIVERY-004、HUMAN-004，Current Phase 設為 PLAN-012。未進行 implementation、測試、Git 或 PR/thread actions；本次同步不構成 approval、verdict、routing 或 delivery authorization。

2026-09-02 — Plan-Creator：僅同步既有獨立結果：PLAN-012 為 Plan-Reviewer 明示 `approved`，TEST-007 為 Tester 明示 PASS。Current Phase 更新為 REVIEW-006；REVIEW-006、DELIVERY-004 與 HUMAN-004 維持 pending。未變更 scope、其他 artifacts、Git 或 PR/thread state；Tester PASS 不構成 verdict，且未回填任何 verdict。

2026-09-02 — Plan-Creator：依第五次 Human 明示授權，僅修訂四份 topic artifacts。如實記錄 `a1e5b4a` 早於未執行 REVIEW-006；將 REVIEW-006 標為 `historical-deviation-not-run`，並將未取得 gate authorization 的 DELIVERY-004 與 HUMAN-004 標為 historical-superseded，不將 `a1e5b4a` 倒填為 DELIVERY-004。新增 PLAN-013、PLAN-014、TEST-008、REVIEW-007、DELIVERY-005、HUMAN-005，Current Phase 設為 PLAN-014。未進行 implementation、測試、Git 或 PR/thread actions；本次同步不構成 approval、verdict、routing 或 delivery authorization。

2026-09-02 — Plan-Creator：僅同步既有獨立結果：PLAN-014 為 Plan-Reviewer 明示 `approved`，TEST-008 為 Tester 明示 PASS。Current Phase 更新為 REVIEW-007；REVIEW-007、DELIVERY-005 與 HUMAN-005 維持 pending。未變更 scope、其他 artifacts、Git 或 PR/thread state；Tester PASS 不構成 verdict，且未回填任何 verdict。
