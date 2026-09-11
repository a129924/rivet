# GitHub Access Token Failure Contract：Step Ledger

## Current Phase

Delivery pending。PR-01、IM-01、TE-01 與 RV-01 均已完成；下一個 phase 為 DL-01，由 Implementer 依已授權 delivery 條件 commit by topic、push 並開 draft PR。

## Goal

交付單一 `GitHubIntegration` target 的 typed-throws token store/provider contract，並保留既有 shared-module boundary。

## Non-Goal

不實作 Keychain、UI、REST/GraphQL adapter、OAuth 或 lifecycle；不改變 HTTP 或 Domain target。

## In-Scope

四個 credential/store type、兩個 protocol、store-backed provider、single target/product/test target、指定 Contracts/Providers layout、contract tests 與最小 architecture writeback。

## Out-Of-Scope

新的 module/target、Security/Keychain、REST/GraphQL/Apollo、OAuth、refresh、re-auth、401 retry、多帳號、Enterprise、HTTP policy、`async`、cancellation 與 `Sendable`。

## ReadOnly

`RivetHTTPClient`、PR Inbox、PR Reader、所有其他 Domain target/source/tests、既有 HTTP/GraphQL source/tests、architecture diagrams 與既有 BC boundary decisions。

## Written

實作階段僅新增 `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`、`GitHubTokenStore.swift`、`GitHubTokenProvider.swift`、`Providers/TokenStoreGitHubTokenProvider.swift`，以及 `Tests/GitHubIntegrationTests/` 下的 contract/provider tests；planning phase 已寫入四份同 slug artifacts。

## Modify

實作階段僅修改 root `Package.swift`，以及 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md` 的 minimal factual contract writeback。

## Deleted

無；不得刪除、搬移或更名既有檔案。

## TestCase

原樣 token return、`nil` 至 `.missingCredential`、`load()` store error 至保留 operation/underlying error 的 `.tokenStore`、external mock conformance、provider injection/conformance、target isolation、root `swift test` 與 `git diff --check`。

## Ledger

| ID | Status | Owner role | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-01 | completed | Plan-Creator | 建立同 slug 的 requirements、technical spec、plan 與 step artifacts。 | 四份文件均存在，並一致記錄 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Modify、Deleted、TestCase、locked API/layout 與 handoff。 | 僅四份指定 planning artifacts 已寫入 feature worktree；未實作 Swift、執行測試、Git、commit、push 或 PR。 |
| PR-01 | completed | Plan-Reviewer | 獨立審查四份 planning artifacts。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check` verdict；不得以 artifact existence 或 ledger status 代替 verdict。 | 獨立 Plan-Reviewer `/root/review_feature_baseline_plan` verdict `pass`；findings：none。 |
| IM-01 | completed | Implementer | 在 feature worktree 實作 approved contract。 | 只寫入 Written/Modify targets，保留 API、failure mapping、layout、target dependency 及 scope。 | Implementer `/root/implement_token_contract` 已完成；`swift test --filter GitHubTokenProviderTests`：4 passed；root `swift build`：passed；root `swift test`：14 passed；`git diff --check`：passed；dev status：clean。 |
| TE-01 | completed | Tester | 獨立驗證 target、contract、test suite 與 diff hygiene。 | 如實回報 root `swift test`、`git diff --check`、target/import isolation 及任何 blocker。 | Tester `/root/test_token_contract` verdict `pass`；`swift build && swift test` exit 0，14 tests / 5 suites passed；package describe target/layout/dependency isolation passed；diff checks passed；無 Sendable warning/error；no blocker。Revalidation：14 tests、format、SwiftLint、renderer-check、staged diff-check 均 passed；無 unstaged 或 lockfile drift。 |
| RV-01 | completed | Code-Reviewer | 獨立審查實作、驗證 evidence、scope、contract 與 workflow drift。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check` verdict。 | External Code-Reviewer final re-review verdict `pass`；findings：none；staged 13 files exact topic；delivery eligible。 |
| DL-01 | pending | Implementer | 在已授權 delivery 條件下 commit by topic、push 並開 draft PR。 | Reviewer 為 `approved`、無 unresolved blocker、human delivery authority 存在；draft PR target 為 `dev`。 | 等待 RV-01 `approved`。 |

## Blockers

- 無已知 technical blocker。
- DL-01 尚待 Implementer 執行已授權 delivery；完成 draft PR 後進入 human review boundary。

## Human Check

- `DL-01` 的 draft PR 開啟後進入 human review boundary；不得自動 merge、release、delete branch 或進行其他整合動作。
- 若任一獨立 reviewer verdict 為 `blocked` 或 `human-check`，停止自動前進並交還 human。

## Last Updated

2026-09-11 — TE-01 revalidation evidence recorded; RV-01 recorded as `pass`; DL-01 pending delivery execution.
