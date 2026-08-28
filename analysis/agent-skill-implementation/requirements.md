# Agent Skill Implementation — Requirements

## Goal

在本 repository 建立一組最小、可維護、語言無關的本地 agent skills，使正式 topic 能以固定 artifacts、獨立規劃審查、可追溯 handoff 與受限 Git 工作方式運作。

## In Scope

- 建立下列本地 skills：`sdd-workflow-contract`、`context-package-builder`、`subagent-dispatch-policy`、`handoff-routing-policy`、`plan-creator`、`plan-reviewer`、`plan-step-tracker`、`git-branch-naming`、`worktree-manager`、`git-commit-convention`。
- 將正式 topic 的唯一 artifacts 固定為同 slug 的 `requirements.md`、`technical-spec.md`、`.plan.md` 與 `.step.md`，並將 artifact contract、roles 與標準 verdict 的唯一真相收斂至 `sdd-workflow-contract`。
- 將 `.step.md` 定義為執行狀態帳本，記錄步驟、owner role、完成條件、驗證證據、blocker、verdict 與 human-check；它不是 approval 的替代品。
- 定義 Planner、Plan-Creator、Plan-Reviewer、Implementer、Tester、Reviewer、Explorer、Observer/Dispatcher 的責任邊界、handoff 與標準 verdict。
- 提供 branch 命名、完整且可操作的 worktree lifecycle，以及 human-confirmed commit 的 Git workflow 指引；這三個 Git skills 只處理各自的 Git 責任，不讀取 SDD artifacts 或 routing 狀態。
- 將 `worktree-manager` 在地化為完整 lifecycle skill：結構化 frontmatter、`create`／`get-worktree`／`release worktree`／`remove worktree`、managed path、branch collision 的 human reuse-or-rename 決策、release/remove 分離，以及三份操作 references。
- 驗證全部 skills，並由獨立 Reviewer 審查其 workflow contract。

## Out Of Scope

- Application code、Bounded Context 實作、release 設定或產品功能。
- Python、Swift、TypeScript 的實作、TDD、測試框架或型別規範。
- 軟體 release、post-merge、自動 commit、push 與遠端 Git 操作。
- `agents/openai.yaml`、scripts、模板或額外的 workflow contract 文件。

## Success Criteria

- 十個 skills 可清楚區分規劃、實作、驗證、審查與 routing 責任，且不要求未授權 artifacts。
- Observer/Dispatcher 僅可讀取狀態與 `.step.md`、派遣、彙整與依明示 step 狀態及 verdict 路由；不實作、改檔、勾選 step、審查、計算 gate 或執行 Git 操作。
- Plan-Creator 必須建立或修正缺少的正式 artifacts；只有進入 Plan-Reviewer 時，四份 artifacts 缺少、scope／BC／path／locked decision 不明才停止並回報 `blocked`，不得自行推論。
- `plan-reviewer` 的最終輸出可被 Dispatcher 直接路由，且只使用既定 JSON 格式。
- `context-package-builder` 與 `handoff-routing-policy` 只能傳遞、讀取與路由既有的明示 verdict，不得自行產生、重寫或推導 verdict。
- `plan-step-tracker` 能發現缺少 owner role、驗證證據、blocker 或 human-check 的 `.step.md`，但只檢查結構與欄位完整性，不判斷內容真實性、不產生 verdict 或放行流程。
- `worktree-manager` 對 managed 與 unmanaged worktree 維持不同安全路徑：`get-worktree` 回傳固定欄位與 `prune-candidate` routing 而不 auto-prune；`remove worktree` 只在明確 human destructive approval 與所有安全檢查通過後才可由獲授權的非-Dispatcher 角色執行。
- `worktree-manager` 保留完整 validation、failure handling、red flags、common rationalizations、boundaries 與 planning／governance coordination warning；Observer/Dispatcher 僅可讀取 `get-worktree` 結果與 routing。
- 所有新增 skills 通過 skill validator，獨立審查沒有未處理 blocker。

## Recovery Baseline

既有 `v0.1.0-architecture-baseline` 足以作為本 topic 的實作前回溯點。tag 僅可在 draft PR 建立並交給 human review 後，作為非阻擋的 cleanup；Observer/Dispatcher 不得建立、移動或推送 tag。
