# Rivet

Rivet 是一個個人 GitHub PR 工作台。

它的首版目標是集中查看目前等待使用者 review 的 GitHub.com open Pull Request，降低在 GitHub 網站、repository 與 PR 之間切換的成本，並成為日常挑選與開啟 PR 的優先入口。

## 成功標準

連續兩週以上，使用者在挑選及開啟待 review PR 時優先使用 Rivet。

## 文件導覽

- [產品規範](docs/product.md)
- [架構規範](docs/architecture/)
- [設計原則](docs/design-principles.md)
- [開發工具鏈](docs/toolchain.md)
- [GitHub PR API Catalog](docs/github-api/)
- [開發分支流程](docs/development-workflow.md)

## 目前狀態

`GitHubIntegration` 現公開 `GitHubRestClient` 八個 async requirements 與四個 default builders，以及 Apollo 2.1.2 `GitHubGraphQLServing` 的 SingleResponseFormat Query／Mutation 契約；concrete clients 與 transports 保持 internal。Caller composition root 建立並保留 `OAuthTokenProvider`，以 `GitHubClientScope.prepare(provider:)` 完成 restore、expiry-first refresh、accepted rotation persistence 與本地 Bearer 驗證後，一次取得 `rest`／`graphql`。Scope 強持有原 provider，支援多 request lifetime；它不是 UoW、singleton 或 DI container，不探測 resource API，也不保證後續遠端 authentication、request 或 repository permission 成功。每次 execution 仍取得 fresh snapshot；兩 client 共用 single-flight／version，僅 HTTP 401 回報實際 snapshot 並最多重送原工作一次。Prepare 失敗或取消不交付 scope；caller 保留原 provider，不自動重建或 retry prepare。

完整 REST endpoint 能力、各 BC adapters、Keychain OAuth credential adapter 與產品登入仍延後。初次 OAuth App 配置、一次性授權 session／code exchange 及獨立驗證 host 已納入本 PR；驗證入口不等於正式產品登入。詳見[初次登入與驗證工具契約](docs/architecture/github-first-sign-in.md)。合法 raw REST 與 Apollo partial／errors-only responses 保持；有限 technical errors 與 cancellation 不形成 shared BC failure contract。

Rivet 目前是可公開的 architecture baseline repository。它保留產品與架構決策、Bounded Context Map，以及 Swift／Node 版本基線；root Swift package 已包含受限的產品實作。

目前已實作 non-BC `RivetPresentation` library target 的原生 SwiftUI `PullRequestRow` leaf、display-ready Presentation input、組合 Row 的 `PullRequestList`，以及獨立的 `InboxHeader`。List 提供 parent-owned 單選、清單焦點、鍵盤選取與安全的 Open PR intent；Header 顯示 parent 提供的標題與副標，並以原生三選一控制將 Presentation filter 選擇交還 parent，不篩選 PR。完整 Inbox 的初次選取與 stale selection fallback、Reader 導覽及 app menu 仍由未來上層整合。該 target 不依賴任何 Bounded Context，也不包含 Domain／Application mapper；後續仍以一次一個 Bounded Context 或 bounded Presentation slice 的節奏推進，並以 `analysis/`、`plan/` 與 `docs/` 的配對文件保留可追溯決策。

GitHubIntegration 已交付 internal `GitHubOAuthHTTPTokenFetcher`，以 generic HTTPClient 執行固定 refresh POST；public `OAuthTokenFetcher.refresh` 使用 typed `OAuthTokenRefreshError`。只有可信純 error 的憑證拒絕映射為 `.authenticationRequired`；設定錯誤維持 `.refresh` 且可再次嘗試。輪替未知與遠端已接受後的 persistence failure 停止該 provider，保留 store。這些 GitHub-specific 分類屬於 GitHubIntegration；通用 HTTPClient 與各 BC 的業務 failure 邊界維持。[完整契約](docs/architecture/github-oauth-dual-client.md)記錄取消與過期行為。

## 正式 OAuth 能力與獨立驗證 App

`GitHubIntegration` 已交付正式初次 OAuth configuration／factories／session／code exchange／errors，沿用既有 credential、provider／scope／clients。獨立 `apps/GitHubSignInVerification` 收納配置與驗證 UI、loopback relay、coordinator、完整記憶體 store、`GitHubAccountProbe` 與 hosted tests；使用真 OAuth／API，結果只用於驗證。共用 `RivetPresentation` 不公開驗證 UI，既有 PR Inbox 保持原樣。正式 Rivet 產品登入 UI 尚未交付。

2026-10-21，Human 在來源版本 `e941d88` 的獨立驗證 App 完成真實授權；agent 觀察實際 API 成功與同程序再次查詢成功。舊版 `e63eeb2` 證據另保留；現行 canvas v2 的人工互動已通過。2026-10-21 反向 PKCE missing／wrong 各執行一次，均 HTTP400 拒絕但原因 unknown，兩者結論皆無法判定；完整遠端 refresh／401 本輪不執行，持久化亦未因此驗證。詳見 [首次 OAuth 契約](docs/architecture/github-first-sign-in.md)。

