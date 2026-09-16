# GitHub Async Access Token Provider

建議 branch：`feat/github-async-access-token-provider`。

## Goal

新增 async、可跨 task／actor 傳遞的 `GitHubAccessTokenProvider`；成功只保證 token 在回傳當下可供送出。

## Non-Goal

- 不實作 PAT／OAuth provider、refresh、expiry、401 recovery、forced refresh、retry、`AsyncHttpSender` 或 authorization header。
- 不修改、deprecated、adapter 化或遷移同步 `GitHubTokenProvider`／`GitHubTokenStore`。
- 不改 root manifest、module target、`RivetHTTPClient`、PR Inbox、PR Reader 或 `InMemoryGitHubTokenStore` 的並行模型；不發布 canvas。

## In-Scope

- `GitHubAccessTokenProvider: Sendable` 與 `async throws(GitHubCredentialError)` 的 `token()`。
- credential value/error 的完整 `Sendable` surface，以及 `.tokenAcquisition(any Error & Sendable)`。
- internal／external consumer tests、static isolation、architecture docs 與既有 OAuth canvas。

## Out-Of-Scope

- OAuth endpoint/payload/HTTP mapping、lifecycle state machine、GraphQL interceptor、REST adapter 與 shared BC failure mapping。
- 新舊 protocol 的 migration 或 compatibility layer。

## ReadOnly

- `Package.swift`、所有 target/product declarations、toolchain、CI、hooks 與 consumer manifest。
- `GitHubTokenProvider.swift`、`GitHubTokenStore.swift`、`TokenStoreGitHubTokenProvider.swift`、`InMemoryGitHubTokenStore.swift`。
- `RivetHTTPClient`、PR Inbox／PR Reader source/tests、OAuth canonical/historical lifecycle evidence，以及所有未列於 Written/Modify 的 tracked paths。

## Written

- `analysis/github-async-access-token-provider/requirements.md`
- `analysis/github-async-access-token-provider/technical-spec.md`
- `plan/github-async-access-token-provider/github-async-access-token-provider.plan.md`
- `plan/github-async-access-token-provider/github-async-access-token-provider.step.md`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubAccessTokenProvider.swift`
- `Tests/GitHubIntegrationTests/GitHubAccessTokenProviderTests.swift`

## Deleted

無。不得刪除、搬移或更名任何 tracked file。

## Modify

- `CredentialTypes.swift`：讓 credential values/errors 符合 `Sendable`，並新增 generic acquisition failure。
- 既有 provider tests、static isolation test、external consumer public API tests。
- 長期 architecture docs，以及 OAuth canvas 的 `scene.js`、generated `index.html`、visual screenshots 與 review。

## Swift Implementation

1. 新增 external fake 的 red test，證明 public async typed-throws contract 尚不存在。
2. 實作最小 protocol 與 credential `Sendable` changes；不新增 conformer。
3. 使 internal／consumer／static-isolation tests 綠燈，並維持舊同步 provider regression。
4. 文件與 canvas 僅表達已交付 contract、未交付 lifecycle；完成 canvas validate、build、accessibility 與 visual review。

## TestCase

| ID | 驗收 |
| --- | --- |
| TC-01 | external `Sendable` fake 可 conform，且 `await token()` 原樣回傳 token。 |
| TC-02 | `.tokenAcquisition` 保留 `Error & Sendable` payload。 |
| TC-03 | token、store error、credential error 與 provider surface 均通過 compile-time `Sendable` 驗證。 |
| TC-04 | 同步 provider 維持原 token、missing credential 與 store-error mapping。 |
| TC-05 | static isolation source set 含新 contract，且無 HTTP/Keychain/Security/Apollo imports。 |
| TC-06 | consumer 僅 import `GitHubIntegration` 即可使用新 public async contract。 |
| TC-07 | docs/canvas 不宣稱 lifecycle implementation；canvas checks 通過且不發布。 |
| TC-08 | root build/tests、consumer validation 與 `git diff --check` 通過。 |
