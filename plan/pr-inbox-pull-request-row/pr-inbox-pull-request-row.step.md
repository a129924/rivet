# PR Inbox / Pull Request Row：Step Ledger

## Current Phase

Post-completion delivery：Topic／Mission維持completed，HC-01 decision維持`採用`；PR-07 approved（Findings：None），PC-11 completed。Current delivery step為DL-01 current／pending；Human exact commit-message confirmation pending。

RV-01已明示`approved`，Findings：None；Reviewer確認focused 6/6、root 70/70，以及scope/path/API/layout/fixtures/accessibility/docs皆pass。HC-01已於2026-09-21完成，Human decision原值為`採用`；Human另以原值`可以 commit -> push -> Open Ready PR`授權external delivery。PR-07已`approved`（Findings：None）；下一步為DL-01 stage＋message proposal。

## Human Review Amendment

- 原始plan的title最多兩行只保留為historical execution record，不再是current requirement。
- Final accepted behavior：title固定單行、constrained width時tail truncation，不因完整title增加row高度；repository／PR identity維持下一層，secondary metadata依既有contract優先收斂，且沒有horizontal scrolling。
- Human於2026-09-21確認doc-only amendment已正確同步上述final accepted behavior。
- Human已接受`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`的test-only compatibility update，不視為production scope violation。
- 本次只修改四份planning/documentation artifacts；SwiftUI implementation、Presentation model、fixtures、tests、manifest與production BC source均不得修改。

## Post-Completion External Delivery Authorization

- Human authorization原值：`可以 commit -> push -> Open Ready PR`；date：2026-09-21。
- Ready PR固定base=`dev`、head=`feat/pr-inbox-pull-request-row`，且必須為Ready而非Draft。
- Stage scope固定為Exact Path Register中的8個Written paths與4個Modify paths；不得stage ReadOnly、Deleted或額外path。
- DL-01由Implementer做preflight、stage exact scope，依`git-commit-convention`檢查single semantic boundary並提出message，然後停止等待Human確認。
- Human commit-message confirmation pending；HC-01的`採用`與external delivery authorization都不等同message確認。
- DL-02只在Human確認message後commit並push；DL-03只在push成功且local/remote heads一致後建立Ready PR並回報URL。
- 不授權merge、release、tag、branch deletion、worktree removal或自動開始`PullRequestList`／下一Mission。

## Topic and Workspace

- Slug：`pr-inbox-pull-request-row`
- Ownership：non-BC Presentation
- Base branch：`dev`
- Work branch：`feat/pr-inbox-pull-request-row`
- Environment：Human/operator準備並attach的專用worktree
- Verified baseline：HEAD/local `dev`/`origin/dev`均為`579e67b6db650218078e3383365e40cf08a5e641`
- Initial worktree state：clean；branch唯一attach
- Workspace preparation owner：Human/operator boundary；Plan-Creator未執行Git

## Scope Register

- Goal：建立可獨立build/test/Preview/Human Review的native SwiftUI `PullRequestRow` leaf與display-ready Presentation input。
- Non-Goal：`PullRequestList`、selection/focus/open interaction、Reader、Domain/Application/Integration mapping、network/storage/business logic、merge/release/tag、branch deletion/worktree removal；commit/push/Ready PR僅限上述external delivery authorization。
- In-Scope：`RivetPresentation` product/target、row input/view、四級layout、debug fixtures/Previews、Swift Testing、focused/root verification、既有locked graph test的bounded compatibility update與兩份durable current-state replacement。
- Out-Of-Scope：所有BC model/use case/facade/adapter、production mapper、AppKit bridge、generic design system、scene/window constraints與下一Mission。

## Artifact Register

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/pr-inbox-pull-request-row/requirements.md` | present / created by PC-01 / revised by PC-02, PC-04 through PC-11 | 產品意圖、scope、success、source authority、workspace/human boundary |
| `analysis/pr-inbox-pull-request-row/technical-spec.md` | present / created by PC-01 / revised by PC-02, PC-04 through PC-11 | target/API/layout/fixture/a11y/path/writeback locked decisions |
| `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md` | present / created by PC-01 / revised by PC-02 through PC-11 | 受限implementation contract、commands、TC-01～TC-14、workflow |
| `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md` | present / created by PC-01 / revised by PC-02 through PC-11 | phase、steps、evidence、blockers、verdict與Human Check ledger |

## Exact Path Register

### ReadOnly

- `docs/design-principles.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/native-interaction-contract.md`
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
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`

### Deleted

None。

## TestCase Register

