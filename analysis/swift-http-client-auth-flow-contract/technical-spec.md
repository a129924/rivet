# Swift HTTP Client Auth Flow Contract：技術規格

## Locked Public API

```swift
public enum ClientAction: Sendable {
  case send(HTTPRequest)
  case finish
}

public protocol Auth: Sendable {
  func makeFlow(for request: HTTPRequest) -> any AuthFlow
}

public protocol AuthFlow: Sendable {
  mutating func start() async -> ClientAction
  mutating func receive(_ response: HTTPResponse) async -> ClientAction
}
```

## Contract Semantics

- `ClientAction.send` 承載既有 `HTTPRequest`；`finish` 表示 state machine 的 terminal action。
- `Auth.makeFlow(for:)` 同步接收 request，回傳 existential `any AuthFlow`。
- `AuthFlow` 是單純、non-throwing async state machine。`start()` 與 `receive(_:)` 是其唯一宣告的 transitions，且必須維持 `mutating async -> ClientAction` signature。
- `.finish` 沒有 payload，表示 terminal action；其後續處理不屬於本 contract。
- package 不呼叫任何 auth-flow method，亦不提供 default implementation、concrete implementation、runtime 或 flow driver。上述語意源自 2026-09-11 human decision。

## Boundaries

- 不改動既有 HTTP client、request／response value types、transport chain、typed error contract 或 manifest。
- 不新增 static authorization header application、request replay、retry、refresh、challenge、401 handling 或 status policy。
- 不提供 concrete auth、credential、token、GitHub 或 persistence behavior。
- `RivetHTTPClient` 擁有 generic declarations-only flow contract；public declarations 不移至 GitHub Integration。
- GitHub Integration 僅保留 GitHub-specific lower authorization policy／capability；其 implementation 與既有 topic read-only。
- implementation 完成時，最小更新既有 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/README.md`；不修改 `docs/architecture/bounded-contexts/github-integration.md`、其他 BC、architecture baseline 或既有 GitHub Integration topic。
- implementation 完成時，新增 `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json` 與生成的 `auth-flow-lifecycle.html`。lifecycle 僅表達宣告的 transitions：`Auth` 建 flow → `start()` 回傳 `.send`／`.finish` → `receive(response)` 回傳 `.send`／`.finish`；必須明示 `HTTPClient` 不 drive flow。

## Required Verification

- 在 `RivetHTTPClientTests` 宣告 concrete `Auth` 與 `AuthFlow` conformers。
- `makeFlow(for:)` 的結果可保存為 `var flow: any AuthFlow`。
- test 可 `await flow.start()` 與 `await flow.receive(_:)`。
- test 對 `.send(let request)` 與 `.finish` pattern match，並驗證 `.send` 保留輸入 `HTTPRequest`。
- 不驗證 HTTP execution、header mutation、retry、refresh、credential 或 GitHub behavior。
- architecture writeback 僅如實記錄 generic contract ownership 與 GitHub-specific lower policy／capability boundary。
- lifecycle JSON 的 authored labels 與 explanatory copy 使用繁體中文；以 `lifecycle` 類型執行 Archify `validate`（`--quality showcase --json`），其 receipt 必須顯示完整 9/9 artifact checks、0 errors、0 warnings。
- 僅在該 validate pass 後執行 `deliver`（`--quality showcase --json`）；deliver 會 freeze exact JSON／HTML。delivery 後不得修改 JSON 或 HTML 再引用舊 receipt；任何 JSON correction 必須重新 validate、deliver，然後重新蒐集 evidence。
- 對 exact delivered HTML 執行 `visual-check`，保存 artifact-local receipt／screenshots；receipt 的 `visualReview: pending` 僅表示自動 capture／containment evidence，不能取代人工 visual review。
- 人工 visual review 必須檢閱 exact delivered HTML 與 screenshots；ledger 記錄 `passed`、`skipped` 或 `failed`，並記錄 correction rounds。`failed` 時僅修正診斷到的 JSON，依前述流程重新驗證與交付。
