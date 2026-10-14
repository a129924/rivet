# GitHub Client Scope Composition — Technical Spec

- Topic：`github-client-scope-composition`
- 狀態：locked decisions 已承接；待獨立 planning review。
- [Requirements](requirements.md)／[Plan](../../plan/github-client-scope-composition/github-client-scope-composition.plan.md)。

## Ownership

Caller composition root 建立並保留 public `OAuthTokenProvider`。
`GitHubClientScope.prepare(provider:) async throws -> GitHubClientScope` 只接受既有 provider。
Scope initializer 為 private，private property 強持有同一 provider。
Scope 暴露 `public let rest: any GitHubRestClient`。
Scope 暴露 `public let graphql: any GitHubGraphQLServing`。
Scope 是多 request composition lifetime，不是 UoW、singleton 或 DI container。
Prepare 失敗／取消後，caller 仍保留原 provider，禁止自動重建或 retry prepare。

## Readiness

1. 先觀察 caller cancellation。
2. 對注入 provider 呼叫 `snapshot()`。
3. 既有 provider 完成 restore、expiry-first refresh、accepted rotation persistence。
4. 依既有 Bearer 本地驗證規則驗證 snapshot access token。
5. internal factory 用同一 provider 建立真實 REST 與 GraphQL client。
6. 返回前最後檢查取消；只有成功後交付完整 scope。

不探測 GitHub resource API、不驗證帳號或 repository permission。
Ready 僅代表本地準備成功，不保證後續 request 成功。
兩 client 每次 execution 仍向 provider 取 fresh snapshot，不保存 prepare token 作 request credential。
internal-only factory seam 可在測試中組合真實 clients 與受控 transports。
Production 使用既有 transport routes；不新增 public transport injection。

## 公開 REST

公開既有 `GitHubRestClient: Sendable`，concrete `GitHubHTTPClient` 保持 internal。
四個 builders 為 `get/post/put/patch(url: HTTPURL, headers: HTTPHeaders, body: Data?)`。
四個 execution requirements 為 `executeGet/executePost/executePut/executePatch(_ request: HTTPRequest)`。
八個 methods 均 `async throws -> HTTPResponse`；四個 default builders 對外可用。
不新增 default arguments、overload 或 methods；method／host validation 與 redirect rejection 保持。

## 公開 GraphQL

新增 `public protocol GitHubGraphQLServing: Sendable`。
`fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>`。
其約束為 `Query.ResponseFormat == SingleResponseFormat`。
`perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> GraphQLResponse<Mutation>`。
其約束為 `Mutation.ResponseFormat == SingleResponseFormat`。
既有 internal `GitHubGraphQLClient` conform；不公開 concrete 或 executor。
Apollo 2.1.2 僅由 consuming Infra／fixture／composition 使用，不進入 BC Core／UseCase／Port。

## Errors

公開既有 `GitHubHTTPClientError`、`GitHubGraphQLClientError` 及必要 stage visibility。
現行 client error mapping 保持；不得夾帶 raw underlying error、credential 或 body。
新增 `GitHubClientPreparationError: Error, Sendable, Equatable`。
Cases：`missingCredential`、`authenticationRequired`、`credentialLifecycle(stage:)`、`invalidAuthorizationToken`。
Preparation stage 僅 `restore`、`refresh`、`persist`。
Provider error 分類映射為此有限契約；取消獨立回 `CancellationError`。
合法 raw HTTP response 與 Apollo partial／errors-only response data 不受 sanitization 改寫。

## 保留 lifecycle 與 cancellation

401-only recovery 回報實際 snapshot；每個原工作最多 retry 一次。
跨 REST／GraphQL 的 stale version 共用 provider single-flight；late 401 使用已前進 version。
Terminal、rotation-indeterminate 與 accepted rotation persistence 語意保持。
Task.cancel、URLError.cancelled、provider underlying、typed refresh cancellation 正規化。
Observed cancellation 不返回 scope；不取消 shared refresh、不 rollback rotation／persist。
不承諾 await 立即返回，也不承諾取消 mutation 意味遠端未執行。

## 文件與工具

長期文件回寫 README、design principles、architecture README 與雙 client 架構文件。
責任邊界依 architecture-canvas，lifecycle v11 保留並新增 canonical v12，依 archify。
V12 應通過 c9 checks、零 errors／warnings、sha／bytes delivery 與四組 desktop visual checks。
作者內容繁體中文；Viewer English fallback；不 preview／publish／upload。
Graphify 0.9.73 每次 CLI 帶 `GRAPHIFY_NO_AUTO_REFRESH=1`；無現成 graph 則 rg／source fallback。
禁止 build／extract／refresh／stamp／install／hooks／provider 操作。
PRLens 0.11.0 僅實作後對真實 bounded base/head diff，在外部 topic tmp validate／render。
PRLens 不上傳、不建立 config、不造 commit；runtime failure 改直接 diff，無第五份 formal artifact。

## 驗證邊界

精確檔案 allowlist 以 plan 為準；provider／ports／fetcher／BC／Presentation／generic HTTP 皆 readonly。
Consumer manifest 僅增加必要 Apollo／ApolloAPI／RivetHTTPClient direct dependencies，版本維持。
Consumer resolved 僅必要 originHash；pins 不變。root manifest 與 pins readonly。
目前未執行實作或測試；最後更新：2026-10-14，Plan-Creator。

AC01–AC14 的 canonical 驗收情境、預定檔／command 與 pending evidence 見 [Plan 驗收映射](../../plan/github-client-scope-composition/github-client-scope-composition.plan.md#ac-verification-mapping)。
