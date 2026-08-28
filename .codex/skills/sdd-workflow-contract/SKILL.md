---
name: sdd-workflow-contract
description: 定義正式 topic 的 SDD artifacts、角色、handoff、verdict 與 human boundary；用於規劃、派遣與審查工作。
---

# SDD 工作流程契約

使用本 skill 時，正式 topic 僅承認同一 slug 的三份 planning artifacts。先讀取 [topic artifacts contract](references/topic-artifacts.md)；需要派遣或處理 verdict 時，再讀取 [routing and verdicts](references/routing-and-verdicts.md)。

## 不可變規則

- roles 僅限 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer、Observer/Dispatcher。
- 已鎖定的 scope、architecture、path 或 contract decision 不得任意重開；資訊不明時回報 `blocked`，不得猜測。
- Observer/Dispatcher 只可讀取 task、branch、worktree、PR 與 topic 狀態，派遣單一適當角色，彙整結果，並依已產生的 verdict 路由。
- Observer/Dispatcher 不得實作、改檔、審查、計算 gate、執行 Git、commit、push、建立 tag、開 PR 或跨越 human boundary。
- `blocked` 與 `human-check` 都停止自動前進並交還人類；不得以推論取代人類決策。
