# GitHub Access Token Failure Contract：Step Ledger

## Current Phase

PR #26 處於 human review／PR-comment review-and-fix phase。historic `DL-02a → RV-05 → DL-02b` route 已不是 current gate，且本 ledger 不回填或推論未記錄的 RV-05 verdict。RV-02 與 RV-03 的 historical verdict 均保持 `needs-rework`，其中 RV-03 不得改寫為 `approved`。TE-06 發現 default consumer `.build` 被 SwiftLint 掃描，PR-10 判定 AM-07 的 combined command 不可執行；human 已授權 AM-09 minimal exact-path cleanup amendment，新的 revalidation route 為 `AM-09 → PR-12 → TE-09 → RV-06 → DL-03`，不能援引 historic route。

## Goal

交付單一 `GitHubIntegration` target 的 typed-throws token store/provider contract，並保留既有 shared-module boundary。

## Non-Goal

不實作 Keychain、UI、REST/GraphQL adapter、OAuth 或 lifecycle；不改變 HTTP 或 Domain target。唯一新增 explicit conformance 是 `TokenStoreOperation: Sendable`，僅為 Swift 6 warnings-as-errors remediation；`TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 有 Swift 隱含 `Sendable` 關係，但不新增其 explicit conformance 或 concurrency behavior。

## In-Scope

四個 credential/store type、兩個 protocol、store-backed provider、single target/product/test target、指定 Contracts/Providers layout、contract tests、`TokenStoreOperation: Sendable`，以及指定 canonical document/map 的最小 factual writeback；另含只驗證 public surface 的獨立 consumer fixture package。

## Out-Of-Scope

新的 root module/target、Security/Keychain、REST/GraphQL/Apollo、OAuth、refresh、re-auth、401 retry、多帳號、Enterprise、HTTP policy、`async`、cancellation，以及除 `TokenStoreOperation: Sendable` 外的新增 explicit `Sendable` conformance 或 concurrency behavior；consumer fixture 不得改動 root manifest、target/product、production source 或 public API，且不得使用 `@testable`。

## ReadOnly

`RivetHTTPClient`、PR Inbox、PR Reader、所有其他 Domain target/source/tests、既有 HTTP/GraphQL source/tests、root `Package.swift`、既有 `GitHubIntegration` product/target 與 production source/public API、除 bounded-context map 外的 architecture diagrams 與既有 BC boundary decisions。

## Written

實作階段新增 `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`、`GitHubTokenStore.swift`、`GitHubTokenProvider.swift`、`Providers/TokenStoreGitHubTokenProvider.swift`，以及 `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift`、`StaticIsolationTests.swift`；fresh PR-comment route 另新增 `Tests/GitHubIntegrationConsumer/Package.swift` 與 `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`。consumer manifest 固定 `../..` local-path dependency、macOS 15、Swift 6、單一 test target，僅依 package `Rivet` 的 `GitHubIntegration` product；public test 僅 `import GitHubIntegration`。planning phase 已寫入四份同 slug artifacts；AM-09 只寫入這四份 artifacts，不寫入 Swift source、consumer fixture 或 `.swiftlint.yml`。

## Modify

fresh PR-comment route 只修改 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`，補 multiline-attribute import parser edge case；既有 structured graph/source/import assertions、root manifest、target/product 與 production source set 維持不變。AM-09 verification workflow 不修改 tracked source、fixture 或 config；只在 safety checks 通過時處理 ignored generated output 的 exact path。其餘 Modify allowlist 與 historic integration record 不因本 amendment 改寫。

## Deleted

不得刪除、搬移或更名任何 tracked file。AM-09 唯一許可的 deletion 是 safety checks 通過後的 ignored generated output `Tests/GitHubIntegrationConsumer/.build`；不得刪除其他 target 或 path。

## TestCase

