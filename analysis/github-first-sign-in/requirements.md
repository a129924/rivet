# 正式 OAuth 能力與獨立驗證 App：需求

- Topic：`github-first-sign-in`。
- 更新：2026-10-20，Plan-Creator；驗證 host 範圍 amendment，已獲獨立 Plan-Reviewer A02 approved（無required fix）；既有基線核准僅涵蓋原交付。
- Branch：`feat/github-first-sign-in`；base／Draft PR target：`dev`。
- 配對：[technical-spec](technical-spec.md)、[plan](../../plan/github-first-sign-in/github-first-sign-in.plan.md)、[step](../../plan/github-first-sign-in/github-first-sign-in.step.md)。

## W：單欄明確複製與 AI 閱讀例外（待獨立規劃審查）

基線 `469f2b07eb425728b2b08eb3b8c9f09623b2c675`，原feature／branch／DraftPR61。Human已明確批准單欄copy與AI閱讀例外、實作並先離線驗證：只允許gate後完整error_description<=4096 UTF8bytes，Human主動copy、手動貼AI；不整份response／自動傳送。Clipboard其他程式／UniversalClipboard／history及AI服務可能留存，gate不能保證未知秘密或完全清除；此殘餘風險已告知並接受。OAuth新增0，正式source／App及6foreign dirty不碰，U/V與全部歷史保留，不接失敗機譯。

Goal是可明確操作的單slot copy工具與獨立盲AI語義校準；copy不等於Human語義確認或PKCEproof。技術見technical-spec W，精確manifest／九欄見plan W。現在只四planning Modify、Written/Deleted0，W02獨立approved前不code／newfixture，不自產approval。任何新live仍未授權。

### W 最新外部狀態

外部獨立Plan-Reviewer已明示W02 approved、無required fix。W03新fixture由獨立Tester作者開始，W04 Implementer開始WC01–WC04範圍的工具／受控接點；盲校準須待核標freeze與真實交接，不預填Tester／Reviewer／reader結果。契約／manifest不變，OAuth0；本次只四planning狀態登錄，未碰code／fixture／答案。


### W04 實際凍結／W07盲校準結果（外部交接，優先於開始狀態）

Human已明確批准單欄copy與手動AI閱讀例外及offline實作。W03新fixture已freeze，W04三檔工具完成；獨立W05 Tester親跑67tests／3.850s／exit0、hash一致、Swift6compile／strictformat／lint／diffcheck0、mockclipboard及CLI互斥AST檢查通過；獨立W06 codeReview approved、無required fix，僅offline。新AI16兩blindreader各9/9decisive＋7/7unknown、分歧0，Tester已核分，labels未改；只代表該synthetic set，不推廣未知provider描述或當PKCEproof。真nativeUI／clipboard仍未驗，無actual provider raw／live。W08publication／Humanreviewpending；OAuth新增0、正常v1及U/V/PQRT歷史保留，失敗中文route不接入。 W02approved後的既定copy／AI例外已是實作授權，先前V「僅規劃」屬歷史。只有已批准單欄clipboard＋Human手動貼AI，不擴大為整response／自動AI或agent讀畫面。新旗標`--copy-description-for-ai`存在但不叫Human執行`--case`；本輪沒有actual provider raw／live。W05／W06外部結果已登錄；nativeUI未驗仍不能預填通過，publication與Humanreview待辦。

## V：本機繁中 synthetic 驗證與校準（現行規劃，待獨立審查）

沿原 feature／branch／DraftPR61，基線 `fbbc2fb0`。Human 已明確同意新增 Apple on-device 元件讀 gate 後 description，僅本機繁中 offline 方案及驗證；原文／譯文僅本機記憶體短暫處理，live 不向 agent／Reviewer／CUA 顯露或保存，不雲端／不自下載。新增 OAuth=0，正式 Swift／public contracts／v3 grammar／proof／outcome 不變。

Human 回報下載完成後，外部 Tester 以同一 inventory source 重查 en→zh-Hant／en→zh-TW，均 installed，compile/run exit0、stderrfalse；未 session／translate／UI／OAuth。這取代先前資產待下載的當時狀態，只證前置資產就緒，不是機譯忠實或方法通過。

