---
name: worktree-manager
description: 安全管理 Git worktree 的 create、get-worktree、release worktree 與 remove worktree lifecycle；適用於 worktree 選擇、建立、釋放或移除，不用於功能實作。
metadata:
  complexity: high
  risk_profile:
    - ambiguity_sensitive
    - destructive_action
    - external_tooling
  inputs:
    - "操作：create、get-worktree、release worktree 或 remove worktree"
    - "目標 repository context 與 worktree selector（適用時）"
    - "create 所需的 branch 或 worktree name"
    - "branch collision 的 human reuse-or-rename 決策，或已 attach branch 的使用既有 worktree 或改用新 branch 決策（適用時）"
    - "暫停中 release 所需的當前直接 human 授權（適用時）"
    - "remove 所需的當前明確 human destructive approval"
  outputs:
    - create_result
    - get_worktree_result
    - release_evidence
    - lifecycle_recommendation
  use_when:
    - "需要安全建立、查詢、釋放或移除本 repository 的 worktree"
    - "需要在 lifecycle 決策前取得結構化 worktree 狀態"
    - "需要依 managed path policy 區分受管理與未受管理的 worktree"
  do_not_use_when:
    - "已選定 worktree 內的功能實作"
    - "merge、push、branch deletion、release tag 或環境設定"
    - "將 release worktree 視為刪除的要求"
    - "要求在 repository root 內放置 managed worktree"
---

# Worktree Lifecycle 管理

管理 Git worktree 的完整 lifecycle，避免把檢查、釋放與破壞性移除混為一談。此 skill 不授權額外 Git 動作；每次 mutation 都必須取得與該操作直接相關的授權。

## 操作路由

1. 先確認目前位置屬於目標 Git repository；無法確認時回傳 `BLOCKED`，不作 mutation。
2. 將需求精確辨識為 `create`、`get-worktree`、`release worktree` 或 `remove worktree`。若「清理」等用語無法判定是 release 或 remove，停下要求 human 明確選擇。
3. 以 path policy 判斷 managed／unmanaged，並解析 selector。selector 無法唯一對應時，僅檢查或請求釐清。
4. 若多個 worktree 可能共同修改共享檔案，先提出 coordination warning；不可假設它們互不影響。

### `create`

- managed path 必須是 repository root 外的 `../<repo-name>.worktrees/<prefix>-YYYYMMDD-<worktree-name>`；預設 prefix 為 `agent`，只有 human 可以指定覆寫。
- 目標 path 已存在但不是預期 worktree 時，停止交 human 決定。
- 建立前必須檢查 branch occupancy。若同名 branch 已 attach 到其他 worktree，回傳 `existing_result`，要求 human 選擇使用既有 worktree 或指定新 branch。`release worktree` 不會 detach branch 或改變 Git 的 occupancy，因此不是此 collision 的解法。不得 force reuse、不得把已 attach branch 加入第二個 worktree。
- 若同名 branch 存在但未 attach 到任何 worktree，才可取得明確 human `reuse` 或 `rename` 決策；不得默默重用既有 lineage。
- path、branch 與直接相關授權都明確後，才可建立 branch 和 worktree。
- 回傳：

```yaml
create_result:
  path: "../<repo-name>.worktrees/<prefix>-YYYYMMDD-<worktree-name>"
  branch: "<branch-name>"
  next_step: "進入此 worktree 後繼續已授權工作"
```

若 branch 已 attach，則不建立並回傳：

```yaml
existing_result:
  status: existing
  path: "<attached worktree path>"
  branch: "<branch-name>"
  next_safe_action: "請 human 選擇使用既有 worktree，或指定新 branch；已 attach branch 維持 occupancy"
```

### `get-worktree`

- 對指定 target 或已知相關 worktrees 做唯讀 inspection。
- 每一筆結果都必須有 `path`、`branch`、`status`、`dirty state`、`recommendation`、`reason`、`next safe action`。
- dirty、untracked、unpushed、detached、locked、unmanaged 或 unknown 一律路由為 `needs-human-decision`。
- Git 註冊存在但 path 缺失時僅標記 `prune-candidate`；不得 auto-prune。

