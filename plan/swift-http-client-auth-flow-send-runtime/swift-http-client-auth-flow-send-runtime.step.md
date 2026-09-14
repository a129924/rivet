# Swift HTTPClient AuthFlow Send Runtime：Step Ledger

## Current Phase

delivery-ready。PR-01 已 approved、IM-01 completed、TE-01 passed、RV-01 final approved。DL-01 已獲授權且等待執行 delivery；commit、push、draft PR 與 human review 均尚未完成。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-01 | Plan-Creator | completed | 建立 requirements、technical spec、plan 與 step，鎖定範圍、API、files、tests、gates。 | 四份同 slug artifacts 一致，且不重開 human locked contract。 | 本 topic 四份 planning artifacts。 |
| PR-01 | Plan-Reviewer | approved | 獨立審查 planning artifacts、workflow contract、scope／contract drift 與 implementation readiness。 | verdict 為 `approved`；否則回 Plan-Creator 或交 human-check。 | Plan-Reviewer approved verdict。 |
| IM-01 | Implementer | completed | 僅修改列於 Modify 的 Swift、tests、docs 與 diagram artifacts。 | locked driver semantics、typed direct-finish error、所有圖表 source/generated/evidence 更新完成；Canvas initial untouched unshared resize refit，share hash 或 pan／zoom transform preservation；無 ReadOnly／Deleted 違反。 | bounded implementation 已完成；功能與 artifact verification 交由 TE-01 passed。 |
| TE-01 | Tester | passed | 獨立執行 test 與 artifact verification。 | focused/full SwiftPM tests、`git diff --check`、Archify showcase validate 9/9／deliver／visual-check／人工 review，以及 Canvas validate/build/enhance/verify／人工 review、unshared untouched resize refit 與 share hash／pan-zoom transform preservation 全部記錄。 | Tester final functional pass；完整 receipts 與 inspection evidence 由 Tester report 保留。 |
| RV-01 | Reviewer | approved | 獨立審查 code、tests、docs、diagrams 與 evidence。 | `approved`；若 scope、contract、workflow 或 verification drift，判為 `needs-rework` 或 `human-check`。 | Reviewer final staged approval。 |
| DL-01 | Implementer | ready-for-authorized-delivery | 依 user 已授權的 delivery sequence，完成 commit、push 與 draft PR。 | `git-commit-convention` 檢查 staged semantic boundary，單一 commit `feat(http-client): drive auth flow sends`，feature branch push 與 draft PR URL。 | Reviewer final approved；authorized delivery 等待執行，尚無 commit、push 或 draft PR evidence。 |
| HC-01 | Human | blocked-by-DL-01 | 人工審查 draft PR。 | human 明示下一步；任何 comment 或 change request 重新進入獨立 Implementer／Reviewer gate。 | human review verdict。 |

## File Boundary

### Goal

以 auth overload 讓 generic `HTTPClient` 對 `AuthFlow` actions 發送 request 並回灌 raw response，直到 final response 或 typed direct-finish error。

### Non-Goal

credential、token、OAuth、GitHub、status／Content-Type policy、retry、backoff、flow cap、endpoint／URL 組裝、另一個 driver，與 AuthFlow contract redesign。

### In-Scope

- `execute(_:auth:)`、generic driver loop、`authFlowFinishedWithoutResponse`、deterministic driver tests。
- architecture overview／BC directory long-term truth，AuthFlow lifecycle 與 HTTP package structure artifacts；package-structure existing delivery support 的 narrow initial-fit fix。

### Out-Of-Scope

- Auth／AuthFlow／ClientAction declarations，transport chain、HTTP value types、manifest、request／verb facades、GitHubIntegration、其他 BC／map、舊 topic analysis／plan；除 locked initial-fit 之外的 Canvas viewer interaction、share format、pan／zoom semantics 或 accessibility redesign。

### Written

- Planning phase：`analysis/swift-http-client-auth-flow-send-runtime/requirements.md`、`analysis/swift-http-client-auth-flow-send-runtime/technical-spec.md`、`plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.plan.md`、`plan/swift-http-client-auth-flow-send-runtime/swift-http-client-auth-flow-send-runtime.step.md`。
- Implementation phase：不新增 Swift source／test file；只由 diagram delivery 重寫既有 generated HTML 與 visual-check evidence。`BUILD.md` 與 `enhance-accessibility.js` 是既有 delivery support，僅能為 locked initial-fit 行為修改；implementation delivery 可寫入既有 `docs/architecture/diagrams/http-client-package-structure/BUILD.md` 與 `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClientError.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/HTTPClientTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/TestDoubles.swift`
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`、`auth-flow-lifecycle.html`、`auth-flow-lifecycle.visual-check.*`
- `docs/architecture/diagrams/http-client-package-structure/scene.js`、`index.html`
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`
- `docs/architecture/diagrams/http-client-package-structure/enhance-accessibility.js`

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`、`packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`
- `packages/RivetHTTPClient/Package.swift`、`packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/AuthTests.swift`、request／verb facade source
- `analysis/swift-http-client-auth-flow-contract/`、`plan/swift-http-client-auth-flow-contract/`、GitHubIntegration、其他 BC、bounded-context map。

### Deleted

無；任何 deletion、move 或 rename 都是 blocker。

## TestCase

| ID | Scenario | Expected result |
| --- | --- | --- |
| TC-01 | 無 auth 的 `execute(_:)` 與 facades | 原 direct dispatch、raw response、error behavior 不變；facades 無 auth overload。 |
| TC-02 | 單輪 flow：start `.send`、receive `.finish` | make-flow/start 各一次，request 已送出，response 僅 receive 一次並回傳。 |
| TC-03 | 多輪 flow | requests/responses 依 action 順序，回傳最後 successful response。 |
| TC-04 | start direct `.finish` | 拋 `.authFlowFinishedWithoutResponse`；零 transport、零 receive。 |
| TC-05 | 首輪／後續 transport failure | 同一 `HTTPClientError` 立即傳遞；無 receive、下一 action 或 retry。 |
| TC-06 | 4xx／5xx response | exact raw response 仍交給 flow，HTTPClient 不分類。 |
| TC-07 | Auth contract regression | `any AuthFlow` mutable transition conformance 維持。 |
| TC-08 | diagram delivery 與 Canvas initial-fit | Archify 9/9 clean validate、deliver、visual-check 與人工 screenshot review；Canvas validate/build/enhance/verify 與人工 screenshot review 均有 evidence。未互動且未帶 share hash 的 initial view resize 時重新 fit；有 share hash 或任何 pan／zoom 後，resize 保持既有 transform。 |

## Stop Conditions

- PR-01、TE-01 或 RV-01 為 `needs-rework`：停止前進，交不同的 Implementer 做 bounded fix，然後重新進入相應獨立 gate。
- 任一 gate 為 `blocked` 或 `human-check`：停止並交 Dispatcher／human；不得自行推進、改 scope 或重開 locked decision。
- DL-01 完成 draft PR 後：停在 HC-01。不得 merge、release、處理 PR comments 或假裝 human review 已完成。
