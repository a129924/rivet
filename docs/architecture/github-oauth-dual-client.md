# GitHub OAuth 雙 Client 架構

## Goal

鎖定 GitHub OAuth App 的可 refresh、會過期 credential bundle shared token lifecycle：`GitHubIntegration` 已交付 `OAuthTokenProvider` runtime 與 adapter ports，未來 GitHub REST client 與 Apollo GraphQL client 可共用同一 instance。provider 在 access token 過期時先更新；client 收到 401 後的 snapshot recovery 與原工作 retry 仍未實作。

這是長期**架構文件**，不是 OAuth、client 或 retry 的 runtime 實作規格。

## Non-Goal

- 已交付 internal OAuth App token-response DTO → public immutable credential bundle mapping，以及 public `OAuthCredentialStore`／`OAuthTokenFetcher` ports、`TokenSnapshot` 與 actor-isolated `OAuthTokenProvider` finite failure contract；不定義 Keychain credential storage schema 或 OAuth endpoint request payload。
- 不實作 OAuth authorization code、PKCE、callback、初次 sign-in、logout、revoke、多帳號、PAT 或 GitHub Enterprise。
- 不定義 Domain endpoint、DTO、GraphQL schema、rate limit、pagination、一般 retry 或各 Bounded Context 的 failure mapping。
- 不修改 `RivetHTTPClient`，也不讓其 `Auth`／`AuthFlow` 成為 OAuth runtime driver。

## 責任與依賴

[責任與依賴 canvas](diagrams/github-oauth-dual-client-architecture/index.html) 只呈現 component ownership 與 dependency；它刻意不表達 request sequence。 [Token lifecycle](diagrams/github-oauth-dual-client-architecture/token-lifecycle-v6.html) 則呈現 expiry-valid snapshot、401-only response recovery 與一次 retry；其 canonical／歷史 evidence 狀態見 [圖表說明](diagrams/github-oauth-dual-client-architecture/README.md)。

```text
Facade（layer 外的 application composition root）
  ├─ bare RivetHTTPClient / URLSessionTransport
  ├─ OAuthCredentialStore adapter（deferred）
  ├─ OAuthTokenFetcher adapter（bare HTTP，deferred）
  ├─ OAuthTokenProvider(OAuthCredentialStore, OAuthTokenFetcher)
  ├─ GitHub REST client(TokenProvider, bare HTTP sender／request executor)
  └─ GitHub GraphQL client(TokenProvider, Apollo)
```

- `GithubIntegration` 是 Bounded Context 外、GitHub-specific 的 shared integration module；它不是 BC，不依賴任何 BC，也不擁有 Domain Port、DTO translation、BC failure mapping 或 business meaning。
- Facade 是 layer 外的 application composition root，只負責 composition：建立唯一共享的 `OAuthTokenProvider` instance，並注入 REST 與 GraphQL client。它不在每個工作前預先驗證 token，也不改變各 BC 的 `Facade → UseCase → Port` 層級方向。
- `RivetHTTPClient`／`URLSessionTransport` 是 bare、generic、GitHub-unaware foundation；bare `HTTPClient` 只執行 raw HTTP request，不認識 OAuth、Bearer、TokenProvider、401 recovery 或 retry，也不直接建立或驅動 `AuthFlow`。
- `RivetHTTPClient` 既有 internal `AuthRequester` runtime：它注入 `Requester` 與 caller-provided generic `Auth`，建立並驅動 generic `AuthFlow` 的 `.send(HTTPRequest) → raw HTTPResponse → receive(response)` loop，直到 `.finish`；flow 保有 authentication decision。這條 generic capability 不持有 credential、retry 或 GitHub OAuth lifecycle。
- 已交付 schema 接受 GitHub OAuth App 的六欄 refreshable、expiring token response，並由 internal DTO 在 caller-supplied `receivedAt` 映射為 public immutable `GitHubOAuthCredentialBundle`。public `OAuthCredentialStore`／`OAuthTokenFetcher` ports 在 adapter boundary 使用完整 bundle；OAuth Keychain adapter 與 bare-HTTP fetcher 未交付。
- `OAuthTokenProvider` 是唯一 lifecycle owner：記憶體 credential、restore、expiry-first refresh、accepted rotation persistence、version 與 single-flight。remote rotation accepted 後的 persistence failure 使 provider 永久 unavailable；它不持有、不接收、不重送 `HTTPRequest` 或 Apollo operation。
- `TokenSnapshot` 是 public immutable、`Equatable`、`Sendable` client input，只包含 access token 與 version；`hasSameVersion(as:)` 只比較 version。refresh token 與完整 bundle 不會暴露給 client。
- 本 topic 不取代目前 public `GitHubTokenProvider`／`GitHubTokenStore` 的 access-token contract，也不定義 adapter、supersession 或 migration。另已交付的 async `GitHubAccessTokenProvider` 只表示 token acquisition；新的 OAuth provider 不 conform 或 bridge 它，也不實作 request、transport、401 classification 或 retry。
- REST client 由 Facade 注入 bare HTTP sender／request executor 與 `TokenProvider`，並保有自己的 `HTTPRequest`；GraphQL client 保有自己的 Apollo operation。兩者只共用 provider instance，不互相呼叫，GraphQL 亦不經 REST route。

