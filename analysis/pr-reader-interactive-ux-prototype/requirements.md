# PR Reader 互動 UX 原型需求

## Topic

- Slug：`pr-reader-interactive-ux-prototype`
- Primary Bounded Context：`PR Reader`
- Base branch：`codex/pr-inbox-static-visual-prototype`
- Status：規劃文件已建立，等待獨立 Plan-Reviewer 審查。

## Goal

建立一個可由本機 Chrome 透過 `file://` 直接開啟的單頁深色桌面互動原型，讓 Human 在 SwiftUI 實作前判斷下列 UX 方向是否成立：

- 從 PR Inbox 選取並開啟單一 PR。
- Reader 取代 Inbox 成為完整 workspace，而不是增加第三欄。
- `Overview`、`Files (8)`、`Commits (3)`、`Checks` 的資訊層級。
- Files/Diff 的檔案、change、visited progress 與 comment draft 操作。
- `Done` 或頂部返回 Inbox 後，按 PR 保留 session-memory progress。

## Non-Goal

- 不證明 SwiftUI、產品架構、PR Reader domain contract、GitHub Integration 或 WebView pipeline 已完成。
- 不提供真實 PR、GitHub API、認證、refresh、同步、快取、network、storage、server 或 backend。
- 不提供 comment submit、review、approve、merge、外部跳轉或任何 GitHub 寫入。
- 不把 Inbox membership/count、selection、tab、file/change、visited 或 draft 變成 Domain ownership；它們只是 fixture 與 Presentation Session 記憶體狀態。
- 不驗收低於 1440 × 900、mobile、iPad、responsive redesign、雙主題或完整 accessibility。

## In-Scope

- 單一、自包含的 HTML/CSS/JavaScript 原型；無外部資源與 build step。
- 固定深色、dense native macOS、restrained 的桌面視覺；使用深灰表面、淺色文字、節制藍色 accent、細分隔線與微妙 transition。
- Inbox workspace：`Inbox (6)`、四個 repo、三段靜態 filter、六筆 compact rows 與 selection/open 行為。
- Reader workspace：頂部 toolbar、四個 tabs、Overview、Files 雙欄 diff、Commits、Checks。
- 六筆固定虛構 PR；每筆都可進 Reader，並各有 8 files、3 commits、三項 checks 與獨立 session-memory progress。
- `atlas-desktop#87` 的逐字 canonical content、8-file fixture、Swift/XCTest diff 與一則 inline review conversation。
- Files-only keyboard shortcuts、memory-only composer、Cancel／Save Draft、Done 與 reload reset。
- 在 1440 × 900 Chrome 進行人工互動與離線檢查。

## Out-Of-Scope

- SwiftUI、Swift Package、產品 source/tests、AppKit、正式 WebView integration。
- PR Inbox／PR Reader 的 Domain model、Port、Facade、UseCase、Adapter、Event、Message 或 Cross-BC contract。
- `docs/architecture` 更新、架構圖或任何長期產品真相修改。
- 真實 filter、search、sort、refresh、pagination、deep link、browser history、routing、loading 或 error workflow。
- localStorage、sessionStorage、IndexedDB、cookies、URL/hash/query persistence 或 filesystem write。
- Conversation tab、一般討論 workspace、diff submit、review state change 或 enabled `Open on GitHub`。
- SaaS dashboard cards、漸層、過度圓角徽章、過度留白、假 browser/window chrome 或 web-style global navigation。

## Product Boundary

- `PR Inbox` 仍只擁有待 review membership 與排序；`Done` 不移除 PR，也不改變 count `6`。
- `PR Reader` 是此原型的 Primary BC，負責表達單一 PR 的背景、files、diff、commits 與 checks 閱讀體驗。
- PR selection、active tab、selected file/change、visited files 與 draft 都屬 Presentation Session fixture，不建立 BC-to-BC dependency。
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
- 非 Files tabs 不顯示 file progress、diff shortcuts、composer action 或底部 Done；只能用頂部 `← Inbox` 返回。
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
- Primary action：`Review Changes →`。

### Files/Diff

