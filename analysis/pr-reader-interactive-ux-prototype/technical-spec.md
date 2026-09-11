# PR Reader 互動 UX 原型技術規格

## Topic 與 Locked Decisions

- Topic：`pr-reader-interactive-ux-prototype`
- Primary BC：`PR Reader`
- Base branch：`codex/pr-inbox-static-visual-prototype`
- 唯一 implementation output：`prototypes/pr-reader-interactive-ux-prototype/index.html`
- 單一自包含 HTML，內嵌 CSS 與原生 JavaScript；以 `file://` 開啟。
- 固定深色，唯一驗收 viewport 為 1440 × 900 Chrome。
- 不使用外部資源、網路、storage、server、build step 或 package。
- Reader 完全取代 Inbox workspace，不建立第三欄。
- 所有 fixture 與互動狀態僅供展示，不建立或改變產品 API／Domain contract。

## Runtime Structure

```text
index.html
├── fixture constants
│   ├── six pull requests
│   ├── per-PR overview, files, diffs, commits, checks
│   └── canonical inline conversation
├── in-memory presentation state
├── renderInbox()
├── renderReader()
│   ├── renderOverview()
│   ├── renderFiles()
│   ├── renderCommits()
│   └── renderChecks()
├── event handlers
│   ├── click / double-click
│   ├── keyboard routing
│   └── composer actions
└── inline CSS
```

不得拆出其他檔案。DOM helper、state reducer 或 render function 都保持 file-local，且不構成 public API。

## Visual Contract

- 固定深色：低對比深灰背景與 surface、淺色正文、節制藍色 focus/selection。
- Dense native macOS workspace：緊湊 toolbar/tab/row、細分隔線、最少必要圓角。
- Selection、tab 與 modal 可用 120–180ms subtle transition；不做整頁滑動或裝飾動畫。
- 禁止 SaaS card wall、漸層、過度圓角徽章、過度留白、假 browser/window chrome 與 web-style global navigation。
- `Interactive mockup` 與 `Fictional data` 必須可見。
- 只驗收 1440 × 900；不得水平 overflow 或遮擋 toolbar、tabs、Files bottom bar。

## Fixture Model

每筆 PR fixture 至少包含：

```text
PRFixture {
  prKey
  repositoryOwner
  repositoryShort
  number
  title
  inboxTime
  readerTime
  author
  inboxContext
  summary
  whatChanged[3]
  status
  files[8]
  commits[3]
  checks[3]
  initialFileOrdinal
}
```

`prKey` 可使用 owner-qualified identity；UI repo line 與 toolbar 使用 `repositoryShort`。資料必須常數化、deterministic，runtime 不得隨機生成。

### Inbox Fixtures

| Ordinal | Internal prKey | Visible repo line | Title | Author · Inbox time | Context metadata |
| --- | --- | --- | --- | --- | --- |
| 1 | `sample-studio/atlas-desktop#87` | `atlas-desktop #87` | `Clarify offline workspace state` | `Theo North · 38m` | `Context prepared · priority` |
| 2 | `example-labs/nebula-ui#142` | `nebula-ui #142` | `Tighten keyboard movement across command results` | `Mira Vale · 12m` | `Keyboard flow · mentioned` |
| 3 | `demo-works/orbit-api#315` | `orbit-api #315` | `Normalize cursor boundaries for activity pages` | `Jun Park · 2h` | `Pagination scope · needs review` |
| 4 | `fictional-inc/harbor-kit#54` | `harbor-kit #54` | `Reduce motion in layered panel transitions` | `Ari Linden · 5h` | `Motion polish · ready` |
| 5 | `sample-studio/atlas-desktop#91` | `atlas-desktop #91` | `Group recent environments by workspace` | `Nadia Stone · Yesterday` | `Workspace grouping · follow-up` |
| 6 | `example-labs/nebula-ui#156` | `nebula-ui #156` | `Refine empty copy for newly created workspaces` | `Rowan Lake · 2d` | `Empty state copy · mentioned` |

