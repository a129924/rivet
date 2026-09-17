# macOS Native Interaction Contract 技術規格

## Topic 與 Locked Decisions

- Topic：`macos-native-interaction-contract`
- Ownership：non-BC Presentation contract；不新增或移動任何 Bounded Context ownership。
- Work branch：`docs/macos-native-interaction-contract`
- 唯一 durable output：`docs/presentation/native-interaction-contract.md`
- 已採用 HTML interaction baseline 不變；本 topic 只消除 native implementation-readiness ambiguity。
- Durable output 是行為契約，不是 SwiftUI implementation design；不得指定 production type、API、package、state storage 或 framework escape。
- 本 topic 不修改 prototype、Swift、Logic、Domain、Integration、networking 或 persistence。
- Reviewer 通過後停止於 Human Review；只有 Human `採用` 才可另開 Swift implementation topic。

## Normative Contract Structure

Durable output 必須依序包含下列章節；可增加導讀，不可移除或合併到無法逐項 trace 的段落：

1. `Status, Ownership, and Sources`
2. `Terms and Invariants`
3. `Focus State Machine`
4. `Inbox Presentation State Matrix`
5. `Reader Presentation State Matrix`
6. `Command Matrix`
7. `Native macOS Container Contract`
8. `Window and Resize Contract`
9. `Large Diff Navigation Contract`
10. `Accessibility Contract`
11. `UI Input Requirements`
12. `SwiftUI Implementation Acceptance Criteria`
13. `Future Swift Topic Admission Schema`
14. `Traceability Index`

Normative statements使用 `MUST`、`MUST NOT`、`SHOULD`、`MAY` 並附繁體中文解釋。文件不得把 prototype 的 HTML DOM、CSS 或 JavaScript shape誤寫成 native requirement。

## Terms and Invariants

- Inbox purpose：`Find work.`；Reader purpose：`Understand work.`。
- Reader 是取代 Inbox 的獨立 workspace，不是 Inbox 第三欄 detail view。
- 已採用的首次開啟路徑保持：Inbox → Open PR → Reader Overview → Review Files → Files／Diff → Mark Reviewed → Next File → Continue Review → All Files Reviewed → Finish Reading → Inbox。重開同一PR不強制回Overview，而是依F-02恢復saved active tab並直接套用該tab既有deterministic content target。
- Files 核心 loop保持：Read Diff → Navigate Change → Navigate File → Mark Reviewed → Next Unreviewed File → Continue。
- `current selection` 與 `reviewed` 是正交 presentation state；comment 不代表 reviewed。
- `empty` 是成功 presentation state，不得與 error 混淆。
- Error／offline 不得無條件清除既有 selection 或 review progress；沒有 readable content 時不得暗示 content 可用。
- Context menu 只能 mirror 已存在能力；native mapping 不得新增 product capability。
- 只有 code／diff content 可以採用水平 scrolling。

## Focus State Machine Requirements

Durable output 必須以 table 記錄 `Source focus`、`Event/action`、`Destination focus`、`Selection behavior`、`Restoration behavior`、`Accessibility effect`，至少含下列 regions：

- Inbox PR List
- Reader Overview
- Reader Tabs
- File Navigator
- Diff／Change Reader
- Review Actions
- Comment Composer

至少建立下列 transition rows。每列的primary destination與destination失效時的fallback都是唯一且有順序的契約；不得使用「可進入」、「適當位置」、「最後有意義」或以`A或B`留給Implementer選擇：

