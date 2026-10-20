# S06a：Integration 契約獨立驗證

- 日期：2026-10-20 UTC 07:47；角色：Tester（非 S05 source 作者）。
- Branch：`feat/github-persistent-connection`；只在指定 feature worktree 執行。
- Verdict：`approved`；requiredFixes：`[]`。只接受 S05 fake-only 契約驗證，可交 S06b 獨立 Reviewer；不代其 approval，不直接前進 S07。
- 上游：S05 已明示完成；gate amendment 與 StaticIsolation 精確 manifest delta 的外部 Plan-Reviewer 均為 approved、requiredFixes=[]。Human 只接受 profile 更新後尚未驗證的限制；E007 兩輪 unknown／phase 2 未執行維持，不重跑。

## 方法與實際結果

使用既有 Swift Testing／SwiftPM；套用 `sdd-workflow-contract`、`test-triage`、`swiftpm-macos`。本角色逐項讀取鎖定 technical-spec／plan、四個新 source、provider additive diff、三個新契約測試及既有 client／scope fake seams，再獨立執行，沒有以作者自驗替代。

| 命令 | 實際結果 | 證據邊界 |
|---|---|---|
| `swift test --filter GitHubIntegrationTests --skip KeychainTokenStoreTests` | exit 0；211 tests／22 suites pass（Swift Testing 原樣計數，含 parameterized tests） | 排除會讀寫真 Keychain 的既有 suite；其餘使用 fake store／fetcher／exchange／HTTP 或攔截 URLProtocol |
| `scripts/check-github-integration-consumer.sh` | exit 0；13 tests／3 suites pass | fresh scratch 的正常 import 外部 consumer；建構 live adapter 但未執行 credential operations 或 GitHub requests |

原始 build／test logs 只留 private scratch，不納入 repository；此處只保存有限命令、結果及來源 hashes。套件解析／建置不是 GitHub OAuth/API 驗收。public session 建構允許 `SecRandomCopyBytes` 取得 OS 安全亂數，因此不宣稱所有 Security API 呼叫均為零。

## 契約對照

| V-ID | 實際驗證與 source 核對 | 結果與限制 |
|---|---|---|
| V02 | production state／challenge 43 字元、跨 session 不同；source 確認各自獨立 32-byte RNG、S256、offline_access、無 secret URL。exact callback scheme／host／port／percent-encoded path、userinfo／fragment／缺值／重複 query／錯 state／code-error 排他皆拒絕且零 exchange；denied／cancelled／expired／consumed 有限分類；latch 控制並行 complete 只一次 exchange，late cancel 不遺失 accepted response | pass；production 隨機 verifier 未輸出，只以 source 與可觀測 challenge／state 檢查；未執行 browser／loopback／真 GitHub |
| V02 | fake exchange 的固定 endpoint、POST、五個 form 欄位、保留字元 escaping、Accept JSON；六欄 DTO、bearer、正數 integral lifetimes、空 scope 合法、mixed/null error／缺欄／非成功 token body／非有限 receipt 拒絕；transport 不重試。production factory policy 30 秒／ephemeral／無 cache-cookie，source 確認 redirect delegate 回 nil | pass；初次 exchange transport 全 fake；redirect 阻擋為 production source 核對，沒有真 HTTP redirect 測量 |
| V03 | fake Security 下 configuration 與完整六欄 expired bundle roundtrip、JSON schema 1、milliseconds、trusted client ID binding；corrupt 不暴露 partial ID；missing／denied／unavailable／corrupt／identityMismatch 分開；denied update 不 add、不覆寫 | pass；configuration-first 與 repair table 的產品先後行為待 S07／S08 coordinator 驗證 |
| V03 | 每項 query／add／update 的 DPK／non-sync／group／service／account；新增 AfterFirstUnlockThisDeviceOnly；update-first、missing add、duplicate 單次 whole update；同 actor 並行寫入序列、完整替換後新 adapter 六欄讀回 | pass；新 adapter 是同 process fake backend，不能稱 fresh-process 或真 DPK |
| V05 | provider disposition 由原 unavailableError 推導；notStopped／authenticationRequired／stopped 對應 technical／credential rejected／indeterminate／cancel stage／persist failure；重複觀測不增 load／save／fetch | pass；本 slice 不包含產品 same-provider retry／所有 reauth retirement |
| V08 | 全 integration fake-only regression 含單一 provider 的 REST／GraphQL、snapshot／single-flight、expiry-first refresh、accepted rotation persist failure、HTTP 401 最多一次與晚到 401 使用新版本；既有 prepare 無 API probe／失敗有限分類 | pass；沒有執行 signed host／hosted unit tests 或資產驗收 |

