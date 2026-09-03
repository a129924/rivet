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
| REVIEW-005 | complete | External Reviewer | 檢查 Search 上限、Viewed taxonomy、notification success output 與 review 限制。 | 指出 Search 1,000 筆上限、Viewed query 分類、notification PATCH `205`，以及未附直接官方來源的作者 review 限制。 |
| IMPL-007 | complete | Implementer | 僅修正 REVIEW-005 中有直接官方或既有 taxonomy 依據的 metadata。 | 補 Search 上限、Viewed read/write 分類、`205 Reset Content`／空 body 與 TC-12；不新增未有直接官方來源的作者限制。 |
| TEST-007 | complete | Tester | 驗證 TC-12、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-007 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-005 threads。 | 修正 commit、更新後 PR #7 與 resolved thread 狀態。 |
| REVIEW-006 | complete | External Reviewer | 檢查 GraphQL query locator、Checks、discussion composition、last-seen identity 與寫入 operation contract。 | 指出 10 項問題；其中 notifications OAuth 與 PENDING visibility 兩項無法由目前直接官方來源支持，其餘 8 項有官方依據。 |
| IMPL-008 | complete | Implementer | 僅修正 REVIEW-006 中有官方依據的 catalog 與同 topic artifacts。 | 補 PR locator、Checks、last-seen identity、merge output/permission、review `commit_id`、thread viewer gate 與不重複 inline composition。 |
| TEST-008 | complete | Tester | 驗證 TC-13、TC-14、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-008 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-006 threads。 | `6ffa142`、更新後 PR #7 與 10 則 resolved thread。 |
| REVIEW-007 | complete | External Reviewer | 檢查 inline review input、outdated position、checks union、nested pagination、notification polling 與 merge method gate。 | 指出六項均有直接 GitHub 官方 REST／GraphQL 來源支持的 operation contract 缺口。 |
| IMPL-009 | complete | Implementer | 僅修正 REVIEW-007 指出的 catalog 與同 topic artifacts。 | 補齊六項 operation contract，且不變更架構文件或 BC 責任。 |
| TEST-009 | complete | Tester | 驗證 TC-15、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-009 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-007 threads。 | `789bb98`、更新後 PR #7 與 6 則 resolved thread。 |
| REVIEW-008 | complete | External Reviewer | 檢查 submit review response、thread comment output／多行起始 side，以及 Checks cursor traversal。 | 指出四項均有直接 GitHub 官方 REST／GraphQL 來源支持的 operation contract 缺口。 |
| IMPL-010 | complete | Implementer | 僅修正 REVIEW-008 指出的 catalog 與同 topic artifacts。 | 補 200 review response、thread content／start side 與 Checks cursor traversal。 |
| TEST-010 | complete | Tester | 驗證 TC-16、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-010 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-008 threads。 | `faaf1cf`、更新後 PR #7 與 4 則 resolved thread。 |
| REVIEW-009 | complete | External Reviewer | 檢查 changed-files pagination、REST inline fallback output、Search query key 與 viewed mutation source coverage。 | 指出四項均有直接 GitHub 官方 REST／GraphQL 來源支持的 operation contract 缺口。 |
| IMPL-011 | complete | Implementer | 僅修正 REVIEW-009 指出的 catalog 與同 topic artifacts。 | 補 files traversal、inline fallback display fields、Search `q` 與 viewed mutation payload sources。 |
| TEST-011 | complete | Tester | 驗證 TC-17、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-011 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-009 threads。 | `197750d`、更新後 PR #7 與 4 則 resolved thread。 |
| REVIEW-010 | complete | External Reviewer | 檢查多行 review 條件輸入、thread resolution payload source 與 Search 後續分頁。 | 指出三項均有直接 GitHub 官方 REST／GraphQL 來源支持的 operation contract 缺口。 |
| IMPL-012 | complete | Implementer | 僅修正 REVIEW-010 指出的 catalog 與同 topic artifacts。 | 補多行條件必填、thread resolution payload sources 與 Search page／Link traversal。 |
| TEST-012 | complete | Tester | 驗證 TC-18、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-012 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-010 threads。 | `ab4d92e`、更新後 PR #7 與 3 則 resolved thread。 |
| REVIEW-011 | complete | External Reviewer | 檢查 diff failure、checks nullability、thread target kind 與 inline review positioning。 | 指出三項直接官方 contract 缺口，以及一項只可確認 HTTP status、不可確認原因的 diff failure claim。 |
| IMPL-013 | complete | Implementer | 僅修正 REVIEW-011 中由官方來源支持的 catalog 與同 topic artifacts。 | 補 406 status、nullable checks／thread target、line-based preference，且不推論 406 成因、fallback 或 REST `subject_type` output。 |
| TEST-013 | complete | Tester | 驗證 TC-19、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-013 | complete | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-011 threads。 | `f038e19`、更新後 PR #7 與 4 則 resolved thread。 |
| REVIEW-012 | complete | External Reviewer | 檢查 review decision 與 changed-file response 的 optional contract。 | 指出 `reviewDecision` nullable 與 REST `patch` 未列於 required set。 |
| IMPL-014 | complete | Implementer | 僅修正 REVIEW-012 中由 GitHub GraphQL schema 與官方 REST OpenAPI 直接支持的 catalog 與同 topic artifacts。 | 補 `reviewDecision` nullable 與 `patch` 可能缺席；不推論兩者的成因。 |
| TEST-014 | complete | Tester | 驗證 TC-20、Markdown links、diff 與完整 pre-commit。 | 本次修正的驗證結果。 |
| DELIVERY-014 | in progress | Implementer | 建立單一修正 commit 並推送既有 feature branch，逐則回覆並 resolve REVIEW-012 threads。 | 待 commit、push 與 GitHub thread 狀態。 |
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

2026-09-03 — 依 REVIEW-005 補 Search 1,000 筆上限、Files Viewed read/write 分類與 notification PATCH 成功輸出；作者 review 限制因目前沒有直接官方來源而不列入 catalog；未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-006 補 GraphQL PR 定位、Checks、last-seen identity、merge output／權限、review `commit_id`、thread viewer gates 與 inline content source；notifications OAuth 與 PENDING visibility 因直接官方來源分別相反或不足而只回覆說明；未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-007 補 inline review 定位、outdated 原始位置、checks union output、nested thread comments 分頁、notification conditional polling 與 merge method gate；未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-008 補 submit review 成功 response、thread comment content／多行起始 side，以及 Checks cursor traversal；未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-009 補 changed-files cursor traversal、REST inline fallback 作者／時間／連結、Issues Search 必填 `q` 與 viewed mutation payload source；未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-010 補多行 review comment 條件必填、thread resolution payload source 與 Issues Search page／Link traversal；未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-011 補 unified diff `406`、checks nullability、thread target kind 與 line-based review positioning；不推論 406 成因／fallback 或未由 list response reference 支持的 REST `subject_type` output，未修改架構文件或 source code。

2026-09-03 — 依 REVIEW-012 補 `reviewDecision` nullable 與 REST changed-file `patch` 可能缺席的 contract；後者以 GitHub REST OpenAPI `diff-entry` required set 驗證，未推論任何缺席成因，未修改架構文件或 source code。
