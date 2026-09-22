# PR Inbox / Pull Request Row：Implementation Plan

## Summary

建立第一個production-quality native SwiftUI Presentation leaf：`PullRequestRow`。新增獨立`RivetPresentation` SwiftPM library product/target，以純Presentation input驅動row、debug-only fixtures與SwiftUI Preview；不依賴`RivetPRInbox`、不建立Domain/Application mapper，也不實作List、selection、Reader或其他Inbox hierarchy。

Human已明示「可以實現」。正式branch鎖定為`feat/pr-inbox-pull-request-row`，implementation只可在Human/operator已準備並attach的專用worktree進行。Baseline HEAD/local `dev`/`origin/dev`均為`579e67b6db650218078e3383365e40cf08a5e641`，PC-01前已驗證clean且branch唯一attach。Plan-Creator未執行Git。

Topic／Mission product acceptance與HC-01 `採用`維持`completed`。PR-09已`approved`（Findings：None），IM-02 completed，TE-02 explicit verdict=`approved`；PC-14已完成workflow sync，current step為RV-03 pending。只有獨立Reviewer明示RV-03 `approved`才可進DL-04。

## Human Review Amendment（Current Override）

Human Review override（2026-09-21）：原始implementation plan的「title最多兩行」行為已在visual review中被拒絕，不再是有效requirement。最終accepted behavior為：

- PR title固定單行。
- 寬度不足時使用tail truncation。
- 不得為完整顯示title而讓row垂直擴張。
- Repository／PR identity維持下一層資訊。
- Secondary metadata依既有degradation contract先於primary identity收斂。
- 不產生horizontal scrolling，也不以arbitrary fixed pixel height鎖定row。

本plan後續仍保留的原始兩行描述只作歷史execution contract記錄，全部由本amendment取代，不得被後續Agent視為current specification。Current specification以`analysis/pr-inbox-pull-request-row/requirements.md`與`analysis/pr-inbox-pull-request-row/technical-spec.md`的單行規則為準。

## Goal

交付可獨立build、test、Preview與Human Review的native macOS `PullRequestRow`，呈現title、repository/PR identity、author、relative time、optional context/status與optional secondary metadata，並依既定資訊優先序可靠逐級退化。

## Non-Goal

- 不實作`PullRequestList`、Inbox workspace/header/sidebar/filter、Reader或navigation。
- 不擁有selection、focus、keyboard navigation、Open Reader、context menu、loading/error/offline或workspace state。
- 不修改PR Inbox、PR Reader、GitHubIntegration、networking、persistence或business logic。
- 不建立Domain/Application到Presentation的production mapper或dependency。
- 不新增generic design system、AppKit bridge、window minimum width或future Inbox component。
- 不宣稱完成List selection/focus、inactive selected appearance或Open Reader acceptance。
- Product Mission本身不授權merge、release、tag、branch deletion、worktree removal或下一Mission；commit、push與Ready PR只可依本plan的post-completion external delivery workflow執行。

## In-Scope

- `RivetPresentation` library product/source target與`RivetPresentationTests`。
- `PullRequestRowPresentation`與stateless `PullRequestRow`。
- 四級deterministic width degradation。
- 五個debug-only deterministic fixtures與五組Preview evidence。
- 六個Swift Testing tests、root regression與static isolation checks。
- 既有`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的bounded locked-graph compatibility update。
- Focused verification後的README/architecture current-state replacement。
- PR #39 comment rework：release-safe fixture test、production fit path與tested policy的shared decision source、長內容boundary regression，以及`docs/presentation/native-interaction-contract.md`的bounded durable writeback。

## Exact Checkout Contract

- Base：`dev`
- Remote baseline：`origin/dev`
- Branch：`feat/pr-inbox-pull-request-row`
- Environment：branch專用worktree；禁止在primary`dev` checkout實作。
- Workspace lifecycle只由Human/operator執行；Plan-Creator不得執行Git。
- 若branch/worktree/HEAD/clean evidence失效，停止於`human-check`。

PC-01 verified input：

```text
branch = feat/pr-inbox-pull-request-row
HEAD = dev = origin/dev = 579e67b6db650218078e3383365e40cf08a5e641
worktree = clean, dedicated, uniquely attached
```

Human/operator在PC-01 materialization前從專用worktree root完成以下exact checkout preflight；這組結果是workspace preparation evidence。Implementer在開始產品實作前重新執行相同commands；branch、HEAD、`dev`、`origin/dev`與worktree條件不得改變，而status的stage-specific條件改為只含四份已materialize planning artifacts。任一條件失敗即停止於`human-check`，不得修改產品檔案。

```bash
git branch --show-current
```

Success：唯一一行為`feat/pr-inbox-pull-request-row`。

```bash
git status --short --untracked-files=all
```

Workspace-preparation success：PC-01前無output。

Implementation-entry success：PC-02後恰為以下四行，沒有tracked modification或其他untracked path：

```text
?? analysis/pr-inbox-pull-request-row/requirements.md
?? analysis/pr-inbox-pull-request-row/technical-spec.md
?? plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md
?? plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md
```

```bash
git rev-parse HEAD
git rev-parse dev
git rev-parse origin/dev
```

Success：三行皆為`579e67b6db650218078e3383365e40cf08a5e641`。

```bash
git worktree list --porcelain
```

Success：目前attached專用workspace的entry含`branch refs/heads/feat/pr-inbox-pull-request-row`，且完整output中此branch只對應目前worktree一次。

## Exact Path Contract

四組兩兩互斥；每個path都是完整repository-relative file path。

### ReadOnly

| Path | Purpose |
| --- | --- |
| `docs/design-principles.md` | Product/architecture取捨 |
| `docs/architecture/bounded-contexts/pr-inbox.md` | PR Inbox ownership boundary |
| `prototypes/pr-inbox-static-visual-prototype/index.html` | Pending、non-normative visual evidence |
| `prototypes/pr-reader-interactive-ux-prototype/index.html` | HC-03 adopted Inbox row behavior actual source |
| `analysis/pr-reader-interactive-ux-prototype/requirements.md` | Adopted UX requirements |
| `analysis/pr-reader-interactive-ux-prototype/technical-spec.md` | Adopted Inbox Fixtures/row behavior |
| `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md` | HC-03 adoption evidence |
| `Tests/RivetPRInboxTests/StaticIsolationTests.swift` | Non-exclusive manifest assertion evidence；無需修改 |

### Written

| Path | Owner phase |
| --- | --- |
| `analysis/pr-inbox-pull-request-row/requirements.md` | Plan-Creator |
| `analysis/pr-inbox-pull-request-row/technical-spec.md` | Plan-Creator |
| `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md` | Plan-Creator |
| `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md` | Plan-Creator |
| `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift` | Implementer |
| `Sources/Presentation/PRInbox/PullRequestRow.swift` | Implementer |
| `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift` | Implementer |
| `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift` | Implementer |

### Modify

| Path | Bounded change |
| --- | --- |
| `Package.swift` | 新增`RivetPresentation` product/target及`RivetPresentationTests`；既有targets不變 |
| `README.md` | Focused verification後完整替換「目前狀態」兩段 |
| `docs/architecture/README.md` | Focused verification後精確替換intro的stale限制句 |
| `docs/presentation/native-interaction-contract.md` | PR #39 rework verification通過後，只在§8 Fixed degradation priorities回寫已採用row contract，不改BC ownership |
| `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | 只在`packageDeclaresTheLockedTargetGraph()`的既有products/targets expected sets加入已核准Presentation graph；其餘assertions/tests不變 |

