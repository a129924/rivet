# 獨立 Planning Review

- Topic：`github-oauth-credential-persistence`
- Role：Plan-Reviewer
- 日期：2026-10-20
- Verdict：`approved`
- Required fixes：無。

## 受審範圍

唯讀核對本 topic 的 requirements、technical-spec、plan、step 四份正式 artifacts，並依 README、設計原則與 Plan-Reviewer skill 檢查範圍、公開契約、九欄 manifest、測試可執行性及角色界線。本次不審查、修改或採用他人的 persistent-connection／E007 產出。

## 審查結果

- 使用者的獨立 topic scope override 已記錄；本 topic 的程式、fake tests 與 Draft PR 不依賴他人的 renewal／live gate，亦不宣稱真 DPK、跨程序、簽章或提示 UX 已驗證。
- Additive configuration／兩 item stores、clientID-bound adapter、strict codec 與有限錯誤可在所列 source／tests leaves 交付；既有 ports、provider、clients、package 與他人 artifacts 保持唯讀。
- Bound save 的 read-check-write 及 update-add-update 均由同一 actor 的同步 operation 保護。T04 的 shared actor 驗證依 technical-spec §2 限定同一 stores facade 內的 configuration store、inspect 與各 bound stores；不同 stores facade／程序不承諾協調。
- T01–T06 可透過 internal fake Security seam、既有 provider 與可注入時鐘執行；不需新增 live Security 操作、provider policy 或 public transport injection。
- 九欄與精確 manifest 涵蓋程式、consumer test、長期文件、單張 storage sequence 及角色 evidence；審查者只寫自身 evidence／S02 結果，不代寫受審設計或實作。
- Archify 為必要文件交付；PR Lens／Graphify 的 bounded 使用、外部 scratch 與具體 fallback 不新增 gate。Human 圖面觀察未取得時保持 pending，不能冒稱接受。
- Branch、base／PR target、獨立 Tester／Reviewer 與已授權 commit／push／Draft PR 邊界一致；不包含 merge。

## 限制

本 verdict 僅核准四份 artifacts 所界定的受限執行契約，不代表實作、測試、圖交付、真系統保存或產品流程已通過。本 reviewer 未執行測試、Git、Security、簽章、產圖或發佈。


## Bounded amendment review：靜態隔離 allowlist（2026-10-20）

- Role：Plan-Reviewer
- Verdict：`approved`
- Required fixes：無。
- 僅回查 plan 的 M01／ReadOnly amendment 與既有 StaticIsolationTests 的對應檢查位置，不重審整個 topic、不改受審測試。
- M01 新增的唯一既有 test leaf 為 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；只准 expectedPaths 加入 `Contracts/GitHubOAuthAppConfiguration.swift`、`Stores/GitHubOAuthDataProtectionStores.swift`，並只為後者增加 Security import 例外。保留既有 legacy Keychain 例外及其他 import／source-path／package／provider 邊界檢查。
- ReadOnly 對 M01 的兩個精確 test leaves 已明列例外，沒有讀寫範圍重疊；本修訂容納已核准 adapter 必要的 allowlist 機械更新，不新增產品能力、測試豁免或 gate。
- 本 reviewer 未執行測試；呼叫端回報的測試結果不作為本次獨立測試證據。既有 review 段落保留，本次只追加本 bounded 判讀。


## Bounded live validation amendment review（2026-10-21）

- Role：Plan-Reviewer。
- Verdict：`approved`。
- Required fixes：[]。
- 範圍：僅核對本 topic 四份 artifacts 的新增 live scope、精確 manifest、LT01–LT07 與 L01–L06；不重新審查原 adapter code／fake tests，不讀寫他人 E007／完整登入工作線。

### 獨立判讀

- 今日 Human 授權與原 fake-only 交付分列；新增最小 validation App、runner、純控制與真實假憑證驗證，不擴張登入、production API、Package.swift、configuration item 或他人資產範圍。原 PR／S08 Human review 不因本次 amendment 自動接受。
- L-W01 九個精確 validation leaves 與 L-W02 準備／逐段 evidence、run-summary 已列明；四 artifacts 按角色維護，既有 source／tests／docs 保持唯讀。本 review 的寫入僅限既有 planning-review.md 追加與自身 L01 記錄。
- Host 連結真實 GitHubIntegration product，不複製 codec；prepare／pure controls／unsigned build 與選定既有 identity／profile 後的簽章／LaunchServices／SecItem 明確分開。準備仍需獨立 Tester／Reviewer，不能以本次 planning approval 代替準備品質或 live 結果。
- 八個階段均需開始前 fresh ready、事後實際 count／有限 actions／whole-stage observation 與 exact machine SHA；未答／不完整保持 unknown 並停止依賴段，setup／rebuild 與 runtime 提示分列，不由 exit 0／讀取成功推零提示。save-a ≤1、fresh／rebuilt reads =0；其餘階段只記當次實際數，不新增門檻。
- Fresh process、先前 process 終止、production source pin、真 Rebuilt scheme／compiled marker／不同 binary、有效相同 App ID／group／certificate／profile／DR／固定安裝位置均有明確 guards。hash 不同、ad-hoc 或單一 exit 0 不能冒充真正重建成功。
- 隔離 UUID service 只操作 credential account。首次寫入先確認 absence，再持久化 write-attempt marker；cleanup 只在 immutable manifest、精確 namespace 與兩項 ownership proof 相符後刪單一 item，並由 production adapter load=nil 回驗。失敗／crash 保留 marker 與恢復入口，cleanup 另取 ready，不以新 run 掩蓋舊殘留，不刪正式憑證或 Apple assets。
- 0700 私有 root 保留 raw paths／identity／child logs；公開 receipts 為有限 schema projection、exclusive-create，僅保留必要 hashes／布林／有限觀察，unknown 不覆寫成成功。LT01–LT04 已包含 ownership、錯誤／crash、拒絕 delete、投影與不完整觀察的負向驗證。
- 新 certificate、trust／安全設定、付費、identity/source mismatch 或 ownership 不明均有必要停止與最小 cleanup 交接；沒有新增 E007、renewal、expiry continuity 或固定時間窗的依賴。

### 限制

本 verdict 僅核准新增受限 planning contract，供 L02 準備工作使用，不代表 L02 實作、L03／L04 準備驗證審查、逐段 fresh ready、簽章／profile 前提、live DPK／UX／cleanup 或 S08 Human 接受已通過。Reviewer 未實作 validation host、執行測試、inventory assets、簽章、啟動 App 或呼叫 SecItem。


## Automatic cached 唯一 setup retry 候選規劃審查（2026-10-21）

- Role：獨立 Plan-Reviewer。
- Verdict：**needs-rework**。
- Required fixes：[RF-RETRY-PLAN-01]。
- 只審 requirements 最新末節、technical-spec／plan §5.1、step L01-Retry1；不審不存在的候選實作，不執行準備／signing／live。前 review 歷史保留，追加前 evidence SHA-256：`86299b2152460dcc71d7d57e60da18144e2d183d8806a15795001247cdd9e056`。

### RF-RETRY-PLAN-01：directory-only crash state 的 resolver／summary 與 quota 契約不一致

Technical-spec §5.1「唯一 retry」明定 private/setup-retry-1 directory 或 attempt.json 任一存在即佔用唯一額度，失敗／crash 不刪除重用；但「Dependency、rebuild、export」又以「retry attempt 不存在時讀原 setup」定義 resolver。Exclusive mkdir 後、attempt.json 建立前 crash 時，directory 已佔額度卻會落回 initial，與同節及 requirements／plan 所要求的「retry 出現後不 fallback」衝突，也未明定 summary 的 retry-1 是 notExecuted 還是 unknown。

Required fix（只交 Plan-Creator）：統一 activation／quota／effective resolver／summary 的 presence 定義為 directory-or-attempt。Directory-only／缺 attempt 的已配置狀態視為 retry unknown、effectiveSetupAttempt=null，禁止 fallback initial、save-a 解鎖或任何第三次嘗試；保留 initial outcome原值及目錄／其他恢復 proof。補進 RT02／RT04 的準備 fixtures：mkdir 後、attempt 前 crash，依賴仍 blocked、retry outcome unknown、原 bytes 不變且唯一額度不得再用。其餘 schema／paths／guards維持，不必擴新狀態機或 framework。

### 其餘 bounded 檢查

