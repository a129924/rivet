# Agent Skill Implementation — Technical Spec

## Design Rule

個別 Agent Skill 是可組合的工具，不是 workflow controller。每個 skill 只接收完成自身工作所需的資料，並只產出其宣告的結果。是否採用 SDD、何時派遣 skill、如何串接結果，屬於 caller 或 Observer/Dispatcher 的工作；它不是一般 skill 的隱含前提。

唯一例外是 `sdd-workflow-contract`：它保留既有 SDD artifacts、phase、role、verdict 與 human-boundary contract，且不應被非 SDD skills 強制載入或複製。

## Universal Handoff Contract

非 SDD skills 的 caller 只交付本次操作必要內容：

```json
{
  "task": "明確工作",
  "inputs": {},
  "expected_output": "預期格式或結果",
  "constraints": [],
  "stop_conditions": [],
  "authorization": "直接相關的操作授權"
}
```

- 欄位只在該 skill 實際需要時提供；skill 不得要求或補造未提供的 workflow、SDD、role、artifact、phase、verdict 或 approval 資訊。
- skill 在輸入不足、直接授權不足或自身停止條件成立時，只回報其局部限制；不得推導 workflow verdict、approval、gate 或下一個角色。
- result 的後續 routing 是 caller 或 Dispatcher 的責任。`handoff-routing-policy` 可依 caller 提供的明示 result 和 routing map 路由，但不解讀其業務或 workflow 意義。

## Remediation Batches

### Batch A — Context、Dispatch 與 Routing

| Skill | 最小責任與輸入 | 最小修正 |
| --- | --- | --- |
| `context-package-builder` | 將 caller 已提供的 task、必要 inputs、expected output、constraints、stop conditions、authorization 整理成可交接 package。 | 移除 SDD artifacts、phase、roles 與 verdict 必填欄位；不發明或轉寫結果。 |
| `subagent-dispatch-policy` | 依明確任務、候選 specialist 與直接限制，選擇單一適當 specialist 或停止。 | 移除 SDD role taxonomy、artifact readiness、phase 與 Git lifecycle 判斷。 |
| `handoff-routing-policy` | 依 caller 提供的明示 result 與 routing map 提出下一個目的地或停止。 | 移除固定 SDD verdict、step、phase、roles 與 artifact 要求；不產生 result。 |

### Batch B — Planning 與 Ledger

| Skill | 最小責任與輸入 | 最小修正 |
| --- | --- | --- |
| `plan-creator` | 依 caller 提供 planning contract、輸出位置與已鎖定決策建立或修正 planning documents。 | 移除固定四 artifact、SDD role、verdict 與 Git boundary 假設；輸入不足時只說明缺少的 contract。 |
| `plan-reviewer` | 依 caller 提供 contract、documents、criteria 與要求格式進行獨立審查。 | 移除固定 SDD JSON、phase、role 與 topic artifact 假設；不代寫、不判 workflow。 |
| `plan-step-tracker` | 依 caller 提供 ledger schema 檢查欄位與狀態完整性。 | 移除 topic、phase、SDD role／verdict 假設；不驗證 evidence 真實性、不完成 step、不批准或路由。 |

### Batch C — Git 與 Worktree

| Skill | 最小責任與輸入 | 最小修正 |
| --- | --- | --- |
| `git-branch-naming` | 使用 caller 提供的命名輸入產生 branch-name 建議。 | 移除 SDD 否定語與任何 topic／routing 參照；既有 owner 慣例不明時，僅以已提供的 type 與 work item 回傳 `<type>/<work-item>` fallback。 |
| `git-commit-convention` | 檢查 staged diff 與適用 commit convention，建議單一語意邊界與 message，等待 human confirmation。 | 移除 SDD、topic artifact、`.step.md`、approval gate 與 Dispatcher 參照。 |
| `worktree-manager` | 依自身 lifecycle contract 管理 create、get-worktree、release worktree、remove worktree。 | 將 Dispatcher／routing／planning-governance 特化改為一般 caller authorization；保留 shared files coordination warning，但不讀取 workflow 狀態。已 attach branch 保持 occupancy，create 僅回傳既有 worktree 或要求人類指定新 branch；非破壞性 release 不得被描述為可釋放 branch occupancy。 |

