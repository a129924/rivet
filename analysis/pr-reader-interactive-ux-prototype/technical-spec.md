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
- 所有fixture與review/unreview狀態僅供展示，屬prototype-local Presentation Session；不建立或改變產品API／Domain contract，也不發送GitHub viewed/unviewed write。
- PC-05 baseline為clean pushed HEAD/upstream`8c2facf`；本輪只調整既有review progress controls並加入同列原生progress，不redesign surface。

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
- 初始 progress：`0 / 8 reviewed`及native`<progress value="0" max="8">`
- 初始 action：`Review Changes →`

不得顯示 Passed、duration 或額外 check detail。Overview在既有action附近、同一既有surface/action列顯示由該PR`reviewedFileOrdinals.size`推導的逐字numeric label；其右側加入唯一非互動native`<progress>`，不重排行動區、不加入Files，也不新增panel、tab、surface、shortcut或product能力。

Overview progress element contract：

- `value = reviewedFileOrdinals.size`，`max = files.length`；0／partial／full一律render。
- 約`72px × 3px`，divider-toned track與restrained accent；不得成為第二個Files indicator或大型meter。
- Visible numeric label具有該PR render內唯一穩定ID；`<progress aria-labelledby="<visible-label-id>">`引用它。
- `aria-valuetext`逐次更新為`<n> of <file-count> files reviewed`，例如`0 of 8 files reviewed`與`8 of 8 files reviewed`。
- 三態：0顯示`0 / 8 reviewed`＋progress＋`Review Changes →`；1...7顯示`n / 8 reviewed`＋progress＋`Continue Review →`；8顯示`8 / 8 reviewed`＋progress＋非互動`✓ All files reviewed`＋primary`Finish Reading`。

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
- current與reviewed正交：同一row可同時是current與reviewed；選取、重選或離開row都不改reviewed membership。只有合格`Mark Reviewed`／`Mark as Unreviewed`event可增減set。

#87 首次由 `Review Changes →` 或 Files tab進入時，仍選`Tests/WorkspaceTests.swift`、顯示`WorkspaceTests.swift`與第一個 change；`reviewedFileOrdinals`維持空集合，footer顯示`0 / 8 reviewed`。進入 Files、選 file/change、切 tab或返回 Inbox本身都不會標記 reviewed。

## Review Progress Contract

### Files Footer State Matrix

Files footer保留既有numeric progress、shortcut legends與comment action，不加入native`<progress>`，再依current membership與reviewedCount呈現三種互斥action state：

| State | Noninteractive status | Secondary action | Primary action |
| --- | --- | --- | --- |
| current未reviewed，count 0...7 | none | none | `Mark Reviewed` |
| current已reviewed，count 1...7 | `Reviewed` | `Mark as Unreviewed` | none |
| count 8、current必為reviewed | `✓ All files reviewed` | `Mark as Unreviewed` | `Finish Reading` |

`Reviewed`與`✓ All files reviewed`不可focus、click或觸發state change。三態都使用既有Files footer/action area，不重排layout、不新增panel/tab/surface/shortcut。

### Mark Reviewed

只有current未reviewed且reviewedCount 0...7時顯示enabled primary`Mark Reviewed`。啟用後依序執行：

1. 讀取目前 `selectedFileOrdinal`為 `markedOrdinal`。
2. 確認`markedOrdinal`尚未reviewed後加入`reviewedFileOrdinals`；stale/ineligible event則no-op。
3. 若加入後 reviewedCount為8，保留`selectedFileOrdinal = markedOrdinal`與目前 selected change，不再切檔；footer改顯示`8 / 8 reviewed`與`Finish Reading`。
4. 若尚未8/8，依候選順序`markedOrdinal + 1 ... 8`再`1 ... markedOrdinal - 1`向後搜尋第一個不在 reviewed set的 ordinal。
5. 找到 next unreviewed後才切換`selectedFileOrdinal`，並將`selectedChangeIndex = 0`；本次Mark操作只新增membership，後續合格的`Mark as Unreviewed`仍可移除目前ordinal。

Reviewed current不顯示`Mark Reviewed`，因此不再有reviewed-current reactivation/forward行為。任何file row indicator都只是既有row內的呈現，不是toggle或新control。

### Mark as Unreviewed

只有current已reviewed時顯示enabled secondary`Mark as Unreviewed`。啟用後依序執行：

1. 擷取active PR、`selectedFileOrdinal`與既有focus source；若workspace/tab不合格、current不在reviewed set、event已stale或modal/editable guard不合格，整體no-op。
2. 只從該PR的`reviewedFileOrdinals`移除`selectedFileOrdinal`；reviewedCount恰減1。
3. 保持active PR、active tab、selected file、selected change、saved/working draft與Inbox selection不變；不搜尋next file、不導覽、不wrap、不改change。
4. Re-render後current row仍為current但已unreviewed，Files footer恢復primary`Mark Reviewed`，並把focus交給這個新render的`Mark Reviewed`。