- 同 run／唯一候選、既有三個工具檔範圍、兩個精確 v1 public leaves及未建立 summary 的 v2 固定 attempts／effective欄位，均與原歷史分開；不允許覆寫原 failure／Human bytes、identity／PBX／manifest或 production／Swift／templates。
- 全域六 overrides 移除、保留 frozen target Automatic、禁止 portal/device/auth-key權限 flags及 missing cache即停、install前exact採用 certificate/profile/AppID/group/bootstrap DR/source/location guards均明確。沒有把不授 portal updates誤寫成所有本機 cache／assets絕對零變更。
- 原 unknown/build、Human完整0提示與machine SHA保留；新 Automatic政策採用與新的唯一 retry ready均未取得。候選準備／獨立 Tester／Reviewer 與 Human execution boundary分離，不以 planning approval消耗ready或嘗試 build/sign/live。
- 接受 runner freeze 的權威是外部獨立 Tester／Reviewer 的已接受版本；執行者必須從其凍結 SHA 交接取值並與 actual runner SHA比對，harness不能自行宣稱 review approved或接受任意 caller hash。這是既有角色交接約束，不要求本輪新增自我雜湊或數位簽章驗證框架。

僅 RF-RETRY-PLAN-01 需回作者小修；本 reviewer不代寫 planning內容、不放寬 guards、不讀 private live root或他人工作線。修正版須再 bounded回查，不前進 L02-Retry1／任何 execution；S08維持 pending。


## RF-RETRY-PLAN-01 bounded 回查（2026-10-21）

- Role：獨立 Plan-Reviewer。
- Verdict：**approved（僅候選準備契約）**。
- Required fixes：[]。
- RF-RETRY-PLAN-01：已解除。原 needs-rework及作者回修歷史保留；追加前 evidence SHA-256：`6be4189ea5c9d30050774e6599314ea0ee6510c0a9e553b725229682d54fcbf7`。

僅回查該 required fix：requirements 末節、technical-spec §5.1 的 activation／quota／effective resolver／summary、plan RT02／RT04 與 step 交接已一致使用 directory-or-attempt presence。只有兩者皆不存在才讀 initial；directory-only／partial／缺 attempt或receipt均為 retry unknown、phases.setup unknown、effectiveSetupAttempt=null，既佔唯一額度又禁止fallback／save-a解鎖／第三次嘗試，保留原 initial outcome／bytes及恢復proof。RT02／RT04已明列 mkdir後attempt前crash及partial入口fixture，涵蓋quota不可重用、依賴blocked及原bytes不變。

本回查沒有新增 schema／paths／runner freeze機制或重審其他設計；未修改作者內容或執行code／test／build／signing／live。此 approval 僅允許依既有L02-Retry1→Tester→Reviewer做候選準備至可審查，不代表 Automatic cached execution政策已由Human採用、cached build可行或唯一retry已執行。實際執行仍須Human明確政策採用及全新當段ready；舊ready不得重用，原unknown／Human觀察及S08 pending不改。


## D01：最小可診斷工具補修 §5.2 獨立規劃審查（2026-10-21）

- Role：獨立 Plan-Reviewer。
- Verdict：**approved（僅診斷工具候選準備契約）**。
- Required fixes：[]。
- 受審：requirements 新增 Human 採用末節、technical-spec／plan §5.2、step D系列；不審不存在的新實作。原 review／結果歷史保留，追加前 evidence SHA-256：`948c4aaf1f710a174bfdd337d94f31a394800032886ecb8885e6e30630fc6b9a`。

### Bounded 判讀

- Human只採用原四個validation leaves的最小工具補修及non-live驗證。原run、manifest、identity、PBX、source pins、current binary、setup／retry／save-a unknown及Human bytes全部唯讀；沒有新credential run、第三次setup、重試save-a、產品API／provider、OAuth或E007範圍。
- 新用途嚴限diagnostic-only／namespace-read-only，獨立owned0700 diagnostic scratch、固定manifest／App與purpose輸出leaves，準備期不得建立真人scratch／manifest／ready。New source／binary／identity freeze與原Writer分開，不能把不同copy／context的通過或不重現描述成舊guard已解除。
- Trusted-operator交接的環境bootstrap與診斷argv／原request解析分開；先驗完整schema／SHA／UUID／owned paths／symlink／legacy hashes等，只有bootstrap可信後才取得固定exclusive0600／fsync目的地並捕捉早期args／request／identity／Bundle／entitlement失敗。Bootstrap失敗或App未啟動時不寫任何不可信路徑，runner只保留unknown，不製造替代App成功收據。
- 獨立receipt與有限stage／status／failureKind／hashes／guard booleans、Human sidecar及新purpose ready已列明；不序列化error／argv／payload／paths／IDs。固定purpose輸出、拒絕preexisting receipt／逸出及實際Swift負向驗證涵蓋必要output escape防護。沒有新增repository leaves或改寫舊summary，公開僅由Tester追加既有live-validation.md的有限摘要。
- diagnostic-only到completed即終止，零store與四個SecItem入口；成功也不進原perform/save。未來namespace-read-only另取Human ready，只從固定legacy資料導出exact selector，公用adapter最多一次load、零config／save／delete；absent僅代表現在nil，present／denied／error停，不能回填absence／write-attempt、抹除unknownchild或放行舊cleanup。無strict ownership／安全恢復方案時保留原root與Apple assets、交Human。
- DT01–DT04要求執行修改後同一Swift共用bootstrap／early guard／receipt控制路徑，而非只mock Python／沿用舊binary；以普通compile scratch用swiftc隔離unsigned編譯新main，核source/binary hash及case IDs、保留舊12checks與Python55regression。禁止xcodebuild／signed/live build或package更新；既有依賴不足就如實報blocker，不能拿舊binary冒充新case。
- D02準備→獨立D03 Tester→D04 Reviewer與未來D05新host build/sign scope採用／freshready、D06 diagnostic launch freshready／actual觀察、D07 namespace唯讀另段freshready／actual觀察清楚分開。Human方向確認不代三個執行段落的採用與ready，也不代S08接受或任何真DPK／prompt成功。

### 結果限制

本 approval 僅允許依所列四個validation leaves及既有role evidence準備至可審查；不代表新code／tests已實作或通過，不放行xcodebuild、簽章、App launch、DPK或新真人inputs。沒有要求增加通用recovery／新框架或放寬原guards。Reviewer只讀四artifacts並寫自身判讀／D01欄，未讀原root作額外probe、改作者文件、跑測試或觸及他人工作線。


## D01 delta：diagnostic／namespace consumed-ready 私有標記（2026-10-21）

- Role：獨立 Plan-Reviewer。
- Verdict：**approved（僅既有工具準備的防重放補充）**。
- Required fixes：[]。
- 只回查 technical-spec／plan §5.2 此delta；其餘D01契約不重審、不代寫。追加前 evidence SHA-256：`2567f878529c4ff1e0069859dff16a721e938e572e3ae653a2fc3072b20af7ea`；既有歷史保留。

兩個新增固定leaf `diagnostic.consumed-ready.json`／`namespace.consumed-ready.json` 限同diagnostic owned scratch，沒有新增repository leaf。完成bootstrap、purpose／ready／來源及所有執行前guards後，launch前必須先exclusive0600建立並fsync；內容限定schemaVersion／diagnosticUUID／purpose／readyUUID／原ready bytes SHA，UUID／SHA只留private。既有／partial／launch失敗或缺Appreceipt均不可刪除、覆寫或當作未執行重放；write／fsync失敗停止且不得launch，保留能保存的partial／恢復事實，不以失敗自動重試。標記不代表App成功、舊namespace未寫入或清理ownership。

DT04已明列真正runner dispatch的正常consume-before-launch、existing／partial／writefailure／missing-Appreceipt後重放等負例；這是既有已授權工具的必要bookkeeping，不增加新Human政策、框架、run或live操作。可在原四個validation leaves內準備及測試，後續仍須獨立Tester／Reviewer與各future Human execution邊界。Reviewer未實作leaf、改code／作者文件、執行測試、建立真人scratch／inputs或launch／sign／DPK。


## D05 caller delta：新 host build/sign 操作清單獨立規劃審查（2026-10-21）

- Role：Plan-Reviewer。
- Verdict：**needs-rework**。
- Required fixes：[RF-D05-PLAN-01]。
- 受審：technical-spec §5.2 新增 D05 caller 清單、plan 對應 delta、step 作者交接；requirements 無需求變更。追加前 evidence SHA-256：`382a1fde4591f5f37f01b0210c72650510c46c3a59b0dade941aacc9d5a433d1`，全部既有 approval／實驗／真人歷史保留。

### RF-D05-PLAN-01 — 必經 caller guards 尚未有完整可照行的操作

technical-spec 的 D05 步驟1／4／6／7與有限 machine 收據段，目前混合既有 helper 精確呼叫及尚未具體化的 caller 控制：新root／parents exclusive ownership與mode建立、source／template表的固定建構與核對、inspection七欄對原baseline逐項比較、App signed-tree table（含symlink escape）構成與比較，以及全段stage／失敗catch後一次性有限build.machine的組裝。Frozen runner確有exclusive_json、private_owned、profile_data、private_command、inspect_selected；但沒有上述新caller guard／tree-table／build receipt控制的實作。單獨照列出的 helper calls 與 xcodebuild argv，不能自動得到這些必經保障，仍需執行者臨場撰寫新的私有控制碼。

