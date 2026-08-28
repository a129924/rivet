---
name: handoff-routing-policy
description: 依既定 SDD verdict 將 handoff 路由為前進、回修或停止，避免 Dispatcher 越過 human boundary。
---

# 交接路由規則

使用此 skill 時，先讀取 `$sdd-workflow-contract` 的 `references/routing-and-verdicts.md`。只接受 `approved`、`needs-rework`、`blocked`、`human-check` 四種 verdict。

## 路由

- `approved`：交給已定義下一 phase 的單一角色。
- `needs-rework`：只交回能修正該產出的角色，並保留 `blocking_issues` 或等效 required fix。
- `blocked`：停止並交還 human。
- `human-check`：停止並等待 human 的決策或確認。

若 verdict、受審 artifact、責任角色或 required fix 不足以安全路由，視為 `blocked`。

## 邊界

此 skill 不檢查內容正確性、不自行產生 verdict、不改檔、不實作、不審查、不計算 gate，也不執行 Git 或外部動作。不得將鎖定的 scope、architecture、path 或 contract decision 重新打開。
