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

建立前還必須檢查 branch occupancy。已存在但未 attach 的 branch，必須由 human 明確選擇 `reuse` 或 `rename`；已 attach 到存在的其他 worktree 的 branch 則回傳 `existing_result`，並要求 human 選擇使用既有 worktree 或改用新 branch。若 Git registration 顯示 branch 已 attach、但該 path 缺失，該 registration 是 `prune-candidate`：不得把它當成可使用 worktree、不得 auto-prune，也不得在未經 human 處置前繼續 create。`release worktree` 是非破壞性 offboarding，不會 detach branch 或改變 Git 的 occupancy；它不能使已 attach branch 可被重用。已 attach branch 不可 force reuse，也不可加入第二個 worktree。

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
| clean、無 untracked、無 unpushed、非 current HEAD worktree，且 lineage 已 merged 或明示不需 merge 的 completed task | `release` | 可離開 active set，仍不代表可刪除。 |
| clean、無 untracked、lineage 已保存、無 active mutation，且有直接 release 授權的 paused 或 abandoned task | `release` | 可非破壞性離開 active set，仍不代表可刪除。 |
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
  current_head_worktree: true | false | unknown
  lineage_preserved: true | false | unknown
  active_mutation: none | in_progress | unknown
  release_authorization: explicit | absent | unknown
  user_intent: release | remove | keep | unknown
  destructive_action_allowed: true | false
  evidence_notes:
    - "<short note>"
```

completed 的最小 release gate 是 `worktree_clean: true`、`untracked_files: false`、`push_status: pushed|no_remote`、`current_head_worktree: false`，且 `branch_status: merged` 或 `pr_status: merged`；若未合併，必須有 human 明示不需 merge。`push_status: unpushed` 或 `current_head_worktree: true|unknown` 一律停止並回傳 `needs-human-decision`。

paused 或 abandoned 的最小 release gate 是 `worktree_clean: true`、`untracked_files: false`、`lineage_preserved: true`、`active_mutation: none`、`release_authorization: explicit` 與 `user_intent: release`。這不是 completed 的替代路徑：呼叫者必須如實標示 task status，不得為避開 completed gate 改寫狀態。兩條合法 release 路徑預設 `destructive_action_allowed: false`，且都不刪除 worktree 或 branch。

release 也不移除 Git worktree registration 或 detach branch。因此 release 後該 branch 仍 attach，不能作為 create branch collision 的前置處理。

## Safety handling

- 非預期 repository：`BLOCKED`。
- create branch 已 attach 且 path 存在：回傳 existing worktree，停在 human `use-existing-or-new-branch`；不可 force reuse。若已 attach 的 registration path 缺失，回傳 `prune-candidate` 並停止，不可使用該 worktree、auto-prune 或繼續 create。未 attach 的既有 branch 才停在 human `reuse-or-rename`。
- dirty、untracked、unpushed、detached、locked、unknown：`needs-human-decision`。
- 共享檔案：先提出 coordination warning，要求相關協作者確認寫入順序與 ownership。
- stale registration：`prune-candidate`，不可 auto-prune。
