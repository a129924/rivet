# GithubIntegration Boundary Redefinition：Step Ledger

## Current Phase

PR comment threads 1–5 的最終 tree 尚待新的獨立 Tester／Reviewer verification。PL-03 的 cross-topic artifact correction 只退役失效 writeback 引用；它不改變 HTTP 功能、API、tests、scope 或 gates。TS-04、RV-04 與更早 evidence 只適用於 prior tree，不得用作目前 tree 的 Reviewer 或 human completion。

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
| PL-03 | completed | Plan-Creator | 依 human 對 PR comment threads 1–5 的限縮授權，將兩個 HTTP topic 各自四份 planning artifacts 納入 allowlist，並只退役指向已刪除 `github-integration.md` 或舊 authorization boundary asset 的失效 writeback。 | 不指定 replacement target；不改變 HTTP header／JSON decoding 的 behavior、API、tests、scope 或 gates。 |
| IM-05 | completed | Implementer | 依 human 對 threads 3、5 的限縮授權，補齊 catalog 的 future shared-mechanism boundary wording，並將 PR Reader GraphQL SDL 還原為未驗證 candidate／暫存 asset。 | 僅修改 `docs/github-api/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 與本 ledger；不宣稱 runtime policy、正式 schema ownership、API 或實作已改變。TS-05 仍須獨立驗證最終 tree。 |
| TS-05 | completed | Tester | 獨立驗證 threads 1–5 最終 tree，verdict：`approved`。 | 實際 final HEAD／upstream 為 `2b6eac01d6ff23d9190376a7cbaed6659977c3b8`，tree 為 `c9d33368870169be6fdc276545cb43024b3bc195`；`git status --short` 為空、`git diff --check` 通過。architecture-canvas validate 結果為 6 bands／17 boxes／12 edges／0 errors／0 warnings；rebuild 後 `index.html` 與 committed artifact byte-identical，SHA256 為 `f4a1f9ce17692bf5304f78f0c0ceed7c2df8072c1965657449645ec35cd77103`。allowlist 檢查未發現 `packages/`、`Sources/`、`Tests/` 或 `Package.swift` 變更；threads 1–5 的限縮 acceptance 均通過。不得沿用 TS-04 或更早 evidence。 |
| RV-05 | completed | Reviewer | 在 TS-05 `approved` 後，獨立審查 final delivery tree，verdict：`approved`。 | Reviewer 已驗證 reviewed delivery HEAD／upstream `2b6eac01d6ff23d9190376a7cbaed6659977c3b8`、tree `c9d33368870169be6fdc276545cb43024b3bc195`；`git diff --check` 通過；architecture-canvas 為 6 bands／17 boxes／12 edges／0 errors／0 warnings；threads 1–5 acceptance 與 allowlist isolation 均通過。此 evidence 僅適用於上述 reviewed delivery tree，不延伸至本 audit-evidence commit 或未來 commit。 |
| HC-01 | pending | Human | 僅在 RV-05 明示 `approved` 後進行終端交付 review。 | 不得將 prior-tree approvals、TS-05 或 RV-05 視為 merge 或 release 授權。 |

## Blockers

- 無已知實作 blocker；TS-05 與 RV-05 對 threads 1–5 最終 tree 的獨立驗證尚未完成。現行 gate 是 TS-05。

## Human Check

PR #17／`github-integration-auth-boundary` 僅作 supersession traceability；其 pending gates 不構成本 topic 的前置條件、blocker 或 human gate。HC-01 須等待 TS-05 與 RV-05 對最終 tree 的明示 approved；不得將其視為 merge 或 release 授權。

## Last Updated

- Topic：`github-integration-boundary-redefinition`
- 更新者：Plan-Creator（依 human threads 1–5 限縮授權更新 allowlist 與 verification routing）
- 狀態：TS-01 needs-rework 已由 IM-02 回修；TS-02、RV-02、TS-03、TS-04 與 RV-04 保留為 prior-tree 歷史證據。current-tree 路由為 TS-05 → RV-05 → HC-01。
