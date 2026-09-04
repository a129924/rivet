# PR Inbox Swift Contract Baseline

## Goal

建立 root SwiftPM `RivetPRInbox` library product／target，於既有 `Sources/BoundedContexts/PRInbox/` 實作 PR Inbox-owned Core contract、refresh-only Facade 與 semantic fake 測試。

## Non-Goal

不建立 GitHub Integration Adapter、HTTP dependency、外部 query／DTO／network、UI、PR Reader、Presentation Session、cache、sync、排序、Git 或 release 動作。

## In-Scope

- target-local `Outcome`、Inbox identity、semantic candidate、failure、Port、internal membership filter 與 refresh Facade。
- root manifest 的 product／source target／test target。
- semantic fake 與 Swift Testing；PR Inbox BC 文件的 target／contract truth writeback。

## Out-Of-Scope

- GitHub search query、pagination、incomplete-result policy、HTTP/auth/rate-limit、`InfraUnknownError`、GitHub DTO 與 adapter failure mapping。
- `RivetHTTPClient` 或其他 package dependency、跨 BC contract、current/snapshot state、cache 及同步。

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

`Outcome` 僅屬於 `RivetPRInbox` target。refresh 只保留 open 且直接要求目前使用者 review 的 candidate，維持來源順序；空集合為成功，failure 原樣傳遞，且不公開 current／snapshot／cache state。

## TestCase

- TC-01：root manifest 可解析，且 `RivetPRInbox` target 使用既有 PRInbox path。
- TC-02：targeted Swift tests 通過；fake source 只提供 semantic candidate。
- TC-03：refresh 只保留 open 且直接要求目前使用者 review 的 candidate。
- TC-04：空 candidate 結果回傳 `.success([])`。
- TC-05：`.unavailable` 原樣回傳，且沒有其他 PR Inbox failure case。
- TC-06：target、source import 與 manifest 均沒有 `RivetHTTPClient`、外部 GitHub integration 或 network dependency。
- TC-07：scope/path check 確認只變更本 topic artifacts、root manifest、PRInbox source/tests 與 PR Inbox BC 文件；不測試排序、pagination、external query 或 DTO。

## Implementation

1. 在 PR-01 明示 `approved` 後，新增 root product／targets，並以 target source 取代 PRInbox `.gitkeep`。
2. 實作 target-owned public contract、internal membership filter 與 refresh Facade；不得加入 Adapter 或外部 dependency。
3. 以 fake source 驗證 membership、empty success、failure passthrough 與呼叫次數；回寫 PR Inbox BC 文件的長期事實。

## Workflow Gate

本計畫不是 approval。只有獨立 Plan-Reviewer 對 PR-01 明示 `approved`，Implementer 才可開始實作。`needs-rework` 回交 Plan-Creator；`blocked` 或 `human-check` 停止自動前進。未來 adapter topic 才可採用 GitHub API catalog 的 query 並在 PR Inbox Port 前映射外部 contract。
