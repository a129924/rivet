# PR Reader 互動 UX 原型執行計畫

## Summary

- Topic：`pr-reader-interactive-ux-prototype`
- Primary BC：`PR Reader`
- Base branch：`codex/pr-inbox-static-visual-prototype`
- 交付一個單一、離線、自包含、固定深色的 1440 × 900 HTML/CSS/JavaScript 互動原型。
- Reader 取代 Inbox 成為另一個完整 workspace，不與 Inbox 並排。
- 固定虛構資料驗證 Overview／Files／Commits／Checks、Files/Diff 導覽、memory-only draft 與回 Inbox 的 session continuity。
- 不建立產品程式碼、domain contract、GitHub/backend/network/storage 或 review 寫入能力。

## HTML Implementation Contract

### Goal

讓 Human 在 SwiftUI 實作前，以本機 Chrome 檢視並操作 PR Inbox → PR Reader 的完整 UX，判斷其資訊層級、桌面密度、Files/Diff 閱讀節奏與互動方向是否可採用。

### Non-Goal

- 不把原型視為正式產品實作、public API、架構真相或 Domain ownership。
- 不提供真實 GitHub 資料、認證、refresh、同步、持久化、外部導覽或寫入 review。
- 不實作 mobile/iPad/responsive、雙主題、完整 accessibility、loading/error flow。
- 不修改 PR Inbox membership；`Done` 只返回，不代表 review 完成。

### In-Scope

- 同一頁中的 Inbox 與 Reader 互斥 workspace。
- 固定深色、dense native macOS、restrained 視覺與 subtle separators/transitions。
- Inbox：sidebar、三段 static filter、六筆 compact fictional rows、single/double click 與 keyboard selection/open。
- Reader：toolbar、四 tabs、canonical Overview、Files 雙欄、Commits、Checks。
- 六筆一致 Reader fixtures；每筆 8 files、3 commits、三 checks 與 per-PR memory state。
- Canonical #87 Swift/XCTest diffs、一則 inline review conversation。
- Files-only keyboard shortcuts、memory-only composer、Cancel/Save Draft、Done、reload reset。
- 1440 × 900 Chrome 人工/靜態驗證。

### Out-Of-Scope

- SwiftUI、Swift Package、產品 source/tests、AppKit/WebView integration。
- GitHub API、REST/GraphQL、OAuth、Keychain、HTTP、network、server、backend、package、CDN。
- PR Inbox／PR Reader Domain model、Port、Facade、UseCase、Adapter、Event、Message、Cross-BC contract。
- `docs/architecture`、架構圖或其他長期文件變更。
- 真實 filter/search/sort/refresh/pagination、routing、deep link、browser history、storage 或 filesystem write。
- Conversation tab、enabled Open on GitHub、comment submit、approve、merge 或其他 GitHub action。
- 低於 1440 × 900 的 layout acceptance。

### ReadOnly

HTML Implementer 只能讀取、不得修改：

- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/architecture/bounded-contexts/pr-reader.md`
- `analysis/pr-inbox-swift-contract-baseline/requirements.md`
- `analysis/pr-inbox-swift-contract-baseline/technical-spec.md`
- `plan/pr-inbox-swift-contract-baseline/pr-inbox-swift-contract-baseline.plan.md`
- `plan/pr-inbox-swift-contract-baseline/pr-inbox-swift-contract-baseline.step.md`
- `analysis/pr-inbox-static-visual-prototype/requirements.md`
- `analysis/pr-inbox-static-visual-prototype/technical-spec.md`
- `plan/pr-inbox-static-visual-prototype/pr-inbox-static-visual-prototype.plan.md`
- `plan/pr-inbox-static-visual-prototype/pr-inbox-static-visual-prototype.step.md`
- `prototypes/pr-inbox-static-visual-prototype/index.html`
- 本 topic 經獨立 Plan-Reviewer 核准的四份 planning artifacts。

其他 tracked paths 全部保持不變。

### Written

Planning phase 只建立下列四份正式 artifacts；它們不屬 HTML Implementer change set：

- `analysis/pr-reader-interactive-ux-prototype/requirements.md`
- `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md`
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`

四份 artifacts 經獨立 Plan-Reviewer 明示 `approved`，且 base delivery prerequisite 完成後，HTML Implementer 唯一可新建：

- `prototypes/pr-reader-interactive-ux-prototype/index.html`

### Deleted

無。

### Modify

