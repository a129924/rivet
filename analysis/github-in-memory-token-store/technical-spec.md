# github-in-memory-token-store：技術規格

## Locked Decisions

- 新增 `public final class InMemoryGitHubTokenStore: GitHubTokenStore`，置於 `Sources/BoundedContexts/GitHubIntegration/Stores/InMemoryGitHubTokenStore.swift`。
- 公開 API 僅新增 `public init()` 與為既有 protocol conformance 所需的 `public load()`、`public save(_:)`、`public delete()`。
- instance 私有擁有一個 optional `GitHubAccessToken`；`save(_:)` 直接覆寫、`load()` 直接回傳、`delete()` 設為 `nil`。
- implementation 不主動產生 `TokenStoreError`；typed-throws signatures 僅承接既有 `GitHubTokenStore` contract。
- 此 class 不提供 thread-safety、`Sendable`、actor isolation 或跨執行緒保證。
- `GitHubTokenStore`、`GitHubAccessToken`、`TokenStoreError`、`GitHubCredentialError`、`GitHubTokenProvider` 及 `TokenStoreGitHubTokenProvider` 的 API 與 failure mapping 都是 immutable。
- root package manifest、target/product graph 與既有 source path 不變；static isolation exact source set 僅加入新的 Stores source。

## Data and Failure Boundary

- token 是原樣保存的單一 ephemeral value；不驗證、正規化、格式化、記錄或加密。
- empty store 與 delete 後的 `nil` 由既有 provider 於其邊界映射為 `.missingCredential`；store 本身不作 credential interpretation。
- store 不依賴任何 BC、`RivetHTTPClient`、Security／Keychain、Apollo／ApolloAPI、HTTP 或 OAuth capability。

## Documentation Boundary

factual writeback 僅限 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md`：一致記錄 public、process-local、non-persistent `InMemoryGitHubTokenStore` 已交付，並保留 Keychain、cross-process persistence、authorizer、raw transport、OAuth lifecycle 與其他 deferred capability 不變。其他 docs 與 Bounded Context 文件不在本 topic 的 write scope。