| ID | Verification | Expected evidence |
| --- | --- | --- |
| TC-01 | Checkout/target boundary | Branch/worktree/baseline正確；Presentation零dependency；既有targets/dependencies不變；locked graph保留既有entries並加入Presentation graph。 |
| TC-02 | Full presentation value | Fields/equality/hash deterministic。 |
| TC-03 | Optional metadata absent | 無placeholder、假零值或空separator。 |
| TC-04 | Required accessibility | title/identity/author/time/context可讀；leaf不偽造selected/position。 |
| TC-05 | Missing-data accessibility | Missing metadata省略；visual tier不刪除a11y semantics。 |
| TC-06 | Fixture literals/uniqueness | 五fixtures逐值符合contract；ids與repository/number tuples唯一。 |
| TC-07 | Native appearance | 無card/custom selection；資訊層級與desktop density成立。 |
| TC-08 | Tier trigger | 680/560/400/300依序四級，且threshold boundary正確。 |
| TC-09 | Long content/no scroll | Title/identity preserved；無horizontal scroll。 |
| TC-10 | Non-color/semantic state | Context文字化；Increase Contrast/inactive leaf style成立。 |
| TC-11 | Selection/focus boundary | Leaf沒有state/binding/action/custom focus；List acceptance deferred。 |
| TC-12 | Coupling/public API | 無BC/mapper；恰13個public declarations。 |
| TC-13 | Durable truth replacement | Stale current-state文字移除，locked replacement且無architecture drift。 |
| TC-14 | Regression/path isolation | 六focused與root 70 tests通過；tracked 4、untracked 8、status 12 entries；locked graph test只做bounded expected-set update。 |

## Ledger

