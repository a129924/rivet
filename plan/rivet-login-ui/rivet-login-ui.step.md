# Rivet 登入 UI：Step Ledger

## Topic 與執行基線

- Slug：`rivet-login-ui`；branch：`feat/rivet-login-ui`；ownership：non-BC `RivetPresentation`。
- 固定基線：`14d0832f042720889993d769b4cbfb720078e6b1`。PC-01 寫入前唯讀確認 feature branch attached、HEAD 相符、工作樹 clean；所有寫入只在已授權 feature worktree，禁止在 dev worktree 修改。
- Branch 命名依本地 `git-branch-naming`：feature 工作＋已知 work item、沒有既定 owner 慣例，因此使用 `feat/rivet-login-ui`，不捏造 owner。
- Human 前輪鎖定 UI／假資料 Demo、slug／branch／ownership 與原 27 個 Written paths；本輪要求納入 Archify、PR Lens、Graphify。新增九個 Archify paths 是本方案為該要求定義的必要交付規劃，不是 Human 曾逐字列出的清單。Human 最新已接受完整本版方案並授權 feature worktree 實作、依 topic 直接 commit、push、開 Draft PR，再進 Human review；不新增重複確認流程。
- 直接 commit 的既有授權不省略 staged diff 語意邊界與 commit message 檢查；由 Implementer 依本地 commit convention 執行。Plan-Creator 不 commit／push／開 PR。
- Planner 的 `approved` 只表示 planning preparation sufficient；獨立對話草稿品質審查已由上游回報 approved，不能替代四文件落盤後的正式 Plan-Reviewer gate。PR-01 既有正式 approved 保留；Dispatcher 已交接 PC-02 delta 的 PR-02 approved，無 required fix。

## Current Phase

- Phase：RV-02獨立approved／required fix None；TE-03焦點缺陷closed，依Human明確公開payload授權準備topic commit／push，再由Dispatcher建立Draft PR。
- Current Step：TE-04 completed-bounded-pass、RV-02 completed-approved；IM-02準備最終focus修正topic commit／push，GH-01與新head PR Lens待後續真結果。
- Upstream verdict：PR-01／PR-02 approved；TE-01 partial verification；RV-01 approved／P2 closed；RV-02 approved／focus defect closed、required fix None。Bounded驗證不替代完整accessibility或Human採用。
- Code commit：`98f057324419d33926850d926483080c3f3ca633`；36檔；全部commit hooks passed。Feature／dev在收尾前皆clean，未push／PR。
- TE-04新binary四份1×真native PNG已取並實看；Show／Hide四次與rapid4保值／focus、Back／Reset／submit departure及canonical Return／Escape兩組passed。TE-03焦點red與舊Escape觀察保留歷史；VoiceOver／完整traversal／大字／高對比與ReduceMotion啟用條件仍pending。Rootlint39分類保留。

