# GitHub OAuth Token Provider Runtime：Step Ledger

## Current State

- Topic：`github-oauth-token-provider-runtime`
- Branch 建議：`feat/github-oauth-token-provider-runtime`（僅命名建議）
- Current phase：`outcome-review`
- Upstream verdict：iteration 2 Plan-Reviewer `approved`，其後 `implementation-2` completed，Tester `approved`（均經 Dispatcher handoff）；Reviewer 尚未審查。
- Current verdict：`tester-approved-iteration-2`
- Last updated：2026-09-22 — Human 授權 audit-preserving ledger truthfulness correction。iteration 2 的 prior `needs-rework`／pending gate statements 已 superseded：Plan-Reviewer recheck approved → implementation-2 completed → verification-2 Tester approved；等待獨立 Reviewer recheck，不等於 Reviewer 或 human approval。

## Steps

| ID | Status | Owner role | Completion condition | Verification evidence |
| --- | --- | --- | --- | --- |
| `planning-artifacts` | completed | Plan-Creator | 四份同 slug formal artifacts 存在，且記錄 locked scope、API、runtime semantics、allowlist、tests 與 human boundary。 | `requirements.md`、`technical-spec.md`、`.plan.md`、`.step.md` 已建立；未執行 source/test implementation。 |
| `plan-review` | completed-iteration-2 | Plan-Reviewer | 獨立 recheck policy A artifacts，明示 verdict。 | Audit order：iteration 2 policy A ledger truthfulness 的 `needs-rework` 已由 Plan-Creator 修正，該 pending-recheck statement 現為 superseded；既有 upstream Plan-Reviewer recheck verdict：`approved`（經 Dispatcher handoff）。 |
| `implementation` | completed-iteration-1 | Implementer | iteration 1 在當時 approved contract 下完成 allowlist runtime 與 canvas-only rework。 | 歷史 evidence：red/green Swift、static isolation、build、diff 與 canvas evidence 如前；不驗證後續 policy A retry cap、private exhausted `.refresh` 或 no-third-fetch/save。 |
| `verification` | completed-iteration-1 | Tester | iteration 1 完成當時 runtime、root、static isolation、allowlist、diff、dev baseline 與 canvas verification。 | 歷史 Tester `approved`：focused 13/13、root suite 78/11、`StaticIsolationTests` 31/2、expired-demand single-flight 等；不驗證 policy A retry cap、private exhausted `.refresh` 或 no-third-fetch/save。 |
| `implementation-2` | completed | Implementer | 在 iteration 2 Plan-Reviewer recheck `approved` 後，完成 policy A 的最多一次 post-persist retry、第二次 expiry 的 private exhausted `.refresh`，以及每 successful persist 的 version event。 | Actual gate order：Plan-Reviewer recheck `approved` → `implementation-2` completed handoff → `verification-2` Tester `approved`；先前 blocked-by-gate／等待 approval statement 已 superseded。 |
| `verification-2` | completed | Tester | 驗證 policy A：expired-before-publish rotation 最多再 fetch/save 一次、第二次仍 expired 回傳既有 `.refresh` 包 private exhausted error，且沒有第三次 fetch/save。 | Tester verdict：`approved`。focused `OAuthTokenProviderTests` 19/19；full `swift test` 84 tests／11 suites；`StaticIsolationTests` 31/31；consumer 8/8；SwiftLint 0；`git diff --check` 與 cached diff check clean；allowlist 正好六個預期 paths、無 delete/untracked、dev clean。初始 restore 與 unauthorized recovery deterministic tests 均 assert fetch=2/save=2，預留第三個有效結果未被使用；第二次 post-persist expiry 維持既有 `.refresh`/private exhausted error，沒有 public surface change。 |
| `outcome-review` | pending | Reviewer | 收到 current iteration 2 Tester `approved` handoff 後，獨立檢查 policy A implementation、tests、scope、contract 與 documentation evidence。 | iteration 2 Tester `approved` evidence 已在 `verification-2` 記錄；先前「等待 Tester verdict」statement 已 superseded。不得由 Tester verdict 推論 Reviewer approval。 |
| `human-boundary` | pending | Human | 接收 iteration 2 independent Reviewer approved outcome 後決定後續 delivery；不自動 commit、push、PR 或 release。 | iteration 2 Tester 已完成；等待 Reviewer verdict 與 human decision。 |

## Blockers