Goal：先用全新 bilingual synthetic holdout 與真 on-device engine 驗證語義忠實，通過才接上可操作的繁中 offline 校準入口，讓 Human 只讀中文。中文畫面固定標示「本機機器翻譯／非遠端證明」，不以英文fallback、不責怪Human。技術／protocol／隱私集中 [technical-spec V 節](technical-spec.md)，manifest／九欄／先後見 [plan V 節](../../plan/github-first-sign-in/github-first-sign-in.plan.md)。

機譯 gate 是16/16語義忠實，非逐字相同或模板命中；Human 將來另明確操作新的9/9 decisive＋7/7 unknown校準，兩者分別記錄。任一引擎不可用／錯誤／失真即停，不接GUI、不請Human、不改ref／label配合；通過也不放行live、不當PKCEproof。

本輪僅四planning Modify，Written／Deleted0，V02獨立approved前不改toolcode／不建新fixture。U06舊英文16／6/9＋2/7未qualified、57controlled／原codeapproval、P/Q/R/T未知與R→T1/1耗盡、正常App/API/canvaspassed全部保留，不沿用或翻譯舊16來過門檻。六份他人Appdirty不碰；不新worktree／PR／merge。新live／OAuth一概未授權。

### V 最新外部狀態紀錄

外部獨立Plan-Reviewer已明示V02 approved、無required fix，可由V03起續行，無額外offline停點。V03獨立Tester造新fixture in-progress；V04a Implementer core／runner in-progress，可並行且不依賴labels，但真翻譯必等V03 Reviewer核標freeze。V04b GUI仍pending，必等V06a16/16 fidelity明示approved。OAuth0，技術／manifest不變；此為外部事實登錄，不是新增quality結論。


### V 本輪實際結果（優先於先前in-progress／pending）

V03新fixture已獨立approved／frozen；V04a只保留installed-only translator core與compile-time固定fixture runner作研究證據，正常binary無dump、CLI未改。V05a唯一真引擎序列16/16技術成功（2.646s、exit0、stderrfalse），58受控／compile／strict通過；獨立V06a語義fidelity failed／needs-rework，至少8處術語／角色失真，不編造精確語義通過數。另一次bounded code Reviewer approved、無required fix／不需額外驗證，僅研究工具code，不推翻fidelity失敗。中文GUI／CLI／Human校準未執行且停止，不宣稱繁中能力已交付。語言包installed、OAuth新增0；U06／PQRT／App/API/canvas歷史保留。Human最新允許規劃AI閱讀經安全檢查的描述，並接受資料可能離Mac／留於對話服務及gate殘餘風險；僅規劃，實際原文揭露／bridge／具體欄位與傳遞方式尚未批准，OAuth0，不擴V實作。 這是先驗機譯方法未達門檻，不是Human過失、正式OAuthbug或PKCEfailed；不以installed／16translated／受控tests當語義或Humanpassed。原scratch JSONL不可再讀且無原bytes hash，結果來源限Tester當次工具輸出直接轉交Reviewer的實際synthetic譯文，不能重建／追補。AI reader只獲規劃授權，不作實際揭露或傳遞契約已核准。

## U：Human-only 語義 review（規劃來源保留；現行實作事實見本節末）

來源 `9f603f81d77040a2e06ad178062e8cfecc4de468`，沿用原 feature worktree／branch／Draft PR61。Human 已接受本機原文可見性的殘餘風險，僅同意方案進入規劃；初步獨立方案複核的四項 fixes 滿足不等於本輪 formal planning 或 implementation approval。

**Goal**：規劃一條可由 Human 短暫閱讀完整 `error_description` 的本機語義 review 路徑，補足 v3 摘要丟失的順序、否定、條件、例子與因果。不繼續猜測句型。已觀察到 synthetic 肯定／否定因果兩句可產生相同安全摘要；這不是歷史原文重建。`invalid_grant` 多義，GitHub 官方 troubleshooting 未提供穩定 verifier-exclusive 句法契約，不能以它或 hints 證明 PKCE 原因。

**本輪 In-Scope**：只修改同 topic 四份 planning artifacts，規劃 privacy gate、私有 helper protocol、獨立 synthetic holdout 與證據界線；獨立 Plan-Reviewer 已明示 U02 formal verdict approved、無 required fix；整體仍停 Human／human-check。**本輪 Out-Of-Scope**：任何 helper／CLI／tests 實作、fixture 建立、離線 Human 校準、工具執行、Git、發布或新 OAuth。Written／Deleted 均無，新增授權預算 **0**。

