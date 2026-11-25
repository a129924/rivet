# PR Reader Background Session 步驟

Topic `pr-reader-background-session-production-adoption`。最後更新 2026-11-25。執行分支 `feat/pr-reader-background-session-production-adoption`，起始基線 `dev` `b0ad6974a33cc53112083eefad60504462593d66`。正式受測基線 `587f7bb91fbe9f056cf72214a9992a1325ffce72`。目前 phase 為交付，當前步驟 S06，完成後交 S07 Human Review。獨立 Plan-Reviewer 於 2026-11-25 明示 S02 approved，必要修正 0。

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 四份同 slug 正式規劃檔落地 | 本 topic 的 requirements、technical-spec、plan 及 step。 |
| S02 | approved | Plan-Reviewer | 獨立核對四檔、九欄、契約、允許範圍、驗收及 Human 邊界 | 獨立 Plan-Reviewer 核對四檔、實際基線、P01–P17、依賴及條件式交付。必要修正 0。 |
| S03 | completed | Implementer | 正式 Session、Port／Facade、adapter 及組裝接入，新增正式測試，同步 Reader BC 與既有架構圖 | Session、正式組裝、Reader BC 及圖面實作完成。受測 Swift 路徑清單 SHA-256 bbdc7b7781feacae555b601d66453e91543de61a9bde8999c86ca10b2257d538。 |
| S04 | completed | Tester | 獨立執行 P01–P17、自取消、組裝、manifest、回歸與相關圖面驗證 | 獨立 Tester 於 587f7bb 加本輪 diff 複驗 517 tests／64 suites 全數通過。SwiftLint 210 檔零違規，格式、diff、Canvas 6 bands／17 boxes／12 edges 皆通過。 |
| S05 | approved | Reviewer | 獨立檢查程式、依賴、原 Task 生命週期、文件、測試及 scope，必要修正結案 | 前次 needs-rework 指出同步 Observation 失效後仍可寫回 loading。已加入實際紅綠回歸，並在通知前完成狀態與 slot 更新，獨立 Reviewer 複審 approved，必要修正 0。 |
| S06 | in-progress | Implementer | 依採用證據完成交付紀錄，核對 staged diff 及建議訊息，按使用者事前授權提交、推送並開 Draft PR | 依授權交付單一 topic commit。建議訊息：feat(pr-reader): 採用背景資料呈現工作階段。提交及 Draft PR 證據由 Git／GitHub 讀回。 |
| S07 | pending | Human | 審閱 Draft PR 與有限採用證據 | 待 Human Review。 |

## Blockers

觀察回呼必要修正已由 Tester 驗證及獨立 Reviewer 核可，目前無未解重大問題。

## 本機工具證據

- Show Me 示意核對至正式 Session。Archify sequence showcase 9 項通過，Chrome 四種尺寸 containment 及最小／最大 light／dark 圖目視通過，HTML SHA-256 be872949989fb105feac04bc15e12e56ad0fcc5570f6235e47b64690eea60bbc。固定 Viewer UI 與 HTML 語言標記採英文。
- Floorplan 套用隔離副本，標示本 topic 三個近期項目，離線瀏覽器檢視。Graphify 0.9.73 可用但缺同版本程式圖，以限定原始碼與 manifest 查證替代。
- PR Lens 0.11.0 在真實 topic commit 後以實際 base／head 產生本機圖。

## Human Check

Human 已批准對話計畫並授權在驗證通過、無重大問題且 staged diff 符合單一 topic 時，作一個 topic commit、推送及開以 dev 為 base 的 Draft PR。提交前依 repo 慣例核對 staged diff 並記錄建議 message。條件不成立停於提交前。已完成交付則讀回遠端狀態並停在 S07。

## 驗證歷史

- 起始骨架選取測試呈現 idle，正式實作後轉為通過。獨立 Reviewer 以實際正式模組重現 Observation 回呼重入，修正前回歸測試顯示 loading；修正後保持 idle。
- 起始基線的一次完整回歸出現既有 OAuth 登出測試時序失敗。該案例單獨重跑通過，同來源完整重跑 499／63 通過。公開交付前同步 PR #94 的 dev 基線，保留同份 Reader BC 文件的留言段落，最終獨立完整驗證 517／64 首次通過。
- 最終 Tester 完整測試紀錄 SHA-256 e178ef4ea89b437e0389f2d132d379f6629e83fc647cb1b88f913e429d2077ed，lint 紀錄 SHA-256 23651dabfba394792169824721ce444512c0a68bdc7e7453a2eb40f2d80bbb9b。