### Q 輪：獨立反向 PKCE 診斷 version 2

本輪僅改善獨立驗證 CLI 的有限脫敏分類，不改正式 OAuth、credential/provider/scope或refresh/401契約。事前固定完整模板與case/衝突規則，區分GitHub拒絕及已證明PKCE拒絕；僅提及verifier、一般invalid_grant或unknown都不是通過證據。P兩次HTTP400 unknown/indeterminate保留，不追補原回應。Q新missing/wrong各一次、總2/2已用完：兩案HTTP400 invalid_grant/code_problem、無token，description unknown且mentions_verifier=true，均無法判定；hint不能證明PKCE原因，不擴表或重試。受控25tests通過不代表遠端通過。[新版來源與證據](plan/github-first-sign-in/evidence/pkce-diagnostics-v2.md)。正常登入/再次查詢及canvas既有Human結果沿用；正式Rivet產品登入UI、完整遠端refresh/401仍未交付或pending。

### R 輪：唯讀診斷調查與停止

來源21e2542；既有CLI的RFC S256公開向量及兩case fixture組裝共11bool通過，未找到實際組裝bug證據。固定完整句辨識有限，但未保存的description不能重建；真client配置/服務端grant狀態仍未知。在已查官方及現有工具材料下，未取得可靠的新遠端辨識契約，依Human條件不修改工具、不選case、不執行新授權，R **0/1未使用**。P/Q各2/2及indeterminate歷史原樣保留，正常登入/再次API/canvaspassed不重做；正式OAuth契約未變，完整遠端refresh/401及完整Humanreview仍pending。[候選原因、證據與限制](plan/github-first-sign-in/evidence/pkce-diagnostic-investigation.md)。

### T 輪現行：有限診斷 version 3

Human指示續行後，獨立CLI新增實際browserURL/HTTP prepared Request被動觀測、local一致性gate、有限完整句法及純詞彙hints。只輸出安全enum/布林，未知仍可無法判定，未觀測或不一致不能passed；這是本機prepared證據，不冒稱遠端wire。正式OAuth/credential/provider/scope/refresh401與公開API不變。36項受控測試、獨立Tester/Reviewer已通過；凍結版本後Human完成wrong一次，共享R→T **1/1已用盡**。實際prepared local一致、valid_different、under_5s；HTTP400 invalid_grant、無token，verifier/challenge/mismatch提示為true但完整grammar未命中，仍無法判定PKCE原因。停止重試/第二次/positive/refresh401，不以hint或本機gate當遠端證明。P/Q/R舊證據與正常App/canvaspassed保留。[version3來源與限制](plan/github-first-sign-in/evidence/pkce-diagnostics-v3.md)。

### U：Human-only 離線語義 review 工具

已實作 private Swift/AppKit helper 與無網路校準入口 `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review`，U03／U04 已完成、獨立 U05 approved（P2 closed、無其他 required fix），可交付工具並由 Human 明確參與正式 offline 校準。若將來另准 live，原文只能通過 gate 後由 Human 短暫閱讀，agent／Reviewer 不看、不保存；新增 `provider_semantic_observation` 只是 Human attestation，不改 proof／outcome。工具以 SystemRandom 打散 synthetic cases，不讀／比較 `expected_category`、不自評；末尾僅輸出 opaque correlation_id 與有限 observations，交獨立 Tester 核分。P2 selectors/stderr 回修後，獨立 Tester 親跑 57 項受控測試通過、strict format／SwiftLint 均 exit 0；完整 UI／clipboard／restoration／timeout 實證及 U06 Human 9+7 校準仍 pending，單次 smoke 不當作校準通過。新增 OAuth=0，共享 R→T 1/1 已用盡；[操作與限制](apps/GitHubSignInVerification/tools/README.md)。

### U06 最新結果：方法未達資格，停止 live

來源 `f420901a1076537c4f7aa0404fe31509b8bdc889`。獨立 Tester 已核對 frozen fixture SHA／16 個唯一映射，正式 offline 校準為 decisive **6/9**、abstain **2/7**，未達 9/9＋7/7，`calibration_threshold_met=false`；U06 completed-not-qualified，方法 needs-rework，停 Human 決策。Human 明示不懂英文，屬方法語言前提未滿足，不是使用者過失。獨立 Reviewer 的結果處置 approved 僅准文件記錄與停止；57 項受控測試與原 U05 code approved 保留，不放行 live、不代表正式 OAuth bug 或 PKCE failed。先前 pending 是執行前歷史；smoke 是另一次受手動操作中止的事件，不算這 16 cases。新 OAuth=0、R→T1/1 已耗盡與正常 App/API/canvas／P/Q/R/T 歷史不變。不改 frozen fixture、不重跑16、不新實作；Human最新已同意本機繁中offline候選，但所需installed語言資產未齊、目前不可用；Human已同意自行下載，待完成回報才重查；既有inventory仍supported非installed，未翻譯／下載／新查，live仍未授權。[安全結果](plan/github-first-sign-in/evidence/pkce-semantic-review.md)。

### V：本機繁中先驗結果（研究工具，未交付中文能力）

