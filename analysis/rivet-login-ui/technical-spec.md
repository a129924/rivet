# Rivet 登入 UI：Technical Specification

## Topic 與執行基線

- Slug：`rivet-login-ui`；branch：`feat/rivet-login-ui`；ownership：non-BC `RivetPresentation`。
- 固定基線：`14d0832f042720889993d769b4cbfb720078e6b1`。PC-01 寫入前唯讀確認 feature branch attached、HEAD 相符、工作樹 clean；所有寫入只在已授權 feature worktree，禁止在 dev worktree 修改。
- Branch 命名依本地 `git-branch-naming`：feature 工作＋已知 work item、沒有既定 owner 慣例，因此使用 `feat/rivet-login-ui`，不捏造 owner。
- Human 前輪鎖定 UI／假資料 Demo、slug／branch／ownership 與原 27 個 Written paths；本輪要求納入 Archify、PR Lens、Graphify。新增九個 Archify paths 是本方案為該要求定義的必要交付規劃，不是 Human 曾逐字列出的清單。Human 最新已接受完整本版方案並授權 feature worktree 實作、依 topic 直接 commit、push、開 Draft PR，再進 Human review；不新增重複確認流程。
- 直接 commit 的既有授權不省略 staged diff 語意邊界與 commit message 檢查；由 Implementer 依本地 commit convention 執行。Plan-Creator 不 commit／push／開 PR。
- Planner 的 `approved` 只表示 planning preparation sufficient；獨立對話草稿品質審查已由上游回報 approved，不能替代四文件落盤後的正式 Plan-Reviewer gate。PR-01／PR-02既有正式approved依step保留；目前PC-03完成待獨立PR-03，尚未放行本次實作。

## PC-03：宣告協調與可控大字設計（2026-11-04，待PR-03）

### 調查依據與邊界

EX-01 Explorer明示調查充分 `approved`；受查source為feature HEAD `6dc04b81834eb8008ed59aebb142771e40d0116f`（程式source與`6fc18b3`一致）。`RivetLoginView.swift`原51–55行同步moveFocus／announcement、227–230行所有heading共用Bool、292–301行statusFocused只設true而未按phase清回，是掛載／focus／語音競爭的可信候選，不宣稱已證唯一root cause。Model真submit／retry只改phase，Controls.show／Reset另換form identity，故兩條路不能互代驗證。

