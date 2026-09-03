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
