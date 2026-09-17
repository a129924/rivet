# Rivet macOS Native Interaction Contract

## 1. Status, Ownership, and Sources

### Status

既有 HTML interaction baseline 已由 Human 採用；本文件亦已由 Human 於本 topic 的 HC-01 明示原值「採用」，現為 `macos-native-interaction-contract` 的 durable native interaction authority。此採用已結束本 contract topic，只允許未來另開正式 Swift implementation topic；它不自動授權、建立或開始任何 Swift implementation。

### Ownership

- 本契約屬於 non-BC Presentation contract；它 **MUST（必須）**只定義原生 macOS UI 可觀察行為。
- 本契約 **MUST NOT（不得）**改變 PR Inbox 對待 review membership／sorting、PR Reader 對單一 PR 閱讀資料，或 Presentation Session 對 selection／切換狀態的既有 ownership。
- 本契約 **MUST NOT（不得）**建立 PR Inbox 與 PR Reader 的 compile-time dependency，也不得定義 Logic、Domain、Integration、networking、persistence 或 GitHub write。
- HTML prototype **MUST（必須）**保持不變；本契約只把已採用 workflow 與 Draft 的 native-readiness `SHOULD FIX` 轉為行為規範。

### Sources

本契約以以下來源為準：

1. `analysis/pr-reader-interactive-ux-prototype/requirements.md`
2. `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`
3. `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md`
4. `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md` 中 HC-03 於 2026-09-15 的 Human 明示決策「採用」
5. 使用者提供的 `Draft Plan — Rivet macOS Native Interaction Contract`
6. 本 topic 的 requirements、technical spec 與 execution plan

若來源之間出現會改變 workflow、ownership 或 capability 的衝突，後續工作 **MUST（必須）**停止並回到 planning／Human Review；implementation **MUST NOT（不得）**自行裁決。

### Normative language

- **MUST（必須）**／**MUST NOT（不得）**：後續 native implementation 與驗收不可偏離。
- **SHOULD（應）**：除非 future Swift topic 記錄可驗證理由，否則必須遵循。
- **MAY（可以）**：不改變 observable contract 時可自行選擇的實作自由。

本文件描述 observable behavior；除非另有明示，它 **MUST NOT（不得）**被解讀為 SwiftUI type、AppKit bridge、資料模型、API 或儲存設計。

## 2. Terms and Invariants

### Terms

- **Inbox**：目的為 `Find work.` 的 workspace。
- **Reader**：目的為 `Understand work.` 的獨立 workspace；它 **MUST NOT（不得）**成為 Inbox 的第三欄 detail view。
- **Current selection**：目前選取並用於閱讀或操作的 PR、file 或 change。
- **Reviewed**：file 的閱讀呈現狀態。它與 current selection **MUST（必須）**正交；同一 file 可以同時為 current 與 reviewed。
- **Selected change anchor**：Diff／Change Reader 中代表目前 selected change、可接收 programmatic focus 且可被 reveal 的穩定 presentation target。
- **Opening target**：開啟 Comment Composer 前實際具有 focus 的 target。
- **Readable existing content**：即使 refresh、error 或 offline，仍可安全顯示與本地導覽的既有 presentation content；本契約不定義其來源或保存方式。
- **Local announcement**：只針對變更區域發出的、去重複的 accessibility status 更新；不是整個 workspace 的 live region。

### Invariants

- 首次開啟selected PR的主流程 **MUST（必須）**保持：Inbox → Open PR → Reader Overview → Review Files → Files／Diff → Mark Reviewed → Next File → Continue Review → All Files Reviewed → Finish Reading → Inbox。
- 重開已有saved Reader session的同一PR時 **MUST（必須）**依F-02恢復saved active tab並直接進入該tab的deterministic content target；不得強制重設為Overview。
- Files 核心 loop **MUST（必須）**保持：Read Diff → Navigate Change → Navigate File → Mark Reviewed → Next Unreviewed File → Continue。
- Comment 或 draft **MUST NOT（不得）**代表 reviewed，也不得改變 review progress、selected file 或 selected change。
- `empty` **MUST（必須）**是成功 presentation state，**MUST NOT（不得）**使用 failure language。
- Error／offline **MUST NOT（不得）**無條件清除仍指向 readable content 的 selection 或 review progress；沒有 readable content 時，UI **MUST NOT（不得）**暗示內容仍可使用。
- `Finish Reading` **MUST（必須）**只在所有 files reviewed 時啟用；`Back to Inbox` **MUST（必須）**在任意 progress 下保持中性返回，且兩者都不得改變 Inbox membership、count、ordering 或 row metadata。
- Context menu **MUST（必須）**只 mirror 已存在且適用於其 clicked／selected item 的能力，**MUST NOT（不得）**新增 product capability。
- 只有 code／diff content **MAY（可以）**水平捲動；workspace chrome、toolbar、tabs、lists 與狀態內容 **MUST NOT（不得）**以水平捲動解決 layout。
- Mock-only 或 disabled control **MUST（必須）**可被視覺與輔助技術辨識為不可執行，且 **MUST NOT（不得）**產生副作用。

### Adopted workflow state

- Overview progress 與 action **MUST（必須）**由同一 presentation review state 導出：零進度為 `Review Changes`、部分進度為 `Continue Review`、完成為 `Finish Reading`。
- `Mark Reviewed` 在尚未完成時 **MUST（必須）**選取下一個 unreviewed file、將 change 正規化為該 file 第一個 appropriate change，並維持不中斷閱讀 loop；完成最後一個 file 時 **MUST（必須）**留在最後 marked file／change。
- `Mark as Unreviewed` **MUST（必須）**只移除 current file 的 reviewed presentation state，保持 PR／tab／file／change／draft／Inbox selection，不搜尋、不 wrap、不導覽。

## 3. Focus State Machine

### Focus regions

本契約使用七個主要 focus regions：Inbox PR List、Reader Overview、Reader Tabs、File Navigator、Diff／Change Reader、Review Actions、Comment Composer。Native controls **MUST（必須）**參與 macOS 標準 keyboard focus traversal；不得以產品自訂 shortcut 取代標準 traversal。

下表中的 fallback 只在 primary destination 於 event 完成時不存在或不可接收 focus 時使用。若row明示ordered fallback chain，implementation **MUST（必須）**依順序使用第一個仍有效的target；其他rows仍只使用各自明示的唯一fallback。任一row明示的primary與fallback chain若因referenced content unavailable而全部失效，focus **MUST（必須）**交由對應Inbox或Reader Presentation State Matrix row明示的focus target接管；implementation **MUST NOT（不得）**猜測或加入其他destination。F-14仍須先完整依opening target → current selected change anchor → selected file row的順序判定，只有該chain全部失效時才交由current Reader matrix接管。

