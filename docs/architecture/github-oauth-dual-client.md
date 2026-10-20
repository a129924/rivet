# GitHub OAuth 雙 Client 架構

## Goal

鎖定 GitHub OAuth App 的可 refresh、會過期 credential bundle shared token lifecycle：`GitHubIntegration` 已交付 `OAuthTokenProvider` runtime 與 adapter ports，以及 public GraphQL Query／Mutation 與 authenticated REST GET／POST／PUT／PATCH 契約。GraphQL client 在 HTTP 401 回報實際 snapshot，透過 provider recovery 後重送原 operation／variables 一次；第二次 401 終止。ready Scope 組合兩個 internal client，共用 caller-owned provider instance；跨 target contracts 已交付，完整 REST endpoint 能力仍延後。

這是長期**架構文件**；internal Query／Mutation client 的受限 runtime 契約與驗證見 `github-graphql-infra-foundation` 與 `github-graphql-mutation-foundation` topics，`github-client-scope-composition` 已交付雙 client ready Scope；產品 composition root 已由 `apps/Rivet` 交付，見下方正式產品持續連線。

## Non-Goal

- 已交付 internal OAuth App token-response DTO → public immutable credential bundle mapping，以及 public `OAuthCredentialStore`／`OAuthTokenFetcher` ports、`TokenSnapshot` 與 actor-isolated `OAuthTokenProvider` finite failure contract；DPK storage schema 已由本文件的正式產品章節定義；internal refresh adapter 已定義固定 endpoint 與 form payload。
- 已交付 OAuth authorization code、PKCE、callback 與初次 sign-in；logout、revoke、多帳號、PAT 與 GitHub Enterprise 仍不在本次範圍。
- 不定義 Domain endpoint、DTO、GraphQL schema、rate limit、pagination、一般 retry 或各 Bounded Context 的 failure mapping。
- 不修改 `RivetHTTPClient`，也不讓其 `Auth`／`AuthFlow` 成為 OAuth runtime driver。

## 責任與依賴

[責任與依賴 canvas](diagrams/github-oauth-dual-client-architecture/index.html) 只呈現 component ownership 與 dependency；它刻意不表達 request sequence。 [Token lifecycle](diagrams/github-oauth-dual-client-architecture/token-lifecycle-v12.html) 則呈現 expiry-valid snapshot、401-only response recovery 與一次 retry；其 canonical／歷史 evidence 狀態見 [圖表說明](diagrams/github-oauth-dual-client-architecture/README.md)。

```text
Facade（layer 外的 application composition root）
  ├─ bare RivetHTTPClient / URLSessionTransport
  ├─ GitHubOAuthDataProtectionStores（DPK 完整 bundle，已交付）
  ├─ GitHubOAuthHTTPTokenFetcher（internal bare HTTP refresh，已交付）
  ├─ OAuthTokenProvider(OAuthCredentialStore, OAuthTokenFetcher)
  └─ GitHubClientScope.prepare(provider:)
       ├─ public rest: any GitHubRestClient（internal concrete／拒絕 redirect）
       └─ public graphql: any GitHubGraphQLServing（internal concrete／Apollo）
```

- `GithubIntegration` 是 Bounded Context 外、GitHub-specific 的 shared integration module；它不是 BC，不依賴任何 BC，也不擁有 Domain Port、DTO translation、BC failure mapping 或 business meaning。
- Facade 是 layer 外的 application composition root，只負責 composition：建立並保留唯一共享的 `OAuthTokenProvider` instance，以 prepare 完成本地 readiness，再由 Scope 注入 REST 與 GraphQL client；不在每個工作前重新 prepare，也不改變各 BC 的 `Facade → UseCase → Port` 層級方向。
- `RivetHTTPClient`／`URLSessionTransport` 是 bare、generic、GitHub-unaware foundation；bare `HTTPClient` 只執行 raw HTTP request，不認識 OAuth、Bearer、TokenProvider、401 recovery 或 retry，也不直接建立或驅動 `AuthFlow`。
- `RivetHTTPClient` 既有 internal `AuthRequester` runtime：它注入 `Requester` 與 caller-provided generic `Auth`，建立並驅動 generic `AuthFlow` 的 `.send(HTTPRequest) → raw HTTPResponse → receive(response)` loop，直到 `.finish`；flow 保有 authentication decision。這條 generic capability 不持有 credential、retry 或 GitHub OAuth lifecycle。
- 已交付 schema 接受 GitHub OAuth App 的六欄 refreshable、expiring token response，並由 internal DTO 在 caller-supplied `receivedAt` 映射為 public immutable `GitHubOAuthCredentialBundle`。public `OAuthCredentialStore`／`OAuthTokenFetcher` ports 在 adapter boundary 使用完整 bundle；internal bare-HTTP refresh adapter 已交付；DPK OAuth adapter 已交付，與 legacy 單一 token store 分離。
- `OAuthTokenProvider` 是唯一 lifecycle owner：記憶體 credential、restore、expiry-first refresh、accepted rotation persistence、version 與 single-flight。remote rotation accepted 後的 persistence failure 使 provider 永久 unavailable；它不持有、不接收、不重送 `HTTPRequest` 或 Apollo operation。
- `TokenSnapshot` 是 public immutable、`Equatable`、`Sendable` client input，只包含 access token 與 version；`hasSameVersion(as:)` 只比較 version。refresh token 與完整 bundle 不會暴露給 client。
- 本 topic 不取代目前 public `GitHubTokenProvider`／`GitHubTokenStore` 的 access-token contract，也不定義 adapter、supersession 或 migration。另已交付的 async `GitHubAccessTokenProvider` 只表示 token acquisition；新的 OAuth provider 不 conform 或 bridge 它，也不實作 request、transport、401 classification 或 retry。
- internal REST client 由 Scope 注入共享 `OAuthTokenProvider`，production 自建拒絕 redirect 的 bare HTTP executor，並保有自己的原 `HTTPRequest`；GraphQL client 保有自己的 Apollo operation。兩者只共用 provider instance，不互相呼叫，GraphQL 亦不經 REST route。

