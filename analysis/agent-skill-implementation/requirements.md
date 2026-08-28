# Agent Skill Implementation — Requirements

## Goal

在本 repository 建立一組最小、可維護、語言無關的本地 agent skills，使正式 topic 能以固定 artifacts、獨立規劃審查、可追溯 handoff 與受限 Git 工作方式運作。

## In Scope

- 建立下列本地 skills：`sdd-workflow-contract`、`context-package-builder`、`subagent-dispatch-policy`、`handoff-routing-policy`、`plan-creator`、`plan-reviewer`、`git-branch-naming`、`worktree-manager`、`git-commit-convention`。
- 將正式 topic 的唯一 artifacts 固定為同 slug 的 `requirements.md`、`technical-spec.md` 與 `.plan.md`。
- 定義 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer、Observer/Dispatcher 的責任邊界、handoff 與標準 verdict。
- 提供 branch 命名、worktree 狀態辨識及 human-confirmed commit 的 Git workflow 指引。
- 驗證全部 skills，並由獨立 Reviewer 審查其 workflow contract。

## Out Of Scope

- Application code、Bounded Context 實作、release 設定或產品功能。
- Python、Swift、TypeScript 的實作、TDD、測試框架或型別規範。
- release、post-merge、自動 commit、push 與遠端 Git 操作。
- `agents/openai.yaml`、scripts、模板或額外的 workflow contract 文件。

## Success Criteria

- 九個 skills 可清楚區分規劃、實作、驗證、審查與 routing 責任，且不要求未授權 artifacts。
- Observer/Dispatcher 僅可讀取狀態、派遣、彙整與依 verdict 路由；不實作、改檔、審查、計算 gate 或執行 Git 操作。
- Planning artifacts 缺失、scope／BC／path／locked decision 不明時，流程停止並回報 `blocked`，不自行推論。
- `plan-reviewer` 的最終輸出可被 Dispatcher 直接路由，且只使用既定 JSON 格式。
- 所有新增 skills 通過 skill validator，獨立審查沒有未處理 blocker。

## Recovery Baseline

既有 `v0.1.0-architecture-baseline` 足以作為本 topic 的實作前回溯點。tag 僅可在 draft PR 建立並交給 human review 後，作為非阻擋的 cleanup；Observer/Dispatcher 不得建立、移動或推送 tag。
