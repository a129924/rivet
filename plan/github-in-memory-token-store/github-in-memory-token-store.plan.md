# github-in-memory-token-store：Implementation Plan

## Goal

在 branch `feat/github-in-memory-token-store` 交付 `GitHubIntegration` 的單一 process-local token store，並同步指定長期文件的已交付事實；呼叫端能以既有 `GitHubTokenStore` contract 管理一個暫存 GitHub access token，而既有 contract、provider failure mapping、module boundary 與 deferred capability 保持不變。

## Public API

```swift
public final class InMemoryGitHubTokenStore: GitHubTokenStore {
  public init()

  public func load() throws(TokenStoreError) -> GitHubAccessToken?
  public func save(_ token: GitHubAccessToken) throws(TokenStoreError)
  public func delete() throws(TokenStoreError)
}
```

- instance 只保存一個 private optional token；save 覆寫、load 回傳目前值、delete 清空。
- 不提供 persistence、thread-safety、`Sendable`、actor isolation 或任何 concurrency guarantee。
- 不變更既有 public contracts、provider、failure mapping、target/product 或 package manifest。

## File Contract

### Written

- `Sources/BoundedContexts/GitHubIntegration/Stores/InMemoryGitHubTokenStore.swift`
- `Tests/GitHubIntegrationTests/InMemoryGitHubTokenStoreTests.swift`

### Modify

- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：將新 Stores source 加入 exact expected source set；保留既有 actual-source enumeration、target graph 與 forbidden-import assertions。
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`：以 public `InMemoryGitHubTokenStore` 驗證外部 consumer 僅透過 `GitHubIntegration` product 與 `any GitHubTokenStore` 使用 save/load/delete。
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/bounded-contexts/pr-reader.md`
- `docs/github-api/README.md`

文件修改只將上述四份文件的對應描述一致改為已交付的 public、process-local、non-persistent `InMemoryGitHubTokenStore`，並保留 Keychain、cross-process persistence、authorization 與其餘 deferred capability；不得新增 architecture decision。

### ReadOnly

- `Package.swift`、所有 target/product declarations 與既有 source layout。
- `Contracts/CredentialTypes.swift`、`Contracts/GitHubTokenStore.swift`、`Contracts/GitHubTokenProvider.swift`、`Providers/TokenStoreGitHubTokenProvider.swift`。
- 既有 provider contract tests、consumer package manifest、toolchain/CI/hooks、其餘 docs、BC 文件、diagram 與任何 Git/PR artifact。

### Deleted

不得刪除、搬移或更名任何 tracked file。

## TestCase

- 新 store：empty load 回傳 `nil`；save/load 原樣 round-trip；第二次 save 覆寫；delete 後 load 為 `nil`；empty delete 後 load 仍為 `nil`。
- 外部 consumer：只 `import GitHubIntegration`，可用 public initializer 建立 store，並以 `any GitHubTokenStore` 完成 save/load/delete。
- Regression：既有 provider tests 持續驗證 `nil → .missingCredential` 與 `TokenStoreError` payload preservation，且不因新 store 改變。
- Static isolation：exact source set 為既有四個 production source 加上 `Stores/InMemoryGitHubTokenStore.swift`；所有 actual target source 都繼續拒絕 `RivetHTTPClient`、`Security`、`Keychain`、`Apollo`、`ApolloAPI` imports。
- 文件一致性：四份 Modify docs 均表達已交付的 public、process-local、non-persistent store，且不改變 Keychain、cross-process persistence、authorization 或其他 deferred capability 的狀態。
- Verification command：`swift test`、`scripts/check-github-integration-consumer.sh` 與 `git diff --check`；後者亦確認 docs writeback 無 whitespace error。

## Non-Goal and Boundaries

- 不實作 Keychain、Security、磁碟／網路 persistence、OAuth、refresh、re-auth、authorization header、REST／GraphQL adapter、多帳號或同步。
- 不在 store 內解讀 missing credential 或交付 token；此行為仍屬既有 provider contract。
- 若需 secure／跨 process persistence、concurrency guarantee 或 credential lifecycle，必須另開 topic。
