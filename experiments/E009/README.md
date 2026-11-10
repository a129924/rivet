# E009：獨立瀏覽器首次登入／授權驗證

## 1. 問題
現有直接 callback 證據無法回答未登入且未授權帳號的互動路徑。

## 2. 假設
開發端提供已核對的 App 設定後，Human 可在獨立未登入 session 完成 GitHub 登入、首次授權，並在同次 OAuth 流程取得有效帳號。

## 3. 最小操作
既有驗證工具啟動 listener 與新 session；手動複製本次網址，Human 在不共用登入狀態的獨立 browser session／無痕視窗貼上並親自登入／2FA／同意。啟動前由 Human 確認該 session 未登入 GitHub，測試帳號尚未授權此 App；條件無法確認便不啟動，不清理或撤銷任何既有授權。保留自動開啟方式。工具局部準備中，設定交接尚未確認。

## 4. 事前判準與投入上限
一次授權啟動、最多 300 秒；取消／拒絕／錯誤／逾時停止、不重試。四項：看見登入頁、完成登入、看見並同意授權、同流程有效帳號。四項齊備成功；明確同流程技術拒絕可判失敗；直接 callback、環境不符或證據不足為無法判定。僅 build／tests 不代替結果。

## 5. 環境與版本
既有 feat/github-first-sign-in 工具，起始 HEAD 9f603f81d77040a2e06ad178062e8cfecc4de468；實際 diff／測試結果待回填。不是已建立 provenance 的舊 binary 重驗。

## 6. 執行與觀察
未啟動真人授權。設定交接為執行前置缺口；不讀取舊 process Secret，不新增 Secret 儲存或要求 Human 手填。網址只經 App 複製至 Human 剪貼簿，不保存原值。

## 7. 是否成功
實驗狀態：未執行。真人驗證任務尚未完成；目前僅受限工具準備。

## 8. 決策影響與限制
保留 A07、C01、產品撤回與 PKCE 未判定。設定契約未解不得啟動。實驗結果不核准產品採用；所有秘密與帳號原值排除紀錄。

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

### M02 已接受：開發端本機操作

Human 已明示「接受此一次性本機方案」，M02 注入契約獲准實作；這不是本輪 OAuth ready。新 launcher 與 app-local 接線已建立，目前僅以 synthetic fixtures 檢查，真實設定未供給。

由持有測試 OAuth App 設定的開發端管理者，在**非錄製的本機互動終端**，於 feasibility worktree 執行以下指令。命令只含程式與 bundle 路徑，不含設定值；本輪登入驗證者不提供這些憑證，也不將任何值貼給 agent。若沒有管理者供給有效設定，真人操作保持未執行。

```sh
swift -swift-version 6 experiments/E009/LaunchVerification.swift --app-bundle ../agent-20261020-github-first-sign-in/.build/github-first-sign-in/ManualBrowserDerivedData/Build/Products/Debug/GitHubSignInVerification.app
```

launcher 會拒絕仍在執行的同 bundle App；切換前先核對並正常結束指定的舊 GitHubSignInVerification。它不終止其他 process、不讀舊配置、不建立平行 instance。實際接收設定僅在 hidden TTY；不要使用 agent exec session、shell 變數／參數、管線、錄製或重導向輸入設定。

成功輸出僅包含身分核對布林與尚未啟動 OAuth 的提示。工具還必須顯示「開發端設定已準備」；未顯示就停止，不按登入。系統可額外注入環境，因此不將 launch completion 當作配置與真人成功。

新入口的 binary 指紋已固定；若未來重建導致指紋不同，launcher 安全拒絕，須按來源／build 檢核重新凍結，不能刪掉驗證來繼續。

### M02 真人交接順序（尚未執行）

1. 開發端設定實際載入且新程序核對完成。
2. 提示 Human 開啟不共用登入狀態且未登入 GitHub 的獨立 browser／無痕 session，準備尚未授權此 App 的測試帳號。
3. 等待 Human 本輪明示 ready；先前的「開始」不是此時的 ready。
4. 才按一次「準備手動登入」建立 session／listener，開始最多 300 秒等待。
5. Human 從工具按「複製本次授權網址」，貼進獨立 session；親自登入、2FA 與同意，任何原值不回貼。
6. 四項分開確認；取消／拒絕／錯誤／逾時立即停止不重試。直接 callback 不記為首次登入／授權。

