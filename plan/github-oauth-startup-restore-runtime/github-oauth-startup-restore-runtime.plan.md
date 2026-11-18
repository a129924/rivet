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