Milliseconds oracle 已獨立確認：測試以原 `Date.timeIntervalSince1970 * 1000` 核對 JSON 數字，另以原 Date 核對還原值及其餘五欄。此避免 Foundation Date 的二進位表示與十進位硬常數不相等，仍能偵測秒／毫秒尺度錯誤與六欄 roundtrip 錯誤；production codec 沒有為此放寬。

## 受測 production hashes

| Repository-relative path | SHA-256 |
|---|---|
| `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift` | `b38dc9bee34b1e840cecee7774266a2446e8fab4d95ce5477f2c6f02870dfb3f` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift` | `8eda511d00b89096f5eb604b8cc63e428df849af3bebbf02962f9c69754a3ecc` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationSession.swift` | `604d50fcd15f314a489351aee749c5dc4f9b81565cdc4a28a1cb2432eb8c4fb8` |
| `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift` | `1b16ec8b8a12b09f3a5e3694be1077b00b52bb62d394bb356c490fbf23e5c2e5` |
| `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift` | `675d989106dd2f882f0a95ab5e2c9884a0606e4ff0a5dcbaa21378050be3a899` |

## 未驗證及停止界線

本輪沒有真 Keychain credential reads／writes、真 GitHub OAuth/API requests、系統提示觀察、重啟／真正重建／輪替後 fresh process、真遠端 refresh、profile 更新、正式入口或產品 UX 證據；V06／V07／產品 V04／V05／V08／V09 仍待後續既定 steps。沒有修改 source／tests／設定或操作 Git，沒有把 Human 接受未知寫成實驗 pass。


# S08a：產品 fake-only 獨立驗證（2026-10-20 UTC 08:11）

- 角色：獨立 Tester；S07 作者已明示完成並停止寫帳本，上游 S06b Reviewer approved／requiredFixes=[] 僅放行原 W04／W05。
- 整體 verdict：`needs-rework`；requiredFixes=`[RF-P01]`。已執行 fake-only 部分 `approved`，不是 S08a 全部通過。V06／V07 真路徑未執行，不進 S08b／S09，交回既有 Implementer bounded fix。
- `RF-P01`：正式 host／coordinator 沒有 V07 所需的受控 expiry clock 與有限驗收觀測途徑。`GitHubConnectionCoordinator.makeProvider` 直接以預設 Date.init 建立 provider，`RivetComposition` 只處理 unit-test-mode，不能在正式入口以受控 clock 觸發真遠端 refresh，也不能由現有帳號文字獨立證明整個輪替 bundle 已保存並由新程序還原。請只在原 W04 host／coordinator 與原有 tests 內補足明確 opt-in 的受控 provider clock／脫敏驗收途徑，維持正常預設真時鐘、真 token fetch receipt 時鐘及原 lifecycle，並測試未啟用／test-mode 不觸發 live、受控條件與真證據分列。不得改 OS 時鐘、偽改已保存 bundle 到期日，或新增 probe source／framework。若此最小修正仍超出鎖定範圍，先交對應 planning 角色，不自行擴張。

## 獨立命令與結果

