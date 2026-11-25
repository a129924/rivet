# 指定 repository 的 open PR Endpoint 步驟

最後更新 2026-11-25，由 Implementer 記錄。基線 `dev` `7a283f8dbf1f6c1d84e5b1013c8f7663c5abb500`，執行分支 `feat/github-repository-open-pull-requests-endpoint`。使用者已確認 Endpoint-only 計畫，並已授權在 feature worktree 內執行。目前為交付階段，當前步驟 P06。

| ID | Status | Owner | 完成條件 | 驗證證據 |
|---|---|---|---|---|
| P01 | completed | Plan-Creator | 同 slug 四份正式規劃文件均落地 | 本 topic 的 requirements、technical-spec、plan 與 step 已在 feature worktree 建立。 |
| P02 | approved | Plan-Reviewer | 獨立核對四份文件、九欄、鎖定契約、驗收、授權與停點，回報明示 verdict | 獨立 Plan-Reviewer 讀回四份文件，明示 `approved`，無必修項。 |
| P03 | completed | Implementer | P02 明示 `approved` 後完成 Endpoint、兩個 targets、測試、Catalog 與本機交接 | 確認新型別尚未定義時測試編譯失敗，加入 Endpoint、targets、測試及 Catalog 後通過。Archify showcase 9/9、零錯誤與警告、四種桌面尺寸及目視核對通過。Floorplan 建置完成並標記兩張卡片。Graphify 0.9.73 缺少對應 graph，改由原始碼確認依賴。 |
| P04 | completed | Tester | 獨立執行 TC01–TC04 並核對本機工具證據及限制 | 獨立 Tester 重驗 TC01–TC04。Endpoint 3 項、隔離 48 項、回歸 420 項均通過，Swift 格式與 diff 檢查通過，SwiftLint 檢查 190 檔零違規。 |
| P05 | approved | Reviewer | 獨立審查變更、驗證結果、範圍與發布條件，回報明示 verdict | 獨立 Reviewer 核對九個檔案、Endpoint 契約、套件隔離與驗證結果，明示 `approved`，無必修項。 |
| P06 | in-progress | Implementer | 成果審查通過、無重大問題且 staged diff 符合授權時完成單一 commit、push、Draft PR 至 `dev`，並讀回遠端狀態 | 成果審查通過，進行暫存差異檢查。PR Lens 將以實際送審 commit 與 PR 差異驗證並渲染。 |
| P07 | pending | Human | 審閱 Draft PR | 待 P06 交接。 |

## Blockers

目前無未解除的 blocker。Headers 是後續 Adapter 的前置，本期 Endpoint 可獨立進行。

## Human Check

若需擴張範圍或調整已確認的技術契約，停下交由 Human 決策。使用者已明示在驗證及審查無重大問題、staged diff 語意單一且範圍符合時，可執行一個 topic commit、推送並開 Draft PR 至 `dev`。若條件不成立，停於提交前；Draft PR 建立及讀回後，停止於 Human Review。
