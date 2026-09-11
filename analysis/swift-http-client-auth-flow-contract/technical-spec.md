# Swift HTTP Client Auth Flow Contract：技術規格

## Locked Public API

```swift
public enum ClientAction: Sendable {
  case send(HTTPRequest)
  case finish
}

public protocol Auth: Sendable {
  func makeFlow(for request: HTTPRequest) -> any AuthFlow
}

public protocol AuthFlow: Sendable {
  mutating func start() async -> ClientAction
  mutating func receive(_ response: HTTPResponse) async -> ClientAction
}
```

## Contract Semantics

- `ClientAction.send` 承載既有 `HTTPRequest`；`finish` 表示 state machine 的 terminal action。
- `Auth.makeFlow(for:)` 同步接收 request，回傳 existential `any AuthFlow`。
- `AuthFlow` 是單純、non-throwing async state machine。`start()` 與 `receive(_:)` 是其唯一宣告的 transitions，且必須維持 `mutating async -> ClientAction` signature。
- package 不呼叫任何 auth-flow method，亦不提供 default implementation、concrete implementation、runtime 或 flow driver。

## Boundaries

- 不改動既有 HTTP client、request／response value types、transport chain、typed error contract 或 manifest。
- 不新增 static authorization header application、request replay、retry、refresh、challenge、401 handling 或 status policy。
- 不提供 concrete auth、credential、token、GitHub 或 persistence behavior。
- GitHub Integration 及其既有 topic 是 read-only；本 topic 不產生 architecture writeback。

## Required Verification

- 在 `RivetHTTPClientTests` 宣告 concrete `Auth` 與 `AuthFlow` conformers。
- `makeFlow(for:)` 的結果可保存為 `var flow: any AuthFlow`。
- test 可 `await flow.start()` 與 `await flow.receive(_:)`。
- test 對 `.send(let request)` 與 `.finish` pattern match，並驗證 `.send` 保留輸入 `HTTPRequest`。
- 不驗證 HTTP execution、header mutation、retry、refresh、credential 或 GitHub behavior。
