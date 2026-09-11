# Swift HTTP Response JSON Sendable Contract：技術規格

## Historical Delivered Public API Contract

`HTTPResponse` 的兩個 public synchronous throwing JSON APIs 為下列 source-breaking signatures：

```swift
public func json<T: Decodable & Sendable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T

public func jsonSemantic<T: Decodable & Sendable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T
```

兩者維持既有 body decode 行為與 caller-supplied `JSONDecoder` ownership；唯一 production contract 變更是 `T` 新增 `Sendable` 約束。

## Historical Delivered Boundaries

- 不修改 `JSONSemanticDecodingError`、其 `Kind`、`underlyingError` 或 error handling。
- 不修改 raw `HTTPResponse` properties、HTTP execution chain、decoder ownership、HTTP status／headers／`Content-Type` metadata policy 或 package manifest。
- 不修改 architecture docs、diagrams 或既有 locked topics。
- test 僅更新直接傳給 `json` 或 `jsonSemantic` 作為 decoded payload 的 local fixture conformance；不改變 test scenario 或 error fixture contract。

## Historical Delivered Verification

- 保留 `json` 與 `jsonSemantic` 的 success 與 configured decoder coverage。
- 保留 raw `DecodingError` passthrough、semantic error mapping 與 `underlyingError` retention coverage。
- 保留 metadata non-validation 與 raw response regression coverage。
- 在 `RivetHTTPClient` standalone package 執行 `swift build` 與 `swift test`。

## Post-Delivery PR Remediation Specification

### Goal

在唯一授權的長期真相 target 補上已交付 payload contract，並令 step ledger 對已完成 delivery 與 reviewer handoff 可追溯且一致。

### Non-Goal

- 不重新決定或變更 Swift public API、execution policy、error policy 或任何 Bounded Context boundary。
- 不以本次 remediation 取代既有 implementation、test 或 review evidence。

### In-Scope

- 在 `docs/architecture/README.md` 的既有 HTTPResponse JSON convenience 敘述加入：`json(_:decoder:)` 與 `jsonSemantic(_:decoder:)` 的 decoded payload public contract 均為 `Decodable & Sendable`。
- 在本 topic step ledger 追加新的 remediation cycle，並將既有 delivery record 校正為：commit `a7bfc9d` 已建立、feature branch 已推送、PR #25 已轉 Ready、先前 Reviewer re-review verdict 為 `approved`。

### Out-Of-Scope

- diagrams、其他 architecture docs、Bounded Context 文件、production source、tests、package manifest、`JSONSemanticDecodingError`、execution chain 與 error handling。
- GitHub comment reply、thread resolution、merge、release 或其他 PR 操作；新的 delivery 僅授權 commit 與 push。

### ReadOnly

- 除 `docs/architecture/README.md` 外的 repository docs、diagrams、Bounded Context 文件、source、tests、manifest 與非本 topic artifacts。

### Written

- `docs/architecture/README.md` 的既有 HTTPResponse JSON convenience 說明。
- 本 topic step ledger 的 correction 與 remediation cycle。

### Deleted

- 無。

### Modify

- 僅修改上述 Written targets；README 僅補充兩個 decoded payload 的 `Decodable & Sendable` contract，ledger 僅補正既有事實並新增 remediation cycle。

### TestCase

- 確認 README 說明同時涵蓋 `json(_:decoder:)` 與 `jsonSemantic(_:decoder:)`，且不加入 execution、error 或 metadata policy 變更。
- 確認 ledger 保留既有 cycle evidence、將既有 delivery／re-review 事實標為完成，並使新的 delivery 依賴本次獨立 Reviewer `approved` 後才可 commit／push，且停在 GitHub reply／resolution 前。
- 本次 remediation 不需重新執行 Swift build 或 test；先前 package checks 為歷史 evidence，非本 cycle 的 gate。
