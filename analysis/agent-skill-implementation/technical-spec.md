# Agent Skill Implementation — Technical Spec

## Artifact Contract

正式 topic 必須以同一 slug 建立且只承認下列 planning artifacts：

| Artifact | Responsibility |
| --- | --- |
| `analysis/<topic>/requirements.md` | 產品意圖、範圍與成功條件 |
| `analysis/<topic>/technical-spec.md` | 已確認的執行設計與限制 |
| `plan/<topic>/<topic>.plan.md` | 本次受限的執行契約、寫入範圍與驗收 |

`analysis/` 保存研究與設計依據；`plan/` 只保存本次執行契約；長期成立的架構結論仍依 repository 規範回寫 `docs/`。skills 不得將 release、VERSION、step、summary 或 correction artifacts 變成必備條件。

## Skill Set

| Skill | Bounded responsibility |
| --- | --- |
| `sdd-workflow-contract` | 共用 roles、phase、artifacts、handoff、verdict 與 human boundary；其下僅有 topic artifacts 與 routing/verdicts references。 |
| `context-package-builder` | 建立可追溯的最小 handoff context。 |
| `subagent-dispatch-policy` | 限制 Observer/Dispatcher 的角色選擇、單一派遣與停止條件。 |
| `handoff-routing-policy` | 將既定 verdict 路由為前進、回修或停止。 |
| `plan-creator` | 只建立或修正三份 planning artifacts。 |
| `plan-reviewer` | 只獨立審查 planning artifacts，絕不代寫。 |
| `git-branch-naming` | 提供 branch 名稱建議，不執行 Git。 |
| `worktree-manager` | 提供 worktree 狀態與受限 lifecycle 指引。 |
| `git-commit-convention` | 依 staged diff 提出語意邊界與 commit message，等待 human confirmation。 |

## Workflow Contract

- Roles 限定為 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer、Observer/Dispatcher。
- Observer/Dispatcher 只可檢查 task、branch、worktree、PR 與 topic 狀態，派遣單一適當角色，彙整結果並依明示 verdict 路由；不得直接實作、改檔、審查、計算 gate、commit、push、開 PR 或跨越 human boundary。
- 最小 handoff 包含：topic slug、目前 phase、artifact paths 與狀態、locked decisions、上游 verdict、未解 blockers、受派角色與下一步目標。不得將未驗證推論標示為鎖定決策。
- 標準 verdict 僅為 `approved`、`needs-rework`、`blocked`、`human-check`。`approved` 可前進；`needs-rework` 僅回到相符的產出角色；`blocked` 與 `human-check` 均停止自動前進並交還人類。
- Plan-Creator 與 Plan-Reviewer 必須獨立；reviewer 不得修正或代寫 plan。任何 scope、architecture、path 或 contract 的 locked decision 不得由 skill 任意重開。

## Git Boundary

Git workflow 僅包含 branch naming、worktree lifecycle 與 human-confirmed commit。Observer/Dispatcher 對 Git 僅有唯讀狀態判斷權；所有改變 Git 狀態的行為只能由獲授權的非-Dispatcher 角色在 human boundary 後執行。release、post-merge、tag 自動化、auto commit、push 與遠端操作不屬於此 skill set。

## Review Output

`plan-reviewer` 與本 topic 的獨立 skill review 在完成檢查時只輸出下列 JSON；`blocking_issues` 每項包含 `issue`、`artifact` 與 `required_fix`：

```json
{
  "verdict": "approved|needs-rework|blocked|human-check",
  "blocking_issues": [],
  "notes": []
}
```
