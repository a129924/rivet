# GitHub OAuth Endpoint 實例化步驟帳本

最後更新 2026-11-24。基線為 `dev` 的 `c389454`。執行分支為 `refactor/github-oauth-endpoint-instances`。目前 phase 為交付，當前步驟為 P06。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Verdict |
| --- | --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 四份同 slug 文件記錄核准的範圍、技術決策、驗收與授權。 | 本 topic 的 requirements、technical spec、plan 及本帳本已落地。對話版計畫已由使用者確認。 | — |
| P02 | approved | Plan-Reviewer | 獨立審查正式四檔、精確九欄、TC1 至 TC5、工具證據及停點。 | 獨立 Plan-Reviewer 核對四檔、基線、精確路徑、TC1 至 TC5 及條件式交付授權，無必修項。 | approved |
| P03 | completed | Implementer | 在 P02 核准後完成兩個實例、三處接線、測試及唯一長期回寫。 | 已完成三處接線及相容性測試。實例測試先因新型別尚未定義而編譯失敗。實作後受限 SwiftPM 89 項、10 suites 通過，Swift 嚴格格式、專案 SwiftLint 及 diff check 通過。交 Tester 獨立驗證。 | — |
| P04 | completed | Tester | 依計畫獨立驗證 TC1 至 TC5，核對限定差異與本機審閱證據。 | 獨立 Tester 親跑 TC1 至 TC5，89 項、10 suites 全數通過。Swift 嚴格格式、專案 SwiftLint（188 檔、零違規）及 diff check 均 exit 0。差異為八個既有檔案與四份新增規劃文件。 | — |
| P05 | approved | Reviewer | 獨立審查程式、文件、驗證結果與 scope，明示 verdict。 | 獨立 Reviewer 核對三處只替換 URL 來源、共用 token 實例、TC1 至 TC5、架構回寫及本機工具證據，無重大或必修發現。 | approved |
| P06 | in-progress | Implementer | 獨立驗證與審查無重大問題，且 staged diff 為單一語意 topic 時，核對提交訊息並完成單一 commit、push 與 Draft PR。 | 完整 staged diff 符合十二檔 allowlist，為單一語意 topic，diff check 通過。建議訊息「refactor(github-integration): 實例化 OAuth 固定端點」。提交雜湊、Draft PR、遠端讀回及提交後工具證據列於交付回報。 | — |
| P07 | pending | Human | 審閱 Draft PR 與有限驗收證據。 | 待 Human review。 | — |

## Blockers

目前無已確認的阻塞。

## 本機工具證據

- Show Me 隨對話計畫提供 call tree。
- Archify 產出本機繁中 sequence，showcase 9/9、零錯誤與警告，已取得交付收據。四種桌面尺寸均通過頁面尺寸檢查，並已查看明暗截圖。Viewer 為英文。
- Graphify 0.9.73 未找到對應版本的既有圖。以限定原始碼搜尋確認三個呼叫點與共用 token 實例。
- Floorplan 以獨立副本刷新，涵蓋 551 個程式檔，四張本題卡片列於 Recent work，本機瀏覽器已開啟。掃描未辨識兩個實驗工具的伺服器路由，該項登入檢查無可用證據。
- PR Lens 需本題提交後的實際 base／head 差異，收據列於交付回報。

## Human Check

使用者已明確授權在獨立驗證與審查無重大問題、完整 staged diff 範圍相符且語意單一時，直接提交一個 topic commit、推送分支並開立以 `dev` 為目標的 Draft PR。若需要變更約定路徑、OAuth 安全行為、公開 API 或標頭契約，或有重大問題及混入其他變更，在提交前交還 Human。條件成立時在 Draft PR 開立並讀回後停下等 Human review。
