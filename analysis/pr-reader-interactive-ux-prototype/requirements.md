# PR Reader 互動 UX 原型需求

## Topic

- Slug：`pr-reader-interactive-ux-prototype`
- Primary Bounded Context：`PR Reader`
- Base branch：`codex/pr-inbox-static-visual-prototype`
- Status：DL-03已交付，Human於HC-02選擇「調整」；PC-05已寫入新契約，等待PR-05獨立Plan-Reviewer審查。

## Goal

建立一個可由本機 Chrome 透過 `file://` 直接開啟的單頁深色桌面互動原型，讓 Human 在 SwiftUI 實作前判斷下列 UX 方向是否成立：

- 從 PR Inbox 選取並開啟單一 PR。
- Reader 取代 Inbox 成為完整 workspace，而不是增加第三欄。
- `Overview`、`Files (8)`、`Commits (3)`、`Checks` 的資訊層級。
- Files/Diff 的檔案、change、可逆reviewed progress與comment draft操作。
- 以 `reviewedFileOrdinals` 表達按 PR 的已閱讀 membership，並將目前 selection 與 reviewed 狀態分離。
- 未reviewed current可標記並沿既有forward/wrap前進；reviewed current可只移除自身membership且不導覽。
- 只有 `8 / 8 reviewed` 才能以 `Finish Reading` 回 Inbox；頂部 `← Inbox` 始終是中性返回。

## Non-Goal

- 不證明 SwiftUI、產品架構、PR Reader domain contract、GitHub Integration 或 WebView pipeline 已完成。
- 不提供真實 PR、GitHub API、認證、refresh、同步、快取、network、storage、server 或 backend。
- 不提供 comment submit、review、approve、merge、外部跳轉、GitHub viewed write 或任何其他 GitHub 寫入。
- 不提供產品、Domain或GitHub層級的review/unreview/viewed寫入；`Mark as Unreviewed`只修改prototype-local Presentation Session set。
- 不把 Inbox membership/count、selection、tab、file/change、reviewed membership 或 draft 變成 Domain ownership；它們只是 fixture 與 Presentation Session 記憶體狀態。
- 不驗收低於 1440 × 900、mobile、iPad、responsive redesign、雙主題或完整 accessibility。

## In-Scope

- 單一、自包含的 HTML/CSS/JavaScript 原型；無外部資源與 build step。
- 固定深色、dense native macOS、restrained 的桌面視覺；使用深灰表面、淺色文字、節制藍色 accent、細分隔線與微妙 transition。
- Inbox workspace：`Inbox (6)`、四個 repo、三段靜態 filter、六筆 compact rows 與 selection/open 行為。
- Reader workspace：頂部 toolbar、四個 tabs、Overview、Files 雙欄 diff、Commits、Checks。
- 六筆固定虛構 PR；每筆都可進 Reader，並各有 8 files、3 commits、三項 checks 與獨立 session-memory progress。
- `atlas-desktop#87` 的逐字 canonical content、8-file fixture、Swift/XCTest diff 與一則 inline review conversation。
- Files-only keyboard shortcuts、memory-only composer、Cancel／Save Draft、`Mark Reviewed`、`Mark as Unreviewed`、gated `Finish Reading`與reload reset。
- Overview既有progress/action列中的numeric label、原生`<progress>`指示器與full-completion label。
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
- PR selection、active tab、selected file/change、可增減的reviewed files與draft都屬prototype-local Presentation Session fixture，不建立BC-to-BC dependency，也不對GitHub發送viewed/unviewed狀態。
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
- Overview 在既有 action 附近、同一既有 surface內，依本 PR 的 `reviewedFileOrdinals.size` 顯示逐字 progress：`0 / 8 reviewed`、`n / 8 reviewed`或`8 / 8 reviewed`；三態都必須可見。
- 同一行的label右側加入唯一非互動原生`<progress>`，約72 × 3 px；`value = reviewedFileOrdinals.size`、`max = files.length`，divider-toned track搭配restrained accent。它以visible label的穩定ID作`aria-labelledby`，並以逐次更新的`aria-valuetext="n of 8 files reviewed"`表達進度。0／partial／full都顯示，不加入Files、不重排行動區，也不新增panel、tab、surface或shortcut。
- 同一 reviewed count驅動 Primary action：`0` 顯示 `Review Changes →`、`1...7` 顯示 `Continue Review →`、`8` 顯示 `Finish Reading`。
- 8/8時在既有action area顯示非互動`✓ All files reviewed`與primary `Finish Reading`；0...7不顯示completion label。

