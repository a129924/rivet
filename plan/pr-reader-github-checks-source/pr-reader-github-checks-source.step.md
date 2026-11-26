# 讀取單一 PR 的 Checks 步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 CK-S06。分支 `feat/pr-reader-github-checks-source`，固定基線 `97e3db851348d2dc0305fc371aa792ce84b257ae`。

| ID | 狀態 | 角色 | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| CK-S01 | completed | Plan-Creator | 在獨立工作樹建立並讀回四份同 slug 文件 | 依 Human 核准對話版計畫建立需求、技術規格、執行計畫及本帳本，四檔已讀回。 |
| CK-S02 | approved | Plan-Reviewer | 獨立審查實際四檔、九欄範圍、驗收及授權，記錄 verdict | 獨立 Plan-Reviewer 實際讀回四檔，明示 approved，無必要修正。 |
| CK-S03 | completed | Implementer | 核對既有基線，依核准契約交付有界讀取、測試及本機審閱證據 | 完成套件入口、GraphQL 讀取、分頁與保真映射。受控空明細案例在占位入口如預期失敗，實作後 Checks 新測試 10 項通過。 |
| CK-S04 | completed | Tester | 獨立執行 CK01–CK04 並核對五項本機證據 | 獨立 Tester 重跑完整指定回歸，476 tests、51 suites 通過。嚴格格式、SwiftLint 583 檔、cached diff、Apollo 離線重生及五項本機證據皆已核對。 |
| CK-S05 | approved | Reviewer | 獨立核對驗收證據與全部 staged、unstaged 及允許新增檔差異，記錄 verdict | 獨立 Reviewer 核對 18 檔、獨立測試回報與產碼差異，明示 approved，無必要修正。 |
| CK-S06 | pending | Implementer | 依 Human 授權條件核對 staged diff 及訊息後，完成單一 commit、push、Draft PR 及讀回 | 已核對單一 topic 的 staged diff。訊息為「feat(pr-reader): 讀取單一 PR 的 Checks」。提交、推送與 Draft PR 讀回後另存本機交付收據。 |
| CK-S07 | pending | Human | 接手 Draft PR 審閱 | 待 Draft PR 建立及讀回。 |

## Blockers

PR #102 已納入固定基線，上游等待已解除。基線 SDL 雜湊與既有文件一致，Apollo 2.1.2 離線重生無差異。 [PR #102](https://github.com/a129924/rivet/pull/102)

## 驗收與本機證據

- 初驗與獨立重跑的指定回歸皆通過，476 tests、51 suites，包含 10 項 Checks 新測試。獨立首輪既有 OAuth `startedSaveSettlesBeforeDelete()` 超過等待護欄後出現兩個斷言，Checks 首輪全過，同一版本重跑全過。OAuth 來源及測試無差異。嚴格 Swift 格式與 SwiftLint 通過，SwiftLint 共檢查 583 檔。
- 官方 SDL 雜湊維持 `a70103efc655a6b81afa69cdbce8b27d90d8202270b19ea54130e95c650047b7`。Apollo 2.1.2 基線重生零差異，新舊兩份 operation 的清潔離線重生也與工作樹產碼逐檔相符。
- Archify sequence 位於 ignored `.build/topic-evidence/pr-reader-github-checks-source/archify/checks.html`，showcase 9/9、零錯誤警告、四種尺寸通過，已目視最小與最大尺寸亮暗畫面。HTML SHA-256 為 `c04b4c0293aa262b62f15efd7ed6cd9a87f13ca869702e02b4ac0cbf528913e2`。
- Graphify 0.9.73 查無可追溯至本工作樹的本機圖，以 `rg` 及原碼核對套件入口、查詢、共用 client 及既有 Reader 結果型別。
- Floorplan 從相依 topic 的既有本機地圖刷新，595/595 檔、62/62 模組有說明，Recent work 只標本題三張卡。本機預覽已開啟。高嚴重度 0 項，端點登入檢查因未辨識到端點而未涵蓋。地圖涵蓋程式碼，沿用既有生成檔排除設定。
- PR Lens 0.11.0 已以實際暫存差異製圖，validate 與 light render 通過，已讀回 graph、SVG 和 manifest。提交與 Draft PR 讀回後，按實際 base／head 更新本機產物並重驗。

### Show Me

    fetchChecks
      readChecks
        readPullRequest → fetch(PullRequestChecks)
        已定位且首頁無 rollup → 成功缺值
        查核歸屬、狀態及總數 → appendChecks → 查核游標並在必要時讀續頁
        收齊明細 → 完整、有序 rollup
      任一步驟失敗或取消 → 單一 PRReaderFailure

## Human Check

Human 已核准對話版完整計畫和獨立 worktree 實作。在產品驗證與獨立成果審查無重大問題，且 staged diff 符合九欄及單一 topic 語意邊界時，Human 已授權依 `git-commit-convention` 核對 staged diff、提出並記錄訊息後，做單一 commit、推送功能分支與以 `dev` 為目標的 Draft PR。若條件未達成，或既有 SDL／產碼流程無法支援 operation，或需調整已確認的契約及 tracked 範圍，停在相應的 Human Check。Draft PR 建立並讀回後交還 Human Review。 [執行計畫](pr-reader-github-checks-source.plan.md)
