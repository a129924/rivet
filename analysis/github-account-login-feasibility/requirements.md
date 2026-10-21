# GitHub Account Login 可行性需求

- Topic：`github-account-login-feasibility`
- 日期：2026-10-21
- 性質：可行性證據保存與文件交付，不是產品登入實作。
- [技術依據](technical-spec.md)；[執行契約](../../plan/github-account-login-feasibility/github-account-login-feasibility.plan.md)；[狀態帳本](../../plan/github-account-login-feasibility/github-account-login-feasibility.step.md)。

## 目標與使用情境

開發端可準備必要 GitHub App 設定。終端使用者只點登入、完成 GitHub 登入與授權、返回 Rivet 並確認有效帳號，不自行註冊 App、不填 client ID／secret、不貼 token。這不是要求 OAuth 協定完全不使用 App 憑證。

本 topic 回答此技術路線是否可行、既有程式已實現到哪裡，以及證據支持範圍。使用者已要求將認可的 feasibility-only 計畫落檔、保存長期結論，依 topic commit／push／建立 Draft PR，停於 Human review；不恢復產品實作。

## 範圍與成功條件

- 以官方文件、固定原碼及歷史正向證據，分開陳述事實、推論、觀察與限制。
- 明確說明開發端配置與自動 token exchange 的路線可行，但完整零配置產品 UX 未交付、未經本輪真人驗證。
- 保存五份文件：本 topic 四份 planning artifacts，以及待 Implementer 建立的 `docs/github-account-login-feasibility.md`。
- 檢核來源 pin、文件連結、五檔範圍、無秘密／本機絕對路徑及撤回界線；獨立審查後交付 Draft PR，不 merge。
- 不以 build、tests 或 callback 單獨替代主要問題的證據，不宣稱 PR #61 gate 通過。

## 非目標

不新增 Swift、App、launcher、UI、產品測試、實驗、架構圖或 public API；不設計 production secret custody、持久化、多帳號、新協定或遠端 refresh；不重跑負向 PKCE、不修改其他 topic／BC，不依賴 PR #61 的 branch、merge 或 Human gate。

## 變更紀錄

| 日期 | 決策 |
| --- | --- |
| 2026-10-21 | 保留原 A 五節可行性計畫及來源限制。曾提出的 B 產品 slice（含 `apps/Rivet`、launcher、composition、UI、產品測試、Human host 驗收及 S01–S06）已明確撤回，不是待執行工作。 |
| 2026-10-21 | 原對話階段 Written／Modify／Deleted 均為無，計畫未落檔。本輪依明示保存與交付指示，Written 更新為五份新文件；Modify／Deleted 仍為無。 |
| 2026-10-21 | 本輪額外固定來源至 `90646c21bd9e6f0f19644f04efa39ef1c033a139`，提高原碼及歷史紀錄可追溯性；不構成真人重驗，也不表示 base dev 已有該 runtime。 |

## 未驗證事項

完整零配置產品 UX、公開發行 custody 與長期持久化均未驗證，屬範圍外，不是本輪 pending implementation。沒有尚須執行才能排除、且影響本次技術選擇的新未知，因此不新增實驗。

## 後續 Human 正向重驗（2026-10-21 新增）

> **2026-10-21 更正（以此為準）：使用者隨後明確表示沒有遇到 GitHub 登入畫面，也沒有進行 GitHub 登入授權。L01「本輪新授權／正向重驗成功」判定撤回，狀態改為「無法判定」。以下原判讀只保留為已被更正的歷史，不是有效成功證據。**

使用者於文件交付後另行要求真人實證，並明示剛在本輪完成登入授權。本次只重驗既有 GitHubSignInVerification 的正常授權與帳號結果；不恢復產品 B、不新增 Swift／實驗程式、不重跑反向 PKCE。原文件交付階段「無真人重驗」保留為當時事實；本次觀察另記 L01，不覆寫 A07。

### C01 本次更正

本輪真人新授權驗證未完成，L01 改為「無法判定」；不以舊畫面或前一則肯定回覆代替本次登入授權。原可行性問題、歷史 A07 與產品撤回範圍不變。本次僅修正文義與證據資格，不新增實驗或產品工作。

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

## M03 後續真人結果與範圍（2026-10-21）

Human 親自回報手動開本次網址、完成登入／同意、callback 及 API 成功／帳號結果；另逐項確認獨立未登入 session、測試帳號操作前未授權、同一 E009 輪次且300秒內未重啟／再啟動／換舊網址。四項主要判準在 Human 回報與原碼契約支持的層級成立，E009 現行狀態為受限成功。

這不追溯改寫 A07、C01 或先前未執行狀態；不恢復產品範圍。本輪只追加六份文件，不修改 source／launcher 或進行任何新授權。來源分層與未獨立確認事項以[本輪 E009 結果](../../experiments/E009/README.md#m03-本輪手動真人驗證結果2026-10-21現行)為準；Human review 仍待決。
