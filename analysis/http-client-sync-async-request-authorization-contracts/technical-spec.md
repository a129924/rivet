# HTTP Client Sync／Async Request Authorization Contracts：技術規格

## Locked Public API

```swift
public protocol AsyncRequestAuthorization: Sendable {
  func applying(to request: HTTPRequest) async throws -> HTTPRequest
}
```

## Contract Semantics

- `AsyncRequestAuthorization` 與既有 `RequestAuthorization` 是獨立 sibling protocols；不互相繼承、不提供 default implementation、不建立 adapter、type erasure 或 interoperability policy。
- 兩者只接受與回傳 `HTTPRequest`。caller 決定是否及何時在 bare execution 前套用 transformation。
- `async throws` 的一般 `Error` 是 transformation-specific failure；它不是 HTTP transport、status、credential 或 GitHub failure model。
- protocol declaration 不可持有、呼叫或注入 `HTTPClient`、`Requester`、`Transport`、`Auth` 或 `AuthFlow`。

## Documentation and Canvas Boundary

- `docs/architecture/README.md` 只記錄 sync/async contracts 都是 caller-applied transformation、async failure 為 caller-visible general error、bare `Requester → Transport` execution 不變。
- package canvas 在 contracts plane 並列 `RequestAuthorization` 與 `AsyncRequestAuthorization` 的 owned-contract boxes，表達 caller-applied transformation 與 `HTTPRequest` dependency。
- 不得建立至 `HTTPClient`、`Requester`、`Transport`、`AuthRequester` 或 `AuthFlow` 的 execution edge；保留既有 Auth/AuthFlow 與 bare execution ownership。
- `BUILD.md` 是 ReadOnly；`index.html` 只可由既有 validate → scratch build → enhance → verify workflow 生成，不可手改或發布 artifact.cafe。

## Test Contract

- `RequestAuthorizationTests.swift` 使用 private fake conformer，經 `any RequestAuthorization` existential 呼叫 `applying(to:)`。
- `AsyncRequestAuthorizationTests.swift` 使用 private success fake conformer，經 `any AsyncRequestAuthorization` existential `try await applying(to:)`。
- async failure fake 拋出 private sentinel type；sentinel 必須 conform `Error & Sendable & Equatable`。catch 後斷言 received value 等於原 sentinel。
- 不修改或重用 `BearerAuthTests`；不測試 HTTP execution、credential、GitHub、retry 或 refresh behavior。

## Path Boundary

Written、Modify、Deleted 與 ReadOnly target 以正式 plan 的 Swift Implementation Handoff 為唯一準則；若任何工作需要變更 failure semantics、execution ownership、concrete conformer、adapter/interoperability、GitHub 或 credential scope，停止並回報 `human-check`。