**必要最小修正：** 在現有 spec 內補齊可直接靜態審查、依序照行的 bounded inline caller／具體命令，明列這些尚缺操作、精確 input／source table 與baseline值來源、success及各失敗stage如何產唯一有限machine並停止，以及Human只綁實際machine bytes的路徑；呼叫既有frozen helpers，不新增repository builder、CLI或泛用框架。可分成consume前／後、建置、觀察幾段，但每段不得省略成『同原檢查』或要求執行者另寫未審私有程式。保留root／leaf existing或partial即停、已耗ready不重放、不launch／不DPK／不改舊run及新assets/security/paid即停。

### 已足夠且不重開的部分

唯一 xcodebuild argv 已明列，沿原已採Automatic PBX，沒有全域identity overrides／portal/device/auth flags；新App位置／新source與舊run隔離、inspect_selected前後呼叫與原certificate/profile/DR baseline、build/sign與D06/D07分別freshready、獨立machine／HumanSHA觀察及原unknown歷史保留，方向與既有§5.2相符。本結果不要求重審已approved工具code、不新增live或新授權。

未修改作者計畫／code，未執行清單、建立root／ready／copy或任何build／sign／launch／DPK／資產probe。D05保持pending／human-check；應先完成具體可審caller後再交Human，不能先請Human批准尚未具體的操作。


## RF-D05-PLAN-01 bounded 回查：完整 inline caller（2026-10-21）

- Role：Plan-Reviewer。
- Verdict：**approved（僅可交 Human 審閱具體 D05 scope／fresh ready）**。
- Required fixes：[]；RF-D05-PLAN-01 已解除。
- 追加前 evidence SHA-256：`d90a0c8df9bed73acf44b933ffe46a04a93478c08325f83d6fa06dcdadfb54af`；初次 needs-rework 及全部歷史原文保留。

只回查原 required fix：technical-spec §5.2 新增的 bounded inline caller與作者 step 交接，不重審已approved工具code或擴大scope。逐段直接核 frozen runner API：exclusive_json／validate_ready／private_owned／profile_data／private_command／inspect_selected／diagnostic_context／validate_observation 的呼叫signature及返回值相符；未新增repository builder或依賴未定義helper。

- 新root固定namespace／UUID、canonical ancestors／自身UID／0700及exclusive mkdir／fsync具體；已存在或partial root拒絕同UUID build。Ready與consumed marker在copy／profile／build之前exclusive寫入；後續失敗保留，無重試／delete／App入口。
- 四工具、五模板、原五項bytes及production table的完整pins明列；frozen／check_copy在copy、build、inspection／install、manifest後重驗。原Automatic PBX完整SHA固定原設定及local package binding，不改原run／current／identity／manifest或PBX。Profile membership／效期由明列檢查及既有helper完成；唯一xcodebuild argv維持cached Automatic／禁portal與device/auth flags，沒有全域identity overrides。
- 七欄inspection精確比對profile／cert／原bootstrap DR／AppID／group，前後相等並驗新binary不同原current；signed-tree實作包含regular mode/hash、directory mode及linktarget，拒絕逸出／特殊檔案／walk error。App copy僅新scratch固定位置，無launch／store／DPK。
- 全段stage及BaseException失敗接線已具體，可信root後盡可能一次exclusive finite unknown machine；machine本身失敗不修復／覆寫。Root建立／flush等更早失敗維持有限unknown並保留partial。成功只completed及各SHA完成；observe使用實際machine bytesSHA、有限count/actions與whole，未答不造0，不以D05成功取代D06/D07或舊Writer結果。

本 reviewer只做AST parse／compile與字串SHA，沒有exec／import caller。明確freeze範圍為Python fenced body中**排除D05-CALLER-BEGIN／END兩行、保留其餘原始bytes及末尾換行**，SHA-256=`31dd8f62a1ecd2720b78a530350699d0ba296b6560bbb18f9ebfc078bd2f09f2`，符合作者交接；不是模糊抽出後任意格式化的版本。

此approval只表示缺少的caller操作已可審查，供Human決定只build/sign的新host具體方案與當段freshready；未核准／執行build-sign，未probe／建立真人root、ready、copy、manifest、App或任何assets。實際cache／profile目前可用性及簽章成功仍由獲ready後的真正步驟核對，新assets/security/trust/paid需求即停。D06/D07各自freshready／actual觀察、原save-a unknown／unknownchild／cleanup及S08停點不改。


## LG02：launcher-only amendment 獨立規劃審查（2026-10-22）

- Role：Plan-Reviewer。
- Verdict：**needs-rework**。
- Required fixes：[RF-LG-PLAN-01, RF-LG-PLAN-02]，僅下列兩項精確澄清。
- 追加前evidence SHA-256：`195f31de0fff6aaba120fd0df69b35e83bdea40161b0f2523f0ab4b0e8626984`；全部既有結果與收據歷史保留。

只核本輪四artifacts的§5.3／LG系列、既有Swift args入口與runner已知context責任。Human本輪已授launcher準備／non-live測試及review，先前human-check不阻止此受限準備；但未授新live。沒有重開DPK／host或否定既有Keychain受限結果。

### RF-LG-PLAN-01：限制UID／0700檢查的適用位置

technical-spec §5.3「全部trusted guards」目前寫「N與parents canonical／無symlink／自身UID／0700」。若全部屬性都套到系統temp祖先，固定N的系統parent不會是本UID／0700，候選將無法合法通過，且不能修改系統目錄。請只澄清：canonical／無symlink適用N與其祖先；自身UID／0700限N及本輪要求owned的descendants／新D，系統祖先沿既有可信temp位置驗證且不得chmod／chown。與既有D05／diagnostic_context的系統parent界線一致即可，不新增安全設定或probe。

### RF-LG-PLAN-02：把必要receipt錯誤分支列入既有LG-T03

同節machine schema已定義appReceiptValidity=invalid／unreadable，但LG-T03目前只明列valid-but-unbound／遲到receipt，缺少本輪必要的malformed及讀取失敗驗收。請在既有LG-T03追加actual non-live入口fixtures：malformed／binding無效→invalid；不能安全讀取或無法確定存在性→unreadable／appReceiptPresent=null；均保留finite結果、hostConfirmed=false、attributable=false且status=unknown，不洩漏raw bytes／error。只補既有cases驗收，不新增leaf、框架、host實作或live動作。

### 已足夠且不重開的部分

三leaf manifest與其他六validation／production／原run唯讀清楚；新caller runner freeze與host舊snapshot分開。Fixed invalid sentinel配既有兩條Swift args guard，正常diagnostic／env遺失fallback均在request／store前停止。Native專用launcher有限return／signal／spawn/wait/timeout、finally一次primary／固定fallback、不可寫disk不保證持久、CLI非零與真SHA Human binding均已定義。Host無nonce造成歸屬缺口如實固定hostConfirmed=false／整體unknown；native0或新valid receipt不冒稱host成功。

同N唯一D與八leaf、directory-or-marker partial永久spent、timeout不kill／不重放、固定Appreceipt安全snapshot及原D06歷史保留、未來exactUID／knownbinary worker前提不當歷史無寫、LG03→獨立Tester／Reviewer→Human新scope／freshready的邊界一致。此次僅兩項文字／驗收回修，未要求新框架或提前批准未具體動作。

本Reviewer未改作者文件／code、未測試／執行caller、未建立真人root／ready、未process/system/assetprobe、App/build/sign/DPK或Git；只append自身既有evidence與LG02角色結果。LG02未approved前不交實作；LG06/07仍未授執行，原D05／D06／save-a／S08結果不改。


## LG02 bounded 回查：RF-LG-PLAN-01／02（2026-10-22）

- Role：Plan-Reviewer。
- Verdict：**approved（僅launcher候選準備）**。
- Required fixes：[]；RF-LG-PLAN-01／02均已解除。
- 追加前evidence SHA-256：`c60336cfda7a1e8b86a098b35639fc5c682b0ae838ce4b0e1afa64947429f637`；初次needs-rework及全部歷史保留。

只回查spec／plan§5.3及作者回修交接的兩項delta。Canonical／無symlink適用N與全部祖先，UID／0700明確限owned N及所要求owned的descendants／新D，私有檔0600；系統祖先不要求本UID／0700、不chmod/chown，已消除不可能的前提。既有LG-T03已明列actual non-live入口malformed／context binding無效→invalid、不可安全讀或存在性不明→unreadable／Present=null，全部unknown、hostConfirmed=false及appReceiptAttributable=false且不洩raw資料。Plan的TestCase同步，無新增leaf／case框架／host或live範圍。