原樣 token return、`nil` 至 `.missingCredential`、`load()` store error 至保留 operation/underlying error 的 `.tokenStore`、external mock conformance、provider injection/conformance、`TokenStoreOperation: Sendable` explicit conformance compile check（不新增其他 explicit conformance 或 concurrency behavior，並保留 error types 的 Swift 隱含關係）、structured package/target graph assertion、four-source exact-set、actual target source enumeration、forbidden-import checks、multiline-attribute import parser edge case、consumer fixture 的 two-step same-shell public API verification：先 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"`，再 `swift test --package-path Tests/GitHubIntegrationConsumer --scratch-path "$RIVET_CONSUMER_BUILD_PATH"`（task-scoped temporary scratch，無 `@testable`、public token/error property/initializer/case surface、Sendable、private external typed-throws mock、provider existential injection、success/missing/store-error mapping）。其後只可清理 exact `Tests/GitHubIntegrationConsumer/.build`：若不存在（亦非 symlink），不執行 cleanup，直接驗證 absence；若存在或為 symlink，必須為 non-symlink directory，且通過 `git check-ignore -q -- Tests/GitHubIntegrationConsumer/.build`，才可執行 `rm -rf -- Tests/GitHubIntegrationConsumer/.build`。禁止 broad target、glob 或其他 path；non-directory、symlink、non-ignored、cleanup 或清理後 `test ! -e Tests/GitHubIntegrationConsumer/.build && test ! -L Tests/GitHubIntegrationConsumer/.build` 失敗即為 workflow blocker 並停止。absence verification 通過後才執行完整 `swiftlint lint --strict` 與 diff checks。consumer route 不得修改 `.swiftlint.yml`、root manifest、target/product、production source 或 public API；historic route 不再是後續 comment 的驗收 gate。

## PR Comment Triage

五項 PR comments 均屬 planning-truth correction，且不改變已鎖定 API、scope、failure contract、target dependency 或 architecture decision：

