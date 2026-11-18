# Login UI 元件化技術規格

> 現行契約：本文件末段「R3：2026-11-18 E011 凍結與驗收歸屬修訂」優先適用於本輪。前文原規劃及 I01／I02 授權、實作與驗收保留為其版本歷史；不得以本輪要求倒推原作業越權，也不得把舊驗收直接套給新 host。

- Topic：`rivet-login-ui-adoption`
- 日期：2026-11-17
- 基線：`1f31b35604adb5bb36326e52f9d6dbcff0cac763`
- 上游決策：Human 已接受需求與對話方案；本文件等待獨立 planning review。

## 鎖定責任與依賴

唯一公開 View 是 `RivetLoginView`。其他 View 為 internal，按互動責任分檔，不把 label／button／裝飾逐一公開。既有品牌、palette、圖示資源與樣式重用；保持 non-BC `RivetPresentation`，不新增 target、package、BC 或認證依賴。

Parent 是 phase 唯一權威；真正建 request、呼 service、管理認證 Task／cancellation 及更新 phase 的外層協調／Adapter 不在本 topic。E011 只提供 fake inputs／events，不 import 或呼叫真實登入 VO／service。

既有依賴由 phase、六個 intents、PAT helper、字級規則、品牌與資源滿足。PAT helper 只是 UI 編輯行為，不取代 `PersonalAccessToken`。

## 元件 composition

| 元件 | 輸入 | callbacks／事件 | owned state |
| --- | --- | --- | --- |
| `RivetLoginView` | phase、content、footer、bodyPointSize、canCreateToken | 統一轉發 `RivetLoginIntent` | 無認證／流程 state；穩定布局、區段選擇 |
| `LoginMethodSelection` | welcome 呈現內容及有效字級／樣式 | GitHub、PAT 選擇 callbacks | 主操作 keyboard／accessibility focus |
| `LoginOAuthSection` | waiting 或 browser failure、內容、有效字級／樣式 | cancel、retry、showTokenEntry callbacks | 區段焦點及可取消 phase-entry UI 工作 |
| `LoginPATForm` | tokenEntry 或 token failure、錯誤文字、內容、字級、canCreateToken | back、submit(String)、createToken callbacks | PAT 文字、Show／Hide、欄位焦點 |
| `LoginStatusNotice` | verifying／connected 的 title、message、announcement、字級／樣式 | 無業務事件 | accessibility focus 及可取消宣告工作 |

子元件只拿切片資料與具名 callbacks，不拿整個 DemoModel 或認證 model。Root 以既有 40:60 原生布局組合元件；元件內的小型排版 helper 可保留，不機械拆出每段 computed property。

## UI state 與生命週期

- 保留七態：welcome、tokenEntry、waitingForBrowser、verifyingAccount、verifyingToken、failure、connected。
- Waiting Cancel／Escape 發 `cancelSignIn`；browser failure 發 `retry`；token failure 保持可重填 form，送出仍發 `submitToken(String)`。
- Parent 決定取消完成、重試開始與結果，不由 View 自行改 phase。
- PAT form 在 tokenEntry 與 token-origin failure 間保留 identity。送出先取外圍 trim 值再立即清除；離開 form、消失或 E011 Reset 清除並隱藏。字級／文案更新、Show／Hide 不清文字；Create 不改編輯內容。
- 本地只拒絕 trim 後空值，保留內部空白，不驗 prefix／權限／到期。
- 沿用 13...21 pt 有限字級規則，非有限值回 13。字級變更不重建 form。
- Focus／accessibility／announcement 只屬 UI；每個 phase-entry 工作可取消，在每個 await 後確認仍屬目前 phase／有效視圖。快速切態、消失時舊工作不得把焦點拉回或發過期宣告。

## 公開介面

保留六個既有 intent 語義，新增 `case createPersonalAccessToken`。同次更新 exhaustive switch 與 E011 消費端；enum 新 case 有 source compatibility 影響，不能宣稱所有下游 switch 無須更新。

```swift
public init(
  phase: RivetLoginPhase,
  footer: String,
  bodyPointSize: CGFloat = 13,
  content: RivetLoginContent = .standard,
  canCreateToken: Bool = false,
  onIntent: @escaping (RivetLoginIntent) -> Void
)
```