## Token Lifecycle

1. REST 或 GraphQL client 向 provider 取得 expiry-valid `TokenSnapshot`；若 snapshot 已到期，Provider 先完成自身更新，再將 access token 交給 client 加為 `Authorization: Bearer`。
2. 每個 client 走自己的 transport route 送出原工作。
3. 401 是此 lifecycle 唯一的**回應狀態**復原觸發；expiry check 是 Provider 交付 snapshot 前的內部責任，不是 response-status policy。非 401 回應由 consuming BC 的 local Infra 依自己的 adapter boundary 處理；403、repository permission 與 resource visibility 不觸發 refresh。
4. 收到 401 時，client 回報**實際使用的 snapshot**。若 provider 已有更高 version，直接回傳目前 snapshot；若仍是相同 stale version，僅 single-flight refresh 一次。
5. 已交付 provider 在 refresh 成功時接受遠端 rotated credential bundle，先持久化完整新 bundle，再更新記憶體 snapshot/version，最後讓等待者取得新版 snapshot。僅可確認未造成輪替的 technical failure 允許再次更新；無法確認的輪替狀態停止 provider，儲存資料仍保留；若遠端 rotation 已接受而本地 persistence 失敗，provider 不再交付 snapshot，產品提供明確重新授權路徑，不恢復可能失效的舊 token。
6. 原 client 以新版 snapshot 重送自己的原 request／operation 一次；每個原工作最多 retry 一次。

| 狀況 | Outcome |
| --- | --- |
| 無 credential | provider 回傳 `.missingCredential`；產品提供授權入口 |
| credential store load failure | provider 回傳 `.restore`；產品區分儲存失敗並提供明確重試 |
| 純 error 的可信 2xx／4xx `bad_refresh_token` | `.authenticationRequired`；provider 不再交付舊 snapshot |
| 純 error 的可信 2xx／4xx `incorrect_client_credentials`、缺少 app 設定、送出前已知失敗 | `.refresh`；保留 bundle，後續可再次更新 |
| 5xx、未知／混合／無效回應、送出後無可信回應 | `.refresh(rotationIndeterminate)`；停止 provider 並保留 store |
| 遠端 rotation 已接受後的本地 persistence failure | provider `.persist` 後永久 unavailable；不宣稱舊 bundle 仍可用，credential reconciliation 留待後續 topic |
| 任一 client 重送後第二次 401 | client 回傳 public technical authenticationRequired |
| 403、repository permission、resource visibility | 非 token-invalid signal；不 refresh |

## 更新失敗與取消契約

`OAuthTokenFetcher.refresh` 是 public typed-throws 契約；新增 `OAuthTokenRefreshError` 的 credentialRejected、clientConfiguration、knownTechnicalFailure、rotationIndeterminate 與 cancelled(stage:)。這是 source-breaking 變更；consumer conformance 必須採用新型別，不把原始 transport error、token 或 body 暴露到 public failure。

internal `GitHubOAuthHTTPTokenFetcher` 使用固定 GitHub token endpoint、POST form、JSON Accept、嚴格六欄成功回應與 receivedAt clock。可信 error 限純 error 的 2xx／4xx；5xx 或 token/error 混合回應優先歸輪替未知。預設 transport 使用 ephemeral URLSession、禁止 redirect／cookie／cache、30 秒界限且無 app retry。RivetHTTPClient 只作 raw sender，不承擔上述分類。

