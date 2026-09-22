# HTTP Client Sync／Async Request Authorization Contracts：Step Ledger

## Current Phase

human-review。HC-01、PL-01、PR-01、IM-01、TE-01、TE-02、RV-02 與 DL-01 已完成；RV-01 的唯一 ledger-truthfulness finding 已由 Plan-Creator correction 處理並完成 fresh review。PR #38 已 Ready for review，等待 Human review。

## Locked Decisions

- `AsyncRequestAuthorization` 是 public `Sendable` protocol，signature 固定為 `func applying(to request: HTTPRequest) async throws -> HTTPRequest`，failure surface 是一般 `Error`。
- 既有同步 `RequestAuthorization` 完全不變。
- 兩個 contract 都是 BC 外、GitHub-unaware、caller-applied pure transformation；不是 request execution。
- Written／Modify／Deleted／ReadOnly allowlist 與 TC-01 至 TC-08 已鎖定。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| HC-01 | Human | completed | 在對話中明示「可實現」作為 pre-write authorization。 | Human authorization 已收到；此前沒有 repository write。 | Human 對話授權。 |
| PL-01 | Plan-Creator | completed | 建立同 slug 的 requirements、technical spec、plan 與 step artifacts。 | 四份 artifact 一致記錄 locked API、scope、allowlist、TC-01 至 TC-08 與 gates。 | 本四份 formal planning artifacts。 |
| PR-01 | Plan-Reviewer | approved | 獨立審查四份 artifacts 的 scope、contract、workflow 與 implementation readiness。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；只有 `approved` 可進入 IM-01。 | Plan-Reviewer verdict：`approved`。 |
| IM-01 | Implementer | completed | 僅在 PR-01 `approved` 後，實作已鎖定 protocol、tests、architecture writeback 與 canvas rebuild。 | 寫入僅限 Written／Modify allowlist；ReadOnly／Deleted／Non-Goal 無 drift。 | 新增 `AsyncRequestAuthorization`、兩個 private-fake existential contract test files；最小更新 architecture README、canvas `scene.js`，並依既有 workflow rebuild `index.html`。 |
| TE-01 | Tester | approved | 僅在 IM-01 完成後，獨立執行 TC-01 至 TC-08。 | 如實回報 checks 結果；任何失敗列為 blocker。 | focused sync／async tests 1+2、standalone package 72 tests、root 64 tests、format、lint、`git diff --check` 與 canvas checks 均 pass。Tester 已記錄 cold-cache environment note 與 unmodified baseline warning；兩者不改寫為本 topic failure 或已修正。 |
| RV-01 | Reviewer | needs-rework | 僅在 TE-01 完成後，獨立審查 implementation、evidence、scope、contract 與 workflow drift。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`。 | Reviewer verdict：`needs-rework`；唯一 finding 是本 ledger stale，未反映 PR-01、IM-01、TE-01 evidence。未宣稱 Reviewer approved 或 delivery completed。 |
| TE-02 | Tester | approved | 在 Plan-Creator ledger correction 後，獨立重新驗證 aggregate delta、locked boundary 與 TC-01 至 TC-08 evidence。 | 如實回報 checks 結果；任何失敗列為 blocker。 | Tester fresh re-verification verdict：`approved`。aggregate delta 為 10 個 allowlist paths，ReadOnly paths unchanged；focused sync 1、async 2；standalone build 與 72 tests／11 suites；root 64 tests／10 suites；SwiftFormat 與 SwiftLint strict 均 0 violations；`git diff --check` 通過；canvas 為 5 bands／17 boxes／25 edges、0 errors／0 warnings，accessibility verifier 通過。 |
| RV-02 | Reviewer | approved | 在 Plan-Creator ledger correction 與 TE-02 後，獨立重新審查 ledger truthfulness、implementation scope、contract 與 verification evidence。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`。 | Fresh independent Reviewer verdict：`approved`。aggregate delta 為 10 個 allowlist paths，ReadOnly unchanged；exact async API 與 sync compatibility 維持 locked contract；external existential tests 與 sentinel equality evidence 成立；canvas 為 5 bands／17 boxes／25 edges、0 errors／0 warnings、byte-identical 且 accessibility verifier 通過；無 scope、contract 或 workflow drift。 |
| DL-01 | Implementer | completed | 在 Human 確認 exact commit message 後，依 conditional delivery authority 執行 topic commit、push、open draft PR，並交還 Human review。 | 僅包含已核定 topic 變更；PR Ready for review 後不得自動 merge、release 或繼續整合。 | Human 已確認 exact commit message；commit `5cbd41304459b4256fe341e9c3b915270ea50d20` 已 non-force push 至 feature branch；PR #38 已建立且 Ready for review（`isDraft: false`）。 |

## Routing and Blockers

- PR-01 回報 `needs-rework` 時，只交回 Plan-Creator 修正四份 planning artifacts；修正後必須重新執行 fresh PR-01，未通過前不得進入 IM-01。
- TE-01 回報 `needs-rework`，或 RV-01／RV-02 指出 code、scope 或 contract finding 時，交獨立 Implementer 做 bounded repair；完成後必須重新執行 TE-01 與 fresh Reviewer。
- RV-01 本次唯一的 planning-artifact ledger truthfulness finding 只交由 Plan-Creator 修正；完成後進入 fresh independent RV-02，不得觸及 implementation。
- 任一 gate 回報 `blocked` 或 `human-check` 時，立即停止並交還 Human。
- 若修正需要擴張 error semantics、execution ownership、concrete conformer、adapter/interoperability、GitHub 或 credential scope，視為 `human-check`，不得自行擴張。

## Human Check

- HC-01 已完成，授權本 topic planning artifacts 與 bounded implementation。
- Human latest instruction 的 conditional delivery 已完成：topic commit 已 non-force push，PR #38 已 Ready for review（`isDraft: false`）。
- PR #38 的 Human review 是目前 boundary；不得將 review、merge、release 或後續整合記為完成，亦不得自動執行。

## Last Updated

2026-09-21（DL-01 completed：commit `5cbd41304459b4256fe341e9c3b915270ea50d20` non-force pushed；PR #38 Ready for review，等待 Human review）
