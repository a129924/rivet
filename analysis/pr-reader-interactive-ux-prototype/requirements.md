# PR Reader 互動 UX 原型需求

## Topic

- Slug：`pr-reader-interactive-ux-prototype`
- Primary Bounded Context：`PR Reader`
- Base branch：`codex/pr-inbox-static-visual-prototype`
- Status：PR-03 已明示 `needs-rework`；PC-04 已完成唯一 required fix，等待 PR-04 獨立 Plan-Reviewer 審查。

## Goal

建立一個可由本機 Chrome 透過 `file://` 直接開啟的單頁深色桌面互動原型，讓 Human 在 SwiftUI 實作前判斷下列 UX 方向是否成立：

- 從 PR Inbox 選取並開啟單一 PR。
- Reader 取代 Inbox 成為完整 workspace，而不是增加第三欄。
- `Overview`、`Files (8)`、`Commits (3)`、`Checks` 的資訊層級。
- Files/Diff 的檔案、change、reviewed progress 與 comment draft 操作。
- 以 `reviewedFileOrdinals` 表達按 PR 的已閱讀 membership，並將目前 selection 與 reviewed 狀態分離。
- 只有 `8 / 8 reviewed` 才能以 `Finish Reading` 回 Inbox；頂部 `← Inbox` 始終是中性返回。

## Non-Goal

- 不證明 SwiftUI、產品架構、PR Reader domain contract、GitHub Integration 或 WebView pipeline 已完成。
- 不提供真實 PR、GitHub API、認證、refresh、同步、快取、network、storage、server 或 backend。
- 不提供 comment submit、review、approve、merge、外部跳轉、GitHub viewed write 或任何其他 GitHub 寫入。
- 不提供 unreview／mark unread；已加入 `reviewedFileOrdinals` 的 ordinal 在 reload 前不可移除。
- 不把 Inbox membership/count、selection、tab、file/change、reviewed membership 或 draft 變成 Domain ownership；它們只是 fixture 與 Presentation Session 記憶體狀態。
- 不驗收低於 1440 × 900、mobile、iPad、responsive redesign、雙主題或完整 accessibility。

## In-Scope

- 單一、自包含的 HTML/CSS/JavaScript 原型；無外部資源與 build step。
- 固定深色、dense native macOS、restrained 的桌面視覺；使用深灰表面、淺色文字、節制藍色 accent、細分隔線與微妙 transition。
- Inbox workspace：`Inbox (6)`、四個 repo、三段靜態 filter、六筆 compact rows 與 selection/open 行為。
- Reader workspace：頂部 toolbar、四個 tabs、Overview、Files 雙欄 diff、Commits、Checks。
- 六筆固定虛構 PR；每筆都可進 Reader，並各有 8 files、3 commits、三項 checks 與獨立 session-memory progress。
- `atlas-desktop#87` 的逐字 canonical content、8-file fixture、Swift/XCTest diff 與一則 inline review conversation。
- Files-only keyboard shortcuts、memory-only composer、Cancel／Save Draft、idempotent `Mark Reviewed`、gated `Finish Reading` 與 reload reset。
- 在 1440 × 900 Chrome 進行人工互動與離線檢查。

## Out-Of-Scope

- SwiftUI、Swift Package、產品 source/tests、AppKit、正式 WebView integration。
- PR Inbox／PR Reader 的 Domain model、Port、Facade、UseCase、Adapter、Event、Message 或 Cross-BC contract。
- `docs/architecture` 更新、架構圖或任何長期產品真相修改。
- 真實 filter、search、sort、refresh、pagination、deep link、browser history、routing、loading 或 error workflow。
- localStorage、sessionStorage、IndexedDB、cookies、URL/hash/query persistence 或 filesystem write。
- Conversation tab、一般討論 workspace、diff submit、GitHub-side review state change 或 enabled `Open on GitHub`。
- SaaS dashboard cards、漸層、過度圓角徽章、過度留白、假 browser/window chrome 或 web-style global navigation。

## Product Boundary

- `PR Inbox` 仍只擁有待 review membership 與排序；`Finish Reading` 不移除 PR，也不改變 count `6` 或 row metadata。
- `PR Reader` 是此原型的 Primary BC，負責表達單一 PR 的背景、files、diff、commits 與 checks 閱讀體驗。
- PR selection、active tab、selected file/change、reviewed files 與 draft 都屬 Presentation Session fixture，不建立 BC-to-BC dependency，也不對 GitHub 發送 viewed 狀態。
- 原型資料全部是固定且明顯虛構的展示資料，不使用真實帳號或 repository data。

