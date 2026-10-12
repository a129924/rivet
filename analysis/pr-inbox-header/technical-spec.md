# PR Inbox / InboxHeader：技術規格

## Ownership 與 public API

本切片只在既有 non-BC `RivetPresentation` target 的 `Sources/Presentation/PRInbox/` 內增添 Header。`Package.swift` 不變；Header 不 import PR Inbox BC、PR Reader、GitHubIntegration，也不建立 mapper 或 generic filter framework。

```swift
public enum InboxHeaderFilter: CaseIterable, Hashable, Sendable {
  case needsReview
  case mentioned
  case all

  public var title: String { get }
}

public struct InboxHeaderPresentation: Equatable, Sendable {
  public let title: String
  public let subtitle: String

  public init(title: String, subtitle: String)
}

public struct InboxHeader: View {
  public init(
    presentation: InboxHeaderPresentation,
    selectedFilter: Binding<InboxHeaderFilter>
  )
}
```

`InboxHeaderFilter.allCases` 固定順序為 `.needsReview`、`.mentioned`、`.all`；對應文字為 `Needs Review`、`Mentioned`、`All`。enum case 是 Presentation identity，不是 query、Domain 類型或持久化格式。標題／副標為 parent 傳入的 display-ready 值；不建立預設 production copy 或動態選項清單。未來 parent 持有 selected filter；Header 使用 `@Binding`，無 production `@State` filter。唯一向上資料流為使用者改選後 Binding 更新。

## Native control、layout 與 accessibility

- 使用 `Picker("Inbox filter", selection: $selectedFilter)`，依固定順序建立三個 `.tag(filter)` 選項並套 `.pickerStyle(.segmented)`。不加自訂鍵盤監聽、全域 shortcut、PR collection 或資料請求。
- title 使用系統 heading 字級並加入 heading accessibility trait；subtitle 使用 secondary style 並保持原生 Text 可讀。Picker 具有可讀的 `Inbox filter` 名稱與原生 choices／selected value 語意；不以單一 accent 色表示 selected。
- 使用 `ViewThatFits(in: .horizontal)`：寬版候選設定 620 pt 最小橫向 fit，下層採可伸縮的 title/subtitle 區及原生 Picker；寬度不足 620 pt 時選窄版 `VStack`，由上而下為 title、subtitle、Picker。兩版都保持 subtitle 單行、tail truncation，title 不隱藏，Picker 不替換成 menu 或自畫按鈕。
- 620 pt 是 Header-local 版型 checkpoint，300 pt 是 Preview 的窄版可用性檢查，兩者不是 app/window 最小寬度。Native segmented control 在 300 pt 必須完整可操作、無 Header 水平捲動；若實際 macOS rendering 無法達成，記錄觀察並停回 Human Review，不自行更換控制或改契約。

## Preview 與測試設計

`Sources/Presentation/PRInbox/InboxHeader+Previews.swift` 僅於 `#if DEBUG` 建立 `@State` selection harness。標準 fixture 為 `PR Inbox`／`Pull requests waiting for your attention.`／`.needsReview`，畫面另顯示 `Selected filter: <title>`。同一 harness 提供 `.mentioned`、`.all` 初始選取、標準寬度、620 pt checkpoint、300 pt 窄寬、長副標、Increase Contrast 與 inactive control state。Harness 不組合 PullRequestList、不產生 PR items、不做 filtering。

`Tests/RivetPresentationTests/InboxHeaderTests.swift` 使用 Swift Testing 測固定 case 順序／identity／title、display-ready input 與 parent Binding 寫入／讀回。純單元測試不宣稱原生 Picker event、focus 或 VoiceOver 已驗證。IH-04 鍵盤依下述 PC-03 一次受限本機焦點方法；layout、VoiceOver、contrast 與 inactive 的既有 Human 證據仍各自保留，不以鍵盤測試取代。

## IH-04 鍵盤驗證方法（HC-01「調整」；PC-03 受限替代）