- 首次 implementation：無既有檔案可修改，只新增唯一 `index.html`。
- 若 Tester/Reviewer 回報 `needs-rework`：Implementer 仍只能修改同一 `index.html`。
- 若修正需要其他 path、外部依賴、產品程式碼或 contract 變更：停止並回到 planning。

### TestCase

正式驗收使用 `TC-01` 至 `TC-14`。TC-01 的基準必須是四份本 topic artifacts 取得獨立 Plan-Reviewer `approved`、且 base delivery prerequisite 完成後建立的 implementation baseline／Implementer handoff change set，不能把合法 planning artifacts 或既有 base commits 算為 HTML 越界。路徑 evidence必須枚舉 tracked、staged、unstaged與 untracked狀態；普通 diff的空白輸出不得作為 untracked evidence。

## PC-01 / Planning Rework Evidence

- 本 topic 四份 planning artifacts 在本輪都是 untracked 新檔。
- 必須用 `git status --short --untracked-files=all` 或等效方式枚舉 tracked、staged、unstaged、untracked paths，確認只有四個 allowlisted `??` planning paths。
- 必須對四個 untracked檔案執行會實際讀取內容的 file-specific static/whitespace check；普通 `git diff --name-status`／`git diff --check`空白輸出不涵蓋 untracked檔案，不能證明 path存在、內容可讀或 whitespace clean。
- 若後續 staged，`git diff --cached --check`可作 staged內容的補強檢查。以上只屬 PC-01/回修 evidence，不等於 Plan-Reviewer approval。

## Implementation Changes

### IM-01.1 — 建立單檔 runtime 與固定視覺

- 在唯一允許路徑內建立自包含 HTML，內嵌全部 CSS、JavaScript 與 fixtures。
- 禁止外部 URL、字型、圖片、stylesheet、script、source map、fetch/XHR/WebSocket、framework、build tool、server 或 package。
- 以 semantic HTML、CSS Grid/Flex、原生 JavaScript 實作。
- 1440 × 900 使用固定深色、深灰 surfaces、淺色文字、節制藍色 accent、緊湊 row、細分隔線與 120–180ms subtle selection/tab/modal transition。
- 明示 `Interactive mockup` 與 `Fictional data`；不得呈現 SaaS card wall、漸層、過度圓角徽章/留白、假 chrome 或 web nav。

### IM-01.2 — 建立 Inbox workspace

- Sidebar：`Inbox (6)`、`atlas-desktop`、`nebula-ui`、`orbit-api`、`harbor-kit`。
- Header：`PR Inbox`；`Pull requests waiting for your attention.`。
- Static filter：`Needs Review / Mentioned / All`；Needs Review active，旁有 `Static sample`，全數 no-op。
- 六列依 technical spec 的 fixture table顯示；第一列預設 selected。
- #87 可見 repo line逐字 `atlas-desktop #87`，Inbox time逐字 `Theo North · 38m`，context逐字 `Context prepared · priority`；owner-qualified值僅作 internal prKey。
- Single click、ArrowUp/Down、Home/End、Space只選取；double-click或 Enter才開 Reader；首尾不 wrap。

### IM-01.3 — 建立 Reader workspace 與 Overview

- 開 Reader時完全取代 Inbox。
- Toolbar：`← Inbox`、`<repo-short> / #<number>`、disabled `Open on GitHub`；#87逐字 `atlas-desktop / #87`。
- Tabs只依序為 Overview、Files (8)、Commits (3)、Checks；初次進 Overview；不建立 Conversation。
- #87 Overview逐字使用：
  - `Clarify offline workspace state`
  - `Theo North · 38m ago`
  - `Ready for review`
  - `This PR clarifies how disconnected workspaces are represented in the project header and removes ambiguous offline state.`
  - `Adds explicit disconnected workspace state`
  - `Updates project header rendering`
  - `Adds coverage for offline transitions`
  - `8 files changed`、`+182`、`−43`、`3 commits`
  - 只顯示 `✓ Build`、`✓ Tests`、`✓ Lint`
  - `Review Changes →`
- 不顯示 Passed、duration 或其他 check detail。
- Review Changes click/Enter/Space 切到 Files；tabs支援 click與 tablist keyboard。

### IM-01.4 — 建立 Files/Diff fixture 與 layout

