# OAuth 冷啟動還原執行契約

## Goal / Non-Goal
完成正式既存 OAuth 還原與明確結果；不交付產品登入、遠端認證保證或其他 Mission。Branch feat/github-oauth-startup-restore-runtime，base dev。

## In-Scope / Out-Of-Scope
遵循 requirements.md；唯一 owner、單次 prepare、busy、明示重試、取消收尾與完整受控驗收。既有 public contracts／provider／scope／store／refresh／401 不變。

## ReadOnly / Written / Modify / Deleted
- ReadOnly：所有既有 Sources／Tests／manifests／scripts／experiments／設定／AGENTS／skills／歷史證據，除下列 Modify。
- Written：Composition/GitHubOAuthStartupRestorer.swift、Contracts/GitHubOAuthStartupRestoreOutcome.swift（均在 Sources/BoundedContexts/GitHubIntegration）；Tests/GitHubIntegrationTests/GitHubOAuthStartupRestoreTests.swift；Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/OAuthStartupRestoreContractTests.swift。
- Written：本 topic requirements／technical-spec／plan／step；docs/architecture/github-oauth-startup-restore-runtime.md 與 diagrams/github-oauth-startup-restore-runtime/ 的必要規格、HTML、收據、視覺與重現證據。
- Written：本機 ignored floorplan/（plan、architecture、descriptions、recent-work、cache、generated graph／index／配套與自身 gitignore），不 commit。不手改 generated HTML／graph，不覆寫 user notes／custom flows。
- Modify：README.md、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md、docs/feasibility-adoption.md；限能力、責任、導覽與證據限制。
- Modify 補正：Tests/GitHubIntegrationTests/StaticIsolationTests.swift 的 expectedPaths 僅登記兩個新增檔；完整測試已證明不更新會失敗，不更改斷言或放寬隔離規則。此為本輪 Human 授權下的必要測試登記，非架構／policy 變更。
- Deleted：無。
ReadOnly 指檔案修改邊界，runtime 仍可依原契約保存 credential rotation。超範圍先報 Scope Gap。

## TestCase
| ID | 場景 | AC |
| --- | --- | --- |
| TC01 | 有效設定／憑證 ready，無多餘 refresh | 1,8 |
| TC02 | 到期 refresh 與完整 save 成功才 ready | 1,3 |
| TC03 | configuration nil／credential nil 分別分類 | 2 |
| TC04 | 設定錯誤、identity mismatch、restore／refresh／persist、auth required、非法 Bearer | 2,3 |
| TC05 | pre-provider retry 可組裝，建立後不重建或切換設定 | 5,6 |
| TC06 | 暫時失敗同 provider retry，rejection／indeterminate／persist-stop 不復活 | 5 |
| TC07 | 開始前及 load／refresh／save 中取消，無晚到 ready，保存保留 | 3,4,6 |
| TC08 | 執行與收尾重疊 busy，settled 後接受新需求 | 6 |
| TC09 | 再次 prepare 原 provider；後續 terminal 不回舊 ready | 5,6 |
| TC10 | 不 clear／signOut／登入／切帳號 | 7 |
| TC11 | 非 testable consumer 與 internal client execution seam | 1,8 |
| TC12 | Floorplan planned／existing、範圍與來源可追溯 | 導覽證據 |

實作先 red 再 green；驗證 focused、root swift test、consumer、Swift format／strict SwiftLint。既有 provider／scope/client tests 為回歸證據；新 owner 不需修改或增加 public transport seam。

## Evidence / tools
Archify showcase 9 checks、0 errors／warnings、deliver hashes、四 desktop visual-check 與人工目視分開；責任 canvas 依 skill 驗證。圖作者繁中，Archify viewer 英文 fallback。
Floorplan blueprint 先於實作，實作後對應 source map；描述範圍限 topic＋直接依賴，不新增全repo義務。圖與 code health 非安全審查。
Graphify 固定 0.9.73、缺圖 rg fallback；PR Lens 固定 0.11.0、實際 base/head/工作樹 provenance、暫存 local validate/render，不上傳。

