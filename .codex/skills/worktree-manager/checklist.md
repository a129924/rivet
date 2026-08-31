# worktree-manager Checklist

此檢查表用於重複執行 safety checks；勾選結果只是 inspection evidence，不能自行授權任何 mutation。

## Pre-create

- [ ] 目前位置已驗證為目標 Git repository 或其 child。
- [ ] 操作明確是 `create`。
- [ ] path 符合 `../<repo-name>.worktrees/<prefix>-YYYYMMDD-<worktree-name>` 且位於 repository root 外。
- [ ] 已知 branch 名稱；collision 時 human 已明確選擇 reuse 或 rename。
- [ ] target path 不是不相關目錄或衝突 worktree。
- [ ] 已提出共享檔案的 coordination warning（適用時）。
- [ ] 輸出將包含 path、branch 與 next_step。

## Pre-release

- [ ] 操作明確是 `release worktree`，不是 remove。
- [ ] selector 唯一解析；path 為 managed，或已明示 unmanaged 預設 inspect-only。
- [ ] `release_evidence.task_status` 已填寫。
- [ ] `worktree_clean: true` 且 `untracked_files: false`。
- [ ] branch、PR、push status 已填寫或明示 `unknown`。
- [ ] lineage 已 merged，或 human 明示 abandoned／不需 merge。
- [ ] `user_intent: release`，且 `destructive_action_allowed: false`。
- [ ] 結果明說 release 不代表 deletion。

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
