# GitHub OAuth 正式憑證儲存：受限執行計畫

- Topic：`github-oauth-credential-persistence`。
- Branch：`feat/github-oauth-credential-persistence`；base／Draft PR target：`dev`；base supplied by dispatcher：origin/dev 16606b89。
- 工作位置：本 topic 專屬 feature worktree，禁止修改別人的 persistent-connection worktree／E007。
- 配對：[需求](../../analysis/github-oauth-credential-persistence/requirements.md)、[技術契約](../../analysis/github-oauth-credential-persistence/technical-spec.md)、[帳本](github-oauth-credential-persistence.step.md)。
- `swift-implementation` 為交接標題，不是同名 skill。分支符合 git-branch-naming 小寫 ASCII／連字號、無既定 owner 時 feat/work-item；不另換分支。

## 1. 原 adapter 交付九欄 bounded contract（新增 live 見 §5）

| 欄位 | 精確範圍 |
|---|---|
| In-Scope | additive configuration／DPK stores、兩 items strict codec、有限錯誤、同步 Security seam／shared actor、fake-only provider／consumer驗證、長期文件與單張 storage sequence |
| Out-Of-Scope | 登入／callback／UI、signed host、E007／live Security／profile／prompts、provider／ports／clients／package改寫、新BC、logout、遷移、多帳號／跨程序協調 |
| ReadOnly | 下列 R leaf／既有 foundations；與 Modify 無重疊；其他檔案不因可讀而可寫 |
| Written | 下列 W01–W04 精確 leaves；W01 本次建立後是既有 artifacts，不重建；不存在才建立，已有非本topic內容先停核對 |
| Deleted | Repository 無；只清本輪 proven-owned temporary test／外部工具 scratch，不碰正式items或Human assets |
| Modify | 僅 M01–M02；M03四artifacts依角色維護，不讓Implementer代填approval |
| Goal | 正式adapter可由caller注入，完整保存／還原／替換，fake契約與provider停止行為可獨立驗收 |
| Non-Goal | 假測試冒充真DPK、cross-process、signing／prompts或完整登入；依賴他人整套Mission gate |
| TestCase | T01–T08；每次handoff明列本段精確leaves、命令／輸入／證據，不能以整表授權任改 |

## 2. 精確 manifest

W01（四份正式 artifacts；後續依 M03 維護）：
- analysis/github-oauth-credential-persistence/requirements.md
- analysis/github-oauth-credential-persistence/technical-spec.md
- plan/github-oauth-credential-persistence/github-oauth-credential-persistence.plan.md
- plan/github-oauth-credential-persistence/github-oauth-credential-persistence.step.md

W02（Implementer 新 source／test）：
- Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift
- Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift
- Tests/GitHubIntegrationTests/GitHubOAuthDataProtectionStoresTests.swift

W03（文件／圖；前綴 `docs/architecture/diagrams/github-oauth-credential-persistence/`，每一項為固定leaf）：
- docs/architecture/github-oauth-credential-persistence.md
- 該前綴下 storage-sequence.json、storage-sequence.html、BUILD.md、tool-evidence.md、visual-review.md。
- 同前綴 storage-sequence.delivery.json、storage-sequence.visual-check.json、storage-sequence.visual-check.html、storage-sequence.visual-check.1440x900.light.png、storage-sequence.visual-check.1440x900.dark.png、storage-sequence.visual-check.2048x1320.light.png、storage-sequence.visual-check.2048x1320.dark.png。
- Archify 自己的私有 same-directory frozen snapshot 僅限工具建立／清理，不授權手寫其他檔；若工具需額外保留／追蹤leaf，先回 Plan-Creator 明列並獨立審查。

W04（各角色 evidence；前綴 `plan/github-oauth-credential-persistence/evidence/`）：
- planning-review.md（Plan-Reviewer）、implementation.md（Implementer）、tests.md（Tester）、review.md（Reviewer）、publication.md（發佈執行者）。
- 各role只寫自己的事實／判讀，不代他人產approval或覆蓋歷史結論；需revision先明列新leaf。

M01（consumer驗證及靜態隔離 allowlist 機械更新）：
- Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift
- Tests/GitHubIntegrationTests/StaticIsolationTests.swift：僅在 expectedPaths 新增 Contracts/GitHubOAuthAppConfiguration.swift、Stores/GitHubOAuthDataProtectionStores.swift；Security import allowlist 僅額外允許 Stores/GitHubOAuthDataProtectionStores.swift，保留既有 legacy Keychain 例外及所有其他檔案限制，不改隔離 policy。

Planning amendment（2026-10-20）：本追加僅容納新增 adapter 必要的既有靜態 allowlist 更新，不增加產品 scope、測試豁免或 gate。由獨立 Plan-Reviewer bounded 回查；結果可在既有 evidence/planning-review.md 追加歷史，不新增 evidence leaf。本角色未修改測試或執行驗證。

M02（長期文件，只更正實際能力、限制與連結）：
- README.md
- docs/design-principles.md
- docs/architecture/README.md
- docs/architecture/github-oauth-dual-client.md

M03：W01四份artifacts。Plan-Creator維護requirements/spec/plan；各role按實際證據維護step自己的交接，Dispatcher不代審查者核准。

R（必要唯讀leaf）：
- Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenFetcher.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenRefreshError.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/TokenSnapshot.swift
- Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift
- Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientScope.swift
- Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientPreparationError.swift
- Tests/GitHubIntegrationTests/OAuthTokenProviderTests.swift
- Package.swift、docs/toolchain.md、docs/development-workflow.md、scripts/check-github-integration-consumer.sh、scripts/check-swift-format.sh、scripts/check-swiftlint.sh。
- 既有REST／GraphQL／HTTPClient／其他BC／tests／experiments均唯讀；tests 唯讀明確排除 M01 的 Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift 與 Tests/GitHubIntegrationTests/StaticIsolationTests.swift，後者僅允許上述兩個 expectedPaths 及單一新增 Security import 例外；其餘限制不變。其他topic artifacts不修改；AGENTS／skills／runtime／config／hooks／gitignore／version stamps不修改。既存.pr-lens config僅存在才讀，不建立。

## 3. TestCase 與執行順序

| ID | 輸入與驗證 |
|---|---|
| T01 | Fake-only設定／六欄往返、inspect／bound ID、bound save不同ID／corrupt／denied／unavailable不覆寫、合法過期日期／空scope、throwing public construction、diagnostics redaction |
| T02 | Strict codec negative：version／missing／null／wrong type／emptytokens／nonbearer／nonfinite date；錯誤分類與invalid config零Security calls |
| T03 | Fake query／attributes精確核對DPK／sync／group／service／account／protection；update→missing add→duplicate一次update；denied不retry／delete |
| T04 | 完整A→B替換；各寫入失敗不部分commit；兩items獨立、configuration-first partial-save不rollback；shared actor所有facades完整operation序列化 |
| T05 | 正式adapter＋fakeSecurity＋受控clock/fetcher：restore、到期rotation先save再snapshot；accepted rotation save失敗後同provider terminal persist，後續無額外refresh/save |
| T06 | swift test；scripts/check-github-integration-consumer.sh；scripts/check-swift-format.sh；scripts/check-swiftlint.sh；既有provider／雙client regression不改期望 |
| T07 | Archify一張sequence source-consistent；validate／deliver九checks零errorswarnings；visual-check1440×900／1600×1000／1920×1080／2048×1320 lightdark與人工截圖檢視，Human pending如實保留 |
| T08 | docs／PR敘述／diff scope一致；無secret與live成果誤稱；獨立review及commit/push/DraftPR實證、停Human review |

獨立 Plan-Reviewer approved → root Implementer bounded TDD（先fake failing tests，再實作T01–T05及consumer，跑T06；W02/M01）→ 文件／圖W03/M02 → 獨立Tester T01–T08適用部分 → 獨立Reviewer。Required fixes只回獨立Implementer，審查者不自行修改受審產出。工具產物／QA未完成不得宣稱文件完整；無法取得Human視覺觀察可標pending帶入DraftPR，不冒稱接受。

原 T01–T08 tests 均假資料、無liveSecurity／GitHub／signing；不因adapter實作完成而觸發真DPK。2026-10-21 新授權的真人驗證僅依 §5 bounded contract，不能擴及原tests。適用checks只跑read-only模式，不formatter掃寫其他檔；build/cache在generated scratch。

## 4. 工具、發佈與停點

Archify 2.16讀sequence schema/common/example後才寫候選，showcase九checks、零errorswarnings；validate成功freeze，deliver再visual-check。不發布artifact.cafe。圖的作者繁中、Viewer英文fallback；人工看lightdark截圖，auto visualReview=pending不改成Human pass。不能為過check刪語意或裁切溢出。

