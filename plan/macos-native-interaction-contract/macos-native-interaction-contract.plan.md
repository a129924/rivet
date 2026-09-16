# macOS Native Interaction Contract 執行計畫

## Summary

- Topic：`macos-native-interaction-contract`
- Ownership：non-BC Presentation contract
- Work branch：`docs/macos-native-interaction-contract`
- Base：建立於最新 `dev` 的獨立 worktree；此事由上游已確認，Plan-Creator不執行Git。
- 唯一 durable output：`docs/presentation/native-interaction-contract.md`
- 目的：把已採用 HTML workflow 與 UI/UX `SHOULD FIX` 轉為 native macOS 行為契約；不實作Swift。
- Current status：completed／adopted。PR-04 `approved`後，IM-01新增durable output；TE-01 Overall FAIL、RV-01 `needs-rework`後，IM-02只修改durable output完成required fixes；TE-02 Overall PASS、RV-02 `approved`後，HC-01由Human明示原值`採用`。後續`Ready PR`僅是delivery request，不授權或自動開始Swift implementation。

## Goal

交付一份可供 Human 採用的 Native Interaction Contract，以可觀察、可追溯的行為消除後續 SwiftUI implementation 在 focus、presentation state、commands、native containers、resize、large diff與accessibility上的自行猜測。

## Non-Goal

- 不實作或修改 SwiftUI、AppKit、HTML prototype、Logic、Domain、Integration、networking、persistence或tests。
- 不重設計已採用 workflow、不重開 current／reviewed、Finish／Back或Presentation Session決策。
- 不新增 public API、type、DTO、protocol、package、target或product capability。
- 不決定future Swift topic的slug、branch、paths、API或implementation steps。

## In-Scope

- 撰寫唯一 durable contract，涵蓋 Focus、Inbox／Reader state matrices、Command Matrix、Native Container、Window／Resize、Large Diff、Accessibility、UI Input Requirement、SwiftUI acceptance criteria與traceability。
- 定義 future Swift topic admission schema及exact path set互斥規則。
- 對durable document執行範圍、內容、traceability與文字格式驗證，再交獨立Reviewer與Human Check。

## Out-Of-Scope

- 任何production source／test、prototype、architecture diagram、BC文件、API或runtime變更。
- Git／commit／push／PR／merge／release與review comment處理。
- Logic如何計算、儲存或傳遞Presentation需要的資料。
- 任何未在adopted workflow或Draft列出的shortcut、menu action、context action或product workflow。

## ReadOnly

本 topic 的 source-of-truth inputs 為下列 exact repository-relative existing files，所有phase均唯讀：

- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `analysis/pr-reader-interactive-ux-prototype/requirements.md`
- `analysis/pr-reader-interactive-ux-prototype/technical-spec.md`
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md`
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md`
- `prototypes/pr-reader-interactive-ux-prototype/index.html`

Closed-world rule：除當前phase列在`Written`或`Modify`的exact path外，所有repository paths均為ReadOnly；不得以此規則擴充任何未列名寫入。

## Written

PC-01只新增：

- `analysis/macos-native-interaction-contract/requirements.md`
- `analysis/macos-native-interaction-contract/technical-spec.md`
- `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`
- `plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md`

PR-04明示`approved`後，IM-01只新增：

- `docs/presentation/native-interaction-contract.md`

以上只記錄path第一次建立時所屬的phase；後續若有已授權rework，必須改依該rework phase的`Modify` allowlist，不得把既有path再次列入`Written`。

## Modify

下列每列都是一個獨立phase的exact repository-relative allowlist；`None`表示該phase不得修改既有檔案：

