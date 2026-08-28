---
name: plan-step-tracker
description: 檢查正式 topic `.step.md` 的結構、必要欄位與狀態完整性；不完成步驟、不產生 verdict 或放行流程。
---

# Step Ledger 檢查器

只檢查同 slug `plan/<topic>/<topic>.step.md` 是否符合 `$sdd-workflow-contract` 的 topic artifact contract。這是 execution ledger 的結構檢查，不是 planning review、測試或 approval。

## 檢查項目

- 文件包含 Topic 與目前 phase。
- 每個 step 都有 ID、status、owner role、完成條件與驗證證據。
- 文件包含 Blockers、Human Check 與最後更新資訊。
- 每個必要欄位都有可讀取的值；缺少欄位或驗證證據時，回報該 artifact 不完整。

## 邊界

- 不修改、勾選、完成或新增 step；不自行補齊缺漏欄位。
- 不判斷 status 是否由 evidence 支持，亦不判斷 evidence 的真實性、充分性或完成條件是否已達成。
- 不產生、推導或變更 verdict；不將 checkbox、status 或完整性檢查視為 approval。
- 不取代 Tester、Plan-Reviewer 或 Reviewer，且不讓 Observer/Dispatcher 自動放行。
- 不實作、不審查其他 artifacts、不執行 Git、commit、push、tag 或外部動作。