可依既有LG03→獨立LG04 Tester→LG05 Reviewer進行三leaf受限non-live準備；本approval不是實作完成或測試通過，不代LG06 Human具體scope／freshready，不允許真人root／inputs、process probe、App/build/sign/DPK、清理或新assets/security操作。原D05成功／Human0、D06unknown／Human0、既有Keychain受限結果與S08停點均保留。Reviewer未改作者內容或執行code／tests／live，只追加自身紀錄與LG02row。


## LG02 delta：current-state preflight 語意回查（2026-10-22）

- Role：Plan-Reviewer。
- Verdict：**approved（僅既有launcher候選準備的current-state guard）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`a347cd717bfef3a723009e47784cdfdbe70dcec7f0e0873cde2d0ffa93a69f72`；既有審查及真人歷史保留。

只審spec§5.3與plan末節／作者step的當次快照delta。legacyWorkerSettled明確限命名相容的current-known-open-absent，processCheckComplete涵蓋ownUID／exact host paths及selected-open argv查核；不再要求無法由舊D06證據證明的historical settlement，也不從CLI0／ready／單獨無AppPID填true。舊同步subprocess.run的普通等待語義與constructor罕見例外只作證據限制，未聲稱是D06已知根因。

查核scope具體：只本UID PID與完整binary paths，只有native executable為精確open或canonical同檔時才讀bounded KERN_PROCARGS2；核argc/NUL邊界，逐token比兩個既有manifest／原request導出的save-a及D06命令，不接受caller覆寫，不讀其他executable argv，無關資料僅記憶體立即丟棄。匹配host/open、snapshot／權限／parse或辨識不完整皆拒絕futureinvoke；不kill／不重試，不把零match作歷史退出／無待寫／無DPK／ownership或cleanup證明。

LG-T05以ordinary fixtures驗兩種exact匹配及unknown拒絕已足夠承接實作；無新leaf、flag、manager或host變更，與原三leaf manifest及既有sentinel／unknown／spentquota一致。此approved只允許該current-state guard的non-live實作／測試，再交獨立Tester／Reviewer；未執行或證明OS查核能成功，不代LG06/07 Human具體scope／freshready，原D06unknown／Human0及所有舊hash／清理停點不改。

Reviewer未改作者內容／code、未跑tests、OS/process/assetprobe或caller/App/DPK，只追加自身既有evidence／LG02補充。


## LG02 delta：RF-LG04-01 receipt publication 契約回查（2026-10-22）

- Role：Plan-Reviewer。
- Verdict：**approved（僅同一RF的兩receipt publication候選契約）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`20a2ff1c95c763d0d0333df4923378a7628d4ed1fbb3af10d8f16dd610878f81`；原LG04兩次needs-rework與全部green／反例歷史保留。

只核spec§5.3末段／plan及作者交接的必要delta，不審尚未實作code、不執行測試。兩固定pending leaves限同D，沒有repository leaf、全域writer、host／manifest／identity／舊root或其他六private leaf變更。原八leaf擴至十leaf已在manifest明列；同N一次、directory-or-marker partial永久耗額、不覆寫／刪除／重試／kill的邊界不變。

必要順序可排除同RF根因：先在記憶體完成canonical payload／SHA，再exclusive0600／O_NOFOLLOW寫pending、完整寫入／flush／file fsync／close／D fsync全成功，最後以不覆寫atomic link發布final。任一publication前失敗不建立final；完整pending仍不可作binding。Link後沒有新增fallible read／fsync／cleanup，成功已發布的primary不因稍後caller失敗被降成未發布。Pending保留供final同dev/inode／bytes／SHA與安全schema/context驗證，沒有自稱commit旗標或任意output路徑。

本delta明示的四態矩陣是這兩receipt的最新選擇契約，取代前段對caller缺失／fallback失敗的一般描述：兩者發布且一致選primary；primary發布而caller失敗仍選primary／exit2；primary未發布而合法caller發布選caller／exit2；兩者皆未發布（包括完整pending）必null／noHuman。兩final跨選擇／SHA矛盾或不安全pair拒絕，不猜測、不把residual bytes當成功。Primary／caller written flags只代表publication成功，hostConfirmed／attributable仍false／整體unknown。

只承諾當次可觀察的fsynced payload及atomic名稱發布，不宣稱final directory entry跨斷電存活。這個限制足以處理本RF的完整JSON／fsync失敗反例，無需擴成通用交易／durability框架。LG-T04已要求在實際prepublication file／D fsync位置注入失敗，覆蓋primary與caller各失敗、兩完整pending不得Human、合法primary與fallback binding、pair不符；沒有以publication後任意raise冒充前段fsync失敗或降低原noHuman期望。

此approval只准Implementer依既有三leaf完成同RF必要修正，再交原LG04獨立Tester；不解除其needs-rework，不以85green替代反例修復，也不放行LG05／LG06/07或真人freshready。Reviewer未改作者文件／code／Tester結論，未tests/probe/build/sign/launch/DPK或觸真人root，只append自身既有evidence與LG02補充。


## LG09：pre-trusted-D 有限stdout觀測獨立審查（2026-10-22）

- Role：Plan-Reviewer。
- Verdict：**approved（僅既有launcher工具紀錄的non-live候選準備）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`371a63a6bcb80c8463eb7f0d76314a71af7f3fd38f1812a6212030fd941da850`；原LG05 approval、LG06真stdout／Human0及全部歷史保留。

只核spec§5.3末段、plan與LG08作者交接的短delta。Requirements無需求變更；Human standing授權足以承接本輪工具補修／non-live／review，不等再次invoke。LG06原stdoutSHA b3d71cb085489be348cd23a361040f247b5b2bbc139b8ae8dd9bbf497885db66、未建D／未native／無binding／Human全程0的結果不回填新欄位或改成已知根因。

四新增stdout keys各有封閉枚舉及精確source point映射。Invocation局部plain dict沿現有amendment/state/snapshot傳遞、每point重置資料，native前清thread-local errno、返回立即取return／errno，能在原require前保留實際分類，無需global狀態／新檔案或額外native呼叫。已知errno有限映射、原生失敗errno不可得／0及未知exception為unknown，純guard且無失敗native才none；不從可能errno、PID race或API文件猜歷史原因。

原五keys及unknown/nonzero保留；新增只限launcher-amendment未trusted-D的拒絕，不改observe／trusted-D native/publication／Human schema。固定guardPoint／return符號／errno分類不含raw message、PID、path、argv、IDs或buffers；觀測初始化失敗也有固定有限unknown fallback。Output point只描述尚未可信的mkdir／ownership失敗，不授新輸出位置或假machine。既有guard成功／失敗條件、snapshot scope、host、pending publication與額度保持。

LG-T05/CLI actual入口的fake API／exception／純guard／成功return後界線拒絕、errno缺失及跨point不污染／敏感sentinel負例已足夠交實作；維持94回歸而不重編Swift或執行真API。只三leaf manifest、無新leaf／flag／caller／namespace／retry／kill／cleanup，與plan及LG08–12路由一致，未見需補契約。

此approved只准LG10 non-live實作後交獨立LG11 Tester／LG12 Reviewer及新freeze，不證code／tests完成，不授CLI/snapshot/OSprobe、真人root／ready／App/sign/build/DPK或新invoke。未來具體方案可審後才另取Human當段scope／freshready；D不存在不代表舊ready可重用。Reviewer未改作者內容／code或測試／探查，只append自身既有evidence與LG09row。


## LG15：正向名稱預篩候選獨立規劃審查（2026-10-22）

- Role：Plan-Reviewer。
- Verdict：**approved（僅三leaf受限non-live準備與所列known-child驗證）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`e1b365c90c286b1db46f2cfca5e218dd925959f1e5e6daca0634b97dfa8af6bc`；所有舊審查／實證／Human歷史保留。

只審本輪四artifacts的LG14／LG-N01–07及LG14–18交接，不審尚未改動source或宣稱API／runtime可行。Standing工具補修／非真人測試與review授權足以承接，不再要求Human先准planning。替換的是agent先前所有ownUID PID先讀fullpath的工具演算法，並未放寬產品秘密保存／簽章決策。

候選具體且保留未知阻擋：同次ownUID列舉每PID只新增一次proc_name；零初始化32-byte buffer，return／NUL／strictUTF-8／空值／長度均明列；新增snapshot-name只屬原有限point enum，不新增stdout keys／PID/name/argv輸出。API0、errno/notFound、例外或不可得長度均guard，不略過ESRCH／ENOENT、不重查。

固定候選集合僅既有兩host與open basename、完整及31/15別名；相等、非空prefix、15/31長度、非ASCII／encoding／別名建立／大小寫或正規化歧義均candidate或guard。只有可信成功且能明確排除所有固定名稱／別名的完整ASCII名稱才省path／args。candidate仍用原fullpath及selected-open精確argv查核，名稱本身不是identity，path任何錯誤仍拒絕。若本機名稱契約或別名無法證成，契約明定不可套用排除。此設計未將LG13失敗PID推成無關或gone，也不宣稱原子快照／歷史無寫／ownership。