| Transition ID | Required transition |
| --- | --- |
| F-01 | App／Inbox 初次進入，將 focus 放在目前選取的 PR list row；若有可恢復 selection則使用它，否則使用第一個可選 row。 |
| F-02 | Inbox Enter／Open Reader後保留來源Inbox selection供返回恢復。首次開啟該PR時啟用Overview，primary destination固定為PR title heading；若heading尚未建立或無法接收programmatic focus，唯一fallback是Overview tab。重開同一PR時恢復saved active tab並直接套用該tab既有deterministic content target：Overview為PR title heading、失效時回Overview tab；Files為saved selected change anchor、失效時保持selected file且focus selected file row，不自動選第一個change；Commits為first visible commit、失效時回Commits tab；Checks為first visible check、失效時回Checks tab。重開恢復不改寫F-03～F-07對明示tab activation與content entry的既有語意。 |
| F-03 | Reader tab由click、Enter／Space或tab strip內的Arrow Left／Right、Home／End依既有baseline啟用後，focus固定留在新啟用tab，不自動跳入content。若target tab在event完成前失效，selection與focus都留在原active tab。 |
| F-04 | Overview tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為Overview的PR title heading；若heading失效，focus留在Overview tab。 |
| F-05 | Files tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為saved selected change的Diff／Change Reader anchor；anchor有效時恢復該PR的selected file／change與scroll anchor。若saved selected change anchor失效，保持selected file並將focus固定到該selected file row，不得自動選取該file的第一個change。 |
| F-06 | Commits tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為第一個可見commit row；若沒有commit row，focus留在Commits tab。 |
| F-07 | Checks tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為第一個可見check row；若沒有check row，focus留在Checks tab。 |
| F-08 | File Navigator選取另一file後，focus固定留在新selected file row。目標file有可讀change時，change selection正規化為第一個change；目標file沒有可讀change時，selected file仍有效、selected change明示為unavailable／不存在，不建立假anchor，focus仍在selected file row，change-dependent navigation／comment依既有safe rules disabled。若target file在event完成前失效，selection不變且focus留在原selected file row。 |
| F-09 | Change navigation後，focus固定移到新selected change的Diff／Change Reader anchor，reveal採minimum necessary scroll；若target change失效，selection不變且focus留在原selected change anchor。 |
| F-10 | Mark Reviewed後若尚有unreviewed file，選下一個unreviewed file；該file有可讀change時選第一個change並將focus固定交給其Diff／Change Reader anchor，anchor失效時唯一fallback是新selected file row。該file沒有可讀change時，selected file仍有效、selected change明示為unavailable／不存在，不建立假anchor，focus固定為新selected file row，change-dependent navigation／comment依既有safe rules disabled。不得將focus留在已消失或失效的Mark Reviewed action。 |
| F-11 | Mark Reviewed形成8/8時，保留最後marked file／change並將focus固定交回該selected change的Diff／Change Reader anchor；若change anchor失效，唯一fallback是最後marked file row。Completion以局部announcement表達，不接收focus且不自動啟動Finish。 |
| F-12 | Mark as Unreviewed保持同一file／change；re-render後primary destination固定為新的Mark Reviewed action。若該action失效，唯一fallback是目前selected file row。 |
| F-13 | Composer open後primary destination固定為composer body editor並形成modal focus containment；若body editor無法建立，composer不得保持開啟，focus回到觸發event前的opening target。 |
| F-14 | Composer Cancel／Escape／Save關閉後使用固定ordered fallback chain：opening target → current selected change的Diff／Change Reader anchor → selected file row → 僅當selected file亦失效時，才交給當前Reader presentation state matrix明示的focus target。Keyboard `C`開啟時，opening target就是觸發前的focus target；不得跳過chain中的有效target。 |
| F-15 | Back to Inbox／Finish Reading後，primary destination固定為先前保留的Inbox selection row；若該row已不存在，唯一fallback是Inbox第一個可選row。不得任意重設到其他row。 |
| F-16 | Diff／Change Reader使用標準Tab向前進入Review Actions時，primary destination由目前review state唯一決定：current未reviewed時為Mark Reviewed；current已reviewed時為Mark as Unreviewed。若對應action不可用，focus留在目前selected change anchor。這是標準focus traversal，不新增product shortcut。 |
| F-17 | Review Actions使用標準Shift-Tab向後返回reading surface時，primary destination固定為目前selected change的Diff／Change Reader anchor；若該anchor失效，唯一fallback是目前selected file row。Mark／Unreview action啟用後的focus另由F-10～F-12決定。 |

