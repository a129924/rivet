# PR Inbox / Pull Request Row：技術規格

## Locked Decisions

- Topic slug：`pr-inbox-pull-request-row`
- Ownership：non-BC Presentation
- Base branch：`dev`
- Work branch：`feat/pr-inbox-pull-request-row`
- Implementation environment：Human/operator準備並attach的專用worktree
- Platform：沿用root package的`.macOS(.v15)`與Swift 6 mode
- New library product／target：`RivetPresentation`
- New test target：`RivetPresentationTests`
- `RivetPresentation` dependencies：empty
- Source path：`Sources/Presentation`
- Test path：`Tests/RivetPresentationTests`
- 本topic不建立Domain/Application mapper，不依賴`RivetPRInbox`，不實作`PullRequestList` interaction。

## SwiftPM Contract

`Package.swift`只加入：

```swift
.library(name: "RivetPresentation", targets: ["RivetPresentation"])

.target(
  name: "RivetPresentation",
  dependencies: [],
  path: "Sources/Presentation"
)

.testTarget(
  name: "RivetPresentationTests",
  dependencies: ["RivetPresentation"],
  path: "Tests/RivetPresentationTests"
)
```

既有`RivetPRInbox`、`GitHubIntegration`及其test targets的path/dependencies不得修改。

### Locked graph compatibility