LG-N01–07覆actual entrypoint fake ctypes的確定非目標零path／args、全部candidate別名與截斷／prefix歧義、name格式／native錯誤拒絕、candidate path notFound／permission拒絕、有限secret projection、原99回歸及sourcefreeze。N07只允許未修改sys.executable的兩個自有finite child及直接取得的known PID，核ordinary／spoofed argv0，API不符或非自然完成就保留限制停止；不copy平台binary／compile/sign/App、全UID OSscan或查其他PID。這足以交non-live驗證，不把先前copy sleep的-9當通過，亦不將公開source當本機exact revision保證。

三leaf及其餘六host／N snapshot／manifest／identity／binary與所有收據唯讀界線、publication/Human/sentinel及hostConfirmed=false都保持。未來仍沿既有具體同CLI/context/flags，不新增caller或待補操作入口；實際方式是否可用須待實作、獨立Tester／codeReview與新freeze，真launch另Human當段freshready，不重用LG13 ready。原LG13真stdoutSHA c1eac0c28c5b3dcc31cf7218d0ff1263a41dd32f31214611ca09a701e8863c9e／Human0／noD/noSpawn以及D05/D06／Keychain受限歷史、DPK／cleanup／S08停點不改。

本Reviewer只append自身既有planning evidence與LG15row；未code/tests/known-child實驗/OSprobe/App/build/sign/DPK或觸真人root／ready。此approval不代實作、測試或可行性完成；交LG16→獨立LG17／LG18。


### LG15補充：15／31長度條件的單一精確回修（2026-10-22）

- 最新 Verdict：**needs-rework**。
- Required fixes：[RF-LG15-01]。
- 初次approved為保守安全邊界的審查歷史，原文保留；此補充只收斂正向排除的操作條件，無Human gate或其他新要求。

**RF-LG15-01：不能僅憑長度15／31將所有可信名稱都升為candidate。** 現spec明寫「或長度恰15/31…均candidate」，並非僅target-compatible截斷；這使已能可靠排除全部固定known名稱／別名的ASCII前綴仍回讀path，留下與本次正向篩選目標無關的全域長度阻礙。安全性可保持，但此條件應作最小收斂。

請只修該決策句及既有LG-N02：15／31長度本身不判candidate；完整／alias／prefix或截斷結果只要仍可能代表任一known target就candidate，若可信原始前綴已與所有固定known名稱／可用別名不相容，可依既有正向排除規則省path／args。metadata空白、API／編碼／別名或規約無法判定仍guard，不能憑長度或notFound略過unknown。加兩種必要fixture：target-compatible 15／31候選仍查path，確定不相容的可信15／31名稱零path／args。其他契約、N01–07範圍、三leaf與已審安全邊界不改。

只需作者短修再bounded回查，尚未核准這項不同於原文的演算法供Implementer自行採用；不新增framework／leaf／API／實驗或要求Human先批准planning。Reviewer未改作者內容或code/tests、未probe／live。


### LG15 bounded回查：RF-LG15-01解除（2026-10-22）

- Verdict：**approved（僅既有三leaf non-live候選準備）**。
- Required fixes：[]；RF-LG15-01已解除。
- 追加前evidence SHA-256：`3055fe7f2ba80d0c73383cd86821f988639440d6690a16c78cbfb575a046791b`；初審及needs-rework歷史保留。

只回查spec決策句、LG-N02、plan與作者step：15／31長度本身不再candidate；可信且與所有fixedknown名稱／別名／可能截斷prefix均不相容者，允許positive exclude且零path／args。仍可能代表target的完整／alias／prefix或不可排除歧義者candidate，metadata／format／API未知仍拒絕，candidate仍原fullpath及selected-open argv。LG-N02已列compatible查核與disjoint 15/31零查詢兩類必要驗收，與plan一致，沒有以新規則略過ESRCH。

無剩餘required fix，不重審其他scope。Standing授權下可交LG16受限non-live實作及所列known-child驗證，再獨立Tester／Reviewer與新freeze；不代表可行性、code或tests已過。真launch仍另Human具體scope／freshready，不重用LG13 ready。Reviewer未code/tests/probe/live，僅append自己evidence與LG15row；所有既有歷史保留。


## LG21：fullinfo／status／instance候選獨立規劃審查（2026-10-22）

- Role：獨立 Plan-Reviewer。
- Verdict：**approved（僅LG22受限non-live準備）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`7a14a47e2f609d3f187f40e262e78476f35892a1c14079987f0c38569d004c3a`；舊source／實證／Human與所有成功／unknown歷史保留。

只核四份artifacts的LG20契約／九欄manifest／LG-M01–07與LG20–24交接，不審不存在的新code、不執行SDK CLI、known-child或API。Human已授必要guard修補／non-live／獨立review且停止真人／DPK；不新增內部planning Human gate。

### 有界可實作性與證據界線

公開SDK TBSDINFO arg1、逐欄native alignment與full-size return／query PID／ownUID／starttime／已知status檢查均明列，layout不能猜offset。M01允許普通自有temp最小unsigned SDK-header CLI核sizeof／offsetof，不新增repo builder或signed App；在ABI／metadata不能證成時拒絕。公開XNU arg0/arg1/zombie來源只證結構配對問題，文件明確不當本機exact revision或LG19根因證明；runtime正向證據另由M06受限驗收提供。

可信完整A為SZOMB才排除，空name不會反過來把未知當zombie；live僅已知可用status，原正向name alias/prefix規則保持。Candidate做兩次原fullpath／selected-open argv分類，再讀B；PID/UID/starttime/status/原bounded name/comm及分類必須一致，觀測到真host/open即直接衝突拒絕，不重分類新instance成無關。Permission、短／零reply、未知／變動及reaped全部guard。

沒有採不可靠的UID列表absence或sysctl fallback：used低於capacity只屬必要界線、不表示完備，沒有新增membership重讀／重試迴圈。本次有界instance／雙分類能拒絕可觀測變動，但文件如實保留中間exec/ABA、PID重用、查核後新程序／exec及非原子限制，不宣稱偵測全部exec、historical退出／無寫或cleanup權。Reaped仍可能阻擋，候選不承諾消除全部prelaunch failures，也不自動拿真人試運氣。

processEvidence八key有新的實際證據來源：decision記本次最後有限事件，zombie／noncandidate排除、instanceChecked／Changed、conflict與checksFinished僅對相應完整正向觀測置true，false不代表全域不存在。只launcher stdout的pre-D與既有trusted-D結果加此allowlist，原四欄metadata真return/errno仍保留；公開不含PID/UID/starttime/name/path/argv/rawerror/buffer，觀測自身失敗回notChecked/allfalse且不放行。Published machine/caller/Human與atomicpublication不變，不另建收據框架或privateleaf。

### 驗收、scope與停點

LG-M01–07足以交TDD：ABI與metadata負例、zombie/noncandidate零path、candidate原path/args及雙端核、PIDreuse/分類/path/argv變更／denied/reaped守住拒絕，aggregate／projection／reset及敏感負例與原104回歸。M06僅單一原版未修改未複製sleep finite child的直接known PID，running→未wait zombie→wait reaped及arg0/1對照，finally自然wait；有界狀態等待只此fixture，階段沒觀察到就未驗／unknown，不擴其他PID或全UID真掃描、不kill／改環境。沒有把source／fake或先前樣例當一般runtime成功。

九欄仍三個runner/tests/README leaves、各owner既有evidence與step；其他六host／production／原N與manifest／identity／binary／source snapshots／收據唯讀。原sentinel／一次quota／publication／Human binding不變，沒有新flag／caller／namespace／產品API。可依LG22→獨立LG23 Tester→LG24 Reviewer完成non-live及newfreeze；這不是新code／測試通過或可行性核准，不設自動真人invoke step。下一次真人仍須Human另明確指示及具體同CLI／freshready，DPK／cleanup／所有歷史停點維持。

Reviewer只append自身planning evidence與LG21row；未改作者code／文件／其他角色結果，未tests/probe/known-child/SDKcompile/launcher/App/build/sign/DPK/root/ready/cleanup或派遣新agent。


## LG27：path失敗單次post-metadata獨立規劃審查（2026-10-22）

- Role：獨立 Plan-Reviewer。
- Verdict：**approved（僅LG28三leaf局部non-live準備）**。
- Required fixes：[]。
- 追加前evidence SHA-256：`eeda1ce22529bda965d6508d8001787b2818bce9a24649307a154a425caeb587`；所有既有實證／Human／unknown歷史保留。

只核四artifacts的LG26窄branch、五key pathFailureEvidence／defaults與P01–05、九欄及LG26–30路由；不審不存在的code或執行測試／query。Standing必要工具修補／non-live授權適用，不增加Human planning gate；真人／DPK保持暫停，LG25 ready已結束。

