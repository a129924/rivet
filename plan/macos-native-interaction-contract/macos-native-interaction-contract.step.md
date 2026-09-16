# macOS Native Interaction Contract 執行帳本

## Topic

- Slug：`macos-native-interaction-contract`
- Ownership：non-BC Presentation contract
- Work branch：`docs/macos-native-interaction-contract`
- Durable output：`docs/presentation/native-interaction-contract.md`

## Current Phase

原topic維持completed／adopted：PR-04已`approved`，durable output經IM-01／TE-01／RV-01與IM-02／TE-02／RV-02完成實作、驗證及獨立審查，Human已於HC-01明示原值`採用`。採用後的PR comment bounded rework已完成PR-05、IM-03與TE-05；RV-04 `needs-rework`的唯一ledger finding經PC-06同步後，PR-06與RV-05均已`approved`且Findings None，resolution map亦已核准。RV-05已放行DL-01；目前等待Human-confirmed commit gate，尚未執行commit、push、PR comment reply或resolve。此delivery不改變contract verdict，也不授權Swift implementation。

## Artifacts

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/macos-native-interaction-contract/requirements.md` | post-HC status synchronized; ReadOnly in current phase | Goal、scope、baseline、focus success、current workflow status、deliverables、Human gate、future admission requirement |
| `analysis/macos-native-interaction-contract/technical-spec.md` | changed by PC-03; ReadOnly in current phase | locked document structure、deterministic focus transitions、F-10核心loop reference、matrices、boundary、traceability、schema semantics |
| `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md` | modified by PC-05 for C1; ReadOnly in current phase | bounded execution contract與phase-scoped exact path allowlists |
| `plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` | synchronized after PR-06／RV-05 approvals | 同步final approvals、TE-05／RV-05 evidence與DL-01 Human-confirmed commit gate |
| `docs/presentation/native-interaction-contract.md` | written by IM-01; modified by IM-02 and IM-03; ReadOnly in current phase | 唯一durable Native Interaction Contract；IM-03 fixes已通過TE-05與RV-05，等待DL-01 commit gate |

## Steps

| ID | Status | Owner role | Work | Completion condition | Verification evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 只新增同slug四份planning artifacts，對齊adopted baseline、Draft、allowlists、TC-01～TC-14與Human boundary。 | 四份artifacts存在且對topic、ownership、durable output、scope、future schema與routing一致；未建立durable contract或修改其他path。 | 四份指定artifacts已寫入；檔案集合、必要章節、TC-01～TC-14、九欄future schema、Draft areas、absolute-path、trailing-whitespace與EOF newline self-check均通過。這不是approval。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查四份planning artifacts的decision completeness、baseline trace、scope／ownership、allowlists、TestCase與workflow。 | Plan-Reviewer明示標準verdict與required fixes。 | `needs-rework`：F-02／F-03／F-08／F-12含非唯一destination，缺少失效fallback、Files／Commits／Checks tab focus transition及Diff Reader ↔ Review Actions keyboard focus transition。 |
| PC-02 | completed | Plan-Creator | 只修改四份planning artifacts，將focus destinations／fallbacks收斂為唯一決策並補齊tabs與Diff／Review transitions。 | Requirements、technical spec、plan TC-03／completion criteria與ledger一致；F-01～F-17 decision-complete；不修改其他contract area或建立durable output。 | 四份artifacts已完成bounded focus rework；17個transition IDs各恰有一列，stale focus wording／gate掃描、absolute-path、trailing-whitespace與EOF newline self-check均通過，durable output仍不存在。這不是approval。 |
| PR-02 | needs-rework | Plan-Reviewer | 由新的獨立Plan-Reviewer重審PR-01 required fix與四份artifacts一致性。 | Plan-Reviewer明示標準verdict與required fixes。 | `needs-rework`：technical spec的SwiftUI acceptance criteria仍將Mark Reviewed核心loop誤標為F-07；唯一required fix是改為F-10並如實更新ledger。 |
| PC-03 | completed | Plan-Creator | 只將technical spec的`F-07核心loop`改為`F-10核心loop`，並更新本ledger的PR-02／PC-03／PR-03狀態。 | 只有technical spec與step ledger變更；stale reference已消除，其他contract內容與檔案保持不變。 | Targeted self-check確認technical spec中`F-07核心loop`為零筆、`F-10核心loop`恰一筆；PR-02／PC-03／PR-03與IM-01 entry gate一致，absolute-path、trailing-whitespace與EOF newline檢查通過，durable output仍不存在。這不是approval。 |
| PR-03 | needs-rework | Plan-Reviewer | 由新的獨立Plan-Reviewer重審PR-02唯一required fix與四份artifacts一致性。 | Plan-Reviewer明示標準verdict與required fixes。 | `needs-rework`：requirements current status、plan Written／Workflow／Stop Conditions與ledger仍指向舊PR-02／PR-03 entry gate；需只同步workflow references，不改contract內容。 |
| PC-04 | completed | Plan-Creator | 只同步requirements、plan與本ledger的stale workflow references，保留PR-02／PC-03／PR-03歷史並建立PR-04 gate。 | Requirements current status、plan Written／Workflow／Stop Conditions與ledger一致只允許PR-04 `approved`進IM-01；不修改F-01～F-17、TestCase semantics、scope、ownership或其他contract area。 | Targeted scan確認舊PR-02／PR-03 implementation entry references為零筆，requirements／plan／ledger只允許PR-04 `approved`進IM-01；F-01～F-17仍為17列，absolute-path、trailing-whitespace與EOF newline檢查通過，durable output仍不存在。這不是approval。 |
| PR-04 | approved | Plan-Reviewer | 由新的獨立Plan-Reviewer重審PR-03唯一required fix與四份artifacts一致性。 | Plan-Reviewer明示標準verdict。 | `approved`；Findings None。 |
| IM-01 | completed | Implementer | 在PR-04 `approved`後，只新增durable output並完成IM-01.1～IM-01.5。 | 唯一新增`docs/presentation/native-interaction-contract.md`；不修改其他contract path。 | 已新增唯一durable output；完成交接給TE-01。 |
| TE-01 | completed | Tester | 逐項驗證TC-01～TC-14、path allowlist、文件結構、內容、traceability與Human boundary。 | 每個TestCase都有明示結果與evidence。 | Overall FAIL；TC-08因preferred wording失敗，TC-10因缺少獨立accessibility rows失敗；TC-01～TC-07、TC-09、TC-11～TC-14 PASS；無此結果以外的verdict推論。 |
| RV-01 | needs-rework | Reviewer | 獨立審查durable output、scope／contract drift與TE-01 evidence。 | Reviewer明示標準verdict與required fixes。 | `needs-rework`；required fixes僅為：修正互斥workspace wording、拆分AC-NI-027、並新增AC-NI-035與AC-NI-036。 |
| IM-02 | completed | Implementer | 只修改durable output完成RV-01 required fixes。 | 互斥workspace wording修正；AC-NI-027拆分；新增AC-NI-035／AC-NI-036；無其他path變更。 | 只修改`docs/presentation/native-interaction-contract.md`並完成交接給TE-02。 |
| TE-02 | completed | Tester | 重新驗證TC-01～TC-14及RV-01 required fixes。 | 每個TestCase都有明示結果且無blocker。 | Overall PASS；TC-01～TC-14全部PASS；無blocker。 |
| RV-02 | approved | Reviewer | 獨立審查IM-02 durable output與TE-02 evidence。 | Reviewer明示標準verdict。 | `approved`；Findings None。 |
| HC-01 | completed | Human | 判斷Focus／states／interaction ambiguity、baseline alignment、scope boundary及acceptance sufficiency。 | Human明示`採用`、`調整`或`放棄`。 | Human明示原值`採用`；本topic完成，只允許未來另開正式Swift implementation topic，不自動開始它。 |
| TE-04 | completed | Tester | 對final working tree重新執行TC-01～TC-14 regression。 | 每個TestCase都有明示結果與evidence，且無blocker。 | Overall PASS；TC-01～TC-14全部PASS；無blocker。此結果不構成Reviewer approval。 |
| RV-03 | human-check | Reviewer | 審查PR #33 comments與working-tree內容，分類C1～C10。 | Reviewer列出findings並依無法自行決定的comment disposition交Human。 | 發現C1～C10並給`human-check`；未自行替Human採納、拒絕或重開scope。 |
| HC-02 | completed | Human | 決定PR #33 C1～C10 comment disposition。 | Human逐項明示採納、不改或不重開scope的處置。 | 採納C1、C2、C3、C5、C6、C7、C8；C4不改；C9、C10不重開scope，於修正push後留言說明並resolve。 |
| PC-05 | completed | Plan-Creator | 只修改plan與step，修正C1 phase-scoped allowlists並補記C6 ledger／routing。 | 只有兩份allowed planning paths變更；不實作durable fixes、不替C9／C10增加path、不自我approval。 | Plan與ledger已同步C1／C6；下一步唯一為獨立PR-05。這不是approval。 |
| PR-05 | approved | Plan-Reviewer | 獨立審查PC-05的C1／C6 planning correction。 | 只有明示`approved`才可進IM-03；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | `approved`；已放行IM-03 bounded durable correction。 |
| IM-03 | completed | Implementer | 只修改durable output完成C2／C3／C5／C7／C8；C4不改，不以C9／C10重開scope。 | 只修改`docs/presentation/native-interaction-contract.md`，逐項完成Human已採納的durable fixes，無其他path變更。 | C2／C3／C5／C7／C8已完成並交TE-05；C4、C9、C10未改寫contract。 |
| TE-05 | completed | Tester | 驗證IM-03 fixes、TC-01～TC-14與phase path allowlist。 | 每個TestCase與每個adopted durable comment都有明示結果及evidence。 | Overall PASS；TC-01～TC-14全部PASS；無blocker。此結果不構成Reviewer approval。 |
| RV-04 | needs-rework | Reviewer | 獨立審查IM-03與TE-05 evidence、scope／contract／workflow drift。 | Reviewer明示標準verdict；只有`approved`可進delivery。 | `needs-rework`；唯一finding是step ledger仍為stale狀態，須如實同步已發生事件與後續gate。不得視為成果approved。 |
| PC-06 | completed | Plan-Creator | 只修改step ledger，同步PR-05／IM-03／TE-05／RV-04、TestCase evidence與routing。 | 只有step ledger變更；保留全部歷史，RV-04仍為`needs-rework`，C9／C10未提前完成，不自我approval。 | Ledger已同步；下一步唯一為獨立PR-06。這不是approval。 |
| PR-06 | approved | Plan-Reviewer | 獨立審查PC-06 ledger-only correction。 | 明示`approved`才可把既有IM-03／TE-05成果交RV-05 final review；其他verdict依標準路由。 | `approved`；Findings None。 |
| RV-05 | approved | Reviewer | 在PR-06 `approved`後，對IM-03成果、TE-05 evidence與已修正ledger做final result review。 | Reviewer明示標準verdict；只有`approved`可進delivery。 | `approved`；Findings None；resolution map已核准。 |
| DL-01 | pending | Implementer | 在RV-05 `approved`後依授權完成bounded commit與push。 | Commit只包含核准的planning／durable corrections並成功push；不含Swift implementation。 | RV-05已放行；等待Human-confirmed commit gate，尚未commit或push。 |
| DL-02 | pending | Implementer | Push後在對應PR threads回覆處置與evidence並resolve；C9／C10只說明不重開scope。 | 對應threads皆有與Human decision一致的留言及resolution；不新增repository path或contract scope。 | 等待DL-01。 |

## TestCase Ledger

| ID | Scope | Status | Evidence owner |
| --- | --- | --- | --- |
| TC-01 | Topic／durable output／phase path allowlists；無prototype、Swift或其他path變更 | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-02 | Adopted baseline、HC-03 evidence、non-BC ownership與workflow invariants | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-03 | 七個focus regions、F-01～F-17的唯一destination／fallback、tabs content transitions、Diff／Review traversal與Mark Reviewed核心loop | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-04 | Inbox六態Presentation State Matrix | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-05 | Reader五態Presentation State Matrix | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-06 | Command context、enablement、conflict與menu mapping | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-07 | Native sidebar/list/toolbar/tabs/file/diff/menu semantics | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-08 | 1440 × 900／half／narrow／minimum與degradation policy | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-09 | Large diff navigation、reveal與scroll restoration | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-10 | VoiceOver、non-color state、announcements與system preferences | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-11 | UI Input Requirement boundary；無Logic／Domain／Integration drift | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-12 | `AC-NI-###` observable SwiftUI acceptance criteria | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-13 | Future Swift topic九欄schema與互斥exact path rules | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |
| TC-14 | Draft／baseline／TestCase traceability與Human stop boundary | PASS | Tester (TE-05) / Reviewer (RV-05 approved) |

