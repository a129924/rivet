# 正式 OAuth 能力與獨立驗證 App

本 topic 交付正式 GitHub OAuth 實作能力與獨立 `GitHubSignInVerification` App。**正式 Rivet 產品登入 UI 尚未交付**。驗證 App 使用真 OAuth／GitHub API，配置與完整 bundle 只留當次程序，不是 mock app，也不是 Rivet 主畫面。

## 責任與契約

GitHubIntegration 保持 non-BC。正式能力為 `GitHubOAuthAppConfiguration`、`GitHubOAuth.makeTokenFetcher(configuration:)`、`makeAuthorizationSession(configuration:redirectURI:)`、`GitHubOAuthAuthorizationSession`、internal `GitHubOAuthCodeExchanger` 與 `GitHubOAuthAuthorizationError`。Session 封裝 state／verifier／單次 callback claim，驗證 loopback URI、state、單值 code/error，採 S256／offline_access。無效 callback 不消耗有效等待；取消、到期或重複結果不發布連線。初次交換無自動重送，完整六欄依同一 receivedAt 建立既有 bundle。

驗證 App 擁有 `GitHubConnectionView`／`GitHubConnectionPresentation`、coordinator／dependencies、loopback relay、完整記憶體 store、caller-owned provider／scope、`GitHubAccountProbe`／Identity／Error 及 hosted tests。兩個 UI 型別只在 App module 內部使用，不再由共用 RivetPresentation 公開；PR Inbox Presentation 不改。日後刪除整個驗證 App，不需修改或刪除 GitHubIntegration 正式 OAuth 能力。沒有新共用 module、CurrentUserReader 或帳號業務抽象。

Relay 僅綁 127.0.0.1 動態 port，限制 headers／connections／讀取時間。Coordinator 追蹤單一 operation，取消後等實際工作 settled；prepare 重試保留原 provider，再次查詢使用原 scope。既有 credential／refresh／rotation／single-flight／401 recovery 及 BC 邊界不變。

驗證成功指 `/user` HTTP 200 且 login／id 有效，不是 callback 或 prepare 成功。UI 顯示身分供驗證，沒有正式帳號顯示需求。Secret／token／callback 不寫 diagnostics、檔案或證據；證據只記必要有效／一致等布林。

## 本機建置與驗證

在 Xcode 開啟 `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj`，選 `GitHubSignInVerification` scheme、My Mac。App／test target 分別為 `GitHubSignInVerification`／`GitHubSignInVerificationTests`。使用 macOS 15+／Swift 6、ad hoc 簽章；不需 Team／profile／Keychain entitlement。

```sh
xcodebuild -project apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj -scheme GitHubSignInVerification -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/VerificationHostDerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build test
open .build/github-first-sign-in/VerificationHostDerivedData/Build/Products/Debug/GitHubSignInVerification.app
```

Hosted TestAction 使用 `GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE=1`；entry 在建立 live dependencies 前改用 disabled dependencies，測試自行注入 fake，不啟動真 OAuth。一般啟動不還原、不自動開瀏覽器，按登入才開始。

若 Human 選擇真登入，自行輸入自有 OAuth App 的配置。callback 設為 `http://127.0.0.1/oauth/callback`，runtime 帶動態 port；外部 App 更動由擁有者確認。不讀 gh credential 或先前機密，不自行改 OAuth App。

## 版本來源與限制

基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22` 的舊 `apps/Rivet` 外殼曾由 Human 完成正常授權，agent 觀察實際 API 與再次查詢成功。其能力證據可沿用，舊外殼名稱不代表產品 UI 已交付；不能冒充新驗證 App 已真登入。2026-10-21，Human 在來源版本 `e941d88c0b3a7bfc117ecf9f0ccecfe7e86e65d7` 的獨立驗證 App 自行輸入配置、完成真實授權；agent 觀察初次實際 API 成功與有效身分欄位，再操作「再次查詢」並確認成功，未重新授權。使用既有受控建置產物，並非本次重新建置；產品 source 與該版本一致。只記有效／成功等分類，不保存身分值、配置、callback 或截圖。新 host 正向與再次查詢已觀察通過；反向 PKCE enforcement、全部遠端 refresh／401、跨重啟及完整 Human review 仍未因此通過。E001–E003 實驗保留原限制。

現行 [責任 canvas v2](diagrams/github-first-sign-in/index-v2.html) 與 [授權 sequence v3](diagrams/github-first-sign-in/authorization-sequence-v3.html) 反映驗證 host。舊 frozen 圖原樣保留為歷史來源，不作現行產品事實；[工具／視覺限制](diagrams/github-first-sign-in/visual-review.md) 分列自動檢查與實看。

持久化／DPK／跨重啟及正式產品 host 的後續整合另行規劃，不假定驗證 host 就是產品。四份 planning 與本次精確搬移契約見 `analysis/github-first-sign-in/`、`plan/github-first-sign-in/`。

## 現行 canvas 與反向 PKCE 驗證（2026-10-21）

Human已自行開啟來源d11f343的現行canvas v2，逐步確認文字/箭頭及責任邊界、拖曳、縮放可讀、點選聚焦/說明、明暗切換皆通過。圖與frozen來源未修改，agent未繞過browser URL policy；先前工具限制與歷史pending保留。

反向PKCE只使用驗證App旁的[獨立CLI](../../apps/GitHubSignInVerification/tools/README.md)，不改正式OAuth／SwiftApp，不擴張public API。missing/wrong各一個新process、新code及單POST，不重做正向/API；Human本機TTY隱藏輸入配置。固定allowlist以外均不冒稱PKCE通過，generic bad_verification_code無法歸因。2026-10-21已依序執行missing與wrong，各新process／一次授權／單次POST；Human安全報告均HTTP400、remote_rejected=true、token_present=false、unknown_error/unknown，按固定判準皆無法判定，不宣稱PKCE enforcement通過。兩次預算已用盡，未保存原body/description，不能追補原因或事後改allowlist，不重試。結果見[脫敏證據](../../plan/github-first-sign-in/evidence/pkce-negative-verification.md)。完整遠端refresh/401本輪不執行、保持pending。

### Q 輪：獨立反向 PKCE 診斷 version 2

本輪僅改善獨立驗證 CLI 的有限脫敏分類，不改正式 OAuth、credential/provider/scope或refresh/401契約。事前固定完整模板與case/衝突規則，區分GitHub拒絕及已證明PKCE拒絕；僅提及verifier、一般invalid_grant或unknown都不是通過證據。P兩次HTTP400 unknown/indeterminate保留，不追補原回應。Q新missing/wrong各一次、總2/2已用完：兩案HTTP400 invalid_grant/code_problem、無token，description unknown且mentions_verifier=true，均無法判定；hint不能證明PKCE原因，不擴表或重試。受控25tests通過不代表遠端通過。[新版來源與證據](../../plan/github-first-sign-in/evidence/pkce-diagnostics-v2.md)。正常登入/再次查詢及canvas既有Human結果沿用；正式Rivet產品登入UI、完整遠端refresh/401仍未交付或pending。