取消某 caller 不取消 shared refresh。可信回應已取得時仍解析並依真實結果更新狀態；有效 rotated pair 必須先保存。送出前取消為 nonterminal cancellation；送出後取消而無可信回應，當次回 cancellation，後續未取消 caller 收到 terminal `.refresh(rotationIndeterminate)`。GraphQL 在 provider await boundary 保留 caller cancellation。

access token 過期先觸發更新，不以 refreshTokenExpiresAt 預先拒絕。兩次成功更新並保存後仍到期的 local exhaustion 維持 nonterminal `.refresh`，後續 snapshot 與 replacement 均可再更新。重新授權後建立新 provider；產品 re-auth flow 已交付；明確退休舊 provider 後，僅新完整 bundle 保存成功可建立新 provider。

## Boundary 與後續 Topic

`GitHubIntegration` 現公開 `GitHubRestClient` 八個 async requirements 與四個 default builders，以及 Apollo 2.1.2 `GitHubGraphQLServing` 的 SingleResponseFormat Query／Mutation 契約；concrete clients 與 transports 保持 internal。Caller composition root 建立並保留 `OAuthTokenProvider`，以 `GitHubClientScope.prepare(provider:)` 完成 restore、expiry-first refresh、accepted rotation persistence 與本地 Bearer 驗證後，一次取得 `rest`／`graphql`。Scope 強持有原 provider，支援多 request lifetime；它不是 UoW、singleton 或 DI container，不探測 resource API，也不保證後續遠端 authentication、request 或 repository permission 成功。每次 execution 仍取得 fresh snapshot；兩 client 共用 single-flight／version，僅 HTTP 401 回報實際 snapshot 並最多重送原工作一次。Prepare 失敗或取消不交付 scope；caller 保留原 provider，不自動重建或 retry prepare。

`GitHubClientPreparationError` 僅包含 `.missingCredential`、`.authenticationRequired`、`.credentialLifecycle(stage:)`（restore／refresh／persist）與 `.invalidAuthorizationToken`，不含 credential、underlying error 或 body。Task cancellation、URLError.cancelled、provider underlying cancellation 與 typed refresh cancellation 正規化為獨立 `CancellationError`。Prepare 前後觀察取消，不承諾 await 立即返回；取消 caller 不取消 shared refresh，也不 rollback 已接受 rotation／persist。原 provider 的 terminal／rotation-indeterminate 狀態在重複 prepare 仍生效。Production 保持既有 transport routes；只有 internal factory seam 用於受控真實雙 client 驗證，沒有 public transport injection。

`GitHubRestClient: Sendable` 的八個 public requirements 為 `get/post/put/patch(url:headers:body:)` 與 `executeGet/executePost/executePut/executePatch(_:)`，均 async throws 回 raw `HTTPResponse`。四個 builder 的 public 預設實作組裝對應 method，委派 execution requirement；不提供 default arguments 或其他 overload，`headers` 與可重播的 `Data?` body 必須明傳（GET 亦可帶 body）。完整 request 的 method 不符或 URL 不合法時，在取得 credential 與發送前回 `.invalidRequest`；不暗改 method。首次 401 才要求 recovery，第二次 401 為 `.authenticationRequired`；非 401 原樣回傳，timeout／transport failure 不重送。舊 internal `executeGET` 已改為 `executeGet`，不保留 alias。

GraphQL interceptor 對當次 snapshot 建立 `BearerAuth`，經 public、nonthrowing Headers overload 授權，再將結果設回 `URLRequest` 副本；不直接呼叫 `AuthorizationHeader`，也不轉換為 `HTTPRequest`。`BearerAuth.init(token:)` 以 typed `AuthorizationHeaderError` 拒絕非法 Token，保存已驗證的 immutable 完整 Header value；其既有 Request overload 委派同一 Headers overload，replacement 與 `AuthorizationHeader` 共用單一 internal helper。建立端須補 `try`，`RequestAuthorization.applying` 仍 nonthrowing，diagnostics／reflection redaction 保留。

本地驗證失敗映射為不攜帶 Token 的 public `.invalidAuthorizationToken`；`next`、取消檢查與 HTTP status 分類維持在局部 catch 外。初始非法 Token 不發送、不 recovery；401 recovery 取得非法 replacement 時，停止重送且不再 recovery。既有 snapshot 隔離與 401-only 一次 retry 不變。REST 既有 `BearerAuth` 呼叫僅補 throwing 建立端，讓非法 Token 經既有 boundary 映射 `.executionFailed`；初始非法 Token 不發送或 recovery，非法 replacement 不重送或額外 recovery。此相容修正未新增 REST 能力，也未更改 recovery。

OAuth technical failure 不跨越成 shared BC failure contract；未來由 consuming BC 的 local Infra 映射為該 BC 自己的 failure contract。