目前這六步尚未開始；E009 真人狀態仍為未執行。

### M02 準備交付與真人前停點（現行）

M02 bounded code review：**approved**，required fixes 無。已獨立檢查配置缺漏／test mode 禁 live、配置後隱藏憑證欄位、TTY／binary／程序身分檢查與有限錯誤輸出；不代表 Human ready、真實配置載入或 OAuth 成功。結合獨立 Tester 的17 definitions／18 executions pass，設定機制準備完成。

Actual：Written 唯一 experiments/E009/LaunchVerification.swift；M02 source Modify 為既有 App composition／coordinator／presentation／view 及 CoordinatorTests 五檔；M01 PresentationTests 沿用未再改動，仍納入六檔回歸檢查。文件 Modify 為 feasibility 四 artifacts 與 E009 README；Deleted 無。runtime／relay／probe／store／project／scheme、dev 及並行 planning／PKCE 工作不屬本輪改動。所有本輪 source／文件尚未 commit／push。

現行 status：human-check。下一個實際前置是 OAuth App 開發端管理者依 E009 的具體命令，在其本機非錄製終端經 launcher 準備設定；不得要求本輪登入驗證者提供憑證，也不從舊 App 取得。管理者未供給前，工具準備成果不能冒稱「真實設定已到位」。

工具必須顯示「開發端設定已準備」，再由 Human 確認獨立 browser session 未登入 GitHub、測試帳號未授權此 App，並回覆本輪 ready。這三項未全備前，不啟動 session／listener，不開始300秒計時。之後按 E009 六步操作，四項真人觀察分開記錄。原 A07、C01、H01、產品撤回及 PKCE 限制均不變；E009 真人狀態保持未執行。

## M03 本輪手動真人驗證結果（2026-10-21，現行）

記錄時間：2026-10-21 07:12:50 UTC；這是整理回報的時間，不是操作起訖時間。M03 是後續新證據，不覆寫原計畫、A07、已撤回的 L01、C01 或 M01／M02 當時的未執行紀錄。

### Human 回報與補充確認

使用者明確指出以下均由本人親自操作，是 Human 回報而非側對話 agent 獨立觀察：使用工具提供的本次授權網址手動開啟；看見 GitHub 登入畫面並完成登入；看見授權頁並親自同意；看見靜態 callback 收到提示；返回驗證 App 看見 API 查詢成功及帳號結果。未保存網址、callback 參數或帳號原值。使用者另表示側對話沒有修改文件、程式、Git 或 PR；本紀錄只將此列為 Human 陳述，不據此否認其他 worktree 的並行變更。

收到三項逐一補充確認：

| 前置／同輪條件 | Human 答覆 | 判讀 |
| --- | --- | --- |
| 不共用原登入狀態的獨立／無痕 browser session，開始時未登入 GitHub | 兩項都確認 | 前置已由 Human 明示確認；不是 agent 對 cookies 的檢查。 |
| 測試帳號在操作前尚未授權此 OAuth App | 確認操作前未授權此 App | 前置已由 Human 明示確認；不僅由看見同意頁推定。 |
| 使用 E009 新版同一次準備手動登入的網址，API 成功在 300 秒內，期間未重啟／再啟動／改用舊網址 | 以上都確認是同一輪 | 可在 Human 操作陳述層級綁定同一輪；不是獨立計時或 wire correlation。 |

### Agent 實際觀察與原碼推論