### Deleted

None。

### PR #39 comment rework exact allowlist

本cycle只允許修改：

1. `analysis/pr-inbox-pull-request-row/requirements.md`
2. `analysis/pr-inbox-pull-request-row/technical-spec.md`
3. `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md`
4. `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md`
5. `Sources/Presentation/PRInbox/PullRequestRow.swift`
6. `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
7. `docs/presentation/native-interaction-contract.md`

本cycle不得修改`Package.swift`、`Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`、`Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`、`Tests/RivetPRInboxTests/StaticIsolationTests.swift`、`README.md`或`docs/architecture/README.md`。

## Public APIs and Target Membership

`Package.swift`加入：

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

Public contract：

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

public struct PullRequestRow: View {
  public init(presentation: PullRequestRowPresentation)
  public var body: some View
}
```

Target只允許上述13個public declarations：兩個structs、八個properties、兩個initializers、`body`。Fixtures、layout tier、fit layout/policy、accessibility helpers與Preview harness保持internal/private。

## Architecture and Data Flow

```text
Future caller / debug fixture
        ↓ display-ready values
PullRequestRowPresentation
        ↓ immutable input
PullRequestRow
        ├─ native semantic Text hierarchy
        ├─ deterministic width-tier selection
        └─ combined accessibility semantics
```

- Input不等同Domain/Application model。
- Target不import任何BC/integration module。
- 不建立mapper、data loading、state或interaction。
- Future `PullRequestList`才擁有collection、selection、focus與open behavior。

## Layout and Accessibility Contract

### Styling

- Title（原始contract，已由上述Human Review Amendment取代）：`.headline`、`.primary`、最多兩行。
- Identity：`.subheadline`、semantic secondary style、單行tail truncation。
- Context、author/time、metadata：`.caption`、semantic secondary style、單行tail truncation。
- Context/status必須是可讀文字；不只靠色彩。
- 禁止card/custom background/custom accent/custom focus/selection/horizontal scroll。

### Reliable degradation

| Tier | Minimum | Content |
| --- | ---: | --- |
| `full` | `620` | title、identity、context、author/time、metadata |
| `withoutMetadata` | `480` | title、identity、context、author/time |
| `withoutAuthorTime` | `340` | title、identity、context |
| `primaryOnly` | none | title、identity |

- `ViewThatFits(in: .horizontal)`candidate依表列順序。
- 以internal `PullRequestRowFitLayout: Layout`取代會讓content ideal width參與水平fit的`ZStack` probe measurement；不新增public declaration。
- `PullRequestRowFitLayout`與`PullRequestRowLayoutTier.resolve(availableWidth:)`必須從`PullRequestRowLayoutTier`共用既有`620`／`480`／`340` constants，不得複製數值或建立第二套policy。
- Fit layout的internal pure width helper固定回傳`max(proposedWidth, tier.minimumWidth)`；`sizeThatFits`production path與existing layout test呼叫同一helper。`proposal.width == nil`時以`tier.minimumWidth`作為proposed width，`primaryOnly`的minimum為`0`。Content measurement只可決定height及在實際finite available width內的placement，不得讓title、repository或metadata的intrinsic／ideal width擴大reported width。
- Width`680/560/400/300`依序選四級；`620`／`480`／`340`恰好值必須fit，`619`／`479`／`339`必須退到下一tier。相同available width使用short或極長content必須得到相同tier。
- Tier內文字自行tail truncation；不得增加title行數、增加row高度或建立horizontal scrolling。

