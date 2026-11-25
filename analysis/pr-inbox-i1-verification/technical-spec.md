# PR Inbox I1 技術規格

SwiftPM 驗證 App 依賴公開的 RivetPresentation。重用 InboxHeader、PullRequestList 及其組合的 PullRequestRow。PR Inbox 定義自查候選。實驗 Session 持有快照、選取及事件，View 負責實際鍵盤與 VoiceOver 焦點。

固定合成列 A、B 分屬不同 repository，PR 編號相同。三列皆可選，C 不可開啟。重排保留 B，移除 B 回退 A。過期 B 的注入驗證 Session 接收端，下一次原生 Enter 驗證當前 A。可讀舊資料允許本地選取，Open 安全性與復原能力各自為未知。可用性缺失落錯誤，離線取自明示情境。

建置與單元測試支持套件和 Session。原生手勢、視窗焦點、明暗與 VoiceOver 均按實際觀察判讀。

[執行計畫](../../plan/pr-inbox-i1-verification/pr-inbox-i1-verification.plan.md)