## Artifact Register

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/rivet-login-ui/requirements.md` | present，PC-02 revised | 意圖、素材、唯一 bounded 能力、驗收與限制。 |
| `analysis/rivet-login-ui/technical-spec.md` | present，PC-02 revised | UI／API／state／native／工具執行設計。 |
| `plan/rivet-login-ui/rivet-login-ui.plan.md` | present，PC-02 revised | 九欄、exact paths、TestCase、執行／review 契約。 |
| `plan/rivet-login-ui/rivet-login-ui.step.md` | present，PC-02 revised | phase、owner、evidence、blocker、verdict、Human boundary。 |

## Ledger

| ID | Status | Owner role | Completion condition | Verification evidence／verdict |
| --- | --- | --- | --- | --- |
| HC-00 | completed | Human | 接受完整本版方案，授權 feature worktree 實作與直接 topic commit／push／Draft PR，最後 Human review。 | 來源：本對話 Human 最新執行指示，由 Dispatcher 明確交接。前輪原 UI／branch／ownership／27 paths、本輪三 skills 及完整方案接受的語意如 Topic 區；不偽稱 Human 曾逐字列九個 Archify 檔。 |
| PC-01 | completed | Plan-Creator | 在已授權 feature worktree 僅建立四份正式 artifact，完整九欄、當時36／10／3／None paths 與 LU-01～11；PC-02 後目前 Modify 為4。 | 本次四文件落盤；寫入前 branch attached、base HEAD 相符、clean。尚未測試或實作。完成狀態不是自審 approval。 |
| PR-01 | completed | Plan-Reviewer | 獨立正式讀四文件，審查 sufficiency／paths／native admission／tools／scope，明示 verdict。 | Dispatcher 交接獨立正式 verdict `approved`、無 required fix；四文件與九欄／exact paths／LU-01～11 reviewed。 |
| IM-01 | needs-rework | Implementer | PR-01 approved 後完成受限 UI／Demo／tests／素材／Archify／docs，提供明示 handoff 與限制。 | 已實作 bounded source／tests／素材；focused9tests、debug/release、format/scopedlint pass。PR-02 approved後expected-set最小修正、root284pass；Archify第1輪全尺寸與四圖實看pass；4份native圖仍缺，見 `evidence/verification.md`。 |
| PC-02 | completed | Plan-Creator | 僅修四文件：新增唯一第4 Modify、LU-08 測試／lint 驗收與真實限制，scope／API／工具契約不變。 | 唯讀確認既有 StaticIsolationTests 與 manifest，四文件同步完成；未改測試／產品、未重跑，不自審 approval。 |
| PR-02 | completed | Plan-Reviewer | 獨立正式審查 PC-02 delta，核對最小 expected-set 同步、路徑集合、lint baseline／no-regression 與證據不冒 pass。 | Dispatcher 明示交接 approved、無 required fix；既有 PR-01 不代替本 delta。 |
| TE-01 | completed | Tester | 獨立執行 LU-01～11，分列自動／native／工具結果與缺口。 | partial verification：親跑 focused10／root284、debug/release、format/scopedlint pass；baseline37=現有37、raw素材新增2原樣保留；Archify validate／hash／四圖實看pass。CGWindow真存在但CUA選窗阻塞、capture preflight=false；native四圖／互動／AX pending。見 verification TE-01。 |
| RV-01 | completed | Reviewer | 獨立審查source／tests／證據與單一P2回修，明示verdict。 | Dispatcher交接approved，唯一PAT failure edge P2 closed，無其他required fix；僅供bounded Draft交付，Native／Human採用仍pending。 |
| IM-02 | pending | Implementer | 已授權topic staged review／commit後push feature branch。 | 本地code commit `98f057324419d33926850d926483080c3f3ca633`完成、全部hooks passed；兩次push在執行前遭auto-review拒絕為歷史；Human本輪已明確公開payload授權。RV-02已approved／required fix None，現準備最終focus修正topic commit／push，不預填成功。 |
| PL-01 | completed | Reviewer | 以真base／code head完成外置本地map與pinned validate／render。 | `14d0832`→`98f0573`，validate／render exit0；1view／4lanes／9nodes／11edges／4steps。只含code commit，未含之後metadata；無raster實看。詳verification目前狀態。 |
| GH-01 | pending | Observer/Dispatcher | push後依授權建立目標dev的Draft PR。 | Human公開發布授權已明確；RV-02已approved，待正常push後由Dispatcher建立目標dev的Draft PR，未預填成功，不merge／release。 |
| HC-01 | pending | Human | Draft PR 與完整證據交 Human review，決定採用／調整／放棄。 | 尚無交付採用決策；HC-00 執行授權不等於成果採用。 |
| HC-PUB | completed | Human | 回覆自動approval review要求的具體公開發布確認。 | Human本輪明確同意將`feat/rivet-login-ui`程式／測試／原始素材／文件圖面公開推送至`a129924/rivet`，並以`dev`建立Draft PR；這不是UI成果採用。 |

## Blockers／證據邊界

- 正式 PR-01／PR-02 approved 由 Dispatcher 交接；root target-set expected-set 的兩行最小修復已完成，Tester focused10／root284親跑passed。Root strict lint仍exit2；baseline37逐條等值、raw素材新增2原樣，scoped0，不冒稱rootlint通過。
- 前輪CUA阻塞／capture=false保留歷史；TE-03／TE-04已完成新版四真圖及bounded互動／focus／canonical keyboard取證，RV-02approved。完整traversal／VoiceOver／大字／對比與motion啟用條件仍pending。舊兩次push拒絕保留，但Human明確公開payload授權已到位；本輪新commit／push／PR尚不預填成功。
- Graphify 沒圖可 source fallback；PR Lens 必須真 SHA；GUI 環境／Keyboard Navigation／VoiceOver 未驗分支如實 pending／blocked。
- Archify Showcase diagnostics 與 perceptual correction 的停止規則分開適用，以 technical-spec／plan 原值為準，不把兩者合成一個兩輪上限。
- Exact paths 之外的 repo 輸出或 scope／baseline 衝突回 planning；外置 scratch 不加入 repo／staged diff。

## Human Check

HC-00 是方案接受及直接執行授權。Staged diff 邊界與 message 檢查仍必做，但不為已授權 commit／push／Draft PR 重問。HC-01 是交付後 Human review，不能由 PC-01、draft quality 或正式 agent verdict 代替。無授權合併／release／下一 capability。

## Last Updated

2026-10-22（Asia/Taipei）；RV-02 approved／focus required fix closed，TE-04 bounded原生回歸passed；Human已明確公開payload至a129924/rivet／Draft base dev授權。準備精確7檔focus修正topic commit／正常push；不預填結果。完整accessibility條件與Human採用仍pending，舊PL-01待新head更新。

## PC-02：必要測試契約修正與已知驗證限制

- IM-01 handoff 為 `needs-rework`。Implementer 回報 root `swift test` 非0：284 tests／36 suites，`packageDeclaresTheLockedTargetGraph()` 的 products／targets exact sets 產生兩個 issues；已唯讀確認既有測試與 manifest，原因是本次已授權新增 Demo product／三 targets，非環境問題。
- 唯一新增 Modify 為 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；Implementer 僅可在上述 test 的 products expected set 加 `RivetLoginDemo`，targets expected set 加 `RivetLoginDemoRuntime`、`RivetLoginDemo`、`RivetLoginDemoRuntimeTests`。不得改 GitHubIntegration dependency／source／import／credential boundary 等隔離斷言、helpers 或放寬 equality。ReadOnly 10／Written 36／Deleted None 不變，目前 Modify 為4；不新增產品 scope／public API。
- 本輪 Human 既有「接受計畫、無重大問題直接實作」及直接交付授權涵蓋此必要 routine 測試同步，不新增確認流程；PC-02 只修四文件，仍交獨立 Plan-Reviewer PR-02 審查本 delta，未自行宣稱 approved。
- Implementer 自我證據：focused 9 tests、debug／release、format／diff check 成功；新增 production 首輪6項 lint 已修，scoped strict 0 violations／136 files。Root strict lint 尚為38 findings：36屬既有未改 experiments，2屬原樣封存 scaffold；Tester 尚須獨立核對 baseline、素材 SHA 與 no-regression，不能稱 root lint passed，也不為全局0修改原素材／舊 experiments／lint config。
- Root tests 修復與重跑待 Implementer／Tester；Archify deterministic validate／deliver 9/9、0 errors／warnings 僅為 Implementer 回報，visual-check 三尺寸 overflow 交既有 bounded diagram repair，不改工具契約；四份最新 native PNG 仍缺待 Tester 取證。

## 九欄執行契約

### Goal

交付貼近四張參考 PNG 的原生 macOS Rivet 登入 UI，以及能操作七種呈現狀態、明暗外觀與 PAT 表單的假資料展示程式；這是一個 bounded native Presentation capability。

### Non-Goal

不重設計 adopted workflow／native contract，不交付正式登入，不建立新 BC，不順帶實作 Logic／Domain／Application／Integration。工具不擴張 UI scope。

### In-Scope

non-BC `RivetPresentation` 登入元件、獨立原生 Demo、假狀態模型、七份素材保存與 artwork、native 操作／accessibility、必要測試及文件；Graphify bounded navigation、Archify 七態 lifecycle、PR Lens 實際變更圖，作為同一 UI 交付的理解／驗證證據。

### Out-Of-Scope

真 OAuth／PAT 驗證、browser authorization、GitHub API、Keychain、credential persistence／restore、PR workspace 轉場、其他 BC、既有 Row／List／Header、兩個 OAuth 驗證 App；Graphify 建圖／refresh／integration；PR Lens provider／發布／repo config；artifact.cafe 等發布、合併／release，以及為產圖強迫 commit。已授權的 topic commit／push／Draft PR 僅是本 topic 交付動作，不代表新增產品能力。

### ReadOnly

- `docs/design-principles.md`
- `docs/toolchain.md`
- `docs/development-workflow.md`
- `docs/presentation/native-interaction-contract.md`
- `Sources/RivetPRReaderHarness/main.swift`
- `Sources/Presentation/PRInbox/InboxHeader.swift`
- `Sources/Presentation/PRInbox/InboxHeader+Previews.swift`
- `Tests/RivetPresentationTests/InboxHeaderTests.swift`
- `scripts/check-swift-format.sh`
- `.swiftlint.yml`

### Written

- `analysis/rivet-login-ui/requirements.md`
- `analysis/rivet-login-ui/technical-spec.md`
- `plan/rivet-login-ui/rivet-login-ui.plan.md`
- `plan/rivet-login-ui/rivet-login-ui.step.md`
- `prototypes/rivet-login-ui/Rivet-Login-Dark.png`
- `prototypes/rivet-login-ui/Rivet-Login-Light.png`
- `prototypes/rivet-login-ui/Rivet-Login-OAuth-Dark.png`
- `prototypes/rivet-login-ui/Rivet-Login-PAT-Dark.png`
- `prototypes/rivet-login-ui/Rivet-Login-Prototype.html`
- `prototypes/rivet-login-ui/Rivet-Login-Spec.md`
- `prototypes/rivet-login-ui/RivetLoginView.swift`
- `Sources/Presentation/Login/RivetLoginPresentation.swift`
- `Sources/Presentation/Login/RivetLoginView.swift`
- `Sources/Presentation/Login/RivetLoginArtwork.swift`
- `Sources/Presentation/Login/RivetLoginView+Previews.swift`
- `Sources/Presentation/Resources/Login/GitHubMark.pdf`
- `Sources/RivetLoginDemo/main.swift`
- `Sources/RivetLoginDemoRuntime/LoginDemoHost.swift`
- `Sources/RivetLoginDemoRuntime/LoginDemoModel.swift`
- `Tests/RivetPresentationTests/RivetLoginPresentationTests.swift`
- `Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift`
- `docs/presentation/login-ui.md`
- `plan/rivet-login-ui/evidence/verification.md`
- `plan/rivet-login-ui/evidence/welcome-light.png`
- `plan/rivet-login-ui/evidence/welcome-dark.png`
- `plan/rivet-login-ui/evidence/waiting-dark.png`
- `plan/rivet-login-ui/evidence/token-dark.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.json`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.html`
- `docs/presentation/diagrams/rivet-login-ui/BUILD.md`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.json`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.html`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.1440x900.light.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.1440x900.dark.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.2048x1320.light.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.2048x1320.dark.png`

### Modify

- `Package.swift`
- `README.md`
- `docs/architecture/README.md`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`

