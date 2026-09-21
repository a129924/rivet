# PR Inbox / Pull Request Row：Implementation Plan

## Summary

建立第一個production-quality native SwiftUI Presentation leaf：`PullRequestRow`。新增獨立`RivetPresentation` SwiftPM library product/target，以純Presentation input驅動row、debug-only fixtures與SwiftUI Preview；不依賴`RivetPRInbox`、不建立Domain/Application mapper，也不實作List、selection、Reader或其他Inbox hierarchy。

Human已明示「可以實現」。正式branch鎖定為`feat/pr-inbox-pull-request-row`，implementation只可在Human/operator已準備並attach的專用worktree進行。Baseline HEAD/local `dev`/`origin/dev`均為`579e67b6db650218078e3383365e40cf08a5e641`，PC-01前已驗證clean且branch唯一attach。Plan-Creator未執行Git。

Topic／Mission status維持`completed`，HC-01 decision維持`採用`。Human於2026-09-21另以原值`可以 commit -> push -> Open Ready PR`授權post-completion external delivery；PR-07已`approved`（Findings：None），PC-11 completed，current delivery step為DL-01 current／pending，Human exact commit-message confirmation pending。

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
| `docs/presentation/native-interaction-contract.md` | Native behavior/degradation authority |
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
| `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | 只在`packageDeclaresTheLockedTargetGraph()`的既有products/targets expected sets加入已核准Presentation graph；其餘assertions/tests不變 |

### Deleted

None。

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

Target只允許上述13個public declarations：兩個structs、八個properties、兩個initializers、`body`。Fixtures、layout tier、fit probe、accessibility helpers與Preview harness保持internal/private。

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
- 前三級各用zero-height、accessibility-hidden fit probe，放在同一`ZStack`並以minimum width實際影響measurement。
- Probe不得是background/overlay。
- `resolve(availableWidth:)`與probe共用同一constants。
- Width`680/560/400/300`依序選四級；邊界`619/620`、`479/480`、`339/340`必須測試。

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

Five fixtures的ids及repository/number tuples必須唯一，test逐值比對所有literal。

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

## Implementation Steps

1. PC-01完成四份artifacts materialization；PR-01明示`needs-rework`後，PC-02只修正workspace owner、exact commands/success conditions、TC-06 trace與ledger findings。
2. PR-02明示`needs-rework`後由PC-03補齊validation success semantics；PR-03明示`needs-rework`後由PC-04同步workflow truth；PR-04與PR-05依序明示`approved`後推進同一IM-01。PC-06修正bounded existing-test allowlist gap，PR-06明示`approved`（Findings：None）後同一IM-01 completed；TE-01 automated gate completed，PC-07同步該workflow truth；RV-01 completed／approved（Findings：None）後，PC-08同步final review truth。HC-01於2026-09-21以Human decision原值`採用`完成，PC-09記錄Mission completion。
3. Implementer先修改`Package.swift`建立零dependency target/product/test target。
4. 建立presentation input與accessibility helpers。
5. 建立stateless row、共用tier constants、fit probes與四個ordered candidates。
6. 建立debug fixtures/Previews與六個focused tests。
7. 執行package describe、target build、selector discovery及focused tests；失敗不得改docs。
8. Focused verification通過後，若root test只因既有locked graph expected sets缺少已核准Presentation graph而失敗，先依bounded contract更新`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`，再重跑完整root tests；不得改其他existing test behavior。
9. Root tests通過後，精確替換兩份durable current-state文字。
10. Tester執行所有validation、Preview與TC-01～TC-14。
11. 獨立Reviewer審查scope、contract、evidence；`approved`後停在Human Review。

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

## Test Cases

| ID | Scenario | Expected result | Verification | Trace |
| --- | --- | --- | --- | --- |
| TC-01 | Checkout/target boundary | Branch/worktree/baseline正確；Presentation零dependency；既有targets與dependencies不變；locked graph expected sets保留既有entries並加入Presentation product/target/test target | preflight、package describe、build、`packageDeclaresTheLockedTargetGraph()` | Human branch/worktree lock；design principles；existing static graph contract |
| TC-02 | Full presentation value | Fields/equality/hash deterministic | `presentationStoresDisplayReadyValues()` | Draft §4.2；UIIR-NI-003 local identity |
| TC-03 | Optional metadata absent | 無placeholder/假零值/空separator | `optionalMetadataCanBeAbsent()`＋Preview | Draft §§4.1/4.3/4.6；native §8 |
| TC-04 | Required accessibility | title/identity/author/time/context可讀；不偽造selected/position | `accessibilityTextIncludesRequiredSemantics()` | Draft §4.6；F-01 row-owned identity/title、§10 |
| TC-05 | Missing-data a11y | Missing metadata省略；visual degradation不刪a11y | `accessibilityTextOmitsMissingMetadataWithoutPlaceholders()` | Draft §§4.1/4.3/4.6；native §§8/10 |
| TC-06 | Fixture literals/uniqueness | 五列逐值相等；ids/tuples unique | fixture test | `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`的Inbox Fixtures；`plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`的HC-03；`prototypes/pr-inbox-static-visual-prototype/index.html`僅為pending、non-normative visual evidence |
| TC-07 | Native appearance | 無card/custom selection；hierarchy清楚 | Fixture Matrix Human review | Draft §§3/4.1/4.5；native §7 |
| TC-08 | Tier trigger | 680/560/400/300依序四級；boundaries正確 | tier test＋Preview | native §8、AC-NI-016/017 row portion |
| TC-09 | Long content/no scroll | Primary info preserved；無horizontal scroll | Long Content＋source search | native §8、AC-NI-016/017 |
| TC-10 | Non-color/semantic state | Status文字化；Increase Contrast/inactive leaf正常 | environment previews＋review | native §§7/10、AC-NI-026/027/035/036 |
| TC-11 | Selection/focus boundary | Leaf沒有state/bindings/actions/custom focus | source/API audit | F-01/F-02、native §7、AC-NI-001/009/014 defer |
| TC-12 | Coupling/public API | 無BC/mapper；恰13 public declarations | describe/search/API count | Architecture/BC docs；Draft §§5/7 |
| TC-13 | Durable truth replacement | Stale文句移除；locked replacement；無architecture drift | grep/diff/review | README/architecture current state |
| TC-14 | Regression/path isolation | 六focused與root 70 tests零failure；tracked set恰4、untracked set恰8、status恰12 entries；existing static graph只做bounded expected-set update | root command、diff/status/whitespace、Reviewer diff inspection | Admission Schema；Draft §§11/13；existing static graph contract |

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
- PC-11：`completed`；只同步PR-07 explicit result與DL-01 current state，不變更product/path/commands/tests/evidence或delivery authorization，且不產生verdict。

## Post-Completion External Delivery

- Human authorization原值：`可以 commit -> push -> Open Ready PR`；date：2026-09-21。
- Ready PR固定base=`dev`、head=`feat/pr-inbox-pull-request-row`，且必須為Ready而非Draft。
- DL-01（Implementer）status=`current／pending`：
  1. Preflight確認仍位於專用worktree與`feat/pr-inbox-pull-request-row`，working tree只含既有Exact Path Contract的8個Written paths及4個Modify paths，沒有ReadOnly、Deleted或額外path。
  2. 只stage上述12個exact paths。
  3. 依`git-commit-convention`唯讀檢查staged diff是否為single semantic boundary、是否混入無關變更，並提出`<type>(<scope>): <繁體中文摘要>`格式的message。
  4. 停止並等待Human明確確認message；不得在DL-01 commit或push。
- Human exact commit-message confirmation status=`pending`。HC-01的`採用`與本次external delivery authorization都不等同message確認。
- DL-02（Implementer）status=`pending`：只有Human明確確認message後，才可使用該message建立commit並push `feat/pr-inbox-pull-request-row`。
- DL-03（Implementer）status=`pending`：只有push成功且local/remote heads一致後，才可建立Ready（非Draft）PR，base=`dev`、head=`feat/pr-inbox-pull-request-row`，並回報PR URL。
- 不授權merge、release、tag、branch deletion、worktree removal或自動開始`PullRequestList`／下一Mission。

## Human Review

Human原可選：

- 採用：Mission完成；只允許另開下一bounded Mission。
- 調整：回本topic planning/implementation routing並重跑gates。
- 放棄：停止，不展開下一Mission。

Human至少檢查五個fixture matrix、四級degradation、long content、Increase Contrast／inactive-window appearance、VoiceOver semantics，以及leaf沒有偽造selected／focused semantics；並確認standard hierarchy、density、13 public declarations與一致durable truth。

HC-01已於2026-09-21完成；Human decision原值為`採用`。Human確認本文件的doc-only amendment已正確同步final accepted behavior；HC-01沒有pending decision。另行delivery workflow的commit-message confirmation仍pending。

## Assumptions

- Human authorization與專用worktree preparation已完成；Plan-Creator未執行Git。
- PR-06已`approved`（Findings：None），IM-01與TE-01 automated gate均completed。RV-01已明示`approved`（Findings：None）；HC-01已由Human以`採用`完成，Topic／Mission維持completed。PR-07 workflow-only review已`approved`（Findings：None）；PC-11只同步workflow truth，不產生verdict。DL-01 current／pending，Human exact commit-message confirmation pending。
- `620/480/340`是本leaf可測breakpoints，不是window minimum。
- Preview selection不是product List acceptance。
- 任何新增path、BC dependency、mapper、List interaction或architecture reopening都停止並回planning。

## Last Updated

2026-09-21
