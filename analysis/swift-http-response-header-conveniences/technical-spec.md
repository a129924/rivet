# Swift HTTP Response and Header Conveniences：技術規格

## Locked API Contract

新增 package-owned public namespace：

```swift
public enum HTTPHeaderName {
  public static let accept = "accept"
  public static let authorization = "authorization"
  public static let contentType = "content-type"
  public static let userAgent = "user-agent"
  public static let etag = "etag"
  public static let ifNoneMatch = "if-none-match"
  public static let location = "location"
  public static let link = "link"
  public static let retryAfter = "retry-after"
}
```

`HTTPHeaders` 新增：

```swift
public var accept: String? { get }
public var authorization: String? { get }
public var contentType: String? { get }
public var userAgent: String? { get }
public var etag: String? { get }
public var ifNoneMatch: String? { get }
public var location: String? { get }
public var link: String? { get }
public var retryAfter: String? { get }

public func value(for name: String) -> String?
```

此 lookup 必須使用既有 `lowercased()` canonicalization 後查詢 `values`；它不限制 name 為 `HTTPHeaderName` 常數，因此 custom header 照常支援。

九個 property 都是 read-only computed property，且各自只以對應的 `HTTPHeaderName` lower-case constant 呼叫 `value(for:)`。它們不直接讀取 storage，亦不新增 setter、subscript setter、`mutating` API、builder API 或 dynamic-member lookup。

`HTTPResponse` 新增：

```swift
public func text(
  encoding: String.Encoding = .utf8
) -> String?
```

它以 `String(data: body, encoding: encoding)` 的等價行為解碼 `body`；無法解碼時回傳 `nil`。

## Invariants and Boundaries

- `HTTPHeaderName` 只有九個指定的 public lower-case `String` constants；不納入 GitHub-specific header。
- `HTTPHeaders.values` 仍是 public `[String: String]`，其 immutable storage、lower-case storage、dictionary literal／initializer 的 duplicate later-wins 規則與 custom header support 均不變；本 topic 不將它改為多值模型。九個點語法 getter 不可改變 `values` 或上述行為。
- `HTTPResponse` 維持 `statusCode`、`headers` 與 raw `body: Data` 的既有 initializer 與 canonical contract。`text(encoding:)` 是 opt-in convenience，不讀取 `Content-Type`，不推論 charset，亦不執行 JSON decode。
- 不改變 `HTTPClient → Requester → Transport` chain、URL ownership、transport error passthrough、status validation 或 retry policy。
- 不新增 error type、decoder、concrete transport、URLSession、manifest dependency、Bounded Context 文件或 architecture diagram 變更。

## Required Verification

- 驗證九個 `HTTPHeaderName` constants 的精確 lower-case wire names。
- 驗證標準 name 的不同大小寫與對應 `HTTPHeaderName` constant 取得同一 stored value，且任意 custom header 同樣可讀取。
- 驗證九個點語法 property 各自以對應 `HTTPHeaderName` constant 經 `value(for:)` 取得值，且混合大小寫輸入的點語法讀取相同。
- 驗證既有 duplicate later-wins、canonical `values`、immutable behavior 與 raw response regression 不變。
- 驗證 UTF-8 成功解碼、顯式指定非預設 encoding 的成功解碼，以及不相容 bytes 回傳 `nil`。