Sidebar 只顯示 `Inbox (6)` 與 `atlas-desktop`、`nebula-ui`、`orbit-api`、`harbor-kit`。Main header 逐字為：

- `PR Inbox`
- `Pull requests waiting for your attention.`
- `Needs Review / Mentioned / All`
- `Static sample`

Filter 是純 presentation；`Needs Review` 預設 active，三段均不響應 click 或 keyboard。

### Canonical Overview Fixture

`sample-studio/atlas-desktop#87` 的 Reader 必須逐字呈現：

- Toolbar：`atlas-desktop / #87`
- Title：`Clarify offline workspace state`
- Author/time：`Theo North · 38m ago`
- Status：`Ready for review`
- Summary：`This PR clarifies how disconnected workspaces are represented in the project header and removes ambiguous offline state.`
- What Changed：
  1. `Adds explicit disconnected workspace state`
  2. `Updates project header rendering`
  3. `Adds coverage for offline transitions`
- Stats：`8 files changed`、`+182`、`−43`、`3 commits`
- Checks：只顯示 `✓ Build`、`✓ Tests`、`✓ Lint`
- Action：`Review Changes →`

不得顯示 Passed、duration 或額外 check detail。

### Canonical Files

File fixture 使用完整 path 作 identity。Changed Files row 在 `Sources`／`Tests` group 下只顯示 basename；完整 path 僅可放在 tooltip、accessible description 或其他輔助資訊。

| # | Group | Identity | Visible basename | Status | Delta | Changes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Sources | `Sources/ProjectHeader.swift` | `ProjectHeader.swift` | M | `+38 −12` | 2 |
| 2 | Sources | `Sources/WorkspaceState.swift` | `WorkspaceState.swift` | M | `+27 −8` | 2 |
| 3 | Tests | `Tests/WorkspaceTests.swift` | `WorkspaceTests.swift` | M | `+18 −4` | 1 |
| 4 | Tests | `Tests/OfflineTests.swift` | `OfflineTests.swift` | M | `+20 −3` | 2 |
| 5 | Tests | `Tests/OfflineStatusViewTests.swift` | `OfflineStatusViewTests.swift` | M | `+31 −4` | 2 |
| 6 | Tests | `Tests/WorkspaceHeaderSnapshotTests.swift` | `WorkspaceHeaderSnapshotTests.swift` | M | `+22 −7` | 2 |
| 7 | Tests | `Tests/ProjectHeaderTests.swift` | `ProjectHeaderTests.swift` | M | `+14 −3` | 1 |
| 8 | Tests | `Tests/WorkspaceStateTests.swift` | `WorkspaceStateTests.swift` | M | `+12 −2` | 1 |

Totals 必須是 `+182 −43`。

每檔需有不同且合理的 Swift/XCTest unified diff：proper hunk header、old/new line number、context、removal、addition。內容聚焦 disconnected `WorkspaceState`、project header rendering、last successful sync 與 offline transition coverage；禁止 lorem ipsum、`sample code`、空 placeholder 或重複 diff。

唯一 preset inline review conversation 位於 `Sources/WorkspaceState.swift` 第一個 change，anchor line：

```swift
case offline(lastSuccessfulSync: Date?)
```

逐字 conversation：

- Mira Vale：`Could this state keep the last successful sync time so the header can explain how stale the workspace is?`
- Reply：`Yes — this fixture keeps it in memory and the header renders a relative value.`

### Other Reader Fixtures

其 repository、number、title、author/time 必須與對應 Inbox row 一致；每筆都固定為 8 files、3 deterministic fictional commits 與 `✓ Build / ✓ Tests / ✓ Lint`。非 canonical commits 不鎖定或驗收 SHA/message，不得 runtime 隨機生成。

