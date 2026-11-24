# PR Inbox 與 PR Reader 的 Swift 取消基線

本基線以 production 來源 `386af9e` 為準。TypeScript WebView bridge 的本地事件防護、Swift Task 取消傳遞、產品狀態提交各自有不同的擁有者和證據。完整呼叫追蹤、八種驗證情境與後續契約選項見 [技術審查](../../analysis/cancellation-trace-contract-review/technical-spec.md)。

## 現行契約

- `URLSessionTransport` 將可辨識的 Foundation 或 Swift 取消轉為 `HTTPClientError.cancelled(underlying:)`。GitHub REST 在 snapshot、send 和 401 recovery 的 await 邊界觀察取消，正規化為 `CancellationError`。受控 REST 測試確認已取消 caller 停止後續送出或重送。 [Transport](../../packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/URLSessionTransport.swift#L10-L47) · [REST](../../Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClient.swift#L50-L125)
- OAuth provider 持有共享 restore／refresh 與輪替保存。單一 caller 取消可能要等待共享工作收尾，且不取消其他 waiter 需要的工作或已接受的輪替保存。共享 refresh 本身在送出後取消且缺少可信回應時，後續 caller 可能收到技術上的 rotation uncertainty。 [OAuth 取消契約](github-oauth-dual-client.md#更新失敗與取消契約)
- PR Inbox GitHub Adapter 在 REST 呼叫前及成功返回後觀察取消。取消在跨越 nonthrowing BC Port 前與其他技術失敗一同映射為 `.unavailable`。E020 CLI 的 Task group 先選報告，再取消其他子工作並等待收尾。 [Adapter](../../Sources/PRInboxGitHub/GitHubSelfReviewSource.swift#L21-L72) · [E020 報告選定](../../experiments/E020/Sources/SelfReviewProbe/Probe.swift#L18-L30)
- PR Reader 已有 nonthrowing `PRContentSource` 與 Reader-local failure 契約。現行 Swift target 僅含 Core。E012 的 WebView 世代與事件身分檢查適用本地 fixture。 [Reader 契約](bounded-contexts/pr-reader.md)

## 受驗證條件

- **E021** 在 arm64 macOS 26.5.2／Swift 6.3.3 測得真 Foundation 本地 HTTP/1.1 請求取消。取消組保留 `NSURLErrorDomain/-999`，loopback peer 於回應或清理前觀察到 EOF。 [E021 證據](../../experiments/E021/README.md#結果與證據)
- **E022** 以受控 REST 替身交付相同成功回應。caller 已取消時，正式 Inbox Facade 回 `.unavailable`，兩組均只有帳號與搜尋兩次請求。 [E022 證據](../../experiments/E022/README.md#結果與證據)

現有證據限於記錄的環境及邊界。產品狀態提交、同步解碼中途取消、真 GitHub、HTTP/2 或其他連線策略仍無本輪直接證據。後續契約取捨及待確認事項見 [審查建議](../../analysis/cancellation-trace-contract-review/technical-spec.md#d01-契約比較與建議)。