| ID | Source focus | Event/action | Destination focus | Selection behavior | Restoration behavior | Accessibility effect |
| --- | --- | --- | --- | --- | --- | --- |
| F-01 | App 尚無 focus／Inbox workspace | App 或 Inbox 初次進入 content state | 目前 selected PR row；若無可恢復 selection，唯一 fallback 為第一個 selectable PR row | 恢復有效 Inbox selection；否則選第一列；無 selectable row 時由 Inbox state matrix處理 | 記住該 row 作為後續 Reader 返回點 | VoiceOver **MUST** 宣告 row 的 PR identity、title 與 selected state，不宣告整個 list |
| F-02 | Inbox selected PR row | Enter、double-click 或 Open Reader；依該PR是否已有saved Reader session區分首次開啟／重開 | 首次開啟：Overview PR title heading，失效時唯一fallback為Overview tab。重開：恢復saved active tab並直接進其content target；Overview為title／Overview tab，Files為saved selected change anchor／selected file row，Commits為first visible commit row／Commits tab，Checks為first visible check row／Checks tab | 首次開啟啟用Overview；重開恢復saved active tab與仍有效的tab-specific selection；兩者都不得改review state | 保存來源Inbox selection row；重開Files的anchor失效時保持selected file，不自動選第一change；此直接恢復不改寫F-03～F-07的明示tab activation／content-entry語意 | **MUST** 宣告進入Reader及實際active tab／content context，避免重複朗讀整個workspace |
| F-03 | Reader Tabs 的 active tab | Click、Enter／Space，或 tab strip 中 Arrow Left／Right、Home／End 啟用 tab | 新 active tab；target tab 在 event 完成前失效時，唯一 fallback 為原 active tab | 更新 active tab；失效時 selection 不變 | 不進入 tab content，不套用過往 content focus history | Active tab 的 label、position 與 selected state **MUST** 可讀；只宣告新 active tab |
| F-04 | Active Overview tab | 標準 Tab 向前離開 tab strip | Overview PR title heading；heading 失效時，唯一 fallback 為 Overview tab | PR、tab 與 review state不變 | 由active Overview tab以標準Tab進入content時從title heading開始，不恢復任意舊content focus | Heading **MUST** 具有可理解的 heading semantics |
| F-05 | Active Files tab | 標準 Tab 向前離開 tab strip | Saved selected change 的 Diff／Change Reader anchor；anchor 失效時，唯一 fallback 為同一 selected file row | 恢復該 PR 的 selected file／change；不得改 reviewed state | 恢復合理 scroll anchor；只做 minimum necessary reveal | VoiceOver **MUST** 宣告 restored file／change identity，避免整頁重讀 |
| F-06 | Active Commits tab | 標準 Tab 向前離開 tab strip | 第一個 visible commit row；沒有 commit row 時，唯一 fallback 為 Commits tab | 不建立或改變 commit selection之外的 product state | 每次由 tab 進入使用第一個 visible row | Row **MUST** 提供 commit identity 與可見摘要 |
| F-07 | Active Checks tab | 標準 Tab 向前離開 tab strip | 第一個 visible check row；沒有 check row 時，唯一 fallback 為 Checks tab | 不改變 check 或 Reader state | 每次由 tab 進入使用第一個 visible row | Row **MUST** 提供 check name 與狀態，不只靠色彩 |
| F-08 | File Navigator 的 selected file row | Click、Arrow Up／Down 或其他 native list selection 選另一 file | 新 selected file row；target file 在 event 完成前失效時，唯一 fallback 為原 selected file row | 選 target file，change 正規化為該 file 第一個 change；失效時 selection 不變 | 不恢復 target file 的舊任意 change；reviewed membership 不變 | Row **MUST** 同時表達 current 與 reviewed／unreviewed；更新採 local announcement |
| F-09 | Diff／Change Reader | Arrow Up／Down、change control 或 click 選另一 change | 新 selected change anchor；target change 失效時，唯一 fallback 為原 selected change anchor | 只在 current file 內更新 selected change | Minimum necessary reveal；不得無條件置中 | Announcement **SHOULD** 包含 change position與hunk摘要，並去重複 |
| F-10 | Review Actions 的 `Mark Reviewed` | 啟用 Mark Reviewed，且仍有 unreviewed file | Next unreviewed file 的第一個 change anchor；anchor 失效時，唯一 fallback 為新 selected file row | Mark current reviewed，依既有 forward／wrap 規則選 next unreviewed，change 設為第一個 | Reveal 新 change，focus 不得留在已消失或失效的 action | **MUST** 局部宣告 marked file、next file 與進度，維持 keyboard loop |
| F-11 | Review Actions 的 `Mark Reviewed` | 啟用後形成全 files reviewed | 最後 marked file 的 current selected change anchor；anchor 失效時，唯一 fallback 為最後 marked file row | 保留最後 marked file／change；不得自動 Finish | 保持 current scroll anchor；completion 不接收 focus | Completion **MUST** 以局部、去重複 announcement 表達，且不得自動啟動 Finish |
| F-12 | Review Actions 的 `Mark as Unreviewed` | 啟用 unreview | Re-render 後新的 `Mark Reviewed` action；action 失效時，唯一 fallback 為 current selected file row | 只移除 current file reviewed state；file／change不變 | 不導覽、不搜尋、不 wrap | **MUST** 宣告 file 已改為 unreviewed 與更新後進度 |
| F-13 | Files context 中的 opening target | C、Comment control 或既有 comment action 開啟 Composer | Composer body editor；editor 無法建立時，唯一 fallback 為 opening target，且 Composer不得保持開啟 | PR／file／change／review state不變 | 保存 opening target，形成 modal focus containment | Dialog title、file identity、change anchor 與 editor label **MUST** 可讀；背景為 inert |
| F-14 | Comment Composer | Cancel、Escape 或 Save Draft 關閉 Composer | 固定ordered chain：opening target → current selected change anchor → selected file row；只有selected file亦失效時，才交給current Reader Presentation State Matrix明示的focus target | Cancel 丟棄 working copy但保留既有 saved draft；Save 只改 draft；selection／review state不變 | Keyboard `C` 的 opening target就是觸發前 focus target；**MUST NOT** 跳過chain中仍有效的target | **MUST** 宣告取消或 draft saved；不得重讀整個 diff |
| F-15 | Reader 任一可用 focus | Back to Inbox 或合格 Finish Reading | 先前保存的 Inbox selection row；row 已不存在時，唯一 fallback 為 Inbox 第一個 selectable row | Inbox selection保持；fallback才選第一列；不得任意改至其他 row | Reader session state保持；返回點供下次 F-02 使用 | **MUST** 宣告返回 Inbox 與 selected PR；Finish 不宣告 PR 已從 Inbox 移除 |
| F-16 | Current selected change anchor | 標準 Tab 向前進入 Review Actions | Current未reviewed時為 `Mark Reviewed`；current已reviewed時為 `Mark as Unreviewed`；對應 action不可用時，唯一 fallback 為 current selected change anchor | Selection與progress不變 | 這是標準 focus traversal，不建立 shortcut | Action 的名稱、enabled state與目前 file **MUST** 可讀 |
| F-17 | Review Actions | 標準 Shift-Tab 向後返回 reading surface | Current selected change anchor；anchor失效時，唯一 fallback 為 current selected file row | Selection與progress不變；action啟用後另依 F-10～F-12 | 恢復 current reading anchor並做 minimum necessary reveal | VoiceOver **MUST** 回到相同 change context，不得跳到 workspace 起點 |

F-10 是核心 keyboard loop gate。Implementation **MUST（必須）**讓使用者連續完成 `Mark Reviewed → next unreviewed file → first change reveal → Diff／Change reading focus`，不需要 pointer，也不得在 action 消失後遺失 focus。

## 4. Inbox Presentation State Matrix

