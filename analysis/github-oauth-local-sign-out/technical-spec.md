# 本地登出與 OAuth 憑證清除：技術契約

## 固定公開介面

新增 public `OAuthCredentialClearingStore: OAuthCredentialStore`，要求 `clear() async throws(any Error & Sendable)`；不存在視為成功，沒有預設 no-op。正式 DPK `credentialStore(clientID:)` 回傳此 refinement。既有 provider initializer 不變，舊 conformers 無需新增能力。

新增 `OAuthTokenProvider.signOut() async throws(OAuthSignOutError)`；public `OAuthSignOutError: Error, Sendable` 包含 `.unsupportedStore`、`.clear(underlying: any Error & Sendable)`。

`OAuthTokenProviderError` 新增 `.signedOut`。REST／GraphQL／scope 映射成既有 `.authenticationRequired`；其本身不是 cancellation。不新增 client error 類型。新 enum case 對下游 exhaustive switches 的 source compatibility 影響必須記錄。

## Actor lifecycle 與 ordering

1. `signOut()` 進入 actor 後，先不可逆退休，清空 provider 的 credential／snapshot references。檢查實際 store 的 clearing refinement；不支援時仍永久退休，回報 unsupportedStore。
2. 所有 token 入口、shared task 返回，以及 load／refresh／save suspension point 後都先檢查退休。退休優先於晚到技術錯誤，不能新 save、publish 或由錯誤處理覆寫退休狀態。
3. 每次 save 開始前登記獨立 pending-write task。登出等待已登記 write 真正 settle，再 clear；write 成功或失敗都不略過 clear。安全性不依賴 Task.cancel。
4. 不等待可能長期阻塞的 load／refresh；晚到結果由退休檢查丟棄。已等候 token 的 caller 最終不能取得成功 snapshot。
5. 同時 signOut 共用一次清除工作；成功後重複呼叫成功。失敗保留退休，下一次明確呼叫只重試 clear。
6. signOut caller 取消不取消清除、不提前宣稱成功，等待並回傳實際清除結果。snapshot caller cancellation 原契約維持。
7. 新登入只能在清除成功後建立新 provider。既有 token 副本／已送出 request 無法收回，清空 references 不等於安全抹除。

## 精確 DPK 刪除

正式 Security seam 增加同步 delete，live adapter 呼叫 SecItemDelete。selector 沿用 class、explicit access group、service、credential account、DPK=true、synchronizable=false；不加 return-data 或 broad selector。

clientID-bound 讀取／驗證與 delete 在同一 storage actor 操作內完成，中間無 suspension。不存在冪等成功；clientID mismatch／corrupt 回報既有有限 store error 並保留 item。errSecItemNotFound 成功，其餘沿用既有 Security status 分類。configuration 與相鄰 namespace 不變。不同 facade／程序不協調，不新增 persistent fencing。

## feasibility-validation：文件優先結果

來源基線 `2973150b2789d63c10226b57150073ccc793c509`：

- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift`：只有 load/save。
- 同 target `Providers/OAuthTokenProvider.swift`：runRestore／refreshAndPublish 的 await 後未退休檢查；save 後發布。
- 同 target `Stores/GitHubOAuthDataProtectionStores.swift`：精確 selector、clientID binding、同 facade actor；copy/update/add seam 無 delete。
- 同 target `Composition/GitHubClientScope.swift`：scope 強持有原 provider。
- `docs/architecture/github-oauth-dual-client.md` 與 `github-oauth-credential-persistence.md`：現有取消、rotation persistence、actor ownership 及跨 facade 限制。

官方依據：[Swift cancellation](https://docs.swift.org/latest/documentation/swift/task/cancel%28%29/)、[Actor reentrancy](https://developer.apple.com/videos/play/wwdc2021/10133/)、[SecItemDelete](https://developer.apple.com/documentation/security/secitemdelete(_:))、[更新及刪除 Keychain items](https://developer.apple.com/documentation/security/updating-and-deleting-keychain-items)。合作式取消與 actor reentrancy 不自動防止晚到寫回；此設計以 retirement／write barrier 解決。這是來源判讀，不是已執行測試結果。

文件足以支持 concurrency 實作方向，不建立另一套 concurrency experiment；正式 gated tests 驗證實作。指定簽章環境的提示、精確刪除及 fresh-process absence 不能由文件證明，另按 plan 的 E016 候選實驗驗證。狀態目前未執行；不外推其他環境或斷電 durability。

## 工具限制

Graphify 只用既有 graph bounded query 並核對 revision／source，所有 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1；缺 graph 則 rg，未授權不 build。Archify 只產必要一圖，依 skill validation／delivery／visual-check。PR Lens 只映射實際 bounded diff，外部 local-only 產物，不是 correctness review。詳細契約見 execution plan。

## 連結

[需求](requirements.md) · [執行計畫](../../plan/github-oauth-local-sign-out/github-oauth-local-sign-out.plan.md) · [狀態帳本](../../plan/github-oauth-local-sign-out/github-oauth-local-sign-out.step.md)
