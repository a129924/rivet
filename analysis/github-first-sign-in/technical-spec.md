# GitHub 首次登入：技術契約

- Topic：`github-first-sign-in`；2026-10-20 Plan-Creator 驗證 host amendment，已獲獨立 Plan-Reviewer A02 approved（無required fix）。
- 配對：[requirements](requirements.md)、[plan／manifest](../../plan/github-first-sign-in/github-first-sign-in.plan.md)、[step](../../plan/github-first-sign-in/github-first-sign-in.step.md)。

## U：Human-only 原文語義 review（既定技術與規劃來源；離線已授權實作）

本節只定義未來候選，不修改 §11 或 P/Q/R/T 歷史、正式 OAuth／public API／lifecycle。本輪來源 `9f603f81d77040a2e06ad178062e8cfecc4de468`；Human 可見性風險已接受進入規劃，獨立 Plan-Reviewer 已明示 U02 formal planning verdict approved、無 required fix；整體停 Human／human-check，未授權實作／校準／live，新 OAuth 額度 0。下列「必須」是未來另行放行後的契約，不是現在的操作授權。

### U1. 目的與獨立觀測軸

v3 安全摘要保留詞彙卻丟失文字順序、否定、條件、例子及因果；synthetic 肯定／否定因果句可有相同摘要，不是歷史原文重建。依 [RFC6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2) 與 [RFC7636 §4.6](https://www.rfc-editor.org/rfc/rfc7636.html#section-4.6)，invalid_grant 可有多種原因；[GitHub token troubleshooting](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors) 未給穩定 verifier-exclusive 句法契約，不再用猜句型補證據。

新增獨立 `provider_semantic_observation`，review_source 固定 `local_human`。它是 Human 對當次 provider statement 的語義 attestation，不是 agent 獨立認證因果、不改既有 `pkce_rejection_proven`／outcome、不回填舊案。沒有原文保存，因此 agent／Reviewer 無法獨立稽核原句。候選分類只有：

| semantic_category | 僅可選取的語義 |
|---|---|
| verifier_mismatch_asserted | 明說當次送出 verifier 與原 challenge 不符是實際拒絕原因；不是條件、否定或例子 |
| grant_or_code_asserted | 明確指向 grant／code 問題 |
| client_redirect_configuration_asserted | 明確指向 client／redirect／configuration 問題 |
| indeterminate | 矛盾、多候選、不完整、否定／條件／例子而未斷言實際原因，或未知 |

Parent 保留既有強 configuration／redirect／auth error 優先與相容性規則；Human 語義與已知強訊號衝突時，強制 review_status=conflict、category=indeterminate／未知，不能由選項升級舊 proof。視窗不呈現 case、outcome 或 expected label，以減少 priming；Human 可能已有上下文，不能承諾全盲。

### U2. Parent gate 與先清理後啟動

僅 strict UTF-8、完整且未截斷的 description，UTF-8 長度 <=4096 bytes；超限不取 prefix。僅可信 strict OAuth error shape；token／成功混合、重複鍵、invalid JSON、非 string／不可信 shape 均不顯示。

Parent 必須在當次已知 secret context 仍存在時，對候選檢查 client ID／secret／code／state／原與送出 verifiers／challenge／已知 token，涵蓋 literal 與常見 URL／JSON／HTML／case／Base64 形式；並 gate URL、control、bidi、長 opaque identifier。命中即整段不顯示，不以局部替換後的文本代替原句。具體 finite detection 與負向例須由未來獨立 holdout／review 凍結；不宣稱可偵測任意編碼、未知秘密或所有混合變形。

時序固定：strict shape／size → 在已知 context 下 gate → 僅取得候選 → finally detach observer、clear Attempt／context／body／request／fields／code／main client ID與secret及衍生敏感參照 → 才 launch helper。Parent 在 helper 啟動時僅保留通過 gate 的候選，不傳已知 context、case 或 expected label；gate 拒絕／清理失敗／異常路徑均不 launch。此為參照生命週期控制，不承諾 immutable strings、allocator 或 OS 層的物理 zero。

Live 原文不得進 stdout／stderr／logs／file／env／argv／screenshot／clipboard；agent／Reviewer／CUA 不看 live 原文。僅 Human 明確啟動 review 才可能顯示，default no UI、no auto reveal。這些操作約束不等於 AppKit／OS 技術保證；copy／export／restoration 等能力尚未驗證，須先以 synthetic 測試，不用真描述驗證。

### U3. 私有 helper 與 bounded protocol

已實作的 private helper 為 `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift`，private Swift／AppKit tool script，不新增共用 module／target／public API。

- 匿名 stdin pipe 只收一個 strict UTF-8 JSON object：`{"protocol_version":1,"description":"..."}`。總輸入 <=16 KiB，description <=4096 UTF-8 bytes；拒絕 duplicate／extra keys、trailing data、invalid UTF-8／JSON、錯型別或 oversize；不截斷。不能透過 argv／env／暫存檔傳原文。
- stdout 上限 512 bytes，只含 `protocol_version`=1、`semantic_category`（上述四 enum）、`review_status`（confirmed／unreviewable／declined／expired／conflict）、`reveal_started`／`user_confirmed`（bool）的單一 strict JSON。Parent 驗 exact keys／types／bounds／enum 及狀態一致性；只有 confirmed 且兩 bool=true 才能有 decisive attestation，其餘歸未知。unexpected／partial／timeout／nonzero／error 一律 unknown＋static reason，不 echo 內容；stderr 不 forward。
- 密封確認窗 30 秒無動作即 discard；Human 按「顯示一次」才 reveal，最多 60 秒且無第二次，結束關窗／釋放參照。Parent watchdog 100 秒，超時結束 helper、清理並記未知。任何時間上限都不是 OS 留痕或記憶體 zero 保證。
- UI copy／export／restoration／automatic reveal 限制與異常關閉須先用 synthetic 驗證；未驗證不得宣稱技術禁止。不能由 agent 截圖或 CUA 檢查 live 原文。

### U4. 先獨立離線驗證，不能用 live 試設計

未來另行放行後，由獨立 Tester 建 synthetic holdout，獨立 Reviewer 核標並凍結；不是 Implementer 自訂判準再自測。共 16 例：3 明確肯定 mismatch、3 明確 grant/code、3 明確 configuration、7 必須 abstain（否定／條件／例子／多候選／矛盾／不完整／未知，各一）。Human 不看 expected labels。要求 **9/9 decisive 正確且 7/7 unknown**；全 unknown 不通過。不得為結果改標；未過禁止 live，需回修再獨立驗證。通過只證明該 frozen synthetic set，不是自然語言全面準確保證。

另做 gate／redaction、strict input/output protocol、size/duplicate/extra/trailing/type、no-auto-reveal／default-no-UI、密封／reveal／parent timeouts、單次顯示、取消／異常／cleanup、main 與 observer 敏感參照清理、strong-error conflict 負測。以上工具的 bounded offline 工作已獲授權；Human offline calibration 尚未執行、不自動啟動，live 仍無新增授權。

若日後另授權 live，推薦 wrong：既有合法不同 verifier 與 actualprepared 一致的基礎，使資訊增益集中於完整 causal text；不是預告一次會判定。共享 R→T 1/1 已耗盡，未來 case／次數須 Human 另行授權，不藉 U02 核准補新額度。

### U 最新授權更正（僅狀態，不變更 U1–U4 技術契約）

U02 formal planning approved 保留；原「未授權 offline implementation／須再批准」為已移除的額外停點。現依既有同 topic 實作授權續行 bounded offline tools、Tester／Reviewer、synthetic Human calibration 準備；不改 privacy gates、protocol／timeouts／cleanup、四分類、holdout／9+7 判準、proof／outcome 或既定 manifest。

U03–U05 的離線工作現可準備及執行，Human 校準仍在 U06 停點，不自動啟動；新 OAuth 額度 0，live 必另次明確授權。本輪先交付可測工具。舊 U 文句保留為授權演進歷史，不能用其阻擋已授權離線工作，也不能由本更正推導 live 或擴大原文處理能力。兩份他人 dirty Swift hosted tests 不讀、不寫、不暫存、不還原，且不在本 scope。

### U 最新執行狀態紀錄

外部 offline confirmation approved／無 required fix 保留。U03 已實作凍結 private Swift/AppKit helper 與 `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review` 無網路／ID-secret 校準入口；U03 completed；P2 selectors/stderr 回修後，獨立 U04 Tester 親跑 57 項受控測試通過，strict format／SwiftLint exit 0；U04 completed，獨立 Reviewer 最終 U05 approved、P2 closed／無其他 required fix，限工具交付與 Human 正式 offline 校準。原 U 初始未授權敘述是規劃來源歷史，現行只開放既定 bounded offline 範圍。

現行安全替代：SystemRandom shuffle，CLI只投影description，UI不見labels/id；不讀／比較 expected_category、不自評。末尾僅回 opaque correlation_id＋有限 observations，交獨立 Tester 依 frozen labels 評分；9/9 decisive正確＋7/7 unknown不變。原自評寫入被 auto-review 拒絕、未執行、未重試。協定／privacy與proof/outcome界線不變；若日後准live，原文僅 Human 經gate短暫看，agent／Reviewer不看不存。完整 UI／clipboard／restoration／timeout 互動實證與 U06 Human 9+7 校準仍 pending，不能宣稱 OS 無留痕；OAuth0、U06 Human停點、R→T1/1耗盡與舊歷史不變。

單次 smoke 紀錄為 30.534s／stderr=false／confirmed＋indeterminate。Human 回報看到文字、當時不能複製並隨意選取，可解釋人工觸發；不據此判自然 timeout、技術性全面禁複製或 Human holdout passed。完整 UI／timeout 等與正式 9+7 校準仍 pending，沒有新增 OAuth。


### U06 實際結果與語言前提（現行停止點）

來源 `f420901a1076537c4f7aa0404fe31509b8bdc889`。獨立Tester核對frozen fixture SHA與16唯一映射後，decisive6/9、abstain2/7，既定9/9＋7/7門檻未達，calibration_threshold_met=false；U06 completed-not-qualified／method needs-rework，停Human，禁止live。Human明示不懂英文，故英文方法前提未滿足；不是使用者過失、不表示正式OAuthbug或PKCEfailed。57項controlledpass、U05codeapproved及既有四個凍結SHA不變；結果處置由獨立Reviewer approved，範圍僅記錄與停止。

先前smoke受Human手動操作中止，不併入本次16-case校準，也不當自然timeout。當時pending與P/Q/R/T原證據不改，App/API/canvaspassed保留，R→T1/1已用盡、新OAuth0；不改label／fixture、不重跑16、不做新code/UI。新語言方案尚未決策／未授權：可另研究Apple官方on-device framework，但機譯不能當proof，任何新本機元件讀取description都須Human確認；本次無實作／安裝／下載。

### V 前置唯讀 inventory facts（不是工具實作或新 experiment）

Human 已准新增 Apple on-device 元件在未來 offline 範圍讀 gate 後 description，原文／譯文僅本機記憶體短暫視窗，agent不看不存；不雲端／不自下載，live未授權、OAuth0。Apple官方 TranslationSession 的 installedSource 初始化在 macOS26+ 為同步 nonthrowing，canRequestDownloads=false、不會要求下載；on-device內容不進其metrics，不是一般Safari／系統雲端翻譯。

外部 Tester 在 macOS26.5.2／SDK26.5／Xcode26.6 執行一次 scratch Swift6 compile/run，exit0、stderr_present=false；source SHA `ce6e738621fafc8c71b744db13dd7da3383cf90aaf9cc1b2b55e68ba9ed380bf`。只呼叫 Translation.LanguageAvailability.status(from:to:) 查 en→zh-Hant 與 en→zh-TW，兩者 supported、非 installed，只證所需語言組合資產未齊，不推論每個語言都沒裝。未初始化session、未translate／prepareTranslation／下載／UI／OAuth；scratch自清、repository無新檔。

目前沒有實際機譯／中文工具／新holdout，不能宣稱方法成立或機譯可當proof。繁中候選目前不可用，Human已同意自行下載，等待完成回報才重查；既有inventory仍supported非installed，本輪未翻譯／下載／新查，不建立V implementation plan或fixture；U06原16observations／6/9＋2/7未達資格與四凍結SHA保留。

## 1. 責任與 additive public 面

GitHubIntegration 保持 non-BC；不依賴 PR BC。獨立 GitHubSignInVerification App composition 獨占 coordinator、完整程序內 store、provider 與 scope；其 app-local Presentation 只有 display-ready input／intent，不再由 RivetPresentation 公開。App 的 Network-framework relay 與預設瀏覽器 opener 是平台 adapter，GitHub-specific 檢查與交換留在 GitHubIntegration。

基線已交付的正式 public surfaces 僅為（本次搬移不修改或擴大）：

- `GitHubOAuthAppConfiguration`：`init(clientID: String, clientSecret: String) throws`，非空、Sendable；description／debugDescription／reflection 遮蔽敏感欄位，錯誤不帶輸入。
- `GitHubOAuth.makeTokenFetcher(configuration:) throws -> any OAuthTokenFetcher`：轉成現有 internal fetcher configuration，沿用既有 production refresh transport，不公開 concrete 或 public transport injection。
- `GitHubOAuth.makeAuthorizationSession(configuration:redirectURI:) throws -> GitHubOAuthAuthorizationSession`：驗證正式 loopback URI、產生 session；session actor 公開 `authorizationURL: URL`、`complete(callbackURL:) async throws -> GitHubOAuthCredentialBundle`、`cancel()`。不公開獨立 state／verifier／code 欄位。
- 初次授權的有限安全 error classification：clientConfiguration、invalidCallback、denied、expiredSession、cancelled、alreadyCompleted、exchangeRejected、transport、invalidTokenResponse。型別為 Sendable，不帶原始 URL、body、credential 或 underlying error。

Session／exchanger 可有 internal-only clock、randomness、bare HTTP seam，以 deterministic tests 驗證；不能形成產品繞過 PKCE 的 public 開關。Public initializer／factory 呼叫採既有 Swift 6 concurrency 規則。

既有 `GitHubOAuthCredentialBundle` 六欄、`OAuthCredentialStore.load/save`、`OAuthTokenFetcher.refresh` typed throws、`OAuthTokenProvider.init(store:fetcher:now:)`、`GitHubClientScope.prepare(provider:)` 與 REST／GraphQL requirements 不改。refresh concrete 與 configuration 保持 internal；不新增 disposition／quiescence API。

## 2. Loopback 與 session

- App listener 僅綁 `127.0.0.1`、系統分配 port，path `/oauth/callback`。listener ready 後才建立 session／開預設瀏覽器。OAuth App 的註冊 callback 為 `http://127.0.0.1/oauth/callback`，authorize／exchange 使用同一帶實際 port URI。
- state 與 verifier 各用獨立 32 bytes cryptographic randomness，base64url 無 padding；challenge 是 verifier SHA-256 的 base64url，method S256。Authorize 只帶 client ID、redirect URI、scope=offline_access、state、challenge／method；secret 不進 browser URL。
- 同一 coordinator 最多一個 active session，五分鐘期限自 session 建立起算，使用可注入 monotonic deadline／timer。Exchange 最多三十秒，仍不能越過整體期限後發布成功。
- Relay 僅收 GET；request target／headers 上限 8 KiB，單 connection 五秒讀取上限。其他 path 靜態拒絕（現有實作為 400），不反射 query。relay 不自行驗證 state；把同一 callback URL 交 session。瀏覽器頁只回靜態結束／忽略文字。
- Session 檢查 exact scheme／host／實際 port／path、無 user-info／fragment、唯一相符 state，以及 code／error 排他且各為單值。無效 callback 回安全 invalidCallback，不 exchange，保留仍有效的等待嘗試；不讓外來錯誤 state 終止它。
- 相符 access_denied 是 denied；相符其他 OAuth error 是安全分類失敗。通過驗證的 callback 在 await 之前原子 claim；最多一次交換。claimed／completed／cancelled／expired session 的後續 complete 不重送 code。
- Session、coordinator 均以嘗試 identity／generation 拒收遲到結果。取消／到期會停止 admission、關 listener、取消可取消工作並清除本地暫存參照；直到真實 operation Task settled 才允許新登入，不把取消 caller 或返回畫面當作 settlement。

## 3. 初次交換與程序內保存

Code exchanger 固定 POST GitHub token endpoint，form fields 為 client_id、client_secret、code、redirect_uri、code_verifier；以正確 percent encoding，不加秘密至 URL。Accept JSON、form Content-Type。URLSession ephemeral，urlCache／cookie storage=nil、不接受 cookies、reloadIgnoringLocalCacheData、request／resource timeout 三十秒、不跟隨 redirects、不自動 retry。所有 failures 經有限初次交換 error 正規化，不把 refresh 的 rotation-indeterminate 政策移植成新 lifecycle。

只接受 2xx、JSON 無 error 混雜、必要六欄完整：access_token、refresh_token、expires_in、refresh_token_expires_in、token_type、scope。Tokens 非空、access token 可形成合法 Bearer、type=bearer、兩期限正整數、receivedAt 及計算結果有限且在未來。scope 是字串，可為空；不要求包含 offline_access。沿用 internal `GitHubOAuthTokenResponse.credential(receivedAt:)`，不新增 bundle Codable 或 credential kind。

App-local `InMemoryOAuthCredentialStore` actor 符合既有 load/save，instance 內保存完整 immutable bundle，不觸及 Security、SQLite、檔案或 UserDefaults。初次 save 成功後才建立 provider／scope；rotation save 仍由既有 provider 呼叫相同 store。不可用單 token `InMemoryGitHubTokenStore` 代替。

初次交換取消或到期後收到的 pair 不發布為新連線；不宣稱已撤銷遠端可能產生的 token。本次不處理遠端 revoke。

## 4. Composition、API 與 Presentation

獨立驗證 App host 為 `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj`、scheme／app product／target／module `GitHubSignInVerification`、test product／target `GitHubSignInVerificationTests`，macOS 15／Swift 6，bundle identifier `local.rivet.github-sign-in-verification`，local ad hoc 簽章、non-Sandbox、ENABLE_DEBUG_DYLIB=NO，不設定 Team／embedded profile，不新增 entitlements 檔。本次 bundle identity 不鎖定未來 DPK group／發行身分。

App entry 在任何 live dependency／Task 建立前檢查 `GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE=1`；hosted tests 使用 fake dependencies，live-call counters 必須為零。一般啟動不 restore、不自動開瀏覽器，使用者按登入才開始。

Coordinator 持有單一 tracked operation task，序列化 sign-in／prepare／GET /user／重試；工作未 settled 前不寫新 bundle、不改設定或開始第二 session。Caller cancellation 不放棄 task handle。所有 provider／client 使用都經 coordinator，不能有不受追蹤的旁路操作。既有 shared refresh await 完成後 operation 才 settled，以 latch 驗證，不以 sleep 猜測。

完整 bundle save 後建立 `OAuthTokenProvider(store:fetcher:)` 並保留，prepare 成功後保留 scope。Prepare 失敗保留同 provider，僅使用者明確 retry；不自動 rebuild／retry。不靠 provider disposition 判斷 terminal；顯示既有有限錯誤／階段，允許明確再操作或重新授權，不宣稱技術失敗等於未認證。重新授權先退休舊 scope／provider，舊工作 settled、新 bundle save 成功後才建新 provider；失敗不復活舊連線。

`GitHubAccountProbe` 以 `scope.rest.get` 呼叫 https://api.github.com/user，明傳 headers 與 body=nil；endpoint-local Accept GitHub JSON、User-Agent GitHubSignInVerification，不新增 shared header/version framework。僅 HTTP 200 且可解碼正 id／非空 login 才呈現當前身分。同 provider／scope 的「再次查詢」不重新授權。API 失敗呈現實際失敗，舊成功資料只能明示歷史，不冒充最新結果；開始重新授權清除舊身分。

Presentation 提供 config 輸入、SecureField、登入、取消、明確重試／重新授權、再次查詢與結果文字；不引入完整設定頁、帳號切換或 PR UI。Configuration／credential 不使用 scene restoration、AppStorage 或磁碟 cache。Secret 可隨 refresh fetcher 在記憶體保留至連線釋放／程序結束，不承諾程序記憶體的安全抹除。

## 5. 診斷、測試與交付邊界

禁止寫入 secret、tokens、完整 bundle、code、verifier、完整 callback URL、交換 body 或 raw error payload 至 logs／檔案／測試收據。診斷只含階段、有限結果分類及非機密關聯 ID。證據不保存完整帳號識別值，只記身分欄位有效／一致等必要布林；驗證 UI 可呈現本次 probe 的 login／id。

TC01–TC09 見 plan。受控 tests、格式／lint、consumer compatibility、驗證 App build/test 與獨立 code review 在 commit/push/Draft PR 前完成；Human 真 OAuth／反向 PKCE 可列 pending，依已授權順序在 Draft PR 後確認。未驗證不等於失敗或通過，不把 live 缺席當作不能完成受控實作的理由。

## 6. Ownership 與歷史來源（本次 Human Decision 收斂）

Human 已明確拆 Mission，本段是本 topic 執行契約的 ownership 收斂，不修改另一 worktree、不代替獨立 verdict。儲存線未合併 draft 的舊重疊敘述，不構成本 topic 的實作授權或 DPK 前置。

| 能力／資產 | 本 topic | 儲存／合流線 |
|---|---|---|
| OAuth configuration public value、refresh factory | 建立並獨占首次交付 | 未來消費既有 public value／factory，不另實作 |
| state／PKCE／callback policy／初次 exchange | 建立並獨占 | 重用正式 OAuth 能力，不複製授權實作 |
| 獨立驗證 host／loopback relay／coordinator／app-local UI／GitHubAccountProbe | 本次程序內驗證 App，非正式產品 UI | 未來產品 host／保存組合須由其流程另規劃，不能假定直接採用驗證 App |
| 完整程序內 bundle store | app-local、本次獨立驗收 | 不作正式 persistent adapter |
| DPK、configuration／credential 保存、repair、跨重啟／真正重建、renewal 採用 | 不實作、不作本 topic gate | 唯一 owner；保留自己的 E007／Human 採用前置 |
| provider disposition／精細 terminal repair | 不新增 | 若其計畫仍有需要，僅在儲存線獨立審查後處理 |
| 最終登入＋保存＋恢復＋refresh 合流驗收 | 不宣稱 | 另行限定的合流交付 |

下列為原 S02 核准所用歷史唯讀快照；本次不重新讀取或改動其他 topic／worktree。2026-10-20 快照：儲存線 branch 為 feat/github-persistent-connection，基線 16606b89b8e3e6b61523c23aa0be9653c1ea7b44。其四份 draft 仍包含重疊產品登入／host／factory；帳本標頭 current_step=S04c、human-check，r1 preparation review approved 僅放行 Tester＋Human live，live 尚未開始；後文仍有較舊 S03／needs-rework 敘述。本 topic 不判斷該歷史帳本品質、不改其 verdict，也不把其中 approved 擴張為本 ownership amendment 的 approval。

來源是平行 worktree 的下列相對文件及 SHA-256（僅來源識別，不複製私有路徑）：

| 來源文件 | SHA-256 |
|---|---|
| analysis/github-persistent-connection/requirements.md | 494f46dc16de22160569b3642e963aebefa36f2bdf75dc02f5ddc767a3769580 |
| analysis/github-persistent-connection/technical-spec.md | 98cd5b38b927b3420cdeffa4fa4f9b086de7046a6a53dd82ea2cb52851cc0a61 |
| plan/github-persistent-connection/github-persistent-connection.plan.md | 098ea6c8dbcbdf91f2a554dee97a76523d444d8d83d49124df413004abd10503 |
| plan/github-persistent-connection/github-persistent-connection.step.md | e512e4357a99fb7ec7911ecd3051b24482e479d71933209fa98348ab7f3fe1b8 |

以下只保留原 S02 歷史完成條件；本次實作 gate 為 plan 的 A02，不重開 S02。原 S02 的完成條件：獨立 Plan-Reviewer 核對 Human split、此矩陣、manifest 無儲存實作／無 provider policy 變更，明示本 topic 可否依此 ownership 執行。它不要求完成 E007 或重審儲存全線。儲存線日後進入產品 integration／host 步驟前，須由其 Plan-Creator 依本 split 回修自身四 artifacts，再獨立審查；本 topic 不替其完成該步，也不假稱其 draft 已修好。

## 7. 驗證 host amendment（現行 locked decision）

來源基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22`，沿用 `feat/github-first-sign-in`、原 feature worktree 與 Draft PR #61。Human 明確區分正式 OAuth 實作、獨立驗證 host 與尚未交付的正式 Rivet 登入 UI。

- apps/Rivet 13 個受版控檔逐一 rename，app entry 改為 GitHubSignInVerificationApp；project、shared scheme、target／product／module、TEST_HOST／BUNDLE_LOADER、test imports 與 references 同步。無新共用 module。
- GitHubConnectionView、GitHubConnectionPresentation 及測試搬入 App；移除其 public access 及 app 對 RivetPresentation 的依賴，保留 PR Inbox Presentation 不動。窗口標題與畫面提示必須明示「GitHub 登入驗證」及「非 Rivet 正式產品登入 UI」。
- GitHubAccountProbe／Identity／Error 保持驗證命名與作用；不改成 CurrentUserReader，不創造帳號業務抽象。relay、完整記憶體 store、coordinator／dependencies 同屬驗證 App。它使用真 OAuth／API，不是 mock app。
- 正式 GitHubIntegration configuration／factories／session／exchanger／errors，以及全部既有 credential／provider／scope／clients／lifecycle source 唯讀；日後可整個移除驗證 App 而保留正式 OAuth 能力。
- 使用新的 test-mode key，hosted test scheme 與 entry 一致，早於 live dependencies 建立檢查；test 移動後不啟動真 OAuth。App dependencies 只保留 GitHubIntegration 與既有 HTTP product。
- frozen sequence v1/v2 與既有生成 HTML／receipts 不變；建立 v3 spec／獨立 basename 交付；責任 canvas 建立 scene-v2.js／index-v2.html。真實改動與每個輸出先納 manifest。
- 舊正常 OAuth＋再次查詢證據可沿用但明示來源基線；本 amendment 核准時新 host 真登入 pending；2026-10-21 已於來源 `e941d88` 觀察正向真實 API 與再次查詢通過，見 amendment evidence。反向 PKCE、canvas 互動視覺及其他既有未驗證項目不自動變成通過。不讀取或保存先前 callback／code／state／secret。

## 8. P 輪追加技術契約：獨立反向 PKCE CLI

本節為 `d11f343` 後現行追加契約，優先於歷史 canvas pending 敘述；不修改正式 OAuth/session、Swift App 或既有實驗。Human 已驗收現行 canvas v2 內容／流程／責任、拖曳、縮放可讀、聚焦說明及明暗可讀。正常登入／再次查詢沿用 e941d88 來源；本輪不做遠端 refresh／401。

### 輸入與單次操作

`apps/GitHubSignInVerification/tools/pkce_negative_probe.py` 僅 Python standard library；唯一 case 參數 `--case missing|wrong`。client ID 與 secret 由本機 TTY getpass 讀取，不從 args／env／檔案／Swift App／gh credential 取得；無安全TTY時有限失敗並結束，不降級明文輸入。

每 process 只一個新 state、原 verifier／S256 challenge、新瀏覽器授權及 callback code，最多一次 token POST；不先執行 positive、不 retry、不跨 process 保存或重用值。missing 的 form 完全省略 code_verifier；wrong 使用另一個 43 字元 base64url verifier，確認其 SHA-256 challenge 不同後才送。兩 case 各新 process，本輪最多兩次新授權；取消或不明結果不自行加跑第三次。

其它條件沿用 GitHub.com authorize/token 固定 HTTPS endpoints、Human同一client配置、scope offline_access、IPv4 127.0.0.1 動態port／oauth/callback、S256、相同當次 redirect_uri、POST form encoding／Accept JSON。工具不載入既有 app 記憶體；秘密及所有嘗試資料只在本process記憶體，結束即丟棄。

### 有界 callback／HTTP

listener 只綁127.0.0.1動態port；先ready再開瀏覽器。只收 GET、exact Host（127.0.0.1:當次port）與 /oauth/callback，無userinfo/fragment，拒絕重複query欄位、錯state及code/error同現或缺失；code或error只能單值。最多16 connections，每連線headers 8KiB／read 5秒、不讀取或接受request body／非零Content-Length／Transfer-Encoding，無效callback不消耗仍有效嘗試；有效callback原子claim一次，後續不交換。回覆靜態頁，不echo query；禁用HTTP access/error logs。

授權總期限5分鐘（monotonic），POST僅在期限內，timeout不超過剩餘期限或30秒較小者。固定TLS token endpoint、無redirect、無proxy環境繼承、無cache/cookies、無自動retry；response最多64KiB。逾期／超限／HTTP或JSON異常皆有限分類，不print raw body／URL／exception或traceback；頂層包含輸入失敗、Ctrl-C與unexpected error的安全終止。

### Fail-closed 判準及安全報告

1. JSON object 中存在任一 access_token／refresh_token key（包括空值、混合error、異常type）即 failed／token_returned；不使用、不保存token。其他意外non-JSON body不打印，indeterminate。
2. passed 僅允許HTTP2xx或400、純error（無token／成功payload）且error精確為 `missing_code_verifier`、`incorrect_code_verifier`、`invalid_code_verifier`、`code_verifier_required` 之一。這是工具的保守辨識allowlist，不宣稱GitHub官方保證這些error名稱；不以自由文字描述或substring推斷通過。
3. `bad_verification_code` 一律 indeterminate／generic_code_rejection，即使描述出現verifier字詞也不升級；safe remoteRejected可為true，仍不是PKCE通過。client config、redirect、expired、授權拒絕、timeout、network、未知error／shape／HTTP均indeterminate。無法確認原因不算PKCE通過。
4. stdout只允許case／三值status／有限HTTP分類或status整數／有限error分類／必要布林（fresh_attempt、single_exchange、token_present、verifier_field_omitted、wrong_challenge_differs等）。未知遠端error映射unknown，不透出原字串；不輸出clientID、secret、code、state、verifier、token、raw body、callback／authorize URL或exception。輸出不自動寫檔，證據僅人工轉錄此安全分類。

E002 runner會先positive、沒有missing case且把generic bad_verification_code視為通過，不能沿用作本輪判準。官方[授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)要求有challenge時提供原verifier；[token錯誤文件](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)中的bad_verification_code也可能是錯誤或過期code，不專指PKCE。2026-10-21已讀官方內容；不引用任何機密範例。

工具僅驗證外部拒絕行為，不改正式實作邊界或圖中ownership，故不需新圖或改frozen specs。fake callback／transport tests詳見PK01–PK06；Human只在獨立Tester及Reviewer完成後執行，一次一步，不索取機密到對話。

### P06 最新執行狀態（2026-10-21）

以上遠端pending為P01規劃時狀態；現已由Human依固定helper與判準完成missing/wrong各一次新授權/單次交換，兩個安全報告均HTTP400、unknown_error/unknown、無token，結論皆indeterminate，不宣稱PKCE enforcement通過。工具最終SHA659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699（d11f343基線後dirty source），兩case間未修改。總預算2/2已用盡，停止授權與重試，無rawbody可追補；後續診斷需另訂有限契約與新預算。Canvas Human驗收passed，遠端refresh/401本輪不做、保持pending，全部PR Humanreview尚未完成。詳見pkce-negative-verification evidence與step；範圍/manifest/既定判準不變。

## 9. Q 輪現行診斷版本2（優先於 §8 的舊P四errorcode判準）

基線82489b68ff21e955611bde1e9028fff21dc68e74；僅改CLI分類及安全報告，不改transport/TTY防fallback/loopback/PKCE生成與單次POST。P輪unknown/indeterminate歷史不可重判。新missing/wrong各freshprocess單POST，總2次；工具與證據均標diagnostic_version=2。

### 事前固定有限詞彙

已知remote_error enum＝原四verifier code（missing_code_verifier、incorrect_code_verifier、invalid_code_verifier、code_verifier_required）、既有incorrect_client_credentials／redirect_uri_mismatch／bad_verification_code，加invalid_request、invalid_grant、invalid_client、unauthorized_client、access_denied、unsupported_grant_type、invalid_scope、server_error、temporarily_unavailable；其餘永遠unknown，不echo原值。已知值只輸出預定enum，不轉印原始error。保留有限http/outcome/布林，新增：diagnostic_version=2、diagnostic_class、description_class、description_present、description_mentions_verifier、signals_conflict、pkce_rejection_proven。

diagnostic_class有限值：verifier_required、verifier_mismatch、verifier_invalid_unspecified、token_returned、json、http、network、timeout、auth、configuration、redirect、code_problem、unknown（輸入/取消/internal安全失敗可映射unknown，原有限reason保留）。description_class只允許下表class及absent／unknown。description_present只表示原欄存在；description_mentions_verifier僅安全提示布林，不參與passed。

raw error/description只存記憶體。description須為string、長度<=512字元；只strip／lower／空白折疊，再移除至多一個末尾句點，然後以下固定完整句比對。超長、非string、附加字、否定句、僅含verifier字詞皆unknown；不做substring／wildcard通過。以下是synthetic supported wording，非GitHub官方保證，live後不得增加模板再回改結果。

| description_class | 正規化後允許的完整句（分號分隔） |
|---|---|
| verifier_required | `missing required parameter: code_verifier`; `the code_verifier is required`; `code_verifier is required`; `the code_verifier parameter is required`; `invalid request: missing code_verifier` |
| verifier_mismatch | `the code_verifier does not match the code_challenge`; `code_verifier does not match code_challenge`; `the code_verifier passed is incorrect`; `code_verifier is incorrect`; `invalid request: code_verifier does not match code_challenge` |
| verifier_invalid_unspecified | `invalid parameter: code_verifier`; `the code_verifier is invalid`; `invalid code_verifier`; `the code_verifier parameter is invalid or missing` |
| code_problem | `the code passed is incorrect or expired`; `the authorization code is invalid or expired` |
| configuration | `the client_id and/or client_secret passed are incorrect` |
| redirect | `the redirect_uri must match the registered callback url for this application` |
| auth | `the user denied access to your application` |

### 固定判定優先序與matrix

1. 任一top-level access_token／refresh_token key（含空值／mixed／非string）仍failed、pkce_rejection_proven=false，不使用token。
2. format/JSON duplicate keys/mixed成功欄位/未知shape、HTTP非2xx/400或unsupported情境均indeterminate；對應有限json/http/unknown。network/timeout亦各有限class，絕不洩漏原exception。
3. 可信純error下：missing_code_verifier／code_verifier_required給required；incorrect_code_verifier給mismatch；invalid_code_verifier只給invalid_unspecified，不能單憑invalid就passed。
4. generic invalid_request／invalid_grant／bad_verification_code及invalid_code_verifier，只有精確完整description為required或mismatch才可取得相應verifier evidence。一般invalid_grant或bad_verification_code自身僅code_problem；unknown error即使description精確或提及verifier也不passed。
5. 強configuration errors（incorrect_client_credentials、invalid_client、unauthorized_client、invalid_scope）、redirect_uri_mismatch、access_denied分別維持configuration/redirect/auth優先；不能被verifier描述升級。unsupported_grant_type/server_error/temporarily_unavailable仍indeterminate（unknown）。強error與已知不相容description class設signals_conflict=true並indeterminate；強verifier required/mismatch與已知不同description class亦衝突。未知/absent description自身不構成已知相反訊號。invalid_unspecified可被上述精確required/mismatch細化。
6. passed須同時可信純error、HTTP2xx/400、無token/格式問題、無conflict、非unknown且case對應：missing只能verifier_required；wrong只能verifier_mismatch。不同case marker及invalid_unspecified/code_problem/unknown一律indeterminate。pkce_rejection_proven只在passed為true；remote_rejected可在可信純error為true，不等於PKCE證明。
7. description_mentions_verifier無論true/false均不能影響上述判定；所有safe欄位由枚舉/布林產生。raw error/description/exception、secret/code/state/verifier/token、body/URL一律不輸出、不保存、不traceback。未知description不echo。

受控QD01–QD05覆蓋每模板、matrix/case/強訊號衝突/否定與附加sentinel、安全output及既有21tests回歸。Human使用新版工具，各case一次，若unknown或failed仍記實際結果，不追body、不追加第三次、不事後擴表。

來源：GitHub[授權](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)與[token errors](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)；[RFC7636 §4.6](https://www.rfc-editor.org/rfc/rfc7636.html#section-4.6)與[RFC6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2)由呼叫端已查證：mismatch可用invalid_grant，但invalid_grant也涵蓋其他grant問題，所以單憑它不是PKCE證據。固定模板只是本工具有限辨識契約。

### Q06 實際執行摘要（判準不變）

2026-10-21，Q05獨立approved/R1closed後，Human以凍結version2 CLI另取missing/wrong各一個新code、各單次exchange。兩案皆HTTP400 invalid_grant/code_problem/generic_code_rejection、remote_rejected=true、token_present=false；description存在並提及verifier，但description_class=unknown，signals_conflict=false、pkce_rejection_proven=false。按事前§9兩者皆indeterminate；不得以hint、HTTP400或一般invalid_grant當PKCE證明。missing/wrong各1/1、Q總2/2用盡，停止新授權/重試/擴模板；P舊2/2 unknown歷史保留。來源82489b6+Q受限diff、CLI SHA `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`。原始描述未保存，無法可靠專指拒絕原因；完整安全JSON/來源與限制見新pkce-diagnostics-v2.md。正式OAuth/credential/provider/scope/refresh/401未改，正常login/API/canvas不重做，完整遠端refresh/401及完整PR Human review仍pending。

## 10. R 輪現行唯讀調查結論（docs-only，不改§9判準）

來源21e2542。本節優先於舊Q/P新授權流程；R新授權最多1次但因未找到可靠資訊增益方案而不使用，0/1，本輪無live、無工具修改。

### Fact（來源及可重現邊界）

- 主agent及獨立Explorer唯讀來源調查未見實際組裝bug證據。CLI以32randombytes產生43字元base64url，對原verifier的ASCII bytes做SHA256後base64url；每process fresh、callback單claim、token單POST。authorize/exchange使用相同clientID/redirect變數。missing真省略verifier；wrong用另一合法verifier且challenge不同。正式Swift同樣使用S256及對應參數。配置型別只用trim判全空後保存原字串；CLI只檢非空/上限而不trim，兩者均不自動trim使用值；不能推論Human輸入有空白。
- 主agent已進行無網路fixture檢查：RFC7636 AppendixB向量、兩case的urlencode/decode、code、same-client/redirect/challenge、合法shape及negativeflags，共11個布林全true。這是公開向量及synthetic fixture的受控本機條件，非live、不消耗R額度；不證明過往實際encoded wire或服務端grant狀態，也不回填歷史runtime布林。Tester可獨立重跑，不把它當遠端歸因。
- 官方[GitHub授權](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)／[token errors](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)、[RFC7636 §4.1/4.2/4.6/AppendixB](https://www.rfc-editor.org/rfc/rfc7636.html)、[RFC6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2)已由呼叫端查證：S256依原verifier計算；GitHub code期限10分鐘，client/redirect需正確；127.0.0.1 loopback允許當次port與設定port不同，動態port差異自身不是已證明錯誤；invalid_grant可有多種原因，不能單獨證明PKCE拒絕。官方未保證Q的19個synthetic描述模板。
- CLI urllib禁proxy與App URLSession的設定、form用+與%20（空白form編碼等價）、callback parser細節有差異；這些差異本身不證明拒絕原因或bug。

### Inference（明示推論，不當遠端事實）

既有fixture和source可排查特定本機組裝條件，但wire booleans無法證明遠端實際拒絕原因。增加猜測描述模板／keyword沒有可靠語義保證。在已查官方及現有工具材料下，尚無有依據的新遠端辨識契約，故依Human條件本輪停止工具/live工作，只交付調查文件。這不是斷言任何未來安全語義方案不可能或所有診斷方案均無價值。

若日後取得可靠語義契約，wrong使用合法verifier但錯誤proof，可能比missing更聚焦mismatch；此為未來候選推論，**不是本輪case選擇或執行授權**。

### No evidence／未確認

真實client配置是否與App完全相同、服務端當次grant/redirect/client狀態，以及未保存description的語義都未確認。不讀取App配置、不追補原rawbody／description／callback或secret。P/Q結果與舊evidence保持readonly。正式OAuth未有已確認bug，不擴成修復任務；PKCE enforcement仍indeterminate。Canvas及正常登入已pass的來源不被本輪推翻，遠端refresh/401本輪不做。

## 11. T 輪現行diagnostic version3（取代R停止指示，保持正式能力不變）

來源90646c2。只做獨立CLI私有被動觀測與有限描述句法，不改正式API、交換算法、endpoint、timeout、retry、TTY/getpass防fallback或loopback安全規則。沿用R尚未消耗的唯一1次：共享R→T規劃時0/1、T06後現1/1用盡，選wrong；無新增預算、無第二次。結果可能仍indeterminate，不能因此不實作已授權改善。

### A. 觀測實際prepared inputs，不建立mirror

在authorize實際把URL傳給browser opener的位置被動觀測該同一URL；在send_token建立urllib Request後、呼叫open前，最多一次觀測該同一Request。不得從case推算真值或另重建等價URL/body代替。可在Deadline加private optional observer，由run_case安裝並finally解除；Attempt可有只在記憶體的authorization binding與布林，clear清除所有原始值/時間/observer參照。不變更exchange_fields、不增加POST/retry或新傳輸策略。

safe `local_checks` 固定鍵：

| Key | 型別／定義 |
|---|---|
| authorization_observed | bool，實際opener參數已觀測才true |
| token_request_observed | bool，實際Request已建立並觀測才true |
| authorization_shape_valid | bool，固定AUTH_URL之HTTPS/host/path、無userinfo/fragment、query唯一且只既有client_id/redirect_uri/scope/state/code_challenge/code_challenge_method，值分別符合當次輸入/redirect/Attempt.state、offline_access、S256與原verifier實算challenge |
| token_request_shape_valid | bool，固定TOKEN_URL/POST、既有Accept JSON/Content-Type form/Cache-Control no-store、body可嚴格解form且欄位唯一，只既有client_id/client_secret/code/redirect_uri及可選code_verifier，必要值非空且secret等於當次輸入；不輸出任何實際值 |
| client_id_same | bool，兩次實際觀測的client_id與當次輸入相等 |
| redirect_same | bool，兩次實際觀測redirect與acquire回傳redirect相等 |
| code_same | bool，Request實際code與acquire回傳code相等 |
| submitted_verifier | enum unobserved/omitted/valid_same/valid_different/invalid；從實際form判定，重複或非當前43字元base64url合法shape為invalid；valid_same等於原verifier，valid_different為合法且不同並且challenge不同 |
| callback_return_to_request_prepared | enum unobserved/under_5s/under_30s/older；從acquire返回到Request prepared觀測，以同一monotonic clock，0<=delta<5、5<=delta<30、delta>=30；非有限/負值為unobserved，不名為code_age |
| local_consistency | enum unobserved/consistent/inconsistent；未完整觀測為unobserved；觀測完整但shape/bindings/negative提交/time不符為inconsistent；全部符合才consistent |

尚未觀測的布林預設false，不能默認true，且observed guards先於判定。正確negative提交：missing必須omitted；wrong必須valid_different（合法43字元且challenge不同），不能valid_same。重複觀測視不一致，不以最後一次覆蓋。以上只證明本機prepared inputs，非遠端wire或發行/接收時間/遠端grant證明。observed原始字串/Request不得持久或輸出；observer只讀，不改Request/metadata。

run_case最終passed另要求local_consistency=consistent與case對應negative提交；缺席/不一致一律indeterminate、pkce_rejection_proven=false。token_present仍failed優先，即使localchecks有問題也不降為indeterminate。classify可獨立受控測試，但不能繞過run_case最終gate。錯誤/取消仍輸出有限safe version3 result，finally解除observer並clear。

### B. 固定有界fullmatch grammar及純hints

沿用Q <=512字元string限制、strip/lower/空白折疊/移除至多一個terminal period。先查原19 legacy exact模板，保留其分類；之後才試以下完整句法。每個field alias限V=`code_verifier`/`code verifier`/`code-verifier`，C=`code_challenge`/`code challenge`/`code-challenge`；每個field可無包裹或完整成對單引號、雙引號、backtick，不接受不成對或任意其它字。以re.fullmatch消耗整句，無wildcard/free tail/substring；以下括號?是有限選項，不允許任意插詞。

可選固定prefix僅 `pkce verification failed: ` 或 `pkce validation failed: `。所列V/C代表上述有限field matcher，其餘字為literal：

| description_class | 完整grammar（prefix可有可無） |
|---|---|
| verifier_required | `(the )?V( parameter)? (is required|is missing|was not provided)`；`missing (required )?V( parameter)?` |
| verifier_mismatch | `(the )?V( (provided|supplied))? (does not match|doesn't match|did not match) (the )?C`，之後最多一個下列固定suffix |
| verifier_invalid_unspecified | `(the )?V( parameter)? (is|was) (incorrect|invalid)`；另完整句 `pkce verification failed` 只算本class |

mismatch suffix只能無、` (supplied|provided|sent) (in|with|during) (the )?authorization request`、` associated with (the )?authorization code`、` for (this|the) authorization request`。沒有其它tail/標點/negation變體。legacy例如`code_verifier is incorrect`仍先走既有exact分類，不因新invalid grammar重判。

新增 `description_match_source` enum：legacy_exact / bounded_grammar / none / not_applicable；可信可分類description命中19模板或grammar才前兩者，有description但未命中/超限/非string為none，無可用description情境（缺欄、非JSON、token優先等）為not_applicable，不輸出原句。

新增純hint booleans：description_mentions_challenge、description_mentions_pkce、description_has_missing_word、description_has_mismatch_word、description_has_invalid_word、description_has_expired_word、description_has_client_word、description_has_redirect_word；沿用mentions_verifier。只對<=512正規化string判斷，否則全false。用ASCII詞邊界（左右不得為[A-Za-z0-9_]）匹配有限字/phrase：

- mentions_verifier：V三alias；mentions_challenge：C三alias；mentions_pkce：`pkce`。
- missing_word：`missing`/`required`/`not provided`；mismatch_word：`mismatch`/`mismatched`/`does not match`/`doesn't match`/`did not match`。
- invalid_word：`invalid`/`incorrect`；expired_word：`expired`；client_word：`client`/`client_id`/`client_secret`；redirect_word：`redirect`/`redirect_uri`。

hints可在未知描述中提供語彙資訊，絕不參與passed/proof/conflict推導，不重建/保存原句、不回推舊Q原始描述。

### C. 保留Q安全matrix與單次Human流程

只在可信純error、HTTP2xx/400、無token/shape問題、knownerror可取精確required/mismatch證據、case對應且無conflict才有classify passed。unknown error即使grammar命中也不pass；強config/auth/redirect優先、case衝突、invalid_unspecified/一般invalid_grant不pass。run_case再加A的actualprepared一致性gate；hint永不參與。token key優先failed，無論內容/混合/空值；不使用token。grammar是事前支持句法，非GitHub官方保證或預言本次訊息一定命中。

T06前固定CLI及test SHA與判準；獨立Tester/Reviewer/requiredfixclosed後，Human僅wrong：fresh新state/challenge/code、單POST、共享R→T唯一1次用完即停，不positive/API/refresh401/第二次、不讀App配置。只收safe diagnostic_version=3 JSON。其資訊增益是actualprepared本機觀測、有限關係grammar或額外不參與proof的hints；未知結果仍如實記，不live後擴表。P/Q/R舊evidence與正常e941d88/canvaspass保留。

T03實作的有限reason補充：classify原本passed但run_case實際觀測gate缺席/不一致時，固定`local_observation_unconfirmed`、indeterminate/proven=false；這不是遠端error原文，也不變更其它error優先規則。

### T06 實際結果（既定判準不變）

2026-10-21，T05 approved且版本SHA凍結後，Human完成共享R→T唯一wrong新授權/新code/單POST，現在1/1已用盡，停止任何重試/第二次。安全version3報告：actualprepared local_consistency=consistent、valid_different、client/redirect/code/shape一致、callback返回至準備Request under_5s；HTTP400 invalid_grant、無token，verifier/challenge/mismatch hints true但description_class=unknown/match_source=none，按§11仍indeterminate/proven=false。local gate是新增本機證據，不能替代完整語義；hints不證明原因、false hints不排除其它grant問題，under_5s不是code_age。CLI/test SHA未改，來源90646c2+T受限dirtydiff，詳v3 evidence。PQR舊結果/預算/正常App/canvaspassed保留，不追原文或擴表；遠端refresh401及完整Humanreview pending。