## Routing

- PR-01 `needs-rework`：已只回Plan-Creator執行PC-02。
- PR-02 `needs-rework`：已只回Plan-Creator執行PC-03的bounded correction。
- PR-03 `needs-rework`：已只回Plan-Creator執行PC-04的workflow-only synchronization。
- PR-04 `approved`：已交Implementer執行IM-01。
- IM-01 completed：已交Tester執行TE-01。
- TE-01 Overall FAIL：已交獨立Reviewer執行RV-01；Tester結果未被視為Reviewer verdict。
- RV-01 `needs-rework`：已只回Implementer執行IM-02 required fixes。
- IM-02 completed：已交Tester執行TE-02。
- TE-02 Overall PASS：已交獨立Reviewer執行RV-02；Tester結果未被視為Reviewer approval。
- RV-02 `approved`：已進HC-01並停止自動前進等待Human。
- HC-01 `採用`：本topic完成；不自動建立或實作Swift topic。
- Human另要求`Ready PR`：作為採用後的external delivery request交由具Git／GitHub授權的流程處理；不改寫contract verdict，也不是Swift implementation approval。
- TE-04 Overall PASS：final working tree的TC-01～TC-14 regression全部PASS；Tester結果不視為Reviewer approval。
- RV-03 `human-check`：PR #33 review發現C1～C10，已停止並交Human決定comment disposition。
- HC-02 completed：Human採納C1／C2／C3／C5／C6／C7／C8，C4不改，C9／C10不重開scope而於修正push後留言並resolve。
- PC-05 completed：已只修正planning C1／C6並交獨立Plan-Reviewer執行PR-05。
- PR-05 `approved`：已交Implementer執行IM-03；IM-03只修改durable output完成C2／C3／C5／C7／C8。
- IM-03 completed：已交TE-05；TE-05 Overall PASS且TC-01～TC-14全部PASS，再交RV-04。
- RV-04 `needs-rework`：唯一finding為ledger stale，已只回Plan-Creator執行PC-06；不得視為成果approval。
- PC-06 completed：已交獨立Plan-Reviewer執行PR-06。
- PR-06 `approved`且Findings None：已將IM-03／TE-05成果交RV-05 final review。
- RV-05 `approved`且Findings None，resolution map已核准：已放行DL-01；目前等待Human-confirmed commit gate。
- DL-01仍為pending；commit／push完成後才可由DL-02留言並resolve對應threads，C9／C10不得提前回覆或resolve。
- 任一`needs-rework`只回對應產出角色；`blocked`／`human-check`停止，不得跳過gate或開始Swift implementation。