初次 OAuth sign-in、authorization code + PKCE 與 callback 已由 `github-persistent-connection` 交付；logout／revoke 與 multi-account 仍須獨立 topic。本文件 supersede `github-integration-auth-boundary` 的 PAT-only、REST-only authorizer 方向；該歷史 topic 僅保留 traceability，沒有被改寫或刪除。

## 正式產品持續連線

`github-persistent-connection` 將登入、保存、重啟還原、刷新與 API 使用接成單一產品流程。責任以[產品責任 canvas](diagrams/github-persistent-connection/responsibility-canvas.html)為準；[初次授權 sequence](diagrams/github-persistent-connection/authorization-sequence.html)、[還原／刷新／重授權 sequence](diagrams/github-persistent-connection/restore-refresh-reauth-sequence.html)與[連線 lifecycle](diagrams/github-persistent-connection/connection-lifecycle.html)補足時間與狀態，重建與 QA 見 [BUILD](diagrams/github-persistent-connection/BUILD.md)。較早雙 client 圖仍描述其局部 runtime；產品圖擴充其組合，不改 ownership。

### 組合與授權契約

- [RivetApp](../../apps/Rivet/Sources/RivetApp.swift) 是最小 macOS 15+／Swift 6 GUI host，非 sandbox、`ENABLE_DEBUG_DYLIB=NO`。Debug 採目前 Mac 架構；不據此宣稱 Intel／Release 分發支援。Team、AppID、access group、有效 embedded profile 與固定安裝位置由私有本機設定注入；原免費 Personal Team 與既有 Apple Development certificate 的受限驗收不代表公開 packaging／notarization。
- [Coordinator](../../apps/Rivet/Sources/GitHubConnectionCoordinator.swift) 獨占一個 provider／scope，以及 prepare、GET/user、重試共用的 tracked operation admission gate。UI 取消後仍等原 Task.result settled；未結束時設定保存、修復或重授權回 `operationInProgress`，不排第二 session。所有重授權／修復先清除舊帳號並退休原 provider／scope；取消、grant 或保存失敗皆不得復活舊 provider。暫時 prepare 失敗可明確重試同 provider，terminal disposition 不以新 provider 繞過。
- [Presentation leaf](../../Sources/Presentation/GitHubConnection/GitHubConnectionView.swift) 只接受 display-ready 資料與 intent，含 SecureField 與有限操作，不依賴 GitHubIntegration。設定保存成功才開啟授權；denied／unavailable 保留兩個儲存項目，僅明確重試。可信 credential clientID 是修復權威；corrupt 資料不抽取 clientID，不做跨 item rollback。[完整 repair table](../../analysis/github-persistent-connection/technical-spec.md)保留全部分支。
- `GitHubOAuthAppConfiguration` 驗證 clientID／clientSecret 並遮蔽 description、debug 與 reflection。`GitHubOAuth` factory 交付 production fetcher 與 actor 授權 session；concrete HTTP／Security helpers 保持 internal。session 的 state 與 verifier 各取獨立 32 bytes 安全亂數，使用 S256 PKCE、`offline_access`、client secret exchange；secret 不進 authorize URL。
- [Loopback relay](../../apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift) 只綁 `127.0.0.1` 動態 port；ready 後才建立 session／開瀏覽器。僅接受 GET `/oauth/callback`，8 KiB 上限、連線讀取 5 秒、session 最多 5 分鐘；其他 path 靜態 404。session 驗證 exact scheme／host／port／path、state、重複 query 與 code/error 排他；無 userinfo／fragment，code 僅消費一次。callback 接受後停用取消，交換限 30 秒；所有出口關 listener，回應與診斷不含完整 callback query。
- 初次交換與 refresh 採固定 GitHub endpoint、ephemeral transport、禁止 redirect／cookie／cache，無一般 retry；可信純成功回應須完整六欄、bearer、有效有限到期秒數，scope 可空。production token receipt 依真時鐘建立，public credential bundle 不加入 Codable。
- [Account probe](../../apps/Rivet/Sources/GitHubAccountProbe.swift) 走 `scope.rest`，明傳 GitHub JSON Accept 與 `User-Agent: Rivet`，只有 HTTP 200、有效 id 與非空 login 顯示帳號；403 等不觸發額外 refresh。REST／GraphQL 仍共用原 provider lifecycle，HTTP 401 recovery 最多一次。

### DPK 保存與停止語意

[`GitHubOAuthDataProtectionStores`](../../Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift) 在精確 access group、service `local.rivet.github.oauth.v1` 下保存 `configuration`、`credential` 兩個 generic-password items。每次 query／update／add 皆 DPK=true、synchronizable=false；新增採 AfterFirstUnlockThisDeviceOnly。共用 actor 序列化 update-first，absent 才 add，duplicate 僅補 update 一次。不假設兩個 items 有跨 item transaction。

