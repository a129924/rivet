# GitHub GraphQL Infrastructure Foundation：Technical Spec

## 決策與 Evidence Boundary

本 topic 採 Human 2026-10-07 明示的 internal foundation：同一 `GitHubIntegration` target、既有 concrete `OAuthTokenProvider`、internal Query-only `fetch`；跨 target 使用 deferred。正式 artifacts 落地不等於 Plan-Reviewer approved。

Explorer 已確認 exact Apollo 2.1.2 的 Query／GraphQLResponse／SingleResponseFormat、`ApolloClient.fetch(query:cachePolicy:requestConfiguration:)`、HTTPInterceptor status surface 與 TaskLocal source-level 可行性。Swift 6 generic、request-chain assembly、noncopyable HTTPResponse bridge、TaskLocal inheritance 與 cancellation 尚無實際 compile／integration pass，不使用未驗證的 unchecked Sendable workaround。

官方版本依據：

- https://github.com/apollographql/apollo-ios/blob/2.1.2/Sources/Apollo/ApolloClient.swift
- https://github.com/apollographql/apollo-ios/blob/2.1.2/Sources/ApolloAPI/GraphQLOperation.swift
- https://github.com/apollographql/apollo-ios/blob/2.1.2/Sources/Apollo/RequestChain/Interceptors/ResponseCodeInterceptor.swift
- https://github.com/apollographql/apollo-ios/blob/2.1.2/Sources/Apollo/RequestChain/RequestChainNetworkTransport.swift
- https://github.com/apollographql/apollo-ios/blob/2.1.2/Sources/Apollo/RequestChain/Interceptors/InterceptorProvider.swift
- https://www.apollographql.com/docs/ios/advanced/request-chain#dependency-injection-via-tasklocal-values

## Internal Surface

`GitHubGraphQLClient` 是 internal final class，internal 構造使用 concrete provider；internal test construction 可注入下列唯一新增 seam。不新增 public client API。

```swift
internal init(provider: OAuthTokenProvider)

internal func fetch<Query: GraphQLQuery>(
  query: Query
) async throws -> GraphQLResponse<Query>
where Query.ResponseFormat == SingleResponseFormat
```

本次唯一新增 protocol 放在既定 `ApolloGraphQLClient.swift`，不新增 production file：

```swift
internal protocol ApolloGraphQLExecuting: Sendable {
  func fetch<Query: GraphQLQuery>(
    query: Query,
    accessToken: GitHubAccessToken
  ) async throws -> GraphQLResponse<Query>
  where Query.ResponseFormat == SingleResponseFormat
}
```

`GitHubGraphQLClientError` 為 internal finite vocabulary：`authenticationRequired`、`credentialLifecycle(stage:)`（stage 僅 restore／refresh／persist）、`httpStatus(Int)`、`executionFailed`；不帶任意 underlying error／body／request／token。取消使用 CancellationError，不強制塞入 technical enum。

既有 public `OAuthTokenProviderError` 為 missingCredential／restore／refresh／persist，既有 provider／adapter ports 不改。Client private helper 只做取消辨識與 finite mapping，不反向依賴新 provider abstraction。

## 固定語意、具名值與 Protocol Boundary

- **Fixed semantics**：Query-only、HTTP 401-only recovery、原 query／variables 不變、第二次 401 terminal、其他 HTTP／provider failure 不 retry、合法 GraphQL data＋errors 原樣回傳。
- **Named fixed value**：client 的 `private static let maximumAuthenticationRecoveries = 1`；不提供 runtime config。
- **Protocol dependency**：唯一新增 `ApolloGraphQLExecuting` 是 internal Apollo-bound testing seam；既有 OAuthCredentialStore／OAuthTokenFetcher ports 保持。
- **刻意不抽 protocol**：外層 client、provider、UnauthorizedClassifier、RetryPolicy、AuthenticationRecovery、ErrorMapper 均不新增 protocol；不建立通用 GraphQL request／response model。

## Execution 與 Error Translation

