# PR Inbox / PullRequestList：Technical Spec

## Locked boundary

`RivetPresentation` 是沒有 BC dependencies 的 non-BC target。`PullRequestList` 位於 `Sources/Presentation/PRInbox/PullRequestList.swift`，由既有 `PullRequestRowPresentation` 與 `PullRequestRow` 組成；不更動 Row、`Package.swift` 或 static isolation tests。工作區與流程狀態見同 slug step ledger；PR-01 `needs-rework`（Preview evidence gap）、PC-02 completed、PR-02 `approved`（Findings：None）、PC-03 workflow sync completed、IM-01 completed、TE-01 `approved` automated scope（Human-only native UI pending）、RV-01 `needs-rework`（fixture ID uniqueness test 與 ledger stale status）、PC-04 workflow sync completed、IM-02 completed、TE-02 `approved` automated scope（debug/release focused 5/5、root 75/75、build/path/whitespace pass）、RV-02 `approved`（Findings：None；source-format-sensitive parsing 為非阻擋維護限制）、PC-05 workflow sync completed、HC-01 pending。Human HR-02 failed：`Clear selection` 後 Open known-safe on，初始未選第一列雙擊 Selection 變該列但 Count 0；再次雙擊仍 0；Enter 使 Count +1 後雙擊才有反應；HR-03 Enter pass。獨立 RV-03 Reviewer 明示 `needs-rework`；雙擊位於 Row `simultaneousGesture`、Enter／雙擊共用 guard、Preview Clear／Count 接線正常，根因未定。現有 path/contract 足夠；PC-06 workflow-only sync completed，IM-03 受限診斷／修正 current／pending，後續 TE-03 → 獨立 RV-04 → Human 重驗 HR-02。HC-01 未有最終「採用／調整／放棄」，PL-02／03／05 其餘 Human-only native evidence 尚未驗收。

## Public interface

```swift
public struct PullRequestList: View {
  public init(
    items: [PullRequestRowPresentation],
    selection: Binding<PullRequestRowPresentation.ID?>,
    focus: FocusState<Bool>.Binding,
    canOpen: @escaping (PullRequestRowPresentation.ID) -> Bool,
    onOpen: @escaping (PullRequestRowPresentation.ID) -> Void
  )
}
```

`items` 是 display-ready ordered values，同一批 ID 唯一；ID 直接採既有 Row `id`。`selection` 由 parent Presentation owner 保存；`focus` 由 parent `@FocusState` 提供。`canOpen` 只在 capability 與 action safety known-safe 時為 true，未知或不可用時為 false。`onOpen` 僅是 Presentation intent callback，不執行 Reader／workspace navigation。

## Native List 與狀態流

- 用原生 `List(selection:)`、`ForEach(items)`、既有 `PullRequestRow(presentation:)` 和 `.tag(id)` 建立單選，保留系統 selected/focused/inactive semantics、Row accessibility 與原有寬度降階；不加自訂選取背景或水平 ScrollView。
- production 與測試共用 internal 純選取函式：輸入當前 optional ID 與最新 ID 集合；存在則回同 ID，stale 或 `nil` 則回 `nil`。在初次呈現和 supplied IDs 改變時套用；空集合自然為 `nil`。不得以集合順序或第一列替換 stale／initial `nil`，也不得改焦點。
- 完整 Inbox 的 F-01、`content` matrix 與 F-15 首列 fallback 由未來 parent 在 composition transition 處理；List 局部的 `nil` 不代表完整 Inbox 的最終 selection。
- `.focused(focus)` 附於 List；parent 可要求焦點回到 List。Up／Down 交給原生 List。無 modifier 的 Home／End 只在 List focus active 時選第一／最後 ID，空清單與已在邊界時 no-op；Enter 在同一局部焦點下請求 Open。其他 control、modifier、VoiceOver 事件不攔截；不用全域 key monitor。
- 單擊由原生 List selection 處理，不能發 Open。雙擊僅發 Open intent；對原先未選列的雙擊，須讓原生首擊先解決 selection，再以同一列 ID 檢查。若 Preview 顯示 gesture 阻斷 native selection 或重複觸發，停止交回規劃／Human Review，不能修改 Row 解決。
- production 與測試共用 internal Open guard：以啟動當下 items、current effective selection、target ID 及 `canOpen` 判斷。只有 target 存在、等於 current selected ID 且 `canOpen(target)` 為 true 才呼叫 `onOpen(target)` 一次；其他情況 no-op 且不更動 selection／focus。Enter 使用 current selected ID，雙擊使用 clicked row ID。

## Preview 與驗證界面

`PullRequestList+Previews.swift` 用 `#if DEBUG` 隔離 deterministic Presentation fixtures 與 `@State` selection、`@FocusState` focus、最後一次 Open intent ID／累計次數顯示。互動 Preview 提供六筆標準清單、預選列、窄寬及需垂直捲動的長集合，並有從其他 control 返回 List 焦點的操作；不持有產品 Reader 或 navigation。

Debug-only harness 的 controls 必須透過**同一 production Open guard／activation path**提供三種可觀察 no-op probe：移除並記住原 selected ID 後嘗試該 missing ID；保留目前 selection 而嘗試另一個可見的 nonselected ID；切換 `canOpen` 為 false 後對已選 ID 嘗試 Open。顯示 probe 前後的 selection、focus、intent ID／累計次數；三者均不增加 intent 次數、不改 selection／focus。正常單擊、初始未選列雙擊與 List 焦點下 Enter 仍須以真實 native 事件操作；unsafe 另須以 List 焦點下 Enter 檢查。Debug controls 不加入 production UI 或新產品能力。

PL-05 另提供 inactive selection 與 Increase Contrast 的 Preview 變體，分別採用既有 Row Preview 的 inactive control state／increased contrast environment 設定；Human 也可使 Preview 視窗失活再啟用，觀察 native inactive selection 與 focus 恢復。兩種變體都要檢查選取與 focus 不只靠顏色、Row 降階未被改寫。Fixture IDs 必須唯一。測試不得依賴 debug-only fixture symbols，另以 release-safe literals 驗證共用 internal selection/Open guard。

## Boundary 與驗收

`README.md` 與 `docs/architecture/README.md` 僅在驗證後更新已交付的 Presentation 現況；不得聲稱 Inbox workspace、Reader、app menu 或端到端 F-01/F-15 已完成。實作只可觸及 formal plan 的 Written／Modify paths；ReadOnly 不變。PL-01～PL-06、Human Preview 與 VoiceOver 檢查依 formal plan 執行。只有 PR-02 獨立 Plan-Reviewer `approved` 才能進入 Implementer；Tester 與獨立 Reviewer 再驗證實際交付。
