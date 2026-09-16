# GitHub OAuth Endpoints

建議 branch：`feat/github-oauth-endpoints`。

## Goal

新增 module-internal `GitHubOAuthEndpoints`，固定描述 GitHub.com OAuth App 的 authorization 與 token HTTPS URL。

## Non-Goal

不建立 OAuth login、callback、PKCE、HTTP execution、token exchange／refresh、credential lifecycle 或任何 public API。

## In-Scope

- GitHub.com OAuth authorization 與 token URL descriptor。
- focused `@testable import` tests。
- static-isolation source-file exact-set 的最小更新。
- 將 `GitHubIntegration` 擁有 internal fixed GitHub.com authorization／token URL descriptor 的長期結論回寫至 `docs/architecture/README.md`。
- 同 slug 的 requirements、technical spec、plan 與 step ledger。

## Out-Of-Scope

- authorization query、callback、`state`、PKCE、HTTP method/header/body/payload/decode。
- token exchange、refresh、expiry、retry、credential、Keychain、store 或 provider lifecycle。
- public/package API、protocol、configuration、generic registry、GitHub Enterprise、`Package.swift`、其他 docs 與 diagrams。

## ReadOnly

- `README.md`、`docs/**`（僅 `docs/architecture/README.md` 依 Modify allowlist 可變更）、`Package.swift`、所有 package target/product declarations。
- `Sources/BoundedContexts/GitHubIntegration/**`，但新增 endpoint source 除外。
- `Tests/GitHubIntegrationTests/**`，但 focused endpoint test 與 `StaticIsolationTests.swift` 除外。
- 所有未列於 Written 或 Modify 的 tracked paths。

## Written

- `analysis/github-oauth-endpoints/requirements.md`
- `analysis/github-oauth-endpoints/technical-spec.md`
- `plan/github-oauth-endpoints/github-oauth-endpoints.plan.md`
- `plan/github-oauth-endpoints/github-oauth-endpoints.step.md`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthEndpoints.swift`
- `Tests/GitHubIntegrationTests/GitHubOAuthEndpointsTests.swift`

## Deleted

無。不得刪除、搬移或更名任何 tracked file。

## Modify

- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：只將 `OAuth/GitHubOAuthEndpoints.swift` 加入 source-file exact set；既有 product、target graph、dependency 與 forbidden-import assertions 不變。
- `docs/architecture/README.md`：只回寫 `GitHubIntegration` 擁有 internal fixed GitHub.com authorization／token URL descriptor 的長期結論；不得宣稱 request、payload、exchange、refresh 或 credential lifecycle 已定義或實作。

## Swift Implementation

1. 先新增 focused failing tests，證明 internal endpoint descriptor 尚不存在。
2. 以最小 `GitHubOAuthEndpoints` source 實作兩個固定 `URL`。
3. 更新 static isolation exact set，執行 focused tests 與 root `swift test`。
4. 確認 diff 僅在 Written／Modify allowlist，且 `git diff --check` 通過。

## TestCase

| ID | 驗收 |
| --- | --- |
| TC-01 | authorization descriptor 等於 `https://github.com/login/oauth/authorize`，為 HTTPS、`github.com`、`/login/oauth/authorize`，且無 query/fragment。 |
| TC-02 | token descriptor 等於 `https://github.com/login/oauth/access_token`，為 HTTPS、`github.com`、`/login/oauth/access_token`，且無 query/fragment。 |
| TC-03 | static isolation source set 含新增 source，且 integration target 無 dependency 與無 forbidden imports。 |
| TC-04 | root `swift test` 與 `git diff --check` 通過。 |
| TC-05 | `docs/architecture/README.md` 只包含狹義 internal fixed GitHub.com authorization／token URL descriptor ownership 回寫，未宣稱 request、payload、exchange、refresh 或 credential lifecycle。 |