- Agent 本輪只做唯讀 process executable 路徑／磁碟 binary 指紋與 source 核對；當下可辨識一個預期新版 executable 路徑相符的程序，磁碟 binary SHA-256 為 `990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877`，符合先前受驗 build。這不是歷史執行 PID 收據，不能單獨回溯證明整輪。
- 六份受驗 Swift 的內容仍符合 M02 source snapshot；current source branch HEAD 已由並行工作前進到 `f420901a1076537c4f7aa0404fe31509b8bdc889`，但六檔仍為同一未提交受限 diff 內容。binary 不冒稱是在此新 HEAD 重建；M02 build 的來源基線／六檔指紋界線保留。
- 原碼契約：app-local live authorize 在同一 relay／session 建立後發布該 session 的授權網址，等待 callback 並交回同一 session.complete；runtime validatedCode 檢查 state 並限制單次 exchange；其後才建 provider／scope 並 probe。Account probe 只在 HTTP 200、正 id 與 trim 後非空 login 時產生有效帳號；success UI 在 probe 回傳後才設定。這是來源推論，不是本輪擷取的 HTTP status／body／token POST。
- Agent 沒有獨立看見本輪登入頁、同意點擊、callback 或結果畫面，也沒有 network trace、server log 或原始交換資料；未重開 App、再登入、再次查詢、重試或進行反向 PKCE。側對話 agent 的證據不被冒充為主 agent 觀察。

### 事前判準逐項判讀

| 必要觀察 | 結果與來源 |
| --- | --- |
| 看見 GitHub 登入畫面 | Human 明示確認，成立。 |
| 完成登入 | Human 明示確認，成立；是否出現 2FA 提示未回報，不另宣稱 2FA 測試通過。 |
| 看見並親自同意授權 | Human 明示確認，成立。 |
| 同一次流程取得有效帳號結果 | Human 確認同輪且看見 API 成功／帳號；配合原碼契約支持，成立於此證據層級。 |

**E009 現行實驗狀態：成功。**成立範圍是本次 Human 明示確認的獨立未登入 session、先前未授權測試帳號、一次 E009 手動流程、300 秒內完成登入／同意／有效帳號結果。真人驗證結果的紀錄判讀已完成；文件交付及 Human PR review 另列，不由此自動完成。

### 保留的缺口與限制

實際操作起訖時間與量測收據、原始 request／response、歷史 PID／session 的獨立關聯證據均未取得；本輪由 Human 陳述補足條件，不要求追補秘密。具體 App 設定供給者／是否真的使用互動 launcher、啟動前主對話 ready 的當時收據、2FA 提示均未獨立確認；不把本次成功追溯寫成主 agent 當時已啟動或見證。來源結構與目前正確程序不等於歷史 network trace。

本結果不證明完整零配置產品 UX、產品 readiness、production custody、persistence、公開發行或 PKCE enforcement；不改反向預算與 indeterminate。取消／拒絕／逾時等舊 mock checks 不升級成真人案例。本輪沒有新增操作或自動重試；原 H01 停在 Human review，不 merge。

### M03 九欄與變更紀錄

- Goal：核對並保存本輪受限真人結果、證據來源與剩餘缺口。
- Non-Goal：產品交付、network trace、Secret custody／PKCE 通過或新的登入操作。
- In-Scope：Human 五項回報／三項補充、來源與現況唯讀核對、M03 結果追加與獨立文件審查。
- Out-Of-Scope：source／tests／launcher 修改、其他 topic／並行工作、dev、授權／重試／cookies／憑證清理。
- ReadOnly：已受驗六份 Swift、runtime／relay／probe、現有 launcher、binary 指紋與程序路徑、Git／PR metadata；不讀 process env／參數／Secret。
- Written：本次操作沒有新檔案。
- Modify：feasibility requirements、technical-spec、plan、step，既有 experiments/E009/README.md，以及長期 docs/github-account-login-feasibility.md，合計六份文件。本輪不改 E009 launcher。
- Deleted：無，舊紀錄全部保留。
- TestCase：四真人判準／三前置逐項來源核對、source／binary 指紋、文件相對連結與敏感資訊／scope／diff 檢核；不重跑 OAuth 或以舊 mock 當本輪真人證據。