- Files只顯示左 Changed Files、右 Code Diff兩欄，不與 Inbox並排。
- Changed Files按 Sources/Tests分組；可見 row只顯示 ordinal、basename、status、delta、change count；完整 path只作 fixture identity/tooltip/accessible description。
- #87固定 8-file identity/visible name/數量：
  1. `Sources/ProjectHeader.swift` / `ProjectHeader.swift` / `+38 −12` / 2
  2. `Sources/WorkspaceState.swift` / `WorkspaceState.swift` / `+27 −8` / 2
  3. `Tests/WorkspaceTests.swift` / `WorkspaceTests.swift` / `+18 −4` / 1
  4. `Tests/OfflineTests.swift` / `OfflineTests.swift` / `+20 −3` / 2
  5. `Tests/OfflineStatusViewTests.swift` / `OfflineStatusViewTests.swift` / `+31 −4` / 2
  6. `Tests/WorkspaceHeaderSnapshotTests.swift` / `WorkspaceHeaderSnapshotTests.swift` / `+22 −7` / 2
  7. `Tests/ProjectHeaderTests.swift` / `ProjectHeaderTests.swift` / `+14 −3` / 1
  8. `Tests/WorkspaceStateTests.swift` / `WorkspaceStateTests.swift` / `+12 −2` / 1
- 總計 `+182 −43`；每檔使用不同、合理的 Swift/XCTest unified diff，含 hunk header、line number、context/removal/addition。
- 唯一 preset conversation位於 `Sources/WorkspaceState.swift`第一 change，anchor `case offline(lastSuccessfulSync: Date?)`，逐字內容依 technical spec。

### IM-01.5 — 建立六筆一致 Reader fixtures

- 六筆 PR 的 visible repo-short/#、title、author/time與 Inbox一致；#87 Reader time例外使用鎖定的 `38m ago`。
- 每筆有 8 files、3 commits、`✓ Build / ✓ Tests / ✓ Lint`。
- 其他五筆 file identities與 Overview summary/What Changed完全使用 technical spec的固定清單。
- #87 commits固定為：
  1. `a17c2d1 Model offline workspace header state`
  2. `c84e6af Refine project header copy`
  3. `e3b4902 Add offline workspace coverage`
- 其他五筆各有三筆固定、deterministic、明顯虛構的 commits；不要求特定 SHA/message，runtime不得隨機生成。

### IM-01.6 — 建立 state、navigation 與 progress

使用 technical spec 的單頁 memory schema：`workspace`、`inboxSelectionKey`、`activePRKey`、`readerStateByPR`、`composer`。

- 每 PR 記憶 active tab、selected file/change、visited files與一份 saved draft。
- 初始每 PR在 Overview、visited空、draft空、change 0；#87 selected/initial file ordinal = 3，其他 = 1。
- Files第一次 active時才將 initial selected file加入 visited。
- #87第一次由 Review Changes或 Files tab進入，必須選 `WorkspaceTests.swift`、第一 change、顯示 `3 / 8 files`、visited恰為 `{3}`。
- 切 file選第一 change並加入 visited；visited只增不減。
- Done與頂部返回保留 per-PR state；reload重設全部 state。

### IM-01.7 — 建立 Files-only shortcuts、composer 與 Done

- Files bottom bar只在 Files顯示：`<selected ordinal> / 8 files`、`↑↓ Change`、`⌥↑↓ File`、`C Comment`、`Done`。
- `<selected ordinal>`是 selected file的 1-based ordinal。
- 非 modal/editable時：ArrowUp/Down移 change；Option+ArrowUp/Down移 file；首尾 no-op。
- `event.key`是 `c`或`C`，且 meta/ctrl/alt皆 false時開 composer；Shift產生大寫 C可用。Cmd+C、Ctrl+C、Option+C不攔截。
- Event target在 input、textarea、select、button、contenteditable/control或 modal開啟時，不觸發背景 shortcuts。
- Composer memory-only：顯示 path/anchor，非空才可 Save Draft；每 PR一份 draft；Cancel/Escape丟棄 working copy但保留舊 draft；無 Submit/Send。
- Done只在 Files底部，返回 Inbox、保留 state、不改 membership/count/order、不產生 completion。
- Overview、Commits、Checks不顯示 Files bottom bar，file/change/c快捷鍵 no-op且不自動切 Files；以頂部 `← Inbox`返回。

## Public API / Interfaces

不新增或修改 public API、Swift target、package manifest、Domain model、Port、Facade、UseCase、Adapter、Event、Message或 Cross-BC contract。原型 DOM event與 memory state只屬本 artifact，不得成為 SwiftUI或 architecture contract。

## Test Plan

### TC-01 — Implementation allowlist

