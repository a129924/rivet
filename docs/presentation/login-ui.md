# Rivet 登入 UI

本元件屬 non-BC `RivetPresentation`，不依賴 `GitHubIntegration`。正式來源提供 SwiftUI 元件、呈現資料、局部 UI state 與 intents；認證、request 建構、儲存、session／clients 及產品 App 組裝留待後續。

## 組合與狀態所有權

唯一公開 View 是 `RivetLoginView`；internal 子元件不接收整個外層 model。

| 元件 | 輸入與 callbacks | owned state |
| --- | --- | --- |
| RivetLoginView | parent phase／content／footer／bodyPointSize／canCreateToken；轉發 RivetLoginIntent | 穩定 40:60 布局，無認證流程 state |
| LoginMethodSelection | 既有 welcome 文案；選 GitHub／PAT | 主操作的 keyboard／accessibility focus |
| LoginOAuthSection | waiting／browser failure、呈現內容；Cancel／Retry／改用 PAT | 區段焦點與可取消 UI 進入工作 |
| LoginPATForm | tokenEntry／token failure、文案與建立可用性；Back／Submit／Create | PAT 編輯、Show／Hide、欄位焦點 |
| LoginStatusNotice | verifying／completed 內容 | heading focus、可取消宣告 |

Parent 是 phase 唯一權威。Cancel／Escape、Retry 與 Submit 只發事件，不自行認證或推進 phase。PAT form 的 tokenEntry／token failure 保留同一 identity；送出取 trim 值後立即清除並隱藏，離開／消失／E011 Reset 同樣清除。內部空白不改，不驗 prefix。Show／Hide、字級／content 更新不清文字；建立入口不清編輯。

## 公開接線介面

```swift
RivetLoginView(
  phase: phase, footer: footer, bodyPointSize: 13,
  content: .standard, canCreateToken: false,
  onIntent: handleIntent
)
```

新增參數有預設值，原 label 呼叫與 trailing closure 仍可用。新增 enum case `createPersonalAccessToken`，下游 exhaustive switch 必須更新。僅在 canCreateToken=true 時發建立事件，View 不持 URL 或開 browser；停用 help／accessibility hint 由 content 提供。

`RivetLoginContent`／`RivetLoginStatusContent` 是 immutable、Equatable、Sendable 的 display-ready copy，具 public initializer。正式 `.standard` 無模擬／Demo Controls／example-only 文案。Connected 的標題／宣告為 `Sign-in completed.`，只表示本次登入完成，不表示 session、account payload、provider 或 clients 已建立，也不宣稱已保存憑證。Failure 沿用 parent 提供的 `RivetLoginFailure(message:origin:)`。

## 乾淨原生預覽（I02）

正式外觀預覽與下節受控展示是兩個獨立入口，使用同一 `RivetLoginView`；預覽固定傳入 `RivetLoginContent.standard`。Footer 與 failure message 不屬於 `.standard`，由預覽 host 提供中性正式文字：footer 為 `Connect your GitHub account to Rivet.`；兩種 failure 分別提示重試或檢查 token，不使用模擬錯誤文字。

乾淨 host 只建一個原生主窗，沒有 Demo Controls、測試 overlay、debug label、事件計數或測試選單。預覽的 parent 仍使用既有假事件處理，不接認證、儲存或 session；不會自動完成等待／驗證。驗證中與完成畫面由啟動參數指定，切換畫面需重新啟動。

同一既有 executable 的使用方式：

```sh
# 先在 feature checkout 使用固定依賴與標準 SwiftPM sandbox build。
swift build --skip-update --disable-automatic-resolution --product RivetLoginDemo
# 原生 GUI 透過下述獨立 .app wrapper 啟動，不直接執行裸 binary。
open "$PREVIEW_APP" --args --state pat --appearance dark --text-size 17
```

App-local CLI 契約為 `--preview [--state <state>] [--appearance system|light|dark] [--text-size <13...21>]`；預設 welcome／system／13，字級可為範圍內有限小數。State 是 welcome、pat、waiting、verifying-account、verifying-token、browser-failure、token-failure、completed。缺值、未知／重複選項及不合法字級在建窗前拒絕，退出碼2。

