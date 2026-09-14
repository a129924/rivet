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
- 所有 fixture 與互動狀態僅供展示，不建立或改變產品 API／Domain contract，也不發送 GitHub viewed write。
- PC-03 baseline為 clean HEAD/upstream `0865469`；本輪只重寫 review progress既有互動，不 redesign surface。

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
- 初始 progress：`0 / 8 reviewed`
- 初始 action：`Review Changes →`

不得顯示 Passed、duration 或額外 check detail。Overview在既有 action附近、同一既有surface內顯示由該PR `reviewedFileOrdinals.size`推導的逐字progress；不得新增panel、tab、surface或layout。Progress/action三態為：0顯示`0 / 8 reviewed`與`Review Changes →`、1...7顯示`n / 8 reviewed`與`Continue Review →`、8顯示`8 / 8 reviewed`與`Finish Reading`。

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
  reviewedFileOrdinals: Set<1...8>
  savedDraft: { body, fileOrdinal, changeIndex } | null
}
composer: { isOpen, workingBody } | null
```

Initial state：

- `workspace = inbox`
- `inboxSelectionKey = sample-studio/atlas-desktop#87`
- `activePRKey = null`
- 所有 PR：`activeTab = overview`、`reviewedFileOrdinals = {}`、`savedDraft = null`、`selectedChangeIndex = 0`
- #87：`selectedFileOrdinal = 3`、`initialFileOrdinal = 3`
- 其他 PR：`selectedFileOrdinal = 1`、`initialFileOrdinal = 1`
- `composer = null`

衍生狀態：

- `currentFileOrdinal = selectedFileOrdinal`；current row indicator只由 selection推導。
- `reviewedCount = reviewedFileOrdinals.size`；Files footer顯示`reviewedCount / 8 reviewed`。
- `isFullyReviewed = reviewedCount == 8`。
- current與 reviewed正交：同一 row可同時是 current與 reviewed；選取、重選或離開 row都不移除 reviewed membership。

#87 首次由 `Review Changes →` 或 Files tab進入時，仍選`Tests/WorkspaceTests.swift`、顯示`WorkspaceTests.swift`與第一個 change；`reviewedFileOrdinals`維持空集合，footer顯示`0 / 8 reviewed`。進入 Files、選 file/change、切 tab或返回 Inbox本身都不會標記 reviewed。

## Review Progress Contract

### Mark Reviewed

Files footer在 reviewedCount 0...7時顯示`Mark Reviewed`。啟用後依序執行：

1. 讀取目前 `selectedFileOrdinal`為 `markedOrdinal`。
2. 將 `markedOrdinal`加入`reviewedFileOrdinals`；若已存在，membership不變，因此操作 idempotent且不提供 unreview。
3. 若加入後 reviewedCount為8，保留`selectedFileOrdinal = markedOrdinal`與目前 selected change，不再切檔；footer改顯示`8 / 8 reviewed`與`Finish Reading`。
4. 若尚未8/8，依候選順序`markedOrdinal + 1 ... 8`再`1 ... markedOrdinal - 1`向後搜尋第一個不在 reviewed set的 ordinal。
5. 找到 next unreviewed後才切換`selectedFileOrdinal`，並將`selectedChangeIndex = 0`；reviewed membership只增不減。

若目前檔已 reviewed而集合尚未滿，重按`Mark Reviewed`不改 membership，仍從目前檔下一 ordinal開始搜尋並前進到 next unreviewed。任何 file row indicator都只是既有 row內的呈現，不是 toggle或新 control。

### Overview Action 與 Finish

- Overview每次render都直接由`reviewedFileOrdinals.size`推導可見progress與action，不能另存可能失真的count或label。
- reviewedCount = 0：在既有action附近顯示`0 / 8 reviewed`；action為`Review Changes →`，只切入 Files並保留 initial/current selection。
- reviewedCount = 1...7：在相同位置顯示逐字`n / 8 reviewed`，其中n為實際set size；action為`Continue Review →`，只切入 Files並恢復該 PR最後 selected file/change。
- reviewedCount = 8：在相同位置顯示`8 / 8 reviewed`；action為`Finish Reading`。
- Files footer在0...7顯示`Mark Reviewed`；8時改顯示`Finish Reading`，不顯示`Done`。
- `Finish Reading`只能在8/8啟用；從 Overview或Files啟用都只切`workspace = inbox`、`activePRKey = null`，保留該 PR 8/8、tab/file/change/draft，不改 Inbox selection、membership、count `6`或 row metadata。
- 頂部`← Inbox`在0...8任何 count都中性可用，只返回 Inbox並保留狀態；它不標記檔案、不觸發 Finish語意。

