# GitHub Account Login 受限可行性驗證計畫

日期：2026-10-21；Topic：`github-account-login-feasibility`。
[需求](../../analysis/github-account-login-feasibility/requirements.md)／[固定來源與限制](../../analysis/github-account-login-feasibility/technical-spec.md)／[狀態帳本](github-account-login-feasibility.step.md)。

## 1. 結論與執行狀態

技術路線可行；開發端提供 App 設定，使用者完成 GitHub 授權後，由程式 exchange token 並確認帳號，不自行註冊 App、輸入憑證或貼 token。OAuth 仍需 App 憑證；完整零配置產品 UX 未交付、本輪無真人重驗，公開發行 custody 未驗證。

保留原 A 五節結構與歷史限制。產品 B（`apps/Rivet`、launcher、composition、UI、產品測試、Human host 驗收及 S01–S06）已撤回，不恢復。本輪使用者明示保存文件並交付 Draft PR，因此 Written 由對話階段的無更新為五份新文件；新增固定來源僅提高追溯性，不代表真人重驗或產品交付。

本次為文件交付，不新增技術實驗；base 為 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`。既有 source／歷史 A07 證據使用 technical-spec 的外部固定 permalink，不虛構本分支已有那些檔案。

## 2. 九欄契約與檔案影響

| 欄位 | 本輪契約 |
| --- | --- |
| Goal | 保存免除使用者配置的技術可行性、既有實現及證據限制，交付 Draft PR。 |
| Non-Goal | 不交付產品、不宣稱 readiness、不核准發行、不 merge。 |
| In-Scope | 官方／固定原碼／歷史證據分類，四份 planning 文件及一份長期結論，文件檢核與獨立審查。 |
| Out-Of-Scope | 已撤回 B、Swift／App／UI／新測試／新實驗／架構圖、production custody、persistence、多帳號、新協定、負向 PKCE 重跑及其他 topic／BC 修改。 |
| ReadOnly | README、既有 docs、Sources、tests、apps、experiments、其他 topic、可用 graph 及固定外部來源。 |
| Written | 下列五份新文件；PR Lens 產物限外部暫存，不加入 repo。 |
| Modify | 無既有檔案修改；新文件可依審查修訂。無產品 API／interface 變更。 |
| Deleted | 無。 |
| TestCase | 第四節文件驗證，不新增 source tests、驗證腳本或實驗目錄。 |

唯一 repo manifest：

1. `analysis/github-account-login-feasibility/requirements.md`
2. `analysis/github-account-login-feasibility/technical-spec.md`
3. `plan/github-account-login-feasibility/github-account-login-feasibility.plan.md`
4. `plan/github-account-login-feasibility/github-account-login-feasibility.step.md`
5. `docs/github-account-login-feasibility.md`（獨立 planning review 後由 Implementer 建立，回鏈 technical-spec）

分支 `docs/github-account-login-feasibility`，type=`docs`、work-item=`github-account-login-feasibility`、無 owner；使用本次新文件 worktree，不沿用 PR #61 branch。已獲使用者明示 topic commit／push／Draft PR 授權；執行者仍須檢查 staged 語意範圍及訊息，不由 Plan-Creator 執行。

`swift-implementation` N/A；未來若真需最小實驗，開始前預定九欄、完成後按 actual diff／證據回填，不視為本輪授權。

## 3. 工具適用性

- Graphify 0.9.73：inventory 無既有 graph，使用定向 `rg` fallback；不建圖、不安裝。未來 CLI 須 `GRAPHIFY_NO_AUTO_REFRESH=1`，重要關係覆核 source。
- Archify 2.16：文字足夠，不產圖。未來若有具體未知才考慮本問題 sequence，遵守 showcase 九 checks、零 error／warning、validate／deliver／visual-check、繁中作者內容、英文 viewer fallback、本機不發布；圖不證明 OAuth 正確性。
- PR Lens 0.11.0：final topic commit 後，用真實 base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44` 至真實 head commit 的 `--find-renames` 五文件 diff，外部暫存 validate／render／manifest。保留 unchanged README 與 GitHub 來源依據的 context／file refs；外部來源以 pinned URL 標示，不假裝本 branch 有 source。記錄真實 SHAs／changed files，不採用舊 PR #61 diff、不造 commit 或 receipt。inventory 無 config，以 no-config 執行；若出現 config 只讀遵守，不改配置、不自動安裝或上傳。工具不可用時回報原因與 fallback，不冒稱成功；外部產物不增加 tracked files。

PR 建立由使用者獨立授權，非 PR Lens 授權。工具圖與 repo 文件驗證均不是新 OAuth 測試。

