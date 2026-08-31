# worktree-manager Reference

僅在需要決定 lifecycle 或解讀 inspection 結果時讀取本檔；它補充主 skill，並不另行授權 Git 操作。

## Lifecycle 術語

- `create`：在 canonical managed path 建立 worktree 與預期 branch lineage。
- `get-worktree`：檢查 state 並輸出結構化 recommendation。
- `release worktree`：非破壞性地離開 active working set。
- `remove worktree`：對 managed worktree，在取得明確 human destructive approval 且通過完整 safety checks 後，移除 worktree directory 與 Git registration。

`release worktree` 與 `remove worktree` 是不同操作，不得合併或互相推論。

## Selector 與 managed path

selector 必須可唯一解析，優先順序如下：

1. 明確 path
2. 明確 branch name
3. 可唯一對應的 worktree name

多個候選、無候選或無法驗證時，不作 mutation。受管理狀態只由 path policy 決定：

`../<repo-name>.worktrees/<prefix>-YYYYMMDD-<worktree-name>`

- path 必須位於 repository root 外。
- 預設 `<prefix>` 是 `agent`；human 可明確覆寫。
- 其他文件只可提供 context，不能覆寫此 path classification。
- 不符合 path policy 就是 unmanaged，預設只可 inspect。

建立前還必須檢查 branch occupancy。已存在但未 attach 的 branch，必須由 human 明確選擇 `reuse` 或 `rename`；已 attach 到其他 worktree 的 branch 則回傳 `existing_result`，並要求 human 選擇先處理 release 或改用新 branch。release 後仍要重新檢查 occupancy；已 attach branch 不可 force reuse，也不可加入第二個 worktree。

## `get-worktree` 結果 contract

每個被回報的 worktree 都輸出以下固定欄位：

```yaml
path: "<path>"
branch: "<branch-name|detached|unknown>"
status: "<簡短狀態>"
dirty state: "clean|dirty|untracked|dirty+untracked|unknown"
recommendation: "keep|release|remove|needs-human-decision|prune-candidate"
reason: "<推薦理由>"
next safe action: "<具體且非破壞性的下一步>"
```

`status` 不可取代 `reason`。若 Git 仍註冊 worktree 而其 path 已不存在，唯一適用的 recommendation 是 `prune-candidate`；這只是交給 human 的處置建議，不是 prune 命令或自動清理授權。

## 推薦矩陣

| 觀察條件 | Recommendation | 理由與限制 |
| --- | --- | --- |
| clean、branch 仍在使用、task 未結束 | `keep` | active workspace 仍有用途。 |
| clean、task 完成、merged 或明示 abandoned | `release` | 可離開 active set，仍不代表可刪除。 |
| clean、已 release／不再需要，且 remove approval 另行通過 | `remove` | 僅提示可進入破壞性路徑。 |
| dirty、untracked、unpushed、detached、locked 或 unknown | `needs-human-decision` | local state、lineage 或 ownership 仍可能重要。 |
| unmanaged | `needs-human-decision` | 不可假設 lifecycle ownership。 |
| missing path 但 Git registered | `prune-candidate` | registration 可能 stale；不得 auto-prune。 |

## Release evidence schema

在建議 `release worktree` 前，記錄完整欄位：

```yaml
release_evidence:
  task_status: completed | paused | abandoned | unknown
  worktree_clean: true | false | unknown
  untracked_files: true | false | unknown
  branch_status: merged | unmerged | no_branch | unknown
  pr_status: merged | closed | open | none | unknown
  push_status: pushed | unpushed | no_remote | unknown
  lineage_preserved: true | false | unknown
  active_mutation: none | in_progress | unknown
  release_authorization: explicit | absent | unknown
  user_intent: release | remove | keep | unknown
  destructive_action_allowed: true | false
  evidence_notes:
    - "<short note>"
```

完成中的最小 release gate 是 `worktree_clean: true`、`untracked_files: false`，且 `branch_status: merged` 或 `pr_status: merged`；除非 human 明示 abandoned 或不需 merge。暫停中的最小 release gate 是 `worktree_clean: true`、`untracked_files: false`、`lineage_preserved: true`、`active_mutation: none`、`release_authorization: explicit` 與 `user_intent: release`。兩條路徑的 release 預設 `destructive_action_allowed: false`，且都不刪除 worktree 或 branch。

## Safety handling

- 非預期 repository：`BLOCKED`。
- create branch 已 attach：回傳 existing worktree，停在 human `release-or-rename`；不可 force reuse。未 attach 的既有 branch 才停在 human `reuse-or-rename`。
- dirty、untracked、unpushed、detached、locked、unknown：`needs-human-decision`。
- 共享檔案：先提出 coordination warning，要求相關協作者確認寫入順序與 ownership。
- stale registration：`prune-candidate`，不可 auto-prune。
