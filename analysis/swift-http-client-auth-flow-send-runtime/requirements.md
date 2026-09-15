# Swift HTTPClient AuthFlow Send Runtime：需求

## Goal

將 generic `AuthFlow` driver 自 `HTTPClient` 移至 internal `AuthRequester` decorator。`HTTPClient` 只保留一次 bare HTTP execution；`AuthRequester` 以 injected `Requester` 與長存的 `any Auth`，為每次 `execute(_:)` 建立新 flow 並依 action 執行。

## Non-Goal

不實作 OAuth、TokenProvider、Keychain、Bearer header、401 refresh、GitHub REST endpoint、Apollo／GraphQL integration、retry 次數或任何 concrete authentication policy；不改 bare HTTP execution。

## Decision Source

本次 human-authorized architecture amendment supersede 此 draft branch 上「`HTTPClient.execute(_:auth:)` 驅動 AuthFlow」的實作與 delivery 判定。已鎖定：driver 歸 `AuthRequester`；`Requester` 維持 public 的單一 request 對單一 response abstraction；本 topic 不為未來 GitHub adapter 擴張 public surface，故 `AuthRequester` 維持 internal。

PR #27 post-delivery review 另鎖定四項受限 correction：package canvas 必須只表達 ownership 與 compile-time dependency；`AuthRequester` 必須如實顯示直接使用的 request／response contracts；step ledger 必須保留已發生的 historical delivery；architecture overview 必須列出 public 的 generic terminal error。PR-02／PR-03 的 source、lifecycle、BC README 與 diagram work 均為 historical scope，不是 PL-04 授權。PL-04 不重開 AuthRequester driver、lifecycle 或任何 auth policy 決策。

## In-Scope

- 移除 `HTTPClient.execute(_:auth:)`，不保留 shim、deprecated overload 或其他 auth entry point；bare `execute(_:)`、`request(...)` 與 HTTP method facades 保持既有行為。
- 新增 internal `AuthRequester`，以 constructor injection 接收 `Requester` 與 `any Auth`；每個 `execute(_:)` 只建立一個新的 mutable `AuthFlow` 並只呼叫一次 `start()`。
- 在 `AuthRequester` 依序處理 `.send(nextRequest) → requester.execute(nextRequest) → flow.receive(response)`；`.finish` 在已有 response 時回傳最後 response，否則 throw `HTTPClientError.authFlowFinishedWithoutResponse`。
- transport／Requester error 原樣立即傳遞；不可 receive、取得下一 action、分類 status 或加上 retry。4xx／5xx 是回灌 flow 的 raw response。
- 更新 architecture prose，使 `HTTPClientError.authFlowFinishedWithoutResponse` 明列為 public、非 transport 的 generic terminal error；它不改變既有 cancellation、network、non-HTTP response 或 underlying failure 的責任。
- AuthFlow lifecycle 維持既定 `AuthRequester → Requester → Transport` truth。PL-04 的 HTTP package canvas 只表達 ownership／compile-time dependency：自 `c44def5` 恢復且逐字採用 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`，取代 generic `.send → raw response → receive` runtime invariant；並補上 `AuthRequester → HTTPRequest`、`AuthRequester → HTTPResponse` direct compile-time dependencies。保留既定 internal tag、`AuthRequester → Auth` injected dependency 與 `AuthRequester → AuthFlow` dependency。`BUILD.md` 與 `scene.js` 的 subtitle 不可描述 runtime flow 或 raw response；現有 subtitle 符合此限制，PL-04 不修改 `BUILD.md`。

## Out-Of-Scope

- `Auth`、`AuthFlow`、`ClientAction`、`Requester`、`Transport`、`URLSessionTransport`、`HTTPRequest`、`HTTPResponse`、manifest 與 HTTP method facade 的 declaration 或 semantics。
- GitHubIntegration、其他 BC、bounded-context map、舊 topic artifacts，以及 GitHub REST 或 Apollo 實作。
- Canvas viewer interaction 或 accessibility redesign。
- 在本次 post-delivery correction 修改 lifecycle source、generated artifact、visual evidence、bounded-context README，或重新定義 HTTPURL validation、transport failure、AuthFlow action／receive semantics。

## Written

- `analysis/swift-http-client-auth-flow-send-runtime/requirements.md`
- `analysis/swift-http-client-auth-flow-send-runtime/technical-spec.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.plan.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.step.md`
- PR-02 historical implementation 曾新增 internal `AuthRequester.swift` 與 `AuthRequesterTests.swift`；不新增 package target 或 public product。PL-04 不新增任何檔案。

## Modify

- PR-02 historical scope 曾修改 `HTTPClient.swift`、`HTTPClientError.swift`、`HTTPClientTests.swift` 與 `TestDoubles.swift`；這些 paths 在 PL-04 皆為 ReadOnly。
- PR-02／PR-03 historical records 曾修改 architecture overview、BC directory README、AuthFlow lifecycle source/generated/evidence 與 HTTP package-structure source/generated artifact；它們不構成 PL-04 修改授權。
- PL-04 writable allowlist 嚴格為 `docs/architecture/README.md`（只補 public no-response terminal-error prose）、package canvas `scene.js`（只以 `c44def5` 的指定 invariant 取代 runtime invariant，並加入兩條 direct type edge）與由既定 pipeline 產生的 `index.html`。現有 `BUILD.md` subtitle 已符合 ownership／dependency-only 限制，維持 ReadOnly；只有 subtitle 被證實不一致時才可修改它。

## ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、`HTTPRequest.swift`、`HTTPResponse.swift`、`Package.swift`、`AuthTests.swift` 與 request／verb facade source。
- `enhance-accessibility.js`：必須先恢復為 feature branch 對 dev 的 merge-base `c44def5` 版本，並維持 ReadOnly；其相對於 `c44def5` 必須是 zero diff。
- `BUILD.md` 的 build semantics 維持 ReadOnly；現有 subtitle 已符合 contract，僅在被證實不一致時才可作為 PL-04 conditional writable path。
- 本 correction 中，AuthFlow lifecycle source、generated HTML、visual-check evidence、bounded-context README 與 `auth-flow-lifecycle` 既定 failure branch 均為 ReadOnly。
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
| TC-08 | diagrams／Canvas | lifecycle 維持既定 Requester failure/no-receive branch，既有 Archify evidence 為 ReadOnly；package canvas 明示 internal tag、`AuthRequester → Auth`、`AuthRequester → HTTPRequest` 與 `AuthRequester → HTTPResponse` dependencies，只保留 ownership／compile-time invariant，且 invariant 逐字為 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`；Canvas rebuild gates 通過，且有獨立 manual visual review evidence。 |
| TC-09 | architecture failure prose | overview 明列 `HTTPClientError.authFlowFinishedWithoutResponse` 為 public、非 transport terminal error，且不錯誤歸類為 network／status policy。 |

## Success Criteria

- `HTTPClient` 的 public surface 不再認識 `Auth`；`AuthRequester` 是唯一 generic flow driver。
- flow lifecycle、terminal error、multi-send 與 failure semantics 均有 focused tests；完整 SwiftPM tests 與 `git diff --check` 通過。
- 先完成新的 planning review；先前基於 HTTPClient driver 的 Tester、Reviewer、commit、Draft PR 與 human-review readiness 都不可作為本次 delivery evidence。
- 五個既有已 resolved PR threads 維持 immutable historical traceability，不得 reopen、替換或再次 resolve；四個新增 review threads 的精確修正映射與 resolve completion condition 以 step ledger 為唯一追蹤真相。
