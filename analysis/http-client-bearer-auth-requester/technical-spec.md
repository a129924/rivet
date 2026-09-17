# HTTP Client Bearer Auth Requester：技術規格

## Locked Decisions

- 本 topic 是 `RivetHTTPClient` package 內的 pure request transformation capability，不是 Bounded Context、authentication flow 或 authenticated request execution path。
- authorization 與 request 發送分離：caller 先 transform，再交由既有 bare `Requester` 發送。
- `Requester`、`HTTPClient`、`Transport` 與 URLSession 的 ownership、API 與 typed-throws surface 均不可改變。
- package 不依賴 GitHub、PAT、OAuth、Keychain、token provider、credential error 或任何 consumer-specific type。
- branch 建議維持 `feat/http-client-bearer-auth-requester`；此技術規格不授權 branch／Git 操作。

## Public API Contract

```swift
public protocol RequestAuthorization: Sendable {
  func applying(to request: HTTPRequest) -> HTTPRequest
}

public struct BearerAuth: RequestAuthorization {
  public init(token: String)
  public func applying(to request: HTTPRequest) -> HTTPRequest
}
```

- 兩個 public declaration 均屬 `RivetHTTPClient`。
- `RequestAuthorization.applying(to:)` 是同步、nonthrowing 的 value transformation；不得標記 `async`、`throws` 或 typed throws。
- `BearerAuth` 只持有其初始化傳入的 `String` token 作為 transformation input；不得曝光 token 的 public metadata、diagnostics 或 error payload。
- `BearerAuth` 可直接被賦予 `any RequestAuthorization` existential；不需 type eraser 或額外 protocol。

## Transformation Semantics

`BearerAuth.applying(to:)` 必須以輸入 `HTTPRequest` 的 value fields 建立新的 request。它應：

1. 從輸入 request 複製 URL、method、headers 與 body。
2. 對複本的 `HTTPHeaders` 使用既有 `authorization` setter，設定精確值 `Bearer <token>`。
3. 以該更新過的 headers 與其餘未變 fields 回傳新的 `HTTPRequest`。

`HTTPHeaders.authorization` 已使用 lower-case canonical storage，因此 setter 對不同大小寫的既有 Authorization header 執行唯一覆寫。不得以手動字串掃描、重建所有 headers、原地修改輸入 request，或加入第二個 Authorization value 取代既有 setter。

呼叫端的固定組合順序如下；這不是新增 execution abstraction：

```swift
let authorizedRequest = auth.applying(to: request)
let response = try await requester.execute(authorizedRequest)
```

`BearerAuth` 不持有 requester／transport、不呼叫 `execute`、不取得 token、不讀取 response，也不加入 retry、refresh、401 recovery 或 request replay。

## Boundary and Secrecy Invariants

- `HTTPRequest`、`HTTPHeaders`、`Requester`、`HTTPClient`、`Transport`、URLSession、`Auth` 與 `AuthRequester` 是既有 reference surface，保持 ReadOnly。
- 不使用 `AuthFlow`、`Auth` 或 `AuthRequester`，也不建立 `BearerRequester`、token-source protocol、provider bridge 或 untyped failure surface。
- URL、method、body 與除了 `Authorization` 以外的所有 headers 必須保留；輸入 request 的 value 不變。
- `BearerAuth.applying(to:)` 不會拋錯、發送網路請求、委派 transport，或產生 log、diagnostics、public metadata、error wrapping／payload。
- token 只能作為 Authorization field value 的 transformation input；不得加入任何新可觀察、持久化或輸出 surface。

## Implementation Artifact Manifest

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift`

### Written

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/RequestAuthorization.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/BearerAuth.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`

### Modify

無。

### Deleted

無。

## Required Verification

- TC-01：驗證不存在 Authorization 時的 Bearer injection，以及 `Authorization`、`authorization`、混合大小寫輸入皆以單一 `Bearer <token>` 值覆寫。
- TC-02：驗證 transformation 前後輸入 request 不變，且輸出 request 的 URL、method、body、非 Authorization headers 與原值相同。
- TC-03：將 `BearerAuth` 指派為 `any RequestAuthorization` 並呼叫 `applying(to:)`，驗證結果與 concrete 使用一致。
- TC-04：執行 standalone `RivetHTTPClient` 完整 test suite，確認既有 bare request execution 無回歸且不自動產生 Authorization header。

不得新增 token acquisition failure、transport delegation failure、network-side-effect、typed-throws 或 GitHub compatibility 的 Bearer-specific tests。若上述契約無法只在 Written paths 內完成，停止並回報 Scope Gap；不得修改 ReadOnly surface 或擴張 contract。