未來候選方法與限制見 [technical-spec 的 U 節](technical-spec.md)。只有 Human 可看通過 gate 的完整、未截斷、至多 4096 UTF-8 bytes 描述；agent／Reviewer／CUA 不看 live 原文。新 `provider_semantic_observation` 只是 local_human 對 provider statement 的 attestation，不變更既有 `pkce_rejection_proven`／outcome，不回改歷史。無原文保存亦代表 agent 無法獨立稽核原句。

P／Q 各 2/2 與 indeterminate、R 調查及 T 實際結果保留；共享 R→T **1/1 已用盡**。正常 App／再次 API／canvas passed 不重做。若日後另獲 live 授權，wrong 為推薦候選：既有合法不同 verifier 與 prepared 一致性提供基礎，新增資訊限完整 causal text 語義；不保證一次判定，case／次數需 Human 另行授權，不能挪用已耗盡額度。

### U 最新授權更正：啟動 bounded offline implementation

本段是現行授權／狀態，優先於 U 先前「須再批准 offline 實作／NOT AUTHORIZED」停點，原文字保留作歷史。依既有同 topic 必要回修／實作授權、Human 在「接下來完成工具修改與離線測試」脈絡的續行要求及 U02 formal approved，移除主 agent 額外增加的 offline 再批准停點；不是新增 OAuth／原文可見性授權。

既定 9 Modify／3 Written、技術與判準不變，現只啟動離線工具實作、獨立 Tester／Reviewer 及 synthetic Human calibration 準備；流程 U03→U04→U05→U06 Human 停點見 plan。本輪先交付可測工具，不自動進行 Human 校準或 live。新增 OAuth 仍 0，P/Q/R/T 歷史及 App／canvas passed 原樣保留；任何 live 必須另次明確授權。其後 topic 發布沿原授權，並不代表現在執行 Git／發布。

### U 最新執行狀態紀錄

獨立 Plan-Reviewer 的 offline confirmation approved／無 required fix 保留；既定離線實作已獲授權，較早「只規劃／NOT AUTHORIZED」為來源歷史，不限制現行 bounded offline 工作。U03 工具已實作並凍結，命令為 `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review`，無網路／ID-secret 輸入；U03 completed；P2 selectors/stderr 回修後，獨立 U04 Tester 親跑 57 項受控測試通過、strict format／SwiftLint exit 0，U04 completed。獨立 Reviewer 最終 U05 approved、P2 closed／無其他 required fix，限工具交付與 Human 正式 offline 校準；U06 Human 9+7 與完整 UI／clipboard／restoration／timeout 實證仍 pending，smoke 不當作自然 timeout／holdout 通過。

安全替代現為 SystemRandom 打散 synthetic cases、UI不見labels/id；工具不讀／比較 expected_category、不自評，只於末尾回傳 opaque correlation_id＋有限 observations，供獨立 Tester 評分，9+7 標準不變。原自評寫入曾被 auto-review 拒絕、未執行且未重試；採已允許的外部獨立評分方案。原文仍只可在 gate 後由 Human 短暫看，agent／Reviewer 不看、不保存；獨立觀測軸不改 proof／outcome。OAuth=0、U06 Human 停點與 P/Q/R/T／App/canvas 歷史不變，本記錄只登錄已明示的外部驗證／review事實，不宣稱 Human 校準或遠端通過；既有 topic 發布授權有效，工具交付後停 U06，不另造發布批准停點。

### U06 最新結果與方法資格

來源 `f420901a1076537c4f7aa0404fe31509b8bdc889`；外部獨立 Tester 已核凍結 SHA 與16唯一映射：decisive6/9、abstain2/7，未達既定9/9＋7/7，calibration_threshold_met=false。U06 completed-not-qualified／method needs-rework，下一步 Human 方法決策，禁止 live。Human 明示不懂英文，方法語言前提未滿足，不是使用者過失；原57controlled pass／U05codeapproved仍成立，不推導正式OAuthbug或PKCEfailed。獨立Reviewer結果處置approved僅文件記錄與停止，舊pending／smoke保留歷史，smoke不算16case。正常App/API/canvaspassed、P/Q/R/T及R→T1/1耗盡保留；新OAuth0，不改fixture、不重跑16／新UI／code。新語言方案只是未授權候選，另待Human，不能以機譯作proof。

### 最新 Human 決策與 V 前置停點（僅文件）