F-10 是核心 keyboard loop gate：next unreviewed file有可讀change時，`Mark Reviewed → next unreviewed file → first change reveal → Diff/Change reading focus` 必須可連續操作；沒有可讀change時只選file並focus其row，不得合成change或anchor。F-02區分首次開啟與重開同一PR：首次開啟固定進Overview title／tab fallback；重開恢復saved active tab並直接使用F-04～F-07的deterministic content target。Overview ↔ Files restoration不保留模糊的focus history：Overview依F-04進入PR title heading；Files依F-05進入saved selected change anchor，失效時保持selected file並只回selected file row，不自動選第一個change。Reader處於`content`且任一明示transition的primary destination與ordered fallback都因referenced content unavailable而失效時，terminal focus固定為目前active Reader tab；此規則不新增heading、presentation state、transition ID或UI capability。

Composer開啟期間若背景Reader轉為`offline-without-readable-content`，Composer保持modal且背景保持inert；working copy不得自動保存或丟棄，focus固定留在body editor。Save Draft只在目前content與action safety已知且安全時enabled。Cancel／Escape關閉後依F-14針對當前offline state求值；不可讀背景使content targets失效時，focus固定交給`offline-without-readable-content`的offline heading。此規則不定義persistence或新workflow。

Save Draft的trimmed內容為空白時必須disabled；stale activation為no-op，Composer保持開啟、focus留在editor、working copy與saved draft都不變，且不得宣告saved。不得以此新增submit或persistence行為。

## Presentation State Matrices

Inbox 與 Reader 必須分為兩張 matrix；共同欄位固定為：`State`、`Workspace chrome`、`Primary content`、`Preserved state`、`Focus target`、`Enabled actions`、`Disabled actions`、`Recovery`、`Accessibility announcement`。

### Inbox Required Rows

- `loading`
- `content`
- `empty`
- `error`
- `offline-with-existing-content`
- `offline-without-content`

### Reader Required Rows

- `loading`
- `content`
- `error`
- `offline-with-readable-existing-content`
- `offline-without-readable-content`

每列必須遵守：

- Workspace chrome在可合理保留時維持，避免狀態切換造成 context loss。
- `empty` 顯示成功完成的無內容結果，不顯示 failure language或 retry-as-error。
- Existing selection／review progress只有在其 referenced content仍可閱讀時保留；不可因 error／offline自動清除。
- Reader處於`content`且明示transition的primary destination與fallback因referenced content unavailable全部失效時，terminal focus固定為目前active Reader tab；不得另造heading或隱含state。
- Inbox availability input缺失時唯一fallback是`error`，不得推定offline；只有offline狀態已知時才可使用offline rows。缺值的error state不得顯示PR rows或啟用Open，focus固定為error heading，recovery依下列safe-capability規則。
- Offline with content明示stale／offline狀態並禁止需要network或不可安全執行的action，但保留local reading/navigation。
- Reader轉入`offline-with-readable-existing-content`時，若Review Action正持有focus且該action因offline而disabled，focus固定移到current selected change anchor；若anchor失效，唯一fallback是selected file row；只有Files content亦失效時，才交給該Reader presentation state matrix row明示的focus target。
- Offline without content不顯示虛假的reader content或可用action；focus落在清楚的狀態與recovery affordance。
- Loading／error／offline announcement採一次性、局部且可理解的狀態更新；不得把整個workspace設為live region。
- Error／offline recovery只有在capability已知且可安全執行時enabled；capability或safety資訊缺失時顯示可理解的disabled affordance，不得樂觀執行或宣告成功。
- Retry／recovery只定義UI affordance與enablement，不定義network、retry、authentication、cache或其他policy。
- Composer開啟期間背景可轉為`offline-without-readable-content`，但Composer維持modal、背景inert、focus在editor且working copy不自動保存／丟棄；Save enablement依目前content與action safety，Cancel／Escape關閉後focus該offline row的heading。

## Command Matrix