| Comment | Triage | Required record |
| --- | --- | --- |
| PC-01 | accepted | `TokenStoreOperation: Sendable` 是唯一新增的 explicit public conformance。 |
| PC-02 | accepted | `TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 有 Swift 隱含 `Sendable` 關係；不額外宣告 conformance 或 concurrency behavior。 |
| PC-03 | accepted | RV-03 歷史 verdict 保持 `needs-rework`，不得回寫為 `approved`。 |
| PC-04 | accepted | amendment 當時的 final thread-resolution gate 維持 pending，歷史 evidence 不取代 RV-05 remote approval。後續 delivery 已關閉該 historical route；它不提供新 comment 的 resolution authority。 |
| PC-05 | accepted | `DL-02a → RV-05 → DL-02b` 是當時 remote 尚未承載已驗證 head 時的 corrective route。其後 feature branch、remote branch 與 PR head 已同步至 `67a2cb7`；`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此記錄不補造 RV-05 verdict，也不是後續 PR comment 的 gate。 |
| PC-06 | accepted | human 授權唯一 external consumer fixture package；它與 multiline-attribute parser thread 必須走 fresh gate，且不改變 locked API、scope、failure contract、target dependency、Non-Goal 或 architecture decision。 |

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
| CF-01 | completed | Code-Implementer | 在 RV-04 `approved` 後建立 single authorized comment-fix commit。 | commit 只包含既有 comment fixes；明確標示非 delivery completion，且不得 push、resolve thread、rebase 或 force push。 | Local-only commit `ed6a957`；all hooks pass；non-delivery、未 push。 |
| IN-01 | completed | Code-Implementer | 在 CF-01 後 non-force merge `origin/dev`。 | 只 resolve `docs/architecture/README.md` 的單一 semantic hunk；同時保留 `GitHubIntegration` implemented/deferred wording 與 HTTP decoded payload `Decodable & Sendable` sentence；不得 rebase、force push 或單方覆寫。 | 已完成，結果交由 TE-05 內容驗證。 |
| TE-05 | completed | Tester | 獨立驗證 IN-01 merge 結果與既有 TestCase。 | 如實回報 README hunk preservation、scope、verification evidence 與 blocker；不得發布 delivery verdict。 | Content verification verdict `pass`。當時 remote-head verification 尚未記錄；後續 delivery 已將 feature branch、remote branch 與 PR head 同步至 `67a2cb7`。 |
| PR-08 | completed | Plan-Reviewer | 獨立審查 `DL-02a → RV-05 → DL-02b` remote-first delivery route。 | 發出明示 verdict；確認 DL-02a 非 approval／不 resolve threads、RV-05 remote review 與 DL-02b completed-thread-only gate 不重寫歷史 verdict 或擴張 scope。 | Latest external Plan-Reviewer verdict `pass`／`approved`；findings：none。 |
| DL-02a | completed | Code-Implementer | push already-tested local HEAD 至 remote branch。 | push 的 HEAD 必須是 TE-05 已驗證的 local HEAD；不得 resolve threads，且此操作不構成 approval、delivery completion 或 human-review exit。 | Subsequent delivery synchronized feature branch, remote branch and PR head at `67a2cb7`; `origin/dev` is in history and PR is mergeable clean. |
| RV-05 | not-recorded | Code-Reviewer | 獨立 review DL-02a 後的 remote PR/head，產生 fresh remote verdict。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；不得借用 RV-03、LR-01、RV-04 或 TE-05 作為 remote delivery approval。 | 本 artifact 沒有可驗證的 RV-05 verdict；不得根據後續 delivery 或 thread action 回填 verdict。 |
| DL-02b | completed (historical) | Code-Implementer | 僅 resolve 已完成的 PR threads。 | RV-05 明示 `approved`、無 unresolved blocker、human delivery authority 存在；不得新增 code、push、rebase 或 force push；PR 維持 human review boundary。 | 後續 PR-comment delivery 已完成當時已完成 threads 的 resolution；此 historical completion 不授權或預先 resolve 新 threads。 |
| AM-06 | completed | Plan-Creator | 依 human 授權建立 multiline parser／external consumer fixture amendment。 | 四份 artifacts 一致列出 fixture paths、manifest contract、ReadOnly/Written/Modify/TestCase 與 fresh gate；不改變 locked API、scope、failure contract、target dependency、Non-Goal 或 architecture decision。 | Plan-Creator 僅修改四份 topic planning artifacts；未修改 Swift、fixture、Git、PR/thread 或 dev。 |
| PR-09 | completed | Plan-Reviewer | 獨立審查 AM-06。 | 明示 verdict，確認 fixture 是單一外部 consumer package，`@testable` 禁止、local-path/package/product contract、parser edge scope、ReadOnly/Written/Modify/TestCase 與 fresh route 均一致。 | External Plan-Reviewer verdict `pass`；findings：none。 |
| IM-05 | completed | Code-Implementer | 依 PR-09 approved 修正兩個新 PR threads。 | 只改 `StaticIsolationTests.swift` 的 multiline-attribute parser edge case，並新增指定 consumer `Package.swift`／`PublicAPITests.swift`；不得修改 root manifest、target/product、production source、public API 或已鎖定 contract。 | parser red：新 multiline balanced-attribute case failed；green：該 case passed。新增 external fixture（macOS 15／Swift 6、`../..` named `Rivet` local dependency、僅 `GitHubIntegration` product 的單一 test target、無 `@testable`）後 consumer `swift test` 4 passed；root `swift test` 28 passed；Swift format、SwiftLint 與 `git diff --check` passed。 |
| TE-06 | blocked | Tester | 獨立驗證 IM-05。 | 如實回報 root test、consumer public-only import、parser edge、scope 與 diff hygiene。 | default consumer `.build` 被完整 SwiftLint 掃描，不能以修改 `.swiftlint.yml` 解決；需 human-authorized temporary-scratch verification amendment。 |
| RV-06 | pending | Code-Reviewer | 獨立審查 IM-05／TE-06 的 fresh evidence。 | 明示 verdict；確認兩個 threads 的 fix、scope 與 contract。 | 等待 TE-06。 |
| DL-03 | pending | Code-Implementer | 依 fresh RV-06 approved 與 human delivery authority commit、push、resolve completed threads。 | commit 僅含 AM-06 authorized changes；push feature branch；只 resolve 已完成的 multiline parser 與 consumer threads；不 merge、release、rebase 或 force push。 | 等待 RV-06 與 human delivery authority。 |
| AM-07 | completed | Plan-Creator | 依 human 授權修正 consumer fixture verification workflow。 | 四份 artifacts 一致固定 task-scoped temporary scratch command、fixture 無 `.build`、其後完整 SwiftLint/diff checks，且不改 source/fixture/config/API scope。 | Plan-Creator 僅修改四份 topic planning artifacts；未改 source、fixture、config、Git 或 PR。 |
| PR-10 | needs-rework | Plan-Reviewer | 獨立審查 AM-07。 | 明示 verdict；確認 task-scoped scratch command、禁止 fixture `.build`／`.swiftlint.yml` 變更、TestCase/handoff 與 revalidation route 一致。 | Plan-Reviewer verdict `needs-rework`：combined variable-assignment command 不保證 `$RIVET_CONSUMER_BUILD_PATH` 可供同一 command expansion 使用；必須改為 two-step same-shell sequence，並在 SwiftLint 前明示 `.build` absence precheck／workflow-blocker stop rule。 |
| TE-07 | blocked | Tester | 依 PR-10 approved 執行 fresh consumer verification。 | task-scoped scratch command、完整 SwiftLint 與 diff checks。 | PR-10 needs-rework；不可執行 combined command，等待 AM-08／PR-11。 |
| AM-08 | completed | Plan-Creator | 依 PR-10 needs-rework 修正 consumer verification workflow。 | 四份 artifacts 一致記錄 two-step same-shell command、SwiftLint 前 `.build` absence precheck、workflow-blocker stop rule，且不改 source/fixture/config/API scope。 | Plan-Creator 僅修改四份 topic planning artifacts；未改 source、fixture、config、Git 或 PR。 |
| PR-11 | pending | Plan-Reviewer | 獨立審查 AM-08。 | 明示 verdict；確認 two-step same-shell sequence、`.build` absence precheck、blocker stop rule、TestCase/handoff 與 fresh revalidation route 一致。 | 等待獨立 Plan-Reviewer。 |
| TE-08 | pending | Tester | 依 PR-11 approved 執行 fresh consumer verification。 | 同一 shell 先 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"`，再以 `--scratch-path "$RIVET_CONSUMER_BUILD_PATH"` 執行 consumer test；SwiftLint 前 precheck fixture `.build` 不存在，失敗即 blocker/stop；通過後完整 SwiftLint 與 diff checks。 | 等待 PR-11。 |
| AM-09 | completed | Plan-Creator | 依 human 對 exact fixture cleanup 的明確授權修正 consumer verification workflow。 | 四份 artifacts 一致只允許安全處理 `Tests/GitHubIntegrationConsumer/.build`：存在時先確認 non-symlink directory 與 ignored generated output，才可精確刪除，並驗證不存在；不改 source、fixture、config、API 或 scope。 | Plan-Creator 僅修改四份 topic planning artifacts；未改 source、fixture、config、Git 或 PR。AM-09 取代 AM-08 的 operational revalidation branch，但不改寫 AM-08／PR-11／TE-08 historical records。 |
| PR-12 | pending | Plan-Reviewer | 獨立審查 AM-09。 | 明示 verdict；確認 temporary scratch、exact-path-only cleanup eligibility、absence verification、blocker stop rule、禁止 `.swiftlint.yml` 變更與 fresh route 一致。 | 等待獨立 Plan-Reviewer。 |
| TE-09 | pending | Tester | 依 PR-12 approved 執行 fresh consumer verification。 | 同一 shell 以 task-scoped scratch 執行 consumer test；若 exact fixture `.build` 存在，確認 non-symlink directory 與 ignored generated output 後只刪除該 path；驗證不存在後才完整 SwiftLint/diff checks。eligibility、cleanup 或 absence verification failure 一律 blocker/stop。 | 等待 PR-12。 |

## Blockers

- AM-09 revalidation route 尚未取得 PR-12 independent planning verdict；在此之前不得重新驗證、commit、push 或 resolve 新 threads。

## Human Check

- PR #26 維持 human review boundary；不得自動 merge、release、delete branch 或進行其他整合動作。
- historic DL-02 route 不構成後續 thread-resolution authority。multiline parser 與 consumer threads 只能依 AM-09 revalidation route，在 RV-06 approved 與 human delivery authority 後 resolve。
- 不得 rebase 或 force push；IN-01 只可 non-force merge `origin/dev`，並只 resolve README 的指定 semantic hunk。
- 若任一獨立 reviewer verdict 為 `blocked` 或 `human-check`，停止自動前進並交還 human。

## Last Updated

2026-09-12 — human 授權 AM-09 minimal cleanup：consumer temporary-scratch test 後只可處理 exact ignored generated path `Tests/GitHubIntegrationConsumer/.build`，並須驗證不存在後才執行完整 SwiftLint/diff checks。新的 route 為 `AM-09 → PR-12 → TE-09 → RV-06 → DL-03`；historic verdicts 維持原狀，RV-05 verdict 未記錄，不予推論。