PR Lens 0.11.0：有實際bounded committed diff才取git diff --find-renames <base>...<head>及真IDs，在外部topic scratch validate/render、讀manifest／必要unchanged neighbors/fileRefs；無committed diff先標待做。Graphify0.9.73每CLI GRAPHIFY_NO_AUTO_REFRESH=1，既存graph才boundedquery/sourceverify；目前無graph則rg。不得build/refresh/install/改設定/upload/PR writes；輔助工具具體失敗可source/diff fallback，不新增gate。

Reviewer通過且無重大blocker後，依已授權topic commit→push→DraftPR到dev。依git-commit-convention檢查staged語意／message；既有明確授權不再重問一般確認。發佈執行者記真commitIDs／checks／DraftPR URL；不merge，停Human review。PR Lens於實際commit後、DraftPR前補真diff evidence；若只改工具evidence，另以實際最終HEAD再確認source關係，不捏造未存在ID。

Scope／path／public contract變更、工具新增需保留leaf或重大錯誤回planning／獨立審查；無法解除的外部權限停報具體阻礙。這不是E007／renewal／45分鐘live gate，不要求他人實驗或真簽章先通過才交付本topic。

## 5. 2026-10-21 live validation amendment（同 topic）

來源：User 明確授權新增真人驗證；只擴本topic bounded validation，不改productionAPI或依賴他人實驗。§1的fake-only／無signedhost排除僅指原T01–T08交付；本節對新增L工作優先。原fake結果／PR #60／S08 pending保留。準備先審查，未取得逐段Human ready不得簽章或live。

### Live handoff 九欄

| 欄位 | 新增受限契約 |
|---|---|
| In-Scope | 自有最小signed validation App／runner、strict私有manifest／公開projection、pure guards／unsignedbuild、逐段Human觀察的假credential cross-process／真正rebuild／精確cleanup |
| Out-Of-Scope | 產品store／ports／clients／Package.swift改寫、登入／OAuth／網路／UI、configuration item、他人E007／App／account資產、新cert／trust／安全設定／付費、renewal／新profile要求 |
| ReadOnly | production source、rootpackage、既有docs／tests／tools／PR歷史，除四artifacts外原W/M均不再取得本live交接寫權；他人worktree不得讀寫 |
| Written | 僅下列L-W01九個validation檔與L-W02確切evidenceleaves；私有runroot依immutablemanifest建立本run自有copy／buildoutput |
| Deleted | Repository無；僅strict ownership proof下的單一UUID credential item與本run proven-owned私有files；不是產品logout／Appleassets刪除 |
| Modify | 本topic四artifacts按role維護；本次只Plan-Creator amend，不代他人填approval。準備／真人結果不修改歷史fake結果 |
| Goal | 新程序與同身分真正重建完整還原假B、提示門檻有當次Human證據、精確清理可證 |
| Non-Goal | unsignedbuild／fakeguard冒充live、hash不同或adhocexit0冒充有效重建、未答推0、用新namespace掩蓋舊殘留、把S08自動核准 |
| TestCase | LT01–LT07，先L01審查→L02準備→L03Tester→L04Reviewer；後續L05逐段Tester+Human→L06cleanup/result，無E007gate／45分鐘窗 |

### 精確追加 manifest

L-W01，固定前綴 validation/github-oauth-credential-persistence/，每項為一個leaf：
- README.md
- CredentialStorageProbe.xcodeproj/project.pbxproj
- CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme
- CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme
- Sources/main.swift
- Resources/Info.plist
- Resources/CredentialStorageProbe.entitlements
- scripts/credential_storage_live.py
- Tests/test_live_protocol.py

L-W02，固定前綴 plan/github-oauth-credential-persistence/evidence/：
- live-preparation-tests.md（Tester）。
- live-preparation-review.md（獨立Reviewer）。
- live-validation.md（Tester記machine結果與Human原意的有限觀察摘要；只追加歷史，不代填未知或覆寫）。
- live/<UUID>/setup.machine.json、setup.human.json。
- live/<UUID>/save-a.machine.json、save-a.human.json。
- live/<UUID>/read-a.machine.json、read-a.human.json。
- live/<UUID>/replace-b.machine.json、replace-b.human.json。
- live/<UUID>/read-b.machine.json、read-b.human.json。
- live/<UUID>/rebuild.machine.json、rebuild.human.json。
- live/<UUID>/rebuilt-read-b.machine.json、rebuilt-read-b.human.json。
- live/<UUID>/cleanup.machine.json、cleanup.human.json。
- live/<UUID>/run-summary.json。

UUID取immutable runmanifest，公開JSON一律exclusive-create，不覆寫或捏造未發生成功。數值／actions／hash等均經technical-spec §5 allowlist投影，不export整份私有stdout。run-summary於停止／完成才寫finalstatus；尚未完成前只留私有progress，不重寫publicsummary。原planning-review.md可追加本amendment的獨立判讀，保留歷史，不新增規劃審查leaf。

私有0700 ownedrunroot只包含：copiedproject/Sources/Resources、精確derivedbuildoutputs、current/CredentialStorageProbe.app、immutable manifests／sourcebuildsigningproof、逐段privatechild/machine/Humanreceipt、absence／write-attempt／cleanupownershipproof。原始路徑／Team／profile／PID／privategroup只在此。清理只按manifest記錄leaf，不刪父目錄或Human assets；遇guard不足留root與恢復交接。需額外repositoryleaf先修本manifest再獨立審查。

### LT 驗證與停點

| ID | 方法／驗收 |
|---|---|
| LT01 | Pure UUID/service/account/group／manifestidentity、immutable/exclusive-create、0700root與pathownership；exists或unknown即不寫，未owned零delete |
| LT02 | Fake Security/child驗證absence→persist write-attempt→save順序；writeerror/crash仍retainmarker；exactdeleteflags→adapterreadnil；cleanupfailure可同root恢復、不清其他assets |
| LT03 | Fake staging：每段freshready／previousPIDterminated／freshUUID、未知Human結果不前進、machineSHA exactbind、setup/rebuild提示與runtime分開；finiteprojection無秘密／自由文字 |
| LT04 | 無簽章unsignedXcodebuild驗App兩schemes／compilemarker／localpackage；publicadapter呼叫不抄codec。來源hash核對、真正buildproof、DR/profile/cert/AppID/group/location檢查與negativeguard以fixtures先測 |
| LT05 | 真save-a≤1prompt、freshread-a=0；replace-b六欄等於B且記實際提示數，freshread-b=0；各phase先前PID退出、不同processUUID，source一致 |
| LT06 | 真Rebuiltschemebuild，actualsource/buildreceipt、marker=true、binaryhash不同；有效同cert/profile/AppID/group/DR/位置；rebuiltfreshreadB六欄一致且0prompt；缺任一前提為未驗證／unknown |
| LT07 | Cleanup另段freshready與觀察；exactowneditemdelete後adapterreadnil、精確私有files清理與公開evidence留存，殘留／未觀察如實報；runsummary不把unknown當成功 |

L02只準備L-W01與pure/unsignedchecks；不簽章、不profileinventory、不LaunchServices、不liveSecItem。L03/L04只驗此準備，不能當liveapproved。L05 setup ready後才Human選已有identity/profile，禁止allowProvisioningUpdates；按technical-spec §5全部階段依序launch open -W，不用open -n／rawGUIlaunch。每段後取得count/actions/完整觀察+SHA，未答停dependent段；setup/rebuild簽章提示不混runtime。無fixedtimebox／renewal要求。新cert、安全trust／paid、identity/source mismatch、ownership不明即停；若可能寫過，最小recover-cleanup交接必保留。

本次派遣只到L01獨立planningreview；之後先完成準備再逐段詢問真人ready。Live未成功不得改先前docs限制為已驗證，也不重寫S08 Human接受。


## 5.1 Setup retry 候選準備 amendment（2026-10-21；待獨立審查）

此節只容納必要驗證工具補修，執行細節以 technical-spec §5.1 為準；不是Human已採用Automatic。先準備至reviewable，Human boundary只在實際執行前，不用一般ready阻擋純準備。原setup unknown/build與Tester綁原machineSHA的formal whole0、原manual0歷史不改。

