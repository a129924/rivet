# Profile-only 自然到期執行契約

> **PR #67 遷移契約更新：** Human已明確接受DPK E008→E010的受限遷移。下列「PR67遷移」段落規範當前編號／檔案／Git授權；舊E008內容保留為遷移前研究／執行歷史，不可據其舊路徑或approval操作dev PKCE E008。M01/M03/M04已各依受限範圍approved、required_fixes=[]；M05首筆遷移commit819b26d已正常完成。M06已在feature受控整合dev並準備E010登記，待M07核對/M08訊息與第二commit/M09發布；不是合併至dev。S06仍human-check、主假設未執行。

本計畫承接 [requirements](../../analysis/github-oauth-dpk-profile-continuity-feasibility/requirements.md) 的九欄與來源，操作契約見 [technical-spec](../../analysis/github-oauth-dpk-profile-continuity-feasibility/technical-spec.md)，進度見 [step](github-oauth-dpk-profile-continuity-feasibility.step.md)。現行為PR67 E010遷移契約；M01/M03/M04受限approved、M05已commit、M06待後段驗審，主假設未執行；下列舊E008實驗/GUI流程均歷史，不得作當前執行入口。M01後唯一路徑為E010受限遷移/準備，精確scope與M-TestCase見PR67段落。

## 歷史計畫：階段與檔案影響（非現行遷移執行指示）

1. S01 Plan-Creator只落地四檔；S02獨立Plan-Reviewer實際審查，對話草案被接受不取代approval。
2. S02 approved後S03 Implementer可準備E008候選最小App/harness/puretests/unsignedcompile；建立前跨registeredworktrees再次查號，碰撞回修四檔重審。不得匯入/修改未合併E007，不修改E006/其18sourceSHA/index/rawreceipts、其他topic/root/sharedpackage/config/hooks/docs。只本feature可寫。
3. 新增限 `experiments/E008/`：README、`DPKContinuityProbe.xcodeproj`、`Sources/DPKContinuityProbe/`（AppKitmain/purecore/唯一LiveStore）、`Resources/`（Info.plist/單groupentitlements）、`scripts/prepare.py`／`proof.py`／`continuity.py`、`Tests/`與`evidence/`。不新增第5份正式artifact或產品API。README使用feasibility-validation八段模板；結果明標未執行，pure evidence synthetic，不冒充真資料。
4. S04 Tester驗證準備，S05獨立Reviewer審查；到S06 Human另核Appleassets/live/跨週保留/recovery/每段ready。在此之前禁止真App launch、Security/SecItem/codesignassetinventory、Xcodeaccount/privateprofile/privatecert操作、簽章/provisioning、arm30min/10日run或保留dummy。
5. 未來只一個自然profile週期，最多3×30min主動窗＋global10日，各25min停新測量。缺時／觀察不完整不自行重跑、換cert、換paid或延長。清理優先但不虛稱總可成功。
6. 真測後Tester分類→獨立Reviewer核收據/cleanup→Humanreview；commit/push/PR本topic未授權，不沿舊PR權限。formaladapter未核准。

八段README依skill模板建立；圖/外部工具不能成為取得live權限的替代，若後續需要額外圖工具交付另限範圍，現在不建立或發布圖。

## 歷史計畫：TestCase與事前判準（非現行遷移執行指示）

| ID | 準備可驗證／未來真人案例 | 必要證據與預期 |
|---|---|---|
| T01 | preauth fail-closed | puremock缺授權/liveproof/ready時零livecommand/SecItem；mockproof不能放行live，禁止unsignedApp launch。 |
| T02 | baseline | 新namespace／同MacGUI／free來源／certificate覆蓋週期／P0實際有效／同完整group；seed-readA六欄相符首次≤1、fresh-readA0。真人未執行。 |
| T03 | 自然到期診斷 | P0實際expiry後，launch/guard/SecItem分層，沒call不報OSStatus/missing；不改clock或繞guard。不可啟動記availability中斷。 |
| T04 | P1真的換新 | actualprofileSHA不同＋dates更新／有效，sameleafcertSHA/fullgroup/必要entitlements/device/query/sourceconfig授權成立；沿用profile/cert混變→unknown，不自行變更研究問題。 |
| T05 | P1 read-original／noRewrite | 新有效host freshprocess只讀原A，六欄全相符，Human正常read0；不可add/upsert或先刪舊item偽恢復。 |
| T06 | trueRebuild | 同P1/cert/group／frozen核心source，獨立marker真建置mainhash不同、讀原A六欄一致、Human0；記DR不誤當輪替必要相同。 |
| T07 | finalcleanup | 同group/service/account delete/readabsent，移除provenowned私有素材，證據保留；assetsretained與假item殘留分開，無cleanuphost不稱完成。 |
| T08 | pureguards/resume/time | 注入clock只測試：manifest/receiptSHA不符、invalidHumanreceipt、symlink/越界/duplicate、window/globaldeadline、已用三窗、stage跳躍/重seed/retentiongrant缺漏均停；failurefinallycleanup，recoveryunavailable出殘留而非success。 |
| T09 | collision／redaction | 編號碰撞不覆寫不自選新號；收據無token/TeamID/certsubject/device/絕對私有路徑；pure/unsigned與真live證據隔離；新JSON固定UTF-8/terminalLF/鍵排序後exclusive-write再hash，formatter檢查不改已完成bytes、不回修舊收據。 |

