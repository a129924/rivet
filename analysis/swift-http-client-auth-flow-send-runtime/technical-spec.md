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
- architecture overview 必須將 `HTTPClientError.authFlowFinishedWithoutResponse` 說明為 public、非 transport 的 generic terminal error；其餘既定 transport failures 的責任不變。
- package canvas 只表達 ownership／compile-time dependency：自 `c44def5` 恢復並逐字採用 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`，取代 `.send → raw response → receive` runtime invariant，並加入 `AuthRequester → HTTPRequest` 與 `AuthRequester → HTTPResponse` direct dependencies。既定 internal tag、`AuthRequester → Auth` injected dependency、`AuthRequester → AuthFlow` dependency 與 lifecycle 的 Requester failure/no-receive branch 均保留；`BUILD.md` 與 `scene.js` subtitle 不描述 runtime flow 或 raw response，現有 `BUILD.md` subtitle 不需變更。

## Out-Of-Scope

- 變更 public `Requester` single-request semantics 或讓它讀取 `AuthFlow` action。
- 將 AuthRequester 暴露給 package 外 caller；未來 GitHub REST adapter 若需直接建構，須由新 topic 決定 public API。
- status、header、body、original／next request equality 的 generic interpretation，或 loop cap／retry count。
- 本 correction 變更 AuthFlow lifecycle source／generated artifact／visual evidence、bounded-context README，或改變 HTTPURL validation、transport failure、AuthFlow action／receive semantics。

## Interface and Data Flow

- `HTTPClient` 對 bare request 仍為 `HTTPRequest → Requester → Transport → HTTPResponse`。
- `AuthRequester` 擁有 injected `Requester` 與長存 injected `any Auth`；它不擁有 Transport、GitHub、OAuth 或 token capability。
- 每個 `AuthRequester.execute(_:)` 呼叫以 input request 建立一個新 flow。flow 可送出零或多個 request；只有 successful requester response 才傳入 `receive(_:)`。
- `.finish` 不帶 response payload，因此 return value 是最後一次成功 response；沒有成功 response 時是 typed terminal error。

## File Contract

### Written

- planning phase 的四份同 slug artifacts。
- PR-02 historical implementation 曾寫入 `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift` 與 `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/AuthRequesterTests.swift`；PL-04 不新增檔案。

### Modify

- PR-02 historical scope 曾修改 `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClientError.swift`、`packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift` 與 `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`；它們都不是 PL-04 writable paths。
- PR-02／PR-03 historical work 曾修改 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、lifecycle source/generated evidence 與 package canvas artifact；這些不是 PL-04 writable contract。
- PL-04 writable allowlist 嚴格為 `docs/architecture/README.md`（只補 public no-response terminal error）、`docs/architecture/diagrams/http-client-package-structure/scene.js`（只以 `c44def5` 的指定 invariant 取代 runtime invariant，並加入兩條 direct type edges）與由既定 pipeline 產生的 `index.html`。現有 `BUILD.md` subtitle 不需變更，只有被證實不一致時才是 conditional writable path；其餘 build semantics、layout 與 scene content 不變。

### ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、`HTTPRequest.swift`、`HTTPResponse.swift`、`Package.swift`、`AuthTests.swift`、request／verb facades。
- `enhance-accessibility.js`：先恢復為 feature branch 對 dev 的 merge-base `c44def5` 版本，並保持 ReadOnly；相對於 `c44def5` 必須是 zero diff。
- `BUILD.md` 的 build semantics 與現有 subtitle；只有 subtitle 被證實不一致時才可作為 PL-04 conditional writable path。
- 本 correction 中的 AuthFlow lifecycle source、generated HTML、visual-check evidence、bounded-context README 與既定 Requester failure/no-receive branch。
- 所有非本 topic 的 source、tests、docs、diagrams 與 historical topic artifacts。

### Deleted

無檔案刪除、搬移或改名；僅移除 `HTTPClient` 的 auth overload 與其專屬 tests。

## Verification

- `HTTPClientTests` 只驗證 bare facade；新增 `AuthRequesterTests` 以 `@testable import` 覆蓋 internal driver。
- focused AuthRequester／HTTPClient tests、complete SwiftPM tests 與 `git diff --check`。
- Archify lifecycle：既有 delivery／visual evidence 只作歷史 ReadOnly evidence。Canvas：對本 correction 重跑既定 validate/build/enhance/verify，並由獨立 Tester 記錄 rebuild 後 light/dark desktop manual visual review；evidence 必須明確記錄於 step ledger，才可完成 TE-03。
- 四個目前 PR review threads 的 ID、個別修正與 resolve completion condition 只記錄於 step ledger；所有 mapped correction 經 Tester、Reviewer、push 後，才可 resolve 對應 thread。五個 prior resolved threads 維持 historical，禁止重開或重複 resolve。

## TestCase

TC-01 至 TC-09 依 requirements；另驗證 auth test doubles 不會讓 HTTPClient 重新取得 Auth dependency，且 transport failure 不會呼叫 `receive(_:)`。