### Files/Diff

- 只顯示左 `Changed Files` 與右 `Code Diff` 兩欄，不顯示 Inbox。
- 左欄依 `Sources`／`Tests` 分組；可見 row 只顯示 basename，完整 path 只作 fixture identity 或輔助資訊。
- #87 依序有 8 files；第 1–2 檔在 Sources，第 3–8 檔在 Tests。
- 每 PR 以 `reviewedFileOrdinals` 保存已閱讀 membership；row 的 current 狀態只由 `selectedFileOrdinal` 推導，重新選取已閱讀檔不會移除 reviewed membership。
- #87 首次由 `Review Changes →` 進 Files 時仍選取第 3 檔 `WorkspaceTests.swift` 與第一個 change，但 reviewed set為空，footer顯示 `0 / 8 reviewed`。
- Files footer 的 `n` 是 `reviewedFileOrdinals.size`，不是 selected ordinal或 change index。
- 只有 Files 且非 modal/editable 時，ArrowUp/Down 操作 change，Option+ArrowUp/Down 操作 file，無 Cmd/Ctrl/Option modifier 的 `c` 或 `C` 開 composer。
- `Cmd+C`、`Ctrl+C`、`Option+C` 不得被攔截；editable/control element 與 modal 內不得觸發背景 shortcut。
- Files footer沿用既有surface，持續顯示`n / 8 reviewed`、`↑↓ Change`、`⌥↑↓ File`、`C Comment`，並依三種互斥狀態呈現既有action area；不加入`<progress>`、不重排，也不新增panel/tab/surface/shortcut。
- 未reviewed current：primary action逐字`Mark Reviewed`；加入目前ordinal後，從下一ordinal向後找第一個unreviewed，超過8則wrap至1，找到後切檔並將change設0。若因此達8/8，留在最後marked current及既有change。
- Reviewed current且總數1...7：顯示非互動`Reviewed`，不得顯示`Mark Reviewed`；另顯示secondary action `Mark as Unreviewed`，不顯示`Finish Reading`。
- 8/8：顯示非互動`✓ All files reviewed`、secondary `Mark as Unreviewed`與primary `Finish Reading`；不得顯示`Mark Reviewed`。
- `Mark as Unreviewed`只移除selected ordinal，count恰減1；保持active PR/tab/file/change/draft與Inbox selection，不導覽、不搜尋、不wrap。render後current仍在同一檔且成為unreviewed，逐字`Mark Reviewed`恢復並接收focus。
- 8→7必須立即移除Overview/Files completion label與Finish，Overview改為`7 / 8 reviewed`＋`Continue Review →`；1→0時Overview改為`0 / 8 reviewed`＋`Review Changes →`。Stale或ineligible unreview event一律no-op。
- Comment/composer/draft操作不得改變 reviewed count、membership、selected file/change或自動導覽。
- `Finish Reading` 只在8/8時可用；從 Overview或Files啟用都只回 Inbox並保留8/8，不改 Inbox membership/count/metadata。
- `← Inbox` 在任何 reviewed count都可用，只回 Inbox並保留狀態，不等同 Finish。

## Success Criteria

- Human 能在單一 1440 × 900 桌面畫面理解 Inbox 與 Reader 是互斥 workspace，並評估是否採用此 UX 方向。
- 六筆 PR 都可透過一致 fixture 進入 Reader；#87 的文案、數量、Files ordering、首次 progress 與 diff conversation 全部符合鎖定內容。
- tab、file、change、可逆reviewed membership與draft只在記憶體中按PR隔離；Inbox／Overview／Files往返均保留，reload後清除。
- 原型完全離線、自包含、零 external request、零 storage、零產品程式碼。
- Human 可以在成果經 Tester 與 Reviewer 後明確選擇「採用／調整／放棄」。