Human 已同意「本機繁中方案與離線驗證」，允許未來 Apple on-device 元件讀取 gate 後 description；原文／譯文只在本機記憶體短暫視窗，agent 不看、不保存，不用雲端、不自下載，live 仍未授權／OAuth0。此同意不改 U06 的6/9＋2/7與未達資格歷史。

外部唯讀 inventory 顯示 en→zh-Hant／en→zh-TW 為 supported 而非 installed，所需語言資產尚未齊全，繁中候選目前不可用；不表示每個語言都沒安裝。Human已同意自行下載，尚未回報完成，等待完成回報才重查；既有inventory仍supported非installed，本輪未翻譯／下載／新查，無中文工具／新holdout或方法成立證據，不建立V implementation plan。詳細前置 facts 見 technical-spec 同節。

## Goal

單一使用者從獨立 GitHubSignInVerification App 輸入個人自有 GitHub.com OAuth App 配置，經系統預設瀏覽器完成授權；取得符合既有模型的完整 credential bundle 後，當次程序使用既有 provider／scope 執行 `GET /user`，呈現實際 `login` 與 `id`，並能再次查詢。

成功不是只收到 callback、取得 token 或本地 prepare 完成。取消、拒絕、逾時及失敗均提供明確結果與重新開始的路徑；過期事件不得完成其他登入嘗試。

## In-Scope

- macOS 15／Swift 6 獨立驗證 App、配置及驗證 UI、真實 API 結果與再次查詢；正式 OAuth 實作仍在 GitHubIntegration。
- 個人 OAuth App 的 client ID／secret 程序內配置、loopback callback、state、S256、初次 token exchange。
- 完整六欄 bundle 程序內 store、caller-owned provider、既有 ready scope 與同程序多次唯讀 API 操作。
- 取消／授權拒絕／五分鐘逾時／重複及遲到 callback／交換與 API 失敗處理。
- TC01–TC09 的受控測試、明確分列的 Human 真實驗收、脫敏證據與長期文件／圖。
- 每次 `swift-implementation` bounded step 及完成交接均列九欄；此名稱為階段稱呼，不聲稱有同名 skill。

## Out-Of-Scope／Non-Goal

正式 Rivet 產品登入 UI 尚未交付；不新增正式帳號管理、CurrentUserReader、共用 module 或 public API。不新增 BC；不實作 Keychain／SQLite／DPK adapter、跨重啟恢復、資料遷移、多帳號／切換、PAT、Enterprise、device flow、broker、完整登出／remote revoke、PR Inbox／Reader 資料、一般 retry／pagination／rate-limit framework、公開發行或 notarization。

不重做 refresh、rotation、single-flight、snapshot、401 recovery；不新增 provider disposition API。不宣稱 `/user` 成功證明 repository permission、所有 refresh／401 路徑已取得遠端實證，或釋放本地狀態即撤銷遠端 token。

## 已鎖定決策

1. GitHubIntegration 是 non-BC，驗證入口與組合屬獨立 App；不改既有 BC 邊界。
2. 個人自有 OAuth App，在驗證 App 內輸入 client ID／secret；secret 與完整 credential 僅程序內，不落盤、不進 logs／證據。不能使用 gh credential 代替產品 OAuth，不自行尋找或讀取 secret。
3. 獨立 GitHubSignInVerification App 使用 macOS 15／Swift 6、ad hoc／Sign to Run Locally、首版 non-Sandbox；不要求 Apple Development／profile／DPK。這不是長期發行安全決策。
4. callback 固定 IPv4 loopback、動態 port、`/oauth/callback`；採 S256，單一 active session、五分鐘期限；不改走 ASWebAuthenticationSession、自訂 scheme 或 HTTPS 替代路徑。
5. 只請求 `offline_access`；`/user` 只讀公開身分 login／id，不索取 read:user 或 repo scopes。回應 scope 字串可為空，不以包含 offline_access 字串作為 bundle 驗證要求。
6. 既有 bundle、OAuthCredentialStore、OAuthTokenFetcher、OAuthTokenProvider、GitHubClientScope 與雙 client 契約不變；完整程序內 store 不等於現有單 token store。
7. 兩 Mission 已由 Human 分開：本 topic 獨占正式首次 OAuth 能力及驗證 host 至當次 API；`github-persistent-connection` 負責保存／重啟／儲存採用及未來合流。詳細 ownership amendment 與來源 SHA 見 technical-spec §6，須獨立審查，不能自填通過。
8. 使用者已授權專用 feature worktree 實作，以及無重大問題時 `commit → push → Draft PR → Human review`。受控 tests 與獨立 review 仍為交付前置；需個人 secret／互動的真實 OAuth 與反向 PKCE 留 Human review pending，不阻擋已授權 Draft PR。不能 merge。

