# GitHub 持續連線：驗證產物歸屬回修計畫

## 現行補充：合併後摘要與收尾（D，待獨立 Plan-Reviewer）

Human已授權此受限延續；requirements D九欄與spec D Git契約優先，下方C九檔授權不擴張到本次。精確六檔：Modify `analysis/github-persistent-connection/requirements.md`、`analysis/github-persistent-connection/technical-spec.md`、`plan/github-persistent-connection/github-persistent-connection.plan.md`、`plan/github-persistent-connection/github-persistent-connection.step.md`；Written `experiments/README.md`、`experiments/VALIDATION-SUMMARY.md`。兩新檔此前local dev／feature及remote API均不存在，不稱改既有。無其他repo寫入／tracked刪除。

### 摘要 facts 與驗證

D-T01：兩索引依實際來源寫繁中與相對links，覆蓋E001–E007 README、新App README、新五份verification-host evidence及必要舊版歷史來源；每項分已驗／未驗與服務／儲存／合成來源，不輸出rawtoken／secret／code／callbackquery／Appleidentity／本機絕對路徑。最小facts如下，作者仍須逐項核source：

- E001真callback code/state，不exchange；E002正向exchange六欄＋GET/user成功，但負向PKCE／總體unknown、兩次quota耗完；E003單次真refresh／rotation／同user API與舊refresh `bad_refresh_token`成功，不證保存／產品自動刷新。
- E004真SQLite配fake tokens／refresh，驗跨process／atomic／singleflight／errorcases，不證加密／正式採用；E005legacy資料成功，最新提示0/0/1使重建UXfail，保留早期unknown，不外推DPK；E006 fakebundle＋真DPK在同有效profile／原免費Team/cert下fresh／真CleanBuild提示0/0/0，非真OAuth／refresh／renewal，保留10/16 setup逾時unknown歷史。
- E007兩輪unknown且renewal read未執行：第一B同profilebytes；第二xattr備份預檢停止，cachemove/refetch/B皆0；Human接受限制不改pass，不第三輪。RF-C01 `bf0db99`的36Python＋4freshCLI只證合成durableexport/checkpoint/cleanup修正，非新live／掉電／renewal實驗。
- PR62新GitHubConnectionVerification於2026-10-21完成真OAuth/DPK/fresh/真CleanBuild/provider受控到期→真refresh accepted1/save1/輪替fresh/同account GETuser，六流程七項Human分段皆0。controlled非natural；grant後digest未觀測、fresh才首次觀測；aggregatepairChanged非逐tokenhash。舊2026-10-20 Rivet名義host結果另標歷史版本。hosted78/root202（22suites）/consumer12（3suites），App缺席production build/test成功，Sources/Tests/Package/locks回16606基線，不等正式產品能力。
- 自然到期、profile更新讀回、expiredprofile恢復、certrotation、跨機／跨user與公開分發未驗。PR60/61/63截至prep仍OPEN，其他worktree E009dirty不碰；不發明E008或稱這些PR已合併。

D-T02：只六檔staged diff、來源links／privacy與必要格式、正常全部mandatoryhooks；D-T03依spec逐步freshverify PR／tag/M／refs／已push docs branch／目標worktree與dev。無source改動，不新跑Swift/live／圖；archify/pr-lens/graphify既有產物只讀、不建圖／索引或新增產物擴scope。

| Step | Owner | 順序與完成條件 |
|---|---|---|
| D01 | Plan-Creator | 四artifacts短補充，交獨立審查，不自產approval |
| D02 | Plan-Reviewer | 獨立scope／facts界線／安全Git契約approved才進D03 |
| D03 | Implementer | 僅六檔：新增兩索引、真實帳本交接；不改舊來源 |
| D04 | Tester | 獨立D-T01／六檔scope／links／privacy |
| D05 | Reviewer | 獨立facts／claims／lifecycle契約與來源審查 |
| D06 | Implementer | staged語意/message→正常fullhooks→commit→push新docsbranch→follow-up Draft PR base dev；PR62不再commit，不merge |
| D07 | Implementer | 重新查tagnamespace，annotated候選tag exactM並normalpush／peeled核對；非release |
| D08 | Implementer | fresh查原remote仍1c8才刪，local原feature -d；保留新docsrefs |
| D09 | Implementer | fresh查乾淨／已push0ahead／untracked0／unlocked nondetached，目標外正常remove原worktree；客觀結果留外部ownedprivatehandoff／final，停止repo寫入 |

