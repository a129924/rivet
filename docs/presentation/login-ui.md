# Rivet 登入 UI

本元件屬 non-BC `RivetPresentation`，不依賴 `GitHubIntegration`。正式來源提供 SwiftUI 元件、呈現資料、局部 UI state 與 intents；認證、request 建構、儲存、session／clients 及產品 App 組裝留待後續。

## 現行驗收歸屬：R3（2026-11-18）

正式 Login 核心／public API／content／children／helper／styles／artwork 不改。本輪 source 唯一正式區變更是 DEBUG 私有 `RivetLoginView+Previews.swift`：改用 @State controlled phase、13／17／21 pt、standard／controlled copy、建立可用性、form generation 與 last event kind/count。有限控制位於 wrapper 外，不混入正式登入主畫面；只有合法目前phase的callback才回寫。Submit不保存、檢視、hash或記錄payload。

同一generation切換tokenEntry↔token failure、字級／copy／建立可用性不重建root；只有明確Reset更換generation並清receipt，保留目前呈現設定。原先fixedphase／ignoreIntent不是互動驗證。既有直接正式helper／content／initializer tests足夠，未新增鏡像test或正式hook；真Canvas連續操作尚未執行，不能用tool parent unit tests冒稱正式View事件。

必要native差異由 [tools/acceptance/login-ui](../../tools/acceptance/login-ui/README.md) 的最小獨立SwiftPM package支撐。三個tool-local targets只透過path依賴root RivetPresentation product；自有configuration／parent／fixtures／NSWindow／Acceptance原生選單，不依賴E011／LoginDemoModel或GitHubIntegration，不copy View／VO。主窗預設.standard與中性footer／failure，無overlay或獨立Controls窗；有限phase／字級／copy／建立可用性／Reset／唯讀event receipt在Acceptance menu，沒有新快捷鍵、timer、Task或自動完成。

新artifact是RivetLoginAcceptance.app／local.rivet.login-ui-acceptance，build/cache在外部scratch，實際resource bundle及source／binary／resource／app tree SHA由build-app腳本保存。Root Package.swift／Package.resolved／設定唯讀；工具有自己的lock且transitive Apollo cache需求如實列出。先source/build/test與獨立review，再提出exact新binary及必要案例取得當下確認；確認前不launch、不沿用舊preview許可。見 [I03實作證據](../../plan/rivet-login-ui-adoption/evidence/acceptance-ownership-implementation.md)。

[T07原生差異證據](../../plan/rivet-login-ui-adoption/evidence/acceptance-ownership-native.md)保留9219bd76…版本的Dark有限操作與初版INCOMPLETE。RF03將同一正式bundle放到generated accessor首選的app根目錄後，新6a7867b5…artifact在Human明示exact版本、fallback可逆排除與shell open方式後完成F01–F06：Light13／Dark13以不同fresh process啟動，fallback兩次缺席時直接觀察GitHub圖示、有限互動及Light21 failure底部操作；fallback已完整還原，app／binary hash不變。[R07獨立有界復審](../../plan/rivet-login-ui-adoption/evidence/acceptance-ownership-native-review.md)已approved代理runtime／來源證據，無新增required fix，RF03在此次受控環境closed；不外推完整矩陣或其他SwiftPM／分發環境。[Human聲音差異證據](../../plan/rivet-login-ui-adoption/evidence/acceptance-ownership-voiceover-human.md)已取得V01／V02普通訊息回覆：Account→Welcome讀到Continue且沒有晚到帳號驗證語音；Token→PAT讀到PAT區塊、不點欄位可直接輸入、沒有晚到舊驗證語音。R07對這兩次有界attestation紀錄與界線已approved／無required fix；未完成嘗試與跨App焦點干擾歷史保留，不外推全部race／漏讀矩陣。Human於2026-11-18明確回覆「接受本輪驗收支援分離、封裝修正與差異補驗結果」，[HC02最終接受紀錄](../../plan/rivet-login-ui-adoption/evidence/acceptance-ownership-human-acceptance.md)對應code9d14a3f／證據196f42c與本6a binary。Canvas仍未驗，不將已揭露gap改寫為pass；Draft維持、不merge，未接認證／Adapter／儲存／session／navigation或產品App。