若由8/8移除，立即撤下Overview/Files的`✓ All files reviewed`與`Finish Reading`，Overview成為`7 / 8 reviewed`＋progress value 7＋`Continue Review →`。若由1/8移除，Overview成為`0 / 8 reviewed`＋progress value 0＋`Review Changes →`。Unreview本身絕不使用Mark的forward/wrap algorithm。

### Overview Action 與 Finish

- Overview每次render都直接由`reviewedFileOrdinals.size`推導可見progress與action，不能另存可能失真的count或label。
- reviewedCount = 0：顯示`0 / 8 reviewed`與progress value 0；action為`Review Changes →`，只切入Files並保留initial/current selection。
- reviewedCount = 1...7：顯示逐字`n / 8 reviewed`與progress value n，其中n為實際set size；action為`Continue Review →`，只切入Files並恢復該PR最後selected file/change。
- reviewedCount = 8：顯示`8 / 8 reviewed`、progress value 8、非互動`✓ All files reviewed`與primary`Finish Reading`。
- Files footer依Files Footer State Matrix呈現；不顯示`Done`。
- `Finish Reading`只能在8/8啟用；從 Overview或Files啟用都只切`workspace = inbox`、`activePRKey = null`，保留該 PR 8/8、tab/file/change/draft，不改 Inbox selection、membership、count `6`或 row metadata。
- 頂部`← Inbox`在0...8任何 count都中性可用，只返回 Inbox並保留狀態；它不標記檔案、不觸發 Finish語意。

## Workspace State Machine