| Phase | Exact `Modify` allowlist |
| --- | --- |
| PC-01 initial planning authoring | `None` |
| PC-02 focus planning rework | `analysis/macos-native-interaction-contract/requirements.md`<br>`analysis/macos-native-interaction-contract/technical-spec.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PC-03 stale focus ID correction | `analysis/macos-native-interaction-contract/technical-spec.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PC-04 workflow reference correction | `analysis/macos-native-interaction-contract/requirements.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| IM-01 initial durable authoring | `None` |
| IM-02 durable rework | `docs/presentation/native-interaction-contract.md` |
| Post-HC ledger synchronization | `plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| Post-HC status synchronization | `analysis/macos-native-interaction-contract/requirements.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md` |
| Post-HC Stop Conditions correction | `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md` |
| PR comment planning correction C1／C6（current） | `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PR comment durable correction C2／C3／C5／C7／C8（只可在PR-05 `approved`後） | `docs/presentation/native-interaction-contract.md` |
| Plan-Reviewer／Tester／Reviewer verification | `None` |

若任一`Written` path在其初次建立phase開始前已存在，該phase仍須停止並回報`blocked`，不得臨時改以`Modify`處理。C4明示不改；C9／C10只在修正push後留言說明並resolve，不增加任何repository path allowlist。

## Deleted

所有phase均為`None`。

## Path Set Rules

- `ReadOnly`、`Written`、`Modify`、`Deleted`四組path sets的兩兩互斥規則只在同一phase內成立；同一path可在初次建立phase屬`Written`、在明示授權的後續rework phase屬`Modify`，但不得在同一phase跨set。
- 每個phase都只接受exact repository-relative file path；不允許glob、directory-only write scope、絕對路徑、未解析變數或模糊path。
- 每個phase未列在該phase `Written`或`Modify` allowlist的path一律ReadOnly；`Deleted`在所有phase均為`None`。
- Current PR comment planning correction只允許修改本plan與step ledger；通過獨立PR-05後的durable correction只允許修改`docs/presentation/native-interaction-contract.md`。
- Tester須枚舉tracked／staged／unstaged／untracked paths並依phase套allowlist；普通空白diff不能證明untracked path不存在。
- Scope需要任何額外path時停止，回到planning；不得由Implementer自行擴張。

## Public API / Interfaces

不新增或修改public API、Swift target、package manifest、Domain model、DTO、protocol、Facade、UseCase、Adapter、Event、Message或Cross-BC contract。唯一新增interface是文件中的future planning admission schema，不是runtime API。

## Implementation Steps

### IM-01.1 — 建立文件骨架與來源聲明

- 只新增durable output，依technical spec的14個normative sections排列。
- 清楚區分adopted baseline、Draft `SHOULD FIX`與本文件的normative native contract。
- 聲明non-BC Presentation ownership及不改變PR Inbox、PR Reader、Presentation Session boundary。

### IM-01.2 — 寫入Focus與Presentation matrices

- 建立F-01～F-17要求的Focus State Machine table；逐列使用technical spec鎖定的唯一primary destination與唯一fallback，不得再以可選目的地或focus history讓Implementer決定。
- 明示Reader tab activation後focus留在active tab，標準Tab進入Overview／Files／Commits／Checks的固定content target，以及Diff Reader ↔ Review Actions的標準Tab／Shift-Tab traversal。
- 分開建立Inbox六態與Reader五態matrix，填滿固定欄位，不以段落含混取代cell。
- 保留selection／review progress continuity，並區分empty、error及兩類offline。

### IM-01.3 — 寫入Commands與Native Containers

- 建立所有指定commands的context／enablement／conflict／observable result／menu mapping。
- 規範sidebar、list、toolbar、tabs、file navigator、diff、context menus與menu commands的native semantics。
- 確保editable、composer與VoiceOver interaction不被single-key command破壞。

### IM-01.4 — 寫入Window、Large Diff與Accessibility

- 記錄preferred、half-window、narrow、minimum四個resize檢查點、degradation priority及scroll policy。
- 定義change／file／page／trackpad／scrollbar navigation與scroll restoration。
- 定義VoiceOver file／diff／state semantics、non-color indicators、局部announcement及system accessibility preferences。

### IM-01.5 — 寫入Boundary、Acceptance與Traceability

- 使用固定UI Input Requirement格式，禁止越界定義Logic／Domain／Integration。
- 產生具穩定`AC-NI-###` ID的observable SwiftUI acceptance criteria。
- 寫入future Swift topic九欄admission schema與path互斥規則，但不代填future slug、branch、paths或steps。
- 完成Traceability Index，逐項對應Draft、adopted baseline evidence與本plan TestCase。

## TestCase

### TC-01 — Topic與path allowlist

- 四份planning artifacts與durable output使用同一topic intent，durable output只有一份。
- PC-01只新增四份planning artifacts，IM-01只新增durable output；其後每次planning、durable與post-HC rework只修改對應phase明列的exact paths，所有phase的Deleted皆為None。
- Current C1／C6 correction只修改plan與step；後續C2／C3／C5／C7／C8 correction只修改durable output；C4不改，C9／C10不增加repository path。
- 不存在prototype、Swift、Logic、Domain、Integration、BC docs或其他tracked path變更。