| ID | Status | Owner role | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-01 | completed | Planner | 確認draft-plan足以轉為formal implementation planning contract，鎖定leaf-only Presentation scope。 | Planner明示可交Plan-Creator，且無scope/authority blocker。 | Upstream Planner verdict已明示`approved`；此verdict不是PR-01。 |
| AU-01 | completed | Human | 明示是否允許建立branch/worktree並materialize/實作本topic。 | Human明示「可以實現」。 | Human authorization已收到。 |
| WP-01 | completed | Human | 從clean且local`dev == origin/dev`建立/attach exact branch專用worktree。 | Branch、HEAD、worktree registration與clean state符合checkout contract。 | `feat/pr-inbox-pull-request-row`；HEAD/dev/origin-dev=`579e67b6db650218078e3383365e40cf08a5e641`；clean且唯一attach。此步不是Plan-Creator執行。 |
| PC-01 | completed | Plan-Creator | 只建立四份同slug正式planning artifacts，materialize approved conversation contract、exact paths/API/layout/tests/writeback/workflow。 | 四份artifacts均存在、內容互相一致；沒有manifest/docs/source/tests或Git變更。 | 四個Artifact Register paths已建立。PC-01只完成寫入與self-check，不產生verdict，不構成PR-01 approval。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查四份materialized artifacts的一致性、decision completeness、scope/ownership、checkout、path、API、layout、fixtures、commands、tests與human boundary。 | Plan-Reviewer回傳標準明示verdict：`approved`、`needs-rework`、`blocked`或`human-check`。 | Verdict：`needs-rework`。Findings：workspace preparation owner錯含Implementer；checkout/package describe/test list/durable writeback/untracked whitespace的exact commands或success conditions不完整；TC-06 trace未列exact sources；ledger尚未記錄rework cycle。 |
| PC-02 | completed | Plan-Creator | 只修正PR-01明示findings並同步四份artifacts；不碰manifest/docs/source/tests，不執行Git。 | Workspace owner只保留Human/operator；完整展開exact commands與success conditions；TC-06列exact adopted sources及pending static evidence；ledger進入PR-02 pending。 | 四份Artifact Register paths已同步回修；PC-02未執行Git且不產生verdict，不構成approval。 |
| PR-02 | needs-rework | Plan-Reviewer | 獨立審查PC-02後四份artifacts及PR-01 required fixes，並確認其餘locked contract未漂移。 | Plan-Reviewer回傳標準明示verdict：`approved`、`needs-rework`、`blocked`或`human-check`。 | Verdict：`needs-rework`。Findings：cache preparation缺exit/tracked-state semantics；test list缺exit 0；forbidden coupling、forbidden interaction、durable stale-text三個no-match gates缺`rg` exit 1/其他exit failure semantics；`git diff --check`缺exit 0。 |
| PC-03 | completed | Plan-Creator | 只補齊PR-02明示的validation success semantics並同步plan/ledger；不改其他artifacts、manifest/docs/source/tests，不執行Git。 | Cache、test list、三個no-match gates及`git diff --check`均具exact success/failure semantics；ledger進入PR-03 pending。 | `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.plan.md`與本ledger已限定回修；PC-03未執行Git且不產生verdict，不構成approval。 |
| PR-03 | needs-rework | Plan-Reviewer | 獨立審查PC-03後四份artifacts及PR-02 required fixes，並確認其餘locked contract未漂移。 | Plan-Reviewer回傳標準明示verdict：`approved`、`needs-rework`、`blocked`或`human-check`。 | Verdict：`needs-rework`。Finding：requirements、technical spec、plan與ledger的current workflow truth未同步至同一review cycle；不得以局部pending state前進。 |
| PC-04 | completed | Plan-Creator | 只同步四份planning artifacts的workflow truth；不改scope、API、paths、commands或design，不碰manifest/source/tests/docs，不執行Git。 | 四份artifacts一致記錄PR-02 needs-rework、PC-03 completed、PR-03 needs-rework、PC-04 completed、PR-04 pending，且只有PR-04 approved可進Implementer。 | 四份Artifact Register paths的workflow sections已同步；PC-04未執行Git且不產生verdict，不構成approval。 |
| PR-04 | approved | Plan-Reviewer | 獨立審查PC-04後四份artifacts的current workflow truth與既有locked contract未漂移。 | Plan-Reviewer回傳標準明示verdict：`approved`、`needs-rework`、`blocked`或`human-check`。 | Verdict：`approved`；IM-01據此開始。此verdict不預先核准後續contract correction。 |
| IM-01 | completed | Implementer | 依exact path/API/layout/writeback contract完成bounded implementation與handoff。 | Package/source/test/docs變更只含allowlist；focused與root verification通過；完成handoff給Tester。 | 完成red-green、focused 6/6、root 70/70、bounded compatibility test update、durable docs writeback與automated path/API/docs audits。此evidence不宣稱Human visual或VoiceOver pass。 |
| PC-05 | completed | Plan-Creator | 只修正formal plan五條Swift commands的cache prefix並同步四份workflow state；不碰partial implementation、docs、manifest/source/tests，不執行Git。 | 兩個cache variables均以`$(pwd)`產生runtime absolute paths；沒有relative `SWIFTPM_MODULECACHE_OVERRIDE`殘留；四份artifacts一致進入PR-05 pending。 | 四份Artifact Register paths已同步；PC-05未執行Git且不產生verdict，不構成approval。 |
| PR-05 | approved | Plan-Reviewer | 獨立審查PC-05 cache-path correction、workflow truth與其餘locked contract未漂移。 | Plan-Reviewer回傳標準明示verdict：`approved`、`needs-rework`、`blocked`或`human-check`。 | Verdict：`approved`；同一IM-01從red setup恢復。此verdict不預先核准後續allowlist correction。 |
| PC-06 | completed | Plan-Creator | 唯讀確認existing static graph assertions後，只新增exact compatibility Modify path、鎖定expected-set update、同步TC/path audits與四份workflow state；不碰implementation/docs或執行Git。 | `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`是唯一新增Modify path；所有既有entries/assertions保留；無第二個Modify path；四份artifacts進入PR-06 pending。 | 排他集合只存在於`packageDeclaresTheLockedTargetGraph()`；`Tests/RivetPRInboxTests/StaticIsolationTests.swift`僅為non-exclusive ReadOnly evidence。PC-06不產生verdict，不構成approval。 |
| PR-06 | approved | Plan-Reviewer | 獨立審查PC-06 allowlist/test/path correction、workflow truth與其餘locked contract未漂移。 | Plan-Reviewer回傳標準明示verdict：`approved`、`needs-rework`、`blocked`或`human-check`。 | Verdict：`approved`；Findings：None。同一IM-01據此恢復。 |
| TE-01 | completed | Tester | 獨立執行TC-01～TC-14 automated gates並明列Human-only portions。 | Automated commands/testcases有明示結果；Human visual／VoiceOver portions明列pending，不得被automated PASS取代。 | Overall PASS automated：RivetPresentation build、focused 6/6、root 70/70及TC automated/path/API/docs gates全過。TC-07以及TC-03/04/05/08/09/10的明示Human visual／VoiceOver portions pending，並非automated failure。 |
| PC-07 | completed | Plan-Creator | 只同步四份artifacts的workflow truth；不改contract/API/path/commands/design，不碰Package/source/tests/durable docs，不執行Git。 | 四份artifacts一致記錄PR-06 approved、IM-01 completed、TE-01 completed、RV-01 pending與Human Check pending。 | PC-07只完成workflow sync，不產生verdict、不構成approval。 |
| RV-01 | approved | Reviewer | 獨立審查implementation scope、source/API/layout/a11y/docs與Tester evidence。 | Reviewer回傳標準明示verdict；只有`approved`可進Human Review。 | Explicit verdict：`approved`；Findings：None。Reviewer確認focused 6/6、root 70/70，以及scope/path/API/layout/fixtures/accessibility/docs皆pass；Human visual／VoiceOver checklist pending。 |
| PC-08 | completed | Plan-Creator | 只同步四份artifacts的final workflow truth；不改contract/API/path/commands/design，不碰Package/source/tests/durable docs，不執行Git。 | 四份artifacts一致記錄RV-01 approved、HC-01 current／pending與automated workflow停止。 | PC-08只完成workflow sync，不產生verdict、不構成Reviewer approval；Reviewer approval evidence只來自RV-01 explicit result。 |
| HC-01 | completed | Human | 完成final Human Review並決定row是否採用。 | Human明示`採用`、`調整`或`放棄`。 | Human decision原值：`採用`；date：2026-09-21。Human確認doc-only amendment已正確同步final accepted behavior：title固定單行、tail truncation、不增加row高度、identity維持次層、metadata依tiers收斂、無horizontal scrolling。 |
| PC-09 | completed | Plan-Creator | 只記錄HC-01 final Human decision與Mission completion；不改contract或implementation，不執行Git或測試。 | 四份artifacts一致記錄HC-01 completed、Human decision原值`採用`、Topic／Mission completed，且沒有pending blocker或Human decision。 | PC-09只完成final decision recording，不產生verdict；completion authority只來自Human `採用`。 |
| PC-10 | completed | Plan-Creator | 只同步post-completion external delivery authorization與routing；不改product contract、implementation或既有evidence，不執行Git或測試。 | 四份artifacts一致記錄Human授權原值、Ready PR base/head、DL-01～DL-03、message confirmation gate、禁止事項與PR-07 routing。 | PC-10只完成delivery workflow-truth sync，不產生verdict。 |
| PR-07 | approved | Plan-Reviewer | 獨立審查PC-10 delivery workflow truth的一致性、授權邊界與routing。 | Plan-Reviewer只對delivery workflow truth回傳標準明示verdict；不得重開single-line title、其他product contract、test／Reviewer evidence或path allowlist。 | Explicit verdict：`approved`；Findings：None；next=DL-01。 |
| PC-11 | completed | Plan-Creator | 只同步PR-07 explicit result與DL-01 current state；不改product/path/commands/tests/evidence或delivery authorization，不執行Git或測試。 | 四份artifacts一致記錄PR-07 approved、PC-11 completed、DL-01 current／pending與Human exact commit-message confirmation pending。 | PC-11只完成workflow truth sync，不產生verdict。 |
| DL-01 | current／pending | Implementer | Preflight、stage Exact Path Register的8個Written及4個Modify paths，依`git-commit-convention`檢查single semantic boundary並提出message。 | Staged scope沒有ReadOnly、Deleted或額外path；message已提出；停止等待Human明確確認。 | Human exact commit-message confirmation pending；HC-01 `採用`及external delivery authorization均不等同message確認。 |
| DL-02 | pending | Implementer | 在Human確認message後commit並push `feat/pr-inbox-pull-request-row`。 | 使用Human確認的message建立commit且push成功。 | 不得在message confirmation前執行。 |
| DL-03 | pending | Implementer | 在push成功且local/remote heads一致後建立Ready PR。 | Ready（非Draft）PR的base=`dev`、head=`feat/pr-inbox-pull-request-row`，並回報URL。 | 不授權merge、release、tag、branch deletion、worktree removal或下一Mission。 |

