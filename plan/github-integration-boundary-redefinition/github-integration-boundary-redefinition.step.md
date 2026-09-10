# GithubIntegration Boundary Redefinition：Step Ledger

## Current Phase

PR comment-fix 已由 Implementer 完成，現必須回到獨立 Tester 驗證。TS-02 與 RV-02 的 `approved` 只適用於 comment-fix 前的 prior tree，不得用作目前 tree 的 Tester、Reviewer 或 human completion。

## Ledger

| ID | Status | Owner | Completion | Evidence |
| --- | --- | --- | --- | --- |
| PL-01 | completed | Plan-Creator | 建立四份同 slug planning artifacts。 | requirements、technical spec、plan 與本 ledger 均位於指定 topic paths。 |
| PL-02 | completed | Plan-Creator | 記錄現況 inventory、dependency map、KEEP／MOVE／SPLIT／REMOVE 與 deferred decisions。 | `technical-spec.md` 的對應 sections；未宣稱未實作 runtime capability。 |
| RV-01 | completed | Plan-Reviewer | 獨立審查 artifact consistency、scope 與 workflow contract。 | 已收到獨立 Plan-Reviewer `approved` verdict；僅放行受限 documentation-only delivery。 |
| IM-01 | completed | Implementer | 在 RV-01 後完成首次受限 documentation 與 Bounded Context Map correction。 | active architecture documentation、BC boundary wording、GitHub API catalog introduction 與 Bounded Context Map 已更新；此首次交付未退役舊 Supporting BC assets。 |
| TS-01 | needs-rework | Tester | 檢查首次 documentation delivery。 | 發現 `docs/architecture/bounded-contexts/github-integration.md` 與 `docs/architecture/diagrams/github-integration-http-client-boundary/` 仍將已 supersede 的 Supporting BC／authorization semantics 保留為 active architecture truth，且 architecture README 仍導航至該 canvas。 |
| IM-02 | completed | Implementer | 在 resolved merge 中完成 TS-01 的必要文件退役與 artifact contract 同步。 | 已退役 `docs/architecture/bounded-contexts/github-integration.md` 及 `docs/architecture/diagrams/github-integration-http-client-boundary/`，從 `docs/architecture/README.md` 移除 navigation，並同步本 topic requirements、technical spec、plan 與 ledger 的 scope matrix、Deleted、驗收與路由。未觸及 runtime/module/package/API/auth implementation。 |
| TS-02 | completed | Tester | 在 IM-02 後重新確認當時的 active docs／diagrams、retirement、Bounded Context Map validate/build、resolved merge 與 `git diff --check`。 | 歷史證據，僅適用於 comment-fix 前的 prior tree：獨立 Tester `approved`，MERGE_HEAD `60ca63e`；無 unmerged paths 或 conflict markers；canvas validate 為 6 bands／17 boxes／15 edges／0 errors／0 warnings；`scene.js` 與 `index.html` 一致，且 scope 無 runtime 變更。不得作為 TS-03 evidence。 |
| RV-02 | completed | Reviewer | 在 TS-02 approved 後驗證當時 documentation delivery 的 dependency assertions、canvas validation、scope isolation 與測試證據。 | 歷史證據，僅適用於 comment-fix 前的 prior tree：獨立 Reviewer `approved`，無 findings。不得作為 RV-03 或 HC-01 evidence。 |
| IM-03 | completed | Implementer | 修正 PR comment threads 1–6：shared mechanism／BC-local boundary、canvas plane color、technical classification、compile-time edges、parent-baseline inventory 與 ledger routing。 | 本次 comment-fix 修改完成；不宣稱 Tester、Reviewer 或 human 已核可。post-fix tree 的 SHA、canvas validate/build、visual check 與 `git diff --check` 結果留給 TS-03 填寫。 |
| TS-03 | pending | Tester | 獨立驗證 IM-03 的 post-fix tree。 | Tester 必須記錄其檢查的最終 commit SHA／tree、architecture-canvas validate/build、視覺檢查、`git diff --check`、compile-time-only edges、shared technical classification 與 BC-local failure contract boundary 的實際結果。 |
| RV-03 | pending | Reviewer | 僅在 TS-03 `approved` 後，獨立審查 post-fix tree 的 comment resolution、scope isolation 與 evidence。 | 等待 TS-03；不得沿用 RV-02 evidence。 |
| HC-01 | pending | Human | 僅在 RV-03 `approved` 後進行終端交付 review。 | 等待 RV-03；不得將 prior-tree approvals 視為 human review、merge 或 release 授權。 |

## Blockers

- 無已知實作 blocker；現行 gate 是 TS-03 對 IM-03 post-fix tree 的獨立驗證。TS-03、RV-03 與 HC-01 均未完成。

## Human Check

PR #17／`github-integration-auth-boundary` 僅作 supersession traceability；其 pending gates 不構成本 topic 的前置條件、blocker 或 human gate。comment-fix 後，HC-01 必須等待 TS-03 與 RV-03 對同一 post-fix tree 的獨立 `approved`；它僅供 human 確認受限交付結果，不得將其視為 merge 或 release 授權。

## Last Updated

- Topic：`github-integration-boundary-redefinition`
- 更新者：Implementer（PR comment-fix 1–6）
- 狀態：TS-01 needs-rework 已由 IM-02 回修；TS-02 與 RV-02 保留為 prior-tree 歷史證據。IM-03 已完成，現等待 TS-03；完整 post-fix 路由為 Implementer → Tester → Reviewer → human review，且最終 SHA／tree 與命令結果由 Tester 填寫。