### TC-02 — Baseline與ownership

- 文件引用四份`pr-reader-interactive-ux-prototype` artifacts及HC-03 `採用` evidence。
- 明示Reader不是Inbox第三欄、current／reviewed正交、comment不代表reviewed、8/8才Finish及Back中性返回。
- 明示non-BC Presentation ownership且未改變任一BC責任。

### TC-03 — Focus State Machine

- 七個focus regions與F-01～F-17都有完整table row；每列明示唯一primary destination、destination失效時的唯一fallback、selection與restoration結果。
- Inbox → Reader固定進Overview PR title heading；tab activation固定留在active tab，標準Tab分別進入Overview title、Files saved change、first commit、first check，且各自fallback符合technical spec。
- Mark Reviewed後若尚未完成，next unreviewed selection、first change reveal與Diff／Change focus形成不中斷loop；8/8固定回selected change而非focus completion status。
- Composer、Overview↔Files、返回Inbox及Diff Reader ↔ Review Actions的標準Tab／Shift-Tab皆有deterministic destination與fallback，且未新增workflow或product shortcut。

### TC-04 — Inbox Presentation State Matrix

- loading、content、empty、error、offline-with-existing-content、offline-without-content六態及九個固定欄位完整。
- Empty為成功狀態；offline兩態不混淆content可用性。

### TC-05 — Reader Presentation State Matrix

- loading、content、error、offline-with-readable-existing-content、offline-without-readable-content五態及九個固定欄位完整。
- Error／offline不無條件清除可保留的selection／progress；不可讀時不暗示content可用。

### TC-06 — Command routing

- 所有指定command均有valid context、enabled／disabled、conflict、observable result、menu與context-menu欄位。
- 無global interception；text input、composer、editable controls與VoiceOver衝突時Reader command不執行。
- 無新增shortcut或workflow。

### TC-07 — Native containers

- Sidebar、PR list、toolbar、tabs、file navigator、diff、context menus與menu commands都有native role與interaction semantics。
- Show／Hide Sidebar、native selection、toolbar menu counterpart與system inactive/accent behavior成立。
- Context menu只mirror既有能力。

### TC-08 — Window／Resize

- 1440 × 900、half-window、narrow、minimum四個檢查點完整。
- Inbox degradation依title → repository／PR identity → context → author → secondary metadata。
- 只有diff/code可水平scroll；sidebar/file navigator collapse不遺失selection。

### TC-09 — Large Diff Navigation

- Change、file、page、system Space／Shift-Space（若沿用）、trackpad、scrollbar、reveal與restoration都有明示行為。
- Overview → Files恢復selected file／change與scroll anchor；reveal採minimum necessary scroll，不無條件置中。

### TC-10 — Accessibility

- VoiceOver可辨識file identity、current/reviewed、stats/comment及diff hunk／line語意。
- 重要狀態不只靠color/background/icon color；announcement局部且workspace不是live region。
- Increase Contrast、inactive window、Reduce Motion與keyboard-only各有acceptance row。

### TC-11 — UI Input Requirement boundary

- 每個Logic缺口使用固定格式，僅描述required information、presentation use與missing-input degradation。
- 無計算、儲存、Domain model、Application API、hash/baseline或Integration來源決策。

### TC-12 — SwiftUI acceptance criteria

- 每列使用穩定`AC-NI-###`、Given/context、Action、Observable result、Source trace。
- 覆蓋native routing、menus、toolbar、sidebar、resize、large diff、VoiceOver、system colors與mock-only controls。
- 不指定不必要的SwiftUI internal type或implementation detail。

### TC-13 — Future Swift admission schema

- Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Modify、Deleted、TestCase九欄皆有精確語意。
- 四個path sets互斥，Written／Modify／Deleted允許`None`，Deleted預設`None`；禁止模糊path。
- 未代填future slug、branch、paths或implementation steps。

### TC-14 — Traceability與Human boundary