## Required Experience

### Inbox

- Sidebar 只顯示 `Inbox (6)` 與 `atlas-desktop`、`nebula-ui`、`orbit-api`、`harbor-kit`。
- Title：`PR Inbox`。
- Subtitle：`Pull requests waiting for your attention.`。
- Static filter：`Needs Review / Mentioned / All`；`Needs Review` 預設 active，旁邊顯示 `Static sample`，三段均不操作資料。
- 第一列預設 selected；single click 與 arrows 只選取，double-click 或 `Enter` 才開 Reader。
- `atlas-desktop#87` 的可見 repo line 必須是 `atlas-desktop #87`；owner-qualified key 只作 internal identity。
- 該列顯示 `Clarify offline workspace state`、`Theo North · 38m`、`Context prepared · priority`。

### Reader

- Reader 完全取代 Inbox；兩者不並排。
- Toolbar：`← Inbox`、`<repo-short> / #<number>`、disabled `Open on GitHub`。
- Canonical toolbar：`atlas-desktop / #87`。
- Tabs 只能依序為 `Overview`、`Files (8)`、`Commits (3)`、`Checks`；初次進入為 Overview。
- 非 Files tabs 不顯示 Files footer、diff shortcuts或 composer action；頂部 `← Inbox` 始終可用且只做中性返回。
- `Open on GitHub` 永遠 disabled/no-op，不產生 URL、window 或 network。

### Canonical Overview

- Title：`Clarify offline workspace state`。
- Author/time：`Theo North · 38m ago`。
- Status：`Ready for review`。
- Summary：`This PR clarifies how disconnected workspaces are represented in the project header and removes ambiguous offline state.`
- What Changed：
  1. `Adds explicit disconnected workspace state`
  2. `Updates project header rendering`
  3. `Adds coverage for offline transitions`
- Stats：`8 files changed`、`+182`、`−43`、`3 commits`。
- Checks 只顯示 `✓ Build`、`✓ Tests`、`✓ Lint`；不得出現 Passed 或 duration。
- Overview 在既有 action 附近、同一既有 surface內，依本 PR 的 `reviewedFileOrdinals.size` 顯示逐字 progress：`0 / 8 reviewed`、`n / 8 reviewed`或`8 / 8 reviewed`；三態都必須可見，不新增 panel、tab、surface或layout。
- 同一 reviewed count驅動 Primary action：`0` 顯示 `Review Changes →`、`1...7` 顯示 `Continue Review →`、`8` 顯示 `Finish Reading`。

### Files/Diff

- 只顯示左 `Changed Files` 與右 `Code Diff` 兩欄，不顯示 Inbox。
- 左欄依 `Sources`／`Tests` 分組；可見 row 只顯示 basename，完整 path 只作 fixture identity 或輔助資訊。
- #87 依序有 8 files；第 1–2 檔在 Sources，第 3–8 檔在 Tests。
- 每 PR 以 `reviewedFileOrdinals` 保存已閱讀 membership；row 的 current 狀態只由 `selectedFileOrdinal` 推導，重新選取已閱讀檔不會移除 reviewed membership。
- #87 首次由 `Review Changes →` 進 Files 時仍選取第 3 檔 `WorkspaceTests.swift` 與第一個 change，但 reviewed set為空，footer顯示 `0 / 8 reviewed`。
- Files footer 的 `n` 是 `reviewedFileOrdinals.size`，不是 selected ordinal或 change index。
- 只有 Files 且非 modal/editable 時，ArrowUp/Down 操作 change，Option+ArrowUp/Down 操作 file，無 Cmd/Ctrl/Option modifier 的 `c` 或 `C` 開 composer。
- `Cmd+C`、`Ctrl+C`、`Option+C` 不得被攔截；editable/control element 與 modal 內不得觸發背景 shortcut。
- Files footer沿用既有 surface，顯示 `n / 8 reviewed`、`↑↓ Change`、`⌥↑↓ File`、`C Comment`與 action；移除 `Done`，不新增 panel/tab/surface。
- `Mark Reviewed` 對目前檔 idempotent：加入目前 ordinal後，從下一 ordinal向後找第一個 unreviewed，超過 8則 wrap至1；找到後切檔並將 change設0。若全數 reviewed，留在使集合成為8/8的最後目前檔並顯示 `Finish Reading`。
- Comment/composer/draft操作不得改變 reviewed count、membership、selected file/change或自動導覽。
- `Finish Reading` 只在8/8時可用；從 Overview或Files啟用都只回 Inbox並保留8/8，不改 Inbox membership/count/metadata。
- `← Inbox` 在任何 reviewed count都可用，只回 Inbox並保留狀態，不等同 Finish。