| State | Workspace chrome | Primary content | Preserved state | Focus target | Enabled actions | Disabled actions | Recovery | Accessibility announcement |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `loading` | Sidebar、header 與既有 window structure **MUST** 保留 | Inline loading status；不得顯示虛假 PR rows | 已知 Inbox selection identity **MUST** 保留但不得假裝 row 可用 | 既有有效 focus保持；無既有 focus時落在 loading status heading | Cancel（若既有產品能力）與不依賴 content 的 chrome actions **MAY** 啟用 | Open Reader、row commands與依賴未完成資料的 actions **MUST** disabled | Loading結束後依 content／empty／error state轉移；本契約不定義 loading policy | 一次性、局部 `Loading pull requests`；workspace **MUST NOT** 成為 live region |
| `content` | Sidebar、header、filters與 list chrome **MUST** 完整保留 | 可讀 PR list與目前 selection | 有效 selection **MUST** 保留；無效時依 F-01 選第一列 | Selected PR row | Native selection、Open Reader與既有 local navigation **MUST** enabled | 不適用 context 的 commands **MUST** disabled且無副作用 | 無 recovery affordance | 首次到達時 **SHOULD** 局部宣告結果可用與 row count；selection變更只讀 current row |
| `empty` | Sidebar、header與 filters **MUST** 保留 | 成功 empty message；**MUST NOT** 使用 error語氣或 failure icon | Selection identity **MAY** 保留供未來內容恢復，但不得呈現 selected row | Empty-state heading | 既有 refresh／recovery affordance **MAY** enabled | Open Reader與 row commands **MUST** disabled | 提供非 failure 的 refresh／重新檢查 affordance（若既有能力） | 一次性宣告沒有等待 attention 的 PR；不得宣告 error |
| `error` | 可保留的 chrome **MUST** 保留 | Error status；若 referenced PR list仍 readable，**MUST** 同時保留該內容並清楚標示非最新 | 只有 referenced content仍 readable時才保留其 selection；不得無條件清除 | 有效既有 focus保持；否則落在 error heading | Retry／recovery **MUST** enabled；readable content的本地 selection/navigation **MAY** enabled | 需要 unavailable capability或沒有內容的 Open Reader **MUST** disabled | 提供明確 Retry；不定義 retry policy | 一次性、局部宣告 failure與內容是否仍可讀；不得重讀整個 list |
| `offline-with-existing-content` | Chrome **MUST** 保留並顯示 offline／stale indicator | 既有 readable PR list，明示可能非最新 | Selection **MUST** 保留，只要 row仍存在 | 目前 selected row；失效時依 F-01 fallback | 本地 selection/navigation與對 readable row 的安全 open **MUST** enabled | 需要 network或無法安全執行的 actions **MUST** disabled | 提供 reconnect／retry affordance；不定義來源或策略 | 一次性宣告 offline、顯示既有內容及其 stale性；selection announcement維持局部 |
| `offline-without-content` | Sidebar、header與基本 chrome **MUST** 保留 | Offline status；**MUST NOT** 顯示 placeholder PR content | Selection identity **MAY** 保存但不得暗示 row存在 | Offline-state heading；標準 Tab後到 recovery affordance | Reconnect／retry **MUST** enabled | Open Reader、row commands及 content actions **MUST** disabled | 清楚的 reconnect／retry affordance；不定義 network policy | 一次性宣告 offline且沒有可讀內容；不得宣告 stale content可用 |

## 5. Reader Presentation State Matrix

| State | Workspace chrome | Primary content | Preserved state | Focus target | Enabled actions | Disabled actions | Recovery | Accessibility announcement |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `loading` | Reader toolbar與 tabs **MUST** 保留；不得回顯 Inbox為第三欄 | Inline Reader loading status；不得顯示虛假 Overview／Files content | Active PR identity、tab、file／change selection與review progress identity **MUST** 保留 | 依F-02：首次開啟使用Overview tab；重開使用saved active tab。Content建立後再進F-02的tab-specific target | Back to Inbox與不依賴 content 的 chrome actions **MUST** enabled | Content navigation、review、comment與 Finish **MUST** disabled | Loading完成後進 content／error／offline state；不定義 loading policy | 一次性、局部宣告 Reader loading；不得把整個 workspace設為 live region |
| `content` | Toolbar、tabs與目前 tab chrome **MUST** 完整保留 | Active tab 的可讀 content | PR、tab、file／change、review progress與draft **MUST** 依 adopted workflow保留 | 依 F-02～F-17 的 deterministic target | Context成立且 input允許的 reading、navigation、review、comment、Back與合格 Finish **MUST** enabled | Context不成立、mock-only或不安全 actions **MUST** disabled | 無 recovery affordance | Selection、progress、file transition與completion使用局部、去重複 announcement |
| `error` | 可保留的 Reader chrome **MUST** 保留 | Error status；若 current Reader content仍 readable，**MUST** 保留並清楚標示非最新 | 只有 referenced content仍 readable時，才保留其 selection、review progress與scroll anchor | 有效 current target保持；否則 error heading | Retry與 readable content 的本地閱讀／導覽 **MUST** enabled | 需要 unavailable capability、沒有內容的 review/comment/Finish **MUST** disabled | 提供明確 Retry；不定義 retry或cache policy | 一次性宣告 failure及內容是否仍可讀；不得清空進度後再宣告零進度 |
| `offline-with-readable-existing-content` | Toolbar、tabs與 active content chrome **MUST** 保留，並顯示 offline／stale indicator | Existing readable Overview／Files／Commits／Checks content | PR、tab、selection、review progress、draft與scroll anchor **MUST** 保留，只要其 referenced content仍有效 | 目前有效focus保持。若Review Action正持有focus且因offline disabled，focus依current selected change anchor → selected file row移動；只有Files content亦失效時，才移到本row的offline／stale status heading | 本地 reading、selection與 Back **MUST** enabled；change／file navigation只有在active Files context且對應local file／change data仍有效時 **MUST** enabled；其他 actions依 UI Input Requirement 的 safe availability決定 | 非Files tabs或local file／change data失效時，Files navigation **MUST** disabled；需要network或無法安全執行的 actions亦 **MUST** disabled | 提供 reconnect／retry；不得阻擋本地閱讀 | 一次性宣告offline、內容仍可讀及disabled能力；因action disabled移動focus時 **MUST** 局部宣告目前reading／file context，不得重讀workspace |
| `offline-without-readable-content` | Toolbar、tabs與基本 Reader chrome **MUST** 保留 | Offline status；**MUST NOT** 顯示虛假 diff、file list或可操作 progress | PR identity與可恢復 session identity **MAY** 保存；不得呈現可讀 selection | Offline-state heading；標準 Tab後到 recovery affordance | Back to Inbox與 reconnect／retry **MUST** enabled | Content navigation、review、comment與 Finish **MUST** disabled | 清楚的 reconnect／retry與 Back affordance；不定義 network policy | 一次性宣告 offline且沒有可讀 Reader content；不得暗示 diff可用 |

## 6. Command Matrix

所有 Reader command **MUST NOT（不得）**以 unconditional global interception 實作。當 focus 位於文字輸入、Comment Composer、editable control、native control正在處理按鍵或 VoiceOver interaction時，該 control／輔助技術 **MUST（必須）**優先；Reader command **MUST NOT（不得）**執行或改變 state。

