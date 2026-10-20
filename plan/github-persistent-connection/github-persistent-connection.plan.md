# GitHub 持續連線：受限執行計畫

- Topic：`github-persistent-connection`；原計畫及第二輪方法／manifest 已審查；2026-10-20 Human 已接受唯一 renewal 未驗證例外、S04e 完成；S05 pending，此 gate delta 待獨立回查。
- Branch：`feat/github-persistent-connection`；base／PR target：`dev`。
- 配對：[需求](../../analysis/github-persistent-connection/requirements.md)、[技術契約](../../analysis/github-persistent-connection/technical-spec.md)、[帳本](github-persistent-connection.step.md)。

## 1. 九欄契約

`swift-implementation` 是本 topic 的階段名稱，不是聲稱存在同名 skill。每個 bounded Implementer handoff 必須帶下列同九欄、精確 manifest 子集與 V-ID；總表不是任改 allowlist，不能讓實作者另選路徑／接口／範圍。超出 manifest 先回 Plan-Creator＋獨立 Plan-Reviewer，不新增 workflow gate。

| 欄位 | 本 topic 契約 |
|---|---|
| In-Scope | signed host、configuration／authorization／DPK、restore／refresh／同 App repair／reauth、GET /user、E007、脫敏證據及文件圖 |
| Out-Of-Scope | 多帳號／App 切換、PR BC、logout／revoke、PAT／device／Enterprise／broker、一般 retry、跨程序協調、遷移、公開分發、generic auth 改寫 |
| ReadOnly | 下列 R01–R05；不與 Modify 重疊；目錄可讀不等於目錄可寫 |
| Written | 下列 W01–W07 新檔；精確 generated names 另列 |
| Deleted | repository 檔預設無；E007 UUID items／proven-owned 私有暫存精確清理另列，非產品 logout |
| Modify | 下列 M01–M04 既有檔，只有指定 additive observation／測試與已證實文件內容 |
| Goal | 真入口登入、跨重啟及到期後可使用 GitHub，失敗有同 App 修復／reauth |
| Non-Goal | 把實驗當產品通過、降 UX 判準、擴張帳號管理、證明所有 profile／OS／cert 行為 |
| TestCase | V01–V09；各交接列本 slice cases、輸入類型、命令與驗證證據要求 |

### 已鎖定 host 與驗證前提（RF01）

產品與 E007 均為 macOS 15+／Swift 6 的真正 App，以 Apple Development 簽章並含有效 embedded development profile；`ENABLE_DEBUG_DYLIB=NO`、首版 non-Sandbox。Team／profile 等私人設定及原始安裝路徑不入版控，僅以私有 runtime configuration 提供；repository evidence 只記必要 hashes／布林。

產品採 Human 首次選定並凍結的同一 private Rivet.app 安裝位置，fresh-process／重建均在該位置替換／啟動；私有 run manifest 保存原始位置，repo 只留位置 hash／same-location 核對。E007 同一輪固定為私有 runroot 的 `current/ProfileRenewalProbe.app`，原 profile 保存與新 profile 只讀使用同一路徑，不另選位置或重設 t0。V01 核對 E007 host／profile／同路徑，V06 核對產品 host／固定位置／提示，V08 核對 deployment target／language mode／簽章／embedded profile／debug-dylib／non-Sandbox；V08 build green 不代替 V01／V06 真人證據。

## 2. 精確 manifest

以下 alias 是固定路徑前綴，展開後才是檔案授權；不是可自由擴張的資料夾：

- `G` = `Sources/BoundedContexts/GitHubIntegration`
- `GT` = `Tests/GitHubIntegrationTests`
- `C` = `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests`
- `A` = `apps/Rivet`
- `D` = `docs/architecture/diagrams/github-persistent-connection`
- `E` = `experiments/E007`

### 新檔 Written

