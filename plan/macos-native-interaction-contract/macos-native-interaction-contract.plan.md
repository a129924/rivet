# macOS Native Interaction Contract 執行計畫

## Summary

- Topic：`macos-native-interaction-contract`
- Ownership：non-BC Presentation contract
- Work branch：`docs/macos-native-interaction-contract`
- Base：建立於最新 `dev` 的獨立 worktree；此事由上游已確認，Plan-Creator不執行Git。
- 唯一 durable output：`docs/presentation/native-interaction-contract.md`
- 目的：把已採用 HTML workflow 與 UI/UX `SHOULD FIX` 轉為 native macOS 行為契約；不實作Swift。
- Current status：原topic維持completed／adopted。上一輪PR-10 `approved`、IM-06 completed、TE-08 PASS、RV-10 `approved`、Human commit message confirmed、DL-05 commit `4ea0af9`、DL-06 push與DL-07三threads reply＋resolve均已完成。PC-11 entry baseline的PR head、local HEAD與origin head皆為`4ea0af9`且working tree clean。本輪6個threads均unresolved／non-outdated；RV-11已明示`needs-rework`並鎖定T1～T6。PC-11已完成planning correction，下一gate唯一為獨立PR-11；IM-07／TE-09／RV-12／DL-08～DL-10均pending。此cycle不授權或自動開始Swift implementation。

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
| PR comment planning correction C1／C6（PC-05） | `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PR comment durable correction C2／C3／C5／C7／C8（只可在PR-05 `approved`後） | `docs/presentation/native-interaction-contract.md` |
| PC-07／PC-08 N1～N6 planning／technical correction | `analysis/macos-native-interaction-contract/technical-spec.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PR-07／PR-08 planning verification | `None` |
| IM-04 N1～N6 durable correction（只可在PR-08 `approved`後） | `docs/presentation/native-interaction-contract.md` |
| TE-06／RV-07 verification | `None` |
| PC-09 planning／state sync（completed） | `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PR-09 planning verification | `None` |
| IM-05 terminal matrix fallback correction（只可在PR-09 `approved`後） | `docs/presentation/native-interaction-contract.md` |
| TE-07／RV-08 verification | `None` |
| DL-03／DL-04 delivery | `None` |
| PC-10 U1～U3 planning／technical correction（completed） | `analysis/macos-native-interaction-contract/technical-spec.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PR-10 planning verification | `None` |
| IM-06 U1～U3 durable correction（只可在PR-10 `approved`後） | `docs/presentation/native-interaction-contract.md` |
| TE-08／RV-10 verification | `None` |
| DL-05 human-confirmed commit／DL-06 push／DL-07 thread resolution | `None` |
| PC-11 T1～T6 planning／technical correction（current） | `analysis/macos-native-interaction-contract/technical-spec.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md`<br>`plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` |
| PR-11 planning verification | `None` |
| IM-07 T2～T6 durable correction（只可在PR-11 `approved`後） | `docs/presentation/native-interaction-contract.md` |
| TE-09／RV-12 verification | `None` |
| DL-08 human-confirmed commit／DL-09 push／DL-10 six-thread resolution | `None` |
| Plan-Reviewer／Tester／Reviewer verification | `None` |

若任一`Written` path在其初次建立phase開始前已存在，該phase仍須停止並回報`blocked`，不得臨時改以`Modify`處理。C4明示不改；C9／C10只在修正push後留言說明並resolve，不增加任何repository path allowlist。

## Deleted

所有phase均為`None`。

## Path Set Rules