9. Human 已確認 PR #61 的驗證畫面不應作正式 Rivet 主畫面：將 apps/Rivet 全數搬至 apps/GitHubSignInVerification，並將驗證專用 UI／測試從 RivetPresentation 搬入 App。保留 GitHubAccountProbe 名稱與驗證責任；刪除驗證 App 不需要修改正式 OAuth。沿用原 branch／feature worktree／Draft PR，不另建、不 merge。

## Acceptance Criteria

| ID | 結果 | 證據層級 |
|---|---|---|
| AC01 | 獨立驗證 App 可發起授權，只有相符且單次有效 callback 進入交換 | 受控＋Human live |
| AC02 | 完整有效六欄 response 才交付 bundle，交換失敗不交付連線 | 受控＋Human live |
| AC03 | 同程序由同 provider／scope 多次 GET /user，結果含實際 login／id | 受控＋Human live |
| AC04 | 取消、拒絕、逾時與失敗後可重新開始；舊事件不污染新嘗試 | 受控＋適用的 Human 操作 |
| AC05 | 本地 prepare、HTTP／decode 失敗均不冒充遠端成功；失敗可再操作 | 受控 |
| AC06 | 不保存 secret、tokens、bundle、code、verifier、完整 callback 或原始交換 body 至磁碟／logs／證據 | source／transport 設定／受控檢查 |
| AC07 | 完整結束再啟動回到未連線；交付不依賴持久化 adapter 或 E007 | 受控／本機啟動 |
| AC08 | 正向 S256 與獨立新 code 的缺失／錯誤 verifier 反向結果分列，不重用 code 製造假陰性 | Human review pending，不能預填 |