| 欄位 | 本 amendment 精確子集 |
|---|---|
| In-Scope | 同run一次setup retry-1、保留frozen targetAutomatic、移除全域六override、no-portal-permission、exactbaseline、獨立immutable收據／雙歷史export與effective依賴 |
| Out-Of-Scope | 真retry／build/sign/Run/SecItem於準備期、新run／新assets／trust/security/paid／OAuth／E007、改production／Swift／project/templates／identity/runmanifest |
| ReadOnly | 原production四pins、copied五pins、privatePBX／identity／manifest／原machine/Human及既有profile/cert/DRproof；不inventory其他資產 |
| Written | 原L-W02角色evidence只append；公開新增僅下列兩leaf，summary使用未建立的原leaf；private僅spec固定retry-1storage |
| Deleted | Repository無；不刪原收據／attempt／資產；原ownership cleanup契約不擴 |
| Modify | 四artifacts按role；L-W01九檔仍登錄，這次Implementer僅README.md、scripts/credential_storage_live.py、Tests/test_live_protocol.py及自己的step交接 |
| Goal | 工具可獨立審查、一次新ready下的真retry可觀察且不覆寫原失敗；全guards/Human成功才解鎖 |
| Non-Goal | 準備approval冒充policyadoption／cachedAutomatic已可行；不帶flag冒充所有本機cache零變更；舊ready重用／unknown轉success |
| TestCase | 原LT01–04適用子集，新增下列RT01–RT04；純runner修正不重build不變Swift |

L-W02固定前綴 `plan/github-oauth-credential-persistence/evidence/live/<UUID>/` 精確新增 `setup-retry-1.machine.json`、`setup-retry-1.human.json`；原setup兩leaf不動。尚未建立的run-summary.json採spec §5.1 v2固定欄位與保守歷史聚合。其他repository leaf不新增。私有固定 `private/setup-retry-1/`：attempt.json與原setup同名整套read/build/proof/observation輸出，新增私有輸入精確為 `private/setup-retry-1-fresh-ready.json`、`private/setup-retry-1-policy.json`，原run／identity／PBX／原logs不動；所有路徑仍strictowned／exclusive。

| ID | 必要準備驗證 |
|---|---|
| RT01 | 實際build入口argv移除六項全域override、拒絕portal/device/authkey flags；沿frozenPBX，cached缺失與exact cert/profile/DR漂移不install／launch |
| RT02 | retry入口原unknown+HumanSHA preflight、新policy+ready、wrongrun／重放／第三次／stalehash拒絕；directory或attempt任一存在即佔額度，mkdir後attempt前crash／partial不可重用，保留proof及原bytes，無新identity／manifest |
| RT03 | observe／export雙歷史exactSHA、v1兩新leaf／v2summary固定欄位；原unknown不變、unknownHuman不補0，summary不掩蓋歷史 |
| RT04 | directory-or-attempt任一存在即只選retry，directory-only／partial／缺attempt或receipt fixture結果須retry unknown、effective=null、依賴blocked／不fallback initial且禁止第三次；全guards＋Human成功才save-a，runtime及rebuild取retryproof並比原bootstrapDR |

交接順序：L01（本amendment獨立Plan-Reviewer）→L02 Implementer bounded red→green→L03獨立Tester→L04獨立Reviewer，使用原planning-review.md／live-preparation-tests.md／live-preparation-review.md各role追加、不新增evidenceleaf或代approval。原L系列既有approved歷史不刪；本次候選尚未approved。

工具完整reviewable且獨立接受後才交Human：明確採用Automatic cached／不授予portal更新（非本機全部assets零變更保證）及同run唯一retry，另給全新當次setupready，然後才L05一次實際retry／actual觀察。缺採用或ready、要求絕對零資產變更而證據不足、cached缺失／guard失敗均停止，禁止自動試其他策略。L06 cleanup與S08 Human接受不改。


## 5.2 最小可診斷工具補修（Human已採方向；準備待審）

Human「確認」只採最小方向；不授新run／第三次setup／重試save-a／實際build-sign-launch-DPK。具體bootstrap／schema／精確私有leaf／fallback以spec§5.2為準，不新增Mission或repo leaf。

| 欄位 | 本輪精確子集 |
|---|---|
| In-Scope | 可信bootstrap後的早期finite診斷、diagnostic-only零store/SecItem、未來獨立exact readonly mode的guards、fake-only實測與55 regression |
| Out-Of-Scope | 產品API/provider／登入/OAuth/E007、泛用recovery、新assets／安全設定、原run寫入／替換binary、實際xcodebuild/sign/launch/DPK、任何save/delete或新真人run/ready |
| ReadOnly | 整個原run 8ad8fb3b-51d9-4162-98fb-067521a37b4e及其machine/Human／manifest／identity／PBX／pins／current App；production/package/templates/schemes/resources／他人工作線 |
| Written | 無新增repo leaf；只原四artifacts及既有role evidence各自append；nonlive自有TemporaryDirectory與unsigned compile scratch；真人私有診斷inputs/receipts僅未來Human段落 |
| Deleted | Repository／原run／items／Appleassets皆無；只本輪普通proven-owned nonlive temp按測試清理，不是舊namespace清理 |
| Modify | L-W01既有Sources/main.swift、scripts/credential_storage_live.py、Tests/test_live_protocol.py、README.md；四artifacts按role，Implementer只自己step，不代approval |
| Goal | 早期throw有可信且finite可觀察診斷、無可信bootstrap安全unknown；原unknown與root完整保留 |
| Non-Goal | 新copy/context冒稱舊Writer重現、nil/無PID回溯無寫、無ownership delete、舊fakebinary代新Swift、準備approval當執行ready |
| TestCase | 下列DT01–04及原55case；隔離swiftc unsigned新main fake-only，不xcodebuild／sign／AppRun |

未來私有namespace固定 `rivet-credential-storage-diagnostic-<UUID>`，不是新credential run；diagnostic.json／app/CredentialStorageProbe.app與diagnostic/namespace的machine／human／ready固定leaf依spec。現在不得建立真人root或輸入，原root不可寫。公開結果只在既有live-validation.md由Tester追加脫敏有限摘要，不新增JSON/evidenceleaf或改舊summary；code準備用原live-preparation-tests.md／live-preparation-review.md，planning用原planning-review.md，各owner只append自己歷史。

| ID | 必要驗收 |
|---|---|
| DT01 | 真Swift共用bootstrap前不可信inputs零落檔；SHA／UUID／schema／pathownership／symlink／escape／既有receipt拒絕，錯誤不含私人資料 |
| DT02 | 真Swift早期args/request/identity/Bundle/entitlement失敗有獨立finite收據；diagnostic-only零store/四SecItem，成功也不perform；不能啟動／bootstrap失敗→runner unknown不造Appreceipt |
| DT03 | readonlyfake nil／present／finiteerror只當下狀態，最多一次load零save/delete；無ownership／marker／unknownchild不放行原cleanup，原所有bytes保持 |
| DT04 | Python實際dispatch／有限projection／exclusive／新ready與HumanSHA隔離、55regression；隔離unsigned新main實際fake case IDs及source/binaryhash，Tester不能沿用舊binary稱新case通過 |

先D01獨立Plan-Reviewer→D02 Implementer受限TDD／新Swift fake-only編譯→D03 Tester→D04 Reviewer。然後才D05 Human新host build/sign當段採用／ready（與第三次setup無關，不替換舊current）；再D06 diagnostic launch獨立ready／實際觀察；再D07 exactnamespace唯讀獨立ready／實際觀察。每段缺前提／securitypermission／資產需求即停。現在D05–07只列停點，不執行或自動批准；不能安全恢復就保留，沒有delete或新run fallback。


### §5.2 私有防重放 leaf 最小補充（待獨立delta審查）

僅新增同diagnostic owned scratch的固定private `diagnostic.consumed-ready.json`／`namespace.consumed-ready.json`；非repository leaf，不擴Mission／schema框架／執行授權。輸入與執行前guards全通後、任何launch前，必須exclusive0600＋fsync記schemaVersion=1／diagnosticUUID／purpose／readyUUID／readySHA256，UUID/SHA不公開。任一既有或partial標記均耗用該purpose額度、不讀成未執行、不刪除重用；寫入或fsync失敗不launch，無Appreceipt也不得retry。DT04追加實際runnerdispatch fixture：正常consume-before-launch、partial／existing／writefailure／missingAppreceipt後ready重放均拒絕，標記不是App成功或舊namespace ownership證據。只此delta交Plan-Reviewer；其餘D01 approved契約不改，未審前不實作額外leaf。


### D05 可審新host準備清單（待獨立delta審查，非執行）

D04的工具approved保留；D05的具體caller順序、完整xcodebuild argv、現有frozen helper精確呼叫、五個新增private build leaves與finite build.machine/Human binding，以spec§5.2「D05 新host build/sign具體caller清單」為本次唯一候選。沒有新repo leaf或builder程式。只新增spec／本plan／作者step文字，未改凍結四葉／模板／evidence，未建立任何真人輸入或執行命令。

