---
name: subagent-dispatch-policy
description: 約束 Observer/Dispatcher 依 SDD phase 派遣單一既定角色並在必要時停止。
---

# SubAgent 派遣規則

使用此 skill 時先讀取 `$sdd-workflow-contract` 的兩份 references，並根據已驗證的 handoff context 決定是否可派遣。

## 派遣規則

- 可派角色僅為 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer。
- 每次只派遣一個最適合目前 phase 的角色，並傳遞最小 handoff context。
- 依 `$sdd-workflow-contract` 的 phase 與 artifact readiness table 派遣：規劃準備可派 Plan-Creator 建立缺少 artifacts；Plan-Reviewer 開始前必須有四份 artifacts；實作只在 Plan-Reviewer 明示 `approved` 後派遣；Implementer 之後交 Tester，再交獨立 Reviewer。
- 可參考 handoff 中明示的目前 step/status 作為脈絡，並只依上游已明示 verdict 決定後續 routing；`needs-rework` 只回到相符產出角色。
- checkbox、step status 或 tracker 結果不等同 approval，不得用來計算或放行 gate。

## 停止規則

依目前 phase 所需資訊判斷是否可派遣：缺少正式 artifacts 時可派 Plan-Creator 建立；Plan-Reviewer 缺 artifacts、或後續 phase 缺少所需的明示上游結果時，不派遣並停止。scope、BC、path 或 locked decision 不明，或上游結果為 `blocked`、`human-check` 時，交還 human。任何需要外部協調或 human confirmation 的情況，也交還 human。

Git 或 worktree 狀態變更不由 Observer/Dispatcher 執行或判定。已有明確 human 授權時，僅將工作交給獲授權的非-Dispatcher 角色，並由 `$git-branch-naming`、`$worktree-manager` 或 `$git-commit-convention` 各自的 lifecycle 與 human boundary 判斷是否可執行；不得以本 skill 的 routing 取代該判斷。

Observer/Dispatcher 只做狀態讀取、派遣、彙整與 routing；不得實作、改檔、勾選或修改 `.step.md`、審查、計算 gate、執行 Git、commit、push、tag 或開 PR。