固定欄位為：`Command ID`、`Command`、`Valid focus/context`、`Enabled when`、`Disabled/conflict behavior`、`Observable result`、`Menu counterpart`、`Context-menu counterpart`。

至少包含：

- Enter → Open Reader
- Arrow Up／Down → Change navigation
- Option+Arrow Up／Down → File navigation
- C → Comment
- Escape → Close／cancel composer
- Mark Reviewed
- Mark as Unreviewed
- Finish Reading
- Back to Inbox
- Show／Hide Sidebar

所有 rows 必須符合：

- 不得以 global shortcut 無條件攔截。
- 文字輸入、Comment Composer、editable controls 與 VoiceOver interaction優先；衝突時 Reader command不執行。
- Command context不成立時保持 state與focus，不偷偷切換 tab或workspace。
- `Open` context item只在clicked Inbox PR row同時是selected row時提供；clicked row不是selected row時不得顯示或執行`Open`，亦不得為了`Open`暗改selection。實際Open仍由CMD-NI-002語意處理selected PR並保留F-02返回點。
- `CMD-NI-006` Option+Arrow Up／Down只在既有Files reading context切換file；new file有可讀change時，selection固定為new file＋第一個change並focus new change anchor，anchor失效時唯一fallback是new selected file row；new file沒有可讀change時，只選new file、selected change為unavailable／不存在且focus new selected file row，不建立假anchor，change-dependent navigation／comment disabled。F-08只描述File Navigator內的direct selection，不得拿來改寫此command result，也不得新增transition ID或shortcut。
- Save Draft只在trimmed working copy非空白且action safety成立時可用；trim後空白必須disabled。Stale activation為no-op，Composer保持開啟、focus editor、working／saved draft不變且不宣告saved。
- Toolbar action 必須有合理 menu counterpart；context menu只有已存在且適用於 clicked／selected item 的能力。
- 不新增 Draft 未列出的 workflow 或 shortcut。

## Native macOS Container Contract

Durable output 必須為每個 region 記錄 `Native role`、`Selection/focus semantics`、`Commands/menu`、`State representation`、`Forbidden expansion`：

- Inbox sidebar：native sidebar behavior與標準 Show／Hide Sidebar。
- Inbox PR list：native single-selection semantics；selection與open為不同action。`Open` context item只適用於clicked row同時是selected row；non-selected clicked row不得顯示／執行`Open`或暗改selection。
- Reader toolbar：只承載既有高階action，並由menu提供等價command。
- Reader tabs/navigation：提供既有 Overview／Files／Commits／Checks，不新增能力。
- File navigator：native list selection；current與reviewed可同時表達。
- Diff reader：閱讀與change navigation surface；code/diff可水平scroll，其他chrome不可。
- Context menus：只mirror現有能力，依context enable／disable；Inbox `Open`只適用於clicked row同時是selected row，且不得以context action改變selection。
- Menu commands：遵循responder/context routing；inactive context不攔截。

System accent、inactive-window appearance、Increase Contrast與Reduce Motion交給native semantics；自訂呈現不得覆蓋其可辨識性。

## Window and Resize Contract

- Preferred initial presentation baseline固定為 1440 × 900；不得誤寫為唯一可用尺寸。
- Durable output必須定義 `preferred`、`half-window`、`narrow usable`、`minimum supported` 四個檢查點與 minimum useful size。若 minimum數值沒有已接受來源，不得猜測數字；以內容不遮擋、核心command可達、主要閱讀面可用的observable lower bound表示，並標記 downstream Swift topic須在 planning時鎖定實際scene constraints。
- Inbox窄化時固定保留優先序：PR title → repository／PR identity → context → author → secondary metadata。
- Sidebar與File Navigator必須各自定義min／ideal behavior與collapse affordance；collapse不得遺失selection。
- Diff pane取得剩餘 expansion；只有diff/code可水平scroll。
- Long filename必須可辨識完整identity（例如accessibility label或secondary affordance），不得只靠不可恢復的visual truncation。
- Column degradation必須有固定優先序，不得任由Swift implementation臨場決定。

## Large Diff Navigation Contract