## Success Criteria

- Human 能在單一 1440 × 900 桌面畫面理解 Inbox 與 Reader 是互斥 workspace，並評估是否採用此 UX 方向。
- 六筆 PR 都可透過一致 fixture 進入 Reader；#87 的文案、數量、Files ordering、首次 progress 與 diff conversation 全部符合鎖定內容。
- tab、file、change、reviewed membership 與 draft 只在記憶體中按 PR 隔離；Inbox／Overview／Files往返均保留，reload後清除。
- 原型完全離線、自包含、零 external request、零 storage、零產品程式碼。
- Human 可以在成果經 Tester 與 Reviewer 後明確選擇「採用／調整／放棄」。

## Acceptance TestCase Index

- `TC-01`：Clean baseline local/upstream HEAD均為 `0865469`。PC-03/PC-04只可修改四份 planning artifacts；PR-04 approved後IM-03只可修改既有 `index.html`；final follow-up commit只可包含這五個 tracked paths。以 `git status --short --untracked-files=all`或等效方式枚舉 tracked/staged/unstaged/untracked paths並套各 phase allowlist，另對實際內容執行 whitespace/EOF檢查；空白普通 diff不可代替 path/content evidence。
- `TC-02`：Offline/self-contained 與 reload reset。
- `TC-03`：固定深色與桌面氣質。
- `TC-04`：Inbox 逐字內容與 compact hierarchy。
- `TC-05`：Inbox selection 與 Reader entry。
- `TC-06`：#87 Overview逐字內容，以及三態逐字 progress與對應 action labels。
- `TC-07`：四 tabs、由reviewed set推導的Overview progress/action transitions與8/8 Finish gate，且不新增surface/layout。
- `TC-08`：Files雙欄、basename rows、初入#87 ordinal 3但`0 / 8 reviewed`、current/reviewed indicator正交。
- `TC-09`：Files-only shortcuts、`Mark Reviewed` idempotency、forward search/wrap與 full-set behavior。
- `TC-10`：移除 Done、Finish/neutral back語意、Inbox membership/count/metadata不變。
- `TC-11`：Commits 與 Checks。
- `TC-12`：Inline conversation、editable guard、memory-only draft且 comment/draft不改 progress/navigation。
- `TC-13`：多 PR reviewed/draft/selection隔離、Overview↔Files↔Inbox往返保留、Overview derived progress恢復與reload reset。
- `TC-14`：無 unreview/storage/network/domain/GitHub viewed write，並維持 visual/scope/runtime hygiene。

詳細判定條件以同 topic 的 technical spec 與 plan 為準。

## Human Check

HC-01 已由 Human 於 2026-09-12 明示選擇「調整」，因此舊 RV-02 approval只保留歷史，不能放行新 contract。PR-03已明示`needs-rework`，PC-04完成bounded planning fix後仍須PR-04明示`approved`，才可進IM-03、TE-03、RV-03與受限delivery；完成後停止於新的`HC-02`。Human再選擇：

- 採用：只允許另開正式 SwiftUI topic，不自動實作。
- 調整：回到本 topic 的 planning／implementation 路由。
- 放棄：本 topic 結案，不建立 SwiftUI topic。

## Assumptions

- 1440 × 900 Chrome 是唯一驗收環境。
- PC-03起始 baseline已確認 worktree clean，local HEAD與upstream均為 `0865469`。
- 本文件只描述原型需求，不變更 PR Inbox、PR Reader 或 Presentation Session 的既定 ownership。

## Planning Artifact Evidence

- PC-03/PC-04 planning rework allowlist只有同 topic四份 tracked artifacts；HTML與其他 paths在此 phase唯讀。
- PR-03 verdict為`needs-rework`；唯一required finding是Overview未鎖定由`reviewedFileOrdinals.size`推導、三態皆顯示且與Files footer同格式的逐字progress。PC-04只補足此項，不構成approval。
- PR-04為目前pending獨立planning gate；只有明示`approved`才可進IM-03。
- PR-04 approved後，IM-03 implementation allowlist只有既有 `prototypes/pr-reader-interactive-ux-prototype/index.html`。
- 最終 follow-up commit allowlist恰為上述四份 artifacts加既有 HTML，共五個 tracked paths；不得新增或刪除檔案。
- 每一 phase都必須枚舉 tracked/staged/unstaged/untracked狀態，並對實際內容執行 whitespace與EOF檢查；evidence不構成 Plan-Reviewer/Reviewer approval。

## Last Updated

2026-09-12