| ID | 精確檔案（每個分號項各為一檔） | 用途 |
|---|---|---|
| W01 | `analysis/github-persistent-connection/requirements.md`; `analysis/github-persistent-connection/technical-spec.md`; `plan/github-persistent-connection/github-persistent-connection.plan.md`; `plan/github-persistent-connection/github-persistent-connection.step.md` | 四份正式 artifacts；建立後只可在對應角色授權下維護 |
| W02 | `G/Contracts/GitHubOAuthAppConfiguration.swift`; `G/OAuth/GitHubOAuth.swift`; `G/OAuth/GitHubOAuthAuthorizationSession.swift`; `G/Stores/GitHubOAuthDataProtectionStores.swift` | configuration／factory／single-session／兩 items；必要 public 型別放這些檔，不另增 module |
| W03 | `GT/GitHubOAuthFactoryTests.swift`; `GT/GitHubOAuthAuthorizationSessionTests.swift`; `GT/GitHubOAuthDataProtectionStoresTests.swift` | fake transport／Security seam 契約測試；不預設真服務 |
| W04 | `A/Rivet.xcodeproj/project.pbxproj`; `A/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme`; `A/Sources/RivetApp.swift`; `A/Sources/GitHubConnectionCoordinator.swift`; `A/Sources/GitHubLoopbackCallbackRelay.swift`; `A/Sources/GitHubAccountProbe.swift`; `A/Resources/Info.plist`; `A/Resources/Rivet.entitlements`; `A/Tests/GitHubConnectionCoordinatorTests.swift`; `A/Tests/GitHubLoopbackCallbackRelayTests.swift` | 最小 Application＋hosted unit-test target，root local package products，沒有新 runtime module／Package.swift 變更 |
| W05 | `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift`; `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift` | 最小 display-ready 連線 leaf；不帶 OAuth／BC dependency |
| W06 | `E/README.md`; `E/ProfileRenewalProbe.xcodeproj/project.pbxproj`; `E/ProfileRenewalProbe.xcodeproj/xcshareddata/xcschemes/ProfileRenewalProbe.xcscheme`; `E/Sources/ProfileRenewalProbe.swift`; `E/Resources/Info.plist`; `E/Resources/ProfileRenewalProbe.entitlements`; `E/scripts/run_profile_renewal.py`; `E/Tests/test_protocol.py` | 獨立 fake-only renewal host／guarded runner／pure controls；實際前先重查編號 |
| W07 | `D/BUILD.md`; `D/scene.js`; `D/responsibility-canvas.html`; `D/authorization-sequence.json`; `D/authorization-sequence.html`; `D/restore-refresh-reauth-sequence.json`; `D/restore-refresh-reauth-sequence.html`; `D/connection-lifecycle.json`; `D/connection-lifecycle.html`; `D/visual-review.md`; `D/tool-evidence.md` | architecture-canvas 責任界線、Archify 兩 sequence＋lifecycle、驗證與工具紀錄 |

E007 run directory 僅允許 `E/evidence/run-<UTC compact>-<UUID>/`，UTC／UUID 由開始前 frozen run manifest 決定；leaf allowlist 為 `window.json`、`preflight.machine.json`、`phase-1.machine.json`、`phase-1.human.json`、`phase-2.machine.json`、`phase-2.human.json`、`cleanup.machine.json`、`cleanup.human.json`、`final.index.json`、`tester-validation.json`、`reviewer-verdict.json`。exclusive-create，不覆寫。準備期原收據 `E/evidence/preparation-tests.json`、`E/evidence/preparation-review.json` 已建立且 immutable，不得覆寫。本次僅額外允許 `experiments/E007/evidence/preparation-tests-r1.json`、`experiments/E007/evidence/preparation-review-r1.json`，供 RF-R01（Human 自由文字採 finite projection）及 RF-R02（guard／invalid machine 不得判成 renewal failure）回修後的獨立 Tester／Reviewer 重驗使用，仍 exclusive-create。這不是任意 revision leaf 授權；其他 leaf 仍須先明列 manifest。

第二輪 E007 run 額外只允許兩個 exact leaves：`E/evidence/run-<UTC compact>-<UUID>/cache-transition.machine.json`、`E/evidence/run-<UTC compact>-<UUID>/cache-recovery.machine.json`。Tester 依實際事前操作紀錄在 `export-clean` 後 exclusive-create，不修改 runner／原 `final.index.json`，不把手動核對冒充自動 sensor。兩份只含有限狀態、計數、hashes／布林與來源為 manual-record-review 的標示，不含 raw UUID／path／profile／自由 Human 私文；具體欄位見 E007 §9。`tester-validation.json` 額外引用兩份 SHA 與既有 final.index SHA，Reviewer 核對。第一輪 run 及所有舊收據 immutable；cache 私有 journal／backup 在恢復核對前不得被 export-clean 清掉。