- 以四份 artifacts獨立 Plan-Reviewer approved且 base prerequisite完成後的 implementation baseline/handoff diff檢查。
- 使用 `git status --short --untracked-files=all` 或等效方式完整枚舉 tracked、staged、unstaged與 untracked paths，再對枚舉結果套用 allowlist；唯一 implementation path須為 `prototypes/pr-reader-interactive-ux-prototype/index.html`，不得有其他新增、修改或刪除。
- 若 HTML仍 untracked，使用會實際開啟該 `index.html`內容並能檢出 trailing whitespace／其他約定 whitespace問題的 file-specific static/whitespace check；空白的 `git diff --name-status`或`git diff --check`輸出不可當作 untracked path或內容證據。
- 若 HTML後續 staged，再執行 `git diff --cached --check`驗證 staged內容；不得為了檢查而 commit。

### TC-02 — Offline/self-contained 與 reload reset

- Chrome以 `file://`開啟成功。
- 無外部 URL/resource、server、build、fetch/XHR/WebSocket；Network零外部 request。
- 無 localStorage、sessionStorage、IndexedDB、cookie、URL persistence。
- Reload回初始 Inbox並清除 tab/file/change/visited/draft state。

### TC-03 — 固定深色與桌面氣質

- 1440 × 900固定深色、dense native macOS、restrained、subtle separators/transitions。
- 無 theme switcher、SaaS cards、過度圓角徽章/留白、漸層、fake chrome、web nav或水平 overflow。

### TC-04 — Inbox 逐字內容與 compact hierarchy

- Subtitle逐字 `Pull requests waiting for your attention.`。
- Filter依序 `Needs Review / Mentioned / All`、Needs Review active、旁有 `Static sample`，click/keyboard no-op。
- Sidebar為 `Inbox (6)`與四個指定 repo；六列不混入其他 repo。
- #87可見 repo line逐字 `atlas-desktop #87`；title、`Theo North · 38m`、`Context prepared · priority`逐字；owner-qualified key不可外顯為 repo line。
- 其他五列使用鎖定 compact metadata，不得全寫 Ready for review。

### TC-05 — Inbox selection 與 Reader entry

- Single click、ArrowUp/Down、Home/End、Space只選取；double-click/Enter才開；首尾 no wrap。
- 六筆各自可進 Reader且 fixture一致；#87 Reader time依 Overview顯示 `38m ago`。
- Reader完全取代 Inbox，不出現第三欄。

### TC-06 — #87 Overview 逐字驗收

- 初次 default Overview。
- Toolbar、title、`Theo North · 38m ago`、status、Summary、三項 What Changed、stats、`Review Changes →`全數符合 IM-01.3。
- Checks只有 `✓ Build / ✓ Tests / ✓ Lint`，無 Passed/duration。

### TC-07 — 四 tabs 與 Overview action

- Tabs只有 Overview / Files (8) / Commits (3) / Checks，無 Conversation。
- Click與 tablist keyboard可切換；初次 Overview。
- Review Changes只切 Files，不產生其他能力。

### TC-08 — Files 雙欄、basename rows、8-file fixture 與首次 3/8

- Files只有 Changed Files與 Code Diff兩欄。
- Sources/Tests分組，可見 rows依序只顯示八個鎖定 basenames；完整 path只作 identity/輔助。
- #87首次進 Files選第 3檔 `WorkspaceTests.swift`、第一 change、`3 / 8 files`、visited恰 `{3}`，不預訪第1/2檔。
- Totals `+182 −43`，diff具 Swift/XCTest unified diff真實感；指定 conversation位於 WorkspaceState第一 change。

### TC-09 — Files-only shortcuts、modifier guard、status 與 composer entry

- Files且非 modal/editable時，bottom bar順序與文案正確。
- Arrow移 change；Option+Arrow移 file；file/change clicks更新 state；首尾 no wrap。
- 無 Cmd/Ctrl/Option modifier的小寫 c與大寫 C都開 composer；Cmd+C、Ctrl+C、Option+C不攔截；C Comment click可開。
- 非 Files tabs不顯示 bottom bar、shortcuts no-op、c/C不開 composer且不跳 Files。

### TC-10 — Done、頂部返回與 per-PR continuity

- Files Done只回 Inbox，count/membership/order仍為 6，保留該 PR state。
- Done只在 Files且不取代頂部 `← Inbox`。
- 非 Files tabs只用頂部返回；同樣保留 state且不修改 Inbox。

### TC-11 — Commits 與 Checks

