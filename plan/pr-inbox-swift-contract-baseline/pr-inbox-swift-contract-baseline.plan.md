# PR Inbox Swift Contract Baseline

## Goal

建立 root SwiftPM `RivetPRInbox` library product／target，於既有 `Sources/BoundedContexts/PRInbox/` 實作 PR Inbox-owned Core contract、refresh-only Facade 與 semantic fake 測試。

已交付 baseline 的最小 amendment 是將 target-local custom `Outcome` enum 改為標準庫 `Result` typealias，同時保留 public contract 的專案用語與所有既有 refresh 語意。

## Non-Goal

不建立 GitHub Integration Adapter、HTTP dependency、外部 query／DTO／network、UI、PR Reader、Presentation Session、cache、sync、排序、Git 或 release 動作。

## In-Scope

- target-local `Outcome`、Inbox identity、semantic candidate、failure、Port、internal membership filter 與 refresh Facade。
- root manifest 的 product／source target／test target。
- semantic fake 與 Swift Testing；PR Inbox BC 文件的 target／contract truth writeback。
- amendment 僅限 `Outcome.swift` 與直接證明 alias／public API 語意所需的既有 PR Inbox tests。

## Out-Of-Scope

- GitHub search query、pagination、incomplete-result policy、HTTP/auth/rate-limit、`InfraUnknownError`、GitHub DTO 與 adapter failure mapping。
- `RivetHTTPClient` 或其他 package dependency、跨 BC contract、current/snapshot state、cache 及同步。
- shared Core target、跨 BC type move、新 dependency、GitHub Integration／其他 BC／全域 architecture 與 lint／format rules。

## ReadOnly

- `docs/github-api/`、`packages/RivetHTTPClient/`、GitHub Integration BC 文件。
- 其他 BC source、既有 bounded-context source-layout 與 HTTP client artifacts、全域 architecture 文件。

## Written

- `analysis/pr-inbox-swift-contract-baseline/requirements.md`
- `analysis/pr-inbox-swift-contract-baseline/technical-spec.md`
- `plan/pr-inbox-swift-contract-baseline/pr-inbox-swift-contract-baseline.plan.md`
- `plan/pr-inbox-swift-contract-baseline/pr-inbox-swift-contract-baseline.step.md`
- `Sources/BoundedContexts/PRInbox/` 下的 target-local Outcome、model、failure、Port、internal refresh use case 與 Facade source。
- `Tests/RivetPRInboxTests/` 下的 Facade／membership tests 與 semantic fake source。

## Deleted

- `Sources/BoundedContexts/PRInbox/.gitkeep`，僅在 target 有實際 source 時移除；不刪除其他檔案。

## Modify

- root `Package.swift`：新增 `RivetPRInbox` library product、source target（使用既有 PRInbox path）與 `RivetPRInboxTests`。
- `docs/architecture/bounded-contexts/pr-inbox.md`：記錄已存在的 root target、Core contract 邊界與尚未實作外部 Adapter 的事實。

## Public API／Interface

```swift
public typealias Outcome<Success: Sendable, Failure: Error & Sendable> = Result<Success, Failure>

public struct InboxItem: Equatable, Sendable {
  public let owner: String
  public let repository: String
  public let number: Int
  public let title: String

  public init(owner: String, repository: String, number: Int, title: String)
}

public struct ReviewRequestCandidate: Equatable, Sendable {
  public let item: InboxItem
  public let isOpen: Bool
  public let isDirectlyRequestedForCurrentUser: Bool

  public init(
    item: InboxItem,
    isOpen: Bool,
    isDirectlyRequestedForCurrentUser: Bool
  )
}

public enum PRInboxFailure: Error, Equatable, Sendable {
  case unavailable
}

public protocol ReviewRequestSource: Sendable {
  func fetchReviewRequestCandidates() async
    -> Outcome<[ReviewRequestCandidate], PRInboxFailure>
}

public struct PRInboxFacade: Sendable {
  public init(source: any ReviewRequestSource)
  public func refresh() async -> Outcome<[InboxItem], PRInboxFailure>
}
```

`Outcome` 僅屬於 `RivetPRInbox` target，並以 Swift 6 標準庫 `Result` 的 typealias
表達 success／failure；不再維護 custom enum。refresh 只保留 open 且直接要求目前
使用者 review 的 candidate，維持來源順序；空集合為成功，failure 原樣傳遞，且不公開
current／snapshot／cache state。

`PRInboxFailure.unavailable` 仍是唯一 PR Inbox failure case。每個 BC 自行擁有 Failure；此 typealias 不構成 shared Core type 或跨 BC contract。

## TestCase