九欄delta：In-Scope只為D05 reviewable prepare/copy/既有cached Automatic build-sign/exact檢查的候選清單；Out-Of-Scope仍為現在任何執行及D06/D07 launch/DPK、第三次setup/save重試、新資產／安全設定；ReadOnly包含整個原root/current/identity/PBX及所有舊收據；Written僅未來當段ready後的新owned diagnostic scratch之五個build private leaves、source/project/derived/app/proof及既有diagnostic.json；Deleted無；Modify本次僅spec/plan/ownstep；Goal為Human採用前具體可審的獨立新host freeze；Non-Goal為原run修復／App觀察收據或預授D06/D07；TestCase由獨立Reviewer靜態核caller各guards/argv/schema/失敗停止，未要求重新跑unsigned/build以代實際執行。

交獨立Plan-Reviewer確認此delta，再由Human採具體D05 scope與新freshready；不把文件完成或D04 approved當ready。執行者先核D03/D04實際freeze；原已採cached Automatic/noPortal policy不擴為新profile/cert/trust/付費權限。新App和diagnostic manifest成功freeze後仍停止問D06；任一失敗只保留新proof，原run及unknown保存A歷史完全不改。


## 5.3 Launcher amendment：啟動紀錄缺口（2026-10-22，待獨立審查）

Human授權只準備到可審查及non-live驗證；確切schema／同context一次attempt／caller CLI／sentinel／失敗fallback依spec§5.3，非新Mission或執行ready。原D05成功／Human0、D06unknown／Human0、原保存A及Keychain受限歷史保留。

| 欄位 | 本輪精確子集 |
|---|---|
| In-Scope | native launcher有限紀錄、finally/exclusive持久與寫入失敗fallback、同N唯一amendment、invalid sentinel防legacy save、Human真receipt SHA binding、non-live tests |
| Out-Of-Scope | 現在App launch／process probe／sign/build／DPK／新root或真人inputs，host/rebuild/nonce擴張、D07、retry／kill／新assets/security/付費/清理/Git、dev/E007 |
| ReadOnly | 原run全部資料及D05 diagnostic root既有檔案／D06所有bytes（不含未來新增D）；production／Package.swift／host main.swift／PBX／兩schemes／Info／entitlements／N/source snapshots；不與Modify重疊 |
| Written | 本四artifacts與各owner原evidence leaf；實作普通fake temp；未來明確新段落ready後才可N/diagnostic-launch-amendment-1的原八個固定leaves＋兩個pending publication候選leaves（spec列明，delta未審前不實作） |
| Deleted | Repository／真人root/items/assets無；測試僅自有temp及已知fakePID受控settlement |
| Modify | validation/github-oauth-credential-persistence/scripts/credential_storage_live.py、Tests/test_live_protocol.py、README.md；其餘既有九leaf六檔不改；planning四檔按role |
| Goal | launcher attempt即使native／receipt／disk失敗也有如實有限結果或明確無持久證據，不能exit0冒充host success |
| Non-Goal | 推定App已執行／安全退出、D06遲到收據歸新attempt、Keychain/DPK通過、歷史無寫或ownership、普遍recovery |
| TestCase | spec LG-T01–06及既有63回歸；LG-T03含malformed/binding無效→invalid、不可安全讀或存在性不明→unreadable/Present=null，均unknown且不hostconfirm；LG-T05只對owned N/D及descendants驗UID/0700，祖先只canonical/nosymlink；真fake-child入口，無真人App／Swift重編譯或新簽章 |

執行順序：LG01作者契約→LG02獨立Plan-Reviewer→LG03 Implementer red/green→LG04 Tester→LG05 Reviewer。皆完成後才LG06 Human審具體純launch scope與freshready／可辨識worker前提，再LG07 Tester單次受控launcher及Human actual觀察（目前未授、不執行）。任何partial attempt耗額、無自動retry/kill；現host無nonce，LG07整體仍unknown/hostConfirmed=false，只補launcher事實，不因新receipt而重寫D06。可靠hostconfirmed缺口只列後續，不能自行擴host/rebuild。原role evidence各自append，不代approval。


### LG current-state preflight最小澄清（候選delta，待獨立審查）

legacyWorkerSettled欄位名保留，語意僅本次完整唯讀snapshot的known-native-open absent；不是historical worker/App退出或DPK無寫。依spec§5.3，以ownUID/proc_pidpath核兩個既有host executable，只對ownUID精確open讀bounded KERN_PROCARGS2 argv，逐token比原save-a及D06兩個既有命令；不讀其他App argv、不保留無關資料。任一match／incomplete／權限或parse不明即停，不用ready、CLI0或單獨無App PID填true。LG-T05只加ordinary fixtures對此既有current-state guard的接線驗證；沒有新leaf／旗標／recovery／真人probe。已批准其他LG工作可保留，此delta未獨立通過前不實作該查核變更。


### RF-LG04-01 publication候選delta（待獨立審查）

只同D新增兩固定private pending leaves：launcher.machine.pending.json、caller-result.pending.json，合計十個，不新repo leaf。只本launcher兩receipt採exclusive pending寫入→file fsync→D fsync→最後不覆寫atomic link發布final，保留pending；final/pending同inode/bytes/schema才可Human綁定。發布是當次可觀察commit，不宣稱跨斷電目錄entry durability，不改全域legacy writer／其他六private leaves／host／舊root。

binding矩陣依spec：primary發布後caller失敗仍可綁primary；primary只有pending、caller發布可綁caller；兩者未發布（含完整pending）必null/noHuman；兩final矛盾拒絕。observe不再把caller缺失當primary殘留可用，而是只認已發布pair。LG-T04加真prepublication fsync fault與這四狀態actual entrypoint，原85及同RF兩反例noHuman保留。原LG04 needs-rework未解除；先獨立Plan-Reviewer審本delta，再回Implementer及原Tester，不前進Reviewer/live或新freshready。


### LG preflight stdout最小觀測delta（候選待審）

只修spec§5.3最後補充的pre-trusted-D stdout：原五keys加固定guardPoint/apiOutcome/apiReturn/errnoKind，真native errno不可得為unknown，不外洩rawerror/PID/path/argv。既有guard／OS呼叫／範圍及trusted-D後native/publication/Human契約不變；原LG06未知結果/真stdout SHA與Human0不可回填或重跑。Modify仍只有runner/Python tests/README三葉；Written無新增真人privateleaf／namespace／flag，Deleted無；ReadOnly仍所有舊context/host/manifest/receipts，Goal只定位未來guard拒絕點，Non-Goal為猜歷史根因或確認host/DPK。TestCase沿LG-T05/projection，fake API/exception/errno/敏感資料負例與94回歸；不真OSprobe或hostbuild。

路由LG08作者準備→LG09獨立Plan-Reviewer→LG10 Implementer→LG11 Tester→LG12 Reviewer。準備reviewable後才另交Human同N唯一純launch新scope/freshready；不是自動重試LG06，原LG06/07、D07/S08與所有歷史保持。各角色仍只原evidence leaf追加，不自批／不改其他owner結果。


### LG14 正向名稱預篩最小delta（候選待審）

依spec§5.3 LG14：先對ownUID列舉結果呼叫一次proc_name；可信成功且可明確排除所有固定host/open完整／31/15別名才略該PID path/args。只有仍與固定known完整／31/15別名／前綴相容或無法排除target的可信歧義名稱為candidate，完整path及selected-open argv保持；15/31長度本身不是candidate，可信且與所有known可能前綴均不相容者可排除、path/args零call，LG-N02同驗compatible與disjoint 15/31；name失敗／空／編碼或長度未知直接guard，candidate path任何錯誤仍拒絕，絕不略ESRCH/ENOENT。只加snapshot-name guardPoint enum、不增stdout keys／privateleaf／CLI flag／caller；finite metadata與publication/Human/sentinel契約不變，hostConfirmed=false。LG13 notFound不能推成無關PID或race，原stdout/Human及全部歷史唯讀保留。