- Apple 官方 [The SwiftUI cookbook for focus（WWDC23，約 15:25）](https://developer.apple.com/videos/play/wwdc2023/10162/?time=925) 指出 macOS buttons 與 segmented controls 不因 click 取得 focus，且 Tab 到達須 system-wide Keyboard Navigation。Xcode Preview 的 click 後 Arrow／Tab 無回應不能單獨判定 `InboxHeader` 缺陷；目前設定下的 parity 也不能證明 Keyboard Navigation 開啟時通過。
- RV-06 的既有 repository 外 XCUI 證據保持原樣：十二筆 `AXFocusedUIElement:-25211`，parent StaticText 值可讀但缺 focused role／label／value，off parity 不能判定。Human 於 2026-10-05 明示 Execution Authorized，僅恢復一次 bounded host-local 焦點證據替代；不改 RV-06 `blocked` 歷史，亦非 HC-02 採用或 IH-04 pass。
- Implementer 只在 repository 外既有 disposable native macOS host 修正診斷。保持**同一** SwiftUI `WindowGroup`／`VStack`／hosting view，未修改的 `InboxHeader` 與 stock `.segmented` `Picker` 在同窗各有相同型別／初值的 parent Binding、`Selected filter: <value>` 診斷與可辨區域；不得拆成不同 hosting views 製造 responder 差異，不改 repo product、`Package.swift` 或加 `.focusable`。
- 以該 host 既有 `NSHostingView.accessibilityFocusedUIElement` 本機 getter 取 focused child；逐次保存其 accessibility role、label、value，以及 ancestor／frame／section 等足以辨識所屬 Header 或 stock 的關係。另保存 raw `NSWindow.firstResponder`、key window／activation，僅作事件送達與焦點背景診斷；`firstResponder` 即使是 shared hosting view，也不能代替 child 的 focus 語意。若 getter nil、只回 generic hosting view、role／label／value unavailable 或兩控制不可區分，明列 unavailable 並停止為 `blocked`。
- 在目前 OS Keyboard Navigation **off** 原值下，以既有授權作一次 bounded native key event sequence：從 focus start 對 Header 與 stock 分別送 Tab／Shift-Tab、方向鍵及 stock 支援的啟用鍵。觀察性 key monitor 只安裝一次、回傳原 event，不攔截或改寫；每鍵附唯一序號，dispatch 後 deferred snapshot 記錄事件、key window／activation、local focused child 語意、raw first responder、兩側 selected values 與 parent Binding 診斷及前後變化，避免把送鍵前或其他 runner 視窗的焦點誤作結果。只有這些 trace 可辨且相符，Tester／Reviewer 才能判此 **off 設定下** Header／stock parity；無法辨識即停止 `blocked`，不得以兩者皆略過或測試 exit 0 代替焦點證據。
- Keyboard Navigation **on** 僅在已預置為 on 的獨立 macOS user session／VM 可用時另行執行；目前缺該環境，保持 `blocked`，不能標 IH-04 pass。不得改目前或全域設定、要求新的 TCC／Accessibility grant、要求 Human 鍵盤重試或使用 undocumented per-app defaults。不得新增持久 UI-test target／repo path；若需此類範圍或產品修改，先回 Human scope／path review。PR-03 獨立 `approved` 後才交 Implementer→Tester→Reviewer；Human HC-02 仍 pending。

## Boundary 與依據

- Row、List、其 tests／Previews、PR Inbox BC、native interaction contract 與 HTML prototype 均 ReadOnly。Header 不擁有 selection restoration、Open PR、Reader routing 或 workspace state。
- 固定 filter 只描述 Presentation 意圖；`Needs Review`／`Mentioned` 的 membership 與 GitHub query 定義留給未來正式 topic。
- `docs/presentation/native-interaction-contract.md` §4 保留 Header／filters chrome；§7、§10 約束原生選取／accessibility；§8 約束非 diff 無水平捲動；§13 要求九欄與 TestCase trace。完整 path、TestCase 與 gate 以同 slug `.plan.md` 為準。
