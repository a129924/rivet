# PR Reader Content Source Core 契約：技術規格

## Locked Decisions

### Target and dependency boundary

root `Package.swift` 新增 `RivetPRReader` library product、source target（`Sources/BoundedContexts/PRReader/Core`）與 `RivetPRReaderTests`。該 target 只編譯 Core，不能以 PR Reader 根目錄作 target path 而納入未驗證 `Infra/GitHub/GraphQL/Schema.graphqls`。不新增 package dependency；Core 不 import PR Inbox、GitHubIntegration、RivetHTTPClient、WebView 或外部 transport。`Outcome` 是 Reader target-local、受 `Sendable` 約束的 `Result` typealias；沒有 shared BC target。

### Public semantic contract

下列是本 topic 的 public shape；所有公開 value 型別提供可由一般 `import RivetPRReader` 使用的 initializer，採 `Equatable`／`Sendable`；Failure 另符合 `Error`。型別、欄位、method 與 case 名稱依此契約，不新增另一層公開抽象。

```swift
public typealias Outcome<Success: Sendable, Failure: Error & Sendable> = Result<Success, Failure>

public struct ReaderPullRequestID: Equatable, Sendable {
  public let owner: String
  public let repository: String
  public let number: Int
}

public struct ReaderFileReference: Equatable, Sendable {
  public let value: String
}

public enum PRReaderFailure: Error, Equatable, Sendable {
  case notReadable
  case unavailable
  case contentNotRepresentable
}

public protocol PRContentSource: Sendable {
  func fetchContent(for id: ReaderPullRequestID) async
    -> Outcome<PRContentSnapshot, PRReaderFailure>
}
```

`PRContentSnapshot` 是一個 PR 的完整語意快照：

| Value | Public fields / cases |
| --- | --- |
| `PRContentSnapshot` | `id: ReaderPullRequestID`, `background: ReaderBackground`, `conversation: [ReaderComment]`, `reviews: [ReaderReview]`, `inlineThreads: [ReaderInlineThread]`, `files: [ReaderFile]`, `reviewDecision: ReviewDecision?`, `checkRollup: ReaderCheckRollup?` |
| `ReaderBackground` | `title: String`, `body: String?`, `author: String?` |
| `ReaderComment` | `id: String`, `body: String`, `author: String?` |
| `ReaderReview` | `id: String`, `body: String`, `author: String?`, `state: ReviewState` |
| `ReaderInlineThread` | `id: String`, `path: String`, `line: Int?`, `isResolved: Bool`, `isOutdated: Bool`, `comments: [ReaderComment]` |
| `ReaderFile` | `reference: ReaderFileReference`, `path: String`, `previousPath: String?`, `change: FileChange`, `additions: Int`, `deletions: Int`, `patch: String?` |
| `FileChange` | `added`, `removed`, `modified`, `renamed`, `copied`, `typeChanged` |
| `ReviewState` | `pending`, `commented`, `approved`, `changesRequested`, `dismissed` |
| `ReviewDecision` | `approved`, `changesRequested`, `reviewRequired` |
| `ReaderCheckRollup` | `overallState: ReaderCheckState`, `checks: [ReaderCheck]` |
| `ReaderCheck` | `.run(name: String, status: ReaderRunStatus, conclusion: ReaderRunConclusion?)`, `.commitStatus(context: String, state: ReaderCheckState)` |
| `ReaderRunStatus` | `requested`, `queued`, `inProgress`, `completed`, `waiting`, `pending` |
| `ReaderRunConclusion` | `actionRequired`, `timedOut`, `cancelled`, `failure`, `success`, `neutral`, `skipped`, `startupFailure`, `stale` |
| `ReaderCheckState` | `expected`, `error`, `failure`, `pending`, `success` |

本 Core slice 不含 check ID 或 URL。`checkRollup == nil` 表示 rollup 不存在；存在且 `checks` 為空是另一個可表達狀態。array 順序就是來源閱讀順序，不在 Core 重新排序。

### Producer obligations and failure

`PRContentSource` producer 回傳成功時，`snapshot.id == request id`，同一 snapshot 的 `ReaderFileReference` 唯一，`files` 的來源順序不變。本切片不新增 Core validator；fake tests 驗證型別表示能力，不宣稱對未來 concrete producer 的義務已有 runtime enforcement。