### Accessibility

- Label包含title、identity、author及存在時context；value包含time及存在時metadata。
- Missing optional values直接省略。
- Visual tier隱藏的author/context仍保留於accessible summary。
- Increase Contrast/inactive leaf appearance依semantic styles。
- Selected state、row position、focus與inactive selected appearancedefer給future List。

## Fixture and Preview Contract

| Fixture | Exact values |
| --- | --- |
| standard | `sample-studio/atlas-desktop#87`；`Clarify offline workspace state`；`atlas-desktop`；`#87`；`Theo North`；`38m`；`Context prepared`；`["priority"]` |
| longTitle | `fixture-labs/long-title#501`；`Preserve keyboard selection while filtering a very long list of pull request results`；`long-title`；`#501`；`Morgan Reed`；`1h`；`Review requested`；`["interface"]` |
| longRepository | `fixture-labs/extraordinarily-long-desktop-workspace-repository#502`；`Keep repository identity readable`；`extraordinarily-long-desktop-workspace-repository`；`#502`；`Sam Lee`；`2h`；`Context available`；`["desktop"]` |
| minimalMetadata | `fixture-labs/minimal-row#503`；`Simplify the empty state copy`；`minimal-row`；`#503`；`Avery Quinn`；`1d`；`nil`；`[]` |
| richMetadata | `example-labs/nebula-ui#142`；`Tighten keyboard movement across command results`；`nebula-ui`；`#142`；`Mira Vale`；`12m`；`Keyboard flow`；`["mentioned", "keyboard"]` |

Five fixtures的ids及repository/number tuples必須唯一，test逐值比對所有literal。`PullRequestRowPreviewFixtures`維持internal且只存在於`#if DEBUG`；test file內建立debug／release都可編譯的expected values，所有configuration都執行expected uniqueness，只有DEBUG branch可讀取fixtures並與expected比對。Release test compilation不得解析或引用fixture symbol。

Preview：

- `Fixture Matrix`：五fixtures、native List、680 points；selection只在debug harness。
- `Degradation Tiers`：rich fixture於680/560/400/300 points。
- `Long Content`：longTitle/longRepository於360 points。
- `Increased Contrast`。
- `Inactive Control State`。

## Durable Writeback

只有target build與focused tests通過後執行。

### README

將「目前狀態」既有兩段完整替換為：

> Rivet 目前是可公開的 architecture baseline repository。它保留產品與架構決策、Bounded Context Map，以及 Swift／Node 版本基線；root Swift package 已包含受限的產品實作。
>
> 目前已實作 non-BC `RivetPresentation` library target 的原生 SwiftUI `PullRequestRow` leaf 與其 display-ready Presentation input。該 target 不依賴任何 Bounded Context，不包含 Domain／Application mapper，也不擁有 `PullRequestList` 的 selection、focus 或 interaction；後續仍以一次一個 Bounded Context 或 bounded Presentation slice 的節奏推進，並以 `analysis/`、`plan/` 與 `docs/` 的配對文件保留可追溯決策。

不得保留舊的「尚未開始任何產品功能實作」或「從`PR Inbox`的第一個最小切片開始實作」。

### Architecture README

將：

> 除其單一架構圖的 artifact-local viewer 可近用性補強外，不建立其他產品功能。

精確替換為：

> Root Swift package 另包含 non-BC `RivetPresentation` target，目前只實作原生 SwiftUI `PullRequestRow` leaf 與其 display-ready Presentation input；該 target 不依賴任何 Bounded Context，不包含 Domain／Application mapper，也不擁有 `PullRequestList` 的 selection、focus 或 interaction。除本文件已列明的受限實作外，不宣稱其他產品能力已完成。

其餘intro、ownership、dependency direction與BC map不變。

### Native interaction contract

在`docs/presentation/native-interaction-contract.md`的「## 8. Window and Resize Contract」→「### Fixed degradation priorities」中，保留既有優先順序並於Inbox row說明後加入：

> `PullRequestRow` title **MUST（必須）**保持單行，寬度不足時使用tail truncation，不得為完整顯示title而增加row高度。Repository／PR identity保持在title的次一層；secondary metadata依full、without metadata、without author/time、title＋identity only順序收斂。`620`／`480`／`340` 是row-local tier thresholds，不是window minimum；candidate是否fit只取決於available width與這三個threshold，不得被title、repository或metadata的ideal width改寫。Tier內文字自行truncate，非diff row **MUST NOT（不得）**產生horizontal scrolling。

這個writeback不新增BC ownership、Domain／Application mapping、public Swift API、List selection／focus或scene／window minimum。

## Test Framework

`Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`使用Swift Testing：

```swift
import Testing
@testable import RivetPresentation

@Suite("PullRequestRow presentation")
struct PullRequestRowPresentationTests { ... }
```

固定tests：

