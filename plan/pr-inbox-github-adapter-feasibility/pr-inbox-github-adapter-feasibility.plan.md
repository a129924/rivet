# PR Inbox GitHub adapter 可行性驗證執行計畫

全部規劃、Swift 實作、測試與 staging 位於已核對的 `../rivet.worktrees/agent-20261118-pr-inbox-github-adapter-feasibility`。使用 `chore/pr-inbox-github-adapter-feasibility`，基線 `0a71be9`。實作前由獨立 Plan-Reviewer 審查正式四檔，明示 `approved` 後交 Implementer。實驗建立前再確認 E019 未占用。 [技術規格](../../analysis/pr-inbox-github-adapter-feasibility/technical-spec.md)

## swift-implementation

| 欄位 | 規格 |
| --- | --- |
| **In-Scope** | E019 獨立 SwiftPM CLI、實驗用 `ReviewRequestSource`、受控測試與一次現有 OAuth 的真實唯讀驗證。 |
| **Out-Of-Scope** | 正式 adapter 採用、產品接線、Inbox UI、新 OAuth 授權或更新、PAT、DPK／Keychain、GitHub PR 資料寫入、合併與發布。 |
| **ReadOnly** | 既有 Facade、Port、Outcome、`GitHubIntegration`、`RivetHTTPClient`、root `Package.swift`、正式測試、架構與 API 文件及歷史實驗。 |
| **Written** | 正式四檔及 `experiments/E019` 的獨立 manifest、adapter、CLI、測試與八段 README。圖面與收據留本機暫存或 ignored 目錄。 |
| **Deleted** | 無。 |
| **Modify** | 回修與證據補記限本輪新建的 E019 檔案及由對應角色維護的正式四檔。 |
| **Goal** | 讓既有 `PRInboxFacade.refresh()` 回傳一筆已獨立確認、仍開啟且直接要求目前帳號審閱的真實 PR，四個 `InboxItem` 欄位一致。 |
| **Non-Goal** | 完整帳號覆蓋、團隊審閱、突破搜尋上限與產品重試策略。 |
| **TestCase** | 精確 query、四欄轉換、跨頁順序、空集合、無效 DTO／分頁、後頁失敗、非 200、傳輸錯誤、取消、不完整結果及搜尋上限。真實驗證核對帳號、現有正例與可用反例。 |

## 驗證與交付

1. Implementer 交接 E019 原碼、受控案例與 README。Tester 執行獨立驗證並記錄差異與缺口，交獨立 Reviewer 審查。真實驗證先核對本機 OAuth 及同帳號正例，依技術規格執行一次，最多 11 個 GET、60 秒、零重試。缺必要前置時在 README 與 Draft PR 明示「未執行」，保留原判準及受控證據。
2. Show Me 用 CLI → Facade → 實驗 source → REST Search 呼叫樹交接。Graphify 優先唯讀查版本可追溯的既有 graph，再回查原碼。目前缺 graph，採限域原碼搜尋。Graphify CLI 一律加 `GRAPHIFY_NO_AUTO_REFRESH=1`。依 E019 原碼製作繁中 Archify sequence，本機完成 showcase 9/9、0 errors、0 warnings、`deliver`、四尺寸 `visual-check` 與實際視覺檢視，Viewer 固定介面為英文。Floorplan 從 feature worktree 的 ignored `floorplan/` 沿用並刷新現有地圖，必要時複製 dev worktree 的作者輸入，標出 E019、核對引用並開啟本機 HTML。工具結果各自記錄，E019 依已鎖定的實驗判準判定。
3. 獨立審查無重大問題時，依 Human 的直接授權，使用 git-commit-convention 檢查 staged diff，只納入正式四檔與 E019。預定單一語意 commit 為 `chore(pr-inbox): 新增 GitHub 待審閱 PR 可行性驗證`，送出前以實際 staged diff 核對。
4. 正常 push feature branch，建立以 `dev` 為 base 的 Draft PR，讀回 URL、draft 狀態、base、head、遠端 SHA。PR Lens 0.11.0 使用實際 PR base/head 與受限 diff 本機 `validate`、`render`，保留 Facade 與 REST client 作為脈絡。本機圖面作為獨立審閱資料。
5. 回報 Draft PR、實驗狀態、測試與本機圖面，停在 Human review。範圍衝突、未解除的 required fix 或權限問題在對應步驟回報。
