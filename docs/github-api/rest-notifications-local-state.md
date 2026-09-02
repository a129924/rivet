# REST Notifications & Local State

最後官方校驗：2026-09-02。

## GitHub Notification Threads

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入 |
| List operation | `GET /notifications` |
| 重要欄位 | `id`、`unread`、`updated_at`、`last_read_at`、`subject`、`repository` |
| Mark read | `PATCH /notifications/threads/{thread_id}` |
| Polling | 支援 `Last-Modified`；沒有新通知時可回傳 `304 Not Modified`。 |
| Token 限制 | 僅 classic PAT；不支援 GitHub App user token、GitHub App installation token 或 fine-grained PAT。 |

Notification thread 的 read state 與「某一個 review comment 是否已在 Rivet 看過」不同，不可互相替代。

## Comment-Level Last-Seen

| 項目 | 定義 |
| --- | --- |
| 狀態 | 可選本機狀態 |
| GitHub 等價能力 | 無 per-comment viewer viewed state。 |
| 最小 identity | review thread id 與最後已看見的 comment id 或時間。 |
| Source of truth | GitHub 仍擁有 comment、thread、outdated 與 resolved；本機只擁有 Rivet 自己的 last-seen UX。 |
| 非決策 | 不定義 SQLite、schema、同步規則、保留期限或跨裝置行為。 |

## Sources

- [List notifications for the authenticated user](https://docs.github.com/en/rest/activity/notifications#list-notifications-for-the-authenticated-user)
- [Mark a thread as read](https://docs.github.com/en/rest/activity/notifications#mark-a-thread-as-read)
