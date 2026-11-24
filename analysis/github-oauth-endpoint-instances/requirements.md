# GitHub OAuth Endpoint 實例化需求

Topic `github-oauth-endpoint-instances`，規劃基線為本地 `dev` 的 `c389454`。使用者已確認對話計畫並授權在獨立 feature worktree 實作。

## 問題與結果

正式授權 session、code exchange 與 refresh 目前讀取靜態 OAuth URL。這次將 GitHub.com 的授權與 token 目的地各建成一個模組內 Endpoint 實例。授權 session 使用授權實例，交換與刷新共用 token 實例。兩個實例的責任限於固定 URL，呼叫點沿用瀏覽器 GET 與兩種 token POST。

兩個 Endpoint 隸屬 BC 外的 `GitHubIntegration`。驗收以現行公開 OAuth API、實際 URL、兩種 POST 的表單與標頭，以及呼叫端的成功、拒絕與取消結果為基準。保留 callback 驗證、state、S256 PKCE、輪替及一次嘗試的相容性。資料沿用現有 session 與憑證物件，程式與文件可一併回退。

## 範圍與驗收

- 授權 URL 維持 `https://github.com/login/oauth/authorize` 與既有六個 query 項目。無效 callback 不觸發交換，有效 callback 在該 session 只觸發一次交換。
- 交換與刷新使用同一個 `https://github.com/login/oauth/access_token` 實例。用測試 transport 擷取實際 POST，以合成資料核對方法、URL、標頭、表單、成功結果、拒絕、取消與嘗試次數。
- 回寫正式 OAuth 文件中的 Endpoint 歸屬。PR Reader diff 標頭與新增 HeadersProvider 需求屬其他題目。登入 UI、憑證儲存、輪替策略、重試及傳輸策略按各自現有契約管理。驗收使用離線測試。

[技術規格](technical-spec.md) · [受限執行計畫](../../plan/github-oauth-endpoint-instances/github-oauth-endpoint-instances.plan.md)