- `nebula-ui#142` files：`Sources/CommandResultsView.swift`、`Sources/KeyboardMovement.swift`、`Sources/SelectionAnchor.swift`、`Sources/CommandKeyHandler.swift`、`Tests/CommandResultsViewTests.swift`、`Tests/KeyboardMovementTests.swift`、`Tests/SelectionAnchorTests.swift`、`Tests/CommandKeyHandlerTests.swift`
- `orbit-api#315` files：`Sources/ActivityCursor.swift`、`Sources/ActivityPage.swift`、`Sources/CursorBoundary.swift`、`Sources/PageRequest.swift`、`Tests/ActivityCursorTests.swift`、`Tests/ActivityPageTests.swift`、`Tests/CursorBoundaryTests.swift`、`Tests/PageRequestTests.swift`
- `harbor-kit#54` files：`Sources/LayeredPanel.swift`、`Sources/PanelTransition.swift`、`Sources/MotionPreference.swift`、`Sources/PanelAnimator.swift`、`Tests/LayeredPanelTests.swift`、`Tests/PanelTransitionTests.swift`、`Tests/MotionPreferenceTests.swift`、`Tests/PanelAnimatorTests.swift`
- `atlas-desktop#91` files：`Sources/EnvironmentGroup.swift`、`Sources/RecentEnvironment.swift`、`Sources/WorkspaceGrouping.swift`、`Sources/EnvironmentList.swift`、`Tests/EnvironmentGroupTests.swift`、`Tests/RecentEnvironmentTests.swift`、`Tests/WorkspaceGroupingTests.swift`、`Tests/EnvironmentListTests.swift`
- `nebula-ui#156` files：`Sources/EmptyWorkspaceView.swift`、`Sources/EmptyWorkspaceCopy.swift`、`Sources/WorkspaceFirstRun.swift`、`Sources/NextStepAction.swift`、`Tests/EmptyWorkspaceViewTests.swift`、`Tests/EmptyWorkspaceCopyTests.swift`、`Tests/WorkspaceFirstRunTests.swift`、`Tests/NextStepActionTests.swift`

其 Overview summary/What Changed 固定為：

- `nebula-ui#142`：`This PR tightens keyboard selection movement across command results.`；`Keeps selection inside visible results`、`Preserves the active anchor during movement`、`Adds keyboard boundary coverage`
- `orbit-api#315`：`This PR normalizes cursor boundaries for paginated activity responses.`；`Defines empty-page cursor behavior`、`Keeps page requests deterministic`、`Adds pagination boundary coverage`
- `harbor-kit#54`：`This PR reduces motion in layered panel transitions without changing panel structure.`；`Shortens layered panel transitions`、`Respects reduced-motion preference`、`Adds transition timing coverage`
- `atlas-desktop#91`：`This PR groups recent environments by their owning workspace.`；`Introduces workspace environment groups`、`Keeps recent ordering within each group`、`Adds grouping coverage`
- `nebula-ui#156`：`This PR refines the empty message shown for a newly created workspace.`；`Shortens first-run workspace copy`、`Clarifies the next available action`、`Adds empty-state copy coverage`

Canonical #87 commits：

1. `a17c2d1 Model offline workspace header state`
2. `c84e6af Refine project header copy`
3. `e3b4902 Add offline workspace coverage`

## Presentation State

```text
workspace: "inbox" | "reader"
inboxSelectionKey: PRKey
activePRKey: PRKey | null
readerStateByPR[PRKey]: {
  activeTab: "overview" | "files" | "commits" | "checks"
  selectedFileOrdinal: 1...8
  selectedChangeIndex: non-negative integer valid for selected file
  visitedFileOrdinals: Set<1...8>
  savedDraft: { body, fileOrdinal, changeIndex } | null
}
composer: { isOpen, workingBody } | null
```

Initial state：

- `workspace = inbox`
- `inboxSelectionKey = sample-studio/atlas-desktop#87`
- `activePRKey = null`
- 所有 PR：`activeTab = overview`、`visitedFileOrdinals = {}`、`savedDraft = null`、`selectedChangeIndex = 0`
- #87：`selectedFileOrdinal = 3`、`initialFileOrdinal = 3`
- 其他 PR：`selectedFileOrdinal = 1`、`initialFileOrdinal = 1`
- `composer = null`

