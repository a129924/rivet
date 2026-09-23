# PR Inbox / PullRequestList：Implementation Plan

## Mission 與 workflow

Goal：在 non-BC `RivetPresentation` 建立原生 SwiftUI `PullRequestList`，重用已採用 `PullRequestRow`，交付 List 單選、焦點、鍵盤選取、安全 Open PR intent、Preview 與受限測試。

Non-Goal：不重設計 workflow 或已採用契約；不修改 Row；不建立 Inbox workspace/filter、Reader 導覽、app menu/context menu、production mapper、Domain/Application/GitHubIntegration、網路、持久化或新產品能力。`Open Selected Pull Request` app menu counterpart 由未來 owning composition 履行，本 Mission 不宣稱端到端 command 驗收。

In-Scope：有序 PR Row 組合、native single selection、List-local selection validity、focus、Up／Down／Home／End、Enter／雙擊 intent、debug-only Preview、共用純 helper 的單元測試、驗證後的 Presentation 現況文件更新。

Out-Of-Scope：完整 Inbox state matrix、初次/Reader-return首列 fallback、filters、Reader state/workspace transition、BC logic/adapter、Package graph、Row styling/layout 修改、PR row context menu、app menu、commit/push/PR/release/下一 Mission。

Human/operator 的初始 workspace preparation evidence 保留為：base=`dev`、work branch=`codex/pr-inbox-pull-request-list`、baseline HEAD/local `dev`/local `origin/dev`=`4ba15ae`、初始 clean 且 branch 唯一 attach；Plan-Creator 未執行 Git。其後 planning、implementation、bounded rework、Tester、Reviewer 與 Human handoff 的完整歷史只以 `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md` 為準，既有 findings 與 evidence 均保留且不是 current gate。

Final workflow truth：HC-01 completed，HR-01～HR-07 pass，Visual／structural、Long List internal vertical scrolling 與 VoiceOver pass，固定 x finding withdrawn／not reproduced；Human decision 原值為 `採用 PullRequestList`。PC-10 completed；獨立 Plan-Reviewer PR-03 `approved`（Findings：None）。Topic／Mission completed／stopped，Current Step=`None`，Next Action=`Stop`。PR #41 已 Ready；Ready 狀態不重開本 plan 的 Goal、API、selection、exact paths、TestCase 或 Human acceptance，也不得新增 capability 或自動開始下一 component。

## Exact Path Contract

四組兩兩互斥；以下均為 exact repository-relative file paths。超出 Written／Modify path 時先回 planning/Human Review。

### ReadOnly

- `Package.swift`
- `docs/design-principles.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/native-interaction-contract.md`
- `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`
- `Tests/RivetPRInboxTests/StaticIsolationTests.swift`

### Written

- `analysis/pr-inbox-pull-request-list/requirements.md`
- `analysis/pr-inbox-pull-request-list/technical-spec.md`
- `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.plan.md`
- `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestList+Previews.swift`
- `Tests/RivetPresentationTests/PullRequestListTests.swift`

### Modify

- `README.md` — 驗證後只更新已交付的 Presentation 現況。
- `docs/architecture/README.md` — 驗證後只更新已交付的 Presentation 現況。

### Deleted

None。

## Implementation contract

- Public API：`PullRequestList(items: [PullRequestRowPresentation], selection: Binding<PullRequestRowPresentation.ID?>, focus: FocusState<Bool>.Binding, canOpen: @escaping (ID) -> Bool, onOpen: @escaping (ID) -> Void)`；ID 使用既有 `PullRequestRowPresentation.ID`。不建立 list-specific DTO。
- 原生 `List(selection:)`、`ForEach` 與 `.tag(id)` 組合既有 Row；同批 ID 唯一。有效 ID 保留，已選 ID 消失清 `nil`，initial `nil` 保持 `nil`，空集合無有效選取；production/test 共用 internal 純 selection helper，資料更新不搶焦點。
- Parent `@FocusState` 控制 List focus；Up／Down 為原生 List 行為。只有 List 持有焦點時局部處理無 modifier Home／End／Enter；首尾與空清單 no-op，native editable control 與 VoiceOver 優先，不使用全域監聽。
- 單擊只選取。Enter/雙擊啟動時共用 internal Open guard：ID 仍存在、等於 current effective selection 且 `canOpen(id)` true 才恰發一次 intent；否則 no-op，selection/focus 不變。初始未選列雙擊由 native selection 先選中，再 Open 同一 ID；不得讓雙擊 gesture 破壞單擊原生選取。
- List 不做完整 Inbox 的 F-01/content/F-15 第一列 fallback。`canOpen` true 代表 parent 已確認 capability 與 action safety known-safe；List 不決定安全來源。Preview 只顯示 intent，沒有導覽。Context `Open` 為 MAY，這次不做。