- TC-01：root manifest 可解析，且 `RivetPRInbox` target 使用既有 PRInbox path。
- TC-02：targeted Swift tests 通過；fake source 只提供 semantic candidate。
- TC-03：refresh 只保留 open 且直接要求目前使用者 review 的 candidate。
- TC-04：空 candidate 結果回傳 `.success([])`。
- TC-05：`.unavailable` 原樣回傳，且沒有其他 PR Inbox failure case。
- TC-06：target、source import 與 manifest 均沒有 `RivetHTTPClient`、外部 GitHub integration 或 network dependency。
- TC-07：scope/path check 確認只變更本 topic artifacts、root manifest、PRInbox source/tests 與 PR Inbox BC 文件；不測試排序、pagination、external query 或 DTO。
- TC-08：`Outcome` 以 Swift 6 編譯為 `Result` typealias，且 `Outcome<[InboxItem], PRInboxFailure>` 滿足 `Sendable`。
- TC-09：`ReviewRequestSource`、`PRInboxFacade` 與 tests 持續以 `Outcome` 表示 `.success(...)`／`.failure(...)`，不改變既有 membership、source-order、empty-success 或 `.unavailable` passthrough 語意。
- TC-10：amendment diff 僅含四份 topic artifacts、`Sources/BoundedContexts/PRInbox/Outcome.swift` 與直接必要的既有 PR Inbox tests；不修改 manifest、BC 文件或其他 baseline path。

## Implementation

1. 在 PR-01 明示 `approved` 後，新增 root product／targets，並以 target source 取代 PRInbox `.gitkeep`。
2. 實作 target-owned public contract、internal membership filter 與 refresh Facade；不得加入 Adapter 或外部 dependency。
3. 以 fake source 驗證 membership、empty success、failure passthrough 與呼叫次數；回寫 PR Inbox BC 文件的長期事實。

## Amendment Rework

1. PR-02 已明示 `approved`；IM-02 已只將 `Outcome.swift` 改為 locked `Result`
   typealias，並只在 `ContractTests.swift` 補上 alias／public API semantics assertion。
2. TE-02 已對 TC-01 至 TC-10 明示 `approved`，並已執行 `swift package dump-package`、
   `swift test`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、
   `scripts/check-swift-coverage.sh` 與 `git diff --check`。
3. RV-02 的 `needs-rework` 僅回交 PC-03：移除本計畫內殘留的 custom `Outcome` enum
   declaration，並使四份 artifacts 與已收到的 verdict 一致。PC-03 完成後，交由獨立
   PR-03 審查；PR-03 已明示 `approved`。RV-03 曾被指定為後續 review gate，但未記錄任何
   verdict、delivery 或 review-thread resolution 結果；本次 human-authorized PR comment amendment
   已將它取代為 historical／superseded 紀錄，不再是 current gate。

## Selected PR Comment Amendment

1. 已選取 review threads 1–4 的 Comment-Reviewer `needs-rework` 結論；本 amendment
   只新增 `ReviewRequestCandidate` 的 public initializer，完全保留 `Outcome`／`Result`、
   PRInbox failure、membership、refresh-only、source-order 與 empty-inbox contracts。
2. PR-04 已由獨立 Plan-Reviewer 明示 `approved`。IM-03 已完成 selected review fixes，
   僅修改
   `Sources/BoundedContexts/PRInbox/ReviewRequestCandidate.swift`、
   `Tests/RivetPRInboxTests/ContractTests.swift` 與
   `Tests/RivetPRInboxTests/StaticIsolationTests.swift`。Contract test 使用普通
   `import RivetPRInbox`，保留既有 `Outcome`／`Result`、`Sendable`、failure assertions，
   並透過新 initializer 建立 candidate；static-isolation test 遞迴列舉僅限 PRInbox target
   的 `.swift` source，並保留既有 banned import／network token checks。
3. TE-03 已對 8 個 tests 與 `swift package dump-package`、`swift test`、
   `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、
   `scripts/check-swift-coverage.sh`、`git diff --check`。獨立 Reviewer 完成後回到
   Human Check；不提交、push、改 PR 狀態、merge 或 release。

## Workflow Gate

本計畫不是 approval。baseline 的歷史 PR-01 至 RV-01 不追溯補填 verdict。selected PR
comment amendment 已完成 PR-04、IM-03 與 TE-03；RV-04 是唯一 current pending gate。RV-04 的
`needs-rework` 只回交 Plan-Creator，`blocked` 或 `human-check` 停止自動前進。
最終 Reviewer 明示結果後交還 human review，不可自行 commit、push、改 PR 狀態、merge、
release 或繞過 human boundary。未來 adapter topic 才可採用 GitHub API catalog 的 query
並在 PR Inbox Port 前映射外部 contract。
