# PR Inbox / Pull Request Row：需求

## Topic

- Slug：`pr-inbox-pull-request-row`
- Ownership：non-BC Presentation
- Base branch：`dev`
- Work branch：`feat/pr-inbox-pull-request-row`
- Implementation environment：Human/operator 準備並 attach 的專用 worktree
- Status：Product acceptance與HC-01 `採用`維持completed。DL-01、DL-02、DL-03已完成；PR #39為Open／Ready，base=`dev`、head=`feat/pr-inbox-pull-request-row`、current head=`7d162aa`。PR-09已`approved`（Findings：None），IM-02 completed，TE-02 explicit verdict=`approved`；PC-14已完成workflow sync，current step為RV-03 pending。

## Goal

建立第一個 production-quality native SwiftUI Presentation leaf：`PullRequestRow`。元件必須能獨立 build、test、Preview 與 Human Review，並呈現：

- PR title
- repository／PR identity
- author
- relative time
- optional context／status
- optional secondary metadata

Row 在寬度受限時必須依 title、repository／PR identity、context、author、secondary metadata 的既定優先序逐級退化，且不得建立水平捲動。

## Non-Goal

- 不實作 `PullRequestList`、Inbox workspace/header/sidebar/filter、Reader 或其他 Inbox hierarchy。
- 不擁有 selection、focus、keyboard navigation、Open Reader、context menu、loading/error/offline 或 workspace state。
- 不修改 PR Inbox、PR Reader、GitHubIntegration production code、networking、persistence 或 business logic；唯一例外是更新既有static isolation test的locked graph expected sets。
- 不建立 `InboxItem`／Domain／Application 到 Presentation 的 production mapper、initializer 或 target dependency。
- 不把 HTML/CSS pixel、prototype fixture schema 或 Preview fixture 當成產品 contract 或 production data source。
- 不新增通用 design system、AppKit bridge、scene/window minimum width或其他 future Inbox component。
- 不宣稱完成 native interaction contract 的 List selection/focus、inactive selected appearance或Open Reader acceptance。
- Product Mission本身不授權merge、release、tag、branch deletion、worktree removal或下一Mission；commit、push與Ready PR只可依下列post-completion external delivery authorization執行。

## In-Scope

- Root Swift package 的 `RivetPresentation` library product、同名source target與`RivetPresentationTests` test target。
- Public、display-ready、Presentation-owned `PullRequestRowPresentation` value type。
- Public、stateless `PullRequestRow` SwiftUI view。
- 可靠可觸發的四級width degradation：full、drop metadata、drop author/time、title＋identity only。
- Debug-only deterministic fixtures：standard、long title、long repository、minimal metadata、rich metadata。
- SwiftUI Preview：fixture matrix、四級degradation、long content、Increase Contrast與inactive control state。
- Swift Testing focused suite、root package regression、source/path/API/dependency isolation checks。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的bounded compatibility update：只把已核准的`RivetPresentation` product/target/test target加入既有locked graph expected sets，保留所有既有entries與assertions。
- 實作完成且focused verification通過後，精確替換 `README.md` 與 `docs/architecture/README.md` 的stale current-state文字。
- PR #39 comment rework：修正release test compilation、讓production fit path與tested policy共享同一決策來源、讓長內容不改寫620／480／340 tier threshold，並bounded回寫既有`docs/presentation/native-interaction-contract.md`。

## Product and Architecture Boundary

- 本 Mission 屬 non-BC Presentation，不改變 PR Inbox 對membership/sorting、PR Reader對閱讀資料或Presentation Session對selection的ownership。
- `RivetPresentation` 不依賴 `RivetPRInbox`、`GitHubIntegration` 或任何其他BC target。
- Presentation input只承載已準備好的display strings與presentation-local identity；不得迫使Domain/Application採用同一shape。
- Future parent `PullRequestList` 才擁有collection、selection、focus、keyboard/open interaction與native selected-row semantics。
- 本 Mission 不建立正式 Domain/Application mapping。

## Required Presentation Behavior

### Information hierarchy

- Title固定單行，使用native semantic headline；空間不足時使用tail truncation，不得為了完整顯示title而讓row垂直擴張。
- Repository與PR number構成不可拆散的主要identity；可以尾端截斷，但完整值必須保留於accessibility semantics。
- Context/status以可讀文字呈現，不得只靠顏色或icon color。
- Author/time與secondary metadata使用native secondary/caption semantics。
- 不建立SaaS card、rounded container、自繪selection background、自訂accent或horizontal `ScrollView`。