| Command ID | Command | Valid focus/context | Enabled when | Disabled/conflict behavior | Observable result | Menu counterpart | Context-menu counterpart |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CMD-NI-001 | Arrow Up／Down、Home／End：Inbox selection | Inbox PR List | Content state且至少一個 selectable row | 首尾 no-op；editable／VoiceOver conflict時 list command不攔截 | 只移動 single selection；不開 Reader | Application menu **SHOULD** 提供等價的 Previous／Next／First／Last selection command，並依 context routing | PR row menu **MAY** mirror selection-independent existing actions；不得新增 navigation能力 |
| CMD-NI-002 | Enter：Open Reader | Selected Inbox PR row | Row存在且可開啟 | Context不成立時保持 state與focus；不得切 tab或 workspace | 依F-02開啟selected PR：首次進Overview target；重開則恢復saved active tab及其deterministic content target | `Open Selected Pull Request` 等價 menu command **MUST** 存在 | Selected／clicked PR row **MAY** 提供等價 `Open` |
| CMD-NI-003 | Reader tab activation與 Arrow Left／Right、Home／End | Reader Tabs | Target tab存在且 enabled | Target失效時依 F-03 保留原 tab；editable／VoiceOver conflict不攔截 | 啟用既有 Overview／Files／Commits／Checks且focus留在 tab | View／navigation menu **MUST** 提供四個既有 tab的等價選擇 | None；tab context menu **MUST NOT** 新增能力 |
| CMD-NI-004 | Review Changes／Continue Review | Overview action | Review count分別為零／部分，且該PR的 Files data與context有效 | Context或Files data不可用時 no-op並保持focus | 啟用 Files、保留 selected file／change與review state，focus到saved selected change anchor；anchor失效時唯一fallback為selected file row | Reader menu **MUST** 提供語意等價 action | None |
| CMD-NI-005 | Arrow Up／Down：Change navigation | Active Files tab的Diff／Change Reader reading focus | Current file有 previous／next change，且無 modal／editable／VoiceOver conflict | 首尾 no-op；focus在File Navigator時Arrow Up／Down只依F-08執行native file-list selection，不得觸發change navigation；其他非Files context不得切到Files，conflict時不攔截 | 只更新 current file內 selected change並依 F-09 reveal／focus | Reader menu **SHOULD** 提供 Previous／Next Change | Current diff／change context menu **MAY** mirror existing navigation |
| CMD-NI-006 | Option+Arrow Up／Down：File navigation | Active Files tab的Diff／Change Reader reading focus | 有 previous／next file，且無 modal／editable／VoiceOver conflict | 首尾no-op；File Navigator direct selection仍只依F-08，不使用本command的focus result；非Files context不得切tab，conflict時不攔截 | Selection設為new file及其第一個change，focus new change anchor並minimum reveal；anchor不存在時唯一fallback為new selected file row；reviewed state不變 | Reader menu **MUST** 提供 Previous／Next File | Diff context menu **MAY** mirror existing file navigation |
| CMD-NI-007 | C：Comment | Files reading context | 無 Meta／Control／Option modifier、Composer關閉、opening target有效且 comment能力可用 | Cmd+C、Ctrl+C、Option+C、editable、modal或VoiceOver interaction **MUST NOT** 被攔截 | 開 Composer並依 F-13 focus editor；selection／review state不變 | Reader menu **MUST** 提供等價 Comment action | Current change context menu **MAY** 提供既有 Comment action |
| CMD-NI-008 | Escape：Close／cancel Composer | Comment Composer | Composer開啟 | Composer外不產生 Reader side effect；native control先處理其既有 Escape語意 | 丟棄 working copy、保留既有 saved draft並依 F-14復原 focus | Composer／Edit menu **SHOULD** 提供 Cancel | Composer context menu不得加入 product action |
| CMD-NI-009 | Mark Reviewed | Review Actions；current file未reviewed | Files content可用且 event仍合格 | Stale／ineligible／offline-unsafe時 no-op；保持selection與focus或由state matrix接管 | 未完成依 F-10前進；完成依 F-11留位；只改既有review presentation state | Reader menu **MUST** 提供 `Mark Reviewed` 並反映 enablement | 只有clicked file row就是current／selected file row時 **MAY** mirror同一能力；clicked non-current row不得顯示或執行，且不得先改selection |
| CMD-NI-010 | Mark as Unreviewed | Review Actions；current file已reviewed | Files content可用且 event仍合格 | Stale／ineligible／offline-unsafe時 no-op；不得誤用 Mark forward algorithm | 只移除 current reviewed state並依 F-12恢復 focus | Reader menu **MUST** 提供 `Mark as Unreviewed` | 只有clicked reviewed file row就是current／selected file row時 **MAY** mirror同一能力；clicked non-current row不得顯示或執行，且不得先改selection |
| CMD-NI-011 | Finish Reading | Overview或Files既有 action area | 全 files reviewed且 action可安全執行 | 未完成、stale或 capability不可用時 no-op且不得顯示 completion成功 | 返回 Inbox、保留8/8與Reader session、Inbox invariants不變，依 F-15 focus | Reader menu **MUST** 提供 `Finish Reading` 並只在合格時 enabled | None |
| CMD-NI-012 | Back to Inbox | Reader toolbar／menu | Reader workspace中永遠可用 | Composer modal開啟時先由 modal處理；不得把 Back解讀為 Finish | 中性返回 Inbox，保留Reader session並依 F-15 focus | Navigation menu **MUST** 提供 `Back to Inbox` | None |
| CMD-NI-013 | Show／Hide Sidebar | Visible workspace 的 collapsible navigation container | Window與container可執行標準toggle | Modal／inactive context不得攔截；不得清除selection | 切換 Inbox sidebar或當前 native sidebar容器可見性，selection保持 | View menu **MUST** 使用標準 Show／Hide Sidebar command與系統快捷鍵語意 | None |
| CMD-NI-014 | Page Up／Page Down | Diff reading scroll context | Diff可垂直scroll且reading surface持有scroll context | Editable／modal／VoiceOver conflict時由目前control處理 | 移動約一個viewport並保留閱讀連續性；不得自動變更 selected change | System scrolling即可；**MAY** 不另建 product menu item | None |
| CMD-NI-015 | Space／Shift-Space：system page scroll | Diff reading scroll context，且未落在button／editable／VoiceOver interaction | Native scroll context沿用system behavior時 | Control activation、文字輸入與VoiceOver優先；不得作全域shortcut | 依system向下／向上page scroll；不得自動變更 selected change | None；這是system behavior，不是product command | None |

## 7. Native macOS Container Contract

| Region | Native role | Selection/focus semantics | Commands/menu | State representation | Forbidden expansion |
| --- | --- | --- | --- | --- | --- |
| Inbox sidebar | Native sidebar／source-list container | **MUST** 使用native focus、selection與collapse behavior；collapse後Inbox PR selection保持 | View menu **MUST** 提供標準 Show／Hide Sidebar | Active source、inactive window與system accent **MUST** 交由semantic native appearance | **MUST NOT** 加入新filter、navigation destination或product mode |
| Inbox PR list | Native single-selection list | Single click／arrows只選取；double-click／Enter才open；selection與open **MUST** 分離 | Open與selection commands依CMD-NI-001／002 route | Selected、focused與inactive selected states **MUST** 可區分且不只靠color | **MUST NOT** 把Reader嵌成第三欄或以selection自動open |
| Reader toolbar | Native window toolbar | Toolbar item **MUST** 依context enable；disabled mock action不可接收成功語意 | 每個既有高階action **MUST** 有合理application menu counterpart | Back、PR identity、disabled mock control與window inactive state **MUST** 清楚 | **MUST NOT** 新增Approve、Request Changes、Merge或外部write能力 |
| Reader tabs/navigation | Native tab／segmented navigation semantics | 只包含Overview、Files、Commits、Checks；F-03～F-07決定focus | View／navigation menu **MUST** mirror四個既有destinations | Active tab **MUST** 有selected semantic，不只靠accent | **MUST NOT** 新增Conversation tab或隱含workflow |
| File navigator | Native single-selection list | Current selection與reviewed state **MUST** 同時可表達；list **MUST** 支援full keyboard access；Arrow Up／Down依F-08移動file selection；collapse不得遺失selection | Previous／Next File依Command Matrix；Mark／Unreview context action只適用於clicked row就是current／selected file row | Filename、current、reviewed、stats與comment count（若有）**MUST** 為獨立semantics | **MUST NOT** 將row indicator變成未授權toggle或寫入GitHub viewed state |
| Diff reader | Native reading／scroll surface | Selected change anchor **MUST** 可focus、reveal與restore；page scroll不得暗改selection | Change／file navigation與comment依context routing；standard scroll input保持system behavior | Hunk、line、added／removed與content **MUST** 有可讀語意 | **MUST NOT** 在非code chrome使用水平scroll或新增submit/review action |
| Context menus | Native contextual menu | 作用target **MUST** 是clicked item；沒有clicked item時才使用明示selected item；Mark／Unreview只在clicked file row同時為current／selected row時適用 | 只mirror該context已存在且可用的Open、Comment、Mark／Unreview等能力；clicked non-current file不得出現或執行Mark／Unreview | Enablement **MUST** 與menu／toolbar一致 | **MUST NOT** 新增product capability、偷偷切tab，或為執行Mark／Unreview先改selection |
| Menu commands | Application menu與responder/context routing | Command **MUST** 只由active workspace、focus與capability決定；inactive context不得攔截 | Command Matrix 是最小counterpart集合 | Disabled、checked／selected與shortcut display **MUST** 使用native semantics | **MUST NOT** 以global key monitor繞過editable、modal或VoiceOver |