原HC01/source3c9baf3、preview42e99fa、binary4d4cf13...及H01–H08接受完整保留；本R3有限新host差異已另獲Human接受，Canvas未驗仍保留；不重開未變core的舊接受，也不把新host存在當產品認證／儲存／session接入。

## 組合與狀態所有權

唯一公開 View 是 `RivetLoginView`；internal 子元件不接收整個外層 model。

| 元件 | 輸入與 callbacks | owned state |
| --- | --- | --- |
| RivetLoginView | parent phase／content／footer／bodyPointSize／canCreateToken；轉發 RivetLoginIntent | 穩定 40:60 布局，無認證流程 state |
| LoginMethodSelection | 既有 welcome 文案；選 GitHub／PAT | 主操作的 keyboard／accessibility focus |
| LoginOAuthSection | waiting／browser failure、呈現內容；Cancel／Retry／改用 PAT | 區段焦點與可取消 UI 進入工作 |
| LoginPATForm | tokenEntry／token failure、文案與建立可用性；Back／Submit／Create | PAT 編輯、Show／Hide、欄位焦點 |
| LoginStatusNotice | verifying／completed 內容 | heading focus、可取消宣告 |

Parent 是 phase 唯一權威。Cancel／Escape、Retry 與 Submit 只發事件，不自行認證或推進 phase。PAT form 的 tokenEntry／token failure 保留同一 identity；送出取 trim 值後立即清除並隱藏，離開／消失同樣清除。現行 controlled Preview wrapper／acceptance parent 的明確 Reset 會更換 form generation，讓表單重建；新 consumer 的實際 rendered／native Reset 結果仍待差異驗證。內部空白不改，不驗 prefix。Show／Hide、字級／content 更新不清文字；建立入口不清編輯。

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

## 歷史：I02 乾淨原生預覽

以下保留I02當時入口與受測版本的說明，並非目前HEAD操作入口。R3已定點移除E011 preview分流／host／tests，當前驗收改歸上節；歷史原貌僅由完整I02 revision或原受測binary支持。

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

本次驗收入口修正維持既有UI範圍；Human接受決策與native補證分開記錄。T02／T03／H01–H08 原證據保留；T04／R04當時的啟動拒絕保留為歷史。取得Human對同一binary的當下確認後，[T05原生補驗](../../plan/rivet-login-ui-adoption/evidence/clean-preview-native.md)已觀察正式Welcome／waiting／PAT／verifying-token、兩種failure與completed，含Dark21捲動及Light17代表。最後留開Light13 Welcome；新preview的verifying-account未另做native重驗，沒有重跑完整矩陣或VoiceOver。後續Human已明示接受目前正式Login UI／UX，詳見末節；HC01完成，尚未merge。

## E011 凍結歷史與語義限制

E011 source逐項恢復至d2332bfff25510a3f78c1fbc8b0d2d9cf953b223，對應tree b6a1e6e1196e64999af9591ec32f09211f1936c6。只恢復本PR改動的三個既有檔並移除三個新增preview檔，model／README及其餘內容不碰。原I01/I02當時核准修改的歷史保持，不倒推越權；E011不再作本輪正式驗收consumer。

Frozen host未傳content，仍可由目前initializer的預設參數編譯，但會使用現行產品.standard。source凍結／可編譯不代表HEAD重建後與舊模擬文案逐字或語意等效；不加formal demo mode、legacy default或footer／bundle特判。若需歷史外觀，只能用完整freeze revision或原binary，本輪不重播。

## 字級與狀態宣告

字級採既有 13...21 pt clamp，非有限值回 13；右側內容以同一比例調整，左側 AX 隱藏品牌維持設計。字級更新不重建 form。這是可重現的 UI 字級入口，不是已交付 macOS 系統文字大小偏好整合。

焦點與宣告由責任元件管理。各 await 後檢查 task 取消與 active 視圖／呈現輸入，離開後不得拉回焦點或宣告過期狀態。Welcome 聚焦主操作，PAT 聚焦欄位，waiting 聚焦 Cancel，browser failure 聚焦 Retry，verifying／connected 聚焦 heading。Waiting 的焦點 label 同時帶等待狀態與取消動作；獨立 announcement 用於 verifying／failure／completed。本輪 Human VoiceOver 受測案例已確認，範圍與限制見末節；本輪Human已明示接受正式Login UI／UX，範圍見末節。

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