Durable output必須分別定義：change navigation、file navigation、Page Up／Page Down、沿用system behavior時的Space／Shift-Space、trackpad、scrollbar、selected change reveal、Overview → Files restoration。

- Keyboard、trackpad與scrollbar都是同一scroll context的不同input，不得產生互相矛盾的selected change。
- Page movement保留閱讀連續性；不將每次viewport移動誤當selected change變更。
- File Navigator direct selection依F-08選取new file；有可讀change時將change selection正規化為第一個change，沒有可讀change時selected change為unavailable／不存在且focus selected file row。Option+Arrow Up／Down同樣只在new file有可讀change時選第一個change並focus其anchor；沒有可讀change時只選file並focus其row。兩者均不得建立假anchor，change-dependent navigation／comment依既有safe rules disabled；Change navigation只在目前file內移動。
- 返回Files時，saved selected change anchor有效才恢復selected file／change與scroll anchor，reveal採最小必要scroll，不無條件置中或跳到頂端。
- Saved selected change anchor失效時保持selected file並focus selected file row，不得自動以該file第一個change替代；這項restoration fallback不得與F-08 direct new-file selection或Option+Arrow file switch的正常化混用。

## Accessibility Contract

### File semantics

VoiceOver可取得 filename、current selection與reviewed／unreviewed；change statistics與comment count都只有資料存在時才必須可讀。依UIIR-NI-005，缺少任一metadata時省略該欄，不得顯示或宣告假`0`；current與reviewed必須是兩個可同時成立的semantic state。此規則只定義Presentation degradation，不定義Logic、DTO或data source。

### Diff／Change semantics

VoiceOver可取得change／hunk grouping、added／removed line、line number與relevant content；裝飾性token不得污染閱讀順序。

### State semantics

- 重要狀態不得只靠color、selection background或icon color。
- Review progress、file transition與completion可使用局部、去重複announcement；整個workspace不得是live region。
- Increase Contrast、inactive window、Reduce Motion與keyboard-only operation必須有獨立acceptance row。
- VoiceOver操作期間，single-key Reader commands不得攔截screen-reader或文字輸入行為。

## UI Input Requirement Boundary

若 Presentation 需要尚未由 Logic 定義的資訊，只可使用下列格式：

```text
UI Input Requirement: <stable ID and required presentation meaning>
Required information: <what UI must distinguish or display>
Presentation use: <how the information affects visible/accessible state>
Missing-input degradation: <safe behavior when absent>
Prohibited decisions: <calculation, storage, Domain model, API or transport choices>
```

允許定義 UI 需要什麼、如何呈現、缺少時如何退化；禁止定義 Logic計算、儲存、Domain model、Application API、commit SHA／hash／baseline判斷或Integration來源。

## SwiftUI Implementation Acceptance Criteria

Durable output必須用穩定 `AC-NI-###` ID列出observable acceptance，至少覆蓋：

- Focus transition、restoration與F-10核心loop；包含F-02首次開啟／重開同一PR的tab與content target、F-14 composer close ordered fallback chain、無可讀change時selected file row focus且無假anchor，以及Reader `content`中referenced targets全部失效時terminal focus回目前active Reader tab。
- Inbox／Reader所有presentation states與offline兩分法；包含offline-readable transition使disabled Review Action讓出focus的ordered fallback、Reader `content`的全域terminal active-tab fallback、availability缺值唯一進error，以及recovery只在capability已知且安全時enabled。
- Native command routing、menu counterpart、context menu與editable／VoiceOver conflict；包含Option+Arrow file switch對有／無可讀change的deterministic結果、`Open` context item只在clicked row同時為selected row時存在且不得暗改selection，以及空白／stale Save Draft安全行為。
- Native toolbar、sidebar、list與tab semantics；包含non-selected clicked Inbox row不得顯示／執行`Open`。
- 1440 × 900、half-window、narrow、minimum的resize／degradation。
- Large diff keyboard／trackpad／scrollbar與scroll restoration；包含saved change anchor失效時保持selected file、focus selected file row且不自動first change。
- VoiceOver file／diff／state semantics及非色彩辨識；change statistics與comment count只在資料存在時可讀，缺值依UIIR-NI-005省略且不得顯示假`0`。
- Semantic system colors、Increase Contrast、inactive window、Reduce Motion。
- Mock-only／disabled controls必須可辨識且不可暗示可執行能力。
- Composer開啟時背景轉`offline-without-readable-content`仍保持modal／inert、focus editor與working copy；Save依content／action safety，Cancel／Escape後focus offline heading且不新增persistence。
- AC-NI-009／010／031必須驗收availability缺值、known-offline與safe recovery；AC-NI-006及applicable command acceptance必須驗收Composer offline與空白／stale Save Draft。不得改寫F-17、CMD-NI-015、AC-NI-036、TC-14或UIIR-NI-007既有語意。

