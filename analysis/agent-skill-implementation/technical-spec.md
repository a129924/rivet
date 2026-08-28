# Agent Skill Implementation — Technical Spec

## Artifact Contract

正式 topic 必須以同一 slug 建立且只承認下列 planning artifacts：

| Artifact | Responsibility |
| --- | --- |
| `analysis/<topic>/requirements.md` | 產品意圖、範圍與成功條件 |
| `analysis/<topic>/technical-spec.md` | 已確認的執行設計與限制 |
| `plan/<topic>/<topic>.plan.md` | 本次受限的執行契約、寫入範圍與驗收 |
| `plan/<topic>/<topic>.step.md` | 執行狀態帳本：目前 phase、步驟、owner role、完成條件、驗證證據、blocker、verdict 與 human-check |

`analysis/` 保存研究與設計依據；`plan/` 保存本次執行契約與其執行狀態。`.step.md` 是正式必備 artifact，不是選擇性附加檔；每個 step 必須可追溯至 owner role、完成條件與驗證證據，並有 Blockers、Human Check 與最後更新資訊。step checkbox 或 status 絕不等同 approval。長期成立的架構結論仍依 repository 規範回寫 `docs/`。skills 不得將 release、VERSION、summary 或 correction artifacts 變成必備條件。

## Skill Set

| Skill | Bounded responsibility |
| --- | --- |
| `sdd-workflow-contract` | 共用 roles、phase、artifacts、handoff、verdict 與 human boundary；其下僅有 topic artifacts 與 routing/verdicts references。 |
| `context-package-builder` | 建立可追溯的最小 handoff context。 |
| `subagent-dispatch-policy` | 限制 Observer/Dispatcher 的角色選擇、單一派遣與停止條件。 |
| `handoff-routing-policy` | 將既定 verdict 路由為前進、回修或停止。 |
| `plan-creator` | 只建立或修正四份 planning artifacts，並產生初始 `.step.md`。 |
| `plan-reviewer` | 只獨立審查四份 planning artifacts，絕不代寫。 |
| `plan-step-tracker` | 只檢查 `.step.md` 的結構、必要欄位與狀態完整性；不完成步驟、不產生 verdict、不取代 Tester 或 Reviewer。 |
| `git-branch-naming` | 提供 branch 名稱建議，不執行 Git。 |
| `worktree-manager` | 提供具完整 lifecycle contract 的 managed／unmanaged worktree 操作指引；以三份 references 保存可操作細節。 |
| `git-commit-convention` | 依 staged diff 提出語意邊界與 commit message，等待 human confirmation。 |

## Workflow Contract

- Roles 限定為 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer、Observer/Dispatcher。
- Observer/Dispatcher 只可檢查 task、branch、worktree、PR、topic 與 `.step.md` 狀態，派遣單一適當角色，彙整結果並依明示 step 狀態及 verdict 路由；不得直接實作、改檔、勾選或修改 step、審查、計算 gate、commit、push、開 PR 或跨越 human boundary。
- 最小 handoff 包含：topic slug、目前 phase、四份 artifact paths 與狀態、目前 step/status、locked decisions、上游 verdict、未解 blockers、受派角色與下一步目標。不得將未驗證推論標示為鎖定決策。
- 標準 verdict 僅為 `approved`、`needs-rework`、`blocked`、`human-check`。`approved` 可前進；`needs-rework` 僅回到相符的產出角色；`blocked` 與 `human-check` 均停止自動前進並交還人類。
- Dispatcher 可參考明示的 step 狀態與 verdict 作 routing，但不得把 checkbox、status 或 tracker 結果當成 approval 或 gate 結論。
- Plan-Creator 與 Plan-Reviewer 必須獨立；reviewer 不得修正或代寫 plan。任何 scope、architecture、path 或 contract 的 locked decision 不得由 skill 任意重開。

## Git Boundary

Git workflow 僅包含 branch naming、worktree lifecycle 與 human-confirmed commit。Observer/Dispatcher 對 Git 僅有唯讀狀態判斷權；所有改變 Git 狀態的行為只能由獲授權的非-Dispatcher 角色在 human boundary 後執行。軟體 release、post-merge、tag 自動化、auto commit、push 與遠端操作不屬於此 skill set。

### Worktree Lifecycle Contract

- `worktree-manager` 的 frontmatter 必須定義 `inputs`、`outputs`、`use_when`、`do_not_use_when` 與 `risk_profile`；其 lifecycle 僅為 `create`、`get-worktree`、`release worktree`、`remove worktree`。
- managed path 固定為 repository root 外的 `../<repo-name>.worktrees/<prefix>-YYYYMMDD-<worktree-name>`；branch collision 必須停在 human 的 reuse-or-rename 決策。shared planning 或 governance files 可能跨 worktree 變更時，必須提出 coordination warning。
- `release worktree` 是非破壞性的 active-working-set offboarding，不得隱含刪除；`remove worktree` 必須有當前明確的 human destructive approval，並在 dirty、untracked、unpushed、detached、locked、unmanaged 或不明狀態時停止。unmanaged worktree 預設 inspect-only，不得自行 release、remove、delete、prune、rename 或假設完成。
- `get-worktree` 對每個 worktree 固定回傳 `path`、`branch`、`status`、`dirty state`、`recommendation`、`reason`、`next safe action`。missing-path-but-registered 僅路由為 `prune-candidate`，不得 auto-prune；status、checkbox 或 tracker 結果均不等同 approval。
- 主 skill 必須連結 `reference.md`、`examples.md`、`checklist.md`，涵蓋固定術語／release evidence、正反 lifecycle 情境及可重複執行的 safety checks。Rivet 的唯一差異是角色限制：Observer/Dispatcher 只能讀取 `get-worktree` 結果並 routing；已獲授權的非-Dispatcher 角色可依 lifecycle contract 執行 create、release 或 remove。

## Review Output

`plan-reviewer` 與本 topic 的獨立 skill review 在完成檢查時只輸出下列 JSON；`blocking_issues` 每項包含 `issue`、`artifact` 與 `required_fix`：

```json
{
  "verdict": "approved|needs-rework|blocked|human-check",
  "blocking_issues": [],
  "notes": []
}
```
