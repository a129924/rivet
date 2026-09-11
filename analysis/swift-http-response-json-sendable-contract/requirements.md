# Swift HTTP Response JSON Sendable Contract：需求

## Historical Delivered Goal

讓 `RivetHTTPClient` 的 `HTTPResponse` decoded JSON payload APIs 明確要求 payload 符合 `Sendable`，使成功解碼所得值具備跨並行邊界傳遞的型別契約。

## Historical Delivered Scope

- 將 `HTTPResponse.json(_:decoder:)` 的泛型 payload 約束收緊為 `Decodable & Sendable`。
- 將 `HTTPResponse.jsonSemantic(_:decoder:)` 的泛型 payload 約束收緊為 `Decodable & Sendable`。
- 讓直接作為上述 APIs decoded payload 的 test fixtures 明確符合 `Sendable`。

## Historical Delivered Boundaries

- `JSONSemanticDecodingError`、其 `underlyingError`，以及任何 error payload 的 `Sendable` contract。
- raw `HTTPResponse`、`HTTPClient → Requester → Transport` execution chain、decoder ownership 與 HTTP metadata policy。
- package manifest、architecture docs 或 diagrams，以及既有 locked topics。

## Historical Delivered Acceptance

- 兩個 public JSON APIs 的 payload 型別都必須同時符合 `Decodable` 與 `Sendable`。
- 成功解碼、caller-provided decoder configuration、raw error passthrough、semantic error mapping 與 underlying error retention 維持既有行為。
- HTTP metadata 不參與 decode validation，且 raw response regression 維持通過。
- `RivetHTTPClient` standalone `swift build` 與 `swift test` 通過。

## Post-Delivery PR Remediation Contract

### Goal

將已交付的 `Decodable & Sendable` decoded payload public contract 回寫至 HTTP client 長期架構說明，並校正本 topic ledger 的既有交付與 reviewer handoff 事實。

### Non-Goal

- 不重新實作或重新驗證已交付的 Swift source／test 變更。
- 不改變任何已鎖定的 architecture、execution 或 error contract。

### In-Scope

- 僅更新 `docs/architecture/README.md` 既有的 `HTTPResponse` JSON convenience 說明，明示 `json(_:decoder:)` 與 `jsonSemantic(_:decoder:)` 的 decoded payload 都必須符合 `Decodable & Sendable`。
- 僅校正本 topic step ledger，使既有 commit `a7bfc9d`、已推送 feature branch、PR #25 已轉 Ready，以及先前 Reviewer re-review `approved` 都有一致且非 pending 的記錄；另建立本次 remediation 的 planning／implementation／test／review／delivery cycle。

### Out-Of-Scope

- diagrams、Bounded Context boundary、execution policy、error policy、`JSONSemanticDecodingError`、package manifest、production source、tests，以及其他 architecture 文件。
- GitHub thread reply 或 resolution；新的 delivery 在 commit 與 push 後即停止。

### ReadOnly

- 除 `docs/architecture/README.md` 外的所有 architecture docs、diagrams 與 Bounded Context 文件。
- 所有 production source、tests、package manifest，以及本 topic 以外的 artifacts。

### Written

- `docs/architecture/README.md` 的既有 HTTPResponse JSON convenience 說明。
- `plan/swift-http-response-json-sendable-contract/swift-http-response-json-sendable-contract.step.md` 的 ledger correction 與 remediation cycle。

### Deleted

- 無。

### Modify

- 僅限上述 Written targets；不得新增或修改其他檔案。

### TestCase

- 靜態確認 README 同時明示兩個 decoded payload APIs 均要求 `Decodable & Sendable`。
- 靜態確認 ledger 將 `a7bfc9d`、已推送 branch、PR #25 Ready 與先前 Reviewer re-review `approved` 記為完成的歷史事實，並將新的 delivery gate 設為本次獨立 Reviewer `approved` 後才可 commit／push。
- 本次 remediation 不執行 production 或 test source 的 build／test；既有 Swift verification 僅保留為先前 cycle 的歷史 evidence。