`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的`packageDeclaresTheLockedTargetGraph()`只允許以下bounded change：

- products expected set由既有`GitHubIntegration`、`RivetPRInbox`加上`RivetPresentation`；
- targets expected set由既有`GitHubIntegration`、`GitHubIntegrationTests`、`RivetPRInbox`、`RivetPRInboxTests`加上`RivetPresentation`、`RivetPresentationTests`；
- 保留所有既有entries、integration product mapping、target type/path/dependency assertions及其他test behavior，不刪除、不放寬。

唯讀搜尋另找到`Tests/RivetPRInboxTests/StaticIsolationTests.swift`，但其manifest checks是non-exclusive `contains` assertions，唯一negative assertion只禁止`RivetHTTPClient`；新增Presentation graph不影響它，因此它只作ReadOnly evidence，沒有第二個Modify path。

## Public Contract

### `PullRequestRowPresentation`

```swift
public struct PullRequestRowPresentation: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let repositoryLabel: String
  public let numberLabel: String
  public let authorLabel: String
  public let relativeTimeLabel: String
  public let contextLabel: String?
  public let secondaryMetadataLabels: [String]

  public init(
    id: String,
    title: String,
    repositoryLabel: String,
    numberLabel: String,
    authorLabel: String,
    relativeTimeLabel: String,
    contextLabel: String? = nil,
    secondaryMetadataLabels: [String] = []
  )
}
```

- `id`是presentation-local stable identity，不是Domain identity contract。
- 所有label都是caller提供的display-ready value；target不計算relative time、不驗證PR number、不做localization或business mapping。
- Internal `accessibilityLabelText`依序組合title、`repositoryLabel numberLabel`、author與存在時的context。
- Internal `accessibilityValueText`組合relative time與存在時的secondary metadata。
- Optional value缺少時直接省略；不得輸出placeholder、假零值或多餘separator。

### `PullRequestRow`

```swift
public struct PullRequestRow: View {
  public init(presentation: PullRequestRowPresentation)
  public var body: some View
}
```

Row不得公開或持有：

- `isSelected`
- `Binding`
- `@State`／`@FocusState`
- action closure
- gesture／context menu
- Open Reader或navigation intent

### Public API allowlist

整個target只允許13個public declarations：兩個public structs、八個model properties、兩個initializers與`body`。以`^[[:space:]]*public[[:space:]]`掃描時必須恰為13個；Preview file不得有public declaration。

## Layout Contract

### Native styling

- Title：`.headline`、`.primary`、固定單行；空間不足時使用tail truncation，不得為完整顯示title而增加row高度。
- Internal title layout contract固定為`titleLineLimit == 1`；repository／PR identity維持下一層資訊，secondary metadata依既有tier優先收斂。
- Repository/PR identity：`.subheadline`、semantic secondary style、單行tail truncation。
- Context、author/time、secondary metadata：`.caption`與semantic secondary style、單行tail truncation。
- 不使用custom RGB/hex color、custom accent、card background、rounded container或自繪selection/focus appearance。
- 不建立horizontal `ScrollView`、AppKit representable或固定content width。

### Deterministic tiers

Internal `PullRequestRowLayoutTier`固定為：

```text
full                 minimum 620
withoutMetadata      minimum 480
withoutAuthorTime    minimum 340
primaryOnly          no minimum
```

各tier內容：

| Tier | Content |
| --- | --- |
| `full` | title、identity、context、author/time、secondary metadata |
| `withoutMetadata` | title、identity、context、author/time |
| `withoutAuthorTime` | title、identity、context |
| `primaryOnly` | title、identity |

Implementation rules：

1. `ViewThatFits(in: .horizontal)`candidate順序固定為上述四級。
2. 以internal `PullRequestRowFitLayout: Layout`取代會讓content ideal width參與水平fit的`ZStack` measurement；不得新增public declaration。
3. `PullRequestRowFitLayout`與`PullRequestRowLayoutTier.resolve(availableWidth:)`都從`PullRequestRowLayoutTier`的620／480／340 constants取得threshold，不得複製數值或建立第二套policy。
4. `PullRequestRowFitLayout` 的internal pure width helper固定回傳`max(proposedWidth, tier.minimumWidth)`；`sizeThatFits`production path與test必須呼叫這個同helper。`proposal.width == nil`時以`tier.minimumWidth`作為proposed width；`primaryOnly`的minimum為`0`。Content subview以parent提供的finite available width測量，其measurement只決定height及在實際available width內的placement，不得以title、repository或metadata的intrinsic／ideal width擴大reported width。
5. 在620／480／340恰好值candidate必須fit；619／479／339必須退到下一tier。相同available width搭配short或極長content必須得到相同tier。
6. Text在tier內自行tail truncation；不得增加title行數、為完整content增加row高度或建立horizontal scrolling。

Expected resolution：

| Width | Tier |
| ---: | --- |
| `680` | `full` |
| `620` | `full` |
| `619` | `withoutMetadata` |
| `560` | `withoutMetadata` |
| `480` | `withoutMetadata` |
| `479` | `withoutAuthorTime` |
| `400` | `withoutAuthorTime` |
| `340` | `withoutAuthorTime` |
| `339` | `primaryOnly` |
| `300` | `primaryOnly` |

## Accessibility Contract

- Row使用單一combined accessible element，從presentation input產生label/value。
- Label至少包含title、repository/PR identity、author與存在時的context/status。
- Value包含relative time與存在時的secondary metadata。
- Context/status以文字存在於visual/a11y semantics，不得只靠顏色。
- Width tier只改變visual subset，不得改變完整accessible summary。
- Increase Contrast與inactive control state必須依semantic system styles退化。
- Selected state、row position、focus、inactive selected appearance及F-01/F-02 list行為由future `PullRequestList`提供，本leaf不得偽造。

## Fixture and Preview Contract

### Exact fixtures

`PullRequestRowPreviewFixtures`置於`#if DEBUG`且為internal：

| Fixture | id | title | repository | number | author | time | context | metadata |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| standard | `sample-studio/atlas-desktop#87` | `Clarify offline workspace state` | `atlas-desktop` | `#87` | `Theo North` | `38m` | `Context prepared` | `priority` |
| longTitle | `fixture-labs/long-title#501` | `Preserve keyboard selection while filtering a very long list of pull request results` | `long-title` | `#501` | `Morgan Reed` | `1h` | `Review requested` | `interface` |
| longRepository | `fixture-labs/extraordinarily-long-desktop-workspace-repository#502` | `Keep repository identity readable` | `extraordinarily-long-desktop-workspace-repository` | `#502` | `Sam Lee` | `2h` | `Context available` | `desktop` |
| minimalMetadata | `fixture-labs/minimal-row#503` | `Simplify the empty state copy` | `minimal-row` | `#503` | `Avery Quinn` | `1d` | `nil` | `[]` |
| richMetadata | `example-labs/nebula-ui#142` | `Tighten keyboard movement across command results` | `nebula-ui` | `#142` | `Mira Vale` | `12m` | `Keyboard flow` | `mentioned`、`keyboard` |

