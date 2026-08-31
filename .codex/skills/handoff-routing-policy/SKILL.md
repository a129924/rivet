---
name: handoff-routing-policy
description: 依呼叫端明示的結果與路由規則決定下一個交接目標；不判定工作結果本身。
---

# 交接路由規則

使用此 skill 將已明示的工作結果套用至呼叫端提供的 routing map。它只處理路由，不驗證、解讀或產生結果。

## 必要輸入

- 已明示的 result value。
- 對應 result value 的 routing map。
- 每個候選路由所需的最小 context。

## 路由

- 只選擇 routing map 中與 result value 完全相符的目標，並交接該目標需要的最小 context。
- 若 result、routing map、目標或必要 context 缺少或不唯一，停止路由，列出缺少資訊並交還呼叫端。
- 保留 result 原值；不可將其改寫成另一種狀態或品質結論。

## 邊界

- 不檢查內容正確性、不實作、不改檔、不審查、不計算 gate，也不執行 Git 或外部動作。
- 不自行產生 result、approval、優先順序或 routing map。
- 路由不足只表示目前無法路由，不可被表述為工作失敗或核准。