- `ReadOnly`、`Written`、`Modify`、`Deleted`四組path sets的兩兩互斥規則只在同一phase內成立；同一path可在初次建立phase屬`Written`、在明示授權的後續rework phase屬`Modify`，但不得在同一phase跨set。
- 每個phase都只接受exact repository-relative file path；不允許glob、directory-only write scope、絕對路徑、未解析變數或模糊path。
- 每個phase未列在該phase `Written`或`Modify` allowlist的path一律ReadOnly；`Deleted`在所有phase均為`None`。
- PC-07／PC-08只允許修改相同的technical spec、plan與step ledger exact paths；allowlist scope不變，`requirements.md`與durable contract在兩個phase均ReadOnly。只有獨立PR-08明示`approved`後，IM-04才只允許修改`docs/presentation/native-interaction-contract.md`。
- PC-09只允許修改plan與step ledger；technical spec、requirements與durable contract均ReadOnly。只有獨立PR-09明示`approved`後，IM-05才只允許修改`docs/presentation/native-interaction-contract.md`；該cycle已完成delivery。
- PC-10的`Written`與`Deleted`均為`None`，`Modify`只包含technical spec、plan與step ledger三個exact paths；PR-10 `approved`後IM-06只修改durable contract，該cycle已完成delivery。
- Current PC-11的`Written`與`Deleted`均為`None`，`Modify`只包含technical spec、plan與step ledger三個exact paths；requirements、durable contract及所有未列paths均ReadOnly。只有獨立PR-11明示`approved`後，IM-07的`Modify`才只包含`docs/presentation/native-interaction-contract.md`；其`Written`／`Deleted`仍為`None`，其他paths全為ReadOnly。
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

### IM-04.1 — 套用N1～N6 deterministic interaction corrections

- 只修改durable output；不得修改planning artifacts、prototype、Swift或其他path。
- F-02區分首次開啟PR與重開同一PR；首次固定Overview title／tab fallback，重開恢復saved active tab並直接使用Overview／Files／Commits／Checks既有deterministic content target。
- F-05與Large Diff restoration在saved change anchor失效時保持selected file、focus selected file row且不自動first change；保留F-08 direct File Navigator selection的first-change normalizing semantics。
- F-14使用opening target → current selected change anchor → selected file row → Reader state matrix focus target的固定ordered fallback chain。
- Option+Arrow file switch選new file＋第一change並focus new change anchor，anchor不存在只回new selected file row；不得新增F ID或shortcut。
- Reader進入offline-readable時，若focused Review Action因offline disabled，依selected change anchor → selected file row → state matrix focus target轉移focus。

### IM-04.2 — 同步acceptance與traceability

- 只調整N1～N6涉及的Focus、Reader matrix、Command、Large Diff與SwiftUI acceptance／traceability rows，不重寫其他已採用contract。
- 保持F-03～F-07既有tab activation／content entry語意；N1對F-05的fallback clarification及N6對F-02的first-open／reopen routing除外。
- 不新增TestCase ID、product capability、shortcut、runtime API或implementation detail。

### IM-05.1 — 修正全域terminal matrix fallback

- 只修改durable output；不得修改planning artifacts、technical spec、requirements、prototype、Swift或其他path。
- 只修正RV-07 finding 1：將durable contract中需要terminal matrix fallback的相關敘述一致指向當前Reader Presentation State Matrix明示的focus target。
- 不改N1～N6 semantics、F IDs、TestCase行為、product capability、shortcut、runtime API或其他contract內容。

### IM-06.1 — 套用U1～U3 bounded durable corrections

- 只修改durable output；不得修改planning artifacts、requirements、prototype、Swift或其他path。
- U1（thread `PRRT_kwDOUFu0Cc6jMpuY`）：Reader為`content`且明示transition的primary／fallback都因referenced content unavailable而失效時，terminal focus固定為目前active Reader tab；同步既有Focus、Reader matrix與applicable acceptance rows，不新增heading、state、transition ID或UI capability。
- U2（thread `PRRT_kwDOUFu0Cc6jMpub`）：change statistics與comment count都只在資料存在時要求可讀；缺值依UIIR-NI-005省略且不得顯示假`0`。同步Accessibility與applicable acceptance rows，但不得定義Logic、DTO或data source。
- U3（thread `PRRT_kwDOUFu0Cc6jMpud`）：`Open` context item只在clicked Inbox PR row同時為selected row時提供；non-selected clicked row不得顯示／執行`Open`或暗改selection。CMD-NI-002仍只開啟selected PR並保留F-02返回點；同步Command、Native Container與applicable acceptance rows，不採用direct-open non-selected row。
- 不新增product capability、shortcut、runtime API、TestCase ID或artifact。

### IM-07.1 — 套用T2～T6 bounded durable corrections