## 4. TestCase 與驗收

| ID | 文件檢核與通過條件 |
| --- | --- |
| TC01 | 官方憑證責任、code exchange 與有效帳號條件有來源；開發端配置標為推論。 |
| TC02 | 原碼／歷史紀錄均 pin 至真實版本；A07 執行 SHA 與保存紀錄 SHA 分開，零配置 UX 未冒稱已驗證。 |
| TC03 | P／Q indeterminate、版本限制、撤回 B 與 production 排除均保留；不依賴 PR #61 gate。 |
| TC04 | 相對文件連結／外部 pin／行號可追溯；沒有本 branch 缺檔的偽本機連結。 |
| TC05 | 實際變更恰為五新文件，無秘密或使用者本機絕對路徑；source／tests／apps／experiments／其他 topic 未變更。 |
| TC06 | 長期結論落入 docs，無新實驗；staged topic 語意一致，真實 commit／push／Draft PR 證據可追溯，停於 Human review、不 merge。 |

Tester 驗文件、來源與 scope，不跑產品測試或真人 OAuth；結果交獨立 Reviewer。尚未執行的步驟不得填通過，PR URL 產生前不得填寫。

## 5. 停止與交接

順序為獨立 Plan-Reviewer → Implementer 建長期文件 → Tester → 獨立 Reviewer → topic commit／push／Draft PR → Human。帳本逐步記錄實際證據，不以 status 代替 approval；Human boundary 僅在前置交付完成後生效，不提前阻斷文件工作。

若出現範圍外改動需求、未解來源衝突或工具權限問題，記錄具體限制交回，不擴成產品實作。每項新增技術工作須說明排除哪個未知、既有證據為何不足；本輪未知已由文件／來源解決，後續是明示保存交付而非新實驗。完成 Draft PR 後停於 Human review，不 merge。

## 後續 Human 正向重驗增補（2026-10-21）

> **2026-10-21 更正（以此為準）：使用者隨後明確表示沒有遇到 GitHub 登入畫面，也沒有進行 GitHub 登入授權。L01「本輪新授權／正向重驗成功」判定撤回，狀態改為「無法判定」。以下原判讀只保留為已被更正的歷史，不是有效成功證據。**

本節記錄文件交付後的使用者追加授權，不追溯改寫原文件階段 scope。使用既有驗證 App，事前限一次新授權、以有效帳號與 API 成功為判準，不新增程式、實驗或產品入口；不動用反向 PKCE 預算，也不增加重試或再次查詢。Human 已確認本輪完成新授權，agent 已觀察四項結果布林，詳 technical-spec L01。

本次九欄交接：Goal 為保存本輪重驗；Non-Goal 為零配置產品與 PKCE enforcement 證明；In-Scope 為 Human 確認與安全 UI 結果紀錄；Out-Of-Scope 為 source／tests／App／新實驗／其他 topic；ReadOnly 為既有工具與 binary；Written 無新檔；Modify 為本 topic 既有五份文件追加本次紀錄；Deleted 無；TestCase 為結果來源、binary 指紋、版本界線、文檔連結及敏感資訊檢核。完整 PR 仍待 Human review，不 merge。

### C01 更正範圍與九欄

本次要排除的是「L01 是否足以證明本輪新授權」的證據誤判。使用者最新更正與缺少流程關聯已足以撤回成功，不需新技術實驗；此處只更正既有紀錄，不增加待執行登入工作。

- Goal：撤回 L01 成功判定，保留 UI 觀察及更正歷史。
- Non-Goal：定位畫面來源、重跑登入或交付產品。
- In-Scope：五份文件與既有 Draft PR 的 C01 更正。
- Out-Of-Scope：Swift、App、憑證／session 清理、重試、新實驗與其他 topic。
- ReadOnly：既有 topic 文件、bounded diff 與 PR 狀態；不再讀取或操作登入 UI。
- Written：無新檔。
- Modify：本 topic requirements、technical-spec、plan、step 與長期 docs 五份既有文件，以及 PR 說明。
- Deleted：無；原誤判明標為已撤回歷史。
- TestCase：五檔均有顯著更正；現行狀態一致為無法判定；歷史成功語句不得當現行證據；無新登入、秘密或程式碼變更；連結與 diff 檢核。

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

### M02 Human 接受與實作進度

Human 已明示接受唯一的一次性本機方案。實際新增 experiments/E009/LaunchVerification.swift；app-local composition、coordinator、view、presentation 與既有 coordinator tests 已接線，M01 行為保留。沒有修改 runtime／relay／probe／store／project／scheme、另一工作的 PKCE scripts／fixtures 或其 planning；不新增 Secret storage。