## 歷史計畫：成功、失敗、無法判定與任務完成（非現行遷移執行指示）

資料恢復成功須實際跨P0自然到期、P1確實換新有效、固定certificate/fullgroup控制、原A六欄未改寫恢復、首次≤1/後續normal0、精確清理。真實有效P1前提完整且資料不符或正常存取提示超標→失敗。profile重用、未跨expiry、certificate混變、帳號/quota/host/recovery不足、缺Human觀察→無法判定。未嘗試live→未執行，不以build/mockgreen取代。

availability另記：舊host過期不能launch僅證中斷，不證item遺失；新P1可讀只證恢復，不證到期期間不中斷。maintenance另記Human重新佈建步驟／耗時／Apple登入和簽章提示，不混Keychain存取prompt，不當GitHub重新登入證據；Human是否接受週期成本待決。

任務完成與假設成敗獨立：證據、缺口及限制可完整記錄unknown，但有假item／私有素材cleanup未完成時不得宣稱整體任務完整完成。cleanup要不要Appleasset權限另詢Human，不改trust/ACL/partition/default/search-list、不保證強制停止後自動清理。

## 歷史計畫：保留缺口（非現行遷移執行指示）

成功仍不核准adapter：實際產品mainhost/entitlement維護、A→B完整update/freshread、malformed/denied/interactionUnavailable/missingEntitlement與notfound區分、certificate renewal/rotation、長期恢復仍需分開。E006 save只是SecItemAdd不可直接當正式store.save；group改變不可默默回nil/刪item。不新增AuthBC、不改GitHubIntegration/providerownership、不導入fallback/migration/跨程序refresh。

## 歷史計畫：S06-BOOTSTRAP 窄幅回修契約（2026-10-21）（非現行遷移執行指示）

Human 已同意窄幅回修後回 S06。此次 Plan-Creator 僅修改本四檔；不動 E008 source/README/evidence，不 arm/設定資產/測量。改正原 global 先需 actual dates 與 selected verifier 先需 global 的循環，細節以 technical-spec 兩階段建立為準。時間、profile-only/samecert/fullgroup、原A不重寫、所有RF01–RF06 controls 不變。

獨立 Plan-Reviewer 核准本revision後，Implementer可只在 feature 回修 E008 `continuity.py` 的 begin-anchor／finalize-global／W1/resume 路徑、`proof.py` 的setup-only context/selected verifier、必要 pure tests與README首次設定說明及新的 synthetic preparation證據。`prepare.py` 仍僅unsigned。本revision另明確包含且僅包含 App `LiveGate.swift` 的 W1 anchor鏈相容驗證：W1核anchor→W1與完整global→anchor/W1，完整actualproof＋另seed-ready不省略；W2/W3維持原window.globalSHA256 binding。其他grants/ready/source/device/expiry/cleanup/RF01–RF06不放寬；main/Core/LiveStore與App功能不擴。fileimpact另含必要純Swift鏈測試及Debug/Rebuilt unsigned重建的新增準備證據，不簽章不launch；任何其他App改動先回契約審查。舊source版本與所有既有 machine/Human/index/closure收據保留原bytes，新的 revision source hashes及pure證據另存不可覆寫，不回修歷史結果。

