# GitHub Integration

## 責任

GitHub Integration 是 Supporting BC，只提供 GitHub authorization 的 lower shared capability。它不擁有、引用或符合任何 consuming Domain BC 的 Port，也不擁有 Domain adapter、endpoint、DTO、外部 failure 正規化或 Domain failure mapping。
## 非責任

- 不定義 PR Inbox 的待審閱規則或 PR Reader 的閱讀模型。
- 不實作各 Domain-owned Port，也不集中提供資料 adapter。
- 不擁有 GitHub endpoint／operation、DTO、infrastructure-failure 正規化或各 Domain failure mapping。
- 不讓 GitHub DTO、HTTP status、token 或 OAuth 細節進入核心 BC。
- 不因為 OAuth 存在而過早形成獨立 Auth BC。
- `RivetHTTPClient` 不屬於 credential lifecycle：不持有或取得 token、不以 `TokenProvider` 作為 public API 或 constructor dependency，也不處理 GitHub authorization policy、refresh 或 401 retry。

## 核心概念與互動

- future authorization seam 屬於 GitHub Integration。初版只預期一個使用者預先提供的 fine-grained PAT；future `GitHubTokenProvider` 的 token-delivery direction、`GitHubAccessToken` value type 與 shared REST request authorizer 都是 declaration-only direction，並非現有 Swift API。provider 的具體 operation signature、`throws`／`Outcome` 選擇、credential failure、refresh 與 re-auth contract 延後至獨立 failure-contract topic。
- 每個 consuming Domain BC 的 local Infra 自己實作自己的 Port。其 local `GitHubRESTAdapter` 可以在每個 GitHub REST request 上採用 shared authorizer，設定或覆寫 Bearer `Authorization` 後交給 `RivetHTTPClient`；同一 BC 的 local `GitHubGraphQLAdapter` 封裝 `ApolloClient`，不經 `RivetHTTPClient.Transport`。Apollo dependency、schema snapshot、`.graphql` operation、codegen、token interceptor 與具體 API operation 均留待獨立 topic。
- OAuth、Keychain、網路與 GitHub API 屬於 Outside。Keychain 與使用者設定的 PAT 都是 Outside；本階段不決定 Keychain identity、entitlement、讀寫 adapter 或 UI，也不採用 OAuth payload、refresh token 或 401 retry。
- local Infra 擁有 endpoint、Base URL、Path、Query、operation、DTO 與 infrastructure-failure 正規化，並在跨越自己的 Port 前映射為該 Domain failure contract。token、OAuth、HTTP status、DTO 與 infrastructure details 不得進入 PR Inbox／PR Reader 的 Core、UseCase 或 Port。
- `packages/RivetHTTPClient/` 是各 local REST adapter 可採用的內部 transport foundation，不是新的 Bounded Context；它提供已驗證 `HTTPURL`、`HTTPRequest`、`HTTPHeaders`、`HTTPClient`、`Requester`、injected `Transport`、package-owned `URLSessionTransport` 與 raw `HTTPResponse` 的最小鏈。package 只將底層 transport failure 正規化為 `HTTPClientError`，不使 HTTP、token 或 infrastructure failure 跨越核心 BC Port。Endpoint、Base URL、Path、Query、status、`Content-Type`、retry、token refresh、decoder configuration 與 response decode policy 都不屬於 package。

## Failure Contract

各 consuming Domain BC 的 local Infra 負責在自己的 adapter 邊界分類與正規化外部失敗；無法安全分類時可產生 `InfraUnknownError`，但不得讓它進入 core Port。local adapter 必須在跨越自己的 Port 前映射為該 Domain 自己的 failure contract。GitHub Integration 不擁有這些 mapping。

## 延後能力

多帳號、GitHub Enterprise、跨裝置同步、雲端 backend 與公開發布需求均不屬於目前 Integration 範圍。