## TestCase Register

| ID | Context／trigger | Observable expected result | Evidence method | Adopted trace |
| --- | --- | --- | --- | --- |
| PL-01 | 初次呈現 `nil`、有效 ID 或空集合 | Initial `nil` 保持無選取；有效 ID 保留；空集合無有效選取，且不搶焦點。完整 Inbox 首列 fallback 留給 parent。 | 共用純 selection helper Swift Testing 分開測 initial `nil`/valid/empty；Preview 核對實際選列。 | F-01 parent obligation；AC-NI-009；UIIR-NI-003。 |
| PL-02 | 點擊列；List 焦點內 Up／Down／Home／End；焦點移出/返回 | 只移動單選；失焦後不攔截；parent 要求時焦點返回選定列。 | Human 以可執行 Preview 檢查鍵盤、焦點與 VoiceOver。 | F-01/F-15 List 接收端；CMD-NI-001；§7。 |
| PL-03 | 單擊、Enter、初始未選列雙擊；missing/nonselected/unsafe Open | 單擊不 Open；雙擊先選中同列並對同 ID 恰 Open 一次；Enter 對有效選取恰一次；三種 guard 均不發 intent，selection/focus 不變。 | 共用 Open guard Swift Testing；Human 用原生單擊／雙擊／Enter 與 debug-only missing/nonselected/unsafe probes，觀察 selection/focus 與 intent ID／次數；unsafe 也用 List 焦點 Enter 檢查。 | F-02 List 出口；CMD-NI-002；AC-NI-011；UIIR-NI-006。 |
| PL-04 | 新集合保留/移除 selected ID，初始 `nil`，空集合 | 保留同一有效 ID；stale 清 `nil` 而不取代；原 `nil` 保持 `nil`；空集合無有效選取，更新不搶焦點。 | Swift Testing 分別測 valid/stale/initial `nil`/empty 及 fixture ID 唯一性。 | F-01/F-15 parent obligation；AC-NI-009；UIIR-NI-003。 |
| PL-05 | 標準、窄寬、長清單；VoiceOver；inactive/contrast | 原生選取可辨識，Row 單行 title 與降階不變；無水平捲動，長清單可垂直捲動。 | Human 檢查標準／窄寬／長清單與 VoiceOver；開啟 inactive control state／Increase Contrast Preview 變體，並使視窗失活／恢復，觀察 native selection/focus 與非色彩辨識。 | §7–§10；AC-NI-014/016/017/027/035/036。 |
| PL-06 | 完成實作後查 target/path 與執行驗證 | Presentation 無 BC dependency；Row、Package graph/static isolation 不變；debug/release build、focused/root tests 通過，diff 只含 allowlist。 | SwiftPM exit 0、static isolation tests 與獨立 Reviewer 路徑審查。 | §1、§13。 |

## Verification 與 handoff

- Preview harness：以同一 production Open guard／activation path 接線 debug-only probes；移除並記住 selected ID 後嘗試 missing ID、對另一可見但未選 ID 嘗試 Open、切換 `canOpen` false 後嘗試 selected ID。畫面顯示 selection、focus、最後 intent ID 與累計次數；三種 probe 均須次數不增加且 selection/focus 不變。原生單擊／雙擊／Enter 另以 List 真實事件驗證。Inactive 與 Increase Contrast 變體使用既有 Row Preview 的 environment 方式；再使視窗失活／恢復觀察 selection/focus。
- Implementer：先以 `swift test --filter PullRequestListTests` 做 focused red/green，再執行 `swift build -c debug`、`swift build -c release`、`swift test --filter PullRequestListTests`、`swift test`；每個 exit 0，root tests 含既有 static isolation。若 SwiftPM 需寫 cache，只能使用 build/cache artifacts，不可改 tracked files。
- Tester：獨立重跑上述 commands，確認 PL-01/03/04 的 production/test helper 共用、PL-06 path/API/static boundary，並將 PL-02/03/05 人工 Preview/VoiceOver 部分明列 pending，不能以 build/tests 代替。
- Reviewer：獨立核對 source、tests、docs diff 與 Tester evidence；只對明示 verdict `approved` 才交 Human Review。
- Human Review：提供標準/已選/窄寬/長清單、鍵盤、VoiceOver、inactive/Increase Contrast 證據；明確展示單擊不 Open、初始未選列雙擊同 ID 恰 Open 一次，以及三種 guard probe 的 selection/focus/intent 次數與 unsafe Enter。附 exact changed paths、責任邊界、debug/release/target/root test 結果。Human 明示「採用／調整／放棄」後停止。

任一實作需要 Row 修改、擴充 path/能力，或 Preview 證明 List 範圍內無法滿足焦點、鍵盤、雙擊契約時停止，回 planning／Human Review；不得自行重開 locked decisions。