每個 Archify basename（authorization-sequence、restore-refresh-reauth-sequence、connection-lifecycle）僅允許同名 `.delivery.json`、`.visual-check.json`、`.visual-check.html`、`.visual-check.1440x900.light.png`、`.visual-check.1440x900.dark.png`、`.visual-check.2048x1320.light.png`、`.visual-check.2048x1320.dark.png`，以及 deliver 工具自己的 exact same-directory frozen-spec snapshot；名稱／SHA 由實際 receipt 記錄。若 pinned tool 另有必要 output，停止該圖交付，先由 Plan-Creator 列明後交獨立 Plan-Reviewer；不能掃寫整目錄。

產品驗證收據固定 `plan/github-persistent-connection/evidence/contracts.md`、`storage-live.md`、`product-e2e.md`、`compatibility.md`、`final-review.md`。只保存脫敏結果；Human 原始秘密輸入、profiles、certificate raw identifiers、build outputs、PR Lens outputs 不入 repository。這些 evidence 是 step 引用素材，不另設正式 artifact。

### 既有檔 Modify

| ID | 精確檔案 | 限制 |
|---|---|---|
| M01 | `G/Providers/OAuthTokenProvider.swift` | 只新增有限 disposition 型別／唯讀 method，derive existing unavailableError；不改 runtime policy |
| M02 | `GT/OAuthTokenProviderTests.swift`; `C/PublicAPITests.swift`; `GT/StaticIsolationTests.swift` | observation／public construction／source compatibility；StaticIsolation 僅同步 W02 四條 source paths 與下列精確 import 例外，不刪測試或放寬其他隔離斷言，不改舊期望配合新 runtime policy |
| M03 | `README.md`; `docs/design-principles.md`; `docs/architecture/README.md`; `docs/architecture/github-oauth-dual-client.md` | 只回寫實際已證實的長期責任、能力、限制與圖連結；未驗證不寫成既定成功 |
| M04 | W01 四份 planning artifacts | 建立後按對應角色維護 scope／step／evidence／verdict；Dispatcher 不代勾 gate |

### S05 靜態隔離 allowlist 的精確維護（待獨立 Plan-Reviewer）

`Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 原為 R04 唯讀，現列 M02 的唯一維護範圍：

- `expectedPaths` 只新增已核准 W02 的四條 target-relative 路徑：`Contracts/GitHubOAuthAppConfiguration.swift`、`OAuth/GitHubOAuth.swift`、`OAuth/GitHubOAuthAuthorizationSession.swift`、`Stores/GitHubOAuthDataProtectionStores.swift`。
- `httpClientFiles` 只新增 `OAuth/GitHubOAuth.swift`、`OAuth/GitHubOAuthAuthorizationSession.swift`，允許這兩檔實際所需 `RivetHTTPClient` import。
- Security 只新增精確例外 `OAuth/GitHubOAuth.swift`、`Stores/GitHubOAuthDataProtectionStores.swift`；factory 既有實際 imports 為 Foundation／RivetHTTPClient／Security，store 為 Foundation／Security。保留 legacy `Stores/KeychainTokenStore.swift` 的既有精確斷言及其他所有檔案禁止 Security 的規則，不允許 session import Security。
- 不改 import parser、其他 forbidden modules／既有 allowlists、target source 集合的相等斷言或其他 isolation checks；不刪測試、不改舊 expectations 迎合 runtime policy、不新增 source 路徑。

此為既有 S05／V08 的 manifest amendment，不是新 phase／gate 或產品契約變更。原 Implementer 先示該靜態測試 red，再以此精確同步得到 green；獨立 Tester 回歸全 suite。此修訂獨立回查前，不修改該 test。

### 唯讀 ReadOnly

- R01：E001–E006 全部 source／README／immutable receipts，既有 DPK feasibility／scope topic artifacts。
- R02：`G/Composition/GitHubClientScope.swift`、`G/Composition/GitHubClientPreparationError.swift`、`G/Contracts/OAuthCredentialStore.swift`、`G/Contracts/OAuthTokenFetcher.swift`、`G/Contracts/OAuthTokenRefreshError.swift`、`G/Contracts/GitHubOAuthCredentialBundle.swift`、`G/Contracts/TokenSnapshot.swift`、`G/OAuth/GitHubOAuthHTTPTokenFetcher.swift`、`G/OAuth/GitHubOAuthEndpoints.swift`。
- R03：既有 `G/REST/`、`G/GraphQL/`、`packages/RivetHTTPClient/`、PR Inbox／Reader、原 PRReaderHarness、既有 Presentation PRInbox source。
- R04：`Package.swift`、既有 test support／其他 tests、`docs/toolchain.md`、`docs/development-workflow.md`、既有其他 diagrams；M01／M02 例外不列唯讀；其中 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 僅限下列精確靜態 allowlist 維護，其他 test support／tests 保持唯讀。
- R05：現有 `.gitignore`、工具 skills／runtime／config；`.github/pr-lens.yml` 僅存在時讀，不建立。不得修改工具 config、AGENTS、hooks 或 version stamps。

## 3. Slice 與 TestCase

每個 Implementer slice 的 handoff 將九欄具體化為本節對應 manifest IDs 的必要檔案子集，必須逐檔列出展開路徑；分派者不可只寫目錄或 W-ID。各 slice 固定路徑、ownership、test IDs 已在本契約鎖定，Implementer 不另選邊界。

| Slice | 角色與範圍 | Cases／完成條件 |
|---|---|---|
| Planning | Plan-Creator W01 → 獨立 Plan-Reviewer | 四份可讀、manifest／scope／gate 無未解 required fixes；不能自審 |
| Renewal preparation | Implementer W06 → Tester → Reviewer | V01 pure guards／準備；不得偷偷真 run／寫 product credential |
| Renewal live／adoption | Tester bounded run＋Human 逐段觀察 → Reviewer → Human | V01 實驗原判準與 unknown 歷史保留；Human 現接受 renewal 未驗證的唯一前置例外，依 §8 受限採用，不重問採用 |
| Integration | Implementer W02／W03／M01／M02 → Tester → Reviewer | V02／V03／V05／V08；在 E007 採用 gate 後才開始正式 adapter |
| Product | Implementer W04／W05 → Tester → Reviewer | V04／V05／V06／V07／V08；host tests 必須 fake-only |
| Docs／drawings | 指定 Implementer W07／M03 → Tester → Reviewer | V09；source／長期文件／圖一致，圖 QA 不得略過 |
| Final verification／review | Tester → 獨立 Reviewer → Human | evidence truthfulness、剩餘 blockers、真入口／UX；未通過不能宣稱 topic 完成 |
| Publication | Implementer bounded staged review／commit／push／Draft PR | 使用者本輪明確授權；base dev、保留 Human review，不能跨未解 gate |

| ID | 驗證內容與方法 |
|---|---|
| V01 | E007 前提／不同 profile／六欄／Human 零提示／45 分鐘／清理三分類；pure guards 可在真人窗外，真人窗 setup 前固定 t0。第二輪 A 前先將 project-specific GUI DerivedData 指定 owned runroot/DerivedData（不改全域），A／B 各一次 Human GUI Build並以各次 built products 核對來源／embedded profile；不混 CLI 舊 App，輸出／來源不明即停且不另建或重建。僅一次精確 cache 移出／refetch／B Build；先驗備份再移出，原 A 清 item 後恢復 cache 再 export；無法安全定位／同 bytes 即停。人工順序不冒稱 runner guard；README 分列假設狀態與任務完成否 |
| V02 | state／S256／exact callback、single session、cancel／denied／duplicate／缺參數／無效 response；fake HTTP，禁止 mock green 冒充真 GitHub |
| V03 | 兩 items 完整寫入、configuration-first partial-save、版本／date／six-field strict codec、修復表全部分支、denied 不覆寫、同 ID／redaction |
| V04 | latch 暫停舊 refresh／save，取消 caller／返回畫面後要求 reauth 仍 operationInProgress；settled 前零設定／新 bundle write；之後新 bundle 不受 old rotation 覆寫 |
| V05 | disposition 只觀測；temporary prepare 明確 retry 同 provider；所有 reauth／修復退休，失敗不復活；new bundle save 後 new provider；初始 restore 例外不被濫用 |
| V06 | 真 DPK 兩 items 保存、same-binary fresh process、真正重建、rotation 後 fresh process；首次 ≤1、fresh 0、rebuild 0；Human 完整觀察與 hashes 分列 |
| V07 | signed 正式入口真 authorization、保存、完整退出／重啟、GET /user；真 refresh＋受控 clock 觸發 expiry，明標不是自然等八小時；帳號呈現不 stale |
| V08 | `swift test`、`scripts/check-github-integration-consumer.sh`、format／SwiftLint checks、Xcode Rivet scheme build/test；既有雙 client single-flight／401 regression；host test live-call counters=0 |
| V09 | 長期 docs、architecture-canvas、Archify validate／deliver／四桌面 containment／截圖／Human inspection，PR Lens 真 diff map 或 concrete fallback，Graphify source-verified navigation 或 fallback |

適用 source checks 使用 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`；不得以 formatter 掃寫非本 slice 檔案。一般 build／test outputs 使用 generated scratch，不新增 repository 刪除範圍。V06／V07 真系統操作需使用當次 signed product host，不能拿實驗 App 或 fake provider 替代。