**有界序列明確。** 只有已持可信live candidate A、第一／第二proc_pidpath實際完成返回≤0才進一次同PID原arg1 fullinfo；不是path retry、UID重列／等待或query loop。Path API自身exception、成功後decode／其他guard與已見真host/open衝突都不進此branch。Post必原fullsize/PID/ownUID/status/starttime驗證；A與post PID/UID/starttime同且SZOMB才正向排除並結束該PID，不再讀其第二path／正常B。新instance即使zombie也拒絕；liveSame／classification改變、permission／unavailable／invalid／unknown全維持guard，不把metadata zero稱reaped/gone。不保證原子／ABA或歷史無寫。

**原錯誤與單筆歸屬足夠。** 原path call即時保留四guard keys與真errno，post使用獨立局部observer，故post reset/API不覆蓋path診斷。五key只描述最近一次本iteration的失敗：pass由caller傳first/second，postState由該A/post觀測，nameMatchKind只A實際pbi_name或comm來源及full/真截斷alias/prefix/ambiguous判準，pathErrno從原native即時真值而非coarse notFound反推，pathFailure保存原四key副本。Post仍guard時外層原四key保留path；zombieSame後另一PID失敗時外層可變，但nested仍是先前最近path事件，沒有把較早processEvidence累積true冒充失敗PID已核。Names只作觀測，不變預篩或identity判準。

**有限schema與驗收。** 五key defaults／allowlists、invocation reset／最後事件覆寫及unknown觀測失敗不放行均明列；只有launcher stdout新增物件，其他CLI及published machine/caller/Human／publication保持，無raw PID/UID/starttime/name/path/argv/error/env或任意errno數值。P01–05覆first/second全部postState、原path不retry／post恰一次、原errno與四欄在post成功失敗均不變、name/comm來源與alias、local evidence對aggregate、後續PID失敗與敏感projection，足以承接局部TDD。原114回歸保持；既驗SDK/known-child無必要不重做，執行者應如實區分新跑fake檢查與沿用舊證據，不將沿用說成新實測。

三leaf manifest、其他六host／production／原roots/context/source/history唯讀及無newleaf/flag/caller/namespace一致。可交LG28→獨立LG29 Tester→LG30 Reviewer與新freeze；不是code／tests完成，不授真query／fixture／CLI／App/build/sign/DPK/cleanup或新ready。LG25真stdout與Human0不回填、更不推kernel根因；未來真人仍另明確指示／具體scope＋freshready，不因D不存在重用舊ready。Reviewer只append自己的evidence及LG27row，未改作者內容或其他role結果。


## LG32 Plan-Reviewer：離線launch-report binding規劃審查（2026-11-03）

**Verdict：needs-rework。Required fixes：[RF-LG32-01]。** 只審四份artifacts之LG31五schema／四葉manifest／LB01–06及未來操作文案；未審不存在的新code或執行tests／compile／probe。追加前本evidence SHA=`f57d8840cd28b77f52f6a090230ef1ab34d9f663c8afa71951e22c06ad9fb14a`；舊歷史保留。

**RF-LG32-01（必要／可執行契約缺口）**：`analysis/github-oauth-credential-persistence/technical-spec.md` LG31「固定位置及schema」「有界鏈與freshness」「發布與有限結果」宣告全部JSON exact keys/types/有限值，但新增`binding-consumed.json`只敘述綁context/attempt/ready/requestSHA，`launcher.machine.json`只描述native rc/signal/有限exception等內容，沒有兩者完整key集合、型別／nullable及必要交叉binding。Machine publication又是hostAttributed成立前提，不能由Implementer臨場補造其成功／錯誤收據契約。

Required fix：由原作者在原LG31補這兩份固定private JSON的完整exact keys、值域／nullable、context/request/attempt/ready或protocol receipts之必要綁定及失敗預設；明列`machineSHA256`只取已發布machine原bytes置於外層stdout，machine自身不含自身SHA、避免自hash循環。沿既有LB04增加這兩schema的缺欄／多欄／錯型別／錯binding拒絕及partial consume／machine publication失敗不成功驗收。只補既有兩leaf契約，不新增leaf、旗標、角色或通用receipt框架。其他四artifacts只對齊必要引用，不改舊結果或擴新Human decision。

其餘受審設計未見需擴scope的缺口：request不含自身hash，report/ACK/final bytes鏈無自hash；nonce/processUUID非auth/freshness，launcher另核精確binary與ownUID/PID/start/path，ACK前重核且有界等待；sameUID信任／exec-ABA與時鐘限制明列。固定pending→預同步→no-clobber link、partial quota耗用、不覆寫／retry／kill與unknown拒絕一致。新sentinel／任一新env優先獨立零credential能力入口，env遺失亦不回落legacy，LB01要求actual Swift共用路徑。新unsigned fake source/binary證據與signed-host分開，原122回歸及四葉／五模板界線合理。

Human已授planning/code/nonlive/review，舊N恢復不是此離線前提，無需再問內部planning許可。本needs-rework只回原作者補上述契約；新context／signedbuild／真kernel或App／freshready／DPK／cleanup仍未授。後續操作文案如實保留cached資產有效期unknown、新資產／cert／trust／paid停點，未將提案當執行。只追加自身原planning evidence及LG32 row/交接，不改作者四artifact內容、code、Tester或其他角色verdict。


## LG32 RF-LG32-01 bounded回查（2026-11-03）

**Verdict：approved；required fixes=[]；RF-LG32-01解除。** 僅回查原唯一required fix之spec／plan／作者交接增補，初次needs-rework及所有歷史保留。追加前本evidence SHA=`f95e93f3ec0b602babe5ce20e19b7696cda891c9712b1aae7a955908ff60117d`。

兩固定private schema現已列完整必需keys、型別／nullable與值域：consume綁B、actual runner、ready及evidenceMode，request bytes先於記憶體定稿取SHA，consume exclusive/fsync成功才建立attempt，partial耗額不重放；machine綁有效consume原bytes及B/ready/runner、receipt鏈，native PID/rc/signal/settled與exception有限狀態及失敗預設具體。已發布pair與完整交叉驗證才可投影成功；pending／publication失敗一律不attributed。Machine自身無machineSHA或自hash，外層machineSHA僅來自已發布原bytes，無digest循環。

LB04已明列兩schema缺／多欄、錯型別／bool冒int／nullable／enum／binding拒絕、partial consume耗額、machine publication失敗、native一致性及fake-only不attributed，且不能用defaults補成有效輸入。Plan引用與作者step一致，未新增leaf／框架／Human gate，requirements無新需求故未變。此修補足以交LG33原四葉non-live實作，再獨立Tester／Reviewer；不是code/tests完成或signed-host實證。

舊N恢復仍非本輪離線前提；新operational context、signedbuild／資產採用、真kernel/App／freshready／DPK／cleanup仍僅後續提案，未授執行。Reviewer只追加自身原planning evidence及LG32 row/交接；未code、tests、compile、probe、私有context/ready或Git。


## LG37 Plan-Reviewer：profile-free純診斷候選（2026-11-03）

**Verdict：approved；required fixes=[]。** 僅LG36四artifacts之候選／兩purpose proof／PF01–05／精確四葉manifest及Human停點。不是實作、signed artifact或OS launch成功，也不自動交Implementer；依本輪明確授權，獨立review後仍交Human採用方案。追加前本evidence SHA=`fb055c08c8cea1c4ad08cbea5298f5ff1bd095587bc9d419a627975079df71f1`；原needs-rework／146成果／成功unknown及所有歷史保留。

**OS必要條件與設計限制已分清。** 獨立讀Apple [TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)官方內容（本次以Apple tutorials/data官方JSON取得）：Mac app無restricted entitlements時不需profile，keychain-access-groups則須profile授權。因此原DPK host的group/profile門檻不可一口刪除；只限制到用途隔離、無權利claims的新variant有文件依據。用途hard fence、exact same DER/Team/BID/codeID及額外dynamic核對是本候選保護契約，不誤稱OS對一切Mac診斷強制要求。