自訂視覺 **MUST NOT（不得）**覆蓋 system accent、inactive-window appearance、Increase Contrast 或 Reduce Motion 的可辨識性。Implementation **MAY（可以）**選擇合適的原生 container，只要上述 observable semantics 完整成立。

## 8. Window and Resize Contract

### Checkpoints

| Checkpoint | Required behavior |
| --- | --- |
| `preferred` | 初始 presentation baseline **MUST** 為 1440 × 900；這是preferred而非唯一可用尺寸。Inbox與Reader兩個互斥workspace在各自啟用時，於此尺寸皆 **MUST** 完整呈現其既有chrome、主要content與action，且無非diff水平overflow。 |
| `half-window` | Window約為一般桌面半寬時，layout **MUST** 先壓縮secondary metadata與spacing，再收斂navigation column；主要title／identity、active content與核心actions仍可達。不得以遮擋toolbar、tabs或footer換取雙欄常駐。 |
| `narrow usable` | 在仍可用的窄視窗中，Inbox **MUST** 套用固定metadata降階；Reader **MUST** 保留一個可閱讀的主要surface，File Navigator可收合但selection必須保持，所有既有commands仍可由menu或標準focus到達。 |
| `minimum supported` | Lower bound **MUST** 由「toolbar／tabs／狀態不互相遮擋、核心command可達、主要reading surface可讀、Composer可完整操作、非diff chrome無水平scroll」決定。此topic沒有accepted數字，故 **MUST NOT** 猜測point size；future Swift topic **MUST** 在planning鎖定實際scene constraints並以本observable lower bound驗證。 |

### Fixed degradation priorities

Inbox row縮窄時 **MUST（必須）**依下列順序保留，且只能由低優先資訊向上收斂：

1. PR title
2. Repository／PR identity
3. Context
4. Author
5. Secondary metadata

換言之，secondary metadata最先隱藏或縮寫，其次author，再其次context；PR title與repository／PR identity **MUST NOT（不得）**因保留低優先資訊而消失。

Reader縮窄時 **MUST（必須）**依下列順序處理：

1. 保留Back、active tab、狀態與既有核心action的可達性。
2. 保留Diff／active tab主要content的垂直閱讀面。
3. File Navigator先縮到可辨識row identity的minimum，再透過可見collapse affordance收合；selection不得清除。
4. 收斂secondary metadata、裝飾與非必要spacing；不得先犧牲主要reading content。

### Columns, filenames, and scrolling

- Inbox sidebar與File Navigator **MUST（必須）**各自具有ideal寬度、可辨識內容的minimum behavior及可見collapse affordance；實際數值留給future Swift topic鎖定。
- Diff pane **MUST（必須）**取得剩餘expandable width；navigation column不得無上限擴張。
- Long filename視覺上 **MAY（可以）**截斷，但完整identity **MUST（必須）**可透過accessibility label及一個secondary affordance取得；截斷 **MUST NOT（不得）**不可恢復。
- 只有diff／code **MAY（可以）**水平scroll。水平位置在同一file／change閱讀期間 **SHOULD（應）**保持；切換file時不得把舊file的水平位置誤套為新file語意。
- Sidebar或File Navigator collapse／expand **MUST（必須）**保留selection、reviewed state與scroll restoration anchor。

## 9. Large Diff Navigation Contract

- **Change navigation**：Arrow Up／Down或等價command只有在active Files tab的Diff／Change Reader reading focus中 **MUST（必須）**依F-09移動current file內selected change；首尾 **MUST（必須）**no-op。File Navigator中的Arrow Up／Down **MUST（必須）**依F-08移動file selection，不得觸發change navigation。新change anchor以minimum necessary scroll reveal，並依F-09接收focus。
- **File navigation**：Option+Arrow Up／Down或等價command只在active Files tab的Diff／Change Reader reading focus切換file；首尾 **MUST（必須）**no-op。成功後selection **MUST（必須）**是new file及其第一個appropriate change，focus落在new change anchor並minimum reveal；anchor不存在時唯一fallback為new selected file row。File Navigator direct selection仍依F-08，reviewed state不得因兩種導覽改變。
- **Page Up／Page Down**：**MUST（必須）**移動約一個viewport並保留閱讀重疊／連續性；它們 **MUST NOT（不得）**把每次viewport移動當成selected change變更。
- **Space／Shift-Space**：若native scroll context沿用system behavior，**MUST（必須）**分別執行向下／向上page scroll；button、editable、Composer與VoiceOver interaction優先，且此行為 **MUST NOT（不得）**升格為global product shortcut。
- **Trackpad**：連續scroll **MUST（必須）**只改viewport；跨越hunk不自動改selected change。若使用者明示選取change，才更新selection。
- **Scrollbar**：thumb、track與accessibility scroll actions **MUST（必須）**操作同一scroll context；不得產生不同於trackpad的selected change語意。
- **Selected change reveal**：reveal **MUST（必須）**只移動足以讓anchor可讀的距離；不得無條件置中或跳到file頂端。
- **Overview → Files restoration**：返回Files時，若saved selected change anchor有效，**MUST（必須）**恢復該PR的selected file、selected change與合理scroll anchor。Saved anchor失效或缺少時，selection **MUST（必須）**保持selected file，focus落在該selected file row；不得自動選第一個appropriate change、reveal不存在的anchor或選擇任意可見hunk。此fallback不改變F-08對新file selection正規化為第一個change的規則。
- Keyboard、trackpad、scrollbar與programmatic reveal **MUST（必須）**共享同一scroll state，且不得互相覆寫仍有效的selection。

## 10. Accessibility Contract

### File semantics

- 每個file row的accessible representation **MUST（必須）**包含filename、current selection、reviewed／unreviewed、change statistics及存在時的comment count。
- Current與reviewed **MUST（必須）**是兩個可同時成立的semantic states；不得將selected等同reviewed。
- 完整path若不在visual row完整顯示，**MUST（必須）**仍可由accessible name／description取得。

### Diff／change semantics

- Diff **MUST（必須）**提供change／hunk grouping、added／removed line、line number與relevant content的可理解reading order。
- 裝飾性syntax tokens、line背景或diff glyph **MUST NOT（不得）**污染VoiceOver reading order或造成同一內容重複朗讀。
- Selected change anchor **MUST（必須）**具穩定accessible identity，讓F-05、F-09、F-10、F-11、F-14、F-16與F-17可恢復。

