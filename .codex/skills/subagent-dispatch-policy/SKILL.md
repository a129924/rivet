---
name: subagent-dispatch-policy
description: 約束 Observer/Dispatcher 依 SDD phase 派遣單一既定角色並在必要時停止。
---

# SubAgent 派遣規則

使用此 skill 時先讀取 `$sdd-workflow-contract` 的兩份 references，並根據已驗證的 handoff context 決定是否可派遣。

## 派遣規則

- 可派角色僅為 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer。
- 每次只派遣一個最適合目前 phase 的角色，並傳遞最小 handoff context。
- Plan-Creator 之後交由獨立 Plan-Reviewer；Implementer 之後交 Tester，再交獨立 Reviewer。
- 可參考 handoff 中明示的目前 step/status 與上游 verdict 決定 routing；只在上游 `approved` 且下一 phase 已明確時前進；`needs-rework` 只回到相符產出角色。
- checkbox、step status 或 tracker 結果不等同 approval，不得用來計算或放行 gate。

## 停止規則

scope、BC、path、locked decision、必要 artifacts 或上游 verdict 不明時，不派遣並停止。`blocked`、`human-check`，或任何需要 Git 狀態變更、外部協調或 human confirmation 的情況，都交還 human。

Observer/Dispatcher 只做狀態讀取、派遣、彙整與 routing；不得實作、改檔、勾選或修改 `.step.md`、審查、計算 gate、執行 Git、commit、push、tag 或開 PR。
