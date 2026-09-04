# PR Inbox Swift Contract Baseline：技術規格

## Locked Decisions

### Target 與責任邊界

root `Package.swift` 新增 `RivetPRInbox` library product、同名 source target 與 `RivetPRInboxTests`；source target path 固定為既有 `Sources/BoundedContexts/PRInbox/`。不新增 package dependency 或 shared target。

`RivetPRInbox` 只擁有「open 且直接要求目前使用者 review」的 membership 判斷與 Presentation 可呼叫的 refresh 入口。外部 GitHub contract 必須由未來 GitHub Integration Adapter topic 先映射至 PR Inbox Port；本 topic 不讀取、定義或測試外部 query。

### Public Contract

```swift
public enum Outcome<Success: Sendable, Failure: Error & Sendable>: Sendable {
  case success(Success)
  case failure(Failure)
}

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

`Outcome` 是 target-local contract。Facade 在每次 `refresh()` 執行 internal refresh use case 一次，保留來源的合格項目順序；它不公開 current、snapshot、cache 或同步狀態。空集合為 `.success([])`，`.unavailable` 原樣傳遞；不定義排序。

### File and Change Constraints

| 類別 | 允許範圍 |
| --- | --- |
| ReadOnly | `docs/github-api/`、`packages/RivetHTTPClient/`、GitHub Integration BC 文件、其他 BC source，以及既有 source-layout／HTTP client artifacts。 |
| Written | 四份本 topic artifacts；PRInbox target-local source；`Tests/RivetPRInboxTests/` 的 Facade／membership tests 與 semantic fake。 |
| Deleted | `Sources/BoundedContexts/PRInbox/.gitkeep`，僅在實際 source 建立時移除。 |
| Modify | root `Package.swift`；PR Inbox BC 文件，且只記錄 target、Core contract 與尚無外部 Adapter 的已實作事實。 |

除上述檔案外的 tracked path 一律不在本 topic 實作範圍；遇到必要變更即停止並交回 Dispatcher。
