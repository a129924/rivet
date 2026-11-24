# GitHub REST 回應分類 Phase A 步驟

最後更新：2026-11-24，Swift 成果已通過獨立驗證與審查，進入交付。

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| A01 | completed | Plan-Creator | 四份同 slug 文件落地 | 本 topic requirements、technical-spec、plan 與 step。 |
| A02 | approved | Plan-Reviewer | 獨立審查四檔及九欄範圍 | 首輪要求記錄提交前檢查點。修訂後獨立複審 approved，無待修正項目。 |
| A03 | completed | Implementer | 完成 classifier、單元測試與精確靜態隔離 | REST／Inbox baseline 22 tests、2 suites 通過。Red：尚無分類時，狀態碼案例產生 5 項預期不符。Green：分類器 8 tests、52 組合成案例通過。 |
| A04 | completed | Tester | 執行 TC01–TC09 | 獨立重跑根目錄 397 tests、52 suites 及 consumer 22 tests、6 suites 全數通過。Strict format、正式 strict lint（180 檔零違規）、diff check 通過。來源掃描只見分類器定義，production 無呼叫。 |
| A05 | approved | Reviewer | 獨立審查產品、證據與範圍 | 403 完整句、衝突 fixtures、status 行為、internal 可見性及 exact scope 符合規格，無待修正項目。 |
| A06 | in-progress | Implementer | 回寫經驗證設計，依授權提交、推送並開 Draft PR | 架構已回寫。單一 topic 的建議訊息為 `feat(github-integration): 新增內部 REST 回應分類`。PR 與 PR Lens 依真實 commit 及遠端結果交付。 |

## Blockers

目前無已知需使用者決策的 blocker。

## 驗證差異

- 首輪根目錄測試在既有 `OAuthLocalSignOutTests.startedSaveSettlesBeforeDelete` 有兩項時序斷言失敗。該測試單獨重跑與完整重跑均通過，該實作及測試檔皆未改。
- 全目錄 `swiftlint lint --strict` 回傳 2，511 項違規位於 62 個未改的實驗／原型檔案。專案正式 `scripts/check-swiftlint.sh` 的 strict lint 範圍回傳 0，掃描 180 檔、零違規。

## 本機審閱

- Archify workflow 的 showcase 9 項檢查通過、0 錯誤及 0 警告。4 個桌面尺寸通過 containment，自動收據的人工視覺欄位仍為 pending。
- Floorplan 本機更新，題目兩個 Swift 檔已在 Recent Work 標記。538 個程式檔都有說明。
- Graphify 0.9.73 可用。兩個 worktree 均無既有圖，改以來源與精確 diff 查證。
- PR Lens 待 commit 後使用真實 base／head 產生本機資料，與 GitHub Draft PR 分開交付。

## Human Check

使用者已就「實作無重大問題時直接按 topic 提交、推送及開 Draft PR」作明確事前確認。提交前記錄 staged diff 的單一語意邊界及建議 message。條件不成立時停在提交前，Draft PR 交付後停在使用者審閱。Phase A 狀態以已取得的實作／驗證證據為準。