新增參數有預設值且位於最後 callback 前，舊 label 呼叫與 trailing closure 語法維持可用。

```swift
public struct RivetLoginStatusContent: Equatable, Sendable {
  public let title: String
  public let message: String
  public let announcement: String

  public init(title: String, message: String, announcement: String)
}

public struct RivetLoginContent: Equatable, Sendable {
  public let waitingDescription: String
  public let waitingStatus: String
  public let waitingNote: String
  public let waitingCancelAccessibilityLabel: String
  public let verifyingAccount: RivetLoginStatusContent
  public let verifyingToken: RivetLoginStatusContent
  public let connected: RivetLoginStatusContent
  public let tokenFieldAccessibilityLabel: String
  public let createTokenUnavailableMessage: String

  public static let standard: RivetLoginContent

  public init(
    waitingDescription: String,
    waitingStatus: String,
    waitingNote: String,
    waitingCancelAccessibilityLabel: String,
    verifyingAccount: RivetLoginStatusContent,
    verifyingToken: RivetLoginStatusContent,
    connected: RivetLoginStatusContent,
    tokenFieldAccessibilityLabel: String,
    createTokenUnavailableMessage: String
  )
}
```

上列是介面宣告規格，不是可直接編譯的完整 struct 實作。Failure 維持 `RivetLoginFailure(message:origin:)`，不新增錯誤型別／轉譯。

Content 覆蓋原 View 的 waiting、verification、connected、PAT accessibility label 與停用提示展示硬字串。其餘既有產品適用 label 沿用。正式 `.standard` 不含 simulated、Demo Controls、example-only，不宣稱憑證保存或 session 已建立。Verification 標題用 `Verifying account…`／`Verifying token…`；connected title／announcement 為 `Sign-in completed.`，message 為 `This sign-in attempt completed successfully.`。它僅表達本次登入完成。

`canCreateToken == true` 才發新增 intent，View 不內嵌 URL、不開 browser；停用 help／accessibility hint 共用 `createTokenUnavailableMessage`。Root 不另外建立 demo mode。E011 自行提供展示 content、fake callbacks，預設保持建立入口停用。

## 文件層的接線對應契約

已核對既有實碼 `Sources/BoundedContexts/GitHubIntegration/Contracts/LoginAuthentication.swift` 與 `docs/architecture/github-dual-login-contract.md`。以下只記錄對應，不新增 production mapper／Adapter，不讓 E011 呼叫真 VO／service。

| UI intent／phase 或 Outcome | 既有 VO／未來外層責任 | 限制 |
| --- | --- | --- |
| `.beginGitHubSignIn` | 未來建立 `LoginRequest.oauth`，呼 `authenticate(_:)` | request 不帶 OAuth 配置，配置屬 service 組裝 |
| `.submitToken(String)` | 未來 `try PersonalAccessToken(rawValue:)` 後形成 `LoginRequest.pat(token)` | init 只 trim 外圍，空值 throws `PATInputError.empty`；本地接受不代表遠端有效 |
| `.showTokenEntry`／`.backToWelcome` | parent 提供 `.tokenEntry`／`.welcome` | 純 UI 切換，沒有登入 request |
| `.cancelSignIn` | 未來外層傳遞取消並等原工作 settled | 沒有 cancel request case，本次只有 callback |
| `.retry` | 未來外層依原嘗試脈絡決定新工作 | intent 無 request payload，Outcome 不含原登入方式 |
| `.createPersonalAccessToken` | 未來外層處理建立入口 | 不對應 LoginRequest，本次不開 browser |
| `LoginOutcome.success` | 未來外層可提供 `.connected` | 無 payload，不建立或交付 account／session／provider／clients |
| `.failure(.authenticationFailed)` | 未來外層可提供 `.failure(RivetLoginFailure)` | origin 從嘗試脈絡取得，message 由外層提供安全文案；Outcome 無原始 error／任意訊息，失敗不證明憑證無效 |
| `.cancelled` | 未來外層依取消完成與 UI 脈絡更新 phase | 沒有唯一內建 UI phase 對應，View 不推測 |
| `.waitingForBrowser`／`.verifyingAccount`／`.verifyingToken` | 未來外層依工作進度提供 | Outcome 無中間狀態，不能單憑最終 Outcome 推導 |

