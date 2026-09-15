# PR Inbox 靜態視覺原型：技術規格

## Locked Decisions

### Delivery Shape

- 唯一 implementation output 是 `prototypes/pr-inbox-static-visual-prototype/index.html`。
- 文件是單一、自包含 HTML；CSS 全部內嵌於文件，不含 JavaScript、外部 stylesheet、font、image、套件、build step、local server 或任何網路資源。
- 原型必須可由本機瀏覽器透過 `file://` 直接開啟；不提供啟動 server 的替代流程。

### Visual and Layout Contract

- 採固定深色 macOS 桌面風格：系統字型、深灰中性色表面、高可讀性的淺色文字，以及節制的藍色 accent；不提供淺色變體或 theme switcher。
- 使用 CSS Grid／Flex 建構 sidebar 與 Inbox 主區。sidebar 只呈現產品識別、`Inbox` 導覽項目與待 review 計數，視覺權重低於主清單。
- 主區顯示清楚的 `Mockup` 標示、Inbox 標題、固定清單與閱讀順序，不顯示產品功能控制項。
- 主要 frame 含恰好 6 筆 PR fixture；第二列是唯一選取列，以較亮深色表面、藍色 accent 邊線及焦點標記呈現。
- 同一頁面在主要工作台下方放置獨立的空 Inbox frame；它保留相同深色版面骨架與 sidebar、顯示計數 0 與簡短空狀態文案，且清楚標示為替代狀態，不混入主要清單。
- 1440px 寬度完整顯示各列標題、repository、作者、相對更新時間、0–2 個標籤與摘要狀態。
- 1024px 寬度縮窄 sidebar、隱藏列摘要、每列只保留第一個標籤，並將作者與更新時間壓縮至單行；標題與 repository 必須持續可辨識，頁面不得產生水平 overflow。
- 低於 1024px、mobile 與 iPad layout 不在設計或驗收範圍。

### Fixture and Ownership Contract

- 6 筆 PR 皆為明顯虛構資料，涵蓋多個虛構 repository、作者、相對時間、標籤與展示用摘要狀態；不得從真實帳號、repository、PR 或使用者資料衍生。
- fixture 順序只服務視覺驗證，不形成 PR Inbox domain sorting rule。
- 第二列 selection 只代表 Presentation Session fixture；它不形成 PR Inbox domain ownership，也不提供點擊、切換或持久化。
- 畫面不得出現或暗示 PR Reader、`GithubIntegration`、authentication、refresh、network、PR 詳情、diff、checks、discussion、通知或 review 寫入能力。

## HTML Implementation Contract

- **Goal**：交付固定深色、完全離線、自包含的 PR Inbox 桌面 HTML 視覺原型，讓 Human 判斷資訊層級、閱讀密度、PR 閱讀順序與選取焦點是否適合後續 SwiftUI 方向。
- **Non-Goal**：不建立正式產品 UI、domain behavior、真實資料流程、GitHub client、PR Reader、review 操作或可持久化互動；原型不構成架構或產品 contract。
- **In-Scope**：單一 HTML、內嵌 CSS、固定深色 macOS 桌面版面、Inbox sidebar、6 筆虛構 PR fixture、第二列唯一選取狀態、獨立空 Inbox frame，以及 1440px／1024px 桌面寬度呈現。
- **Out-Of-Scope**：SwiftUI、Swift Package、產品程式碼、JavaScript、外部資源、build step、local server、GitHub API、authentication、cache、refresh、network/error handling、PR 詳情、diff、checks、discussion、review 寫入、真實或持久化互動、mobile、iPad、雙主題切換與完整 accessibility 驗證。
- **ReadOnly**：HTML Implementer 只以唯讀方式參照 `README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`，以及本 topic 經 PR-02 明示 `approved` 的四份 planning artifacts。所有未列入 `Written`、`Modify` 或 `Deleted` 的 tracked paths 均必須保持不變。
- **Written**：僅可新建 `prototypes/pr-inbox-static-visual-prototype/index.html`。四份 planning artifacts 由 Plan-Creator 在 planning phase 建立，不屬於 HTML Implementer 的 `Written` allowlist。
- **Deleted**：無；不得刪除任何 tracked 或既有 prototype 檔案。
- **Modify**：首次 implementation 為無，不得修改任何既有檔案。若 Reviewer 明示 `needs-rework`，後續 Implementer 仍只能修改同一個 `prototypes/pr-inbox-static-visual-prototype/index.html`；需要變更其他檔案或範圍時，必須停止並返回 planning。
- **TestCase**：使用 TC-01 至 TC-09 作為唯一驗收集合，定義如下。