## Routing

- PR-01 `needs-rework`已路由Plan-Creator完成PC-02。
- PR-02 `needs-rework`已路由Plan-Creator完成PC-03。
- PR-03 `needs-rework`已路由Plan-Creator完成PC-04。
- PR-04 `approved`已路由Implementer進IM-01；IM-01因validation-contract flaw暫停。
- PC-05 completed後派獨立Plan-Reviewer進PR-05。
- PR-05 `approved`已恢復同一IM-01；IM-01在focused green後曾因bounded existing-test allowlist gap暫停。
- PC-06 completed後派獨立Plan-Reviewer進PR-06。
- PR-06 `approved`（Findings：None）已恢復同一IM-01；IM-01 completed後已派Tester進TE-01。
- TE-01 completed（Overall PASS automated）後，PC-07已完成workflow-only sync並交獨立RV-01。
- RV-01已明示`approved`（Findings：None），因此進入HC-01 Human Review；PC-08只同步此既成workflow truth。
- HC-01已於2026-09-21 completed，Human decision原值為`採用`；PC-09已完成final decision recording，Topic／Mission維持completed。
- Human另行明示external delivery authorization後，PC-10已完成workflow-truth sync；PR-07已`approved`（Findings：None），PC-11已同步該explicit result。Current step為DL-01 stage＋message proposal。
- DL-01必須停在Human commit-message confirmation；Human確認後才路由DL-02，push成功且heads一致後才路由DL-03。DL-03完成後停止，不得merge、release、tag、刪除branch/worktree或開始下一Mission。

