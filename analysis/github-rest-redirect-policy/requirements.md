# GitHub REST 預設重新導向政策需求

Topic `github-rest-redirect-policy`。原始碼現況參考為 `dev` `c2f52d8`。獨立 feature worktree 的執行基線為 `dev` `3468eaa`，已核對兩個基線之間本 topic 預計修改的既有檔案未變。

使用者已接受在 GitHub REST 明文化既有預設，並將重新導向判斷與 Foundation 回呼轉譯分開。預設對 URLSession 提出的重新導向一律拒絕。使用同一 session 工廠的 OAuth REST、共用 REST factory 與登入帳號探查都採用此預設。

目前 `GitHubHTTPRedirectBlocker` 已透過 `completionHandler(nil)` 拒絕 Foundation 提出的重新導向。GitHub REST 收到首次 302 時會交回原始狀態、標頭與 body，應用層只發一次且不進入認證復原。現有 `GitHubResponseClassifier` 若收到 302，回傳 `.unexpectedStatus(statusCode: 302)`。OAuth REST client 的回應觸發復原限 401，每份原請求最多重送一次。現行正式來源未提供獨立 `TransportClassifier` 或 `RetryPolicy` 型別。

## 成功條件

- 設計可直接辨識預設政策、delegate 轉譯和 session 接線三個責任。
- 離線驗證證明既有 raw 302 與 401 復原行為，既有公開及 package 契約可原樣使用。
- GraphQL、OAuth token 交換及刷新、通用 HTTP transport 與各 Bounded Context 的 failure mapping 排除於本 topic。

人類已授權獨立工作樹內的實作與受限交付。提交及發布條件見執行計畫。 [技術規格](technical-spec.md) · [執行計畫](../../plan/github-rest-redirect-policy/github-rest-redirect-policy.plan.md)