1. `presentationStoresDisplayReadyValues()`
2. `optionalMetadataCanBeAbsent()`
3. `accessibilityTextIncludesRequiredSemantics()`
4. `accessibilityTextOmitsMissingMetadataWithoutPlaceholders()`
5. `previewFixturesHaveUniqueIdentitiesAndAreDeterministic()`
6. `layoutTierBreakpointsFollowDegradationOrder()`

Focused prefix：`RivetPresentationTests.PullRequestRowPresentationTests/`。

Existing static graph compatibility：

- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的`packageDeclaresTheLockedTargetGraph()` products expected set固定為`GitHubIntegration`、`RivetPRInbox`、`RivetPresentation`。
- 同一test的targets expected set固定為`GitHubIntegration`、`GitHubIntegrationTests`、`RivetPRInbox`、`RivetPRInboxTests`、`RivetPresentation`、`RivetPresentationTests`。
- 所有既有entries、integration product mapping、target type/path/dependency assertions與其他test functions逐字保留；不得刪除、改名或放寬。
- 唯讀搜尋只另找到`Tests/RivetPRInboxTests/StaticIsolationTests.swift`的manifest assertions；它們是non-exclusive `contains` checks，negative assertion只禁止`RivetHTTPClient`，因此新增Presentation graph後仍成立。沒有第二個Modify path。

PR #39 comment rework test contract：

- 不新增、刪除或改名上述六個tests，不新增UI／snapshot dependency。
- `previewFixturesHaveUniqueIdentitiesAndAreDeterministic()`的expected values在test file中always-compilable＋debug與release都執行uniqueness assertions；只有`#if DEBUG`內可讀取`PullRequestRowPreviewFixtures.all`並比對actual fixtures。
- `layoutTierBreakpointsFollowDegradationOrder()`直接驗證production `PullRequestRowFitLayout`使用的shared internal tier policy；保留既有680／620／619／560／480／479／400／340／339／300 cases，並加入short與extremely long content在620／480／340及619／479／339的相同fit／tier結果。
- Static graph assertions不擴張；`colorSchemeContrast`的public key path不可寫，保留現行Preview-only作法。

## Implementation Steps

1. PC-01完成四份artifacts materialization；PR-01明示`needs-rework`後，PC-02只修正workspace owner、exact commands/success conditions、TC-06 trace與ledger findings。
2. PR-02明示`needs-rework`後由PC-03補齊validation success semantics；PR-03明示`needs-rework`後由PC-04同步workflow truth；PR-04與PR-05依序明示`approved`後推進同一IM-01。PC-06修正bounded existing-test allowlist gap，PR-06明示`approved`（Findings：None）後同一IM-01 completed；TE-01 automated gate completed，PC-07同步該workflow truth；RV-01 completed／approved（Findings：None）後，PC-08同步final review truth。HC-01於2026-09-21以Human decision原值`採用`完成，PC-09記錄Mission completion。
3. Implementer先修改`Package.swift`建立零dependency target/product/test target。
4. 建立presentation input與accessibility helpers。
5. 建立stateless row、共用tier constants、fit layout與四個ordered candidates。
6. 建立debug fixtures/Previews與六個focused tests。
7. 執行package describe、target build、selector discovery及focused tests；失敗不得改docs。
8. Focused verification通過後，若root test只因既有locked graph expected sets缺少已核准Presentation graph而失敗，先依bounded contract更新`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`，再重跑完整root tests；不得改其他existing test behavior。
9. Root tests通過後，精確替換兩份durable current-state文字。
10. Tester執行所有validation、Preview與TC-01～TC-14。
11. 獨立Reviewer審查scope、contract、evidence；`approved`後停在Human Review。
12. Historical delivery DL-01／DL-02／DL-03已完成；PR #39已Open／Ready，base=`dev`、head=`feat/pr-inbox-pull-request-row`、current head=`7d162aa`。RV-02對PR comments明示`needs-rework`後，PC-12只更新本contract與workflow truth；PR-08是current pending step。
13. PR-08 `needs-rework`已由PC-13修正；PR-09只有`approved`才可路由IM-02。IM-02先在現有fixture test中建立always-compilable expected values與DEBUG-only actual comparison，解除release compile failure，不改fixture file。
14. IM-02再以internal `PullRequestRowFitLayout`讓production candidate fit與`PullRequestRowLayoutTier.resolve`共用單一threshold source，並在現有layout test加入long-content與620／480／340及相鄰boundary regression；不改public API、dependency或test names。
15. Debug與release build/focused/root verification全數通過後，IM-02才在`docs/presentation/native-interaction-contract.md`執行上述bounded writeback，然後完成exact seven-path audit。
16. TE-02獨立驗證後才路由RV-03。只有RV-03 `approved`才可進DL-04 stage／message proposal；DL-04必須停在HC-02 Human exact commit-message confirmation。Human確認後依序執行DL-05 commit、DL-06 push，最後DL-07 reply／resolve已addressed comments。

## Exact Validation Commands

在專用worktree root、PR-06 approved後由同一IM-01恢復執行；先套用bounded static graph compatibility update，再重跑root tests及本節validation。每條Swift command都以`$(pwd)`在runtime產生cache absolute paths，command必須從專用worktree root執行。

```bash
mkdir -p .build/codex-clang-module-cache .build/codex-swiftpm-module-cache
```

