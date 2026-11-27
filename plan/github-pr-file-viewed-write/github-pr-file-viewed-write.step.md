# GitHub PR 檔案已讀寫入步驟帳本

最後更新 2026-11-27。分支 `feat/github-pr-file-viewed-write`，基線 `3468eaab4cf7a1646083332e1eef2223b107ebb4`。Phase 為交付，當前步驟 `V06`，狀態 `pending`。Human 已接受對話版計畫。

| ID | 狀態 | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| V01 | completed | Plan-Creator | 在獨立 feature worktree 起草並讀回同 slug 四份正式文件。 | Human 核准對話計畫。四份文件已寫入並讀回。 |
| V02 | approved | Plan-Reviewer | 獨立審查實際四檔、九欄、技術契約、FV01–FV04、交付條件及停點，回報明示 verdict。 | 獨立 Plan-Reviewer 核對實際四檔及九欄，回覆 `approved`，無必要修正。 |
| V03 | completed | Implementer | 依核准契約交付套件入口、兩個 mutation、target、離線產碼、測試與文件回寫。留存本機審閱證據與限制。 | 同一組六項受控測試從初始行為的 49 個斷言失敗，轉為實作後六項全數通過。 |
| V04 | completed | Tester | 獨立執行 FV01–FV04，核對離線重生、回歸與最終差異。 | 回修後獨立 Tester 確認 FV01–FV04 通過。SwiftPM 511 項、56 個 suite，SwiftLint 971 檔零違規，SwiftFormat 與 diff 檢查通過。Apollo 2.1.2 離線重生 350 檔逐檔一致，固定 schema SHA 相符。 |
| V05 | approved | Reviewer | 依實際差異與 Tester 證據審查本 topic，回報明示 verdict。 | 獨立 Reviewer 核對實際九欄差異、操作、錯誤及取消契約、套件隔離與驗收證據，回覆 `approved`，無必要修正。 |
| V06 | pending | Implementer | 驗收及成果審查無重大問題、staged diff 屬單一且受限 topic 時，依已授權條件記錄 commit message，完成單一 commit、push、Draft PR 與讀回。 | Commit message 為 `feat(pr-write): 支援 GitHub PR 單檔標記與取消已讀`。實際 push 與 Draft PR 讀回收據由交付回報承接。 |
| V07 | pending | Human | 審閱以 `dev` 為目標的 Draft PR。 | 待 V06。 |

## Blockers

目前無已確認的阻礙。任何驗收未達標、重大問題、越界差異或需改動已鎖定決策，依執行計畫停在提交前。

## 證據

- 首輪獨立 Tester 的 7 項 SwiftLint 診斷已修正。同一組測試與完整 lint 由 Tester 重跑通過。既有 GraphQL `401` 認證復原、Reader 讀取、target graph、依賴鎖檔及唯讀範圍均已核對。
- Archify sequence 位於 feature worktree 的 `.build/topic-evidence/github-pr-file-viewed-write/archify/sequence.html`。Showcase 9/9、0 錯誤與 0 警告。1440×900、1600×1000、1920×1080、2048×1320 容納測試通過，已目視最小與最大尺寸的明暗四張截圖。
- Graphify 0.9.73 未找到可對應本版的圖，已用定向搜尋核對 manifest、writer、`GitHubGraphQLServing` 及 pinned schema 的兩個 mutation。Floorplan 重建至 ignored `floorplan/index.html`，Recent work 顯示兩張本組卡片，已目視 Chrome 本機預覽。全圖仍有舊 Reader 模組拆分警告與檔案描述缺口。無需本機伺服器。
- PR Lens 提交前核對受限差異與本組新檔，待取得真實 commit pair 後以固定 CLI 出圖。

```text
PRFileViewedWriter.setViewed
  ├─ 無效輸入或進入 perform 前取消 → 零次 client 呼叫
  └─ valid → mark 或 unmark → GitHubGraphQLServing.perform 一次
       ├─ 同 PR 且必要欄位不受錯誤影響 → 已接受
       ├─ 必要拒絕證據一致 → 明確拒絕
       └─ 其餘回應或中斷 → 待核對
```

[寫入入口](../../Sources/RivetPRWriteGitHub/PRFileViewedWriter.swift) · [受控測試](../../Tests/RivetPRWriteGitHubTests/PRFileViewedWriterTests.swift)

## Human Check

Human 已授權本 topic 的獨立工作樹實作及受條件限制的 commit、push、Draft PR。此次交付止於 Draft PR 讀回與 Human Review。真人遠端寫入、合併、發布及下一個 topic 有各自邊界。 [執行計畫](github-pr-file-viewed-write.plan.md)
