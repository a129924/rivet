# PR Inbox 靜態視覺原型：Step Ledger

## Current Phase

Human Check（HC-01 pending；先完成已授權 commit／push delivery）

## Scope Register

- Goal：建立單一離線自包含、固定深色的 PR Inbox 桌面 HTML 視覺原型，供 Human 決定是否採用後續 SwiftUI 方向。
- Non-Goal：SwiftUI、產品功能、domain behavior、GitHub／PR Reader 能力、真實資料、真實互動、mobile／iPad、雙主題與完整 accessibility 驗證。
- In-Scope：單一 HTML、內嵌 CSS、深色 macOS 桌面版面、Inbox sidebar、6 筆虛構 PR、第二列唯一 selection、獨立空 Inbox frame、1440px 與 1024px 驗收。
- Out-Of-Scope：JavaScript、外部資源、套件、build step、server、network、GitHub API、authentication、cache、refresh、error handling、PR 詳情、diff、checks、discussion、通知、review 寫入及任何產品程式碼。
- ReadOnly：`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`，以及 PR-02 明示 `approved` 後的本 topic 四份 planning artifacts；所有其他 tracked paths 保持不變。
- Written：僅 `prototypes/pr-inbox-static-visual-prototype/index.html`。四份本 topic artifacts 是 PC-01 的 planning output，不屬於 IM-01 allowlist。
- Deleted：無。
- Modify：首次 implementation 無。若 RV-01 明示 `needs-rework`，後續 Implementer 仍只能修改同一個 `index.html`；需要其他變更時返回 planning。
- Architecture：不新增或修改 public API、Swift target、Domain model、Port、Facade、Event、Message、Cross-BC contract 或 `docs/architecture/`；selection 僅屬 Presentation Session fixture。

## TestCase

| ID | Verification | Expected evidence |
| --- | --- | --- |
| TC-01 | Implementation allowlist | 以四份本 topic artifacts 取得獨立 Plan-Reviewer 明示 `approved` 後的 implementation baseline 為差異基準；IM-01 change set 只能新增指定 `index.html`。四份 artifacts 不計入 Implementer diff 且保持不變，其他檔案無新增、修改或刪除。 |
| TC-02 | Offline self-contained | HTML 透過 `file://` 開啟，無 JavaScript、外部 stylesheet／font／image、網路 URL、套件、build step 或 local server。 |
| TC-03 | Fixed dark theme | 僅有固定深色主題、深灰表面、可讀淺色文字與節制藍色 accent；沒有 theme switcher 或淺色變體。 |
| TC-04 | Desktop 1440 | 1440px 完整呈現 sidebar 與所有 PR 欄位，資訊層級清楚且清單是主要焦點。 |
| TC-05 | Desktop 1024 | 1024px 無水平 overflow；sidebar 縮窄、摘要隱藏、每列只保留第一個標籤、作者與時間位於單行，標題與 repository 保持可辨識。 |
| TC-06 | Selection ownership | 恰好 6 筆 PR 且只有第二列具選取樣式；selection 明示為 Presentation Session fixture，不屬於 PR Inbox domain，無點擊、切換或持久化。 |
| TC-07 | Empty state | 主要工作台下方有獨立標示的空 Inbox frame，保留相同深色版面骨架與 sidebar、顯示計數 0 與空狀態文案，且不混入清單。 |
| TC-08 | Capability boundary | 畫面不含或暗示 PR Reader、`GithubIntegration`、登入、authentication、refresh、network、PR 詳情、diff、checks、discussion、通知或 review 寫入能力。 |
| TC-09 | Fictional fixtures | 6 筆 fixture 全部明顯虛構，涵蓋多個 repository、作者、相對時間、0–2 個標籤與摘要狀態，不含真實帳號或 PR 資料。 |

## Ledger

