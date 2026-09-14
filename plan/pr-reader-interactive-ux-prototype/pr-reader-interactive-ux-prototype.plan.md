# PR Reader 互動 UX 原型執行計畫

## Summary

- Topic：`pr-reader-interactive-ux-prototype`
- Primary BC：`PR Reader`
- Base branch：`codex/pr-inbox-static-visual-prototype`
- 交付一個單一、離線、自包含、固定深色的 1440 × 900 HTML/CSS/JavaScript 互動原型。
- Reader 取代 Inbox 成為另一個完整 workspace，不與 Inbox 並排。
- 固定虛構資料驗證 Overview／Files／Commits／Checks、Files/Diff 導覽、per-PR reviewed progress、memory-only draft與回 Inbox的 session continuity。
- 不建立產品程式碼、domain contract、GitHub/backend/network/storage 或 review 寫入能力。

## HTML Implementation Contract

### Goal

讓 Human 在 SwiftUI實作前，以本機 Chrome檢視並操作 PR Inbox → PR Reader的完整 UX，驗證「Mark current reviewed → forward/wrap到next unreviewed → 8/8才可Finish」是否提供清楚、可保留且不改 Inbox membership的閱讀節奏。

### Non-Goal

- 不把原型視為正式產品實作、public API、架構真相或 Domain ownership。
- 不提供真實 GitHub 資料、認證、refresh、同步、持久化、外部導覽或寫入 review。
- 不實作 mobile/iPad/responsive、雙主題、完整 accessibility、loading/error flow。
- 不修改 PR Inbox membership/count/metadata；Finish Reading只代表此 Presentation Session已標記8/8 reviewed。
- 不提供 unreview／mark unread，也不把 reviewed progress寫入storage、Domain或GitHub viewed狀態。

### In-Scope

- 同一頁中的 Inbox 與 Reader 互斥 workspace。
- 固定深色、dense native macOS、restrained 視覺與 subtle separators/transitions。
- Inbox：sidebar、三段 static filter、六筆 compact fictional rows、single/double click 與 keyboard selection/open。
- Reader：toolbar、四 tabs、canonical Overview、Files 雙欄、Commits、Checks。
- 六筆一致 Reader fixtures；每筆 8 files、3 commits、三 checks 與 per-PR memory state。
- Canonical #87 Swift/XCTest diffs、一則 inline review conversation。
- Files-only keyboard shortcuts、memory-only composer、Cancel/Save Draft、reviewed file indicator、idempotent Mark Reviewed、Overview三態derived progress/action、gated Finish Reading與reload reset。
- 只沿用既有 file-row indicator、Overview action與Files footer；不增加panel、tab或surface。
- 1440 × 900 Chrome 人工/靜態驗證。

### Out-Of-Scope

- SwiftUI、Swift Package、產品 source/tests、AppKit/WebView integration。
- GitHub API、REST/GraphQL、OAuth、Keychain、HTTP、network、server、backend、package、CDN。
- PR Inbox／PR Reader Domain model、Port、Facade、UseCase、Adapter、Event、Message、Cross-BC contract。
- `docs/architecture`、架構圖或其他長期文件變更。
- 真實 filter/search/sort/refresh/pagination、routing、deep link、browser history、storage 或 filesystem write。
- Conversation tab、enabled Open on GitHub、comment submit、approve、merge 或其他 GitHub action。
- Unreview/remove reviewed、persistence、Domain progress、GitHub viewed write。
- 低於 1440 × 900 的 layout acceptance。

### ReadOnly

PC-03/PC-04 planning rework時，HTML與下列既有內容唯讀；除四份本 topic artifacts外，所有 tracked paths都不得修改：

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
- `prototypes/pr-reader-interactive-ux-prototype/index.html`

PR-04明示`approved`後的IM-03中，四份本 topic artifacts與上述既有內容都唯讀；只有既有`prototypes/pr-reader-interactive-ux-prototype/index.html`可修改。其他 tracked paths全程保持不變。

### Written

無。四份 artifacts與HTML都已存在；PC-03、PC-04與IM-03不得建立新檔。

### Deleted

無。

### Modify

- PC-03/PC-04只可修改：
  - `analysis/pr-reader-interactive-ux-prototype/requirements.md`
  - `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`
  - `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md`
  - `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`
