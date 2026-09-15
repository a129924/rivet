# GitHub OAuth 雙 Client 架構

## Goal

鎖定既有 GitHub OAuth credential 的 shared token lifecycle：同一個 `OAuthTokenProvider` 供 GitHub REST client 與 Apollo GraphQL client 共用。access token 過期或某個原工作收到一次 401 時，client 取得新版 snapshot，並只重送自己的原工作一次。

這是長期**架構文件**，不是 OAuth、client 或 retry 的 runtime 實作規格。

## Non-Goal

- 不定義 Swift 型別、方法、actor isolation、storage schema、endpoint payload 或 failure enum。
- 不實作 OAuth authorization code、PKCE、callback、初次 sign-in、logout、revoke、多帳號、PAT 或 GitHub Enterprise。
- 不定義 Domain endpoint、DTO、GraphQL schema、rate limit、pagination、一般 retry 或各 Bounded Context 的 failure mapping。
- 不修改 `RivetHTTPClient`，也不讓其 `Auth`／`AuthFlow` 成為 OAuth runtime driver。

## 責任與依賴

[責任與依賴 canvas](diagrams/github-oauth-dual-client-architecture/index.html) 只呈現 component ownership 與 dependency；它刻意不表達 request sequence。 [Token lifecycle](diagrams/github-oauth-dual-client-architecture/token-lifecycle-v2.html) 則呈現 snapshot、401 recovery 與一次 retry。

```text
Facade（composition root）
  ├─ bare RivetHTTPClient / URLSessionTransport
  ├─ KeychainTokenStore
  ├─ OAuthTokenFetcher(bare HTTP)
  ├─ OAuthTokenProvider(TokenStore, TokenFetcher)
  ├─ GitHub REST client(TokenProvider)
  └─ GitHub GraphQL client(TokenProvider, Apollo)
```

- `GithubIntegration` 是 Bounded Context 外、GitHub-specific 的 shared integration module；它不是 BC，不依賴任何 BC，也不擁有 Domain Port、DTO translation、BC failure mapping 或 business meaning。
- Facade 只負責 composition：建立唯一共享的 `OAuthTokenProvider` instance，並注入 REST 與 GraphQL client。它不在每個工作前預先驗證 token。
- `RivetHTTPClient`／`URLSessionTransport` 是 bare、generic、GitHub-unaware foundation；它不認識 OAuth、Bearer、TokenProvider、401 recovery 或 retry。
- `RivetHTTPClient.Auth`／`AuthFlow` 是獨立的 generic declarations-only state-machine contract。HTTPClient 不建立、驅動或解讀 flow；此 OAuth lifecycle 亦不由它承擔。
- `TokenStore` 只讀寫完整 OAuth credential bundle。`OAuthTokenFetcher` 只透過 bare HTTP 呼叫 GitHub OAuth token endpoint，並回傳完整 rotated bundle。
- `OAuthTokenProvider` 是唯一 lifecycle owner：記憶體 snapshot、restore、expiry、refresh、rotation、version 與 single-flight。它不持有、不接收、不重送 `HTTPRequest` 或 Apollo operation。
- `TokenSnapshot` 是 client 的 immutable input，只包含 access token 與 version；refresh token 與完整 bundle 不會暴露給 client。
- REST client 保有自己的 `HTTPRequest`；GraphQL client 保有自己的 Apollo operation。兩者只共用 provider instance，不互相呼叫，GraphQL 亦不經 REST route。

## Token Lifecycle

1. REST 或 GraphQL client 向 provider 取得有效 `TokenSnapshot`，並將 access token 加為 `Authorization: Bearer`。
2. 每個 client 走自己的 transport route 送出原工作。
3. 非 401 回應由 consuming BC 的 local Infra 依自己的 adapter boundary 處理；403、repository permission 與 resource visibility 不觸發 refresh。
4. 收到 401 時，client 回報**實際使用的 snapshot**。若 provider 已有更高 version，直接回傳目前 snapshot；若仍是相同 stale version，僅 single-flight refresh 一次。
5. refresh 成功時，provider 先保存完整 rotated credential bundle，再更新記憶體 snapshot/version，最後讓等待者取得新版 snapshot。
6. 原 client 以新版 snapshot 重送自己的原 request／operation 一次；每個原工作最多 retry 一次。

| 狀況 | Outcome |
| --- | --- |
| 無 credential、永久 refresh failure、重送後第二次 401 | `authentication-required`，交由 Facade 導向重新登入 |
| 暫時性 refresh／Keychain／網路失敗 | technical failure；保留 credential，不強制重新登入 |
| 403、repository permission、resource visibility | 非 token-invalid signal；不 refresh |

## Boundary 與後續 Topic

OAuth technical failure 不跨越成 shared BC failure contract；未來由 consuming BC 的 local Infra 映射為該 BC 自己的 failure contract。

初次 OAuth sign-in、authorization code + PKCE、callback、logout／revoke 與 multi-account 必須以獨立 topic 處理。本文件 supersede `github-integration-auth-boundary` 的 PAT-only、REST-only authorizer 方向；該歷史 topic 僅保留 traceability，沒有被改寫或刪除。