Apple [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate)與[announcementRequested](https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct/notification/announcementrequested)為採用API；SDK允許把announcement通知發給application element，不能把既有NSApp target直接判成bug。Apple [dynamicTypeSize](https://developer.apple.com/documentation/swiftui/environmentvalues/dynamictypesize)明示macOS使用者不能改該值且不影響文字大小；[NSFont.preferredFont](https://developer.apple.com/documentation/appkit/nsfont/preferredfont%28fortextstyle%3Aoptions%3A%29)不足以保證追蹤Human系統13／15點設定。本次不宣稱接上該系統偏好。

### 狀態宣告與focus

以phase對應的具名accessibility focus identity取代所有heading共用Bool；waiting指向Cancel，verifyingAccount／verifyingToken／connected指向各自status heading；welcome CTA、PAT／token failure輸入框、browser failure Retry落點維持原契約。新目標元件掛載後，使用可取消、以phase entry辨識的task協調：先清過期accessibility focus，再設本phase目標；非waiting phase的focus與局部announcement分序，每個phase entry最多一次；PC-06 waiting改由Cancel焦點label帶狀態、不另post，其他通知路徑不變。每次await後及送出更新前檢查取消與phase仍相符；快速Back／Reset／Cancel後，不可由舊task拉回focus或宣告舊狀態。不得以任意固定sleep、提高通知priority、全域鍵盤攔截或再創獨立狀態模型取代協調。

PAT submit、Welcome→waiting、browser Retry→waiting必須各自親驗；同時回歸既有account／connected／failure宣告、Show／Hide持續編輯與清除、Cancel／Escape。AX只證明元素／focus；三缺口的聲音結果須由Human逐項確認，不能以Controls直切phase、背景送鍵、build或unit test判為朗讀pass。

### 真字級入口與Demo控制

公開init增量鎖為 `RivetLoginView(phase:footer:bodyPointSize:onIntent:)`，新增 `bodyPointSize: CGFloat = 13` 置於最後的onIntent前；既有省略此參數的label呼叫與trailing closure繼續可用，不宣稱binary ABI相容。有限輸入策略：finite值clamp至閉區間13...21；NaN與正負infinity回13。可測的internal正規化／比例邊界如有需要只能放既有 `RivetLoginPresentation.swift`，不新增public type或檔案。

右側實際字體以有效bodyPointSize為基準、比例effectiveSize／13；heading、eyebrow、field、button、說明、error、footer皆依同一比例，不用scaleEffect或Dynamic Type注入偽裝大字。左側品牌／diff屬AX隱藏裝飾，可維持固定字級。必要時調整原View內的垂直配置／原生捲動，仍為40／60、最小content780×500 pt，不截斷或增加水平捲動。

Demo model只保有內部局部字級，Controls提供13／17／21 pt三選一並明載「Demo文字大小；不代表系統文字大小偏好整合」；Host傳到新init入口。改字級不重建form identity、不清PAT或重設顯示模式；Reset demonstration保留目前字級，與外觀控制一致，便於同字級逐態驗收。Preview改用同一入口明確顯示21 pt，移除原 `.dynamicTypeSize(.accessibility3)` 大字示例；不改全域設定或要求TCC。

### 本輪驗證與交付

Tests只對有效字級、非法／邊界值與局部size傳遞／Reset保留做有意義行為檢查；task取消／去重若具可觀察可注入邊界才加測，不為測試鏡像SwiftUI實作。自動檢查重跑focused／root、debug／release、format與scoped strict lint；root strict如實記錄非零及未變baseline，不改原素材／experiments／lint config。原focused10／root284等舊成功不充當新版結果。

Tester在13／17／21 pt、最小780×500 pt content檢查Welcome、PAT、PAT failure、waiting、connected的真字級、垂直捲動、footer與核心操作可達性，必要時再增大視窗；記有效字級／比例、window尺寸、binary SHA與逐項結果。舊四張13 pt native PNG保持原source provenance；若重取只用既有四個exact paths並記新binary／尺寸，新增大字capture僅外置scratch，不擅增repo path。更新 `docs/presentation/login-ui.md` 留下macOS限制、公開入口及操作方法。七態／intent graph不變，不重產凍結Archify；Graphify維持無圖source fallback；新PR Lens由獨立Reviewer於真source commit後依pinned本地契約完成，舊map不冒充新head。

## Presentation 介面與所有權

- `RivetLoginPhase: Equatable, Sendable`：`.welcome`、`.tokenEntry`、`.waitingForBrowser`、`.verifyingAccount`、`.verifyingToken`、`.failure(RivetLoginFailure)`、`.connected`。
- `RivetLoginFailure: Equatable, Sendable`：display-ready `message: String` 與 `origin`；origin 固定 `.browser`／`.token`。不公開 remote error、HTTP 或 credential 細節。
- `RivetLoginIntent`：`.beginGitHubSignIn`、`.showTokenEntry`、`.backToWelcome`、`.cancelSignIn`、`.submitToken(String)`、`.retry`。
- PC-03增量：`RivetLoginView(phase:footer:bodyPointSize:onIntent:)` 接受parent-owned phase／footer、預設13的 `bodyPointSize: CGFloat` 與最後的intent callback；既有省略字級的呼叫繼續可用。字級finite值clamp13...21、非finite回13；不自行驗證、載入、持久化或導航到PR，Presentation不依賴BC／GitHubIntegration。
- View 只擁有本地 PAT 文字、showsToken 與 focus。Internal PAT value state 放在 `RivetLoginPresentation.swift`，用來測 eligibility／normalize／clear 行為，不公開 token 驗證 API。Submit trim 外圍 whitespace，guard 非空白，一次回報 intent 並立即清除／隱藏；不記錄值。 PC-03的字級為parent提供的display-ready input，不形成第二份狀態模型；只有Demo保有局部字級選擇。

## 原生畫面與 artwork

初始 content size 780×500 pt，品牌／操作區 312／468 pt，保留約 44 pt traffic-light safe region。AppKit NSWindow 採 full-size content view、hidden title／透明 titlebar，保留原生關閉、最小化、拖曳與 shadow，不需 fullscreen。可增大，最小 content size 780×500；避免固定子 view 高度，大字必要時垂直捲動，不截斷或水平捲動。

依 PNG 對照主要 frames／間距／字階／色彩，兩態品牌均深色；使用系統字體，不封裝 Apple 字體。以 SwiftUI 原生繪製 branch mark、dots、vignette 與靜態 diff，branch geometry 取原 HTML，不用 scaffold chevron。GitHub mark 取原 HTML 嵌入 SVG，製成單色 template PDF，以 `Bundle.module` 載入 `Sources/Presentation/Resources/Login/GitHubMark.pdf`。`docs/presentation/login-ui.md` 記錄 provenance，不誤稱已另行查證官方來源。

## Demo host 與假流程

Root 新增 `RivetLoginDemo` executable、`RivetLoginDemoRuntime` target 及其測試 target；runtime 僅依賴 `RivetPresentation`。沿用既有 NSApplication／AppKit harness 模式，不建立 Xcode project、signing profile、entitlement 或 persistence。

Host 管主視窗與輔助控制視窗。System 為預設；Light／Dark 僅改 Demo window appearance，產品 View 沒有 theme switch。控制可選七態、failure origin、模擬 success／failure、模擬返回／完成及 Reset。Model 同步處理假 intents，stale／重複／不適用 intent no-op；不靠 timer。Reset 回 welcome 並重建本地表單 identity。關閉主窗終止 Demo。

| Context／intent | 結果 |
| --- | --- |
| welcome／beginGitHubSignIn | waitingForBrowser。 |
| waiting／模擬返回 | verifyingAccount。 |
| verifyingAccount／模擬完成 | connected 或 browser failure。 |
| welcome 或 browser failure／showTokenEntry | 空白、隱藏的 tokenEntry。 |
| tokenEntry 或 token failure／有效 submitToken | 清除本地輸入，verifyingToken；model 不保存值。 |
| verifyingToken／模擬完成 | connected 或 token failure。 |
| waiting／cancelSignIn | welcome，沒有 error banner。 |
| browser failure／retry | 新 waiting。 |
| PAT／backToWelcome；任態／Reset | 清除本地 PAT，welcome。 |
| connected | 停留；只有展示切換或 Reset 可離開，不開 PR。 |

Footer 使用明確示範文案，例如 `UI demonstration · No GitHub requests or credential storage.`；verifying／connected 也明示 simulated，不能假稱驗證或保存成功。Token 建立 link disabled 且具可理解的 unavailable 描述，無 browser／network 副作用。

## Focus 與 accessibility

Focus 落點：welcome／返回 welcome 為 primary CTA；PAT／token failure 為 token field；waiting 為 Cancel；browser failure 為 Retry；verifying／connected 為可讀 status heading。Show／Hide 保留編輯 focus，error 不朗讀 token。Native Buttons、SecureField／TextField、ProgressView 參與系統 traversal，不攔截全域 Tab／Arrow／VoiceOver。

Decorative diff 從 reading order 隱藏；heading／field label／disabled 可讀；狀態只作局部且去重複 announcement。Increase Contrast、inactive、Reduce Motion 下保留辨識與 focus，不只靠顏色。記錄 Keyboard Navigation 實際設定，不改全域設定或要求新 TCC 權限。

## 工具執行契約

### Graphify：導覽，不建圖

使用 pinned `0.9.73`；每次 CLI invocation 包含 help／version 均設 `GRAPHIFY_NO_AUTO_REFRESH=1`。實作前重新確認 graph availability、source revision、source locations。準備階段在限定 repo／worktrees／暫存候選未找到可用 codegraph；歷史 PR Lens graph 不是 codegraph。

預設 targeted reads，不因缺圖阻擋。有圖且可用時只做本 topic 的一次 query，budget 1500，再查 source 核實重要關係；過期／錯誤／失敗即記錄限制並 fallback。不得 extract／build／refresh、裝套件、寫 stamp／config／hooks 或啟用 integration。Repository 讀取仍受本契約 path 邊界約束。

### Archify：七態 lifecycle 與同 bytes 交付

以 locked 狀態與實際 code 描述七態假流程；failure 保留 browser／token recovery。不畫真 OAuth／network／Keychain／新 BC。作者內容繁中；省略 `meta.locale`，在 BUILD 披露固定 Viewer UI／`html lang` English fallback。採靜態 classic、`meta.quality_profile: showcase`；不發布、不啟 preview server，不讀 renderer internals。

進入圖實作時，先讀 matching lifecycle schema、common schema、一個 example；下一個 authoring 動作寫 candidate，不先探索 renderer internals。每次 candidate 修改後 validate。

**Showcase diagnostics 修正**：objective error count 持續創最低值時，繼續依 diagnostics 作針對性修正；連續兩輪未改善最佳值時停止，保留未解診斷，不稱 pass。最終接受條件仍是全部 9 artifact checks、0 errors、0 warnings，四項基本檢查不代表 showcase。

**Perceptual review 修正**：依 delivery contract 最多兩輪 focused visual correction，回報 `correction_rounds: 0|1|2`。實看後如修改 candidate，必須重新 validate／deliver／spec 與 artifact hash 核對，原樣複製新 HTML，再對該 exact HTML 重新 visual-check 與實看；舊證據不代表新版本通過。

Deliver 的已查證 CLI 會在 output 同層建立動態私有 staging，含 `specification.snapshot.json` 與 staged HTML，最後清除，沒有額外固定 snapshot。為避免未列 repo 路徑，deliver 僅輸出到 repository 外 topic scratch。最終 pipeline：

1. Repo 的 `login-lifecycle.json` 通過 final validate 後凍結；deliver 對該 JSON、輸出外置 scratch HTML，取得真 receipt。
2. 核對 receipt specification SHA／bytes 與 repo JSON；原 bytes 複製成功交付的 HTML 到已列最終 repo HTML path，核對 SHA／bytes 等於 receipt。不是重 render，不編輯 HTML。
3. 對 repo 最終 exact HTML 執行 `visual-check --repo-root`，六份固定 sidecars 放在 HTML 旁，不外置、不改 receipt。
4. 自動量測 1440×900、1600×1000、1920×1080、2048×1320 containment；實看最小與最大尺寸的 light／dark screenshots，檢查 readable／balanced、label／edge、空白與 clipping。
5. Receipt 的 `visualReview: pending` 原樣保留；實看者另在 BUILD 寫 truthful `visual_review: passed|skipped (image reader unavailable)|failed`，不能以 capture 成功當人工 pass。

不得隱藏 overflow、縮字、clip 或加 internal scroller 偽裝 containment。Chrome 不可得／capture 失敗依工具 exit／receipt 分類，保留缺口，不稱 passed。BUILD 記錄版本、實際命令、spec／artifact SHA 與 bytes、9/9 結果、copy 同 bytes、containment、實看結果及分開的修正紀錄。路徑採 repo-relative 或工具根別名，避免記錄使用者本機絕對路徑。`verification.md` 引用 BUILD。

### PR Lens：獨立 Reviewer 的實際變更圖

使用 pinned `0.11.0`，只有實作後真 bounded diff 才有 map。先讀 example／document contract；外置 topic scratch 固定相對項目為 `pr-lens/graph.json` 與 `pr-lens/rendered/`，不寫 repo `.pr-lens`／config／ignore。保留必要 unchanged neighbours、file refs，不把 map 當 findings 或 correctness verdict。

真 base／head 尚未存在時，Reviewer 直接審查 bounded working diff；map 保持 pending，provenance 不用 `workingtree` 或假 SHA。本輪 Human 已明示 topic commit／push 授權，無需另問；仍必須先做 staged diff／message 邊界檢查，不能為圖自行製造無授權 commit。正式成果 Reviewer approved 後由 Implementer 依既有授權 commit／push，再由獨立 Reviewer 使用真 commit IDs 建立／validate／render local map。

準備階段未找到適用 overlay；執行時重新確認，沒有則 `--no-config`。如新 baseline 出現適用 overlay，先回 planning 核對其 exact ReadOnly path，再讀並用 `--config`，不得繞過。CLI 失敗保留具體錯誤並 fallback direct diff review；不得安裝／升級、analyze／provider、upload、開 hosted canvas／server、發布／評論 PR。圖僅提供 reviewer 理解，不另增 correctness gate。

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

non-BC `RivetPresentation` 登入元件、獨立原生 Demo、假狀態模型、七份素材保存與 artwork、native 操作／accessibility、必要測試及文件；Graphify bounded navigation、Archify 七態 lifecycle、PR Lens 實際變更圖，作為同一 UI 交付的理解／驗證證據。 PC-03僅追加兩類狀態宣告修補與Demo局部13／17／21 pt真字級驗收；系統文字大小偏好整合仍未交付。

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
| LU-05 | Demo局部13／17／21 pt、780×500 pt最小content與增大視窗；Reduce Motion。 | 右側heading／欄位／按鈕／說明／error／footer真字級依同一比例放大；無遮擋／截斷；footer及核心操作可垂直捲動到達，無水平捲動；非必要動畫不延遲狀態／focus。 | 同一point-size入口的Preview與host原生實看；記錄有效字級／比例、視窗尺寸、binary SHA。不能用Dynamic Type／系統13或15點未生效的操作當大字pass；系統偏好整合未交付。 | §8／10；AC-NI-028；PC-03。 |
| LU-06 | 真PAT submit、Welcome→waiting、browser Retry→waiting；Keyboard／VoiceOver逐態與快速離開回歸。 | 無需手動進scroll area即可理解當前狀態；PC-06 waiting由Cancel焦點label同時提供等待狀態及取消動作，不另post；其他phase通知路徑不變。Cancel／Escape與既有focus落點可用、無明顯雙讀／過期focus；label／heading／disabled與裝飾reading order不回歸。 | Tester核新版link role／label／focus與Cancel／Escape；Human逐項親聽Welcome及Failure Retry兩真waiting入口，不以Controls直切／AX／背景送鍵／build代聲音。PAT舊兩次無聲、probe／HC-05有聲及HC-02通過各留源，大字Human／rapid與未補驗項pending。 | §3／7／10；AC-NI-026／030；PC-03／PC-06。 |
| LU-07 | Source／dependency／copy／path review。 | 無真登入、network、Keychain、persistence 或外部 help 副作用；文案明示模擬；既有 BC／兩驗證 App 不變；所有變更限 exact paths。 | 獨立 Reviewer 核對實際 diff、imports、manifest、provenance。 | §1／2／11／13；AC-NI-030。 |
| LU-08 | bounded 自動驗證、target graph 同步及 native host 啟動。 | focused／root tests、demo debug／release build、format 成功；StaticIsolationTests 僅同步新增 Demo product／三個 targets 的 expected sets，所有 GitHubIntegration 隔離斷言不變。Root strict lint 如實記錄非0，Tester 核對 baseline 舊 findings 無回歸、原素材 SHA 未改及新增 production／tests scoped strict 0；不得為全局0修改 experiments／原素材。GUI 獨立分類，不把啟動成功當原生驗收。 | Tester 獨立跑計畫命令、targeted StaticIsolationTests、baseline／current lint 與 scoped strict 比對、verification matrix；root test 未重跑前不得宣稱修復，root lint 不冒 pass。 | §13；LU-01～07；既有 GitHubIntegration isolation contract。 |
| LU-09 | Graphify availability／revision 檢查。 | 有可用圖時 bounded query 後 source 核實；無圖／過期／失敗則 targeted reads；沒有建圖、refresh、stamp／config／hooks 等額外 repo 輸出。 | 記錄 pinned invocation 或具體 fallback 原因與 source locations。 | Graphify local skill；Human 工具要求；§13。 |
| LU-10 | 七態 lifecycle 的 diagnostics 修正、交付及視覺檢查。 | 與 state model 一致；Showcase 9/9、0 errors／warnings。Objective error count 創最低值時續修，連續兩輪未改善最佳值才停止。Perceptual correction 最多兩輪；修改 candidate 後重跑 validate／deliver／hash 核對／exact HTML 取證及實看。四尺寸 containment、light／dark 實看及未解問題如實記錄。 | 新版 receipts、spec／HTML SHA、九份列入 Written 的圖檔／sidecars、BUILD 中分開的修正紀錄及 `correction_rounds: 0|1|2`；獨立 review。 | Archify delivery contract；Human 工具要求；§13。 |
| LU-11 | 實作後 bounded diff 與真 base／head commits。 | 未有真 head 前直接 review 並將 map 標 pending；真 SHA 到位才產圖。使用 pinned validate／render、適用 overlay，全程外置；不把 map 當 correctness approval。 | Reviewer 核對實際 diff／SHA、外置 graph／manifest；verification 記錄結果及限制。 | PR Lens local skill；Human 工具要求；§13。 |

## PC-04：debug觀測契約（2026-11-04，待PR-04）

EX-02指出source `.onChange(initial:true)`才更新focusPhase，而phase task第一guard先要求focusPhase等於entryPhase；若task較早啟動，可直接return且不重啟。這是待runtime區辨候選，非已證兩次無聲的原因；三次Task.yield不是AX-ready barrier。NSApp通知target合法；換macOS14+ Announcement／LayoutChanged／ScreenChanged API不保證出聲，macOS26 accessibilityDefaultFocus不符baseline15。
僅在既有 `Sources/Presentation/Login/RivetLoginView.swift` 以 `#if DEBUG`、系統OSLog和可關閉的局部logger觀測，release不含該觀測；不新增檔案／public API／type／dependency／UI控制或runtime框架。不改功能guard、focus ownership、通知API／priority、sleep或yield數；可先依既有guard結果再記skip以降低干擾，但明載logger仍會改變timing，不回推前兩次原因。
Trace採有限allowlist：phase／entryPhase／focusPhase的固定enum映射、case correlation ID、guard返回reason／cancel／match、focus request與binding enum變化、notification post前後的call標記，以及NSApp.isActive／hasMainWindow／hasKeyWindow／key==main／NSWorkspace.isVoiceOverEnabled布林。不得PAT／欄位值／任意AX label／failure message／window title／私人app資料；不得用帶associated message的enum描述字串。post只證明呼叫，mainWindow不證own View附窗或AX ready。
Trace僅外置；先由TE-06核可讀、source／binary與敏感欄位限制，再由主對話CUA準備真PAT欄位，最多一次Human真正前景Return作主要runtime case。啟動／PAT entry可先讀preflight trace，Controls.show與背景送鍵不能替代；不動全域、TCC或VoiceOver設定。
依trace再路由：未到post，才按guard實證修協調ownership並保留取消／stale／focus契約；post已到但window／AX未知，只補具體缺的最小event-driven觀測；條件足且Human仍無聲，需先明示單一變數scope／API probe。這些後續動作均非PC-04預先核准的修法；若須actual-attachment橋接或違反locked design，先最小planning delta。

## PC-05：保存探針、單檔還原與正常版對照（2026-11-04，待PR-05）

先外置保存View探針source `98bb32bd5ff4e014b9e146d42ab8cb7880d9f93793e9c571abadab7b0a6eacd3`、probe binary `18c8a3a4b81ed7bf6f335af96ab8aa4ef504a67150406eddb3f31fd250a4d2eb`，以及HC-04的34筆trace／receipts與各自完整SHA；外置檔不stage。以保存hash及既知source hash雙重guard確認未有新改動，再只把既有View還原為已發布HEAD `9dd80eaf51f0c5f4c7245db092ed3f04b92fe605` 的原blob bytes，expected SHA `89cb23c412b7d9e2b5ecefe0e1b0123731e2b4d96cfafaf366126527afc980a5`；不符即停止覆蓋。可git show讀該blob再寫單檔，禁止whole-tree restore／reset或丟失metadata；其餘六個Swift檔保持原frozen來源。
這只移除diagnostic working diff，不修改phase／focus／字級API／priority／三yield／七態行為。正常debug／release重建後實測hash，不預填舊9a／22c或假定bit deterministic；TE-07核View與public source9f8955c同bytes、無probe marker及新wrapper／binary來源，正常版不冒稱有post trace。
HC-05新增獨立預算0／1，最多一次正常debug真Human前景PAT Return；HC-04的1／1已用不可重用。主對話CUA只換版重啟及準備Welcome→真PAT欄位／dummy，保留Human已開的VoiceOver不切設定；Human點欄位確保前景，可等欄位朗讀完，再Return一次，事前不手動進scroll area。只收真聲音及視窗結果；單次正常／probe對照不唯一確立logging因果、穩定性或全面pass。

## PC-06：waiting以既定焦點label表達狀態（2026-11-11，待PR-06）

依Explorer調查充分approved及[accessibilityLabel](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:))可讀描述能力，在既有waiting Cancel link加簡短label `Waiting for simulated authorization. Cancel sign in.`。保留可見 `Cancel sign in`、link role、既有AX waitingCancel落點、keyboard cancel與Escape；不新增hidden announcer或改focus協調。僅waiting移除獨立announcementRequested post，讓焦點label承載等待語義並避免同狀態雙路播報；其餘phase／通知／priority／三yield／字級完全沿用。
Human同次只讀Cancel而缺狀態足以支持此語義修補，無當次post trace，不宣稱已證失敗機制、修復歷史PAT原因或需要新probe。唯一source變更為既有View，長期說明同步既有 `docs/presentation/login-ui.md`；自動檢查與AX role／label／focus證據不代替Human聲音。Welcome→waiting、Failure Retry→waiting兩真入口逐項親聽：無需進scroll area即可理解等待、無明顯雙讀，Cancel／Escape仍可操作。
IM-09不動running app；正常新版build／來源核對後由驗證／主線準備wrapper再交Human。保留HC-05正常PAT一次有聲、舊failed與probe來源，大字Human／rapid及整體採用仍pending；不改凍結七態Archify或三工具契約。