- PR-04 `approved`後，IM-03只可修改既有`prototypes/pr-reader-interactive-ux-prototype/index.html`。
- 若 TE-03/RV-03回報`needs-rework`，Implementer仍只能修改同一 HTML。
- Final follow-up commit只可包含上述四份 artifacts與既有 HTML，共五個 tracked paths。
- 若修正需要其他 path、外部依賴、產品程式碼或 contract 變更：停止並回到 planning。

### TestCase

正式驗收使用更新後的`TC-01`至`TC-14`。基準為PC-03前clean local/upstream HEAD `0865469`：PC-03/PC-04 planning rework只改四份 artifacts；PR-04 approved後的IM-03 handoff只改既有 HTML；最終 follow-up commit只含五個 tracked paths。每階段都須枚舉 tracked、staged、unstaged、untracked paths並套 phase allowlist，且實讀內容做whitespace/EOF檢查；空白普通 diff不能代替path/content evidence。

## PC-03 / PC-04 Planning Rework Evidence

- 起始 worktree clean，local HEAD與upstream均為`0865469`。
- `git status --short --untracked-files=all`或等效 enumeration必須確認PC-03/PC-04 combined change set只有四份allowlisted tracked artifact modifications；HTML與其他 paths不變。
- PR-03已明示`needs-rework`；唯一required finding是Overview缺少0/1...7/8三態皆可見、由`reviewedFileOrdinals.size`推導且與Files footer同格式的逐字progress。PC-04只補足此項，PR-04 pending。
- 四檔須實讀並完成cross-artifact、whitespace與EOF檢查。這些只屬planning evidence，不等於PR-04 approval。

## Implementation Changes

### IM-03.1 — 保持單檔 runtime 與固定視覺

- 只修改唯一允許路徑中的既有自包含 HTML；CSS、JavaScript 與 fixtures 仍全部內嵌於該檔。
- 禁止外部 URL、字型、圖片、stylesheet、script、source map、fetch/XHR/WebSocket、framework、build tool、server 或 package。
- 以 semantic HTML、CSS Grid/Flex、原生 JavaScript 實作。
- 1440 × 900 使用固定深色、深灰 surfaces、淺色文字、節制藍色 accent、緊湊 row、細分隔線與 120–180ms subtle selection/tab/modal transition。
- 明示 `Interactive mockup` 與 `Fictional data`；不得呈現 SaaS card wall、漸層、過度圓角徽章/留白、假 chrome 或 web nav。

### IM-03.2 — 保持 Inbox workspace

- Sidebar：`Inbox (6)`、`atlas-desktop`、`nebula-ui`、`orbit-api`、`harbor-kit`。
- Header：`PR Inbox`；`Pull requests waiting for your attention.`。
- Static filter：`Needs Review / Mentioned / All`；Needs Review active，旁有 `Static sample`，全數 no-op。
- 六列依 technical spec 的 fixture table顯示；第一列預設 selected。
- #87 可見 repo line逐字 `atlas-desktop #87`，Inbox time逐字 `Theo North · 38m`，context逐字 `Context prepared · priority`；owner-qualified值僅作 internal prKey。
- Single click、ArrowUp/Down、Home/End、Space只選取；double-click或 Enter才開 Reader；首尾不 wrap。

### IM-03.3 — 更新 Reader Overview action

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
  - 初始0 reviewed為`Review Changes →`
- 不顯示 Passed、duration 或其他 check detail。
- Overview action由`reviewedFileOrdinals.size`推導：0為`Review Changes →`、1...7為`Continue Review →`、8為`Finish Reading`。
- 在既有Overview action附近、同一surface內，始終顯示由同一set size推導的逐字progress：0為`0 / 8 reviewed`、1...7為`n / 8 reviewed`、8為`8 / 8 reviewed`；不得新增panel、tab、surface或layout。
- Review/Continue的click/Enter/Space只切到Files並恢復目前 selection；Finish只在8/8可用並返回Inbox。Tabs行為不變。

### IM-03.4 — 沿用 Files/Diff fixture 與 layout

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
- 不新增或重排 panel、tab、surface；只在既有 file rows呈現獨立的current與reviewed indicators，並更新既有 Files footer。

### IM-03.5 — 保持六筆一致 Reader fixtures

- 六筆 PR 的 visible repo-short/#、title、author/time與 Inbox一致；#87 Reader time例外使用鎖定的 `38m ago`。
- 每筆有 8 files、3 commits、`✓ Build / ✓ Tests / ✓ Lint`。
- 其他五筆 file identities與 Overview summary/What Changed完全使用 technical spec的固定清單。
- #87 commits固定為：
  1. `a17c2d1 Model offline workspace header state`
  2. `c84e6af Refine project header copy`
  3. `e3b4902 Add offline workspace coverage`
