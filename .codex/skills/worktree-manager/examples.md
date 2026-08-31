# worktree-manager Examples

本檔展示 lifecycle 判斷；例中的結果不取代即時 Git inspection 或 human approval。

## 1. 建立受管理 worktree

需求：為 `agent-skill-implementation` 建立工作目錄。

正確處理：確認 repository、使用 managed path、確認 branch 不 collision，並取得 create 所需的直接授權後才建立。

```yaml
create_result:
  path: "../rivet.worktrees/agent-20260828-agent-skill-implementation"
  branch: "feat/andrew/agent-skill-implementation"
  next_step: "進入此 worktree 後繼續已授權工作"
notes:
  - "若其他 worktree 也會更新共享檔案，先協調寫入順序與 ownership。"
```

## 2. Create 時 branch collision

觀察：想使用的 branch 已 attach 到另一個存在的 worktree。

正確處理：回傳 `existing_result`，要求 human 選擇使用既有 worktree 或 `rename` 為新 branch。`release worktree` 不會 detach branch 或釋放 occupancy，不能用來讓同一 branch 加入第二個 worktree。不得 force reuse、不得在未決定時把已 attach branch 加入第二個 worktree。若 branch 存在但未 attach，才可由 human 選擇 `reuse` 或 `rename`。

若 `git worktree list` 顯示 branch 已 attach、但其 path 缺失，正確結果改為 `prune-candidate`：不得建議使用缺失 path、不得 auto-prune，也不得繼續 create；交由 human 決定是否另行處置 stale registration。

## 3. Managed worktree 可 release

觀察：managed path、乾淨、無 untracked、PR 已 merged。

```yaml
release_evidence:
  task_status: completed
  worktree_clean: true
  untracked_files: false
  branch_status: merged
  pr_status: merged
  push_status: pushed
  current_head_worktree: false
  user_intent: release
  destructive_action_allowed: false
  evidence_notes:
    - "工作已合併，可自 active working set 移出。"
recommendation: release
reason: "lineage 已完成，且沒有本地未保存狀態。"
next safe action: "標記為 released；若日後需要刪除，另行提出 remove worktree 與明確破壞性同意。"
```

release 不可執行或暗示 delete、detach branch 或釋放 branch occupancy。

若 completed worktree 有 `push_status: unpushed`，或 `current_head_worktree: true|unknown`，正確結果是 `needs-human-decision`，不得建議 release。

## 4. Paused 或 abandoned worktree 可 release

觀察：managed path、乾淨、無 untracked；工作暫停或已放棄，但其 lineage 已保存，且沒有進行中的 mutation。human 已直接要求本次非破壞性 release。

正確處理：記錄 `task_status: paused` 或 `abandoned`、`lineage_preserved: true`、`active_mutation: none`、`release_authorization: explicit` 與 `user_intent: release`，再建議 `release`。不得把此路徑套用到 completed worktree 以避開 unpushed 或 current-HEAD gate。

## 5. Dirty 或 untracked worktree

需求：release 此 worktree。

觀察：有 tracked edits 或 untracked files。

正確結果：`needs-human-decision`；建議先 review、commit、shelve 或明確放棄剩餘 state。不得因 task 看似結束而 release 或 remove。

## 6. Unmanaged path

需求：清理一個不符合 managed path policy 的 worktree。

正確處理：分類為 unmanaged，僅做 inspection，輸出固定七欄，並指出 ownership 不可假設。即使 human 要求 destructive cleanup，本 skill 仍停在 inspect-only，將後續處理交給人類另行決定。

```yaml
path: "<unmanaged-path>"
branch: "unknown"
status: "unmanaged"
dirty state: "unknown"
recommendation: "needs-human-decision"
reason: "path 不屬於 managed family，沒有自動管理權。"
next safe action: "請 human 確認 ownership 並在最新 safety checks 後決定後續動作。"
```

## 7. Stale registration

觀察：`git worktree list` 仍列出 path，但該 path 不存在。

正確結果：`recommendation: prune-candidate`，並說明需要 human 決定是否用獨立操作處理 stale registration。`get-worktree` 不得 auto-prune。

## 8. 明確 remove

需求：human 在當前 request 明確授權 destructive remove。

正確處理：先再次取得唯一 selector 與最新 state；只要有 dirty、untracked、unpushed、detached、locked、unmanaged 或 unknown 任一狀態，就回傳 `needs-human-decision`。全部 safety gate 通過且已有當前明確 destructive approval 時，才可執行 remove。

先前的 release request 不是 delete 同意。

## 9. 非 repository 位置

需求：在目前位置 create worktree。

觀察：目錄無法驗證為目標 Git repository。

正確結果：`BLOCKED`，要求切換到正確 repository；不得產生任何 worktree mutation。
