# GitHub 持續連線：技術契約

- Topic：`github-persistent-connection`；原契約／第二輪方法已審查；2026-10-20 第二輪主假設仍未知；Human 已接受唯一 renewal 未驗證例外，其餘契約不變。
- 配對：[需求](requirements.md)、[執行計畫與 manifest](../../plan/github-persistent-connection/github-persistent-connection.plan.md)、[帳本](../../plan/github-persistent-connection/github-persistent-connection.step.md)。

## 0. 已鎖定的 host 前提（RF01）

產品 Rivet.app 與 E007 ProfileRenewalProbe.app 均限定 macOS 15+、Swift language mode 6、Apple Development 簽章及有效 embedded development profile，設定 `ENABLE_DEBUG_DYLIB=NO`；首版不啟用 App Sandbox。實際 Team／profile／私人安裝路徑由 Human 私下選定，不入版控，repository 只保留參數占位、必要 hashes／布林。

產品安裝位置由 Human 首次選定單一 private path，在本輪 fresh-process／真正重建驗證前固定；不同 binary 均替換同一路徑的 Rivet.app，不改位置重測。原始路徑只在私有 runtime configuration／run manifest，repository 收據記其 hash 與 same-install-location 布林，不記本機絕對路徑。

E007 固定使用該輪私有 runroot 下 `current/ProfileRenewalProbe.app`；原 profile 寫入與新 profile 唯讀均在此同一路徑替換 App 後啟動。兩版須相同 App ID／private group／certificate，且 profile bytes 真正不同並各自在操作時有效；不重設 runroot／t0 來延長窗口。這些前提由 V01（E007）、V06（產品真儲存／提示）及 V08（signed build／host tests）核對，不以 build 成功代替 profile／路徑／提示證據。

## 1. 責任與 public surfaces

GitHubIntegration 保持 non-BC；不依賴 PR BC。App composition 保留單一 provider／scope；provider 獨占 restore、expiry-first refresh、rotation persistence、snapshot version／single-flight。Clients 維持 request-local snapshot 及 HTTP 401 最多一次 recovery retry。既有 public signatures、concrete client visibility、通用 HTTP auth、各 BC failure boundary 不變。

新增 public API 的型別／位置如下；error 均為有限 classification，沒有原始 payload：

- `GitHubOAuthAppConfiguration`：`init(clientID: String, clientSecret: String) throws`，非空欄位，Sendable；description／debugDescription／reflection redaction。ID 與 secret 不出現在錯誤。
- `GitHubOAuth.makeTokenFetcher(configuration:) throws -> any OAuthTokenFetcher`：把 public configuration 轉成既有 internal fetcher Configuration，沿用 production refresh transport；不公開 concrete 或 transport injection。
- `GitHubOAuth.makeAuthorizationSession(configuration:redirectURI:) throws -> GitHubOAuthAuthorizationSession`；session actor 公開 `authorizationURL`、`complete(callbackURL:) async throws -> GitHubOAuthCredentialBundle`、`cancel()`。Façade 擁有 state／PKCE／callback 檢查／初次 exchange，不保存資料。
- `GitHubOAuthDataProtectionStores.init(accessGroup: String, service: String)`；公開 `configurationStore: any GitHubOAuthAppConfigurationStore`、`inspectCredential() async throws -> GitHubOAuthStoredCredential?`、`credentialStore(clientID:) -> any OAuthCredentialStore`。`GitHubOAuthStoredCredential` 是完整驗證後的 `clientID`＋bundle；configuration store 為 async load／save，missing 為 nil。新增型別留在計畫所列四個新檔，不公開 Security concrete。
- `OAuthTokenProvider.disposition() -> OAuthTokenProviderDisposition`，actor 呼叫須 await；值僅 `notStopped`／`authenticationRequired`／`stopped`。由現有 unavailableError 推導：nil 為 notStopped、authenticationRequired 同名、其餘 terminal error 為 stopped；不發動工作，不重設狀態，不暴露 reason／version／error。

既有 prepare／client error 只留下 lifecycle stage，不能區分 nonterminal refresh 與 rotationIndeterminate，因此 additive disposition 是必要觀測；它不是新的 readiness 保證。既有 OAuthCredentialStore、bundle、snapshot、fetcher、scope、REST／GraphQL signatures 均不改。

## 2. Authorization 與 callback

固定 GitHub.com HTTPS endpoints。Authorize 請求只有 `offline_access` 作本 Mission 所需 scope，不索取 repo 權限。state 與 verifier 各用獨立 32 bytes cryptographic randomness、base64url 無 padding；S256 challenge 由 verifier SHA-256 產生。不把 secret 放入 browser URL。GitHub web exchange 及其 refresh 都仍需要 client secret；PKCE 不取代 secret。[官方契約](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)

