---
name: context-package-builder
description: 為既定 subAgent 建立最小、可追溯的 SDD handoff context；用於派遣前的交接整理。
---

# 交接內容建立器

使用此 skill 建立下一個既定角色所需的最小交接內容。先讀取 `$sdd-workflow-contract` 的 `references/topic-artifacts.md`。

## 交接內容

輸出唯一一個 JSON，包含 `topic`、`phase`、`artifacts`、`current_step`、`locked_decisions`、`upstream_verdict`、`blockers`、`assigned_role`、`next_objective`。`artifacts` 必須列出四份正式 artifacts，`current_step` 必須含 `.step.md` 中明示的 ID 與 status。欄位與值域遵循共用 contract。

只包含已驗證的 repository 狀態與上游結果；不可將猜測、要求或尚未決定的方案標為 locked decision。`next_objective` 必須限縮為受派角色可完成的單一工作。

## 邊界

- 不派遣、不實作、不改檔、不審查、不計算 gate，也不執行 Git。
- artifacts、scope、BC、path 或 locked decision 不明時，只將原因列入 `blockers`。保留上游原有的明示 verdict；沒有上游 verdict 時維持 `null`，不得改成或推導為 `blocked`。
- `.step.md` 的 checkbox 或 status 不得標為 approval；不增列 release、VERSION、summary 或 correction artifacts。