必要純驗收：
1. 未知實際日期可固定anchor/W1；適用三grants與begin/setup-ready不足即拒絕，anchor/setup-only路徑零App executor/launch/SecItem。
2. 注入clock只puretest：Xcode設定／等待／selected-inspection耗時計原W1；finalize後global仍沿原t0及10日，cutoff／deadline不重設。
3. actual P0/cert日期不符、source/binding/grants/anchor不符、過cutoff、duplicate／partialfinalize／crashresume均不能產生可launch/seed的假完整狀態；原bytes不變，不重arm。
4. W1→anchor、global→anchor/W1單向SHA關係可驗；完整global/actualproof之前、缺另seed-ready時，LiveBackend仍failclosed，mock不能冒充actual。 純Swift直接驗證真App使用的LiveGate W1鏈helper：合法鏈通過，缺anchor/binding、tamper、partialglobal/setup-onlyproof拒絕；W2/W3原globalSHA鏈正負回歸，不能讓W1例外漏到後兩窗。Swift改動後Debug/Rebuilt unsigned重建保存新hash/無debugdylib證據，不沿用舊build結果，不執行App。
5. 固定序列化跨語言bytes/terminalLF不變；RF01–RF06、自然expiry／三窗resume／cleanup-only／grantexpiry／未確證process退出等既有guards做必要回歸，不以修bootstrap解除。
6. setup failure零假項目寫入，精確cleanup準備素材、Appleassetsretained分列，無法清理保留residue；純fixture不當真人／Security證據。

順序：Plan-Reviewer→Implementer→Tester→獨立Reviewer→回S06 Human。只有這輪四檔、受限prepfix與純驗證／審查獲准；真anchor/clockarm、資產/CMS/Security/簽章、App/live/跨週retention及Gitpublication仍無授權，Human須再確認具體scope與freshready。任何新requiredfix依原角色回修，不用歷史approval預填本revision通過。

## 歷史計畫：S06-D 操作 checkpoint 文件補強（2026-10-22）（非現行遷移執行指示）

本revision僅改四planning artifacts＋既有E008 README操作清單/未來證據欄位，不新增第五正式artifact，不改source/config/CLI schema/測試/immutable receipts/index。不得新建privateRoot/grant/namespace/clock、UI/Xcode/Build/CMS/Security/App/DPK或Git。舊控制輪closed；本次「繼續下一步」不是新輪或asset/ready授權。

操作順序與欄位以technical-spec S06 exact-window段落為準：適用新輪begin/setup-ready後，先同窗核設定再另build-ready、Human一次⌘B/noRun、關窗前先matching Report/product provenance、完整host才原setup-only→complete-global→完整setupHuman→另seed-ready。所有UI/CLIparsed/Human來源分開；補充operator sidecars只記真實觀察，不假稱harness自動驗GUI，也不放寬原guards。不足即受控stop，沒有自動重Build、新namespace重試、重設時間或廣域搜尋。

文件審查驗收（本phase不跑測試）：
- 五檔一致限制scope／授權與closed run，保留source与歷史SHA；README仍八段。
- settings-before-Build與Report-before-close兩停點明確，exact project/scheme/target/Debug/Mac/UUID/signing/InfoEntitlements/ownedoutput具可觀察欄位；未知標null/stop。
- build-ready獨立於setup/seed-ready，手動operator補充證據與原CLI schema相容；GUIpass不冒稱actualproof/DPK。
- 原W1的配置/確認/等待全部計時、25min停新操作、30min清理；source/clock/grant/retentionguard不改。
- 報告仍空或host不完整→zero-item受控stop/精確FS cleanup，保留HumanBuild聲明且outsideunknown；不作配置bug或DPK失敗結論。

交獨立Plan-Reviewer，沒有新source故不發起build/test。審查通過後也仍回S06 Human確認新輪scope/S/資產與逐段ready；不自動執行上述清單或開新run。

## PR67遷移：當前受限執行契約

M01/M03/M04已依各階段正式approved、required_fixes=[]；M05經Human確認訊息後正常commit819b26d（parent422d0c7、原六hooks通過）。M06已用--no-commit --no-ff整合origin/dev758aca9且無衝突，feature兩registry新增E010與必要事實同步待M07/M08；尚未第二commit/push。22原檔/193清冊/171immutable保持，以下順序及後段停點不變。