Tests逐欄比對五列literal values，並驗證ids與repository/number tuples唯一。Expected fixture array必須定義在test file且在debug／release皆可編譯；`#if DEBUG`只包住對`PullRequestRowPreviewFixtures.all`的actual fixture lookup與equality assertions。Release compilation不得解析或引用`PullRequestRowPreviewFixtures`。

### Preview set

- `Fixture Matrix`：五fixtures同時置於native `List`，width `680`；selection只由debug harness的`@State`與`.tag(id)`擁有。
- `Degradation Tiers`：同一rich fixture依序以`680/560/400/300`呈現四級；expected tier caption只放在row外。
- `Long Content`：long title與long repository於`360` points。
- `Increased Contrast`：standard與rich fixtures使用increased-contrast environment。
- `Inactive Control State`：standard與rich fixtures使用inactive control environment；不宣稱完成List selected/inactive acceptance。

## Test Contract

Tests使用Swift Testing：

```swift
import Testing
@testable import RivetPresentation

@Suite("PullRequestRow presentation")
struct PullRequestRowPresentationTests { ... }
```

固定六個tests：

1. `presentationStoresDisplayReadyValues()`
2. `optionalMetadataCanBeAbsent()`
3. `accessibilityTextIncludesRequiredSemantics()`
4. `accessibilityTextOmitsMissingMetadataWithoutPlaceholders()`
5. `previewFixturesHaveUniqueIdentitiesAndAreDeterministic()`
6. `layoutTierBreakpointsFollowDegradationOrder()`

Specifier prefix固定為`RivetPresentationTests.PullRequestRowPresentationTests/`。

PR #39 comment rework不得新增、刪除或改名test。既有tests的bounded新增coverage固定為：

- `previewFixturesHaveUniqueIdentitiesAndAreDeterministic()`：always-compilable expected values與uniqueness assertions在所有configuration執行；只有DEBUG branch讀取DEBUG-only fixtures並比對expected values。
- `layoutTierBreakpointsFollowDegradationOrder()`：除既有680／620／619／560／480／479／400／340／339／300 cases外，直接驗證production `PullRequestRowFitLayout`使用的shared policy；short與long-content ideal width在620／480／340及相鄰boundary產生相同reported candidate fit／tier結果。

## Durable Writeback Contract

既有README／architecture writeback的historical gate維持不變。本cycle的native interaction contract amendment只有debug與release target build、focused tests、root tests均通過後才可修改。

### README replacement

將「目前狀態」既有兩段完整替換為：

> Rivet 目前是可公開的 architecture baseline repository。它保留產品與架構決策、Bounded Context Map，以及 Swift／Node 版本基線；root Swift package 已包含受限的產品實作。
>
> 目前已實作 non-BC `RivetPresentation` library target 的原生 SwiftUI `PullRequestRow` leaf 與其 display-ready Presentation input。該 target 不依賴任何 Bounded Context，不包含 Domain／Application mapper，也不擁有 `PullRequestList` 的 selection、focus 或 interaction；後續仍以一次一個 Bounded Context 或 bounded Presentation slice 的節奏推進，並以 `analysis/`、`plan/` 與 `docs/` 的配對文件保留可追溯決策。

不得保留「尚未開始任何產品功能實作」或「從 `PR Inbox` 的第一個最小切片開始實作」。

### Architecture README replacement

將intro中的：

> 除其單一架構圖的 artifact-local viewer 可近用性補強外，不建立其他產品功能。

精確替換為：

> Root Swift package 另包含 non-BC `RivetPresentation` target，目前只實作原生 SwiftUI `PullRequestRow` leaf 與其 display-ready Presentation input；該 target 不依賴任何 Bounded Context，不包含 Domain／Application mapper，也不擁有 `PullRequestList` 的 selection、focus 或 interaction。除本文件已列明的受限實作外，不宣稱其他產品能力已完成。

Intro其餘內容、ownership、dependency direction與BC map原文保持不變。

### Native interaction contract bounded amendment

