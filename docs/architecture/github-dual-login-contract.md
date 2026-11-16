# OAuth／PAT 雙登入契約

本契約位於既有 non-BC `GitHubIntegration`，供登入組裝端表達 GitHub.com 的單帳號請求。它只交付 VO、Protocol 與結果語義；沒有正式登入服務、遠端驗證或 UI 接線。

## 請求與結果

```swift
let oauth = LoginRequest.oauth
let token = try PersonalAccessToken(rawValue: "controlled-example-token")
let pat = LoginRequest.pat(token)
// service 是呼叫端提供的 any LoginAuthenticating。
// let outcome = await service.authenticate(pat)
```

`PersonalAccessToken` 使用 `.whitespacesAndNewlines` trim 並保存處理後值；空值或純空白拋出 `PATInputError.empty`。保留內部空白、不檢查 prefix、到期或權限，本地可接受不代表 GitHub 接受。

`LoginRequest.oauth` 不帶配置。未來 concrete service 的組裝端提供 OAuth App configuration；本次不新增該服務。`.pat` 只能持有已完成本地建構的 PAT。

`LoginAuthenticating: Sendable` 的唯一 requirement 是 `authenticate(_:) async -> LoginOutcome`，不拋錯。結果為 `.success`、`.failure(.authenticationFailed)` 或 `.cancelled`。失敗表示本次登入未完成，不證明憑證無效，不含原始 error 或任意訊息。成功是無 payload 標記，沒有帳號、session、token provider 或 clients。

## 取消與敏感資料

Conformer 必須在已取消時直接回 `.cancelled` 且不開始工作；執行中取消須傳遞給原工作，等待其結束。發布結果前最後同步檢查若觀察到取消，取消優先於已就緒的成功／失敗，之後不再 await；檢查後到 return 之間的新取消是競態邊界。已回傳結果不追溯改寫。

Protocol 本身不能強迫 conformer 遵守；本次測試只以受控替身驗證義務，不提供 production driver 或取消管理器。

PAT 與外層 request 的 description、debugDescription 及 customMirror 只呈現固定型別、登入方式及 redacted 標記，不含 token 原值、片段、長度或雜湊；Mirror 不展開 PAT 子值。明確存取 `rawValue` 仍取得敏感值，這不是 debugger 或 process-memory 防護。

## UI 與既有能力

既有 OAuth intent 未來對應 `.oauth`；PAT intent 的文字先經 `PersonalAccessToken` 建構再形成 `.pat`。本次不改 UI intent 的資料或診斷表示。

既有 OAuth configuration／authorization runtime、`OAuthTokenProvider`、`GitHubAccessTokenProvider` 與 `GitHubClientScope` 均不變。Scope 仍只接受具體 OAuth provider；本次契約不宣稱 PAT 可直接取得 scope，也不建立 token bridge。帳號、session 與 client 組裝留待實際接線確認。

## 受控驗證與圖

[受控契約 sequence](diagrams/github-dual-login-contract/login-contract-sequence.html) 描述本地 PAT 拒絕、共同呼叫與結果／取消；不是遠端登入證據。作者內容繁體中文；固定 Viewer UI 與 HTML lang 使用 English fallback。

測試位於 `LoginAuthenticationContractTests`，使用一般 import、Sendable 替身與 continuation／barrier，驗證本地值、共同入口、有限結果、診斷及取消，不使用時間 sleep 推測競態。

重建圖時，以 Archify skill 的 sequence schema／common schema 為準，對同目錄 JSON 執行 showcase validate、deliver，最後對 HTML 執行 visual-check 並指定 repository root；不可直接修改已交付 HTML。驗證、交付與視覺 receipts、四尺寸截圖及人工視覺結論與圖同目錄保存。

本 topic 的 [需求](../../analysis/github-dual-login-contract/requirements.md)、[技術規格](../../analysis/github-dual-login-contract/technical-spec.md)、[計畫](../../plan/github-dual-login-contract/github-dual-login-contract.plan.md) 與 [帳本](../../plan/github-dual-login-contract/github-dual-login-contract.step.md) 保留範圍及獨立審查狀態。受控測試通過不代表真實授權、帳號驗證、持久化、refresh、401 recovery 或正式產品登入已交付。