### State, announcements, and system preferences

- Selection、reviewed、offline、error、completion與disabled **MUST NOT（不得）**只靠color、selection background或icon color；至少另有文字、shape、symbol加label或semantic state。
- Review progress、file transition、Mark／Unreview與completion **SHOULD（應）**使用局部、去重複announcement。整個workspace **MUST NOT（不得）**設為live region。
- Loading、error與offline announcement **MUST（必須）**說明內容是否可讀及可採取的recovery，但不得重複朗讀整個workspace。
- Increase Contrast開啟時，selection、focus ring、reviewed/current與disabled差異 **MUST（必須）**仍可辨識；custom color不得壓過system contrast semantics。
- Window inactive時，selection與focus **MUST（必須）**呈現native inactive語意；reviewed/current仍須以非色彩資訊可辨識。
- Reduce Motion開啟時，workspace、tab、sidebar、selection與Composer transition **MUST（必須）**移除非必要animation；狀態變更結果與focus restoration不得延遲或缺失。
- Keyboard-only使用者 **MUST（必須）**能完成Open Reader、四tabs、Files閱讀、change／file navigation、Mark／Unreview、Comment、Finish及Back；不得要求pointer-only gesture。
- VoiceOver interaction期間，single-key Reader commands **MUST NOT（不得）**攔截screen-reader操作；系統或輔助技術處理後不得再重複執行Reader command。

## 11. UI Input Requirements

下列項目只定義Presentation需要的資訊與缺值退化。它們 **MUST NOT（不得）**被轉譯為Logic計算、storage、Domain model、Application API、commit SHA／hash／baseline判斷或Integration來源決策。

### UIIR-NI-001 — Inbox presentation availability

```text
UI Input Requirement: UIIR-NI-001 — Inbox presentation availability
Required information: UI能區分loading、content、empty、error、offline-with-existing-content、offline-without-content，並知道既有PR rows是否仍可閱讀。
Presentation use: 決定Inbox matrix row、stale/offline indicator、selection可否呈現及Open Reader是否可用。
Missing-input degradation: 顯示offline-without-content或error的安全狀態；不顯示PR rows、不啟用Open Reader，保留可恢復selection identity但不宣稱row存在。
Prohibited decisions: 不定義狀態如何計算、資料從何處取得、cache／network／retry policy或Inbox membership規則。
```

### UIIR-NI-002 — Reader readability and recovery

```text
UI Input Requirement: UIIR-NI-002 — Reader readability and recovery
Required information: UI能區分loading、content、error、offline-with-readable-existing-content、offline-without-readable-content，並知道目前Reader snapshot是否仍可安全閱讀。
Presentation use: 決定Reader matrix row、content是否保留、哪些本地reading/navigation actions可用及recovery affordance。
Missing-input degradation: 視為沒有可證明的readable content；顯示清楚狀態與Back/recovery，不顯示diff或可操作progress。
Prohibited decisions: 不定義snapshot來源、cache、transport、retry、同步或PR Reader資料模型。
```

### UIIR-NI-003 — Stable presentation identities

```text
UI Input Requirement: UIIR-NI-003 — Stable presentation identities
Required information: UI取得足以在目前presentation snapshot內辨識Inbox row、PR、file、change anchor及Composer opening target的穩定identity與有效性。
Presentation use: 執行F-01～F-17的selection、focus與scroll restoration，以及判斷唯一fallback何時啟用。
Missing-input degradation: 不嘗試猜測或模糊比對；使用該transition明示的唯一fallback，整體content失效時交由state matrix接管。
Prohibited decisions: 不定義Domain identity、commit hash、baseline演算法、儲存格式或跨session persistence。
```

### UIIR-NI-004 — Review presentation state

```text
UI Input Requirement: UIIR-NI-004 — Review presentation state
Required information: UI能針對目前PR／file區分current selection、reviewed／unreviewed、reviewed count、file count及是否全部reviewed。
Presentation use: 同時呈現current與reviewed semantics，驅動Review Changes／Continue Review／Finish Reading、Mark／Unreview與progress announcement。
Missing-input degradation: 顯示review state unavailable；不得假設reviewed、不得顯示completion或啟用Finish，且不以selection推算reviewed。
Prohibited decisions: 不定義review progress如何計算／儲存、ReadingSession、ReviewedBaseline、GitHub viewed state或任何write contract。
```

### UIIR-NI-005 — File and change presentation metadata

```text
UI Input Requirement: UIIR-NI-005 — File and change presentation metadata
Required information: UI取得filename／完整identity、change statistics、存在時的comment count、ordered changes及每個change可呈現的hunk／line semantics。
Presentation use: File Navigator row、Diff reading order、VoiceOver label、change navigation與selected anchor reveal。
Missing-input degradation: 保留可取得的filename；缺少stats／comment count時省略該欄而不顯示假零值；缺少可讀change時顯示明確unavailable state並停用change navigation。
Prohibited decisions: 不定義DTO、parser、mapper、GitHub API、diff transport、comment來源或line計算。
```

### UIIR-NI-006 — Action safety and capability availability

```text
UI Input Requirement: UIIR-NI-006 — Action safety and capability availability
Required information: UI知道既有Open、Comment、Mark、Unreview、Finish、recovery與mock-only actions在目前context是否可安全執行及disabled原因。
Presentation use: 統一toolbar、menu、context menu與keyboard routing的enablement，尤其是error／offline與mock-only controls。
Missing-input degradation: Action保持disabled並提供可理解的disabled semantics；不得樂觀執行、偷偷切tab或宣告成功。
Prohibited decisions: 不定義authorization、network、retry、persistence、business eligibility、review submission或外部API。
```

### UIIR-NI-007 — Scroll restoration anchor

```text
UI Input Requirement: UIIR-NI-007 — Scroll restoration anchor
Required information: UI取得目前selected file／change的presentation-local scroll anchor是否仍有效，以及可供minimum necessary reveal的target bounds。
Presentation use: Overview → Files、tab往返、file／change navigation與focus restoration時維持閱讀連續性。
Missing-input degradation: Selection保持selected file，focus落在該selected file row；不得自動選第一個appropriate change或reveal不存在的anchor。若selected file也失效，交由Reader presentation state處理，不猜測任意可見hunk。
Prohibited decisions: 不定義anchor persistence、storage、diff版本比對、commit hash或跨snapshot mapping algorithm。
```

## 12. SwiftUI Implementation Acceptance Criteria

下列 criteria只驗收observable behavior；future implementation **MAY（可以）**選擇內部SwiftUI／AppKit結構，但 **MUST NOT（不得）**以內部方便為由改變結果。

