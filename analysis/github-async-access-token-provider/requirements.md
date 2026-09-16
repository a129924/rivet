# GitHub Async Access Token Provider：Requirements

## Goal

新增 async、`Sendable` 的 `GitHubAccessTokenProvider`。它以 `token()` 交付回傳當下可供送出的 `GitHubAccessToken`，並以 typed `GitHubCredentialError` 表達取得失敗。

## In-Scope

- protocol-only public contract；PAT 與 OAuth 未來皆可 conform。
- `GitHubAccessToken`、`TokenStoreError`、`GitHubCredentialError` 的完整 `Sendable` contract。
- 新增 `.tokenAcquisition(any Error & Sendable)`。
- internal／external consumer tests、static isolation、長期 architecture writeback 與既有 OAuth canvas。

## Non-Goal

- PAT／OAuth implementation、refresh、expiry、401 recovery、retry、`AsyncHttpSender`、authorization header 或 transport。
- 既有同步 `GitHubTokenProvider`／`GitHubTokenStore` 的修改、adapter、deprecation 或 migration。

## Acceptance Criteria

1. 外部 `Sendable` fake 可 conform，並以 `await token()` 原樣取得 token。
2. 成功只保證 provider 回傳當下可送出；下游 HTTP result 不屬 contract。
3. future non-store acquisition failure 可保留 `Error & Sendable` payload。
4. 既有同步 token provider 的行為與 failure mapping 不變。