TDD red 缺 Composition／init 接線；green build test exit 0。launcher synthetic self-test exit 0，live_launch_performed=false、credential_input_performed=false；嚴格格式與 lint 已通過（首次可失敗的字串解碼 lint 已修正為無效 UTF-8／過長輸入拒絕）。binary SHA-256 為 990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877，固定於 launcher；六檔 source bounded patch hash 為 a32959904d15c552bde67c676d68bc798e377f04d82498d23117e5f868651914。這是未提交工作快照與本輪 build，不冒稱新 head commit。

獨立 Tester／Reviewer 正在核對，未預填通過。真實設定尚未供給、App 未切換、OAuth 未啟動；操作指令與 Human ready 順序見 E009。所有原歷史與 C01 保留；H01 未通過、不 merge。M02 實際 Written=一個 launcher；Modify=本 topic 四 artifacts／E009 README，以及已授權六檔 Swift 的必要接線；Deleted=無。其他並行變更不混入本輪發布，尚未 commit／push。

### M02 準備交付與真人前停點（現行）

M02 bounded code review：**approved**，required fixes 無。已獨立檢查配置缺漏／test mode 禁 live、配置後隱藏憑證欄位、TTY／binary／程序身分檢查與有限錯誤輸出；不代表 Human ready、真實配置載入或 OAuth 成功。結合獨立 Tester 的17 definitions／18 executions pass，設定機制準備完成。

Actual：Written 唯一 experiments/E009/LaunchVerification.swift；M02 source Modify 為既有 App composition／coordinator／presentation／view 及 CoordinatorTests 五檔；M01 PresentationTests 沿用未再改動，仍納入六檔回歸檢查。文件 Modify 為 feasibility 四 artifacts 與 E009 README；Deleted 無。runtime／relay／probe／store／project／scheme、dev 及並行 planning／PKCE 工作不屬本輪改動。所有本輪 source／文件尚未 commit／push。

現行 status：human-check。下一個實際前置是 OAuth App 開發端管理者依 E009 的具體命令，在其本機非錄製終端經 launcher 準備設定；不得要求本輪登入驗證者提供憑證，也不從舊 App 取得。管理者未供給前，工具準備成果不能冒稱「真實設定已到位」。

工具必須顯示「開發端設定已準備」，再由 Human 確認獨立 browser session 未登入 GitHub、測試帳號未授權此 App，並回覆本輪 ready。這三項未全備前，不啟動 session／listener，不開始300秒計時。之後按 E009 六步操作，四項真人觀察分開記錄。原 A07、C01、H01、產品撤回及 PKCE 限制均不變；E009 真人狀態保持未執行。

## M03 結果保存增補與 actual 九欄（2026-10-21）