- 只顯示左 `Changed Files` 與右 `Code Diff` 兩欄，不顯示 Inbox。
- 左欄依 `Sources`／`Tests` 分組；可見 row 只顯示 basename，完整 path 只作 fixture identity 或輔助資訊。
- #87 依序有 8 files；第 1–2 檔在 Sources，第 3–8 檔在 Tests。
- 首次由 `Review Changes →` 進 Files 時選取第 3 檔 `WorkspaceTests.swift`，顯示 `3 / 8 files`，visited 恰為 `{3}`。
- `<current>` 是 selected file 的 1-based ordinal，不是 visited count 或 change index。
- 只有 Files 且非 modal/editable 時，ArrowUp/Down 操作 change，Option+ArrowUp/Down 操作 file，無 Cmd/Ctrl/Option modifier 的 `c` 或 `C` 開 composer。
- `Cmd+C`、`Ctrl+C`、`Option+C` 不得被攔截；editable/control element 與 modal 內不得觸發背景 shortcut。
- Files 底部顯示 progress、`↑↓ Change`、`⌥↑↓ File`、`C Comment`、`Done`。
- `Done` 只回 Inbox、保留按 PR progress，不改 membership/count，也不表示 review 完成。

## Success Criteria

- Human 能在單一 1440 × 900 桌面畫面理解 Inbox 與 Reader 是互斥 workspace，並評估是否採用此 UX 方向。
- 六筆 PR 都可透過一致 fixture 進入 Reader；#87 的文案、數量、Files ordering、首次 progress 與 diff conversation 全部符合鎖定內容。
- tab、file、change、visited 與 draft 只在記憶體中按 PR 隔離；reload 後清除。
- 原型完全離線、自包含、零 external request、零 storage、零產品程式碼。
- Human 可以在成果經 Tester 與 Reviewer 後明確選擇「採用／調整／放棄」。

## Acceptance TestCase Index

- `TC-01`：Implementation allowlist 與 baseline。必須以 `git status --short --untracked-files=all` 或等效方式枚舉 tracked、staged、unstaged、untracked paths 後套用 allowlist；未追蹤 HTML 必須另以實際讀取該檔內容的 file-specific static/whitespace check 檢查，若後續 staged 再以 `git diff --cached --check` 補強。空白的普通 diff 輸出不得作為 untracked path 或內容證據。
- `TC-02`：Offline/self-contained 與 reload reset。
- `TC-03`：固定深色與桌面氣質。
- `TC-04`：Inbox 逐字內容與 compact hierarchy。
- `TC-05`：Inbox selection 與 Reader entry。
- `TC-06`：#87 Overview 逐字驗收。
- `TC-07`：四 tabs 與 Overview action。
- `TC-08`：Files 雙欄、basename rows、8-file fixture 與首次 `3 / 8 files`。
- `TC-09`：Files-only shortcuts、modifier guard、status 與 composer entry。
- `TC-10`：Done、頂部返回與 per-PR continuity。
- `TC-11`：Commits 與 Checks。
- `TC-12`：Inline conversation、editable guard 與 memory-only draft。
- `TC-13`：六 PR 的隔離 state 與 reload。
- `TC-14`：Capability boundary 與 runtime stability。

詳細判定條件以同 topic 的 technical spec 與 plan 為準。

## Human Check

原型完成、Tester 驗證並由獨立 Reviewer 明示 `approved` 後，停止於 `HC-01`。Human 只選擇：

- 採用：只允許另開正式 SwiftUI topic，不自動實作。
- 調整：回到本 topic 的 planning／implementation 路由。
- 放棄：本 topic 結案，不建立 SwiftUI topic。

## Assumptions

- 1440 × 900 Chrome 是唯一驗收環境。
- Base branch `codex/pr-inbox-static-visual-prototype` 的既有 commits 不需重建；由 `Implementer` 執行該上一 topic branch 的 bounded non-force push，是建立 implementation baseline 前的 delivery prerequisite，不是 planning blocker。Observer/Dispatcher、Plan-Creator 與 Reviewer 不得執行該 push。
- 本文件只描述原型需求，不變更 PR Inbox、PR Reader 或 Presentation Session 的既定 ownership。

## Planning Artifact Evidence

- PC-01 與本輪 rework 的四份 topic artifacts 目前都是 untracked 新檔；必須以 `git status --short --untracked-files=all` 或等效的 tracked/staged/untracked enumeration 如實列出四個 `??` paths。
- 每份 untracked planning artifact 必須由可實際讀取內容的 file-specific whitespace check 檢查；普通 `git diff --check` 或 `git diff --name-status` 的空白輸出不代表 untracked 檔案存在、可讀或無 whitespace 問題。
- 上述 evidence 只證明 PC-01/回修的檔案範圍與基本格式，不構成 Plan-Reviewer approval。

## Last Updated

2026-09-11
