# Swift HTTP Response JSON Sendable Contract

## Historical Delivery Summary

收緊 `HTTPResponse` 兩個 JSON decoded payload APIs 的 public generic constraint，讓 decoded payload 必須為 `Decodable & Sendable`。這是預期的 source-breaking contract 變更；除直接 decoded payload test fixtures 外，不變更任何既有行為或所有權邊界。

## Historical Implementation Changes

- 將 `HTTPResponse.json(_:decoder:)` 更新為 `json<T: Decodable & Sendable>(_:decoder:) throws -> T`。
- 將 `HTTPResponse.jsonSemantic(_:decoder:)` 更新為 `jsonSemantic<T: Decodable & Sendable>(_:decoder:) throws -> T`。
- 僅為直接傳入兩個 JSON APIs 的 decoded payload test fixtures 補上 `Sendable` conformance。

## Historical Swift Implementation Record

### Delivered Goal

讓 `HTTPResponse` 的 decoded JSON payload APIs 具有 `Sendable` contract。

### Delivered Non-Goal

- 不讓 `JSONSemanticDecodingError`、`underlyingError` 或其他 error payload 符合 `Sendable`。
- 不變更 raw response、HTTP execution chain、decoder ownership、HTTP metadata policy、manifest、diagrams 或 Bounded Context boundary。

### Delivered Scope

- `HTTPResponse.json` 與 `HTTPResponse.jsonSemantic` 的 `T: Decodable & Sendable` 泛型 constraints。
- 直接作為兩個 APIs decoded payload 的 test fixtures `Sendable` conformance。
- 本 topic 的四份 planning artifacts、topic-scoped commit、push、draft PR 與 human review handoff。
- Post-delivery remediation 僅更新 `docs/architecture/README.md` 既有 HTTPResponse JSON convenience 說明，加入兩個 decoded payload APIs 都要求 `Decodable & Sendable` 的 public contract。
- Post-delivery remediation 僅校正本 topic step ledger 的 commit `a7bfc9d`、已推送 feature branch、PR #25 Ready、先前 Reviewer re-review `approved`，並追加新的 remediation cycle。

### Delivered Boundaries

- `JSONSemanticDecodingError`、underlying error、error payload 與 semantic decoding error behavior。
- `HTTPClient → Requester → Transport`、raw `HTTPResponse`、decoder instance ownership、HTTP status／headers／`Content-Type` validation policy。
- package manifest、除 `docs/architecture/README.md` 外的 architecture docs／diagrams、Bounded Context files、既有 locked topics，以及合併、release 或後續整合。
- Post-delivery remediation 的 source／test 變更、GitHub comment reply 或 thread resolution。

### Historical ReadOnly Boundaries

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/` 與 `packages/RivetHTTPClient/Package.swift`：只供 boundary verification 與 standalone checks。
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/JSONSemanticDecodingError.swift`：error contract 不得變更。
- 既有 JSON decoding 與 semantic decoding topics、除 `docs/architecture/README.md` 外的 architecture docs、Bounded Context files 及 diagrams。
- Post-delivery remediation 的 production source、tests、package manifest 與其他 docs。

### Historical Written Targets

- `analysis/swift-http-response-json-sendable-contract/requirements.md`
- `analysis/swift-http-response-json-sendable-contract/technical-spec.md`
- `plan/swift-http-response-json-sendable-contract/swift-http-response-json-sendable-contract.plan.md`
- `plan/swift-http-response-json-sendable-contract/swift-http-response-json-sendable-contract.step.md`
- `docs/architecture/README.md`：僅既有 HTTPResponse JSON convenience 說明的 contract writeback。

### Historical Deleted Targets

- 無；不得刪除、搬移或更名既有 API、source、tests、artifacts 或 docs。

### Historical Modified Targets

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/HTTPResponse.swift`：僅收緊兩個 JSON APIs 的泛型 constraints。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Response/HTTPResponseTests.swift`：僅讓直接 decoded payload fixtures 符合 `Sendable`。
- Post-delivery remediation 僅可修改 `docs/architecture/README.md` 與本 topic step ledger；不得改動其他 source、test、doc 或 diagram。