- Focus、Presentation、Command、Container、Resize、Large Diff、Accessibility、Acceptance、Boundary與Human Gate皆映射Draft、adopted baseline與TestCase。
- 只有最新獨立Reviewer明示`approved`才進HC-01；實際RV-01為`needs-rework`，經IM-02／TE-02後RV-02為`approved`，因此HC-01 entry gate成立。
- HC-01已completed且Human decision原值為`採用`；TC-14已由TE-02驗證PASS並由RV-02審查`approved`。
- Human `採用`只允許未來另開正式Swift implementation topic，不自動實作；`Ready PR`僅是本topic delivery request。

## Workflow / Gates

1. `PC-01` — Plan-Creator只新增四份planning artifacts；完成不構成approval。
2. `PR-01` — 獨立Plan-Reviewer已明示`needs-rework`；唯一finding是Focus State Machine含非唯一destination／fallback且缺少tabs與Diff／Review focus transitions。
3. `PC-02` — Plan-Creator只修改四份planning artifacts完成上述required fix；完成不構成approval。
4. `PR-02` — 新的獨立Plan-Reviewer已明示`needs-rework`；唯一finding是SwiftUI acceptance criteria將Mark Reviewed核心loop誤標為F-07。
5. `PC-03` — Plan-Creator已將該stale ID更正為F-10並更新ledger；完成不構成approval。
6. `PR-03` — 新的獨立Plan-Reviewer已明示`needs-rework`；唯一finding是requirements、plan與ledger仍含stale workflow entry gate。
7. `PC-04` — Plan-Creator只同步workflow references至PR-04；不修改contract內容，完成不構成approval。
8. `PR-04` — 新的獨立Plan-Reviewer已明示`approved`；Findings None。
9. `IM-01` — Implementer已只新增`docs/presentation/native-interaction-contract.md`並完成交接。
10. `TE-01` — Tester已完成；Overall FAIL，TC-08因preferred wording失敗、TC-10因缺少獨立accessibility rows失敗，其餘TestCase PASS。
11. `RV-01` — 獨立Reviewer已明示`needs-rework`；required fixes僅為互斥workspace wording、拆分AC-NI-027、新增AC-NI-035／AC-NI-036。
12. `IM-02` — Implementer已只修改durable output完成RV-01 required fixes。
13. `TE-02` — Tester已完成；Overall PASS，TC-01～TC-14全部PASS，無blocker。
14. `RV-02` — 獨立Reviewer已明示`approved`；Findings None。
15. `HC-01` — Human已明示decision原值`採用`；本topic completed／adopted並停止自動前進。
16. `Post-HC-01` — Human另要求`Ready PR`；此為delivery request，不改變contract verdict，也不是Swift implementation approval。

任何checkbox、step status、Plan-Creator self-check或Tester結果都不等於Plan-Reviewer／Reviewer approval。

## Stop Conditions

- PR-04或RV-01 verdict為`needs-rework`：只交回對應產出角色並附required fixes；不得改寫歷史verdict或跳過重新驗證／審查。
- 任一Plan-Reviewer／Reviewer verdict為`blocked`或`human-check`：停止自動前進並交Human。
- IM-01 entry時若durable output path已預存、工作需要allowlist外path，或發現baseline／Draft衝突：回報`blocked`，不得猜測、改path或擴張scope。
- 出現workflow、ownership、Logic／Domain／Integration或product capability drift：停止並回planning，不得在implementation或delivery中改寫contract。
- 到HC-01後不得自動選擇Human decision，亦不得自動命名、建立或實作Swift topic。

## Completion Outcome

- PR-04實際verdict為`approved`；TE-01 Overall FAIL與RV-01 `needs-rework`依上述規則只回Implementer，IM-02完成required fixes後由TE-02驗證TC-01～TC-14全部PASS，RV-02明示`approved`且Findings None。
- HC-01已由Human明示decision原值`採用`；本topic completed／adopted，沒有pending contract gate或topic content blocker。
- Earlier PR-01、PR-02、PR-03與RV-01的`needs-rework`保留原值，不因最終完成而改寫為`approved`。

## Delivery Boundary

- Human另要求`Ready PR`，只授權本topic的delivery流程；delivery狀態、GitHub操作或PR結果都不改變contract verdict。
- `採用`與`Ready PR`均不授權或自動開始Swift implementation；任何future Swift implementation仍必須另開正式topic。
- Delivery若發現超出既有allowlist或contract的變更，必須停止並回到適當planning／Human routing，不得在delivery中擴張scope。

## Last Updated

2026-09-16
