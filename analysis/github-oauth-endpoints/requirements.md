# GitHub OAuth Endpoints：Requirements

## Goal

在 `GitHubIntegration` 提供 module-internal 的 `GitHubOAuthEndpoints`，固定描述 GitHub.com OAuth App 的 authorization 與 token HTTPS URL。

## In-Scope

- authorization URL：`https://github.com/login/oauth/authorize`。
- token URL：`https://github.com/login/oauth/access_token`。
- 以 focused tests 驗證兩個 URL 的完整值與 URL components。
- 以 static isolation test 鎖定新增 source file，並維持既有 dependency 與 import 邊界。

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