`Package.swift` 只新增 Demo executable／runtime／其 test target 及 Presentation resource processing，維持 macOS 15、Swift 6 與既有 dependencies。`README.md`／`docs/architecture/README.md` 僅在驗證後補已交付能力、責任與限制。

### Deleted

None。

四組兩兩互斥；ReadOnly／Modify 在固定 baseline 存在，36 Written 在該 baseline 均不存在。Written 的 baseline 分類不因本次建立四文件而改為 Modify。不得使用 glob、directory-only allowlist 或未列 repo 路徑。Repository 外 scratch／工具 caches 不屬交付；禁止將其放進 staged diff。若需額外 repo path，停止並回 planning，不自行擴張。

## TestCase

每項保持 stable ID，證據寫入 `plan/rivet-login-ui/evidence/verification.md`；不能以 build／test 成功取代人工可觀察結果。Native contract 只採用本 capability 對應的共通原生／accessibility rows，不引入 Inbox／Reader 專屬 workflow。

| ID | Context／trigger | Observable expected result | Evidence method | Contract trace |
| --- | --- | --- | --- | --- |
| LU-01 | 780×500 主視窗，依序顯示四 PNG 對應畫面。 | 雙欄、字階、間距、品牌、dots／vignette、靜態 diff 接近來源；差異限已列展示／系統項目。 | 四份列入 Written 的原生截圖與參考 PNG 並列；記錄尺寸及差異。 | Native contract §7／8／13；四 PNG。 |
| LU-02 | 假 GitHub／PAT 成功、失敗、取消、Retry、Reset；另送 stale／重複 intent。 | 七態可達；不重複啟動；取消無 error；connected 停留；沒有外部呼叫。 | `LoginDemoModelTests`＋原生實際操作。 | §2／11／13；AC-NI-030。 |
| LU-03 | PAT 空白、外圍 whitespace、非固定 prefix、Show／Hide、submit、Back、token failure。 | 空白不能送；只 trim 外圍；不驗 prefix；顯示切換保留文字與編輯 focus；送出／離開清除；failure 仍可重填表單。 | `RivetLoginPresentationTests`＋原生操作；證據不保存輸入值。 | §3／10／13；素材 Spec §4 PAT。 |
| LU-04 | System／Light／Dark、主窗 active／inactive、Increase Contrast。 | 外觀依系統或展示設定；品牌兩態深色；focus／disabled／error／success 不只靠顏色。 | 原生檢查，記錄實際系統條件。 | §7／10；AC-NI-026／035／036。 |
| LU-05 | 標準／放大文字、視窗增大、Reduce Motion。 | 無表單／footer 遮擋；核心操作可達；必要時垂直捲動，無水平捲動；非必要動畫不延遲狀態／focus。 | Preview／host 原生檢查，記錄實際文字大小及視窗尺寸。 | §8／10；AC-NI-028。 |
| LU-06 | Keyboard／VoiceOver 逐態進入及操作。 | focus 符合 spec；label／heading／disabled／局部更新可理解；裝飾不重複朗讀；不攔截全域鍵盤。 | 原生操作／可得 AX evidence；記錄 Keyboard Navigation 設定；缺條件分支 pending／blocked，不冒充 pass。 | §3／7／10；AC-NI-026／030。 |
| LU-07 | Source／dependency／copy／path review。 | 無真登入、network、Keychain、persistence 或外部 help 副作用；文案明示模擬；既有 BC／兩驗證 App 不變；所有變更限 exact paths。 | 獨立 Reviewer 核對實際 diff、imports、manifest、provenance。 | §1／2／11／13；AC-NI-030。 |
| LU-08 | bounded 自動驗證、target graph 同步及 native host 啟動。 | focused／root tests、demo debug／release build、format 成功；StaticIsolationTests 僅同步新增 Demo product／三個 targets 的 expected sets，所有 GitHubIntegration 隔離斷言不變。Root strict lint 如實記錄非0，Tester 核對 baseline 舊 findings 無回歸、原素材 SHA 未改及新增 production／tests scoped strict 0；不得為全局0修改 experiments／原素材。GUI 獨立分類，不把啟動成功當原生驗收。 | Tester 獨立跑計畫命令、targeted StaticIsolationTests、baseline／current lint 與 scoped strict 比對、verification matrix；root test 未重跑前不得宣稱修復，root lint 不冒 pass。 | §13；LU-01～07；既有 GitHubIntegration isolation contract。 |
| LU-09 | Graphify availability／revision 檢查。 | 有可用圖時 bounded query 後 source 核實；無圖／過期／失敗則 targeted reads；沒有建圖、refresh、stamp／config／hooks 等額外 repo 輸出。 | 記錄 pinned invocation 或具體 fallback 原因與 source locations。 | Graphify local skill；Human 工具要求；§13。 |
| LU-10 | 七態 lifecycle 的 diagnostics 修正、交付及視覺檢查。 | 與 state model 一致；Showcase 9/9、0 errors／warnings。Objective error count 創最低值時續修，連續兩輪未改善最佳值才停止。Perceptual correction 最多兩輪；修改 candidate 後重跑 validate／deliver／hash 核對／exact HTML 取證及實看。四尺寸 containment、light／dark 實看及未解問題如實記錄。 | 新版 receipts、spec／HTML SHA、九份列入 Written 的圖檔／sidecars、BUILD 中分開的修正紀錄及 `correction_rounds: 0|1|2`；獨立 review。 | Archify delivery contract；Human 工具要求；§13。 |
| LU-11 | 實作後 bounded diff 與真 base／head commits。 | 未有真 head 前直接 review 並將 map 標 pending；真 SHA 到位才產圖。使用 pinned validate／render、適用 overlay，全程外置；不把 map 當 correctness approval。 | Reviewer 核對實際 diff／SHA、外置 graph／manifest；verification 記錄結果及限制。 | PR Lens local skill；Human 工具要求；§13。 |