九欄沿本節原表的精確manifest：In-Scope為上述正向名稱預篩及LG-N01–07；Out-Of-Scope為真launcher/App/全UID OSsnapshot/DPK／新ready／host改建／新資產及安全設定；ReadOnly為原root、context、identity、manifest、source snapshots、host及其他六validation leaves／所有舊收據；Written限四planning artifacts、各owner原evidence追加及普通自有non-live temp；Deleted無repo／真人資料／assets，只有已知自有finite child自然退出及測試temp收尾；Modify仍runner/tests/README三個既有精確leaf；Goal為可靠排除確定非目標後只完整檢查candidate；Non-Goal為name=identity／歷史settlement／host或DPK驗收／recovery；TestCase為spec LG-N01–07與全部既有99回歸。LG-N07限未修改sys.executable普通／偽裝argv0兩child，以及一個原機未修改且未複製的/bin/sleep有限child（executable=/bin/sleep、固定非秘密spoof argv0、1秒）；只query該Popen直接取得的own PID之name/path/bounded kernel argv0，自然退出wait，不列舉UID／其他PID，不copy/patch/sign binary或建App。直接native fixture依已知basename/path對照，不以Python launcher/shim假設填值；原Python path/argv0 mismatch限制保留，native結果另記，不可用／不符／非自然退出即記限制停止，不安全調查或假通過。公開source非本機runtime可行性的保證，先前exit-9未驗不冒稱通過。

路由LG14作者→LG15獨立Plan-Reviewer→LG16 Implementer non-live red/green／三葉新freeze→LG17 Tester→LG18 Reviewer；各owner只原evidence leaf記自己結果。準備授權不再要求Human預先採用planning，但實際sameN唯一purelaunch仍須上述結果及具體CLI後Human當段freshready；不重用LG13 ready／新invoke／清理或進DPK。


### LG20 fullinfo/status/instance受限契約（候選待審；真人暫停）

依spec LG20取代LG14 proc_name讀取，以公開SDK PROC_PIDTBSDINFO,arg1同筆讀PID/UID/status/starttime/name/comm及完整return；正向zombie狀態可排除、live正向noncandidate維持原名字規則，live candidate的完整path/open argv前後classification與A/B instance/status/name一致才接受本次查核。真衝突／permission／unknown／變動仍guard。不採private flavor，不把errno當gone。**Reaped本輪仍guard**：無complete flag的ownUID列表不支持完整absence，exactPID sysctl亦未證本機MAC可見性條件，故不新增membership/fallback/query框架。這是修zombie結構缺口，不承諾所有prelaunch failure消失或race-free。

| 欄位 | LG20精確delta |
|---|---|
| In-Scope | SDK fullinfo/ABI、正向zombie/noncandidate、candidate有界instance/classification一致、有限processEvidence及LG-M01–07 |
| Out-Of-Scope | 真人launcher/App、全UID真snapshot、DPK、provider/產品API/host改動、private pidversion/kinfo解析、reaped errno略過、UID membership或exactPID fallback、retry/kill/安全/資產/cleanup/Git |
| ReadOnly | production／Package.swift／host main.swift及其他六validation葉、原run／N/context／manifest／identity／全部source snapshots/current/binary/收據與成功/unknown史、dev/E007 |
| Written | 本四artifacts／各owner原evidence leaf；普通自有測試temp、必要SDK-layout unsigned CLI（不新repo leaf）及唯一known-child資料只留private／finite projection |
| Deleted | 無repo／原root/item/asset刪除；普通temp收尾與已知自有child自然wait回收，不kill |
| Modify | validation/github-oauth-credential-persistence/scripts/credential_storage_live.py、Tests/test_live_protocol.py、README.md；各role自身step/evidence，不碰他人verdict |
| Goal | 修正active+zombie列表與arg0 name讀取不相容，得到可判讀的status/instance/衝突觀測，而不以不明metadata放行 |
| Non-Goal | LG19根因回填／無競態保證／所有reaped可跳過／hostConfirmed/DPK驗收／普遍processmanager或recovery |
| TestCase | spec LG-M01–07及既有104回歸；全UID全fake、只單一原版finite /bin/sleep knownPID可做running/zombie/reaped非真人證據；舊Python mismatch保留 |

processEvidence八keys與decision enum、有限guardPoint、stdout適用範圍完全依spec；published machine/caller/Human schema、publication與sentinel保持。未來具體purelaunch只能提供當次有限排除／拒絕／native事實，hostConfirmed仍false，原D06/LG13/LG19不改。源碼/zombie樣例不能代本機全snapshot或LG19原因。

路由LG20作者→LG21獨立Plan-Reviewer→LG22 Implementer TDD／SDK layout與known-child受限可行性／三葉freeze→LG23 Tester→LG24 Reviewer。各owner原evidence追加自己結果。Human standing已授此non-live準備，毋須另問內部planning許可；本輪真人/DPK暫停，**不列自動後續invoke step**。任何未驗metadata／ABI／非自然child狀態皆如實限制，不改環境或拿真人試運氣。下一段live必待Human另明確指示、具體同CLI／newfreeze與freshready，原ready絕不重用。


### LG26 path後查最小delta（候選待審；真人/DPK暫停）

依spec LG26，只在第一/第二proc_pidpath native返回≤0時同PID arg1 fullinfo後查一次；保留原path四欄與精確有限errno。同PID/UID/starttime可信zombie才exclude，liveSame／instance或classification變更／denied/unavailable/invalid仍guard，不稱reaped。不重試path／重列UID／改名字篩選或aggregate語義；stdout固定五key pathFailureEvidence及defaults／eventsource依spec，其他receipt schema不動。

九欄沿LG20表：In-Scope只此窄branch/post／五key有限證據與P01–05；Out-Of-Scope為真query/UIDscan/fixture/App/sign/build/DPK/cleanup、名字策略變動及普遍recovery；ReadOnly原roots/context/identity/manifest/host/production與其他六葉／全部歷史；Written僅四artifacts、owner原evidence及普通fake temp；Deleted無；Modify仍validation/github-oauth-credential-persistence/{scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}及ownstep；Goal為可區分本次path失敗後同instance狀態，不拿先前aggregate當證明；Non-Goal為LG25根因回填、race-free／hostConfirmed／DPK或reaped確認；TestCase為spec LG-P01–05與原114回歸。無新leaf/flag/caller/namespace。

LG26作者→LG27獨立Plan-Reviewer→LG28 Implementer局部red/green／114＋必要新cases及三葉freeze→LG29 Tester→LG30 Reviewer。各owner僅原evidence追加自己結果；真人/DPK仍暫停，不安排自動invoke或新ready，不以nonlive approved代Human執行授權。


### LG31 離線回報綁定（2026-11-03，待LG32審查）

Human授本輪最小planning/code/nonlive/review，舊N缺失不阻本輪；不代表採用或建立新operational context。Schema、request→report→獨立live-instance/binary核對→ACK→final及publication依spec LG31；nonce/processUUID非auth/fresh proof，unknown不補成功，入口先於legacy credential capability。

| 欄位 | 本輪精確範圍 |
|---|---|
| In-Scope | 四既有工具葉之獨立launch-report-only模式、嚴格五份schema／一次quota／安全output、fake hooks與有限projection、unsigned fake compile／LB01–06、後續操作文案 |
| Out-Of-Scope | 新真人context/namespace/ready、原N重建/reset、Xcode/signed build/sign/真App/全UIDscan/DPK/cleanup/新資產或安全設定、OAuth/login/E007/dev/Git |
| ReadOnly | production/Package.swift/ports/provider、原roots/manifest/identity/binary/receipts/ready/history、PBX／兩schemes／Info／entitlements五模板及其他topic |
| Written | 四planning artifacts、各owner原evidence追加；ordinary fake temp／必要本地locked modules與unsigned fake binary，不是正式context |
| Deleted | 無repo／原run/item/asset刪除；普通fixture自然收尾、已知own-child wait，不kill |
| Modify | validation/github-oauth-credential-persistence/{Sources/main.swift,scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}及owner自身step/evidence；不新增repo leaves |
| Goal | 讓未來一次host回報能綁可信request/context/binary/live instance，離線完整驗證拒絕與安全派送 |
| Non-Goal | 今日host實證／簽章／提示／DPK、原context恢復、同UID惡意攻擊防護或零競態保證、通用handshake/recovery框架 |
| TestCase | spec LB01–06＋原122 regression；新Swift source對應新unsigned binary，無法建立實際runtime前提就記限制，fake不升格signedhost |

LG31作者→LG32獨立Plan-Reviewer→LG33 Implementer局部TDD／新fake compile／freeze→LG34獨立Tester→LG35 Reviewer。各owner只自己evidence/row；LB/現契約偏離先回修、不臨場擴namespace或資產。Xcode config現有main單檔/APP target足夠，本輪無修改理由；若實際需要先列具體理由回planning。LG35之後仍停：先另提新context與signedbuild/verify的具體操作、資產/有效期/一次quota及停止條件，再由Human採用；另freshready才可能purelaunch，host attribution前DPK一直停。