App 的 Network-framework listener 僅綁 `127.0.0.1`、系統分配 port，path 固定 `/oauth/callback`；listener ready 後才建立 session／開瀏覽器。自有 OAuth App 註冊 `http://127.0.0.1/oauth/callback`；實際 authorize／exchange 使用同一帶 port redirect URI。每 session 最多五分鐘，只容許一個 active session。

Relay 只處理 GET、最多 8 KiB request headers／target、單 connection 五秒讀取上限；其他 path 靜態 404，不輸出 query。Relay 不驗證 OAuth state；它把 callback URL 交同一 session façade。Session 檢查 exact scheme／host／port／path、無 user-info／fragment、唯一相符 state，以及 code／error 排他且單值；缺值、重複、錯誤 state 或 invalid callback 終止 session，不 exchange、不保存。`access_denied` 有效 callback 分類 denied；使用者等待階段取消分類 cancelled；session 過期分類 expiredSession。重複 complete 或 cancelled session 不重用 code。

接受 callback 後 UI 停用取消；POST exchange 30 秒 timeout、ephemeral session、無 cookie／cache、不跟隨 redirect、不自動重送，form body 包含 client_id／client_secret／code／redirect_uri／code_verifier，Accept JSON。僅接受可信 2xx、沒有 error 混雜、六欄完整且非空 token、bearer、正數兩個期限及有限 receivedAt 的 DTO；由同一 receivedAt 計算完整 bundle。scope 可為空，不假設回應會含 offline_access 字串。錯誤分為 clientConfiguration、exchangeRejected、transport、invalidTokenResponse 等有限分類，不傳遞 body／URL／underlying error。所有路徑關 listener、釋放 code／verifier；瀏覽器回靜態結束文字。

## 3. DPK 與同 App 修復

正式 service 固定 `local.rivet.github.oauth.v1`，accounts 為 `configuration`、`credential`。group 由 signed host 的唯一 private group 注入；兩個 items 使用 kSecClassGenericPassword，所有 add／query／update 明指定 DPK=true、synchronizable=false、group／service／account；新增為 AfterFirstUnlockThisDeviceOnly，不加 presence／biometry／ACL。各 value 單次完整 update；不存在才 add，duplicate 僅重試完整 update；同 process store actor 序列化。不存在為 nil，denied／unavailable／corrupt／identityMismatch 為不同有限 store errors，不能將 entitlement／授權拒絕當作 missing。

Configuration JSON schemaVersion=1，完整 clientID＋clientSecret。Credential envelope schemaVersion=1，clientID＋完整六欄 bundle；dates 使用 JSON millisecondsSince1970，必須有限，允許已過期日期以支援 restore；tokens 非空、bearer、scope 字串。未知版本或任何必要欄位解碼失敗整個 payload 都是不可信，不從損毀資料撈 ID。Codec 不新增公用 bundle Codable conformance，不改 production DTO。

Inspect 和 bound credential store 共用嚴格 codec。完整 credential envelope 的 ID 是已連線身分權威；fetcher configuration、bound store、fresh load 一律同 ID，mismatch 禁止發送 token。兩 items 不作跨 item transaction，也不宣稱 crash-atomic pair。

| 狀態 | 固定處理 |
|---|---|
| 兩者 absent | 首次輸入設定；先保存 configuration，成功才開授權 |
| valid configuration＋absent／corrupt credential | 沿用 configuration ID；重新授權成功後完整覆寫 credential |
| valid credential＋absent／corrupt configuration | 鎖定 credential ID，重輸同 App secret；先保存 configuration，再重新授權 |
| 兩者 valid、ID mismatch | 以 credential ID 修復設定；禁止使用另一設定建立 fetcher |
| 存在 corrupt 且皆無可信 ID | Human recovery：使用者提供並明確確認原 App ID／secret後才修復及重新授權；無法自動驗證歷史身分，不默認切 App |
| 任一 denied／unavailable | 保留 items，僅明確重試，不修復覆寫 |

設定保存失敗不開授權；設定保存後取消／grant 失敗保留設定和原 credential。已有 credential 時 ID 鎖定，只容許在修復／重新授權更正同 ID secret。沒有新的跨 item rollback；不得恢復可能遠端已失效的 token。

## 4. Composition、settlement 與顯示

App coordinator 獨占 provider／scope；所有 prepare／GET /user／重試透過同一 admission gate，一次一個 tracked Task。不得把 provider／clients 洩漏給旁路 caller。取消 UI caller／返回畫面不移除 task handle，也不視為 settled；直到實際 Task.result 完成才清除。工作未完成時，任何 configuration save、credential 修復或 reauth 回 operationInProgress，使用者待完成再觸發；不排第二 session。