## Workspace State Machine

```text
Inbox select -> 只更新 inboxSelectionKey
Inbox double-click / Enter -> activePRKey = inboxSelectionKey -> workspace = reader
Reader tab activation -> 更新該 PR activeTab；Overview progress/action在render時由reviewed set size推導
Enter Files -> activeTab = files；保留 selected file/change；不改 reviewed set
Review Changes → / Continue Review → -> 執行 Enter Files
Select file -> selectedFileOrdinal = target -> selectedChangeIndex = 0；不改 reviewed set
Select change -> 更新 selectedChangeIndex
Mark Reviewed -> set加入 current（idempotent）-> 未滿則forward/wrap找next unreviewed並將change設0；全滿則留在最後marked file
合格 c/C 或 C Comment -> 開 composer working copy
Save Draft -> 寫入該 PR savedDraft -> 關 modal
Cancel/Escape -> 丟棄 working copy -> 關 modal
Comment/draft lifecycle -> 不改 reviewed set/count、selected file/change或navigation
Finish Reading（僅8/8）/ ← Inbox -> workspace = inbox -> activePRKey = null；readerStateByPR 不變
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
- Overview同一既有surface中，0/1...7/8 reviewed時分別顯示`0 / 8 reviewed`／`n / 8 reviewed`／`8 / 8 reviewed`；action分別為`Review Changes →`／`Continue Review →`／`Finish Reading`。Review/Continue的click/Enter/Space只切入Files，Finish只回Inbox。

### Files/Diff

只在 `activeTab = files`、modal 關閉，且 event target 不在 `input`、`textarea`、`select`、`button`、`[contenteditable]` 等 editable/control element 時啟用：

- ArrowUp/Down：在目前 file 的 changes 內移動，首尾 no-op。
- Option+ArrowUp/Down：切上一/下一 file，首尾 no-op；切換後 change index = 0，不改 reviewed membership。
- Click file：選 file、change index = 0，不改 reviewed membership；已 reviewed row重選後仍 reviewed。
- Click hunk/change：更新 selected change。
- `event.key` 為 `c` 或 `C`，且 `metaKey`、`ctrlKey`、`altKey` 皆為 false：開 composer；Shift 可產生大寫 C。
- Cmd+C、Ctrl+C、Option+C 不攔截。
- Click `C Comment`：開 composer。
- `↑↓ Change`、`⌥↑↓ File` 是 legend，不是 control。
- Files footer顯示`n / 8 reviewed`、shortcut legends、`C Comment`與`Mark Reviewed`或`Finish Reading`；移除`Done`。
- `Mark Reviewed`使用 Review Progress Contract 的 idempotent forward/wrap algorithm。
- `Finish Reading`只在8/8出現並返回 Inbox；未滿時不存在且合成/錯誤觸發必須 no-op。

Overview、Commits、Checks 不顯示 Files footer；file/change/C shortcuts no-op且不自動切 Files。不得新增 progress panel、tab或 surface；只沿用 file-row indicator、Overview action與既有 Files footer。

### Composer

- Modal 只從 Files 的合格 c/C 或 `C Comment` 開啟；背景 inert，focus 留在 dialog。
- 顯示完整 file identity 與 change anchor。
- 同 anchor 的已保存 draft 可載入 textarea；不同 anchor 初始空白。
- `Save Draft` 只在 trim 後非空時可用；每 PR 最多一份 `{body, fileOrdinal, changeIndex}`，新保存取代舊保存，diff 顯示 `Draft · not submitted`。
- Cancel/Escape 丟棄 working copy，但保留先前 saved draft。
- modal 或 editable/control focus 內不攔截 c/C、Arrow、Option+Arrow；不阻礙輸入或複製。
- Open、Cancel、Save Draft與 inline conversation都不得改變 reviewed set/count、selected file/change或觸發 next-file navigation。
- 不提供 Submit、Send、review action 或 persistence。

## Edge Cases

- 所有 selection navigation 在首尾 no-op，不 wrap、不越界。
- 只有一個 change 的 file 收到 ArrowUp/Down 時 no-op。
- 切 file 一律將 invalid/old change index 正規化為 0。
- 重選 reviewed file仍維持 reviewed；不存在 unreview/remove操作。
- Mark Reviewed目前未reviewed file時只新增一次；目前已reviewed file時membership不變，但仍搜尋 next unreviewed。
- Forward search先走較大 ordinal再wrap到1；永不選回已reviewed file。最後一個未reviewed file被標記後留在該 file，顯示8/8與Finish。
- 在未達8/8時不得出現或執行Finish；達8/8後 Overview與Files都顯示Finish Reading。
- Static filters 與 disabled GitHub action 永遠 no-op。
- 空白 draft 不可保存；重複保存只取代同一 PR 的單一 draft。
- 不同 PR 的 tab/file/change/reviewed/draft完全隔離；返回/重開不重設。
- Overview↔Files↔Inbox往返後，Overview progress/action必須由該PR保留的reviewed set重新推導並顯示，不可顯示stale count或其他PR進度。
- Finish Reading不移除 PR、不減`Inbox (6)`、不改 row metadata、不新增 completion badge；`← Inbox`同樣中性。
- reload 清除所有 runtime state，回到 Inbox 第一列 selected。

## Public API / Interfaces

不新增或修改 public API、Swift target、package manifest、Domain model、Port、Facade、UseCase、Adapter、Event、Message或 Cross-BC contract。`reviewedFileOrdinals`、DOM events與上述 state schema只屬原型 Presentation Session，不可當成產品或架構契約，也不得映射為 GitHub viewed write。

## Verification Mapping

| TestCase | Technical focus |
| --- | --- |
| TC-01 | clean HEAD/upstream `0865469`；PC-03/PC-04只改四份 artifacts、IM-03只改既有 HTML、final commit只含五個 tracked paths；以status/equivalent枚舉所有狀態並實讀做whitespace/EOF檢查 |
| TC-02 | file://、self-contained、zero network/storage、reviewed state reload reset |
| TC-03 | 1440 × 900 fixed-dark native desktop visual |
| TC-04 | Inbox exact strings、static filters、repo/metadata hierarchy |
| TC-05 | single/double click、keyboard selection/open、workspace replacement |
| TC-06 | #87 exact Overview、0/1...7/8逐字progress與dynamic action labels |
| TC-07 | four tabs、derived Overview progress/action transitions、8/8 Finish gate、no new surface/layout |
| TC-08 | two-column Files、basename、initial selected3但0/8 reviewed、current/reviewed indicators |
| TC-09 | Files keyboard、Mark idempotency、forward/wrap、last/full behavior |
| TC-10 | no Done、Finish vs neutral back、Inbox count/membership/metadata |
| TC-11 | canonical commits、other deterministic commits、checks |
| TC-12 | inline conversation、modal/draft lifecycle不影響review progress/navigation |
| TC-13 | multi-PR tab/file/change/reviewed/draft isolation、Overview↔Files↔Inbox persistence、derived display與reload reset |
| TC-14 | no unreview/storage/network/domain/GitHub viewed write與scope/runtime hygiene |

## Baseline 與 Phase Allowlist

- PC-03起始狀態：worktree clean，local HEAD與upstream均為`0865469`。
- PC-03/PC-04 Modify allowlist只含四份 topic artifacts；HTML與其他 tracked paths ReadOnly。Written/Deleted皆為none。
- PR-04明示 approved後，IM-03 Modify allowlist只有既有`prototypes/pr-reader-interactive-ux-prototype/index.html`；四份 artifacts與其他 paths ReadOnly。Written/Deleted仍為none。
- RV-03明示 approved且 staged review通過、Human確認 commit後，final follow-up commit只包含四份 artifacts與既有 HTML共五個 tracked paths；不得新增、刪除或夾帶其他 path，之後由Implementer執行bounded non-force push。
- 每一 phase使用`git status --short --untracked-files=all`或等效方式枚舉 tracked/staged/unstaged/untracked paths並套 phase allowlist；對實際內容執行 whitespace/EOF檢查，staged後以`git diff --cached --check`補強。空白普通 diff不作為未枚舉 path的證據。

## Planning Artifact Evidence

- PC-03/PC-04 combined planning evidence必須如實顯示 clean baseline `0865469`之後只有四份 tracked artifacts被修改。
- PR-03已明示`needs-rework`；唯一required finding是Overview缺少由reviewed set size推導、0/1...7/8三態皆可見且與Files footer同格式的逐字progress。PC-04只修此項。
- PR-04為目前pending獨立Plan-Reviewer gate；只有明示`approved`才可建立IM-03 handoff。
- Cross-artifact檢查需確認不再以`visitedFileOrdinals`、`Done`或`3 / 8 files`描述現行契約；歷史 ledger evidence可保留但必須標為歷史。
- Checks只證明path/content一致性，不產生PR-04 approval。

## Last Updated

2026-09-12
