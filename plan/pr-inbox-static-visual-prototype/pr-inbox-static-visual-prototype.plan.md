# PR Inbox 桌面靜態視覺原型

## Summary

建立一個可由本機瀏覽器透過 `file://` 直接開啟的固定深色 PR Inbox 桌面靜態原型，在 SwiftUI implementation 前驗證待 review PR 工作台的資訊層級、閱讀密度與選取焦點。

本 topic 僅處理視覺與資訊架構驗證，不建立 SwiftUI、產品功能、GitHub 整合或 domain behavior。原型不是長期架構真相，不修改 `docs/architecture/`。

既有 `pr-inbox-swift-contract-baseline` correction prerequisite 已完成並取得該 topic 獨立 Plan-Reviewer 明示 `approved`；該結果不構成本 topic 的 approval。本 topic 的 PR-01 verdict 為 `needs-rework`；PC-02 只校正其唯一 required fix，不構成 approval。新的獨立 PR-02 已對四份 artifacts 明示 `approved`，並以此核准狀態建立 TC-01 implementation baseline；IM-01 已 ready 但仍為 pending，尚未實作。

## Implementation Changes

- Implementer 僅新增 `prototypes/pr-inbox-static-visual-prototype/index.html`：單一自包含文件、內嵌 CSS、無 JavaScript、套件、build step、local server 或外部網路資源。
- 主畫面採固定深色 macOS 桌面風格，以系統字型、深灰中性色表面、高可讀性的淺色文字與節制藍色 accent 呈現乾淨且資訊密度適中的工作台；使用 CSS Grid／Flex 建立低干擾 sidebar 與主要 Inbox 清單。
- sidebar 只呈現產品識別、`Inbox` 導覽項目與待 review 計數；主區顯示清楚的 `Mockup` 標示、Inbox 標題、固定 fixture 清單及閱讀順序。
- 主清單使用恰好 6 筆明顯虛構的 PR fixture，涵蓋多個 repository、作者、相對更新時間、0–2 個標籤與展示用摘要狀態。每列以 PR 標題為第一層、repository 與作者為第二層，其餘 metadata 為第三層；fixture 順序只用於視覺驗證，不定義 PR Inbox sorting rule。
- 第二列呈現唯一明確選取狀態，以較亮深色表面、accent 邊線及焦點標記表達目前工作重心；此狀態明示為 Presentation Session fixture，不屬於 PR Inbox domain，也不提供點擊或持久化。
- 同一 HTML 在主要工作台下方加入清楚標示為替代狀態的獨立空 Inbox frame；它保留相同深色外框與 sidebar、顯示計數 0 與簡短空狀態文案，不混入主要清單，也不加入 loading、error 或互動狀態。
- 1440px 寬度完整呈現所有欄位；在 1024px 桌面寬度縮窄 sidebar、隱藏列摘要並只保留第一個標籤，將作者與更新時間壓縮至單行，但始終保持 PR 標題與 repository 可辨識且無水平 overflow。低於 1024px、mobile 與 iPad 不在驗收範圍。
- 不顯示 PR 詳情、diff、checks、discussion、通知、refresh、authentication、review action 或任何可能暗示真實 GitHub 連線與寫入能力的控制項。

## Public API / Interfaces

- 唯一使用者介面是 `prototypes/pr-inbox-static-visual-prototype/index.html`，輸入為固定 HTML fixture，輸出為本機瀏覽器中的靜態畫面。
- 不新增或修改 public API、Swift target、Domain model、Aggregate、Entity、Value Object、Event、Message、Port、Facade 或 Cross-BC contract。
- PR Inbox、PR Reader、`GithubIntegration` 與 Presentation Session 的既定 ownership 維持不變；原型中的清單、順序與選取皆不形成產品 contract。

## HTML Implementation Contract