不重新啟動驗證；本輪僅核對Human已執行的回報，事前判準不變。Human逐一確認前置與同輪條件後，按原判準記E009為受限成功；缺少獨立trace／歷史程序關聯等限制另列，不升級證據。詳[E009](../../experiments/E009/README.md#m03-本輪手動真人驗證結果2026-10-21現行)。

| 欄位 | 本次操作實際影響 |
| --- | --- |
| Goal | 保存本輪受限真人結果、來源與缺口。 |
| Non-Goal | 產品readiness、production custody、PKCE或network trace。 |
| In-Scope | Human五項回報／三項補充、唯讀source／process／binary核對、六份文件追加及獨立審查。 |
| Out-Of-Scope | 新授權／重試、code／tests／launcher改動、dev及其他topic並行工作。 |
| ReadOnly | 受驗六Swift、runtime／relay／probe、既有launcher、binary指紋與process executable、Git／PR metadata；不讀env／參數／Secret。 |
| Written | 本次無新檔。E009 README是M01先前建立，對Git HEAD仍為未追蹤新文件。 |
| Modify | 本topic四artifacts、既有experiments/E009/README.md、docs/github-account-login-feasibility.md，六份文件。 |
| Deleted | 無，原紀錄保留。 |
| TestCase | 四真人判準／三前置來源、source／binary指紋、連結／敏感資訊／diff scope與獨立文件審查；不重跑OAuth／產品測試。 |

文件交付沿用docs分支；只stage上述六份文件。先前未提交launcher及另一feature的六Swift不混入本次文件commit／PR，不冒稱PR已交付工具。原source工作分支另有並行變更，不stage／push該處；不建立或切換分支。獨立Tester／Reviewer後依既有授權提交文件、更新同一Draft PR，再停H01 Human review，不merge。PR Lens只用實際文件diff，沒有可用graph則Graphify定向source查核，Archify N/A。

## M04 將驗證程式碼交付到同一 PR #63（2026-10-21 增補）

Human 明示「直接到 #63，不要再開新的」。因此前輪文件-only交付限制在本節受限放寬；歷史M01–M03／A07／C01不覆寫，仍不交付產品登入。沿用目前既有PR head分支／worktree，不建立、切換、改名或另開PR；docs前綴是既有PR歷史名稱，本輪內容已擴為可重現的驗證工具，PR title/body將依最終內容更新，不把原docs分支當新功能分支建議。

依賴查核：此head尚缺五個既有OAuth配置／factory／session／exchange/error檔。只帶手動入口不能編譯，因此從固定9f603f81d77040a2e06ad178062e8cfecc4de468原樣重用五檔與必要測試，不重寫runtime、不依賴PR61合併。App完整host亦取同pin，但六份M01/M02受驗Swift按已核對工作快照帶入。原source worktree完全唯讀；其中PKCE工具、判讀fixtures、其planning或其他並行更動不帶入。不cherry-pick／merge整條分支。

### 預定九欄與檔案

- Goal：讓PR63包含可建置／測試的驗證host、M01/M02入口、一次性啟動器及必要既有OAuth依賴，補足重現性。
- Non-Goal：產品入口、runtime新設計、PKCE／refresh401真人重跑、Secret store、PR61依賴或merge。
- In-Scope：下列精確manifest的原樣搬入、局部建置／測試、啟動器對本PR產物重凍結及操作文件、長期現況同步。
- Out-Of-Scope：apps/Rivet、其他BC、PKCE tools／人工判讀／fixtures、原source worktree寫入、dev、任何新真人授權。
- ReadOnly：固定來源與M02六檔snapshot、原source worktree其他變更、現有runtime/lifecycle/transport、秘密與執行中App不讀取。
- Written：下列新增runtime五檔／root tests三檔／App host十六檔、既有未追蹤E009 launcher納入Git、docs/architecture/github-first-sign-in.md；共26新tracked paths，actual待回填。
- Modify：既有root consumer/isolation tests兩檔；本topic四artifacts／長期docs／E009README與README、design-principles、architecture overview、OAuth dual-client現況文件，共12 paths；原source worktree零寫入。
- Deleted：無。
- TestCase：root OAuth/隔離測試、跨target consumer、App hosted mock suite、strict format/lint、launcher synthetic與新binary指紋／source清單／秘密掃描；不將重建或mock當M03真人重跑。

### 精確重用 manifest

- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationError.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationSession.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthCodeExchanger.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/GitHubOAuthAuthorizationSessionTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/GitHubOAuthCodeExchangerTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Resources/Info.plist`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/GitHubConnectionPresentation.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/GitHubConnectionView.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/GitHubLoopbackCallbackRelay.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/InMemoryOAuthCredentialStore.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Tests/GitHubAccountProbeTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Tests/GitHubConnectionCoordinatorTests.swift`（live-M02）
- `apps/GitHubSignInVerification/Tests/GitHubConnectionPresentationTests.swift`（live-M02）
- `apps/GitHubSignInVerification/Tests/GitHubLoopbackCallbackRelayTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Tests/InMemoryOAuthCredentialStoreTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）

其他兩個新tracked paths為 experiments/E009/LaunchVerification.swift 與 docs/architecture/github-first-sign-in.md。既有docs只更新對應能力現況，保留deferred產品UI／持久化及證據限制。新架構文件只記既有契約與app-local新增入口，不搬入另一topic diagrams／PKCE資料。未新增boundary或流程設計，Archify本輪N/A；Graphify無可用圖定向查source；PR Lens依實際新base/head凍結本機重製，不發布。

### 執行／交接

ID：M04；status：planned；owner：Implementer。完成條件為獨立plan-review、精確搬入、Tester／Reviewer、topic commit／push到同一PR63、PR實際diff／title／body讀回；actual九欄／來源相等檢查回填。新build不追溯替代M03 binary990917ac的歷史結果；launcher需核新binary重新凍結，M03不重跑。Human review H01不自動通過，不merge。

### M04 搬入與建置 actual（2026-10-21）

M04 planning 已由獨立 Plan-Reviewer 明示 approved、無 required fixes；Implementer 已原樣搬入清單 26 檔：20 檔 byte-for-byte 取固定 `9f603f81d77040a2e06ad178062e8cfecc4de468`，6 檔先核對 M02 SHA-256 再複製。來源 worktree／dev 零寫入，未攜入 PKCE tools、fixtures 或另一 topic 文件。新增聚焦初次登入契約與既有 E009 launcher，更新本節授權的現況文件；未啟動真人 App 或 OAuth。

Implementer 檢查：host `xcodebuild test` exit 0（17 tests／5 suites）、正常 host `xcodebuild build` exit 0、root `swift test` exit 0（275 tests／34 suites）；strict Swift 6 launcher compile／synthetic self-test exit 0，輸出明示無 live launch／credential input。launcher 另以 `_ =` 明確丟棄清零操作回傳值，消除既有 unused-result warning，未改啟動／憑證邏輯。六 hooks 與局部 lint／format 結果另於最後檢查紀錄回填。

本 PR 新 build binary SHA-256：`781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153`；launcher expectedBinarySHA256 已更新至此值。這是 M04 本機重建，不替換 M03 的 `990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877` 歷史真人指紋。獨立 Tester／Reviewer 與同 PR #63 Git 交付尚待進行，未 commit、push 或 merge。

#### M04 actual 九欄

| 欄位 | Actual |
| --- | --- |
| Goal | 將可重現驗證 host 與必要既有 OAuth 依賴交付同一 PR #63；搬入及 Implementer 建置已完成，尚待獨立驗證／交付。 |
| Non-Goal | 未恢復產品 B、runtime 設計、secret store、PKCE 真人重跑或 PR #61 依賴。 |
| In-Scope | 精確 26 reuse、launcher 重凍結、聚焦架構文件與十份文件現況同步。 |
| Out-Of-Scope | 未修改 apps/Rivet、其他 BC、PKCE 工具、source worktree、dev；未真人授權。 |
| ReadOnly | 固定 pin／六 snapshot、原 source worktree、既有 transport／provider／lifecycle 及秘密；未讀舊 App 配置。 |
| Written | runtime 5、root tests 3、host 16、launcher 1、聚焦架構 doc 1，共 26 新 tracked paths（目前尚未 stage）。 |
| Modify | root consumer／isolation tests 2；四 artifacts、長期 docs、E009 README 與四份現況 docs 共 10，合計 12 paths。 |
| Deleted | 無。 |
| TestCase | host mock／root suites、正常 build、helper synthetic 已完成；source equality／scope／六 hooks／局部 lint-format 結果另記，獨立 Tester／Reviewer 未執行。 |

#### M04 Implementer 最後檢查收據

六項既有 hooks 全 pass：trailing-whitespace、end-of-file、Swift format、consumer contract、SwiftLint、renderer check。host／launcher 另跑 strict Swift format 與 SwiftLint（13 Swift files、0 violations），helper 以 `swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors` 編譯及 `--self-test` 均 exit 0，無真人啟動或設定輸入。

實際範圍恰 38 paths：26 new、12 modified、0 deleted；26 reuse byte/hash 全相等，`git diff --check` clean，未見本機使用者絕對路徑或 GitHub token 格式原值。檢查只覆蓋指定檔案，不宣稱全面秘密偵測。外部本機 M04 log 包含 host test／normal build、root test、six-hooks、local-checks、scope-equality 與新 binary SHA，未納入 Git。所有內容未 stage／commit／push，交獨立 Tester／Reviewer；不產圖、不更新 PR、不 merge。

#### M04 Tester setup 與最終 build 重凍結（2026-10-21）

獨立 Tester 回報首次 hosted mock setup 缺測試產物，補 `build-for-testing` 後重跑：17 definitions／18 executions、0 failures；隨後 normal build exit 0。這是測試產物準備／重建，不是 source 修改，也不是新真人 OAuth。重凍結前已核對原 38 個 repo 檔案 SHA 全未改。

最終 bundle 已核為 `781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153`，與前次 launcher 凍結不符。現行 launcher 與 M04 build 指紋已同步至此最終值；前一 M04 normal build 指紋 `96ee9b8661850577495206e78c1db8114aa2489a50758f3f48cacff098b01170` 已被最終 build supersede，僅保留為歷史，不再作目前啟動依據。M03 `990917ac…` 的原始真人證據不變。

本修正不 rebuild、不讀秘密、不啟動 App 或 OAuth；只變更 launcher 指紋與本五份文件中的現行值／補充收據，26 reuse source／tests／project 仍原樣。修正後 helper strict Swift 6 warnings-as-errors 編譯、synthetic self-test、局部 strict format／SwiftLint 已 exit 0（0 violations）；文件 consistency／whitespace 與新版 frozen 38 收據保存在外部 M04 evidence，交 Tester 局部核對，尚未 commit。