## PR-02 後 Implementer handoff

Dispatcher正式交接PR-02 approved、無required fix。只對新增第4Modify測試檔增加2行expected-set entries，保留equality／隔離assertions；focused10／root284pass。圖面第1輪9/9／四尺寸／四圖實看自驗pass。Native最後fresh CUA仍cgWindowNotFound，停止重試交Tester；四份nativePNG仍pending，IM-01不宣稱全部completion condition完成。


## TE-01 獨立 Tester handoff

2026-10-22：親跑自動與baseline比較已完成，沒有production／test修改。原生主窗／controls的CGWindowList證實存在且onscreen；CUA選窗長阻塞與screen-capture preflight=false使最新圖及互動不可取證，未索取新權限／改設定、沒有證實sourcebug。Verdict為partial verification，沒有全部passed；LU-01～06 native branches及LU-11仍pending，交Reviewer判斷交付與Human檢查停點。PR Lens留真commit後，不以map替代review。


## RV-01 P2 bounded diagram fix handoff

2026-10-22：Dispatcher明示RV-01 needs-rework，只有PAT failure送出edge一項P2；source／tests沒有required fix。Implementer已回修 `failed→checking` 與 `token：重填後送出`，七態不變；第2輪完整validate／deliver／samebytes核對／四尺寸visual-check與新版四圖實看自驗pass，最新hash見BUILD。未改source、未重跑Swift、未再操作CUA。TE-01 partial verification與Native四圖／操作／AX pending保持。現交Tester核新圖，再交Reviewerclose，不由Implementer宣告gate通過。perceptual兩輪額度已用完。


