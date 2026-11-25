# PR Reader 行內審閱留言端點步驟帳本

最後更新 2026-11-25。目前 phase 為交付，目前步驟為 IC-S07。執行基線 `c9c9f17a0d7732574d25a652ce088c65dcefea06`，分支 `feat/pr-reader-github-inline-review-comments-endpoint`。

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| IC-S01 | completed | Planner | 核對 Endpoint-only 規劃準備與基線。 | Planner 回覆規劃準備 `approved`。已讀回獨立 feature worktree 的分支與基線，四檔建立前工作樹乾淨。 |
| IC-S02 | completed | Plan-Creator | 建立四份同 slug 規劃文件。 | 需求、技術規格、執行計畫與本帳本已寫入 feature worktree。 |
| IC-S03 | approved | Plan-Reviewer | 獨立審查四份實際文件、九欄、基線、驗收及五項本機審閱。 | 獨立 Plan-Reviewer 明示 `approved`，無必修項。 |
| IC-S04 | completed | Implementer | 依核准計畫完成端點、離線測試及 BC 契約回寫，提供本機審閱證據。 | 新增測試先由於找不到端點型別而編譯失敗，新增實作後 5 項全過。離線驗收後已回寫 BC。 |
| IC-S05 | completed | Tester | 獨立驗證 IC01–IC03 及五項本機審閱證據。 | 獨立 Tester 重跑 101 項／10 suites 全過。格式、217 檔 SwiftLint 零違規、七路徑與新增檔空白檢查通過。已核對五項本機證據。 |
| IC-S06 | approved | Reviewer | 獨立核對實際差異及證據，逐欄檢查九欄範圍及尚未追蹤的新增檔。 | 獨立 Reviewer 核准端點、離線驗收、五項本機審閱及七路徑差異，無必修項。 |
| IC-S07 | in-progress | Implementer | 條件符合時核對 staged diff，執行一個 topic commit，推送 feature branch，開啟 Draft PR 並讀回。 | 審查已核准，進入暫存差異與交付核對。Draft PR 與實際遠端狀態作為交付證據。 |
| IC-S08 | pending | Human | 審閱 Draft PR。 | 待交付。 |

## Blockers

目前無已知阻礙。

## 本機審閱證據

- Graphify `0.9.73` 已關閉自動更新。兩個工作樹皆無可對應基線的既有圖，已以 `rg` 與原碼確認共用 PR 識別驗證及網址建構。
- Show Me 同步呼叫樹與 IC01、IC02 交叉核對通過，順序為頁碼、PR 識別、URL 建構。
- Archify 交付於 `.build/topic-evidence/pr-reader-github-inline-review-comments-endpoint/archify/inline-review-comments.html`。Showcase 9/9、零錯誤與警告，四種桌面尺寸通過。兩輪修正後目視核對最小與最大尺寸的四張亮暗畫面。
- PR Lens `0.11.0` 已在 repo 外暫存目錄驗證 `worktree.graph.json` 並渲染一張亮色 SVG。圖與 manifest 已對照七個實際路徑及既有相鄰元件，含尚未追蹤的新檔。提交後再以實際 base/head 核對。
- Floorplan 已在 feature worktree 更新並開啟本機預覽，586 個程式檔皆有描述，Recent work 標記本次端點一張卡片。預覽 HTTP 200，圖中可追到既有識別驗證和 URL 建構器。自動檢查無高嚴重度項目，既有實驗工具的端點登入檢查因未辨識路由而略過。

## Human Check

Human 已核准 Endpoint-only 計畫及獨立 feature worktree。驗收與獨立成果審查通過、無重大問題且 staged diff 符合九欄範圍時，已授權一個 topic commit、推送 feature branch 並開啟以 `dev` 為 base 的 Draft PR。Draft PR 讀回後停在 Human Review。

[執行計畫](pr-reader-github-inline-review-comments-endpoint.plan.md)