兩個嚴格 version 1 envelopes 分別保存 App 設定與 clientID-bound 六欄 bundle；日期使用有限 JSON milliseconds，允許 expired bundle 由 provider 決定刷新。未知版本、必要缺欄、非法型態或值為 corrupt；credential ID 不符為 identityMismatch。missing 僅限真正 item-not-found；denied／unavailable／corrupt 不當空資料覆寫。`inspectCredential()` 只交付嚴格解碼後的可信 clientID／bundle。舊 `KeychainTokenStore` 仍是 legacy 單一 access-token store，無自動遷移或實驗資料沿用。

refresh accepted 後必須先完整保存輪替結果，再交付新 snapshot；保存失敗依既有 provider 永久停止契約，不回退舊 token。`disposition()` 是純讀觀測：notStopped、authenticationRequired 與其他 stopped，不讀 store 或 refresh。產品提供明確重新授權，不自動復活舊 provider。

### 已驗證與限制

[正式入口證據](../../plan/github-persistent-connection/evidence/product-e2e.md)與[真實儲存證據](../../plan/github-persistent-connection/evidence/storage-live.md)經獨立 S08a Tester／S08b Reviewer 核對：首次真授權／保存／GET/user、同版本完整退出後新程序還原、真正 GUI Clean 後新 binary 同身分還原、受控 provider 到期後真 GitHub refresh accepted 1 次與 DPK 保存 1 次、輪替後新程序讀回且 refresh/save 為 0，五段 Human 全程皆 0 系統提示。

受控到期是明確 opt-in 的 provider clock，並非等待自然 8 小時。未改系統時間或持久 bundle 日期；token fetch receipt 用真時鐘，新 bundle 保存後 provider clock 回真時間。後一程序六欄 hash 與 accepted／persisted 完整新 bundle 一致，aggregate `tokenPairChanged=true`；沒有個別 token hashes，不能主張每個 token 各自變更。初次正常程序沒有觀測 digest，不補造初始 hash。受控開關只供驗收，正常模式使用 Date.init，細節見 [BUILD](diagrams/github-persistent-connection/BUILD.md)。

[契約測試](../../plan/github-persistent-connection/evidence/contracts.md)及[相容性證據](../../plan/github-persistent-connection/evidence/compatibility.md)涵蓋取消／拒絕／無效 callback、完整 repair table、儲存失敗與 terminal、並行 settlement、client policy、test-mode 零 live dependencies；它們是 fake 或受控測試，不是刻意破壞真 credential 的 live 驗收。已通過 29 hosted tests、root 226 tests／25 suites 與 consumer 13 tests／3 suites，不重複相加早期子集合。

適用同一 Mac／GUI 使用者、AppID／access group／certificate、固定安裝位置與有效 profile。免費 Personal Team profile 的 7 日有效期內成立；過期區間不可用，certificate rotation、公開分發、其他機器與多程序 refresh 協調不在證據內。E007 兩輪皆 unknown，profile 更新後 read 未執行；Human 明示接受此唯一 gate 例外，並未把它改成通過。以下 E001–E007 保持當時歷史結論，內文的 deferred 不代表否定後續本產品交付。

## E001 受限可行性依據

[實驗 E001：GitHub OAuth 重導向可行性驗證](../../experiments/E001/README.md) 已於 2026-10-07 完成一次真實 GitHub OAuth App → 系統瀏覽器 → IPv4 loopback callback 測試。遮蔽後結果為 `code_present=true`、`state_matches=true`、程序 `exit_code=0`，人類亦確認成功 callback 頁；未保存 code/state 或完整授權 URL。

此依據僅證明 E001 獨立 runner 的此次 redirect/code/state 流程可行。實驗未交換 token，未驗證 token acquisition、refresh、Keychain 或產品登入；實際 port 與瀏覽器版本未記錄，不補造數值。本次不鎖定產品 callback architecture，正式 authorization 與 app 整合仍須由後續獨立 topic 處理，既有 shared token lifecycle 與雙 Client 責任決策保持。

## E002 受限交換與 credential 相容性依據

[實驗 E002](../../experiments/E002/README.md) 於 2026-10-07 使用 runner commit `d87407fbdc739a5e564e8777f149a9fbc3f0e1b0` 沿用 E001 OAuth App 與 IPv4 loopback，完成兩次新授權。L02 獨立 Reviewer 已核准如實保存 [遮蔽 stdout](../../experiments/E002/evidence/2026-10-07-live-safe-report.txt) 與 [receipt](../../experiments/E002/evidence/2026-10-07-live-receipt.json)；這是受限實證，不是正式採用決策。

