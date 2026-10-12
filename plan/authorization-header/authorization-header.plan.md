# AuthorizationHeader 執行契約

## Goal、Non-Goal 與已授權交付

Goal：依 [technical-spec](../../analysis/authorization-header/technical-spec.md) 完整交付純 AuthorizationHeader、測試、最小長期文件及受限輔助產物。公開 API、RFC grammar、ASCII replacement、input preservation 與 typed error 均已鎖定。

Non-Goal：consumer integration、credential lifecycle、network execution、retry、額外 scheme／抽象或 generic headers framework。需求來源見 [requirements](../../analysis/authorization-header/requirements.md)。

依 repository git-branch-naming overlay，分支為 `feat/authorization-header`，不新增 owner。Dispatcher 已交接 feature worktree `agent-20261012-authorization-header`，base 為 `4805061a0d8d08d7690c0acd288a374860fa71c8`（已 fetch 的 origin/dev）；此 Git 狀態來自交接，不是 Plan-Creator 自行驗證。所有寫入僅在此 feature worktree，禁止在 dev worktree執行 delivery mutation。

使用者本輪明示「請直接 commit by topic」，並已明確授權 feature implementation → topic commit → push → Draft PR → human review；成果審查 approved 後依此授權交付，不重複索取 commit 許可。commit 前依 git-commit-convention 檢查 staged diff 與提出 message；不得跨 topic、force push、merge 或 release。Draft PR 以 dev 為目標，送出後停在人類 review 邊界。

Dispatcher 補充已驗證：Swift 6.3.3 可用、Graphify runtime 0.9.73 與 PR Lens 0.11.0 存在；gh auth 在 network-enabled 環境有效，sandbox 的先前 invalid 訊息屬連線限制。無 graph 仍使用 source fallback；這些交接環境資訊不代表本 topic 測試或 gate 已通過。

## 全域九欄與檔案 allowlist

| 欄位 | 契約／代號 |
| --- | --- |
| Goal | 交付已鎖定的新元件及有證據的驗收／Draft PR。 |
| Non-Goal | 不遷移既有 consumers，不增加 lifecycle／transport／抽象。 |
| In-Scope | P、S、T、D、M、X 與授權 topic delivery。 |
| Out-Of-Scope | 任何未列出的 tracked 寫入、graph build、工具安裝／升級／上傳／server、非 Draft PR 發布及 merge／release。 |
| ReadOnly | 所有既有 source／tests，含 BearerAuth、REST／GraphQL consumers、OAuthTokenProvider、HTTPHeaders／transport；manifests、AGENTS、skills、config／hooks、既有圖與 BC 文件，以及未列出的 tracked paths。既有 PR Lens config 僅讀取。 |
| Written | **P** 四份新 planning artifacts（見下表）；**S** 新元件；**T** 新測試；**D** 本流程圖與工具實際生成的必要證據；**X** repository 外 PR Lens scratch。 |
| Deleted | 無。工具自身清理 private temporary state 不代表授權刪除 repository 交付檔。 |
| Modify | **M** `docs/architecture/README.md` 的最小 capability／圖表連結回寫；P 建立後的本 topic 契約／ledger 維護。S／T／D 新增後僅可在同範圍修正，不擴張 allowlist。 |
| TestCase | TC-01 至 TC-07；每 step 必須明示適用 subset，不能只引用全部而略過實際紀錄。 |

| 代號 | 精確範圍 |
| --- | --- |
| P | `analysis/authorization-header/requirements.md`、`analysis/authorization-header/technical-spec.md`、`plan/authorization-header/authorization-header.plan.md`、`plan/authorization-header/authorization-header.step.md`。 |
| S | `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/AuthorizationHeader.swift`：namespace、error、public API 文件。 |
| T | `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/AuthorizationHeaderTests.swift`：Swift Testing、一般 import RivetHTTPClient。 |
| D | 僅 `docs/architecture/diagrams/authorization-header/` 內的 `authorization-header-flow.json`／`authorization-header-flow.html`，以及 skill 實際生成且屬於本流程的 validation／delivery／visual-check receipts、contact sheet／screenshots；sidecar 檔名以實際輸出為準，不捏造命名或加入任意 exports。 |
| X | repository 外專屬暫存目錄的 PR Lens graph.json、rendered outputs、實際 provenance／執行紀錄；不納入 Git。一般 build caches／臨時輸出不是交付檔。 |

M 只有在實作真實存在後才記為已交付，並明示 consumers 未整合；不改既有圖、BC／dependency boundary 或 system canvas。