## Blockers

None。Product automated gates、Reviewer與HC-01均已完成；PR-07已`approved`（Findings：None）。DL-01與Human exact commit-message confirmation pending是正常delivery state，不是blocker。

## Human Check

- AU-01 authorization已完成，只允許本topic依gates前進；不等同implementation/quality/final acceptance。
- HC-01 completed，owner為Human；Human decision原值為`採用`，date為2026-09-21。
- Human確認doc-only amendment已正確同步final accepted behavior：title固定單行、tail truncation、不增加row高度、repository／PR identity維持次層、secondary metadata依既有tiers收斂，且沒有horizontal scrolling。
- `採用`只結束本Mission；另有Human明示的external delivery authorization，但不包含commit-message confirmation。
- Human exact commit-message confirmation pending；只在DL-01提出message後由Human明確確認。
- External delivery不授權merge、release、tag、branch deletion、worktree removal或自動開始`PullRequestList`／下一Mission。

## Verdict History

- Upstream Planner：`approved`，作為PC-01 entry。
- Conversation implementation plan：獨立Plan-Reviewer曾明示`approved`，只授權materialization，不是materialized artifacts的PR-01至PR-06 verdict。
- PC-01：無verdict；Plan-Creator不得自我核准。
- PR-01：`needs-rework`；findings已完整記錄於Ledger。
- PC-02：無verdict；Plan-Creator只完成required fixes，不得自我核准。
- PR-02：`needs-rework`；findings已完整記錄於Ledger。
- PC-03：無verdict；Plan-Creator只完成required fixes，不得自我核准。
- PR-03：`needs-rework`；finding已完整記錄於Ledger。
- PC-04：無verdict；Plan-Creator只完成workflow state同步，不得自我核准。
- PR-04：`approved`；IM-01據此開始。
- IM-01：paused；原因是validation-contract flaw，不是code failure。
- PC-05：無verdict；Plan-Creator只完成bounded planning correction，不得自我核准。
- PR-05：`approved`；同一IM-01從red setup恢復。
- IM-01：曾paused；focused green後root 70 tests唯一failure為bounded existing-test allowlist gap，不是product failure。
- PC-06：無verdict；Plan-Creator只完成bounded planning correction，不得自我核准。
- PR-06：`approved`；Findings：None。
- IM-01：completed；red-green、focused 6/6、root 70/70、bounded compatibility test、docs與automated audits均完成；未宣稱Human visual／VoiceOver pass。
- TE-01：completed；Overall PASS automated；明示Human visual／VoiceOver portions仍pending。
- PC-07：無verdict；Plan-Creator只完成workflow-only sync，不得自我核准。
- RV-01：`approved`；Findings：None。此explicit Reviewer result是進入Human Review的唯一Reviewer approval evidence。
- PC-08：無verdict；Plan-Creator只完成final workflow sync，不得自我核准或取代RV-01 approval。
- HC-01：completed；Human decision原值為`採用`，date為2026-09-21。Human確認doc-only amendment已正確同步final accepted behavior。
- PC-09：無verdict；Plan-Creator只完成final Human decision recording，不得自我產生completion authority。Topic／Mission completion authority只來自Human `採用`。
- Human external delivery authorization：原值`可以 commit -> push -> Open Ready PR`，date為2026-09-21；這不是commit-message confirmation。
- PC-10：無verdict；Plan-Creator只完成delivery workflow-truth sync。
- PR-07：`approved`；Findings：None；next=DL-01。
- PC-11：無verdict；Plan-Creator只完成workflow truth sync，不取代PR-07 approval。
- DL-01：current／pending；Human exact commit-message confirmation pending。

## Last Updated

2026-09-21
