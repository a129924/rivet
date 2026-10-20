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
- 舊正常 OAuth＋再次查詢證據可沿用但明示來源基線；新 host 真登入 pending。反向 PKCE、canvas 互動視覺及其他既有未驗證項目不自動變成通過。不讀取或保存先前 callback／code／state／secret。