D06–D09依Human明確授權，不新增確認；遇spec停點只停受影響步驟回報，不force／prune／未知刪除。最終新docs PR停humanreview、不merge；D09後不為填step重建worktree或寫dev。

---

## 現行補充：PR comment RF-C01（待獨立 Plan-Reviewer）

Human 已授權必要回修→topic commit→push→回覆／resolve，沿原featureworktree/branch/Ready PR62，不改dev、不merge。獨立Reviewer needs-rework：[4333613564](https://github.com/a129924/rivet/pull/62#discussion_r4333613564)，thread `PRRT_kwDOUFu0Cc6upRad`。requirements現行九欄與technical-spec現行失敗安全契約優先；下方R／S為歷史。

### 精確 Modify（只有九檔，無新repository leaf）

| ID | 路徑 | 允許delta |
|---|---|---|
| C-M01 | `experiments/E007/scripts/run_profile_renewal.py` | export-clean完整staging／durable no-clobber publish／兩階段cleanup／resume必要helpers；原privacy／owner／symlink／Humanclosure／read-absent guards保持 |
| C-M02 | `experiments/E007/Tests/test_protocol.py` | C-T01–07 synthetic temp故障／重試／脫敏cases，保留既有tests |
| C-M03 | `experiments/E007/README.md` | 新版匯出／pending／完成／恢復說明與舊runner版本pin，不改舊測量事實 |
| C-M04 | `analysis/github-persistent-connection/requirements.md` | 現行scope補充 |
| C-M05 | `analysis/github-persistent-connection/technical-spec.md` | 現行技術契約補充 |
| C-M06 | `plan/github-persistent-connection/github-persistent-connection.plan.md` | 本manifest/cases/route |
| C-M07 | `plan/github-persistent-connection/github-persistent-connection.step.md` | Csteps、各角色實證、真實交付狀態；R／S不擦 |
| C-M08 | `plan/github-persistent-connection/evidence/verification-host-manifest.md` | 追加三檔新舊SHA／Modify與保留表；原immutable表標原版本歷史，不覆寫舊SHA |
| C-M09 | `plan/github-persistent-connection/evidence/verification-host-review.md` | 追加本輪assessment／planning／implementation／Tester／Reviewer／commit／thread實證，不改舊R06或approval |

只解除E00732中的三檔，其餘29及舊native29＝58檔仍逐bytes保留；原manifest61immutable作舊版本收據保留，新三檔以`62dece35`追溯。所有native圖、新App sources/tests及R06、production仍只讀。Written限owned synthetic/runtime temp；Deleted無trackedfile；其餘完整九欄以requirements現行補充為準，無目錄級授權。

### 必要 TestCase（全部synthetic，不跑真人／Apple／Keychain）

| ID | 判準 |
|---|---|
| C-T01 | receipt/source hash／stat故障：private保留、無partialfinal，解除故障可重試 |
| C-T02 | index建檔/write故障及partial ownedstage：private未刪，同命令可恢復 |
| C-T03 | receipt/index/stage-dir/publication-parent fsync故障：不可cleanup，原private或完整final可恢復，不吞錯 |
| C-T04 | publication race/collision/symlink/未知final/錯run：no-clobber，目標不改，private保留 |
| C-T05 | cleanup開始前／部分rmtree失敗：完整durable final hashes正確、index pending/false；即使privateJSON已刪可依checkpoint resume |
| C-T06 | 真成功順序：files/index fsync→stage-dir→exclusivepublish→parentfsync→完整性核對→rmtree→觀察absent/parentfsync→completion；redaction與原cleanup/closure guards保持 |
| C-T07 | 刪完後completion write/fsync失敗可重試；自身pending/completed可核驗接續但不冒認未知collision；completed再跑不覆寫、不刪其他檔 |

C01 Plan-Creator四artifacts → C02獨立Plan-Reviewer approved → C03 Implementer bounded red-green／自驗／manifest → C04獨立Tester → C05獨立Reviewer → C06 stageddiff語意／message、完整mandatoryhooks、topiccommit、normalpush → C07回覆原thread實際commit／tests與理由、resolve**僅已處理thread**、全pagination讀回threads與PRhead → humanreview。不新增Human批准或真人gate，不forcepush／merge。

只重測適用Python protocol合成cases及格式／依賴／privacy／58immutable；若該檔含不相關Swiftfake可明確selection並記skip原因，不冒稱全套通過。hooks正常執行不繞過。系統責任／sequence不變，不重產native圖；archify保留原QA，pr-lens／graphify依skills bounded使用或記實際fallback於既有review，不建graph／改config／造成功，也不稱舊map覆蓋新commit。needs-rework回對應作者；blocked/human-check停交Human。未執行結果pending。

---

- Topic：`github-persistent-connection`；2026-10-21，回修四 artifacts 待獨立 Plan-Reviewer；此文件取代原 production implementation contract。
- 沿用原 feature worktree、branch `feat/github-persistent-connection`、[Draft PR #62](https://github.com/a129924/rivet/pull/62)、base `dev`，不得在 dev 或 PR #61 worktree 實作。
- 撤回基準：本 topic 前 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`；回修起點 `ca00bc074f77fa21a7fac1aaae07dc1059de5b01`。不得覆蓋基準後其他人變更，發現偏離先報具體diff。
- 配對：[需求](../../analysis/github-persistent-connection/requirements.md)、[技術契約](../../analysis/github-persistent-connection/technical-spec.md)、[帳本](github-persistent-connection.step.md)。

## 1. 九欄執行契約

| 欄位 | 本輪 |
|---|---|
| In-Scope | 完整獨立驗證 App；本topic production污染撤回；App-local新依賴／terminal tracker；適當tests與真人重驗；版本化證據、文件圖、原PR宣稱回修 |
| Out-Of-Scope | 正式產品功能；PR #61 去重／合流／共用抽象；新production API；E007第三輪；舊資料遷移／刪除、logout／revoke；Apple安全變更／新certificate；其他BC及一般重試framework |
| ReadOnly | R清單；整個dev／其他worktrees；E00732檔；舊圖native產物；本topic前正式能力 |
| Written | W清單精確leaves，新驗證App及新版證據／圖；無任意目錄寫入授權 |
| Deleted | D清單19檔，本topic新增且尚無其他變更才撤；只刪repo source，不刪安裝App或真DPK |
| Modify | M清單4個正式檔精確撤回、4artifacts、4長期docs、8歷史導覽／evidencebanner；原DraftPRtitle/body |
| Goal | 可操作完整驗證流程；App可整個移除而production不改仍build/test；所有變更與保留可核對 |
| Non-Goal | 把驗證通過說成產品交付、留驗證專用publicAPI／共用UI／控制工具、把舊host或mock結果冒充新host |
| TestCase | TC01–TC10，手動結果pending；每個handoff逐檔展開其必要manifest子集與case |

## 2. 精確 manifest 與污染清單

以下alias僅縮短表格；展開每一leaf才是授權，不得掃寫目錄：

- `G`=`Sources/BoundedContexts/GitHubIntegration`；`GT`=`Tests/GitHubIntegrationTests`。
- `P`=`Sources/Presentation/GitHubConnection`；`O`=`apps/Rivet`；`A`=`apps/GitHubConnectionVerification`。
- `T`=`plan/github-persistent-connection`；`D`=`docs/architecture/diagrams/github-persistent-connection`；`N`=`D/verification-host-v2`。

### D：搬移後撤回19個舊路徑

下表每個舊路徑均為本topic新增production污染。搬移不等於原樣rename；新App須改module/import／visibility、local dependencies／名稱／identity／測試。任何無法撤回的正式契約先報必要性，不默認保留。

| 舊路徑（Deleted） | 新路徑（Written） |
|---|---|
| `G/Contracts/GitHubOAuthAppConfiguration.swift` | `A/Sources/GitHubOAuthAppConfiguration.swift` |
| `G/OAuth/GitHubOAuth.swift` | `A/Sources/GitHubOAuth.swift` |
| `G/OAuth/GitHubOAuthAuthorizationSession.swift` | `A/Sources/GitHubOAuthAuthorizationSession.swift` |
| `G/Stores/GitHubOAuthDataProtectionStores.swift` | `A/Sources/GitHubOAuthDataProtectionStores.swift` |
| `GT/GitHubOAuthFactoryTests.swift` | `A/Tests/GitHubOAuthFactoryTests.swift` |
| `GT/GitHubOAuthAuthorizationSessionTests.swift` | `A/Tests/GitHubOAuthAuthorizationSessionTests.swift` |
| `GT/GitHubOAuthDataProtectionStoresTests.swift` | `A/Tests/GitHubOAuthDataProtectionStoresTests.swift` |
| `P/GitHubConnectionPresentation.swift` | `A/Sources/GitHubConnectionPresentation.swift` |
| `P/GitHubConnectionView.swift` | `A/Sources/GitHubConnectionView.swift` |
| `O/Sources/RivetApp.swift` | `A/Sources/GitHubConnectionVerificationApp.swift` |
| `O/Sources/GitHubConnectionCoordinator.swift` | `A/Sources/GitHubConnectionCoordinator.swift` |
| `O/Sources/GitHubLoopbackCallbackRelay.swift` | `A/Sources/GitHubLoopbackCallbackRelay.swift` |
| `O/Sources/GitHubAccountProbe.swift` | `A/Sources/GitHubAccountProbe.swift` |
| `O/Resources/Info.plist` | `A/Resources/Info.plist` |
| `O/Resources/Rivet.entitlements` | `A/Resources/GitHubConnectionVerification.entitlements` |
| `O/Rivet.xcodeproj/project.pbxproj` | `A/GitHubConnectionVerification.xcodeproj/project.pbxproj` |
| `O/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme` | `A/GitHubConnectionVerification.xcodeproj/xcshareddata/xcschemes/GitHubConnectionVerification.xcscheme` |
| `O/Tests/GitHubConnectionCoordinatorTests.swift` | `A/Tests/GitHubConnectionCoordinatorTests.swift` |
| `O/Tests/GitHubLoopbackCallbackRelayTests.swift` | `A/Tests/GitHubLoopbackCallbackRelayTests.swift` |

### W：其餘新 App／新證據／新版圖 leaves

| ID | Written精確檔案（分號各為一檔） | 用途 |
|---|---|---|
| W01 | `A/README.md` | 工具定位、build/tests與真人分段操作、資料namespace與限制 |
| W02 | `A/Sources/VerificationOAuthEndpoints.swift`; `A/Sources/VerificationOAuthTokenResponse.swift`; `A/Sources/VerificationOAuthHTTPTokenFetcher.swift`; `A/Sources/VerificationLifecycleObservation.swift`; `A/Sources/GitHubExpiryValidation.swift` | App-local endpoints／DTO／refresh、同generation tracker、從原entry抽出controlledclock／receipt及wrapper；不再借productioninternal |
| W03 | `A/Tests/VerificationOAuthHTTPTokenFetcherTests.swift`; `A/Tests/VerificationLifecycleObservationTests.swift`; `A/Tests/GitHubExpiryValidationTests.swift`; `A/Tests/GitHubConnectionVerificationIsolationTests.swift` | 新local能力及隔離／早期testguard；舊factory test裡disposition專用測試改測local tracker，移除productionAPI依賴 |
| W04 | `A/GitHubConnectionVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | 僅若Xcode實際需要則從既有一致pins產生，無版本更新／新外部package |
| W05 | `T/evidence/verification-host-manifest.md`; `T/evidence/verification-host-contracts.md`; `T/evidence/verification-host-isolation.md`; `T/evidence/verification-host-live.md`; `T/evidence/verification-host-review.md` | 逐檔action/from/to／keep原因及SHA、命令與fake實證、排除Appproduction檢查、新真人結果／原版界線、獨立Tester／Reviewerverdict |
| W06 | `N/BUILD.md`; `N/scene.js`; `N/responsibility-canvas.html`; `N/visual-review.md`; `N/tool-evidence.md` | 新責任canvas與真工具／QA／provenance |
| W07 | 見下列固定27leaves | 3張新版Archify，不能覆寫舊版 |

W07固定basenames為 `authorization-sequence`、`restore-refresh-reauth-sequence`、`connection-lifecycle`；每個basename在N下各允許以下9個leaf：`.json`、`.html`、`.delivery.json`、`.visual-check.json`、`.visual-check.html`、`.visual-check.1440x900.light.png`、`.visual-check.1440x900.dark.png`、`.visual-check.2048x1320.light.png`、`.visual-check.2048x1320.dark.png`。此有限笛卡兒積即27個精確路徑；所有native receipt不得手改。若實際pinnedtool必須另寫frozen snapshot，先報工具實際固定名稱並以最小manifestdelta獨立回查，再產生，不借目錄授權。

PR Lens產物／screenshots／private runtimereceipts／Xcode私有副本／DerivedData僅放本topic proven-owned ignored builddir或private0700scratch，不入版控。Xcode自動生成xcuserdata不能stage；發現新檔先確認本輪擁有權，精確保留／移出，不刪未知資產。

### M：既有檔限定修改

| ID | Modify精確檔案 | 允許delta |
|---|---|---|
| M01 | `G/Providers/OAuthTokenProvider.swift` | 只撤本topic dispositionenum／method，恢復basebytes，不改原providerpolicy |
| M02 | `GT/OAuthTokenProviderTests.swift`; `GT/StaticIsolationTests.swift`; `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` | 只撤topic4行附加test／四sourcepaths與imports例外／28行新增publicconstruction；結果basezero-diff；不能砍原測試 |
| M03 | `analysis/github-persistent-connection/requirements.md`; `analysis/github-persistent-connection/technical-spec.md`; `T/github-persistent-connection.plan.md`; `T/github-persistent-connection.step.md` | 現行scope／精確契約及各角色實證，舊帳本標歷史保留 |
| M04 | `README.md`; `docs/design-principles.md`; `docs/architecture/README.md`; `docs/architecture/github-oauth-dual-client.md` | 撤正式產品完成／正式DPKadoption等錯誤歸屬，寫驗證工具／有限可行性結果，指新圖及新舊來源；不改topic前正式lifecycleownership |
| M05 | `T/evidence/contracts.md`; `T/evidence/compatibility.md`; `T/evidence/storage-live.md`; `T/evidence/product-e2e.md`; `T/evidence/final-review.md` | **僅頂部historybanner**連新版：原ca00bc0／source7e81b77／實際precommitbuildsourcehash；舊觀察／收據／SHA／verdict內容原樣 |
| M06 | `D/BUILD.md`; `D/visual-review.md`; `D/tool-evidence.md` | **僅頂部historyindex**，明示舊圖production歸屬已撤回、原版本與新revision；原工具事實不改 |

### R：保留及唯讀

- E007全部32個trackedleaves逐bytes保留；E001–E006及其sources／receipts保留；不新run、不改原unknown／cleanup收據。
- `D/scene.js`、`D/responsibility-canvas.html`與3張舊Archify的spec／HTML／delivery／visual-checkJSON／HTML／12PNG逐bytes保留。M06只是導覽banner，不是重生成／修舊native收據。
- `Package.swift`、`Package.resolved`、consumerPackage／lockfile、既有productionSources／Tests（僅M01/M02精確撤回例外）、packages、BC、PRInboxPresentation及既有harness、工具skills/config/hooks/AGENTS/.gitignore/.github configs皆不改。rootPackage本topic原無變更，現在也不能新增Appproduct或root測試依賴。
- PR #61及其worktree只讀參考host分離，不搬檔／改commit／做去重；所有其他topic文件與圖只讀。
- 原安裝Rivet.app、其真DPKitems、OAuthApp／Appleprofiles／certificate保留，不revoke／刪除／migrate。不沿用舊App namespace當新host。

本輪production23個路徑＝D19＋M01/M02四檔；以base與修後比較必須zero-diff（19個原新增檔須不存在），不是只通過allowlist測試。base後若有他人更動先停並逐hunk評估，不能盲目restore整檔。

## 3. swift-implementation 執行順序

| Step | Owner | 範圍與完成條件 |
|---|---|---|
| R01 | Plan-Creator | 四artifacts現行scope／manifest／歷史界線完成，交獨立審查；不產生approval |
| R02 | Plan-Reviewer | 獨立approved或具體requiredfixes；approved才開始source回修 |
| R03 | Implementer | D19搬移／撤回、M01/M02還原、App與localdependencies／controlled／receipt／tests完整、自驗交接，W05逐檔action實表 |
| R04 | Tester | 獨立TC01–TC07，含排除App production build/test；回報命令／hash／限制，不補真人結果 |
| R05 | Reviewer | 獨立bounded source／dependency／scope／測試審查；重大問題先修，approved後準備真人段 |
| R06a–R06f | Tester＋Human觀察 | 依technicalspec六段逐段操作／Human回報，未執行皆pending；需要Human先通知，不能預填 |
| R07 | Implementer | M04–M06文件修truth、W06/W07新版圖與archify／canvasQA；可在不依賴真人結果的部分先做，未驗部分標pending |
| R08 | Tester | 核對新圖／工具實證及所有manifest／privacy／歷史immutablehash／真人provenance；獨立結果 |
| R09 | Reviewer | 獨立成果／宣稱／流程review，批准或requiredfixes；不代Human接受，profileunknown不改pass |
| R10 | Implementer | 依已授權topiccommit；每組stageddiff語意／message檢查及mandatoryhooks；真base/head PRLenscoverage、graphify有限使用，正常push後更新原DraftPRtitle/body並讀回 |
| R11 | Human | 原Draft PR #62 human review；不merge／release |

不另加啟動／採用／commit確認。needs-rework交相應作者，獨立重驗限影響範圍；blocked／human-check交Human。角色依既有workflow獨立，不自審。每次handoff須帶九欄、展開精確files、case、upstreamverdict及未解問題。

## 4. TestCase 與證據

| ID | 方法及判準 |
|---|---|
| TC01 | 逐檔核對23productionpaths與16606b89zero-diff、Package／locks不變、E00732與舊native圖hash不變，actions表覆蓋所有新增／搬移／改／刪／保留 |
| TC02 | xcodebuild新project/scheme普通unsignedbuild及fakehostedtests；showBuildSettings/plist核target/module/product/testhost、Swift6/macOS15／arch／keychaingroup；無新runtimepackage，production無App反向依賴、App無RivetPresentation |
| TC03 | App-localstate／PKCE／exactcallback／cancel／denied／invalidresponse／single-session／relaybounds／sixfieldcodec／兩itempartialsave／repair／redaction；transport/Securityfake，不能冒充真服務 |
| TC04 | localrefresh可信response/error／cancellation階段／redirect／timeout／strictDTO及finiteDates；samegenerationtrackerterminal對照既有provider；rotationIndeterminate／afterRequestStarted／accepted-savefail停止，nonterminal不誤停；querytracker零額外snapshot／network／store |
| TC05 | latch驗settlement／所有reauth退休、cancel／grant/savefail不復活、temporaryretry同provider、newbundle完整保存後才新provider；root既有singleflight／version／HTTP401有限retry回歸 |
| TC06 | newtestkey最早guard、livecounters0；clock單次trustedrestore／真save後real／observe不強制；privateexclusive收據、六欄digest及敏感資料negativecases |
| TC07 | rootintegration及publicconsumer原baseline回歸、RivetPresentation適用tests；在owned獨立scratch排除**整個A**後普通swiftbuild與相同productiontests，production檔無需改。reallegacyKeychain測試如會碰他人真item不執行，明列skip範圍／原因；strictswiftformat／SwiftLint、plistlint、gitdiffcheck／localdepsgraph。命令／exitcode／testcount真實記錄，不硬套舊226/29/13 |
| TC08 | 新host六段真人：簽章preflight；自有secret只填SecureField、初次OAuthsaveAPI；完整退出新PIDsamebinary；真正CleanBuild新binarysameidentitysamepath；controlledexpiry真GitHubrefresh真DPKsave；新PIDobserve輪替讀回API。每段Humanready／提示／machinehash分列；初次≤1、fresh/rebuild0；未取得結果明列pending，不用舊host補 |
| TC09 | 4長期docs及新舊evidence連結、revisioncanvas責任／單向依賴；三Archify sequence/lifecycle sourceconsistent，依skillvalidate/build/visualQA、light/dark實際截圖親看；native receipts不手寫、作者內容繁中、Viewerfallback如實記，無artifact.cafepublish |
| TC10 | staged每組語意／message與mandatoryhooks；PRLens真base/headrename-awaremanifest／coverage／validate-render及圖片檢視，標清映射commit不虛稱後docs全覆蓋；Graphify每次禁autorefresh，無usablegraph用targetedsourcefallback，不建graph／裝hook／傳repo。push後讀回原PR Draft/OPEN/base=dev/headbranch與SHA、無CI則不稱green；dev乾淨未改 |

如本機工具需要cache/dependency權限，先完成可行部分再走實際權限流程，不改hooks／跳過必要check。真人新identity如無法簽章先停；不得借舊identity／舊真token維持看似通過。

## 5. 交付宣稱與歷史

舊S01–S12及2026-10-20實測仍是原版本歷史。新host若未真人驗收，只能交付「工具已build/test，搬移後live未驗證」，不得宣稱完整新host通過；目前R06全部pending。必須等適用真人結果與獨立review，或Human對明列未驗項作具體決策；既有接受profile更新unknown不擴張成其他豁免。

PR #62改名／body以「GitHub持續連線獨立驗證工具與可行性結果」為主，列新增App／production撤回／新測試／真人新舊來源／E007unknown及限制。沿原branch和PR，不重開／merge。所有本輪變更清單落W05；只可保留topic前正式能力，不留驗證productionAPI／共用UI／控制／收據工具。
