# PR Inbox Swift Contract Baseline：技術規格

## Locked Decisions

### Target 與責任邊界

root `Package.swift` 新增 `RivetPRInbox` library product、同名 source target 與 `RivetPRInboxTests`；source target path 固定為既有 `Sources/BoundedContexts/PRInbox/`。不新增 package dependency 或 shared target。

`RivetPRInbox` 只擁有「open 且直接要求目前使用者 review」的 membership 判斷與 Presentation 可呼叫的 refresh 入口。外部 GitHub contract 必須由未來 GitHub Integration Adapter topic 先映射至 PR Inbox Port；本 topic 不讀取、定義或測試外部 query。

### Public Contract

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

`Outcome` 是 `RivetPRInbox` target-local 的 Swift 標準庫 `Result` typealias，不再有 custom enum。型別參數維持 `Success: Sendable` 與 `Failure: Error & Sendable` 約束；因此 target 的 public API 仍以 `Outcome` 表達 success／failure，呼叫端持續使用 `Result` 提供的 `.success(...)` 與 `.failure(...)` case。

每個 BC 仍各自擁有 Failure contract；本 topic 的唯一 failure case 是 `PRInboxFailure.unavailable`。此 alias 不建立 shared Core target、不跨 BC 搬移型別，也不新增 dependency。Facade 在每次 `refresh()` 執行 internal refresh use case 一次，保留來源的合格項目順序；它不公開 current、snapshot、cache 或同步狀態。空集合為 `.success([])`，`.unavailable` 原樣傳遞；不定義排序。

### File and Change Constraints

| 類別 | 允許範圍 |
| --- | --- |
| ReadOnly | `docs/github-api/`、`packages/RivetHTTPClient/`、GitHub Integration BC 文件、其他 BC source，以及既有 source-layout／HTTP client artifacts。 |
| Written | 四份本 topic artifacts；PRInbox target-local source；`Tests/RivetPRInboxTests/` 的 Facade／membership tests 與 semantic fake。 |
| Deleted | `Sources/BoundedContexts/PRInbox/.gitkeep`，僅在實際 source 建立時移除。 |
| Modify | root `Package.swift`；PR Inbox BC 文件，且只記錄 target、Core contract 與尚無外部 Adapter 的已實作事實。 |

除上述檔案外的 tracked path 一律不在本 topic 實作範圍；遇到必要變更即停止並交回 Dispatcher。

### Delivered-baseline Amendment

baseline 已在 feature branch 以 `2db4d13` 交付並位於既有 draft PR #12。本 amendment 不重開 baseline 的 target、source path、Facade、membership 或 failure 決策；後續實作只允許修改 `Sources/BoundedContexts/PRInbox/Outcome.swift`，以及直接證明 alias／public API 語意所需的既有 `Tests/RivetPRInboxTests/` 檔案。四份同 topic artifacts 為本 amendment 唯一 planning write 範圍；不再修改 root manifest、BC 文件或任何其他 baseline path。

PR-02 已由獨立 Plan-Reviewer 明示 `approved`。IM-02 已完成，實際 source／test
scope 限於 `Sources/BoundedContexts/PRInbox/Outcome.swift` 與
`Tests/RivetPRInboxTests/ContractTests.swift`；TE-02 已對 TC-01 至 TC-10 與指定
validation commands 明示 `approved`。RV-02 的 code review verdict 是
`needs-rework`，只要求移除 planning contract 中殘留的 custom `Outcome` enum
declaration，並使 ledger 如實反映上述 evidence。PC-03 不授權任何 source、test 或
其他非-artifact path 變更。獨立 Plan-Reviewer 已對 PR-03 明示 `approved`；目前
RV-03 是最終 outcome／code review 的 pending gate，尚未有其 verdict 或 delivery 結果。