## 4. 工具與圖交付

Architecture-canvas 的唯一作者輸入為 `docs/architecture/diagrams/github-persistent-connection/scene.js`；依技能 author scene → validate → build，不手寫 viewer。通過 bundled `validate.js` 後，以 `build.js --scene` 指向此 scene、`--out` 指向既定 `responsibility-canvas.html`；保留本 topic 已鎖定 HTML 名稱。Scene 與 HTML 同目錄，BUILD.md 記重建命令。Canvas 畫面檢視所需截圖只留 proven-owned scratch，不另增 repository PNG／其他 outputs，不發布 artifact.cafe。

Archify pin 2.16，授權／restore-refresh-reauth 為兩張 sequence、temporary／stopped／repair 為 lifecycle；責任界線仍 architecture-canvas，不以 PR Lens／Graphify 替代。作者繁中、預設無動畫、omit meta.locale，揭露 Viewer UI／HTML lang 英文 fallback。每圖 showcase 九 checks／零 errors／零 warnings；validate 後 freeze，deliver，再 visual-check 1440×900、1600×1000、1920×1080、2048×1320，檢視 light／dark 截圖與 Human 畫面驗收。auto visualReview=pending 不冒稱 pass；不 publish artifact.cafe。必要圖未 validate／deliver／QA 完成，文件交付仍 incomplete，不因產品測試通過略過。

PR Lens pin 0.11.0。Graph schema 要求真實且不同的 base／head commit SHA；只有真 bounded diff 時讀 `git diff --find-renames <base>...<head>` 並記實際 IDs，不捏造尚不存在的 topic commit，也不以相同 SHA 冒充範圍。外部 topic scratch 產生 graph、validate／render，讀實際 output manifest，保留必要 unchanged neighbors／fileRefs，非 trivial map 附短 walkthrough。只讀現有 `.github/pr-lens.yml`，目前不存在，故 no-config local path；不建立 repository .pr-lens，不修改 config／gitignore，不 install／upgrade／API calls／upload／PR writes。它不代 correctness review。

S09 若尚無真 topic commit，先在既定 `D/tool-evidence.md` 記明具體 source／working-tree diff fallback、實際覆蓋來源及「真 code commit 後補 PR Lens」，不得寫成 map 已完成。此為既定輔助工具的執行時機，不新增 phase／gate，也不延後 Archify 必要 validate／deliver／四桌面 visual-check／light-dark 截圖與 Human inspection。既有 gates 允許進入已授權 S12 時，先依 staged diff 完成語意／message 檢查並建立實際 source／topic commit；再以真 base／該 code commit head 產生 bounded code-change PR Lens local map，完成 validate／render 並核實 output manifest。隨後在後續 docs／evidence topic commit 將真 base／head、manifest hashes、source coverage 與 walkthrough 補記 `D/tool-evidence.md`，才 push／開 Draft PR。Map 明示只代表該 bounded code-commit diff，不聲稱涵蓋其後 docs／evidence commit。若工具不可用，沿既有具體錯誤與 source／diff fallback 契約如實記錄，不新增 approval phase。