- **Goal**：交付固定深色、完全離線、自包含的 PR Inbox 桌面 HTML 視覺原型，讓 Human 判斷資訊層級、閱讀密度、PR 閱讀順序與選取焦點是否適合後續 SwiftUI 方向。
- **Non-Goal**：不建立正式產品 UI、domain behavior、真實資料流程、GitHub client、PR Reader、review 操作或可持久化互動；原型不構成架構或產品 contract。
- **In-Scope**：單一 HTML、內嵌 CSS、固定深色 macOS 桌面版面、Inbox sidebar、6 筆虛構 PR fixture、第二列唯一選取狀態、獨立空 Inbox frame，以及 1440px／1024px 桌面寬度呈現。
- **Out-Of-Scope**：SwiftUI、Swift Package、產品程式碼、JavaScript、外部資源、build step、local server、GitHub API、authentication、cache、refresh、network/error handling、PR 詳情、diff、checks、discussion、review 寫入、真實或持久化互動、mobile、iPad、雙主題切換與完整 accessibility 驗證。
- **ReadOnly**：HTML Implementer 只以唯讀方式參照 `README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`，以及本 topic 經 PR-02 明示 `approved` 的四份 planning artifacts。所有未列入 `Written`、`Modify` 或 `Deleted` 的 tracked paths 均必須保持不變。
- **Written**：僅可新建 `prototypes/pr-inbox-static-visual-prototype/index.html`。四份 planning artifacts 由 Plan-Creator 在 planning phase 建立，不屬於 HTML Implementer 的 `Written` allowlist。
- **Deleted**：無；不得刪除任何 tracked 或既有 prototype 檔案。
- **Modify**：首次 implementation 為無，不得修改任何既有檔案。若 Reviewer 明示 `needs-rework`，後續 Implementer 仍只能修改同一個 `prototypes/pr-inbox-static-visual-prototype/index.html`；需要變更其他檔案或範圍時，必須停止並返回 planning。
- **TestCase**：
  - `TC-01 Allowlist`：以本 topic 四份 planning artifacts 已取得獨立 Plan-Reviewer 明示 `approved` 後的 implementation baseline 作為差異基準；HTML Implementer 的 change set 只能新增指定 `index.html`。四份 artifacts 不計入本次 Implementer diff 且保持不變，其他檔案不得新增、修改或刪除。
  - `TC-02 Offline Self-Contained`：HTML 可由 `file://` 直接開啟，無 JavaScript、外部 stylesheet、font、image、網路 URL、套件、build step 或 local server 依賴。
  - `TC-03 Fixed Dark Theme`：全頁只呈現固定深色主題，使用深灰表面、淺色文字與節制藍色 accent，沒有 theme switcher 或淺色替代主題。
  - `TC-04 Desktop 1440`：在 1440px 寬度完整呈現 sidebar 與所有 PR 欄位；標題、repository、作者及次要 metadata 層級清楚，清單維持主要注意焦點。
  - `TC-05 Desktop 1024`：在 1024px 寬度無水平 overflow；sidebar 縮窄、摘要隱藏、每列只保留第一個標籤，作者與更新時間位於單行，標題與 repository 仍可辨識。
  - `TC-06 Selection Ownership`：6 筆 PR 中只有第二列具選取樣式；selection 明示為 Presentation Session fixture，不屬於 PR Inbox domain，且沒有點擊、切換或持久化能力。
  - `TC-07 Empty State`：同頁主要工作台下方存在獨立且清楚標示的空 Inbox frame，保留相同深色版面骨架、sidebar、計數 0 與空狀態文案，不混入主要清單。
  - `TC-08 Capability Boundary`：畫面沒有 PR 詳情、diff、checks、discussion、通知、refresh、登入、authentication 或 review action，也不以控制項或文案暗示 `GithubIntegration`、PR Reader 或寫入能力已存在。
  - `TC-09 Fictional Fixtures`：主清單恰有 6 筆明顯虛構資料，涵蓋多個 repository、作者、相對更新時間、0–2 個標籤與摘要狀態；不含真實帳號、repository、PR 或使用者資料。

## Test Plan

- 以 PR-02 `approved` 後的 implementation baseline 執行 scope diff，確認 TC-01，且四份 planning artifacts 未被 Implementer 修改。
- 靜態檢查 TC-02、TC-03、TC-06、TC-08 與 TC-09，確認文件自包含、固定深色、selection ownership、能力邊界與 fixture 性質。
- 以 Safari 或 Chrome 任一可用桌面瀏覽器透過 `file://` 開啟，不啟動 server；分別以 1440px 與 1024px 桌面寬度人工驗證 TC-04 與 TC-05。
- 人工驗證 TC-07 的獨立空狀態 frame，以及主要 frame 的資訊層級、清單焦點與 `Mockup` 標示。
- Tester 完成 TC-01 至 TC-09 後交由獨立 Reviewer 審查 scope、視覺 evidence 與 ownership boundary；任何失敗回報 `needs-rework`，scope 或 locked decision 缺口回報 `blocked`，不得自行擴充功能補救。

## Assumptions and Gates

- 固定採用單一深色主題；不提供 theme switcher，亦不進行完整 accessibility 驗證，但保留基本語意結構與深色介面所需的可讀文字對比。
- 所有名稱、repository、作者與狀態皆為虛構展示資料；不從現有 GitHub、PR 或使用者資料衍生。
- PC-01 completed 只表示四份 artifacts 寫入完成。本計畫不是 approval；PR-01 已明示 `needs-rework`，PC-02 只完成其唯一 artifact routing correction。新的獨立 PR-02 已明示 `approved`；此 verdict 建立 TC-01 implementation baseline 並使 IM-01 ready，但 IM-01 仍為 pending 且尚未實作。
- 原型完成並經 TE-01 後交獨立 RV-01。只有 RV-01 明示 `approved` 才能進入 HC-01 的「採用／調整／放棄」方向決策。
- RV-01 `needs-rework` 只回交對應 Implementer；`blocked`／`human-check` 依 SDD 契約停止並交還 Human。這些結果不得視為成果核准，也不得開啟 HC-01 方向決策。
- 「採用」只允許另開新的正式 SwiftUI topic 進行規劃，不授權自動開始 SwiftUI implementation；「調整」須回修本 topic 並重新驗證／審查；「放棄」則停止，不建立替代產品功能。
- 若原型不足以讓 Human 判斷方向，回報 scope gap 並停止，不加入真實資料、互動、PR Reader 或 GitHub 能力。

## Last Updated

2026-09-11
