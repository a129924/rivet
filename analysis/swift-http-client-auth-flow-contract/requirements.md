# Swift HTTP Client Auth Flow Contract：需求

## Goal

在 generic `RivetHTTPClient` 宣告可供未來 wrapper 使用的 public auth-flow contracts：`ClientAction`、`Auth` 與 `AuthFlow`。本 topic 僅建立型別邊界，不執行或解讀 flow。

## In Scope

- public `ClientAction: Sendable`，僅有 `.send(HTTPRequest)` 與 `.finish`。
- public `Auth: Sendable`，由既有 `HTTPRequest` 建立 `any AuthFlow`。
- public `AuthFlow: Sendable`，提供 non-throwing、`mutating async` 的 `start()` 與 `receive(_:)` state transitions。
- package external test target 的 concrete conformers，驗證 public conformance、existential return、action pattern matching 與 async transition signature。

## Out of Scope

- concrete auth、token／credential provider、parser、persistence、NoAuth、Bearer、Basic、Digest、OAuth。
- flow driver、runtime、request dispatch、response routing、HTTP request execution。
- `HTTPClient`、`Requester`、`Transport`、`HTTPRequest`、`HTTPHeaders`、`HTTPResponse`、`HTTPClientError`、manifest 的任何變更。
- static header auth、retry、refresh、challenge、401 policy、GitHub behavior。
- GitHub Integration、其既有 topic、architecture／BC docs 或 canvas 的變更。

## Success Criteria

- external target 可宣告符合 `Auth` 與 `AuthFlow` 的 concrete types。
- `Auth.makeFlow(for:)` 可回傳 `any AuthFlow`。
- `await start()` 與 `await receive(_:)` 可用於 mutable existential flow。
- `.send(HTTPRequest)` 與 `.finish` 可 exhaustive pattern match。
- 既有 HTTP execution behavior 不變。