本次正向 code exchange 取得非空 access token；回應符合本地嚴格六欄 DTO（`access_token`、`refresh_token`、`expires_in`、`refresh_token_expires_in`、`token_type`、`scope`），且可建立 public `GitHubOAuthCredentialBundle`；唯一一次 `GET /user` 回 200 且具有效 id／非空 login。結論僅支持本次 App／請求的初次交換、六欄相容性與 API 成功，不宣稱執行產品 internal decoder、refresh／rotation、Keychain 或 client integration。

反向使用另一組新 state／challenge／code 與合法但不匹配的 verifier，固定分類為回應／錯誤未確認，PKCE 與 overall 無法判定、exit1。兩次授權預算 2／2 已用盡；原始反向 body 未保存且程序已結束，不能追補 HTTP status／error 或據此推論 PKCE 拒絕原因。receipt 時間僅為外層檔案建立時間 proxy，非精確交換事件時間。本次不鎖定正式採用或 secret 部署方式，不改 shared lifecycle／雙 Client 的既有架構決策。

## E003 受限 refresh／rotation 實證

[實驗 E003](../../experiments/E003/README.md) 於 2026-10-08 沿用 E002 OAuth App，以一次新授權取得 refreshable credential，完成單次遠端 refresh／rotation 測量；runner exit 0，遮蔽結果為 T01–T04 與 overall 均成功。T01 初始 access token 的 `GET /user` 回 HTTP 200 且有有效身分；T02 一次 refresh 取得各自更換的非空 access／refresh token、有效六欄與可建立的 public `GitHubOAuthCredentialBundle`；T03 新 access token 的 `/user` 回 HTTP 200 且身分一致。T04 唯一一次重用舊 refresh token 的 HTTP status 為 200，但 body 含明確 `bad_refresh_token` 且無新 token；拒絕判準來自 body，不能由 HTTP 200 單獨推論。

此證據只支持本次 App／帳號的 refresh exchange、credential 相容性、身分一致與舊 refresh token 拒絕，不表示產品 `OAuthTokenProvider` 自動刷新、持久化、並行、401 recovery、正式 OAuth adapter 或遠端 revoke 已驗證。App 全域 expiring-token 設定未另行查證；E002 反向 PKCE 與 overall「無法判定」結論保持獨立。E003 的遮蔽 stdout、程序外層時間與單次實驗限制保存在實驗 README；repository 證據未保存 secret、code、token、user ID 或原始回應；browser／OS 留痕不在 runner 控制範圍。本次實證不改變上述 shared lifecycle 與雙 Client 的責任決策。

Mutation 沿用 request-local snapshot 與 401-only 最多一次 recovery；合法 partial／errors-only response、timeout、transport／parse failure 不重送。取消或 transport failure 不保證遠端未執行寫入，也不提供 rollback；不包含產品 operation 或寫入結果 reconciliation。

## E004 受限 SQLite 儲存與 provider lifecycle 實證

[實驗 E004](../../experiments/E004/README.md) 於 2026-10-14 在 arm64 macOS 26.5.2／Apple Swift 6.3.3，以獨立 Swift tools 6.1 package、GRDB 7.11.1、真磁碟 SQLite 與既有 `OAuthTokenProvider` 完成受限驗證。所有憑證、refresh 回應與時鐘皆為模擬輸入；沒有呼叫 GitHub OAuth。這是 feasibility experiment，並非正式 credential adapter 的交付或採用決策。

[Runtime 證據](../../experiments/E004/evidence/2026-10-14-runtime.txt)記錄 T01–T06 全部成功、probe exit 0；[Swift Testing 證據](../../experiments/E004/evidence/2026-10-14-swift-test.txt)記錄六個測試通過。獨立 writer 結束後，fresh reader 逐欄讀回完整 bundle；到期刷新後，新程序可讀回兩個 token 均已輪替的完整 bundle。同一 provider 的本次 12 個重疊需求只 refresh 一次，後續 stale snapshot recovery 沒有額外 refresh。

故障注入先成功執行部分 SQL 改寫並於交易內確認可見，再在 commit 前拋錯；rollback 後新程序仍讀回完整舊 bundle。fake fetcher 接受輪替後若保存失敗，同一 provider 的後續 snapshot／replacement 持續 `.persist`，沒有額外 refresh 或 save。空 store、損毀 DB 與唯讀寫入故障維持不同分類；後兩者分別觀察到 `SQLITE_NOTADB` 與 `SQLITE_READONLY`。

