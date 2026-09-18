# HTTP Client Bearer Auth Requester：技術規格

## Locked Decisions

- 本 topic 是 `RivetHTTPClient` package 內的 pure request transformation capability，不是 Bounded Context、authentication flow 或 authenticated request execution path。
- authorization 與 request 發送分離：caller 先 transform，再交由既有 bare `Requester` 發送。
- `Requester`、`HTTPClient`、`Transport` 與 URLSession 的 ownership、API 與 typed-throws surface 均不可改變。
- package 不依賴 GitHub、PAT、OAuth、Keychain、token provider、credential error 或任何 consumer-specific type。
- 使用者已採納 PR #36 全部四則 review thread；本次 remediation 不重開上述 architecture、path 或 contract decision。
- Human 已針對同一檔內 SwiftFormat／SwiftLint `opening_brace` conflict 選擇 narrow file-local policy exception：`SwiftFormat` 擁有 `BearerAuth` 多行 conformance declaration 與下一行 opening brace 的 layout；只允許在該 declaration 正上方放置一個 `// swiftlint:disable:next opening_brace` directive。不得修改全域 `.swiftlint`、其他 file rule 或工具設定。
- branch 建議維持 `feat/http-client-bearer-auth-requester`；此技術規格不授權 branch／Git 操作。

## Selected Review Thread Manifest（固定）

本次 remediation 只處理下列 PR #36 exact thread ID，且 mapping 不可變動：

| Thread ID | 已鎖定 remediation |
| --- | --- |
| `PRRT_kwDOUFu0Cc6jPk81` | delivery ledger 的 phase、status、evidence、blocker 與 Last Updated truthfulness。 |
| `PRRT_kwDOUFu0Cc6jPo1k` | historical delivery deviation：initial pre-commit 被 Swift format issue 與缺少 local Biome 拒絕，後續完成 frozen-lockfile local dependency installation、formatter correction、focused／full tests、full pre-commit 與 independent review；不得將其回填為本輪 approval。 |
| `PRRT_kwDOUFu0Cc6jPo1r` | `docs/architecture/README.md` 的最小已交付 capability truth writeback。 |
| `PRRT_kwDOUFu0Cc6jPo1x` | `BearerAuth` 的 diagnostics／reflection token redaction 與 fake-sentinel regression coverage。 |

CR-07 僅可向這四個 exact ID 回覆實際修改與 fresh verification evidence，然後逐一 resolve；不得回覆或 resolve 任何其他 thread。

## Worktree Delivery Boundary

所有 implementation、verification、commit、non-force push、selected PR reply 與 thread resolution 都必須從 feature worktree 的 `feat/http-client-bearer-auth-requester` branch 執行。dev worktree 不得有任何寫入、修改或 delivery mutation。

## Original Delivered Public API

下列 capability 已在 initial delivery commit `5439798bdb779708dc00c0ad71f97675b85a18b5` 建立；本次不建立或修改其 initializer 或 transformation contract：

```swift
public protocol RequestAuthorization: Sendable {
  func applying(to request: HTTPRequest) -> HTTPRequest
}

public struct BearerAuth: RequestAuthorization {
  public init(token: String)
  public func applying(to request: HTTPRequest) -> HTTPRequest
}
```

- `RequestAuthorization.applying(to:)` 是同步、nonthrowing value transformation；不得標記 `async`、`throws` 或 typed throws。
- `BearerAuth` 可直接被賦予 `any RequestAuthorization` existential；不需 type eraser 或額外 protocol。
- `BearerAuth` 不持有 requester／transport、不呼叫 `execute`、不取得 token、不讀取 response，也不加入 retry、refresh、401 recovery 或 request replay。

## Retained Transformation Semantics

`BearerAuth.applying(to:)` 以輸入 `HTTPRequest` 的 value fields 建立新的 request。它必須：

1. 從輸入 request 複製 URL、method、headers 與 body。
2. 對複本的 `HTTPHeaders` 使用既有 `authorization` setter，設定精確值 `Bearer <token>`。
3. 以更新後 headers 與其餘未變 fields 回傳新的 `HTTPRequest`。

`HTTPHeaders.authorization` 使用既有 lower-case canonical storage，因此 setter 對不同大小寫的既有 Authorization header 執行唯一覆寫。不得以手動字串掃描、重建所有 headers、原地修改輸入 request，或加入第二個 Authorization value 取代既有 setter。

呼叫端的固定組合順序如下；這不是新增 execution abstraction：

```swift
let authorizedRequest = auth.applying(to: request)
let response = try await requester.execute(authorizedRequest)
```

## Selected Review Remediation

### Minimal Architecture Truth Writeback

只修改 `docs/architecture/README.md` 一處，以既有、已交付的事實補充 `RivetHTTPClient`：它提供 caller-applied、pure 的 `RequestAuthorization`／`BearerAuth` request transformation capability。文字必須同時明示：

- bare `Requester → Transport` 保有既有 request execution responsibility；
- capability 不涉及 `AuthFlow`、credential provider、GitHub dependency、retry 或 lifecycle；
- 不修改 architecture diagram、Bounded Context 文件或其他 docs。

此 writeback 只記錄已驗證的 long-term truth，不創造新的 architecture decision。

### Diagnostics and Reflection Redaction

`BearerAuth` 的 existing public initializer 與 `RequestAuthorization` contract 保持不變。為避免意外的 diagnostics／reflection 洩漏，既有 struct 加入最小的 `CustomStringConvertible`、`CustomDebugStringConvertible` 與 `CustomReflectable` conformance：

