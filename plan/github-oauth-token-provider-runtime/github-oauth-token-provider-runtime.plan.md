# GitHub OAuth Token Provider Runtime：Execution Plan

建議 branch：`feat/github-oauth-token-provider-runtime`。這是命名建議，不建立或切換 branch。

## Goal

在既有 `GitHubIntegration` target 內交付 `OAuthCredentialStore`、`OAuthTokenFetcher`、`TokenSnapshot` 與 `OAuthTokenProvider`，以 actor 集中 OAuth credential lifecycle，並維持既有 GitHub token contracts 與 generic HTTP auth boundary 不變。

## Swift Implementation Control

### Goal

以受限 allowlist 新增 OAuth provider runtime 與 ports，並回寫其已交付／仍 deferred 的長期架構真相。

### Non-Goal

不擴張為 OAuth adapter、client request lifecycle、generic HTTP auth flow、credential migration 或任何 Domain BC 功能。

### In-Scope

- public contracts、provider actor、finite typed error、injected clock、restore／refresh single-flight、rotation persistence 與 unavailable state。
- Human 已授權的 `GitHubAccessToken` additive `Equatable` conformance；`TokenSnapshot` 保持 `GitHubAccessToken` field type 與 synthesized full equality。
- Human 已鎖定 version semantics：每個 accepted 且成功 persist 的 rotation 均保留 version event，即使其 credential 在 publish 前 expired；version 僅用於 equality/staleness。
- focused async runtime tests、static isolation、architecture writeback 與 OAuth dual-client canvas status update。
- 同 slug 的四份 formal artifacts。

### Out-Of-Scope

- Keychain credential serialization、OAuth HTTP fetcher adapter、authorization/sign-in/PKCE/callback、logout/revoke、多帳號、PAT、GitHub Enterprise。
- REST/GraphQL client integration、Bearer header injection、401 classification、request/operation retry、second-401 handling、credential reconciliation、release 與 Git delivery。

### ReadOnly

- `GitHubTokenProvider`、`GitHubTokenStore`、`TokenStoreGitHubTokenProvider`、`InMemoryGitHubTokenStore`、`KeychainTokenStore`、`GitHubAccessTokenProvider`。
- OAuth DTO、`GitHubOAuthCredentialBundle` mapping、OAuth endpoint descriptor、package manifest、target/product graph 與 toolchain。
- `RivetHTTPClient`、`AuthFlow`、HTTP transport、PR Inbox、PR Reader、其他 Bounded Context source/tests，以及既有 archify lifecycle artifacts。
- 所有未列於 Written 或 Modify 的 tracked path。

### Written

- `analysis/github-oauth-token-provider-runtime/requirements.md`
- `analysis/github-oauth-token-provider-runtime/technical-spec.md`
- `plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.plan.md`
- `plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.step.md`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenFetcher.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/TokenSnapshot.swift`
- `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift`
- `Tests/GitHubIntegrationTests/OAuthTokenProviderTests.swift`

### Modify

- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：僅新增 `GitHubAccessToken: Equatable`；此為 additive public compatibility change，不改變既有 token API。
- OAuth lifecycle status 已不一致的 long-lived architecture documents：設計原則、architecture overview、BC overview／PR Inbox／PR Reader、GitHub API overview 與 OAuth dual-client document。
- `docs/architecture/diagrams/github-oauth-dual-client-architecture/` 的 canvas source、generated artifact 與 visual review；只更新 provider runtime status，不改 client retry boundary。

### Deleted

無。不得刪除、搬移或更名任何 tracked file。

### TestCase

- public consumer 只可取得 `TokenSnapshot`；provider surface 不含 credential bundle 或 refresh token。
- same-version/different-token 的 `hasSameVersion(as:)` 為 true；different-version/same-token 為 false；synthesized `Equatable` 仍要求兩個 properties 都相同。
- `GitHubAccessToken` 的 additive `Equatable` 必須可編譯，且 `TokenSnapshot` 以 `GitHubAccessToken` 與 `UInt64` 的 synthesized full equality 比較；不得以 version-only helper 取代完整 equality。
- valid restore 不 fetch/save；exact expiry 或過期 credential 在 publish 前 refresh。
- 一般無 expiry race 時首個 delivered snapshot 為 v1；首次 restore credential expired 且第一個 persisted rotation 也 expired 時，該 rotation 的 version event 必須保留、provider 必須再次 refresh，首個 delivered snapshot 為 v2。
- `load()` 回傳 `nil` 時，當次回傳 `.missingCredential`，後續 demand 可重新 restore，且不進永久 unavailable。
- concurrent initial restore、expired demand、same-version concurrent recovery 各只執行一次相應 port work；different-version recovery 不 fetch。
- current snapshot 尚不存在時，`replacementSnapshot(afterUnauthorized:)` 必須走正常 restore/expiry path，而不是比較 caller snapshot 或直接 refresh。
- rotation 只在 persist 成功後 publish；三種 port failure 保留 underlying error；persist failure 使 provider 永久 unavailable。
- existing contracts、OAuth schema、static isolation、root suite、architecture-canvas validation、changed-path allowlist 與 diff hygiene 通過。

## Implementation Sequence

1. 在 independent Plan-Reviewer `approved` 後，Implementer 先建立 async store/fetcher fakes 與 injected-clock focused tests。
2. 依 technical spec 新增 contracts 與 actor，維持所有 production source 僅 import `Foundation`。
3. 更新 static isolation；不修改 ReadOnly paths。
4. 回寫 long-lived architecture docs，並依 `architecture-canvas` 更新與驗證 canvas status；不得發布 artifact.cafe，且不變更既有 archify lifecycle artifact。
5. Tester 執行 focused suite、root suite、static isolation、canvas validation、changed-path check 與 diff hygiene；獨立 Reviewer 再檢查 contract/scope drift。

## Human Boundary

僅在獨立 Plan-Reviewer `approved` 後才能實作。Tester 與獨立 Reviewer 完成後停止交還 human；不得自行 commit、push、開 PR、release 或處理後續 review comment。