Success：exit 0；只建立或重用Git已ignore的`.build/codex-clang-module-cache`與`.build/codex-swiftpm-module-cache`directories，不新增或修改任何tracked path，且後續path/status audit不得出現這兩個directories。

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift package --disable-sandbox describe --type json
```

Success：exit 0，且JSON逐項符合：

- products中恰有library product `RivetPresentation`，其target集合恰為`RivetPresentation`；
- target `RivetPresentation`的path為`Sources/Presentation`，dependencies為empty；
- test target `RivetPresentationTests`的path為`Tests/RivetPresentationTests`，且唯一dependency為`RivetPresentation`；
- 既有target `RivetPRInbox`的path仍為`Sources/BoundedContexts/PRInbox`且dependencies仍為empty；
- 既有target `GitHubIntegration`的path仍為`Sources/BoundedContexts/GitHubIntegration`且dependencies仍為empty；
- 既有test target `RivetPRInboxTests`仍存在且唯一dependency為`RivetPRInbox`；
- 既有test target `GitHubIntegrationTests`仍存在且唯一dependency為`GitHubIntegration`。

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift build --disable-sandbox --target RivetPresentation
```

Success：exit 0，無new-target warning/error。

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift test --disable-sandbox list
```

Success：exit 0；suite prefix下恰有以下六個exact specifiers，且沒有任何其他`RivetPresentationTests.PullRequestRowPresentationTests/`item：

```text
RivetPresentationTests.PullRequestRowPresentationTests/presentationStoresDisplayReadyValues()
RivetPresentationTests.PullRequestRowPresentationTests/optionalMetadataCanBeAbsent()
RivetPresentationTests.PullRequestRowPresentationTests/accessibilityTextIncludesRequiredSemantics()
RivetPresentationTests.PullRequestRowPresentationTests/accessibilityTextOmitsMissingMetadataWithoutPlaceholders()
RivetPresentationTests.PullRequestRowPresentationTests/previewFixturesHaveUniqueIdentitiesAndAreDeterministic()
RivetPresentationTests.PullRequestRowPresentationTests/layoutTierBreakpointsFollowDegradationOrder()
```

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift test --disable-sandbox --filter '^RivetPresentationTests\.PullRequestRowPresentationTests/'
```

Success：六tests執行、零issue/failure。

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift test --disable-sandbox
```

Success：root package全tests零issue/failure。

```bash
find Sources/Presentation Tests/RivetPresentationTests -type f -print
```

Success集合恰為：

```text
Sources/Presentation/PRInbox/PullRequestRow+Previews.swift
Sources/Presentation/PRInbox/PullRequestRow.swift
Sources/Presentation/PRInbox/PullRequestRowPresentation.swift
Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift
```

```bash
rg -n '(RivetPRInbox|GitHubIntegration|InboxItem|ReviewRequestCandidate|PRInboxFacade)' Sources/Presentation/PRInbox/PullRequestRowPresentation.swift Sources/Presentation/PRInbox/PullRequestRow.swift Sources/Presentation/PRInbox/PullRequestRow+Previews.swift Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift
```

Success：無output，且`rg` exit 1代表預期的零match；exit 0或任何其他exit code均為failure。

```bash
rg -n '(@State|@FocusState|Binding<|isSelected|onTapGesture|contextMenu|ScrollView[[:space:]]*\([[:space:]]*\.horizontal|NSViewRepresentable|NSViewControllerRepresentable)' Sources/Presentation/PRInbox/PullRequestRowPresentation.swift Sources/Presentation/PRInbox/PullRequestRow.swift
```

Success：無output，且`rg` exit 1代表預期的零match；exit 0或任何其他exit code均為failure。

```bash
rg -n '^[[:space:]]*public[[:space:]]' Sources/Presentation/PRInbox/PullRequestRowPresentation.swift Sources/Presentation/PRInbox/PullRequestRow.swift Sources/Presentation/PRInbox/PullRequestRow+Previews.swift
```

Success：恰為鎖定13個declarations；Preview零public。

```bash
rg -n '^[[:space:]]*public[[:space:]]' Sources/Presentation/PRInbox/PullRequestRowPresentation.swift Sources/Presentation/PRInbox/PullRequestRow.swift Sources/Presentation/PRInbox/PullRequestRow+Previews.swift | wc -l
```

Success：`13`。

```bash
rg -n '(尚未開始任何產品功能實作|從 `PR Inbox` 的第一個最小切片開始實作|不建立其他產品功能)' README.md docs/architecture/README.md
```

Success：無output，且`rg` exit 1代表預期的零match；exit 0或任何其他exit code均為failure。

```bash
rg -n '(RivetPresentation|PullRequestRow|不依賴任何 Bounded Context|不包含 Domain／Application mapper|不擁有 `PullRequestList` 的 selection、focus 或 interaction)' README.md docs/architecture/README.md
```

Success：`README.md`與`docs/architecture/README.md`兩者都含本plan「Durable Writeback」鎖定的完整replacement；Reviewer逐字比對replacement，不能只以部分keyword match代替。

```bash
git diff --name-status
```

Success集合恰為：

```text
M	Package.swift
M	README.md
M	Tests/GitHubIntegrationTests/StaticIsolationTests.swift
M	docs/architecture/README.md
```

Success：忽略output order後恰為上述4個tracked paths；不得缺少或新增其他tracked path。

```bash
git diff --check
```

Success：exit 0且無output。

```bash
git status --short --untracked-files=all
```

Success集合恰為：

```text
 M Package.swift
 M README.md
 M Tests/GitHubIntegrationTests/StaticIsolationTests.swift
 M docs/architecture/README.md
