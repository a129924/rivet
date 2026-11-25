# PR Reader GitHub 一般討論留言端點步驟帳本

最後更新 2026-11-25。當前 phase 為交付，當前步驟為 CC-S07。執行基線為 `dev` `d8e2ffed24c64da728cfb394da8d5a521b03642d`，分支為 `feat/pr-reader-github-conversation-comments-endpoint`。

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| CC-S01 | completed | Implementer | 核對執行基線並建立獨立 feature worktree。 | 派遣確認工作樹已建立。Plan-Creator 進入該工作樹前核對分支與 HEAD，規劃寫入前工作樹乾淨。 |
| CC-S02 | completed | Plan-Creator | 寫入並讀回四份同 slug 正式規劃文件。 | 四份文件寫入 feature worktree，供獨立規劃審查。 |
| CC-S03 | approved | Plan-Reviewer | 獨立審查四檔、九欄、路徑範圍、介面、驗收與交付條件，回報明示 verdict。 | 獨立 Plan-Reviewer 已審查四份實際文件，明示 approved，無須修正事項。 |
| CC-S04 | completed | Implementer | 依核准計畫完成端點、測試、窄幅共用識別驗證、BC 文件與本機交接產物。 | Swift TDD red 因找不到新增端點型別而失敗。實作後 25 項 Reader GitHub 測試通過。端點、測試、共用驗證與 BC 文件完成。 |
| CC-S05 | completed | Tester | 驗證 CC01–CC03 與五項本機交接證據。 | 獨立 Tester 通過 CC01–CC03，25 項測試、4 組。Swift 格式與 SwiftLint 通過，SwiftLint 194 檔、零違規。八檔的空白與範圍檢查通過。五項本機交接已覆核。 |
| CC-S06 | approved | Reviewer | 獨立審查實際實作、驗收與範圍，回報明示 verdict。 | 獨立 Reviewer 明示 approved，八檔符合九欄契約，無須修正事項。 |
| CC-S07 | in-progress | Implementer | Human 授權條件成立時，核對 staged diff 與 commit message，單一 commit、推送並建立以 `dev` 為 base 的 Draft PR。 | 核對單一語意提交，訊息為 `feat(pr-reader): 新增 GitHub PR 一般討論留言端點`。交付後讀回實際 commit 與 PR。 |
| CC-S08 | pending | Human | 審閱 Draft PR。 | 待 Human Review。 |

## Blockers

目前無已知交付阻礙。首次 commit hook 的 renderer 檢查缺少 Biome。已在 feature worktree 依既有 lockfile 安裝依賴，renderer 檢查通過。

## 本機交接

- Graphify 0.9.73 已核對，專用 worktree 無可用圖，已直接核對端點與共用建址原碼。
- Archify sequence 通過 showcase 9/9，零錯誤與警告。四個桌面尺寸通過，獨立 Tester 已核對最小亮色及最大暗色。HTML SHA-256 前綴為 `1fa54b4a4971`。
- Show Me 的同步呼叫樹已與實作對照。
- Floorplan 描述覆蓋 563/563、零未指派檔案，Recent work 標示兩張卡，本機預覽讀回 HTTP 200。
- PR Lens 0.11.0 以暫存的八檔 topic diff validate／render，獨立 Tester 已核對原碼、SVG 與 manifest。交付時用實際 base、head 與 Draft PR 更新來源。

## Human Check

Human 已核准 endpoint-only 計畫與條件式交付。若驗證未通過、獨立審查未放行、發現重大問題或 staged diff 超出範圍，停在提交前回報。Draft PR 建立並讀回後停在 Human Review。

[執行計畫](pr-reader-github-conversation-comments-endpoint.plan.md)