| 檢查 | 實際結果 |
|---|---|
| `xcodebuild test -project apps/Rivet/Rivet.xcodeproj -scheme Rivet -destination 'platform=macOS,arch=arm64' -derivedDataPath <Tester-owned scratch> -clonedSourcePackagesDirPath <同 scratch> CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= ONLY_ACTIVE_ARCH=YES` | exit 0；xcresult summary：Passed、23 total／23 passed／0 failed／0 skipped |
| 同 project／scheme／destination／scratch／unsigned settings 的 `xcodebuild build` | exit 0，正式 source 的 unsigned App build；沒有 launch live App |
| `swift test --filter 'GitHubIntegrationTests|RivetPresentationTests' --skip KeychainTokenStoreTests` | exit 0；226 tests／25 suites pass |
| 精確 S07 八個 Swift 檔 `swift format lint --strict`、`swiftlint lint --strict` | 均 exit 0；SwiftLint 0 violations |
| `plutil -lint` project／Info／entitlements、`git diff --check` | 均 exit 0 |

上述均由本角色獨立執行，未引用作者數字替代。初次 hosted 命令只指定 platform=macOS、未限制 arch，Xcode 嘗試 x86_64 App 而 dependency modules 為 arm64，build exit 65、tests 未執行；分類為 destination／architecture 命令條件，依實際 arm64 host／既有作者命令加入 arch=arm64、ONLY_ACTIVE_ARCH=YES 即通過，沒有修改 source 或 package graph。這不證明 Intel host 相容性。

## V04／V05／V08 source 與 fake 測試對照

| 契約 | 實際證據 |
|---|---|
| Settlement／舊寫不得蓋新 grant | 舊 refresh 與 rotation save 分別由 latch 暫停；caller／operation cancellation 後 connect／reauthorize 仍 operationInProgress、零新 config writes／authorization；release 後才完成，最終 store 為新 grant。沒有 sleep 作先後推論 |
| Retry／retirement | 暫時 prepare retry 是同一 provider object；stopped／authenticationRequired 不重建／不重試 fetch；同 config 的 reauth、secret repair、取消／拒絕／invalid callback／grant failure／bundle save failure 都退休舊 provider，retry 不復活，只有新 grant 保存後才建新 provider |
| Repair table | missing／corrupt configuration、valid credential、ID mismatch 均以完整 trusted credential ID 鎖定；valid config＋missing／corrupt credential reauth；皆無 trusted ID 的 corrupt 需 explicit confirmation；denied／unavailable 無 config／bundle writes，僅 explicit retry；config save 失敗零 authorization |
| Account result | GET /user、Accept GitHub JSON、User-Agent Rivet、僅有效 200 account；403／無效 ID／空 login 拒絕；reauth 開始 account 清空，exchanging 不能取消；probe fail retry 保留 provider／scope |
| Relay | production source 綁 127.0.0.1／動態 port、ready 後開 browser；fake listener/parser 測 GET origin-form／exact encoded path、8 KiB 限額、單次 callback、取消／受控 expire 分類。5 秒 connection timer／五分鐘等待只核對 production source，沒有執行真 NWListener/socket 或 browser |
| Host test safety | shared TestAction 使用 RIVET_UNIT_TEST_MODE=1；App entry 在任何 live dependency／restore Task 前走 fake root，實際 hosted audit 的 live construction／credential／network entry counts 全 0。OS RNG 不等於 credential operations；沒有以 unsigned host 操作 DPK |

受測 source／resources／tests hashes：