在`docs/presentation/native-interaction-contract.md`的「## 8. Window and Resize Contract」→「### Fixed degradation priorities」中，保留既有優先順序，並於Inbox row說明後加入以下長期contract：

> `PullRequestRow` title **MUST（必須）**保持單行，寬度不足時使用tail truncation，不得為完整顯示title而增加row高度。Repository／PR identity保持在title的次一層；secondary metadata依full、without metadata、without author/time、title＋identity only順序收斂。`620`／`480`／`340` 是row-local tier thresholds，不是window minimum；candidate是否fit只取決於available width與這三個threshold，不得被title、repository或metadata的ideal width改寫。Tier內文字自行truncate，非diff row **MUST NOT（不得）**產生horizontal scrolling。

這個writeback不新增BC ownership、Domain／Application mapping、public Swift API、List selection／focus或scene/window minimum。

## Exact Path Contract

### ReadOnly

- `docs/design-principles.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `prototypes/pr-inbox-static-visual-prototype/index.html`
- `prototypes/pr-reader-interactive-ux-prototype/index.html`
- `analysis/pr-reader-interactive-ux-prototype/requirements.md`
- `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`
- `Tests/RivetPRInboxTests/StaticIsolationTests.swift`

### Written

- `analysis/pr-inbox-pull-request-row/requirements.md`
- `analysis/pr-inbox-pull-request-row/technical-spec.md`
- `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md`
- `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`

### Modify

- `Package.swift`
- `README.md`
- `docs/architecture/README.md`
- `docs/presentation/native-interaction-contract.md`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`

### Deleted

None。

四組path兩兩互斥；遇到任何額外必要path即停止並回planning。

### PR #39 comment rework exact allowlist

本cycle只允許修改以下七個exact paths：