## TE-02 新版圖證據複核

2026-10-22：TE-02 completed／passed，僅核對 RV-01 P2 回修後 lifecycle。token-retry 已是 failed→checking／「token：重填後送出」，與 model 一致；親validate9/9、0errors／warnings，新spec／HTML SHA與BUILD／receipt一致，四尺寸receipt與四張新版明暗實看pass。無Swift／CUA／deliver／新capture／凍結圖修改；TE-01自動pass及nativepending保留。Reviewer P2 close與整體verdict仍待獨立處理。


## IM-02：topic commit／push 準備

Dispatcher已交接正式RV-01 `approved`，唯一P2圖契約修正closed，沒有其他required fix；此approval供bounded code／evidence的Draft交付，不表示Native完整驗收或Human採用。TE-01自動驗證與第2輪Archify新證據已獨立核對；四份Native PNG、互動與AX仍pending，不建placeholder。

IM-02進行中：核對feature branch與固定base、dev仍dev且clean；實際32個Written＋4個Modify共36檔，無ReadOnly／其他topic變更。依Human已明示的直接topic commit／push授權，stage後仍檢查單一語意與message `feat(presentation): 新增原生登入畫面與假資料展示`；本紀錄尚未宣稱commit／push成功或填SHA。PR Lens及Draft PR留後續正式交付，不merge／release。


