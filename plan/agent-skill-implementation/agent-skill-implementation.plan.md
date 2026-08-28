# agent-skill-implementation

## Goal

建立完整的本地 SDD、Dispatcher handoff／routing 與受限 Git workflow skills；既有 architecture baseline tag 提供 implementation 前回溯點。

## Git Recovery Baseline

- 既有 `v0.1.0-architecture-baseline` 足以作為本 topic 的實作前回溯點。
- draft PR 建立並交給 human review 後，才可考慮 tag cleanup；該 cleanup 非阻擋，且不得影響實作、驗證、commit、push 或 draft PR 建立。
- Observer/Dispatcher 不得建立、移動或推送 tag。

## Non-Goal

不加入 Python、Swift、TypeScript 實作細節、軟體 release、VERSION、summary 或 correction workflow；不變更 application code；不自動 commit、push 或操作 tag。

## Agent-skills Adoption Baseline

| Upstream skill | 本次本地化處理 |
| --- | --- |
| `context-package-builder` | 建立最小、可追溯的 subAgent handoff context skill；只傳遞上游明示 verdict。 |
| `subagent-dispatch-policy` | 建立限定角色、單一派遣與停止條件的 Dispatcher policy skill；只讀取既有狀態。 |
| `handoff-routing-policy` | 建立依既有明示 verdict 路由或停止的 policy skill；不產生或改寫 verdict。 |
| `plan-creator` | 建立符合 Rivet artifact contract 的本地 skill。 |
| `plan-reviewer` | 建立符合 Rivet 獨立審查 contract 的本地 skill。 |
| `git-commit-convention` | 建立只依 staged diff 與適用 commit conventions 的語意檢查、message 建議與 human-confirmed commit 規範 skill。 |
| `git-branch-naming` | 建立只產生 branch 名稱建議的 skill；不讀 SDD artifacts 或 routing，不執行 Git。 |
| `worktree-manager` | 建立完整、可操作且安全的 worktree lifecycle skill；不讀 SDD artifacts 或 routing，以繁體中文在地化上游 safety contract 與三份 references。 |

Git 範圍只涵蓋 branch、worktree 與 human-confirmed commit 規範；不涵蓋軟體 release、post-merge、自動 commit 或 push。Observer/Dispatcher 只能讀取 Git 狀態與路由，不得自行執行 Git 操作。

## In-Scope

- 建立或更新正式 topic 的四份同-slug planning artifacts。
- 建立或更新 `sdd-workflow-contract`、`context-package-builder`、`subagent-dispatch-policy`、`handoff-routing-policy`、`plan-creator`、`plan-reviewer`、`git-branch-naming`、`worktree-manager`、`git-commit-convention`，並新增 `plan-step-tracker`。
- 執行 skill validator 與獨立 skill review。

## Out-Of-Scope

- Application code、軟體 release 設定與 remote Git 操作。
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
- `plan/agent-skill-implementation/agent-skill-implementation.step.md`
- `.codex/skills/sdd-workflow-contract/SKILL.md`
- `.codex/skills/sdd-workflow-contract/references/topic-artifacts.md`
- `.codex/skills/sdd-workflow-contract/references/routing-and-verdicts.md`
- `.codex/skills/context-package-builder/SKILL.md`
- `.codex/skills/subagent-dispatch-policy/SKILL.md`
- `.codex/skills/handoff-routing-policy/SKILL.md`
- `.codex/skills/plan-creator/SKILL.md`
- `.codex/skills/plan-reviewer/SKILL.md`
- `.codex/skills/plan-step-tracker/SKILL.md`
- `.codex/skills/git-branch-naming/SKILL.md`
- `.codex/skills/worktree-manager/SKILL.md`
- `.codex/skills/worktree-manager/reference.md`
- `.codex/skills/worktree-manager/examples.md`
- `.codex/skills/worktree-manager/checklist.md`
- `.codex/skills/git-commit-convention/SKILL.md`

## Modify

- `AGENTS.md`：將正式 topic artifacts 由三份更新為四份，新增 `plan/<topic>/<topic>.step.md`。
- 九個既有本地 skills：更新 artifact contract、handoff、routing 與 planning review 邊界；`worktree-manager` 擴充為完整 lifecycle skill 與三份 references，其餘 Git skills 維持既有限制。

## Deleted

無檔案刪除。

## Implementation Changes