```text
Inbox select -> 只更新 inboxSelectionKey
Inbox double-click / Enter -> activePRKey = inboxSelectionKey -> workspace = reader
Reader tab activation -> 更新該 PR activeTab；Overview numeric/progress/completion/action在render時由reviewed set size推導
Enter Files -> activeTab = files；保留 selected file/change；不改 reviewed set
Review Changes → / Continue Review → -> 執行 Enter Files
Select file -> selectedFileOrdinal = target -> selectedChangeIndex = 0；不改 reviewed set
Select change -> 更新 selectedChangeIndex
Mark Reviewed（current未reviewed）-> set加入 current -> 未滿則forward/wrap找next unreviewed並將change設0；全滿則留在最後marked file
Mark as Unreviewed（current已reviewed）-> 只移除current membership -> file/change/draft/selection不變 -> render後focus Mark Reviewed
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
- Overview同一既有surface/action列中，0/1...7/8 reviewed時分別顯示numeric label＋native progress，action分別為`Review Changes →`／`Continue Review →`／`Finish Reading`；8/8另顯示非互動`✓ All files reviewed`。Review/Continue的click/Enter/Space只切入Files，Finish只回Inbox。

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
- Files footer顯示`n / 8 reviewed`、shortcut legends、`C Comment`與Files Footer State Matrix的status/actions；移除`Done`且不加入progress indicator。
- `Mark Reviewed`只在current未reviewed時使用既有forward/wrap algorithm；reviewed current partial只顯示非互動`Reviewed`與secondary`Mark as Unreviewed`。
- 8/8顯示非互動`✓ All files reviewed`、secondary`Mark as Unreviewed`與primary`Finish Reading`；Finish只返回Inbox。
- `Mark as Unreviewed`只移除current membership、保持位置/state並恢復Mark focus；stale/ineligible event no-op。

Overview、Commits、Checks 不顯示 Files footer；file/change/C shortcuts no-op且不自動切 Files。不得新增 progress panel、tab或 surface；只沿用 file-row indicator、Overview action與既有 Files footer。

### Composer

- Modal 只從 Files 的合格 c/C 或 `C Comment` 開啟；背景 inert，focus 留在 dialog。
- 顯示完整 file identity 與 change anchor。
- 同 anchor 的已保存 draft 可載入 textarea；不同 anchor 初始空白。
- `Save Draft` 只在 trim 後非空時可用；每 PR 最多一份 `{body, fileOrdinal, changeIndex}`，新保存取代舊保存，diff 顯示 `Draft · not submitted`。
- Cancel/Escape 丟棄 working copy，但保留先前 saved draft。
- modal 或 editable/control focus 內不攔截 c/C、Arrow、Option+Arrow；不阻礙輸入或複製。
- Open、Cancel、Save Draft與inline conversation都不得改變reviewed set/count、selected file/change，亦不得觸發Mark或Unreview navigation。
- 不提供 Submit、Send、review action 或 persistence。

## Edge Cases

- 所有 selection navigation 在首尾 no-op，不 wrap、不越界。
- 只有一個 change 的 file 收到 ArrowUp/Down 時 no-op。
- 切 file 一律將 invalid/old change index 正規化為 0。
- 重選reviewed file仍維持reviewed，並顯示對應`Reviewed`／`Mark as Unreviewed`或full state；row indicator與current不互相覆寫。
- Mark Reviewed只適用未reviewed current；stale/ineligible Mark event no-op。
- Mark as Unreviewed只移除current membership；stale/ineligible event no-op，且永不forward/wrap/navigation/change reset。
- Forward search先走較大 ordinal再wrap到1；永不選回已reviewed file。最後一個未reviewed file被標記後留在該 file，顯示8/8與Finish。
- 在未達8/8時不得出現或執行Finish/completion label；達8/8後Overview與Files既有action area都顯示`✓ All files reviewed`與Finish Reading。8→7需立即撤下，1→0需回Review Changes。
- Static filters 與 disabled GitHub action 永遠 no-op。
- 空白 draft 不可保存；重複保存只取代同一 PR 的單一 draft。
- 不同 PR 的 tab/file/change/reviewed/draft完全隔離；返回/重開不重設。
- Overview↔Files↔Inbox往返後，Overview progress/action必須由該PR保留的reviewed set重新推導並顯示，不可顯示stale count或其他PR進度。
- Finish Reading不移除 PR、不減`Inbox (6)`、不改 row metadata、不新增 completion badge；`← Inbox`同樣中性。
- reload 清除所有 runtime state，回到 Inbox 第一列 selected。

## Public API / Interfaces

不新增或修改public API、Swift target、package manifest、Domain model、Port、Facade、UseCase、Adapter、Event、Message或Cross-BC contract。`reviewedFileOrdinals`、review/unreview DOM events與上述state schema只屬prototype-local Presentation Session，不可當成產品或架構契約，也不得映射為GitHub viewed/unviewed write。

## Verification Mapping

| TestCase | Technical focus |
| --- | --- |
| TC-01 | clean pushed HEAD/upstream`8c2facf`；PC-05只改四份artifacts、IM-05只改既有HTML、DL-04只含五個tracked paths；以status/equivalent枚舉所有狀態並實讀做whitespace/EOF檢查 |
| TC-02 | file://、self-contained、zero network/storage、review/unreview state reload reset |
| TC-03 | 1440 × 900 fixed-dark native desktop visual與restrained native progress |
| TC-04 | Inbox exact strings、static filters、repo/metadata hierarchy |
| TC-05 | single/double click、keyboard selection/open、workspace replacement |
| TC-06 | #87 exact Overview、numeric/native progress a11y、0/partial/full action與completion label |
| TC-07 | four tabs、derived Overview transitions、8→7/1→0、no new surface/layout |
| TC-08 | two-column Files、basename、initial selected3但0/8 reviewed、current/reviewed indicators |
| TC-09 | Files footer三態、Mark forward/wrap、Unreview remove-only/focus、stale no-op、8→7/1→0 |
| TC-10 | no Done、full completion/Finish vs neutral back、Inbox invariants |
| TC-11 | canonical commits、other deterministic commits、checks |
| TC-12 | inline conversation、modal/draft lifecycle不影響review/unreview progress/navigation |
| TC-13 | multi-PR review/unreview/draft isolation、Overview↔Files↔Inbox persistence、derived display與reload reset |
| TC-14 | prototype-local review/unreview、native progress a11y、no storage/network/domain/GitHub write/new product UI與scope/runtime hygiene |

## Baseline 與 Phase Allowlist

- PC-05起始狀態：worktree clean，local HEAD與upstream均為`8c2facf`；DL-03已完成。
- PC-05 Modify allowlist只含四份topic artifacts；HTML與其他tracked paths ReadOnly。Written/Deleted皆為none。
- PR-05明示approved後，IM-05 Modify allowlist只有既有`prototypes/pr-reader-interactive-ux-prototype/index.html`；四份artifacts與其他paths ReadOnly。Written/Deleted仍為none。
- RV-05明示approved且staged review通過、Human確認commit message後，DL-04只包含四份artifacts與既有HTML共五個tracked paths；不得新增、刪除或夾帶其他path，之後由Implementer執行bounded non-force push。
- 每一 phase使用`git status --short --untracked-files=all`或等效方式枚舉 tracked/staged/unstaged/untracked paths並套 phase allowlist；對實際內容執行 whitespace/EOF檢查，staged後以`git diff --cached --check`補強。空白普通 diff不作為未枚舉 path的證據。

## Planning Artifact Evidence

- DL-03 evidence：commit`8c2facf`已bounded non-force push，local/upstream一致且worktree clean；HC-02其後選擇「調整」。
- PC-05 evidence必須如實顯示clean baseline`8c2facf`之後只有四份tracked artifacts被修改。
- Cross-artifact檢查需確認舊no-unreview、monotonic set、reviewed-current enabled Mark/reactivation-forward與TC-14 forbidden-unreview都只留在明確標示的歷史ledger，不再描述active contract。
- PR-05為目前pending獨立Plan-Reviewer gate；checks只證明path/content一致性，不產生approval。

## Last Updated

2026-09-14
