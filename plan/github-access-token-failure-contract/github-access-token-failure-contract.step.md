# GitHub Access Token Failure Contract：Step Ledger

## Current Phase

RV-04 external Code-Reviewer 已 `approved`／`pass`，且只完成 IM-04 snapshot 的 pre-integration review，不構成 delivery approval。CF-01 為 `pending / eligible` 的下一 gate，且只能建立 non-delivery comment-fix commit。TE-04 已 pass，但 `docs/architecture/README.md` 的 `origin/dev` base conflict 與未提交 comment fixes 使 merge/delivery 不安全。DL-01 已完成且 PR 已進入 human review；RV-02 與 RV-03 的歷史 verdict 均保持 `needs-rework`，其中 RV-03 不得改寫為 `approved`。IN-01、TE-05、RV-05、DL-02 維持 `pending`。唯一可前進的 corrective route 為 CF-01 → IN-01 → TE-05 → RV-05；只有 RV-05 明示 `approved` 後，才可進入 DL-02。

## Goal

交付單一 `GitHubIntegration` target 的 typed-throws token store/provider contract，並保留既有 shared-module boundary。

## Non-Goal

不實作 Keychain、UI、REST/GraphQL adapter、OAuth 或 lifecycle；不改變 HTTP 或 Domain target。唯一新增 explicit conformance 是 `TokenStoreOperation: Sendable`，僅為 Swift 6 warnings-as-errors remediation；`TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 有 Swift 隱含 `Sendable` 關係，但不新增其 explicit conformance 或 concurrency behavior。

## In-Scope

四個 credential/store type、兩個 protocol、store-backed provider、single target/product/test target、指定 Contracts/Providers layout、contract tests、`TokenStoreOperation: Sendable`，以及指定 canonical document/map 的最小 factual writeback。

## Out-Of-Scope

新的 module/target、Security/Keychain、REST/GraphQL/Apollo、OAuth、refresh、re-auth、401 retry、多帳號、Enterprise、HTTP policy、`async`、cancellation，以及除 `TokenStoreOperation: Sendable` 外的新增 explicit `Sendable` conformance 或 concurrency behavior。

## ReadOnly

`RivetHTTPClient`、PR Inbox、PR Reader、所有其他 Domain target/source/tests、既有 HTTP/GraphQL source/tests、除 bounded-context map 外的 architecture diagrams 與既有 BC boundary decisions。

## Written

實作階段新增 `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`、`GitHubTokenStore.swift`、`GitHubTokenProvider.swift`、`Providers/TokenStoreGitHubTokenProvider.swift`，以及 `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift`、`StaticIsolationTests.swift`；PR comment fix 只允許在 `CredentialTypes.swift` 增加唯一 explicit `TokenStoreOperation: Sendable` conformance（`TokenStoreError`／`GitHubCredentialError` 僅保留因 `Error` 而有的 Swift 隱含關係，不額外宣告），在 `StaticIsolationTests.swift` 進行 graph/source/import/Sendable checks remediation，並寫入 `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的受限 canonical factual wording。planning phase 已寫入四份同 slug artifacts。

## Modify

實作階段僅修改 root `Package.swift`、`Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`、`docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`，以及 `docs/architecture/diagrams/bounded-context-map/scene.js` 與生成 `index.html` 的 minimal factual contract writeback。source 限 `TokenStoreOperation: Sendable`；test 限 structured graph/source/import/Sendable checks；兩份新增 doc 限已實作 token contract 與 Keychain/authorizer/REST/OAuth lifecycle deferred 的 factual wording。pre-integration merge 只允許 non-force merge `origin/dev`，只 resolve `docs/architecture/README.md` 的單一 semantic hunk，且同時保留 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。diagram 必須由 `architecture-canvas` validation/build 同步，且不得發布 artifact.cafe。

## Deleted

無；不得刪除、搬移或更名既有檔案。