## Acceptance TestCase Index

- `TC-01`：Clean pushed baseline local/upstream HEAD均為`8c2facf`。PC-05只可修改四份planning artifacts；PR-05 approved後IM-05只可修改既有`index.html`；DL-04 follow-up commit只可包含這五個tracked paths。以`git status --short --untracked-files=all`或等效方式枚舉tracked/staged/unstaged/untracked paths並套各phase allowlist，另對實際內容執行whitespace/EOF檢查；空白普通diff不可代替path/content evidence。
- `TC-02`：Offline/self-contained 與 reload reset。
- `TC-03`：固定深色與桌面氣質。
- `TC-04`：Inbox 逐字內容與 compact hierarchy。
- `TC-05`：Inbox selection 與 Reader entry。
- `TC-06`：#87 Overview逐字內容、三態numeric label/action、8/8 completion label，以及原生progress的value/max/尺寸/視覺與accessible name/value。
- `TC-07`：四tabs、由reviewed set推導的Overview progress/action/completion transitions、8→7與1→0，以及不新增surface/layout。
- `TC-08`：Files雙欄、basename rows、初入#87 ordinal 3但`0 / 8 reviewed`、current/reviewed indicator正交。
- `TC-09`：Files footer三態、Mark forward/wrap、Unreview remove-only／無導覽／focus recovery、stale no-op，以及8→7與1→0。
- `TC-10`：移除Done、8/8 completion/Finish與neutral back語意、Inbox membership/count/metadata不變。
- `TC-11`：Commits 與 Checks。
- `TC-12`：Inline conversation、editable guard、memory-only draft且comment/draft不改review/unreview progress/navigation。
- `TC-13`：多PR review/unreview/draft/selection隔離、Overview↔Files↔Inbox往返保留、derived display與reload reset。
- `TC-14`：Review/unreview只存在prototype-local memory；無storage/network/domain/GitHub viewed write、product action或新UI能力，並維持visual/a11y/scope/runtime hygiene。

詳細判定條件以同 topic 的 technical spec 與 plan 為準。

## Human Check

HC-01與HC-02都已由Human明示選擇「調整」。DL-03已以commit`8c2facf`交付，但HC-02的新決策supersede RV-04作為active contract gate；舊evidence只保留歷史。PC-05、PR-05、IM-05、TE-05、RV-05與DL-04完成後，停止於新的`HC-03`。Human再選擇：

- 採用：只允許另開正式 SwiftUI topic，不自動實作。
- 調整：回到本 topic 的 planning／implementation 路由。
- 放棄：本 topic 結案，不建立 SwiftUI topic。

## Assumptions

- 1440 × 900 Chrome 是唯一驗收環境。
- PC-05起始baseline已確認worktree clean，local HEAD與upstream均為`8c2facf`。
- 本文件只描述原型需求，不變更 PR Inbox、PR Reader 或 Presentation Session 的既定 ownership。

## Planning Artifact Evidence

- DL-03 completed：commit`8c2facf`已由Implementer bounded non-force push，local/upstream一致且worktree clean；HC-02其後明示「調整」。
- PC-05 planning rework allowlist只有同topic四份tracked artifacts；HTML與其他paths在此phase唯讀。
- PR-05為目前pending獨立planning gate；只有明示`approved`才可進IM-05。
- PR-05 approved後，IM-05 implementation allowlist只有既有`prototypes/pr-reader-interactive-ux-prototype/index.html`。
- DL-04 follow-up commit allowlist恰為上述四份artifacts加既有HTML，共五個tracked paths；不得新增或刪除檔案。
- 每一 phase都必須枚舉 tracked/staged/unstaged/untracked狀態，並對實際內容執行 whitespace與EOF檢查；evidence不構成 Plan-Reviewer/Reviewer approval。

## Last Updated

2026-09-14