Core snapshot 不設頂層 `unifiedDiff`，逐檔 `patch?` 是唯一 diff payload。合法缺 patch 不丟棄 file metadata，亦不構成 Reader failure；未來 Reader Infra 可選擇 raw unified diff 為來源，但拆檔與保真規則另立 topic。

`.notReadable` 表示 PR 無法閱讀或無權存取，`.unavailable` 表示內容暫時不可取得。`.contentNotRepresentable` 是已獲 human 明示授權的 Reader 閱讀語意：未來 mapper 對必要集合元素或必要資料無法保真映入完整 Core 模型時必須回傳 failure，不得略過後成功；合法的 optional `reviewDecision`、`checkRollup`、`author`、`conclusion`、`patch` 為 nil 不屬於此情況。本 topic 不定義 concrete mapper 的資料來源或 technical mapping。

### Deferred Swift–WebView boundary

WebView `DiffSnapshot` 另有 `pullRequestId`、`snapshotId` 與 snapshot-local `fileId`；`DiffViewModel` 另有 `viewed`。它們均不是 Reader Core 的持久資料欄位。Swift 是 viewed 的持久化權威；後續 bridge topic 才決定 PR ID encoding、snapshot ID 生命週期、Reader file reference 與 snapshot-local file ID 映射／事件回查、viewed 來源、過期事件處理、patch／count 轉換。

現有 TS `DiffFileStatus` 只有 added／removed／modified／renamed，Core 的 copied／typeChanged 不能被該契約接收。TS 六狀態擴充需另立 topic 並完成其 planning／human gate，bridge 前不得宣稱完整相容。此 topic 不更動 TS、WebView runtime 或 viewed persistence。

## File Impact

- ReadOnly：`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、現有 TS diff contracts、候選 GraphQL SDL、`docs/github-api/`、其他 BC source 與既有 tests；唯一 test-only 例外為下列 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` exact graph expected-set 同步。
- Written：四份同 slug artifacts；實作階段新增 Reader Core source 與 `Tests/RivetPRReaderTests/`。
- Deleted：無；保留 PR Reader 根目錄 `.gitkeep` 與候選 SDL。
- Modify：實作階段修改 root `Package.swift` 加入 product／targets；完成後修改 `docs/architecture/bounded-contexts/pr-reader.md` 的 Core／failure truth；唯一新增 compatibility path 是 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`，且只可將 products expected set 加入 `RivetPRReader`，targets expected set 加入 `RivetPRReader`、`RivetPRReaderTests`。必須保留所有既有 entries、GitHubIntegration product mapping、target type／path／dependency assertions、helpers 與其他 behavior；不得搬移／重構此 test，也不得在該 suite 新增 Reader semantic assertions。

## Validation Contract

fake Port／Core values 須能表達完整、有序多檔快照、六種 file changes、不同名稱 runs 與 commit status、rollup 缺席／空 checks、patch 缺席／存在、合法 optional nil、空集合及三種 failure；`swift build`、focused Reader tests 與 root `swift test` 必須全綠。`swift package dump-package` 與 exact graph assertions 必須證明 root graph 新增 `RivetPRReader` product、`RivetPRReader` target、`RivetPRReaderTests` target 三個節點，且所有既有 products／targets、GitHubIntegration product mapping、target type／path／dependencies 不變。target dependency 與 changed-path audit 必須通過，並明示允許唯一 test-only compatibility path。producer obligations 待 concrete source／mapper topic 另驗，不由本輪 fake tests 宣稱已驗。

## Planning Status

PR-01 曾由獨立 Plan-Reviewer 明示 `approved`。IM-01 runtime evidence 顯示 focused Reader 11 tests、`swift build`、`swift package dump-package` 通過，但 root `swift test` 唯一 failure 是既有 graph exact set 未包含 Reader 新節點；Plan-Reviewer 因此明示 `needs-rework`。本輪只加入上述 compatibility sync，修訂後仍待 fresh independent re-review，不得視為實作、測試或 delivery gate 通過。

## Last Updated

2026-09-23