`<current> / 8 files` 的 current 是 selected file 的 1-based ordinal。

第一次讓 Files 成為 active tab 時，將目前 initial selected file 加入 visited。#87 首次由 `Review Changes →` 或 Files tab 進入，唯一結果是：選 `Tests/WorkspaceTests.swift`、顯示 `WorkspaceTests.swift` 與第一個 change、顯示 `3 / 8 files`、visited 恰為 `{3}`。後續 visited 只增不減；切 tab 或回 Inbox 不清除，reload 才清除。

## Workspace State Machine

```text
Inbox select -> 只更新 inboxSelectionKey
Inbox double-click / Enter -> activePRKey = inboxSelectionKey -> workspace = reader
Reader tab activation -> 更新該 PR activeTab
Enter Files -> 若 visited 為空，採 initialFileOrdinal；visited += selected ordinal
Review Changes → -> activeTab = files -> 執行 Enter Files
Select file -> selectedFileOrdinal = target -> selectedChangeIndex = 0 -> visited += target
Select change -> 更新 selectedChangeIndex
合格 c/C 或 C Comment -> 開 composer working copy
Save Draft -> 寫入該 PR savedDraft -> 關 modal
Cancel/Escape -> 丟棄 working copy -> 關 modal
Done / ← Inbox -> workspace = inbox -> activePRKey = null；readerStateByPR 不變
Reload -> 還原 Initial state
```

資料只由常數 fixture 流向 render，再由 UI event 更新記憶體 state 後重繪。不得讀寫 storage、URL/hash/query、network、filesystem 或持久化 DOM attribute。

## Interaction Contract

### Inbox

- Single click：只選取 row。
- Double-click：選取 target 並開 Reader；快速重複只產生一次 transition。
- `ArrowUp`／`ArrowDown`、`Home`／`End`：只移動 selection；首尾不 wrap。
- `Space`：只保持 selection。
- `Enter`：開 selected PR。

### Toolbar/Tabs

- `← Inbox`：從任何 Reader tab 返回，保留該 PR session state。
- Disabled `Open on GitHub`：click、Enter、Space 均 no-op。
- Tabs：click 可啟用；tablist focus 下 `ArrowLeft`／`ArrowRight`、`Home`／`End` 移動並啟用，首尾不 wrap；`Enter`／`Space` 啟用。
- Tabs 只有 Overview、Files (8)、Commits (3)、Checks；沒有 Conversation。
- `Review Changes →`：click、Enter、Space 切入 Files。

### Files/Diff

只在 `activeTab = files`、modal 關閉，且 event target 不在 `input`、`textarea`、`select`、`button`、`[contenteditable]` 等 editable/control element 時啟用：

- ArrowUp/Down：在目前 file 的 changes 內移動，首尾 no-op。
- Option+ArrowUp/Down：切上一/下一 file，首尾 no-op；切換後 change index = 0 並加入 visited。
- Click file：選 file、change index = 0、加入 visited。
- Click hunk/change：更新 selected change。
- `event.key` 為 `c` 或 `C`，且 `metaKey`、`ctrlKey`、`altKey` 皆為 false：開 composer；Shift 可產生大寫 C。
- Cmd+C、Ctrl+C、Option+C 不攔截。
- Click `C Comment`：開 composer。
- `↑↓ Change`、`⌥↑↓ File` 是 legend，不是 control。
- `Done`：只在 Files bottom bar，返回 Inbox、保留 progress、不改 count/membership、不表示 review 完成。

Overview、Commits、Checks 不顯示 Files bottom bar；file/change/C shortcuts no-op 且不自動切 Files。

### Composer