獨立 preview wrapper bundle ID 為 `local.rivet.login-ui-preview`，放於 feature `.build`，不 commit、不覆寫歷史 wrapper；此身分的 app 啟動即預設選 preview，`open` 不附 args 也不會誤開展示介面。一般 `RivetLoginDemo` 沒有 `--preview` 時仍啟動原展示 host／Controls。當前 wrapper 相對位置、build／差異測試與來源記於 [I02 證據](../../plan/rivet-login-ui-adoption/evidence/clean-preview-implementation.md)。

這是本次驗收入口修正，不表示新的 Human 外觀接受。T02／T03／H01–H08 原證據保留；獨立 T04／R04 只補驗本入口差異，再回 HC01 最終接受，尚未 merge。

## E011 受控展示

展示 host／Runtime／專屬測試維持 [E011](../../experiments/E011/README.md) 歸屬。E011 呼叫相同正式 View，由本地 `LoginDemoCopy` 提供模擬文字、假 phase 及事件處理；不呼叫真 VO／service。正式 library 無 demo mode。建立入口預設停用。

在 feature checkout 用 `swift build --product RivetLoginDemo` 建置，以 E011 既有 wrapper 操作。主窗最小 content 780×500 pt、40:60 雙欄、操作區垂直捲動，原生 titlebar／traffic lights／輸入控制保留。Controls 提供 Light／Dark、13／17／21 pt、七態、兩種 failure origin、模擬返回／完成與 Reset，不用 timer。

## 字級與狀態宣告

字級採既有 13...21 pt clamp，非有限值回 13；右側內容以同一比例調整，左側 AX 隱藏品牌維持設計。字級更新不重建 form。這是可重現的 UI 字級入口，不是已交付 macOS 系統文字大小偏好整合。

焦點與宣告由責任元件管理。各 await 後檢查 task 取消與 active 視圖／呈現輸入，離開後不得拉回焦點或宣告過期狀態。Welcome 聚焦主操作，PAT 聚焦欄位，waiting 聚焦 Cancel，browser failure 聚焦 Retry，verifying／connected 聚焦 heading。Waiting 的焦點 label 同時帶等待狀態與取消動作；獨立 announcement 用於 verifying／failure／completed。本輪 Human VoiceOver 受測案例已確認，範圍與限制見末節；最終視覺／UI 接受仍待 Human。

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


## 素材來源

接收日期：2026-10-22；使用者提供 `rivet_login_ui` 七份原件，已原樣歸檔在 `prototypes/rivet-login-ui/`。PNG 為外觀依據，Spec 補行為；原 scaffold 不參與編譯。素材內真登入／Keychain／PR 導覽敘述沒有當作本次已交付能力。

分支 mark geometry 來自 HTML 的三 circles／vertical stem／branch curve；dots、gradient、diff 使用原生 SwiftUI。`GitHubMark.pdf` 將該 HTML 內嵌 `githubIcon` path 轉為 24×24 pt 單色 PDF（SVG elliptical arcs 分段為 cubic Bezier、翻轉 Y 軸），以 `Bundle.module` 載入並標 template；不誤稱額外查證過官方品牌來源。未封裝系統字體。

| 原件 | SHA-256 | 原件 mtime（Asia/Taipei） |
| --- | --- | --- |
| `Rivet-Login-Dark.png` | `44823e32891e379b738e3a8d587dd8ccc6c153a6f89e3e406d8d75ace4e0e400` | 2026-10-21T12:06:54+08:00 |
| `Rivet-Login-Light.png` | `c02d1e3c857fd76af64936166886f0ed4431ee363f8be873ed8623d9b6f3f42a` | 2026-10-21T12:07:30+08:00 |
| `Rivet-Login-OAuth-Dark.png` | `aa84b79540f02199fdf99d075cd5df6219e0465a0cfb67059535180611f277df` | 2026-10-21T12:06:55+08:00 |
| `Rivet-Login-PAT-Dark.png` | `9a0e0b2e22ea2cc668f5aeffb62ff5d8948afd83631fc8985106ddf05bf15abc` | 2026-10-21T12:06:54+08:00 |
| `Rivet-Login-Prototype.html` | `bfef67912c39d39d07fffcebb5cd2924f9be8a9960b6a0be33d33fee01cacf9e` | 2026-10-21T12:06:50+08:00 |
| `Rivet-Login-Spec.md` | `e91487dfb126af40a838013d6bad2d53cbd571ccd6e30fbedb20bcd9480f336f` | 2026-10-21T12:05:55+08:00 |
| `RivetLoginView.swift` | `7906af649cca21e66f47b1bff1e662665365df7fbdd2adff95c009d53c11a2ce` | 2026-10-21T12:06:50+08:00 |

