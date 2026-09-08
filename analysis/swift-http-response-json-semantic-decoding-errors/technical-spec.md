# Swift HTTP Response JSON Semantic Decoding Errors：技術規格

## Locked Public API

`HTTPResponse` 新增：

```swift
public func jsonSemantic<T: Decodable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T
```

獨立 source file 定義：

```swift
public struct JSONSemanticDecodingError: Error {
  public enum Kind {
    case dataCorrupted
    case keyNotFound
    case typeMismatch
    case valueNotFound
    case other
  }

  public let kind: Kind
  public let underlyingError: any Error
}
```

`JSONSemanticDecodingError` initializer 維持 internal；不提供其他 public protocol conformance、serialization、localized description 或 end-user wording contract。

## Behavior and Error Contract

- `jsonSemantic` 只執行 `decoder.decode(type, from: body)`；不讀取或驗證 response metadata。
- 成功時直接回傳 decoded value。
- `DecodingError.dataCorrupted`、`keyNotFound`、`typeMismatch`、`valueNotFound` 分別對應同名 `Kind`。
- 未知 `DecodingError` case 與任何非 `DecodingError` 都對應 `.other`。
- wrapper 必須完整保存 caught error 作為 `underlyingError`；不得複製或公開 decoding context、coding path、debug description、target type 或 key。
- 既有 `json(_:decoder:)` 不得修改，且繼續直接傳遞 caller decoder 的原始錯誤。

## Architecture and Writeback

- `HTTPResponse` 維持 canonical raw `Data` response；兩個 JSON convenience 都是 caller-invoked helper，不改變 raw response dataflow。
- package 不擁有 decoder configuration、HTTP metadata validation 或通用 response decode policy；semantic wrapper 僅是此明確 opt-in API 的 decode-failure classification。
- 僅更新 architecture README 與 GitHub Integration BC 文件；不修改 diagrams。

## Required Verification

- 成功解碼、caller decoder configuration、四個 decoding kind、custom non-decoding error 與 underlying error retention。
- 原始 `json(_:decoder:)` 的 `DecodingError` passthrough，以及 raw body、status、headers regression。
- standalone `RivetHTTPClient` package build 與完整 test suite。