LG31 RF-LG32-01短修：spec已鎖既有binding-consumed及launcher.machine完整exact keys/types/nullability、B/ready/runner/consume/receipt鏈綁定、native值一致性與失敗預設。Machine不含自身SHA；僅已發布原bytes SHA放外層stdout，partial/publication失敗不attributed。LB04加入兩schema缺/多欄、型別/null/binding/enum負例與partial耗額；無新leaf/框架/Human gate，requirements及其餘scope保持。作者修好交原LG32回查，不代approval。


### LG36：purpose限定profile-free診斷候選（只規劃，待LG37）

只此append supersedes將有效profile一律當純診斷前提的舊操作文案；不更動原DPK gates/146成果/任何舊history。執行設計、兩既有proof exact schema、recipe及PF01–05依spec LG36；不是已簽/已launch，也不是實作授權。

| 欄位 | 精確範圍 |
|---|---|
| In-Scope | 同target LAUNCH_REPORT_ONLY hard fence、profile-free purpose proof/驗證候選、原binding保障、必要fake驗收與操作proposal |
| Out-Of-Scope | 本輪code/tests/compile/build/sign/App/DPK/profile取得或變更、新context/ready、cert/revoke/trust/ACL/Team/BID/paid變更、OAuth/E007/Git |
| ReadOnly | production/ports/provider/Package.swift、PBX/兩schemes/Info/entitlements五模板、舊roots/assets/context/identity/receipts/ready/quota與全部歷史 |
| Written | 本輪僅同slug四artifacts；未來實作/owner evidence/fake scratch須Human採用與另派授權，實際R/proofs未建立 |
| Deleted | 無；不刪expired profile、quarantine、舊item/root/assets或partialquota |
| Modify | 本輪四artifacts；採用後才限validation/github-oauth-credential-persistence/{Sources/main.swift,scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}與owner step/原evidence，不新增target/framework/repo leaf |
| Goal | 不先取得profile亦能準備同原certificate身分的純啟動歸屬診斷，hard fence及OS/security標準保持 |
| Non-Goal | 今日OS成功、原DPK權利/產品登入驗收、替換原host/current或歷史修復、同UID攻擊/零競態保證 |
| TestCase | spec PF01–05；原146只原version證據，新variant須新fakecompile/必要拒絕及獨立review，後續signed/launch另授 |

路由LG36作者→LG37獨立Plan-Reviewer；approved後仍停Human採用，不能自動Implementer。採用後由Dispatcher另派bounded Implementer→Tester→Reviewer；通過後先審具體私有build/sign輸入／original identity適用性→另准unsigned build與原key當次sign→staticpostverify/finalbinaryfreeze→另准新context→另freshready一次LS/同PID dynamic/binding驗證。需要newcert/revoke/security/paid/changeTeamBID或未知信任/私鑰/OS政策就停，不請Human調查profile補洞。


### LG44：原certificate嚴格解析及一次透明sign amendment（待LG45）

執行契約／exact evidence／private manifest依spec LG44 SP01–05；不把OU掃描缺口寫成LG43已證根因。先獨立規劃審查，再按既有Human routine授權做non-live bounded fix，實際query/sign另新freshready。

| 欄位 | 受限範圍 |
|---|---|
| In-Scope | 原DER前置pin；獨立subject/date/class解析與有限證據；真helper/config形狀fake；同prep root唯一amendment caller/config/proof準備及獨立審查 |
| Out-Of-Scope | 本輪code/tests/query/sign/context/launch；改certificate/Team/BID/class/date/trust安全標準、reset舊quota、new namespace／framework／target、DPK/cleanup/Git |
| ReadOnly | main.swift／五模板／production、原caller/config/controller snapshot、LG43 consumed/operation與全部歷史／ready；原App/build/source proofs |
| Written | 四artifacts；之後各owner原evidence、ordinary fake scratch；LG49僅spec SP03列明私有新leaf，不建context／ready、不改原leaf |
| Deleted | 無；保留原失敗、pending、App原件與資產 |
| Modify | validation/github-oauth-credential-persistence/{scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}，owner自身step/原evidence；不新增repo leaves |
| Goal | 消除fulltext/issuer污染Team解析並讓下一次準備失敗有實際有限證據；透明保留LG43及原build provenance |
| Non-Goal | 回溯宣稱LG43根因、私鑰／OS／signedhost已通過、App重新建置或DPK驗收；通用recovery |
| TestCase | spec SP04–05：先局部red→green、適用NoApp/selective解析回歸、AST/Ruff、三leaf freeze；main不變不重編 |

LG44作者→LG45獨立Plan-Reviewer→LG46 Implementer→LG47 Tester→LG48 Reviewer→LG49 Implementer私有準備→LG50 Reviewer。LG49給完整actual caller/config/controller/freezes、父收據及雙App核對、NoApp dry結果與具體單次命令；新controller SHA獨立受審，原App build九source不偷更新。LG50通過後才集中Human原key當次auth／實際觀察及新sign freshready；舊兩ready不可用。新sign成功/postverify/proof完成前不context；後續context與launch仍當段另授、不自動前進。各owner只寫自己evidence/row，現在不query/probe/sign/launch或建私有inputs。


LG49私有manifest routine澄清（待原獨立Reviewer回查）：SP03追加context/launch各一consumed及一pending/final operation，共六固定amendment-1 root leaves，exact names/schema/guard依spec「producer私有manifest銜接澄清」。沿原LG41 pipeline保留可稽核context/launch producers與各段ready；只綁已發布child sign success/newproof及新ready，不引用LG43unknown。Sign前核unsigned副本；context/launch核新signed tree，原unsigned原件始終保持。Parent/history／source/Appbuild proof完全不改，不將ready證據塞尚未建立的future-context。先獨立澄清回查再LG49接線／LG50審actualcaller；現在不建六leaf/context／ready、不query/sign/LS。


### LG52：LG51 report-timeout bounded修補（待LG53）

Scope/schema/原bytes與OS證據限制、exactmanifest／RTT01–06以spec LG52為準；不重述原歷史。Human已授內部planning→implementation/nonlive→review與unsigned準備，真正私鑰/sign/新context/LS仍最後集中窗口，不現在問ready。

| 欄位 | 受限契約 |
|---|---|
| In-Scope | A原bytes真Swift replay；B真FS/NSNumber/SDK-selfPID；C雙channel最小可信bootstrap/entry/failure/stream；D report缺失仍native poll；一次透明子amendment／unsigned產物與精確caller準備 |
| Out-Of-Scope | 本planning段code/tests/build；任何真sign/LS/App/DPK、新Keychainquery/資產發證安裝/security/trustACL、-n/kill/autoretry/cleanup、OAuth/login/E007/Git |
| ReadOnly | 原LG51/43 roots/App/source/build/proofs/receipts/ready/quotas與全部歷史；production/ports/provider/Package.swift、五模板及其他topic |
| Written | 四artifacts；各owner原evidence；ordinary nonlive fixtures／unsignedCLI；LG57僅spec明列新私有準備/build leaves，真context/operation/consumed仍未建 |
| Deleted | 無原repo／App／item／root／asset刪除；ordinary fixture自然收尾，不kill |
| Modify | validation/github-oauth-credential-persistence/{Sources/main.swift,scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}＋owner step/原evidence；不新增repo葉/target/framework |
| Goal | 能用同核心判讀原資料與真native橋接，下一次有限區分入口／wire／guard／stream／native結果，保持host attribution全部條件 |
| Non-Goal | 將OS lifecycle當Swift入口、將TCCpreflight當拒絕或提示、回填LG51成功、降低OS安全標準／DPK通過／零競態保證 |
| TestCase | spec A–F/RTT01–06；新main finalbytes對新unsignedCLI/新App buildfreeze，選擇性必要回歸；原成功歷史不機械重測 |

LG52作者→LG53獨立Plan-Reviewer→LG54 Implementer受限TDD／rawbytes Swift replay與native-self/streams／四葉freeze→LG55 Tester→LG56 Reviewer→LG57 Implementer真unsignedApp與完整privatecaller/config/proofs、NoApp phasefixtures／exact未執行命令→LG58 Reviewer。每owner原evidence追加自己結果，不代approval。需要guard修正先證實再最小修，不降低安全要求；新schema偏離先受限回修。LG58之後才新Human sign當次auth與觀察，子context／單次LS各段新ready，原全部ready不得carry。這輪只作者planning/readback，無code/test/build/sign/launch。


## LG60：有效 profile 取得受限執行契約（待 LG61）

