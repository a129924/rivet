# Swift HTTPClient AuthFlow Send Runtime

## Summary

在 `RivetHTTPClient` 將既有 `AuthFlow` contract 接入 `HTTPClient` 的 auth overload。client 僅依 `.send` dispatch request、回灌 raw response 與處理 terminal result；flow 保留認證決策。此 runtime 行為明確 supersede `swift-http-client-auth-flow-contract` 中 HTTPClient 非 driver 的歷史決策。

## Goal

透過 `execute(_:auth:)` 完成通用 `send → response → receive` loop，並回傳使 flow finish 的最後成功 `HTTPResponse`。

## Non-Goal

不實作 credential／token／OAuth／GitHub behavior、static headers、status 或 Content-Type policy、retry／backoff、flow cap、endpoint／URL 組裝、另一個 driver，或變更 AuthFlow contract。

## In-Scope

- 新增 `execute(_ request: HTTPRequest, auth: any Auth)`；原 `execute(_:)` 和 `request(...)`／verb facades 不變。
- flow 僅建立一次、`start()` 僅呼叫一次；每次 `.send` 經 `Requester` 執行並將成功 raw response 回灌一次。
- `.finish` 回傳最後 response；direct finish 丟出 `.authFlowFinishedWithoutResponse`。
- transport error 原樣停止；所有 HTTP status 交由 flow。
- 最小 docs、Archify lifecycle 與 Architecture Canvas writeback，並完成各自 required verification；Canvas existing generated-viewer/accessibility delivery support 只修正 initial untouched unshared view 的 resize refit。

## Out-Of-Scope

- `Auth`、`AuthFlow`、`ClientAction`、`Requester`、`Transport`、`URLSessionTransport`、`HTTPRequest`、`HTTPResponse`、manifest、method facade、GitHubIntegration、其他 BC／bounded-context map 的修改。
- 既有 `swift-http-client-auth-flow-contract` 的 analysis／plan artifacts 修改。
- 除已鎖定 initial-fit 行為外的 Canvas viewer interaction、share format、pan／zoom semantics 或 accessibility redesign。

## Public Interface and Implementation Changes

- `HTTPClient.swift` 使用 mutable `any AuthFlow` 實作 locked driver sequence；直接使用 private `Requester`，避免 auth overload 遞迴或改動 non-auth path。
- `HTTPClientError.swift` 新增 `authFlowFinishedWithoutResponse`；無 response 的 terminal condition 不映射成 transport failure。
- `HTTPClientTests.swift` 驗證 driver order、terminal response、direct finish、errors 與 raw HTTP statuses；`TestDoubles.swift` 僅加入需要的 deterministic transport recording support。
- docs 與圖表只更新 ownership／lifecycle／package structure 事實，不宣稱 retry 或 GitHub authentication policy。
- Canvas `BUILD.md` 與 `enhance-accessibility.js` 僅作 generated-viewer/accessibility delivery support：未互動且無 share hash 的 initial view 隨 resize refit；任何 share hash 或 pan／zoom 後保留 transform。

## Written

本次先建立四份 topic artifacts：

- `analysis/swift-http-client-auth-flow-send-runtime/requirements.md`
- `analysis/swift-http-client-auth-flow-send-runtime/technical-spec.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.plan.md`
- `plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.step.md`

Swift implementation 不建立新的 Swift source 或 test file；圖表交付只重寫既有 generated HTML 與 Archify visual-check evidence。`BUILD.md` 與 `enhance-accessibility.js` 是既有 delivery support，僅能為 locked initial-fit 行為修改，不新增 viewer／accessibility artifact。implementation delivery 可寫入既有 `docs/architecture/diagrams/http-client-package-structure/BUILD.md` 與 `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`，僅為此 support。

## Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClientError.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`、`auth-flow-lifecycle.html`、`auth-flow-lifecycle.visual-check.*`
- `docs/architecture/diagrams/http-client-package-structure/scene.js`、`index.html`
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`
- `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`

## ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、`HTTPRequest.swift`、`HTTPResponse.swift`、`Package.swift`、`AuthTests.swift` 與 request／verb facade source。
- `analysis/swift-http-client-auth-flow-contract/`、`plan/swift-http-client-auth-flow-contract/`、GitHubIntegration、其他 BC、bounded-context map。

## Deleted

無；不刪除、搬移或更名任何既有 source、test、API、topic artifact 或 diagram artifact。

## TestCase

- 原 `execute(_:)` 維持單次 direct dispatch、raw response 與 error propagation；facades 未獲 auth parameter。
- auth flow 建立一次、`start()` 一次；start 的 `.send` request 被送出。
- 每個 successful send 的 exact response 只傳給 `receive(_:)` 一次；multi-send 依序送出並回傳終止前最後 response。
- `start() → .finish` 丟 `.authFlowFinishedWithoutResponse`，零 transport、零 receive。
- 首次或後續 send 的 transport error 不變傳遞；不 receive、不再取 action、不 retry。
- 4xx 與 5xx raw response 仍回灌 flow，不由 client 分類。
- 既有 `Auth` public conformance／mutable existential coverage 維持。
- SwiftPM focused/full tests、diff check、Archify 9/9 showcase delivery＋visual evidence／人工 review、Canvas validate/build/enhance/verify＋人工 review 均通過；initial untouched unshared view resize refit，share hash 或 any pan／zoom 後 resize preserve transform。

## Delivery Gates

1. Plan-Reviewer approval 後，獨立 Implementer 才能修改 Swift／docs／diagrams。
2. 實作完成後，獨立 Tester 執行全部 TestCase 與 diagram verification，包含 Canvas unshared untouched resize refit 與 share hash／pan-zoom transform preservation；失敗只交給新的 Implementer 修復。
3. 獨立 Reviewer 檢查 scope、public contract、docs／diagram truthfulness 與 Tester evidence；發現 scope／contract／workflow drift 一律 `needs-rework` 或 `human-check`。
4. 僅在 Reviewer approval 且無 major blocker 後，由 Code-Implementer 依 `git-commit-convention` 檢查 staged diff，使用單一 topic commit `feat(http-client): drive auth flow sends`，push feature branch，並開 draft PR。
5. draft PR 開啟後即停止自動前進，交 human review；不自行 merge、release 或處理後續 PR comment。