## 本地交付收尾／公開發布確認停點

Code commit `98f057324419d33926850d926483080c3f3ca633`已完成36檔與全部hooks，feature clean；dev仍dev且clean。依Human原「commit by topic→push→Draft PR」指令嘗試push兩次，但autoapproval均在命令執行前拒絕。既有origin已核對public `a129924/rivet`、owner同名、ADMIN／push權限，第二次仍要求明確將本topic程式／測試／使用者原始素材／文件與圖面公開至此repo的Human確認。這是工具審核的額外要求，不抹掉原授權；沒有第三retry或換通道，遠端feature branch不存在，noPR。

PL-01獨立Reviewer本地map已完成，真base14d0832→codehead98f0573；pinnedvalidate／render exit0，external symbolic path與contentHash詳verification。Reviewer只核source／manifest／SVG XML labels，未做raster視覺review；map不包含本次兩檔metadata收尾，不假稱final-head provenance。

本次只更新verification／step，按既有topic commit授權建立本地docs metadata commit，不push／remote／PR；不在自身文件預填該commit SHA。Native四PNG／互動／AX及Human最終採用保持pending。


## TE-03 handoff（2026-10-22）

- TE-03 completed-needs-rework：四份已列Written的真PNG均1560×1064px、已實看；主要七態／PAT／明暗／resize與AX結構已驗。前輪capture=false／CUA阻塞保留為歷史，本輪preflight與AX查詢已可用。
- 唯一已確認required fix：Show／Hide切換後valueLength保持、secure旗標正確，但實際focus由AXTextField失去到AXWindow；精確復現與View對應位置見verification TE-03。交獨立Implementer既有View內bounded修正，Tester不得改production。
- Target-PID Return成功、Escape兩次未取消而AXCancel正常，列待調查觀察，不先當已鎖sourcebug。KeyboardUIMode0、app後續失active使Tab完整traversal未定；VoiceOver／大字／IncreaseContrast與ReduceMotion啟用條件pending，未改全域設定。
- Human已明確補公開payload授權，舊auto-review拒絕是歷史；push／Draft暫待focus修正回歸，由Dispatcher續行。既有code／PL-01 map與root284等證據保留，不冒稱本輪重跑或Human採用。
- 本輪只寫4PNG、verification與step，沒有production／tests／commit／push／PR；外置helper／logs不入repo。最後主窗回780×532frame、Reset welcome，程序保留。


