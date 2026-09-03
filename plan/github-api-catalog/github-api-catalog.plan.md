# GitHub API Endpoint Catalog — Implementation Plan

## Goal

新增已官方校驗、按 endpoint family 分檔的 GitHub PR API catalog，供後續 implementation topic 參考。

## Non-Goal

不建立產品行為、API client、資料模型、OAuth、SQLite、圖或 BC contract；不改變既有文件。

## In-Scope

- 建立四份正式 topic artifacts。
- 建立 `docs/github-api/` 索引及 REST、GraphQL、notification/local-state 分拆文件。
- 為每個 capability 提供官方來源、產品狀態及可實作所需的 API metadata。

## Out-Of-Scope

- GitHub Enterprise、多帳號、同步與所有 GitHub 寫入能力的實作。
- 使用 `author:@me` 的使用者自建 PR 瀏覽；它不屬目前待 review MVP 集合。
- 對 `docs/architecture/`、既有 BC 文件、產品規範或 source code 的變更。

## ReadOnly

- `README.md`、`docs/design-principles.md`、`docs/product.md`
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/`
- GitHub 官方 REST、GraphQL、Search 與 Notifications 文件

## Written

- `analysis/github-api-catalog/requirements.md`
- `analysis/github-api-catalog/technical-spec.md`
- `plan/github-api-catalog/github-api-catalog.plan.md`
- `plan/github-api-catalog/github-api-catalog.step.md`
- `docs/github-api/README.md`
- `docs/github-api/rest-inbox-discovery.md`
- `docs/github-api/rest-pr-reader.md`
- `docs/github-api/rest-discussion-reviews.md`
- `docs/github-api/graphql-pr-state.md`
- `docs/github-api/graphql-write-actions.md`
- `docs/github-api/rest-notifications-local-state.md`

## Modify

無。

## Deleted

無。

## TestCase

| ID | 情境 | 預期結果 |
| --- | --- | --- |
| TC-01 | capability 索引審閱 | 原始清單每項能力皆可找到唯一主文件與產品狀態。 |
| TC-02 | REST／GraphQL operation 審閱 | 每個 operation 有直接官方來源、輸入、輸出、限制與認證／權限注意事項。 |
| TC-03 | MVP boundary 審閱 | 寫入、merge、notification 與 local state 均不被誤標為現行 MVP。 |
| TC-04 | 關鍵事實審閱 | `user-review-requested:@me`、`DISMISSED`、diff media type、classic-PAT notification 限制均正確。 |
| TC-05 | 連結與 scope 檢查 | Markdown 連結可解析，diff 只包含 Written 清單中的新增檔案。 |
| TC-06 | Review thread schema 審閱 | `reviewThreads`、nodes 與 `threadId` 一律使用 `PullRequestReviewThread`。 |
| TC-07 | Viewed boundary 審閱 | catalog 只將 `viewerViewedState` 描述為遠端 API 資料，不宣告本機持久化、同步或 UI authority。 |
| TC-08 | Inbox scope 審閱 | catalog 不列出 `author:@me`，且只以目前使用者的 direct review request 作為跨 repository Inbox query。 |
| TC-09 | REST pagination metadata 審閱 | 所有 REST list 文件使用官方 `page`／`per_page` query 名稱；`GET /notifications` 並列出 `all`、`participating`、`since`、`before`、`page`、`per_page` 與 50 筆上限。 |
| TC-10 | REST operation contract 審閱 | Notification operations 列出 classic PAT 與所需 scope；`@me` search 要求有效 token；inline comments 與 review summary 皆有分頁；`REQUEST_CHANGES`／`COMMENT` 均要求 `body`。 |
| TC-11 | 延後唯讀 taxonomy 審閱 | repository PR list 與 `GET /notifications` 標為「後續唯讀」；`PATCH /notifications/threads/{thread_id}` 維持「後續寫入」，且 Capability Index 分列讀取與寫入能力。 |
| TC-12 | Search／Viewed／notification contract 審閱 | Search 明列單一 query 1,000 筆上限；`PullRequest.files` 與 Files Viewed state index 為「後續唯讀」，viewed mutations 為「後續寫入」；notification PATCH 列出 `205 Reset Content` 與無 response body。 |
| TC-13 | GraphQL Reader query contract 審閱 | 所有 PR state query 均記錄 `repository(owner:, name:) → pullRequest(number:)` 定位；Checks 以 `statusCheckRollup`、`state` 與 cursor-paginated `contexts` 表達。 |
| TC-14 | Discussion、local identity 與寫入 contract 審閱 | issue-level 與 inline source 不重複串接；last-seen identity 覆蓋兩種 comment；submit review 的 `commit_id`、thread viewer gates、merge 成功 payload 與 permission gate 均有直接官方來源。 |
| TC-15 | Nested output 與操作限制審閱 | inline review comment 有定位必要輸入與原始位置欄位；checks union 列出 `__typename`／兩種 fragment output；nested thread comments 各自有 window/cursor；notification polling 有 conditional header 與 interval；merge method 有 repository setting gate。 |
| TC-16 | Review response、thread content 與 checks traversal 審閱 | Submit Review 列出 `200` 與 review resource output；thread 有 `startDiffSide` 與完整 comment node output；Checks 明列 `first`／`after`、`hasNextPage`／`endCursor` traversal。 |
| TC-17 | Files、inline fallback、Search 與 viewed mutation contract 審閱 | `files` 明列 `first`／`after`、`hasNextPage`／`endCursor` traversal；REST inline fallback 有作者、時間與連結欄位；Search 使用必填 `q`；viewed mutations 同時連結 operation payload 與 input。 |
| TC-18 | 多行 review、thread resolution 與 Search pagination contract 審閱 | Submit Review 的非 reply 多行範圍將 `start_line`／`start_side` 列為條件必填；thread resolution mutations 同時連結 operation payload 與 input；Search 列出 `page` 與 Link next traversal。 |
| TC-19 | Diff failure、checks nullability 與 thread target contract 審閱 | Unified diff 只記錄官方 `406`，不推論原因或 fallback；`statusCheckRollup` 及 thread line fields 保留 nullable 語意；thread 選取 `subjectType`；新整合優先 line-based 定位，`position` 僅為 closing-down 相容用途。 |
| TC-20 | Review decision 與 changed-file optional contract 審閱 | `reviewDecision` 保留 nullable 語意且不推論 null 原因；REST changed-file `patch` 標記為可能缺席，並以官方 OpenAPI `diff-entry` required set 支持，且不歸因於特定檔案類型。 |
| TC-21 | Reader、checks、thread 與 Search output contract 審閱 | REST PR `body` 保留 nullable，`previous_filename`、`patch`、`submitted_at` 保留可能缺席語意；GraphQL locator、check output、resolver 與 author 保留 nullable；Search root response 列出 `total_count` 與 `incomplete_results`，且不對 null／缺席成因作推論。 |
| TC-22 | Thread reply 關係與來源邊界審閱 | `PullRequestReviewComment.replyTo` 標記為 nullable；Notifications 維持官方明示的 classic-PAT 限制；REST `user` 不因 component 名稱而作未被 schema 直接支持的 nullable 宣告。 |
| TC-23 | Thread 位置、雙層分頁與 comment identity 審閱 | `PullRequestReviewThread` 的其餘位置欄位保留 nullable；外層與巢狀 comments 各以自身 `hasNextPage`／`endCursor` 推進 `after`；REST inline response 保留 `id`／`node_id`，last-seen key 以 API source 與 opaque identity 區隔，不假定可跨 API 對應。 |
| TC-24 | Mutation 與 REST response nullable contract 審閱 | 五個 GraphQL mutation payload resource fields 保留 nullable；REST repository PR list `body`、inline comment 的三個多行範圍欄位與 notification `last_read_at` 均依官方 OpenAPI 標為 nullable。 |
| TC-25 | REST review nullable 與 Submit Review input contract 審閱 | REST inline comment 的 `pull_request_review_id` 與 review resource 的 `commit_id` 依官方 OpenAPI 標為 nullable；`original_position` 不因未列於 `required` 而標 nullable；Submit Review 的多行範圍描述不暗示 `in_reply_to` input。 |
| TC-26 | REST inline optional-presence contract 審閱 | `pull-request-review-comment.original_position` 與 `in_reply_to_id` 未列於官方 OpenAPI required set，因此標為可能缺席，而非 nullable；不推論缺席原因。 |
| TC-27 | GraphQL mutation operation nullable contract 審閱 | 五個寫入 mutation 的 operation field 與其 payload resource field 均保留 nullable contract；不只記錄 payload 內層資源欄位。 |
| TC-28 | Files、PR draft 與 notification filter contract 審閱 | `PullRequest.files` 保留外層 nullable；REST list/detail 的 `draft` 標為可能缺席；Notifications `all` 預設為 `false` 且省略時只回傳未讀 notification，是否採用 `all=true` 留給後續產品 topic。 |
| TC-29 | GraphQL cursor 與 nested comment nodes nullability 審閱 | `PageInfo.endCursor` 保留 nullable，只有在 `hasNextPage` 為 true 且 cursor 存在時才傳入 `after`；review-thread comments 的 nodes list 與元素各自保留 nullable。 |
| TC-30 | Checks／changed-files nodes nullable contract 審閱 | `StatusCheckRollupContextConnection.nodes` 與 `PullRequestChangedFileConnection.nodes` 的 list 與每個 node 均保留 nullable；只有非 null node 才讀取 union fragment 或 changed-file 欄位。 |
| TC-31 | Review-thread nodes nullable contract 審閱 | `PullRequestReviewThreadConnection.nodes` 的 list 與每個 node 均保留 nullable；只有非 null node 才讀取 review thread 欄位，並依欄位自己的 contract 判空。 |