### `release worktree`

- release 是把已完成或暫停的 managed worktree 移出 active working set 的非破壞性 offboarding；絕不等同刪除。
- release 不執行 `git worktree remove`、不 detach branch，也不改變 Git 的 branch occupancy；若要在另一個 worktree 使用該 branch，必須改用既有 worktree 或由 human 指定新 branch。
- 先完成 [release evidence schema](reference.md#release-evidence-schema)，並預設 `destructive_action_allowed: false`。
- 完成中的 release 必須是 clean、無 untracked，且 lineage 已 merged 或 human 明示 abandoned／不需 merge。
- 暫停中的 release 也可進入安全 gate：必須是 clean、無 untracked、lineage 已保存、沒有進行中的 mutation，並取得本次 release 的直接 human 授權。此路徑只做非破壞性 offboarding，不刪除 worktree 或 branch。
- 缺證據、unmanaged 或任何不安全狀態時，停在 `needs-human-decision`。

### `remove worktree`

- 這是破壞性操作；必須在當前 request 或重述確認中取得明確 human destructive approval。
- 執行前重新檢查：target 唯一、clean、無 untracked、無 unpushed、非 detached、未 locked、branch 狀態可確認。
- dirty、untracked、unpushed、detached、locked、unmanaged 或 unknown 的任何一項都停止並回傳 `needs-human-decision`；不得 force removal。
- 先前的 release 絕不構成 remove 的隱含同意。unmanaged path 一律維持 inspect-only；本 skill 不對它執行 remove。

## Validation

- 操作前後依 [checklist](checklist.md) 驗證。
- `create` 後確認 path 存在、branch attach 正確，且 `next_step` 指向該 worktree。
- `get-worktree` 後確認每一筆都有完整固定欄位，而非只回報一個摘要 status。
- release 或 remove 前必須用最新 inspection 重跑相應 evidence 與 safety gate；歷史結果不可當成目前狀態。

## Failure handling

### 缺少 context

缺 selector、branch、release evidence 或 destructive approval 時，標記 `INCOMPLETE`、列出缺項並停止 mutation；不得猜測 branch lineage、task 完成狀態或破壞性意圖。

### 需求含糊

若含糊之處會改變 `create`、`release worktree` 或 `remove worktree` 的選擇，回傳 `BLOCKED` 並要求 human 釐清。純唯讀的不確定性可提供 inspection-only guidance，但必須明示假設與未確認項目。

### 執行限制

Git command、selector 或 state 無法驗證時，明示限制且不捏造狀態或 evidence；改採最安全的 inspection-only guidance。詳情見 [reference.md](reference.md)，正反例見 [examples.md](examples.md)。

## Red flags

- 「cleanup」未指明 release 或 remove。
- branch occupancy 未檢查，或把 release 誤當成已 attach branch 的 occupancy 解法。
- 目標 path 不在 managed family，卻假定由此 skill 擁有。
- Git 註冊仍存在但 path 缺失。
- 多個 active worktrees 可能編輯相同共享檔案。

## Common rationalizations

- 「release 跟 remove 差不多。」
- 「branch 已存在，直接重用就好。」
- 「unmanaged 看起來很像 managed。」
- 「stale registration 可以在 inspection 時順手 prune。」

以上理由都不足以跨過既定 gate。

## Boundaries

- 不執行 feature implementation、merge、push、branch deletion、PR 管理、軟體 release、post-merge、auto commit、tag lifecycle 或 auto-prune。
- 不在 repository root 內建立 managed worktree。
- 不把 release worktree 轉譯成 remove worktree。
- 不假設 unmanaged worktree 可 release、remove、改名、刪除或已完成。
- 不在 branch collision 時略過 human 決策；已 attach branch 一律不可 force reuse。

## Local references

- [reference.md](reference.md)：術語、selector、managed path、結果欄位、推薦矩陣與 release evidence。
- [examples.md](examples.md)：四種 lifecycle 的正反例與失敗情境。
- [checklist.md](checklist.md)：create、release、remove、unmanaged 與不明狀態的可重複 safety checks。
