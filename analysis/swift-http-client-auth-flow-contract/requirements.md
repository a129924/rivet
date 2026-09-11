# Swift HTTP Client Auth Flow Contract：需求

## Goal

在 generic `RivetHTTPClient` 宣告可供未來 wrapper 使用的 public auth-flow contracts：`ClientAction`、`Auth` 與 `AuthFlow`，並以最小長期文件與 lifecycle artifact 記錄其 ownership 與 declarations-only transitions。package 不執行或解讀 flow。

## Decision Source

2026-09-11 human decision 鎖定下列語意：`AuthFlow` 是 non-throwing async state machine；payload-less `.finish` 表示 flow terminal action，且不承諾任何 client runtime handling。

## In Scope

- public `ClientAction: Sendable`，僅有 `.send(HTTPRequest)` 與 `.finish`。
- public `Auth: Sendable`，由既有 `HTTPRequest` 建立 `any AuthFlow`。
- public `AuthFlow: Sendable`，提供 non-throwing、`mutating async` 的 `start()` 與 `receive(_:)` state transitions。
- package external test target 的 concrete conformers，驗證 public conformance、existential return、action pattern matching 與 async transition signature。
- 最小 architecture writeback：在既有 architecture overview 與 BC directory README 澄清 `RivetHTTPClient` 擁有 generic declarations-only flow contract；GitHub-specific policy 不獲得本 topic implementation。
- 一份以繁體中文撰寫的 Archify lifecycle artifact，表達 `Auth` 建 flow、`start()`／`receive(_:)` 回傳 `.send` 或 `.finish`，並明示 client 不 drive flow。

## Out of Scope

- concrete auth、token／credential provider、parser、persistence、NoAuth、Bearer、Basic、Digest、OAuth。
- flow driver、runtime、request dispatch、response routing、HTTP request execution。
- `HTTPClient`、`Requester`、`Transport`、`HTTPRequest`、`HTTPHeaders`、`HTTPResponse`、`HTTPClientError`、manifest 的任何變更。
- static header auth、retry、refresh、challenge、401 policy、GitHub behavior。
- GitHub Integration implementation 或其既有 topic 的變更；不移動 public declarations 至 GitHub Integration。
- 任何其他 architecture redesign、runtime semantics、diagram，或未列入本 topic 的文件 writeback。

## Success Criteria

- external target 可宣告符合 `Auth` 與 `AuthFlow` 的 concrete types。
- `Auth.makeFlow(for:)` 可回傳 `any AuthFlow`。
- `await start()` 與 `await receive(_:)` 可用於 mutable existential flow。
- `.send(HTTPRequest)` 與 `.finish` 可 exhaustive pattern match。
- 既有 HTTP execution behavior 不變。
- 長期文件正確區分 generic flow contract 與 GitHub-specific lower authorization policy／capability。
- lifecycle artifact 的 showcase validate 必須是完整 9/9 artifact checks、0 errors、0 warnings；deliver 後 freeze exact JSON／HTML，修正 JSON 必須重新 validate、deliver，再蒐集 evidence。
- lifecycle artifact 通過 Archify visual-check 後，仍須對 delivered HTML 進行人工 visual review；ledger 記錄 `passed`、`skipped` 或 `failed` 與 correction rounds。`visualReview: pending` receipt 不構成人工 acceptance。
- 作者內容為繁體中文，且不宣稱 client runtime。
