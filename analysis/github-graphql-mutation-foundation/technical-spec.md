# GitHub GraphQL Mutation Foundation：技術規格

## Locked Decisions 與介面

維持 non-BC GitHubIntegration、internal-only、Apollo 2.1.2，revision `38c202227d0f09508e573dcf22f54885cfb0c5d4`。Production 變更限既有 GraphQL 兩檔，不新增 target、dependency 或外層 abstraction。

GitHubGraphQLClient 新增：

```swift
internal func perform<Mutation: GraphQLMutation>(
  mutation: Mutation
) async throws -> GraphQLResponse<Mutation>
where Mutation.ResponseFormat == SingleResponseFormat
```

既有 internal ApolloGraphQLExecuting 新增 requirement，ApolloGraphQLClient 提供 concrete witness，測試 conformers 同步：

```swift
func perform<Mutation: GraphQLMutation>(
  mutation: Mutation,
  accessToken: GitHubAccessToken
) async throws -> GraphQLResponse<Mutation>
where Mutation.ResponseFormat == SingleResponseFormat
```

Query fetch 保留。Client 私有共用 helper 接收捕捉原 operation／variables 的 async closure，讓 Query／Mutation 共用 snapshot acquisition、認證恢復與 async boundary；每次只傳入當次 access token，不重建操作。

## Execution 與 Ownership

1. 於既有 async boundary 取得 initial snapshot，使用其 access token 執行原 operation。
2. HTTP interceptor 在 GraphQL parser 前分類。僅首次實際 `.httpStatus(401)` 可將完整 used snapshot 傳給 replacementSnapshot(afterUnauthorized:)。
3. Replacement 成功後，以原 operation／variables 與 replacement Bearer 重送一次；每次最多兩次發送，第二次 401 回報 authenticationRequired。
4. 合法 partial／errors-only response 原樣保留。Provider failure、非法 initial／replacement token、timeout、transport／parse failure 與 payload errors 不新增發送。

沿用 invalidAuthorizationToken、authenticationRequired、credentialLifecycle(stage: restore／refresh／persist)、httpStatus、executionFailed 的現有 technical classification。Provider 保持 credential lifecycle、refresh、rotation persistence、single-flight 與 snapshot version 的唯一 owner，client 不改其內部 state。

## Apollo 與取消

Mutation 在既有 TaskLocal access-token scope 執行：

```swift
try await client.perform(
  mutation: mutation,
  requestConfiguration: .init(
    requestTimeout: nil,
    writeResultsToCache: false
  )
)
```

沿用 Mutation NetworkOnly，不傳 Query cachePolicy；固定 POST、APQ off、MaxRetryInterceptor(maxRetriesAllowed: 0)、既有 HTTP interceptor 與 non-HTTP response guard。

保留 snapshot acquisition、executor execution、replacement acquisition 各 await 前後 Task.checkCancellation 與既有正規化，包括 CancellationError、URLError.cancelled、provider stage 包裝的 cancellation。觀察到取消後不開始下一段 recovery／發送；不取消 shared refresh，不承諾 provider await 立即返回，不承諾遠端 rollback。

## 測試與文件

以手寫 test-only Mutation 延伸既有 support，不使用 Reader SDL／codegen。GraphQLIsolationTests 允許 internal Query／Mutation，保留 Subscription／public 禁制；既有 StaticIsolation source 與 allowlist 不需改動。

長期文件同步 Query／Mutation 狀態，兩份 BC 文件只改 integration 交付狀態句，不改 behavior／契約／依賴。Canvas 使用 architecture-canvas；canonical lifecycle 延續 `docs/architecture/diagrams/github-oauth-dual-client-architecture/token-lifecycle-v11.json`，由 archify 驗證與重建 HTML／receipts／captures。歷史資料不覆寫，作者文案繁體中文，固定 Viewer UI／HTML lang 英文 fallback 要揭露，不 preview／publish。

工具 pinned runtime、fallback、執行條件與完整檔案界線依本 topic plan；Graphify／PR Lens 不擴張產品 scope，也不新增 workflow gate。