已核[Apple TN3161](https://developer.apple.com/documentation/technotes/tn3161-inside-code-signing-certificates)對identity selector、trust及驗證用途的界線：DER日期／關聯key可見不能保證私鑰可用，strict signature verify不能替代正常執行政策。SHA1只由已核原DER導出供codesign selector使用，簽後仍比leaf DER SHA256精確pin；沒有把DER SHA256當selector或靠CODE_SIGN_IDENTITY／不帶portal flags宣稱可防所有資產變動。Certificate class/用途、現trust、private-key sign-use及Gatekeeper/AMFI仍待另授精確核驗，未知就停，未推斷certificateType或承諾一定可launch。

**用途與身分契約足夠。** 同target/Debug、原registeredAppID/BID/CodeIdentifier與原DER-Team保持；移除application-identifier/team entitlement claim不改CodeDirectory Team或註冊身分，也不驗DPK權利。LAUNCH_REPORT_ONLY頂層只允新LaunchReport；legacy argv/env／原fake／unknown／envloss不能回落credential capability。需驗signed empty claims（含Xcode注入）及無embedded profile，不能只改模板一key。五模板唯讀、只四既有工具葉未來可改；不新target/config/module/repo leaf。

兩既有proof exact keys、固定purpose/variant/mode、compileConditions／來源hash／原identifier外部expected值、buildProofSHA及final binary hash交叉核對具體；host/runner都拒舊DPK或opaque JSON，新marker非auth。原request/report、兩次live-instance/path、freshness/last-wall、ACK/final/native0 settled/publication標準保持。ACK前同reported PID新增dynamic validity/精確identity與instance重核，必在原deadline，unknown不ACK；不把nonce或相同path當identity。SameUID惡意／exec-ABA／postcheck殘餘未誇大為消除。

**PF與後續授權。** PF01–05足以交後續受限實作：actual compiled dispatch/envloss與共用hooks零credential能力、兩proof exact schema/purpose負例、fake static/dynamic錯DER/Team/BID/codeID/instance/deadline、原binding/clock/publication不退步及新variant新freeze；舊146不當新variant認證。本輪PF全部未執行、不重跑146、不編譯新variant。

未來recipe已將unsigned build、原identity手動sign、新context與單次LS分開；簽章前未知profile/nested code停，不刪除或deep-sign猜補。簽後strict／DER／identity／empty claims／profile absence／DR／final SHA才可凍結新context。Expired／原identity不可核／用途不符／需newcert或profile、revoke、trust/ACL/partition-list、安全／paid或改Team/BID皆停；不以此candidate繞正常政策或混同notarization要求。實際私有輸入未建立、不是當下可run命令。

Agent應負責精確唯讀定位／驗原DER與既有identity、準備可審命令與證據，不將profile排障交Human。Human不可代填的動作集中於方案採用、具體build/sign操作審閱與ready、原key當次授權（無當次選項或需永久權限即取消）、新context授權及launch freshready與實際prompt觀察。原profile本輪直接hash定位未匹配是unknown，不要求恢復舊N/profile，不猜資產變動。現在不問ready、不執行操作。

只追加本owner既有planning evidence及LG37 row/交接；未改作者計畫／code，未tests/compile/build/sign/probe/App/新context/ready/資產或profile查詢變更/DPK/cleanup/Git，也未新agent。


## LG45 Plan-Reviewer：certificate解析與唯一sign amendment（2026-11-04）

**Verdict：approved；required fixes=[]。** 僅四artifacts LG44 SP01–05／九欄／有限evidence schema與固定私有leaf/parent配額契約；可交LG46 bounded non-live，不代真人query/sign/ready/context/launch。追加前本planning evidence SHA=`5ff5cb2fcda0c72a10c6a01869d83a7e04b92e71fcc5d2efc23436d6896f79f3`。未審不存在的新code，也未測試／probe／查憑證或私有root。

**Parser保護未降低。** 原DER type/pin先於decode及SHA1；subject/dates/class以三個固定stdin argv分離，public-only／locale/config固定／bounded capture。只接受單獨subject記錄，RFC2253 escape/RDN/attribute按明確規則處理，非法escape／multivalued RDN／多OU（含重複同值）皆拒絕，不借issuer/fulltext或dedup得Team。UTC兩唯一日期、Code Signing EKU與兩原OID仍必要，postverify/dynamic沿共用嚴格解析；不是以DER pin或subject取代class/trust。原fulltext OU耦合是可證工具缺口，但無LG43實際decoder輸出，不回推其精確原因。

**Finite evidence與驗收具體。** SP02 exact guardPoint/decoderPart/outcome/returncode/OUcount／四nullable檢查布林，未查null、實讀pass/fail，native exception/timeout/nonzero不變空成功，後call不抹前錯。只有限enum/int/bool/null，不公開subject/Team/CN/date/path/rawerror；不補寫舊LG43。SP04要求實際三argv與原config形狀fixture，先證舊combined錯拒、再證新解析只信獨立subject；覆escaping/重複OU/subject與缺class/date/EKU/OID/wrongDER/path等，拒絕時零codesign，不mock整個helper。SP05包含selector/static/dynamic與有限projection、parent bytes/replay/partial/publication及新freeze，足夠承接局部TDD；main不變不重編Swift或機械重跑146。

**Parent、不重建與唯一額度。** SP03新caller/config/controller/freeze及固定consumed/proof/artifact/operation leaves受限於同準備root，原leaf/history不覆寫；amendment固定literal與原LG43 op/caller/config/consumed hashes、原paired unknown/sign-preparation、雙App原tree／無context與launchmarker等前提可核。原sign quota永久spent；新amendment只一次，任何新consumed/operation pending或final存在就拒第二次，先exclusive consume後query，freshready拒舊兩項，不因缺成功proof重試。非新namespace或general recovery。

原build/source九葉與App保留LG41 provenance不假重建；新controller SHA=新reviewed runner，repo三工具leaf另核外部approved reviewedToolSourceHashes，repo main/五模板/package及私有原九source仍原freeze。這解決修改工具與原App sourcehash混綁，不能偷更新buildproof。新signing proof仍原exactschema引用原build；未來context只能引用成功amendment operation/新signproof，不能fallback舊unknown。External actualSHA核對不自證review。

**Scope與Human邊界。** 本輪plan-only；LG45通過後可依已授routine排障範圍做LG46→獨立Tester/Reviewer，LG49同root私有準備與LG50實讀審查另明列，不增加內部Human訪談。三工具leaf/owner evidence可變，main/五模板/production/舊caller-config/source/build/App/history唯讀。所有nativequery/sign只待LG50後新最後窗口freshready；原LG43／Human whole0及兩ready已結束不沿用。失敗即停不第三自動retry，原cert/Team/AppID/BID、trust/ACL/paid安全條件及DPK/cleanup停點完全維持。

只追加自己原planning evidence與LG45 row/交接，未修改作者內容、code或其他角色結果，未tests/compile/query/probe/簽章/App/新context/ready/Git／新agent。


## LG48補充：LG49六個producer私有leaf規劃回查（2026-11-04）

**Verdict：approved；required fixes=[]。** 僅spec／plan「producer私有manifest銜接澄清」及作者交接delta，不改LG48 code approval或舊verdict；追加前planning evidence SHA=`47932c56a7054844f384c59769388956d94f1522672aecfd254928389567d9e5`。

六個固定root leaf逐列明確：context/launch各一consumed與operation pending/final；沒有new namespace或任意receipt路徑。Consumed exact schema綁parent LG43、已發布child sign success/proof/artifact及caller/config/controller/newready；launch再綁context operation/bytes SHA。Context operation只能完成copy/static驗證後非null contextSHA，launch成功必合法child/context鏈及binding hostAttributed=true/code0；unknown/null不升格成功。Consume與operation hashes是前向bytes綁定，不將ready放入尚未可信future-context，無自hash或freshness循環。

各phase先共同核原parent/source/build與unsigned原件，sign前才核副本unsigned/context不存在；簽後context/launch改核新signed tree及child成功三pair，再各自exclusive/fsync消耗該phase後copy／單次binding dispatch。Consumed或operation pending/final任何既存即永久spent，partial不刪不重用；published pair同inode/bytes、不覆寫，native/write錯誤仍unknown。原parent/consumed/history、原build proof/source/App不變。

足以續LG49 actual privatecaller準備與NoApp跨phase驗收，再LG50實讀；這只是manifest/schema補齊，不是六真leaf/context/ready已建立，也不授query/sign/launch。各段authority/freshready與舊window ended、DPK/cleanup停點保持，不增加內部Human確認。只追加自身planning evidence與LG48補充交接／其evidence引用；未code/tests/query/probe或新agent。


## LG53 Plan-Reviewer：LG51 report-timeout受限補修（2026-11-04）

**Verdict：approved；required fixes=[]。** 四artifacts present且LG52作者交接/readback完成；只審LG52 A–F／RTT01–06、exact schemas／manifest及Human停點，不自評實作／執行結果。追加前planning evidence SHA=`b0028643218bca68e8024a2b2b5e759f155bc14175a9f42536c1e55e80078713`。可交既定LG54 bounded non-live實作；LG51 sign/context success、launch unknown/report-timeout/native未結算及Human全窗口permissionRequests=0/wholeObserved=true原範圍保留，不拆造各段數字／actions或回填成功。

**真實接線矩陣足夠。** RTT01保原request/context/proof/source bytes/digests，ordinary fixture只替歷史clock與最低identity/executable/ACK sink，真Swift read/keys/verifyProofs/verifyContext與首失敗guard，不由Python重編JSON或fake report補成功。RTT02真FS/owner/mode/canonical/no-follow/size、nlink2及Foundation NSNumber/CFBoolean/equality；native accessor只SDK/getpid自身，正常／不可得與格式負例如實記，無全UID/他PID/GUI。靜態14條件無矛盾、OS lifecycle或TCC preflight都不升格Swift入口／拒絕原因。發現guard bug才沿原嚴格語義最小修，不為未知造環境blocker。

**Bootstrap與entry/failure schema。** 新五argv與原兩env各exact pair；完整argv優先，env僅diagnostic fallback，duplicate/unknown/partial/mismatch仍wire failure。Bootstrap先核固定candidate request path／rawSHA/exactschema與owned root/output才entry，不讀第二任意path，無可信pair只finite stderr。新entry/failure exact B+有限stage/outcome/wire/nullable selfbinary/三instance欄，只有實得可填；同inode/bytes公開pair不代表auth或完整attribution。錯wire/未知RIVET仍拒絕，不回credential path。Failure保真正失敗guard，無rawargv/env/path/error/IDs；disk/可信output不足不保證必落檔，不以不落檔推App未進入。

Report/ACK/final/request/context/proof原exactschema不改；新machine/publicprojection明確exact追加entrySHA/failureSHA與appOutput，舊machine只用frozen舊validator解讀。App streams只bounded snapshot：≤65536原bytes可SHA，oversize只size，不公開raw內容，不以snapshot證已final。Newsuccess除原全部binary/static/dynamic/liveinstance/freshness/clock/ACK/final/native/發布條件，另須有效同B entry、failure不存在；entry、exit0或新UUID均不能單獨hostAttributed。有限schema與成功標準可由RTT03–05負例逐項驗證，不放寬原安全界線。

**Native與transport。** Open沿精確fixedApp、env、stdout/stderrredirect及新五argv；native與App streams分開。Report缺失時每輪及timeout/finally只poll既有Popen，真rc/signal/settled即保留、未得仍unknown；pollerror不抹先前值。原30秒、no -n/no kill/no retry維持，rc0從不代report或Swift成功。RTT04要求actual subprocess fake child/最低nativeprovider覆無report的rc0/nonzero/signal/exception/timeout/pollerror及精確argv，非mock整個核心而喊成功。

**Once／manifest／provenance。** Parent明綁LG51 sign/context成功、launch operation/machine unknown及原caller/config/controller/freeze/consumed/pairs，不重置spent或新random namespace掩歷史。新LG51-report-timeout-amendment-1各固定caller/config/controller/freeze、source/project/build/unsigned及子context/三phase leaves明列；每phase marker/operation pending/final／partial attempt耗額，不覆寫／清除或跨phase再要求signedcopy為unsigned。新main必新unsigned App、新build/sign proof/source9，原signedartifact不能冒充新host；原key/DER/Team/BID/codeID不換。公DER來自已pin owned副本，準備不需先重查Keychain或叫Human找欄位。

LG57實際私有檔/unsigned產物/caller/config/proofs/NoApp跨phase仍須完成，再LG58獨立實讀；本planning只授內部受限準備，不代表真sign/context/LS授權。Newconfig及freeze exact keys、四工具reviewhash／原parent、新build/finalbinary與公DER pin分開，無自hash/自核approval。Oldsigncontext成功和launchunknown均immutable，originalOS evidence只限既有安全範圍，原14靜態guards不是實際core測試替代。

本輪不新增內部Human訪談；依routine授權可往LG54→Tester→Reviewer與unsigned準備，但原key當次auth/sign/真context/單次launch須LG58後最後集中新當段authority/freshready，原全部ready不carry。缺key/需newcert/profile/revoke/trust/ACL/security/paid/改TeamBID或OS拒絕均停，DPK/cleanup不解鎖。Reviewer只追加自己原planning evidence及LG53 row，未改作者spec/source／他人verdict，未測試/compile/build/sign/LS/App/新context/DPK/query/probe/Git或新agent。


### LG61 Plan-Reviewer：LG60 profile acquisition 獨立審查（2026-11-04）

**completed／approved；required fixes=[]。** 已核四 artifacts LG60／PA01–05：最新 Human 授權涵蓋原 Team/AppID 的 Automatic provisioning、必要 profile download/create/install 與標準流程必要 development certificate 新增；原 DER 必須包含於最終有效 profile，不以新 cert 替代。Exact copied target／六檔及 local-package 接線、固定 profile-acquisition-1 私有 leaves、exclusive once／partial spent、before/after/input hashes及有限結果足以交 LG62 執行。

CMS signer status／既有 Apple chain trust、原 DER/date、Team/AppID prefix、exact group、device 及日期須逐項真驗；未知不算成功、Xcode green不代 pass。原 cert/history/LG59/spent immutable；不手動 Manage Certificates/Fix Issue、不 revoke/trustACL/付費／換身分；signed App build若必需即停。僅真 login/2FA/unlock/private-key auth交 Human，不再索一般 ready。Approved只放行本次 profile acquisition；不放行 App sign/Run/LS/context/DPK/cleanup。本人僅讀規劃並追加自身 evidence/row，未操作UI、資產、測試或建私有目錄。


### LG66 Plan-Reviewer：LG65 bounded contract（2026-11-04）

**completed／approved；required fixes=[]。** 已核四artifacts最新LG65：DPK互斥purpose/profile-aware分支不放寬report-only；同attempt先完整ctx/phase/claims/binary/instance再ACK，真operation與六欄結果綁final/machine，ownership及writer退出/fresh讀/完整替換/真同身分重建順序完整。Exact四葉/私有manifest、DK01–06與affected測試、既有profile快核及歷史preservation足以交LG67非live實作。硬deadline含Human等待／剩餘門檻／到期不新operation、不kill/cleanup；替換及build/sign提示提案未採，不代Human授權。Actualcaller/unsigned準備及獨立Review後才集中fresh授權，現在無sign/App/DPK權限。僅自身metadata，未code/tests/build/資產或live操作。


### LG74 Plan-Reviewer：LG73 bounded window契約（2026-11-05）

**completed／needs-rework；required fixes=[RF-LG74-01]。** 其餘最小scope、三份hash鏈、unsigned/後簽proof分離、contextSHA帶入B、剩餘時間/到期停止及新Human邊界符合本次交接；未重查歷史或操作source/資產/live。

**RF-LG74-01（唯一，跨開機拒絕缺綁定資料）：** spec要求同一boot-session／拒絕跨重啟續窗，但human-window/live-authority的exact schemas未保存開窗時boot-session識別。只用UTC窗口與mach_continuous_time>=start不足：原uptime短、重啟後uptime追過原start且UTC仍窗口內，兩數值可均合法。最小修正：Human record捕捉既有可信本機boot-session值/hash，authority逐值承接／hash鏈綁定，各participant在native/SecItem前核當前同session，不可得或不符拒絕；只增必要欄位，不新leaf/framework。NW03新增不同boot但UTC/mono範圍表面合法仍零native/DPK的負例。由作者最小修spec/plan後bounded回查；不需Human內部planning採用，不授開窗。


### LG74 RF-LG74-01 bounded複查（2026-11-05）

**completed／approved；required fixes=[]，RF-LG74-01解除。** 只核四檔最小delta：descriptor凍結來源政策、Human capture與authority同值承接可信kernel boot-session canonical hash、各participant current-session核對及不可得先拒；fixed buffer/UUID/域分隔bytes明確一致，NW03含跨boot但UTC/mono均合法仍零native/DPK。沒有新leaf/framework/權限；前輪needs-rework/RF歷史保留。只交LG75離線實作，準備/Review/真Human採用前不開窗、sign/App/DPK；本人只讀契約及追加metadata，無source/tests/probe/live。


### LG83 Plan-Reviewer：LG82 closeout契約（2026-11-05）

**completed／approved；required fixes=[]。** 已讀README/design、SDD/PlanReviewer與四artifacts LG82/CD01–05/CO01–05；D六文字葉、P四檔、E八既有owner證據、V九葉exact-stage聯集及Readonly/Modify界線明確。無已知產品code必修，本次僅必要能力/驗證/導覽與publication草案、現況帳本及後續exact-stage/staged語意提案，未擴API/圖/工具/新artifact。文件必保LG81本環境假bundle DPKpass及未驗configuration/拒絕/斷電等界線；原README歷史freeze不當目前9/9，圖bytes/QA沿初始snapshot，Humanvisual/S08/LC06與整合缺項不代答、不抹歷史。

五base衝突及configuration公開契約差異只列未整合，不機械取邊/merge/改contract；不影響已核DPK結果。CO01–04有限docs/links/secret/abs/unchanged-bytes核對適度，不重成功suite/live。LG86approved後LG87先讀index、只exactleaf stage、排除個人metadata/xcuserdata/私有資產、核staged diff並依commit skill提message，未知staged不reset；最終停Human，不commit/push/merge/rebase/PR write或cleanup。只可交LG84受限文字收尾。本人只唯讀計畫及自身evidence/row，未改作者內容或執行tests/Git/資產/live。