目前 provider 的 self-owned shared Task 經 snapshot／replacement await Task.value；prepare／clients 亦等待該 await 後才傳遞取消。因此此受限入口追蹤實際 operation Task 可證明 shared work settled，不新增 quiescence API、不允許 cancellation early-return。舊 refresh／save 完成前禁止新 bundle write。V04 必須以 latch 控制驗證此先後，不以 sleep 推定。

所有 reauth／credential 修復均在 settled 後退休舊 provider／scope，包括不改 configuration 的分支；取消、grant 失敗、save 失敗都不能恢復。只有新授權完整 bundle 保存成功才能建立新 provider。正常新程序啟動可用同 ID 有效資料建立初始 restore provider，此例外不得用於本程序繞過退休。

暫時 prepare 失敗保留同 provider，只接受使用者明確 retry；用 disposition 判斷 stopped 時不可重建；authenticationRequired 引導 reauth。原 provider rotationIndeterminate／accepted persistence failure 停止與 store 保留規則不改。Clients 保持每 execution fresh snapshot、401 最多一次 resend。

GET /user 透過 scope.rest，headers 為 GitHub JSON Accept、固定 User-Agent `Rivet`，不擴張 shared header framework。僅 200 且可解碼有效 id／非空 login 才呈現當前帳號；403／其他 status 為 probe failure，不觸發一般 refresh。重新授權一開始清除舊帳號顯示，不把歷史資料當現況。API 暫時失敗可明確重試，不能錯誤宣告未保存的連線成功。

最小 SwiftUI leaf 只有 display-ready input／intent、SecureField、登入／取消等待／明確重試／重新授權按鈕與帳號文字，不加入 PR UI。App 的 hosted unit tests 透過 shared scheme 的 `RIVET_UNIT_TEST_MODE=1` 選 fake dependencies，App entry 在任何 live dependency／task 建立前檢查；test mode 不觸發 OAuth／Security／產品啟動還原。測試要驗證 live-call counters 為零。

## 5. E007 與證據約束

E007 建立前已確認未占用；沿用已審查的獨立 fake-only host 與 runner，不另設實驗編號；E006 source／receipt 只讀，不依賴已清理的私有 App／setup。run t0 在 setup 前持久化，45 分鐘窗口內包含 Human Xcode reprovision／建置；35 分鐘停止新增測量並開始 cleanup，不能 reset／延長。原 profile 與 updated profile 必須真正不同 bytes、有效且授權相同 App ID／private group／certificate／GUI user；不改 profile bytes 偽造差異。raw IDs／profiles／proof 留在 proven-owned 私有 scratch，repo 收據僅必要 hashes／布林。

先用 A-profile App 寫完整假 A，再由 B-profile App 在 fresh process 唯讀 A；renewal read 六欄相符且 Human 全程零提示為成功。前提完整但拒絕或超標為失敗；不能取得 B-profile、前提不足／觀察不全為無法判定。初始正常存取仍受首次 ≤1 提示約束。每段 Human ready／觀察綁 machine SHA，machine promptCount=null 不回填。未執行／成功／失敗／無法判定與任務完成否分列。遇新 certificate／安全設定／付費要求即停；不 revoke 或刪 Human Apple 資產。

