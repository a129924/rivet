# 整體 Review 送出步驟帳本

目前 phase 為交付。規劃基線 `a559f7a69f2f`，分支 `feat/github-pull-request-review-submission`。

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 同一 slug 四份規劃文件齊備。 | 四份規劃文件已建立。 |
| P02 | approved | Plan-Reviewer | 審查範圍、九欄、驗收與風險。 | 獨立 Plan-Reviewer 核准，無必修項目。 |
| I01 | completed | Implementer | 交付送出 target、受控測試與 Catalog。 | 套件內 target、受控測試、target graph 與 Catalog 已更新。 |
| T01 | completed | Tester | 完成受控驗收及靜態檢查。 | 獨立 Tester 完成 TC01–TC05。74 項測試、5 個 suites、格式、SwiftLint 605 檔零違規、diff 檢查均通過。TDD 起始測試的四個案例按預期因未實作而失敗。 |
| R01 | approved | Reviewer | 獨立核對實作、證據與變更邊界。 | 獨立成果 Reviewer 核准，無必修項目。 |
| D01 | completed | Implementer | 依授權提交單一 topic commit、推送且讀回 Draft PR。 | 初次提交 `656b0e8` 已推送並讀回 Draft PR #108。 |

## PR #108 修正

2026-11-27 依使用者確認拆分 GitHub Review Endpoint 與送出 Source。新增獨立 Endpoint 測試，並重驗 Source 的請求專用 Content-Type、取消邊界與現有 client 的 401 復原上限。Endpoint 測試先因型別尚未建立而編譯失敗。實作後，相關 6 個 suites 共 77 項測試通過，Swift 格式、SwiftLint 607 檔零違規與 diff 檢查通過。

## PR #108 第二次修正

使用者確認加入 `.standardRESTWithJSONBody`、將成功狀態 200 置於 Endpoint，並把非成功 HTTP 回應交共用分類器。422 的新技術分類保留既有 Reader 與 Inbox 結果。測試先因缺少 preset 等型別成員而編譯失敗。實作後，15 個 suites 共 199 項測試通過，包含 200 無收據、取消、401 復原、明確拒絕及 5xx／未知狀態。Swift 格式、SwiftLint 607 檔零違規與 diff 檢查通過。

## 初次交付的本機檢閱證據

- Archify showcase 9/9、零錯誤及警告，四尺寸 containment 和明暗主題目視通過。Viewer 採英文。HTML SHA-256 為 `c2b21d342cdcc95ff2ab11d1e8ca44b455a0b403962605355fbd2675fe8410eb`。
- Floorplan 已 build 並開啟本機預覽，Recent work 標示三張卡。兩份新 Swift 檔皆有說明。沿用舊 map 的其餘描述，工具回報部分既有檔仍缺說明。
- Graphify 0.9.73 檢查時沒有可查詢的圖。從 manifest、adapter 與既有 REST client 核對依賴與 401 邊界。
- PR Lens 以提交後的實際 diff 驗證及渲染，結果併入本機交付收據。

## Blockers

目前無。

## Human Check

Draft PR 交付後由使用者審閱。真人遠端 Review 送出須另行指定。

最後更新 2026-11-27。 [執行計畫](github-pull-request-review-submission.plan.md)