- 其他五筆各有三筆固定、deterministic、明顯虛構的 commits；不要求特定 SHA/message，runtime不得隨機生成。

### IM-03.6 — 以 reviewedFileOrdinals 重建 progress

使用 technical spec 的單頁 memory schema：`workspace`、`inboxSelectionKey`、`activePRKey`、`readerStateByPR`、`composer`。

- 每 PR記憶active tab、selected file/change、`reviewedFileOrdinals`與一份saved draft；移除`visitedFileOrdinals`。
- 初始每 PR在Overview、reviewed set空、draft空、change 0；#87 selected/initial ordinal=3，其他=1。
- #87第一次進Files仍選`WorkspaceTests.swift`與第一 change，但顯示`0 / 8 reviewed`；進Files或選檔不會自動review。
- Current row只由`selectedFileOrdinal`推導；reviewed indicator只由set membership推導，兩者可同時成立且互不抹除。
- `Mark Reviewed`先idempotent加入目前ordinal；若未滿，依目前+1...8再1...目前-1找next unreviewed，切換後change=0。若全滿，留在最後marked file與目前change，顯示Finish。
- 不提供unreview；reviewed set只增不減，直到reload reset。
- `← Inbox`、Overview/Files/tab往返保留per-PR state；reload重設全部 state。

### IM-03.7 — 更新 Files footer、composer isolation 與 Finish

- Files footer只在Files顯示：`<reviewed count> / 8 reviewed`、`↑↓ Change`、`⌥↑↓ File`、`C Comment`與`Mark Reviewed`或`Finish Reading`；完全移除`Done`。
- Reviewed count是`reviewedFileOrdinals.size`，current則由selected ordinal推導，兩者不得混用。
- 非 modal/editable時：ArrowUp/Down移 change；Option+ArrowUp/Down移 file；首尾 no-op。
- `event.key`是 `c`或`C`，且 meta/ctrl/alt皆 false時開 composer；Shift產生大寫 C可用。Cmd+C、Ctrl+C、Option+C不攔截。
- Event target在 input、textarea、select、button、contenteditable/control或 modal開啟時，不觸發背景 shortcuts。
- Composer memory-only：顯示 path/anchor，非空才可 Save Draft；每 PR一份 draft；Cancel/Escape丟棄 working copy但保留舊 draft；無 Submit/Send。
- Comment/composer/draft的open/cancel/save都不得改reviewed progress、selected file/change或觸發navigation。
- `Mark Reviewed`使用IM-03.6的idempotent forward/wrap algorithm；0...7 reviewed時可用。
- `Finish Reading`只在8/8出現；從Files或Overview啟用只回Inbox、保留8/8，不改Inbox membership/count/metadata。
- Overview、Commits、Checks不顯示 Files footer，file/change/c快捷鍵 no-op且不自動切 Files；頂部`← Inbox`始終中性可用。

## Public API / Interfaces

不新增或修改 public API、Swift target、package manifest、Domain model、Port、Facade、UseCase、Adapter、Event、Message或 Cross-BC contract。`reviewedFileOrdinals`、原型DOM event與memory state只屬Presentation Session fixture，不得成為SwiftUI/architecture contract或GitHub viewed write。

## Test Plan

### TC-01 — Implementation allowlist

- 確認PC-03前 worktree clean，local HEAD與upstream均為`0865469`。
- PC-03/PC-04檢查只允許四份 planning artifacts被修改；HTML與其他 paths不得變動。
- PR-04 approved後，以approved planning handoff作IM-03 baseline；IM-03只允許既有`prototypes/pr-reader-interactive-ux-prototype/index.html`變動。
- Final staged review只允許四份 artifacts加HTML共五個 tracked paths；Written/Deleted必須為none。
- 各 phase使用`git status --short --untracked-files=all`或等效方式枚舉tracked/staged/unstaged/untracked後套allowlist，並實讀內容做whitespace/EOF；staged後以`git diff --cached --check`補強。空白普通 diff不可代替path/content evidence。

### TC-02 — Offline/self-contained 與 reload reset

