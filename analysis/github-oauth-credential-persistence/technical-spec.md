# GitHub OAuth 正式憑證儲存：技術契約

- Topic：`github-oauth-credential-persistence`；受限執行契約；規劃審查及修訂結果見 [evidence/planning-review.md](../../plan/github-oauth-credential-persistence/evidence/planning-review.md)。
- 配對：[需求](requirements.md)、[計畫](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.plan.md)、[帳本](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.step.md)。

## 1. 既有邊界與 additive API

GitHubIntegration 仍是 non-BC。既有 `OAuthCredentialStore.load/save` 維持 async typed throws(any Error & Sendable)；bundle 六欄、fetcher、provider、snapshot、scope／clients／Package.swift 不改。沒有既存 OAuthCredentialStoreError 型別可沿用，不建立 shared BC failure contract。

新增 `GitHubOAuthAppConfiguration: Sendable`，public immutable clientID／clientSecret，`init(clientID:clientSecret:) throws(GitHubOAuthAppConfigurationError)`；空字串拒絕、不 trim，有限 enum 僅 invalidConfiguration。description／debugDescription／customMirror 全脫敏，不輸出 ID 或 secret。

同檔新增 `GitHubOAuthAppConfigurationStore: Sendable`：`load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration?`、`save(_ configuration:) async throws(any Error & Sendable)`。

新增 `GitHubOAuthDataProtectionStores: Sendable`：
- public `init(accessGroup: String, service: String = "local.rivet.github.oauth.v1") throws(GitHubOAuthDataProtectionStoreError)`；空 group／service 或含 wildcard 的 group 在建立時回 invalidConfiguration，不呼叫 Security。
- public `configurationStore: any GitHubOAuthAppConfigurationStore`。
- public `inspectCredential() async throws -> GitHubOAuthStoredCredential?`。
- public `credentialStore(clientID: String) -> any OAuthCredentialStore`。
- `GitHubOAuthStoredCredential: Sendable` 公開唯讀 clientID、credential（完整 bundle）；建立由內部驗證後進行。
- `GitHubOAuthDataProtectionStoreError: Error, Sendable` 僅 denied／unavailable／corrupt／identityMismatch／invalidConfiguration，無 associated payload。
- bound clientID 空字串於 operation 回 invalidConfiguration，且不得呼叫 Security。bound load 完整 decode 後比較 ID。bound save 在同一 actor operation 先讀完整 existing envelope；已有不同 ID 回 identityMismatch，corrupt／denied／unavailable 原樣回有限分類，均零 write；不存在或同 ID 才以綁定 ID 建完整新 envelope並寫入。不新增 clear／repair API。

Configuration／stored credential 的 diagnostics 均脫敏；不變更既有 bundle 的 reflection 契約或宣稱防止記憶體／debugger 存取。

## 2. 同步 Security seam 與 actor

同一 stores facade 建立唯一 internal actor；configuration store、inspect、各 bound stores 均共用它，不設 global singleton／registry。各 actor operation 內的 validate／codec／Security read-check-write 或 update-add-update 全程同步，無 suspension point，避免 actor reentrancy 拆開完整操作。不同 facade／程序不承諾協調。

internal Sendable Security seam 提供同步 copy／update／add，production wrapper 只在實際 operation 呼叫 SecItem APIs；public API 不暴露 seam。測試用 internal initializer 注入 fake，觀察完整 query／attributes／calls，禁止 live Security side effects。Fake complete-item commit 或失敗不變；不靠 sleep 測排序。

DPK generic-password service 預設 `local.rivet.github.oauth.v1`，account 分別 configuration／credential。每次操作明指定 class、group、service、account、`kSecUseDataProtectionKeychain=true`、`kSecAttrSynchronizable=false`；copy 指定 matchLimitOne／returnData。Add 指定 AfterFirstUnlockThisDeviceOnly，無 access-control／presence／biometry／ACL。Update 僅完整 value Data；查無才 add，duplicate 才補一次完整 update；最後狀態直接分類，不再 retry。無 delete API。

Read errSecItemNotFound → nil；errSecAuthFailed／errSecUserCanceled → denied；errSecDecode 或成功但非 Data／無有效 payload → corrupt；其他非 success（含 interactionNotAllowed、missing entitlement、notAvailable）→ unavailable。Write 只有 success 為成功；authFailed／userCanceled → denied，decode → corrupt，其餘 → unavailable。原 status／underlying error 不出現在 public errors／logs。

## 3. Strict codec、替換與 provider

Private JSON DTO，不為公用 bundle 增加 Codable：
- configuration：schemaVersion=1、完整 clientID／clientSecret。
- credential：schemaVersion=1、clientID、accessToken、refreshToken、accessTokenExpiresAt、refreshTokenExpiresAt、tokenType、grantedScopes。
- schemaVersion 必須 Int 1；必要欄位型別正確；ID／secret／tokens 非空；tokenType 只接受 bearer；scope 為字串可空。日期為有限 JSON number millisecondsSince1970，換算 Date 後也有限；允許過期值。額外未知 keys 忽略，未知 version／缺值／null／型別錯／invalid value 整筆 corrupt。
- inspect 與 load 共用唯一 codec；不從壞資料擷取 ID。讀取 decode failure 為 corrupt，bound mismatch 為 identityMismatch；save 的無效 bundle 為 corrupt且零 Security write。

完整 payload 先成功 encode 才操作單一 item。整個 value 一次替換，不逐欄寫，不 delete、不 rollback 補舊值。失敗不回保存成功；fake 可證明失敗保留完整 A、成功換完整 B。真 Security commit／durability 不以 fake 測試宣稱已實證；兩 items 不具 transaction，configuration-first partial-save 不回滾已保存設定。

Adapter 不自行 refresh、retry lifecycle、建立 provider 或決定 UI repair。以既有 provider＋受控 fetcher／clock 驗證 restore／rotation；accepted remote rotation 保存失敗後同一 provider terminal persist、後續無額外 refresh／save。保留舊 item 不表示遠端舊 token 有效。

## 4. 文件與工具

一張 `storage-sequence`（Archify sequence）描述 inspect／bound restore、完整 rotation save，以及保存失敗回 provider stop；無新責任邊界圖，不新增登入全流程。作者繁中、預設無動畫、omit meta.locale，Viewer／HTML lang 英文 fallback。

Archify 2.16：showcase 九 checks、零 errors／warnings，validate→freeze→deliver；visual-check 四桌面尺寸及兩 theme，人工檢視實際截圖，未 Human 觀察維持 pending，不發布。PR Lens 0.11.0 只於真 diff／實 commit IDs 後在外部 scratch validate/render及讀 manifest；Graphify 0.9.73 每 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1，有既存圖才 bounded query並 source verify，無圖 targeted rg；不 build／refresh／install／改設定。兩輔助工具 fallback 不新增 gate，必要 Archify 不可用則文件交付仍 incomplete。

## 5. 2026-10-21 bounded live validation 契約

本節是最新 Human 授權；§1–§4 production API／codec／fake-only seam 保持。validation host 自行使用本 topic public adapter，不抄 codec，不讀寫 E006／E007 host，不實作 OAuth／網路／登入 UI。

### Host、source 與操作入口

獨立 CredentialStorageProbe Xcode App 連結 root local Swift package 的 GitHubIntegration product；macOS 15+、Swift 6、non-Sandbox、ENABLE_DEBUG_DYLIB=NO。runtime 以 SecTaskCreateFromSelf／CopyValueForEntitlement 核對唯一實際 keychain group 與 manifest；缺失或多義即停，不猜 group。async CLI 包成 .app，由 LaunchServices 在當前 GUI user 啟動；async main 只執行一個 manifest 指定 operation，寫私有 machine receipt 後終止。Debug／Rebuilt configs 分別由兩個 shared schemes 選定；Rebuilt 定義 CREDENTIAL_STORAGE_REBUILT，machine 記 compiledMarker。App 不提供任意 service／group／delete 搜尋入口。

Runner 的 prepare 只在 exclusive-create、0700 私有 owned runroot 複製自己的 project／Sources／Resources；local package reference 改為當次 feature worktree 的私有絕對位置。Repository 只留參數占位，不寫 raw path／Team／profile。UUID、source hashes、private group／service／App ID／選定 certificate／profile及固定安裝位置寫 immutable 私有 manifest；未選定的人類輸入只在 setup fresh ready 後取得並凍結，不以 prepare 猜值。

固定安裝位置為同一 owned root 的 current/CredentialStorageProbe.app。只允許 LaunchServices sequential open -W；不用 open -n 或直接執行 GUI binary。每段開始先確認上一 PID 終止、各新程序 UUID 不同；PID／原始位置僅留私有 proof，公開只布林。App 每次自行產生 process UUID；runner 與收據核對 phase/run身份。

Build proof 記真 xcodebuild command／source revision及 manifest hash在私有root；公開source hash與build結果布林。每次操作前核對 feature worktree adapter/configuration source SHA 與 frozen manifest，變動即停，不混不同 source round。真正 rebuild 必須由 Rebuilt scheme 實際 build，marker=true、binary SHA不同，並核 source／build receipt，不能只改 marker 收據、重簽或重包舊 binary。

Setup／rebuild 在 fresh ready 後才允許 Human 使用既有 Apple Development identity／profile。禁止 -allowProvisioningUpdates、inventory 他人 App／帳號資產、建立 certificate、trust／security 變更或付費。Agent 可在此已準備階段依精確 selected App 檢查簽章／embedded profile；完整原始輸出留私有，不印出身份值。兩版相同 App ID／private group／certificate／profile／DR、兩次操作時 profile／certificate有效、signature非adhoc，固定同安裝位置；setup無SecItem。raw profile／Team／ID／signing logs均不入repo。不存在有效前提則停止而非宣稱跨程序已測。

### Namespace、ownership 與最小 cleanup

service 固定 local.rivet.github.oauth.validation.<UUID>，唯一 account=credential，固定假 clientID與假六欄 A／B；全部六欄以預期 B 比較，tokenType兩者仍bearer。無 configuration item操作。App 不印 token／payload，public adapter只做load／save。

save-a 先依 strict UUID／service／group／account／DPK=true／sync=false 精確 read；須 absence成功證據，exists／讀取失敗即停，禁止覆寫。完成absence後，在save嘗試之前持久化 write-attempt ownership marker（namespace／來源manifest SHA）；即使save拋錯或程序中斷，也保留可能已寫入狀態，不能假裝無殘留。其後read／replace／cleanup只用同 frozen namespace。

測試App cleanup 是本topic唯一額外 SecItemDelete 入口：必須核 strict UUID、exact service／group／credential account、DPK=true／sync=false、同run immutable manifest、absence proof及先前 write-attempt marker。未owned／mismatch零delete。只刪精確單一item（包括class條件），不放寬query；刪後由production adapter load=nil驗證。success／notFound仍需read-absent proof才算清理通過。正式產品不加delete／logout API。

失敗／crash不自動移除owned root或ownership proof。Runner支援只針對此root的recover-cleanup入口，仍需當次cleanup ready與相同guards；不能建立新namespace冒充原run已清。只清manifest登記proven-owned App copies／project／DerivedData／暫存，export必要安全evidence後保留最小cleanup proof；Human既有Apple assets留存。若使用者停止或guard不成立，回報未清項目的有限狀態與私有root恢復交接，不遍歷／刪其他root或謊報完成。

### 階段與觀察

固定順序：setup（無SecItem）→save-a（absence/write/read）→read-a（fresh/read-only）→replace-b（full write/read）→read-b（fresh/read-only）→rebuild（無SecItem）→rebuilt-read-b（fresh/read-only）→cleanup。各段前當次fresh ready，後段只有取得該段實際promptCount／有限actions／wholeStageObserved、與machine receipt bytes SHA綁定後才繼續。initial ready／availability不等下一段ready。Setup／rebuild簽章授權提示另計；replace-b／cleanup記實際提示數，不虛構門檻。save-a≤1，read-a／read-b／rebuilt-read-b=0。

工具不能偵測系統提示；沒有回答／觀察不全時 promptCount=null、result=unknown，不當0，不前進依賴操作。private觀察可先等答，public human sidecar僅最終export時exclusive-create；若停止時export unknown則永久保留該歷史，不回填或覆寫。要更正收據先修manifest，不偷加revision leaf。不存在或未嘗試階段不造success；summary可列notExecuted／unknown。

### 公開投影與準備驗證

Private receipt 含run／phase／PID／private selectors等；export 僅 allowlist：schemaVersion、runUUID、phase、status（success/failure/unknown/notExecuted）、必要SHA256（source／binary／profile／certificate／AppID／group／DR／manifest／machine）、validity／sameIdentity／sameLocation／sameSource／differentBinary／freshProcess／previousTerminated／absenceConfirmed／writeAttempted／owned／deleted／readAbsent等布林、compiledMarker、六欄相等布林、有限failureKind、promptCount（非負整數或null）、wholeStageObserved、actions（none／allow／deny／authenticate／other）。準備fake schema測試禁止bool冒充prompt count、任意keys／自由文字／token／raw paths／ID／錯誤body export；收據完全bytes的SHA綁Human，原始stdout／buildlogs不入repo。

準備期只跑pure controls／fake child／cleanup seam／projection與unsignedbuild（CODE_SIGNING_ALLOWED=NO），零LaunchServices／signing／profile／SecItem；不得將unsignedbuild或控制測試當live。live前獨立Tester／Reviewer確認guards後才逐段啟動。無固定45分鐘窗，遇阻按當次bounded段停止並保留cleanup能力。


## 5.1 Automatic cached setup retry：候選準備契約

本節只覆蓋 §5 的簽章命令／setup單次收據及其依賴選擇；production、host Swift、templates、六欄／cleanup／逐段觀察等其餘契約不變。新流程尚未取得 Human execution adoption，任何原 ready 不適用；先實作／獨立驗證與審查可審查工具，才向 Human 問最終政策採用及全新 ready。

### 簽章候選與證據界線

保持 frozen private PBX（SHA256=`15ad13e1575ab7ccad88737efe28587a4022daefebbf00f6bf7bfe0c4177c4dd`）原 App-target Debug／Rebuilt Automatic；identity SHA256=`b2f84e2c45ff65ccef212f6d15abc4bbfd36ebec8d8e516f3f8cc2ebe652b550`。不修改 PBX／identity／run.json，也不更改 project/global 設定。兩 config 既有 AppID／Team 相符，group 由既有 build settings 展開吻合；profile specifier 為空。移除 build_selected command 的全域 CODE_SIGN_STYLE、DEVELOPMENT_TEAM、PRODUCT_BUNDLE_IDENTIFIER、CODE_SIGN_IDENTITY、PROVISIONING_PROFILE_SPECIFIER、RIVET_VALIDATION_GROUP 六項，其他既有 clean build／scheme／config／owned derived location／兩個 safety settings 維持。不得改用全域 Automatic override。

禁止任何形式的 allowProvisioningUpdates／allowProvisioningDeviceRegistration／authenticationKeyPath／authenticationKeyID／authenticationKeyIssuerID，以及建立／更新資產、UI retry、登入／下載資產或換 cert/profile 的 fallback。缺 cached assets、帳號／選擇／簽章錯誤即 unknown/build 停止。原 strict signature、certificate/profile效期與membership、唯一group／AppID／source/location guards不得放寬；簽章前驗原frozen選擇及profile可用前提，產物簽章後、install前逐項核 exact採用值。Certificate SHA256=`5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440`，profile SHA256=`adae3b48b74bd053391083b3312c135e43efdd6670f58acd1172438cb52cb55c`，bootstrap canonical DR（strip後）SHA256=`85c3e82e98159c68fa1ff3888339c7dea3795b0f962a7844f2f0aaabf41a17a2`；原 staging canonical receipt保留。DR不只比較兩次新產物彼此相同，還必須符合此既有baseline。新產物全部匹配才可安裝原 current 固定位置；setup不launch／SecItem。

