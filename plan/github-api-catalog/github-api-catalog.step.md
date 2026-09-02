# GitHub API Endpoint Catalog — Step Ledger

## Topic and Current Phase

- Topic: `github-api-catalog`
- Current phase: Human Check 待處理。
- Ledger rule: status 與驗證證據只記錄工作狀態；不構成 approval 或取代 human review。

## Steps

| ID | Status | Owner | Completion Condition | Validation Evidence |
| --- | --- | --- | --- | --- |
| PLAN-001 | complete | Human / Plan-Creator | Human 已確認 catalog plan，四份 topic artifacts 已建立。 | 本 request 的計畫確認與四份 artifacts。 |
| IMPL-001 | complete | Implementer | 僅新增 catalog artifacts 與 `docs/github-api/` 文件。 | `git diff --check` 與 file impact contract。 |
| TEST-001 | complete | Tester | 驗證索引完整性、關鍵 API facts、官方來源與 scope。 | TC-01 至 TC-05 的本地文件檢查。 |
| DELIVERY-001 | complete | Implementer | topic commit、push，並建立以 `dev` 為 base 的 draft PR。 | commit、remote branch 與 draft PR URL。 |
| REVIEW-001 | complete | External Reviewer | 核對 API catalog 與官方文件。 | 回報 thread schema、metadata、taxonomy、auth contract 與 authority boundary 的修正要求。 |
| IMPL-002 | complete | Implementer | 僅修正 REVIEW-001 指出的 catalog 與同 topic artifacts。 | 修正型別、metadata、taxonomy、auth/source rows 與 local/remote viewed boundary。 |
| TEST-002 | complete | Tester | 驗證 TC-01 至 TC-07、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-002 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch。 | 修正 commit 與更新後 PR #7。 |
| HUMAN-001 | pending | Human | 審閱 draft PR 的文件內容與 scope。 | Human review。 |

## Blockers

- 無已知 blocker；Human Check 是唯一未完成邊界。
- 若 GitHub 官方文件與 catalog 任一記錄不一致，以官方文件為準並在 PR 中揭露。

## Human Check

- 確認 catalog 的產品分級、官方校驗結果與未納入實作的範圍。

## Last Updated

2026-09-02 — 建立 topic artifacts 與 API catalog；未修改既有文件或 source code。

2026-09-02 — 依 external reviewer report 修正 GraphQL review thread schema、REST metadata、status taxonomy、每個 operation 的認證／權限與來源、未證實延伸敘述，以及 remote GitHub API data 與 Swift snapshot-local viewed state 的界線；未修改架構文件或 source code。
