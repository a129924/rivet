# REST Discussion & Reviews

最後官方校驗：2026-09-03。

## PR Conversation Comments

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/issues/{issue_number}/comments` |
| 用途 | 取得 PR 的 issue-level comments；PR 同時也是 Issue。 |
| 成功結果 | `200 OK` 與 issue comment list response。 |
| 重要欄位 | id、body、user、created_at、updated_at、html_url |
| 分頁 | `page`／`per_page`；依 Link header 取下一頁。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Issues` 或 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List issue comments](https://docs.github.com/en/rest/issues/comments#list-issue-comments) |

Rivet catalog composition rule：issue-level comments 是獨立內容來源。若同次閱讀取得 GraphQL `reviewThreads`，以其 `comments` 作為 inline comment 內容來源，並以同一 thread 取得 resolved／outdated；不得再與下列 REST inline comments 串接成兩份 feed。REST inline comments 是未取得 review threads 時的替代內容來源。本規則不將任一單一 endpoint 描述為完整 conversation。

## Inline Review Comments

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}/comments` |
| 用途 | 取得 diff 上的 review comments。 |
| 成功結果 | `200 OK` 與 review comment list response。 |
| 重要欄位 | id、node_id、pull_request_review_id（nullable）、path、line（可能缺席）、side（可能缺席）、start_line（nullable）、start_side（nullable）、commit_id、original_commit_id、original_position（可能缺席）、original_line（可能缺席）、original_start_line（nullable）、body、`user`、`created_at`、`updated_at`、`html_url`、in_reply_to_id（可能缺席） |
| 分頁 | `page`／`per_page`；依 Link header 取下一頁。 |
| 注意事項 | REST fallback 保留 `id` 與 `node_id`。可選本機 last-seen 使用 API source 與該 source 回傳的 opaque comment identity，catalog 不宣告 REST `node_id` 與 GraphQL `PullRequestReviewComment.id` 可直接互換；thread grouping、resolved 與 outdated 見 GraphQL 文件。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List review comments on a pull request](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request)、[GitHub REST OpenAPI `pull-request-review-comment` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`line`、`side`、`original_line`、`original_position` 與 `in_reply_to_id` 未列於 `required`） |

## Review Summary

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews` |
| 用途 | 取得 PR reviews 的時序與結果。 |
| 成功結果 | `200 OK` 與 Pull Request Review list response。 |
| 重要欄位 | id、user（nullable）、body、state、commit_id（nullable）、submitted_at（可能缺席，不能當作必填時間） |
| Review state | `APPROVED`、`CHANGES_REQUESTED`、`COMMENTED`、`DISMISSED`、`PENDING`。 |
| 分頁 | `page`／`per_page`；依 Link header 取下一頁。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List reviews for a pull request](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request)、[GitHub REST OpenAPI `pull-request-review` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`user` 與 `commit_id` 為 nullable；`submitted_at` 未列於 `required`） |

## Submit Review

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入 |
| Operation | `POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews` |
| 用途 | 提交整體 review。 |
| 重要輸入 | `event`：`APPROVE`、`REQUEST_CHANGES` 或 `COMMENT`；`REQUEST_CHANGES` 與 `COMMENT` 必須帶 `body`。`commit_id` 指向受 review 的 commit SHA；省略時 GitHub 預設使用送出時 PR 的最新 commit。可帶 `comments` 陣列：每筆必帶 `path` 與 `body`。新整合優先使用 line-based `line`／`side` 定位；line-based 多行範圍時，`start_line` 與 `start_side` 均為條件必填。`position` 為 closing-down 的相容定位方式。 |
| 成功結果 | `200 OK` 與 Pull Request Review resource；主要欄位為 `id`、`state`、`commit_id`（nullable）、`submitted_at`（可能缺席）、`body`、`user`（nullable）。 |
| 併發注意事項 | 將 Reader snapshot 的 head SHA 帶入 `commit_id` 與送出時重新讀取策略，都是後續 implementation topic 才決定的 Rivet policy。 |
| 注意事項 | 不屬目前 MVP，亦不在本 topic 實作。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（write）。 |
| 官方來源 | [Create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request)、[Multi-line review comment inputs](https://docs.github.com/en/rest/pulls/comments#create-a-review-comment-for-a-pull-request)、[GitHub REST OpenAPI `pull-request-review` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`user` 與 `commit_id` 為 nullable；`submitted_at` 未列於 `required`） |

## Sources

- [List issue comments](https://docs.github.com/en/rest/issues/comments#list-issue-comments)
- [List review comments on a pull request](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request)
- [List reviews for a pull request](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request)
- [Create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request)
- [GitHub REST API description](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)
