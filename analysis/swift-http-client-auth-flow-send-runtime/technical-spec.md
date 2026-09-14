# Swift HTTPClient AuthFlow Send Runtime：技術規格

## Goal

讓 internal `AuthRequester` 作為 `Requester` 的 generic decorator，獨自驅動 `AuthFlow`；`HTTPClient` 回到 GitHub-unaware、Auth-unaware 的 bare HTTP facade。

## Non-Goal

本次不提供 concrete auth、OAuth token endpoint、Bearer header、token lifecycle、retry policy、GitHub REST adapter 或 Apollo interceptor，也不改 AuthFlow contract。

## In-Scope

- `HTTPClient` 只公開既有 `execute(_:)`、`request(...)` 與 verb facades；移除 `execute(_:auth:)`，沒有 source compatibility shim。
- 新增 internal `AuthRequester: Sendable` 與 internal initializer `init(requester: Requester, auth: any Auth)`；它不是本次的 public API。
- `AuthRequester.execute(_:)` 依下列 locked algorithm 執行：

```swift
var flow = auth.makeFlow(for: request)
var action = await flow.start()
var lastResponse: HTTPResponse?

while true {
  switch action {
  case .send(let nextRequest):
    let response = try await requester.execute(nextRequest)
    lastResponse = response
    action = await flow.receive(response)
  case .finish:
    guard let lastResponse else {
      throw .authFlowFinishedWithoutResponse
    }
    return lastResponse
  }
}
```

- `HTTPClientError.authFlowFinishedWithoutResponse` 保持無 associated value，供 generic terminal condition 使用。
- docs／diagrams 改述 `AuthRequester → Requester → Transport`，並保留 Canvas initial-fit support 與其 verification。

## Out-Of-Scope

- 變更 public `Requester` single-request semantics 或讓它讀取 `AuthFlow` action。
- 將 AuthRequester 暴露給 package 外 caller；未來 GitHub REST adapter 若需直接建構，須由新 topic 決定 public API。
- status、header、body、original／next request equality 的 generic interpretation，或 loop cap／retry count。

## Interface and Data Flow

- `HTTPClient` 對 bare request 仍為 `HTTPRequest → Requester → Transport → HTTPResponse`。
- `AuthRequester` 擁有 injected `Requester` 與長存 injected `any Auth`；它不擁有 Transport、GitHub、OAuth 或 token capability。
- 每個 `AuthRequester.execute(_:)` 呼叫以 input request 建立一個新 flow。flow 可送出零或多個 request；只有 successful requester response 才傳入 `receive(_:)`。
- `.finish` 不帶 response payload，因此 return value 是最後一次成功 response；沒有成功 response 時是 typed terminal error。

## File Contract

### Written

- planning phase 的四份同 slug artifacts。
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/AuthRequesterTests.swift`

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClientError.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`、generated HTML 與 visual-check evidence
- `docs/architecture/diagrams/http-client-package-structure/scene.js` 與 generated `index.html`；build/enhance support 只須維持既有 initial-fit contract。

### ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、`HTTPRequest.swift`、`HTTPResponse.swift`、`Package.swift`、`AuthTests.swift`、request／verb facades。
- Canvas `BUILD.md` 與 `enhance-accessibility.js` 的 initial-fit／share／pan-zoom semantics。
- 所有非本 topic 的 source、tests、docs、diagrams 與 historical topic artifacts。

### Deleted

無檔案刪除、搬移或改名；僅移除 `HTTPClient` 的 auth overload 與其專屬 tests。

## Verification

- `HTTPClientTests` 只驗證 bare facade；新增 `AuthRequesterTests` 以 `@testable import` 覆蓋 internal driver。
- focused AuthRequester／HTTPClient tests、complete SwiftPM tests 與 `git diff --check`。
- Archify lifecycle：showcase validate、deliver、visual-check 與 delivered light/dark 1440×900、2048×1320 人工 review；Canvas：既定 validate/build/enhance/verify 與 light/dark desktop 人工 review。
- Canvas 若因 package-structure regeneration 被觸及，必須驗證 untouched unshared resize refit，以及 share hash 或 pan／zoom 後 resize preserve transform。

## TestCase

TC-01 至 TC-08 依 requirements；另驗證 auth test doubles 不會讓 HTTPClient 重新取得 Auth dependency，且 transport failure 不會呼叫 `receive(_:)`。