1. **M00保全**：原commit422d0c7的22檔及193清冊已保存；不得修改既有23保全產物。清冊SHA見requirements。
2. **M01實際契約審查**：獨立Plan-Reviewer審四檔與本次Human細則，approved才交Implementer。原對話/準備approval不替代此gate。
3. **M02遷移**：先重查registeredworktrees（含untracked Markdown保留）、遠端完整trees/openPR及新base/head；E010被別owner占即停Human，不E011。精確active17/README/171move與offline mapping按spec，新active manifest/必要新證據，不改immutable內容。
4. **M03 Tester→M04獨立Reviewer**：只驗當時已交付的M-T01–04、M-T05當時可核之保存/連結/上游保護基線與M-T06首次占號。只puretests/必要兩版unsignedcompile；未整合/commit/push/readback的項目明列尚未執行，不要求提前通過。正常hooks在各commit按stageddiff範圍執行，不新真人/GUI/App/Security。
5. **M05第一commit Human訊息停點**：實際stage受限migration diff、核PKCE保護/19xaccounting，提出具體message，Human確認後append migration commit；不沿原2806702/266a1b7/422d0c7訊息、不rebase/amend/force。
6. **M06占號→受控整合/登記（Implementer）**：整合/登記時再重查上述占號與base。執行`git merge --no-commit --no-ff origin/dev`，不自動commit/FF跨Human；預期外其他topic衝突即停，不ours/theirs。整合後由Implementer更新`experiments/README.md`及`experiments/VALIDATION-SUMMARY.md`，僅增E010保留E001–009，不從dev獨立拷檔製造add/add；原migration使head相對共祖不再新增DPK rootE008，正常三方保留dev PKCE。
7. **M07獨立核對（Reviewer）**：只審M06已由Implementer修改的`experiments/README.md`及`experiments/VALIDATION-SUMMARY.md`、最新PKCE bytes與整合diff，不代寫/修檔。補核M-T05整合後保護/登記與M-T06第二次占號、M05已發生commit/訊息確認/正常hooks；有必要驗證只限受影響範圍。
8. **M08第二commit Human訊息停點**：核實際整合後stageddiff、擬具體message，Human確認後正常hooks/commit；仍不借舊message或讓merge自動提交。
9. **M09發佈/工具交付（Implementer）**：push前第三次核本機/保留聲明/remote/openPR占號；衝突停。補記M08實際Human訊息確認/正常hooks/commit，按適用授權push/更新PR67，readback真base/head/paths、仍Draft且非CONFLICTING才稱解除，本機clean不足。若重生PRLens，pin0.11本機外部以真新base/head validate/render，舊凍結圖不改；Graphify無圖sourcefallback不autoextract。補交M-T06第三次占號/第二commit與M-T07實際發布/工具證據，不預填成功；工具不替代Reviewer或DPK證據。
10. **M10 Human review**：取得M09實際發布/readback/工具交付證據後，停Human決策；不merge至dev、不adapter。

E010只有完成整合/登記及必要發佈核對才可按實際狀態稱登記，不以mkdir宣布全球唯一。每次base更新先核新增PKCE檔保護，非無限跟進上游；超scope停Human。

### M-TestCase

分期驗收：M03/M04不驗未來事件；M05/M08各commit後、M06整合/登記後及M09push/readback後按實際新增證據補核相應項目。未發生記尚未執行，不能用M04 approval預填整合或發布通過。

| ID | 必要驗收 |
|---|---|
| M-T01 | 原193逐檔accounting；17active/README/4docs的原bytes在22快照、158+13同bytesmove；23保全不覆寫。 |
| M-T02 | 兩輪47/60檔與4+10indexes含self-exclude、人機SHA不變；舊source manifest對原snapshot，新manifest對newactive，無SHA循環。 |
| M-T03 | JSON vs MD/HTML按原context/version分解析，歧義/缺失/SHA不符failclosed；5unavailable明列，22files/22sourcecombos統計不混，不false-origin。 |
| M-T04 | 新E010正向/舊E008 root-kind-service-grant-ID拒絕purecases，拒絕過程零backend/Security/launch；Python/Swiftmarker/Debug-Rebuilt相符，必要兩版unsignedcompile。 |
| M-T05 | 最新base PKCE E008 bytes/文件保持，活動新links正確、歷史經map或unknown；不compatshim/legacyresume/重建privateRoot。 |
| M-T06 | 分期：M03/M04只核首次占號；M07補核第二次占號、整合/registry與M05已發生commit；M09補第三次占號/M08 commit。兩commit各真stageddiff/message Humanconfirm與hooks，未發生不預填；碰撞停、merge不自commit。 |
| M-T07 | 僅M09發布後核GitHub真base/head/paths仍Draft且非CONFLICTING；PRLens新外部map僅真head/Graphifyfallback，交M10Human；M03/M04尚未執行，不拿歷史approval冒充。 |

移動正確/離線證據保存與準備green只驗遷移，不構成profile自然到期/UX成功。五source缺口為已接受保留的既存unknown，不要求為遷移捏造恢復；其他新缺口依證據明列，必要停止。此契約不放行真測量或E008 PKCE內容修改。