相對 M02 開始前是六檔追加；相對文件分支 HEAD，E009 README 仍為先前已建立、未追蹤的新文件。E009 launcher 與另一 source worktree 的 Swift 是先前未提交準備成果，本輪不混入文件發布，不冒稱文件 PR 已交付 Swift。工具圖只用實際文件 bounded diff；Graphify 無既有圖維持定向 source fallback，Archify 本輪不需產圖。

## M04 同一 PR 的重現與建置（2026-10-21）

本節為現行同 PR #63 的 build／操作路徑；前述依賴另一 worktree 的 M02 命令與 M03 指紋保留為歷史。以下命令在本 repository 根目錄執行，不需要原 source worktree，不代表此輪已獲新的真人 ready。

```sh
xcodebuild test -project apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj -scheme GitHubSignInVerification -destination 'platform=macOS' -derivedDataPath .build/github-account-login-feasibility/VerificationHostDerivedData
xcodebuild build -project apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj -scheme GitHubSignInVerification -destination 'platform=macOS' -derivedDataPath .build/github-account-login-feasibility/VerificationHostDerivedData
swift test
scripts/check-github-integration-consumer.sh
swift -swift-version 6 -strict-concurrency=complete experiments/E009/LaunchVerification.swift --self-test
```

上述 test scheme 設 unit-test mode，host 不建立 live dependencies。Implementer 本輪 host test／正常 build 均 exit 0（17 tests／5 suites），root 275 tests／34 suites pass；helper 另以 swiftc 的 Swift 6／complete concurrency 編譯後 synthetic self-test pass，未讀配置、未 launch App。launcher 以 `_ =` 明確丟棄清零操作回傳值，消除原 unused-result warning；其餘啟動／憑證邏輯不變。其他檢查與獨立 Tester／Reviewer 尚以最後紀錄為準。

新 build 位於 `.build/github-account-login-feasibility/VerificationHostDerivedData/Build/Products/Debug/GitHubSignInVerification.app`；binary SHA-256 `781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153` 已凍結於 launcher。此值僅綁定本機本次 build，不保證其他 compiler／path 重建的 binary 相同。重建 hash 不符時須停止並在來源／build 核對後另行凍結，不能關掉檢核或冒用 M03 的 `990917ac…`。

只有開發端管理者及 Human 完成前述本輪配置／browser／未授權帳號 ready，且另有真人操作授權時，才可在未錄製 TTY 使用以下本 PR bundle；本次未執行：

```sh
swift -swift-version 6 experiments/E009/LaunchVerification.swift --app-bundle .build/github-account-login-feasibility/VerificationHostDerivedData/Build/Products/Debug/GitHubSignInVerification.app
```

仍先拒絕既有同 bundle App，不讀舊 process／憑證、不秘密 argv／檔案／log。配置由開發端管理者隱藏輸入，登入驗證者不提供。未見「開發端設定已準備」不得開始；任何取消／拒絕／錯誤／逾時停止不重試。現行 M04 不進行上述真人步驟，不重跑 PKCE；M03 僅 Human 層級受限成功、C01 對 L01 的撤回與缺口均保留。

#### M04 Implementer 最後檢查收據

六項既有 hooks 全 pass：trailing-whitespace、end-of-file、Swift format、consumer contract、SwiftLint、renderer check。host／launcher 另跑 strict Swift format 與 SwiftLint（13 Swift files、0 violations），helper 以 `swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors` 編譯及 `--self-test` 均 exit 0，無真人啟動或設定輸入。

實際範圍恰 38 paths：26 new、12 modified、0 deleted；26 reuse byte/hash 全相等，`git diff --check` clean，未見本機使用者絕對路徑或 GitHub token 格式原值。檢查只覆蓋指定檔案，不宣稱全面秘密偵測。外部本機 M04 log 包含 host test／normal build、root test、six-hooks、local-checks、scope-equality 與新 binary SHA，未納入 Git。所有內容未 stage／commit／push，交獨立 Tester／Reviewer；不產圖、不更新 PR、不 merge。

#### M04 Tester setup 與最終 build 重凍結（2026-10-21）

