# PR Inbox / InboxHeader：Implementation Plan

## Mission 與九欄契約

- **Goal**：獨立 `pr-inbox-header` topic 在 non-BC `RivetPresentation` 交付原生 SwiftUI `InboxHeader`，顯示 title、subtitle、固定三 filter 與目前 selected filter，將選取更新交 parent。
- **Non-Goal**：不重設計已採用 HTML／native interaction contract 或 Row/List；不實作 PR filter 業務語意、資料載入或其他 capability。
- **In-Scope**：Header 的 native layout、固定單選、parent Binding、窄寬降階、accessibility、獨立 debug Preview、Presentation-level tests、驗證後的現況文件回寫。
- **Out-Of-Scope**：InboxContent／sidebar／workspace、Reader、PR collection/filtering/membership/ordering、repository filter、loading/empty/error/offline、全域命令、Domain／Application／Facade／GitHubIntegration、networking、persistence、cache、production mapper、Row/List 修改、commit/push/PR/release／下一 Mission。

## Exact Path Register

四組兩兩互斥，均為 exact repository-relative file path；Written 在 baseline 不存在，其他列出的檔案在 baseline 存在。超出 Written／Modify 或需碰 ReadOnly 時，停止並回 planning／Human Review。

### ReadOnly

- `Package.swift`
- `docs/design-principles.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/native-interaction-contract.md`
- `prototypes/pr-reader-interactive-ux-prototype/index.html`
- `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestList+Previews.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
- `Tests/RivetPresentationTests/PullRequestListTests.swift`

### Written

- `analysis/pr-inbox-header/requirements.md`
- `analysis/pr-inbox-header/technical-spec.md`
- `plan/pr-inbox-header/pr-inbox-header.plan.md`
- `plan/pr-inbox-header/pr-inbox-header.step.md`
- `Sources/Presentation/PRInbox/InboxHeader.swift`
- `Sources/Presentation/PRInbox/InboxHeader+Previews.swift`
- `Tests/RivetPresentationTests/InboxHeaderTests.swift`

### Modify

- `README.md` — 實作通過驗證後，僅更新已交付的 Presentation 現況。
- `docs/architecture/README.md` — 實作通過驗證後，僅更新已交付的 Presentation 現況。

### Deleted

None。

## Implementation contract

- Public `InboxHeaderFilter: CaseIterable, Hashable, Sendable` 固定 `.needsReview`、`.mentioned`、`.all`，`title` 分別為 `Needs Review`、`Mentioned`、`All`。不加 raw persistence／query 意義或變動選項 API。
- Public `InboxHeaderPresentation: Equatable, Sendable` 以 `let title`／`let subtitle` 及 `init(title:subtitle:)` 保存 display-ready values。Public `InboxHeader(presentation: InboxHeaderPresentation, selectedFilter: Binding<InboxHeaderFilter>)` 只接受 parent-owned Binding；Header 不以 `@State` 持久持有 filter，也不修改 PR items。
- 原生 `Picker("Inbox filter", selection:)` 與 `.pickerStyle(.segmented)` 呈現三個 tagged options。Heading 具系統 typography 與 heading trait，副標為 secondary Text；原生控制負責 focus、keyboard、accent、inactive、Increase Contrast 與 selected 語意。不加 custom pill/card、global shortcut 或自畫 segmented control。
- `ViewThatFits(in: .horizontal)` 的寬候選以 620 pt 為最小 fit：左 title＋單行 subtitle，右 Picker；不足 620 pt 時改為 title、副標、同一 segmented Picker 的垂直排列。副標 tail truncation；保留 title 與三選項、無水平捲動。620 pt 不是 app minimum；300 pt 是窄版 Preview checkpoint。300 pt 若原生 control 不可用，停回 Human Review，不自行重開控制決策。
- Debug-only Preview harness 持有 `@State`、顯示 `Selected filter: <title>`，覆蓋 `.needsReview`／`.mentioned`／`.all` 初始值、標準／620／300 pt、長副標、Increase Contrast 與 inactive；不建 PR list 或 filtering。Production 只有 Header。
- `Package.swift` 不變，既有 Row/List 與 BC、prototype、native contract 不變。驗證後才回寫 `README.md`、`docs/architecture/README.md` 的已交付現況。

## TestCase Register

| ID | Context／trigger | Observable expected result | Evidence method | Adopted contract trace |
| --- | --- | --- | --- | --- |
| IH-01 | 建立 `InboxHeaderFilter` 並列舉 cases／title。 | 恰三個固定且唯一的 identity，順序 Needs Review、Mentioned、All，文字逐一對應。 | `InboxHeaderTests` Swift Testing。 | 已採用 HTML prototype filter；native contract §4、§13。 |
| IH-02 | Parent 傳入 title／subtitle／Binding，於 Preview 改選三段。 | Input 原值呈現；選取寫回 parent，診斷文字同步；Header 不持久持有 filter，也不過濾 PR。 | Swift Testing 核對 input／Binding contract；Human 操作 debug Preview，核對診斷值與無 PR collection。 | native contract §1、§4、§13；Presentation Session ownership。 |
| IH-03 | 顯示標準寬、620 pt、300 pt 與長 subtitle。 | Heading 始終可見；寬版左右排、窄版垂直；副標尾端截斷；三段控制仍可操作，無水平捲動。 | Human 檢視並操作四種 Preview；記錄畫面證據。 | native contract §8，AC-NI-016／017。 |
| IH-04 | 在 macOS Keyboard Navigation off／on 條件檢查 native segmented Picker keyboard focus／selection；另檢查 VoiceOver、Increase Contrast、active/inactive window。 | Heading／副標與三選項／選取可讀、非僅顏色；鍵盤結果須按系統設定與 stock segmented Picker baseline 對照。Off 只可在本機 focused child 的 role／label／value 與所屬區域可辨時聲稱同設定 parity；nil／generic／不可區分即 blocked。On 分支無預置隔離環境時 blocked，不可標 IH-04 pass。 | Repository 外既有 disposable native host 載入未修改 Header 與 stock Picker、同型別 parent Binding 診斷；一次受限 native key events＋`NSHostingView.accessibilityFocusedUIElement` 本機 focused child 語意、raw `NSWindow.firstResponder` 診斷、key window／activation 與逐鍵 dispatch 後 parent／selected value 紀錄。Off 在目前設定；on 僅在已預置獨立 session／VM 可用時另驗。Tester 獨立核對，Human 不再重試鍵盤；VoiceOver／contrast／inactive 既有觀察分開保留。 | native contract §7、§10，AC-NI-026／027／035／036；[Apple WWDC23 Focus Cookbook](https://developer.apple.com/videos/play/wwdc2023/10162/?time=925)。 |
| IH-05 | 檢查 source、test、docs diff 與 target dependency。 | 變更只在 Written／Modify；Row/List、BC、manifest、prototype、native contract 不變；無 production mapper、filtering、workspace。 | 獨立 Reviewer 核對 exact paths 與 diff。 | native contract §1、§13；既有 Row/List acceptance。 |
| IH-06 | 實作後執行受限及全量驗證。 | Focused/root tests、debug/release build、format 與 SwiftLint exit 0；人工項目仍標 Human pending。 | Tester 獨立執行下列六個 commands，記錄結果；Reviewer 查證。 | native contract §13；IH-01～IH-05。 |

## HC-01「調整」與 PC-03 鍵盤驗證 handoff

2026-10-01 Human 對 HC-01 明示原值「調整」並停止所有人工鍵盤重試；此決策關閉該次 Human Check，不是採用或 IH-04 pass。RV-01～RV-06、TE-01～TE-06 verdict 各保留為當時證據，尤其 RV-06 `blocked` 的 `AXFocusedUIElement:-25211` 不得覆寫。Inactive 與 Increase Contrast 的 Human 觀察、VoiceOver filter 名稱與選取語意的部分證據、IH-03 待最終 Human 驗收保持原狀。2026-10-05 Human 的 Execution Authorized 僅恢復一次 bounded repository 外 keyboard evidence 方法修訂與執行，不是 HC-02「採用」、on-session、global setting 或 Accessibility 權限授權。

Apple 官方 [The SwiftUI cookbook for focus（WWDC23，約 15:25）](https://developer.apple.com/videos/play/wwdc2023/10162/?time=925) 明示 macOS segmented controls 不因 click 取得 focus，Tab focus 需 system-wide Keyboard Navigation；此來源界定條件，不預判結果。

- PC-03 只修訂四份同 slug planning artifacts，Exact Path Register 與 public API、Binding、Picker、620 pt layout、Presentation 邊界均不變。先交獨立 Plan-Reviewer PR-03；明示 `approved` 前不改驗證 host 或執行 GUI。
- PR-03 `approved` 後，Implementer 只在 repository 外既有 disposable native host 實作一次受限的 host-local focus 診斷。同一 `WindowGroup`／`VStack`／hosting view 保留未修改 Header 與 stock Picker 及各自 parent Binding 診斷，不拆 hosting view、不加 `.focusable`、不改 product 或 `Package.swift`。
- 從 `NSHostingView.accessibilityFocusedUIElement` 本機 getter 取得 focused child，記錄 role／label／value 及 ancestor／frame／section 等足以辨識 Header／stock 的關係；`NSWindow.firstResponder` 僅作 raw 診斷。Native key monitor 僅安裝一次且回傳 event，每鍵編號，dispatch 後 deferred snapshot 記錄 key window／activation、focus child、first responder、兩側 selected value／parent Binding 診斷及變化。不得把 shared hosting view responder 或其他視窗焦點當 child 語意。若 getter nil、generic、缺 role／label／value 或無法區分兩控制，立即停止 `blocked`。
- 在目前 Keyboard Navigation off 條件下，Tester 只核對這一次 bounded native Tab／Shift-Tab／方向鍵／啟用鍵 trace 是否足以判 Header／stock parity；兩者都略過或測試 exit 0 不等於 IH-04 pass。Reviewer 再獨立分類結果。跨行程 AX 的原失敗保留；不得要求 TCC／Accessibility grant、改使用者或全域設定、要求 Human 再試鍵盤、使用未文件化 per-app defaults。
- Keyboard Navigation-on 只有已有且預設 on 的獨立 macOS user session／VM 才可另驗；目前缺環境，分支保持 `blocked`，IH-04／HC-02 pending。下一次 Human Check 只處理剩餘視覺／VoiceOver／整體採用，不要求鍵盤重試。新 repo path、持久 UI-test target、manifest 或產品控制契約變更均須先回 Human scope／path review；未有 Human 原值「採用」前不開始 `InboxContent`。

## 初始實作驗證與 handoff（歷史）

以下保留原始 implementation gate；目前 IH-04 鍵盤方法以上方 HC-01「調整」段為準，不要求 Human 重試鍵盤。Implementer 在原始 Plan-Reviewer 明示 `approved` 後新增 Header／Preview／test，並於通過驗證後做兩份現況文件回寫；不得從本 plan 自行擴張檔案或能力。Tester 獨立執行：

```sh
swift test --filter InboxHeaderTests
swift test
swift build -c debug
swift build -c release
scripts/check-swift-format.sh
swiftlint lint --strict
```

Reviewer 獨立審查 IH-01～IH-06 的 source、測試、文件及 path／contract drift；只有其明示 `approved` 才交 Human Review。Human delivery 包含三種 selected filter、標準／620／300 pt／長副標、Increase Contrast／inactive、keyboard／VoiceOver 的視覺與互動證據、Binding 診斷變更、exact changed paths、六項命令結果與責任邊界。Human 明示「採用／調整／放棄」後停止；不開始 `InboxContent`。若需修改 ReadOnly、未列路徑或變更 filter/control 決策，先停止並回 planning／Human Review。