- `description` 與 `debugDescription` 回傳固定、token-free representation，不洩漏 token、token length 或衍生 token metadata。
- `customMirror` 回傳不含 token child 的 mirror；`Mirror(reflecting:)` 不得列出 stored token。
- conformance 僅改變一般 description、debug description 與 reflection 觀察面；不改變 `applying(to:)` 的 request header outcome、public initializer、storage ownership 或 execution boundary。
- 這是 accidental diagnostics／reflection leak 防護，不宣稱防止 debugger 或 process-memory 存取。

上述三個額外 conformance 令 declaration 採 SwiftFormat 要求的多行 layout，且 opening brace 必須位於下一行。該 layout 唯一觸發的 SwiftLint `opening_brace` conflict 必須只以緊鄰 declaration、正好一個的下列 directive 抑制：

```swift
// swiftlint:disable:next opening_brace
public struct BearerAuth: /* existing and redaction conformances */
{
```

此 directive 是 `BearerAuth.swift` 唯一允許的 `opening_brace` suppression；不使用檔案範圍 disable／enable pair、不抑制其他 rule、不改變全域 SwiftLint configuration，也不改變 SwiftFormat configuration。

`BearerAuthTests` 使用明確 fake token sentinel，驗證 `String(describing:)`、`debugDescription` 與 mirror output／children 不含該 sentinel；不得使用真實 credential，也不得將 sentinel 寫入 log、error payload 或 PR reply。

## Boundary and Secrecy Invariants

- `RequestAuthorization`、`HTTPRequest`、`HTTPHeaders`、`Requester`、`HTTPClient`、`Transport`、URLSession、`Auth` 與 `AuthRequester` 是既有 reference surface，保持 ReadOnly。
- 不使用 `AuthFlow`、`Auth` 或 `AuthRequester`，也不建立 `BearerRequester`、token-source protocol、provider bridge 或 untyped failure surface。
- URL、method、body 與除了 `Authorization` 以外的所有 headers 必須保留；輸入 request 的 value 不變。
- `BearerAuth.applying(to:)` 不會拋錯、發送網路請求、委派 transport，或產生 error wrapping／payload。
- token 只能作為 Authorization field value 的 transformation input。新診斷／reflection conformance 必須以固定 token-free output 防止 accidental exposure，且不得新增 logs、public metadata 或其他可觀察輸出 surface。
- formatting exception 只涵蓋上述一個 declaration 的 `opening_brace` diagnostic；SwiftFormat-required layout 仍是 source layout 的 authority，兩個工具均須在 fresh verification 中通過。

## Remediation Artifact Manifest

### Planning Artifact Corrections

- `analysis/http-client-bearer-auth-requester/requirements.md`
- `analysis/http-client-bearer-auth-requester/technical-spec.md`
- `plan/http-client-bearer-auth-requester/http-client-bearer-auth-requester.plan.md`
- `plan/http-client-bearer-auth-requester/http-client-bearer-auth-requester.step.md`

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/RequestAuthorization.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift`
- 所有 architecture diagram、Bounded Context 文件與未列出的 docs／tracked paths。

### Written

無。`RequestAuthorization.swift`、`BearerAuth.swift` 與 `BearerAuthTests.swift` 是 initial delivery 的既有檔案；本輪不建立新檔。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/BearerAuth.swift`：既有 diagnostics／reflection redaction，以及唯一、緊鄰 `BearerAuth` declaration 的 `// swiftlint:disable:next opening_brace` directive 和 SwiftFormat-required layout。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`
- `docs/architecture/README.md`

### Deleted

無。

## Required Verification

- TC-01：維持不存在 Authorization 時的 Bearer injection，以及 `Authorization`、`authorization`、混合大小寫輸入皆以單一 `Bearer <token>` 值覆寫。
- TC-02：維持 transformation 前後輸入 request 不變，且輸出 request 的 URL、method、body、非 Authorization headers 與原值相同。
- TC-03：將 `BearerAuth` 指派為 `any RequestAuthorization` 並呼叫 `applying(to:)`，驗證結果與 concrete 使用一致。
- TC-04：使用明確 fake token sentinel，驗證 `String(describing:)`、`debugDescription` 與 `Mirror(reflecting:)` 均不含 sentinel；mirror 不得揭露 token storage child。
- TC-05：執行 focused BearerAuth tests、repository root 的 `swift test` 與 `packages/RivetHTTPClient` 內的 `swift test`。兩個 full SwiftPM suite 的實際 command、result 與 evidence 必須分開記錄；兩者尚未在本 planning correction 執行，不得預先宣稱通過。確認既有 bare request execution 無回歸且不自動產生 Authorization header。
- TC-06：執行完整 pre-commit，將實際 command result 作為 evidence；fresh proof 必須明確記錄 SwiftFormat 與 SwiftLint 均通過，並確認 `BearerAuth.swift` 只有一個緊鄰 declaration 的 `opening_brace` suppression。docs verification 固定為 N/A：本次只更新 `docs/architecture/README.md` prose，已確認 repository 沒有適用於 README-only change 的 docs validator；此為 plan 的既定 verification disposition，不由 Tester 決定。

不得新增 token acquisition failure、transport delegation failure、network-side-effect、typed-throws 或 GitHub compatibility 的 Bearer-specific tests。若上述 remediation 無法只在 Modify paths 內完成，停止並回報 Scope Gap；不得修改 ReadOnly surface 或擴張 contract。