- iteration 2 Plan-Reviewer recheck gate 已 completed `approved`，且 `implementation-2`／`verification-2` 已依序完成；舊「等待 recheck」blocker 已 superseded。當前 blocker 是獨立 Reviewer recheck。
- `GitHubAccessToken` 是否可 additive conform `Equatable` 的 blocker 已由 Human 選擇 A 解除；僅允許修改 `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift` 以加入此 conformance。
- version 是否在 expired-before-publish rotation 保留 event 的 blocker 已由 Human 選擇 A 解除：每個 accepted 且成功 persist 的 rotation 都保留 version event；本次紀錄不等於新的 Plan Review approval。
- post-persist expiry 的 retry cap 與 terminal mapping blocker 已由 Human 選擇 A 解除：最多再 refresh/persist 一次，第二次仍 expired 時以既有 `.refresh` 包 private exhausted error；不新增 public failure case。

## Iteration 1 Historical Evidence

- 下列 evidence 僅為 iteration 1 historical record，不驗證後續 policy A retry cap、private exhausted `.refresh` 或 no-third-fetch/save。
- Commit hook diagnostics 的 bounded remediation：移除 `TokenSnapshot` 的 explicit synthesized initializer；修正 `OAuthTokenProviderTests` import、換行與 `for-in` gate waiter loops；將 OAuth static isolation test 移至 primary struct 外的 extension，保留全部 source surface、signature、forbidden-marker 與 import assertions，並將檔案壓至 799 行。
- `bun install --frozen-lockfile` 首次因 sandbox 無法建立 ignored `node_modules` 失敗；同一命令升權後成功安裝 9 個依賴。`scripts/check-swift-format.sh`、`scripts/check-github-integration-consumer.sh`、`scripts/check-swiftlint.sh` 與 `surfaces/pr-reader-webview` 的 `bun run check` 均通過；`swift test --filter OAuthTokenProviderTests` 為 13/13，`swift test --filter StaticIsolationTests` 為 31/31。
- 完整 `pre-commit run --all-files` 的升權被安全策略拒絕，因其 fixer 可能寫入 allowlist 外路徑；未將其宣稱為通過，改以四個 non-fixer hook entrypoint 與雙 focused Swift suite 作安全等價驗證。

## Human Check

- iteration 2 Tester 已 completed `approved`；獨立 Reviewer 完成前，不得將 iteration 1 evidence、Tester evidence 或 Implementer evidence 視為 policy A outcome approval。
- 成果審查後，Git delivery、release 與任何超出 allowlist 的行為均須由 human 明示授權。

## Handoff

```json
{
  "topic": "github-oauth-token-provider-runtime",
  "phase": "outcome-review",
  "artifacts": [
    {"path": "analysis/github-oauth-token-provider-runtime/requirements.md", "status": "present"},
    {"path": "analysis/github-oauth-token-provider-runtime/technical-spec.md", "status": "present"},
    {"path": "plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.plan.md", "status": "present"},
    {"path": "plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.step.md", "status": "present"}
  ],
  "current_step": {"id": "outcome-review", "status": "pending"},
  "locked_decisions": [
    "OAuth provider runtime、TokenSnapshot Equatable/hasSameVersion、finite failure contract、injected expiry clock、single-flight、rotation persistence/unavailable state、allowlist 與 human boundary",
    "Human 選擇 A：GitHubAccessToken additive Equatable authorized；TokenSnapshot 保持 GitHubAccessToken field type 與 synthesized Equatable",
    "Human 選擇 A：version 代表每次 accepted 且成功 persist 的 credential rotation；expired-before-publish rotation 不抹去 version event，version 僅作 equality/staleness",
    "Human 選擇 A：post-persist expiry 最多再 refresh/persist 一次；第二次仍 expired 以既有 .refresh 包 private exhausted error 終止，不新增 public failure case",
    "canvas 僅更新 provider status；所有作者文案使用繁體中文，code identifiers 保持原樣"
  ],
  "upstream_verdict": "Plan-Reviewer approved via Dispatcher handoff (iteration 2 policy A recheck); Tester approved via Dispatcher handoff; no Reviewer verdict",
  "blockers": ["independent Reviewer recheck required before human boundary"],
  "assigned_role": "Reviewer",
  "next_objective": "獨立重新檢查 iteration 2 policy A implementation、Tester evidence、scope、contract 與 documentation evidence"
}
```

此 handoff 保留 iteration 1 evidence 為歷史，並以 iteration 2 Plan-Reviewer／Tester approved evidence 路由至獨立 Reviewer；不等於 Reviewer 或 human outcome approval。