- 只修改durable output；不得修改planning artifacts、requirements、prototype、Swift或其他path。T1（thread `PRRT_kwDOUFu0Cc6jOma2`）只屬workflow truth同步，不重跑PR-10～DL-07。
- T2（thread `PRRT_kwDOUFu0Cc6jOma4`）：同步F-08、F-10、CMD-NI-006與Large Diff。有可讀change時沿用原語意；沒有可讀change時只保留有效selected file、selected change為unavailable／不存在、focus selected file row，不建立假anchor，change-dependent navigation／comment依既有safe rules disabled。
- T3（thread `PRRT_kwDOUFu0Cc6jOma6`）：error／offline recovery只在capability已知且安全時enabled；資訊缺失時顯示可理解的disabled affordance且不得樂觀執行。同步AC-NI-009／010／031，不定義network／retry／authentication policy。
- T4（thread `PRRT_kwDOUFu0Cc6jOma-`）：Inbox availability input缺失唯一進`error`；offline只在known offline使用。不顯示PR rows、不啟用Open、focus error heading，recovery依T3。
- T5（thread `PRRT_kwDOUFu0Cc6jOmbC`）：Composer開啟時背景可轉`offline-without-readable-content`，Composer仍modal、背景inert、working copy不自動保存／丟棄且focus editor。Save依content／action safety；Cancel／Escape後focus offline heading，不新增persistence／workflow。
- T6（thread `PRRT_kwDOUFu0Cc6jOmbG`）：trim後空白Save Draft disabled；stale activation no-op，Composer保持開啟、focus editor、working／saved draft不變且不宣告saved，不新增submit／persistence。
- 不新增F／CMD／AC／UIIR／TestCase ID、product capability、shortcut、runtime API或artifact；F-17、CMD-NI-015、AC-NI-036、TC-14、UIIR-NI-007及ownership／non-BC／Human boundary維持既有語意。

## TestCase

### TC-01 — Topic與path allowlist

- 四份planning artifacts與durable output使用同一topic intent，durable output只有一份。
- PC-01只新增四份planning artifacts，IM-01只新增durable output；其後每次planning、durable與post-HC rework只修改對應phase明列的exact paths，所有phase的Deleted皆為None。
- PC-05只修改plan與step，IM-03只修改durable output；PC-07／PC-08只修改相同的technical spec、plan與step exact paths，PR-08 `approved`後的IM-04只修改durable output。所有其他paths均ReadOnly，所有phase的Deleted皆為None。
- PC-10只修改technical spec、plan與step三個exact paths；PR-10 `approved`後IM-06只修改durable output。兩個phase的Written／Deleted皆為None，其他paths均ReadOnly。
- PC-11只修改technical spec、plan與step三個exact paths；PR-11 `approved`後IM-07只修改durable output。兩個phase的Written／Deleted皆為None，其他paths均ReadOnly。
- 不存在prototype、Swift、Logic、Domain、Integration、BC docs或其他tracked path變更。

### TC-02 — Baseline與ownership

- 文件引用四份`pr-reader-interactive-ux-prototype` artifacts及該baseline topic的HC-03 `採用` evidence；不得與本topic新cycle的HC-03 `Execution Authorized`混淆。
- 明示Reader不是Inbox第三欄、current／reviewed正交、comment不代表reviewed、8/8才Finish及Back中性返回。
- 明示non-BC Presentation ownership且未改變任一BC責任。

### TC-03 — Focus State Machine

- 七個focus regions與F-01～F-17都有完整table row；每列明示唯一primary destination、destination失效時的唯一fallback、selection與restoration結果。
- 首次開啟PR固定進Overview PR title heading、失效時回Overview tab；重開同一PR恢復saved active tab並直接套用各tab deterministic content target：Overview title／tab、Files saved change anchor／selected file row、first commit／Commits tab、first check／Checks tab。F-03明示tab activation仍固定留在active tab，F-04～F-07其他語意不變。
- Mark Reviewed後若尚未完成，next unreviewed file有可讀change時沿用first change reveal與Diff／Change focus loop；沒有可讀change時只選file、selected change為unavailable／不存在且focus file row，不建立假anchor。8/8固定回selected change而非focus completion status。
- Composer close固定依opening target → current selected change anchor → selected file row → Reader state matrix focus target的ordered chain；Overview↔Files、返回Inbox及Diff Reader ↔ Review Actions的標準Tab／Shift-Tab皆有deterministic destination與fallback，且未新增workflow或product shortcut。
- Reader為`content`且某明示transition的primary destination與fallback都因referenced content unavailable而失效時，terminal focus固定為目前active Reader tab；不新增heading、state、transition ID或UI capability。
- Composer開啟期間背景轉為`offline-without-readable-content`時維持modal containment、背景inert、working copy不自動保存／丟棄及focus editor；Cancel／Escape後依目前state固定focus offline heading。

