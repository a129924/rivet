# 按需讀取 GitHub 未讀通知｜技術規格

在既有 `GitHubIntegration` target 新增 `Notifications/`，提供 Swift `package` 範圍的通知來源。 [需求](requirements.md) · [執行計畫](../../plan/github-unread-notifications-source/github-unread-notifications-source.plan.md)

## Endpoint、Source 與 PageLinks

- `internal GitHubUnreadNotificationsEndpoint` 持有 GET、精確路徑 `/notifications`、`all=false`、`per_page=50` 和成功狀態 `200`。`makeURL(page: Int = 1) throws -> HTTPURL` 沿用 `GitHubRESTDestination.makeURL`。首頁省略 `page`，續頁明列大於 1 的頁碼。零或負頁碼在建構 URL 前拒絕。
- `GitHubUnreadNotificationsSource` 透過 `package` initializer 建立，套件入口為 `list(using: PersonalAccessToken?) async -> GitHubUnreadNotificationsOutcome`。Source 為每一頁呼叫 Endpoint，套用 `.standardREST` 的 Accept、User-Agent 和 API version，以及同一 PAT 的 `BearerAuth`。正式傳輸採用 `GitHubHTTPClient.makeHTTPClient()`，拒絕所有 HTTP 轉址。測試用 `internal` initializer 注入 `HTTPClient`。
- PageLinks 依 Endpoint 的路徑及查詢常數驗證 `Link`，交回可信的下一頁頁碼或確認終頁。只接受 `https://api.github.com`、省略 port 或明列 `443`、精確 percent-encoded 路徑 `/notifications`、無 userinfo 或 fragment 的分頁目的地。Source 向 Endpoint 建構續頁 URL 後才套用 Bearer。
- 驗證 `Link` 語法及 `next`／`last` 關係，拒絕不明確的分頁關係及分頁用 `anchor`。分頁查詢只接受 `page`、`all`、`per_page`，拒絕重複、空值及未知參數。`next` 的正整數 `page` 必須等於目前頁碼加一。`all` 與 `per_page` 可省略，提供時必須分別等於 `false`、`50`。沒有 `next` 且無同頁 `last` 矛盾時確認終頁。提供 `last` 時，其頁碼須位於 `next` 或之後。若無 `next`，`last` 須是目前頁碼。`is_done` 全程省略。 [GitHub 通知 API](https://docs.github.com/en/rest/activity/notifications#list-notifications-for-the-authenticated-user) · [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)

## 資料與結果

Source 只從 HTTP `200` 解碼清單，按頁與列累積。`GitHubNotificationThread` 保留 opaque 字串 `id`、布林 `unread`、`updatedAt: Date` 與 `lastReadAt: Date?`。主旨保留原始 `title` 與 `type`，以及可缺的主旨與最新留言 URL 字串。Repository 保留 `Int64` ID 與 `fullName`。未知主旨類型與合法缺值照原義保留。

| Outcome 或 failure 分類 | 條件 |
| --- | --- |
| `.success([GitHubNotificationThread])` | 分頁已確認完整，包含零筆。 |
| `.accessDenied` | 缺 PAT、Bearer 設定失敗、HTTP `401`，或既有分類器未辨識為限流的 `403`。 |
| `.unavailable` | 其餘首頁非成功 HTTP 狀態或傳輸失敗。 |
| `.incompletePagination` | 無法驗證分頁，或續頁的其餘非成功 HTTP 狀態或傳輸失敗。已辨識的限流按發生的頁面分類。 |
| `.invalidData` | 任一頁的必要資料無法映射。 |
| `.cancelled` | 取消優先於尚未交付的結果。 |

四種 failure 分類由 `GitHubUnreadNotificationsOutcome.failure` 承載。存取拒絕與失效的分頁都終止該次列舉，結果與診斷只暴露有限分類。帳號歸屬與每頁授權使用呼叫端提供的同一 PAT。