- `analysis/pr-inbox-pull-request-row/requirements.md`
- `analysis/pr-inbox-pull-request-row/technical-spec.md`
- `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md`
- `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
- `docs/presentation/native-interaction-contract.md`

`Package.swift`、`Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`、`Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`、`Tests/RivetPRInboxTests/StaticIsolationTests.swift`、`README.md`與`docs/architecture/README.md`在本cycle均不得修改。Static graph無需擴張；`colorSchemeContrast`的public environment key path不可寫，保留現行Preview-only作法。

## Workspace and Workflow Evidence

- Current phase：PR #39 comment rework independent review。Topic／Mission product acceptance與HC-01 `採用`維持`completed`；PR-09已`approved`（Findings：None），IM-02 completed，TE-02 explicit verdict=`approved`；PC-14 completed；current step為RV-03 pending。
- Human已明示「可以實現」。
- Human/operator已準備專用worktree並attach目前task。
- Branch：`feat/pr-inbox-pull-request-row`。
- HEAD/local `dev`/`origin/dev` baseline：`579e67b6db650218078e3383365e40cf08a5e641`。
- Worktree在PC-01前clean且branch唯一attach。
- Workspace preparation由Human/operator完成並attach；Plan-Creator未執行Git。
- PR-01已明示`needs-rework`；PC-02只修正其findings，不產生approval。
- PR-02已明示`needs-rework`；PC-03只補齊validation success semantics，不產生approval。
- PR-03已明示`needs-rework`；PC-04只同步四份planning artifacts的current workflow truth，不變更locked contract且不產生approval。
- PR-04已明示`approved`並進入IM-01；runtime preflight因相對`SWIFTPM_MODULECACHE_OVERRIDE`不是合法absolute path而在compile前exit 1。這次historical pause已由PC-05／PR-05解除，原因是validation-contract flaw，不是code failure。
- PC-05只將formal plan每條Swift command的`CLANG_MODULE_CACHE_PATH`與`SWIFTPM_MODULECACHE_OVERRIDE`改為由專用worktree root的`$(pwd)`產生runtime absolute paths，並同步workflow state；不變更其他locked contract且不產生approval。
- PR-05已明示`approved`，同一IM-01從red setup恢復；focused六tests與package describe/build/test-list均通過。Root `swift test`執行70 tests，唯一failure為既有`packageDeclaresTheLockedTargetGraph()`排他expected sets未包含已核准的Presentation graph；這次historical pause已由PC-06／PR-06解除，屬bounded allowlist gap，不是product failure。
- PC-06只新增`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的bounded Modify contract、同步TC/path audits與workflow state；README/docs仍未修改，Plan-Creator未碰觸任何implementation path。
- PR-06已明示`approved`，Findings：None；同一IM-01據此恢復並completed，完成red-green、focused 6/6、root 70/70、bounded compatibility test、durable docs writeback與automated path/API/docs audits。此evidence不宣稱Human visual或VoiceOver pass。
- TE-01已completed，Overall PASS automated；TC-07以及TC-03/04/05/08/09/10的明示Human visual／VoiceOver portions仍pending，且不是automated failure。
- PC-07只同步四份artifacts的workflow truth，不變更任何locked contract且不產生approval。
- RV-01已completed並明示`approved`，Findings：None；Reviewer確認focused 6/6、root 70/70，以及scope/path/API/layout/fixtures/accessibility/docs皆pass。Human visual／VoiceOver checklist仍pending。
- PC-08只同步四份artifacts的final workflow truth，不變更任何locked contract且不產生Reviewer approval；Reviewer approval evidence只來自RV-01 explicit result。
- HC-01已completed，owner為Human；Human decision原值為`採用`，date為2026-09-21。Human確認doc-only amendment已正確同步final accepted behavior：title固定單行、tail truncation、不增加row高度、repository／PR identity維持次層、secondary metadata依既有tiers收斂，且沒有horizontal scrolling。
- PC-09只記錄final Human decision與Mission completion，不變更任何locked contract且不產生verdict；completion authority只來自Human `採用`。
- Topic／Mission已completed，沒有product blocker或HC-01 decision pending。Human於2026-09-21另以原值`可以 commit -> push -> Open Ready PR`授權post-completion external delivery；`採用`不等同commit-message confirmation。
- PC-10只同步delivery workflow truth，不變更任何locked product contract且不產生verdict。
- PR-07已`approved`，Findings：None；獨立Plan-Reviewer只審delivery workflow truth，未重開single-line title、其他product contract、test／Reviewer evidence或path allowlist。
- PC-11只同步PR-07 explicit result與當時DL-01 state，不產生verdict。
- DL-01 completed：既有topic scope已stage，且Human exact commit-message confirmation gate已完成。
- DL-02 completed：Human-confirmed commit已建立並push。
- DL-03 completed：PR #39已建立為Open／Ready，base=`dev`、head=`feat/pr-inbox-pull-request-row`、current head=`7d162aa`。
- RV-02 verdict=`needs-rework`：T-01／T-03是同一release compile failure，T-02要求production path與tested policy共用決策來源，T-04要求content ideal width不得蓋過fit threshold，T-05要求本文件的bounded durable writeback。Findings不需要新檔案、BC ownership、public API、dependency或test name變更。
- PC-12 completed：Plan-Creator只materialize本bounded PR-comment amendment與truthful workflow state，不產生verdict。
- PR-08 verdict=`needs-rework`：findings只限step ledger的historical doc-only scope標示與plan內一處「執行」文字誤植。
- PC-13 completed：Plan-Creator只修正PR-08兩項findings並同步workflow truth，不產生verdict。
- PR-09 `approved`，Findings：None。
- IM-02 completed：red release fixture／layout seam後green，debug／release builds、focused 6/6、root 70/70、precommit／path／API audits均通過，diff恰為七個allowlist paths。
- TE-02 explicit verdict=`approved`；獨立驗證同evidence。Human-only Preview／VoiceOver仍為pending，但不是automated blocker。
- PC-14 completed：Plan-Creator只同步workflow truth，不產生verdict。
- RV-03 pending：current step為獨立Reviewer。
- 只有RV-03 `approved`才可進DL-04：stage本cycle exact allowlist中的七個paths，依`git-commit-convention`提出message後停止等待HC-02 Human exact commit-message confirmation。
- HC-02明確確認message後才可DL-05 commit；DL-05完成後才可DL-06 push並驗證local/remote heads一致；之後才可DL-07 reply／resolve已addressed comments。
- Human授權不含merge、release、tag、branch deletion、worktree removal或自動開始`PullRequestList`／下一Mission。

## Last Updated

2026-09-21
