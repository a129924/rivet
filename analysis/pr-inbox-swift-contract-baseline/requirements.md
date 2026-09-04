# PR Inbox Swift Contract Baseline：需求

## Goal

在 root SwiftPM package 建立 `RivetPRInbox` library product／target，使用既有 `Sources/BoundedContexts/PRInbox/` source path，提供 PR Inbox 自有的 Core contract、refresh-only Facade 與可測試的 semantic fake 基線。

已交付 baseline 的最小 amendment：保留專案用語 `Outcome`，但改以 Swift 標準庫 `Result` 的 target-local typealias 表達 success／failure；不再維護重複的 custom enum。

## Non-Goal

不建立 GitHub Integration Adapter、HTTP client dependency、外部 query、DTO、真實網路、UI、PR Reader、Presentation Session、cache 或 sync。

## In-Scope

- root `RivetPRInbox` library product、source target 與 test target。
- target-local `Outcome`、`InboxItem`、`ReviewRequestCandidate`、`PRInboxFailure`、`ReviewRequestSource`、internal refresh use case 與 `PRInboxFacade`。
- semantic fake source 與 Swift Testing。
- PR Inbox BC 文件對本 target 與 Core contract 邊界的長期事實回寫。
- amendment 僅限 `Outcome.swift` 改為 `Result` typealias，以及直接證明 alias／public API 語意所需的既有 PR Inbox tests。
- 已選取 PR review comment 的最小 amendment：只為 `ReviewRequestCandidate` 加入一個 public memberwise initializer，並調整受影響 contract／static-isolation tests；不改變任何既有 Outcome、membership 或 refresh 行為。

## Out-Of-Scope

- `RivetHTTPClient` 或任何外部 package dependency。
- GitHub search query、pagination、incomplete-result policy、HTTP/auth/rate-limit、`InfraUnknownError`、GitHub DTO 與 failure mapping。
- 排序、snapshot/current state、cache、sync、跨 BC contract、Git、release、PR 或 artifact 發布。
- shared Core target、跨 BC 搬移 `Outcome` 或 Failure、任何新 dependency、以及 GitHub Integration／`RivetHTTPClient`／其他 BC／全域 architecture／lint 或 format 規則修改。
- 其他 public API、failure case、production behavior 或測試語意的變更。

## Success Criteria

- refresh 只回傳 open 且明確直接要求目前使用者 review 的 Inbox item；空集合是成功結果。
- failure 僅以 PR Inbox 自有 `.unavailable` 表達並原樣傳遞。
- `Outcome<Success, Failure>` 是 `RivetPRInbox` target-local 的 `Result<Success, Failure>` typealias；`Success: Sendable` 與 `Failure: Error & Sendable` 仍受約束，呼叫端持續使用 `.success(...)` 與 `.failure(...)`。
- 每個 BC 仍自行擁有 Failure contract；本 amendment 不建立 shared Core target。
- target、source import 與 manifest 均不依賴 HTTP client 或外部 integration。
- 四份同 slug artifacts 可完整描述本次受限實作、驗收與 human boundary。

## Amendment Status

- 獨立 Plan-Reviewer 已對 PR-02 明示 `approved`；Implementer 隨後只修改
  `Sources/BoundedContexts/PRInbox/Outcome.swift` 與
  `Tests/RivetPRInboxTests/ContractTests.swift`。
- Tester 已對 TC-01 至 TC-10 與指定 command 明示 `approved`。
- RV-02 的獨立 code review 結果為 `needs-rework`：planning contract 仍保留舊的
  custom `Outcome` enum declaration，且 ledger 尚未如實記錄已收到的 verdict。
  PC-03 已只修正這些 planning artifacts；不改變已鎖定的 source、test 或 public
  contract。
- 獨立 Plan-Reviewer 已對 PR-03 明示 `approved`。RV-03 曾被指定為下一個 review gate，
  但未記錄任何 verdict、delivery 或 review-thread resolution 結果；它已由本次 human-authorized
  PR comment amendment 取代，僅保留為 historical／superseded 紀錄，不再是 current gate。
- selected PR review threads 1–4 的 Comment-Reviewer verdict 為 `needs-rework`：
  `ReviewRequestCandidate` 缺少可供 client 使用的 public initializer；contract test 應以
  普通 `import RivetPRInbox` 驗證該 initializer；static-isolation test 應遞迴列舉僅限
  PRInbox target 的 `.swift` source，並保留既有 banned import／network token checks。
  此輸入不重開既有 contract；PC-04 只更新 artifacts。PR-04 已由獨立 Plan-Reviewer 明示
  `approved`；IM-03 已在下列三個 locked paths 完成 selected review fixes；TE-03 已對六個
  指定 validation commands 與 8 個 tests 明示 `approved`。RV-04 是唯一 current pending gate：
  `Sources/BoundedContexts/PRInbox/ReviewRequestCandidate.swift`、
  `Tests/RivetPRInboxTests/ContractTests.swift`、
  `Tests/RivetPRInboxTests/StaticIsolationTests.swift`。不得修改其他 source 或 test path。
