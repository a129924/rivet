# 讀取單一 PR GraphQL 審閱對話步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 RT-S06。分支 `feat/pr-reader-github-review-threads-source`，基線 `1fcdb2c274e2d0fde5c88e4225e20942650167c3`。

| ID | 狀態 | 角色 | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| RT-S01 | completed | Plan-Creator | 在獨立工作樹建立並讀回四份同 slug 文件 | 以已核准對話計畫建立需求、技術規格、執行計畫及本帳本。 |
| RT-S02 | approved | Plan-Reviewer | 獨立審查實際四檔、九欄範圍、驗收及授權 | 獨立 Plan-Reviewer 複核四檔，明示 approved，無必要修正。Human 授權的套件隔離測試單檔限制已記入九欄。 |
| RT-S03 | completed | Implementer | 依執行契約交付 bounded 讀取、測試及本機審閱證據 | 兩個 GitHub.com query、Reader Infra 來源與保真結果已實作。Apollo 2.1.2 產碼納入同一 target，套件隔離測試已依授權同步。初驗 466 tests、50 suites 通過。 |
| RT-S04 | completed | Tester | 獨立執行 RT01–RT04 並核對五項本機補充證據 | 獨立 Tester 執行最終暫存版本，RT01–RT04 通過。466 tests、50 suites，格式與 SwiftLint 574 檔零違規，cached diff check 通過，離線重生 352 檔零差異。 |
| RT-S05 | approved | Reviewer | 獨立核對驗收證據與已暫存、未暫存及允許新增檔差異 | 獨立 Reviewer 核對全 365 個暫存路徑、輸入與生成碼、查詢、保真與失敗契約，明示 approved，無必要修正。 |
| RT-S06 | pending | Implementer | 在 Human 授權條件成立時完成單一 commit、push、Draft PR 及讀回 | 已核對 staged diff 語意限本 topic。訊息為「feat(pr-reader): 讀取單一 PR 的 GraphQL 審閱對話」。單一提交產生後，以本機 ignored 交付收據記錄實際 base／head 及 Draft PR 讀回。 |
| RT-S07 | pending | Human | 接手 Draft PR 審閱 | 待 Draft PR 建立及讀回。 |

## Blockers

無。已具備本次條件式交付的驗收與獨立審查證據。

## 實作與本機證據

- 基線 457 tests、49 suites 通過。空 thread 清單測試在占位實作如預期失敗，實作後 9 項新測試通過。指定回歸共 466 tests、50 suites。嚴格 Swift 格式及 SwiftLint 通過，SwiftLint 檢查 574 檔。
- 官方公開 SDL 的 SHA-256 為 a70103efc655a6b81afa69cdbce8b27d90d8202270b19ea54130e95c650047b7。Apollo CLI 2.1.2 驗證 query 並產生 352 個 Swift 檔。生成檔開頭的局部規則註解由重生程序固定加上，共用工具設定維持原值。
- Archify 目錄 .build/topic-evidence/pr-reader-github-review-threads-source/archify 內交付 review-threads.html。Showcase 9/9，零錯誤警告，四尺寸 containment 通過，兩極尺寸亮暗目視已核對。HTML SHA-256 為 a2cbbc38d5b403cdc45d35cf3ed55454eb4f9e2013b39362c715f96f8ec2c9da。
- PR Lens 0.11.0 本機 graph 與 light SVG 初次驗證、渲染通過，產物為 repo 外暫存目錄 rivet-review-threads.RHv4Fo/pr-lens 下的 graph.json 與 rendered/manifest.json。發佈後以實際 base、head、Draft PR 讀回重驗。
- Graphify 0.9.73 已確認版本。預設位置未有可追溯的既有圖，使用 rg 與原碼核對來源、兩查詢及既有 GraphQL client 的呼叫關係。
- Floorplan 在獨立工作樹刷新，檔案描述 592/592、modules 62/62、routes 0/0、未分派 0。Recent work 只標示本題四張卡。本機瀏覽器開啟並讀回。高嚴重度項目 0，Endpoint sign-in 未檢查，因未偵測到疑似伺服器的端點。

- 提交前檔尾 hook 將 350 個生成 Swift 收尾正規化為單一 LF。修正重生程序後，獨立 Tester 比對 352 檔零差異，回歸 466 tests、50 suites 通過，Reviewer 複核維持 approved。Renderer 依既有鎖檔安裝本機依賴後檢查通過。

### Show Me

    fetchReviewThreads
      readThreads
        readThreadPage → fetch(ReviewThreads)
        逐一 thread：readComments → 必要時 fetch(ReviewThreadComments)
        當頁留言讀完 → 下一個外層頁或完整結果
      任一層失敗或取消 → 單一 PRReaderFailure

## Human Check

Human 已確認可將 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 納入 Modify，僅與 Reader GitHub 來源路徑及成對來源／測試 target 的 Apollo／ApolloAPI 依賴預期同步。

Human 已核准對話版完整計畫與獨立工作樹實作。產品驗證與獨立成果審查無重大問題，且 staged diff 符合九欄與單一 topic 語意邊界時，Human 已授權依 `git-commit-convention` 先核對差異、提出並記錄訊息，再做單一 commit、推送功能分支及開啟以 `dev` 為目標的 Draft PR。條件未達成時停於提交前。若 schema 採用或重生無法成立，或須調整公開契約、共享 client、完整性條件或 tracked 路徑，停在 Human Check。Draft PR 建立並讀回後交還 Human Review。 [執行計畫](pr-reader-github-review-threads-source.plan.md)