每列固定包含 `ID`、`Given/context`、`Action`、`Observable result`、`Source trace`；不得指定無必要的SwiftUI type或internal implementation。

## Future Swift Topic Admission Schema

| Field | Required semantics |
| --- | --- |
| Goal | 恰好一個 bounded native capability的可觀察、可驗收outcome。 |
| Non-Goal | 明示不重設計workflow、不重開adopted contract、不順帶實作Logic／Domain／Integration或其他capability。 |
| In-Scope | 唯一bounded capability及其必要UI surface／behavior。 |
| Out-Of-Scope | 其他BC、Logic、Integration、deferred capabilities與未授權UI。 |
| ReadOnly | Exact repository-relative existing file paths；可讀但不得修改。 |
| Written | Exact repository-relative new file paths；無則`None`，且baseline時不得已存在。 |
| Modify | Exact repository-relative existing file paths；無則`None`。 |
| Deleted | Exact repository-relative existing file paths與逐項理由；預設`None`。 |
| TestCase | Stable ID、context／trigger、observable result、evidence method、adopted contract trace。 |

Path rules：

- 四個path sets兩兩互斥；同一路徑不得跨set。
- 禁止 glob、directory-only allowlist、未解析變數、絕對路徑、`相關`／`必要`／`受影響`等模糊描述。
- `Written` path在baseline必須不存在；`Modify`／`Deleted`／`ReadOnly` path在baseline必須存在。
- `Deleted`為`None`是預設；非None必須有必要性與recoverability說明。
- Future slug、branch、ownership與paths未鎖定時，planning verdict只能是`blocked`；本 topic不得代填。

## Traceability Requirements

Traceability Index 至少建立下列 mapping：

| Contract area | Draft source | Adopted baseline evidence | Verification |
| --- | --- | --- | --- |
| Focus State Machine | Draft 3.1／7A | prototype technical spec的Workspace State Machine／Interaction Contract | TC-03 |
| Inbox／Reader Presentation State | Draft 3.2／7B | adopted workspace／selection／progress continuity | TC-04／TC-05 |
| Command Matrix | Draft 3.3／7C | adopted Files-only shortcuts、composer guard、Finish／Back behavior | TC-06 |
| Native Container | Draft 3.4 | adopted Inbox／Reader／Files region model | TC-07 |
| Window／Resize | Draft 3.5／7D | 1440 × 900 baseline與native-readiness SHOULD FIX | TC-08 |
| Large Diff Navigation | Draft 3.6 | adopted file／change selection continuity | TC-09 |
| Accessibility | Draft 3.7／7E | reviewed/current/progress semantics與Draft SHOULD FIX | TC-10 |
| SwiftUI acceptance | Draft 3.8／7F／9 | 全部adopted workflow evidence | TC-12 |
| UI Input boundary | Draft 5 | repository layer／ownership invariants | TC-11 |
| Human gate | Draft 8／9 | HC-03只授權另開topic | TC-14 |

## Public API / Interfaces

本 topic 不新增或修改 public API、Swift target、package manifest、Domain model、DTO、protocol、Facade、UseCase、Adapter、Event、Message 或 Cross-BC contract。

## Last Updated

2026-09-17