## TestCase 與驗證命令

| ID | 驗收 |
| --- | --- |
| TC-01 | 精確 Bearer formatting；允許字元各種類；零、一、多個尾端 =，包含符合 grammar 但非 Base64 padding 長度的 token。 |
| TC-02 | 空、僅 =、中間 =、空白／tab／CR／LF／NUL、非 ASCII／非法字元；兩 API 精確拋 invalidToken，error description／reflection 不含非法測試 sentinel。 |
| TC-03 | 空 headers 新增；標準／小寫／混合大小寫替換；多個變體正規為單一精確 Authorization。 |
| TC-04 | 無關 key 拼字／value 保留；成功／失敗 input 不變；同 token 冪等、不同 token 替換；插入順序不影響結果內容。 |
| TC-05 | public import 獨立測試、不建立 network client／provider；focused／standalone／root suite 與 format／lint 有分開的真實結果。 |
| TC-06 | Archify dataflow 語意一致；showcase／delivery receipts 與視覺 inspection 真實通過。 |
| TC-07 | 真實 diff 的 PR Lens map 或如實 fallback；Graphify query／source fallback 不建圖，不偽造 edges／provenance。 |

```sh
swift test --package-path packages/RivetHTTPClient --filter AuthorizationHeaderTests
swift test --package-path packages/RivetHTTPClient
swift test
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
```

Tester 分別保存 actual command／result／evidence；README prose 由 Reviewer 核對真相。後續 commit 執行 repository hooks／既有品質檢查，不 bypass；工具或檢查失敗均如實記錄，不擴張至其他元件修復。

## Skills 交付界線

**Archify**：使用 dataflow、靜態、showcase；執行時讀 matching schema／common schema／example，先 author candidate，不先研究 renderer internals。圖表主路徑為 token 驗證 → Bearer value，headers 與 value → 清理 Authorization 變體 → 新增 → 回傳，另有 invalidToken 分支；沒有 consumer／transport 邊。作者繁體中文，省略不支援的 locale，固定 UI／HTML lang fallback English。每次 candidate 修改後 validate；deliver 是最終 acceptance，須 9 checks、0 errors、0 warnings，保存 spec／artifact SHA-256 receipts。對可信 HTML 執行 visual-check 並傳 repo-root，涵蓋 1440×900、1600×1000、1920×1080、2048×1320 containment 與兩種 theme 截圖，再人工 inspect；自動 pending 不等同人工 passed。修復只針對 diagnostics；objective error count 創新低就繼續，連續兩輪未改善最佳 count 才停止，回報未解 diagnostics／needs-rework。圖表失敗或視覺 skipped 不算交付通過，不以 fallback 取消本項。

**PR Lens**：由獨立 Reviewer 在真實 bounded diff 存在後使用 skill pinned CLI 0.11.0，讀 graph-document／example，於 X author／validate／render。記錄真實 base／head SHA；未 commit diff 明示 working-tree 狀態與實際 base，不偽造 head commit／patch provenance。包含有 source 證據的 unchanged 鄰居／file refs，不捏造 consumer edges。當時若有既有 correction config，只讀套用；無 config 的 scratch 使用 no-config。不寫 .github／.pr-lens／.gitignore。工具失敗或 map 增加閱讀負擔時記錄原因，fallback direct diff review；fallback 不等同 tool passed。不安裝、上傳、provider call、server 或 PR attach／comment。

**Graphify**：僅查既有 graph，每個 CLI invocation（含 help／version）都帶 GRAPHIFY_NO_AUTO_REFRESH=1。目前無可用 graph，採 targeted source reads；若執行時有可用 graph，先查 revision，做 bounded query 並以 source 複核 consequential edges。無 graph／runtime failure 如實 fallback，不 extract、建圖、refresh、寫 version stamp／skills／config／hooks 或啟動服務。

## Gates 與停止點

依 [step ledger](authorization-header.step.md) AH-01 至 AH-06 執行。四份 P 存在且可讀後，須獨立 Plan-Reviewer 明示 approved 才實作；Implementer 完成後由獨立 Tester 驗證，再交獨立 Reviewer。成果 approved 才進入已授權的 topic commit／non-force push／Draft PR。

needs-rework 只交對應產出角色；blocked／human-check 停止並交還人類。API、consumer、dependency、allowlist 或已鎖定決策有衝突即回報，不自行擴張。Draft PR 建立後停在人類 review；不自動 merge／release。任何 checkbox／完成 status／歷史 evidence 不等同獨立 gate approval。
