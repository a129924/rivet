# HTTP Client Bearer Auth Requester：Step Ledger

## Current Phase

規劃審查（`PR-01` pending）。`PC-01` 僅表示 artifacts 已由 Plan-Creator 建立，不構成 approval。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | Plan-Creator | completed | 建立本 topic 的 requirements、technical spec、plan 與 step artifacts。 | 四份文件使用同一 slug，並一致鎖定 pure `RequestAuthorization`／`BearerAuth` contract、scope、path manifest、test cases 與 workflow gates。 | 四份 `http-client-bearer-auth-requester` planning artifacts。 |
| PR-01 | Plan-Reviewer | pending | 獨立審查四份 planning artifacts 的 scope、public API、ReadOnly／Written manifest、test plan 與 workflow consistency。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；只有 `approved` 可進入 IM-01。 | 尚無 independent Plan-Reviewer verdict。 |
| IM-01 | Implementer | pending | 僅在 PR-01 明示 approved 後，於 feature worktree 的 Written paths 實作 `RequestAuthorization`、`BearerAuth` 與 TC-01 至 TC-03。 | API/signature、pure transformation、case-insensitive replacement、source preservation、existential use 與 path allowlist 符合本 plan；無 execution／failure／GitHub scope drift。 | 尚待 Implementer completion handoff。 |
| TE-01 | Tester | pending | 僅在 IM-01 完成後，獨立執行 TC-01 至 TC-04 與適用 package checks。 | 新增 transformation tests 及完整 `RivetHTTPClient` suite 通過；bare execution 無回歸；失敗如實列為 blocker。 | 尚待 independent Tester evidence。 |
| RV-01 | Reviewer | pending | 僅在 TE-01 完成後，獨立審查 implementation、verification evidence、scope／contract drift 與 ReadOnly preservation。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；只有 `approved` 可進入 DL-01。 | 尚無 independent Reviewer verdict。 |
| DL-01 | Implementer | pending | 僅在 RV-01 明示 approved 且沒有重大問題後，依既有 human authorization 在 feature branch 執行 topic commit、push 與 draft PR 建立。 | 僅包含本 topic approved changes；完成 commit、non-force push 與 draft PR，然後停止於 human review。 | 尚待 delivery evidence。 |
| HC-01 | Human | pending | Draft PR 建立後進行 human review。 | Human 明確要求修正、接受或決定後續處置。 | Draft PR 尚未建立。 |

## Blockers

- 無已知 implementation blocker；目前缺少 PR-01 的獨立 Plan-Reviewer verdict，因此 implementation 不可開始。
- 若 implementation 需要修改任何 ReadOnly path、擴張至 Auth／AuthFlow／Requester execution、token acquisition／provider、GitHub type、typed-throws 或未列 Written path，必須回報 Scope Gap 並停止，不得自行擴張。
- 若 token 需要進入 log、diagnostics、public metadata 或 error payload，停止並交還 human；本 topic 不授權此類 surface。

## Human Check

- Plan-Reviewer、Tester 或 Reviewer 出現 `blocked`、`human-check`、scope drift、contract drift 或 workflow drift 時，停止自動前進並交還 human。
- RV-01 approved 後，既有 human authorization 僅涵蓋本 topic 的 `commit → push → open draft PR`；draft PR 建立即進入 human review boundary。不得自動 merge、release、rebase、force push 或處理未授權 review comments。
- 若 docs writeback 被認為必要，先由 human 確認其是否為已驗證的長期 truth 與其 write scope；本 topic 不預設修改 docs 或 diagrams。

## Last Updated

2026-09-17 — Plan-Creator 已建立四份正式 planning artifacts；等待獨立 Plan-Reviewer 執行 PR-01。
