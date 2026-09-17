# HTTP Client Bearer Auth Requester

## Summary

在 `RivetHTTPClient` 新增 GitHub-free、同步、純 value transformation 的 Bearer authorization capability。caller 先套用 `BearerAuth`，再將回傳的 `HTTPRequest` 交給既有 bare `Requester`；既有 `HTTPClient → Requester → Transport` pipeline、typed-throws contract 與 URLSession responsibility 均不變。

建議 Git branch 名稱：`feat/http-client-bearer-auth-requester`。僅為命名建議；本 plan 不授權建立、切換或推送 branch。

## Swift Implementation Handoff

### Goal

在不更動既有 request execution surface 的前提下，提供 GitHub-free 的 Bearer request transformation，讓 caller 可在交由 bare `Requester` 發送前套用 authorization。

### Non-Goal

- 不建立 authenticated requester、authentication flow 或 credential lifecycle。
- 不使用或修改 `AuthFlow`、既有 `Auth` protocol、`AuthRequester`、`Requester`、`HTTPClient`、`Transport` 或 URLSession。
- 不處理 token acquisition、token provider／source、provider bridge、OAuth、PAT、Keychain、refresh、401 recovery、retry 或 request replay。
- 不引入 `BearerRequester`、GitHub 型別、`GitHubAccessTokenProvider`、`GitHubCredentialError`、untyped throws、endpoint、DTO、BC failure mapping、其他 authentication scheme、logs、diagnostics、public metadata 或 error payload。
- 不修改 package manifest、architecture／BC docs 或 diagrams；無預設 documentation writeback。

### In-Scope

- 新增下列 public request-transformation contract：

  ```swift
  public protocol RequestAuthorization: Sendable {
    func applying(to request: HTTPRequest) -> HTTPRequest
  }

  public struct BearerAuth: RequestAuthorization {
    public init(token: String)
    public func applying(to request: HTTPRequest) -> HTTPRequest
  }
  ```

- `BearerAuth` 只複製輸入 `HTTPRequest`，透過既有大小寫不敏感的 `HTTPHeaders.authorization` setter 設定 `Bearer <token>`；保留 URL、method、body 與其餘 headers，且不可原地修改原 request。
- caller 顯式執行 `auth.applying(to: request)`，再將結果交給既有 `requester.execute(...)`。`BearerAuth` 不取得 token、拋錯、委派 request 或發送網路請求。
- 新增新的 Bearer transformation test file，並以現有完整 package suite 驗證 bare execution regression。

### Out-Of-Scope

- Bearer-specific token acquisition failure、transport delegation failure、network side effect、response handling與 typed-throws tests。
- 對 ReadOnly paths 的任何修正、`Auth`／`AuthFlow` adaptation、GitHub client composition 或 token-provider compatibility。
- 未列在 Written allowlist 的任何 source、test、manifest、target、adapter、documentation 或 diagram artifact。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift`

這些是 existing reference／regression verification surface；禁止寫入。所有未列於 Written 的 tracked paths 同樣為 ReadOnly 與 Out-Of-Scope。

### Written

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/RequestAuthorization.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/BearerAuth.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`

### Modify

無。

### Deleted

無。

### TestCase

- TC-01：`BearerAuth` 注入 `Authorization: Bearer <token>`，並覆寫 `Authorization`、`authorization` 或混合大小寫的既有 header。
- TC-02：`applying(to:)` 不改變輸入 request；輸出 request 保留原 URL、method、body 與非 Authorization headers。
- TC-03：`any RequestAuthorization` existential 使用 `BearerAuth` 時，產生與 concrete 呼叫相同的 request transformation。
- TC-04：執行既有完整 `RivetHTTPClient` test suite，確認 bare request execution 無回歸且不自動加入 Authorization header。

## Implementation Sequence

1. 在 `RequestAuthorization.swift` 宣告唯一的 public protocol，不加入 type erasure、throwing／async surface 或 GitHub dependency。
2. 在 `BearerAuth.swift` 以 private token storage 實作指定 initializer 與 nonthrowing transformation；以 `HTTPRequest`／`HTTPHeaders` 的 value semantics 建立複本，再用 `headers.authorization` 覆寫唯一 Authorization field。
3. 在 `BearerAuthTests.swift` 實作 TC-01 至 TC-03；不得新增 network、token-provider、failure 或 execution-delegation test doubles。
4. 執行 TC-04 的完整 standalone package suite。驗證 diff 只含 Written paths；任一 ReadOnly／scope drift、token observability surface、或需變更 typed-throws contract 時，停止並回報 Scope Gap。

## Acceptance

- public API 與 nonthrowing signature 精確符合本 plan；`RequestAuthorization` 與 `BearerAuth` 皆為 `Sendable`。
- Authorization replacement 使用既有 setter 的 case-insensitive storage semantics，且輸入／輸出 request values 符合 TC-01、TC-02。
- 發送仍由 caller 對 existing bare `Requester.execute(...)` 的呼叫負責；`BearerAuth` 沒有 execution、response 或 failure surface。
- implementation 與 tests 僅出現在 Written paths，沒有 token 新增至 logs、diagnostics、public metadata 或 error payload。
- 只有在 Plan-Reviewer 明示 `approved` 後，Implementer 可實作；完成後必須先交獨立 Tester、再交獨立 Reviewer。Reviewer 明示 `approved` 且無重大問題後，Implementer 才可依既有 human authorization 依序 commit、push、開 draft PR，並停止於 human review boundary。

## Assumptions

- `HTTPRequest` 是 value type，且可用其 public initializer 建立含更新 headers 的新值。
- `HTTPHeaders.authorization` setter 以既有 lower-case canonical storage 唯一覆寫 Authorization，並保留其他 headers。
- 本 topic 不預設需要 architecture writeback 或圖；若實作後發現需改長期 truth，先交還 human，不自行擴張。
