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

### R 輪：唯讀診斷調查與停止

來源21e2542；既有CLI的RFC S256公開向量及兩case fixture組裝共11bool通過，未找到實際組裝bug證據。固定完整句辨識有限，但未保存的description不能重建；真client配置/服務端grant狀態仍未知。在已查官方及現有工具材料下，未取得可靠的新遠端辨識契約，依Human條件不修改工具、不選case、不執行新授權，R **0/1未使用**。P/Q各2/2及indeterminate歷史原樣保留，正常登入/再次API/canvaspassed不重做；正式OAuth契約未變，完整遠端refresh/401及完整Humanreview仍pending。[候選原因、證據與限制](../../plan/github-first-sign-in/evidence/pkce-diagnostic-investigation.md)。

### T 輪現行：有限診斷 version 3

Human指示續行後，獨立CLI新增實際browserURL/HTTP prepared Request被動觀測、local一致性gate、有限完整句法及純詞彙hints。只輸出安全enum/布林，未知仍可無法判定，未觀測或不一致不能passed；這是本機prepared證據，不冒稱遠端wire。正式OAuth/credential/provider/scope/refresh401與公開API不變。36項受控測試、獨立Tester/Reviewer已通過；凍結版本後Human完成wrong一次，共享R→T **1/1已用盡**。實際prepared local一致、valid_different、under_5s；HTTP400 invalid_grant、無token，verifier/challenge/mismatch提示為true但完整grammar未命中，仍無法判定PKCE原因。停止重試/第二次/positive/refresh401，不以hint或本機gate當遠端證明。P/Q/R舊證據與正常App/canvaspassed保留。[version3來源與限制](../../plan/github-first-sign-in/evidence/pkce-diagnostics-v3.md)。

## U：Human-only 語義 review 工具目前狀態

已實作 private Swift/AppKit helper、parent gate／先清理再匿名 pipe，以及無網路／無 ID-secret 的 `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review` 校準入口；U03／U04 completed、獨立 U05 approved（P2 closed、無其他 required fix），工具可交付、U06 待 Human 正式 offline 校準，不自動啟動。若未來另准 live，通過 gate 的原文僅 Human 短暫看，agent／Reviewer 不看、不保存；`provider_semantic_observation` 是獨立 Human attestation，不改既有 proof／outcome。SystemRandom 打散後只送 description；工具不讀／比較 `expected_category`、不自評，末尾 opaque correlation_id＋有限 observations 由獨立 Tester 評分，9/9 decisive＋7/7 unknown 標準不變。P2 selectors/stderr 回修後獨立 Tester 親跑 57 項受控測試通過，strict format／SwiftLint exit 0；單次 smoke 不證明自然 timeout 或 Human holdout 通過，完整 UI／clipboard／restoration／timeout 與 Human 9+7 仍 pending；OAuth 新額度 0、R→T 1/1 歷史不改。[操作與限制](../../apps/GitHubSignInVerification/tools/README.md)。

### U06 最新結果：方法未達資格，停止 live

來源 `f420901a1076537c4f7aa0404fe31509b8bdc889`。獨立 Tester 已核對 frozen fixture SHA／16 個唯一映射，正式 offline 校準為 decisive **6/9**、abstain **2/7**，未達 9/9＋7/7，`calibration_threshold_met=false`；U06 completed-not-qualified，方法 needs-rework，停 Human 決策。Human 明示不懂英文，屬方法語言前提未滿足，不是使用者過失。獨立 Reviewer 的結果處置 approved 僅准文件記錄與停止；57 項受控測試與原 U05 code approved 保留，不放行 live、不代表正式 OAuth bug 或 PKCE failed。先前 pending 是執行前歷史；smoke 是另一次受手動操作中止的事件，不算這 16 cases。新 OAuth=0、R→T1/1 已耗盡與正常 App/API/canvas／P/Q/R/T 歷史不變。不改 frozen fixture、不重跑16、不新實作；Human最新已同意本機繁中offline候選，但語言資產未齊、目前不可用；Human已同意自行下載，待完成回報才重查；既有inventory仍supported非installed，未翻譯／下載／新查，live仍未授權。[安全結果](../../plan/github-first-sign-in/evidence/pkce-semantic-review.md)。

## V：實際研究結果與停止

V03新fixture已獨立approved／frozen；V04a只保留installed-only translator core與compile-time固定fixture runner作研究證據，正常binary無dump、CLI未改。V05a唯一真引擎序列16/16技術成功（2.646s、exit0、stderrfalse），58受控／compile／strict通過；獨立V06a語義fidelity failed／needs-rework，至少8處術語／角色失真，不編造精確語義通過數。另一次bounded code Reviewer approved、無required fix／不需額外驗證，僅研究工具code，不推翻fidelity失敗。中文GUI／CLI／Human校準未執行且停止，不宣稱繁中能力已交付。語言包installed、OAuth新增0；U06／PQRT／App/API/canvas歷史保留。Human最新允許規劃AI閱讀經安全檢查的描述，並接受資料可能離Mac／留於對話服務及gate殘餘風險；僅規劃，實際原文揭露／bridge／具體欄位與傳遞方式尚未批准，OAuth0，不擴V實作。 原scratch JSONL不可再讀、未量測原bytes SHA，Reviewer依據Tester同次工具輸出直接轉交的synthetic譯文，非reference重建；不追補。[證據界線](../../plan/github-first-sign-in/evidence/pkce-semantic-review.md)。
