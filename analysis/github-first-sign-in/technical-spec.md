# GitHub 首次登入：技術契約

- Topic：`github-first-sign-in`；2026-10-20 Plan-Creator 驗證 host amendment，已獲獨立 Plan-Reviewer A02 approved（無required fix）。
- 配對：[requirements](requirements.md)、[plan／manifest](../../plan/github-first-sign-in/github-first-sign-in.plan.md)、[step](../../plan/github-first-sign-in/github-first-sign-in.step.md)。

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