## TestCase

原樣 token return、`nil` 至 `.missingCredential`、`load()` store error 至保留 operation/underlying error 的 `.tokenStore`、external mock conformance、provider injection/conformance、`TokenStoreOperation: Sendable` explicit conformance compile check（不新增其他 explicit conformance 或 concurrency behavior，並保留 error types 的 Swift 隱含關係）、structured package/target graph assertion、four-source exact-set、actual target source enumeration、forbidden-import checks、bounded-context map `architecture-canvas` validation/build、`pr-reader.md`／GitHub API README factual wording、README conflict hunk 同時保留 `GitHubIntegration` implemented/deferred wording 與 HTTP decoded payload `Decodable & Sendable` sentence、root `swift test` 與 `git diff --check`。

## PR Comment Triage

五項 PR comments 均屬 planning-truth correction，且不改變已鎖定 API、scope、failure contract、target dependency 或 architecture decision：

| Comment | Triage | Required record |
| --- | --- | --- |
| PC-01 | accepted | `TokenStoreOperation: Sendable` 是唯一新增的 explicit public conformance。 |
| PC-02 | accepted | `TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 有 Swift 隱含 `Sendable` 關係；不額外宣告 conformance 或 concurrency behavior。 |
| PC-03 | accepted | RV-03 歷史 verdict 保持 `needs-rework`，不得回寫為 `approved`。 |
| PC-04 | accepted | DL-02 撤除 `eligible` 並恢復 `pending`。 |
| PC-05 | accepted | `PR-06 → IM-04 → TE-04` 已完成；README conflict 後僅 `RV-04 → CF-01 → IN-01 → TE-05 → RV-05` 可產生新的 delivery gate truth，delivery 只依 RV-05 明示 `approved`。 |

## Ledger

| ID | Status | Owner role | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-01 | completed | Plan-Creator | 建立同 slug 的 requirements、technical spec、plan 與 step artifacts。 | 四份文件均存在，並一致記錄 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Modify、Deleted、TestCase、locked API/layout 與 handoff。 | 僅四份指定 planning artifacts 已寫入 feature worktree；未實作 Swift、執行測試、Git、commit、push 或 PR。 |
| PR-01 | completed | Plan-Reviewer | 獨立審查四份 planning artifacts。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check` verdict；不得以 artifact existence 或 ledger status 代替 verdict。 | 獨立 Plan-Reviewer `/root/review_feature_baseline_plan` verdict `pass`；findings：none。 |
| IM-01 | completed | Implementer | 在 feature worktree 實作 approved contract。 | 只寫入 Written/Modify targets，保留 API、failure mapping、layout、target dependency 及 scope。 | Implementer `/root/implement_token_contract` 已完成；`swift test --filter GitHubTokenProviderTests`：4 passed；root `swift build`：passed；root `swift test`：14 passed；`git diff --check`：passed；dev status：clean。 |
| TE-01 | completed | Tester | 獨立驗證 target、contract、test suite 與 diff hygiene。 | 如實回報 root `swift test`、`git diff --check`、target/import isolation 及任何 blocker。 | Tester `/root/test_token_contract` verdict `pass`；`swift build && swift test` exit 0，14 tests / 5 suites passed；package describe target/layout/dependency isolation passed；diff checks passed；無 Sendable warning/error；no blocker。Revalidation：14 tests、format、SwiftLint、renderer-check、staged diff-check 均 passed；無 unstaged 或 lockfile drift。 |
| RV-01 | completed | Code-Reviewer | 獨立審查實作、驗證 evidence、scope、contract 與 workflow drift。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check` verdict。 | External Code-Reviewer final re-review verdict `pass`；findings：none；staged 13 files exact topic；delivery eligible。 |
| DL-01 | completed | Implementer | 依 human delivery authority commit by topic、push 並開 draft PR。 | Commit 已推送至 feature branch；draft PR target 為 `dev`，且未 merge/release。 | Commit `d2b324e` 已推送；PR #26 已建立並由 human 設為 Ready for review。 |
| AM-01 | completed | Plan-Creator | 依 human 對 PR comments 的明確授權，修正四份 planning artifacts。 | 四份 artifacts 一致限制 amendment 為唯一新增 explicit `TokenStoreOperation: Sendable` conformance 與指定 canonical truth/map writeback；其餘 contract/scope 維持鎖定。 | Human 明確授權兩項 planning amendment；本次 Plan-Creator 僅修改四份 topic planning artifacts。 |
| PR-02 | needs-rework | Plan-Reviewer | 獨立審查 PR comment planning amendment。 | 明示 verdict；確認 Sendable exception、canonical map/doc scope、test/handoff 與既定 contract 一致。 | Plan-Reviewer verdict `needs-rework`：必須將 `StaticIsolationTests.swift` 的 structured package/target graph、exact source-set、actual-source enumeration、forbidden-import 與 Sendable compile checks 納入受限 handoff/TestCase。 |
| AM-02 | completed | Plan-Creator | 依 PR-02 needs-rework 修正四份 planning artifacts。 | 四份 artifacts 一致限制 static-isolation remediation 為 `StaticIsolationTests.swift`，並維持所有既定 contract/scope。 | 本次 Plan-Creator 僅修改四份 topic planning artifacts；未實作、測試或執行 Git。 |
| PR-03 | completed | Plan-Reviewer | 獨立審查 PR-02 rework。 | 明示 verdict；確認 source/test allowlist、static-isolation TestCase/handoff 與既定 contract 一致。 | Plan-Reviewer `/root/review_pr_comment_amendment` verdict `pass`／`approved`；findings：none；amendment scope bounded。 |
| IM-02 | completed | Code-Implementer | 依 approved amendment 修正 implementation、canonical docs/map 與 tests。 | 僅寫入 amended Written/Modify targets；唯一新增 explicit conformance 是 `TokenStoreOperation: Sendable`；architecture-canvas validation/build 通過；不重開其他 contract。 | `TokenStoreOperation: Sendable`、structured package/source/import isolation tests、design principles／PR Inbox factual writeback 與 bounded-context map 已完成；red：缺少 Sendable conformance 時 `StaticIsolationTests.tokenStoreOperationIsSendable` compile failure；green：static isolation 5 tests／2 suites、root `swift test` 15 tests／5 suites、`scripts/check-swift-format.sh`、`swiftlint lint --strict`、architecture-canvas validate（0 errors／0 warnings）與 build 均通過。 |
| TE-02 | pending | Tester | 獨立驗證 PR comment fix。 | 如實回報 Sendable compile check、contract/isolation、architecture-canvas、root test 與 diff hygiene evidence。 | 等待 IM-02 completion。 |
| RV-02 | needs-rework | Code-Reviewer | 獨立審查 fix 與 evidence。 | 明示 verdict，分類 unresolved PR comments。 | Code-Reviewer verdict `needs-rework`：`pr-reader.md` 與 GitHub API README 仍將已實作的 token contract 表示為若建立／未來／尚未實作；屬既有 human-authorized canonical truth/map update 的必要範圍。 |
| AM-03 | completed | Plan-Creator | 依 RV-02 needs-rework 修正四份 planning artifacts。 | 四份 artifacts 一致限制兩份 canonical docs 僅更新已實作 token contract 與 deferred wording，不新增 architecture decision。 | 本次 Plan-Creator 僅修改四份 topic planning artifacts；未實作、測試或執行 Git。 |
| PR-04 | completed | Plan-Reviewer | 獨立審查 RV-02 canonical-doc amendment。 | 明示 verdict；確認兩份 doc 的 allowlist、TestCase/handoff 與既定 contract/scope 一致。 | PR-04 approved；fresh corrective route authorized。 |
| PR-05 | completed | Plan-Reviewer | 獨立審查 fresh corrective route。 | 明示 verdict；確認 IM-03 allowlist、TE-03/RV-03/DL-02 gate 與既定 contract/scope 一致。 | External Plan-Reviewer verdict `pass`／`approved`；findings：none。 |
| IM-03 | completed | Code-Implementer | 僅修正 `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 factual status。 | 僅將已實作 token contract 更新為 current truth，並保留 Keychain、authorizer、REST、OAuth lifecycle deferred。 | 兩份文件已將 `GitHubIntegration` 的可注入、同步、typed-throws access-token store/provider contract 表達為已實作；並明確保留 Keychain、authorizer、GitHub REST／GraphQL raw transport 與 OAuth lifecycle 為 deferred。未執行測試、Git commit、push 或 PR thread 操作。 |
| TE-03 | completed | Tester | 獨立驗證 IM-03 的兩份 canonical docs。 | 確認兩份文件如實表達已實作 token contract 與 deferred capabilities，且無 scope/API drift。 | Tester verdict `pass`；root `swift test` 15 tests passed。 |
| RV-03 | needs-rework | Code-Reviewer | 獨立審查 IM-03 與 TE-03 evidence。 | 發出明示 verdict，確認 factual wording、scope 與 workflow。 | Technical/doc verdict 無需 rework；僅因 ledger inconsistency 為 `needs-rework`，不得視為 `approved`。 |
| LR-01 | completed | Code-Reviewer | 獨立確認 ledger reconciliation。 | 驗證 IM-03、TE-03、RV-03、DL-02 的 record、status、evidence 與 transition 一致，發出 `pass` 或需要回修的 verdict。 | External Code-Reviewer verdict `pass`；record 一致。 |
| AM-04 | completed | Plan-Creator | 處置本次五項 PR comments 的 planning-truth amendment。 | 四份 artifacts 一致記錄唯一新增 explicit `TokenStoreOperation: Sendable` conformance、error types 的 Swift 隱含關係、RV-03 historical `needs-rework`、DL-02 `pending` 與 fresh corrective route；不得改變 locked contract/scope。 | Plan-Creator 僅修改四份指定 planning artifacts；未實作 Swift/docs/map/test、未執行 Git 或 delivery。 |
| PR-06 | completed | Plan-Reviewer | 獨立審查 AM-04 planning-truth amendment。 | 發出明示 verdict；確認五項 comment triage、fresh route 與 delivery gate 不重寫歷史 verdict，且不擴張 API/scope。 | External Plan-Reviewer verdict `approved`／`pass`；findings：none。 |
| IM-04 | completed | Code-Implementer | 僅在 PR-06 `approved` 後執行既有 allowlist 內、由 PR comments 所需的 corrective work。 | 具體改動逐項可追溯至既有 Written/Modify allowlist；不得新增 API、scope、architecture decision 或未授權檔案。 | `StaticIsolationTests.swift` 新增 red→green fixture，涵蓋 PackageDescription 的 `byName`／`target`／`product` dependency representation、production target 原始 dependencies empty assertion，以及 attribute／scoped-import module-root extraction 後逐一檢查 actual source；保留 existing exact-source graph checks。bounded-context map 將 GitHubIntegration 明確為「不定義 BC failure contract」，同時呈現已交付 shared technical credential errors，並以 architecture-canvas validate/build 同步 `index.html`（0 errors／0 warnings）。僅修改 IM-04 allowlist；未碰 `docs/architecture/README.md` conflict。 |
| TE-04 | completed | Tester | 獨立驗證 IM-04 的實際 corrective work 與現有 TestCase。 | 如實回報 scope、contract、驗證結果與 blocker；不得發布 delivery verdict。 | Tester verdict `pass`；README base conflict 是 delivery blocker，且未提交 comment fixes 使 merge 不安全。 |
| AM-05 | completed | Plan-Creator | 依 TE-04 delivery blocker 修正 corrective route。 | 四份 artifacts 一致記錄 pre-integration review、single comment-fix commit、non-force merge、README semantic hunk、TE-05/RV-05 與 DL-02 fresh gate；不改 API/scope。 | Plan-Creator 僅修改四份 topic planning artifacts；未修改產品/docs/tests，未執行 Git 或 delivery。 |
| PR-07 | completed | Plan-Reviewer | 獨立審查 AM-05 corrective route。 | 發出明示 verdict；確認 pre-integration review、non-delivery commit、non-force merge、README semantic hunk、TE-05/RV-05/DL-02 gate 與既定 contract/scope 一致。 | External Plan-Reviewer verdict `approved`／`pass`；findings：none。 |
| RV-04 | completed | Code-Reviewer | 獨立 pre-integration review，且只 review IM-04 snapshot。 | 明示 verdict；只確認 IM-04 snapshot 是否可進入 authorized comment-fix commit，不得產生 delivery approval 或重寫歷史 verdict。 | External Code-Reviewer verdict `approved`／`pass`；IM-04 snapshot 可進入 CF-01；非 delivery approval。 |
| CF-01 | pending / eligible | Code-Implementer | 在 RV-04 `approved` 後建立 single authorized comment-fix commit。 | commit 只包含既有 comment fixes；明確標示非 delivery completion，且不得 push、resolve thread、rebase 或 force push。 | RV-04 `approved`／`pass`；CF-01 eligible，等待 Code-Implementer。 |
| IN-01 | pending | Code-Implementer | 在 CF-01 後 non-force merge `origin/dev`。 | 只 resolve `docs/architecture/README.md` 的單一 semantic hunk；同時保留 `GitHubIntegration` implemented/deferred wording 與 HTTP decoded payload `Decodable & Sendable` sentence；不得 rebase、force push 或單方覆寫。 | 等待 CF-01 completion。 |
| TE-05 | pending | Tester | 獨立驗證 IN-01 merge 結果與既有 TestCase。 | 如實回報 README hunk preservation、scope、verification evidence 與 blocker；不得發布 delivery verdict。 | 等待 IN-01 completion。 |
| RV-05 | pending | Code-Reviewer | 獨立審查 IN-01 與 TE-05 evidence，產生 fresh delivery verdict。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；不得借用 RV-03、LR-01 或 RV-04 作為 delivery approval。 | 等待 TE-05 completion。 |
| DL-02 | pending | Code-Implementer | 依 human authority push fix，並只 resolve 已完成 threads。 | RV-05 明示 `approved`、無 unresolved blocker、human delivery authority 存在；PR 維持 human review boundary。 | 等待 RV-05 fresh `approved`。 |

## Blockers

- delivery blocker：`docs/architecture/README.md` 的 `origin/dev` base conflict 與未提交 comment fixes。流程 blocker 為 CF-01、IN-01、TE-05、RV-05 尚未完成。DL-02 是 `pending`，不得以 RV-03、LR-01、RV-04 或既有 human delivery authority 單獨前進。

## Human Check

- PR #26 維持 human review boundary；不得自動 merge、release、delete branch 或進行其他整合動作。
- 僅在 RV-05 明示 `approved` 後，才可依既有 human authority push 並 resolve 已完成的 threads；未完成或需 human decision 的 thread 必須保留。
- 不得 rebase 或 force push；IN-01 只可 non-force merge `origin/dev`，並只 resolve README 的指定 semantic hunk。
- 若任一獨立 reviewer verdict 為 `blocked` 或 `human-check`，停止自動前進並交還 human。

## Last Updated

2026-09-11 — RV-04 external Code-Reviewer `approved`／`pass`，只為 pre-integration snapshot review，非 delivery approval；CF-01 `pending / eligible`，IN-01、TE-05、RV-05、DL-02 維持 pending。