第二輪唯一增加的外部變動是：首存與 Human 全段觀察完成、私有 project 停止／關閉後，從本輪保留 A App 的 embedded profile 解碼 UUID，綁 `private/first.json` 的 profile／certificate／group 證明，只探 Apple 文件所述兩個 cache 位置中該 UUID 的兩種副檔名（最多四個精確候選）；不得列舉帳號資產或清空目錄。候選須為目前使用者擁有的非 symlink regular file，profile bytes 等於 A，UUID／App ID／certificate／private group 均相符且能證明只屬本輪，否則停止。逐檔 exclusive 私有備份、原路徑／metadata／hash journal、fsync 及備份再雜湊與恢復可用性檢查全部完成，才暫移已證明的精確檔案。這是本機可逆移出，不是 revoke／portal 刪除。保留原 certificate，不啟用 CLI provisioning updates。A 建置前先在本輪私有 project-specific 設定將 GUI DerivedData 指向 owned runroot 的 `DerivedData`，不改全域設定；A／B 各由 Human GUI Build 一次，Tester 只 preflight／run。精確 APP_A／APP_B 必須來自各次實際 GUI Build 的 built products，核對同 owned DerivedData、本輪 project／凍結 source 及 embedded profile，不能拿 CLI／A 舊 App 當 B；輸出或來源不明即停止，不猜外部 DerivedData、不另建或重建第二次。原始路徑只留私有 journal，來源／同位置的有限布林記既有 tester-validation，不新增框架。Human 重開同私有 Xcode，先確認同一 project-specific DerivedData 設定，再只按 Build 一次取得 B；bytes 不同且既有同身分／雙向 DR 檢查通過，才允許原 runner `phase read`。詳細手動操作與停止點見 [E007 §9](../../experiments/E007/README.md#9-第二輪受限補驗證方法已獨立計畫審查)。

第二輪無論結果，都先用保留 A App 精確刪本輪 UUID item／read-absent並取得 Human 清理觀察，再停 Build／關專案，逐檔恢復原 cache bytes 並核對 hash；原位置已同 bytes 可視為已恢復，其他 bytes 衝突不得覆寫。恢復失敗或衝突時保留私有 backup／journal，停於 human-check，不執行 `export-clean`，不宣稱清理完成；新下載 B profile 保留。只有全部恢復並核對後才允許 export／移除 private root。既有 runner 不會自動核對外部 cache 恢復，此順序由 Tester／Human 人工核對並硬停止，不虛稱新增自動 guard。

只清本輪 UUID DPK items 和 proven-owned scratch／App copies／DerivedData，保留 immutable evidence。清理與 timebox 各自報告；以下原路由只記當時前置，現行 Human 例外見本節末：當時 gate 為失敗／無法判定停止 adapter 採用（後續 Human 受限例外見本節末），成功也必須經 Tester／Reviewer 真實判讀及 Human 採用決策；第二輪全部原判準成立且無重大問題時，依 Human 本次「通過就回產品」條件授權前進 S05，不重問同一許可。目前尚未成立，不預填觀察或成功。

官方 [Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account) profile 七日到期；有效 profile 是產品可用前提，過期期間不可用。一次 renewal 不保證已過期恢復、certificate rotation 或所有週期。真 GitHub、真 DPK、受控時鐘／fakes 各自標記，不記錄原始秘密或回應。

### E007 方法執行現況（事實回寫）

上述是第二輪事前方法，現已完成唯一額外嘗試；不再等待 fresh ready 或啟動新窗口。A GUI 產物、私有 project-specific owned DerivedData、凍結 source／原 certificate 均經 Tester 當輪核對；A 六欄相符、Human 首段 0 提示。匹配 cache 一份，raw backup 一份 bytes／hash 相符，但原 xattrs=0、backup／check xattrs=1（系統 provenance），完整 restore-check 未通過，因此原 cache 未移出、未 refetch、未建置 B、未讀回更新 profile。不能由此外推普遍不可恢復。原 bytes／identity／metadata／xattrs 在 export 前完全未變，requiredRestore=0／notRequired，無 restore 操作；humanRecoveryConfirmed=false 表示無須新恢復確認，不是未解確認。假 item 與 owned root 如期清理。

[第二輪結果及收據](../../experiments/E007/README.md#10-第二輪唯一補驗證實際結果)已由 Tester／Reviewer approved，僅指有限證據與安全收尾；主假設無法判定，原 runner taskComplete=false。唯一額外輪用完，原條件式回產品授權未成立；其後 Human 已明確接受未知並修 gate，受限採用記錄如下，非改寫上述實驗判讀。

### Human 接受未知：唯一採用前置例外

Human 實際決策：「接受 profile 更新後尚未驗證的限制，修訂 gate 並繼續產品實作」。本次只解除「renewal 必須先驗證成功」的採用前置；其他驗收維持，仍保留連線失效處理與重新授權路徑。S04e 已依該決策完成；S05 待本 gate delta 獨立回查後進入既有 bounded implementation，不再要求新的 E007 run／fresh 45 分鐘或採用許可。E007 兩輪 unknown／phase 2 未執行與當時 Reviewer human-check 收據 immutable。

只接受同身分 profile 更新後讀回的未驗證限制；仍要求有效 embedded profile、同 Mac／GUI user／App ID／private group／原 certificate、固定位置，保留七日到期與過期不可用、已過期恢復／cert rotation／公開發行未驗證界線。§0–§4 的 ownership／API／儲存錯誤與同 App repair／reauth／settlement 不改。V06–V09 與真實／受控分列全部保留，尤其產品提示首次≤1／fresh 0／rebuild 0、輪替後新程序、真遠端 refresh、provider accepted-rotation 保存失敗停止、denied 不覆寫及雙 client lifecycle；不聲稱產品或 refresh 已驗證。

S05 驗證維護：既有 `StaticIsolationTests.swift` 的 target source／import 精確 allowlist 須同步已核准 W02 四檔；只允許 plan M02 所列兩個 HTTPClient 與兩個 Security 路徑例外，保留其他隔離斷言，不改 runtime／public 契約；此 manifest delta 待獨立回查。