## Dispatch / Stop
Plan-Creator 落四 artifacts -> 獨立 Plan-Reviewer approved -> Implementer -> Tester -> 獨立 Reviewer -> Draft PR -> Human review。Required fix 不以時間截止視為通過。未知契約變更、清憑證、登入、跨程序、秘密操作或範圍擴張停 Human boundary。
Human 此次明確授權 topic commit、push、Draft PR；commit 前仍依 staged diff 檢查語意與提出 message。本次直接授權取代先前逐次確認偏好。保留9欄交接與精確完成／pending證據。

## L：2026-11-18 E018 live extension
Goal：正式入口真OAuth／DPK first/fresh。Non-Goal：新登入、清除、強制到期、舊App重跑、profile延續性。In-Scope：新E018 host/controller/offline tests、既有exact group/service的正式load／必要refresh/save／GET user、有限證據。Out-Of-Scope：原product功能擴張、新Apple資產、policy變更及其他實驗。ReadOnly：所有production Sources／manifests、舊實驗／App／控制與秘密。Written：experiments/E018/README.md、Sources/main.swift、Resources、E018OAuthStartupProbe.xcodeproj、scripts/startup_live.py、Tests/test_startup_live.py；新owner-only scratch的build／簽章／controls與safe receipts。Modify：四topic artifacts與必要驗證結果文件；不修改Apple cache、AGENTS、根gitignore、原public API。Deleted：無。TestCase：L01 fake/offline零Security、L02錯誤／重複launch fail-closed、L03 source/profile/binary/process guards、L04真first還原及完整readback、L05同binary新process讀回、L06Human全程觀察與receipt SHA綁定。
Live前先獨立planning review、工具offline驗證及獨立code review；controller launch不自動retry。此追加授權取代原對本輪live out-of-scope，其他locked contract保持。

L Written補充：plan/github-oauth-startup-restore-runtime/evidence/e018-*.json與e018-live.md保存固定safe projection及Human attestation；不含raw資料或私有路徑。

L Modify補充：experiments/README.md只追加E018索引；既有圖BUILD.md僅追加原圖版本與E018證據指向，不反改舊圖或收據。

## M：正式 hosted integration 測試設施修訂

本節追加目前受限執行契約，不取代原 P／I／T／R／L 歷史；Human 已明示 Implement the plan。維持同一 topic、branch 與 Draft PR #77，僅在既有 feature worktree 實作。M01–M06 順序及獨立角色依本 step ledger。新 Live 入口可實作，本輪僅 Offline／mock 驗證，不執行 Live build／簽章／DPK／OAuth，不建立新 live context。

### Goal / Non-Goal / In-Scope / Out-Of-Scope

| 欄位 | 目前修訂契約 |
| --- | --- |
| Goal | 必要驗證能力進入有原生斷言、明確命令及結果的正式 hosted integration 設施。 |
| Non-Goal | 不交付正式產品 App／UI E2E，不重新證明舊 live 結果。 |
| In-Scope | 兩 targets、Offline／Live configurations 與 shared schemes、測試組裝／觀測／斷言、跨程序 Offline smoke、手動 Live 介面、E018 退役及必要文件。 |
| Out-Of-Scope | 新登入、seed／clear、強制到期、修改 provider／refresh／401 policy、新 Apple 資產、產品接線、本輪新增 live 操作。 |
| ReadOnly | 正式 Sources／public APIs、root／packages／consumer manifests、既有 SwiftPM 受控／consumer 測試、其餘實驗、AGENTS／skills／設定、原 evidence bytes／SHA／Human 觀察與私有歷史資料。 |
| Written | Tests/GitHubIntegrationHostedTests/ 內正式 project、薄 host、hosted test bundle、test support、driver 受控測試；scripts/check-github-integration-hosted-tests.py。不另鎖 Host／Tests／TestSupport 子目錄。 |
| Modify | 原四份 topic artifacts、docs/toolchain.md、README.md、experiments/README.md、docs/architecture/README.md、docs/architecture/github-oauth-startup-restore-runtime.md、docs/architecture/github-oauth-dual-client.md、docs/feasibility-adoption.md 及本 topic 原圖 BUILD.md；限目前設施、測試命令、退役導覽與歷史來源／實證限制，不改舊圖及收據。 |
| Deleted | 移植必要能力後，刪除 active experiments/E018/ 全部九個 tracked files；不刪私有 App、Keychain 或歷史證據。 |
| TestCase | TC-H01–TC-H07。 |