## Token Lifecycle

1. REST 或 GraphQL client 向 provider 取得 expiry-valid `TokenSnapshot`；若 snapshot 已到期，Provider 先完成自身更新，再將 access token 交給 client 加為 `Authorization: Bearer`。
2. 每個 client 走自己的 transport route 送出原工作。
3. 401 是此 lifecycle 唯一的**回應狀態**復原觸發；expiry check 是 Provider 交付 snapshot 前的內部責任，不是 response-status policy。非 401 回應由 consuming BC 的 local Infra 依自己的 adapter boundary 處理；403、repository permission 與 resource visibility 不觸發 refresh。
4. 收到 401 時，client 回報**實際使用的 snapshot**。若 provider 已有更高 version，直接回傳目前 snapshot；若仍是相同 stale version，僅 single-flight refresh 一次。
5. 已交付 provider 在 refresh 成功時接受遠端 rotated credential bundle，先持久化完整新 bundle，再更新記憶體 snapshot/version，最後讓等待者取得新版 snapshot。僅在接受遠端 rotation 前發生的暫時性 technical failure 才保留既有 credential；若遠端 rotation 已接受而本地 persistence 失敗，provider 不再交付 snapshot，credential reconciliation 留待後續獨立 topic。
6. 原 client 以新版 snapshot 重送自己的原 request／operation 一次；每個原工作最多 retry 一次。

| 狀況 | Outcome |
| --- | --- |
| 無 credential、refresh failure、重送後第二次 401 | provider 分別回傳 `.missingCredential`／`.refresh`；Facade re-auth 與第二次 401 policy deferred |
| 暫時性 refresh／Keychain／網路失敗，且遠端 rotation 尚未接受 | provider 的 `.refresh` 保留 credential；Keychain adapter／client outcome deferred |
| 遠端 rotation 已接受後的本地 persistence failure | provider `.persist` 後永久 unavailable；不宣稱舊 bundle 仍可用，credential reconciliation 留待後續 topic |
| 403、repository permission、resource visibility | 非 token-invalid signal；不 refresh |

## Boundary 與後續 Topic

OAuth technical failure 不跨越成 shared BC failure contract；未來由 consuming BC 的 local Infra 映射為該 BC 自己的 failure contract。

初次 OAuth sign-in、authorization code + PKCE、callback、logout／revoke 與 multi-account 必須以獨立 topic 處理。本文件 supersede `github-integration-auth-boundary` 的 PAT-only、REST-only authorizer 方向；該歷史 topic 僅保留 traceability，沒有被改寫或刪除。