## Test Cases

| ID | Verification | Expected evidence |
| --- | --- | --- |
| TC-01 | Implementation allowlist | 以本 topic 四份 planning artifacts 取得獨立 Plan-Reviewer 明示 `approved` 後的 implementation baseline 為差異基準；HTML Implementer 的 change set 只能新增指定 `index.html`。四份 artifacts 不計入本次 Implementer diff 且保持不變，其他檔案不得新增、修改或刪除。 |
| TC-02 | Offline self-contained | HTML 可由 `file://` 直接開啟，無 JavaScript、外部 stylesheet／font／image、網路 URL、套件、build step 或 local server 依賴。 |
| TC-03 | Fixed dark theme | 全頁只呈現固定深色主題，使用深灰表面、淺色文字與節制藍色 accent，沒有 theme switcher 或淺色替代主題。 |
| TC-04 | Desktop 1440 | 1440px 寬度完整呈現 sidebar 與所有 PR 欄位；標題、repository、作者與次要 metadata 層級清楚，清單維持主要注意焦點。 |
| TC-05 | Desktop 1024 | 1024px 寬度無水平 overflow；sidebar 縮窄、摘要隱藏、每列只保留第一個標籤，作者與更新時間位於單行，標題與 repository 仍可辨識。 |
| TC-06 | Selection ownership | 6 筆 PR 中只有第二列具選取樣式；selection 明示為 Presentation Session fixture，不屬於 PR Inbox domain，且沒有點擊、切換或持久化能力。 |
| TC-07 | Empty state | 同頁主要工作台下方存在獨立且清楚標示的空 Inbox frame，保留相同深色版面骨架、sidebar、計數 0 與空狀態文案，不混入主要清單。 |
| TC-08 | Capability boundary | 畫面沒有 PR 詳情、diff、checks、discussion、通知、refresh、登入、authentication 或 review action，也不以控制項或文案暗示 `GithubIntegration`、PR Reader 或寫入能力已存在。 |
| TC-09 | Fictional fixtures | 主清單恰有 6 筆明顯虛構資料，涵蓋多個 repository、作者、相對更新時間、0–2 個標籤與摘要狀態；不含真實帳號、repository、PR 或使用者資料。 |

## Public API and Architecture Impact

不新增或修改 public API、Swift target、Domain model、Aggregate、Entity、Value Object、Port、Facade、Event、Message 或 Cross-BC contract。PR Inbox、PR Reader、`GithubIntegration` 與 Presentation Session 的既定 ownership 不變；不修改 `docs/architecture/`，也不建立 architecture diagram。

## Workflow Constraints

- 本文件與其他三份同 slug artifacts 由 PC-01 建立；PC-01 completed 只代表寫入完成，不等同 approval。PR-01 已明示 `needs-rework`，required fix 僅限補正 RV-01 至 HC-01 routing；PC-02 完成此 artifact-only correction，仍不構成 approval。
- 校正後已收到新的獨立 PR-02 明示 `approved`；PC-02 completed 仍不構成 approval。以 PR-02 核准的四份 artifacts 建立 TC-01 implementation baseline，IM-01 已 ready 但維持 pending，尚未實作 HTML。
- IM-01 僅建立受限 HTML，完成後交 TE-01，再交獨立 RV-01。只有 RV-01 明示 `approved` 才可進入 HC-01；RV-01 `needs-rework` 只回交對應 Implementer，`blocked`／`human-check` 停止並交還 Human，不得視為成果核准或進入方向決策。
- HC-01 只接受「採用」、「調整」或「放棄」。採用只允許另開 SwiftUI topic 進行規劃，不自動開始 SwiftUI implementation；RV-01 未明示 `approved` 時 HC-01 維持 pending。

## Last Updated

2026-09-11