| Repository-relative path | SHA-256 |
|---|---|
| `apps/Rivet/Rivet.xcodeproj/project.pbxproj` | `f4ecf63c57f13ed7f4e3087f3a7fe4d2f861f946e0930d86d6d00cc235f06d15` |
| `apps/Rivet/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme` | `3832ea8a70762b06eb77421a7f18abbab1ca62ba7749276fd7ed164e0638c4a6` |
| `apps/Rivet/Sources/RivetApp.swift` | `ff16af0de5eb9402af7a85aaa0b94e414517b200346ca2f01791be9f839e338b` |
| `apps/Rivet/Sources/GitHubConnectionCoordinator.swift` | `0a68383628283cfd73860655b61314d40ce48d7d974c2ff50ae20a8fe3506109` |
| `apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift` | `b8fa70f0eb357316d69d7e1a6e964508355708793053018afd738c3f3dee3ed4` |
| `apps/Rivet/Sources/GitHubAccountProbe.swift` | `7db900775746a49583344600a79509c6f75a14352483b4ef78abed350e556eaf` |
| `apps/Rivet/Resources/Info.plist` | `733e24e4a9848b28d9fae0eda9ac0b322af568881dcb46244625acfaf1782fd7` |
| `apps/Rivet/Resources/Rivet.entitlements` | `526bac7f8ee939569becdf3d59ab86e83bf68c0bafda5ff3d660c5683dab6dc8` |
| `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift` | `03f0b5a63568e33078064b5d54215d89dcf14c74070c470ce6bc14dddb95c93f` |
| `apps/Rivet/Tests/GitHubLoopbackCallbackRelayTests.swift` | `d8afc7a0e854d91fd52584be7f8e9a622959e5bf94987134e972908897595b1e` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift` | `b7fb55bb837a1a6577d3041a4b13c3431636e90db4dfaee860a9def803c0bf10` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift` | `681c086fa72914fed0557338be833d43c98fd38b9eb61d394b8fa65bf4732b72` |

真簽章／有效 profile／固定安裝位置、真 DPK／Human 提示、正式 browser 授權／fresh-process／真遠端 refresh 全未執行。S08a 不將 fakes／unsigned compile 當作這些驗收通過。V06／V07 準備與停止條件見 storage-live.md／product-e2e.md。


# S08a RF-P01 獨立重驗（2026-10-20）

- 原 Implementer final 停止寫入後鎖定三檔 hashes，獨立 hosted test xcresult：29 total／29 passed／0 failed／0 skipped；同 arm64／ONLY_ACTIVE_ARCH／unsigned／Tester-owned scratch 命令，exit 0。跑後三檔 hashes 不變。unsigned build、精確三檔 strict format／SwiftLint（0 violations）與 diff check 均 exit 0。不重跑未修改且先前獨立通過的 root226 suite。
- RF-P01 已獨立解除：opt-in 缺席用真時鐘，unit-test-mode 先於 validation 與 live construction；expire-restored-once 只在完整可信、同 ID 初始 restore arm 原 access expiry，一次性控制不以 now 呼叫次數推進（12次讀取仍同判定），不改 OS clock／保存日期。Production fetcher 仍用既有 Date.init receipt；原 fetcher 接受及原 store 成功保存完整新 bundle 後、provider 判斷新expiry前回真時鐘。accepted save failure 保留原 stopped、不控制循環，reauth retirement 結束控制。
- 六個新增測試驗 off／test-mode、單次refresh／保存後回真時鐘、非呼叫次數控制、accepted-save failure、observe還原fingerprint，以及有限receipt。完整六欄 SHA-256／token-pair-changed／counts／booleans 不輸出 raw secrets；receipt 父目錄要求目前 user 所有及無group/other權限，leaf以0600／O_EXCL／O_NOFOLLOW建立、不覆寫。observe fake明記同hosted process的真PID相同、observation UUID不同，不冒充真fresh-process。
- 本次 finite receipt 是可操作驗收途徑；實際真程序退出／新啟動、真 DPK／GitHub／prompt 仍須外部 provenance與Human回報，未執行不能由fake hash相等推成livepass。

| 受測檔 | SHA-256 |
|---|---|
| `apps/Rivet/Sources/RivetApp.swift` | `dbde174c7115de5fb096d09c19a71b6b933448e8160bdf9e39c43abca303b742` |
| `apps/Rivet/Sources/GitHubConnectionCoordinator.swift` | `3e485cb590a7c0fdbabdf6d39dde8860a604266d70c1fa496570578fa6fb6837` |
| `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift` | `73fab0479c8e5a5ad84b2947e9ad5af6d86233bfd11722389f9e927bfc5f3fe9` |

