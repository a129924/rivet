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