### TC-04 — Inbox Presentation State Matrix

- loading、content、empty、error、offline-with-existing-content、offline-without-content六態及九個固定欄位完整。
- Empty為成功狀態；offline兩態不混淆content可用性。
- Availability input缺失時唯一fallback為error；offline只在known offline使用。此時無PR rows／Open，focus error heading，recovery依safe capability規則。

### TC-05 — Reader Presentation State Matrix

- loading、content、error、offline-with-readable-existing-content、offline-without-readable-content五態及九個固定欄位完整。
- Error／offline不無條件清除可保留的selection／progress；不可讀時不暗示content可用。
- 轉入offline-with-readable-existing-content時，若focused Review Action因offline disabled，focus依current selected change anchor → selected file row → 該matrix row focus target的固定順序移動。
- Reader為`content`時，明示transition的referenced targets全部失效即回目前active Reader tab，作為唯一terminal focus。
- Error／offline recovery只在capability已知且安全時enabled；資訊缺失顯示可理解的disabled affordance，不樂觀執行或定義network／retry／authentication policy。
- Composer開啟時背景可轉offline-without-readable-content，但Composer保持modal、背景inert、focus editor與working copy；Save依content／action safety，Cancel／Escape後focus offline heading。

### TC-06 — Command routing

- 所有指定command均有valid context、enabled／disabled、conflict、observable result、menu與context-menu欄位。
- 無global interception；text input、composer、editable controls與VoiceOver衝突時Reader command不執行。
- Option+Arrow Up／Down切file後，new file有可讀change才選第一個change並focus其anchor；沒有可讀change時只選file、selected change為unavailable／不存在且focus file row，不建立假anchor並disabled change-dependent navigation／comment。F-08 direct selection使用同一有／無change distinction。
- `Open` context item只在clicked Inbox PR row同時為selected row時提供；non-selected clicked row不得顯示／執行`Open`或為Open暗改selection。CMD-NI-002仍只處理selected PR與F-02返回點。
- Save Draft的trimmed working copy為空白時disabled；stale activation為no-op，Composer保持開啟、focus editor、working／saved draft不變且不得宣告saved。
- 無新增shortcut或workflow。

### TC-07 — Native containers

- Sidebar、PR list、toolbar、tabs、file navigator、diff、context menus與menu commands都有native role與interaction semantics。
- Show／Hide Sidebar、native selection、toolbar menu counterpart與system inactive/accent behavior成立。
- Context menu只mirror既有能力；Inbox `Open`只適用於clicked row同時為selected row，non-selected clicked row不提供或執行`Open`且selection不變。

### TC-08 — Window／Resize

- 1440 × 900、half-window、narrow、minimum四個檢查點完整。
- Inbox degradation依title → repository／PR identity → context → author → secondary metadata。
- 只有diff/code可水平scroll；sidebar/file navigator collapse不遺失selection。

### TC-09 — Large Diff Navigation

- Change、file、page、system Space／Shift-Space（若沿用）、trackpad、scrollbar、reveal與restoration都有明示行為。
- Overview → Files只在saved change anchor有效時恢復selected file／change與scroll anchor；anchor失效保持selected file並focus selected file row，不自動first change。F-08 direct selection與Option+Arrow new-file switch只有在new file有可讀change時才正常化到第一change；沒有可讀change時selected change不存在、focus file row且不建立假anchor。Reveal採minimum necessary scroll且不無條件置中。

### TC-10 — Accessibility

- VoiceOver可辨識file identity、current/reviewed及diff hunk／line語意；change statistics與comment count只在資料存在時必須可讀，缺值依UIIR-NI-005省略且不得顯示假`0`。
- 重要狀態不只靠color/background/icon color；announcement局部且workspace不是live region。
- Increase Contrast、inactive window、Reduce Motion與keyboard-only各有acceptance row。
- Accessibility correction只定義Presentation observable result，不定義Logic、DTO或data source。

### TC-11 — UI Input Requirement boundary

- 每個Logic缺口使用固定格式，僅描述required information、presentation use與missing-input degradation。
- 無計算、儲存、Domain model、Application API、hash/baseline或Integration來源決策。
- Action／recovery safety資訊缺失時使用disabled affordance；availability缺值進error，不推定offline。UIIR-NI-007既有scroll restoration語意保持不變。