- #87恰有三筆鎖定 canonical commits。
- 其他五 PR各有三筆固定、deterministic、虛構 commits，不要求特定 SHA/message且不隨機。
- Checks只顯示三個鎖定名稱，無 duration/refresh/detail。

### TC-12 — Inline conversation、editable guard 與 memory-only draft

- 唯一 conversation在鎖定 path/change/anchor且文案逐字。
- 合格 c/C與 C Comment開 modal；focus/background inert。
- 空白不可 Save；非空顯示 `Draft · not submitted`；每 PR一份；Cancel/Escape保留舊 draft；無 Submit。
- Modal/editable/control內 c/C、Arrow、Option+Arrow不觸發背景 shortcut，文字輸入/複製正常。

### TC-13 — 六 PR 隔離 state 與 reload

- 至少兩 PR建立不同 tab/file/change/visited/draft後往返，確認按 PR隔離與恢復。
- Reload後所有 PR回 Overview、visited/draft清空；#87 ordinal 3、其他 ordinal 1；Inbox第一列 selected。

### TC-14 — Capability boundary 與 runtime stability

- Open on GitHub disabled/no-op；filter static。
- 無 auth、refresh、fetch、review submit、product write、storage、network或其他 repo。
- Fictional/mockup標示可見；全流程無 console error、外部 request、水平 overflow或遮擋。

## Base Delivery Prerequisite

- `codex/pr-inbox-static-visual-prototype` 的既有 commits 不需重建。
- Owner：`Implementer`。
- Status：pending；不是 PC-01 或 planning review的 blocker。
- Completion：在進入 IM-01並建立 TC-01 implementation baseline前，只對上一 topic branch `codex/pr-inbox-static-visual-prototype`執行 bounded non-force push，確認 remote ref包含既有 base commits；不得 force-push、重寫 commit、建立新 commit或夾帶其他 branch/ref。
- Evidence：Implementer回報 push target、non-force結果與 remote ref確認；pending時不得推導為完成。
- Observer/Dispatcher、Plan-Creator與 Reviewer不得執行 push；本條也不授權 Tester或其他角色取代 Implementer。

## Workflow / Gates

1. `PC-01` — Plan-Creator建立四份 artifacts；completed只表示寫入，不是 approval。
2. `PR-01` — 已由獨立 Plan-Reviewer明示 `needs-rework`；只回 Plan-Creator執行 bounded artifact rework。
3. `PC-02` — Plan-Creator只修正 PR-01 required fixes；completed只表示回修寫入與 evidence更新，不是 approval。
4. `PR-02` — 由獨立 Plan-Reviewer重新審查四份 artifacts。只有明示 `approved`才可進下一步；`needs-rework`再回 Plan-Creator，`blocked`／`human-check`停止交 Human。
5. `BP-01` — Implementer執行上一 topic branch的 bounded non-force push並提供 evidence；完成後建立 TC-01 implementation baseline。
6. `IM-01` — Implementer只新增唯一 HTML並提供 TC-01～TC-14 evidence。
7. `TE-01` — Tester以真實 Chrome 1440 × 900驗證全部 test cases。
8. `RV-01` — 獨立 Reviewer審查實作與證據。只有明示 `approved`才進 HC-01；`needs-rework`只回 Implementer；`blocked`／`human-check`停止並交 Human。
9. `HC-01` — Human選擇採用／調整／放棄。採用只允許另開 SwiftUI topic，不自動實作。

Checkbox、step status、Plan-Creator寫入、Tester結果都不構成 Reviewer approval或 Human decision。

## Assumptions

- 1440 × 900 Chrome是唯一視覺與互動 acceptance環境。
- 六筆 PR及其 files/commits/checks/diffs/conversation全部固定、deterministic、明顯虛構。
- 原型 state全部屬 Presentation Session fixture，不改變 PR Inbox或 PR Reader ownership。
- Base push只影響 implementation baseline，非 planning readiness。
- 本 topic不回寫 architecture docs，不建立長期 interface。

## Stop Conditions

- Plan-Reviewer verdict為 `needs-rework`：只回 Plan-Creator修正四份 artifacts。
- Plan-Reviewer/Reviewer verdict為 `blocked`或`human-check`：停止自動前進並交 Human。
- 需要修改 allowlist外 path、外部依賴、真實資料或新能力：停止並回 planning。
- RV-01未明示 approved：不得進 HC-01。
- 到 HC-01：不得自行選擇或開始 SwiftUI實作。

## Last Updated

2026-09-11
