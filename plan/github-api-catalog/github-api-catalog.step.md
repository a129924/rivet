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
| IMPL-002 | complete | Implementer | 僅修正 REVIEW-001 指出的 catalog 與同 topic artifacts。 | 修正型別、metadata、taxonomy、auth/source rows 與未鎖定 authority claim。 |
| TEST-002 | complete | Tester | 驗證 TC-01 至 TC-08、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-002 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch。 | 修正 commit 與更新後 PR #7。 |
| REVIEW-002 | complete | External Reviewer | 檢查 REVIEW-001 remediation 的 product scope 與架構依據。 | 指出 `author:@me` MVP drift 與無依據 Swift viewed claim。 |
| IMPL-003 | complete | Implementer | 僅移除 REVIEW-002 指出的 catalog scope 與未鎖定推論。 | 移除 `author:@me`、Swift snapshot-local claim，並同步 artifacts 與 TC-08。 |
| TEST-003 | complete | Tester | 驗證 Inbox scope、未鎖定 authority claim、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-003 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch。 | 修正 commit 與更新後 PR #7。 |
| REVIEW-003 | complete | External Reviewer | 檢查 REST pagination metadata 與 Notifications operation inputs。 | 指出三處錯誤的連字號 pagination 名稱，以及 `GET /notifications` 漏列 query／分頁 metadata。 |
| IMPL-004 | complete | Implementer | 僅修正 REVIEW-003 指出的 catalog metadata，並同步本 topic artifacts。 | REST 正式 query 名稱、Notifications query／上限與 TC-09。 |
| TEST-004 | complete | Tester | 驗證 TC-09、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-004 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-003 threads。 | 修正 commit、更新後 PR #7 與 resolved thread 狀態。 |
| REVIEW-004 | complete | External Reviewer | 檢查 REST operation contract 與 capability taxonomy。 | 指出 notification scopes、review body 條件、`@me` 認證、兩個 list 分頁，以及兩項 taxonomy 意見。 |
| IMPL-005 | complete | Implementer | 僅修正 REVIEW-004 中有官方依據且不改變既有 taxonomy／架構的 metadata。 | 補 notification scopes、conditional body、`@me` token、inline/review 分頁與 TC-10。 |
| TEST-005 | complete | Tester | 驗證 TC-10、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-005 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve 已處理 REVIEW-004 threads。 | 修正 commit、更新後 PR #7 與 resolved thread 狀態。 |
| DECISION-001 | complete | Human | 授權以「後續唯讀」區分非 MVP 讀取與延後寫入。 | 本 request 的 `Execution Authorized`。 |
| IMPL-006 | complete | Implementer | 僅在本 topic 的 catalog 與 artifacts 新增「後續唯讀」taxonomy。 | repository PR list、`GET /notifications` 與 Capability Index 均使用正確狀態。 |
| TEST-006 | complete | Tester | 驗證 TC-11、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-006 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，回覆並 resolve REVIEW-004 最後 thread。 | 修正 commit、更新後 PR #7 與 resolved thread 狀態。 |
| HUMAN-001 | pending | Human | 審閱 draft PR 的文件內容與 scope。 | Human review。 |

## Blockers

- 無已知 blocker；Human Check 是唯一未完成邊界。
- 若 GitHub 官方文件與 catalog 任一記錄不一致，以官方文件為準並在 PR 中揭露。

## Human Check

- 確認 catalog 的產品分級、官方校驗結果與未納入實作的範圍。

## Last Updated

2026-09-02 — 建立 topic artifacts 與 API catalog；未修改既有文件或 source code。

2026-09-02 — 依 external reviewer report 修正 GraphQL review thread schema、REST metadata、status taxonomy、每個 operation 的認證／權限與來源，以及未證實延伸敘述；未修改架構文件或 source code。

2026-09-02 — 依後續 reviewer feedback 移除不屬待 review MVP 集合的 `author:@me` catalog entry，並移除無既有架構依據的 Swift snapshot-local viewed claim；未修改架構文件或 source code。

2026-09-02 — 依 REVIEW-003 修正 REST pagination query 名稱，補齊 `GET /notifications` 的 query、分頁上限與 TC-09；未修改架構文件或 source code。

2026-09-02 — 依 REVIEW-004 補齊 notification scopes、review conditional body、`@me` token、inline comment 與 review summary 分頁；taxonomy 與 repository browse scope 的衝突留待 human decision，未修改架構文件或 source code。

2026-09-02 — Human 授權新增「後續唯讀」taxonomy，將 repository PR list 與 `GET /notifications` 與延後寫入明確區分；未修改架構文件或 source code。
