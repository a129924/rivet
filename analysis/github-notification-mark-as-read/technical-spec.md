# 將單一 GitHub 通知標記為已讀技術規格

## Endpoint 與套件入口

- `internal GitHubNotificationMarkAsReadEndpoint` 代表單筆寫入目的地。採 throwing `init(threadID:)`、`method` 回傳 `.patch`、throwing `makeURL()`。ID 限全為 ASCII 數字且至少有一個非零數字的原始 `String`。保留前導零與可長於 Swift `Int` 的字串。用 `GitHubRESTDestination.makeURL(path:)` 組成 `https://api.github.com/notifications/threads/{thread_id}`，query 為空。無效 ID 在建立 endpoint 時回報。
- `package GitHubNotificationReadMarker.markAsRead(threadID:using:)` 接受 `String` 與非 optional `PersonalAccessToken`，以 `async` 回傳操作專屬的 `Sendable` 結果。Adapter 先取得 endpoint 的固定目的地，沿用 `GitHubHeadersFactory.standard` 的 `.standardREST` 準備無 body 的請求，再以 `BearerAuth` 加入憑證。PAT 類型、scope 與帳號歸屬由呼叫端提供且由 GitHub 裁決。
- 正式預設採 `GitHubHTTPClient.makeHTTPClient()` 提供的 raw `HTTPClient`，由既有 URLSession delegate 阻擋轉址。以 internal 注入點支援受控測試。每次有效呼叫只進入 raw request execution 一次，自動讀回、OAuth 401 recovery 與自動重送次數為零。單次指應用層 transport 提交。 [GitHub 單筆已讀 API](https://docs.github.com/en/rest/activity/notifications#mark-a-thread-as-read)

## 結果與中斷

| 條件 | 結果 |
| --- | --- |
| 提交前已取消 | 回報送出前取消，零提交。 |
| 無效 thread ID | 回報無效 ID，零提交。 |
| 固定 URL、標頭或 Bearer 無法組裝 | 回報有限本地準備失敗，零提交。 |
| `205` | 確認已讀，依狀態碼交付，無須解碼。 |
| `304` | 回報未修改，呼叫端保留原狀態。 |
| `401`，或既有分類器未辨識為限流的 `403` | 回報存取遭拒。單憑回應無法裁定拒絕原因或 PAT scope。 |
| 既有分類器辨識為限流的 `403` 或 `429` | 回報限流。 |
| `5xx` | 回報結果待核對。 |
| 其他 HTTP 狀態 | 回報非預期回應。 |
| 提交後無有效 HTTP 回應，包括取消、逾時、斷線與非 HTTP 回應 | 回報結果待核對。 |

在提交前檢查取消。跨入 raw execution 後，已取得的有效 HTTP 回應優先於同時發生的取消，依上表映射。結果待核對由呼叫端保留。結果與診斷只保留有限分類及必要狀態碼，排除 PAT、原始標頭、回應內容與底層錯誤。 [GitHub 官方回應規格](https://docs.github.com/en/rest/activity/notifications#http-response-status-codes-for-mark-a-thread-as-read)

[需求](requirements.md) · [執行計畫](../../plan/github-notification-mark-as-read/github-notification-mark-as-read.plan.md)
