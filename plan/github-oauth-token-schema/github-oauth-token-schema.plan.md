# GitHub OAuth Token Schema：執行計畫

## Summary

在 `GitHubIntegration` 以 internal DTO 實作 GitHub OAuth App six-field token response 到 immutable public `GitHubOAuthCredentialBundle` 的 mapping。此為 schema-only slice：bundle 是未來 TokenStore 的完整 atomic replacement unit；本次不實作 store、refresh 或任何 OAuth runtime。

## Contract

### Goal

交付可 refresh、會過期的 GitHub OAuth App credential schema。`credential(receivedAt:)` 以外部注入的 receipt time 將兩個 response relative expiry 換成 absolute `Date`，並僅把 bundle 交給未來 TokenStore。

### Non-Goal

PAT、credential-kind union、OAuth request/refresh runtime、Keychain、TokenStore/provider implementation、client、retry、migration、GHES fallback、non-expiring credential、OAuth lifecycle ownership、failure contract 及既有 access-token contract 改動都不在本 topic。

### In-Scope

- `GitHubOAuthTokenResponse` 維持 internal，decodes six non-optional snake-case fields。
- public `GitHubOAuthRefreshToken`、`.bearer`-only `GitHubOAuthTokenType`、immutable `GitHubOAuthCredentialBundle` 均宣告 `Sendable`；其前提是既有 `GitHubAccessToken` 已有 `Sendable`，不得修改它。
- bundle public initializer 收取六個無預設值參數：access token、refresh token、兩個 absolute expiry、token type 和 `grantedScopes`。
- `credential(receivedAt:)` 必須由 caller supplied time 實作 expiry mapping；scope 原字串保留，不提供 scope parsing utility。
- refresh success 的 future semantics 是完整新 bundle 原子取代舊 bundle；本 topic 僅保留其 data boundary。

### Out-Of-Scope

- `ghu_` fixture、space-delimited response scope、non-expiring OAuth token、missing refreshable fields 或 GHES fallback。
- HTTP endpoint、headers/body、secret/grant、network decoding、rotation/store-write policy、persistence failure 與 retry。
- 所有 package target/product、`RivetHTTPClient`、REST/GraphQL/Apollo client、Domain BC、PAT 和 architecture diagram 修改。

### ReadOnly

- `Package.swift`、現有 GitHub access token/store/provider source、public contracts 與 implementation。
- `RivetHTTPClient`、all BC source/tests、OAuth runtime、PAT、Keychain、client source、history artifacts 和未明列 docs/diagrams。

### Written

- `analysis/github-oauth-token-schema/requirements.md`
- `analysis/github-oauth-token-schema/technical-spec.md`
- `plan/github-oauth-token-schema/github-oauth-token-schema.plan.md`
- `plan/github-oauth-token-schema/github-oauth-token-schema.step.md`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift`
- `Tests/GitHubIntegrationTests/GitHubOAuthCredentialBundleTests.swift`

### Modify

- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：新增 production source 的 exact-set 與 forbidden dependency verification。
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`：只從 public module surface 建構／讀取 bundle 並檢查 `Sendable`；不得存取 DTO。
- `docs/architecture/github-oauth-dual-client.md`：回寫 OAuth App issuer、已交付 schema/mapping 與 future atomic replacement，並保留 runtime/provider/store/client/retry/persistence deferred。

### Deleted

無；不得刪除、搬移或更名 tracked file。

## Implementation Sequence

1. 在 Plan Review approved 後，Implementer 先新增 fixture-driven focused tests。
2. 實作 single Foundation-only contract source，僅包含 DTO → bundle mapping 及被允許的 public values。
3. 補 isolation/public-consumer coverage，最小回寫 architecture doc；不得新增 runtime capability。
4. Tester 先執行 focused test，再執行 root suite、consumer fixture、static isolation 與 diff hygiene。
5. Independent Reviewer 檢查 path allowlist、no DTO leak、no PAT/runtime/store/client/migration drift 與 evidence。approved 後才可 delivery。

## TestCase

- Decode fixture 六個 snake-case fields，使用 `gho_...`、`ghr_...`、`repo,gist`、`28800`、`15897600`。
- Fixed `receivedAt` 轉為正確兩個 absolute expiries，bundle 不保存 relative seconds。
- 任一必要欄位缺失、refresh token 缺失、任一 expiry 缺失、unknown token type 都 decode fail。
- access token、refresh token、token type、scope 原樣保留；test output 不輸出 token。
- consumer 可使用公開 bundle 而不能存取 internal DTO；new public values 都驗證 `Sendable`。
- source isolation 阻擋 HTTP client、Security/Keychain、Apollo 和 PAT dependencies；existing access-token provider/store contract 保持可編譯。

## Delivery Boundary

僅在獨立 Plan-Reviewer、Tester 與 Reviewer 都沒有 blocker、且所有 scope/path checks 合格後，才能由授權的 Implementer 依 topic 建立單一 commit、non-force push 並開 draft PR。draft PR 開啟後立即停止於 human review；不得 auto-merge、release、rebase、force push 或處理未授權 review comment。