## IM-03 handoff（2026-10-22）

TE-03 Show／Hide focus required fix 已在既有 View 內 bounded 回修；不同私有欄位 identity＋可取消 task 在 yield 後轉交焦點。立即 task 的 attempt 1仍 red，最終 attempt 2真 AX 自驗 secure／visible／secure 全 focused、值長保持，完整限制見 verification。Focused10／root284／debug／release／format／唯一 source scoped strict 自驗皆 exit0；沒有修改 Host／Escape mapping、public API、tests 或其他產品行為。最新既有 wrapper PID36729、Welcome；四份原生 PNG 保留 TE-03 歷史，待 Tester 最終 source 回歸與新截圖。此為 Implementer 自驗完成、獨立 Tester／Reviewer pending，不自行清除 required fix 或放行 gate；未 commit／push／PR。


## TE-04 handoff（2026-10-22）

- Tester最終source獨立native回歸passed：Show／Hide四次及rapid4均保值、AXFocused=true／AXTextField；Back／Reset／submit離開後無殘留textfield或task拉回，重進空白hidden且focus=true。Source／binary SHA、精確限制見verification TE-04；required fix close交獨立Reviewer，不代判gate。
- Canonical private CGEventSource、flags0、Unicode13／27與keyCode36／53兩組Return→waiting／Escape→welcome成功；TE-03舊觀察保留，不推導舊產品keyboardbug。沒有改Host或keyboard mapping。
- 新binary正式4PNG均780×532px（1×，780×500content＋32chrome）且實看對照，無resample；TE-03舊hash保留歷史。其餘特殊系統條件／VoiceOver／完整traversal仍pending，未改global setting。
- Human已明確native驗收與公開payload至`a129924/rivet`、Draft base `dev`授權；舊拒絕保留，但不再列缺Human回答。尚未commit／push／PR，下一步獨立Reviewer，再由Dispatcher依授權交付，最後Human成果review。
- 本Tester只改verification／step及4PNG；既有View變更屬IM-03，不由Tester改動。未新增repo路徑、工具安裝、重跑Swift或產圖。


## RV-02／IM-04：正式審查後公開交付準備（2026-10-22）

Dispatcher正式交接RV-02 `approved`、required fix `None`；TE-03 focus defect closed。TE-04最終source／binary／新版四圖與focus／departure／canonical鍵盤bounded驗證通過，其他Human條件仍pending。Human已直接明確同意程式、測試、原始素材與文件圖面公開推送到public `a129924/rivet`，並建立base `dev`的Draft PR；舊拒絕不是目前欠缺Human授權。

Implementer本輪只準備stage既有View、verification／step與4真PNG共7檔，依staged diff核對單topic並採`fix(presentation): 保留 PAT 顯示切換後的輸入焦點`；完整hooks、正常非force只push feature branch。七原始素材／frozen圖／resource未改，dev worktree唯讀核clean且外部HEAD613a505，不rebase／merge／改dev。本紀錄不預填新SHA、push或PR成功；PR由Dispatcher後續建立，Human成果採用仍pending。
