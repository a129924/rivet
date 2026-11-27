# PR Inbox I1 技術規格

SwiftPM 驗證 App 依賴公開的 RivetPresentation。重用 InboxHeader、PullRequestList 及其組合的 PullRequestRow。PR Inbox 定義自查候選。實驗 Session 持有快照、選取及事件，View 負責實際鍵盤與 VoiceOver 焦點。

固定合成列 A、B 分屬不同 repository，PR 編號相同。三列皆可選，C 不可開啟。重排保留 B，移除 B 回退 A。過期 B 的注入驗證 Session 接收端，下一次原生 Enter 驗證當前 A。可讀舊資料允許本地選取，Open 安全性與復原能力各自為未知。可用性缺失落錯誤，離線取自明示情境。

建置與單元測試支持套件和 Session。原生手勢、視窗焦點、明暗與 VoiceOver 均按實際觀察判讀。

[執行計畫](../../plan/pr-inbox-i1-verification/pr-inbox-i1-verification.plan.md)

## 2026-11-26 Plan Amendment · 採用邊界

設計語言採用基準是 tag `v0.1.97-rivet-design-language-adoption` 指向的 `e53214ed9327174c316724c4b8ba28e227526d4f`。本次整合基線是最新核對的 `origin/dev` `d92eea7fafc93625311693ac2583111f2a1e07cb`。採用提交是該基線的祖先，後續提交只整理實驗索引與驗證摘要。原 I1 分支與驗證基線仍分別記為 `9610830` 與 `e0cab03`。

- **既定共用能力。** `RivetPalette` 的 Background／Primary／Secondary／Surface 和 `RivetBrandMark` 留在 `RivetPresentation` internal。只在非控制項的靜態文字使用 palette 前景。16 pt glyph 與可辨識的 Rivet 文字並列，glyph 為裝飾，品牌只朗讀一次。
- **提案的唯一公開接線。** 新增一個 `InboxWorkspace` SwiftUI view，讓獨立 SwiftPM 消費者可用正式容器。容器接受既有 Header 顯示資料與 filter Binding／enablement、側欄與內容的 View，以及驗證端的 footer slot，持有分層及 compact 版面。由同 target 的 Header 內部接線將 Primary／Secondary 限於標題與副標。既有 Header、List、Row 的公開介面及獨立使用外觀／行為維持舊契約。E024 透過單一入口引用正式容器，維持既有選取、焦點、事件與 Session。
- **原生內容。** 清單外層可用 `.scrollContentBackground(.hidden)` 讓 Surface 承接捲動區，只在該內容區作用。選列、List 內分隔、Picker 前景和 accent、焦點環、inactive 與 disabled 由系統呈現。使用低對比原生 Divider 作結構分界，保留現行可及性行為。Border 共用、Login Border 色值及 symbol-only 皆未鎖定。
- **受限寬度。** 寬版用側欄與內容並列。完整 workspace 內容寬 420 pt 時，側欄收斂成靜態 compact 列，保留品牌與 repository 語意，Header 用既有窄版垂直排列。採維持子 View identity 的配置，讓 List 及其焦點繫結在 resize 前後仍為同一份。既有 620／480／340 pt 是列可用寬度的降階門檻。記錄 List 可用寬度，並用長標題驗證單行尾截斷、完整 AX 名稱及 PR 識別優先。E024 的舊 720 pt 內容最小寬度只為本次驗證入口調整。
- **測試入口。** E024 預設仍為原有 disabled filter。以受控選單啟用原生 Picker，驗證鍵盤與強調色。切換 Picker 只改顯示 Binding，固定清單順序與資料保持原樣。長標題以顯示 fixture 供 420 pt 驗收，維持 A／B／C 完整識別及舊 Session 行為。

[Visual Design Contract](../../docs/presentation/visual-design-contract.md) · [原生互動契約](../../docs/presentation/native-interaction-contract.md) · [Apple AnyLayout](https://developer.apple.com/documentation/swiftui/anylayout) · [Apple 捲動背景](https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:))