Graphify pin 0.9.73，每次 invocation 都設 GRAPHIFY_NO_AUTO_REFRESH=1。若既存可用 graph 才核對 revision／source、用 real node terms、budget 1500 bounded query，重要關係回 source verify。目前未發現 usable graph，fallback targeted rg／source；不因 skill 使用而 build graph，不 install／hooks／config／.graphify_version／provider／外連／發布。

PR Lens／Graphify unavailable 時記具體錯誤並 fallback source／diff；不把輔助圖失敗當產品失敗，不新增 approval phase。Archify 是 required 文件 deliverable，工具受阻需如實留該交付未完成。

## 5. 授權與停止條件

只能在指定 feature worktree 寫檔，不在 dev worktree。User 已授權本 topic 實作及無重大問題時 topic commit → push → Draft PR → Human review；仍須 staged diff 檢查語意與 message，但不重複要求已提供的 commit/push/Draft PR 授權。root 確認 gh keyring auth 有效，不因 default sandbox 誤報逕自 auth login。

S02 Plan-Reviewer 未明示 approved 前不派實作。原 E007 unknown 停 Human 的前置已由 §8 的實際 Human 決策解除，僅限 renewal 更新讀回未驗證；其他 Human 觀察與產品驗收不得略過。S05 在本 gate amendment 獨立回查後開始，不並行偷跑未核准 slice。遇到 certificate rotation、安全設定、付費需求、path／scope／locked contract 衝突或 required fixes 未清，停止依賴工作。Human 批准執行不等於真 run 已完成或 gate 已通過。

## 6. E007 第二輪方法修訂：受限九欄（歷史執行契約）

本節只落地 Human 新授權的方法，不啟動計時或外部操作。獨立 Plan-Reviewer 審本修訂後，沿用 S04c Tester → S04d Reviewer → S04e Human；不重開 S03 準備週期、不新增 gate。新 run 須另取 Human fresh ready／免費 Personal Team／原 certificate 聲明；舊 availability、ready、觀察不得沿用。每輪新 t0 是獨立補驗證，不能延長已結束第一輪。

| 欄位 | 本次文件修訂與後續唯一補驗證邊界 |
|---|---|
| In-Scope | 本次只修四正式 artifacts＋E007 README；方法為新輪 A 首存、精確本機 cache 備份／暫移、一次 refetch／B Build、同身分前提下讀回、精確清理與 cache 恢復 |
| Out-Of-Scope | 本次 live／cache 操作、產品實作、helper／probe／runner／測試修改、新實驗編號、新 framework、新 gate、Git 操作、降低 UX 判準 |
| ReadOnly | E001–E006、E007 全部既有 immutable receipts 與七份 source／測試、產品與工具設定；第一輪結果不可覆寫 |
| Written | 本次無新檔；後續新 run 只限既有 allowlist 加上述兩個 cache receipts |
| Deleted | 本次無；後續僅本輪已核對精確 cache 暫移，原 A 精確 UUID item／proven-owned root 清理；無遠端 Apple 資產刪除 |
| Modify | `analysis/github-persistent-connection/requirements.md`、`analysis/github-persistent-connection/technical-spec.md`、`plan/github-persistent-connection/github-persistent-connection.plan.md`、`plan/github-persistent-connection/github-persistent-connection.step.md`、`experiments/E007/README.md` |
| Goal | 一輪有終點且可審查的方法；真成功且無重大問題經獨立驗證、符合本次 Human 條件授權後回到既有完整產品結果 |
| Non-Goal | 現在操作／計時、預填成功／採用、宣稱所有 renewal 均驗證、以手動流程冒充自動 guard |
| TestCase | V01 方法前提、最多四精確候選、backup／restore／no-overwrite、唯一嘗試、原窗口、同身分異 bytes、Human 全段觀察及 gate 維持；本次僅文件獨立審查，不重跑準備測試 |