本 topic 的實作／測試證據見 [I01](../../plan/rivet-login-ui-adoption/evidence/implementation.md)，採用程度與方式見 [獨立採用紀錄](../feasibility-adoption.md)。初次I01／T01已完成helper／content／model自測與root Demo build，當時native操作未驗。後續原生、Human聲音與最終UI接受結果見本文件末節；不以model tests代替native UI或Human聆聽。

初次查核基線 `1f31b35` 的 root `swift test` 被既有 `FakePATSecurity` 缺 `GitHubOAuthSecurityClient.delete` 編譯缺陷阻擋，相關檔案與當時 base bytes 相同；原失敗歷史保留。上游修正後，本 feature 整合至 `ab77391`，root 實際執行 **361 tests／46 suites 通過**，正式 Demo build 也通過；本 topic 沒有修改認證來源。獨立 focused 32 tests／7 suites 證據仍只支持其 helper／content／model 範圍，不替代 native 互動。整合與 Draft 交付見 [D01／D02](../../plan/rivet-login-ui-adoption/evidence/delivery.md)。上游已有登入 runtime，UI 與其間的外層 Adapter 仍未接線。

[原七態 lifecycle](diagrams/rivet-login-ui/login-lifecycle.html) 保持凍結；本次 [後繼 lifecycle](diagrams/rivet-login-ui/login-lifecycle-v2-r1.html) 與 [BUILD 證據](diagrams/rivet-login-ui/BUILD.md) 記錄 UI events／parent-owned phase，文件層 VO 對應沒有畫成已接線 runtime。圖面視覺接受與產品 VoiceOver 接受是不同證據。R3只改驗收consumer歸屬，不改正式七態／intent語義；上述凍結圖及receipts不重產，圖的舊consumer與受測來源限制保留。

## 原生補驗：2026-11-17

受測正式來源為`83543b0`，沒有修改Swift元件。使用者重送視窗存取後，E011與外部public-consumer假parent完成N01–N16：PAT identity／Show-Hide／字級與content保留、trim提交／立即清除、Back／離開／Reset、七種intent單次回呼。八種畫面變體×Light／Dark×13／17／21pt共48組原生呈現／AX已補驗；代表性21pt截圖與ScrollView操作可到達Submit／footer。

詳見[原生補驗證據](../../plan/rivet-login-ui-adoption/evidence/native-ui.md)。原T01限制與T02當時VoiceOver待驗保留為歷史；R02獨立審查另記。後續Human聽覺確認見下一節，原生heading本身不代替聽覺證據，T02當時沒有Human最終接受；後續明示接受見末節。

## Human VoiceOver 補驗：2026-11-17

正式來源`1d5f2a0`與T02的Swift元件相同。Human已確認Welcome／waiting／Escape、PAT欄位／Show-Hide／編輯／提交、PAT失敗／再次提交、模擬完成／未連接帳號，以及帳號驗證／browser failure／Retry。正常流程回報沒有重複、漏讀或過期語音。同主窗Account→Welcome正常；Token→PAT修正外部host的截圖衝突快捷鍵後，Human確認PAT朗讀／焦點／直接輸入及沒有晚到舊宣告。

[Human聲音證據](../../plan/rivet-login-ui-adoption/evidence/voiceover-human.md)區分E011模擬copy與外部consumer正式copy，保留跨視窗Controls干擾及快捷鍵衝突的未驗歷史。結論限當次Human聆聽與所列操作，不外推所有OS語音佇列或race；正式元件、系統設定、認證與session均未改動。以上為T03當時證據與限制，當時TC06最終UI接受尚未完成；後續Human明示接受見下一節，不merge。

## Human 正式 UI 接受：2026-11-17

Human於乾淨預覽啟動、必要原生差異補驗及R05後，明確回覆「接受目前這版正式 Login UI／UX」。[HC01接受紀錄](../../plan/rivet-login-ui-adoption/evidence/human-acceptance.md)追溯交付`3c9baf3`／程式`42e99fa`及同一SHA4d4cf13f719e…的native preview；正式文案、視覺／UI與本topic局部互動已獲Human接受，連同T03聲音確認，TC06的Human部分完成。

此接受限本topic UI能力，既有測試與未重驗限制保持，不擴為真認證／VO Adapter／憑證儲存／session或所有環境保證。正式preview仍由假phase／事件處理驅動；PR維持Draft／未merge。本輪只同步接受紀錄，未修改程式或重跑測試。