?? Sources/Presentation/PRInbox/PullRequestRow+Previews.swift
?? Sources/Presentation/PRInbox/PullRequestRow.swift
?? Sources/Presentation/PRInbox/PullRequestRowPresentation.swift
?? Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift
?? analysis/pr-inbox-pull-request-row/requirements.md
?? analysis/pr-inbox-pull-request-row/technical-spec.md
?? plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md
?? plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md
```

Success：忽略output order後恰為12個entries，即上述4個tracked modifications與既有8個untracked files；不得缺少或新增其他path。

八個untracked files逐一執行：

```bash
git diff --no-index --check /dev/null analysis/pr-inbox-pull-request-row/requirements.md
git diff --no-index --check /dev/null analysis/pr-inbox-pull-request-row/technical-spec.md
git diff --no-index --check /dev/null plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md
git diff --no-index --check /dev/null plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md
git diff --no-index --check /dev/null Sources/Presentation/PRInbox/PullRequestRowPresentation.swift
git diff --no-index --check /dev/null Sources/Presentation/PRInbox/PullRequestRow.swift
git diff --no-index --check /dev/null Sources/Presentation/PRInbox/PullRequestRow+Previews.swift
git diff --no-index --check /dev/null Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift
```

Success：每條command可因content不同而exit 1，但八條均不得輸出任何whitespace diagnostic。

### PR #39 comment rework validation

本節只在PR-09 `approved`後，由IM-02／TE-02從專用worktree root執行。先執行上述cache preparation、package describe、debug target build、test list、debug focused tests與debug root tests，且各項仍須符合原success semantics。接著執行：

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift build --disable-sandbox -c release --target RivetPresentation
```

