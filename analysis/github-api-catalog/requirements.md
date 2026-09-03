# GitHub API Endpoint Catalog — Requirements

## Goal

建立可追溯的 GitHub.com Pull Request API 參考資料，讓後續 PR Inbox、PR Reader 與延後能力的實作 topic 能快速選擇正確的 REST endpoint 或 GraphQL operation，而不把 GitHub 外部協定帶入核心 BC。

## In-Scope

- 整理等待目前使用者 review 的 PR discovery、PR detail/diff、comments/reviews、file viewed state、review threads、merge、notifications，以及 comment-level last-seen 的可選本機 state。
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
- 每個紀錄均連向 GitHub 官方文件，且與 2026-09-02 的官方 REST／GraphQL reference 相符。
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