| ID | Given/context | Action | Observable result | Source trace |
| --- | --- | --- | --- | --- |
| AC-NI-001 | Inbox有可選PR，且selected PR分別處於首次開啟或已有saved Reader session | 啟動app、進入Inbox並以Enter開Reader | Inbox focus在恢復row，否則第一row；首次開啟進Overview title／Overview tab fallback；重開恢復saved active tab並直接進Overview title、Files saved change、first commit或first check及各自fixed fallback | F-01／F-02；Draft 3.1；Baseline TC-05／per-PR continuity；本topic TC-03 |
| AC-NI-002 | Reader tab strip可用 | Click、Enter／Space、Arrow Left／Right、Home／End明示啟用各tab，再Tab進content | 明示tab activation的focus先留active tab；Overview／Files／Commits／Checks再分別依F-04～F-07進固定target與fallback，不受F-02重開direct restoration改寫 | F-03～F-07；Draft 3.1；本topic TC-03 |
| AC-NI-003 | Files有多個files／changes | 選file或navigate change | File selection留在row且change設第一個；change selection移到anchor並minimum reveal；target失效時只用F-08／F-09 fallback | F-08／F-09；Baseline Interaction Contract；TC-03／TC-09 |
| AC-NI-004 | Current file未reviewed且尚有unreviewed file | 啟用Mark Reviewed | 選next unreviewed與其第一change，focus到change anchor；無pointer即可繼續navigation | F-10；Draft 3.1；Baseline Review Progress；TC-03 |
| AC-NI-005 | Mark後形成全files reviewed，或current已reviewed | 啟用Mark／Mark as Unreviewed | 完成時留最後change且只announcement；Unreview留原file/change並focus新Mark action | F-11／F-12；Baseline TC-09／TC-10；TC-03 |
| AC-NI-006 | Files reading target有效 | 開啟、Cancel、Escape或Save Composer | Focus進editor且modal containment；關閉依opening target → current change anchor → selected file row，selected file亦失效才交Reader state matrix；selection／progress不變 | F-13／F-14；Baseline TC-12；TC-03 |
| AC-NI-007 | Reader從任意tab返回 | Back或合格Finish | Focus回原Inbox row；row消失才回第一row；Back中性，Finish保留8/8且Inbox invariants不變 | F-15；Baseline TC-10／TC-13；TC-03 |
| AC-NI-008 | Diff與Review Actions可用 | 標準Tab／Shift-Tab | 未reviewed進Mark，reviewed進Unreview；Shift-Tab固定回current change；不可用時採唯一fallback | F-16／F-17；Draft 3.1；TC-03 |
| AC-NI-009 | Inbox依序收到六種presentation state | 觸發loading、content、empty、error、兩種offline | 每態九欄行為成立；empty無failure語氣；有內容offline保留selection，無內容offline不暗示內容可用 | §4；Draft 3.2；TC-04 |
| AC-NI-010 | Reader依序收到五種presentation state | 觸發loading、content、error、兩種offline；在Review Action持有focus時轉入offline-readable | 每態九欄行為成立；readable content保留selection／progress；disabled Review Action依current change anchor → selected file row恢復focus，Files content失效才進state heading；無content時不顯示diff或可用review action | §5；Draft 3.2；TC-05 |
| AC-NI-011 | Files content有效且沒有輸入衝突 | 使用change／file／comment／review／Finish／Back commands | 只有valid context執行；無global interception、無偷偷切tab／workspace，結果符合Command Matrix | §6；Draft 3.3；Baseline Interaction Contract；TC-06 |
| AC-NI-012 | Focus在text input、Composer、editable native control或VoiceOver interaction | 輸入C、Arrow、Option+Arrow、Space或其他衝突鍵 | Control／VoiceOver優先，Reader command不執行且state／focus不被背景handler改變 | §6；Draft 3.3／3.7；Baseline TC-12；TC-06／TC-10 |
| AC-NI-013 | Toolbar、menu與適用context menu同時可見 | 比較既有action的名稱、enablement與執行結果 | Toolbar action有等價menu；context menu只mirrorclicked／selected item既有能力；non-current file row不顯示或執行Mark／Unreview，三處結果一致 | §6／§7；Draft 3.3／3.4；TC-06／TC-07 |
| AC-NI-014 | Inbox與Reader在native containers呈現 | 使用sidebar、list、toolbar、tabs、file navigator與diff | Native selection／focus／inactive semantics成立；Reader取代Inbox，current與reviewed正交，沒有新capability | §7；Draft 3.4；Baseline region model；TC-07 |
| AC-NI-015 | Window以1440 × 900初次顯示 | 開啟Inbox與Reader各主要tab | 完整chrome、primary content與actions可達；非diff content無水平overflow或遮擋 | §8 preferred；Draft 3.5；Baseline 1440×900；TC-08 |
| AC-NI-016 | Window縮至half-window | 檢查Inbox與Reader | Secondary metadata先收斂；title／identity、active content與核心actions仍可達；不以遮擋維持雙欄 | §8 half-window；Draft 3.5；TC-08 |
| AC-NI-017 | Window縮至narrow usable | 檢查Inbox metadata與Reader navigation | Inbox依固定優先序降階；Reader保留一個可讀surface，File Navigator可collapse且selection不丟失 | §8 narrow；Draft 3.5；TC-08 |
| AC-NI-018 | Window接近future topic鎖定的minimum supported constraints | 操作tabs、reading、commands與Composer | Toolbar／tabs／狀態不遮擋，核心commands可達，Composer完整；非diff無水平scroll；低於此界限由scene constraint阻止 | §8 minimum；Draft 3.5；TC-08 |
| AC-NI-019 | Sidebar／File Navigator含selection，並有long filename | Collapse、expand與縮窄column | Selection／reviewed／anchor保留；filename可截斷但完整identity可由accessibility與secondary affordance取得 | §8；Draft 3.5；TC-08 |
| AC-NI-020 | Large diff含多file／change | 在Diff／Change Reader使用Arrow與Option+Arrow，並在File Navigator直接選file | Change只在file內移動；Option+Arrow選new file＋first change並focus new change anchor，anchor不存在只回new file row；File Navigator direct selection只依F-08；首尾no-op且reviewed state不變 | §9；Draft 3.6；Baseline navigation；TC-09 |
| AC-NI-021 | Diff viewport可scroll | 使用Page Up／Down及合格Space／Shift-Space | Viewport保有閱讀重疊；selected change不因page movement自動改變；input／VoiceOver衝突優先 | §9；Draft 3.6；TC-09 |
| AC-NI-022 | 同一diff scroll context | 分別使用trackpad與scrollbar | 兩者只移動viewport且不產生矛盾selection；selected change只由明示selection command改變 | §9；Draft 3.6；TC-09 |
| AC-NI-023 | Files有saved selected file／change／scroll anchor | 從Overview返回Files或reveal target | Anchor有效時恢復三者並只做minimum necessary scroll；anchor失效或缺少時selection保持selected file、focus落selected file row，且不自動選第一change或reveal不存在anchor | §9；F-05；Draft 3.6；TC-09 |
| AC-NI-024 | VoiceOver啟用且File Navigator有current／reviewed rows | 逐row導覽 | 讀到filename、current、reviewed／unreviewed、stats與存在時comment count；current與reviewed可同時成立 | §10 File；Draft 3.7；TC-10 |
| AC-NI-025 | VoiceOver啟用且Diff有多hunk／line | 閱讀diff並navigate change | Hunk grouping、added／removed、line number與content依序可讀；decorative token不重複污染reading order | §10 Diff；Draft 3.7；TC-10 |
| AC-NI-026 | UI呈現selection、reviewed、offline、error、completion與disabled | 移除color或以單色／高對比檢視 | 每個重要狀態仍有文字、shape、symbol label或semantic state；announcement局部且去重複 | §10 State；Draft 3.7；TC-10 |
| AC-NI-027 | System accent或semantic system colors變更 | 操作selection與review state | UI使用semantic system colors；system accent依native semantics套用，且重要狀態仍保有非色彩辨識 | §7／§10；Draft 3.4／3.7／3.8；TC-10／TC-12 |
| AC-NI-028 | Reduce Motion開啟 | 切workspace、tab、sidebar、selection與Composer | 非必要animation移除；state result、focus restoration與announcement不延遲或遺失 | §10；Draft 3.7；TC-10／TC-12 |
| AC-NI-029 | 不使用pointer | 完成Inbox→Reader→Files→Mark／Unreview→Comment→Finish／Back | 全流程可由keyboard與menu完成；focus ring與deterministic restoration持續可見／可讀 | §3／§6／§10；Draft 3.1／3.7；TC-03／TC-06／TC-10 |
| AC-NI-030 | Mock-only或disabled control存在，例如未實作的外部action | 以pointer、keyboard、VoiceOver檢查 | Control清楚表達disabled／mock-only，不接收成功語意、不產生side effect，也不暗示已提供能力 | §2／§7；Draft 3.8；Baseline disabled Open on GitHub；TC-12 |
| AC-NI-031 | 任一UI Input Requirement缺失 | 顯示對應surface | 套用該UIIR的safe degradation，不猜測值、不宣告completion、不擴張Logic／Domain／Integration | §11；Draft 5；TC-11／TC-12 |
| AC-NI-032 | Error／offline發生前已有selection、progress與content | 進入error或offline state，再recovery | Readable content的selection／progress保持；不可讀時只保存identity且不呈現假content；recovery不預設清零 | §4／§5；Draft 3.2；TC-04／TC-05／TC-12 |
| AC-NI-033 | 同一file可為current與reviewed，且有comment/draft | 選取、comment、save/cancel draft | Current／reviewed同時可見；comment/draft不改review state或navigation | §2／§10；Baseline TC-08／TC-12；TC-02／TC-10／TC-12 |
| AC-NI-034 | Review progress分別為partial與complete | 使用Back與Finish | Back任意progress中性返回；Finish只在complete可用；兩者均保留Inbox membership/count/metadata | §2／CMD-NI-011／012；Baseline TC-10；TC-02／TC-06／TC-12 |
| AC-NI-035 | Increase Contrast開啟 | 操作selection、focus、review state與disabled control | Selection、focus ring、reviewed／current與disabled差異仍清楚可辨識；custom appearance不壓過system contrast semantics | §7／§10；Draft 3.4／3.7／3.8；TC-10／TC-12 |
| AC-NI-036 | Window由active變為inactive，或由inactive恢復active | 檢查selection、focus與review state | Selection與focus使用native inactive-window semantics；reviewed／current仍以非色彩資訊可辨識，恢復active時不遺失state | §7／§10；Draft 3.4／3.7／3.8；TC-10／TC-12 |