獨立 Tester 回報首次 hosted mock setup 缺測試產物，補 `build-for-testing` 後重跑：17 definitions／18 executions、0 failures；隨後 normal build exit 0。這是測試產物準備／重建，不是 source 修改，也不是新真人 OAuth。重凍結前已核對原 38 個 repo 檔案 SHA 全未改。

最終 bundle 已核為 `781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153`，與前次 launcher 凍結不符。現行 launcher 與 M04 build 指紋已同步至此最終值；前一 M04 normal build 指紋 `96ee9b8661850577495206e78c1db8114aa2489a50758f3f48cacff098b01170` 已被最終 build supersede，僅保留為歷史，不再作目前啟動依據。M03 `990917ac…` 的原始真人證據不變。

本修正不 rebuild、不讀秘密、不啟動 App 或 OAuth；只變更 launcher 指紋與本五份文件中的現行值／補充收據，26 reuse source／tests／project 仍原樣。修正後 helper strict Swift 6 warnings-as-errors 編譯、synthetic self-test、局部 strict format／SwiftLint 已 exit 0（0 violations）；文件 consistency／whitespace 與新版 frozen 38 收據保存在外部 M04 evidence，交 Tester 局部核對，尚未 commit。

#### M04 獨立檢查結論與交付範圍

Tester 的最終 hosted mock 為 17 definitions／18 executions、0 failures，binary 重新凍結 RF01 已解除。獨立 Reviewer 在 architecture overview 的現況句修正後明示 approved、required fixes=[]；只審本 38 paths，不代表產品採用或新真人成功。M04 準備按既有授權提交／推送原分支、交同 PR #63；PR metadata 待主方更新與讀回，尚不宣稱已更新 PR。M03／C01／PKCE 與 production 限制保留，Human review 不自動通過。

## 2026-10-22：同步 dev 後的本機候選 build

本次只解同 PR #63 與 `origin/dev@14d0832f042720889993d769b4cbfb720078e6b1` 的十檔衝突。六 Swift 檔的 upstream 逐檔等於原 9f 基線，故保留已受驗 M01／M02 手動與配置增補；upstream 文件／獨立工具／PKCE 結果及額度原樣繼承，未執行它們。root Sources／Tests／Package 相對合併前 #63 無差異，沒有新 root 行為需重跑全 suite，也沒有新增測試定義。

沿用 M04 project／scheme／macOS destination 與 `.build/github-account-login-feasibility/VerificationHostDerivedData`，依序 `build-for-testing`、`test-without-building`、最後 normal `build` 全 exit 0；host 的 17 definitions／5 suites pass，其中一個參數化測試執行兩案，共 18 executions、0 failures；xcresult summary 為 17 definitions passed／0 failed。這只是既有 mock 契約／合併相容性核驗，不是 TDD 新行為或真人重驗。

最後 normal build binary SHA-256 為 `66aa6f9af216198df2e982aa2e9295fc16f9124e05a848aadac9676ae57dba2f`，launcher 已重凍結至此本機候選產物。M04 的 `781e1413…`／先前 `96ee9b…` 及 M03 `990917ac…` 均保留為各版歷史，不再視為本次現行 launcher 指紋，不用新 build 改寫真人結果。此值不保證其他 compiler／path 或重建相同；後續如再重建，必須重新核對，不可保留失配 launcher 或關閉檢核。

本次沒有真人 App launch、憑證輸入、OAuth 或 PKCE 操作。launcher 的隱藏 TTY、無秘密 argv／檔案／log、拒絕既有 App 與新程序身分檢核保持原樣；手動 URL 仍為同一 session、最多 300 秒、單輪後停止。合併候選尚未 commit，獨立 Tester／Reviewer 尚待核對；先前 approved 僅屬各歷史範圍。

本輪 launcher 已以 Swift 6／complete strict concurrency／warnings-as-errors 編譯及 synthetic self-test exit 0，明示無 live launch／credential input；host／launcher strict format、SwiftLint（13 files、0 violations）均 exit 0。此為 Implementer 檢查，獨立 Tester／Reviewer 尚待；未 commit／push，未重跑 PKCE／root 全 suite。