`worktree-manager` 必須維持既有的 managed path policy、branch collision 的 human reuse-or-rename decision、release/remove 分離、remove 的 destructive approval 與 dirty/untracked/unpushed/detached/locked/unmanaged/unknown stop states、固定 get-worktree result 與 `prune-candidate` no-auto-prune。

### Batch D — Tooling Bootstrap Assumptions

| Skill | 最小責任與輸入 | 最小修正 |
| --- | --- | --- |
| `build-run-debug` | 使用 caller 指定或 repository 既有入口 build、run 或 diagnose。 | 不再強制 `git init` 或 bootstrap；僅在 caller 要求建立入口時進行。relaunch 前解析目標 app/process，並以可辨識的既有 bundle 或 caller 指定 launch method 啟動，無法確認時停止而不宣稱已重啟。bootstrap 的 PID selector：零個匹配時繼續且不執行 `kill`；唯一匹配時才可停止該 PID；多個匹配時不執行 `kill`、停止並要求 human 提供明確唯一 selector 後重評。 |
| `swiftui-patterns` | 依既有結構與 caller UI task 建立或調整 macOS SwiftUI patterns。 | 將 `git init`、run bootstrap、固定檔案樹改為 caller 明確要求時才採用。 |
| `telemetry` | 依觀察目標、程式區域與驗證方式加入或檢查 telemetry。 | 使用既有 launch method；只有缺少所需入口時才建議轉介。 |
| `window-management` | 依目標 window／scene 行為調整管理方式。 | 接受任何可用 launch method；必要時才建議 `build-run-debug`。 |

### Batch E — PR Follow-up Metadata and Durable Principle

| Target | 最小責任與輸入 | 最小修正 |
| --- | --- | --- |
| `docs/design-principles.md` | 只接受本輪已證實、跨 topic 仍成立的本地 skill 維護結論。 | 加入「上游來源與本地 overlay 必須可追溯、不可混淆」及「只有 SDD contract skill 定義 SDD，其他 skills 不以 SDD 為前提」兩項長期原則；不記錄 PR thread、commit SHA 或一次性 remediation。 |
| `.codex/skills/BUILD_MACOS_APPS_UPSTREAM.md` | 提供 pinned upstream 與本地覆寫的可追溯 metadata。 | 新增 local overlay 區段，列出被本 repository 有意調整的 skill、調整原因與 upstream 同步時需重新評估的要求；不改動 upstream pin，不進行 plugin 同步。 |

Batch E 僅處理這兩個指定文件；它不改變其他 skill 的責任，也不建立新的 workflow contract。

## No-Change Skills

下列 skills 已符合最小責任界線，保持不修改：`appkit-interop`、`liquid-glass`、`packaging-notarization`、`sdd-workflow-contract`、`signing-entitlements`、`swiftpm-macos`、`test-triage`、`view-refactor`。

## Acceptance and Stop Conditions

- 檢查每個修正 skill 的 `SKILL.md` 與直接 references，確認無不必要 SDD／topic／step／phase／verdict／跨角色與 routing 假設。
- 所有 21 個 skill 都執行 `quick_validate.py`；任何驗證失敗先回到修改該 skill 的 Implementer，不以 tracker 或 status 放行。
- 獨立 Reviewer 以本 spec 的最小責任表審查，特別確認 Dispatcher 不被嵌入一般 skills、Git/worktree skills 不被 SDD 綁定，且安全規則未跨 skill 重複。
- 任何 caller 必需輸入、直接授權或 destructive approval 缺失時，對應 skill 停在其自身 boundary；不得延伸為全域 workflow gate。
- 對本輪 PR fixes 與 rework constraints 執行相稱驗證：branch occupancy 的 create/reuse 行為、branch-name 無 owner fallback、build relaunch 的 target／launch-method guard、PID selector 的零／唯一／多重匹配分支、metadata 與兩項 design principle 的一致性，以及受影響 skills 的 validator。PID selector 零個匹配時繼續且不執行 `kill`，唯一匹配時才可停止該 PID，多重匹配時必須不執行 `kill`、停止並要求 human 提供明確唯一 selector 後重評。獨立 Reviewer 應確認 release/remove 分離、未引入 upstream 同步假象，且沒有以文件回寫擴張 workflow scope。