Tester 對本 bounded fix 的 verdict=approved／requiredFixes=[]；整體 S08a verdict=human-check，僅等待既定 V06／V07 真人ready與逐段真驗收，不新增 gate、不進 S08b／S09。之前 needs-rework段落保留為歷史，不再是目前 blocker。


# S08a 首次正式 GUI Build：RF-P02

Human准許核對並建置後，以私有正式project的GUI⌘B實際失敗：App請求x86_64，三個localpackage module僅arm64，Unable to resolve GitHubIntegration／RivetPresentation／RivetHTTPClient。ownedDerivedData activitylog有限核對與UI錯誤一致；未Run，不是簽章或credential錯誤。原project Debug沒有ONLY_ACTIVE_ARCH，先前成功驗證命令皆有YES override，不能代替正常GUI可Build。

Tester verdict=needs-rework、requiredFixes=[RF-P02]：交原Implementer在既有project.pbxproj的Debug配置補足native-arch建置條件（對照既有成功命令ONLY_ACTIVE_ARCH=YES），使正常GUIBuild不需隱藏override；不改runtime／signing／security／publicAPI。修正後私有project只同步核准設定、保留HumanTeam／AppID，再獨立重驗。未新增gate或sourcepath，RF-P01仍已解除；V06／V07保持未執行。


# S08a RF-P02 獨立 GUI 回查

formal projectSHA256=`ddf42ca3511f297456cb82c30b8c1a74413da785c103a4409ebc6fff058df62f`，移除唯一共用Debug ONLY_ACTIVE_ARCH=YES可精確還原原hash；私有project以完整plist比對只新增同欄，HumanTeam／產品ID／localpackage重定向均保留。CUA BuildSettings→All實際解析BuildActiveArchitectureOnly=Yes後，正常GUI⌘B（無任何外部arch／ONLYACTIVE override）BuildSucceeded，真產物arm64；RF-P02獨立approved、requiredFixes=[]。未修改runtime或其他source。

實際GUIactivitylog來源與四個privatehostsourcepaths／Swift6相符，copy與linkedpackage hashes全符。真產品strictcodesign驗證成功、profile當時有效、目前Mac的provisioning_UDID受授權、原certificateleaf相符且在profile中、產品AppID／Team／Info／privategroup／profile一致；macOS15、無debugdylib、nonSandbox。這證明正式hostbuild前提，仍不證明OAuth／跨重啟／refresh。


# S08a 最終 Tester verdict

`approved`；requiredFixes=`[]`。獨立fake-only hosted23→RF-P01後29（29為新版全suite，不能相加），root226／25與S06a consumer13／3等已記實跑結果；RF-P01以29／0／0與精確三檔checks解除，RF-P02以one-settingdiff＋正常GUIBuild／真正GUIclean-rebuild解除。無未解sourcefix。

真產品五主要路徑與逐段Human0均完成，詳storage-live.md／product-e2e.md，source-hash及有限receipt鏈可供獨立Reviewer核對。Live原fetcher／DPKstore／正式App與fakes／controlledclock分列，無rawsecret／callback，未測normal初hash／個別tokenhash／renewal等保持未驗證。只交既定S08b，不代Reviewer／S11接受，不提前進S09／發布。


# S10a 最終驗證第一輪：needs-rework／RF-D01

- 角色：獨立Tester，非S09圖作者。Verdict=`needs-rework`、requiredFixes=`[RF-D01]`；只交原圖Implementer回修，不自行改圖或進S10b。
- **RF-D01：Canvas責任關係不符source。** `scene.js` 的EDGES直接由`session`指向`stores`，實際HTML亦顯示OAuth授權session→DataProtectionstores。已鎖technical-spec、授權sequence及production source均為session只驗證／exchange並交回bundle；`GitHubConnectionCoordinator.authorize`才呼叫credentialStore.save。請在原scene把此錯誤直接關係改成正確coordinator→stores，維持其他ownership，重新Canvas validate／build與實際截圖核對、更新同組既有作者證據與hash。不是改production／新需求／新gate。