具體操作、input provenance、exact 私有 manifest、once／結果 schema 與成功條件只定義於 technical-spec LG60，執行者逐項遵守。本輪不修 DPK 工具、不重演既有測試／純啟動，沒有 App sign/launch/DPK gate 放行。

| 欄位 | 本次限定 |
|---|---|
| In-Scope | 原 Team/AppID/cert 的單次 Xcode Automatic provisioning；必要 profile download/create/install、標準流程必要 cert 新增；公開 bytes 真驗證及有限結果 |
| Out-Of-Scope | App certificate-sign/Run/LS/DPK/context/cleanup；revoke、trustACL、安全設定、付費／換身分、Manage Certificates/Fix Issue、重試／新 namespace |
| ReadOnly | 原四葉工具／六個 target 模板、LG59 與更早 App/project/manifest/receipts/readies/spent、production/provider/package lock、E007／其他工作線 |
| Written | spec LG60 的固定 profile-acquisition-1 私有 leaves／六檔 project 副本；Xcode 標準 profile／必要新增 cert 資產；各 owner 原 evidence 追加自己結果 |
| Deleted | 無；不刪／撤銷原 profile/cert/App/root/item，不做清理 |
| Modify | 只四 planning artifacts／owner row/evidence；原 repo toolcode/templates 不改。private copied PBX 的原 App target Automatic／Team／profile/local-package 接線依 spec |
| Goal | 取得並驗明包含原 cert、同 Team/AppID、exact group/device/date/CMS 全成立的有效 profile |
| Non-Goal | Xcode green等於成功、以新 cert替代原 pin、DPK／跨程序／重建驗收或產品登入 |
| TestCase | PA01 input cert/BID/Team pin及before inventory；PA02 once/partial拒絕且不覆舊；PA03 exact原target provisioning及可觀察資產差異；PA04 raw profile/CMS/原DER/Team/AppID/group/device/date逐項驗；PA05 fail/需要signedbuild/auth/意外變更有限結算、實際Human觀察與舊歷史不變；不跑未受影響suite |

LG60 Plan-Creator → LG61 獨立 Plan-Reviewer → LG62 Implementer 執行已授單次 provisioning／取得與有限 receipt → LG63 Tester 獨立純讀 bytes/關聯/實際觀察核對 → LG64 Reviewer。各角色只填自己 row／原 evidence；本作者不產 approval。只有不可代辦 login/2FA/unlock/private-key auth 才由 root 集中 Human 操作；不是重新問一般可否取得。若 signed build不可避免、匹配失敗／其他硬界線則停止，不自動轉下一條路。取得成功後仍停，不簽／啟 App 或進 DPK。


## LG65：一小時受限 DPK 接線
唯一delta見spec LG65；deadline10:06:29Z含Human等待，不延長。

| 欄位 | 本次限定 |
|---|---|
| In-Scope | DPK專用purpose/profile verifier與同次report/ACK/final內正式operation；affected nonlive/unsigned準備 |
| Out-Of-Scope | 未授真人sign/App/DPK；新cert/revoke/trustACL/TeamAppID/pay/Auto/profile更新/Git/cleanup/retry/-n/kill/E007 |
| ReadOnly | 原五模板、production/provider/ports/package/locks、LG59/LG64及全部old roots/history/readies/spent |
| Written | 四artifacts/owner原evidence；ordinary fake/unsigned；spec限定producer，真round/context仍需後續fresh授權 |
| Deleted | 無 |
| Modify | validation/github-oauth-credential-persistence/{Sources/main.swift,scripts/credential_storage_live.py,Tests/test_live_protocol.py,README.md}及自己row/evidence |
| Goal | A→writerexit→freshA→wholeB→freshB→同身分真重建→freshB，全六欄及完整歸屬鏈 |
| Non-Goal | 把純診斷或exit0當DPK成功、回填unknown、推空/ownership、清理或安全保證擴張 |
| TestCase | spec DK01–06、局部red-green/affected checks/獨立驗證；未受影響歷史不機械重跑 |

LG65作者→LG66規劃審查→LG67實作→LG68Tester→LG69Reviewer→LG70實unsignedApp/actualcaller/config/proofs/NoApp→LG71獨立準備審查→LG72 Tester/Human。準備審過才集中問待定提示判準及各段fresh授權；不先live、不把首次授權延用。各owner只填自己結果。時間不足不start，到期只settle/save/no kill/no cleanup，不延deadline。


## LG73：新真人窗口受限候選
完整schema/manifest/時間/接合只定義spec LG73，既有LG65其餘契約維持。RF-LG74-01：descriptor固定boot來源政策，Human/authority承接kernel boot-session canonical hash，各participant current hash不同或不可得先拒；NW03跨boot但UTC/mono表面合法仍零native/DPK。無新leaf/權限。

| 欄位 | 本delta |
|---|---|
| In-Scope | owned一次authority/freshphase、既有contextSHA/B接合、新window真wire/affected NoApp及unsigned準備 |
| Out-Of-Scope | 此刻開窗/sign/App/DPK；延長舊deadline、重用ready/quota、新認證框架、new/revoke cert/trustACL/TeamAppID/pay/Auto/profile更新/cleanup/Git |
| ReadOnly | 原profile/身份/evidence、原窗口/candidate/App/buildsource9/所有成功unknown及spent、production/ports/provider/package與五模板 |
| Written | 四artifacts/owner原evidence；新parent-linked operative private family/descriptor；真正Human前future authority/ready/consumed absent |
| Modify | 既有validation main/runner/tests/README及privatecaller/config；無新增repo leaf/target/BC |
| Deleted | 無 |
| Goal | 所有新deadline只由最後真授權/ready導出，完整綁到同次operation/proof/context/B，過期/越權/混鏈先拒 |
| Non-Goal | UUID/hash當Human authentication、預填signedbinary、重開舊clock或承諾DPK已通過 |
| TestCase | spec NW01–06；新main必新unsigned build，source/runtime provenance分離，不重做未影響成果 |

LG73作者→LG74獨立PlanReviewer→LG75 Implementer→LG76 Tester→LG77 Reviewer→LG78實際新unsignedApp/caller/descriptor/NoApp/freezes準備→LG79獨立actual準備審查→LG80 Human集中採用≤60min/待定提示判準＋freshready後才factory開窗，後續各段freshready。User只提供真授權/必要keyauth/實際觀察，不排障或找欄位。各角色只寫自己結果；本planning不寫source/執行命令，不自批。


## LG82：交付收尾 amendment（本輪最新授權優先）

同slug、不改既定實作；精確語意依spec CD01–05。LG81-Cap-R completed／approved，並非全topic Human接受；LC06與Human visual/S08及PR整合仍尚缺。此節只授文件／證據／提案及後續exact-stage，不承接舊自動commit/push/PR授權。

### 精確 manifest

D（可修改的六個文字leaf，僅能力／驗證／導覽）：
- README.md
- docs/design-principles.md
- docs/architecture/README.md
- docs/architecture/github-oauth-dual-client.md
- docs/architecture/github-oauth-credential-persistence.md
- validation/github-oauth-credential-persistence/README.md

P：本topic既有requirements.md、technical-spec.md、同slug .plan.md／.step.md四份；各owner只寫自己交接，頭摘要可依已明示角色結果對齊現在式。

E（固定前綴plan/github-oauth-credential-persistence/evidence/）：planning-review.md（PlanReviewer）、implementation.md（Implementer）、tests.md／live-preparation-tests.md／live-validation.md（Tester）、review.md／live-preparation-review.md（Reviewer）、publication.md（Implementer的PR內容草案／交付與staged提案）。皆既有leaf，只按owner必要追加，非每檔必改，不新建summary。

V（固定前綴validation/github-oauth-credential-persistence/，exact-stage交付九leaf；本輪只有README可寫）：README.md；CredentialStorageProbe.xcodeproj/project.pbxproj；CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme；CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme；Sources/main.swift；Resources/Info.plist；Resources/CredentialStorageProbe.entitlements；scripts/credential_storage_live.py；Tests/test_live_protocol.py。

Exact-stage allowlist = D ∪ P ∪ E ∪ V（重複README去重；只stage其中實際本topic changed/untracked項，不為湊集合造變更）。兩個個人.swiftpm xcschememanagement leaf不屬集合，維持原bytes；任何.swiftpm／xcuserdata／其他未列path不得stage。圖與其他現有未變程式不加進本輪stage。先前已committed的正式adapter不重造diff。

