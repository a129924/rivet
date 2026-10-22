# Rivet 登入 UI：Requirements

## Topic 與執行基線

- Slug：`rivet-login-ui`；branch：`feat/rivet-login-ui`；ownership：non-BC `RivetPresentation`。
- 固定基線：`14d0832f042720889993d769b4cbfb720078e6b1`。PC-01 寫入前唯讀確認 feature branch attached、HEAD 相符、工作樹 clean；所有寫入只在已授權 feature worktree，禁止在 dev worktree 修改。
- Branch 命名依本地 `git-branch-naming`：feature 工作＋已知 work item、沒有既定 owner 慣例，因此使用 `feat/rivet-login-ui`，不捏造 owner。
- Human 前輪鎖定 UI／假資料 Demo、slug／branch／ownership 與原 27 個 Written paths；本輪要求納入 Archify、PR Lens、Graphify。新增九個 Archify paths 是本方案為該要求定義的必要交付規劃，不是 Human 曾逐字列出的清單。Human 最新已接受完整本版方案並授權 feature worktree 實作、依 topic 直接 commit、push、開 Draft PR，再進 Human review；不新增重複確認流程。
- 直接 commit 的既有授權不省略 staged diff 語意邊界與 commit message 檢查；由 Implementer 依本地 commit convention 執行。Plan-Creator 不 commit／push／開 PR。
- Planner 的 `approved` 只表示 planning preparation sufficient；獨立對話草稿品質審查已由上游回報 approved，不能替代四文件落盤後的正式 Plan-Reviewer gate。PR-01 既有正式 approved 依 step 保留；本輪 PC-02 delta 的 PR-02 pending。

## 意圖、來源與成功條件

使用者可啟動原生展示程式，檢視與四 PNG 接近的 Welcome、PAT、OAuth 等畫面並操作假狀態，不需要 GitHub 帳號或真 token。品牌區在七態保持穩定，主視窗初始 780×500 pt、40／60 雙欄。

素材來源為使用者提供的 `rivet_login_ui` 目錄。四 PNG 為外觀優先來源；`Rivet-Login-Spec.md` 補足行為與尺寸；Swift scaffold／HTML 是實作參考。保存七原件且不修改，記錄檔名、SHA-256 與來源日期。素材的 macOS 13+ 不取代 repo macOS 15 基線。

Scaffold 的固定 frame、chevron logo、缺少 dots／vignette、PAT failure 清空整個表單與不完整 focus 不直接照搬。既有 native contract 僅採用與本 capability 相符的共通原生操作／accessibility，不引入 Inbox／Reader workflow 或視窗尺寸。

### 鎖定展示體驗

- 七態：welcome、tokenEntry、waitingForBrowser、verifyingAccount、verifyingToken、failure、connected；failure 區分 browser／token 來源，token failure 保持可填的 PAT 表單。
- Welcome CTA 進入假 waiting；輔助控制模擬返回進 verifyingAccount，模擬完成進 connected 或 browser failure。PAT 非空白送出進 verifyingToken，模擬完成進 connected 或 token failure。
- 不用 timer 自動完成；每態可穩定檢視。Connected 停留，不開 PR。Waiting Cancel 回 welcome，無錯誤 banner；browser Retry 進新的假 waiting。
- PAT 只 trim 外圍 whitespace，不依 prefix 驗證。Show／Hide 保留文字與編輯 focus；送出、Back／離開表單或 Reset 清除文字並重設隱藏。假 model 不保存 token。
- 主窗保留原生 traffic lights、drag、shadow、focus 與輸入。可增大；大字不截斷表單，必要時垂直捲動，無水平捲動。
- 輔助控制視窗提供 System／Light／Dark、七態、模擬結果、模擬返回／完成及 Reset；正式 reusable View 不包含 demo controls。

### 已接受的必要外觀差異

- OAuth PNG 的 `Simulate return to Rivet` 移到輔助控制視窗。
- Footer／verifying／connected 明示 simulated，不宣稱已送出、存入 Keychain、連接帳號或打開 PR。
- 真 token 建立 link 在 Demo disabled，提供可視及 accessibility 的 unavailable 說明。
- 系統 traffic lights、focus ring、ProgressView、字體 rasterization 依 macOS，不自畫、不要求逐像素一致。

### Feasibility 判斷及證據限制

現有 `RivetPresentation` leaf／debug Preview、root AppKit SwiftPM harness 及使用者素材足以支持此受限 UI；沒有影響本次實作選擇、必須透過新實驗回答的未知，因此不建立 experiments。此結論不外推真 OAuth、PAT、Keychain 或正式產品登入整合。

三工具是同一交付的輔助證據：Graphify 沒有可用圖時回 targeted reads；Archify 描述七態假流程並通過 deterministic／perceptual 檢查；PR Lens 只描述真 diff 與真 commit provenance，不取代 correctness review。工具輸出不能放大 UI scope。

### 驗收與完成

以 LU-01～LU-11、原生 Demo 及四份截圖驗收。未執行的 GUI／Keyboard Navigation／VoiceOver 分支保持 pending／blocked，不以 build 或 Human 採用回寫為 pass。正式成果需獨立 Tester／Reviewer；現有使用者授權涵蓋其後 topic commit／push／Draft PR，最後停於 Human review，不自動合併或 release。

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