Success：exit 0，`RivetPresentation`在release configuration完成編譯，無fixture visibility或layout implementation error。

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift test --disable-sandbox -c release --filter '^RivetPresentationTests\.PullRequestRowPresentationTests/'
```

Success：exit 0，固定六個existing tests全數執行且零issue／failure；release compilation沒有解析DEBUG-only `PullRequestRowPreviewFixtures`。

```bash
env CLANG_MODULE_CACHE_PATH="$(pwd)/.build/codex-clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(pwd)/.build/codex-swiftpm-module-cache" swift test --disable-sandbox -c release
```

Success：exit 0，root package在release configuration的全數discovered tests零issue／failure；不得以縮小test selection取代。

```bash
rg -n '(PullRequestRow|620|480|340|ideal width|horizontal scroll)' docs/presentation/native-interaction-contract.md
```

Success：exit 0；Reviewer必須在§8 Fixed degradation priorities逐字比對本plan的完整bounded amendment，不可只以keyword match代替，且diff不得改變BC ownership、List interaction或scene constraints。

```bash
git diff --name-only
```

Success：忽略output order後恰為以下七個paths，不得缺少或多出任何path：

```text
Sources/Presentation/PRInbox/PullRequestRow.swift
Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift
analysis/pr-inbox-pull-request-row/requirements.md
analysis/pr-inbox-pull-request-row/technical-spec.md
docs/presentation/native-interaction-contract.md
plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md
plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md
```

```bash
git diff --check
```

Success：exit 0且無output。

Reviewer另須確認`Package.swift`、`Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`、`Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`、`Tests/RivetPRInboxTests/StaticIsolationTests.swift`、`README.md`與`docs/architecture/README.md`本cycle無diff；static graph無擴張、Preview fixtures仍為DEBUG-only，public declaration count仍為13。

## Test Cases

| ID | Scenario | Expected result | Verification | Trace |
| --- | --- | --- | --- | --- |
| TC-01 | Checkout/target boundary | Branch/worktree/baseline正確；Presentation零dependency；既有targets與dependencies不變；locked graph expected sets保留既有entries並加入Presentation product/target/test target | preflight、package describe、build、`packageDeclaresTheLockedTargetGraph()` | Human branch/worktree lock；design principles；existing static graph contract |
| TC-02 | Full presentation value | Fields/equality/hash deterministic | `presentationStoresDisplayReadyValues()` | Draft §4.2；UIIR-NI-003 local identity |
| TC-03 | Optional metadata absent | 無placeholder/假零值/空separator | `optionalMetadataCanBeAbsent()`＋Preview | Draft §§4.1/4.3/4.6；native §8 |
| TC-04 | Required accessibility | title/identity/author/time/context可讀；不偽造selected/position | `accessibilityTextIncludesRequiredSemantics()` | Draft §4.6；F-01 row-owned identity/title、§10 |
| TC-05 | Missing-data a11y | Missing metadata省略；visual degradation不刪a11y | `accessibilityTextOmitsMissingMetadataWithoutPlaceholders()` | Draft §§4.1/4.3/4.6；native §§8/10 |
| TC-06 | Fixture literals/uniqueness | 五列逐值相等；ids/tuples unique；release test compilation不引用DEBUG-only fixture symbol | 同名fixture test的always-compilable expected values、DEBUG-only actual comparison、debug／release focused tests | `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`的Inbox Fixtures；`plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`的HC-03；`prototypes/pr-inbox-static-visual-prototype/index.html`僅為pending、non-normative visual evidence |
| TC-07 | Native appearance | 無card/custom selection；hierarchy清楚 | Fixture Matrix Human review | Draft §§3/4.1/4.5；native §7 |
| TC-08 | Tier trigger | 680/560/400/300依序四級；production fit path與tested policy共用constants；620/480/340 fit、619/479/339降級 | 現有tier test＋Preview＋Reviewer source inspection | native §8、AC-NI-016/017 row portion |
| TC-09 | Long content/no scroll | Short／極長content在相同width選同一tier；primary info preserved；無horizontal scroll | 現有tier test的long-content boundary cases＋Long Content＋source inspection | native §8、AC-NI-016/017 |
| TC-10 | Non-color/semantic state | Status文字化；Increase Contrast/inactive leaf正常 | environment previews＋review | native §§7/10、AC-NI-026/027/035/036 |
| TC-11 | Selection/focus boundary | Leaf沒有state/bindings/actions/custom focus | source/API audit | F-01/F-02、native §7、AC-NI-001/009/014 defer |
| TC-12 | Coupling/public API | 無BC/mapper；恰13 public declarations | describe/search/API count | Architecture/BC docs；Draft §§5/7 |
| TC-13 | Durable truth replacement | README／architecture既有truth保持；native §8加入鎖定row contract且無ownership drift | positive search＋exact diff review | README/architecture current state；native §8 Fixed degradation priorities |
| TC-14 | Regression/path isolation | Debug/release focused與root tests零failure；本cycle diff恰為七個allowlist paths；13 public declarations、six test names、static graph與DEBUG-only Preview file不變 | debug/release commands、diff/whitespace/API/test-list audits、Reviewer inspection | Admission Schema；Draft §§11/13；RV-02 T-01～T-05 |

### PR #39 comment rework acceptance

| Finding | Required result | Evidence |
| --- | --- | --- |
| T-01／T-03 | Fixtures維持DEBUG-only；release test target以always-compilable expected values執行uniqueness，不引用fixture symbol | Existing fixture test source review；release focused／root tests exit 0 |
| T-02 | Production `ViewThatFits` candidate與existing tier test共用`PullRequestRowLayoutTier`的620／480／340 decision source，無第二policy | Existing layout test；Reviewer比對production/test source |
| T-04 | Content ideal width不影響candidate fit；620／480／340及619／479／339在short／long content結果相同；tier內truncate且無horizontal scroll | Existing layout test的boundary/long-content regression；debug／release focused tests |
| T-05 | Native contract §8含完整bounded row writeback，無新檔案、BC ownership或scene constraint | Exact doc diff與positive search |
| Locked nonessential findings | Static graph無擴張；`colorSchemeContrast`不寫public key path；Preview-only作法保留 | Seven-path audit與Reviewer inspection |

## Workflow Gate

- Upstream Planner：`approved`。
- PC-01：`completed`；只代表四份artifacts存在且已由Plan-Creator自檢。
- PR-01：`needs-rework`；findings限於workspace owner、command/success contract、TC-06 trace與ledger狀態。
- PC-02：`completed`；只代表上述findings已回修，不構成planning approval。
- PR-02：`needs-rework`；findings限於cache preparation、test list、三個no-match gates與`git diff --check`的success semantics。
- PC-03：`completed`；只代表上述findings已回修，不構成planning approval。
- PR-03：`needs-rework`；finding為四份planning artifacts的current workflow truth未同步。
- PC-04：`completed`；只同步workflow state，不變更已鎖定contract且不構成planning approval。
- PR-04：`approved`；依此verdict進入IM-01。
- IM-01 historical pause（已由PC-05／PR-05解除）：runtime preflight的相對`SWIFTPM_MODULECACHE_OVERRIDE`使SwiftPM在compile前exit 1。此為validation-contract flaw，不是code failure；當時partial implementation保持原狀。
- PC-05：`completed`；只修正五條Swift commands的runtime absolute cache paths並同步workflow state，不構成planning approval。
- PR-05：`approved`；同一IM-01據此從red setup恢復。
- IM-01 historical pause（已由PC-06／PR-06解除）：focused六tests與package describe/build/test-list均通過，root 70 tests唯一failure是既有locked graph expected sets缺少已核准Presentation graph。這是bounded existing-test allowlist gap，不是product failure；README/docs當時未動。
- PC-06：`completed`；只新增exact compatibility Modify path、鎖定expected-set update、同步TC/path audits與workflow state，不構成planning approval。
- PR-06：`approved`；Findings：None。同一IM-01據此恢復。
- IM-01：`completed`；完成red-green、focused 6/6、root 70/70、bounded compatibility test update、durable docs writeback與automated path/API/docs audits；不宣稱Human visual或VoiceOver pass。
- TE-01：`completed`；Overall PASS automated。TC-07以及TC-03/04/05/08/09/10的明示Human visual／VoiceOver portions pending，不是automated failure。
- PC-07：`completed`；只同步workflow truth，不變更contract且不構成approval。
- RV-01：`completed`，明示verdict為`approved`，Findings：None；Reviewer確認focused 6/6、root 70/70，以及scope/path/API/layout/fixtures/accessibility/docs皆pass。Human visual／VoiceOver checklist仍pending。
- PC-08：`completed`；只同步final workflow truth，不變更contract且不構成Reviewer approval；Reviewer approval evidence只來自RV-01 explicit result。
- HC-01：`completed`，owner為Human；Human decision原值為`採用`，date為2026-09-21。Human確認doc-only amendment已正確同步final accepted behavior：title固定單行、tail truncation、不增加row高度、repository／PR identity維持次層、secondary metadata依既有tiers收斂，且沒有horizontal scrolling。
- PC-09：`completed`；只記錄final Human decision與Mission completion，不變更contract且不產生verdict；completion authority只來自Human `採用`。
- Topic／Mission：`completed`，沒有product blocker或HC-01 decision pending。Human另行授權post-completion delivery；HC-01的`採用`不等同commit-message confirmation。
- PC-10：`completed`；只同步delivery workflow truth，不變更product contract且不產生verdict。
- PR-07：`approved`，Findings：None；獨立Plan-Reviewer只審delivery workflow truth，未重開single-line title、其他product contract、test／Reviewer evidence或path allowlist。
- PC-11：`completed`；只同步PR-07 explicit result與當時DL-01 state，不產生verdict。
- DL-01／DL-02／DL-03：`completed`；已完成stage／Human message gate、commit／push與Ready PR creation。PR #39為Open／Ready，base=`dev`、head=`feat/pr-inbox-pull-request-row`、current head=`7d162aa`。
- RV-02：`needs-rework`；T-01／T-03是同一release compile failure，T-02要求shared production/test decision source，T-04要求content-independent fit thresholds與boundary regression，T-05要求bounded native-contract writeback。
- PC-12：`completed`；只materialize bounded PR-comment amendment與truthful workflow state，不產生verdict。
- PR-08：`needs-rework`；findings只限historical doc-only scope標示與一處「執行」文字誤植。
- PC-13：`completed`；只修正PR-08兩項findings並同步workflow truth，不產生verdict。
- PR-09：`approved`，Findings：None。
- IM-02：`completed`；red release fixture／layout seam後green，debug／release builds、focused 6/6、root 70/70、precommit／path／API audits均通過，diff恰為七個allowlist paths。
- TE-02：explicit verdict=`approved`；獨立驗證同evidence。Human-only Preview／VoiceOver仍為pending，但不是automated blocker。
- PC-14：`completed`；只同步workflow truth，不產生verdict。
- RV-03：`pending`，current step為獨立Reviewer。
- DL-04／HC-02／DL-05／DL-06／DL-07：`pending`；只有RV-03 `approved`才能依stage／message proposal → Human exact message confirmation → commit → push／head verification → reply／resolve addressed comments的順序執行。

## Post-Completion External Delivery

- Human authorization原值：`可以 commit -> push -> Open Ready PR`；date：2026-09-21。
- Ready PR固定base=`dev`、head=`feat/pr-inbox-pull-request-row`，且必須為Ready而非Draft。
- DL-01／DL-02／DL-03 status=`completed`；PR #39已為Open／Ready，current head=`7d162aa`。
- Human對PR comment cycle的授權順序固定為comment review／bounded fix → Tester → independent Reviewer → stage／message proposal → Human exact commit-message confirmation → commit → push → reply／resolve addressed comments。
- DL-04（Implementer）status=`pending`：只有RV-03 `approved`後，才可確認working tree只含七個rework exact paths、stage該七個paths，依`git-commit-convention`檢查single semantic boundary並提出message；然後停止。
- HC-02（Human）status=`pending`：只能對DL-04實際提出的exact message明確確認；HC-01 `採用`、既有delivery authorization或舊commit message均不構成本次確認。
- DL-05（Implementer）status=`pending`：HC-02完成後才可使用Human-confirmed exact message建立commit。
- DL-06（Implementer）status=`pending`：DL-05完成後才可push `feat/pr-inbox-pull-request-row`，並驗證local HEAD與remote branch head一致。
- DL-07（Implementer）status=`pending`：DL-06成功且evidence完整後，只回覆並resolve已由本bounded fix address的PR comments；未addressed或新finding不得假裝resolved。
- 不授權merge、release、tag、branch deletion、worktree removal或自動開始`PullRequestList`／下一Mission。

## Human Review

Human原可選：

- 採用：Mission完成；只允許另開下一bounded Mission。
- 調整：回本topic planning/implementation routing並重跑gates。
- 放棄：停止，不展開下一Mission。

Human至少檢查五個fixture matrix、四級degradation、long content、Increase Contrast／inactive-window appearance、VoiceOver semantics，以及leaf沒有偽造selected／focused semantics；並確認standard hierarchy、density、13 public declarations與一致durable truth。

HC-01已於2026-09-21完成；Human decision原值為`採用`。Human-only Preview／VoiceOver仍為pending，但不是automated blocker。HC-02只是PR-comment fix的exact commit-message gate，現在尚未到該boundary；current step為RV-03。

## Assumptions

- Human authorization與專用worktree preparation已完成；Plan-Creator未執行Git。
- PR-09已`approved`（Findings：None），IM-02 completed，TE-02 explicit verdict=`approved`。PC-14只同步workflow truth、不產生verdict；RV-03為current pending step。
- `620/480/340`是本leaf可測breakpoints，不是window minimum。
- Preview selection不是product List acceptance。
- 本cycle可修改的七個exact paths已鎖定；任何額外path、新檔案、BC dependency、mapper、List interaction、13-public-API變更或architecture reopening都停止並回planning。

## Last Updated

2026-09-21