1. Plan-Creator 建立或更新本 topic 的 requirements、technical spec、topic plan 與初始 step ledger；Plan-Reviewer 獨立確認四份 artifacts 的一致性與鎖定決策後才交給 Implementer。
2. Implementer 更新九個既有 skills 並新增 `plan-step-tracker`，共十個 skills；每個 skill 只含必要的 `SKILL.md`，只有 `sdd-workflow-contract` 建立兩份共用 references。
3. `sdd-workflow-contract` 固定角色、phase、四份 topic artifacts、最小 handoff、四種 verdict 與 human boundary；`.step.md` 是執行狀態帳本，記錄 step、owner role、完成條件、驗證證據、blocker、verdict 與 human-check。禁止任意重開 locked scope、architecture、path 或 contract decision。
4. Dispatcher skills 限定既定角色、單一派遣與明示 step 狀態／verdict routing。context builder 只能傳遞上游明示 verdict；routing policy 只能依此路由，不得自行產生、改寫或推導 verdict。Observer/Dispatcher 不得實作、改檔、勾選或修改 `.step.md`、審查、把 checkbox 當 approval、計算 gate、Git 操作、commit、push、開 PR 或跨越 human boundary。
5. Planning skills 分離建立與獨立審查責任。`plan-creator` 建立或修正四份 artifacts，不因初始缺少 artifact 而阻擋自己；`plan-reviewer` 開始審查時要求四份 artifacts 齊全，不代寫，檢查 step 可追溯性與 human boundary，且最終只輸出既定 JSON。
6. `plan-step-tracker` 僅檢查 `.step.md` 是否具備 Topic／phase、每個 step 的 ID、status、owner role、完成條件與驗證證據，以及 Blockers、Human Check、最後更新資訊；不得判斷內容真實性、自行完成 step、產生 verdict、取代 Tester／Reviewer 或讓 Dispatcher 自動放行。
7. `worktree-manager` 以完整在地化骨架處理 `create`、`get-worktree`、`release worktree`、`remove worktree`：frontmatter、managed path、branch collision human reuse-or-rename、固定 inspect output、release evidence、unmanaged inspect-only、`prune-candidate` no-auto-prune、remove human destructive approval 與所有安全 stop states。主 skill 連結 `reference.md`、`examples.md`、`checklist.md`，並包含 validation、failure handling、red flags、common rationalizations、boundaries 與 planning／governance coordination warning。
8. Rivet 僅在角色層限制 worktree lifecycle：Observer/Dispatcher 只能讀取 `get-worktree` 結果與 routing，不得執行 Git 或 worktree mutation；已獲授權的非-Dispatcher 角色可在 lifecycle contract 和 human boundary 內執行 create、release 或 remove。Git skills 不讀取 SDD artifacts、step ledger 或 routing：branch naming 只建議名稱，worktree manager 只依 lifecycle contract，commit convention 只看 staged diff 與適用 commit conventions。Git skills 不納入軟體 release management、post-merge、自動 commit、push 或 tag lifecycle。
9. Tester 逐一執行 `skill-creator` 的 `quick_validate.py`；Reviewer 以獨立 handoff 審查十個 skills、四份 artifact contract、Dispatcher 與 Git 邊界，並只輸出既定 JSON。

## TestCase

- 既有 `v0.1.0-architecture-baseline` 可作為實作前回溯點；缺少新的 topic tag 不得阻擋實作、驗證、commit、push 或 draft PR 建立。
- 全部十個 skills 通過 `skill-creator` 的 `quick_validate.py`，沒有 frontmatter、命名或 scaffold placeholder 問題。
- handoff context 含四份 artifact paths、目前 step/status 與其他最小欄位，且不夾帶未驗證推論；Dispatcher 每次只派遣一個允許角色，並對四個標準 verdict 正確前進、回修或停止。
- `plan-step-tracker` 對缺少 owner role、驗證證據、blocker 或 human-check 的 `.step.md` 回報不完整，但不產生 verdict 或 approval。
- `plan-creator` 可建立或修正缺少的正式 artifact，遇 scope／BC／path／locked decision 不明時回傳 `blocked`，不猜測補齊；`plan-reviewer` 開始審查時若缺任何一份正式 artifact、四份 artifact 不一致、workflow／contract drift 或將 checkbox 視為 approval，回傳 `needs-rework` 或 `blocked`，且只輸出指定 JSON。
- branch naming 不執行 Git；worktree skill 對 Dispatcher 僅允許唯讀狀態檢查；commit convention 不執行 commit 或 push，且要求 human confirmation。
- `worktree-manager` 的 frontmatter 含 inputs、outputs、use_when、do_not_use_when、risk profile，且 `SKILL.md` 對三份 references 的連結均存在。
- `get-worktree` 對每個工作目錄提供固定七欄；stale registration 只回傳 `prune-candidate`，不得 auto-prune；branch collision 必須要求 human reuse-or-rename。
- `release worktree` 與 `remove worktree` 維持語意分離；remove 在 dirty、untracked、unpushed、detached、locked、unmanaged 或不明狀態時停止，並要求當前明確 human destructive approval。
- 獨立 Reviewer 確認新增 skills 沒有未授權 artifacts、Python workflow 假設、Git 自動化、Dispatcher 修改 `.step.md`、自行計算 gate 或跨越 human boundary。

## Assumptions

- `sdd-workflow-contract` 維護兩份共用 references：`topic-artifacts.md` 與 `routing-and-verdicts.md`；`worktree-manager` 另維護 `reference.md`、`examples.md` 與 `checklist.md`。
- 其餘 skills 僅建立必要的 `SKILL.md`。
- `sdd-workflow-contract` 是 SDD 共用規則唯一真相；其他 planning、routing 與 Git skills 僅引用適用 contract，不複製不相容流程。
