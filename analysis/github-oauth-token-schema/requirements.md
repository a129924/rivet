# GitHub OAuth Token Schema：需求

## Goal

為 `GitHubIntegration` 建立 GitHub OAuth App 的 token-response schema：將 internal wire DTO 映射為公開、immutable、可 refresh 且會到期的 `GitHubOAuthCredentialBundle`。未來 `TokenStore` 只讀寫完整 bundle；refresh 成功後的新 bundle 必須完整、原子取代舊 bundle。

## Non-Goal

- 不實作 OAuth authorization code、PKCE、device flow、callback、初次 sign-in、logout、revoke、多帳號或 GitHub Enterprise。
- 不實作 token endpoint request、client ID／secret handling、refresh runtime、rotation runtime、TokenStore、Keychain、persistence、client、401 recovery、retry 或 migration。
- 不加入 PAT、credential-kind union、OAuth／PAT 共用 abstraction，亦不改變既有 `GitHubAccessToken`、`GitHubTokenStore`、`GitHubTokenProvider` public contract。
- 不定義 OAuth lifecycle ownership、snapshot/version、failure enum、actor isolation、serialization format 或 domain BC behavior。

## In-Scope

- issuer 固定為 GitHub OAuth App；不支援 GitHub App user access token。
- 新增 internal `GitHubOAuthTokenResponse: Decodable`，以 snake-case `CodingKeys` 解碼六個 non-optional 欄位：`access_token`、`token_type`、`scope`、`expires_in`、`refresh_token`、`refresh_token_expires_in`。
- 新增 public `GitHubOAuthRefreshToken: Sendable`、`GitHubOAuthTokenType: String, Decodable, Sendable`（僅 `.bearer`）與 immutable `GitHubOAuthCredentialBundle: Sendable`。既有 `GitHubAccessToken` 已 conform `Sendable`，故本 topic 的三個新增公開 value type 必須明示 conform `Sendable`。
- bundle 保存 access token、refresh token、access-token absolute expiry、refresh-token absolute expiry、token type 與 `grantedScopes: String`；public initializer 的六個參數均不得有預設值。
- DTO 提供 internal `credential(receivedAt:)`；呼叫端必須傳入 `receivedAt`，以兩個 relative expiry seconds 換算 absolute `Date`。bundle 不得保存 relative seconds。
- `grantedScopes` 原樣保存 GitHub token response 的 comma-delimited 字串；不得拆分、排序、正規化或提供 `hasScope(...)`。
- 缺任一 refreshable credential 必要欄位，或 `token_type` 非 `bearer`，均以既有 `Decodable` failure 拒絕。

## Out-Of-Scope

- non-expiring OAuth token、缺 refresh token 或任一 expiry 的 response，以及 GHES fallback。
- authorization request 的 space-delimited scope；本 topic 僅處理 response 的原始 comma-delimited scope。
- endpoint URL、HTTP headers／body、OAuth client secret、grant parameter、network error decoding、refresh rotation policy、store atomic write 或 persistence failure。
- `RivetHTTPClient`、REST／GraphQL／Apollo client、任何 Domain Bounded Context、package target/product、OAuth dual-client runtime 與既有 architecture diagram。

## Success Criteria

- internal DTO 可將 GitHub OAuth App 的六欄 token response 轉為 public credential bundle，而 public consumer 無法接觸 DTO。
- `credential(receivedAt:)` 僅保存 computed absolute expiry，保留 access token、refresh token、token type 與 scope 原值。
- 未來 refresh 成功後可將完整新 bundle 作為 atomic replacement 單位；本 topic 不實作該 store action。
- 新 source 僅依賴 Foundation，不依賴 HTTP client、Security／Keychain、Apollo 或 PAT implementation。

## ReadOnly

- `Package.swift`、既有 `GitHubAccessToken`、`GitHubTokenStore`、`GitHubTokenProvider` 及其 provider/store implementation。
- `RivetHTTPClient`、PR Inbox、PR Reader、所有其他 Domain BC、OAuth runtime、REST／GraphQL client、PAT source 與 Keychain topic。
- 除本 topic 明列 Modify 外的 architecture docs、diagram artifacts、歷史 topic artifacts 與 tracked paths。

## Written

- 本 topic 的四份 planning artifacts。
- 實作階段新增 `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift`：public wrappers、token-type enum、bundle、internal DTO 與 mapping；僅依賴 Foundation。
- 實作階段新增 `Tests/GitHubIntegrationTests/GitHubOAuthCredentialBundleTests.swift`：DTO decode 與 receipt-time mapping tests。

## Modify

- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：將新增 source 納入 exact production-source set，並維持禁止 HTTP client、Security／Keychain、Apollo 與 PAT dependencies 的 isolation assertion。
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`：consumer 僅以 `import GitHubIntegration` 使用 bundle 的 public initializer 與 public properties，並驗證新公開 type 的 `Sendable` surface；不得使用或暴露 internal DTO。
- `docs/architecture/github-oauth-dual-client.md`：只回寫本 topic 已交付的 GitHub OAuth App schema／mapping 與 future full-bundle atomic replacement；保留 provider、lifecycle runtime、TokenStore、client、retry、persistence deferred，且不改動既有 dual-client ownership decision。

## Deleted

無。不得刪除、搬移或更名任何 tracked file。

## TestCase

- six-field snake-case JSON decode：fixture 使用 `gho_...` access token、`ghr_...` refresh token、`scope: "repo,gist"`、`expires_in: 28800` 與 `refresh_token_expires_in: 15897600`；不得使用 `ghu_...` 或 space-delimited response scope。
- 固定 `receivedAt` 時，兩個 relative seconds 精確換算為兩個 absolute expiry，且 bundle 無 relative-seconds property。
- 缺少任一必要欄位（包括 refresh token 與兩個 expiry）或 unknown `token_type` 時 decode failure。
- access token、refresh token、`grantedScopes` 與 token type 原樣保留；assertion 或 diagnostic 不得輸出 token 值。
- public consumer 只能使用 public bundle，internal DTO 不可見；新增 public wrappers、enum 與 bundle 都通過 compile-time `Sendable` surface 驗證。
- static isolation 確認新增 source 不 import HTTP client、Keychain、Apollo 或 PAT implementation；既有 access-token store/provider contract 持續編譯。

## 參考

- GitHub 官方 OAuth App authorization documentation：<https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps>