### Width degradation

四級breakpoints固定為：

| Minimum width | Tier | Visible information |
| ---: | --- | --- |
| `620` | `full` | title、identity、context、author/time、secondary metadata |
| `480` | `withoutMetadata` | title、identity、context、author/time |
| `340` | `withoutAuthorTime` | title、identity、context |
| none | `primaryOnly` | title、identity |

Implementation必須讓internal fit layout與`PullRequestRowLayoutTier`共用同一組620／480／340 constants。Candidate回報給`ViewThatFits`的水平fit width只由available width與該tier minimum決定；title、identity或metadata的intrinsic／ideal width不得參與candidate acceptance。Tier內文字在實際available width自行tail truncation，不得改寫threshold、增加row高度或建立horizontal scrolling。

### Accessibility

- Accessible representation至少包含title、repository／PR identity、author、relative time，以及存在時的context/status。
- Secondary metadata存在時才加入accessibility value；缺少時直接省略，不顯示placeholder、假零值或多餘separator。
- 視覺因width tier隱藏的author/context仍須保留在accessible semantics。
- Selected state與list row position由future parent List提供；leaf不得偽造。

## Fixture Requirements

五個fixtures必須deterministic，且`id`與repository/number tuple皆唯一：

| Fixture | Exact values |
| --- | --- |
| `standard` | id `sample-studio/atlas-desktop#87`；title `Clarify offline workspace state`；repo `atlas-desktop`；number `#87`；author `Theo North`；time `38m`；context `Context prepared`；metadata `priority` |
| `longTitle` | id `fixture-labs/long-title#501`；title `Preserve keyboard selection while filtering a very long list of pull request results`；repo `long-title`；number `#501`；author `Morgan Reed`；time `1h`；context `Review requested`；metadata `interface` |
| `longRepository` | id `fixture-labs/extraordinarily-long-desktop-workspace-repository#502`；title `Keep repository identity readable`；repo `extraordinarily-long-desktop-workspace-repository`；number `#502`；author `Sam Lee`；time `2h`；context `Context available`；metadata `desktop` |
| `minimalMetadata` | id `fixture-labs/minimal-row#503`；title `Simplify the empty state copy`；repo `minimal-row`；number `#503`；author `Avery Quinn`；time `1d`；context `nil`；metadata `[]` |
| `richMetadata` | id `example-labs/nebula-ui#142`；title `Tighten keyboard movement across command results`；repo `nebula-ui`；number `#142`；author `Mira Vale`；time `12m`；context `Keyboard flow`；metadata `mentioned`、`keyboard` |

`PullRequestRowPreviewFixtures`必須維持internal且只存在於`#if DEBUG`。既有fixture test名稱不變；expected values必須在test file中always-compilable，release build不得引用fixture symbol，只有DEBUG branch比對actual fixtures與expected values。

## Success Criteria

- `RivetPresentation` product/target可獨立build，且沒有BC或integration dependency。
- `PullRequestRowPresentation`與`PullRequestRow`只有已鎖定的13個public declarations。
- Row不擁有state、selection、focus、gesture、action、context menu或horizontal scroll。
- Width tier在`680/560/400/300` points依序呈現full／withoutMetadata／withoutAuthorTime／primaryOnly。
- 五個fixtures逐值符合contract，ids與repository/number tuples唯一。
- Focused六個Swift Testing tests與root 70 tests通過；既有locked graph test保留全部既有entries/assertions，並包含`RivetPresentation`、`RivetPresentationTests`。
- Debug與release configuration都能編譯並執行同一組六個既有test names；release test target不引用DEBUG-only fixtures。
- Production `ViewThatFits` path與既有`layoutTierBreakpointsFollowDegradationOrder()`共享internal fit decision source；長title／repository ideal width不得改變620／480／340 boundary結果。
- Preview可檢視standard、long title、long repository、minimal、rich、Increase Contrast與inactive leaf style。
- `README.md`與architecture README的stale current-state敘述被精確替換，沒有矛盾或architecture drift。
- `docs/presentation/native-interaction-contract.md`以bounded amendment記錄已採用row contract：單行tail truncation、不增加row高度、identity次層、metadata依tiers收斂、620／480／340為row-local thresholds、content ideal width不影響tier selection、無horizontal scrolling；不改BC ownership。
- Exact path audit只包含本topic allowlist。
- Tester完成驗證、獨立Reviewer明示verdict後停止於Human Review。