### Historical Test Evidence

- `json` success 與 configured decoder。
- `jsonSemantic` success 與 configured decoder。
- `json` raw `DecodingError` passthrough。
- `jsonSemantic` semantic error mapping 與 underlying error retention。
- metadata non-validation 與 raw response regression。
- `RivetHTTPClient` standalone `swift build` 與 `swift test`。
- Post-delivery remediation：靜態確認 README 同時記載兩個 decoded payload APIs 的 `Decodable & Sendable` contract，及 ledger 對既有 delivery／re-review evidence 與新 cycle gate 的記錄；不重新執行 Swift source checks。

## Post-Delivery PR Remediation Contract

### Goal

將已交付的 decoded payload `Decodable & Sendable` public contract 回寫至 HTTP client 長期架構說明，並校正 ledger 的既有 delivery 與 Reviewer re-review handoff。

### Non-Goal

- 不重新實作或驗證既有 Swift source／test 交付。
- 不變更 diagram、Bounded Context boundary、execution policy、error policy、`JSONSemanticDecodingError`、manifest 或任何其他 architecture 文件。

### In-Scope

- 僅更新 `docs/architecture/README.md` 既有 HTTPResponse JSON convenience 說明，明示 `json(_:decoder:)` 與 `jsonSemantic(_:decoder:)` 的 decoded payload 都必須符合 `Decodable & Sendable`。
- 僅校正本 topic step ledger：既有 commit `a7bfc9d`、已推送 feature branch、PR #25 Ready、先前 Reviewer re-review `approved` 必須為完成事實，並新增本次 remediation 的 planning／implementation／test／review／delivery cycle。

### Out-Of-Scope

- production source、tests、package manifest、除 `docs/architecture/README.md` 外的 docs、diagrams、Bounded Context 文件，以及本 topic 以外的 artifacts。
- GitHub reply、thread resolution、merge、release、branch deletion 或其他 PR 操作。

### ReadOnly

- 除 `docs/architecture/README.md` 外的所有 docs、diagrams、Bounded Context 文件、production source、tests、package manifest 與本 topic 以外的 artifacts。

### Written

- `docs/architecture/README.md` 的既有 HTTPResponse JSON convenience 說明。
- `plan/swift-http-response-json-sendable-contract/swift-http-response-json-sendable-contract.step.md` 的 ledger correction 與 remediation cycle。

### Deleted

- 無。

### Modify

- 僅修改上述 Written targets；不得新增、刪除或修改其他檔案。

### TestCase

- 靜態確認 README 同時記載兩個 decoded payload APIs 的 `Decodable & Sendable` contract，且不導入 execution、error 或 metadata policy。
- 靜態確認 ledger 保留既有 cycle evidence、將既有 delivery／re-review 事實標為完成，且新的 delivery 受本次獨立 Reviewer `approved` gate 約束並停在 GitHub reply／resolution 前。
- 本次 remediation 不重新執行 Swift build 或 test；既有 package checks 僅為歷史 evidence。

## Post-Delivery Remediation and Human Boundary

- 本次 remediation 的唯一長期真相 write target 是 `docs/architecture/README.md`；不得改 diagram、BC boundary、execution/error policy、`JSONSemanticDecodingError`、manifest 或其他 architecture 文件。
- 本次 remediation 的 planning／implementation／test／review／delivery 使用 step ledger 新 ID；不得覆寫既有 cycle 的 evidence。
- 僅在本次獨立 Reviewer 明示 `approved` 後，才可建立 remediation topic-scoped commit 並 push feature branch。
- commit／push 後停在 GitHub reply／resolution 前，交回 human review；不得自動 reply、resolve thread、merge、release、刪除 branch 或執行後續整合。

## Assumptions

- 呼叫端 payload 未符合 `Sendable` 時必須自行修正，以接受這項 source-breaking API contract。
- 若實作需要觸及 ReadOnly 或 Out-Of-Scope 範圍，停止並回報 human check；不得自行擴張。
