# GithubIntegration Boundary Redefinition：Step Ledger

## Current Phase

RV-04 已對 TS-04 驗證的 HEAD `c34a7a23` current tree 完成獨立審查並給予 `approved`；現等待 HC-01 human review。TS-03 與更早 evidence 只適用於 prior tree，不得用作目前 tree 的 Reviewer 或 human completion。

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
| TS-03 | completed | Tester | 獨立驗證 IM-03 的 post-fix tree，verdict：`approved`。 | 已驗證 HEAD `9cafe00a3c1b548981081bf01b4a8a30599e0416`、tree `fdae47ddcce7f5b0ff5f3101a1d421fe04baf191`；`git diff --check 60ca63e..HEAD` 通過；變更限於允許 scope 並涵蓋 6 個 thread acceptance；architecture-canvas validate 為 6 bands／17 boxes／12 edges／0 errors／0 warnings；temporary build 與 committed `index.html` byte-identical，SHA256 為 `f4a1f9ce17692bf5304f78f0c0ceed7c2df8072c1965657449645ec35cd77103`；headless 視覺檢查通過，favicon 404 不影響結果。 |
| RV-03 | superseded | Reviewer | 原定在 TS-03 `approved` 後審查 IM-03 post-fix tree。 | PR comment threads 1–2 產生 IM-04，尚未開始的 RV-03 不再對 current tree 適用；TS-03 保留為 prior-tree Tester evidence。 |
| IM-04 | completed | Implementer | 修正 PR comment threads 1–2：補全 plan 的 future shared-mechanism responsibility categories，並將 GitHub API catalog introduction／「共通規則」的 shared-module boundary wording 納入 delivery contract。 | 僅修改本 topic requirements、technical spec、plan 與 ledger；未修改 runtime、API、auth lifecycle、catalog capability content 或 thread 3 的 old-topic artifacts。不得將此完成視為 Tester、Reviewer 或 human 核可。 |
| TS-04 | completed | Tester | 獨立驗證 HEAD `c34a7a23` current tree 的 PR comment threads 1–3 acceptance、delivery allowlist／ReadOnly contract 一致性與 `git diff --check`，verdict：`approved`。 | 已驗證 8 個未提交 planning artifact edits：#1 plan 明載 future shared mechanisms 為 pagination、rate limit 與 retry；#2 GitHub API catalog introduction／共通規則的 shared-module boundary wording 已納入 Modify contract 並與 README 實際內容一致；#3 `swift-http-response-header-conveniences` 的四份 artifacts 將 GitHub Integration writeback 標為 superseded、未指定 replacement target，且其餘 HTTP header scope 不變。所有允許路徑均為 planning/documentation artifacts，無 runtime 變更；`git diff --check` 通過。不得沿用 TS-03 或更早 evidence。 |
| RV-04 | completed | Reviewer | 在 TS-04 `approved` 後，獨立審查 HEAD `c34a7a23` current tree 的 comment resolution、scope isolation 與 evidence，verdict：`approved`。 | 獨立 Reviewer `approved`，無 findings；確認 threads 1–3、TS-04 evidence、scope isolation 與 canvas contract 均通過。不得將此 approval 延伸為 human review、merge 或 release 授權。 |
| HC-01 | pending | Human | 僅在 RV-04 `approved` 後進行終端交付 review。 | RV-04 已 approved；等待 human review，不得將 prior-tree approvals、TS-04 或 RV-04 視為 merge 或 release 授權。 |

## Blockers

- 無已知實作 blocker；TS-04 與 RV-04 已對 HEAD `c34a7a23` current tree approved。現行 gate 是 HC-01 human review。

## Human Check

PR #17／`github-integration-auth-boundary` 僅作 supersession traceability；其 pending gates 不構成本 topic 的前置條件、blocker 或 human gate。TS-04 與 RV-04 已對 HEAD `c34a7a23` current tree approved；HC-01 等待 human 確認受限交付結果，不得將其視為 merge 或 release 授權。

## Last Updated

- Topic：`github-integration-boundary-redefinition`
- 更新者：Implementer（回寫 RV-04 Reviewer approved evidence）
- 狀態：TS-01 needs-rework 已由 IM-02 回修；TS-02、RV-02 與 TS-03 保留為 prior-tree 歷史證據。TS-04 與 RV-04 已對 HEAD `c34a7a23` approved；current-tree 路由為 human review，HC-01 pending。