保留 E018 成本較低，但缺 Test Action、與舊環境耦合，且 JSON passed:false 不保證非零 exit。正式 targets 增加少量 Xcode 設定，換取探索、框架斷言與 xcresult；採 Human 最新決策，不新增 E。官方能力／慣例／本案命名之區分依 requirements M 節，targets／CLI／private context／phase 與結果契約依 technical-spec M 節。

```diff
- experiments/E018/                         # active 工具退役
+ Tests/GitHubIntegrationHostedTests/
+   GitHubIntegrationHostedTests.xcodeproj
+   …                                      # 薄 host、test bundle、support、driver tests
+ scripts/check-github-integration-hosted-tests.py
= plan/github-oauth-startup-restore-runtime/evidence/
                                           # 原 bytes／SHA／Human 觀察保持
= 正式 GitHubIntegration runtime            # 沿用，不複製
```

### TestCase

| ID | 驗收與證據 |
| --- | --- |
| TC-H01 | 既有 root／consumer 回歸保持，正式 runtime／manifests 零差異。 |
| TC-H02 | Offline 只用 fake，Security／網路呼叫 0。 |
| TC-H03 | first／fresh 各一次，不同實際 PID／starttime、前程序退出，相同 host／test bundle／依賴／設定 provenance。 |
| TC-H04 | 斷言、throw、timeout、零案例、錯選或缺結果不綠燈；mock 驗證 exit 0／1／2／3。 |
| TC-H05 | prepare／API 計數分離、API 後最後保存 oracle、完整六欄比較移入 support，diagnostics 不含秘密。 |
| TC-H06 | active E018 路徑與依賴消失；原 evidence bytes／SHA／人工觀察不變；舊來源以 0debe0b Git 引用追溯。 |
| TC-H07 | mock 驗證手動 Live 資格、exclusive 額度、first→Human→fresh、原 receipt SHA 綁定與禁止 retry；不真正執行 Live。 |

Offline canonical 命令為 `python3 -B scripts/check-github-integration-hosted-tests.py --offline`，涵蓋 driver 受控測試及 hosted first／fresh smoke。既有 root swift test／consumer、Swift format／strict SwiftLint 及必要 diff 檢查作回歸；不能把目錄搬入 Tests 當作已接入 SwiftPM。新設施本輪只可記錄離線／mock 驗證結果，manual Live 尚未實證；不以舊 live 通過代替。

### 歷史 / Stop conditions

- 原 safe receipts、Human attestation、machine／source／binary／profile SHA 與舊版本結果原樣保存；歷史工具使用 0debe0b Git 引用，不把舊 pins 更新為新設施 pins。
- 舊 first／fresh 各 1/1 已用完；新 run-root 不構成新預算或授權，禁止匯入舊 context／markers 重用。
- 本輪不產生或執行新的 live context，不重新簽章／啟動舊 App，不登入／seed／clear／force expiry。
- 若必須修改正式 contract、產品組裝、新登入、清除或新增 live 才能完成，停止並回報 Scope Gap，不默認擴入。
- 原圖、Floorplan／Graphify／PR Lens 邊界維持；本輪文字 filetree／calltree 為計畫呈現，不新增未驗證 SVG／HTML 或發布義務。

## N：正式 hosted 有限 Live 驗收