既有 `LoginAuthenticating: Sendable` 唯一 requirement 為 `authenticate(_ request: LoginRequest) async -> LoginOutcome`，不拋錯；結果僅 success、failure(LoginFailure)、cancelled，LoginFailure 目前僅 authenticationFailed。取消義務由未來 conformer／外層遵守，不在本 topic 實作；既有 OAuth Scope 仍只接受具體 OAuth provider，不推論 PAT 可取得 Scope。

## 長期說明與證據

長期 UI 文件記錄上述對應及元件責任，校正相關入口的舊 pending 摘要；既有 GitHubIntegration 契約不改。採用程度／方式／來源關係分開記錄；舊 Human 接受不當作新二進位驗收。Native Human VoiceOver／最終 UI 接受可以 pending 交付 Draft，但必須明記未驗，不能升格為已接受。

- [需求與 audit](requirements.md)
- [執行計畫](../../plan/rivet-login-ui-adoption/rivet-login-ui-adoption.plan.md)
- [帳本](../../plan/rivet-login-ui-adoption/rivet-login-ui-adoption.step.md)


## I02 補充：乾淨原生預覽入口（2026-11-17）

Human 在既有 UI scope 要求驗收正式 Login 外觀。本次僅新增 E011 app-local 的獨立乾淨 host，保留既有展示 host／Controls／LoginDemoCopy，不擴正式 library 或真登入能力，不重開架構或新增 gate。

- Written：`experiments/E011/Sources/RivetLoginDemoRuntime/LoginPreviewConfiguration.swift`、`LoginPreviewHost.swift`；`experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginPreviewConfigurationTests.swift`；本 topic `evidence/clean-preview-implementation.md`。
- Modify：既有 executable `experiments/E011/Sources/RivetLoginDemo/main.swift` 增加 `--preview` 分流；`Sources/Presentation/Login/RivetLoginView+Previews.swift` 只替換 footer／failure 展示文字；`docs/presentation/login-ui.md`、本 topic technical-spec／plan／step。
- ReadOnly：Package.swift／Package.resolved、正式 View／content／component／intent 實作、既有 Demo host/model/copy、E011 README、T02／T03／H01–H08 歷史與凍結圖。Deleted：無。
- CLI：同一 `RivetLoginDemo` executable；無 `--preview` 維持原展示入口。乾淨入口為 `--preview [--state <state>] [--appearance system|light|dark] [--text-size <13...21>]`，預設 welcome／system／13。state 為 welcome、pat、waiting、verifying-account、verifying-token、browser-failure、token-failure、completed；非有限／超範圍字級、未知／缺值／重複選項在建窗前拒絕，不靜默改成展示模式。
- Host：單一原生主窗，直接組合 `RivetLoginView(content: .standard)`；不建立 Controls、overlay、debug labels、事件計數或測試選單。CLI 只指定啟動畫面／外觀／字級；重新啟動切換，沒有 timer 或自動完成。
- Parent：重用既有 LoginDemoModel 的 fake event 處理，不呼認證服務／VO／儲存／session。初始 failure 由 preview configuration 提供中性可重試文字，不使用模擬 failureMessage。
- `.standard` 不含 footer 或 failure message；host 明確提供中性 footer `Connect your GitHub account to Rivet.` 與 failure copy，不誤稱它們來自 `.standard`。不修改正式 content schema 或空 footer 行為。
- 原生 wrapper：可在 feature `.build` 新增獨立 `RivetLoginPreview.app`，bundle ID `local.rivet.login-ui-preview`，複製同一正式 debug executable／Presentation resource bundle，不覆寫既有 wrapper，不 commit `.app`。此 bundle ID 在同一 executable 入口預設選擇 preview，即使 `open` 未附參數也不會誤開展示 host；外加 state／appearance／text-size 參數仍由相同 parser 處理。本實作階段只準備，不啟動或停止其他 app。
- 差異驗證：配置／八種 phase 選擇、邊界參數拒絕、中性 copy 與 Demo copy 隔離、fake callbacks不自動推進，受影響 tests、正式 executable build、scoped format／lint／diff-check；不因預覽入口重跑不相關完整 suite，也不重產 lifecycle。獨立 Tester T04 驗證單窗／原生外觀／無展示文字及必要事件；R04 獨立審查後回 HC01，既有 T02/T03/H01–H08 結果保留。本次 preview 不宣稱 Human 已接受，HC01 仍 pending／no merge。


