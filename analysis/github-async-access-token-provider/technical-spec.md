# GitHub Async Access Token Provider：Technical Spec

## Public API

```swift
public protocol GitHubAccessTokenProvider: Sendable {
  func token() async throws(GitHubCredentialError) -> GitHubAccessToken
}
```

`GitHubAccessToken`、`TokenStoreError` 與 `GitHubCredentialError` 均為 `Sendable`。`TokenStoreError.underlyingError` 及 initializer 接受 `any Error & Sendable`；`GitHubCredentialError` 新增 `.tokenAcquisition(any Error & Sendable)`。

## Boundary

此 protocol 不 import 或依賴 HTTP、Security、Keychain、Apollo、`RivetHTTPClient` 或任何 Domain BC。它不接收 request、不寫入 header、不判斷 HTTP status，且不公開 forced refresh。未來 async provider implementation 自行決定 actor、lock 或 immutable state。

既有同步 `GitHubTokenProvider` 保持原樣；兩種 protocol 不在同一 request flow 併用。本 topic 不實作任何 conformer。

## Verification

以 external consumer fake 驗證 public async typed-throws contract、`Sendable` surface 與 generic acquisition error payload；既有 provider tests 驗證回歸；static isolation 維持 exact source set 與 forbidden-import policy。