## Blockers

None。TE-05的TC-01～TC-14全部PASS，RV-04唯一ledger finding已由PC-06同步，PR-06與RV-05均已`approved`且Findings None。RV-05已放行DL-01；Human-confirmed commit gate是目前pending delivery gate，不是topic content blocker。RV-02既有`approved`、HC-01 `採用`與HC-02 comment disposition均保持原值。任何GitHub authentication狀態只屬外部`Ready PR` delivery，不將其記為contract未完成。

## Human Check

- Current：HC-01 completed。
- Entry evidence：RV-02明示`approved`，Findings None。
- Decision options：`採用`／`調整`／`放棄`。
- Human decision原值：`採用`。
- Outcome：本topic完成；只允許未來另開正式Swift implementation topic，不得由本topic自動命名branch、建立artifacts或開始implementation。
- `Ready PR`是採用後delivery request，只能交由另行授權的delivery流程處理；不改變Human decision或任何Reviewer verdict。
- HC-02：completed。Reviewer就PR #33 C1～C10給`human-check`後，Human明示採納C1／C2／C3／C5／C6／C7／C8、C4不改、C9／C10不重開scope並於修正push後留言說明及resolve；目前沒有pending Human decision。
- Current delivery gate：沒有新的contract Human Check；PR-06與RV-05均已`approved`，目前等待Human-confirmed commit gate。C9／C10留言及resolve仍等待DL-01 commit／push完成。

