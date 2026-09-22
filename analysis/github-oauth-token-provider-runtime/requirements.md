# GitHub OAuth Token Provider Runtime：Requirements

## Goal

在 `GitHubIntegration` 交付 OAuth credential lifecycle runtime。它必須只向 client 交付 access token 與 version 的 immutable snapshot，並在 async concurrent demand 下避免重複 restore 或 refresh。

## In-Scope

- public、`Sendable`、async injectable `OAuthCredentialStore` 與 `OAuthTokenFetcher` ports。
- public immutable `TokenSnapshot: Equatable, Sendable`，具有 `accessToken`、`UInt64 version` 與僅比較 version 的 `hasSameVersion(as:)`。
- Human 已選擇 A：既有 `GitHubAccessToken` 可 additive conform `Equatable`，使 `TokenSnapshot` 在維持 field type 為 `GitHubAccessToken` 的前提下使用 synthesized full equality。
- `OAuthTokenProvider` actor 的 restore、expiry-first refresh、accepted rotation persistence、version、single-flight 與 persist-failure unavailable state。
- Human 已選擇 A：version 代表每次 accepted 且成功 persist 的 credential rotation；rotation 即使在 publish snapshot 前已 expired，也不得抹去其 version event。
- Human 已鎖定 post-persist expiry policy A：rotation 在 publish 前 expired 後，最多再 refresh/persist 一次；第二次仍 expired 時終止，並以既有 `.refresh` 包裝 private exhausted error，不新增 public failure case。
- provider 專屬 finite typed error：missing credential、restore、refresh、persist，並保留 `Error & Sendable` underlying error。
- focused runtime tests、static isolation、已交付／deferred boundary 的 long-lived architecture writeback，以及 OAuth dual-client canvas status update。

## Success Criteria

- provider 的 client-facing methods 只回傳 `TokenSnapshot`；refresh token 與完整 credential bundle 不會出現在 snapshot 或 recovery surface。
- `accessTokenExpiresAt <= now()` 時必須在交付 snapshot 前 refresh；相同 concurrent demand 只共享一次 restore／refresh work。
- caller 以實際 `TokenSnapshot` 回報未授權結果時，只有 same-version 才 refresh；different-version 直接回傳 current snapshot，且不比較 token 字串。
- remote accepted rotation 必須先 persist 才 publish 新 snapshot；persist 失敗後 provider 不再交付 snapshot 或呼叫 ports。
- `TokenSnapshot.version` 只用於 equality 與 staleness。一般無 expiry race 時首個 delivered snapshot 是 v1；若首次 restore 的 credential已 expired 且第一個 persisted rotation 又已 expired，provider 最多再 refresh/persist 一次；第二次仍 expired 時以 `.refresh` 終止，否則首個 delivered snapshot 可以是 v2。每次 successful persist 都保留 version event。
- `GitHubAccessToken` 的 `Equatable` 為 additive public compatibility change：不移除、不更名或改變既有 token API，僅支援 `TokenSnapshot` 的 synthesized `Equatable`。

## Non-Goals

- Keychain credential serialization、OAuth HTTP fetcher adapter、sign-in／PKCE／callback、logout／revoke、多帳號、PAT 與 GitHub Enterprise。
- REST／GraphQL client integration、Bearer header injection、HTTP 401 classification、request/operation one-retry、second-401 handling、credential reconciliation、migration、release 或 Git delivery。
- 修改既有 `GitHubTokenProvider`、`GitHubTokenStore`、`GitHubAccessTokenProvider`、OAuth DTO/bundle mapping、`RivetHTTPClient`、`AuthFlow`、PR Inbox 或 PR Reader。
