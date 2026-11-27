# 整體 Review 送出技術規格

`RivetPRReviewGitHub` 透過 `GitHubPullRequestReviewSubmissionSource` 提供同 Swift package 的 `package` 送出入口、輸入值與結果，依賴 `GitHubIntegration` 和 `RivetHTTPClient`。呼叫端注入 `GitHubClientScope.rest`。PR Reader 擁有唯讀契約。GitHub 持有遠端審閱紀錄。

`GitHubCreatePullRequestReviewEndpoint` 持有 `.post`，驗證 owner 與 repo 為安全路徑片段、PR 編號為正整數，並使用 `GitHubRESTDestination` 組裝 URL。

Source 驗證 commit SHA 為完整 40 個 ASCII 十六進位字元。要求 `REQUEST_CHANGES` 與 `COMMENT` 提供非純空白正文。`APPROVE` 的正文選填。保留通過驗證的 SHA 與正文原值。

Source 使用 Endpoint 的 method 與 URL 組裝 `POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews`。Source 取得 `.standardREST`，並在本次請求的標頭值設定 `Content-Type: application/json`。JSON 包含 `event`、`commit_id` 與提供時的 `body`。

| 結果 | 條件 |
| --- | --- |
| 已接受，附收據 | Adapter 收到 200，ID 為正整數且狀態符合動作，分別為 APPROVED、CHANGES_REQUESTED 或 COMMENTED。 |
| 已接受，收據待核對 | Adapter 收到 200，且無法讀取有效收據。 |
| 本機未送出 | 驗證或組裝失敗、進入 client 前已取消，或 client 回報 invalidRequest。 |
| 認證未完成 | Client 回報 authenticationRequired 或 credentialLifecycle。 |
| GitHub 明確拒絕 | Adapter 收到 401、403、404、422 或 429，保留狀態碼。 |
| 送出結果待核對 | 進入 client 後只有取消、傳輸或未分類錯誤，或收到其他狀態碼。 |

Adapter 每次最多呼叫 client 一次。現有 client 在明確 401 後可用替代 token 重送同一請求一次。Adapter 以交付的 HTTPResponse 為準，收到 200 優先保留成功事實，即使 task 已取消。若 client 因取消只交回錯誤，歸類為待核對。

[需求](requirements.md) · [API Catalog](../../docs/github-api/rest-discussion-reviews.md#submit-review)