V03新fixture已獨立approved／frozen；V04a只保留installed-only translator core與compile-time固定fixture runner作研究證據，正常binary無dump、CLI未改。V05a唯一真引擎序列16/16技術成功（2.646s、exit0、stderrfalse），58受控／compile／strict通過；獨立V06a語義fidelity failed／needs-rework，至少8處術語／角色失真，不編造精確語義通過數。另一次bounded code Reviewer approved、無required fix／不需額外驗證，僅研究工具code，不推翻fidelity失敗。中文GUI／CLI／Human校準未執行且停止，不宣稱繁中能力已交付。語言包installed、OAuth新增0；U06／PQRT／App/API/canvas歷史保留。Human最新允許規劃AI閱讀經安全檢查的描述，並接受資料可能離Mac／留於對話服務及gate殘餘風險；僅規劃，實際原文揭露／bridge／具體欄位與傳遞方式尚未批准，OAuth0，不擴V實作。 原scratch JSONL已無法再讀且無原bytes hash，語義來源限Tester當次輸出直接交Reviewer的實際synthetic譯文，不追補或重跑。[來源與限制](plan/github-first-sign-in/evidence/pkce-semantic-review.md)。

### W：單欄copy與AI閱讀的目前實作狀態

Human已明確批准單欄copy與手動AI閱讀例外及offline實作。W03新fixture已freeze，W04三檔工具完成；獨立W05 Tester親跑67tests／3.850s／exit0、hash一致、Swift6compile／strictformat／lint／diffcheck0、mockclipboard及CLI互斥AST檢查通過；獨立W06 codeReview approved、無required fix，僅offline。新AI16兩blindreader各9/9decisive＋7/7unknown、分歧0，Tester已核分，labels未改；只代表該synthetic set，不推廣未知provider描述或當PKCEproof。真nativeUI／clipboard仍未驗，無actual provider raw／live。W08publication／Humanreviewpending；OAuth新增0、正常v1及U/V/PQRT歷史保留，失敗中文route不接入。 已實作的opt-in旗標為 `--copy-description-for-ai`，不代表現在可執行任何 `--case`；無新授權／交換／實際provider原文。只在gate及cleanup後，Human明確點擊才copy完整error_description<=4096UTF8bytes，不自動傳送、不顯示或寫出原文。Clipboard／同步／history／其他程式及AI服務留存風險仍在，不能保證未知秘密或完全清除。

## X：唯一 wrong 收尾（2026-10-22）

來源`4dbf3df`，工具凍結未改。native正常明確copy／Human手貼核對passed；本次唯一wrong為HTTP400 invalid_grant／無token／遠端拒絕，兩獨立AI的單欄語義共識為`verifier_mismatch_asserted`（`provider_description_ai_review`）。fresh／single及prepared一致、valid_different／challenge不同只支持這一次拒絕且provider歸因verifier不符，不是普遍enforcement／wire證明。自動v3仍indeterminate／provenfalse、description unknown／match none，所有歷史保留；原文不保存。新預算1/1 used，本輪結束、不得再執行case／OAuth／研究。正常APIpassed、missing舊unknown及refresh/401pending不變；native正常路徑不推論timeout／cancel／OS清除，67既有測試未重跑。[安全來源與三層限制](plan/github-first-sign-in/evidence/pkce-semantic-review.md)。文件待最終獨立review／原PR61交付後Human review，無新增Human操作。

兩個驗證 App 分屬首次登入與持續連線 topic，證據與來源版本各自保留；下節的持續連線驗收不回填首次登入 topic 的歷史 pending，兩者都不代表正式 Rivet 產品登入 UI 已交付。

## GitHub 整條流程可行性驗證

[`GitHubConnectionVerification`](apps/GitHubConnectionVerification/README.md) 是獨立驗證工具，畫面明示驗證用途；交付的是「登入 → 保存 → 重啟還原 → 自動刷新 → 輪替後讀回 → API」的可行性結果與限制。初次授權、DPK adapter、UI、coordinator、probe、受控到期與收據全部位於該 App；正式 Sources、共用 RivetPresentation 與 root package 保持 topic 前契約。移除整個驗證 App 後 production 仍可建置與測試，沒有新增正式產品登入能力。

2026-10-21 新驗證 App 已通過真 GitHub 授權／DPK 保存、同版本新程序還原、同身分真正 Clean／Build 還原、受控 provider 到期觸發真刷新與保存、輪替後新程序讀回與同帳號 API；各段 Human 系統提示皆0次。適用有效 profile、同機同GUI使用者、相同AppID／private group／原certificate。profile更新後讀回仍未驗證、使用者已接受限制；受控觸發不代表自然到期已測。詳見[新版真人證據](plan/github-persistent-connection/evidence/verification-host-live.md)、[責任與流程圖](docs/architecture/diagrams/github-persistent-connection/verification-host-v2/BUILD.md)及[逐檔歸屬清單](plan/github-persistent-connection/evidence/verification-host-manifest.md)。舊2026-10-20 Rivet名義host結果保留為原版本歷史，不能冒充本 App 的驗收或正式產品交付。