Human 已明確授權 N 既存 credential／合格簽章的有限 first／fresh；這是 M 離線交付後的新階段，不重跑舊 E018，不改 L／M 歷史。僅在既有 feature worktree 執行，PR #77 保持 Draft，dev 不修改。N01–N07 與 Human 邊界依 step ledger；以下為N01起點的受限契約，當前執行結果依帳本及hosted-live.md分列。

### N Goal / Non-Goal / In-Scope / Out-Of-Scope / 檔案邊界

| 欄位 | N 受限契約 |
| --- | --- |
| Goal | 以正式 hosted 設施驗證既存連線 restore、API、完整 credential readback 及新程序 continuity。 |
| Non-Goal | 不交付產品 App／UI E2E，不證明所有環境、普遍權限或未發生的真 refresh。 |
| In-Scope | 離線與資格核對、獨立純 build-only Live 簽章 preflight、first／fresh 各最多一次、每段 Human 實答及 SHA 綁定、安全證據與獨立審查後交付。 |
| Out-Of-Scope | login／seed／clear／強制到期、新 Apple 資產、改正式 OAuth runtime／contracts、改 runner／tests、舊 E018 重跑、automatic phase retry。 |
| ReadOnly | 所有正式 Sources、既有 tests／scripts／project／root 與 packages manifests、Apple 資產、其餘實驗／歷史 private controls／keys／assets／logs、舊 evidence／Human／pins。 |
| Written | 新 owner-only N context／key／journal／純建置 preflight 與正式 run roots 的 build／machine／Human 等；本 topic evidence 的 hosted-live-first.json、hosted-live-first-human.json、hosted-live-fresh.json、hosted-live-fresh-human.json、hosted-live.md（只記實際完成段）。 |
| Modify | 原四 artifacts；結果經 N06 審查後，必要更新 README.md、docs/toolchain.md、docs/architecture/README.md、docs/architecture/github-oauth-startup-restore-runtime.md、docs/architecture/github-oauth-dual-client.md、docs/feasibility-adoption.md 的驗收結論與限制，由後續 Implementer 處理。 |
| Deleted | 無；不 cleanup fixture／Keychain／既有私有 App，不刪歷史證據。 |
| TestCase | TC-N01–TC-N07。 |

ReadOnly 為來源修改邊界，不禁止正式 runtime 依既有契約在必要時接受／保存 rotation；不得補償 rollback 已接受的保存。公開新增 evidence 僅允許安全 projection、SHA 與獨立 Human attestation，不含 raw token／secret／clientID／account／profilePath／使用者家目錄；不得回填原 machine placeholder。

### N 操作順序與 preflight 例外

N02 approved → N03 canonical Offline／資產／related-writer 核對 → 獨立 owner-only preflight root 的 `root_control(root, 'live', ctx)` 與 `build(root, 'live', ctx)`，只 build／sign／驗證／列舉 → 通知 Human 準備完成，等本輪可觀察回覆 → first 一次 → 原程序退出、詢問實際觀察／提示次數、SHA attest → 符合 first machine passed＋Human 全程且 0 提示後 fresh 一次 → 重新詢問與 attest → N06 獨立結果審查 → N07 topic commit／push／更新既有 Draft PR／Human review。

正式 first CLI 會先 bind context／建立 attempt，不能用作 preflight。Preflight 嚴禁 `bind_context`、`execute_phase`、`main --live`、authorize、DPK fixture 或 GitHub 操作；unexpected hello 不 authorize，停止回報。Preflight 不消耗 phase，不提供 first 結果；正式 first 另新 root 以正常 CLI 建置／固定 pins。新的 root 不重設任何已耗額度。
N context `authorizationRef` 使用 `human-2026-11-18-hosted-live-first-fresh`，沿用既有 schema／每段 1 次，不能自行擴張授權。不依 installed E014／舊私有資料推導環境；exact group／service 按 repo 已有公式與 current profile prefix 明示核對。

### N TestCase