## R3：2026-11-18 E011 凍結與驗收歸屬修訂

### 優先序與正式核心

前文「不新增 target/package」及 I02 E011 路徑是原授權契約歷史，不能刪除或倒推越權。本輪依 Human 新要求，只增加獨立 acceptance-tool SwiftPM package 的明列例外，正式 root product/package/target 不變；此例外交獨立 Plan-Reviewer 審查，作者不自行宣稱放行。

目前正式 RivetLoginView、content/API/intent、四個 child、helper/字級/品牌/資源不重建、不改行為。本輪正式 source 只改既有 `RivetLoginView+Previews.swift` 的 DEBUG 私有 wrapper。既有 UI／VO 文件對應維持，不新增 LoginRequest／PersonalAccessToken mapper／VO，Presentation 與驗收工具不 import GitHubIntegration。

### Controlled #Preview

以既有私有 LoginPreview 改成 `@State` controlled phase、字級、content 選項、canCreateToken、form generation 及 last event kind/count；狀態存在 DEBUG wrapper，不新增正式 public API。保留代表性 preview，wrapper 外側提供有限 state／text-size／content／canCreateToken／Reset 控制，不能混成正式主畫面。

- `beginGitHubSignIn`／browser `retry`→waiting；`showTokenEntry`→tokenEntry；`backToWelcome`／waiting `cancelSignIn`→welcome；`submitToken`→verifyingToken；createPersonalAccessToken 只記 event kind，不開 browser／改 phase。只在合法目前 phase 接受事件，其餘 no-op。
- Submit callback 收到 String 後立即丟棄，只保留 kind/count；不保存 intent payload、token片段／長度／hash，不寫含 token 的 log／收據。這是 UI fake parent，不是 fake LoginAuthenticating service。
- Account/token verification、兩種 failure、completed 可由 wrapper 的有限 phase 選項手動提供；不以 timer／Task 自動完成，不聲稱呼過認證。
- 同一 form generation 下切 tokenEntry↔token failure、字級13/17/21、standard↔controlled content 與 canCreateToken；禁止 `.id(phase/textSize/content)` 重建 form。僅顯式 Reset 增加 generation，或真正離開表單使正式元件依原契約清除。
- Controlled content 是 wrapper 自有測試資料，依現有公開 schema 建構；預設 .standard。測試文字只在明確選擇時出現，不新增 formal demo mode。
- Preview／fake parent 單元測試不能證明正式 View 的實際點擊、focus 或聲音；必須分開標示實際 rendered callback 觀察。

### 直接正式 tests

保留 `RivetLoginPresentationTests.swift`／`RivetLoginContentTests.swift`，必要補充限定 `Tests/RivetPresentationTests/RivetLoginConsumerTests.swift`。Fixture／spy 只在 test module，直接 import／@testable import RivetPresentation，不能 import E011 runtime/model/fixtures 或 GitHubIntegration。驗原 helper、content、兩種 initializer、可用性資料與可觀察事件種類；不得自己呼 spy 就宣稱 View 發出事件。無法由單元測試觀察的實際 Return/Escape、clear/identity/focus/callback 移交受控 Preview 或 native case，明記來源與限制，不加正式測試 hook。

### 最小 native acceptance package

必要性：#Preview／純單元測試不能完整證明獨立 NSWindow、標準 Edit 選單／responder chain、Return/Escape、視窗 focus、資源 bundle 與 Human VoiceOver。因此新增 `tools/acceptance/login-ui`，不是產品 App。

