---
name: swift-tdd
description: 以測試驅動方式實作或修正明確的 Swift／SwiftPM 行為。適用於需要 red-green-refactor 與局部驗證的工作，不用於建置、啟動或診斷流程。
---

# Swift TDD

## 使用時機

在需求或 bug 對應到可觀察的 Swift 行為，且可識別目標程式碼與測試邊界時使用。

## 最小輸入

- 明確的行為需求或 bug。
- 目標 source／test 範圍，或可供探索的 repository。
- 適用的測試命令，以及 caller 要求的 format、lint 或 coverage 設定。

## 工作方式

1. 辨識既有測試框架與最小可測邊界。
2. 新增或調整一個可代表需求的 failing test，並確認失敗可歸因於目標行為尚未實作。
3. 以最小變更使測試通過。
4. 只在測試持續通過時進行必要重構。
5. 執行受影響測試及 caller 指定的 format、lint、coverage 驗證。

## 輸出

回報：

- 測試邊界。
- red test 與其可歸因的失敗證據。
- green 後已執行的驗證結果。
- 若停止，僅回報本次工作的局部 blocker 與缺少資訊。

## 停止條件

遇到下列情況時停止，不自行猜測：

- 需求、可觀察行為或測試邊界不明。
- 需要未授權的 public contract 或架構變更。
- 無法區分測試失敗是環境問題或目標行為問題。

## 邊界

- 不假設固定測試框架、coverage 門檻或 app 啟動方式。
- 不取代專門的 SwiftPM 建置／執行、app 啟動／debug 或測試失敗診斷工作。
- 不執行或要求 commit、push、PR、branch、worktree 或其他 Git workflow。