| 欄位 | 本輪受限契約 |
|---|---|
| In-Scope | D最小文字回寫、現在式帳本、E必要owner結果／publication內PR草案、exact-stage與staged語意提案 |
| Out-Of-Scope | 新code／API／相容層、dev整合、tests/build/sign/App/DPK/provision/cleanup、Git commit/push/merge/rebase/remote PR更新、新圖／工具／framework |
| ReadOnly | 所有production/Package/其餘tests；V除README的8leaf；全圖與其QA/PNG/sidecars；原receipt/manifest/authority/source/build hash/private assets；dev/E007與兩個個人.swiftpm metadata |
| Written | 僅既有D/P/E必要文字；無新增repo leaf，publication承載摘要與PR草案；stage僅上述exact set的實際變更 |
| Deleted | 無；不清理repo／私有root／Keychain item／Apple資產／個人檔案 |
| Modify | PlanCreator只本次P四檔；Implementer依獨立PlanReview後D及自身E/publication；Tester/Reviewer各owner E/step；後續stage只index，不改source |
| Goal | 長期能力／限制／最新DPK證據可追溯，交付diff可審且有具體staged message，停Human |
| Non-Goal | 全topic/S08/圖視覺/cleanup/PR整合自動通過、用歷史freeze誤稱新docs已測、把Draft PR或base conflicts當DPK成敗 |
| TestCase | CO01–05如下；未影響工具source不重跑suite/live，既有approved證據沿用 |

### CO01–05與角色步驟

CO01：D六葉現在式準確對照LG81-Cap-R／原S05/S06與界線，正文不再全域宣稱live未驗；歷史段保留原時間語境。相對連結存在、無whitespace錯、有限secret／本機abs掃描；不輸出raw私有資料。
CO02：四artifacts及step頭狀態一致，最新LG81-Cap-R completed／approved明示；AC09 Human visual、LC06未cleanup、S08 Human、PR整合未完成均清楚且不代答。
CO03：V八code/template葉與舊圖bytes不變；V README新doc hash與原freeze區分。沿原獨立驗證，不跑新tests/build/sign/App/DPK；不把entry-only/NoApp或預建Rebuilt當live證據。
CO04：publication的PR title/body/驗證清單及限制為草案，列五個衝突與公開契約差異；不改PR、不整合dev，不藉此改API。暫擬一個同topic提交語意，最終message只依真正staged diff再提出。
CO05：成果Reviewer approved後，Implementer唯讀核index/changed範圍及兩個個人metadata前後bytes相同，用exact leaf allowlist stage，核staged names與diff --check，再依git-commit-convention提出Human確認；任何多餘path/secret/不明差異先停，不reset他人index。不commit/push/merge/PR write。

LG82 PlanCreator（本候選）→LG83獨立PlanReviewer→LG84 Implementer文字回寫/PR草案→LG85 Tester CO01–04有限文件核對→LG86獨立Reviewer→LG87 Implementer exact-stage及實際staged diff／git-commit-convention提案→LG88 Human：確認message／是否後續提交及圖visual/S08或剩餘整合/cleanup安排。LG88前不commit，Human未答保持pending；本輪不執行cleanup或整合。各role只寫本人證據，不互批。若發現真code問題，停本收尾scope交明確bounded評估，不直接改產品。


## LG89：PR #60 五個衝突的受限修復

最新 Human 授權與採用決策見 requirements LG89，唯一設計／驗收以 technical-spec LG89／CF01–05 為準。此節只解除既有 closeout 對本次 dev 整合的排除；不授新 commit 或遠端更新，不改其他歷史限制。

### 精確手動修改 manifest

- 衝突五葉：`README.md`；`Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift`；`docs/architecture/README.md`；`docs/architecture/github-oauth-dual-client.md`；`docs/design-principles.md`。
- 授權入口：`Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift`（dev 既有檔，只 private blank-validation 接線）。
- 相容測試：`Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift`（dev 既有檔；直接 constructor 採用結果、兩 factories blank／合法／redaction）；必要時 `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`（typed-throws／public fields 跨 target compile 斷言）。既有 store／provider tests 不改，只跑受影響範圍。
- P：本 topic 原 requirements／technical-spec／plan／step 四葉；E：既有 `plan/github-oauth-credential-persistence/evidence/{planning-review,implementation,tests,review,publication}.md`，各 owner 只追加實際結果，非每葉必改，不建立 summary／新框架。

`git merge --no-commit --no-ff 758aca9bb518f2a21f20f47609335fac49043370` 只可由後續 Implementer 在原 feature worktree 執行；前置確認 HEAD 仍為已核 feature tip、tracked/index 無其他工作，保留個人 metadata checkpoint。dev 正常 merge 帶入的既有無衝突檔案不是本輪手動新增範圍；須在 evidence 將自動合併來源與上述 resolution delta 分開，不為測試修改 E007／驗證 App。若 head/base 已變，先唯讀重新核具體差異，不拿過時 pin 執行。

| 欄位 | 本次受限契約 |
|---|---|
| In-Scope | 原 feature 的 dev 非提交 merge、五 conflicts、已採 configuration／兩 factory validation 及必要 tests／docs／證據 |
| Out-Of-Scope | 新 topic／branch／worktree、dev worktree 實作、E007／完整登入新功能、公開簽名額外破壞、新圖、live／DPK／sign／App 啟動／資產／清理、未核准 commit／push／PR 更新／PR merge |
| ReadOnly | adapter／provider／ports／validation host 及圖、所有原 live 收據／成功／unknown／失敗、Apple assets、兩個個人 metadata；其他 dev 工作只作正常 merge 來源 |
| Written | 僅上述手動 leaves、四 P／必要 owner E；普通私有非真人測試 logs 及 Git merge/index metadata；無新 repo leaf |
| Deleted | 無；不清理測試資料、Apple assets、私有 root 或個人檔案 |
| Modify | Plan-Creator 只 P；獨立規劃審查後 Implementer 解衝突／private guard／tests；Tester／Reviewer 僅自身 evidence／row |
| Goal | configuration 取捨符合 Human 選擇，授權入口仍拒 blank，保留兩邊有效內容且有可審 staged merge／message |
| Non-Goal | 零 constructor 行為差異、驗證 App UI 前置狀態不變、新 merge binary 已 live、整 Topic／cleanup／Human 接受自動完成 |
| TestCase | CF01–05；先受影響 TDD，再精確 integration suites／consumer／isolation、文件檢查與獨立審查；不重既有 live／未影響 suite |

LG89 Plan-Creator 最小 amendment → LG90 獨立 Plan-Reviewer → LG91 Implementer 非提交 merge／TDD／解衝突 → LG92 Tester 受影響非真人整合核驗 → LG93 Reviewer → LG94 Human：真正 staged diff 的新 merge commit 範圍／message。LG94 前不得 commit，亦不 push／更新 PR；確認只限原 message／25 檔的舊 LG88 授權不延用至本次 merge。各角色保留原歷史，只填自身結果。


### RF-LG94-LINT：已核 merge 範圍內的最小 hook 回修

LG89 manifest 唯一新增手動 leaf：`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；它原已由 dev 正常整合帶入 index。只採 spec 所列一行收斂，不能修改其他來源／測試行為。四 artifacts／owner evidence 仍依原 manifest 只追加真實結果；不改其他歷史，無新 leaf／step／Mission。

| 欄位 | 本 delta |
|---|---|
| In-Scope | 上述同檔 whitespace-only 收斂、窄驗證／獨立 review、刷新 staged commit 檢查 |
| Out-Of-Scope | 規則停用／threshold／hooks bypass、allowlist／API／production 行為修改、其他整合或新功能、App／DPK／簽章／資產／清理 |
| ReadOnly | 原八個 resolution source／docs、其餘 auto entries、原失敗 receipt／各歷史、兩個個人 metadata |
| Written | 四 planning／必要 owner evidence；一個既有 test leaf；私有新 amendment receipt，不覆原 commit failure |
| Deleted | 無 |
| Modify | 先 planning 候選；獨立審查後 Implementer 只一行 whitespace 收斂並 exact-stage 必要變更 |
| Goal | 同一 Human 核准的 merge fix 可通正常 hooks，且非 whitespace byte invariant 成立 |
| Non-Goal | 新語意／新公開契約、重跑完整驗收、把前次 hook failure 覆寫為成功 |
| TestCase | 真 repo delta／invariant、單檔 strict format／SwiftLint、GitHubIntegration StaticIsolationTests、其他來源／metadata hashes、refreshed staged check |

原 Human 核准 message 未變。完成 bounded planning review→Implementer／窄驗證→獨立成果 review→刷新 commit-convention 後可沿原授權執行正常 commit、push、PR 更新；不因單純格式要求重問 Human。若語意／message／授權範圍改變則不得延用。
