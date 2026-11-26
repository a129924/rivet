# 單一 PR 審閱與合併狀態步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 RM-S06。基線 `10610d0be88c1d2bce37d5418fa5bae3171f8526`，分支 `feat/pr-reader-github-review-merge-state-source`。

| ID | 狀態 | 角色 | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| RM-S01 | completed | Plan-Creator | 在獨立 worktree 建立四份同 slug 文件 | 已依 Human 核准的對話版建立。 |
| RM-S02 | approved | Plan-Reviewer | 實際四檔符合規劃契約及九欄 | 獨立 Plan-Reviewer 讀回四檔並明示 approved，無必要修正。 |
| RM-S03 | completed | Implementer | 完成有界實作、受控測試與證據 | 正常入口代表案例先因占位實作失敗。完成功能後，本題 9 項 Swift Testing 測試通過。 |
| RM-S04 | completed | Tester | 獨立驗證 RM01–RM04 與輔助產物 | 獨立 Tester 確認 RM01–RM04 通過，485 tests／52 suites。 |
| RM-S05 | approved | Reviewer | 核對實作與證據 | 獨立 Reviewer 核對 15 檔及驗證證據，明示 approved，無必要修正。 |
| RM-S06 | pending | Implementer | 核對 staged diff，提交、推送、建立並讀回 Draft PR | 15 檔符合單一 topic。提交訊息為 `feat(pr-reader): 讀取單一 PR 的審閱與合併狀態`。提交、推送與 Draft PR 讀回後，將結果存於本機交付收據。 |
| RM-S07 | pending | Human | 審閱 Draft PR | 待 Draft PR。 |

## Blockers

固定 SDL 雜湊與基線一致，Apollo 2.1.2 離線重生既有產碼零差異。新查詢重生只新增 query 與三種 enum。

## 驗收與本機證據

- 獨立 Tester 重跑 485 項測試、52 個 suites，涵蓋本題 9 項、Checks 與 `reviewThreads` 回歸。首輪的三項 SwiftLint 問題已修正，重驗嚴格格式、SwiftLint 590 檔與 Git diff 檢查皆通過。
- Apollo 2.1.2 以固定 SDL 清潔離線重生基線與 feature，兩者均與各自产碼逐檔一致。SDL SHA-256 為 `a70103efc655a6b81afa69cdbce8b27d90d8202270b19ea54130e95c650047b7`。
- Archify sequence 位於 `.build/topic-evidence/pr-reader-github-review-merge-state-source/archify/review-merge-state.html`，繁中內容與英文 Viewer，showcase 9/9、零錯誤或警告。四種桌面尺寸通過，獨立 Tester 目視最小及最大尺寸的亮暗畫面。HTML SHA-256 為 `e89a58e47b3c9f96a4d4203cefab969022dc4e2502cf8945ce7e3348959c2205`。
- Floorplan 用 Checks 的本機基線圖更新，599/599 檔、62/62 模組有說明，Recent work 標出本題三張卡。已開啟本機預覽，高嚴重度 0 項。工具未辨認出可執行登入檢查的端點。
- Graphify 0.9.73 查無可追溯本題的既有圖，改以 `rg`、query、Reader source 與共用 client 原碼核對，並對照受控請求。
- PR Lens 使用 0.11.0 依提交後的實際 base／head 產出本機變更圖，結果留在 repo 外的交付收據。

### Show Me

    fetchReviewMergeState
      驗證 PR 識別與取消狀態
      readPullRequest → fetch(PullRequestReviewMergeState)
      核對 repository 與 PR 歸屬 → 映射五項欄位
      交付完整結果或單一 PRReaderFailure

## Human Check

已核准獨立 worktree 實作與條件式交付。若較大契約問題或需調整 tracked 範圍，停在 Human Check。Draft PR 建立並讀回後交 Human Review。 [執行計畫](pr-reader-github-review-merge-state-source.plan.md)
