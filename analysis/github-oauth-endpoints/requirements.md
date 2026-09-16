# GitHub OAuth Endpoints：Requirements

## Goal

在 `GitHubIntegration` 提供 module-internal 的 `GitHubOAuthEndpoints`，固定描述 GitHub.com OAuth App 的 authorization 與 token HTTPS URL。

## In-Scope

- authorization URL：`https://github.com/login/oauth/authorize`。
- token URL：`https://github.com/login/oauth/access_token`。
- 以 focused tests 驗證兩個 URL 的完整值與 URL components。
- 以 static isolation test 鎖定新增 source file，並維持既有 dependency 與 import 邊界。
- 實作與驗證完成後，將 `GitHubIntegration` 擁有 internal fixed GitHub.com authorization／token URL descriptor 的長期 ownership 結論回寫至 `docs/architecture/README.md`；回寫不得延伸為 request、payload、exchange、refresh 或 credential lifecycle 的架構宣稱。

## Non-Goal

- OAuth login、callback、`state`、PKCE 或 authorization query construction。
- HTTP request、method、headers、body、payload、decode、token exchange、refresh、expiry 或 retry。
- credential、Keychain、store、provider lifecycle。
- public/package API、protocol、configuration、generic endpoint registry、GitHub Enterprise。

## Acceptance Criteria

1. `GitHubOAuthEndpoints` 僅在 `GitHubIntegration` module 內可見。
2. authorization 與 token descriptor 的 URL 值、HTTPS scheme、`github.com` host 與 path 均精確符合 GitHub.com OAuth App endpoint。
3. 兩個 URL 均不含 query 與 fragment。
4. `GitHubIntegration` 不新增 dependency 或 forbidden import，且 public API surface 不變。
5. `docs/architecture/README.md` 僅記錄此 internal fixed GitHub.com authorization／token URL descriptor 的 ownership 結論，不宣稱 request、payload、exchange、refresh 或 credential lifecycle 已由此 topic 定義或實作。
