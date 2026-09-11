# Swift HTTP Client Auth Flow Contract

## Summary

在 `RivetHTTPClient` 新增 declarations-only、non-throwing async auth-flow public contracts：`ClientAction`、`Auth`、`AuthFlow`。這是 future wrapper 的型別邊界；本 topic 以最小 long-term docs 與 lifecycle artifact 澄清其 generic ownership，既有 HTTP client execution 不變。

## Implementation Changes

- 新增 `ClientAction: Sendable`，精確宣告 `.send(HTTPRequest)` 與 `.finish`。
- 新增 `Auth: Sendable`，精確宣告 `makeFlow(for:) -> any AuthFlow`。
- 新增 `AuthFlow: Sendable`，精確宣告 `mutating async start()` 與 `receive(_:)`。
- 在 package external test target 以 concrete conformers 驗證 compile contract。
- 不建立 runtime 或任何 auth behavior，且不變更既有 HTTP execution path。
- 最小回寫既有 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/README.md`：generic declarations-only flow contract 屬 `RivetHTTPClient`；GitHub-specific policy 不獲得本 topic implementation。
- 新增繁體中文 Archify lifecycle artifact，明確呈現四種 declared outcomes：`start() → .send`、`start() → .finish`、`receive(response) → .send`、`receive(response) → .finish`，並明示 `HTTPClient` 不 drive flow。

## Swift Implementation Handoff

### Goal

宣告可供 future wrapper 使用的 public、`Sendable`、non-throwing async auth-flow contracts，並如實回寫其 generic ownership 與 declarations-only lifecycle；不執行 flow。

### Non-Goal

authentication runtime、HTTP client integration、flow driver、request execution、response routing、static header auth、concrete auth、credential/token lifecycle、GitHub behavior，或 `.finish` 的 client runtime handling。

### In-Scope

- `ClientAction` 的 `.send(HTTPRequest)` 與 `.finish`。
- `Auth.makeFlow(for:) -> any AuthFlow`。
- `AuthFlow` 的 non-throwing `mutating async start()` 與 `receive(_:)`。
- external test-target conformers 與 compile-contract tests。
- 對既有 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/README.md` 的最小 ownership writeback。
- Archify lifecycle JSON、generated HTML 與 artifact-local visual-check evidence。

### Out-Of-Scope

- `HTTPClient`、`Requester`、`Transport`、`HTTPRequest`、`HTTPHeaders`、`HTTPResponse`、`HTTPClientError` 或 manifest 的修改。
- retry、refresh、challenge、401 policy、request replay、`AuthRuntime`、NoAuth、Bearer、Basic、Digest、OAuth、credential、token、parser、persistence。
- GitHub Integration implementation、`docs/architecture/bounded-contexts/github-integration.md` 或其既有 topic 的變更；public declarations 不移至 GitHub Integration。
- 除列明 writeback 與 lifecycle artifact 外的其他 architecture／BC docs、diagram 或 canvas 變更。

### Modify

- `docs/architecture/README.md`：如實記錄 `RivetHTTPClient` generic declarations-only flow contract；不宣稱 client drives flow。
- `docs/architecture/bounded-contexts/README.md`：以 directory-level boundary 如實澄清 generic declarations 不屬於 GitHub-specific policy capability。

### Written

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`：新增 locked public declarations。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/AuthTests.swift`：新增 external conformer 與 compile-contract tests。
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.json`：繁體中文 authored Archify lifecycle source。
- `docs/architecture/diagrams/http-client-auth-flow-contract/auth-flow-lifecycle.html`：由 Archify deliver 生成的 lifecycle artifact。
- artifact-local `auth-flow-lifecycle.visual-check.*` receipt、screenshots 與 contact sheet：visual-check evidence。
- 除上述新檔外，不新增 runtime 或其他 documentation／architecture artifact。

### ReadOnly

- `HTTPClient`、`Requester`、`Transport`、`HTTPRequest`、`HTTPHeaders`、`HTTPResponse`、`HTTPClientError`、manifest、GitHub Integration implementation、`docs/architecture/bounded-contexts/github-integration.md` 及其既有 topic、其他 architecture docs、BC docs、canvas 與 GitHub source。

### Deleted

- 無。不得刪除、搬移或更名既有 API、source、test 或 artifact。

### TestCase

- concrete `Auth` conformer 回傳 concrete `AuthFlow` 作為 `any AuthFlow`。
- `var flow: any AuthFlow` 可依序 `await start()` 與 `await receive(_:)`。
- `.send(let request)` 與 `.finish` 可 exhaustive pattern match，且 `.send` 保留輸入 `HTTPRequest`。
- `.finish` 僅驗證為 payload-less terminal action；不加入 client runtime handling assertion。
- lifecycle artifact 以繁體中文呈現四種 declared transitions：`start() → .send`、`start() → .finish`、`receive(response) → .send`、`receive(response) → .finish`，以及 client-not-driver boundary；showcase validate 必須為 9/9 artifact checks、0 errors、0 warnings，然後 deliver 與 visual-check。
- exact delivered HTML 必須完成人工 visual review；ledger 記錄 `passed`、`skipped` 或 `failed` 與 correction rounds。`visualReview: pending` 自動 receipt 不構成人工 acceptance。
- 不新增 HTTP execution、header mutation、retry、refresh、challenge、credential、token、parser、persistence 或 GitHub assertions。

## Test Plan

- original test-first evidence 永久不可驗證；既有事後 declarations 移除／復原 replay 不證明原始工作曾 test-first，且不得作為 TDD proof。
- Human 已接受此不可驗證限制不再阻擋本 topic 交付。若未來另有 implementation cycle，其 test-first evidence 必須獨立建立；本 topic 不以歷史 replay 補造 proof，亦不以重建 red → green evidence 作為當前交付 gate。
- lifecycle artifact 依序執行 showcase validate（9/9、0 errors、0 warnings）、deliver、visual-check 與人工 visual review；deliver 後 freeze exact JSON／HTML，不得修改後引用舊 receipt。JSON correction 必須重新 validate、deliver，再蒐集 visual-check／人工 review evidence。

## Assumptions

- future wrapper 自行決定如何使用 state transitions；本 topic 不預先定義 runtime。
- 若需要任何 HTTPClient integration、auth implementation 或 GitHub behavior，停止並以新 topic 規劃。
- `.finish` 的 payload-less terminal semantics 源自 2026-09-11 human decision；不擴張為 client runtime policy。