- SwiftPM tools6.0、Swift language6、macOS15；package `RivetLoginAcceptance`，local dependency 明名 `Rivet`、path `../../..`，只取 `.product(name: "RivetPresentation", package: "Rivet")`。
- 僅三個 target：tool-local `RivetLoginAcceptanceSupport`、executable `RivetLoginAcceptance`、`RivetLoginAcceptanceSupportTests`。Support 依賴 Presentation；executable 依賴 Support；tests 依賴 Support 及必要 Presentation。不得 import E011 或 GitHubIntegration。跨 tool target 只公開必要啟動入口，不向正式 library 增加 API。
- Main/config/host/fixtures/tests 全在工具目錄，自有 `LoginAcceptanceParent`，不得重用 LoginDemoModel。可抽取調整 I02 parser／window 組裝的必要邏輯，但不複製正式 View／VO／整個原驗證工具。
- Parent 僅擁有 phase、bodyPointSize、content selection、canCreateToken、form generation、last event kind/count；有限事件回寫規則同 controlled Preview，提交值立即丟棄，無 credential/service/DI/auth/task/timer/storage/session/navigation。
- CLI 只選初始 state／appearance／text-size：`RivetLoginAcceptance [--state welcome|pat|waiting|verifying-account|verifying-token|browser-failure|token-failure|completed] [--appearance system|light|dark] [--text-size 13...21]`。預設welcome/system/13，未知／缺值／重複選項、非有限／越界字級在建窗前拒絕。新工具不需要 --preview 分流或 bundle 偵測；不改 E011 main。
- Host 一個原生主窗，780×500最小 content、原生 titlebar/traffic lights/可調整尺寸；直接組合正式 RivetLoginView。預設content=.standard、footer=`Connect your GitHub account to Rivet.`；failure 使用工具 fixtures 的中性可重試文字，不從 E011 copy/model取得。
- App/Quit、標準Edit選單保留。有限驗收控制在工具 Acceptance menu：phase、13/17/21字級、standard/controlled content、canCreateToken、Reset及唯讀last kind/count；不在主登入畫面加控制、overlay或獨立Controls窗。控制不設新快捷鍵，不占用mac截圖3/4/5/6；正式Return/Escape依原控制測試。
- Menu 對同一 parent 寫入，不更換NSWindow或Root identity；phase／字級／content控制與callbacks都可連續回寫。Reset才換form generation。Menu所記event只是kind/count，不保存或顯示token。
- 新wrapper為 `RivetLoginAcceptance.app`、bundle ID `local.rivet.login-ui-acceptance`，不覆寫／重用舊preview app。build腳本將binary及實際產出的RivetPresentation resource bundle放入新app，逐項記source／binary SHA／resource清單／新artifact位置；不可假定舊wrapper資源路徑等效。build產物及cache放topic外部scratch，不commit app／.build。
- 工具可有自己的Package.resolved；root Package.swift／Package.resolved／gitignore唯讀。SwiftPM解析local root仍可能需要transitive Apollo manifests/cache；不宣稱無cache需求或無任何依賴解析。若需變更root設定／rootlock，先停止相依操作提出最小proposal，先做其餘獨立工作。

### E011 freeze 的語法與語義限制

Freeze d2332bfff25510a3f78c1fbc8b0d2d9cf953b223，E011 tree b6a1e6e1196e64999af9591ec32f09211f1936c6；本輪HEAD tree a1fd3793fecdccf52c192158939629b58ca7c685。逐項操作見plan R3，model/README未變不碰。

Frozen host沒傳content，仍可由目前initializer的預設參數維持呼叫語法；model switch有default。因.standard現是產品文案，HEAD重建並不保證舊demo逐字／語意等效。本輪不再用E011作正式驗收，不加legacy.defaultdemo或footer／bundle偵測。歷史原貌只由完整freeze revision／原binary支持，本輪不重播。

### 圖、歷史與新binary

已讀 `login-lifecycle-v2-r1.json`，圖表達正式七態／外層事件，沒有E011路徑，正式graph語義未因consumer搬移而過期；本輪不重畫、不改凍結HTML／JSON／receipts。在可寫長期UI文字標註其舊consumer／受測版本與R3 ownership即可。若後續發現真正生命週期語義變更，再走原Archify驗證流程，不為修目錄重畫系統。

HC01/source3c9baf3、preview42e99fa、binary4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea的接受保留；新host／新Preview的受影響案例要新證據。先build與獨立source review，再提出exact新app／SHA／操作範圍取得當下確認；不沿用舊binary啟動許可。必要新Human VoiceOver只重驗本輪受影響焦點／宣告／同窗切態，不強制重做未改core的全部歷史矩陣，也不拿舊結果填新hostpass。
