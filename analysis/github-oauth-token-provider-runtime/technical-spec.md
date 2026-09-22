# GitHub OAuth Token Provider Runtime：Technical Spec

## Public Surface

```swift
public protocol OAuthCredentialStore: Sendable {
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle?
  func save(_ credential: GitHubOAuthCredentialBundle)
    async throws(any Error & Sendable)
}

public protocol OAuthTokenFetcher: Sendable {
  func refresh(_ credential: GitHubOAuthCredentialBundle)
    async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle
}

public struct TokenSnapshot: Equatable, Sendable {
  public let accessToken: GitHubAccessToken
  public let version: UInt64

  public func hasSameVersion(as other: Self) -> Bool {
    version == other.version
  }
}

public enum OAuthTokenProviderError: Error, Sendable {
  case missingCredential
  case restore(underlying: any Error & Sendable)
  case refresh(underlying: any Error & Sendable)
  case persist(underlying: any Error & Sendable)
}

public actor OAuthTokenProvider {
  public init(
    store: any OAuthCredentialStore,
    fetcher: any OAuthTokenFetcher,
    now: @escaping @Sendable () -> Date = Date.init
  )

  public func snapshot()
    async throws(OAuthTokenProviderError) -> TokenSnapshot

  public func replacementSnapshot(afterUnauthorized usedSnapshot: TokenSnapshot)
    async throws(OAuthTokenProviderError) -> TokenSnapshot
}
```

Human 已選擇 A，授權既有 `GitHubAccessToken` additive conform `Equatable`。`TokenSnapshot` 維持 `GitHubAccessToken` field type，initializer 維持 internal，僅 provider 可建立 snapshot；它使用 synthesized `Equatable` 作完整 equality，這是 additive public compatibility change，不移除、不更名或改變既有 token API。`hasSameVersion(as:)` 只比較 version，且不提供 `hasDifferentVersion`。它不認識 HTTP、401、refresh、retry 或 stale recovery。

## Provider State and Transitions

- actor private state 擁有完整 credential、current snapshot、version event counter、single in-flight restore/refresh task 與 persist-failure unavailable state；每次 accepted 且成功 persist 的 rotation 都記錄一個 version event，即使其 credential 在 publish snapshot 前已 expired。
- version 只表示 snapshot equality/staleness，且僅在單一 provider instance 有效；它不表示已 publish snapshot 的連續序號。一般無 expiry race 時首個 delivered snapshot 是 v1。每次 accepted 且成功 persist 的 credential rotation 都必須保留並前進 version event，即使該 rotated credential 在 publish 前已 expired；首次 restore credential 已 expired、第一個 persisted rotation 又 expired 時，provider 最多再 refresh/persist 一次，成功取得仍有效的第二個 rotation 時首個 delivered snapshot 可以是 v2。
- `now()` 是 access-token expiry 的唯一 clock，`accessTokenExpiresAt <= now()` 即 expired。provider 不預先驗證 `refreshTokenExpiresAt`。
- first demand single-flight restore：`load()` 回傳 `nil` 時，當次 demand 回傳 `.missingCredential`，不進 unavailable，後續 demand 可重新 restore；restore failure 回傳 `.restore` 且可由後續 demand 重試；valid credential 直接 publish，expired credential 先 refresh。只有 accepted rotation 後的 persist failure 才能永久進 unavailable。
- refresh in-flight 時，新的 `snapshot()` 加入同一 task，不交付舊 snapshot。
- `replacementSnapshot(afterUnauthorized:)` 不接收 HTTP response/request/operation。current snapshot 存在時，與 `usedSnapshot` 的 `hasSameVersion(as:)` 為 false 直接交付 current snapshot；為 true 時啟動或加入 refresh，不讀 token 字串。current snapshot 尚不存在時，走正常 restore/expiry path。
- fetcher 成功回傳 bundle 代表 rotation 已 accepted。provider 先 `store.save`，成功後才取代 private credential 並保留該 rotation 的 version event；只有 bundle 在 `now()` 時仍有效才 publish snapshot。若已 expired，仍不得抹去已 persist 的 version event，最多再 refresh/persist 一次。該第二次 rotation 若仍在 publish 前 expired，provider 終止並以既有 `.refresh` 包裝 private exhausted error；不新增 public failure case。
- fetch failure 在 accepted rotation 前回傳 `.refresh`，保留舊 credential/version，後續 demand 可再 refresh。
- accepted rotation 的 save failure 回傳 `.persist` 並永久進 unavailable；所有後續 provider calls 回傳同一 underlying error，不再呼叫 store/fetcher，也不宣稱舊 credential 可用。

## Boundary

這不是 `GitHubAccessTokenProvider` 的 conformer 或 bridge，也不取代既有同步 token store/provider。store/fetcher 是 adapter-facing public ports；provider 的 client-facing acquisition/recovery surface 不洩漏 credential bundle。caller 自行判讀 401 與自行 retry；本 topic 不實作 retry。
