# GitHub API Endpoint Catalog — Requirements

## Goal

建立可追溯的 GitHub.com Pull Request API 參考資料，讓後續 PR Inbox、PR Reader 與延後能力的實作 topic 能快速選擇正確的 REST endpoint 或 GraphQL operation，而不把 GitHub 外部協定帶入核心 BC。

## In-Scope

- 整理等待目前使用者 review 的 PR discovery、PR detail/diff、checks、comments/reviews、file viewed state、review threads、merge、notifications，以及 comment-level last-seen 的可選本機 state。
- 依 endpoint family 分拆文件，並以總索引連結每項能力。
- 對每個 operation 記錄用途、輸入、關鍵欄位、分頁或上限、權限注意事項、產品狀態與官方來源。
- 將能力標記為「MVP 唯讀」、「後續唯讀」、「後續寫入」或「可選本機狀態」。

## Out-Of-Scope

- API client、OAuth／Keychain、SQLite schema、Swift type、Port、DTO、UI 或資料同步實作。
- 使用 `author:@me` 瀏覽使用者建立的 PR；這不是目前 MVP 的待 review 集合。
- 變更產品範圍、Bounded Context 責任、架構圖或現有架構文件。
- GitHub Enterprise、多帳號、跨裝置同步與通知功能的產品實作。

## Success Criteria

- 原始 capability 清單的每個項目皆能從 API catalog 索引找到唯一的主文件。
- 每個紀錄均連向 GitHub 官方文件，且與 2026-09-03 的官方 REST／GraphQL reference 相符。
- 現行 MVP 唯讀、延後唯讀與延後寫入能力不會混淆。

## Research Findings

