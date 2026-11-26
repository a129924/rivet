# 讀取單一 PR 的 Files Viewed 狀態｜步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 FV-S06。基線為 `41fdb0e30e2ecc4edc68e4ac944ace32ffe2592d`，分支為 `feat/pr-reader-github-files-viewed-source`，使用獨立 feature worktree。 [需求](../../analysis/pr-reader-github-files-viewed-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-files-viewed-source/technical-spec.md) · [執行計畫](pr-reader-github-files-viewed-source.plan.md)

| ID | 狀態 | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| FV-S01 | completed | Plan-Creator | 確認獨立工作樹基線後建立同 slug 的四份正式文件。 | 已確認分支及 HEAD，依 Human 核准的對話版寫入四檔。 |
| FV-S02 | approved | Plan-Reviewer | 獨立讀回四份文件，核對契約、九欄與 FV01–FV04，回傳明示 verdict。 | 獨立 Plan-Reviewer 讀回實際四檔，核對九欄、FV01–FV04、五項輔助審閱及交付條件，明示 approved。無修正事項。 |
| FV-S03 | completed | Implementer | 完成界定內的實作、回寫契約及取得本機輔助審閱證據。 | 完成套件內來源及受控 Apollo 測試，回寫契約與重生命令。實作端回歸與風格檢查通過，交 Tester 獨立驗證。 |
| FV-S04 | completed | Tester | 獨立驗證 FV01–FV04 與可取得的輔助審閱證據。 | 獨立 Tester 重跑 505 tests／54 suites，含本題 11 項。嚴格格式、SwiftLint 603 檔及差異檢查皆退出 0。固定 SDL 與基線／本題 Apollo 2.1.2 離線再生皆逐檔一致。 |
| FV-S05 | approved | Reviewer | 獨立審查授權範圍、實際差異與測試證據，回傳明示 verdict。 | 獨立 Reviewer 核對九欄範圍、17 檔差異、分頁與失敗契約、測試及產碼證據，明示 approved。無必要修正。 |
| FV-S06 | pending | Implementer | 核對 staged diff，先提出訊息，再依授權進行單一 commit、push 與 Draft PR，讀回遠端狀態。 | 採單一 topic commit，建議訊息為 `feat(pr-reader): 讀取單一 PR 的 Files Viewed 狀態`。推送、Draft PR 讀回及最終 PR Lens 憑據記於本機交付收據。 |
| FV-S07 | pending | Human | 審閱 Draft PR。 | 待 Draft PR。 |

## Blockers

獨立驗證與成果審查完成，無已知產品阻擋。

## 驗收與本機證據

| 證據 | 狀態與記錄位置 |
| --- | --- |
| FV01–FV04 | 在基線 `41fdb0e` 加本題差異驗證。認證拒絕 red 因入口暫回 `.unavailable` 而失敗，接入來源後 green。11 項 Files Viewed 測試通過。依計畫篩選的 Swift 回歸為 505 tests／54 suites，退出 0。Swift format、SwiftLint（603 檔零違規）及 `git diff --check` 皆退出 0。Apollo 2.1.2 離線重生基線逐檔一致，本題重生保留既有四項 query，新增 Files Viewed query，差異為五個新產碼檔與兩筆型別註冊。 |
| Archify | 本機 `.build/topic-evidence/pr-reader-github-files-viewed-source/archify/files-viewed.html`。Showcase 9/9，零錯誤及警告。四種桌面尺寸 containment 通過，目視最小與最大尺寸的亮暗畫面。規格 SHA-256 `4e2e8513e20015f569636801854b377c39726f725a69413f82d7d4587b73b484`，HTML SHA-256 `689d46d4b8578f2b161b44b6360eb05f8831f738d8e0079bbf61238ea85b1741`。 |
| PR Lens | 排入 FV-S06，以最終 base／head 產出本機證據。 |
| Graphify | 確認固定 0.9.73 可執行。feature worktree 與 dev worktree 未找到既有圖，依 skill 以 `rg` 和原碼核對新 query、Reader 分頁、`GitHubGraphQLServing` 與 Apollo config。 |
| Show Me | 見下方呼叫樹。 |
| Floorplan | 本機 `floorplan/index.html`。Chrome 預覽已核對，Recent work 標示本題三張卡。608/608 檔與 62/62 模組有說明。Health 高嚴重度 0 項，端點登入檢查未覆蓋。可重生的 Apollo 產碼卡片已隱藏。 |

### Show Me

    fetchFilesViewed(for:)
      驗證 PR 識別與取消狀態
      讀取檔案頁
        查詢指定 PR 與有效的續頁游標
        核對 repository、PR、head 與總數
        依來源順序累積檔案並保留 viewed 三態
      交付完整清單或單一 PRReaderFailure

## Human Check

Human 已確認本計畫及獨立 feature worktree 實作。提交、推送與建立 Draft PR 的授權條件見執行計畫。實作、驗證或獨立審查若有重大問題，或 staged diff 超出 topic 語意邊界，停在提交前。Draft PR 建立並讀回後交 Human Review。