其餘獨立檢查：三Archify canonicalJSON各重新validate showcase9/9、0errors／0warnings；sourceJSON／HTML／原生delivery／visualreceipt SHA及bytes鏈一致、32個W07精確leaves符合manifest。原生receipt四尺寸1440×900／1600×1000／1920×1080／2048×1320 containment皆pass；Tester另外只在ownedscratch HTML副本重跑三圖visual-check，全部exit0、12/12 viewportpass，canonical32檔hash未改。原12PNG已逐張用view_image獨立親看light/dark，沒有裁切／關係label壓線／dock擋legend；11張重擷取與原PNGbytes相同，剩一張lifecycle大尺寸light另親看亦無可見缺陷。不將技術containment或Tester視覺檢查冒充Human接受，原visualReview=pending保留。

Canvas validator5bands／17boxes／16edges、0errors／0warnings；Tester在scratch由原scene用bundledbuilder重建，HTML與canonicalbyteidentical；既有privatepointer所指實際1440×1100截圖SHA核符並親看。幾何／輸出可重建通過，但上述RF-D01語意不能由工具0/0掩蓋。

69個S08記錄source/packagehash未變，四真程序有限receiptSHA與accepted→persisted→freshrestore六欄鏈仍相符，五Human主要段均0；未重跑Swift或真人流程。兩輪E007immutableReviewSHA與unknown／phase2未執行保持，Human接受未知不改成pass。正常初digest未測、aggregatepairchange非個別token變化、受控expiry非自然8h、有效profile／free7日／certrotation及公開發行限制均在M03保留。


# S10a RF-D01 bounded 重驗與最終 verdict

Tester verdict=`approved`、requiredFixes=`[]`。只重驗本次Canvas／必要metadata，原已通過的三Archify／12PNG／四尺寸／69sourcehash／五liveHuman0／79links結果保持，沒有重跑Swift／真人流程。

獨立將修前scene純資料與新版逐欄比較：W/H／planes／bands／17boxes／texts／swatches／chips及其他15edges完全不變，只有session→stores這一條改成coordinator→stores；起點[200,590]在Coordinator左界、經[136,590]／[136,1030]左gutter至stores左側[196,1030]，新增「初次授權bundle完整保存」label。錯誤session直接關係已無、正確邊沒有重複，符合原source的session只return bundle／Coordinator.authorize保存責任。

獨立Canvasvalidator仍5bands／17boxes／16edges、0errors／0warnings；用bundledbuilder在ownedscratch重建新版scene，HTML與canonicalbyteidentical。新sceneSHA256=`187bba542b1e1f2b17e960a74863b39b5e0a2633d4655bfb2d638f27ceff95d3`，HTMLSHA256=`61a8f9b558407ae9d1d04c63b56221325d2d666cd660fa110ef80cd4763e69ae`；privatepointer的新1440×1100真截圖SHA256=`b315a4a4b32929ec9915b775ccb9fa9007ca2be9da8e4fad700c96e753685d10`核對後已view_image親看：箭頭確由Coordinator經gutter進stores，與瀏覽器外部授權線分開，不穿OAuthsession，無裁切／新增遮擋。visual_review=passed（獨立Tester）、correction_rounds=1；這不是S11Human接受。

只scene／canvasHTML／BUILD／visual-review四個核准leaves比前輪改變，其餘canonical28leaves含三Archify收據／PNG未變；必要Markdown8個links存在，privacy／whitespace與diffcheck0。原作者visual-review仍如實為作者檢查，Tester未改它。RF-D01解除後，只交既定S10b獨立Reviewer；S11Human圖表／最終接受與S12真codecommit後PRLens真diffmap／DraftPR後review仍pending，未捏造provenance或越gate。