- Chrome以 `file://`開啟成功。
- 無外部 URL/resource、server、build、fetch/XHR/WebSocket；Network零外部 request。
- 無 localStorage、sessionStorage、IndexedDB、cookie、URL persistence。
- Reload回初始 Inbox並清除 tab/file/change/reviewed/draft state；不得持久化 reviewed progress。

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
- Toolbar、title、`Theo North · 38m ago`、status、Summary、三項 What Changed與stats維持既有逐字內容。
- Checks只有 `✓ Build / ✓ Tests / ✓ Lint`，無 Passed/duration。
- #87 reviewed count為0、1...7、8時，Overview progress分別逐字為`0 / 8 reviewed`、`n / 8 reviewed`、`8 / 8 reviewed`，action分別逐字為`Review Changes →`、`Continue Review →`、`Finish Reading`；兩者都由set size推導，reselect reviewed file不降低count或回退顯示。

### TC-07 — 四 tabs 與 Overview action

- Tabs只有 Overview / Files (8) / Commits (3) / Checks，無 Conversation。
- Click與 tablist keyboard可切換；初次 Overview。
- Review Changes/Continue Review只切Files並恢復per-PR selection；不標記reviewed。
- Finish Reading在0...7不得出現/執行，在8/8才可從Overview返回Inbox並保留8/8。
- Overview progress/action只沿用既有surface與layout，切tab往返時由reviewed set重新推導，不得新增panel、tab或surface。

### TC-08 — Files 雙欄、current/reviewed indicators 與首次 0/8

- Files只有 Changed Files與 Code Diff兩欄。
- Sources/Tests分組，可見 rows依序只顯示八個鎖定 basenames；完整 path只作 identity/輔助。
- #87首次進Files選第3檔`WorkspaceTests.swift`與第一 change，但`reviewedFileOrdinals = {}`、footer逐字`0 / 8 reviewed`。
- Current indicator由selected ordinal推導；reviewed indicator由set membership推導。同一row可同時current/reviewed；重選reviewed row或切走不抹除membership。
- Totals `+182 −43`，diff具 Swift/XCTest unified diff真實感；指定 conversation位於 WorkspaceState第一 change。
- Layout仍只用既有file rows、Overview action與Files footer；不得新增panel/tab/surface。

### TC-09 — Files-only shortcuts 與 Mark Reviewed algorithm

- Files且非modal/editable時，footer顯示`n / 8 reviewed`、既有shortcut/comment controls與`Mark Reviewed`或`Finish Reading`；不得有Done。
- Arrow移 change；Option+Arrow移 file；file/change clicks更新 state；首尾 no wrap。
- 無 Cmd/Ctrl/Option modifier的小寫 c與大寫 C都開 composer；Cmd+C、Ctrl+C、Option+C不攔截；C Comment click可開。
- Mark未reviewed current只新增一次；重按/在reviewed current啟用membership保持不變，不提供unreview。
- Mark後依較大ordinal再wrap到1尋找next unreviewed，切檔時change=0且不選已reviewed；測試尾端wrap。
- 標記最後一個unreviewed後留在該最後marked file，reviewed=8/8並顯示Finish；不得再自動切檔。
- 非Files tabs不顯示Files footer、shortcuts no-op、c/C不開composer且不跳Files。

### TC-10 — Finish Reading、neutral back 與 Inbox invariants

- DOM與可見UI都不再有`Done`。
- 0...7 reviewed不能Finish；8/8時Overview與Files的`Finish Reading`都只回Inbox、保留8/8與per-PR state。
- Finish前後Inbox selection、membership、order、count `6`與metadata完全不變。
- 頂部`← Inbox`在0...8始終可用且中性返回，不標記reviewed、不要求8/8；返回/重開保留tab/file/change/reviewed/draft。

### TC-11 — Commits 與 Checks

- #87恰有三筆鎖定 canonical commits。
- 其他五 PR各有三筆固定、deterministic、虛構 commits，不要求特定 SHA/message且不隨機。
- Checks只顯示三個鎖定名稱，無 duration/refresh/detail。

### TC-12 — Inline conversation、editable guard 與 memory-only draft

- 唯一 conversation在鎖定 path/change/anchor且文案逐字。
- 合格 c/C與 C Comment開 modal；focus/background inert。
- 空白不可 Save；非空顯示 `Draft · not submitted`；每 PR一份；Cancel/Escape保留舊 draft；無 Submit。
- Modal/editable/control內 c/C、Arrow、Option+Arrow不觸發背景 shortcut，文字輸入/複製正常。
- 開啟、Cancel、Save draft與既有inline conversation都不得改reviewed membership/count、selected file/change或觸發next-file navigation。

### TC-13 — 六 PR 隔離 state 與 reload