本機 xcodebuild -help 明示 allowProvisioningUpdates 授予 Developer website 通訊並讓 Automatic 建立／更新 profiles/AppIDs/certs；[Apple WWDC21](https://developer.apple.com/videos/play/wwdc2021/10204/)亦將它說明為網站通訊權限。因此此候選是「不授予 portal provisioning 更新」；不是網路隔離，也不保證所有本機cache／資產零變更，事後exact比對不能充當事前零副作用保證。[Apple build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference)說明 Automatic 管理簽章資產、profile specifier指定profile。cached Automatic真build仍未驗。若 Human 要求本機所有Appleassets絕對不變而不接受此證據界線，執行保持停止，不以ready補造技術保證。

### 唯一 retry、storage 與不可改寫歷史

新增唯一 `retry-setup --root --ready-file --policy-adoption-file` 入口，不接受built-app／identity-file／任意attempt字串或自動重試。只准本run，在原 setup machine=unknown/build且原Human完整觀察已綁定後、無成功setupproof／currentApp／write-attempt／任何後續phase或未settled child、未finalized時使用；重新驗ownedroot／parents／sourcepins／immutableidentity與PBX及baseline。原已消耗ready及任何舊ready均拒絕；新ready必須是runUUID／phase=setup／ready=true／新UUID。私有輸入固定為 `private/setup-retry-1-policy.json` 與 `private/setup-retry-1-fresh-ready.json`，均exclusive建立、owned／無symlink；原ready UUID（包括未消耗的初次manual輸入）及所有已消耗UUID均拒絕。Policy proof是Human原意的私有有限輸入：schemaVersion=1、runUUID、policy=automaticCachedNoPortalUpdates、attempt=retry-1、adopted=true，明示此政策而不是單純profile採用。

只可exclusive建立 `private/setup-retry-1/attempt.json`，schemaVersion=1；固定runUUID／phase=setup／attempt=retry-1，加 originalMachineSHA256／originalHumanSHA256／manifestSHA256／identitySHA256／projectSHA256／runnerSHA256／policySHA256／bootstrapDRSHA256／readyUUID。原machineSHA固定899ed35b0279c730e6c39bb1c4bc927612f7e6c81897b2d3062ff13a5db46d19；原HumanSHA固定6229797bb5271fa44158be28b63ddf77a46794c154f240bfef2d43e238056154。Runner SHA須等本次獨立Tester／Reviewer接受後的freeze，不得先猜或接受任意呼叫端hash；政策proof bytes亦須綁定。attempt／ready消耗順序須先完成所有preflight；`private/setup-retry-1/`須exclusive mkdir0700；directory或attempt任一存在即已佔唯一額度，不因crash/失敗刪除重用。

所有 retry setup ready／build-request／selected-profile／build stdout/stderr／verify／details／entitlements／embedded-profile／DR／canonical-DR／certificate extraction及validity／machine／public-machine／human／build-proof，使用同套原setup固定leaf名但storage改為 `private/setup-retry-1/`，不寫原 `private/setup.*`。只新增私有attempt與有限policy／ready輸入；不重新bootstrap或freezeidentity，不重建runmanifest。共用build helper以storage參數寫整套proof，不把原log rename或覆寫。合法新ready消耗後的任何錯誤仍寫immutable unknown machine／binding供當次Human實際觀察；停止後續，不吞錯成功。此入口無第三次retry、無setup recovery fallback。

新增 observe 的有限 selector `--setup-attempt retry-1`，僅phase=setup合法；無selector維持原setup。Retry human照原v1欄位綁該次public bytes SHA，觀察未知不補0。公開新增兩leaf名，payload仍schemaVersion=1／phase=setup、原allowlist不擴張；其attempt身分由固定leaf及summary表達。原setup machine/public binding/Human與manual觀察原bytes全部保留。

### Dependency、rebuild、export

共用activation／quota／effective-setup resolver使用同一presence判準：retry directory與attempt皆不存在才讀原setup；directory或attempt任一存在即耗用唯一額度並只選retry。Directory-only（mkdir後、attempt前crash）、partial或缺attempt／receipt／Human／buildproof時，retry outcome=unknown、effectiveSetupAttempt=null，禁止fallback initial、save-a解鎖或任何第三次嘗試，保留目錄及其他恢復proof；完整receipt仍依classify維持unknown／failure／success。原run/profile/identity採用不替代新policy與freshready。全guards及Human完整觀察成功後，save-a/runtime／rebuild只使用retry setup build-proof；rebuild再核同exact baseline／有效期／真正不同binary與compiledmarker。不再硬讀缺失的原setup.build-proof。其他phase freshready／ownership契約不變。

run-summary尚未建立，改schemaVersion=2，保留runUUID／status／phases；新增固定setupAttempts物件（initial、retry-1各為notExecuted/unknown/failure/success）及effectiveSetupAttempt（initial/retry-1/null）。phases.setup反映同一directory-or-attempt resolver：retry directory與attempt皆不存在時，setupAttempts.retry-1=notExecuted；任一存在而directory-only／partial／缺receipt時，setupAttempts.retry-1=unknown、phases.setup=unknown、effectiveSetupAttempt=null，絕不借initial填success。effectiveSetupAttempt只有所選該次classify成功且buildproof有效才填，否則null。原initial outcome永維持原classify，不因retry成功改寫。Top-level status採保守歷史聚合：任一已嘗試結果failure為failure，否則任一已嘗試unknown或有效流程未完成為unknown；全部已嘗試與有效phases均success才success。因此retry成功可解鎖save-a，但不抹除原unknown歷史；必要時summary仍unknown，文件可分述有效後續驗證。summary仍final時exclusive-create，不加summary revisions。

Export同時保持原setup兩leaf及retry兩leaf各自exact binding；final時缺Human仍照原規則投影unknown。新增準備fixtures必走真entrypoints：移除六override且保留targetsettings、禁止權限flags、cached錯誤／identityDR漂移不install；新ready單次／第三次與wrongrun拒絕、mkdir後attempt前crash及partial／缺receipt仍佔額度、retryunknown／effective=null／依賴blocked／不fallback、原bytes不變；observe/export雙歷史、unknown不前進、retry成功採正確baseline、rebuild不讀原missingproof。全部mock build/signing，不執行真簽章或live；Swift未改不重build兩config。


## 5.2 最小可診斷工具補修（準備契約；非live授權）

### 固定保留與執行界線

只在本topic現有validation四個leaves補修。原run／manifest／identity／privatePBX／copiedsources／current App／初次失敗與retry成功及save-a unknown／Human bytes全部唯讀，不替換／重簽原App、不更新原pins、不增加setup/save重試。只準備non-live：允許隔離unsigned編譯修改後同一main.swift並執行明確fake-only入口；禁止實際xcodebuild、signedhostbuild／launch／DPK、assets／DevTools/TCC/trust/security變更、新真人root或ready。

### 可信bootstrap、獨立收據與最小fallback

新增host有限purpose：`diagnostic-only`與`namespace-read-only`；不能是save／replace／cleanup/retry。Runner未來只在獨立0700 owned scratch `rivet-credential-storage-diagnostic-<diagnosticUUID>`使用，不是新credential run／service；本準備期不建立真人scratch。原root只能作固定legacyRunUUID的唯讀來源。新host將在該scratch的固定 `app/CredentialStorageProbe.app`，不得替換舊current；實際新build/sign的source／binary／identity證據必須獨立freeze，須未來該段freshready後才可產生。

Bootstrap由兩個私有環境值 `RIVET_DIAGNOSTIC_MANIFEST`／`RIVET_DIAGNOSTIC_SHA256`提供，不依賴待診斷argv／原request解析成功。Manifest固定leaf `diagnostic.json`，schemaVersion=1，精確fields：diagnosticUUID、legacyRunUUID、purpose、legacyRoot、expectedApp、sourceHashes、binarySHA256、legacyManifestSHA256、legacyIdentitySHA256、legacySaveMachineSHA256、legacySaveHumanSHA256；SHA作外部trusted-operator交接binding，不宣稱抵抗同UID偽造或自己核准自己。purpose只有上述兩值；legacyRunUUID固定本run、legacy hashes綁原已保留bytes，expectedApp固定同scratch/app位置，sourceHashes只新工具本次freeze來源。原paths／IDs只在私有manifest，不入收據。

在接觸任何輸出前先驗manifest完整schema／SHA、lowercase UUIDv4、canonical0700自身UID root與每個parent無symlink、manifest/expectedApp/來源皆精確owned位置、原root/hashes與固定run一致；不信任任意receiptpath、service/group、operation或相對逸出。只在成功bootstrap後選固定輸出：diagnostic-only→`diagnostic.machine.json`，namespace-read-only→`namespace.machine.json`，exclusive0600／fsync、不得覆寫，既有leaf或多義立即停。Bootstrap本身失敗／App不能啟動／無可信輸出時，不寫任何路徑；runner只保留有限unknown，不承諾每種錯誤必有Appreceipt，也不製造替代App成功收據。

共用早期guards的實際Swift控制路徑，將stage固定為bootstrap／args／request／root／source／identity／bundle／entitlement／completed；receipt在可信bootstrap之後、原args/request/validate等可throw工作之前取得安全destination。Catch只記stage及finite failureKind（input／guard／unavailable／other），不序列化error、argv、原始bytes／路徑／IDs／credentials。Receipt schemaVersion=1，僅diagnosticUUID、legacyRunUUID、purpose、stage、status（success/failure/unknown）、failureKind、manifestSHA256／sourceSHA256／binarySHA256、有限guard布林；不混用舊phase=save-a或原save-a.app.json。新diagnostic copy驗其新expectedApp／sourcefreeze；原root／identity／原manifest固定App對照另作明確legacy只讀檢查，不暗改舊安裝期望，也不把不同binary/context診斷當原Writer的實際失敗重現。

`diagnostic-only`到completed就結束，不能建立store或呼叫四個SecItem入口；Bundle／SecTask只用於本診斷host的有限guard結果。即使全guards通過也不進原perform/save。未知外部輸入拒絕且不寫他處。私有Human sidecar固定 `diagnostic.human.json`／`namespace.human.json`，沿原有限count/actions/whole與exact machine bytes SHA綁定；future各purpose另有固定 `diagnostic.ready.json`／`namespace.ready.json`，不得沿用原任何ready。未答／觀察不足維持unknown。

最小防重放補充（待獨立delta審查）：私有固定新增 `diagnostic.consumed-ready.json`／`namespace.consumed-ready.json`，依purpose二選一；不得新增repository leaf。完成全部bootstrap、mode／ready／來源及執行前guard後，必須在LaunchServices呼叫之前exclusive0600建立該purpose標記並fsync；內容只schemaVersion=1、diagnosticUUID、purpose、readyUUID、readySHA256（原ready bytes），UUID／SHA只留private、不投影公開。標記任何存在（含partial、內容無法解析、曾launch失敗或沒有Appreceipt）即永久耗用該purpose本次診斷額度並拒絕再次launch；不得刪除／覆寫以重用ready。未寫成標記不得launch，write/fsync失敗即停並保留partial。此標記不是Appreceipt、成功證據或清理ownership；不製造原save-a收據，也不授自動重試。

### 未來exact namespace唯讀與清理停點

`namespace-read-only`須未來獨立Humanfreshready及新signedhost完整審查／有效原採用identity前提。只從固定legacy manifest/identity取得原UUIDservice、唯一group、credential account、假clientID，public adapter只load一次；flags維持DPK=true／sync=false，不允許caller覆寫query，不呼叫config／save／delete。Receipt只記state（absent/present/denied/unavailable/corrupt/identityMismatch/unknown），不輸出bundle／tokens。此模式和diagnostic-only分支／權限分開，fake測試須證diagnostic零load、readonly最多一次load且零write/delete。

Absent只證當下nil，不能回填原absence/write-attempt或將原unknown／unknownchild改成安全未寫。Present／拒絕／error立即停並保留；本補修沒有新delete／reset／cleanup授權，也不因無PID或資料目前空而放行舊files-onlycleanup。原root及Appleassets不清理；若未來不能以原strictownership安全恢復，停交Human，不自動新run或要求移除安全保護。

### non-live驗收／執行停點

必須先實際Swift fake-only入口測共用bootstrap／早期guard／receipt控制路徑：各stage throw、malformedargv／request／identity、Bundle/entitlement拒絕、wrongpurpose／UUID／SHA／symlink／escape／preexistingreceipt、bootstrap前零檔案、bootstrap後finite失敗收據、diagnostic零Security/store、readonlyfake absent/present/error及零write/delete。Python驗真runnerdispatch／投影／exclusive／SHA觀察及原55regression。不能只mock Python或沿用舊main binary：用一般compile scratch以swiftc隔離unsigned編譯新main（僅編譯並執行fake-only CLI，不launch App／sign，禁止xcodebuild／signed/live build與舊run操作），執行exact fake-only入口，必核新source/binary hash與必要case IDs，舊12checks仍保留。若本階段禁止xcodebuild，採swiftc隔離compile，不為方便觸發xcodebuild／package更新；缺既有module/object依賴即報真blocker，不能以舊binary過關。

獨立Plan-Reviewer→Implementer red/green→Tester→Reviewer；之後Human才另採當次新host build/sign scope並freshready，再獨立diagnostic launch freshready及actual觀察，再另問namespace-read-only。現在僅準備，不建立上述真人scratch／manifest／receipts／ready，不自動執行新程序；任何新的securitypermission／assets需求即停。新診斷不宣稱修復原save-a、DPK保存或原提示驗收。


### D05 新host build/sign具體caller清單（候選，待獨立審查及Human當段ready）

本段只補可審準備，沒有執行任何下列操作。D04 approved僅為工具候選；D05必須先由獨立Reviewer審本清單，再由Human明確採用「新診斷host、原已採cached Automatic／noPortal、只build/sign不Run」及freshready。不重用setup/save-a/diagnostic ready，不呼叫 `prepare`、`build_selected`、`stage` 或任何App入口；不是第三次setup或新credential run。新assets／安全權限／付費需求即停；沒有 `-allowProvisioningUpdates` 不保證所有本機cache零變更。

**確定輸入及私有位置。** 以下為執行時trusted operator在記憶體指定的變數，不能從任意caller提供的JSON接受新路徑：`R`為本feature worktree、`L`為固定原run root、`U`為本次新lowercase UUIDv4、`N`為private temp parent下精確 `rivet-credential-storage-diagnostic-<U>`、`P=N/proof`。原root、identity/profile、原PBX/source/current全程唯讀。`I=load(L/identity.json)`、`F=Path(I['profilePath'])`；F必為原identity固定、原ownedroot內既存regular非symlink檔，不inventory其他profiles。新root必absent、canonical、自身UID、parents無symlink，exclusive mkdir0700；所有新目錄0700、私有檔0600，existing/partial任一leaf即停，無覆寫或重試。

本段固定新增private leaves：`build.ready.json`、`build.consumed-ready.json`、`build-input.json`、`build.machine.json`、`build.human.json`；raw helper logs／certificate／profile解碼只在 `proof/`，source／project／derived-debug／app為本次自有目錄。不是repo leaves；不得寫入原run或製造App machine。原§5.2的diagnostic／namespace ready與consumed仍各自獨立。

**逐條caller操作；順序及條件不可略過。** 使用D04 approved的凍結runner模組 `h`（由R的既有runner載入；import不執行CLI）；外部Dispatcher/Tester先比actual四葉與D03/D04 freeze，不能由h自稱核准。下列呼叫均沿其現有signature，未列的新script／CLI不在此ready內：

1. Human答覆當段scope及freshready後才建立N／P；`h.exclusive_json(N/'build.ready.json', {'runUUID':U,'phase':'host-build-sign','ready':True,'readyUUID':<新UUIDv4>})`。以 `h.validate_ready(h.load(N/'build.ready.json'),U,'host-build-sign')` 驗證。開始任何copy／metadata probe／build前，`h.exclusive_json(N/'build.consumed-ready.json', {'schemaVersion':1,'diagnosticUUID':U,'phase':'host-build-sign','readyUUID':<同readyUUID>,'readySHA256':h.digest((N/'build.ready.json').read_bytes())})`；fsync已由helper實作。既有／partial耗用額度，失敗保留，不能刪除再做。若可信root／輸出未成立，僅在原live-validation.md記未知限制，不向任意位置寫receipt。
2. 以 `h.private_owned(L, path)` 及SHA讀原 `run.json`、`identity.json`、`private/save-a.public-machine.json`、`private/save-a.human.json`、`project/<PROJECT_FILES[0]>`，逐項比原帳本已確認bytes：manifest `7223cc87…90b0c`、identity `b2f84e2c…b550`、save machine `2d1ac7df…83c60`、save Human `011039ba…968fc`、Automatic PBX `15ad13e1…c4dd`（完整SHA以本spec前文／既有runner RETRY_PINS及原step收據為準，不以prefix驗證）。確認PBX App target仍Automatic、local package仍精確R；**不改PBX bytes／signing設定／identity**。`h.verify_sources(h.load(L/'run.json')['sources'])` 核原production/package pins；缺key或不符即停，不補造。四個新工具來源逐項比D02 finalfreeze與D03/D04九葉審查；其餘五模板仍比原freeze，private PBX則只比上述已採Automatic版本。
3. `h.profile_data(F,P,'selected-profile')` 只讀此確切已採profile；使用與既有 `build_selected` 同一檢查：TeamIdentifier=[I.team]、application-identifier=I.team+'.'+I.appID、allowed-group可涵蓋I.group、DeveloperCertificates包含I.certificateSHA1、creation/expiry有效。profile bytes SHA必為已採 `adae3b48…cb55c`，不得改選或建立profile。certificate精確性與有效期仍須後續 `inspect_selected` 驗證；目前1個identity的count不代替此證據。
4. 建立下面各destination的0700 parents，輸入必regular／無symlink，輸出必absent。四個 `DIAGNOSTIC_SOURCES`，逐一以 `h.private_command(['/usr/bin/ditto',str(R/h.TEMPLATE/leaf),str(N/'source'/leaf)],P,'copy-source-'+str(index))` 複製；`h.PROJECT_FILES` 中除Sources/main.swift外五leaf，逐一同樣ditto由 `L/'project'/leaf` 到 `N/'project'/leaf`，basename固定 `copy-project-<index>`。新main另用ditto從 `N/source/Sources/main.swift` 到 `N/project/Sources/main.swift`、basename `copy-main`。copy前後比每個檔bytesSHA；新source/README/runner/tests不作App資源。不得複製整個舊project／current或改localpackage路徑。source私有檔設0600不改bytes。`build-input.json`以exclusive_json記schemaVersion1、U、readySHA、原五個SHA、profileSHA、九葉source/template SHA table、原production/package SHA table、實際runnerSHA、exact command（下列）、固定expectedApp與PBX SHA；raw paths只private。
5. 唯一建置命令如下，以 `h.private_command(command,P,'clean-build')` 執行；argv由已驗證N組成，不展開未驗證shell文字：

```text
/usr/bin/xcodebuild -project <N>/project/CredentialStorageProbe.xcodeproj
  -scheme CredentialStorageProbe -configuration Debug
  -derivedDataPath <N>/derived-debug
  -destination platform=macOS,arch=arm64
  clean build ENABLE_DEBUG_DYLIB=NO ENABLE_APP_SANDBOX=NO
```

不加全域 `CODE_SIGN_STYLE`／`DEVELOPMENT_TEAM`／`CODE_SIGN_IDENTITY`／`PROVISIONING_PROFILE_SPECIFIER`／`PROVISIONING_PROFILE`／`RIVET_VALIDATION_GROUP`，不加provisioning/device-registration/authentication-key flags，不用Xcode Run／LaunchServices。僅原已採Automatic target及cached assets；缺cache／build非零即停，不修環境或再次build。本機架構須arm64，否則本清單不適用。raw stdout/stderr只在P，不能貼出錯誤payload。
6. `C=N/'derived-debug/Build/Products/Debug/CredentialStorageProbe.app'`，`A=N/'app/CredentialStorageProbe.app'`。C的ancestors須owned無symlink、C確在N內、A須absent。`before=h.inspect_selected(C,F,I,P,'candidate')`；必validity、同已採profile／certificate／bootstrap DR完整SHA，AppID/group雜湊與I一致。再核所有source/package／PBX／identity／原五SHA未變，新main編譯來源及source manifest完整、binarySHA與原current不同。先不install，任一不符即停。
7. 建立N/app0700後，`h.private_command(['/usr/bin/ditto',str(C),str(A)],P,'copy-app')`；`after=h.inspect_selected(A,F,I,P,'installed')`。before==after（涵蓋binary/profile/cert/DR/AppID/group/validity）；regular檔相對path→SHA及symlink相對path→linktarget的signed tree table須相等，拒絕逃出App的link，不改／清除OS provenance metadata。重新核步驟2/4全部pins，位置只能A；舊current完全不碰。此處沒有App launch或store呼叫。
8. 以上全通才用 `h.exclusive_json(N/'diagnostic.json', value)` 產既有§5.2精確v1 manifest：U、固定legacy UUID／L、purpose=diagnostic-only、expectedApp=str(A)、四個N/source精確sourceHashes、after.binarySHA256及原manifest/identity/save-machine/save-Human四SHA。`h.diagnostic_context(N/'diagnostic.json',<實際bytesSHA>)` 必通；只讀bootstrap檢查，不執行App。不建立D06/D07 ready、不改purpose、不造diagnostic.machine.json。

**D05有限獨立收據與Human binding。** 在可信N established後，任何步驟失敗立即停止；用 `h.exclusive_json` 一次性寫 `build.machine.json`，精確keys為schemaVersion=1、diagnosticUUID、purpose='host-build-sign'、status(success/unknown)、stage(input/copy/profile/build/signature/install/manifest/completed)、failureKind(null/guard/build/signature/other)、inputSHA256（未建立input時null）、sourceSHA256（未完成freeze時null）、binarySHA256（未驗證時null）、signatureSHA256（未完成exact檢查時null）、locationSHA256（未完成檢查時null）、buildVerified(bool)。成功僅completed、failureKind=null及各SHA非null；sourceSHA為sorted source table的JSON bytesSHA，signatureSHA為before/after七欄inspection sorted JSON bytesSHA（JSON用sort_keys=True,separators=(',',':'),ensure_ascii=True），locationSHA為str(A).encode()的SHA。不輸出raw errors／private IDs／paths／UUID／readySHA；公開只有限status/stage、必要SHA及checks，UUID只private。失敗不把原unknown改成功；receipt本身寫失敗也停止，不覆寫修復。

Human須回本段全程whole、實際promptCount、actions（none/allow/deny/authenticate/other），不能推定0。Tester組 `{runUUID:U, phase:'host-build-sign', machineSHA256:<build.machine原bytesSHA>, promptCount:<實際或null>, actions:[…], wholeStageObserved:<實答>}`，以 `h.validate_observation(value,U,'host-build-sign',machineSHA)` 驗後 `h.exclusive_json(N/'build.human.json',value)`；只用此generic validator，不用限定App-purpose的diagnostic-observe／public_human，不造Appreceipt。whole未答／count=null維持unknown，不交D06。所有新proof保留，沒有cleanup／retry；未成功或新permission/assets需求即Human停點。成功也僅為新host build/sign freeze，不是DPK或UX驗收；Tester只在既有live-validation.md追加實際有限摘要。D06／D07各自再審前提、問當段freshready，未預授。


#### RF-D05-PLAN-01：完整bounded inline caller（只供靜態審查）

以下完整文字優先於上述需要caller控制的自然語言。它不是新repository程式；Reviewer批准後才可原文抽出至普通私有暫存檔並由外部trusted operator逐項核其SHA。**現在只允許ast.parse／compile，不得exec、import或執行本段。** 未取得D05具體scope採用及freshready，不得執行build分支。外部核獨立approved freeze是workflow責任；內文SHA只核實際bytes，不能自己核准自己。

未來build的唯一位置參數為 `<本feature絕對canonical路徑> <新diagnosticUUID> build <新readyUUID> yes`；yes只可由執行者在Human實答本段freshready後傳入。observe則為 `<同feature路徑> <同diagnosticUUID> observe <當時觀察的build.machine完整SHA> <實際count或unknown> <逗號分隔有限actions，無動作用none> <實答whole yes或no>`。無實際答覆不執行observe；傳入yes不構成工具自行取得Human授權。路徑只留private，不在公開證據列出。沒有通用action、retry、cleanup或App launch功能。

```python
# D05-CALLER-BEGIN
import datetime as dt
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import re
import stat
import sys
import uuid

sys.dont_write_bytecode = True
os.umask(0o077)
RUN = "8ad8fb3b-51d9-4162-98fb-067521a37b4e"
TEMPLATE = "validation/github-oauth-credential-persistence"
TOOLS = {
    "Sources/main.swift": "d65f818dfbfe92726cc3e1928b161a8b783b3f84af2b3befceb5897f1223f618",
    "scripts/credential_storage_live.py": "a2834ede6d9c90b418e20c3723210c54530fe6a18ee5308edf9cb0f9a09c6907",
    "Tests/test_live_protocol.py": "1e016f12fcfc99f9f18f3ee36eb535d8dca3a902d893da9b3d9941c8cd046f53",
    "README.md": "8a14aa67d05b6036b3e301ca03b938015814b210a5e80d511b0c3fb22e0f54c8",
}
PROJECT = "CredentialStorageProbe.xcodeproj/project.pbxproj"
TEMPLATES = {
    PROJECT: "2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece",
    "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme": "0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604",
    "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme": "a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800",
    "Resources/Info.plist": "b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d",
    "Resources/CredentialStorageProbe.entitlements": "27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0",
}
LEGACY = {
    "run.json": "7223cc870fb02861c31b73aa5b4866c10dda5d3c96620f65d305b62669390b0c",
    "identity.json": "b2f84e2c45ff65ccef212f6d15abc4bbfd36ebec8d8e516f3f8cc2ebe652b550",
    "private/save-a.public-machine.json": "2d1ac7df2f6265abaecf797ece11f3ce159eb103682d76be254db3cadd583c60",
    "private/save-a.human.json": "011039badb381ee2f188a403e0068e84d31f3299db17bd7326cb6f13079968fc",
    "project/" + PROJECT: "15ad13e1575ab7ccad88737efe28587a4022daefebbf00f6bf7bfe0c4177c4dd",
}
PROFILE = "adae3b48b74bd053391083b3312c135e43efdd6670f58acd1172438cb52cb55c"
CERT = "5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440"
DR = "85c3e82e98159c68fa1ff3888339c7dea3795b0f962a7844f2f0aaabf41a17a2"
INSPECTION = {"validity", "profileSHA256", "certificateSHA256", "appIDSHA256",
              "groupSHA256", "drSHA256", "binarySHA256"}
STAGES = {"input", "copy", "profile", "build", "signature", "install", "manifest", "completed"}
MACHINE_KEYS = {"schemaVersion", "diagnosticUUID", "purpose", "status", "stage", "failureKind",
                "inputSHA256", "sourceSHA256", "binarySHA256", "signatureSHA256",
                "locationSHA256", "buildVerified"}


def need(value):
    if not value:
        raise ValueError("guard")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=True, allow_nan=False).encode()


def uid4(value):
    parsed = uuid.UUID(value)
    need(str(parsed) == value and parsed.version == 4)


def ancestors(path):
    need(path.is_absolute() and ".." not in path.parts)
    need(path == path.resolve(strict=True))
    for part in [path, *path.parents]:
        need(not stat.S_ISLNK(part.lstat().st_mode))


def regular(path):
    ancestors(path)
    info = path.lstat()
    need(stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid())
    return path.read_bytes()


def flush_dir(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def new_dir(path):
    ancestors(path.parent)
    need(not os.path.lexists(path))
    path.mkdir(mode=0o700)
    info = path.lstat()
    need(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid()
         and stat.S_IMODE(info.st_mode) == 0o700)
    flush_dir(path.parent)


def parents_in(root, parent):
    need(parent.is_relative_to(root))
    cursor = root
    for component in parent.relative_to(root).parts:
        cursor /= component
        if not os.path.lexists(cursor):
            new_dir(cursor)
        ancestors(cursor)
        info = cursor.stat()
        need(info.st_uid == os.getuid() and stat.S_ISDIR(info.st_mode)
             and stat.S_IMODE(info.st_mode) == 0o700)


def tree(app):
    ancestors(app)
    table = {}

    def walk_error(error):
        raise ValueError("guard")

    for folder, directories, files in os.walk(app, followlinks=False, onerror=walk_error):
        for name in sorted(directories + files):
            path = Path(folder) / name
            info = path.lstat()
            need(info.st_uid == os.getuid())
            relative = str(path.relative_to(app))
            if stat.S_ISLNK(info.st_mode):
                target = path.resolve(strict=True)
                need(target.is_relative_to(app) and target != app)
                table[relative] = ["link", os.readlink(path)]
            elif stat.S_ISREG(info.st_mode):
                table[relative] = ["file", stat.S_IMODE(info.st_mode), sha(path.read_bytes())]
            elif stat.S_ISDIR(info.st_mode):
                table[relative] = ["directory", stat.S_IMODE(info.st_mode)]
            else:
                need(False)
    return table


def main():
    args = sys.argv[1:]
    need(len(args) in (5, 7))
    R, U, action = Path(args[0]), args[1], args[2]
    uid4(U)
    ancestors(R)
    need(R.name == "agent-20261020-github-oauth-credential-persistence")
    need(R.stat().st_uid == os.getuid())
    L = Path("/private/tmp") / ("rivet-credential-storage-" + RUN)
    N = Path("/private/tmp") / ("rivet-credential-storage-diagnostic-" + U)
    A = N / "app/CredentialStorageProbe.app"
    for leaf, pin in {**TOOLS, **TEMPLATES}.items():
        need(sha(regular(R / TEMPLATE / leaf)) == pin)
    runner = R / TEMPLATE / "scripts/credential_storage_live.py"
    module = importlib.util.spec_from_file_location("frozen_d05_runner", runner)
    need(module is not None and module.loader is not None)
    h = importlib.util.module_from_spec(module)
    module.loader.exec_module(h)
    h.owned_root(L, RUN)

    def write(path, value):
        result = h.exclusive_json(path, value)
        flush_dir(path.parent)
        return result

    def frozen():
        for leaf, pin in {**TOOLS, **TEMPLATES}.items():
            need(sha(regular(R / TEMPLATE / leaf)) == pin)
        for leaf, pin in LEGACY.items():
            h.private_owned(L, L / leaf)
            need(sha(regular(L / leaf)) == pin)
        run = h.load(L / "run.json")
        need(run["runUUID"] == RUN and run["repo"] == str(R)
             and run["fixedApp"] == str(L / "current/CredentialStorageProbe.app"))
        need(set(run["sources"]) == {str(R / name) for name in h.SOURCE_FILES})
        for name, pin in run["sources"].items():
            need(sha(regular(Path(name))) == pin)
        for leaf in TEMPLATES:
            if leaf != PROJECT:
                need(sha(regular(L / "project" / leaf)) == TEMPLATES[leaf])
        identity = h.load(L / "identity.json")
        need(set(identity) == {"team", "appID", "group", "certificateSHA1", "profilePath", "projectSHA256"})
        need(identity["projectSHA256"] == LEGACY["project/" + PROJECT])
        need(all(isinstance(identity[key], str) and re.fullmatch(r"[A-Za-z0-9.-]+", identity[key])
                 for key in ("team", "appID", "group")))
        need(identity["group"].startswith(identity["team"] + "."))
        need(re.fullmatch(r"[0-9A-Fa-f]{40}", identity["certificateSHA1"]) is not None)
        selected = Path(identity["profilePath"])
        need(selected.is_relative_to(L))
        h.private_owned(L, selected)
        need(sha(regular(selected)) == PROFILE)
        return run, identity, selected

    if action == "observe":
        need(len(args) == 7)
        ancestors(N)
        need(N.stat().st_uid == os.getuid() and stat.S_IMODE(N.stat().st_mode) == 0o700)
        machine_path = N / "build.machine.json"
        machine_sha = sha(regular(machine_path))
        need(machine_sha == args[3] and re.fullmatch(r"[0-9a-f]{64}", args[3]))
        machine = h.load(machine_path)
        need(set(machine) == MACHINE_KEYS and machine["schemaVersion"] == 1
             and machine["diagnosticUUID"] == U and machine["purpose"] == "host-build-sign"
             and machine["stage"] in STAGES and machine["status"] in ("success", "unknown"))
        need(args[6] in ("yes", "no"))
        count = None if args[4] == "unknown" else int(args[4])
        human = {"runUUID": U, "phase": "host-build-sign", "machineSHA256": machine_sha,
                 "promptCount": count, "actions": args[5].split(","),
                 "wholeStageObserved": args[6] == "yes"}
        h.validate_observation(human, U, "host-build-sign", machine_sha)
        write(N / "build.human.json", human)
        complete = machine["status"] == "success" and human["wholeStageObserved"] and count is not None
        print(json.dumps({"status": "success" if complete else "unknown", "machineSHA256": machine_sha}))
        return 0 if complete else 1

    need(action == "build" and len(args) == 5 and args[4] == "yes")
    uid4(args[3])
    need(platform.machine() == "arm64")
    ancestors(N.parent)
    need(not os.path.lexists(N))
    new_dir(N)
    stage = "input"
    status, failure = "unknown", "guard"
    input_sha = source_sha = binary_sha = signature_sha = location_sha = None
    P = N / "proof"
    try:
        new_dir(P)
        ready = {"runUUID": U, "phase": "host-build-sign", "ready": True, "readyUUID": args[3]}
        ready_sha = write(N / "build.ready.json", ready)
        h.validate_ready(h.load(N / "build.ready.json"), U, "host-build-sign")
        write(N / "build.consumed-ready.json", {"schemaVersion": 1, "diagnosticUUID": U,
              "phase": "host-build-sign", "readyUUID": args[3], "readySHA256": ready_sha})
        run, identity, selected = frozen()
        sources = {str(N / "source" / leaf): pin for leaf, pin in TOOLS.items()}
        source_sha = sha(canonical(sources))
        command = ["/usr/bin/xcodebuild", "-project", str(N / "project/CredentialStorageProbe.xcodeproj"),
                   "-scheme", "CredentialStorageProbe", "-configuration", "Debug",
                   "-derivedDataPath", str(N / "derived-debug"), "-destination", "platform=macOS,arch=arm64",
                   "clean", "build", "ENABLE_DEBUG_DYLIB=NO", "ENABLE_APP_SANDBOX=NO"]
        input_sha = write(N / "build-input.json", {"schemaVersion": 1, "diagnosticUUID": U,
                          "readySHA256": ready_sha, "legacyHashes": LEGACY, "profileSHA256": PROFILE,
                          "toolHashes": TOOLS, "templateHashes": TEMPLATES, "productionHashes": run["sources"],
                          "runnerSHA256": TOOLS["scripts/credential_storage_live.py"], "command": command,
                          "expectedApp": str(A), "projectSHA256": LEGACY["project/" + PROJECT]})
        stage = "copy"
        pairs = [(R / TEMPLATE / leaf, N / "source" / leaf, pin) for leaf, pin in TOOLS.items()]
        pairs += [(L / "project" / leaf, N / "project" / leaf,
                   LEGACY["project/" + PROJECT] if leaf == PROJECT else pin) for leaf, pin in TEMPLATES.items()]
        pairs += [(N / "source/Sources/main.swift", N / "project/Sources/main.swift", TOOLS["Sources/main.swift"])]
        for index, (source, target, pin) in enumerate(pairs):
            need(sha(regular(source)) == pin)
            parents_in(N, target.parent)
            need(not os.path.lexists(target))
            h.private_command(["/usr/bin/ditto", str(source), str(target)], P, "copy-" + str(index))
            need(sha(regular(target)) == pin)
            os.chmod(target, 0o600)
            with target.open("rb") as stream:
                os.fsync(stream.fileno())
            flush_dir(target.parent)
        copied = {str(target): pin for _, target, pin in pairs}

        def check_copy():
            frozen()
            for name, pin in copied.items():
                need(sha(regular(Path(name))) == pin)

        check_copy()
        stage = "profile"
        profile = h.profile_data(selected, P, "selected-profile")
        need(profile.get("TeamIdentifier") == [identity["team"]])
        entitlements = profile.get("Entitlements", {})
        need(entitlements.get("com.apple.application-identifier", entitlements.get("application-identifier"))
             == identity["team"] + "." + identity["appID"])
        need(any(group == identity["group"] or
                 (isinstance(group, str) and group.endswith(".*") and identity["group"].startswith(group[:-1]))
                 for group in entitlements.get("keychain-access-groups", [])))
        need(any(isinstance(cert, bytes) and hashlib.sha1(cert).hexdigest().lower()
                 == identity["certificateSHA1"].lower() for cert in profile.get("DeveloperCertificates", [])))
        stage = "build"
        h.private_command(command, P, "clean-build")
        check_copy()
        stage = "signature"
        C = N / "derived-debug/Build/Products/Debug/CredentialStorageProbe.app"
        ancestors(C)
        h.private_owned(N, C)
        before = h.inspect_selected(C, selected, identity, P, "candidate")
        need(set(before) == INSPECTION and before["validity"] is True)
        need(before["profileSHA256"] == PROFILE and before["certificateSHA256"] == CERT
             and before["drSHA256"] == DR and before["appIDSHA256"] == sha(identity["appID"].encode())
             and before["groupSHA256"] == sha(identity["group"].encode()))
        need(before["binarySHA256"] != sha(regular(L / "current/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe")))
        candidate_tree = tree(C)
        check_copy()
        stage = "install"
        parents_in(N, A.parent)
        need(not os.path.lexists(A))
        h.private_command(["/usr/bin/ditto", str(C), str(A)], P, "copy-app")
        ancestors(A)
        h.private_owned(N, A)
        after = h.inspect_selected(A, selected, identity, P, "installed")
        need(set(after) == INSPECTION and before == after and candidate_tree == tree(A))
        check_copy()
        binary_sha, signature_sha, location_sha = after["binarySHA256"], sha(canonical(after)), sha(str(A).encode())
        stage = "manifest"
        value = {"schemaVersion": 1, "diagnosticUUID": U, "legacyRunUUID": RUN,
                 "purpose": "diagnostic-only", "legacyRoot": str(L), "expectedApp": str(A),
                 "sourceHashes": sources, "binarySHA256": binary_sha,
                 "legacyManifestSHA256": LEGACY["run.json"], "legacyIdentitySHA256": LEGACY["identity.json"],
                 "legacySaveMachineSHA256": LEGACY["private/save-a.public-machine.json"],
                 "legacySaveHumanSHA256": LEGACY["private/save-a.human.json"]}
        manifest_sha = write(N / "diagnostic.json", value)
        h.diagnostic_context(N / "diagnostic.json", manifest_sha)
        check_copy()
        stage, status, failure = "completed", "success", None
    except BaseException:
        failure = "build" if stage == "build" else "signature" if stage == "signature" else "guard"
    machine = {"schemaVersion": 1, "diagnosticUUID": U, "purpose": "host-build-sign", "status": status,
               "stage": stage, "failureKind": failure, "inputSHA256": input_sha, "sourceSHA256": source_sha,
               "binarySHA256": binary_sha, "signatureSHA256": signature_sha, "locationSHA256": location_sha,
               "buildVerified": status == "success"}
    need(set(machine) == MACHINE_KEYS)
    machine_sha = write(N / "build.machine.json", machine)
    print(json.dumps({"status": status, "stage": stage, "machineSHA256": machine_sha}))
    return 0 if status == "success" else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        # No trusted output, or receipt write failed: never overwrite/repair/retry.
        print('{"status":"unknown","failureKind":"guard"}')
        raise SystemExit(1) from None
# D05-CALLER-END
```

所有輸入檔／SHA來源在本段明列；原manifest的production table由完整manifest SHA授信。原Automatic PBX完整bytes SHA即其設定／local package binding，不另重寫或呼叫showBuildSettings。App tree比較包含regular mode/hash、directory mode與原symlink target且拒絕escape；不修改signed metadata／OS provenance。exclusive新root及consume先於copy/probe/build；任何partial root即禁止同UUID再次執行。本段只處理一次build及其實際Human觀察，不接受重試或既有root修復。即使build.machine寫不成，也只回unknown並保留partial；不得改舊run或臨場新增輸出。原D06／D07全部邊界不變。


## 5.3 Launcher紀錄缺口：runner-only amendment（2026-10-22，準備待審）

### 固定證據、來源及信任界線

沿已存在D05 diagnostic context，diagnostic manifest SHA `15e4e4fbcc09524cbabdca03b24f98e136f77f7c4ee99ea8351ee6cce06cd02e`、binary SHA `94a4cee1c1f26b8da62e633784b0fd0bbafae2ee6c3766fc5222bd253fe1108f`、build/Human及舊run全部bindings須保持；D06 marker SHA `cbdb03661df37a634a97ba6e973377ea87a220f0891cd70c44a82fa297991a31` 保留。原ready／logs／收據bytes不改，不能重用D06額度或改N/source snapshots。新runner只作外部caller，actualSHA由Dispatcher/Tester對獨立Reviewer最新approved freeze核對；attempt只記actualSHA，不自核approval。host/main／project／schemes／resources／production／Package.swift不改、不重編譯或重簽。

唯讀來源：runner `private_command`只保存兩log，native return/exception不持久化；diagnostic_stage將相關錯誤合併unknown，CLI可exit0。host DiagnosticProbe.bootstrap失敗直接return、最後exclusiveJSON為try?，故缺receipt不能區分未啟動、bootstrap拒絕或receipt寫入失敗。診斷receipt只有同context UUID／manifest／binary／source binding，**沒有本次nonce、requestSHA或processUUID**；普通Probe的processUUID也不是診斷receipt契約，未見過的UUID不能當歸屬證據。本輪 `hostConfirmed=false` 固定，整體 `status=unknown`，即使native0＋新有效receipt也不升級；可以交付完整launcher觀察而不宣稱host驗收。要可靠hostconfirmed仍缺本attempt的host可信回應binding；僅當下無PID不足排除D06遲到。必要nonce/等價host修補是後續受限缺口，**不納本次host/rebuild授權**。

### 唯一未來純launch與前提（本輪不執行）

新準備CLI固定：`python3 <本feature runner> launcher-amendment --manifest <N/diagnostic.json> --manifest-sha <上述完整SHA> --ready-uuid <fresh UUIDv4> --ready-confirmed`。布林旗標由trusted operator依Human當段實答傳入，不是工具自行授權；執行前還須本候選獨立code review、actualrunner freeze、D05完整freeze/全程觀察及明確新段落授權。CLI本輪只實作／non-live tests，不invoke真人context。

全部trusted guards先於attempt creation：既有diagnostic_context、fixedpurpose=diagnostic-only、精確manifest/binary/source/legacy pins、N與全部祖先canonical／無symlink；自身UID與0700只限N及要求owned的descendants／新D（私有檔0600），系統祖先只沿既有可信temp位置核對，不要求本UID／0700、不得chmod／chown、D05 build/Human exactSHA、D06既有spentmarker／兩logs原SHA、固定Appreceipt目前不存在；若已出現Appreceipt僅保留並停止，不刪除。未來啟動前只讀本UID的kernel PID集合（libproc PROC_UID_ONLY）及proc_pidpath，僅與本topic原fixed current與N/app兩個完整executable paths比較，丟棄非matching資料，不讀其他App argv／他人帳號或保留其他App inventory；公開只match count／檢查完整布林，matching PID只private。原D06 CLI返回＋同步subprocess.run只屬常規native等待證據，不能排除Popen constructor在進入with之前的例外，亦不證App退出／DPK無寫；不將此罕見分支當既有根因。未來preflight只要求本次完整唯讀快照沒有matching host或已知native open仍執行：ownUID PID集合用proc_pidpath匹配前述兩個精確App executable；僅對同UID且native executable等於/usr/bin/open（或其canonical同檔路徑）的PID，以sysctl KERN_PROCARGS2讀bounded argv、核argc／NUL邊界後逐token比較兩個已知完整命令：(1)原save-a的open -W -a <L/current App> --args --request <固定原request> --request-sha <該bytesSHA>；(2)原D06的open -W -a <同A> --env RIVET_DIAGNOSTIC_MANIFEST=<同manifest> --env RIVET_DIAGNOSTIC_SHA256=<同SHA> --args --request <固定原request> --request-sha <該SHA>。兩argv只由既有manifest／原request安全讀取導出，不接受caller覆寫；argv buffer僅記憶體比對，立即丟棄非matching資料，不寫raw argv／無關PID／秘密至logs或公開收據。不讀其他executable的argv。任一host/open match、snapshot不完整、權限／parse／查核無法驗證即拒絕futureinvoke，不kill或重試。legacyWorkerSettled為沿用欄位名，嚴格只表示此當次完整快照的known-native-open match=0，不表示歷史native exit／App安全退出；processCheckComplete涵蓋UID/path/selected-open-argv兩項查核。零match不證歷史無寫、無待寫、ownership或cleanup。本輪不作OSprobe；delta先獨立審，再僅以普通fixtures實作測匹配／unknown拒絕，不重開DPK或host。

未來native argv唯一為 `[/usr/bin/open,-W,-a,<同A>,--env,RIVET_DIAGNOSTIC_MANIFEST=<同manifest>,--env,RIVET_DIAGNOSTIC_SHA256=<同SHA>,--args,--launcher-amendment-only]`，不用-n/raw executable/原save-a request；不追加任何其他App參數。此固定sentinel令CommandLine.arguments.count=2：DiagnosticProbe.validateEarly的count==5 guard在request/Bundle/SecTask/load之前拒絕；兩env若皆未送達，Probe.run同樣先以count==5 guard拒絕，destination仍nil且不建立ProbeOperations.live／store。只有一env送達則diagnostic bootstrap拒絕，不進legacy。可產finite args/input診斷receipt，但不能宣稱completed或本attempt歸屬；即使所有env遺失也不讀原request或進DPK。這是純launch的必要fail-closed caller修正，不改host。

### Exact私有leaves、執行順序及有限schema

同N只新增固定目錄 `diagnostic-launch-amendment-1/`（下稱D），不是新namespace。精確原八leaves：`attempt.json`、`ready.json`、`consumed-ready.json`、`launch.stdout`、`launch.stderr`、`launcher.machine.json`、`launcher.human.json`、`caller-result.json`；RF-LG04-01 publication候選delta僅增加下列兩固定pending leaves（合計十個），待獨立審查；不新增repo leaves／其他私有fallback路徑。D或任一marker存在（含partial）即額度耗用；spawn入口不得重入或fallback舊D06，觀察CLI只允許已存在D讀取及exclusive Human leaf。先全部guards，再exclusive mkdir0700 D並fsync parent；其後任何失敗用finally落有限結果，絕不spawn前重置／刪除。檔案exclusive0600、O_NOFOLLOW、fsync file＋parent；可信D未成立不向任何輸入指定位置落檔。

`attempt.json`精確keys：schemaVersion=1、attempt='diagnostic-launch-amendment-1'、diagnosticUUID、purpose='launcher-only'、manifestSHA256、binarySHA256、runnerSHA256、originalConsumedSHA256、command（上述argv）、processCheckComplete=true、matchingAppCount=0、legacyWorkerSettled=true；後三項只能來自上述實際當段完整read-only snapshot；legacyWorkerSettled只命名相容的current-known-open-absent布林，不作historical settlement證明，不能從ready／缺receipt／單獨無App PID代填。`ready.json`精確keys：schemaVersion=1、diagnosticUUID、attempt、purpose='launcher-only'、ready=true、readyUUID；`consumed-ready.json`精確keys：schemaVersion=1、diagnosticUUID、attempt、readyUUID、readySHA256、attemptSHA256。原D06 ready UUID拒絕再用。consume須在spawn之前exclusive＋fsync，partial/fsync失敗不spawn，保留目錄並落unknown；不以attempt/consume作Appreceipt或成功證據。

Native專用launcher（不改所有build/sign helper語義）先exclusive開兩logs，再Popen上述精確argv，nativePID只private記錄於machine；spawn前置spawnAttempted=true，成功取得Popen物件後nativeSpawned=true。只wait一次，固定30秒；returncode整數原樣記，負數另記signal=-returncode。OSError／SubprocessError／其他例外有限分類，不保存message或traceback至公開receipt。wait timeout只記unknown，**不用subprocess.run(timeout)的自動kill行為，不kill/terminate App或open、不重試**；已知PID保留交接，無法證實native settled不解鎖依賴。受控fake child可自行有限退出；測試只清理自己建立且PID已知的fake child。finally無論native結果都嘗試一次primary machine，不能在except直接漏失嘗試紀錄。

`launcher.machine.json`精確keys：schemaVersion=1、diagnosticUUID、attempt、purpose='launcher-only'、manifestSHA256、binarySHA256、runnerSHA256、attemptSHA256（未持久則null）、readySHA256（未持久則null）、originalConsumedSHA256、status='unknown'、stage（consume/log-open/spawn/wait/receipt-check/completed）、spawnAttempted(bool)、nativeSpawned(bool)、nativePID(int/null，僅private)、nativeReturnCode(int/null)、nativeSignal(正int/null)、nativeSettled(bool)、exceptionKind(null/spawnOS/subprocess/waitOS/interrupted/guard/other)、timedOut(bool)、appReceiptPresent(bool/null)、appReceiptValidity(absent/valid/invalid/unreadable/unchecked)、appReceiptSHA256(完整SHA/null)、appReceiptAttributable=false、hostConfirmed=false。不存在returncode時必null，不能填0；settled只由確實wait返回，不能由worker結束或空logs推論。receipt只以固定N/diagnostic.machine.json讀一次安全snapshot、驗既有projection/context bindings，不接受caller指定輸出；即使valid仍unbound，不以新出現或mtime/未知processUUID推歸屬。若無法確定存在與否，Present=null／Validity=unreadable。Primary不是hostmachine，不寫原fixed App receipt。

primary在可信D成立後finally只exclusive寫一次；寫/fsync失敗保留partial，不能覆寫重做。最後也只一次寫固定 `caller-result.json`，精確keys：schemaVersion=1、diagnosticUUID、attempt、purpose='launcher-only'、status='unknown'、primaryReceiptWritten(bool)、primaryMachineSHA256(完整原bytesSHA/null)、failureKind(null/receiptWrite)、humanBinding(primary/caller-result/none)。primary持久成功→primary；primary失敗且caller-result可落檔→caller-result；fallback本身失敗則沒有可用binding，不在不存在的fallback中宣稱成功。CLI stdout最小有限結果只status、failureKind、primaryReceiptWritten、callerResultWritten、bindingReceiptSHA256（真持久bytes/null），不含原error／命令／IDs／paths／nativePID；**primary/fallback任一寫失敗exit2，其他unknown exit1，不以native0返回host success**。磁碟不可寫或process被外部中斷無法保證落檔；無任何可信receipt則stdout有限unknown／非零且只由Tester在原live-validation敘述實際觀察，不能造SHA／其他私有路徑fallback。

Human觀察CLI：`launcher-amendment-observe --manifest <同manifest> --manifest-sha <同SHA> --binding-receipt-sha <真primary或fallback SHA> --prompt-count <實際非負int或unknown> --actions <none|allow|deny|authenticate|other的逗號序列> --whole-observed <yes|no>`。只在Human實答後執行；精確綁選定已持久receipt原bytesSHA，exclusive一次 `launcher.human.json`。其精確keys：schemaVersion=1、diagnosticUUID、attempt、purpose='launcher-only'、bindingKind(primary/caller-result)、bindingReceiptSHA256、promptCount(int/null)、actions(既有限列舉)、wholeStageObserved(bool)。未答不寫；count=null或whole=false不完整，零次必actions=[]或[none]。原D06 Human0敘述、D05 Human0 JSON均不改。公開只role evidence既有leaf追加有限launcher／actual Human結果，不更新原D06 outcome或summary。

### 本輪實作與驗收界線

Implementer僅修改既有runner／Python tests／README；先真entrypoint red→green、再獨立Tester／Reviewer。Tests以普通TemporaryDirectory實際fake child或mock spawn/wait例外接線：LG-T01完整argv/env及固定invalid sentinel（不得有--request），查現有Swift兩args guard和已驗args case來源不改host；LG-T02 spawnOS／native非0／signal／native0無receipt／waiterror／timeout不kill與nativePID/return空值；LG-T03實際non-live入口fixtures：valid但unbound／遲到receipt仍unknown；malformed或context binding無效→appReceiptValidity=invalid；不能安全讀取或無法確定存在性→appReceiptValidity=unreadable、appReceiptPresent=null；各分支均status=unknown、hostConfirmed=false、appReceiptAttributable=false，有限結果不得洩漏raw bytes／error；LG-T04 primary/fsync失敗、fallback失敗、可信D未成立零輸出、finally落一次有限結果與CLI非零；LG-T05 path/symlink/pin拒絕、partial directory/consume耗額、ready重放；ordinary fixtures驗ownUID/exact host paths與selected-open精確argv token比對、matching host/open或snapshot/argv不可讀／parse不明皆禁止spawn，不以當下零match推歷史settlement；LG-T06實際observe exactSHA／count/actions/whole／exclusive及原D06bytes保持。Fake child自有有限退出與受控fakePID清理，不執行open/App/DPK；保留既有63回歸，新Swift/unsigned/build/sign不需重跑，原已驗fake入口若依賴現存binary須如實標示，不能以skip冒稱完整63通過。

本輪準備可完成launcher可觀察性；未來純launch只可能補native失敗邊界／是否出現receipt，不能保證hostconfirmed。此後若需可靠host歸屬，另列最小可信nonce/等價回應方案再審，不能把本次unknown自動導向host改動、rebuild或第三次setup。現在禁止任何真人root/inputs/ready/attempt、process/system probe、App/sign/build/DPK/新assets／trust/付費／清理/Git；D07及原namespace停點維持。


### RF-LG04-01：雙receipt publication最小候選delta（待獨立審查，未實作）

根因是直接寫final名稱，完整JSON殘留不能證明該次write/fsync已成功；schema及caller選擇欄位不足以排除fallback自身完整partial。本delta只兩個launcher觀察receipt，不改全域exclusive_json、其他stage/write語義或任何舊資料／host。原八private leaves之外，在同D固定增加 `launcher.machine.pending.json`、`caller-result.pending.json`，無其他temp/marker或repo leaf；pending bytes保留不刪除、不覆寫／重試、不作Human target。其他六原private leaves維持既有exclusive/fsync。

本launcher專用publication helper的唯一順序：先核D owned0700／canonical與精確final/pending pair皆不存在；canonical JSON與SHA先在記憶體完成；以exclusive0600/O_NOFOLLOW建立對應pending、寫全payload、flush＋fsync該fd，close後fsync D以同步pending entry；以上**全部成功後才最後一步** `os.link(pending, final, follow_symlinks=False)`，不overwrite，保留pending。helper在link後不再追加fallible read/fsync/cleanup，直接回已計算SHA；其他later I/O失敗不能將已發布primary降為未發布。任一prepublication write/fsync/close失敗只能留pending，final仍absent，不回SHA；link失敗保留unknown與既有bytes，不重試。這裡publication是當次可觀察的fsynced payload＋原子發布名稱，不宣稱final directory entry在跨斷電後必存活；不作一般power-loss/recovery保證。不得用『先final再fsync』重引同一缺口。

observe只接受精確已發布final/pending pair：安全檔案位置／UID／0600／非symlink／regular、兩者stat dev+inode相同、完整bytes及SHA相等、精確有限schema/context成立。只有pending（即使完整JSON）永不選為binding；不從內容自稱已提交。新helper所有final只在prepublication同步完成後建立，外部trusted-operator仍須核actual runner獨立approved freeze。不接受任意receiptpath或自行增commit旗標。primary/caller payload schema不增加欄位，hostConfirmed/attributable始終false。

| 本次可驗publication狀態 | CLI binding及observe唯一選擇 | 失敗界線 |
|---|---|---|
| primary已發布，caller已發布且宣告primary SHA一致 | primary原bytesSHA；可記Human | 整體仍unknown/exit1，不是hostpass |
| primary已發布，caller寫入／fsync失敗只pending或未建立 | **仍保留primary可用SHA**；observe由primary已發布pair直接驗，不再強制caller存在 | CLIexit2、callerWritten=false，不因later caller失敗降null；不是回復舊residual-primary fallback |
| primary失敗只有pending／未建立，caller已發布且宣告primaryWritten=false／primarySHA=null／failureKind=receiptWrite／humanBinding=caller-result | caller-result已發布原bytesSHA；可記Human(bindingKind=caller-result) | CLIexit2，primarypending永不觀察 |
| 兩者未發布（含兩個完整pending、fallback寫前或fsync失敗） | bindingSHA=null，observe拒絕，**Human leaf不存在** | CLIexit2，保留partial，不能從完整bytes自算binding |

若兩個final都通過publication pair但payload交叉選擇／SHA矛盾，拒絕觀察，不猜測；malformed／不安全pair仍finite unknown。Public stdout沿原五keys；primaryReceiptWritten/callerResultWritten只表示各自成功發布，可用binding先primary、否則已發布且合法caller、否則null。Human exactSHA／新freshready／同D一次／不kill不retry與原D05/D06歷史全部不變。

LG-T04只增加同RF必要入口fixtures：在真正pending payload已完整之後注入file fsync及prepublication directory fsync失敗，驗final不存在、pending保持、兩種primary/caller失敗組合都不能綁partial；primary發布後caller失敗仍能合法綁primary；primary失敗caller發布仍能合法綁caller；正常primary/caller皆發布、pair inode/bytes/schema不符及兩個pending後observe拒絕。Fault注入必對應publication之前實際同步呼叫；已成功publication helper返回後再任意raise不能冒稱其先前fsync失敗，不能以此放寬真fsync反例。保留原85回歸與原反例的noHuman期望。先獨立Plan-Reviewer核此精確兩leaf/順序/矩陣，再Implementer→原LG04 Tester；不實作或建立真人pending/ready/root、App/sign/DPK或其他框架。


### LG preflight有限stdout觀測補充（2026-10-22，候選待獨立審查）

沿Human standing授權只補工具紀錄／non-live／review。LG05 approved歷史保留；LG06已單次invoke後pre-spawn guard、未建D／未native、Human全程0次及真stdout SHA `b3d71cb085489be348cd23a361040f247b5b2bbc139b8ae8dd9bbf497885db66` 不改、不rerun。唯讀SDK/API文件未證明實際呼叫錯誤，歷史精確guard未知；本補充不把可能errno或PID race寫為根因。requirements意圖無變，無新Mission。

只launcher-amendment在trusted D建立之前的拒絕stdout，於原五keys增加四個固定keys：

- `guardPoint`：context／ready／quota／request／snapshot-platform／snapshot-library／snapshot-list-size／snapshot-list-read／snapshot-open-path／snapshot-path／snapshot-args-size／snapshot-args-read／snapshot-args-decode／snapshot-match／caller-source／output／unknown。依實際source在操作或require之前設定；output限D mkdir及ownership驗證尚未成為trusted output的失敗。
- `apiOutcome`：notCalled／returned／exception／guard；`apiReturn`：notAvailable／negative／zero／positive（只分類原native回傳，不公開PID、buffer內容或process count）。
- `errnoKind`：none／notFound／permissionDenied／interrupted／unsupported／other／unknown。僅真實已取得errno分類：ENOENT/ESRCH→notFound，EACCES/EPERM→permissionDenied，EINTR→interrupted，ENOSYS/ENOTSUP/EOPNOTSUPP→unsupported，其餘已知非零→other。原生失敗但errno不可取得／為0或未知exception→unknown，不猜none／permissionDenied。純require拒絕且沒有失敗native call才為none。

實作採每次CLI invocation局部plain dict，沿launcher_amendment→process_state→snapshot傳遞觀測（內部optional參數可維持既有fixture直接呼叫），不用global累積狀態／框架／檔案。每個guardPoint起始清前一階段API資料；原native call前清ctypes thread-local errno，call返回後立即擷取原return及get_errno，再作原有require，避免後續操作覆蓋errno。既有CDLL維持use_errno=True；若調整只為讀取觀測，不增加native呼叫／buffer重試。OSError只取errno，不序列化str/repr/traceback；其他exception只歸有限unknown。每階段純guard保留guardPoint與guard分類，API native失敗則保留returned/return符號/實際errno分類。所有操作／成功拒絕條件／快照範圍不變；未分類Exception也只能有限拒絕，不能為取得診斷繼續spawn。

映射：launcher_context→context；布林/UUID→ready；D/Appreceipt absence→quota；原request fingerprint讀取→request；Darwin/platform→snapshot-platform；CDLL/symbol signatures→snapshot-library；兩次proc_listpids→list-size/list-read；open canonicalpath→open-path；每次proc_pidpath→path；selected-open兩次sysctl→args-size/args-read；純argv parser→args-decode；state三值require→snapshot-match；actual runner bytes讀取→caller-source；trusted D前mkdir/owner→output。API後buffer/count界線仍標同point、正確記returned符號；不為每個PID加序號／path或rawerr字串。

新四keys僅上述launcher-amendment失敗回覆；observe／其他legacy CLI、trusted-D後native結果、兩receipt atomicpublication／Human binding schema與pending數目完全不變。status仍unknown、nonzero，guard0／errno none都不證歷史退出或無寫。無法建立觀測狀態則固定guardPoint=unknown、apiOutcome=exception、apiReturn=notAvailable、errnoKind=unknown，原五keys照舊；仍不寫新privateleaf或假machine。原stdout實際bytes/Human歷史不補填新keys。公開嚴禁rawerror／PID／path／argv／環境／secret與原始buffer。

Non-live驗收加在既有LG-T05/CLI projection範圍：以fake native API/exception測各必要point在API失敗、純guard拒絕、成功返回後界線拒絕的有限輸出；errno缺失/0→unknown、既知errno逐類正確且不沿用上一point；敏感sentinel出現在mock error/path/argv時stdout不得含它。走實際CLI入口，assert尚未trustedD零spawn/零新目錄；正常preflight及trusted-D結果仍舊schema，觀察與publication回歸保持。保留既有94 regression，不重編Swift／sign/build或真API snapshot，不為測試呼叫任何App/DPK。

只改既有runner/tests/README及自己step，無新privateleaf／namespace／旗標、無snapshot放寬或retry/kill/cleanup/globallegacy變更。先獨立Plan-Reviewer→Implementer non-live→Tester→Reviewer並新freeze，才可能交Human審未來同N唯一native attempt的具體scope＋freshready；舊LG06 ready不得重用、D不存在也不等再次invoke許可。本輪禁止新CLI/snapshot/OSprobe/App/sign/DPK/ready/root，所有既有收據／manifest／host及D05/D06/Keychain結果不動。


### LG14 正向名稱預篩：受限候選，待獨立Plan-Reviewer

此補充只替換「所有ownUID PID先完整path」的工具演算法；來源是standing必要補修授權與Reviewer更正，不是放寬產品秘密保存或簽章決策。其餘§5.3 trusted guards／一次額度／publication／Human binding／invalid sentinel不變；hostConfirmed及appReceiptAttributable仍false。LG13僅證snapshot-path回zero且errno合併notFound，不補填精確errno、PID或race。

一手依據：[Apple libproc.c proc_name](https://github.com/apple-oss-distributions/xnu/blob/main/libsyscall/wrappers/libproc/libproc.c)先查PROC_PIDTBSDINFO，pbi_name非空優先，否則pbi_comm；[proc_info.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/proc_info.c)強制pbi_name[31]／pbi_comm[15]為NUL；[param.h](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/param.h) MAXCOMLEN=16；[kern_exec.c set_proc_name](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_exec.c)從exec檔名分量填name/comm。這些是公開source證據，未證與本機kernel每個revision完全相同，也不是名稱的安全identity保證。proc_pidpath的ESRCH亦可能來自缺text vnode／vnode回收等，故不以名稱失敗或path ESRCH/ENOENT推定gone。

唯一新增native API為libproc.proc_name(int, void*, uint32_t)→int，沿原CDLL/use_errno和同次ownUID PID列舉，每PID只呼叫一次。使用零初始化32-byte buffer；先標guardPoint=snapshot-name（加入既有enum，不新增stdout keys），按既有helper即時讀return/errno。require 1≤return≤31、buffer[return]為NUL、此前無NUL、strict UTF-8成功及非空；異常長度、不可得長度、空／壞編碼／API零或例外一律guard unknown並停止，不能略過。原有限errnoKind映射不變，不為此增加query/retry。名稱、PID、buffer、別名不公開、不持久化，純名稱格式拒絕仍沿既有finite觀測規則。

已知候選名稱集合只由既有固定兩host完整executable paths的basename，以及/usr/bin/open basename導出，不接受caller新增名稱或flags；各名稱保留UTF-8完整bytes、前31及前15 bytes別名（只在合法UTF-8邊界使用）。決策順序固定：(1)可信格式檢查失敗即停；(2)只有仍與固定known target完整名稱／31/15別名／非空前綴相容，或因非ASCII／別名／大小寫或正規化歧義而不能安全排除是target的可信名稱，才為candidate；長度15/31本身不構成candidate。(3)可信ASCII名稱若與所有固定名稱／別名及其可能截斷前綴均不相容，即判定非目標，不呼叫該PID的path或argv；即使長度恰15/31也相同。metadata／編碼／format未知或非法仍按(1)拒絕，不用不相容比較掩蓋unknown。不得把名字相符直接當identity。candidate按原proc_pidpath完整路徑比較，path失敗含notFound仍拒絕；只有path精確為open才讀原bounded selected-open argv，不變更token／argc／NUL檢查。若本機名稱契約或已知host別名無法證成，保持candidate／guard，不能用實驗猜測忽略unknown。名稱與path跨呼叫的PID狀態變化仍是限制，不宣稱原子快照或歷史退出／無寫。

LG-N01–07是既有LG-T05/projection必要子例，不另建框架：(01)actual entrypoint fake ctypes回可信無關短名，該PID path／args零call；(02)兩host/open完整／31/15 aliases及仍相容的截斷／prefix／無法排除target的歧義名稱仍candidate，原path與selected-open argv精確接線；另驗可信且對所有known prefix均不相容的15/31-byte名稱，path／args零call，不能以長度設全域candidate；(03)name zero/errno/notFound/例外、空、壞UTF-8、NUL／return長度不符及長度不可得均拒絕且無D/spawn；(04)candidate path ENOENT/ESRCH／permission/unknown仍拒絕，不因名字預篩轉成功；(05)敏感fixture不進stdout，既有四keys只增加snapshot-name enum；(06)保留全部既有99 regression、publication/Human/sentinel及sourcefreeze；(07)known-child可行性只允許既述未修改原sys.executable普通／偽裝argv0兩child，以及一個原機未修改、未複製的/bin/sleep有限child（Popen executable=/bin/sleep、argv0固定非秘密spoof、參數1秒）。僅查直接Popen回傳的該own PID之proc_name/path及已批bounded kernel argv0；對照已知直接native executable basename／完整path，而非假設interpreted launcher/shim realpath必等kernel實際exec。child須自然有限退出並wait收尾；不列舉UID或查其他PID，不copy/patch/sign binary、不建App或作安全設定調查。前述Python path/argv0對照未成立限制保留，不改期望假通過；native等價fixture另記實際結果。先前copied /bin/sleep exit-9原因未驗，不作成功或安全原因證據。原/bin/sleep不可用／未自然完成／結果不符時記限制停止，不能改環境或以假值宣稱N07通過；全UID快照仍只fake provider。

Modify仍僅validation/github-oauth-credential-persistence/{scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}，不新增repo/private leaf、namespace、caller、CLI flag、host／sourcepins或安全設定；普通fake/temp與LG-N07 known child是唯一non-live執行例外，不能執行真人launcher／App／全UID OSsnapshot／DPK／新ready或清理舊root。外部approved runner freeze與oldhost freeze分離；獨立PlanReview→Implementer→Tester→Reviewer後，真launch仍另交Human具體同CLI及freshready，不重用LG13 ready或自動invoke。


### LG20：fullinfo/status/instance取代逐PID proc_name（候選待獨立審查）

本補充取代LG14的proc_name讀取，不修改原positive-name別名判準／sentinel／一次額度／trusted-D／publication與Human binding。真正保護目的是排除兩固定host及帶原exact argv的native open衝突，不要求任意無關程序永久可讀。現在只準備／non-live；LG19真結果及所有已存bytes／freeze不追補、不重跑。

**依據與限度。** Apple [libproc.c](https://github.com/apple-oss-distributions/xnu/blob/main/libsyscall/wrappers/libproc/libproc.c)的proc_name固定PROC_PIDTBSDINFO,arg=0；[proc_info.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/proc_info.c)列舉含allproc/zombproc，而TBSDINFO在arg非零才find_zombref。這證明原語配對有結構缺口，不證LG19失敗PID是zombie。當地SDK公開proc_pidinfo／PROC_PIDTBSDINFO／proc_bsdinfo（PID/UID/status/name/comm/start sec/usec）；arg非零的zombie語義來自公開XNU source，非本機runtime已驗。只用這些公開SDK欄位，不硬編private uniqueidentifier/pidversion flavor，不解析kinfo ABI或偽造audit token。

**精確有界演算法。** 保留原ownUID PID列舉／buffer檢查；每筆正PID以`proc_pidinfo(pid, PROC_PIDTBSDINFO, 1, &info, sizeof(info))`讀A。ctypes ABI逐欄依SDK（uint32/int32/uint64、16-byte comm/32-byte name及native alignment），return必恰sizeof而非只>0；核pbi_pid等於query PID、pbi_uid等於本UID、start秒>0/usec<1000000、status在SDK已知集合。短／大／零reply、無法驗證layout、PID/UID不符、未知status或任一permission/API/格式未知即拒絕。errno不等於gone證據。

- A.status==SZOMB(5)：完整可信metadata是當次已退出狀態的正向證據，記zombieObserved/zombieExcluded並略path/argv；不需要從空名字推論，不推歷史無寫、別的child已退出或cleanup權限。
- Live只接受SRUN(2)/SSLEEP(3)/SSTOP(4)；SIDL(1)等未就緒狀態拒絕。以NUL有界name優先、空則comm，兩欄均依固定32/16-byte邊界核NUL、strict UTF-8；依LG14固定完整/31/15 aliases與prefix判斷。可信noncandidate可排除；空／非法編碼仍拒絕，可信歧義為candidate，15/31非global candidate。
- Live candidate：A為前界；做兩次有界classification（每次原完整proc_pidpath；僅exact canonical open才原bounded KERN_PROCARGS2 size/read＋argc/NUL/token checks），各自結果為exactHost／exactKnownOpen／other，兩次path與selected-open argv結果須一致；其後再同arg1讀B作後界。A/B的PID、UID、starttime、status、原bounded name/comm bytes及name-classification均須一致；否則instanceChanged或classificationChanged拒絕，不把新instance重新分類成排除。任何已觀測exactHost／exactKnownOpen直接拒絕，不為衝突繼續讀取。path/argv失敗依舊拒絕；無等待、重試或改任何程序狀態。

PID+starttime是本次一致性檢查，不是不可偽造或形式唯一token；兩端相等仍不能排除中間exec/ABA、查核後新程序／exec或LaunchServices行為。只拒絕可觀測的instance／name/status/path/argv變動，不宣稱偵測所有exec、原子snapshot或race-free。初始UID列表沒有complete flag，原少於buffer容量僅必要檢查，不能升格全程序完備證明；processCheckComplete維持既有「本次有界檢查依契約完成」意義，不作更強保證。

**Reaped明確停點。** 本輪不實作UID membership重讀來略過查不到metadata的PID：[proc_info.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/proc_info.c)內部nprocs+20上限且無complete flag，不支持把used<caller capacity當嚴格完整absence。也不納exactPID sysctl fallback：其size-only會加KERN_PROCSLOP，不能以估計長度判無entry；actual buffer成功零長度雖有來源候選，尚未證本機MAC／可見性適用，不假定unsandboxed能解所有policy。故metadata zero／reaped、permission及未知維持guard，不能只靠原errno跳過。來源：[kern_sysctl.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_sysctl.c)、[kern_newsysctl.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_newsysctl.c)。不擴查／探測policy、增加環境設定或偽造complete。

**有限觀測，非新receipt框架。** 僅launcher-amendment stdout（pre-D拒絕及trusted-D既有結果）固定加`processEvidence`物件；其餘CLI、published machine/caller/Human schemas與atomicpublication不變。既有四有限keys保留，guardPoint新增snapshot-metadata/snapshot-instance/snapshot-classification，原snapshot-name保留歷史不改。processEvidence固定八keys：`decision` enum={notChecked,noncandidate,zombieExcluded,metadataUnavailable,metadataInvalid,permissionDenied,instanceChanged,classificationChanged,targetHost,targetOpen,candidateOther,pathUnavailable,argsUnavailable}；`zombieObserved`、`zombieExcluded`、`noncandidateExcluded`、`instanceChecked`、`instanceChanged`、`conflictObserved`、`checksFinished`皆bool，invocation局部預設false。decision記最後有限事件，aggregate只在實際正向證據成立時置true；instanceChecked只完整A/B已核後true、checksFinished只全次契約查核完成true，false不代表全局不存在。API失敗保留原四key真return/errno分類，permission只來自已知EACCES/EPERM，不猜錯因；observation自身失敗輸出固定notChecked/allfalse，不能讓guard放行。新物件只能allowlist投影，不含rawerror/PID/UID/starttime/name/path/argv/env或buffer；原stdout歷史不補填。未來若另授purelaunch，新stdoutSHA可支持本次哪些正向排除／拒絕被觀測，仍不能hostconfirm、DPK／歷史無寫或原子保證。

**LG-M01–07驗收。** M01 SDK layout/offsetof/sizeof及完整return／PID/UID/status/starttime負例，原fullinfo field names不可猜offset；如必要，既有Python測試內嵌最小C，普通自有temp以SDK header compile unsigned CLI比對size/offset，不新增repo leaf、不signed App。M02 actual CLI fake ctypes分live noncandidate／可信zombie：零path/argv且aggregate正確；zombie空name不影響可信status排除。M03 known/truncated/ambiguous候選仍完整path/selected-open argv及有界前後核對；真host/open conflict拒絕；name非法／denied/metadata0或reaped仍拒絕。M04 fake PIDreuse/starttime/UID/status/name/exec分類/path/argv變化、短buffer與未知metadata全部拒絕，沒有errno-only略過／UID重讀或snapshot迴圈。M05 stdout有限schema／敏感fixture不洩漏／每次reset、成功與失敗的aggregate皆如實；publication/Human/sentinel及全部既有104回歸保持，舊99 proof不重編Swift。M06 單一原版未修改未複製/bin/sleep自有finite child（固定1秒）running→退出未wait的zombie→wait後reaped，只查直接取得own PID；arg0/arg1對照及metadata status證據、reaped仍guard；須finally wait自然回收，不kill／copy／sign，不查其他PID或全UID列表。僅對這個自有child可用有界deadline等待狀態，非production guard重試；若未觀察到某階段則該case未驗/unknown，不能假通過或查其他程序。M07 核原9葉中只三葉變動／新freeze、原context與所有成功unknown不改；真人全部停。本輪只fake全UID snapshot與單known child；不執行launcher/App/DPK/sign/build/新ready或舊root清理。


### LG26：path failure同PID單次post-metadata（候選待LG27獨立審查）

僅LG20兩次classification中proc_pidpath**完成返回≤0**的窄branch，已持有可信live candidate A時，對同PID呼叫一次既有arg1 fullinfo（沿原完整size／PID／UID／status/starttime格式驗證）。不重試path、不查argv、不重列UID、不等待／迴圈／kill。API本身exception、成功後decode／其他guard、真host/open衝突不進此branch；原行為保留。第一或第二pass由caller明確傳入，不以global aggregate推定。至多每個失敗candidate一次post；若正向zombie排除便結束該PID，不再做其第二path或正常B。

先在原path call即時捕獲原四有限guard fields及真native errno，再以**獨立局部observer**作post，不能讓post API/reset覆蓋原path證據或借errnoKind推原因。A與post的PID/UID/starttime相同且post.status=SZOMB，才記zombieSame並正向排除；若identity不同為instanceChanged，若同identity live且status/name/comm/name-classification不一致為classificationChanged；完整一致live為liveSame。這三類及permissionDenied/unavailable/invalid/unknown均停止。post zero／無資料只稱unavailable，不證reaped/gone；permission只來自實際EACCES/EPERM。zombie尚須同instance，不能因新PID instance恰為zombie而排除。既有processEvidence八欄仍各依原正向事件更新，不把累積true綁本PID；pathFailureEvidence是本失敗iteration的明確證據。

只有launcher-amendment stdout固定新增`pathFailureEvidence`，其餘CLI／published machine/caller/Human及publication不動、無新leaf/flag/caller。固定五keys與預設：

- `pass`: none(default)/first/second。
- `postState`: notRead(default)/liveSame/zombieSame/instanceChanged/classificationChanged/permissionDenied/unavailable/invalid/unknown。post實讀且可信才能輸出對應狀態；observer自身失敗為unknown而非放行。
- `nameMatchKind`: notChecked(default)/full/alias15/alias31/prefixOnly/ambiguous。只取A實際選用欄位（非空pbi_name，否則comm）；先casefold exact full，否則只有該來源的實際截斷界線可標alias31（name且31 bytes、known更長）或alias15（comm且15 bytes、known更長），剩餘相容前綴為prefixOnly，其餘原candidate歧義為ambiguous。這僅觀測分類，**不改任何預篩結果**，不宣稱LG25是prefix假陽性。
- `pathErrno`: notCalled(default)/ENOENT/ESRCH/EPERM/EACCES/zero/other/unknown。只原path native call即時實得errno，零為zero、其餘已知非零other、不可得unknown；不從coarse notFound反推，也不公開任意數值。
- `pathFailure`: 固定原四keys guardPoint/apiOutcome/apiReturn/errnoKind，沿原allowlists；預設unknown/notCalled/notAvailable/none。事件成立時是原path失敗四值的副本，post不改。若post後仍guard，外層原四keys也保持原path失敗；若zombieSame後繼續其他PID，外層依當次最後guard，本物件仍保存最近一次path failure，不冒充新的失敗來源。

五keys總是allowlist序列化（pre-D及trusted-D），無event用上述defaults，跨invocation reset；最後一筆path失敗可更新此單一局部物件，不新歷史框架。禁止raw PID/UID/starttime/name/path/argv/error/env。實際native launch仍須未來另授，本schema不重構舊stdout或觸原roots。

LG-P01–05驗收：P01 actual CLI fake-provider first/second path failure，覆蓋全部postState與同instance zombie才排除；live/identity或classification變動／denied/zero/invalid仍guard，後查恰一次、原path不retry、零UID重讀。P02 實際errno ENOENT/ESRCH/EPERM/EACCES/0/其他/不可得與四guard fields在post成功／失敗後皆原值，拒絕從notFound猜symbol。P03 A的name/comm來源、full/alias15/alias31/prefixOnly/ambiguous分類，預篩結果與原tests不變。P04 actual CLI序列化五key defaults/reset、敏感fixtures不洩露、較早aggregate true不冒充本失敗項目；zombie排除後另一PID失敗時nested pathFailure與外層guard分別正確，publication/Human/sentinel不退步。P05 完整既有114 regression與適用AST/Ruff／三葉freeze／其他六葉一致；SDK layout與單child既驗部分不因本局部接線重做，除非source變更產生具體理由。全部UID snapshot只fake，本輪不跑known child／App／真query或原root操作。


### LG31 離線launch-report binding（2026-11-03；候選待LG32）

本輪只準備既有main.swift／runner／tests／README，舊N不作fake工作依賴。保留所有舊入口與LG30成果；不修舊manifest/pins、不把新版本冒充舊binary。新驗證模式名稱固定`launch-report-only`，與既有diagnostic-only/namespace-read-only分開；不新建module/BC/產品API。

**入口及零DPK。** 新host固定argv只有`--launch-binding-only`；此sentinel或任一新環境key存在時，先進獨立LaunchReport路徑，再核argv及inputs，絕不回落Probe.run/DiagnosticProbe.load。新環境僅`RIVET_LAUNCH_REPORT_REQUEST`與`RIVET_LAUNCH_REPORT_REQUEST_SHA256`；兩者缺失/部分/無效皆有限拒絕。完全env遺失仍由sentinel拒絕或完成此獨立診斷，不建立store/provider、不呼叫任何SecItem／SecTask/entitlement查詢。舊`--launcher-amendment-only`的安全拒絕保持。新hooks只含檔案/自身binary/自身process metadata/clock與ACK等待，沒有credential capability。

**固定位置及schema（均private）。** R是未來獨立批准的operational context，現在只存在普通fake temp中；不沿舊N建立。R本身owned0700、全祖先canonical/no-symlink（系統祖先不要求本UID/0700）；metadata/輸出regular0600/O_NOFOLLOW/exclusive，App executable依原mode/owner與預期canonical位置核對，不硬套0600。R/context.json為immutable；App固定R/app/CredentialStorageProbe.app，source snapshots固定R/source/原九validation相對leaves。R/binding-consumed.json或R/attempt/任一存在即耗唯一額度，partial也不得retry/reset/delete。attempt內只下列固定leaves：request.json、host.report.pending.json／host.report.json、ack.pending.json／ack.json、host.final.pending.json／host.final.json、launcher.machine.pending.json／launcher.machine.json、launch.stdout、launch.stderr。沒有caller可任意指定的receipt/ACK路徑。

全部JSON exact keys/types/有限值；UUID lowercase v4、SHA lowercase64hex、整數不接受bool/浮點，檔案上限64KiB。核心binding B固定`schemaVersion=1,purpose=launch-report-only,attemptUUID,contextSHA256,requestSHA256,expectedBinarySHA256`；request本身不含requestSHA256，避免自我hash循環。

- context exact keys：schemaVersion(1)、purpose、contextUUID、sourceHashes（九個固定相對source leaves→SHA）、expectedBinarySHA256、buildProofSHA256、signingProofSHA256。兩proof固定R/build.machine.json、R/signing.machine.json；未來由外部trusted operator核signed-host來源/預期身分/有效期後凍結，hash不自證approval。Host核owned context bytes SHA、source snapshot hashes、預期self executable位置及實讀self binary SHA；launcher亦獨立核。
- request exact keys：schemaVersion、purpose、attemptUUID、contextSHA256、expectedBinarySHA256、createdAtUnixMicroseconds。Bytes由runner在唯一attempt內exclusive產生，原bytes SHA透過環境傳入host；context不包含request hash。
- host.report exact keys：B＋observedBinarySHA256、pid、startSeconds、startMicroseconds、processUUID、stage、outcome。Stage只能report，outcome只能awaitingAck；自身PID/start由self kernel metadata取得，不信caller輸入。
- ACK exact keys：B＋hostReportSHA256。只在launcher獨立驗證report及live instance後exclusive發布。
- host.final exact keys：B＋hostReportSHA256、ackSHA256、outcome(completed)。Host核ACK原bytes完整binding才發布final。Final是實際讀ACK的回應，不以native open exit0代替。

**RF-LG32-01：兩個private schema補全。** 下列B沿本節完整binding；所有keys均必有、不得多欄，除明示外不可null。

- `R/binding-consumed.json` exact keys：B＋`readyUUID`(lowercase v4 string)、`readyConfirmed`(bool且必true)、`runnerSHA256`(hash)、`evidenceMode`(fake-only/signed-host)。B的schemaVersion為int=1、purpose為固定string、attemptUUID為v4 string，其餘B hash皆64hex string。Request bytes須先在記憶體定稿計SHA，consume綁該context/request/expectedbinary與CLI attempt/ready及actual runner bytes；ready來自trusted operator實答，runner hash不自證review。Consumed無nullable欄位／自身hash；regular0600 exclusive寫全＋fsync/parent fsync成功才可建attempt/request。任何既存／partial即耗額，之後即使JSON可parse也不容重試或當新ready。
- `R/attempt/launcher.machine.json` exact keys：B＋`readyUUID,runnerSHA256,consumedSHA256,evidenceMode,stage,outcome,failureKind,hostAttributed,bindingMatched,liveInstanceVerified,binaryVerified,nativeSettled,nativeReturnKind,spawnAttempted,nativePID,nativeReturnCode,nativeSignal,nativeExceptionKind,reportSHA256,ackSHA256,finalSHA256`。B／readyUUID／runnerSHA256／evidenceMode逐值同有效consume，consumedSHA256是該consume原bytes非null hash。stage/outcome/failureKind/nativeReturnKind沿本節stdout有限enum（outcome是唯一status欄）；五驗證/settle欄及spawnAttempted嚴格bool。NativePID為positive int或null，nativeReturnCode為int或null，nativeSignal為positive int或null（int均拒bool）；nativeExceptionKind僅null/spawnOS/waitOS/timeout/subprocess/guard/other。Receipt三SHA各為hash或null；machine**不含machineSHA256或自身hash**。

Machine失敗預設：stage為實際停止階段、outcome=unknown、failureKind依已知有限原因（不可得為other），五bool及spawnAttempted初始false，三native數值／exception及三receiptSHA初始null，nativeReturnKind=notStarted；只由實際事件推進，後續失敗不得抹先前native rc/signal/exception。未spawn三native數值null、nativeSettled=false且notStarted；已attempt但未可驗settle為unknown、returnCode/signal=null，PID只在真正Popen取得後非null。已settle須PID非null、returnCode為int；0→zero且signal=null，正數→nonzero且signal=null，負數→signal且nativeSignal=-returnCode。

reportSHA僅在已發布pair及完整report binding/selfbinary驗證後非null；ACK SHA須reportSHA非null、binaryVerified/liveInstanceVerified=true且ACK已發布並綁report；finalSHA須report/ACK非null且已發布final exact B／兩hash匹配。bindingMatched僅完整report/ACK/final鏈通過後true；liveInstanceVerified僅兩次獨立live metadata/path及freshness核對通過後true；binaryVerified僅預期檔案/簽章freeze及host實讀hash匹配後true，均不是nonce自證。

signed-host的候選outcome=hostAttributed只允許stage=publish、failureKind=none、五bool全true、spawnAttempted=true、nativeReturnKind=zero、nativeExceptionKind=null及三receiptSHA非null；fake-only一律hostAttributed=false/outcome=unknown，即使protocol flags通過可failureKind=none。其餘已知input/binding/quota拒絕用rejected，runtime缺失/timeout/寫入/native不明用unknown，不得把失敗組合編成成功。只有成功發布的machine pair且上述schema/consume/receipt交叉綁定再核通，外層stdout才可輸出hostAttributed=true；machine pending完整但未發布永不受信。Machine publication失敗時外層強制unknown/failureKind=write/hostAttributed=false/machineSHA256=null，不改寫任何partial或先前已發布收據。`machineSHA256`僅放外層stdout，取已發布machine原bytes；其他stdout欄由驗證後machine投影，發佈失敗的有限錯誤另如實回報。可信attempt/output尚未成立時不寫machine、不偽造nullable B。

各hash均取對應原bytes；外部context SHA由已核operational freeze給定，禁止工具自核review。Host不能以context自填expected hash冒充實讀binary。Bootstrap在可信input/output成立前失敗不寫任何App收據；若無可安全寫入的位置，只能caller有限unknown，無法保證壞磁碟仍可持久。

**有界鏈與freshness。** 未來CLI固定`binding-launch --context <R/context.json> --context-sha <SHA> --attempt-uuid <UUID> --ready-uuid <fresh UUID> --ready-confirmed`；本輪只實作fake接線，不invoke真R。先驗operational freeze／quota／freshready，再exclusive binding-consumed（綁context/attempt/ready/requestSHA）→attempt/request→唯一open -W -a該App、兩env及固定sentinel；無-n/raw App/重試。Runner並行等待report而非先阻塞等open退出。Host report發布後最多30秒等ACK；runner自spawn起最多30秒完成report→instance→ACK→final→native settle，逾時unknown、不kill；host自己的有界窗口自然收尾，不能因此推其他程序退出。

Launcher不信receipt自報即認fresh：核所有B、self/expected binary相等、exact frozen App檔案hash與已批准簽章proof；只查report指定的有界正PID基本metadata（先核本UID）及expected executable path，PID/start須與host report一致、start不得早於本次request createdAt、不得晚於本次觀測時間，再於ACK前重核同一instance/path。ProcessUUID只輔助關聯，不構成證據。以monotonic控制30秒；遇缺失、PID reuse、metadata/path/UID/time不符或觀測到時鐘逆轉皆unknown/拒絕，不能拿新UUID或native0補證。此為trusted operator／正常本機時鐘前提下的有界交叉觀測，不保證exec/ABA/postcheck完全無競態、不抵抗同UID惡意程序偽造或改檔；實際簽章/OS來源證據另由未來操作階段建立。

**發布與有限結果。** Report/ACK/final/launcher各只用自身固定pending→完整write/flush/fsync→directory fsync→不覆寫atomic link發布final，保留pending；最後publication後不加fallible I/O來撤回既有SHA。不改舊global writer；不宣稱跨斷電directory entry保證。只有final/pending owned同inode/bytes/exactschema/binding才能被消費，partial不因JSON完整而受信。

新binding-launch stdout/public projection固定：evidenceMode(fake-only/signed-host)、stage(preflight/consume/spawn/report/instance/ack/final/settle/publish)、outcome(hostAttributed/rejected/unknown)、failureKind(none/input/context/binary/signature/instance/replay/path/missing/timeout/write/native/other)、hostAttributed/bindingMatched/liveInstanceVerified/binaryVerified/nativeSettled五bool、nativeReturnKind(notStarted/zero/nonzero/signal/unknown)，及requestSHA256/reportSHA256/ackSHA256/finalSHA256/machineSHA256（hash或null）。不公開UUID/PID/starttime/name/路徑/Team/group/profile/原error或秘密；原native rc/signal/有限exception只留owned private machine，後續失敗不得覆蓋原始錯誤。只有全部binding、獨立binary/live-instance、ACK/final、native settle及machine publication通過才能signed-host hostAttributed=true；native0單獨、缺回報、timeout／mismatch／寫入失敗均非成功。Fake-only結果必hostAttributed=false，可用其餘bool驗protocol，不當signed實證。

**離線驗收LB01–06。** LB01 actual Swift共用dispatch/validation/writer fake入口（`--self-test-launch-binding`只fakes）測兩env/全env遺失、錯argv/input、零store/provider/SecItem能力；不要只Python抄流程。LB02 actual runner dispatch＋fake native/clock/metadata/signature providers：wrong/missing B、changed binary/context、舊receipt／同attempt重放、PID reuse、UUID-only、nonexistent process及clock reversal均不attributed。LB03 first report→kernel crosscheck→ACK→final完整bytes/hash鏈；wrong ACK/final、env傳遞、native0無receipt、timeout/無回報、原error保存。LB04 非法路徑/symlink/非owned/overwrites/partial quota；consume與machine各自缺欄/多欄/錯型別/bool冒int/違反nullable/未知enum及context/request/attempt/ready/runner/consumeSHA/receiptSHA不匹配均拒絕，不能由defaults補成有效JSON。Consume partial存在即耗額、不可spawn/replay；machine完整pending或publication失敗一律不成功，外層machineSHA=null，且machine無自身SHA。另驗native rc/signal/settled一致性、receipt鏈與fake-only不可attributed；pending完整後fsync失敗、publication/link collision、ACK/report/final/machine寫入失敗皆fail closed，fake privacy/defaults。LB05 新source unsigned Swift fake-only compile與模式結果、122舊regression及適用Python AST/Ruff、Swift format/lint；必記新main source/binary SHA，不沿舊binary證新case。本地locked dependency module缺失時只允許普通scratch編譯所需target，不Xcode/App/sign/下載更新依賴或改環境；不足記未驗/blocked、不以skip當pass。LB06 frozen四修改葉＋其他五模板一致、old evidence immutable；必要ordinary finite own-child只驗process token且自然wait，不UID enumerate/真host；fake不證簽章、環境真傳遞或真人提示。

**後續操作文案，不是授權。** LG35後另提出具體context路徑/UUID/一次quota/來源freeze／精確build-sign及read-only signature/kernel checks，Human採用才建新R；不是恢復或reset舊N。現free profile／certificate適用性與有效期unknown；只已有合法資產，缺資產或需新cert/profile/security/trust/paid即停，不能假設仍有效。另授signed build/verify後核實binary/profile/cert/AppID/group/DR/validity/fixed location、凍結proof，再另freshready一次purelaunch及實際Human count/actions/whole。這輪不建立R/inputs/ready、不build/sign/launch/DPK/清理。


### LG36 profile-free launch-report-only 候選（2026-11-03；待LG37／Human採用）

**依據及適用邊界。**

| 層 | 已確認／限制 |
|---|---|
| OS | [TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)明定無restricted entitlements的Mac app不需profile；keychain-access-groups須profile授權。這是文件支持，不是本機launch實證。 |
| DPK | 原adapter明確用access group＋DataProtectionKeychain；原DPKhost授權／有效profile gates全部維持，不用本variant驗DPK。 |
| 工具 | 模板明列keychain-access-groups；LaunchReport/binding_context不核profile/group，只綁opaque proof；舊inspect_selected的group＋embedded profile是舊工具條件。 |
| 身分／政策 | [Apple Development用途](https://developer.apple.com/help/account/certificates/certificates-overview)含macOS開發；[TN3161](https://developer.apple.com/documentation/technotes/tn3161-inside-code-signing-certificates)區分signature validity與OS可執行性。原DER日期有效／key關聯可見非trust或sign-use證明；正常Gatekeeper/AMFI仍需另授實證，不能靠strictverify宣稱必可launch。 |

只用既有CredentialStorageProbe target／Debug，不新增target/framework/config/repo leaf。`LAUNCH_REPORT_ONLY`編譯variant的頂層dispatch只選LaunchReport；legacy argv/env、原fake入口、無sentinel且無新env及其他unknown組合均reject before Probe/DiagnosticProbe/store/provider/SecTask/SecItem。新env仍依LG31 exact input核；全env遺失的sentinel只進新guard、不fallback。Variant不執行任何DPK。單純移除entitlements而保留現dispatch不合格。

原CFBundleIdentifier、CodeIdentifier、registered AppID與原certificate DER/Team保持；**拿掉com.apple.application-identifier／com.apple.developer.team-identifier權利claim，不是改registered AppID或CodeDirectory Team**。Variant預期無entitlement claims（absent或嚴格解析的empty dictionary）、無embedded profile；不要求get-task-allow／debug attach，Hardened Runtime可保持且不加例外。Xcode base注入明確關閉，不能只改模板那一個key。[Build settings](https://developer.apple.com/documentation/xcode/build-settings-reference)

**Proof delta，無新增context/request/report/ACK/final/stdout keys。** 既有兩proof葉對此variant採以下exact keys；version均int=1、purpose=launch-report-only、variant=profile-free、evidenceMode=fake-only/signed-host，hash皆lowercase64hex，bool嚴格且成功proof必為指定值；缺/多/錯型/未知值拒絕。它們不自證review，仍由外部獨立審查及operator核actual bytes SHA。Live validator只允許signed-host；fake-only僅明確fake hooks／入口可用，不由request選擇。

- build.machine.json：schemaVersion,purpose,variant,evidenceMode,sourceHashes（原九固定relative leaves→SHA）,compileConditions（ordered array恰[DEBUG,LAUNCH_REPORT_ONLY]）,scheme（CredentialStorageProbe）,configuration（Debug）,commandSHA256,unsignedBinarySHA256,buildSucceeded（true）。
- signing.machine.json：schemaVersion,purpose,variant,evidenceMode,buildProofSHA256,binarySHA256,certificateDER_SHA256（恰5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440）,teamIdentifierSHA256,bundleIdentifierSHA256,codeIdentifierSHA256,designatedRequirementSHA256,entitlementsEmpty（true）,embeddedProfilePresent（false）,signatureValid（true）,certificateValidNow（true）。

兩proof purpose/variant/mode互同，sign.buildProofSHA256等context引用的build原bytes SHA，sign.binarySHA256等context.expectedBinarySHA256／host實讀self hash。三identifier hashes對原source BID/CodeIdentifier及原DER Team的外部已核expected值，不能以self-filled值互證。Host與runner都核此purpose/variant proof，拒把舊DPK proof或任意opaque JSON當新variant證據；compiler flag／marker只是外部build provenance的一部分，不是auth。Fake proof不能升格signed證據。

**後續操作recipe，現在不可執行。** Human採用方案且離線code/test/獨立review完成後，再逐段授權下列操作；私有變數尚未建立，不是現成可run命令。

1. Agent精確只讀核原DER class/用途、日期、Team與可用existing identity來源；不inventory其他topic。Apple [WWDR CPS §4.11.25](https://images.apple.com/certificateauthority/pdf/Apple_WWDR_CPS_v1.24.pdf)對Apple Development列Code Signing EKU及OID 1.2.840.113635.100.6.1.2／.12。先前原profile匹配與過期保持歷史；本輪標準目錄按原SHA定位未找到匹配檔，未解析其他profile，故當前class未補證，不猜資產變動。原公開DER亦可由未來另授權的精確已選certificate唯讀取得，不要求恢復原profile或舊N。缺可核原DER/identity、用途不符或expired就停，由agent回報具體缺口，不要求Human調查profile；trust/sign-use只於另授簽章段驗。
2. 隔離新build路徑、既有project private copy只接own package；固定原BID/CodeIdentifier不改；locked local dependencies不足即停，不下載。Unsigned build argv形狀如下（不帶任何portal/auth/device flags，不接舊root/current）：

```sh
xcodebuild -project "$DIAG_PROJECT" -scheme CredentialStorageProbe -configuration Debug \
  -derivedDataPath "$DIAG_DERIVED" -disableAutomaticPackageResolution \
  -onlyUsePackageVersionsFromResolvedFile -skipPackageUpdates clean build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_STYLE=Manual \
  CODE_SIGN_ENTITLEMENTS= CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO ENABLE_DEBUG_DYLIB=NO \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG LAUNCH_REPORT_ONLY'
```

3. 在簽章前核exact owned新App、source/flags/build receipt、BID、無profile／restricted claims；意外profile/nested code/未知產物即停，不刪除或ad-hoc補過。從已核原DER導出SHA1 selector（codesign -s接受SHA1，不接受把DER SHA256直接充作selector）；只用exact existing keychain與原identity手動簽新產物：`codesign --force --sign "$ORIGINAL_CERT_SHA1" --keychain "$EXACT_LOGIN_KEYCHAIN" --options runtime --identifier "$UNCHANGED_CODE_IDENTIFIER" "$FRESH_DIAG_APP"`。不給entitlements或preserve舊claims；force只限此次new unsigned/只具linker signature的owned產物，不碰舊binary。缺原key、需new/revoke cert、trust/ACL/partition-list/安全或paid變更立即停。
4. 另授readonly postverify：strict signature、extract原DER SHA256精確pin、certificate class/日期/Team、BID/CodeIdentifier、empty claims、profile absence、DR及final binary SHA；nested code若存在須先另列確切簽章序列回審，不用deep signing猜處理。簽後才凍結sign proof／final expectedBinarySHA，再另授建立新R/context，不重建舊N/resetquota；原146不冒充此build。
5. 再另freshready單次既有binding-launch/LaunchServices。原兩次PID+kernel start/time/path、自身/expected binary、request/context/nonce鏈、ACK/final、last-wall／monotonic、native settle／atomicpublication皆保持。ACK前對**同一reported PID**加dynamic code validity與同frozen code identity核對（codesign --verify --strict -v及精確requirement，並比DER/Team/BID；全部bounded於原deadline、unknown就不ACK），重核instance防PIDreuse；不能以nonce當auth或因path相同省動態核對。公開投影不增raw PID/IDs/paths/errors；同UID惡意、exec/ABA/postcheck殘餘仍不保證。正常OS政策拒絕就停，不spctl放寬、不移除quarantine、不改trust。

**PF01–05，未執行。** PF01普通unsigned CLI各編default與LAUNCH_REPORT_ONLY：actual頂層legacy/envloss/unknown reject，normal fake入口共用dispatch hooks證zero store/provider/SecItem/SecTask；不讓signed variant開舊fake/credential入口。PF02兩exact proof缺/多/型別/null/purpose/variant/mode/flag/來源hash/identifier錯綁、舊DPK proof、profilePresent或非empty claims皆拒絕；fake不attributed。PF03 fake static/dynamic verifier覆wrongDER/SHA1-selector混淆/Team/BID/codeID/hash、signature unknown、PIDreuse／dynamic與static不符、deadline不新增ACK；不真簽或query。PF04原146及clock/nonce/ACK/final/native/publication/privacy不退步；unsigned新source/newvariant compile只證fake，非OS/signature實證。PF05四葉新freeze＋其他五模板保持；後續人工操作另核same original DER/Team/BID/codeID、empty claims/no profile及actual launch，從不解鎖DPK。

本輪只LG36 planning→LG37獨立review，之後Human採用才可另派離線Implementer→Tester→Reviewer；build/sign及新context/launch仍各自另核准。人類動作集中：方案採用、明確build/sign操作審閱ready、原key當次授權（沒有當次選項或需永久權限即取消）、新context授權及單次launch freshready/實際prompt觀察；不交Human調查或取得profile。現在不問ready。


### LG44 原certificate解析與sign-preparation amendment-1（候選待LG45）

**SP01 可信解析。** DER type=bytes且SHA256恰原pin必先於decode／SHA1 selector。將現有public-only x509解碼分成三份固定argv輸出：subject=`x509 -inform DER -noout -subject -nameopt RFC2253`；dates=`x509 -inform DER -noout -dates`；class=`x509 -inform DER -noout -text -nameopt RFC2253`。都只stdin同一已pin DER，沿LC_ALL=C／OPENSSL_CONF=/dev/null／10秒bounded capture；不私鑰、不trust／network操作。保留每個實際native return／exception分類，失敗不改成空成功；後call不抹原失敗。Subject只允許恰一個subject記錄與可選末尾換行，任何額外行／重複記錄拒絕。以RFC2253 escaped separator／hex escape規則拆RDN及attribute；dangling／不合法escape、multi-valued RDN、非預期subject格式拒絕，不以任意split或dedup取Team。恰一個OU，解碼值符合原Team格式[A-Z0-9]+且非空；多OU（即使值相同）拒絕。Issuer／完整text的OU永不參與subject解析。Dates僅兩個唯一notBefore/notAfter，保留UTC有效期；class仍須Code Signing EKU及兩個原Apple Development OID，不能以subject或pin代class。原postverify／dynamic identity也使用同一嚴格解析，信任／OS政策限制維持，不能把decode當trust驗證。

**SP02 有限準備證據。** 每次sign preparation初始化並逐步填exact object：`guardPoint` enum(derPin,subjectDecode,subjectParse,datesDecode,datesParse,classDecode,classParse,keychainPath,appPath,profileAbsent,infoBundle,infoExecutable,prepared)；`decoderPart` enum(none,subject,dates,class)；`decoderOutcome` enum(notStarted,zero,nonzero,signal,timeout,exception,decodeInvalid,unknown)；`decoderReturnCode` int或null（未知／未返回必null）；`subjectOUCount` enum(unknown,zero,one,multiple)；`derPinned,subjectValid,dateValid,classValid`四nullable bool，未檢查null、實際pass=true／fail=false。只記實際guard事件，不能猜stderr/errno；既有native錯誤資訊留private，不把後guard覆蓋原native結果。對外只此有限object與既有status/hash，不加rawsubject／日期原文／Team/CN/path/secret/error。不補寫LG43收據；固定輸入目前通過不代表歷史各guard通過。

**SP03 同準備root唯一明確amendment。** 以下僅future LG49準備，不在LG44建立私有檔。所有新leaf直接位於原owned準備root（不新namespace），exact allowlist：`caller-sign-amendment-1.py`、`config-sign-amendment-1.json`、`credential-storage-controller-amendment-1.py`、`preparation-freeze-amendment-1.json`、`sign-consumed-amendment-1.json`、`signing-amendment-1.machine.{pending,json}`、`signed-artifact-amendment-1.{pending,json}`、`sign-operation-amendment-1.{pending,json}`；brace各指兩個固定leaf。其餘原leaf完全不改。Caller／controller／config先exclusive0600 freeze並由外部Reviewer核actualSHA，不能自填hash當approval。新config保留原config全keys和值，另加exact `amendment` object：`id`=LG43-sign-preparation-amendment-1；`parentOperationSHA256`=d123529e216fd44ffdce0bfd4b82343e6851a00996513b9abefc1d37af5edf26；`parentCallerSHA256`=fa37d3ae267865dc0c2546f1c3806c588501ad4802f0dba851009a03788df5dd；`parentConfigSHA256`=f850bcfa2421a17f9c442048a12c3eddeb6a3455a92d383722a7a8128b213be3；`parentConsumedSHA256`=18c0df133b5b7c050909787d52484aed543ef48f3be44ca6e1ddca0e686e8df6；`controllerSHA256`為新reviewed controller bytes。其餘hash均strict lowercase64hex、id strict literal；缺／多／錯型拒絕。Freeze列new caller/config/controller hashes及全部parent hashes／原buildProofSHA／兩App treeSHA；不含自hash，外部取其bytesSHA。

原build.machine/source九葉與App仍代表原LG41 build，**不得更新sourceHashes或重造buildproof**來假裝App重建；執行工具另核新controller review SHA：新caller不得沿舊guard要求現repo三個已授變動工具leaf等於原build sourceHashes，而是核現repo runner/tests/README等於外部approved新三葉freeze（記入preparation-freeze-amendment-1的reviewedToolSourceHashes，exact三relative leaves→SHA）；原私有source九葉仍逐一核原build sourceHashes，現repo main／五模板及package inputs仍核原freeze。Controller副本SHA須等新runner SHA；caller及config SHA另由外部review核對，不自證approval。兩App都必須仍為e4f4139096f34c9f8f1a9f0e2e1a9202ed11889759ce9782528a5854d4d83614，簽副本僅於新ready後可變；原件保持。核原operation/pending同inode同bytes與unknown/sign-preparation、consumed及parent hashes、caller/config/build/source、own/no-symlink/root0700/files0600、future-context／原launch markers不存在；不符即停不repair。任何新consumed／operation pending或final存在即amendment額度已耗，拒第二次，不以缺成功proof重試。Freshready由實際新Human回覆建立，UUID不得等舊sign或launch ready；只exclusive新consumed成功後方可原公certquery/sign。Consumed exact keys為schemaVersion=1,purpose=launch-report-only,amendmentID,parentOperationSHA256,readyUUID,configSHA256,callerSHA256,controllerSHA256，型別／hash／UUID strict。

Operation沿原schemaVersion/purpose/status/stage/failureKind/signingProofSHA256/signedArtifactSHA256，另exact amendmentID,parentOperationSHA256,preparation（SP02）；hash成功才非null，unknown仍null。Signed-artifact沿原exact schema；兩proof與operation用既有pending→fsync→exclusive hardlink publication，final/pending pair才受信，不宣稱斷電保證。Signing proof維持LG36 exact schema，仍引用**原**buildproof；新名字不改proof格式。首次native錯誤／準備證據不因publication失敗變成功。未來context producer只能引用唯一成功amendment operation及新signproof，copy其bytes到context既有標準proof leaf；不改LG43，也不以舊unknown作fallback。Context／launch另有當段authority與freshready，原第二項ready已結束，不能carry。缺key／wrong class/expired／newcert/trust/ACL/Team/BID/security/paid需求停，DPK仍停。

**SP04–05驗收。** SP04以實際default三份argv輸出fixture及原config形狀跑真helper／privatecaller入口：原combined輸出含issuerOU、text Subject OU及subject記錄，先證舊parser拒絕，再證新parser只信獨立subject；多／重複subject、escaped comma/plus/hex及非法escape、多OU/duplicate OU、缺class/EKU/OID/日期、wrong DER、BID/keychain/path拒絕；所有拒絕零codesign。命令與參數須實際assert，不mock整個helper。SP05 selective NoApp regression保DER→SHA1、static/dynamic解析、parent rawbytes、freshready重放／partial spent／private exclusive publication、原錯誤及有限projection privacy；新caller/config/controller freeze再獨立審。純fake public DER可ordinary temp controlled使用，絕不查真Keychain／export key／簽App。Main/模板未變，不重build／重跑無影響Swift／146；原歷史及LG43 unknown不改。本輪只planning。


#### LG44／LG49 producer私有manifest銜接澄清（待獨立回查）

只補原LG41 context/launch pipeline的child-amendment專名，不將ready搬進尚未可信的context、不刪減操作證據。SP03 fixed root allowlist追加六leaf：`context-consumed-amendment-1.json`、`context-operation-amendment-1.pending`、`context-operation-amendment-1.json`、`launch-consumed-amendment-1.json`、`launch-operation-amendment-1.pending`、`launch-operation-amendment-1.json`（共六leaf；名稱逐列為準）。原future-context及內部LG31既有context/source/app/proof/attempt收據範圍保持，不另造namespace。

兩consumed exact keys：schemaVersion(int=1),purpose(launch-report-only),amendmentID(LG43-sign-preparation-amendment-1),parentOperationSHA256(原LG43),signOperationSHA256(已發布child success),signingProofSHA256,signedArtifactSHA256,readyUUID,configSHA256,callerSHA256,controllerSHA256；launch另有contextOperationSHA256與contextSHA256。Hash皆strict lowercase64hex、UUID為合法canonical v4；context/launch ready必是實際當段新Human authority，與原sign及child sign/context已記ready不同，不能carry舊條件ready。

Context operation exact keys沿原schemaVersion,purpose,status,stage,contextSHA256，另amendmentID,parentOperationSHA256,signOperationSHA256,signingProofSHA256,signedArtifactSHA256,consumedSHA256,failureKind。status=success/unknown；stage=copy/validate/completed；failureKind=none/guard/native/write，依實際事件；contextSHA256成功完成驗證才非null，其他必null，成功stage=completed/failureKind=none。其餘三proof/operation hashes必綁同一已發布child成功鏈，不能引用父unknown。

Launch operation exact keys沿原schemaVersion,purpose,status,stage,bindingResult,exitCode，另amendmentID,parentOperationSHA256,signOperationSHA256,signingProofSHA256,signedArtifactSHA256,contextOperationSHA256,contextSHA256,consumedSHA256,failureKind。status=success/unknown；stage=launch/completed；failureKind=none/guard/native/write；未取得binding結果時bindingResult/exitCode=null，已取得時沿LG31 exact有限binding projection及int code；只有已核child/context鏈、binding hostAttributed=true/code0才success/completed/none。原native錯誤不得變成成功。對外仍只有限status/stage/receiptSHA，不公開ready或私有IDs。

各phase由同受審child caller建立：先共同核原parent/source/build／unsigned原件不變；sign前才要求副本unsigned且context不存在。Context前核child success operation/signing/artifact三pair／signed副本tree及context不存在；launch前核同三pair／signed tree、已發布context operation及context bytes/hash/static proof。不要求簽後副本仍unsigned。各自檢查自身consumed／operation pending/final任一存在即耗額拒絕；先exclusive0600 consumed/fsync，context才mkdir0700/copy，launch才進LG31 binding一次派遣。可信root存在可記unknown operation；partial context/consumed永不清理或重試。Operation沿既有pending完整write/fsync→exclusive hardlink final；同inode/bytes才可讀，不overwrite。LG49只準備caller/config／ordinary fake測試，這六leaf及真future-context僅未來當段authority時建立；本澄清不放行執行。


### LG52：LG51-report-timeout-amendment-1（待LG53）

**事實／限制。** LG51 request建立06:09:18.361914UTC；06:09:18–19UTC（本地14:09:18–19）精確App path有OS launch/checkin與death。只證OS lifecycle，不證Swift入口。原raw request/context/build/sign/consumed的14項可靜態判定schema/hash/bool條件全符，舊build source與新controller hash分離不違Swift guard；但非真Swift/NSNumber/FS/native重現。Swift無nlink==1 guard，不臆造hardlink拒絕；真owner/mode/canonical/read≤65536及NSNumber objCType／CFBoolean仍須非live測。Same-BID現況association0、原open PID現在不存在，不推歷史reuse/退出。秒級精確目標PID窄OS關聯及原path log皆無無歧義拒絕點；TCCD DeveloperTool為preflight=yes/result0/reason5，不能當launch拒絕或Human提示。Private OS evidence basename `rivet-lg51-readonly-evidence-3odtyr90`：原path log SHA dfef95ff3d0733a5f32dc9699244fc63fe8eb561f520087b50ddcd457d2e81b3，PID窄關聯SHA76a2be33338672420b20dcf6642f8fd1632c736711e14819ccd0594f7f433de2，raw只0700/0600。

原signed App的display/extract（無verify/trust/Keychain/privatekey）已取得普通owned0600公開DER副本`original-public-certificate-reviewed-0`，SHA恰5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440；reviewed split helper真解碼class/date有效、Team match原signproof、SHA1可導出，原binary不變。這是公開資料副本，不是發證／安裝新asset。未來準備由agent讀此pin資料，不要求Human找Team/DER或先重查Keychain。

**RTT01–02：先真核心離線重現。** 保留原compiled main2fd43及原request/context/proof/source原bytes，copy到普通owned fixture（非正式context），不經Python重編JSON；原digest/schema/Swift file/read/verifyProofs/verifyContext保持真實。固定原createdAt與觀察clock僅供non-live，fake executable/instance/ACK writer只為隔離，write sink限fixture，不寫原root。Record每個實際guard的有限stage，不能mock整個validator。核真filesystem型別/owner/mode/canonical/nosymlink/size及pending-final hardlink nlink2，不一概fake成功；跨OS JSONSerialization NSNumber integer／bool／dictionary equality走真Foundation。另ordinary unsigned CLI用原live metadata accessor只查getpid自身，核SDK proc_bsdinfo fullreturn/PID/UID/status/starttime/usec；不讀其他PID/全UID、不GUI/LS。需要SDK layout可普通C/Swift compile對照，不新framework。若有真guardbug只在原嚴格語義內修，未發現不猜；self native不可得記unknown，不改安全環境。

**RTT03：最小可信入口與有限回報。** 保LAUNCH_REPORT_ONLY before-store/provider/SecTask/SecItem硬fence。新預期argv恰`[--launch-binding-only,--request,<absolute request.json>,--request-sha,<SHA>]`；原兩env保持。argv/env各只接受唯一完整pair，重複/未知args不作有效argv；優先完整argv pair，否則完整env pair只供診斷bootstrap。兩channel都缺／非法而無可信pair：只stderr有限JSON，不亂寫。

Trusted bootstrap必核candidate path canonical/nosymlink、固定attempt/request.json、root/attempt ownUID0700、request regular0600/O_NOFOLLOW/size、raw SHA及原request exact schema/purpose/UUID/hash。此時B=原六binding keys（requestSHA取rawbytes），只是可信owned輸入/output，不等於sender authentication；full context/proof/source/selfbinary/instance/clock之後仍全部必要。先exclusive entry，再做wire一致性/full validator；任一channel缺失/partial/mismatch、argv非精確shape均有限failure，零credential/DPK。兩channel有pair但不一致只用已驗優先pair綁failure，不讀第二任意path。Env中的未知RIVET_*仍拒絕。

新增attempt內固定`host.entry.pending.json`／`host.entry.json`、`host.failure.pending.json`／`host.failure.json`，沿既有完整write/fsync→exclusive hardlink，同inode/bytes才可讀。兩schema exact keys均B＋`stage,outcome,wire,observedBinarySHA256,pid,startSeconds,startMicroseconds`；failure另`failureKind`。Entry stage=bootstrap/outcome=entered；failure stage=wire/context/proof/source/binary/instance/clock/publish/ack、outcome=rejected/unknown、failureKind=input/path/schema/binding/binary/instance/clock/write/timeout/other。ObservedBinarySHA nullable64hex；三instance欄全null或正int PID／seconds及0≤usec<1000000，僅實際取得才填，不因UUID推fresh。wire exact keys：argvShape(expected/invalid/missing),argvPair(valid/partial/missing/invalid),envPair(valid/partial/missing/invalid),channelsMatch(bool|null)。不含raw argv/env/path/error。Failure保最後實際guard及已取得欄位，不能後錯蓋原錯；新entry/failure不能代hostAttributed或App/remote成功。可信output未成立／disk不可寫只stderr，不能保證必落收據。Stderr exact finite keys為purpose=launch-report-only,stage=bootstrap,failureKind=input/path/schema/binding/write/other,argvShape,envPair；無B/UUID/私ID/rawerror。

Report/ACK/final及request/context/two-proof原exact schema不變；新host成功report前必已有同B entry。Launcher嚴核entry/failure exact keys/types/nullable/enum/B/pair；self/instance未核時只是claimed diagnostic，失敗收據不能放寬binary/static/dynamic/liveinstance/ACK/final/freshness/clock/native成功條件。新machine及外層finite projection保原schemaVersion=1及原keys，**exact追加**entrySHA256、failureSHA256（hash|null）與appOutput。appOutput exact keys stdoutState,stderrState(enum unreadable/empty/bounded/oversize),stdoutBytes,stderrBytes(nonnegative int|null),stdoutSHA256,stderrSHA256(hash|null)。初始unreadable/null；僅成功bounded讀≤65536可有SHA；oversize只size、不讀全文/hash，empty hash為空bytes SHA。這是當次stream snapshot，不宣稱App已退出／內容已final；原immutable機器歷史只由其frozen舊validator解讀，不更新。新success必entrySHA非null、failureSHA=null並保原全部成功前提。

**RTT04：exact wire及native觀察。** Attempt先exclusive0600建立`app.stdout`/`app.stderr`，原launch.stdout/stderr繼續捕捉native open。Open argv沿`/usr/bin/open -W -a <fixedApp> --env <requestPair> --env <hashPair>`，再`--stdout <attempt/app.stdout> --stderr <attempt/app.stderr> --args`及上述五args；本機open(1)明文支持env/args/stream redirect。Caller不輸出raw streams，只有界snapshot。等待entry/report各迭代及timeout/finally只nonblocking poll已建立的native Popen；若實得rc則nativeSettled=true、保rc/signal，即使report沒來也保留，未得仍unknown；poll exception有限分類、不抹較早結果。Native0或已settled從不代host success，不kill、不wait超原30秒、不自動retry/-n。

**RTT05–06：單次透明後續與manifest。** Parent固定原launch operation9e3d7a44bac5284d5cb6d9cf909e08006118d2441253b63df5bf66b538266cd5、machine3aeee2627fb13800d9829fa3bf9005a4b1940ad14f6dd6c1b800027069f6da37、context operation f81564bc9cc1986355c7278eb6afef0d48bcf2042aa942a3bda27e92a63cd27f/context24fb6ede002a80bfc286e8d5f6c22e95eaff5fd8548856299bbbeafc4ed2c7d7、sign operation d8405dbeefb3759b5b2ac8e0fbc508acd08a6734f11eb9eb36b4f9f95ebc98cd/signproof38b7cfdebb5a4caca36d68050e6dce5a7e10cbbabaab61e8664bcefbb03fe285/artifact26317b77f8a27f829a858fc2b00b51be1498d5eb5c5bc47e5ac3ad370e87839c。原caller/config/controller/freeze及所有ready/consumed/pairs原bytes也核LG50 pins。

同原prep root固定新名稱，不建立獨立random run藏失敗：`caller-report-timeout-amendment-1.py`、`config-report-timeout-amendment-1.json`、`controller-report-timeout-amendment-1.py`、`preparation-freeze-report-timeout-amendment-1.json`；`source-report-timeout-amendment-1/<BINDING_SOURCES九leaf>`、`project-report-timeout-amendment-1/<同九leaf>`（僅private PBX localpackage path差異另外pin）；`derived-report-timeout-amendment-1/`僅無簽章build產物；`unsigned-report-timeout-amendment-1/CredentialStorageProbe.app`及`to-be-signed-report-timeout-amendment-1/CredentialStorageProbe.app`。新build proof／command／logs為`build-report-timeout-amendment-1.machine.{pending,json}`、`build-report-timeout-amendment-1.command.json`、`build-report-timeout-amendment-1.stdout`、`build-report-timeout-amendment-1.stderr`。

未來sign/context/launch各有`<phase>-consumed-report-timeout-amendment-1.json`與`<phase>-operation-report-timeout-amendment-1.{pending,json}`，及`signing-report-timeout-amendment-1.machine.{pending,json}`、`signed-artifact-report-timeout-amendment-1.{pending,json}`。Schemas沿LG44/SP03＋六leaf澄清，只literal amendmentID改LG51-report-timeout-amendment-1、parentOperationSHA256指原LG51launch；launch operation bindingResult含上述新有限projection。固定child `future-context-report-timeout-amendment-1/`沿LG31 app/source/proofs/context/binding-consumed/attempt原allowlist，追加上述entry/failure及兩App stream leaves。它是明列parent失敗的一次子amendment，不替換原future-context，不reset其spent。各phase marker/operation pending/final或child attempt任何partial即該phase耗額；未來build/sign/context/launch按自己guard，不把signedcopy再當unsigned。

New config沿LG49基底keys，但build/source/paths改為上述新產物；追加publicCertificateDERPath指已pin ordinary publiccopy。amendment exact keys為id、parentLaunchOperationSHA256,parentMachineSHA256,parentContextOperationSHA256,parentContextSHA256,parentSignOperationSHA256,parentSignProofSHA256,parentArtifactSHA256,parentCallerSHA256,parentConfigSHA256,parentControllerSHA256,parentFreezeSHA256,controllerSHA256。Freeze exact keys沿LG49：schemaVersion,purpose,amendmentID,parentHashes,callerSHA256,configSHA256,controllerSHA256,reviewedToolSourceHashes,buildProofSHA256,unsignedOriginalTreeSHA256,unsignedCopyTreeSHA256，另privateProjectSHA256,publicCertificateDER_SHA256；reviewedToolSourceHashes本輪恰四工具relative leaves→SHA，全部hash64hex/ID strict。外部Reviewer核actual SHA才有authority，不由caller自行approve。新build/sign proof仍LG36 exact格式，記新實際main/flags/source9；舊build/proof完全不改。

本輪main改變即必須新unsigned App build，原LG51signedartifact不能冒充新host。Recipe沿LG36同target/Debug、CODE_SIGNING_ALLOWED/REQUIRED=NO、空entitlements/base injection NO、DEBUG LAUNCH_REPORT_ONLY、locked packages及no provisioning flags；LG57可備真正unsigned產物與exact caller/config/proof，不真sign/context/LS。未來公DER pin→class/date/Team→deriveSHA1 sign selector，原key/Team/BID/codeID不換；不重查Keychain取得公開cert。真正sign/postverify/newcontext/唯一binding-launch由LG58後最後集中新Human窗口逐段授權，精確caller flags沿LG49，但caller/config新SHA須產物freeze後實得、不能預填；new context及expected binary亦只簽後建立。拒絕、缺key／需newcert/profile/trustACL/security/paid改動即停，不自修安全設定。

**必要測試矩陣。** A/RTT01原rawbytes＋原clock→真Swift core/FS，記首個實際失敗點及rawbyte/hash未變，不由NoApp fake report代Swift成功。B/RTT02真FS與NSNumber/CFBoolean／SDK selfPID accessor正常/不可得；permission/canonical/symlink/size/mode/型別負例不放寬。C/RTT03 exact argv/env、雙channel缺/partial/不一致/unknownRIVET、legacy/envloss零DPK、entry/failed receipt exactschema/nullable/missing/extra/replay/writefail；不信任路徑零output。D/RTT04 actual subprocess fake child/nativeprovider：report永不來但open rc0/nonzero/signal/exception/timeout/pollerror各自保留，App與native兩stream路徑/參數精確，不exit0=pass。E/RTT05 publication/Human/freshness/clock/staticdynamic/binary/ACK/final成功前提及rawprivacy不退；選擇性受影響回歸，不重跑無影響146/44/37。F/RTT06 actual privatecaller NoApp跨phase/sign改copy、parent pins/once/spent/ready replay/provenance/公開DER準備與futurecommands可審；fake不證OS/sign/DPK。本段作者不執行測試。


### LG60：單次 profile acquisition（2026-11-04；待 LG61）

**固定輸入。** 只原 feature worktree；原 cert pin 沿 requirements LG60。使用 LG59 已核且仍存在的公開 DER 副本，先 hash 再從獨立 subject 解析原 Team，不讀私鑰；BID／CodeIdentifier 取現行 target 的 PRODUCT_BUNDLE_IDENTIFIER，與原受審 config 的 expectedBundleIdentifier／expectedCodeIdentifier 相等才繼續。Exact group 採原 target `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`：prefix 必由取得 profile 的 ApplicationIdentifierPrefix 與 application-ID entitlement 核實，不把 Team 當成 prefix 猜值。若原固定輸入不能從已知資料一致還原即停，由 agent 回報具體缺證，不能換身分。

**唯一操作／私有 manifest。** 已知 owned preparation root 下固定 `profile-acquisition-1/`，是資產取得紀錄，不是 diagnostic context／DPK namespace。全祖先 canonical／無 symlink；本目錄及子目錄 ownUID/0700、regular files exclusive0600＋fsync。目錄或 consumed／pending 任一存在即耗額，partial 停，不自動重試、刪除或 reset。精確 leaves：`inputs.json`（固定 input hashes、預期 BID／Team／group 表達式及原 DER pin，private raw 值不公開）、`before.json`、`consumed.json`、`operation.pending.json`、`operation.json`、`after.json`、`profile.provisionprofile`。另 `project/` 只複製原 target 所需六檔：project.pbxproj、兩 shared schemes、Sources/main.swift、Resources/{Info.plist,CredentialStorageProbe.entitlements}；不複製／修改 LG59 project/App/caller。複本 PBX local-package path 指原 feature，只有 App target 的 Team／Automatic／profile 選擇可由本次 Xcode 操作變更，BID、sources、entitlement template、package lock 不變；inputs 保存修改前 hashes，operation 保存修改後 hashes，不篡 frozen inputs。

**選定執行路徑。** (1) agent 先建立 owned 紀錄／副本，唯讀記 before：兩標準 profile 目錄直接檔 hashes、候選公開 DeveloperCertificates fingerprints、原 DER pin 存在與有效日期；不輸出其他 App 資產。 (2) 開 exact copied project，Project navigator → CredentialStorageProbe target → Signing & Capabilities → Debug；原 Team 由已 pin DER 與既有帳號 Team 一致核對，勾 Automatically manage signing，保留原 BID／group，等待此畫面的 provisioning resolution；不點 Run、Build、Fix Issue、Manage Certificates。進入帳號／任何可能更新資產的 UI 前，先 exclusive consumed、pending，綁 inputs/before hashes；這就是本次唯一已授操作，不使用任何舊 ready。既有登入可直接用；需要 password／2FA／unlock／私鑰授權則保留同一操作待 Human 手動，不收錄秘密，不把一次流程重新建立成另一 operation。只接受標準 Automatic 的必要 cert 新增，遇 revoke／配額需刪 cert／新條款或付費／換 Team／改 trustACL 立即停止。 (3) resolution 後只窄讀新／更新的標準 profile 檔與 exact target 所指 profile；複製匹配原 cert 的原始 bytes 至固定 leaf，不 overwrite。若 Xcode 只有實際 signed build 才能產 profile，停止並回報此具體限制；本次不能為取得 profile 簽 App。沒有可用候選或 native/UI failure 即結算，不再嘗試另一條路。

**真驗收。** 保存 raw profile SHA；CMSDecoderCopySignerStatus 的 signature status 與 evaluateSecTrust=true 所得既有 Apple signer chain／平台信任均須成功（不能把 noverify／nosigs 解碼當真實性）；若需新增 trust／權限才可驗則停。核 creation≤now<expiration、原 DER exact inclusion 且原 cert 日期有效、Team 與原 DER 同、application-ID 為同 prefix＋固定 BID、keychain-access-groups 授權上列 exact group、ProvisionedDevices 含本機（由本次 target destination 已知資料核對，未知即停）。AppID prefix 不強制等於 Team。after 記前後檔 hashes／新增公開 cert fingerprints；不得撤銷原 cert，不能以原 DER 檔存在推原 cert 遠端未撤銷。任何未驗項維持 null／unknown，不算可用 profile，不簽／啟 App 來補證。

**有限結果。** before/after/inputs 均 private；operation schemaVersion=1，purpose=`profile-acquisition-only`，status=`success|unknown|blocked`，stage=`inputs|account|provisioning|profile-validation|complete`，failureKind=`none|authenticationRequired|missingInput|provisioningFailed|signedBuildRequired|profileUnavailable|profileInvalid|unexpectedAssetChange|io|unknown`，inputsSHA256/beforeSHA256 必 hash，afterSHA256/profileSHA256 可 hash|null，originalCertificateIncluded/teamMatch/appIDMatch/groupAuthorized/deviceMatch/dateValid/cmsSignatureValid/appleSignerTrusted 各 bool|null，originalCertificatePreserved/newCertificateObserved 各 bool|null；success 必所有 match/valid/preserved true、stage complete、failure none。pending 含同 schema/purpose、inputsSHA256/beforeSHA256；consumed 含 purpose、inputsSHA256、operationUUIDv4。結算 once exclusive operation，連失敗也保存有限結果；不可寫入就回有限 io/unknown，不假稱已持久。公開僅上述有限狀態／hash／bool，不 raw IDs／subject／path／native error；Human 提示觀察另由原 live-validation leaf 的 Tester 綁 operation SHA 記實際 count/whole/actions，未答不填零。無新增 repo 工具或驗證框架。

官方依據：[Personal Team 由 Xcode 管理資產](https://developer.apple.com/help/account/basics/about-your-developer-account)、[manual download 的 Program 資格與動作](https://help.apple.com/xcode/mac/current/en.lproj/deva899b4fe5.html)、[DPK 權利與 profile](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)。這次允 Automatic provisioning，不再以舊 manual 路線不足阻擋；是否實際成功以 bytes／授權驗證為準。


### LG65：受限 DPK delta（待 LG66）

沿LG64已驗profile/result與LG59原身份；只快核既有原bytes、日期、source freeze，不在本文重列識別值、不重CMS/取得。只改既有main/runner/tests/README；production/API與五target模板不改。

新增與LAUNCH_REPORT_ONLY互斥的compile flag DPK_VALIDATION_ONLY、purpose=dpk-credential-validation。新branch五argv為`--dpk-validation-only --request <固定request> --request-sha <digest>`；fallback僅RIVET_DPK_REQUEST/RIVET_DPK_REQUEST_SHA256。未知/遺失/partial/mismatch先拒、不回legacy、不建store。Profile-aware verifier只屬此purpose；report-only拒profile/零DPK維持。DPK實際entitlements精確application-identifier、team-identifier與唯一keychain-access-groups，值取LG64已核input，不能猜prefix等於Team。原identity/static/dynamic/binary/clock/ACK/final/native/publication全部保留。

固定既有owned preparation parent下`dpk-acceptance-1/`為透明新round，明綁LG59機器成果與LG64驗證結果（值由原evidence讀取）；不復原/重設任何舊namespace。目錄/partial既存即spent。Service沿原UUID格式但必當次load=nil才證空；account credential、固定fake client/A/B沿Probe。Root固定round.json、profile.provisionprofile、entitlements.plist、context.json、context-rebuilt.json、build.machine.json、signing.machine.json、rebuild.build.machine.json、rebuild.signing.machine.json、app/CredentialStorageProbe.app、unsigned-debug/、unsigned-rebuilt/、兩to-be-signed副本、caller.py/config.json/preparation-freeze.json/OPERATIONS.md。真round/context只fresh授權後建；準備只ordinary unsigned與完整producer。round immutable承接原context source/identity/proof欄，精確另含roundUUID/service/account/clientID/group、deadlineUTC、parentLG59MachineSHA256、parentLG64ResultSHA256；原context新增roundSHA256/profileSHA256，initial/rebuilt各自綁真產物/proofs，不自我hash。build/sign proof沿原schema改DPK purpose與dpk-entitled variant/實際compile flag，DPK sign proof記profile/entitlement/group digests；empty-claims條件只在DPK分支改成exact授權核對，不全域放寬。

每phase固定phases/<save-a|read-a|replace-b|read-b|rebuilt-read-b>/，用既有request/entry/failure/report/ACK/final/machine及pending、四streams和binding-consumed.json同名leaves；directory/consume/partial任一存在耗該phase一次。B沿原schema，只DPK精確加roundSHA256與phase，所有訊息相同B。Ownership固定ownership/absence.json及write-attempt.json，沿原值/完整檢查與exclusive+fsync；owner0700/regular0600/canonical/nofollow與原publication維持。

Host完整核ctx/round/attempt/phase/profile/group/selfbinary/deadline後report，launcher核liveinstance/staticdynamic/binary/clock才ACK；host再核ACK/selfinstance/clock/deadline，**同程序同流程**重用Probe.perform/正式facade，不另跑Probe.run。Save-a必nil→durable absence→durable write-attempt→save/read六欄A；依序writer確認終止→freshA→完整B→freshB→真Rebuilt→freshB。後段須前段machine及Human已核，read/replace須同round ownership；PID或UUID不同不是fresh證據。DPK final精確多operationResult={phase,comparison:{accessToken,refreshToken,accessTokenExpiresAt,refreshTokenExpiresAt,tokenType,grantedScopes:bool},ownershipVerified:bool}，與同B/report digest/ACK digest鏈相連；DPK machine新增operationResultSHA256(hash|null)、operationVerified(bool)，只能由可信final六true及ownershiptrue算pass。原有限錯誤/native結果保留，missing/invalid/result錯皆unknown，exit0不代成功。

Runner新增dpk-prepare --repo --parent --profile（只unsigned/producer）；dpk-stage --root --phase --ready-file及dpk-observe --root --phase --human-file。受審caller準備固定prepare/sign-debug/context/rebuild/sign-rebuilt子命令；兩原scheme/config不變，unsigned使用Manual、CODE_SIGNING_ALLOWED=NO/REQUIRED=NO及DPK flag，無provisioning flags；manual sign只既有原key/受審profile，來源DER自動推selector且post核原identity。不簽新artifact前不得建立正式context。LG70須提供actualcaller/config/完整命令與proof凍結供LG71，本文不冒充現成CLI。重建須同source/identity/profile/claims/DR/固定App位置，新binary及編譯marker，新proof/context-rebuilt，不覆原proof。

固定deadline=2026-11-04T10:06:29Z，CLI/host/store入口核剩餘時間與逆轉；unsigned build需≥540秒、sign≥210秒、runtime≥60秒才能start，否則有限deadline stop且不consume新live額度。到期不新spawn/SecItem/下一段；已開始只自然settle/保存，不kill/cleanup/retry/延長。每段freshready與實際count/whole/actions綁machine；沉默/未知不可推零或pass。原首次save/fresh-read門檻維持；replace0、各build/sign原key授權≤1待Human明示採用，未採用不live。

DK01–06 affected驗收：01真Swift parser/FS/NSNumber/兩channel/fence及原report-only不變；02 profile-aware目的/claims/binary/instance/clock/deadline負例；03真Probe.perform＋正式adapter fakeSecurity的nil/proof/save順序、完整替換/失敗，ACK前零SecItem；04同B result/ACK/final wire、partial/replay/publication/timeout/native0不假pass；05實際NoApp自有普通child跨五phase、fake sign真改副本、fresh/ownership/quota，最低native/hooks fake、不mock核心；06兩unsigned config/sourcefreeze/Rebuilt marker與不同binary、原模板/profile/history不變。只最小受影響回歸與AST/Ruff/Swift strict，不重跑原未受影響suite/CMS/純App。


### LG73：新live authority／deadline最小delta（候選待LG74）

**來源缺口與邊界。** Python DPK_DEADLINE/dpk_time/dpk_round及privatecaller guard/rebuild timeout、Swift DPKValidation.cutoff/time/round及DPKDeadlineStore仍固定舊窗口。不能換常數或live monkeypatch。新增獨立window資料；舊schema未帶authority只走原legacy截止且現在failclosed，不推新期限。LAUNCH_REPORT_ONLY及已核offline結果不變。不新mission/框架/credential模型；只既有main/runner/tests/README、privatecaller/config與owner evidence。

**信任邊界。** Window/attempt使用安全亂數UUIDv4與不可覆hash鏈防混用；UUID、hash、ready旗標不是人類身分認證，也不宣稱抵抗同UID惡意改檔。Human真實回覆與獨立review freeze由既有Dispatcher/Tester外部信任流程核對，不能由caller自填hash自批。沒有該真實回覆不得產生下述human檔。所有metadata exactkeys/types，bool拒整數、整數拒bool/fraction、SHA沿既有hash規則；private owned0700/regular0600/canonical/nofollow/exclusive+fsync與原publication模式保持，原候選/窗口/收據不改。

**三個精確schema（均schemaVersion=1、purpose=dpk-credential-validation）。**
- `descriptor.json`：schemaVersion,purpose,roundUUID,sourceHashes（新App實際buildsource9）,operationalSourceHashes（實際controller/producer來源，與build史分離）,callerSHA256,controllerSHA256,unsignedDebugBinarySHA256,unsignedRebuiltBinarySHA256,profileSHA256,certificateSHA256,identityInputsSHA256（固定Team/BID/codeID/group/claims）,parentLG59MachineSHA256,parentLG64ResultSHA256,parentOfflineFreezeSHA256,maximumWindowSeconds（int=3600）,bootSessionPolicy（固定字串darwin-kern.bootsessionuuid-sha256-v1）,allowedPhases（下列固定次序）,promptLimits（下述exact dict）。除兩map/phase list/policy/int外，UUID/hash按名稱型別，不容null/extra。離線先凍結；不含未來signedbinary或authority，無自我hash。Rebuilt unsigned是準備佐證，正式仍必read-b後clean/build。
- `human-window.json`：schemaVersion,purpose,descriptorSHA256,liveAuthorized(bool=true),ready(bool=true),readyUUID(v4),readyAtUnixSeconds(int>0),readyAtMonotonicNanoseconds(int>0),bootSessionSHA256（下述canonical SHA256）,windowSeconds(int,1..3600),acceptedPromptLimits（exact同descriptor）。由trusted operator在真正回覆時捕捉UTC/monotonic，不能等開窗時把ready時間向後移。Policy exact keys：saveMaxPrompts=1、freshReadMaxPrompts=0、replaceMaxPrompts=0、buildSignMaxKeyAuthorizations=1；後兩值僅Human明示採用才寫入，不接受缺項/默認/較寬值。Human不採用則不開窗，交回具體決定，不自行換門檻。
- `live-authority.json`：schemaVersion,purpose,evidenceMode(signed-host；只有明確NoApp test boundary可fake-only，CLI不能選),windowUUID(v4),roundUUID,descriptorSHA256,humanAuthorizationSHA256,startsAtUnixSeconds,expiresAtUnixSeconds,startsAtMonotonicNanoseconds,expiresAtMonotonicNanoseconds,bootSessionSHA256（逐值同Human record）,allowedPhases,promptLimits。兩start逐值同Human record，兩expiry=start+windowSeconds（ns換算）；UTC expiry不得越profile/原cert有效期。phase/policy逐值同descriptor；不得null/extra。Window不是事前起鐘；mint動作時間≥ready且ready age≤60秒才可開，elapsed已計入duration。

固定allowedPhases次序：sign-debug,context,save-a,read-a,replace-b,read-b,rebuild,sign-rebuilt,context-rebuilt,rebuilt-read-b。每phase當段freshready使用原readyUUID；後續phase檔在原欄位外精確加authoritySHA256、readyAtUnixSeconds、readyAtMonotonicNanoseconds。新attemptUUID只在當段ready驗妥後mint，沿B既有attemptUUID作phase correlation，不另加B欄位。ready age≤60秒、同authority、不得跨phase/重用UUID；初次Human record的ready只可供sign-debug，不替後段授權。Prompt觀察仍實答count/whole/actions綁machine SHA，不自動產真Human觀察。

**固定private manifest與API。** 新parent-linked operative-live-1 revision保存原候選不覆寫；既有caller/config/proofs/operations family沿用，僅新增descriptor.json、human-window.json、window-open-consumed.json、live-authority.pending.json/live-authority.json、phase-ready/<固定phase>.json。真正Human回覆前，後五種future文件均absent，不mint/window consume。`caller open-window --descriptor-sha <已審凍結值> --human-file <固定human-window.json>`：外部先核獨立Review及實答，再由factory核全部inputs與time/policy、exclusive consumed（schemaVersion,purpose,descriptorSHA256,humanAuthorizationSHA256），mint安全UUID並原pending→fsync→atomic link發布authority；只要window-open-consumed或authority pending/final任一存在（含partial）即spent；已準備revision目錄/descriptor本身不耗開窗額度。不自動retry/renew/改deadline。沒有任意duration/issuedAt/deadline CLI旗標。其他已備caller action改成必讀此fixed authority與當段human-file，不由ready-confirmed布林自行開窗。R內新增immutable `live-authority.json`原bytes副本；新DPK round/context各精確加authoritySHA256，round.deadlineUTC必是authority expiry的UTC秒格式。既有B不變，contextSHA＋roundSHA把authority帶進request/entry/report/ACK/final/machine；任何複本/hash/round/phase不符在native/SecItem前拒絕。

**簽章接合不循環。** Authority只綁已準備unsigned來源/identity/profile及descriptor。新DPK build/sign proof精確加authoritySHA256；build的原source/provenance值不改寫，sign proof在本次原key簽完、靜態驗證成功後才記真signed binary/hash；再生成綁該proof與authority的context。不得預填signed SHA或把新controller hash塞舊build史。新main因window驗證碼改動，必先新ordinaryCLI與兩unsigned App/sourcefreeze（無sign/Auto/provision），完整NoApp受測及獨立Review完成後才問Human；原unsigned/App/snapshots保留，不稱舊App支援新窗口。正式rebuild仍read-b＋Human成功後重新clean/build、新binary/marker、原identity/profile/claims/DR/固定位置、新proof/context-rebuilt。

**RF-LG74-01 boot-session精確綁定。** 可信來源僅本機Darwin `sysctlbyname("kern.bootsessionuuid")`，不是env/CLI/檔案自填值。Python/Swift使用相同bounded讀取：固定64-byte buffer，rc=0、回傳長度37、唯一末尾NUL，前36 bytes必為ASCII UUID `8-4-4-4-12` hex/hyphen且非nil UUID；其他長度/編碼/空白/額外NUL/失敗均拒絕。Canonical bytes為ASCII `rivet.dpk.boot-session.v1\n`＋UUID lowercase ASCII＋`\n`（兩個\n均代表單一LF byte 0x0a）；SHA256輸出lowercase64hex作bootSessionSHA256，raw UUID只私有memory、不公開。Human record由trusted operator於freshready時以boot讀取夾住UTC/monotonic捕捉，前後canonical hash必同；open factory重新讀current boot並與Human欄位逐值相同，authority承接同hash。各participant在接受authority及每次既定native/SecItem/ACK/成功guard時重新核current boot hash；不符或不可得在任何新副作用前failclosed。Descriptor只凍結來源政策、不預填未來boot值；既有Human hash→authority hash→contextSHA/B鏈承接新欄位，不加leaf或B欄位，也不把boot hash當認證。

**時間及停止。** UTC與單調時鐘兩者都綁窗口並檢每participant已觀測倒退；window monotonic統一用Darwin mach_continuous_time＋timebase轉ns（同機跨程序，同一開機session），不拿不同base的clock直接比。不可得/clock不同domain/current bootSessionSHA256不符或不可得/now小於start均拒絕，不支援跨重啟續窗、不宣稱防惡意系統改鐘。保存原monotonic迴圈/clock-reversal guard；已驗window值顯式傳入store wrapper/operation，不全域覆常數或live clock。各native/SecItem前及ACK/成功接受前重查；whole action start reserve至少build540s、sign270s（public preparation30+sign180+postverify30+保存30）、context/runtime120s；每個下層native另核自身timeout與保存餘裕。到期不新spawn/SecItem/postverify/下一phase；已開始command只自然settle保存rc/error/log/已得hash，未完成核對的proof/null/unknown不補成功，不kill/cleanup/retry。超時後仍可純檔案記錄已發生Human觀察，但不可解鎖下一段；DPK-only machine/host-failure新增有限failureKind=deadline，outcome=unknown且hostAttributed=false，保留已得native/operation事實，report-only enum不變。無authority的舊入口仍原expired。

**NW01–06 affected驗收。** 01真正Human-record factory/schema/hash/clock/policy、無檔/extra/type錯/未授/舊ready拒且零native；02 descriptor→authority→round/context→B→proof/ACK/final真wire，換authority/round/phase/unsigned或signedproof/replay/partial皆拒；03 UTC/mono start/end/倒退/不可得、boot canonical bytes/Python-Swift一致性、boot值不可得/錯型別/不符，以及跨boot但UTC/mono均表面合法仍零native/DPK；remaining不足及到期途中原rc保留、禁止下一native/postverify/SecItem、觀察保存不解鎖；04原legacy cutoff保持expired、CLI不能選fakeclock或自行deadline、fake-only權威不能signed-host；05以實際新caller＋frozen新Swift核心跑完整五phase/Rebuilt NoApp/own child退出/六欄/once/ownership，新authority缺/錯負例，不mock核心；06 finalsource普通CLI/兩unsigned App真build/proofs/命令與固定parent freeze、原歷史/profile不變。只必要affected checks，不重CMS/取得/未變production全面suite。


### LG82：closeout受限契約 CD01–05

**CD01 現況及文字權威。** LG81-Cap-R completed／approved、required fixes=[]，引用本topic既有live-preparation-review與live-validation對應段；不重算gate、不擴成真OAuth或所有OS／簽章環境保證。AC01–08沿S05/S06；LC01–05／07本輪DPK已通過。Cleanup LC06未做／本輪不授，Human visual及S08未答；將兩者保留為獨立尚缺。早期unknown與各輪失敗／提示敘述仍原意原bytes，現在式摘要不能覆寫它們。

**CD02 文件最小回寫。** 只改plan LG82 D六葉的能力／驗證／導覽段：正式adapter原API/兩item/clientID/六欄/一致性/provider ownership不變；真credential DPK跨程序、完整替換、writer退出、新reader及真同身分重建與本次各runtime Human0已在指定環境成立。Configuration item、denial、斷電／crash durability、跨程序refresh競爭、其他環境、真OAuth/API/產品登入不能從本輪推得。舊storage-sequence bytes不改；在長期credential doc標初始adapter snapshot，未畫本輪host/authority流程，技術QA原證據沿用、Human視覺pending。Validation README開頭加現在式結果與歷史章節邊界，不把舊命令當新ready或續行授權。README純文字更新會產生新doc hash，舊buildsource9/manifest/proof/hash不改、不稱9/9仍為當前README；code八葉仍沿既有獨立review。沒有新live/build，不為doc改動重建或鬆綁source guard。

**CD03 evidence及PR草案。** 只在既有evidence依owner追加：publication.md保存交付摘要、擬議PR title/body、驗證／Human／cleanup／整合限制及暫擬commit語意；不新增summary或實際更新PR。其他七evidence只追加各自角色結果／必要索引，不互改verdict。更新step頭現在狀態，以LG81-Cap-R completed與後續closeout步驟取代stale current LG79；舊row／歷史不改。任何source/receipt freeze沿當時原bytes，不把新文件當新驗收證據。Published PR仍OPEN Draft、HEAD ec193a26；上述遠端／base狀態沿Planner本輪audit，後續實際操作前需唯讀再核，不假已發佈收尾變更。

**CD04 PR整合尚缺。** Planner audit：dev／origin-dev 758aca9b，五個conflict為README.md、Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md、docs/design-principles.md。本topic public configuration＋typed finite error／空字串拒絕，dev internal／AuthError／trim拒絕有契約差異。現在只在publication草案列未整合，不merge/rebase/cherry-pick、不混dev code／改public contract／做相容層。日後另授整合時先核config公開surface及consumer與原行為再審；未確定相容性即停，不能拿本輪文件review當整合通過，也不以merge禁令阻止本次文件收尾。

**CD05 有限驗證及提交邊界。** 新docs只查relative links/敘述對證據/whitespace/有限secret及本機abs掃描；不開raw私有資產或重跑suite/build/sign/App/DPK/CMS。原工具交付沿LG77/LG79/LG81及各freeze的獨立證據，不說成今日重測。Git stage另由受派Implementer在成果Reviewer approved後只用plan exact allowlist；先讀index，任何未知staged項不reset，停回報。排除兩個既有個人.swiftpm xcschememanagement leaf及所有xcuserdata/private/build/credential資料，保存其bytes；不使用add -A／add .。Stage後核完整path set及diff --cached --check，將實際staged diff依git-commit-convention提出語意邊界/message供Human。此輪不commit/push/merge/rebase/PR write；圖視覺、S08與cleanup／整合缺項不因stage而核准。


## LG89：衝突整合的 configuration 契約

本節取代本輪 integration 尚未決定的 constructor 選擇，不追改歷史結論：

1. `GitHubOAuthAppConfiguration.swift` 保留 feature 版本的 public immutable fields、configuration store protocol、脫敏 diagnostics 及 `init(clientID:clientSecret:) throws(GitHubOAuthAppConfigurationError)`。空字串是 `invalidConfiguration`；任何非空字串（含全空白／換行）原樣保存，不做 trim。dev 直接 constructor 的 AuthorizationError 預期改為這個已採用契約，須以精確測試／長期文件明示。
2. dev 的 `GitHubOAuth.makeTokenFetcher(configuration:)` 與 `makeAuthorizationSession(configuration:redirectURI:)` 已各有一般 `throws`，因此不改 signature；新增共用 private validation，對 clientID／secret 各用空白與換行判斷是否 blank，失敗拋無 payload 的 `GitHubOAuthAuthorizationError.clientConfiguration`。檢查必在 fetcher／exchanger／session 建立前；合法值不 trim、不改 token lifecycle／request 行為。新增先驗敘述後，fetcher factory 保留明確 return。
3. 不修改 internal session／code exchanger 或驗證 App；不把 constructor 改動宣稱成所有 dev consumer 完全無差異。特別是 App 環境 `try?` 的 blank-only 起始狀態限制如 requirements LG89；授權入口仍拒絕、不放寬遠端授權。
4. 四個 Markdown conflicts 合併兩邊仍成立的產品／架構能力與獨立工作線結果，消除現行 DPK／初次授權 deferred 的矛盾。E007／登入歷史保留原歸屬、日期與限制；只整合 dev 既有內容，不編寫該工作線的新實作。原圖 bytes 與 live 證據不改，不執行 signed host。

### CF01–CF05 必要驗收

| ID | 驗收與證據界線 |
|---|---|
| CF01 | 準備 `758aca9b` 到原 feature 的非提交 merge；五個已知 conflict 全部消解、無 unmerged index／新 conflict markers。額外真 conflict 先列具體差異，不用 ours／theirs 全檔覆蓋；新 merge commit 保留雙親，無 rebase／force。 |
| CF02 | 直接 constructor 的兩空值 typed-error、public typed-throws consumer、全空白／換行仍可建構且原值不 trim 均成立；診斷無 credential／secret。兩個 factories 分別拒絕 blank clientID 與 blank secret、error 精確 AuthorizationError，先拒絕而不建 session／fetcher；合法路徑原測試維持。 |
| CF03 | 以 fake backend 跑受影響 DPK configuration／store/provider、授權 factory／session／code exchange suites、public consumer 與 GitHubIntegration static isolation。先以新 factory 負例展示無 guard 的失敗，再最小修正；未影響真人／完整 CLI／其他 topic suite 不重跑。精確命令、結果及來源差異由 Tester 核實，不能用測試期待改名冒稱無回歸。 |
| CF04 | 衝突文件的現行能力／連結與 typed-constructor／factory 邊界準確；有限 whitespace／相對 links／秘密及本機絕對路徑檢查。已通 DPK 只限原假 bundle／指定環境／來源，不聲稱新 merge binary 已真人驗收；cleanup／visual／S08 不勾完成。 |
| CF05 | 原 dev tip 所帶無衝突 changes 與本輪手動修復明確分層，兩個個人 metadata bytes 保留且不 stage。獨立 Reviewer 後核真正 staged tree／parents／scope，再依 git-commit-convention 提新 message；Human 明確確認前不 commit／push／更新 PR。 |


### RF-LG94-LINT：唯一排版 delta

唯一新增手動葉為 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`。在 `targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports()` 的 expectedPaths 陣列，將 `"Contracts/CredentialTypes.swift",` 與次行 `"Contracts/GitHubAccessTokenProvider.swift",` 放同一行，除此無變更。以去 whitespace 後逐 byte 相等為 invariant；檔801→800、函數81→80，不改任何 allowlist member、排序／assertion 或 import policy。私有精確 candidate 的 strict swift-format／SwiftLint 已通，但不冒稱 repo source 已修或獨立驗證。

窄驗收：實際 repo delta 與 candidate 相同／非 whitespace invariant 成立；strict format／SwiftLint 重驗該檔；只跑 GitHubIntegration StaticIsolationTests，不重跑74／11或真人；其他已審來源／兩個人 metadata 不變。planning／成果獨立 bounded review後，刷新實際 staged SHA／tree／統計及 commit 語意檢查；message仍為 Human 已確認的同一 integration fix。正常 hooks 不 bypass、不 disable 規則，不更改 thresholds。若必須改非排版語意則停回審，不能將本節當擴scope授權。


## LG95：受限 post-merge 收尾

1. 執行前再核 PR merged/closed、merge `c8c989a2e4be99e73c9cdc17e82cc16ada7a489c` 的雙親／tree、remote dev／feature refs 與原 worktree 狀態。允許最窄 fetch dev 取得缺少的 merge object；只在原 feature worktree FF 到同 tree 的 merge pin，先保護本輪 owned planning／evidence、確認與 incoming 檔案無重疊，不 reset／autostash／改 main dev worktree。
2. Annotated tag 固定為 `v0.1.60-github-oauth-credential-persistence`，精確指向上述 PR merge，不指向後續文件 commit；先核 local／remote tag 無碰撞再正常建立／push、核 annotated object 與 peeled commit 一致。不是 GitHub Release；不覆寫／force。
3. 兩個 metadata 的來源只接受當輪私有 inventory 的兩個精確 regular-file leaves（公開以 M1／M2 表示，原始路徑／私人識別只存 Git 私有區）。在 common Git dir 下 exclusive 新建 0700 archive；保存原 bytes／權限與來源對照、大小／SHA，copy/readback 核符且移出前來源仍一致，才只移出那兩個 source leaves。任何額外／改變／未知來源保留並停止該動作，不刪未知或父目錄；archive 不 track／push。其他 untracked 不獲此授權，沒有 DPK／Apple 資產清理。
4. 兩索引新增「PR #60 正式 OAuth 憑證儲存」，日期 2026-11-10，引用 merge／最後 feature 與固定 merge links：長期 storage 契約、LG81-Cap-R／live-validation／tests／review。分清 fake Security＋受控 provider、真 DPK 假完整六欄 A→fresh A→整筆 B→fresh B→同身分真重建→fresh B（五 runtime Human 全程0提示）、未驗真 OAuth／遠端 refresh／API。E004 合成／秘密保護界線、E005 legacy 0／0／1 UX 失敗、E007 renewal unknown 全部保留；不把 merged commit 當 live build。只記已完成的 tag／archive／Git 動作，未刪除不先填 removed。
5. 文件與必要 owner P/E 經獨立有限 checks／review後 exact-stage，按 git-commit-convention 提新 docs message，連同普通 FF `HEAD:dev` 維護路線請 Human 一次確認。未確認不 commit／push dev／新增 PR；不能藉已合併 PR 輸入新提交。若 remote dev 變動或 push gate 不符，先唯讀定位，不 force／繞規則或自動擴路線。
6. 確認後文件 commit 必須正常 hooks、普通 FF push dev 並核遠端實際保存完整 feature HEAD。移除前只作有限 ignored 頂層分類，並確認已知 protected run／manifest／signed binary／profile／receipt 根不落 target；已知 private tmp live roots 保留原位置，`.build`／Ruff 等可重建 caches 可隨正常移除，不逐檔掃 cache 或盤點 Apple assets。target 中有未知非 cache／protected ignored 內容即先保護／釐清，不假設可刪。刪除前 fresh gate：managed selector 唯一、clean、無 untracked／unpushed、非 detached、unlocked、無 mutation、lineage 已 merged／文件已在 remote dev。remote feature 正常 delete；已不存在如實記錄，不重建。從非 target 的安全 cwd 正常 `git worktree remove`，再正常 `git branch -d`；不能先刪仍 attach 的 branch，不 force／prune。main local dev 可保持原值。
7. 本地 dev 可能落後，local branch `-d` 可只在該命令用 `-c branch.feat/github-oauth-credential-persistence.remote=origin -c branch.feat/github-oauth-credential-persistence.merge=refs/heads/dev`，令原生 merged gate 核已 fresh 驗明的 origin/dev；不永久改 config、不動 main worktree。必先核 feature HEAD（含新 docs commit）可達真 remote dev、本地 origin/dev 精確相符。若 gate 拒絕保留 ref 回報，不以 `-D` 補救。

必要檢查只有事實／來源、兩文件 links/anchors／whitespace／有限秘密與本機絕對路徑 patterns、archive bytes/permissions／精確 selector 與 Git refs/gates。既有成功 runtime 不重跑，不 build／sign／App／DPK／certificate／trust／ACL／Apple assets 操作。
