# worktree-manager Checklist

此檢查表用於重複執行 safety checks；勾選結果只是 inspection evidence，不能自行授權任何 mutation。

## Pre-create

- [ ] 目前位置已驗證為目標 Git repository 或其 child。
- [ ] 操作明確是 `create`。
- [ ] path 符合 `../<repo-name>.worktrees/<prefix>-YYYYMMDD-<worktree-name>` 且位於 repository root 外。
- [ ] 已檢查 branch occupancy；若 branch 已 attach 到其他 worktree，已回傳 existing worktree 並取得 human 使用既有 worktree 或指定新 branch 的決策，且不會 force reuse。
- [ ] 若 branch 已存在但未 attach，human 已明確選擇 reuse 或 rename。
- [ ] target path 不是不相關目錄或衝突 worktree。
- [ ] 已提出共享檔案的 coordination warning（適用時）。
- [ ] 輸出將包含 path、branch 與 next_step。

## Pre-release

- [ ] 操作明確是 `release worktree`，不是 remove。
- [ ] selector 唯一解析；path 為 managed，或已明示 unmanaged 預設 inspect-only。
- [ ] `release_evidence.task_status` 已填寫。
- [ ] `worktree_clean: true` 且 `untracked_files: false`。
- [ ] branch、PR、push status 已填寫或明示 `unknown`。
- [ ] 若 `task_status: completed`，lineage 已 merged，或 human 明示 abandoned／不需 merge。
- [ ] 若 `task_status: paused`，`lineage_preserved: true`、`active_mutation: none`，且有本次 release 的直接 human 授權。
- [ ] `user_intent: release`，且 `destructive_action_allowed: false`。
- [ ] 結果明說 release 不代表 deletion。
- [ ] 結果明說 release 不會 detach branch 或釋放 branch occupancy。

## Pre-remove

- [ ] 操作明確是 `remove worktree`。
- [ ] 當前 request 或重述確認中有明確 human destructive approval。
- [ ] selector 唯一，且目標為 managed worktree，最新 inspection 為 clean、無 untracked、無 unpushed。
- [ ] 沒有 detached、locked 或 unknown state。
- [ ] 沒有把較早的 release 當作隱含 remove 同意。
- [ ] unmanaged path 未進入 remove；仍維持 inspect-only，並交還 human 處理。

## Unmanaged 與不明狀態

- [ ] managed classification 先依 canonical path policy 判斷。
- [ ] unmanaged 預設只 inspection；沒有隱含 release、remove、delete、prune、rename 或 branch deletion。
- [ ] 「cleanup」等不明需求已要求 human 指定 release 或 remove。
- [ ] repo 驗證失敗時回傳 `BLOCKED` 且不 mutation。
- [ ] dirty、untracked、unpushed、detached、locked、unmanaged 或 unknown route 到 `needs-human-decision`。
- [ ] missing-path-but-registered route 到 `prune-candidate`；沒有 auto-prune。
- [ ] 每筆 `get-worktree` 結果都有 path、branch、status、dirty state、recommendation、reason、next safe action。