## 13. Future Swift Topic Admission Schema

任何 future Swift implementation topic 在進入 Plan-Reviewer 前，其同slug四份planning artifacts **MUST（必須）**完整填寫下列九欄。本topic **MUST NOT（不得）**代填future slug、branch、paths、API、types或implementation steps。

| Field | Required semantics |
| --- | --- |
| `Goal` | **MUST** 恰好描述一個bounded native capability的可觀察、可驗收outcome。 |
| `Non-Goal` | **MUST** 明示不重設計workflow、不重開adopted contract、不順帶實作Logic／Domain／Integration或其他capability。 |
| `In-Scope` | **MUST** 只包含唯一bounded capability及其必要UI surface／behavior；可獨立驗收的其他能力不得綁入。 |
| `Out-Of-Scope` | **MUST** 列出其他BC、Logic、Integration、deferred capabilities與未授權UI。 |
| `ReadOnly` | **MUST** 列出exact repository-relative existing file paths；只能讀取，**MUST NOT** 修改。 |
| `Written` | **MUST** 列出exact repository-relative new file paths；沒有時填`None`，且每個path在baseline **MUST NOT** 已存在。 |
| `Modify` | **MUST** 列出exact repository-relative existing file paths；沒有時填`None`。 |
| `Deleted` | **MUST** 列出exact repository-relative existing file paths及逐項必要性／recoverability；預設`None`。 |
| `TestCase` | 每項 **MUST** 具stable ID、context／trigger、observable expected result、evidence method與本adopted contract trace。 |

Path sets **MUST（必須）**遵守：

- `ReadOnly`、`Written`、`Modify`、`Deleted` 四組 **MUST（必須）**兩兩互斥；同一路徑不得跨set。
- Path **MUST（必須）**是精確的repository-relative file path；**MUST NOT（不得）**使用glob、directory-only allowlist、未解析變數、絕對路徑、`相關檔案`、`必要時`、`受影響檔案`或其他模糊描述。
- `Written` path在baseline **MUST NOT（不得）**存在；`Modify`、`Deleted`與`ReadOnly` path在baseline **MUST（必須）**存在。
- `Written`、`Modify`或`Deleted`沒有項目時 **MUST（必須）**明示`None`；`Deleted`的預設 **MUST（必須）**是`None`。
- Future topic 的slug、branch、ownership、唯一bounded capability或exact paths尚未鎖定時，planning verdict **MUST（必須）**是`blocked`；agent **MUST NOT（不得）**猜測。
- Future `TestCase` **MUST（必須）**至少覆蓋其選定capability所對應的 `AC-NI-###` rows，並保留到evidence與review handoff。

## 14. Traceability Index

| Contract area | Draft source | Adopted baseline evidence | Verification |
| --- | --- | --- | --- |
| Status、ownership、唯一durable output與HTML不變 | Draft 1、4、6、9 | Baseline HC-03 `採用`；repository Presentation／BC boundaries | TC-01、TC-02、TC-14 |
| Terms、Inbox／Reader目的、workflow、current／reviewed與Finish／Back invariants | Draft 2 | Baseline requirements的Required Experience；technical spec的Review Progress／Workspace State Machine | TC-02 |
| Focus State Machine F-01～F-17 | Draft 3.1、7A | Baseline technical spec的Workspace State Machine／Interaction Contract；首次開啟workflow與per-PR saved tab／selection continuity | TC-03 |
| Inbox Presentation State Matrix | Draft 3.2、7B | Adopted Inbox workspace、selection與返回continuity | TC-04 |
| Reader Presentation State Matrix | Draft 3.2、7B | Adopted Reader workspace、per-PR selection／progress continuity | TC-05 |
| Command Matrix | Draft 3.3、7C | Baseline Files-only shortcuts、Composer guard、Mark／Unreview、Finish／Back behavior | TC-06 |
| Native macOS Container Contract | Draft 3.4 | Adopted Inbox／Reader互斥workspace與Files region model | TC-07 |
| Window and Resize Contract | Draft 3.5、7D | 1440 × 900 accepted prototype baseline；native-readiness SHOULD FIX | TC-08 |
| Large Diff Navigation Contract | Draft 3.6 | Adopted file／change selection、Overview↔Files continuity | TC-09 |
| Accessibility Contract | Draft 3.7、7E | Adopted current／reviewed／progress semantics、native progress accessibility與Composer guard | TC-10 |
| UI Input Requirements boundary | Draft 4、5 | Repository layer／ownership invariants；baseline prototype-local Presentation state boundary | TC-11 |
| SwiftUI observable acceptance criteria | Draft 3.8、7F、9 | 全部adopted workflow evidence與HC-03 adoption | TC-12 |
| Future Swift Topic Admission Schema | Draft 5、8、9的boundary與future-topic gate；本topic locked planning decision | Baseline HC-03只允許另開正式SwiftUI topic，不自動實作 | TC-13 |
| Human Review gate | Draft 8、9 | Baseline HC-03 Human boundary；本topic Reviewer／Human routing | TC-14 |

本契約完成後 **MUST（必須）**先交Tester驗證TC-01～TC-14，再由獨立Reviewer明示verdict。只有Reviewer `approved` 才能進入Human Review；Human只能明示 `採用`、`調整`或`放棄`。Human `採用`只允許另開正式Swift implementation topic，**MUST NOT（不得）**由本topic自動命名branch、建立artifacts或開始implementation。