| ID | 驗收與證據 |
| --- | --- |
| TC-N01 | Canonical Offline、source／existing contracts／舊 evidence 不變；現有工具與合格資產／single writer 前置核對。 |
| TC-N02 | 純 build-only preflight 完成 Live build／sign／產物／測試列舉；無 bind／attempt／authorize／fixture／API，必要 hosted 資格不明或工具失敗停止。 |
| TC-N03 | Human 本輪 ready 後 first 最多一次；正式 restore ready、API、完整 readback／configuration 保持及 actual process 退出。 |
| TC-N04 | 每段 Human 是否全程與 actual prompt count 均重新取得，原 receipt SHA 綁定；不預設 0／不回填 machine。 |
| TC-N05 | 只有 first 完整通過才 fresh 一次；不同 actual process、同產物、相同完整 credential／account continuity。 |
| TC-N06 | 有效／自然到期依真實情況分列 prepare／API refresh／save coverage；無真 refresh 不宣稱涵蓋，缺 fixture 停止、不 seed。 |
| TC-N07 | 新 safe projections／Human／SHA 經獨立 Review；原 evidence／Human／pins bytes 保持，既有 Draft PR 更新後交 Human。 |

### N Stop / evidence limits

- 缺合格 profile／identity／exact group／必要 hosted 資格或 related writer 不為 0，停止；profile 缺 get-task-allow 本身不是自動不合格，仍以本次實際資格檢查為準。
- Fixture 存在／expiry 只能正式 first 讀 DPK 得知；缺失或 runtime／tool／timeout 失敗停止，不 seed／暗修／換 root 重試。任何 phase 的 attempt 已消耗即不自動重啟。
- Human 尚未確認可觀察不得 first；first machine／退出／Human 全程且 0 提示未完整通過不得 fresh。各段實際 prompt count 不預設。
- 本輪不修改 source／tooling／contracts；如必須修工具或增 scope 才能完成，回報 Scope Gap，不能以本驗收授權暗中修補。
- 原 L／E018 已耗預算與結果不變；新 N 也只支持實際完成的有限環境／情境，非產品 E2E。N06 前不把未審結果寫成已 accepted 或更新遠端。

## N-R：nested test bundle 簽章路徑受限修正

N03 blocked 與獨立 Reviewer needs-rework 為已記錄事實；本節明示原 Implement 授權內的最小修正及驗證，不抹除失敗、不增加 Live 次數。僅在 feature worktree，dev 不修改。

| 欄位 | N-R 受限契約 |
| --- | --- |
| Goal | `sign_products` 使用本 project 實際 nested test bundle，先簽 bundle 再 host，缺產物 fail-closed。 |
| Non-Goal | 不擴充 signing 系統、不改 runtime／hosted case／CLI／context／授權／fixture，不以 Live first 探路。 |
| In-Scope | 上述 signing target／順序／預期產物存在性；純 mock／暫存 fixture TDD；完整 Offline、單一修後純建置 preflight 與獨立新來源審查。 |
| Out-Of-Scope | 其他 runner 改動、掃描／fallback signing targets、其他 tests／project、登入／seed／clear／force expiry、新 Apple 資產及額外 phase。 |
| ReadOnly | 除下列 Modify 的兩檔受限區域外，所有 source／tests／project／manifests／contracts／CLI／context schema／phase budget／Apple 資產／原 evidence 與失敗 preflight root／safe proof。 |
| Written | 新回歸使用的暫存 fixture 與修後 Offline 證據；同一私有 parent 下獨立 `preflight-fixed` build／sign／列舉及新 source／artifact pins，均 owner-only。 |
| Modify | 四 topic artifacts；scripts/check-github-integration-hosted-tests.py 僅 sign_products；Tests/GitHubIntegrationHostedTests/test_driver.py 僅純 mock／暫存 fixture 回歸。 |
| Deleted | 無，不刪原失敗 root、safe proof、journal 或 credential。 |
| TestCase | TC-NR01–TC-NR04。 |