## Source Authority

1. `docs/presentation/native-interaction-contract.md`：native observable behavior、row degradation與accessibility authority。
2. `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`的Inbox Fixtures，以及`plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`的HC-03「採用」evidence。
3. `prototypes/pr-reader-interactive-ux-prototype/index.html`：只作已採用Inbox row內容/行為的actual prototype source。
4. `prototypes/pr-inbox-static-visual-prototype/index.html`：pending、non-normative visual evidence，不得升格為adopted contract。
5. Human鎖定的第四版conversation implementation plan、branch與專用worktree決策。
6. `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的排他products/targets集合，以及`Tests/RivetPRInboxTests/StaticIsolationTests.swift`的non-exclusive manifest assertions。唯讀搜尋確認後者不受新增Presentation graph影響，沒有第二個Modify path。

## Workflow and Human Check

- Upstream Planner verdict：`approved`。
- PC-01：completed，只表示四份artifacts已materialize，不構成planning approval。
- PR-01：`needs-rework`；findings限於workspace preparation owner、exact command/success contract、TC-06 exact trace與ledger狀態。
- PC-02：completed，只修正PR-01 findings，不構成planning approval。
- PR-02：`needs-rework`；PC-03：completed，只補齊validation success semantics，不構成planning approval。
- PR-03：`needs-rework`；finding為四份planning artifacts的current workflow truth未同步。
- PC-04：completed，只同步workflow state，不變更scope、API、paths、commands或design，亦不構成planning approval。
- PR-04：`approved`；依此verdict進入IM-01。
- IM-01 historical pause（已由PC-05／PR-05解除）：Runtime preflight發現相對`SWIFTPM_MODULECACHE_OVERRIDE`不是合法absolute path，SwiftPM在compile前exit 1；這是validation-contract flaw，不是code failure。當時partial implementation只包含`Package.swift`、`Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`六-test file與empty `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift` sentinel；docs與其餘production code未動。
- PC-05：completed，只把每條Swift command的兩個cache paths改為由worktree root的`$(pwd)`產生runtime absolute paths，並同步workflow state；不構成planning approval。
- PR-05：`approved`；同一IM-01據此從red setup恢復。
- IM-01 historical pause（已由PC-06／PR-06解除）：Focused六tests與package describe/build/test-list均通過；root `swift test`執行70 tests，唯一failure為`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的`packageDeclaresTheLockedTargetGraph()`仍排他地期待舊product/target集合。這是bounded existing-test allowlist gap，不是product failure；README/docs當時仍未修改。
- PC-06：completed，只將上述exact test加入Modify allowlist、鎖定expected-set compatibility update、同步path/test audit與workflow state；不構成planning approval。
- PR-06：`approved`；Findings：None。同一IM-01據此恢復。
- IM-01：completed。完成red-green、focused 6/6、root 70/70、bounded compatibility test update、durable docs writeback與所有automated path/API/docs audits；此狀態不宣稱Human visual或VoiceOver pass。
- TE-01：completed；Overall PASS automated。TC-07以及TC-03/04/05/08/09/10的明示Human visual／VoiceOver portions仍pending，這些pending不是automated failure。
- PC-07：completed，只同步四份artifacts的workflow truth，不變更任何contract/API/path/commands/design，亦不構成approval。
- RV-01：completed，明示verdict為`approved`，Findings：None。Reviewer確認focused 6/6、root 70/70，以及scope/path/API/layout/fixtures/accessibility/docs皆pass；Human visual／VoiceOver checklist仍pending。
- PC-08：completed，只同步四份artifacts的final workflow truth，不變更任何contract/API/path/commands/design，亦不構成Reviewer approval；Reviewer approval evidence只來自RV-01 explicit result。
- HC-01：completed，owner為Human；Human decision原值為`採用`，date為2026-09-21。Human確認doc-only amendment已正確同步final accepted behavior：title固定單行、tail truncation、不增加row高度、repository／PR identity維持次層、secondary metadata依既有tiers收斂，且沒有horizontal scrolling。
- PC-09：completed，只記錄final Human decision與Mission completion，不變更任何contract/API/path/commands/design，亦不產生verdict；completion authority只來自Human `採用`。
- Topic／Mission：completed，沒有product blocker或HC-01 decision pending。`採用`只結束此Mission，不等同commit-message confirmation；post-completion delivery authorization為另一項Human明示授權。
- PC-10：completed，只同步delivery workflow truth，不變更product contract且不產生verdict。
- PR-07：`approved`，Findings：None；獨立Plan-Reviewer只審delivery workflow truth，未重開single-line title、其他product contract、test／Reviewer evidence或path allowlist。
- PC-11：completed，只同步PR-07 explicit result與DL-01 current state，不變更product/path/commands/tests/evidence或delivery authorization，亦不產生verdict。
- DL-01：completed；既有topic scope已stage且commit message gate已完成。
- DL-02：completed；Human-confirmed commit已建立並push。
- DL-03：completed；PR #39已建立為Open／Ready，base=`dev`、head=`feat/pr-inbox-pull-request-row`，current head=`7d162aa`。
- RV-02：`needs-rework`。T-01與T-03為同一release compile failure；T-02要求production path與tested policy共享決策來源；T-04要求長內容不得蓋過tier threshold；T-05要求bounded durable writeback。Findings不要求新增public API、dependency、test name、snapshot/UI dependency、BC ownership或新文件。
- PC-12：completed，只materialize bounded PR-comment amendment與truthful workflow state，不構成approval。
- PR-08：`needs-rework`；findings只限step ledger的historical doc-only scope標示與plan內一處「執行」文字誤植。
- PC-13：completed；只修正PR-08兩項findings並同步workflow truth，不構成approval。
- PR-09：`approved`，Findings：None。
- IM-02：completed；red release fixture／layout seam後green，debug／release builds、focused 6/6、root 70/70、precommit／path／API audits均通過，diff恰為七個allowlist paths。
- TE-02：explicit verdict=`approved`；獨立驗證上述同evidence。Human-only Preview／VoiceOver仍為pending，但不是automated blocker。
- PC-14：completed；只同步本次workflow truth，不構成approval。
- RV-03：pending；current step為獨立Reviewer。只有RV-03 `approved`才可進DL-04。