這些觀察支持 GRDB＋SQLite 在上述條件下作為 `OAuthCredentialStore` 的候選後端，並沿用既有 provider 的持久化及失敗契約；不代表正式 adapter、秘密儲存或產品登入已交付。未驗證其他 compiler／OS、所有並行排程、真 GitHub OAuth、client 401 retry、sandbox 隔離、加密、斷電 durability 或跨程序 refresh 協調。SQLite 路徑名稱不提供秘密保護；輪替保存失敗後舊 bundle 完整保留，不表示真遠端仍接受它。正式採用、最低工具鏈與 reconciliation 仍須另行決策，既有 OAuth lifecycle ownership 與正式 adapter deferred 狀態不變。

## E005 本機 Keychain 完整憑證的受限實證

[實驗 E005](../../experiments/E005/README.md) 於 2026-10-15 在 arm64 macOS 26.5.2／Apple Swift 6.3.3，以無憑證、無 profile 的 ad-hoc app-like CLI，明確選用 legacy file-based Keychain（DPK selector false、同步 false），保存固定假 OAuth bundle。writer 結束後兩個 fresh reader 的六欄均一致；恢復原 binary 身分後整筆替換 B，新程序六欄均為 B。這只支持本次 host 的跨程序資料保存與完整替換，不是正式 Keychain adapter 交付。

真正修改 build marker 並重新建置後，binary hash 改變、簽章有效，但 designated requirement 不一致；T03 沒有執行 acceptance read，不能以相同 bundle ID 或還原舊 binary 讀回冒充同身分重建成功。初輪 machine 收據的提示次數維持 null／unobserved，真實拒絕授權未測。後續 03:16:56–03:17:01 UTC 的新 UUID 補測，Human 明確回報全程觀察 0 次 Keychain 提示；[獨立人工觀察](../../experiments/E005/evidence/human-observation.json) 以 SHA-256 綁定該輪 machine 收據，原 null 欄位與歷史證據未覆寫。這只支持該輪原 binary 身分下實際保存、fresh-process 讀回、替換及清理的零提示體驗，不涵蓋未執行的 T03 acceptance read。主假設仍為**無法判定**，不表示機制失敗或核准採用。DPK 免費 host／profile 前提仍未證實，不能據此推論必須付費。

真實 absent／malformed 分類與所有本輪已嘗試寫入的主要／負向／停止項目清理均有證據，確認不存在。SIGINT／SIGTERM 控制流程及清理期間重複訊號以明標 synthetic 測試驗證；寫入後受控例外清理另有真實 Keychain 證據，兩者不混作真實訊號中斷的 Keychain 或 UX 證明。不可捕捉停止／程序或主機失效仍不保證 finally 清理。

後續需要免費且維持穩定 code identity 的 host 與實際系統提示觀察，再返回採用決策；不得自行新增帳號／憑證或放寬 ACL／安全設定。既有 non-BC GitHubIntegration 邊界、OAuthTokenProvider ownership、production APIs 與 Keychain adapter deferred 狀態保持。

使用者後續明確授權實驗專用自簽 Code Signing 憑證／私鑰與獨立實驗 Keychain，僅補同一 legacy／假六欄的穩定簽章前提。[PKCS12 preflight](../../experiments/E005/evidence/self-signed-preflight.json) 停於匯入 exit1；一次 [PEM 相容性 preflight](../../experiments/E005/evidence/self-signed-pem-preflight.json) 成功匯入憑證與私鑰後，首次簽章 exit1。未取得兩版有效簽章／相等 DR，沒有 OAuth 寫入或 T03 acceptance read；根因尚未確認，不推論信任錯誤、必須付費或自簽方案普遍不可用。兩輪專用 Keychain 與秘密暫存完整清理，default Keychain／全域搜尋清單前後一致；未改系統信任、既有 ACL 或安全設定。獨立 Tester／Reviewer 已核對受限紀錄；原 binary 的 Human 零提示結論保留，主假設仍無法判定。現有 host 已有 app-like `.app` 包裝，尚無證據表示改成 GUI App 可解除此簽章缺口。後續仍須釐清免費穩定簽章前提，才可補 T03 與新 host 的 UX 觀察；此不核准正式採用。

使用者要求續行後，同一 PEM 自簽候選的 [限定診斷](../../experiments/E005/evidence/self-signed-diagnostic.json)（03:46:15–03:46:19 UTC）只查本輪專用 Keychain：1 matching／0 valid identities，codesigning policy 分類 `CSSMERR_TP_NOT_TRUSTED`；首次 codesign 回 `no identity found`。這具體指出本次重現的可用簽章身分前提未成立，前兩輪未保存的根因不倒填。未調整信任設定，零 OAuth 寫入、T03 acceptance 未執行；專用 Keychain／秘密清理完整、全域設定一致。獨立 Tester／Reviewer 已核對。若沿此自簽路徑進入信任調整，須另獲 Human 明確授權；不推論必須付費，也不核准正式採用，原 host 的 Human 零提示依據保留。