| ID | 驗收與證據 |
| --- | --- |
| TC-NR01 | 純 mock／temp fixture：使用 host/Contents/PlugIns 的預期 xctest，nested bundle→host 順序固定。 |
| TC-NR02 | 缺 host／nested bundle（即使有外置假目標）在簽章前 fail-closed；不掃描或 fallback。 |
| TC-NR03 | 新增回歸 red→green 且完整 canonical Offline 通過，正式 Sources／contracts／CLI／context／budget／Apple 資產／原收據不變。 |
| TC-NR04 | 同一 N context、獨立修後純建置 root 完成必要 preflight，無 bind／journal／attempt／authorize／DPK／API；修後 source／pins 經獨立 Reviewer。 |

順序：N02r Plan-Reviewer → NR01 Implementer → NR02 Tester → NR03 Reviewer。NR02 先 full Offline／regressions，再既有 helper-only build／sign／驗證／列舉；任一步再次工具／環境失敗即停止回報，不擴 scope／自動重試。
私有 parent 固定為 TMPDIR 的 `rivet-hosted-live-n-20261118-m2mhtqhu/`；沿用唯一已建立 context，不改授權或 fixture。原 N03 blocked／失敗 preflight immutable；修後 `preflight-fixed` 不是 phase retry。First／fresh 各使用 0/1，正式 run-root 尚不存在；無 sidecar journal、未 bind。NR03 approved 後仍由主 session 等 Human ready 才可正常 first，不由本修正直接放行。

## N-R2：App 內嵌程式碼 inside-out signing 受限修正

NR03 獨立分類 needs-rework，原 N03／NR02 blocked 保留。本節為原 Implement 授權內的第二個明示最小修正，不是新 Live 額度；其他 N／N-R 邊界不重開。
Modify 例外仍只兩個 py 檔：runner sign_products／內部 App-bound discovery helper，以及 test_driver.py 純 mock／temp fixture TDD。Goal 為本次 App 內實際 executable frameworks／dylibs／巢狀 code 的 inside-out signing，再 test bundle、host 最後；resolved path 逃逸 App 即停止，全部同一既有 identity，僅 host 用既定 DPK entitlements。Resource-only bundle 不簽，內層失敗立即停止。
ReadOnly 保持 project／Swift／其他 tests與runner邏輯／正式 Sources／manifests／contracts／CLI／schema／budget／profile／identity／group／Apple 資產及原 roots／evidence。禁止刪 seal、降格 deep strict verify、codesign --deep --force 或重構 Xcode native sign-on-copy；Deleted 無。
TestCase TC-NR2-01：多 frameworks＋dylibs／巢狀 code 的順序；TC-NR2-02：host-only entitlements；TC-NR2-03：resolved path 逃逸與內層失敗立即停止；TC-NR2-04：resource-only bundle 跳過；均先純 mock／temp fixture red→green，再 full Offline。
Written 僅新暫存回歸／Offline 證據與同一私有 parent 的單次 preflight-insideout 純 build／sign／verify／列舉產物及新 pins。原 N03／preflight-fixed／safe proof immutable，同一 context 不改授權或 fixture、未 bind，first／fresh 各使用 0/1；新 root 不是 phase retry 或額度重設。
流程固定 N02s planning review → NR11 bounded Implementer → NR12 Tester（新增回歸＋full Offline，通過後單次 helper-only preflight）→ NR13 Reviewer 新 source／pins → 主 session 通知並等本輪 Human ready 才 first。任何再次工具／環境失敗停止回報，不自動重試或擴修；無 authorize／DPK／API 的原 preflight 禁令保持。

### N結果交付準備（N06有限結果approved）

N04／N05已各完成一次正式hosted機器結果及本輪Human SHA attestation；兩phase已各1/1耗盡，禁止額外run／preflight／sign／DPK／API。有效credential下refresh／save皆0，只記本次restore／API／完整readback／新程序continuity；[hosted-live.md](evidence/hosted-live.md)與4份exact-byte safe／Human receipts為N06受審輸入，原5份evidence／machine placeholders／失敗preflight pins不動。N06獨立Reviewer已明示本次有限結果approved、無required finding；N07目前交付中，待正常commit／push／更新既有Draft PR完成，不代替Human最終接受。