- Modal 只從 Files 的合格 c/C 或 `C Comment` 開啟；背景 inert，focus 留在 dialog。
- 顯示完整 file identity 與 change anchor。
- 同 anchor 的已保存 draft 可載入 textarea；不同 anchor 初始空白。
- `Save Draft` 只在 trim 後非空時可用；每 PR 最多一份 `{body, fileOrdinal, changeIndex}`，新保存取代舊保存，diff 顯示 `Draft · not submitted`。
- Cancel/Escape 丟棄 working copy，但保留先前 saved draft。
- modal 或 editable/control focus 內不攔截 c/C、Arrow、Option+Arrow；不阻礙輸入或複製。
- 不提供 Submit、Send、review action 或 persistence。

## Edge Cases

- 所有 selection navigation 在首尾 no-op，不 wrap、不越界。
- 只有一個 change 的 file 收到 ArrowUp/Down 時 no-op。
- 切 file 一律將 invalid/old change index 正規化為 0。
- Static filters 與 disabled GitHub action 永遠 no-op。
- 空白 draft 不可保存；重複保存只取代同一 PR 的單一 draft。
- 不同 PR 的 tab/file/change/visited/draft 完全隔離。
- `Done` 不移除 PR、不減 `Inbox (6)`、不改 row metadata、不新增 completion badge。
- reload 清除所有 runtime state，回到 Inbox 第一列 selected。

## Public API / Interfaces

不新增或修改 public API、Swift target、package manifest、Domain model、Port、Facade、UseCase、Adapter、Event、Message 或 Cross-BC contract。DOM events 與上述 state schema 只屬原型內部，不可當成產品或架構契約。

## Verification Mapping

| TestCase | Technical focus |
| --- | --- |
| TC-01 | approved planning baseline 後，以 `git status --short --untracked-files=all` 或等效 enumeration 涵蓋 tracked/staged/unstaged/untracked paths並套 allowlist；未追蹤 HTML 另以實際讀取內容的 file-specific static/whitespace check驗證，staged後可再用 `git diff --cached --check`；空白普通 diff不可作為 untracked evidence |
| TC-02 | file://、self-contained、zero network/storage、reload reset |
| TC-03 | 1440 × 900 fixed-dark native desktop visual |
| TC-04 | Inbox exact strings、static filters、repo/metadata hierarchy |
| TC-05 | single/double click、keyboard selection/open、workspace replacement |
| TC-06 | #87 exact Overview content |
| TC-07 | four tabs、default Overview、Review Changes action |
| TC-08 | two-column Files、basename rows、8-file totals、initial 3/8、conversation |
| TC-09 | Files-only keyboard、modifier/editable guards、bottom bar |
| TC-10 | Done/top back、count/membership、per-PR continuity |
| TC-11 | canonical commits、other deterministic commits、checks |
| TC-12 | inline conversation、modal、draft lifecycle |
| TC-13 | six-PR isolated state、reload reset |
| TC-14 | disabled capabilities、runtime stability、fictional data |

## Delivery Prerequisite

Base branch 的既有 commits 不需重建。建立 implementation baseline 並進入 `IM-01` 前，必須由 `Implementer` 對上一 topic branch `codex/pr-inbox-static-visual-prototype` 執行 bounded non-force push並確認 remote ref。這不是 PC-01 或 planning review 的 blocker。只授權該 bounded Implementer push；Observer/Dispatcher、Plan-Creator 與 Reviewer 不得執行 push，也不得 force-push、重寫 commit或夾帶其他 branch/ref。

## Planning Artifact Evidence

- 本輪四份 topic artifacts 是 untracked 新檔。PC-01/回修 evidence必須以 `git status --short --untracked-files=all` 或等效 enumeration列出 tracked、staged、unstaged、untracked paths並確認只有四個 allowlisted `??` paths。
- 對四份 untracked artifacts使用會實際開啟檔案內容的 file-specific static/whitespace check；普通 `git diff --check`／`git diff --name-status` 的空白輸出不涵蓋 untracked檔案，不能作為存在性或 whitespace evidence。
- 若後續將檔案 staged，可再以 `git diff --cached --check`驗證 staged內容；這些檢查都不產生 approval。

## Last Updated

2026-09-11