後續 Human 限定授權本輪實驗 cert 的 user-domain／Code Signing trust，並親自完成系統設定授權。四輪 [最新 E005 紀錄](../../experiments/E005/README.md) 中，系統附加 policyName 造成的 checker 誤拒已依 Apple OSS 修正為僅接受標準 CodeSigning metadata，實際 type／OID／trustRoot／domain 限制維持。[Metadata 收據](../../experiments/E005/evidence/limited-trust-metadata-run.json) 與 [SHA-1 selector 收據](../../experiments/E005/evidence/limited-trust-sha1-run.json) 均驗證限定 trust 讀回成立、私有 Keychain 有 1 matching／1 valid identity；後者亦確認 exact cert DER 指紋相符，但 codesign 仍回 no identity found。四輪全部零 OAuth 寫入、無兩版有效簽章／DR 或 T03 acceptance，主假設仍無法判定。每輪 exact-cert trust 已撤回並確認三 domain absence，專用 Keychain／秘密完整清理，default／search-list 未變，無已知殘留；獨立 Tester／Reviewer 已核對。

這支持免費 cert 與限定 user/codeSign trust 的局部可用性，不支持本 host 在現有隔離條件下成功簽署或穩定重建，也不核准正式 adapter。下一個待測前提為本機 Apple codesign 手冊所述的使用者 Keychain 搜尋清單要求；本輪明確禁止修改，未介入，不能稱已證實為唯一根因或推論必須付費。任何暫時加入專用 Keychain 的新試驗須另獲 Human 授權並規劃精確恢復；原 binary 的 Human 零提示依據保留，setup 授權不冒充 runtime UX。


**後續受限實證（2026-10-15）。** Human 另明確授權暫時將專用實驗 Keychain 加入 user search-list 後，唯一 [補測](../../experiments/E005/evidence/user-search-list-run.json) 已建立免費自簽／user-only codeSign trust／無 profile 的兩版有效簽章：first writer 與 marker 重建的 second reader hash 不同、DR 相同、path／bundle／entitlements 一致，六欄 A 完整還原；second 整筆替換 B 及 fresh read B 亦成立，真 absent／malformed 分類成功。這已解除本輪 T03 資料機制缺口；不能宣稱搜尋清單是其他環境失敗的唯一根因，亦不外推 DPK。

兩項 OAuth、exact-cert user trust、own search-list membership、專用 Keychain／秘密均精確清理；原搜尋順序／default 恢復、無已知殘留。[Human 觀察](../../experiments/E005/evidence/user-search-list-human-observation.json) 綁定 machine SHA：全程回報第一次密碼並選「永遠允許」、第二次指紋，但無法確認兩次屬 runtime 或撤 trust，故 runtime promptCount 仍未知，UX／主假設仍無法判定。不能依耗時猜階段或把「永遠允許」當作未測下一次重建的證明。獨立 Tester／Reviewer 核對，受限紀錄任務完成；未驗證長期保留 identity reuse，實驗 cert 已刪除。正式 adapter／採用仍延後，原 provider ownership 不變。


**分段 UX 真人補測（2026-10-15）。** 後續經 Human 明確授權免除桌面工具連線前提，改由本人逐段觀察，唯一 [Human-only 結果](../../experiments/E005/evidence/ux-human-only-result-20261015T080306Z.json) 已將設定、正常存取與清理提示分離：首次保存／存取 0 次、相同 binary 的 fresh-process 讀取 0 次、不同 hash／相同 DR 的重建版讀取 1 次憑證提示。Human 明確回報該次只能輸入密碼並選「允許」；setup 與撤 trust 各一次指紋設定授權另記。每段皆在前段完整觀察及新 ready 後執行，machine／Human SHA 綁定與控制原樣 snapshots 均保存於 [本輪證據](../../experiments/E005/evidence/ux-human-only-20261015T080306Z/)。

六欄資料全數還原、身份／簽章前提成立，OAuth／exact-cert trust／own search-list membership／專用 Keychain與秘密已精確清理，原清單順序及 default 恢復。獨立 Tester／Reviewer 核對後，按寫入前「首次最多一次，fresh-process與同身分重建均零」判準，**此候選 UX 失敗、資料機制成功，受限驗證任務完成**；本輪不再是提示階段未知。前輪 unknown 收據保留，不把本次「允許」混成前輪「永遠允許」，不推論其他選項或未測下一次重建。這是本次 macOS／legacy／隔離自簽＋限定 user Code Signing trust／暫時 user search-list 條件的結果，不證明所有免費 Keychain 路徑不可行或需要付費；DPK、其他 macOS、長期 retained identity 及真 denial 仍未驗證。正式 adapter／採用繼續延後，既有 provider ownership 不變。