1. 經 private async-boundary helper 取得 provider.snapshot()。
2. raw executor 接收 query 與 snapshot.accessToken，執行一次 Apollo fetch。
3. 初次 HTTP 401、且 caller 未取消時，把完整實際 snapshot 傳給 replacementSnapshot(afterUnauthorized:)；以 replacement 重送相同 Query 一次。
4. 第二次 401 為 authenticationRequired；沒有第二次 recovery 或第三次 execution。

| 原始 signal | Client 結果 |
| --- | --- |
| missingCredential | authenticationRequired |
| restore／refresh／persist 的非取消 failure | credentialLifecycle，保留該 stage |
| 初次 HTTP 401 | internal recovery，使用完整 used snapshot |
| 第二次 HTTP 401 | authenticationRequired |
| 其他非 2xx HTTP status | httpStatus(status)，不 recovery |
| network／parser／非 HTTP／其他 execution failure | executionFailed，不 recovery |
| CancellationError／URLError.cancelled／provider underlying cancellation／已取消 caller | CancellationError |
| 合法 2xx GraphQL partial 或 errors-only response | GraphQLResponse<Query> 原樣回傳 |

HTTPInterceptor 在 parser 讀 body 前檢查 HTTPResponse.response.statusCode，含 empty／non-JSON 401 與 empty 403。非 HTTP failure 不猜測 status；GraphQL payload errors 不視為401。

集中 private async-boundary helper 在 await 前、成功後與 throw path 檢查取消，主流程不散佈重複 checks。優先序為 caller cancellation > authentication recovery > error mapping；辨識 stage 內包裝的 CancellationError／URLError.cancelled，非取消才映射 stage。取消 caller 不送 retry、不主動 cancel provider shared refresh；provider await 可能延遲返回，不保證 prompt cancellation。

Provider 獨占 restore／expiry／refresh／stale version／single-flight／rotation／persist；client 不自建 refresh state，不修改 TokenSnapshot／provider API 或 legacy contracts。

## 固定 Apollo Configuration 與位置

- exact `apollo-ios` 2.1.2，既有 GitHubIntegration target 依賴 Apollo、ApolloAPI；不新增 target／product 或 BC dependency。
- 固定 POST `https://api.github.com/graphql`、APQ off、`MaxRetryInterceptor(maxRetriesAllowed: 0)`、network-only，另 explicit disable cache write；network-only 本身不是 write-disable 證據。
- raw executor 將 accessToken 參數放在本次 TaskLocal scope；Bearer interceptor 只修改本次 URLRequest value，不改 shared headers 或重新向 provider取 snapshot。
- 每個 fetch 最多兩次 Apollo session/application execution；不對 Foundation redirect／connection／wire request 次數下保證。
- `Sources/BoundedContexts/GitHubIntegration/GraphQL/` 僅新增 GitHubGraphQLClient.swift、ApolloGraphQLClient.swift、GitHubGraphQLHTTPInterceptor.swift、GitHubGraphQLClientError.swift。
- 所有新增 tests／test-only Query／fake ApolloURLSession helpers／GraphQL-specific isolation extension 都在 `Tests/GitHubIntegrationTests/GraphQL/`。
- 既有共享 StaticIsolationTests 與 consumer files 留原位；只修正授權 path／dependency／visibility assertions。既有 provider／contracts／stores／OAuth isolation 保留，不改成全 target 允許 Apollo。

## 驗證與長期文件

Wrapper tests 的 substitution 只有 ApolloGraphQLExecuting；真 provider使用既有 fake store／fetcher ports。Apollo integration 使用 fake ApolloURLSession 經真 request chain與 test-only non-BC Query，不採用 Reader SDL或建立 codegen pipeline。

驗證 concurrent TaskLocal Bearer、single-flight owner、無 APQ retry、無 cache write、empty401、取消與 noncopyable bridge。`@testable` 僅限 integration 內部 tests；consumer維持正常 import／既有 public API regression，不直接依賴 Apollo或呼叫 internal client。Static visibility evidence確認 internal邊界，不新增 compile-failure script或 gate。

docs 只更新 internal foundation交付狀態，跨 target、BC adapters、OAuth concrete adapters仍 deferred；不把長期 shared-consumer架構改成已交付。無法實現固定版本／契約時回報實際 evidence，不自行換版本、加 public abstraction或擴 scope。
