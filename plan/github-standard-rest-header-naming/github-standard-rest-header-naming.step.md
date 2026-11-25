# 標準 REST 標頭命名步驟帳本

最後更新 2026-11-25。基線 `dev` `7a283f8dbf1f6c1d84e5b1013c8f7663c5abb500`，執行分支 `refactor/github-standard-rest-header-naming`。目前 phase 為交付，N06 進行中。

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| N01 | completed | Plan-Creator | 在獨立 worktree 建立四份同 slug 正式文件，含九欄契約。 | 需求、技術規格、本計畫與步驟帳本已落地。 |
| N02 | approved | Plan-Reviewer | 獨立審查四檔、相容性與路徑範圍，記錄明示 verdict。 | 獨立審查查獲 overlay 缺少時的分支，Plan-Creator 回修後重審 approved，無必修項。 |
| N03 | completed | Implementer | 完成兩份 Swift 的內部更名與長期文件回寫，提供限定 diff 與待驗證範圍。 | 兩份 Swift 的標準組合命名與固定標頭契約一節完成。 |
| N04 | completed | Tester | 執行基線與 topic 離線測試及 diff 檢查，另記本機工具驗證。 | Swift 6.3.3 下基線與 feature 各 60 項測試、7 個 suites 通過，通過清單一致。差異檢查與兩個 Swift 檔的嚴格格式檢查皆 exit 0。 |
| N05 | approved | Reviewer | 獨立審查受限差異及驗收證據，回報 verdict。 | 獨立審查確認七個路徑符合範圍，程式差異限內部命名，測試證據齊備，無必修項。 |
| N06 | in-progress | Implementer | 條件符合時在提交前記錄 staged diff 語意邊界及建議訊息，完成一次 commit、推送及 Draft PR，讀回遠端狀態。 | 建議訊息為「refactor(github-integration): 對齊標準 REST 標頭命名」。實際提交、Draft PR 與遠端讀回見交付回報。 |
| N07 | pending | Human | 審閱 Draft PR 與證據。 | 待交付。 |

## Blockers

目前無已知阻塞。

## 本機工具狀態

Show Me 的預期差異已比對兩份 Swift。Graphify 0.9.73 已核，缺少標準 graph，已用限定原始碼搜尋驗證 Factory 與 Inbox、Reader 的引用。Floorplan 副本建置 551/551 個檔案描述、標記 2 張 topic 卡片，並開啟本機預覽。Archify sequence 的 showcase 9/9、零錯誤與警告，四種桌面尺寸皆通過，最小與最大尺寸的明暗截圖皆已目視。PR Lens 0.11.0 將使用實際 topic commit 與交付基線產圖。

## Human Check

人類已確認受限實作及條件式提交、推送與 Draft PR 授權。N06 先檢查條件，若有重大問題、無法驗收、範圍混入或需拆分，停在提交前交還 Human。符合條件則在 Draft PR 交付後停止，等待 Human review。
