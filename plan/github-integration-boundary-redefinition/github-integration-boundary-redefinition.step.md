# GithubIntegration Boundary Redefinition：Step Ledger

## Current Phase

TS-02 獨立 Tester 與 RV-02 獨立 Reviewer 均為 `approved`。已進入終端 human review；不得將 human review 視為已完成。

## Ledger

| ID | Status | Owner | Completion | Evidence |
| --- | --- | --- | --- | --- |
| PL-01 | completed | Plan-Creator | 建立四份同 slug planning artifacts。 | requirements、technical spec、plan 與本 ledger 均位於指定 topic paths。 |
| PL-02 | completed | Plan-Creator | 記錄現況 inventory、dependency map、KEEP／MOVE／SPLIT／REMOVE 與 deferred decisions。 | `technical-spec.md` 的對應 sections；未宣稱未實作 runtime capability。 |
| RV-01 | completed | Plan-Reviewer | 獨立審查 artifact consistency、scope 與 workflow contract。 | 已收到獨立 Plan-Reviewer `approved` verdict；僅放行受限 documentation-only delivery。 |
| IM-01 | completed | Implementer | 在 RV-01 後完成首次受限 documentation 與 Bounded Context Map correction。 | active architecture documentation、BC boundary wording、GitHub API catalog introduction 與 Bounded Context Map 已更新；此首次交付未退役舊 Supporting BC assets。 |
| TS-01 | needs-rework | Tester | 檢查首次 documentation delivery。 | 發現 `docs/architecture/bounded-contexts/github-integration.md` 與 `docs/architecture/diagrams/github-integration-http-client-boundary/` 仍將已 supersede 的 Supporting BC／authorization semantics 保留為 active architecture truth，且 architecture README 仍導航至該 canvas。 |
| IM-02 | completed | Implementer | 在 resolved merge 中完成 TS-01 的必要文件退役與 artifact contract 同步。 | 已退役 `docs/architecture/bounded-contexts/github-integration.md` 及 `docs/architecture/diagrams/github-integration-http-client-boundary/`，從 `docs/architecture/README.md` 移除 navigation，並同步本 topic requirements、technical spec、plan 與 ledger 的 scope matrix、Deleted、驗收與路由。未觸及 runtime/module/package/API/auth implementation。 |
| TS-02 | completed | Tester | 在 IM-02 後重新確認 active docs／diagrams、retirement、Bounded Context Map validate/build、resolved merge 與 `git diff --check`。 | 獨立 Tester `approved`：MERGE_HEAD `60ca63e`；無 unmerged paths 或 conflict markers；cached／worktree diff checks 通過；舊 active GitHub Integration BC 文件與 authorization canvas 均已退役且無 navigation；shared non-BC boundary、BC-local ownership 與 generic `RivetHTTPClient` 一致；deferred auth details 不再是 active truth；canvas validate 為 6 bands／17 boxes／15 edges／0 errors／0 warnings，`scene.js` 與 `index.html` 一致，headless 實際視覺無碰撞；scope 無本 topic runtime 變更。 |
| RV-02 | completed | Reviewer | 在 TS-02 approved 後驗證 documentation delivery 的 dependency assertions、canvas validation、scope isolation 與測試證據。 | 獨立 Reviewer `approved`，無 findings：TS-02 evidence、resolved merge integrity、舊 Supporting BC／authorization assets retirement、shared non-BC boundary、BC-local ownership、Bounded Context Map canvas validation 與 documentation-only scope isolation 均通過。 |
| HC-01 | pending | Human | 在 RV-02 approved 後進行終端交付 review。 | RV-02 已 approved；等待 human review。不得將此 review 視為已完成，也不構成 merge 或 release 授權。 |

## Blockers

- 無已知實作 blocker；RV-02 已 approved，現行終端 gate 為 HC-01 human review。

## Human Check

PR #17／`github-integration-auth-boundary` 僅作 supersession traceability；其 pending gates 不構成本 topic 的前置條件、blocker 或 human gate。RV-02 已 completed／`approved`；現已進入 HC-01，僅供 human 確認受限交付結果，不得將其視為 merge 或 release 授權。

## Last Updated

- Topic：`github-integration-boundary-redefinition`
- 更新者：Implementer（依人類授權同步 RV-02 Reviewer evidence）
- 狀態：TS-01 needs-rework 已由 IM-02 回修；TS-02 Tester 與 RV-02 Reviewer 均為 `approved`。現等待 HC-01 終端 human review。完整路由為 Plan-Creator → Plan-Reviewer → Implementer → Tester → Reviewer → human review。
