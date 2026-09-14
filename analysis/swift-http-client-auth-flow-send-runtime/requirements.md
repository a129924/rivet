# Swift HTTPClient AuthFlow Send Runtime：需求

## Goal

將 generic `AuthFlow` driver 自 `HTTPClient` 移至 internal `AuthRequester` decorator。`HTTPClient` 只保留一次 bare HTTP execution；`AuthRequester` 以 injected `Requester` 與長存的 `any Auth`，為每次 `execute(_:)` 建立新 flow 並依 action 執行。

## Non-Goal

不實作 OAuth、TokenProvider、Keychain、Bearer header、401 refresh、GitHub REST endpoint、Apollo／GraphQL integration、retry 次數或任何 concrete authentication policy；不改 bare HTTP execution。

## Decision Source

本次 human-authorized architecture amendment supersede 此 draft branch 上「`HTTPClient.execute(_:auth:)` 驅動 AuthFlow」的實作與 delivery 判定。已鎖定：driver 歸 `AuthRequester`；`Requester` 維持 public 的單一 request 對單一 response abstraction；本 topic 不為未來 GitHub adapter 擴張 public surface，故 `AuthRequester` 維持 internal。

## In-Scope

- 移除 `HTTPClient.execute(_:auth:)`，不保留 shim、deprecated overload 或其他 auth entry point；bare `execute(_:)`、`request(...)` 與 HTTP method facades 保持既有行為。
- 新增 internal `AuthRequester`，以 constructor injection 接收 `Requester` 與 `any Auth`；每個 `execute(_:)` 只建立一個新的 mutable `AuthFlow` 並只呼叫一次 `start()`。
- 在 `AuthRequester` 依序處理 `.send(nextRequest) → requester.execute(nextRequest) → flow.receive(response)`；`.finish` 在已有 response 時回傳最後 response，否則 throw `HTTPClientError.authFlowFinishedWithoutResponse`。
- transport／Requester error 原樣立即傳遞；不可 receive、取得下一 action、分類 status 或加上 retry。4xx／5xx 是回灌 flow 的 raw response。
- 更新 architecture prose、AuthFlow lifecycle 與 HTTP package structure，使其如實表達 `AuthRequester → Requester → Transport` ownership；保留已交付的 Canvas initial-fit 行為與既有驗證要求。

## Out-Of-Scope

- `Auth`、`AuthFlow`、`ClientAction`、`Requester`、`Transport`、`URLSessionTransport`、`HTTPRequest`、`HTTPResponse`、manifest 與 HTTP method facade 的 declaration 或 semantics。
- GitHubIntegration、其他 BC、bounded-context map、舊 topic artifacts，以及 GitHub REST 或 Apollo 實作。
- Canvas viewer interaction、share format、pan／zoom semantics 或 accessibility redesign；initial-fit support 只能維持，不能藉本次改動重設其既有契約。

## Written

- `analysis/swift-http-client-auth-flow-send-runtime/requirements.md`
- `analysis/swift-http-client-auth-flow-send-runtime/technical-spec.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.plan.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.step.md`
- implementation 另新增 internal `AuthRequester.swift` 與 `AuthRequesterTests.swift`；不新增 package target 或 public product。

## Modify

- `HTTPClient.swift` 移除 auth overload，保持 bare facade。
- `HTTPClientError.swift` 保留／使用 `authFlowFinishedWithoutResponse`。
- `HTTPClientTests.swift` 移除已不屬於 client 的 auth-driver tests；`TestDoubles.swift` 僅保留或調整 deterministic flow／transport support。
- architecture overview、BC directory README、AuthFlow lifecycle source/generated/evidence、HTTP package-structure source/generated artifact；Canvas build/enhancer support 維持 initial-fit 行為。

## ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、`HTTPRequest.swift`、`HTTPResponse.swift`、`Package.swift`、`AuthTests.swift` 與 request／verb facade source。
- 既有 Canvas `BUILD.md`／`enhance-accessibility.js` 的 initial-fit contract，除維持與驗證所需的 generated output 外不改其 semantics。
- `swift-http-client-auth-flow-contract` artifacts、GitHubIntegration、其他 BC 與 bounded-context map。

## Deleted

無檔案 deletion、move 或 rename。移除的是 `HTTPClient` 內的 auth overload 與其測試 coverage，不是 source file 或既有 public type 的刪除。

## TestCase

| ID | Scenario | Expected result |
| --- | --- | --- |
| TC-01 | bare `HTTPClient.execute(_:)` 與 facades | 原 single dispatch、raw response 與 error propagation 不變；沒有 auth overload。 |
| TC-02 | start `.send`、receive `.finish` | AuthRequester make-flow／start 各一次；response receive 一次且被回傳。 |
| TC-03 | flow 產生第二個 `.send` | 同一 injected Requester 依序發送兩次，並回傳最後 response。 |
| TC-04 | start 直接 `.finish` | throw `.authFlowFinishedWithoutResponse`；零 request、零 receive。 |
| TC-05 | 每次 AuthRequester execute | 共用 injected Auth，但為每次 execution 建立新的 flow。 |
| TC-06 | 首次或後續 requester failure | 原 `HTTPClientError` 立即傳遞；不 receive、不再 dispatch、不 retry。 |
| TC-07 | 4xx／5xx | raw `HTTPResponse` 照常 receive，由 flow 決定後續 action。 |
| TC-08 | diagrams／Canvas | flow ownership 改為 AuthRequester；Archify 與 Canvas gates 通過，且 initial untouched-unshared resize refit 與 share／pan-zoom transform preservation 不 regress。 |

## Success Criteria

- `HTTPClient` 的 public surface 不再認識 `Auth`；`AuthRequester` 是唯一 generic flow driver。
- flow lifecycle、terminal error、multi-send 與 failure semantics 均有 focused tests；完整 SwiftPM tests 與 `git diff --check` 通過。
- 先完成新的 planning review；先前基於 HTTPClient driver 的 Tester、Reviewer、commit、Draft PR 與 human-review readiness 都不可作為本次 delivery evidence。
