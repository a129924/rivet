# REST Notifications & Local State

通知清單最後官方校驗為 2026-11-26。其餘條目的校驗日期為 2026-09-03。

## GitHub Notification Threads

| Operation | 狀態 | 用途／重要欄位 | 認證／權限 | 官方來源 |
| --- | --- | --- | --- | --- |
| `GET /notifications` | 後續唯讀，已提供套件內按需讀取 | 正常回應為 `200 OK` 與 notification thread list。官方 query 包含 `all`、`is_done`、`participating`、`since`、`before`、`page` 與 `per_page`（最多 50）。`all` 預設為 `false`，`is_done` 省略時涵蓋所有完成狀態。依 `Link` 的 `next` 讀取下一頁。重要欄位為 `id`、`unread`、`updated_at`、`last_read_at`（nullable）、`subject` 與 `repository`。 | 僅 classic PAT，需 `notifications` 或 `repo` scope。存取相關 issue 或 commit endpoint 時需 `repo` scope。 | [List notifications for the authenticated user](https://docs.github.com/en/rest/activity/notifications#list-notifications-for-the-authenticated-user)、[GitHub REST OpenAPI `notification-thread` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json) |
| `PATCH /notifications/threads/{thread_id}` | 已提供套件內單筆寫入 | 將指定 notification thread 標為已讀；成功回應為 `205 Reset Content`，無 response body。 | 僅 classic PAT，且需 `notifications` 或 `repo` scope；若還要從相關 endpoint 取得 issue 或 commit，需 `repo` scope。不支援 GitHub App user token、GitHub App installation token 或 fine-grained PAT。 | [Mark a thread as read](https://docs.github.com/en/rest/activity/notifications#mark-a-thread-as-read) |

Rivet 套件內由 `GitHubIntegration` 的 `GitHubUnreadNotificationsSource.list(using:)` 提供按需讀取。組裝端透過 `init(client:)` 注入 client，正式組裝採用 `GitHubRESTTransport.makeClient()`，保留原始轉址回應並拒絕自動跟隨。呼叫端傳入 classic PAT。每次以 `all=false&per_page=50` 開始，逐頁驗證 `Link` 的目的地、查詢與連續頁碼，使用相同 PAT 與標準 REST 標頭，終頁確認後一次交付原順序的完整清單。結果可區分存取拒絕、來源無法使用、分頁未完成、資料無法映射與取消。該能力屬產品 MVP 之外。

條件式輪詢屬後續工作。GitHub 提供 `Last-Modified`、`If-Modified-Since`、`304 Not Modified` 與以秒為單位的 `X-Poll-Interval`。 GitHub App user／installation token 與 fine-grained PAT 不適用於通知清單。

Rivet 套件內由 `GitHubIntegration` 的 `GitHubNotificationReadMarker.markAsRead(threadID:using:)` 提供單筆寫入。呼叫端傳入同一帳號的 thread ID 與 classic PAT。寫入入口先驗證 ID，再向固定 GitHub API 目的地提交一次無 body 的 PATCH。 `205` 確認寫入，`304` 回報未修改。缺少伺服器確認時，呼叫端收到待核對結果。轉址及自動重送均停用。此契約已用受控離線測試驗證。

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