- 至少兩 PR建立不同tab/file/change/reviewed/draft後，在Inbox/Overview/Files間往返，確認按PR隔離、完整恢復，以及Overview progress/action顯示對應該PR的set size而非stale/其他PR資料。
- 一個PR的Mark/Finish不得改其他PR progress；Finish不得移除任何Inbox row。
- Reload後所有PR回Overview、reviewed/draft清空；#87 selected ordinal3、其他ordinal1；Inbox第一列selected，所有Overview progress/action回`0 / 8 reviewed`與`Review Changes →`。

### TC-14 — Capability boundary 與 runtime stability

- Open on GitHub disabled/no-op；filter static。
- 無unreview、auth、refresh、fetch、review submit、product write、storage、network、Domain progress或GitHub viewed write。
- Fictional/mockup標示可見；全流程無 console error、外部 request、水平 overflow或遮擋。
- Scope hygiene確認只有既有file-row indicator、Overview action與Files footer變化，無新panel/tab/surface。

## Baseline / Delivery Contract

- PC-03起始 baseline：branch`codex/pr-reader-interactive-ux-prototype` worktree clean，local HEAD與upstream均為`0865469`。
- Planning phase：PC-03/PC-04只修改四份 topic artifacts；HTML ReadOnly。
- Implementation phase：PR-04 approved後只修改既有 HTML；四份 artifacts ReadOnly。
- Final staged review：只 stage四份 artifacts與HTML共五個 tracked paths；確認無新增/刪除、`git diff --cached --check` clean且變更符合approved contract。
- Final follow-up commit：只有RV-03 approved且Human依repository commit convention確認message後，才由Implementer建立包含上述五 paths的單一commit並bounded non-force push；Observer/Dispatcher、Plan-Creator、Tester與Reviewer不得執行commit/push。

## Workflow / Gates

1. 歷史PC-01～RV-02與其evidence/verdict保留於step ledger；HC-01於2026-09-12由Human明示選擇「調整」，因此舊approval不可放行新contract。
2. `PC-03` — Plan-Creator只修改四份artifacts以記錄本次調整；completed只表示寫入與自檢。
3. `PR-03` — 獨立Plan-Reviewer已明示`needs-rework`；唯一required finding是Overview缺少三態皆可見的derived reviewed progress。
4. `PC-04` — Plan-Creator只在四份artifacts補足Overview progress與相關TC/workflow；completed不等於approval。
5. `PR-04` — 獨立Plan-Reviewer重審。只有明示`approved`才可進IM-03；`needs-rework`回Plan-Creator，`blocked`／`human-check`停止交Human。
6. `IM-03` — Implementer只修改既有HTML並依TC-01～TC-14提供evidence。
7. `TE-03` — Tester以真實Chrome 1440 × 900重驗reviewed progress、Finish/back、isolation、runtime與scope。
8. `RV-03` — 獨立Reviewer審查implementation與Tester evidence。只有明示`approved`才可開啟final commit gate；`needs-rework`只回Implementer，`blocked`／`human-check`停止交Human。
9. Delivery — staged review後，經Human確認commit message，由Implementer建立只含五個tracked paths的follow-up commit並bounded non-force push。
10. `HC-02` — Delivery完成後停止，Human選擇採用／調整／放棄。採用只允許另開SwiftUI topic，不自動實作。

Checkbox、step status、Plan-Creator寫入、Tester結果都不構成 Reviewer approval或 Human decision。

## Assumptions

- 1440 × 900 Chrome是唯一視覺與互動 acceptance環境。
- 六筆 PR及其 files/commits/checks/diffs/conversation全部固定、deterministic、明顯虛構。
- `reviewedFileOrdinals`與其他原型state全部屬Presentation Session fixture，不改變PR Inbox或PR Reader ownership。
- Baseline `0865469`已包含先前approved prototype與歷史ledger；PC-03/PC-04只在其上做Human要求的contract及bounded review fix。
- 本 topic不回寫 architecture docs，不建立長期 interface。

## Stop Conditions

- PR-04 verdict為`needs-rework`：只回Plan-Creator修正四份artifacts。
- Plan-Reviewer/Reviewer verdict為 `blocked`或`human-check`：停止自動前進並交 Human。
- 需要修改 allowlist外 path、外部依賴、真實資料或新能力：停止並回 planning。
- RV-03未明示 approved：不得stage/commit/push或進HC-02。
- 到HC-02：不得自行選擇或開始SwiftUI實作。

## Last Updated

2026-09-12