基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22` 的正常授權及再次查詢見既有 product-e2e.md，可作未變動 OAuth 的來源證據；不能冒充新驗證 App 已重驗。新 host 的 AC01–AC03 live 部分及 AC08 未驗證時，Draft PR 明示 pending；不能把它寫成 topic 已完成或宣稱真 GitHub 通過。

## 依據與未知界線

[既有 OAuth 架構](../../docs/architecture/github-oauth-dual-client.md) 與 [scope step](../../plan/github-client-scope-composition/github-client-scope-composition.step.md) 是既有契約依據。E001 證明獨立 loopback callback，E002 正向證明六欄與 /user，反向 PKCE 仍未定；E003 是受限 refresh／rotation 實證，均不取代新驗證 App 驗收。

GitHub 官方：[OAuth authorization／offline_access／S256／loopback／secret](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)、[/user 與 private response scopes](https://docs.github.com/en/rest/users/users#get-the-authenticated-user)。本 topic 沒有待補造的重大產品決策；2026-10-21，Human 已自行提供配置並完成新驗證 App 正向授權；agent 觀察真實 API 與再次查詢通過，來源 `e941d88`。反向 PKCE、canvas 及完整 Human review 仍 pending；最新脫敏紀錄見 amendment evidence。

## Amendment 驗收

- 新 project／scheme／entry／product／test target 與畫面均明示 GitHubSignInVerification／驗證用途；hosted tests 不觸發真實 OAuth。
- 共用 RivetPresentation 不再公開或包含 GitHubConnectionView／GitHubConnectionPresentation；PR Inbox Presentation 原樣保留。
- root／consumer／app build-test、適用 format／lint 通過；正式 OAuth 與既有 lifecycle source 不因搬移改變。
- 文件、精確 rename/delete manifest、修訂圖及原 Draft PR 如實反映「正式 OAuth 能力＋獨立驗證 App」，不宣稱正式產品登入 UI 已交付。

## P 輪現行追加範圍（2026-10-21，優先於較舊 pending 敘述）

本輪來源 `d11f343`；沿用 feat/github-first-sign-in、原 feature worktree 與 Draft PR #61，不建新 worktree／PR、不 merge。既有正式 OAuth、獨立驗證 App 及 `e941d88` 正常授權／再次 API 已完成，不重做。正式 Rivet 產品登入 UI 仍未交付。

Human 已針對現行 `index-v2.html`／來源 `d11f343` 明示：內容／流程／責任可接受、拖曳正常、縮放可讀、聚焦說明正常、明暗皆可讀。這是 Human canvas 驗收，不是 agent 已取得 file-URL 瀏覽權限；既有 browser policy 不繞過。前文 canvas pending 屬歷史狀態。

本輪 Goal：先保存上述 canvas Human 結果，再以獨立、Python standard-library CLI 準備及執行 missing／wrong verifier 反向 PKCE；每 case 獨立新程序／新授權／新 code／單次交換，結果分別為 passed、failed 或 indeterminate。最多兩次新授權，不自動重試；遠端 refresh／401 本輪明確不做。

新增工具置於驗證 App 旁 tools，不新增 shared module、experiment topic、正式 bypass 或 Swift App 功能。正式 session 不提供 negative 開關。機密只由 Human 在本機終端以 getpass 輸入，agent 不讀取既有配置、secret 或先前 callback/code/state。

反向通過必須是沒有 token 的純 OAuth error、HTTP 2xx／400，且明確 verifier-specific 分類。generic bad_verification_code 只代表 GitHub 拒絕，PKCE 原因無法判定；expired／network／config／未知錯誤不算通過。任何 access／refresh token 回傳均為該 negative case failed，立即丟棄、不使用、不呼叫 API。

驗收 PK01–PK06 及精確 manifest 見 plan P 輪 amendment。Human 每次只處理一步；新 missing／wrong 遠端結果仍 pending，不用正常登入或舊 E002 代填。既有全部 Human review、跨重啟與遠端 refresh／401 未驗證項目仍如實保留。

### P06 最新執行狀態（2026-10-21）

以上遠端pending為P01規劃時狀態；現已由Human依固定helper與判準完成missing/wrong各一次新授權/單次交換，兩個安全報告均HTTP400、unknown_error/unknown、無token，結論皆indeterminate，不宣稱PKCE enforcement通過。工具最終SHA659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699（d11f343基線後dirty source），兩case間未修改。總預算2/2已用盡，停止授權與重試，無rawbody可追補；後續診斷需另訂有限契約與新預算。Canvas Human驗收passed，遠端refresh/401本輪不做、保持pending，全部PR Humanreview尚未完成。詳見pkce-negative-verification evidence與step；範圍/manifest/既定判準不變。

## Q 輪現行診斷 amendment（2026-10-21；優先於舊 P 判準）

本輪基線 `82489b68ff21e955611bde1e9028fff21dc68e74`，沿用原 feature worktree／feat/github-first-sign-in／Draft PR61；不在dev實作、不新worktree/PR、不merge。只改善獨立negative CLI的有限脫敏診斷，再missing／wrong各一次freshcode、單POST；本輪新額度總2次，逐步等待Human，不自動重試。P輪2/2已用完，兩者unknown／indeterminate原樣保留；不追補原body、不重用、不改判。

Goal是區分已知OAuth拒絕與精確verifier證據，不把一般invalid_grant或bad_verification_code當PKCE證明；新增diagnostic_version=2讓Human辨識新工具。正式OAuth不是已確認bug，不能宣稱enforcement已驗證；case與原因不相符、unknown、衝突及未明確verifier訊息仍indeterminate。機密/raw description僅記憶體，不輸出或保存。

本輪不改transport、loopback、TTY/getpass防fallback、PKCE生成／單次策略，不改Swift App／正式GitHubIntegration／rootPackage／實驗／圖。Canvas Human passed及e941d88正常授權／再次API來源沿用，不重做positive/API/remote refresh/401。精確manifest與九欄見plan Q，分類鎖定technical-spec §9。規劃時新Human兩case結果pending；只有獨立planningreview→implementation→Tester/codeReviewer後才能執行。此為執行前契約，現行實際結果見下方Q06摘要（兩case均indeterminate、Q2/2用盡）。

### Q06 實際執行摘要（判準不變）

2026-10-21，Q05獨立approved/R1closed後，Human以凍結version2 CLI另取missing/wrong各一個新code、各單次exchange。兩案皆HTTP400 invalid_grant/code_problem/generic_code_rejection、remote_rejected=true、token_present=false；description存在並提及verifier，但description_class=unknown，signals_conflict=false、pkce_rejection_proven=false。按事前§9兩者皆indeterminate；不得以hint、HTTP400或一般invalid_grant當PKCE證明。missing/wrong各1/1、Q總2/2用盡，停止新授權/重試/擴模板；P舊2/2 unknown歷史保留。來源82489b6+Q受限diff、CLI SHA `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`。原始描述未保存，無法可靠專指拒絕原因；完整安全JSON/來源與限制見新pkce-diagnostics-v2.md。正式OAuth/credential/provider/scope/refresh/401未改，正常login/API/canvas不重做，完整遠端refresh/401及完整PR Human review仍pending。

## R 輪現行調查收斂（優先於Q/P/A/S執行指示）

來源HEAD `21e2542`；沿用原feature worktree、feat/github-first-sign-in與Draft PR61，不在dev實作、不建新worktree/PR、不merge。本輪docs-only：記錄唯讀調查所得及停止決定，不修改CLI／診斷判準、不執行新OAuth。

Human新授權上限1次且明示沒有可靠資訊增益就停止。現有調查沒有找到足以讓唯一一次新授權可靠增加遠端歸因資訊的方案，故R預算為 **0/1未使用**，本輪不選case、不消耗。這不是已跑、通過或新增授權額度；將來有可靠方案須另確認流程，不因本文件自動執行。

P2/2 unknown與Q2/2 invalid_grant/code_problem、description unknown／mentions_verifier=true均仍indeterminate；舊證據不追body、不重用、不改判。e941d88正式驗證App正常授權／真/user／再次查詢及canvas Human passed原樣沿用，不重做。正式OAuth未發現實際組裝bug證據；不能因此聲稱已排除所有bug或已驗證PKCE enforcement。正式Rivet產品登入UI、遠端refresh/401及跨重啟仍未交付或未驗證。

本輪Goal是清楚分開fact／inference／no evidence，交付有來源的停止結論；不再增加猜測模板或keyword，不讀App配置或原始描述，不新增experiment/module/public API。精確manifest與R01–R06九欄／最小驗證見plan R。

## T 輪現行最小診斷改善（優先於R停止及舊Q/P執行契約）

來源HEAD `90646c2`，沿用原feature/feat/github-first-sign-in/原DraftPR61，不dev實作、不建worktree/PR、不merge。Human已明確要求繼續實作最小改善，不能因無法保證PKCE遠端結論再次只交停止文件。

交付diagnostic_version=3：（A）被動觀測實際交給browser opener的授權URL及send_token實際建立的prepared Request，僅輸出本機一致性布林/有限enum；（B）保留19完整模板並加事前固定fullmatch句法，另有不參與proof的有限詞彙hints。prepared request不是遠端wire、code發行時間或grant狀態證明；即使改善後結果仍可能unknown/indeterminate。

沿用R唯一尚未使用的1次額度，**共享R→T預算目前0/1**，不是T新增1次；核准、實作、獨立Tester/Reviewer及requiredfixclosed後，僅wrong一個freshcode/單POST，無第二次/positive/API/refresh401，不讀App配置。wrong送合法43字元但challenge不同的verifier，可減少缺欄位/shape歧義；此為選案理由，不是預告通過。

正式Swift/API/lifecycle、交換算法/endpoint/timeout/retry/TTY防fallback/loopback安全不變。P/Q既有indeterminate與R調查歷史全保留；e941d88正常login/user/requery、canvasHumanpassed不重做。新機密由Human本機隱藏輸入，一次一步ask-question，只收safe version3 JSON；live前freeze SHA，live後不擴表或回推舊rawdescription。

### T06 實際結果（既定判準不變）

2026-10-21，T05 approved且版本SHA凍結後，Human完成共享R→T唯一wrong新授權/新code/單POST，現在1/1已用盡，停止任何重試/第二次。安全version3報告：actualprepared local_consistency=consistent、valid_different、client/redirect/code/shape一致、callback返回至準備Request under_5s；HTTP400 invalid_grant、無token，verifier/challenge/mismatch hints true但description_class=unknown/match_source=none，按§11仍indeterminate/proven=false。local gate是新增本機證據，不能替代完整語義；hints不證明原因、false hints不排除其它grant問題，under_5s不是code_age。CLI/test SHA未改，來源90646c2+T受限dirtydiff，詳v3 evidence。PQR舊結果/預算/正常App/canvaspassed保留，不追原文或擴表；遠端refresh401及完整Humanreview pending。
