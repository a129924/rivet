# REST Notifications & Local State

最後官方校驗：2026-09-03。

## GitHub Notification Threads

| Operation | 狀態 | 用途／重要欄位 | 認證／權限 | 官方來源 |
| --- | --- | --- | --- | --- |
| `GET /notifications` | 後續唯讀 | 正常回應為 `200 OK` 與 notification thread list；query 為 `all`、`participating`、`since`、`before`、`page`、`per_page`（最多 50），依 response `Link` header 的 next URL 取得下一頁。`all` 省略時預設為 `false`，只顯示未讀 notification；是否要求包含已讀 notification 留給後續產品 topic 決定。重要欄位為 `id`、`unread`、`updated_at`、`last_read_at`（nullable）、`subject`、`repository`。conditional polling 時保存 response `Last-Modified`，下次以完全相同的值傳入 `If-Modified-Since`；無新通知可得 `304 Not Modified`。依 response `X-Poll-Interval`（秒）決定最短 polling 間隔。 | 僅 classic PAT，且需 `notifications` 或 `repo` scope；若還要從相關 endpoint 取得 issue 或 commit，需 `repo` scope。不支援 GitHub App user token、GitHub App installation token 或 fine-grained PAT。 | [List notifications for the authenticated user](https://docs.github.com/en/rest/activity/notifications#list-notifications-for-the-authenticated-user)、[GitHub REST OpenAPI `notification-thread` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json) |
| `PATCH /notifications/threads/{thread_id}` | 後續寫入 | 將指定 notification thread 標為已讀；成功回應為 `205 Reset Content`，無 response body。 | 僅 classic PAT，且需 `notifications` 或 `repo` scope；若還要從相關 endpoint 取得 issue 或 commit，需 `repo` scope。不支援 GitHub App user token、GitHub App installation token 或 fine-grained PAT。 | [Mark a thread as read](https://docs.github.com/en/rest/activity/notifications#mark-a-thread-as-read) |

Notification thread 的 read state 與「某一個 review comment 是否已在 Rivet 看過」不同，不可互相替代。

## Comment-Level Last-Seen

| 項目 | 定義 |
| --- | --- |
| 狀態 | 可選本機狀態 |
| GitHub 等價能力 | 本 catalog 未識別 GitHub 官方的 per-comment viewed state。 |
| 最小 identity | PR identity、comment resource 類型（issue-level 或 inline review）、API source（REST 或 GraphQL）與該 source 回傳的 opaque comment identity；不得假設 REST 的 comment `id`／`node_id` 與 GraphQL `PullRequestReviewComment.id` 可直接互換。只有 inline review comment 在取得 GraphQL thread 時，才可額外保留 review thread id。 |
| Rivet 資料邊界 | GitHub API 提供 comment、thread、outdated 與 resolved；本機只保存 Rivet 自己的 last-seen UX。 |
| 非決策 | 不定義 SQLite、schema、同步規則、保留期限或跨裝置行為。 |

## Sources

- [List notifications for the authenticated user](https://docs.github.com/en/rest/activity/notifications#list-notifications-for-the-authenticated-user)
- [Mark a thread as read](https://docs.github.com/en/rest/activity/notifications#mark-a-thread-as-read)