## Post-Completion External Delivery Authorization

- Human authorization原值：`可以 commit -> push -> Open Ready PR`；date：2026-09-21。
- Ready PR固定base=`dev`、head=`feat/pr-inbox-pull-request-row`，且不得建立Draft PR。
- DL-01／DL-02／DL-03：completed；PR #39為Open／Ready，base=`dev`、head=`feat/pr-inbox-pull-request-row`、current head=`7d162aa`。
- 不授權merge、release、tag、branch deletion、worktree removal或自動開始`PullRequestList`／下一Mission。

## PR #39 Comment Rework Authorization

- Human授權順序固定為comment review／bounded fix → Tester → independent Reviewer → stage＋message proposal → Human exact commit-message confirmation → commit → push → reply／resolve addressed comments。
- Bounded implementation paths只有`Sources/Presentation/PRInbox/PullRequestRow.swift`、`Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`與`docs/presentation/native-interaction-contract.md`；本cycle四份planning artifacts仍可修改。不得修改其他path。
- Fixtures維持DEBUG-only；六個test名稱、13個public declarations、620／480／340 thresholds、single-line title、無BC coupling與leaf selection/focus boundary均保持。
- Static graph不需擴張；`colorSchemeContrast` public key path不可寫，維持現行Preview-only作法。
- 不授權merge、release或下一Mission；只有addressed comments可在push成功且evidence完整後reply／resolve。

## Workspace Evidence

- Human已明示「可以實現」。
- Human/operator已建立並attach專用worktree。
- Branch：`feat/pr-inbox-pull-request-row`。
- Baseline：HEAD、local `dev`與`origin/dev`均為`579e67b6db650218078e3383365e40cf08a5e641`。
- Worktree在PC-01前已驗證clean且branch只attach一次。
- Current PR delivery truth：PR #39 Open／Ready；base=`dev`；head=`feat/pr-inbox-pull-request-row`；current head=`7d162aa`。
- Workspace preparation不是Plan-Creator執行；PC-01至PC-14均未執行Git。

## Last Updated

2026-09-21
