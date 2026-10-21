# GitHub Account Login 可行性技術依據

日期：2026-10-21。對應[需求](requirements.md)與[執行契約](../../plan/github-account-login-feasibility/github-account-login-feasibility.plan.md)。

## 結論與適用條件

開發端準備 App 設定時，終端使用者不必各自註冊 App、輸入 client ID／secret 或貼 token，既有 OAuth 授權、code exchange 與有效帳號確認路線可行。開發端配置責任的拆分是文件／程式結構推論，不是本輪零配置 UX 真人觀察。產品入口尚缺不構成新技術未知，也不授權建立 App。

## 來源與證據分類

官方文件於 2026-10-21 核對；原碼及歷史紀錄固定至 `90646c21bd9e6f0f19644f04efa39ef1c033a139`。下列 GitHub permalink 指向固定版本，並非本 branch 的本機檔案或目前 PR HEAD。

| 分類 | 來源 | 支持內容與限制 |
| --- | --- | --- |
| 官方事實 | [OAuth web application flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#web-application-flow) | authorize 使用 App client ID；token POST 要求 client ID／secret，PKCE 不免除 secret；流程包含 verifier／state 與 token 後的帳號確認。 |
| 官方事實／推論依據 | [REST basic authentication](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api#using-basic-authentication) | App credentials 屬於 App，不是 owner 或 authorizing user；由開發端提供設定符合此模型，但不是零配置 UX 實測。 |
| 原碼事實 | [App configuration](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift#L7) | public init 接受 client ID／secret 並檢核 trim 後非空，未規定由終端 UI 輸入。 |
| 原碼事實 | [OAuth composition](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift#L12) | configuration／redirect URI 建立 session、exchanger 與 state／verifier，支持程式自動 exchange 路線。 |
| 原碼事實 | [Account probe](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift#L20) | GET `https://api.github.com/user`，僅 HTTP 200、正整數 id、trim 後非空 login 為有效帳號；callback 或 token 單獨不足。 |
| 歷史觀察 | [A07 保存紀錄](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/plan/github-first-sign-in/evidence/verification-host-amendment.md#L60) | 記錄 2026-10-21／`e941d88` Human 手填驗證 App 配置後，真人 callback、真實 `/user` 及同 process 再次 `/user` observed pass。此 agent 未重跑或保存憑證值。 |
| 歷史限制 | [既有 topic ledger](https://github.com/a129924/rivet/blob/90646c21bd9e6f0f19644f04efa39ef1c033a139/plan/github-first-sign-in/github-first-sign-in.step.md#L1) | P／Q 各 2／2 反向 PKCE 預算耗盡且 indeterminate；後續 R05 approved／R06 Human review、R 0／1 未用僅屬文件調查，不是本 topic 前置 gate。 |
| 發行限制 | [OAuth App 最佳實務](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app) | native 隨附 secret 不可視為 server secret；公開發行 custody 未在本輪驗證，不提出新方案。 |

歷史 A07 的執行版本是 `e941d88`；`90646c21bd9e6f0f19644f04efa39ef1c033a139` 是本輪讀取其保存紀錄與原碼的來源 pin，兩者不混用。

## 分支與產品狀態限制

本次工作 base 為 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`；[base README](https://github.com/a129924/rivet/blob/16606b89b8e3e6b61523c23aa0be9653c1ea7b44/README.md) 仍將首次 OAuth／產品登入列為 deferred，不能因外部分支存在程式就宣稱 dev 已交付。

前輪 `dev@16606b8`、feature `82489b6`／`21e2542`、PR #61 Draft 未合併只是歷史快照。本 topic 不刷新其現況、不以其 merge 或 Human review 為依賴，也不修改其 artifacts。

## 是否需要實驗

不需要新實驗：官方條件、固定程式結構及歷史正向觀察已足以回答受限路線可行性。這不是宣稱完整產品驗收成功；build／tests／callback 不可單獨替代假設驗證。

`swift-implementation` 為 N/A。只有未來另有具體決策未知，且能說明既有證據不足，才依 feasibility skill 固定假設、區辨操作、成功／失敗／無法判定判準及有限預算，確認未占用 E### 後僅建立必要實驗素材與八段 README。開始前預定完整九欄，完成後依 actual diff／觀察回填；Written／Modify／Deleted 依實際缺口決定。此條件不是本輪新任務授權，不預選編號或虛構 manifest。

## 工具界線

Graphify 未見既有 `graph.json`，已用定向 `rg` fallback，未執行 Graphify CLI／建圖。若日後需要，只用既有圖、pin 0.9.73、每次 CLI 設 `GRAPHIFY_NO_AUTO_REFRESH=1`，重要關係回查 source。

本輪文字足夠，Archify 2.16 不產圖；若未來真需 sequence，先說明排除哪個未知與文字為何不足，遵守 showcase 九 checks、零 error／warning、validate／deliver／visual-check、繁中作者內容、英文 viewer fallback、本機不發布。任何圖均不是 OAuth 實驗證據。

PR Lens 0.11.0 用本 topic 真實五文件 diff，詳執行契約；無 config 時不假設存在，不自動安裝、上傳或改配置。

## L01：2026-10-21 本輪真人正向重驗（新增）

> **2026-10-21 更正（以此為準）：使用者隨後明確表示沒有遇到 GitHub 登入畫面，也沒有進行 GitHub 登入授權。L01「本輪新授權／正向重驗成功」判定撤回，狀態改為「無法判定」。以下原判讀只保留為已被更正的歷史，不是有效成功證據。**

- 觀察紀錄時間：2026-10-21 06:15:08 UTC。這是後續使用者要求的既有工具重驗，不是新產品交付或新的 PKCE 實驗。
- 事前範圍：最多一次新授權，成功必須看到有效帳號與 API 查詢成功；取消、逾時或錯誤即停止，不自動重試。不安排反向 PKCE、refresh／401 或額外再次查詢。
- Human 明示確認：「是，我剛在這輪完成登入授權」。這項確認用來區別本次新授權與先前留下的成功畫面。
- agent 在 Human 確認後以 AX 僅輸出結果布林：`apiSuccess=true`、`busy=false`、`failureVisible=false`、`identityDisplayed=true`。
- 判讀：**本輪既有驗證 App 正向重驗成功**。Human 確認新授權，agent 觀察到有效帳號結果呈現；不是由 callback 或 build 單獨推定。

### 執行物與來源界線

使用既有 GitHubSignInVerification.app，未重新 build；唯讀 process 檢查確認與預期 executable 路徑相符。其 binary SHA-256 為 `648435704a5a335040cb8abc6ad0f1841304500c4b9ab2dd96d79b1af7078a31`。本輪未建立 binary 與目前 source checkout 的一對一 build provenance，因此不把此結果冒稱為 90646c21、e941d88 或其他 source commit 的重驗。

agent 沒有重新觸發授權或操作「再次查詢」。本次沒有擷取 raw HTTP status／response、token POST 或 callback；正常授權依 Human 明示，帳號查詢結果依驗證 App UI 與已查原碼契約判讀，不冒稱獨立 network trace。

沒有確認本輪設定由誰於何時輸入；既有工具仍包含配置欄位。因此此證據不證明終端使用者零配置產品 UX、Production custody 或 PKCE enforcement。P／Q／後續反向驗證的舊結果與耗盡預算不變，不據此追加負向授權。

repository 紀錄不保存 client ID、secret、帳號原值、token、code、state、verifier、callback URL 或 screenshot。結果只保存 Human 確認、上述四布林、時間、binary 指紋與限制。原 A07 與文件階段的歷史事實不改判。

## C01：L01 判讀更正（2026-10-21）

使用者更正：「但是我沒有碰到 Github 登入畫面，也沒有授權 Github 登入」。以此更新 Human 事實；先前「是，我剛在這輪完成登入授權」的回覆保留為對話歷史，不能繼續作新授權證據。agent 將其與既有成功畫面合併推定本輪成功，屬證據判讀錯誤，責任不歸於使用者。

- 現行狀態：**無法判定**，本輪真人新授權與完整登入路徑驗證未完成；不是技術路線失敗。
- 尚可保留的觀察只有當時 UI 四項布林與 binary 指紋。它們不證明本輪發出新 request、取得新帳號回應或完成新授權；亦不能判定該畫面來自舊狀態、既有憑證、瀏覽器 session 或其他原因。
- 缺少證據：本輪授權啟動、GitHub 互動、對應 callback／exchange／帳號查詢的同一次流程關聯；沒有獨立 network trace。僅缺少登入畫面也不能單獨定位原因，本次不作歸因。
- 原文件／固定 source 與歷史 A07 的受限可行性依據維持；C01 不重新核准或否定該歷史證據。零配置產品 UX、PKCE enforcement 與 Human-review 限制不變。
- 本次只更正五份文件及同一 Draft PR 說明，不觸發登入、清除憑證／session、重建 App、重試或追加實驗。若後續需要重驗，須先固定能區別本輪與舊狀態的操作與觀測，再執行；本次未執行該工作。

## M01 受限手動瀏覽器驗證增補（2026-10-21）

使用者於 C01 後明示授權本增補並要求開始。原計畫、A07、已撤回 L01 與 C01 均保留；本節不是產品 B 恢復。真人步驟尚未啟動，不能宣稱成功。

未知是「未登入且未授權測試帳號，能否在同一 session 完成登入、首次同意與有效帳號確認」。舊直接 callback 路徑不足以回答，故需要一次受限真人操作。工具現只有預設瀏覽器立即開啟；最小增補僅改 app-local opener，不改 runtime／relay／probe。E009 保存操作契約，操作前已核對所有已註冊 worktree 及歷史編號；E001–E008 占用。

工具修改沿用既有 feat/github-first-sign-in worktree；不建立或切換分支。既有四份未提交 first-sign-in planning 檔案不動、不 stage。feasibility artifacts 與 E009 留在本 docs worktree，兩個 diff 分開回填，不把文件 PR 當 Swift 成果。

設定契約尚未解：現有 App 僅畫面輸入及記憶體設定，未找到重建後的開發端注入來源；不擷取既有 process Secret、不新設儲存／注入方式、不要求 Human 手填憑證。此項解除前不停止現有 App、不啟動真人授權。

九欄：
- Goal：準備首次登入與首次授權的同流程驗證。
- Non-Goal：產品交付、production custody、PKCE enforcement、新協定。
- In-Scope：手動模式建立 session／listener、只在記憶體發布本次網址供 App 複製；保留自動方式；必要局部測試、受限 build 及紀錄。
- Out-Of-Scope：apps/Rivet、正式入口、OAuth runtime、cookies／憑證／授權清理、反向 PKCE、自動重試、其他 topic planning 變更。
- ReadOnly：runtime、relay、probe、credential store、project 設定與既有未提交文件。
- Written：experiments/E009/README.md；沒有新 source 檔案。
- Modify：本 topic 四 artifacts；另一既有 feature 的 apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift、GitHubConnectionView.swift、GitHubSignInVerificationApp.swift、GitHubConnectionPresentation.swift，以及 Tests/GitHubConnectionCoordinatorTests.swift、GitHubConnectionPresentationTests.swift。
- Deleted：無。
- TestCase：manual 不開瀏覽器、同一 await 授權完成後才 probe、不能併發再啟動、取消／拒絕／逾時清理；auto 保留；四項真人結果分開記錄，設定未解即不執行。

執行判準：一次授權啟動，最多 300 秒；取消、拒絕、錯誤或逾時立即停止，不重試。Human 親自確認看到登入頁、完成登入、看到並同意授權；再加同流程有效帳號結果四項齊備才成功。直接 callback 僅支持返回路徑；build／tests／callback 或舊成功畫面均不足。

Graphify 無現有 graph，以定向 source 查核，不建圖。流程文字足夠，Archify N/A。PR Lens 僅對後續實際凍結 diff 本機產出，不發布；未產生不預填。授權網址與 credential／callback／帳號原值不進 log、文件或對話。

### M01 actual diff 與受限準備結果

- 本次 Modify 實際為另一既有 feature 的四 source（coordinator／presentation／view／App）與兩 tests（coordinator／presentation），與預定六檔一致；runtime／relay／probe／store／project／scheme 無改。本 docs worktree Modify 為四份 feasibility artifacts；Written 為 experiments/E009/README.md；Deleted 無。
- TDD red：build-for-testing exit 65，缺少手動啟動、copy dependency／presentation 等新成員；另有依賴新 signature 的 compiler diagnostic，未將其當真人證據。green：獨立 DerivedData 的 build test exit 0。
- 獨立 Tester 親跑 test-without-building exit 0，14 個 test definitions／15 次案例執行通過，0 failed／skipped；六檔 strict format 與 SwiftLint --no-cache exit 0。首次 lint 報 0 violations 但 cache 寫入遭拒，不計通過；後續無 cache 檢查已解。測試只用 mock，不驗真人或實際剪貼簿。
- 獨立 Reviewer：bounded code review **approved**，required fixes 無。同一次 session／relay 與原 300 秒 timer 保留；manual 不自動開 browser，單輪 guard、取消與結束清理複製入口；auto 保留。這不是 Human 操作許可或產品 approval。
- 六檔 bounded diff SHA-256：`fee0d2f958588a476892a31c4edc3d6dca4faf22dd2dd885c5a72212d2dbe1e6`；以私有 source-manifest 固定六檔內容，未把它冒稱新 commit／PR head。
- 並行變更：四份原有 first-sign-in planning 初查 4/4 指紋符合，末查全部與 baseline 不同。Main／Tester 未寫這四檔；來源尚未確認，不能聲稱整個 worktree 未變，也不歸入本輪 diff。已停止 source mutation／build／發布，未覆寫、stage 或還原這些內容。
- PR Lens 0.11.0：已凍結本機六檔 bounded patch 與內容指紋；validate 因未提交快照沒有 base/head provenance 而失敗，未捏造 head SHA、未 render／發布。fallback 為本機 source-diff.patch／manifest；不宣稱圖產出成功。Graphify 維持 source fallback；Archify N/A。
- 舊 App process 仍可辨識存在；沒有重啟舊 App、擷取設定、開真人授權、清除 cookies／憑證或撤銷授權。新入口已 build／mock 驗證，但尚未在真人用 App 載入。
- M01 工具準備完成；status：human-check。真人前仍須確認開發端設定交接、不共用登入狀態的 session，以及未授權測試帳號；來源不明 planning 並行變更需在發布前協調。設定未解前不要求 Human 填憑證或啟動 session。
- E009 狀態仍為**未執行**；四個真人觀察均未執行。原 A07、C01、PKCE 限制、產品撤回及 H01 均保留。未 commit／push 本次 source 或文件，也未更新任何 PR 為已完成。

## M02 開發端設定查核與具體待決方案（2026-10-21）

本節是尚待 Human 接受的增補，不是已實作的設定來源；M01 手動入口、A07、C01 與原限制保留。沒有啟動 OAuth，也沒有從舊 App 讀取 Secret。

### 唯讀查核結論

- 現行 SignIn App 的 composition 只讀 unit-test-mode 環境旗標；coordinator 的配置欄位初始為空，既有方式是畫面輸入、程序內記憶體。Shared Xcode LaunchAction 沒有 App 設定注入；VS Code 只有 Reader harness 啟動設定。
- public GitHubOAuthAppConfiguration 只接受 caller-provided ID／secret 並提供 redaction，不提供設定來源。
- 另一 persistent-connection 驗證 App 有 configurationStore，但綁 DPK group／service、signed host 與 embedded profile；credential-persistence 分支也有 explicit entitled access-group 的 shared store。這些不等於目前 ad hoc SignIn App 的可用設定來源；未讀 Keychain 內容，也未採用其 persistence／簽章契約。
- 歷史 E001 為 CLI client ID argument；E002／E003／PKCE 工具為 Human 互動輸入。它們不提供已備妥的 App 設定，且負向 PKCE 額度不動用。沒有讀取 env secret、私有設定檔、process memory 或舊 App secure field。
- 開發端仍須擁有有效的測試 OAuth App 配置；此方案只定義供給管道，不會產生或取得真實憑證，不能以 mock 代替。

### 唯一提案：一次性本機開發端啟動器

由擁有測試 OAuth App 的開發端管理者，在其本機非 agent 錄製的互動終端執行 E009 啟動器，以隱藏輸入提供既有 ID／secret；本輪登入驗證者不填這些資料。啟動器只以 app bundle 位置作命令參數，透過 NSWorkspace.OpenConfiguration.environment 啟動已核對的新版 bundle，使用兩個僅供此工具的程序環境 key：RIVET_VERIFY_GITHUB_CLIENT_ID／RIVET_VERIFY_GITHUB_CLIENT_SECRET。不可經 shell 字串、open --env 參數、scheme 檔或環境 dump 傳遞。

新版 App composition 讀取完整配對、建構既有 typed configuration，直接交給 coordinator；已配置時畫面僅顯示已準備，不展示配置值或要求輸入。缺值、半套、空白或 unit-test mode 不啟動真人能力；不從舊 App／Keychain／Token fallback。設定只存於 launcher 與 App 的程序記憶體／環境，不新增應用層持久化；不承諾 OS 不會留下痕跡或字串可安全抹除。退出後需由開發端再準備，不自動重啟／授權。已核對本機 SDK：OpenConfiguration.environment 只適用新程序；launcher 若發現同 bundle 已在執行便安全停止，不使用 new instance。切換時須先核實並結束指定舊 App，再由開發端準備新版啟動；不從舊程序搬移設定。啟動完成後，還須核對 NSWorkspace 回傳 App 的 bundle identifier、canonical bundle／executable 路徑及新 PID，確認與預期新 bundle 一致且不是啟動前程序。若重用既有程序、身分不符或無法確認，停止並不啟動 OAuth；不得只以 launch completion 判定設定已載入。

### 九欄與預定檔案（待接受）

- Goal：用明確的開發端供給管道解除新版工具設定缺口，使真人驗證者只負責 GitHub 登入與同意。
- Non-Goal：取得／產生憑證、產品登入、Secret store、DPK／Team／profile 變更、多帳號、persistence、新協定。
- In-Scope：一次性 launcher 與 app-local composition 配置接線、最小 mock tests；沿用 M01 manual session／listener。
- Out-Of-Scope：dev、apps/Rivet、OAuth runtime／relay／probe、另一工具的 storage、並行 PKCE 工作及其 planning、讀舊 App Secret。
- ReadOnly：既有 source 契約、schemes／launch 設定、相關 store 原碼及 source worktree 的其他變更。
- Written：只預定 experiments/E009/LaunchVerification.swift；不建立含配置的檔案或新 store。
- Modify：feat/github-first-sign-in 既有 apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift（環境解析）、GitHubConnectionCoordinator.swift（typed configuration 注入）、GitHubConnectionView.swift（已配置狀態）、Tests/GitHubConnectionCoordinatorTests.swift（配對／缺值／test-mode／不顯示敏感值測試）；需要 presentation 狀態時才沿用既有 GitHubConnectionPresentation.swift 與其 test，不擴大 target／project。feasibility 四 artifacts 與 E009 README 只追加契約及實際結果。
- Deleted：無。
- TestCase：完整配對可注入；缺值／半套／空白安全拒絕；unit-test mode 零 live；未配置不啟動；已配置畫面不要求憑證；launcher 無秘密 args／檔案／log，錯誤有限分類；既有 App 在跑即拒絕、回傳錯誤 bundle／路徑／舊 PID／無法確認身分均拒絕；manual／auto 舊測試保留。真實供給與 UI 不由 mock 通過代替。

此工作排除「新版如何取得開發端配置」的具體缺口；現有欄位與另一 storage 契約不足以滿足本輪免手填且不擴張架構的要求。此新增注入契約尚待接受，未實作／build／測試。

### Worktree／Human 操作停點

source branch 仍為 feat/github-first-sign-in，feasibility 文件仍為 docs/github-account-login-feasibility；沒有建／切／推分支。M01 受審六份 Swift 指紋重查吻合；其他 planning／PKCE scripts／fixtures 的並行變更不歸入本輪，不覆寫、stage、commit 或執行。dev clean。

方案接受後完成必要實作／獨立檢查；開發端供給到位才切換新版。接著先提示 Human 準備不共用登入狀態且未登入 GitHub 的獨立 browser session，以及尚未授權此 App 的測試帳號；取得本輪 ready 後才啟動一次 session／listener及最多 300 秒等待。Human 從工具複製並貼上網址，親自登入／2FA／同意。取消／拒絕／錯誤／逾時停止不重試。四項觀察（看到登入、完成登入、看到並同意授權、同流程有效帳號）分別記錄，齊備前不宣稱成功。原 H01 保留。

### M02 來源定位與版本補充

下列是對應來源 worktree 的相對路徑，不表示文件分支含有該 source，也不是 source build provenance。2026-10-21 唯讀查核；SignIn 前兩檔含 M01 工作快照，必須用內容 hash 區分 parent HEAD。

| 來源版本／位置 | 支持內容 | 工作檔 SHA-256 |
| --- | --- | --- |
| `feat/github-first-sign-in@9f603f81d77040a2e06ad178062e8cfecc4de468`；`apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift`，行 10 | composition 只讀 unit-test 旗標；沒有配置來源 | `59f15c2792158512e2b4dec81e75967ecbbe58b7f956f0d336a736cf9b704f98` |
| `feat/github-first-sign-in@9f603f81d77040a2e06ad178062e8cfecc4de468`；`apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift`，行 71, 72 | clientID／clientSecret 初始空欄位；M01 不含設定 loader | `d46b85e8c14aeb7d8470130efbc4eeea82052aec9dd1dd49d16ae07d54e850c8` |
| `feat/github-first-sign-in@9f603f81d77040a2e06ad178062e8cfecc4de468`；`apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme`，行 4, 5 | TestAction 只有 unit-test 旗標，LaunchAction 無設定注入 | `1b6e21c4c93a39b9037494014c50b9a7562c3768f185c15e2f1a8d179e36b464` |
| `feat/github-first-sign-in@9f603f81d77040a2e06ad178062e8cfecc4de468`；`apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj`，行 51 | ad hoc 簽章設定及非 sandbox，未納入 DPK group/profile | `f148863c49fc65aeb2ddd9415abe60b3fb850f4a13ff324a78cf00aff777b05c` |
| `feat/github-persistent-connection@1c8e2c85fe417daf4ad20dfdaa5e2604edf07631`；`apps/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift`，行 11, 56, 59 | configurationStore composition 先檢 group 與 embedded profile | `12797a0bc7bbf9b5f03d0724937277b64dceeeb9444da97d5faec9b12d477d86` |
| `feat/github-persistent-connection@1c8e2c85fe417daf4ad20dfdaa5e2604edf07631`；`apps/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift`，行 26, 30, 35, 91 | configurationStore 綁 backend accessGroup／service | `b2e55652df45e573c138a6acdf5495586dbec03268fbd4aad08a1558a565a282` |
| `feat/github-oauth-credential-persistence@ec193a26c54a7efd243dc04821e9e8ffe0ec0a78`；`Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift`，行 34, 37, 41, 49 | shared store 建構要求 signed host 的 entitled explicit access group | `023b33f6bece762acefa628e8975d7646d7457b50524ea37d050db18f4a13b00` |
| Xcode 26.6（17F113），SDK `AppKit.framework/Headers/NSWorkspace.h` 行 46、188–190 | openApplication 使用 OpenConfiguration；environment 只對新 instance 生效，系統可追加環境變數 | `be46224f91d11b7d0e25a0ed80dda5c1a9e52c404038a5a7ebfc25794befff30` |

因此採最小新注入方案前需 Human 接受；既有 store 不因來源存在就視為當前 host 可用，亦未用 source／SDK 推定已有真實配置。M02 初審 needs-rework 的兩項（來源追溯與啟動後身分核對）已補正，待獨立回查。

### M02 Human 接受與實作進度

Human 已明示接受唯一的一次性本機方案。實際新增 experiments/E009/LaunchVerification.swift；app-local composition、coordinator、view、presentation 與既有 coordinator tests 已接線，M01 行為保留。沒有修改 runtime／relay／probe／store／project／scheme、另一工作的 PKCE scripts／fixtures 或其 planning；不新增 Secret storage。

TDD red 缺 Composition／init 接線；green build test exit 0。launcher synthetic self-test exit 0，live_launch_performed=false、credential_input_performed=false；嚴格格式與 lint 已通過（首次可失敗的字串解碼 lint 已修正為無效 UTF-8／過長輸入拒絕）。binary SHA-256 為 990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877，固定於 launcher；六檔 source bounded patch hash 為 a32959904d15c552bde67c676d68bc798e377f04d82498d23117e5f868651914。這是未提交工作快照與本輪 build，不冒稱新 head commit。

獨立 Tester／Reviewer 正在核對，未預填通過。真實設定尚未供給、App 未切換、OAuth 未啟動；操作指令與 Human ready 順序見 E009。所有原歷史與 C01 保留；H01 未通過、不 merge。M02 實際 Written=一個 launcher；Modify=本 topic 四 artifacts／E009 README，以及已授權六檔 Swift 的必要接線；Deleted=無。其他並行變更不混入本輪發布，尚未 commit／push。

### M02 準備交付與真人前停點（現行）

M02 bounded code review：**approved**，required fixes 無。已獨立檢查配置缺漏／test mode 禁 live、配置後隱藏憑證欄位、TTY／binary／程序身分檢查與有限錯誤輸出；不代表 Human ready、真實配置載入或 OAuth 成功。結合獨立 Tester 的17 definitions／18 executions pass，設定機制準備完成。

Actual：Written 唯一 experiments/E009/LaunchVerification.swift；M02 source Modify 為既有 App composition／coordinator／presentation／view 及 CoordinatorTests 五檔；M01 PresentationTests 沿用未再改動，仍納入六檔回歸檢查。文件 Modify 為 feasibility 四 artifacts 與 E009 README；Deleted 無。runtime／relay／probe／store／project／scheme、dev 及並行 planning／PKCE 工作不屬本輪改動。所有本輪 source／文件尚未 commit／push。

現行 status：human-check。下一個實際前置是 OAuth App 開發端管理者依 E009 的具體命令，在其本機非錄製終端經 launcher 準備設定；不得要求本輪登入驗證者提供憑證，也不從舊 App 取得。管理者未供給前，工具準備成果不能冒稱「真實設定已到位」。

工具必須顯示「開發端設定已準備」，再由 Human 確認獨立 browser session 未登入 GitHub、測試帳號未授權此 App，並回覆本輪 ready。這三項未全備前，不啟動 session／listener，不開始300秒計時。之後按 E009 六步操作，四項真人觀察分開記錄。原 A07、C01、H01、產品撤回及 PKCE 限制均不變；E009 真人狀態保持未執行。

## M03 同輪綁定與證據資格（2026-10-21）

Human 五項操作回報與三項前置／連續性補充，詳[本輪 E009 紀錄](../../experiments/E009/README.md#m03-本輪手動真人驗證結果2026-10-21現行)。同輪、獨立未登入、帳號未授權與300秒均為 Human 明示，agent 未獨立重建歷史。依此及下列原碼契約，判讀為受限成功，不是 network trace。

- `GitHubConnectionCoordinator.swift` 行27–48：同一次 live authorize 建 relay／session，發布本 session 網址，callback 回同 session.complete，保留300秒timer；行155與205–218才執行 provider／scope／probe並設定成功UI。
- `GitHubOAuthAuthorizationSession.swift` 行52–76與125–128：單次 claim/exchange、state 檢核與 deadline；這不證明遠端 PKCE enforcement。
- `GitHubAccountProbe.swift` 行20–34：HTTP200、正id、非空login才回傳帳號。這些是對 source 的推論，不是本輪HTTP原值觀察。

上述路徑分別相對於原source worktree的 `apps/GitHubSignInVerification/Sources/` 與 `Sources/BoundedContexts/GitHubIntegration/OAuth/`。current HEAD f420901a1076537c4f7aa0404fe31509b8bdc889 含並行前進，但受驗六Swift仍與M02 snapshot逐檔相符；不把它當新binary的build commit。當下預期executable路徑相符，磁碟binary SHA256仍為990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877。沒有獨立觀察本輪UI、network trace或歷史PID關聯。

未取得精確起訖量測、設定供給者／互動launcher實際執行證據、啟動前主對話ready收據或2FA提示紀錄；不要求追補秘密或重跑。四主判準已由Human確認，以上為證據層級限制，不將其補成已驗。原產品／custody／PKCE限制及C01不變。