### TC-12 — SwiftUI acceptance criteria

- 每列使用穩定`AC-NI-###`、Given/context、Action、Observable result、Source trace。
- 覆蓋native routing、menus、toolbar、sidebar、resize、large diff、VoiceOver、system colors與mock-only controls；applicable rows亦驗收T2無change file、T3 safe recovery、T4 missing availability、T5 Composer offline及T6 blank／stale Save Draft。AC-NI-009／010／031須同步，AC-NI-036保持既有語意。
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
- 新cycle的RV-06 `human-check`已由HC-03原值`Execution Authorized`解除N6 conflict並鎖定N1～N6；PR-07 `needs-rework`後只有PR-08 `approved`才可進IM-04，只有RV-08 `approved`且DL-03完成commit／push後，才可由DL-04回覆並resolve新6個threads。
- 上一輪delivery完成後的baseline為PR head／local HEAD／origin head皆`952fb54`且working tree clean；本輪三個U1～U3 threads均為unresolved／non-outdated。只有PR-10 `approved`可進IM-06，只有RV-10 `approved`可進human-confirmed commit；其後依序push，再回覆並resolve三個threads。
- U1～U3 cycle已完成PR-10 → IM-06 → TE-08 → RV-10 → DL-05／DL-06／DL-07；commit為`4ea0af9`，三threads已reply＋resolve。PC-11 entry baseline三端head一致且clean；本輪6個T1～T6 threads均unresolved／non-outdated。只有PR-11 `approved`可進IM-07，只有RV-12 `approved`可進human-confirmed commit；其後依序push，再回覆並resolve6個threads。TC-14、ownership、non-BC與Human boundary維持不變。

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
17. `PC-05 → RV-05` — 上一輪PR comment bounded correction已完成planning、durable implementation、TE-05與final review；各step及earlier `needs-rework`歷史保留於ledger。
18. `DL-01` — 已completed；commit `3b62409`已push且local／remote head一致。
19. `DL-02` — 已completed；7個threads均已reply＋resolved，0 unresolved。
20. `RV-06` — Reviewer已明示`human-check`；N1～N5為bounded fixes，N6為locked conflict，已停止交Human。
21. `HC-03` — Human已明示原值`Execution Authorized`，採用Reviewer對N6的建議並授權N1～N5 bounded fixes直接處理。
22. `PC-07` — Plan-Creator已只修改必要planning artifacts，鎖定N1～N6 semantics與新cycle allowlists；完成不構成approval。
23. `PR-07` — Plan-Reviewer已明示`needs-rework`；唯一finding是technical spec通用主流程仍將所有Open PR寫成Reader Overview，須限定為首次開啟並明示重開依F-02 restoration。
24. `PC-08` — Plan-Creator已只修正上述唯一semantic finding並同步PR-08 gate；不改N1～N5、F IDs、TestCase semantics、contract其他內容或allowlist scope，完成不構成approval。
25. `PR-08` — 已明示`approved`；已放行IM-04。
26. `IM-04` — completed；只修改durable output完成N1～N6 bounded fixes。
27. `TE-06` — completed；Overall PASS，TC-01～TC-14全部PASS。
28. `RV-07` — 已明示`needs-rework`；finding 1是durable terminal matrix fallback，finding 2是stale execution artifacts，未放行delivery。
29. `PC-09` — completed；只修改plan與step同步實際狀態、phase allowlists與PR-09 routing，不改N1～N6或TestCase行為，完成不構成approval。
30. `PR-09 → DL-04` — 上一輪planning review、durable correction、TE-07、RV-08與delivery已完成；PC-10 entry baseline的PR head／local HEAD／origin head皆`952fb54`且working tree clean，上一輪threads已完成處理。
31. `RV-09` — 已明示`needs-rework`；findings只限U1 active Reader tab terminal fallback、U2 optional accessibility metadata與U3 selected-clicked-row-only `Open`，三個threads仍unresolved／non-outdated。
32. `PC-10` — completed；只修改technical spec、plan與step鎖定U1～U3 semantics、acceptance、allowlists與routing，完成不構成approval。
33. `PR-10 → DL-07` — PR-10 `approved`、IM-06 completed、TE-08 PASS、RV-10 `approved`、Human commit message confirmed、DL-05 commit `4ea0af9`、DL-06 push及DL-07三threads reply＋resolve均已完成；不得重跑舊delivery。
34. `RV-11` — 已明示`needs-rework`；findings只限T1 workflow truth與T2～T6 bounded semantics，6個threads仍unresolved／non-outdated。
35. `PC-11` — completed；只修改technical spec、plan與step鎖定T1～T6 semantics、acceptance、allowlists與routing，完成不構成approval。
36. `PR-11` — pending；只由獨立Plan-Reviewer審查PC-11，僅`approved`可進IM-07。
37. `IM-07` — pending；PR-11 `approved`後只修改durable output完成T2～T6 corrections；T1不重跑舊delivery。
38. `TE-09` — pending；IM-07後重新驗證TC-01～TC-14與T2～T6 observable results。
39. `RV-12` — pending；獨立Reviewer審查IM-07、TE-09 evidence與6 threads resolution map，僅`approved`可進delivery。
40. `DL-08` — pending；RV-12 `approved`後依`git-commit-convention`檢查staged semantic boundary，取得Human明示確認後才可commit。
41. `DL-09` — pending；DL-08 commit完成後才可push並確認local／origin head一致。
42. `DL-10` — pending；DL-09 push完成後才可依核准resolution map回覆並resolve6個T1～T6 threads。

