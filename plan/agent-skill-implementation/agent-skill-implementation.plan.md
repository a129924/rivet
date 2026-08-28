# agent-skill-implementation

## Goal

建立完整的本地 SDD、Dispatcher handoff／routing 與受限 Git workflow skills；既有 architecture baseline tag 提供 implementation 前回溯點。

## Git Recovery Baseline

- 既有 `v0.1.0-architecture-baseline` 足以作為本 topic 的實作前回溯點。
- draft PR 建立並交給 human review 後，才可考慮 tag cleanup；該 cleanup 非阻擋，且不得影響實作、驗證、commit、push 或 draft PR 建立。
- Observer/Dispatcher 不得建立、移動或推送 tag。

## Non-Goal

不加入 Python、Swift、TypeScript 實作細節、release、VERSION、step、summary 或 correction workflow；不變更 application code；不自動 commit、push 或操作 tag。

## Agent-skills Adoption Baseline

| Upstream skill | 本次本地化處理 |
| --- | --- |
| `context-package-builder` | 建立最小、可追溯的 subAgent handoff context skill。 |
| `subagent-dispatch-policy` | 建立限定角色、單一派遣與停止條件的 Dispatcher policy skill。 |
| `handoff-routing-policy` | 建立依標準 verdict 路由或停止的 policy skill。 |
| `plan-creator` | 建立符合 Rivet artifact contract 的本地 skill。 |
| `plan-reviewer` | 建立符合 Rivet 獨立審查 contract 的本地 skill。 |
| `git-commit-convention` | 建立 staged diff 語意檢查、message 建議與 human-confirmed commit 規範 skill。 |
| `git-branch-naming` | 建立 branch 名稱規範 skill；只產生建議，不執行 Git。 |
| `worktree-manager` | 建立 worktree 狀態檢查與受限 lifecycle 指引 skill。 |

Git 範圍只涵蓋 branch、worktree 與 human-confirmed commit 規範；不涵蓋 release、post-merge、自動 commit 或 push。Observer/Dispatcher 只能讀取 Git 狀態與路由，不得自行執行 Git 操作。

## In-Scope

- 建立正式 topic 的三份同-slug planning artifacts。
- 建立 `sdd-workflow-contract`、`context-package-builder`、`subagent-dispatch-policy`、`handoff-routing-policy`、`plan-creator`、`plan-reviewer`、`git-branch-naming`、`worktree-manager`、`git-commit-convention`。
- 執行 skill validator 與獨立 skill review。

## Out-Of-Scope

- Application code、release 設定與 remote Git 操作。
- `agents/openai.yaml`、scripts、額外 workflow contract 文件。
- 自動建立、移動或推送 Git tag，以及自動 commit、push、開 PR。

## ReadOnly

- Repository 規範、設計原則、既有 lifecycle 與 planning 範例。
- 上游 skills 的指引與 `skill-creator` validator。
- Git status、branch、worktree、PR 與 tag 狀態，僅供 routing 與回溯基線確認。

## Written

- `analysis/agent-skill-implementation/requirements.md`
- `analysis/agent-skill-implementation/technical-spec.md`
- `plan/agent-skill-implementation/agent-skill-implementation.plan.md`
- `.codex/skills/sdd-workflow-contract/SKILL.md`
- `.codex/skills/sdd-workflow-contract/references/topic-artifacts.md`
- `.codex/skills/sdd-workflow-contract/references/routing-and-verdicts.md`
- `.codex/skills/context-package-builder/SKILL.md`
- `.codex/skills/subagent-dispatch-policy/SKILL.md`
- `.codex/skills/handoff-routing-policy/SKILL.md`
- `.codex/skills/plan-creator/SKILL.md`
- `.codex/skills/plan-reviewer/SKILL.md`
- `.codex/skills/git-branch-naming/SKILL.md`
- `.codex/skills/worktree-manager/SKILL.md`
- `.codex/skills/git-commit-convention/SKILL.md`

## Modify

無既有檔案修改。

## Deleted

無檔案刪除。

## Implementation Changes

1. Plan-Creator 建立本 topic 的 requirements、technical spec 與本計畫；Plan-Reviewer 獨立確認其一致性與鎖定決策後才交給 Implementer。
2. Implementer 建立九個 skills；每個 skill 只含必要的 `SKILL.md`，只有 `sdd-workflow-contract` 建立兩份共用 references。
3. `sdd-workflow-contract` 固定角色、phase、三份 topic artifacts、最小 handoff、四種 verdict 與 human boundary；禁止任意重開 locked scope、architecture、path 或 contract decision。
4. Dispatcher skills 限定既定角色、單一派遣與明示 verdict routing。Observer/Dispatcher 不得實作、改檔、審查、計算 gate、Git 操作、commit、push、開 PR 或跨越 human boundary。
5. Planning skills 分離建立與獨立審查責任。`plan-creator` 對缺少 artifacts 或未鎖定決策回傳 `blocked`；`plan-reviewer` 不代寫且最終只輸出既定 JSON。
6. Git skills 僅提供 branch naming、worktree lifecycle 與 staged-diff commit 建議。所有 Git 狀態變更只能由獲授權的非-Dispatcher 角色在 human confirmation 後執行。
7. Tester 逐一執行 `skill-creator` 的 `quick_validate.py`；Reviewer 以獨立 handoff 審查新增 skills，並只輸出既定 JSON。

## TestCase

- 既有 `v0.1.0-architecture-baseline` 可作為實作前回溯點；缺少新的 topic tag 不得阻擋實作、驗證、commit、push 或 draft PR 建立。
- 全部九個 skills 通過 `skill-creator` 的 `quick_validate.py`，沒有 frontmatter、命名或 scaffold placeholder 問題。
- handoff context 含最小欄位且不夾帶未驗證推論；Dispatcher 每次只派遣一個允許角色，並對四個標準 verdict 正確前進、回修或停止。
- `plan-creator` 在缺正式 artifact 或 scope／BC／path／locked decision 不明時回傳 `blocked`，不猜測補齊；`plan-reviewer` 對 workflow 或 contract drift 回傳 `needs-rework`，且只輸出指定 JSON。
- branch naming 不執行 Git；worktree skill 對 Dispatcher 僅允許唯讀狀態檢查；commit convention 不執行 commit 或 push，且要求 human confirmation。
- 獨立 Reviewer 確認新增 skills 沒有未授權 artifacts、Python workflow 假設、Git 自動化或 Dispatcher 越界。

## Assumptions

- 每個 skill 僅建立必要的 `SKILL.md`；共用 SDD contract 才使用兩份 references。
- `sdd-workflow-contract` 是 SDD 共用規則唯一真相；其他 planning、routing 與 Git skills 僅引用適用 contract，不複製不相容流程。
