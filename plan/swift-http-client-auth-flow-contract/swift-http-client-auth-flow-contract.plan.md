# Swift HTTP Client Auth Flow Contract

## Summary

在 `RivetHTTPClient` 新增 declarations-only、non-throwing async auth-flow public contracts：`ClientAction`、`Auth`、`AuthFlow`。這是 future wrapper 的型別邊界；既有 HTTP client execution 與 GitHub Integration 均不受影響。

## Implementation Changes

- 新增 `ClientAction: Sendable`，精確宣告 `.send(HTTPRequest)` 與 `.finish`。
- 新增 `Auth: Sendable`，精確宣告 `makeFlow(for:) -> any AuthFlow`。
- 新增 `AuthFlow: Sendable`，精確宣告 `mutating async start()` 與 `receive(_:)`。
- 在 package external test target 以 concrete conformers 驗證 compile contract。
- 不建立 runtime 或任何 auth behavior，且不變更既有 HTTP execution path。

## Swift Implementation Handoff

### Goal

宣告可供 future wrapper 使用的 public、`Sendable`、non-throwing async auth-flow contracts，不執行 flow。

### Non-Goal

authentication runtime、HTTP client integration、flow driver、request execution、response routing、static header auth、concrete auth、credential/token lifecycle、GitHub behavior。

### In-Scope

- `ClientAction` 的 `.send(HTTPRequest)` 與 `.finish`。
- `Auth.makeFlow(for:) -> any AuthFlow`。
- `AuthFlow` 的 non-throwing `mutating async start()` 與 `receive(_:)`。
- external test-target conformers 與 compile-contract tests。

### Out-Of-Scope

- `HTTPClient`、`Requester`、`Transport`、`HTTPRequest`、`HTTPHeaders`、`HTTPResponse`、`HTTPClientError` 或 manifest 的修改。
- retry、refresh、challenge、401 policy、request replay、`AuthRuntime`、NoAuth、Bearer、Basic、Digest、OAuth、credential、token、parser、persistence。
- GitHub Integration、其既有 topic、architecture docs、BC docs 或 canvas 的變更。

### Modify

- 無。本 topic 不修改任何既有檔案。

### Written

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`：新增 locked public declarations。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/AuthTests.swift`：新增 external conformer 與 compile-contract tests。
- 除上述兩個新檔外，不新增 runtime、documentation 或 architecture artifact。

### ReadOnly

- `HTTPClient`、`Requester`、`Transport`、`HTTPRequest`、`HTTPHeaders`、`HTTPResponse`、`HTTPClientError`、manifest、GitHub Integration 及其既有 topic、architecture docs、BC docs、canvas 與 GitHub source。

### Deleted

- 無。不得刪除、搬移或更名既有 API、source、test 或 artifact。

### TestCase

- concrete `Auth` conformer 回傳 concrete `AuthFlow` 作為 `any AuthFlow`。
- `var flow: any AuthFlow` 可依序 `await start()` 與 `await receive(_:)`。
- `.send(let request)` 與 `.finish` 可 exhaustive pattern match，且 `.send` 保留輸入 `HTTPRequest`。
- 不新增 HTTP execution、header mutation、retry、refresh、challenge、credential、token、parser、persistence 或 GitHub assertions。

## Test Plan

- 先建立 `AuthTests.swift` compile-contract tests；在 declarations 尚不存在時，確認 red 編譯失敗。
- 以最小 public declarations 實作後，執行相同 package test 取得 green。
- IM-01 完成後，交由獨立 Tester 重跑適用 package build/test；Implementer 的 green evidence 不取代獨立驗證。

## Assumptions

- future wrapper 自行決定如何使用 state transitions；本 topic 不預先定義 runtime。
- 若需要任何 HTTPClient integration、auth implementation 或 GitHub behavior，停止並以新 topic 規劃。
