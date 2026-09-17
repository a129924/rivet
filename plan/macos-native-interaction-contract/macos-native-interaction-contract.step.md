# macOS Native Interaction Contract 執行帳本

## Topic

- Slug：`macos-native-interaction-contract`
- Ownership：non-BC Presentation contract
- Work branch：`docs/macos-native-interaction-contract`
- Durable output：`docs/presentation/native-interaction-contract.md`

## Current Phase

原topic維持completed／adopted。上一輪PR-11 `approved`、IM-07 completed、TE-09 PASS、RV-12 `approved`、Human commit message confirmed、DL-08 commit `afc5616`、DL-09 push與DL-10六threads reply＋resolve均已完成。PC-12 entry baseline的PR head、local HEAD與origin head皆為`afc5616`且working tree clean。本輪4個L1～L4 PR threads均為unresolved／non-outdated；RV-13已明示`needs-rework`，PC-12已只修改technical spec、plan與ledger完成bounded planning correction。下一gate唯一為獨立PR-12；IM-08／TE-10／RV-14／DL-11～DL-13均pending。此cycle不改變HC-01採用結果，也不授權Swift implementation。

## Artifacts

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/macos-native-interaction-contract/requirements.md` | ReadOnly in PC-12 | Goal、scope、baseline、success criteria、Human gate與future admission requirement維持不變 |
| `analysis/macos-native-interaction-contract/technical-spec.md` | modified by PC-12 | 鎖定L1／L2／L4 semantics與acceptance guard；L3只同步workflow truth |
| `plan/macos-native-interaction-contract/macos-native-interaction-contract.plan.md` | modified by PC-12 | L1～L4 durable instructions、TestCase、phase allowlists與PR-12 → DL-13 routing |
| `plan/macos-native-interaction-contract/macos-native-interaction-contract.step.md` | modified by PC-12 | PR-11～DL-10完成證據、RV-13／PC-12結果、TestCase evidence與pending gates |
| `docs/presentation/native-interaction-contract.md` | ReadOnly in PC-12 | 上一輪delivery已完成；只可在PR-12 `approved`後由IM-08修改L1／L2／L4 |

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
| DL-01 | completed | Implementer | 在RV-05 `approved`後依授權完成bounded commit與push。 | Commit只包含核准的planning／durable corrections並成功push；不含Swift implementation。 | Commit `3b62409`已push，local HEAD與remote head一致。 |
| DL-02 | completed | Implementer | Push後在對應PR threads回覆處置與evidence並resolve；C9／C10只說明不重開scope。 | 對應threads皆有與Human decision一致的留言及resolution；不新增repository path或contract scope。 | 7個threads已reply＋resolved；0 unresolved。 |
| RV-06 | human-check | Reviewer | 審查新6個review threads的N1～N6 contract findings與locked decisions。 | N1～N5可作bounded fix；N6 locked conflict須停止交Human。 | `human-check`；N1～N5為bounded fixes，N6涉及既有first-open／reopen語意衝突，未自行決定。 |
| HC-03 | completed | Human | 決定N6並授權本輪bounded execution。 | Human明示是否採用Reviewer N6建議及N1～N5 disposition。 | Human原值`Execution Authorized`；採用Reviewer對N6的建議，並沿用general disposition直接處理N1～N5 bounded fixes。 |
| PC-07 | completed | Plan-Creator | 只修改technical spec、plan與step，鎖定N1～N6 semantics、acceptance、TestCase與phase allowlists。 | Requirements與durable output保持ReadOnly；三份actual planning paths一致；不新增F ID、shortcut、TestCase或artifact，不自我approval。 | N1～N6與PR-07 → IM-04 → TE-06 → RV-07 → DL-03 → DL-04 routing已同步；下一gate唯一為PR-07。這不是approval。 |
| PR-07 | needs-rework | Plan-Reviewer | 獨立審查PC-07的N1～N6 planning／technical correction、scope與allowlists。 | 只有明示`approved`可進IM-04；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | `needs-rework`；唯一finding是technical spec通用主流程`Inbox → Open PR → Reader Overview`未限定為首次開啟，且未同列明示重開同一PR依F-02 restoration。 |
| PC-08 | completed | Plan-Creator | 只修正PR-07唯一finding並同步PR-08 workflow／status gate。 | 通用主流程限定首次開啟，重開同一PR依F-02恢復saved active tab與tab-specific deterministic content target；N1～N5、F IDs、TestCase semantics、其他contract與allowlist scope不變。 | Technical spec、plan workflow/status與ledger已同步；下一gate唯一為PR-08。這不是approval。 |
| PR-08 | approved | Plan-Reviewer | 由新的獨立Plan-Reviewer審查PC-08唯一bounded correction及gate一致性。 | 只有明示`approved`可進IM-04；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | `approved`；已放行IM-04。 |
| IM-04 | completed | Implementer | PR-08 `approved`後只修改durable output完成N1～N6 bounded fixes。 | 只修改`docs/presentation/native-interaction-contract.md`；不新增capability、F ID、shortcut、TestCase或其他path。 | N1～N6 durable corrections已完成並交TE-06。 |
| TE-06 | completed | Tester | 驗證IM-04、TC-01～TC-14與N1～N6 observable results。 | 每個TestCase及N1～N6都有明示結果與evidence。 | Overall PASS；TC-01～TC-14全部PASS；無blocker。此結果不構成Reviewer approval。 |
| RV-07 | needs-rework | Reviewer | 獨立審查IM-04、TE-06 evidence、scope／contract／workflow drift及新6 threads resolution map。 | Reviewer明示標準verdict；只有`approved`可進DL-03。 | `needs-rework`；finding 1為durable terminal matrix fallback，finding 2為stale execution artifacts；未放行DL-03／DL-04。 |
| PC-09 | completed | Plan-Creator | 只修改plan與step，同步實際execution state、phase allowlists、TestCase evidence與新routing。 | PC-09只修改plan＋step；IM-05只可修改durable output；Deleted為None；N1～N6與TestCase行為不變。 | Planning／state sync已完成；下一gate唯一為PR-09。這不是approval。 |
| PR-09 | approved | Plan-Reviewer | 獨立審查PC-09的planning／state sync、allowlists與IM-05 bounded scope。 | 只有明示`approved`可進IM-05；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | 上一輪delivery baseline明示此gate已通過並進入IM-05。 |
| IM-05 | completed | Implementer | PR-09 `approved`後只修改durable output修正全域terminal matrix fallback。 | 只修改`docs/presentation/native-interaction-contract.md`；不改N1～N6、TestCase行為或其他path。 | 上一輪bounded durable correction已完成。 |
| TE-07 | completed | Tester | 驗證IM-05、TC-01～TC-14與RV-07 finding 1。 | 每個TestCase與finding都有明示結果與evidence。 | 上一輪delivery完成；TC-01～TC-14為PASS baseline。此結果不構成Reviewer approval。 |
| RV-08 | approved | Reviewer | 獨立審查IM-05、TE-07 evidence、scope／contract／workflow drift及新6 threads resolution map。 | Reviewer明示標準verdict；只有`approved`可進DL-03。 | 上一輪delivery baseline明示final review已放行delivery。 |
| DL-03 | completed | Implementer | RV-08 `approved`後執行上一輪bounded commit／push。 | Commit只含核准的上一輪planning／durable changes並成功push；不含Swift implementation。 | Delivery完成；PR head、local HEAD與origin head皆為`952fb54`。 |
| DL-04 | completed | Implementer | DL-03完成後回覆並resolve上一輪6個review threads。 | 6個threads依核准resolution map完成reply＋resolve，unresolved為0；不得在DL-03前處理。 | 上一輪delivery已完成；目前新出現的是另三個U1～U3 threads。 |
| RV-09 | needs-rework | Reviewer | 審查目前三個unresolved／non-outdated PR threads與durable contract。 | Reviewer明示標準verdict與bounded findings。 | `needs-rework`；U1 `PRRT_kwDOUFu0Cc6jMpuY`鎖定Reader `content`全域terminal active-tab fallback，U2 `PRRT_kwDOUFu0Cc6jMpub`鎖定optional metadata缺值省略且無假`0`，U3 `PRRT_kwDOUFu0Cc6jMpud`鎖定selected-clicked-row-only `Open`且不得暗改selection。 |
| PC-10 | completed | Plan-Creator | 只修改technical spec、plan與step，同步U1～U3 semantics、acceptance、TestCase、allowlists與routing。 | 三個Modify paths精確；Written／Deleted為None；requirements與durable保持ReadOnly；不自我approval。 | Bounded planning correction已完成；下一gate唯一為PR-10。這不是approval。 |
| PR-10 | approved | Plan-Reviewer | 獨立審查PC-10的U1～U3 planning／technical correction、scope、acceptance與phase allowlists。 | 只有明示`approved`可進IM-06；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | `approved`；已放行IM-06。 |
| IM-06 | completed | Implementer | PR-10 `approved`後只修改durable output完成U1～U3 corrections。 | 只修改`docs/presentation/native-interaction-contract.md`；不新增heading、state、transition ID、capability、Logic／DTO／data source或其他path。 | U1～U3 durable correction已完成。 |
| TE-08 | completed | Tester | 驗證IM-06、TC-01～TC-14與U1～U3 observable results。 | 每個TestCase與U1～U3都有明示結果及evidence。 | Overall PASS；TC-01～TC-14全部PASS；無blocker。此結果不構成Reviewer approval。 |
| RV-10 | approved | Reviewer | 獨立審查IM-06、TE-08 evidence、scope／contract／workflow drift與三threads resolution map。 | Reviewer明示標準verdict；只有`approved`可進DL-05。 | `approved`；已放行delivery。 |
| DL-05 | completed | Implementer | RV-10 `approved`後依`git-commit-convention`檢查staged semantic boundary，取得Human明示確認後commit。 | Human確認commit message／boundary且bounded commit成功；不含Swift implementation。 | Human已確認commit message；bounded commit `4ea0af9`已完成。 |
| DL-06 | completed | Implementer | DL-05完成後push bounded commit。 | Push成功且local HEAD／origin head一致。 | Push完成；PR head、local HEAD與origin head皆為`4ea0af9`。 |
| DL-07 | completed | Implementer | DL-06完成後回覆並resolve三個U1～U3 review threads。 | 三threads依核准resolution map完成reply＋resolve，unresolved為0；不得在push前處理。 | 三threads已reply＋resolved；0 unresolved。 |
| RV-11 | needs-rework | Reviewer | 審查目前6個unresolved／non-outdated PR threads與durable contract。 | Reviewer明示標準verdict與bounded findings。 | `needs-rework`；T1 `PRRT_kwDOUFu0Cc6jOma2`同步舊cycle workflow truth；T2 `PRRT_kwDOUFu0Cc6jOma4`無change file；T3 `PRRT_kwDOUFu0Cc6jOma6` safe recovery；T4 `PRRT_kwDOUFu0Cc6jOma-` missing availability；T5 `PRRT_kwDOUFu0Cc6jOmbC` Composer offline；T6 `PRRT_kwDOUFu0Cc6jOmbG` blank／stale Save Draft。未放行implementation或delivery。 |
| PC-11 | completed | Plan-Creator | 只修改technical spec、plan與step，同步T1～T6 semantics、acceptance、TestCase、allowlists與routing。 | 三個Modify paths精確；Written／Deleted為None；requirements與durable保持ReadOnly；不自我approval。 | Bounded planning correction已完成；下一gate唯一為PR-11。這不是approval。 |
| PR-11 | approved | Plan-Reviewer | 獨立審查PC-11的T1～T6 planning／technical correction、scope、acceptance與phase allowlists。 | 只有明示`approved`可進IM-07；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | `approved`；已放行IM-07。 |
| IM-07 | completed | Implementer | PR-11 `approved`後只修改durable output完成T2～T6 corrections；T1不重跑舊delivery。 | 只修改`docs/presentation/native-interaction-contract.md`；不改F-17、CMD-NI-015、AC-NI-036、TC-14、UIIR-NI-007、ownership／Human boundary或其他path。 | T2～T6 durable correction已完成；T1舊delivery未重跑。 |
| TE-09 | completed | Tester | 驗證IM-07、TC-01～TC-14與T2～T6 observable results。 | 每個TestCase與T2～T6都有明示結果及evidence；preservation guards保持。 | Overall PASS；TC-01～TC-14全部PASS；無blocker。此結果不構成Reviewer approval。 |
| RV-12 | approved | Reviewer | 獨立審查IM-07、TE-09 evidence、scope／contract／workflow drift與6 threads resolution map。 | Reviewer明示標準verdict；只有`approved`可進DL-08。 | `approved`；已放行delivery。 |
| DL-08 | completed | Implementer | RV-12 `approved`後依`git-commit-convention`檢查staged semantic boundary，取得Human明示確認後commit。 | Human確認commit message／boundary且bounded commit成功；不含Swift implementation。 | Human已確認commit message；bounded commit `afc5616`已完成。 |
| DL-09 | completed | Implementer | DL-08完成後push bounded commit。 | Push成功且local HEAD／origin head一致。 | Push完成；PR head、local HEAD與origin head皆為`afc5616`。 |
| DL-10 | completed | Implementer | DL-09完成後回覆並resolve6個T1～T6 review threads。 | 6 threads依核准resolution map完成reply＋resolve，unresolved為0；不得在push前處理。 | 六threads已reply＋resolved；0 unresolved。 |
| RV-13 | needs-rework | Reviewer | 審查目前4個unresolved／non-outdated PR threads與durable contract。 | Reviewer明示標準verdict與bounded findings。 | `needs-rework`；L1 `PRRT_kwDOUFu0Cc6jPcJD`鎖定非modal Reader error／offline-without-readable-content的Back；L2 `PRRT_kwDOUFu0Cc6jPcJJ`鎖定F-16實際source；L3 `PRRT_kwDOUFu0Cc6jPcJM`同步上一輪workflow truth；L4 `PRRT_kwDOUFu0Cc6jPcJQ`鎖定AC-NI-003內F-08／F-09互斥語意。未放行implementation或delivery。 |
| PC-12 | completed | Plan-Creator | 只修改technical spec、plan與step，同步L1～L4 semantics、acceptance、TestCase、allowlists與routing。 | 三個Modify paths精確；Written／Deleted為None；requirements與durable保持ReadOnly；不自我approval。 | Bounded planning correction已完成；下一gate唯一為PR-12。這不是approval。 |
| PR-12 | pending | Plan-Reviewer | 獨立審查PC-12的L1～L4 planning／technical correction、scope、acceptance與phase allowlists。 | 只有明示`approved`可進IM-08；`needs-rework`只回Plan-Creator，`blocked`／`human-check`停止。 | Pending。 |
| IM-08 | pending | Implementer | PR-12 `approved`後只修改durable output完成L1／L2／L4 corrections；L3不重跑舊delivery。 | 只修改`docs/presentation/native-interaction-contract.md`；不新增ID、capability、shortcut、runtime API或其他path，並保持既有boundaries。 | 等待PR-12 `approved`。 |
| TE-10 | pending | Tester | 驗證IM-08、TC-01～TC-14與L1／L2／L4 observable results。 | 每個TestCase與L1／L2／L4都有明示結果及evidence；preservation guards保持。 | 等待IM-08。 |
| RV-14 | pending | Reviewer | 獨立審查IM-08、TE-10 evidence、scope／contract／workflow drift與4 threads resolution map。 | Reviewer明示標準verdict；只有`approved`可進DL-11。 | 等待TE-10。 |
| DL-11 | pending | Implementer | RV-14 `approved`後依`git-commit-convention`檢查staged semantic boundary，取得Human明示確認後commit。 | Human確認commit message／boundary且bounded commit成功；不含Swift implementation。 | 等待RV-14 `approved`與Human confirmation。 |
| DL-12 | pending | Implementer | DL-11完成後push bounded commit。 | Push成功且local HEAD／origin head一致。 | 等待DL-11。 |
| DL-13 | pending | Implementer | DL-12完成後回覆並resolve4個L1～L4 review threads。 | 4 threads依核准resolution map完成reply＋resolve，unresolved為0；不得在push前處理。 | 等待DL-12；4 threads仍unresolved／non-outdated。 |

## TestCase Ledger

| ID | Scope | Status | Evidence owner |
| --- | --- | --- | --- |
| TC-01 | Topic／durable output／PC-12及IM-08 phase allowlists；無prototype、Swift或其他path變更 | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L3 `needs-rework`; TE-10／RV-14 pending |
| TC-02 | Adopted baseline、non-BC ownership與workflow invariants維持不變 | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 `needs-rework`; TE-10／RV-14 pending |
| TC-03 | F-16實際source／destination／unavailable fallback及F-17 preservation | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L2 `needs-rework`; TE-10／RV-14 pending |
| TC-04 | Inbox六態、availability缺值唯一error、known-offline及safe recovery | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 `needs-rework`; TE-10／RV-14 pending |
| TC-05 | Reader五態、非modal error／offline-without-readable-content Back與Composer modal priority | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L1 `needs-rework`; TE-10／RV-14 pending |
| TC-06 | CMD-NI-012非modal Back、Composer modal conflict及CMD-NI-015 preservation | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L1 `needs-rework`; TE-10／RV-14 pending |
| TC-07 | Native containers維持既有semantics，Composer modal時背景inert | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L1 `needs-rework`; TE-10／RV-14 pending |
| TC-08 | 1440 × 900／half／narrow／minimum與degradation policy | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 `needs-rework`; TE-10／RV-14 pending |
| TC-09 | AC-NI-003內F-08 file selection與F-09 change navigation互斥語意 | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L4 `needs-rework`; TE-10／RV-14 pending |
| TC-10 | VoiceOver、non-color state、announcements與system preferences；AC-NI-036保持 | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 `needs-rework`; TE-10／RV-14 pending |
| TC-11 | UIIR-NI-002非modal Back與UIIR-NI-007 preservation；無新增Logic／Integration policy | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L1 `needs-rework`; TE-10／RV-14 pending |
| TC-12 | Acceptance同步AC-NI-003、AC-NI-004／008／029，AC-NI-036保持且無新capability | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L1／L2／L4 `needs-rework`; TE-10／RV-14 pending |
| TC-13 | Future Swift topic九欄schema與互斥exact path rules | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 `needs-rework`; TE-10／RV-14 pending |
| TC-14 | 上一輪delivery truth、current four-thread boundary、ownership／non-BC／Human／Swift boundaries維持 | PASS baseline; TE-10 pending | Tester TE-09; Reviewer RV-12 `approved`; RV-13 L3 `needs-rework`; TE-10／RV-14 pending |

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
- RV-05 `approved`且Findings None，resolution map已核准：已交DL-01。
- DL-01 completed：commit `3b62409`已push且local／remote head一致；DL-02 completed：7個threads已reply＋resolved，0 unresolved。
- RV-06 `human-check`：N1～N5為bounded fixes，N6 locked conflict已停止交HC-03。
- HC-03 `Execution Authorized`：Human採用Reviewer對N6的建議並授權直接處理N1～N5；已交PC-07。
- PC-07 completed：已交獨立Plan-Reviewer執行PR-07。
- PR-07 `needs-rework`：唯一finding只回Plan-Creator執行PC-08，未進IM-04。
- PC-08 completed：已交新的獨立Plan-Reviewer執行PR-08。
- PR-08 `approved`：已交IM-04；IM-04 completed後交TE-06。
- TE-06 Overall PASS：TC-01～TC-14全部PASS；已交RV-07，但Tester結果未視為Reviewer approval。
- RV-07 `needs-rework`：finding 1只交Implementer在PR-09核准後執行IM-05；finding 2已交Plan-Creator執行PC-09。DL-03／DL-04維持pending。
- PC-09 completed：下一步唯一交獨立Plan-Reviewer執行PR-09。
- PR-09 → IM-05 → TE-07 → RV-08 → DL-03／DL-04已完成；PC-10 entry baseline的PR head／local HEAD／origin head皆`952fb54`且working tree clean，上一輪delivery已關閉。
- RV-09 `needs-rework`：U1～U3只回Plan-Creator執行PC-10；三個threads保持unresolved／non-outdated。
- PC-10 completed：下一步唯一交獨立Plan-Reviewer執行PR-10。
- PR-10 → IM-06 → TE-08 → RV-10 → Human-confirmed DL-05 → DL-06 → DL-07已完成；commit `4ea0af9`已push，三threads已reply＋resolved，舊delivery不得重跑。
- RV-11 `needs-rework`：T1～T6只回Plan-Creator執行PC-11；6 threads保持unresolved／non-outdated。
- PC-11 completed：下一步唯一交獨立Plan-Reviewer執行PR-11。
- PR-11 → IM-07 → TE-09 → RV-12 → Human-confirmed DL-08 → DL-09 → DL-10已完成；commit `afc5616`已push，六threads已reply＋resolved，舊delivery不得重跑。
- RV-13 `needs-rework`：L1～L4只回Plan-Creator執行PC-12；4 threads保持unresolved／non-outdated。
- PC-12 completed：下一步唯一交獨立Plan-Reviewer執行PR-12。
- PR-12只有`approved`可交IM-08；IM-08只修改durable output完成L1／L2／L4，L3不重跑舊delivery，完成後依序交TE-10與RV-14。
- RV-14只有`approved`可進DL-11；DL-11須先取得Human對commit boundary／message的明示確認才可commit，之後依序DL-12 push與DL-13回覆並resolve4 threads。
- 任一`needs-rework`只回對應產出角色；`blocked`／`human-check`停止，不得跳過gate或開始Swift implementation。

## Blockers

None。RV-13的L1～L4 findings已有bounded route：L3 workflow truth已由PC-12同步，L1／L2／L4等待PR-12後依序進IM-08／TE-10／RV-14／DL-11～DL-13。這些是pending gates，不是unresolved input；4 threads保持unresolved／non-outdated，且不得在RV-14 approval、Human-confirmed commit與push前處理。

## Human Check

- Current：HC-01 completed。
- Entry evidence：RV-02明示`approved`，Findings None。
- Decision options：`採用`／`調整`／`放棄`。
- Human decision原值：`採用`。
- Outcome：本topic完成；只允許未來另開正式Swift implementation topic，不得由本topic自動命名branch、建立artifacts或開始implementation。
- `Ready PR`是採用後delivery request，只能交由另行授權的delivery流程處理；不改變Human decision或任何Reviewer verdict。
- HC-02：completed。Reviewer就PR #33 C1～C10給`human-check`後，Human明示採納C1／C2／C3／C5／C6／C7／C8、C4不改、C9／C10不重開scope並於修正push後留言說明及resolve；目前沒有pending Human decision。
- HC-03：completed。RV-06 `human-check`後，Human明示原值`Execution Authorized`，採用Reviewer對N6的建議並授權N1～N5 bounded fixes直接處理。
- Current cycle：目前沒有需要決定L1～L4 semantics的pending Human decision；下一步等待PR-12獨立verdict。若RV-14後進入delivery，DL-11仍必須取得Human對commit boundary／message的明示確認，才可commit；4 threads必須等DL-12 push完成後才可由DL-13 reply＋resolve。

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
- DL-01：completed；commit `3b62409`已push且local／remote head一致。
- DL-02：completed；7個threads已reply＋resolved，0 unresolved。
- RV-06：`human-check`；N1～N5為bounded fixes，N6 locked conflict交Human決定。
- HC-03：completed；Human原值`Execution Authorized`，採用Reviewer N6建議並授權N1～N5直接處理。
- PC-07：completed；只修改必要planning artifacts，不構成approval。
- PR-07：`needs-rework`；唯一finding為通用主流程未限定首次開啟，且未同列明示重開依F-02 restoration。
- PC-08：completed；只修正PR-07唯一finding並同步PR-08 gate，不構成approval。
- PR-08：`approved`；已放行IM-04。
- IM-04：completed；只修改durable output完成N1～N6。
- TE-06：completed；Overall PASS，TC-01～TC-14全部PASS，無blocker；不構成Reviewer approval。
- RV-07：`needs-rework`；finding 1為durable terminal matrix fallback，finding 2為stale execution artifacts，未放行delivery。
- PC-09：completed；只同步plan與step，不構成approval。
- PR-09：`approved`；已放行IM-05。
- IM-05：completed；上一輪只修改durable output完成terminal fallback correction。
- TE-07：completed；TC-01～TC-14為PASS baseline，不構成Reviewer approval。
- RV-08：`approved`；已放行上一輪delivery。
- DL-03／DL-04：completed；PC-10 entry baseline的PR head／local HEAD／origin head皆`952fb54`且working tree clean，上一輪delivery已完成。
- RV-09：`needs-rework`；findings只有U1 active-tab terminal fallback、U2 optional metadata與U3 selected-clicked-row-only `Open`。
- PC-10：completed；只修改technical spec、plan與step，不構成approval。
- PR-10：`approved`；已放行IM-06。
- IM-06：completed；只修改durable output完成U1～U3。
- TE-08：completed；Overall PASS，TC-01～TC-14全部PASS，無blocker；不構成Reviewer approval。
- RV-10：`approved`；已放行上一輪delivery。
- DL-05：completed；Human已確認commit message，commit為`4ea0af9`。
- DL-06：completed；push成功，PR／local／origin head一致。
- DL-07：completed；三threads已reply＋resolved，0 unresolved。
- RV-11：`needs-rework`；findings為T1 workflow truth及T2～T6 bounded semantics。
- PC-11：completed；只修改technical spec、plan與step，不構成approval。
- PR-11：`approved`；已放行IM-07。
- IM-07：completed；只修改durable output完成T2～T6，未重跑T1舊delivery。
- TE-09：completed；Overall PASS，TC-01～TC-14全部PASS，無blocker；不構成Reviewer approval。
- RV-12：`approved`；已放行上一輪delivery。
- DL-08：completed；Human已確認commit message，commit為`afc5616`。
- DL-09：completed；push成功，PR／local／origin head一致。
- DL-10：completed；六threads已reply＋resolved，0 unresolved。
- RV-13：`needs-rework`；findings為L1非modal Back、L2 F-16 source、L3 workflow truth與L4 AC-NI-003互斥語意。
- PC-12：completed；只修改technical spec、plan與step，不構成approval。
- PR-12：pending；等待獨立Plan-Reviewer verdict。
- IM-08／TE-10／RV-14／DL-11～DL-13：pending；不得跳過前序gate或提前commit、push、reply／resolve4 threads。

## Last Updated

2026-09-17