## Verdict History

- Upstream Planner：`approved`；只授權Plan-Creator建立正式planning artifacts。
- PC-01：completed；Plan-Creator不自我產生verdict。
- PR-01：`needs-rework`；required fix限於focus destination／fallback decision completeness與缺少的tabs、Diff／Review transitions。
- PC-02：completed；只表示bounded planning rework完成，不構成approval。
- PR-02：`needs-rework`；唯一required fix是將SwiftUI acceptance criteria的`F-07核心loop`更正為`F-10核心loop`並更新ledger。
- PC-03：completed；只表示bounded stale-reference correction完成，不構成approval。
- PR-03：`needs-rework`；唯一required fix是同步requirements、plan與ledger的stale workflow references，不改contract內容。
- PC-04：completed；只表示workflow-only synchronization完成，不構成approval。
- PR-04：`approved`；Findings None。
- IM-01：completed；唯一新增durable output。
- TE-01：completed；Overall FAIL，僅TC-08與TC-10失敗，其餘PASS。
- RV-01：`needs-rework`；required fixes僅為互斥workspace wording、拆分AC-NI-027、新增AC-NI-035／AC-NI-036。
- IM-02：completed；只修改durable output完成RV-01 required fixes。
- TE-02：completed；Overall PASS，TC-01～TC-14全部PASS，無blocker。
- RV-02：`approved`；Findings None。
- HC-01：completed；Human decision原值`採用`。
- Post-HC-01：Human另要求`Ready PR`；此為external delivery request，不是contract verdict或Swift implementation approval。
- TE-04：completed；final working-tree regression Overall PASS，TC-01～TC-14全部PASS，無blocker。
- RV-03：`human-check`；PR #33 review發現C1～C10並交Human決定處置。
- HC-02：completed；採納C1／C2／C3／C5／C6／C7／C8，C4不改，C9／C10不重開scope而留言並resolve。
- PC-05：completed；只修正C1／C6 planning artifacts，不構成approval。
- PR-05：`approved`；已放行IM-03 bounded durable correction。
- IM-03：completed；只修改durable output完成C2／C3／C5／C7／C8，未以C4、C9或C10改寫contract。
- TE-05：completed；Overall PASS，TC-01～TC-14全部PASS，無blocker；不構成Reviewer approval。
- RV-04：`needs-rework`；唯一finding為ledger stale，未核准成果。
- PC-06：completed；只同步step ledger，不構成approval。
- PR-06：`approved`；Findings None。
- RV-05：`approved`；Findings None；resolution map已核准並放行DL-01。
- DL-01：pending；等待Human-confirmed commit gate，尚未commit或push。

## Last Updated

2026-09-16