第二輪若仍無不同 profile 或其他停止條件成立，即清理／恢復並結束追查；保留未知。只有 Human 可另決定接受未驗證限制並修 gate，或改選儲存方案。本輪「通過就回產品」是條件式前進授權：真正不同有效 profile＋同身分／六欄／UX／精確恢復清理全部符合原判準，且 Tester／Reviewer 明示真成功、無重大問題時，S04e 依此 Human 決策記條件成立後前進 S05，不再重問採用許可；現在不預填成功或觀察。詳細 cache 操作／恢復／有限收據契約以 [E007 §9](../../experiments/E007/README.md#9-第二輪受限補驗證方法已獨立計畫審查) 為本節具體程序。

## 7. 唯一額外輪實際停止點（不變更執行契約）

第二輪已執行並收尾，方法 §6 與 E007 §9 保留為事前契約，不代表仍待開始。A GUI 一次 Build／完整假 bundle 保存讀回成功、Human 全段 0 提示；精確 cache 備份恢復預檢因副本多系統 provenance xattr 而未通過，在移出前按停止條件結束。沒有 cache 移出、refetch、B GUI Build 或 renewal read；原 cache 未變，requiredRestore=0，無恢復操作或待補恢復確認。假 item／私有 root 在原窗口內清理。備份非測量段全段提示數未確證，保留 null，不能補成零或 phase 2 觀察。

Tester／Reviewer 明示 approved、requiredFixes=[]，僅接受有限證據與安全收尾；experiment=無法判定、renewalRead=未執行、runnerTaskComplete=false、dpkAdoptionApproved=false。詳見 [E007 第二輪結果](../../experiments/E007/README.md#10-第二輪唯一補驗證實際結果)及帳本外部 verdict。唯一額外輪已用完，不自動第三輪，不再等開始訊號。當時 S04e 等 Human 決策，原條件授權未成立；後續 Human 已明確接受未知並授權繼續，現路由依 §8。此實驗結果仍不構成產品／refresh／renewal 成功。

## 8. Human 決策：受限採用 DPK 與唯一 gate delta

Human 原文：「接受 profile 更新後尚未驗證的限制，修訂 gate 並繼續產品實作」。所答問題明示：本次只解除「renewal 必須先驗證成功」的採用前置；其他驗收維持，仍保留連線失效處理與重新授權路徑。本節僅依該實際決策解除 renewal 必須先成功的阻擋，不更換儲存方案、不重開 ownership／簽章前提；S04e Human completed，S05 pending。此 amendment 交獨立 Plan-Reviewer 快速回查，approved 後直接交既有 S05 Implementer，不重問採用／fresh 45 分鐘、不新設 phase 或 gate、不再跑 E007。

E007 兩輪仍 unknown、phase 2 未執行；原 Tester／Reviewer 及 index／cache 收據 immutable，當時 human-check 有效，後續 Human 決策另記，絕不改為 pass。只接受同身分 profile 更新後讀回尚未驗證，首版本機自用仍要求有效 embedded profile、同 Mac／GUI user／App ID／private group／原 certificate 與固定位置。七日到期與過期不可用、已過期恢復／certificate rotation／公開發行未驗證限制不擴大。

V06 首次≤1／same-binary fresh 0／真正 rebuild 0／輪替 bundle 新程序；V07 正式真 OAuth／重啟／GET /user／真遠端 refresh 與受控 expiry clock 分列；V08 regressions／fake-only host safety；V09 工具圖及 Human 產品 UX 全部保留。明確錯誤／必要 reauth、denied 不覆寫、accepted rotation 本地保存失敗停 provider、clients 共用 lifecycle 及原 In-Scope／Out-Of-Scope 均不改。既有最終 Human review／Draft PR 邊界不變，未宣稱任何產品測試已通過。

本次精確 Modify 僅四正式 artifacts＋E007 README；ReadOnly 為 source／immutable live evidence，Written／Deleted 均無。Goal 只解除已明示的 renewal 採用前置，Non-Goal 為實作／第三輪／降低其他 AC；TestCase 為本唯一 exception、其餘 V06–V09 不變及真實／受控／unknown 歷史一致性。不增加 manifest、helper 或收據。