| ID | Status | Owner role | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立四份同 slug 正式 artifacts，記錄 locked visual scope、HTML Implementation Contract、TC-01 至 TC-09、workflow 與 Human boundary。 | requirements、technical spec、plan 與 step 四份 artifacts 均已寫入且使用同一 slug。 | 2026-09-11 已建立四份本 topic artifacts；此狀態只表示寫入完成，不構成 PR-01 approval。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查四份 artifacts 的一致性、scope、desktop visual contract、ownership boundary、implementation allowlist、TestCase 與停止條件。 | Plan-Reviewer 提供明示 verdict。 | 已收到 `needs-rework`：四份 artifacts 必須一致鎖定只有 RV-01 `approved` 可進入 HC-01；RV-01 `needs-rework` 回交 Implementer，`blocked`／`human-check` 停止並交還 Human，不得視為成果核准或方向決策。 |
| PC-02 | completed | Plan-Creator | 只校正 PR-01 required fix，使四份 artifacts 的 RV-01 routing 與 HC-01 entry condition 一致；不修改 scope、TestCase 或 allowlist。 | 四份 artifacts 均明示相同 routing，且未實作 prototype 或修改 allowlist 外 path。 | 2026-09-11 已完成 artifact-only rework；此狀態不構成 PR-02 approval。 |
| PR-02 | completed | Plan-Reviewer | 獨立審查 PC-02 correction 與四份 artifacts 的一致性，不重新開啟其他 locked decisions。 | Plan-Reviewer 提供明示 verdict。 | 已收到新的獨立 Plan-Reviewer 明示 `approved`；以本次核准的四份 artifacts 建立 TC-01 implementation baseline。此 evidence 不將 PC-02 status 或 ledger 視為 approval。 |
| IM-01 | completed | Implementer | 僅在 PR-02 明示 `approved` 後，依 HTML Implementation Contract 新增唯一 prototype output。 | change set 只新增指定 `index.html`，並完成 TC-01 至 TC-09 所需 behavior；沒有未授權 path 變更。 | Implementer 已明示完成；唯一新增 `prototypes/pr-inbox-static-visual-prototype/index.html`。handoff evidence 摘要涵蓋 TC-01 allowlist、TC-02 offline self-contained、TC-03 fixed dark、TC-04 1440px、TC-05 1024px／no overflow、TC-06 selection ownership、TC-07 empty state、TC-08 capability boundary 與 TC-09 fictional fixtures。 |
| TE-01 | completed | Tester | 獨立執行 TC-01 至 TC-09 的 scope、static、file-open 與 1440px／1024px visual checks。 | 每一 testcase 均有明示結果、evidence 或 blocker。 | 已收到 Tester 明示 `approved`；真實 Chrome 1440px／1024px 驗證，以及 offline、overflow、console、network 與 allowlist checks 均通過。 |
| RV-01 | completed | Reviewer | 獨立審查 IM-01 scope、prototype 與 TE-01 evidence。 | Reviewer 提供明示 verdict；只有 `approved` 前進 HC-01，`needs-rework` 回交 Implementer，`blocked`／`human-check` 停止並交還 Human。 | 已收到 Reviewer 明示 `approved`；findings：none。 |
| HC-01 | pending | Human | 僅在 RV-01 明示 `approved` 後，依原型與 Reviewer 結果決定視覺方向。 | Human 明示「採用」、「調整」或「放棄」。 | RV-01 已明示 `approved`；先完成已授權 commit／push delivery，再交由 Human 選擇「採用」、「調整」或「放棄」。不得由 agent 自行跨越。 |

## Blockers

- 無已知 blocker。既有 `pr-inbox-swift-contract-baseline` correction 已取得其獨立 Plan-Reviewer 明示 `approved`，只代表新 topic prerequisite 已完成，不構成本 topic approval。
- PR-02、IM-01、TE-01 與 RV-01 均已完成；已授權 commit／push delivery 尚待執行，屬 HC-01 前置交付步驟，不是 blocker。

## Human Check

- TE-01 已完成且獨立 RV-01 已明示 `approved`；完成已授權 commit／push delivery 後交由 Human 進行 HC-01，並停止所有自動前進。
- RV-01 `needs-rework` 只回交對應 Implementer；`blocked`／`human-check` 停止並交還 Human。這些 verdict 不得視為成果核准或進入 HC-01 的方向決策。
- 「採用」只允許另開正式 SwiftUI topic 進行規劃，不自動開始 SwiftUI implementation。
- 「調整」回到本 topic 的 planning／implementation／verification flow；若調整超出既定 HTML scope，必須先更新 artifacts 並重新經 Plan-Reviewer 審查。
- 「放棄」結束此視覺方向，不建立替代產品功能。

## Last Updated

2026-09-11