- PR 是 Issue 的一種；一般 PR conversation 使用 Issues comments API，diff inline comment 使用 Pull request review comments API。
- `PullRequestChangedFile.viewerViewedState` 的 `DISMISSED` 是 GitHub API 回傳的 state，官方定義為檔案在上次 viewed 後有新變更。
- `PullRequest.reviewThreads` 回傳 `PullRequestReviewThreadConnection`，其 nodes 與 resolve/unresolve 的 thread identity 都是 `PullRequestReviewThread.id`。
- Notifications REST API 僅支援 classic PAT，不支援 GitHub App user／installation token 或 fine-grained PAT；每次呼叫另需 `notifications` 或 `repo` scope，因此它是延後能力且有獨立認證限制。
- `GET /notifications` 的官方 query 為 `all`、`participating`、`since`、`before`、`page` 與 `per_page`，後者每頁最多 50 筆。
- Issues Search 單一 query 最多提供 1,000 筆結果；跨 repository review-request Inbox 超出此上限時的處理策略不在本 topic 鎖定。
- `PATCH /notifications/threads/{thread_id}` 成功時回傳 `205 Reset Content`，無 response body。
- 直接要求目前使用者 review 的明確 search qualifier 為 `user-review-requested:@me`；不將未經官方參考確認的 `review-involves:@me` 列為可採用 query。
- 建立 review 時，`REQUEST_CHANGES` 與 `COMMENT` 兩種 `event` 必須帶 review `body`；inline review comments 與 review summary 都使用 `page` 與 `per_page` 分頁。
- GraphQL PR state query 以 `repository(owner:, name:) { pullRequest(number:) }` 定位 PR；`PullRequest.statusCheckRollup` 提供 PR head ref 的 check/status rollup，其 `contexts` 是 cursor-paginated connection。
- `mergePullRequest` 成功 payload 含已合併的 `pullRequest`；fine-grained token 的 REST merge reference 要求 `Contents` permission（write），而 `viewerCanMergeAsAdmin` 只描述 branch-protection bypass 能力。
- 建立 review 的 `commit_id` 省略時預設為送出時 PR 的最新 commit；可選 last-seen identity 必須區分 issue-level 與 inline review comment，且只有後者可選用 review thread identity。
- 建立 review 的每筆 inline comment 必帶 `path` 與 `body`，並以 diff `position` 或 line-based `line`／`side` 定位；REST 回應與 `PullRequestReviewThread` 都有可保留 outdated comment 原始位置的欄位。
- `StatusCheckRollup.contexts` 的 node 是 `CheckRun`／`StatusContext` union，query 必須用 `__typename` 與對應 inline fragments；review thread 的巢狀 comments 也有自己的 window input 與 cursor。
- Notifications conditional polling 需將 response `Last-Modified` 原樣傳入下一次的 `If-Modified-Since`，並遵守 `X-Poll-Interval`。
- `mergePullRequest.mergeMethod` 必須符合 repository 的 `mergeCommitAllowed`、`squashMergeAllowed` 或 `rebaseMergeAllowed` 設定。
- 提交 review 成功回傳 `200 OK` 與 Pull Request Review resource；catalog 必須記錄能讓後續 Adapter 取得 review identity、state 與 commit 的主要 output。
- `PullRequestReviewThread` 的多行範圍需同時保留 `startLine` 與 `startDiffSide`；其 `comments.nodes` 需選取 identity、body、author、時間、reply 關係與 URL。
- `PullRequestReviewThread` 的 `line`、`startLine`、`startDiffSide`、`originalLine`、`originalStartLine` 與 `resolvedBy` 都沒有 non-null 標記；外層 `reviewThreads` 與每個巢狀 `comments` connection 都必須各自以 `hasNextPage`／`endCursor` 推進自己的 `after`。
- Checks cursor traversal 以 `pageInfo.hasNextPage` 與 `endCursor` 驅動下一個 `contexts(after: ...)` query；所有 GraphQL connection 的 window 為 1–100。
- Changed files cursor traversal 同樣以 `pageInfo.hasNextPage` 與 `endCursor` 驅動下一個 `files(after: ...)` query；不得只泛稱 cursor。
- REST inline review comments 的 fallback output 必須保留 `user`、`created_at`、`updated_at` 與 `html_url`，以供顯示作者、時間與連結。
- Cross-repository Issues Search 的必要 query parameter 名稱為 `q`，其值為 `is:pr is:open user-review-requested:@me`。
- Files viewed mutation 的官方來源必須同時連結 operation／payload 與 input，讓成功 `pullRequest` output 與輸入都可追溯。
- REST inline review comment response 提供 `id` 與 `node_id`；可選本機 last-seen 的 Rivet 規則使用 API source 與 opaque identity，不推論其與 GraphQL `PullRequestReviewComment.id` 的跨 API 對應。
- `MarkFileAsViewedPayload.pullRequest`、`UnmarkFileAsViewedPayload.pullRequest`、`ResolveReviewThreadPayload.thread`、`UnresolveReviewThreadPayload.thread` 與 `MergePullRequestPayload.pullRequest` 都沒有 non-null 標記；catalog 必須保留 nullable contract，不推論 null 成因。
- REST OpenAPI 的 `pull-request-simple.body`、`pull-request-review-comment.start_line`／`start_side`／`original_start_line` 與 `notification-thread.last_read_at` 都明示為 nullable。
- Submit Review 的多行 inline comment 範圍（非 reply）必須將 `start_line` 與 `start_side` 記錄為條件必填；不得以「可帶」弱化該 contract。
- Review thread resolution mutations 的官方來源必須同時連結 operation／payload 與 input，讓成功 thread output 與輸入都可追溯。
- Cross-repository Issues Search 除 `q` 與 `per_page` 外，必須列出 `page` 與依 Link header next URL 的 traversal。
- Unified diff endpoint 必須記錄官方列出的 `406 Unacceptable`，但不得將其歸因於未被官方來源支持的特定 diff 大小，或預先定義 fallback。
- Checks contract 必須保留 nullable `statusCheckRollup`，且不得對 null 原因作未證實推論。
- Review thread 必須選取 `subjectType`，並保留 nullable line／start-line fields；Submit Review 新整合優先 line-based 定位，`position` 僅記錄為 closing-down 相容方式。
- `PullRequest.reviewDecision` 沒有 non-null 標記；catalog 必須保留其 nullable 語意，且不推論 null 的原因。
- REST changed-file 的官方 `diff-entry` schema 不將 `patch` 列為 required；catalog 必須標示其可能缺席，但不得將缺席歸因於未被該來源支持的特定檔案類型。
- REST `pull-request` schema 將 `body` 標為 nullable；`diff-entry` 的 `previous_filename` 與 `patch`、以及 `pull-request-review` 的 `submitted_at` 都未列於 required，catalog 必須分別保留 nullable 或可能缺席語意，不推論成因。
- GraphQL `Query.repository`、`Repository.pullRequest`、`CheckRun.conclusion`、`CheckRun.detailsUrl`、`StatusContext.targetUrl`、`PullRequestReviewThread.resolvedBy` 與 `PullRequestReviewComment.author` 都沒有 non-null 標記，catalog 必須保留逐層 nullable contract；不得推論 null 原因或 failure mapping。
- Cross-repository Issues Search 的 root response 必須列出 `total_count`，與既有 `incomplete_results` 共同作為 search response output。
- `PullRequestReviewComment.replyTo` 沒有 non-null 標記；catalog 必須標為 nullable，且不推論 null 的成因。Notifications operation 的 token 限制與 REST `user` nullable claim 則必須以現行官方文件或 schema 的明確標記為準，不以 component 名稱或未驗證行為延伸。
- REST OpenAPI 的 `pull-request-review-comment.pull_request_review_id` 與 `pull-request-review.commit_id` 都明示為 nullable；`original_position` 沒有 nullable 標記，不得僅因其未列於 `required` 而推論可為 null。
- `POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews` 的 `comments` item 官方輸入只列 `path`、`position`、`body`、`line`、`side`、`start_line` 與 `start_side`；catalog 不得暗示支援 `in_reply_to`。
- REST OpenAPI 的 `pull-request-review-comment.original_position` 與 `in_reply_to_id` 沒有列於 `required`；catalog 必須標為可能缺席，並與 nullable contract 區分，不推論缺席原因。
- `markFileAsViewed`、`unmarkFileAsViewed`、`resolveReviewThread`、`unresolveReviewThread` 與 `mergePullRequest` 的 mutation operation field 都沒有 non-null 標記；catalog 必須同時保留 operation field 與 payload resource field 的 nullable contract。
- `PullRequest.files` 沒有 non-null 標記；catalog 必須在取其 connection 的 `nodes` 或 `pageInfo` 前保留外層 nullable contract，且不推論 null 原因。
- REST `pull-request-simple.draft` 與 `pull-request.draft` 未列於各自 required set；catalog 必須標為可能缺席，並與 nullable contract 區分。
- `GET /notifications` 的 `all` query 預設為 `false`，省略時只顯示未讀 notification；是否包含已讀 notification 是後續產品決策。
- `PageInfo.endCursor` 沒有 non-null 標記；所有 connection traversal 只在 `hasNextPage` 為 true 且 cursor 存在時才使用 `after`。
- `PullRequestReviewCommentConnection.nodes` 的 list 與每個 list element 都沒有 non-null 標記；catalog 必須保留兩層 nullable contract，再讀取 comment node fields。
- `StatusCheckRollupContextConnection.nodes` 與 `PullRequestChangedFileConnection.nodes` 的 list 與 list element 都沒有 non-null 標記；catalog 必須逐層保留 nullable contract，再讀取 union fragment 或 changed-file 欄位。

## Official Sources

- [REST Pull requests](https://docs.github.com/en/rest/pulls/pulls)
- [REST Search](https://docs.github.com/en/rest/search/search)
- [Search qualifiers for issues and pull requests](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests)
- [REST Issue comments](https://docs.github.com/en/rest/issues/comments)
- [REST Pull request review comments](https://docs.github.com/en/rest/pulls/comments)
- [REST Pull request reviews](https://docs.github.com/en/rest/pulls/reviews)
- [REST Notifications](https://docs.github.com/en/rest/activity/notifications)
- [GraphQL Pull requests](https://docs.github.com/en/graphql/reference/pulls)
- [GraphQL introduction and transport](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api)
- [GitHub REST API description](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)
