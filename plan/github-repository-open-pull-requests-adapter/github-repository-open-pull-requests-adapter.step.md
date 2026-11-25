# 指定 repository 的完整 open PR 清單步驟

最後更新 2026-11-25，由執行協作者記錄。執行基線 `dev` `d8e2ffed24c64da728cfb394da8d5a521b03642d`，分支 `feat/github-repository-open-pull-requests-adapter`。目前為發布，當前步驟 P06。Human 已確認對話計畫及執行授權。正式規劃審查 verdict 為 `approved`。

| ID | Status | Owner | 完成條件 | 驗證證據 |
|---|---|---|---|---|
| P01 | completed | Plan-Creator | 在獨立 feature worktree 建立四件同 slug 的正式規劃文件。 | 本 topic 的 requirements、technical-spec、plan 與 step 已寫入。 |
| P02 | approved | Plan-Reviewer | 獨立讀回四件文件，核對已確認的契約、九欄、TC01–TC05、工具交接、授權與停點，回報明示 verdict。 | 獨立 Plan-Reviewer 已讀回正式四件文件，明示 `approved`，無必修項目。 |
| P03 | completed | Implementer | P02 明示 `approved` 後，依受限契約新增 query、測試和 Catalog 記錄，完成本機工具交接並回報待驗範圍。 | Implementer 交付 query、測試與 Catalog。正式入口未實作時 SwiftPM exit 1，完成後聚焦 16 tests／2 suites 通過。Archify、PR Lens 與 Floorplan 本機交接可供查核。 |
| P04 | completed | Tester | 獨立執行 TC01–TC05，核對本機工具證據與具體限制。 | 獨立 Tester 在 Swift 6.3.3 執行六項命令皆 exit 0。聚焦 16 tests／2 suites、隔離 48／3、回歸 438／57，SwiftLint 194 檔零違規，格式與 diff 檢查通過。 |
| P05 | approved | Reviewer | 獨立核對成果、驗收證據、範圍與發布條件，回報明示 verdict。 | 獨立 Reviewer 明示 `approved`，核對七個允許路徑、H1–H3、TC01–TC05 與成果邊界，無必修項目。 |
| P06 | in-progress | Implementer | 審查及驗證符合發布條件，完成 staged diff 檢查、單一 topic commit、push、開 Draft PR 至 `dev`，讀回遠端結果。 | 已進入提交前 staged diff 核對。建議訊息 `feat(repository-pr): 新增完整 open PR 清單查詢`。commit、push 與 Draft PR 的讀回證據由本機交付收據記錄。 |
| P07 | pending | Human | 審閱 Draft PR。 | 待 P06 交接。 |

## 本機驗證證據

- Archify showcase 9/9、零錯誤與警告，deliver 與四尺寸 visual-check 均 exit 0。已核對四張明暗擷圖，HTML SHA-256 為 `962ceabdfa07fa8b11f7f256bc5524e1aaf5d5cf74563cb298261b0b111a4881`。
- PR Lens 0.11.0 以實際 base 與 worktree HEAD `d8e2ffed` 記錄未提交差異，涵蓋本 topic 七個路徑。local validate、render 成功，產出 manifest 與 1 份 SVG。
- Graphify 0.9.73 已核對版本。兩個 worktree 都缺少圖檔，改以受限原始碼查證。
- Floorplan 從既有圖更新，563 檔與 64 節點，topic 四張檔案卡片具描述，本機預覽 HTTP 200。其他 23 檔的缺少描述與一筆待複核來自既有地圖的基線差異。Health 無高嚴重項目，既有驗證工具內的 server endpoint 登入檢查未覆蓋。

## Blockers

目前無已知 blocker。

## Human Check

已確認的授權包含在獨立 feature worktree 實現，且在驗證、成果審查及 staged diff 符合計畫時，直接執行單一 topic commit、push、開 Draft PR 至 `dev`。若範圍或已確認契約需要調整，或發布條件未滿足，交 Human 決策。Draft PR 已建立且完成讀回後，停於 Human Review。

[執行計畫](github-repository-open-pull-requests-adapter.plan.md)