## 驗證與限制

舊 UI topic 的 HC-01 已有 Human「通過，採用目前這版」接受紀錄；入口原有 pending 摘要落後於 [舊驗證末段](../../plan/rivet-login-ui/evidence/verification.md)。此接受僅支持其來源與案例，不回填新版重構結果。

本 topic 的實作／測試證據見 [I01](../../plan/rivet-login-ui-adoption/evidence/implementation.md)，採用程度與方式見 [獨立採用紀錄](../feasibility-adoption.md)。初次I01／T01已完成helper／content／model自測與root Demo build，當時native操作未驗。後續原生與Human聲音補驗結果見本文件末節；最終視覺／UI接受仍pending，不能用model tests代替native UI或Human聆聽。

初次查核基線 `1f31b35` 的 root `swift test` 被既有 `FakePATSecurity` 缺 `GitHubOAuthSecurityClient.delete` 編譯缺陷阻擋，相關檔案與當時 base bytes 相同；原失敗歷史保留。上游修正後，本 feature 整合至 `ab77391`，root 實際執行 **361 tests／46 suites 通過**，正式 Demo build 也通過；本 topic 沒有修改認證來源。獨立 focused 32 tests／7 suites 證據仍只支持其 helper／content／model 範圍，不替代 native 互動。整合與 Draft 交付見 [D01／D02](../../plan/rivet-login-ui-adoption/evidence/delivery.md)。上游已有登入 runtime，UI 與其間的外層 Adapter 仍未接線。

[原七態 lifecycle](diagrams/rivet-login-ui/login-lifecycle.html) 保持凍結；本次 [後繼 lifecycle](diagrams/rivet-login-ui/login-lifecycle-v2-r1.html) 與 [BUILD 證據](diagrams/rivet-login-ui/BUILD.md) 記錄 UI events／parent-owned phase，文件層 VO 對應沒有畫成已接線 runtime。圖面視覺接受與產品 VoiceOver 接受是不同證據。

## 原生補驗：2026-11-17

受測正式來源為`83543b0`，沒有修改Swift元件。使用者重送視窗存取後，E011與外部public-consumer假parent完成N01–N16：PAT identity／Show-Hide／字級與content保留、trim提交／立即清除、Back／離開／Reset、七種intent單次回呼。八種畫面變體×Light／Dark×13／17／21pt共48組原生呈現／AX已補驗；代表性21pt截圖與ScrollView操作可到達Submit／footer。

詳見[原生補驗證據](../../plan/rivet-login-ui-adoption/evidence/native-ui.md)。原T01限制與T02當時VoiceOver待驗保留為歷史；R02獨立審查另記。後續Human聽覺確認見下一節，原生heading本身不代替聽覺證據，不宣稱topic已由Human最終接受。

## Human VoiceOver 補驗：2026-11-17

正式來源`1d5f2a0`與T02的Swift元件相同。Human已確認Welcome／waiting／Escape、PAT欄位／Show-Hide／編輯／提交、PAT失敗／再次提交、模擬完成／未連接帳號，以及帳號驗證／browser failure／Retry。正常流程回報沒有重複、漏讀或過期語音。同主窗Account→Welcome正常；Token→PAT修正外部host的截圖衝突快捷鍵後，Human確認PAT朗讀／焦點／直接輸入及沒有晚到舊宣告。

[Human聲音證據](../../plan/rivet-login-ui-adoption/evidence/voiceover-human.md)區分E011模擬copy與外部consumer正式copy，保留跨視窗Controls干擾及快捷鍵衝突的未驗歷史。結論限當次Human聆聽與所列操作，不外推所有OS語音佇列或race；正式元件、系統設定、認證與session均未改動。最終Human視覺／UI接受仍pending，TC06整體尚未完成，不merge。
