# PR Inbox / InboxHeader：需求

## Mission

- **Goal**：以獨立 `pr-inbox-header` topic，在 non-BC `RivetPresentation` 交付可獨立驗收的原生 SwiftUI `InboxHeader`。呈現 Inbox title、subtitle、固定三選一 filter 與目前選取；使用者選擇透過 Binding 交還 parent。
- **Non-Goal**：不重設計已採用的 HTML／native interaction contract，不重開既有 Row/List 決策；不定義篩選的 Domain／Application 業務語意，不實際過濾 Pull Requests、載入資料或增加其他產品能力。
- **In-Scope**：Header 原生排版、三選一互動、parent-owned selected filter、窄寬降階、原生輔助使用語意、獨立 debug Preview 與 Header 自有的 Presentation 測試。
- **Out-Of-Scope**：`InboxContent`、sidebar、workspace、Reader、PR filtering／membership／ordering、repository filtering、loading／empty／error／offline state、全域快捷鍵／menu、Domain／Application／Facade／GitHubIntegration、networking、persistence、cache、production mapper，以及 PullRequestRow／PullRequestList 修改。

## 已鎖定的產品行為

- 標準 fixture 顯示 `PR Inbox` 與 `Pull requests waiting for your attention.`；filter 固定為 `Needs Review`、`Mentioned`、`All`，標準初始選取為 `Needs Review`。名稱是 Presentation 選項，不承諾何種 PR 符合條件。
- 以系統字級、semantic foreground、accent、focus、inactive window 與 Increase Contrast 語意呈現。Heading 最優先，副標次之，filter 是可操作但不主導的 Inbox 控制；不得畫 web 式自訂 pill／card。
- 620 pt 以上顯示左側 title＋單行副標、右側 segmented filter；不足 620 pt 時堆疊為 title、副標、segmented filter。副標尾端截斷；300 pt Preview 必須可觀察 title 與三個可操作 filter，無非 diff 水平捲動。不定義 app 最小視窗尺寸。
- 未來 parent 持有 durable selected filter；Header 只接受 current value 並回寫選擇。切換 filter 不修改 PR 集合、不請求資料、不導航。
- 標題、副標、可用選項與目前選擇須可由輔助技術理解；選取不得只靠顏色。Header 只參與原生控制的 keyboard／focus 行為，不接管 Inbox 全域焦點或快捷鍵。IH-04 的 keyboard 證據須區分 macOS「全面鍵盤操控」（Keyboard Navigation）關閉／開啟；原生 segmented control 不因點擊取得焦點，Tab 焦點可達性受該系統設定影響。

## HC-01「調整」：鍵盤驗證邊界

Human 於 2026-10-01 對 HC-01 明示原值「調整」並停止所有人工鍵盤重試；這不是 Header 採用，也不是 IH-04 通過。先前 Xcode Preview 與暫存 App 的 Tab／Arrow 觀察、當前設定下 Header 與 stock Picker 的部分 parity、inactive／Increase Contrast 人工觀察、VoiceOver filter 名稱／選取語意的部分證據均保留。IH-03 最終 Human 驗收與 VoiceOver heading／subtitle 朗讀仍未完成。

RV-06 保留為 `blocked` 歷史：repository 外 XCUI harness 的十二筆跨行程 `AXFocusedUIElement` 均回 `-25211`，當時沒有可辨識的逐鍵焦點證據，不能判 Header 缺陷或 off parity。2026-10-05 Human 明示 Execution Authorized，僅允許一次受限的 repository 外 host-local 替代驗證；此授權不是 HC-02「採用」、IH-04 pass、系統設定或 Accessibility 權限變更。維持同一原生 host 視窗中的未修改 `InboxHeader` 與 stock SwiftUI segmented `Picker` baseline、相同 parent Binding 診斷；以既有 `NSHostingView.accessibilityFocusedUIElement` 本機 getter 讀取 focus 子元素，記錄可辨識的 role／label／value 及所屬 Header／stock 區域，並以 `NSWindow.firstResponder` 作診斷背景，不以 responder 身分代替子元素語意。一次受限 native key event 序列逐鍵在 dispatch 後取 snapshot，記錄 key window／activation、焦點、兩側選取與 parent 值；事件監聽只觀察並傳回 event，不消耗或改寫。只有在目前 Keyboard Navigation off 條件下，焦點子元素語意可辨且 Header／stock 可區分時，才可依 trace 判該條件下的 parity；local getter 若為 nil、generic、無法辨識所屬或值 unavailable，停止並回報 `blocked`。Keyboard Navigation-on 分支缺預先設定的獨立 session／VM 時仍 `blocked`，IH-04／HC-02 pending。不得改使用者或全域設定、授予 TCC／Accessibility 權限、要求 Human 再試鍵盤、使用未文件化 per-app defaults、在產品加 `.focusable`、增加持久 UI-test target 或修改 `Package.swift`；新 repo path 須另經 Human scope／path review。

Apple 官方 [The SwiftUI cookbook for focus（WWDC23，約 15:25）](https://developer.apple.com/videos/play/wwdc2023/10162/?time=925) 說明 macOS buttons 與 segmented controls 不因 click 取得 focus，需啟用 system-wide Keyboard Navigation 才能以 Tab 到達；這只界定驗證條件，不預判目前元件的結果。

## Scope 與 path contract

`ReadOnly`、`Written`、`Modify`、`Deleted` 的 exact repository-relative paths，以及逐項 TestCase，均以同 slug 的 `plan/pr-inbox-header/pr-inbox-header.plan.md` 為本次唯一執行契約；四組路徑兩兩互斥。四份正式 topic artifacts 使用同一 slug。任一 ReadOnly／未列路徑變更或需新增產品能力時，停止實作並回規劃／Human Review。

## 成功條件與 Human boundary

- `InboxHeader` 可獨立顯示並切換三個固定選項；parent Binding 收到選取變更，Header 不持有 durable state。
- 300 pt、620 pt 與一般寬度、長副標、三種初始選取、Increase Contrast、inactive 的 Preview 可供 Human 檢查；互動診斷只顯示 selected filter，沒有 PR list。
- IH-01～IH-06 的證據按 plan 的 TestCase Register 收集；IH-04 鍵盤採上述一次受限的本機 focus getter／原生事件／host 與 stock baseline 對照，無可辨焦點語意即 blocked；其他未完成的原生觀察維持 Human pending。既有 Row/List、manifest、原型與 BC 不變。
- PC-03 的四份規劃文件先交獨立 Plan-Reviewer PR-03；只有其明示 `approved` 才由 Implementer 在 repository 外既有可拋棄 host 作一次受限本機焦點驗證修正，再由 Tester、獨立 Reviewer 檢查證據。後續 Human Review 不要求人工鍵盤重試；Human 明示下一次「採用／調整／放棄」前不得宣稱採用或開始 `InboxContent`。

## 依據與未鎖定項目

依據：使用者已核准的 `processed-plan`、`prototypes/pr-reader-interactive-ux-prototype/index.html`、`docs/presentation/native-interaction-contract.md` §1／§4／§7／§8／§10／§13，以及已採用的 Row/List。未鎖定的 PR filter 業務語意與未來 Inbox composition 由其他 topic 處理，本 topic 不補造。
