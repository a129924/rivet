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
- 已採用主流程保持：Inbox → Open PR → Reader Overview → Review Files → Files／Diff → Mark Reviewed → Next File → Continue Review → All Files Reviewed → Finish Reading → Inbox。
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
| F-02 | Inbox Enter／Open Reader後，primary destination固定為Reader Overview的PR title heading；保留來源Inbox selection供返回恢復。若heading尚未建立或無法接收programmatic focus，唯一fallback是已啟用的Overview tab。 |
| F-03 | Reader tab由click、Enter／Space或tab strip內的Arrow Left／Right、Home／End依既有baseline啟用後，focus固定留在新啟用tab，不自動跳入content。若target tab在event完成前失效，selection與focus都留在原active tab。 |
| F-04 | Overview tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為Overview的PR title heading；若heading失效，focus留在Overview tab。 |
| F-05 | Files tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為已保存selected change的Diff／Change Reader anchor，並恢復該PR的selected file／change與scroll anchor；若selected change anchor失效，唯一fallback是同一selected file row。 |
| F-06 | Commits tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為第一個可見commit row；若沒有commit row，focus留在Commits tab。 |
| F-07 | Checks tab啟用時，使用標準Tab向前離開tab strip的primary destination固定為第一個可見check row；若沒有check row，focus留在Checks tab。 |
| F-08 | File Navigator選取另一file後，focus固定留在新selected file row，並將change selection正規化為該file第一個change；若target file在event完成前失效，selection不變且focus留在原selected file row。 |
| F-09 | Change navigation後，focus固定移到新selected change的Diff／Change Reader anchor，reveal採minimum necessary scroll；若target change失效，selection不變且focus留在原selected change anchor。 |
| F-10 | Mark Reviewed後若尚有unreviewed file，選下一個unreviewed file、選其第一個change並將focus固定交給該change的Diff／Change Reader anchor；若change anchor失效，唯一fallback是新selected file row。不得將focus留在已消失或失效的Mark Reviewed action。 |
| F-11 | Mark Reviewed形成8/8時，保留最後marked file／change並將focus固定交回該selected change的Diff／Change Reader anchor；若change anchor失效，唯一fallback是最後marked file row。Completion以局部announcement表達，不接收focus且不自動啟動Finish。 |
| F-12 | Mark as Unreviewed保持同一file／change；re-render後primary destination固定為新的Mark Reviewed action。若該action失效，唯一fallback是目前selected file row。 |
| F-13 | Composer open後primary destination固定為composer body editor並形成modal focus containment；若body editor無法建立，composer不得保持開啟，focus回到觸發event前的opening target。 |
| F-14 | Composer Cancel／Escape／Save關閉後，primary destination固定回到opening target；若opening target已失效，唯一fallback是目前selected change的Diff／Change Reader anchor。Keyboard `C`開啟時，opening target就是觸發前的focus target。 |
| F-15 | Back to Inbox／Finish Reading後，primary destination固定為先前保留的Inbox selection row；若該row已不存在，唯一fallback是Inbox第一個可選row。不得任意重設到其他row。 |
| F-16 | Diff／Change Reader使用標準Tab向前進入Review Actions時，primary destination由目前review state唯一決定：current未reviewed時為Mark Reviewed；current已reviewed時為Mark as Unreviewed。若對應action不可用，focus留在目前selected change anchor。這是標準focus traversal，不新增product shortcut。 |
| F-17 | Review Actions使用標準Shift-Tab向後返回reading surface時，primary destination固定為目前selected change的Diff／Change Reader anchor；若該anchor失效，唯一fallback是目前selected file row。Mark／Unreview action啟用後的focus另由F-10～F-12決定。 |

F-10 是核心 keyboard loop gate：`Mark Reviewed → next unreviewed file → first change reveal → Diff/Change reading focus` 必須可連續操作。Overview ↔ Files restoration不保留模糊的focus history：Overview一律依F-04進入PR title heading；Files一律依F-05進入已保存selected change anchor，失效時只回selected file row。

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
- Offline with content明示stale／offline狀態並禁止需要network或不可安全執行的action，但保留local reading/navigation。
- Offline without content不顯示虛假的reader content或可用action；focus落在清楚的狀態與recovery affordance。
- Loading／error／offline announcement採一次性、局部且可理解的狀態更新；不得把整個workspace設為live region。
- Retry／recovery只定義UI affordance與enablement，不定義retry policy、networking或cache來源。

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
- Toolbar action 必須有合理 menu counterpart；context menu只有已存在且適用於 clicked／selected item 的能力。
- 不新增 Draft 未列出的 workflow 或 shortcut。

## Native macOS Container Contract

Durable output 必須為每個 region 記錄 `Native role`、`Selection/focus semantics`、`Commands/menu`、`State representation`、`Forbidden expansion`：

- Inbox sidebar：native sidebar behavior與標準 Show／Hide Sidebar。
- Inbox PR list：native single-selection semantics；selection與open為不同action。
- Reader toolbar：只承載既有高階action，並由menu提供等價command。
- Reader tabs/navigation：提供既有 Overview／Files／Commits／Checks，不新增能力。
- File navigator：native list selection；current與reviewed可同時表達。
- Diff reader：閱讀與change navigation surface；code/diff可水平scroll，其他chrome不可。
- Context menus：只mirror現有能力，依context enable／disable。
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
- File navigation選取新file後reveal appropriate change；change navigation只在目前file內移動。
- 返回Files時恢復selected file／change與合理scroll anchor；reveal以最小必要scroll為原則，不無條件置中或跳到頂端。
- 缺少可恢復anchor時才採用該file的第一個appropriate change作deterministic fallback。

## Accessibility Contract

### File semantics

VoiceOver可取得 filename、current selection、reviewed／unreviewed、change statistics與存在時的comment count；current與reviewed必須是兩個可同時成立的semantic state。

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

- Focus transition、restoration與F-10核心loop。
- Inbox／Reader所有presentation states與offline兩分法。
- Native command routing、menu counterpart、context menu與editable／VoiceOver conflict。
- Native toolbar、sidebar、list與tab semantics。
- 1440 × 900、half-window、narrow、minimum的resize／degradation。
- Large diff keyboard／trackpad／scrollbar與scroll restoration。
- VoiceOver file／diff／state semantics及非色彩辨識。
- Semantic system colors、Increase Contrast、inactive window、Reduce Motion。
- Mock-only／disabled controls必須可辨識且不可暗示可執行能力。

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

2026-09-16
