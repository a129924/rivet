# 讀取單一 PR 的 Files Viewed 狀態｜執行計畫

Topic 為 `pr-reader-github-files-viewed-source`，分支為 `feat/pr-reader-github-files-viewed-source`，使用獨立 feature worktree。分支的 `feat` 對應新增能力，work item 沿用 topic slug，採用 repo 既有的兩段式分支名稱。實際起點為 `dev` 的 `41fdb0e30e2ecc4edc68e4ac944ace32ffe2592d`，已含獨立交付的審閱與合併狀態讀取。 [需求](../../analysis/pr-reader-github-files-viewed-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-files-viewed-source/technical-spec.md) · [PR #105](https://github.com/a129924/rivet/pull/105)

## swift-implementation

`GraphQL/` 代表 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/`。Implementer 開工前核對九欄與實際基線。Reviewer 核對 staged、unstaged 的 tracked 差異與允許新增的 untracked 檔。

| 欄位 | 執行契約 |
| --- | --- |
| In-Scope | Query、套件入口、逐檔 viewed 三態、有序分頁與失敗映射、FV01–FV04、PR Reader 文件回寫及五項本機輔助審閱。 |
| Out-Of-Scope | 標記／取消已讀、本機同步、持久化、UI／WebView、快照組裝、patch／raw diff、REST fallback、共用 client／headers、Core 與公開 API 變更。 |
| ReadOnly | `Written` 與 `Modify` 以外的 tracked 路徑，含固定 SDL、既有 operations、共用工具設定及其他 topic 的變更。 |
| Written | 同 slug 的 requirements、technical-spec、plan、step 四份規劃文件。在 `GraphQL/` 新增 `PullRequestFilesViewed.graphql`、`GitHubPullRequestFilesViewedSource.swift`、`ReaderFileViewed.swift` 與必要 `Generated/` 檔。在 `Tests/RivetPRReaderGitHubTests/` 新增 `GitHubPullRequestFilesViewedSourceTests.swift`。 |
| Deleted | 無。 |
| Modify | 在 `GraphQL/apollo-codegen-config.json` 的 `operationSearchPaths` 與 `Package.swift` 對應 target 的 `exclude` 追加新 query。既有生成檔差異限本題必要且可離線重生的項目。驗收後回寫 `docs/architecture/bounded-contexts/pr-reader.md` 的契約與重生命令，並更新本題帳本。 |
| Goal | 呼叫端取得指定 PR 經核對的完整有序檔案與逐檔 viewed 三態，或單一 Reader failure。 |
| Non-Goal | 推導 viewed、轉成布林、交付部分結果或接入快照。 |
| TestCase | FV01 入口與映射、FV02 分頁完整性、FV03 失敗與取消、FV04 產碼與回歸。 |

## 產品驗收

- **FV01 入口與映射**。走套件正式入口與受控 Apollo JSON，覆蓋單頁、跨頁、三態、六種變更、原序、原始路徑和增刪數。驗證前後空白、全空白及 UTF-8 不同但 Unicode 正規等價的路徑均保留。
- **FV02 分頁完整性**。驗證合法零筆、`files`／`nodes`／元素的 `null`、同頁與跨頁重複路徑、空續頁、缺少或循環的游標、repo／PR／head 變動與 `totalCount` 不一致。每個異常皆回單一對應失敗。
- **FV03 失敗與取消**。驗證無效輸入零請求、首續頁定位缺席及拒絕、欄位權限、partial data、限流、傳輸失敗、未知 enum、負增刪數、空路徑、錯型及缺失必填欄位。驗證預先取消無請求，以及晚到成功或認證失敗皆由取消優先處理。
- **FV04 產碼與回歸**。以固定 SDL、Apollo 2.1.2 先清潔離線重生基線，再加入 Files Viewed 重生並比對。整合時合併 operation 清單後重生並核對 Files Viewed、Checks、兩個 Review Threads operations，以及本基線已納入的審閱與合併狀態 query。執行 `swift test --filter 'RivetPRReaderGitHubTests|RivetPRReaderTests|GitHubIntegrationTests'`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`。

## 本機輔助審閱

| 工具 | 執行與核對 |
| --- | --- |
| Archify 2.16 | 在 feature worktree 的 `.build/topic-evidence/<topic>/archify/` 產出繁中 Reader sequence，Viewer 使用英文。執行 `showcase` validate，要求 9/9 且零錯誤、零警告，再以 `deliver` 產出 HTML。執行四尺寸 `visual-check`，目視最小與最大尺寸的亮暗畫面，保留 HTML 與收據。 |
| PR Lens 0.11.0 | 使用本機固定版本，依實際 base 與本題 head 或明示的未提交有界 diff，在 repo 外暫存產出差異圖，涵蓋本題改動與未改動的直接鄰居。執行 validate、light render 並讀回 manifest 與 SVG。有適用 overlay 時沿用，否則以 `--no-config`。取得最終 base／head 時重新產出並核對來源資訊。 |
| Graphify 0.9.73 | 每次執行設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。只對可確認匹配受查修訂的既有圖做限量查詢並覆核原碼。無相符既有圖時以 `rg` 和原碼核對，記錄替代證據。 |
| Show Me | 在步驟帳本記錄精簡 call tree，核對正式入口、輸入驗證、查詢、分頁歸屬及游標、三態映射與單一失敗出口。 |
| Floorplan | 將現有 ignored map 複製到 feature worktree，保留筆記及自訂 flows 後 refresh。執行時若無既有圖，依 skill 在本機初始化 ignored map。Recent work 僅標示本 topic，核對說明覆蓋、HTML 預覽、高嚴重度 Health 項目及未涵蓋的檢查。保留可用的本機輸出。 |

Implementer 產出證據，Tester 獨立核對，Reviewer 檢查差異與證據。輔助產物留在 ignored 或 repo 外暫存位置，交付限於本機。工具出現可恢復錯誤時依各 skill 修正後重試，仍受限則記錄原因、替代核對與未驗項。產品驗收依 FV01–FV04 判定。

## 交接與停點

獨立 Plan-Reviewer 讀回四檔並明示 `approved` 後，依序交 Implementer、Tester 與獨立 Reviewer。若需變更 scope、已確認契約或允許寫入範圍，交 Human Check。

Human 已授權本題在實作、驗證及獨立審查無重大問題且 staged diff 符合 topic 語意邊界時交付。提交前依 `git-commit-convention` 核對 staged diff 並先提出 commit message。條件成立後，建立單一 topic commit、推送功能分支並建立以 `dev` 為目標的 Draft PR。讀回遠端分支與 Draft PR 後交 Human Review。條件未達成時在提交前停下。 [步驟帳本](pr-reader-github-files-viewed-source.step.md)
