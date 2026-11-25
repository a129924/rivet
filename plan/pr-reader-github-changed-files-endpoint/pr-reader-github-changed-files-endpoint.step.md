# PR Reader GitHub 變更檔案端點步驟帳本

最後更新 2026-11-25。當前 phase 為交付。執行基線為 `dev` `47e4b45983df38ee9a5e2784cf7aceb25a75b2f9`，分支為 `feat/pr-reader-github-changed-files-endpoint`。當前步驟為 CF-S07，獨立成果審查已核准。

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| CF-S01 | completed | Implementer | 核對執行基線並建立獨立 feature worktree。 | 派遣交接已確認分支與基線。#84 詳情端點、端點測試及 `GitHubRESTDestination` 與原基線無差異。 |
| CF-S02 | completed | Plan-Creator | 建立四份同 slug 正式規劃文件。 | `requirements.md`、`technical-spec.md`、`.plan.md`、`.step.md` 已寫入 feature worktree。 |
| CF-S03 | approved | Plan-Reviewer | 獨立審查四檔、九欄、檔案範圍、介面和驗收。 | 獨立 verdict 為 `approved`，無須修正事項。 |
| CF-S04 | completed | Implementer | 依核准計畫完成兩個 Swift 新增檔及本機交接產物。 | Swift TDD 的 red 在新增端點前因找不到型別而失敗。新增端點後，Reader GitHub 測試 20 項通過。 |
| CF-S05 | completed | Tester | 驗證 CF01–CF03 及本機交接證據。 | 獨立 Tester 驗證 CF01–CF03 通過。Swift Testing 共 20 項、3 組。格式及 SwiftLint 為 exit 0，SwiftLint 192 檔、零違規。六個新檔逐一通過空白檢查。 |
| CF-S06 | approved | Reviewer | 獨立審查實際實作、驗收及範圍。 | 獨立 verdict 為 `approved`，六個新增檔皆在範圍內，無須修正事項。 |
| CF-S07 | in-progress | Implementer | Human 授權條件成立時核對 staged diff、提交、推送並開啟 Draft PR。 | 核對六個新增檔及單一 topic commit 邊界。提交與 PR 資訊於交付後讀回。 |
| CF-S08 | pending | Human | 審閱 Draft PR。 | 待 Human Review。 |

## Blockers

目前無已知阻礙。首次 SwiftLint 指出新增的測試 suite 名稱過長，縮短名稱後重跑通過。

## 本機交接

- Graphify 0.9.73 已核對。工作樹沒有可用的同版圖，以原碼核對新端點、#84 詳情端點及共用目的地 builder 的呼叫關係。
- Archify sequence 通過 showcase 9/9，零錯誤、零警告。四種桌面尺寸均未溢出，已目視核對最小亮色及最大暗色；圖與驗證 receipt 留在 ignored `.build/topic-evidence/pr-reader-github-changed-files-endpoint/archify/`。
- Show Me 呼叫樹與實作相符。初始化保存同一 PR 識別，每次 `makeURL(page:)` 先驗頁碼，沿用 #84 驗證 PR 後組裝 `/files` URL。
- Floorplan 已重建至 561/561 個程式檔有描述，Recent work 標示本次兩檔，已開啟本機預覽。
- PR Lens 以實際提交內容製作，隨 Draft PR 的交付證據讀回。

## Human Check

已授權的交付範圍止於以 `dev` 為 base 的 Draft PR。若有重大問題、驗證未通過、獨立審查未放行或 staged diff 超出範圍，停止於提交前並回報。Draft PR 讀回後停在 Human Review。

[執行計畫](pr-reader-github-changed-files-endpoint.plan.md)