任何checkbox、step status、Plan-Creator self-check或Tester結果都不等於Plan-Reviewer／Reviewer approval。

## Stop Conditions

- PR-04或RV-01 verdict為`needs-rework`：只交回對應產出角色並附required fixes；不得改寫歷史verdict或跳過重新驗證／審查。
- 任一Plan-Reviewer／Reviewer verdict為`blocked`或`human-check`：停止自動前進並交Human。
- IM-01 entry時若durable output path已預存、工作需要allowlist外path，或發現baseline／Draft衝突：回報`blocked`，不得猜測、改path或擴張scope。
- 出現workflow、ownership、Logic／Domain／Integration或product capability drift：停止並回planning，不得在implementation或delivery中改寫contract。
- 到HC-01後不得自動選擇Human decision，亦不得自動命名、建立或實作Swift topic。
- Current cycle若PR-11或RV-12為`needs-rework`，只交回對應產出角色；`blocked`或`human-check`停止交Human。未取得Human對commit boundary／message的明示確認不得commit；未完成commit不得push，未完成push不得reply或resolve6個T1～T6 threads。

## Completion Outcome

- PR-04實際verdict為`approved`；TE-01 Overall FAIL與RV-01 `needs-rework`依上述規則只回Implementer，IM-02完成required fixes後由TE-02驗證TC-01～TC-14全部PASS，RV-02明示`approved`且Findings None。
- HC-01已由Human明示decision原值`採用`；本topic completed／adopted，沒有pending contract gate或topic content blocker。
- Earlier PR-01、PR-02、PR-03與RV-01的`needs-rework`保留原值，不因最終完成而改寫為`approved`。
- 上一輪Ready PR delivery已由DL-01／DL-02完成；commit為`3b62409`，7個threads已reply＋resolved且0 unresolved。
- RV-06提出的N1～N6 cycle及RV-07 follow-up已完成PR-09 → IM-05 → TE-07 → RV-08 → DL-03／DL-04 delivery；PC-10 entry baseline的PR head／local HEAD／origin head皆`952fb54`且working tree clean。
- U1～U3 cycle已完成PR-10 `approved`、IM-06、TE-08 PASS、RV-10 `approved`、Human-confirmed commit、DL-05 commit `4ea0af9`、DL-06 push與DL-07三threads reply＋resolve；PC-11 entry baseline三端head一致且working tree clean。
- 新T1～T6 cycle的RV-11實際verdict為`needs-rework`；PC-11 completed，PR-11及其後IM-07／TE-09／RV-12／DL-08～DL-10仍pending。6個threads保持unresolved／non-outdated，不得當作已核准或已交付。

## Delivery Boundary

- Human另要求`Ready PR`，只授權本topic的delivery流程；delivery狀態、GitHub操作或PR結果都不改變contract verdict。
- `採用`與`Ready PR`均不授權或自動開始Swift implementation；任何future Swift implementation仍必須另開正式topic。
- Delivery若發現超出既有allowlist或contract的變更，必須停止並回到適當planning／Human routing，不得在delivery中擴張scope。

## Last Updated

2026-09-17
