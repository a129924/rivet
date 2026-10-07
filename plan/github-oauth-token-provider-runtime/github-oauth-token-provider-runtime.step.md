# GitHub OAuth Token Provider Runtime：Step Ledger

## Current State

- Topic：`github-oauth-token-provider-runtime`
- Branch 建議：`feat/github-oauth-token-provider-runtime`（僅命名建議）
- Current phase：`human-boundary`
- Upstream verdict：iteration 2 Plan-Reviewer `approved` → `implementation-2` completed → Tester `approved`；2026-10-05 本次獨立 Reviewer recheck `approved`（經 Dispatcher handoff）。
- Current verdict：`approved`
- Human decision：2026-10-05「接受並繼續」。
- Last updated：2026-10-07 — 在 GraphQL feature worktree 保存本次 Reviewer／Human acceptance；不倒填歷史 approval，不新增 test execution evidence。原2026-09-22 correction與pending Reviewer狀態保留為下方歷史紀錄。

## Steps

| ID | Status | Owner role | Completion condition | Verification evidence |
| --- | --- | --- | --- | --- |
| `planning-artifacts` | completed | Plan-Creator | 四份同 slug formal artifacts 存在，且記錄 locked scope、API、runtime semantics、allowlist、tests 與 human boundary。 | `requirements.md`、`technical-spec.md`、`.plan.md`、`.step.md` 已建立；未執行 source/test implementation。 |
| `plan-review` | completed-iteration-2 | Plan-Reviewer | 獨立 recheck policy A artifacts，明示 verdict。 | Audit order：iteration 2 policy A ledger truthfulness 的 `needs-rework` 已由 Plan-Creator 修正，該 pending-recheck statement 現為 superseded；既有 upstream Plan-Reviewer recheck verdict：`approved`（經 Dispatcher handoff）。 |
| `implementation` | completed-iteration-1 | Implementer | iteration 1 在當時 approved contract 下完成 allowlist runtime 與 canvas-only rework。 | 歷史 evidence：red/green Swift、static isolation、build、diff 與 canvas evidence 如前；不驗證後續 policy A retry cap、private exhausted `.refresh` 或 no-third-fetch/save。 |
| `verification` | completed-iteration-1 | Tester | iteration 1 完成當時 runtime、root、static isolation、allowlist、diff、dev baseline 與 canvas verification。 | 歷史 Tester `approved`：focused 13/13、root suite 78/11、`StaticIsolationTests` 31/2、expired-demand single-flight 等；不驗證 policy A retry cap、private exhausted `.refresh` 或 no-third-fetch/save。 |
| `implementation-2` | completed | Implementer | 在 iteration 2 Plan-Reviewer recheck `approved` 後，完成 policy A 的最多一次 post-persist retry、第二次 expiry 的 private exhausted `.refresh`，以及每 successful persist 的 version event。 | Actual gate order：Plan-Reviewer recheck `approved` → `implementation-2` completed handoff → `verification-2` Tester `approved`；先前 blocked-by-gate／等待 approval statement 已 superseded。 |
| `verification-2` | completed | Tester | 驗證 policy A：expired-before-publish rotation 最多再 fetch/save 一次、第二次仍 expired 回傳既有 `.refresh` 包 private exhausted error，且沒有第三次 fetch/save。 | Tester verdict：`approved`。focused `OAuthTokenProviderTests` 19/19；full `swift test` 84 tests／11 suites；`StaticIsolationTests` 31/31；consumer 8/8；SwiftLint 0；`git diff --check` 與 cached diff check clean；allowlist 正好六個預期 paths、無 delete/untracked、dev clean。初始 restore 與 unauthorized recovery deterministic tests 均 assert fetch=2/save=2，預留第三個有效結果未被使用；第二次 post-persist expiry 維持既有 `.refresh`/private exhausted error，沒有 public surface change。 |
| `outcome-review` | completed | Reviewer | 在 iteration 2 Tester evidence基礎上獨立檢查policy A implementation、tests、scope、contract與documentation，明示verdict。 | 2026-10-05 本次獨立Reviewer recheck：approved、無code blocker（經Dispatcher handoff）；未重新執行測試，verification-2保留歷史來源。 |
| `human-boundary` | completed | Human | 接收本次獨立Reviewer approved後決定是否接受runtime並允許後續規劃。 | 2026-10-05 Human選擇「接受並繼續」；不是倒填先前approval，不等於自動merge／release授權。 |

## Blockers

- iteration 2 Plan-Reviewer／implementation／Tester紀錄保留；原「等待獨立Reviewer」blocker已由2026-10-05本次approved recheck解除，Human acceptance已完成；無已知runtime code blocker。
- `GitHubAccessToken` 是否可 additive conform `Equatable` 的 blocker 已由 Human 選擇 A 解除；僅允許修改 `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift` 以加入此 conformance。
- version 是否在 expired-before-publish rotation 保留 event 的 blocker 已由 Human 選擇 A 解除：每個 accepted 且成功 persist 的 rotation 都保留 version event；本次紀錄不等於新的 Plan Review approval。
- post-persist expiry 的 retry cap 與 terminal mapping blocker 已由 Human 選擇 A 解除：最多再 refresh/persist 一次，第二次仍 expired 時以既有 `.refresh` 包 private exhausted error；不新增 public failure case。

## Iteration 1 Historical Evidence

- 下列 evidence 僅為 iteration 1 historical record，不驗證後續 policy A retry cap、private exhausted `.refresh` 或 no-third-fetch/save。
- Commit hook diagnostics 的 bounded remediation：移除 `TokenSnapshot` 的 explicit synthesized initializer；修正 `OAuthTokenProviderTests` import、換行與 `for-in` gate waiter loops；將 OAuth static isolation test 移至 primary struct 外的 extension，保留全部 source surface、signature、forbidden-marker 與 import assertions，並將檔案壓至 799 行。
- `bun install --frozen-lockfile` 首次因 sandbox 無法建立 ignored `node_modules` 失敗；同一命令升權後成功安裝 9 個依賴。`scripts/check-swift-format.sh`、`scripts/check-github-integration-consumer.sh`、`scripts/check-swiftlint.sh` 與 `surfaces/pr-reader-webview` 的 `bun run check` 均通過；`swift test --filter OAuthTokenProviderTests` 為 13/13，`swift test --filter StaticIsolationTests` 為 31/31。
- 完整 `pre-commit run --all-files` 的升權被安全策略拒絕，因其 fixer 可能寫入 allowlist 外路徑；未將其宣稱為通過，改以四個 non-fixer hook entrypoint 與雙 focused Swift suite 作安全等價驗證。

## 本次Acceptance與歷史狀態

- 原2026-09-22 correction只記iteration 2 Plan-Reviewer approved → implementation-2 completed → Tester approved，當時Reviewer／Human pending；本次不把當時pending倒填為已通過。
- 2026-10-05本次獨立Reviewer明示approved，Human「接受並繼續」；本次沒有新跑測試，歷史iteration 1／2 evidence不更名或重算。
- 2026-10-07 Human另選GraphQL topic為internal foundation，跨target使用deferred；這是GraphQL Goal／AC收斂，不改本provider契約或policy。

## Human Check

- 本次Reviewer approved與Human acceptance已完成，不再派遣provider review；既有Tester／Implementer evidence仍不單獨構成approval。
- GraphQL topic的最新條件式commit／push／DraftPR授權與各formal gate另記其ledger，不由本provider終態紀錄產生自動dispatch；merge／release不自動進行。

## Handoff

```json
{
  "topic": "github-oauth-token-provider-runtime",
  "phase": "human-boundary",
  "artifacts": [
    {"path": "analysis/github-oauth-token-provider-runtime/requirements.md", "status": "present"},
    {"path": "analysis/github-oauth-token-provider-runtime/technical-spec.md", "status": "present"},
    {"path": "plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.plan.md", "status": "present"},
    {"path": "plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.step.md", "status": "present"}
  ],
  "current_step": {"id": "human-boundary", "status": "completed"},
  "locked_decisions": [
    "OAuth provider runtime、TokenSnapshot Equatable/hasSameVersion、finite failure contract、injected expiry clock、single-flight、rotation persistence/unavailable state、allowlist 與 human boundary",
    "Human 選擇 A：GitHubAccessToken additive Equatable authorized；TokenSnapshot 保持 GitHubAccessToken field type 與 synthesized Equatable",
    "Human 選擇 A：version 代表每次 accepted 且成功 persist 的 credential rotation；expired-before-publish rotation 不抹去 version event，version 僅作 equality/staleness",
    "Human 選擇 A：post-persist expiry 最多再 refresh/persist 一次；第二次仍 expired 以既有 .refresh 包 private exhausted error 終止，不新增 public failure case",
    "canvas 僅更新 provider status；所有作者文案使用繁體中文，code identifiers 保持原樣"
  ],
  "upstream_verdict": "approved",
  "blockers": [],
  "assigned_role": null,
  "next_objective": "已接受成果的終態紀錄；無待執行provider review，不產生自動派遣。"
}
```

本段是已接受成果的終態紀錄；assigned_role明確允許null，表示沒有待派遣agent，不作為dispatch handoff。保留iteration 1／2 historical evidence；2026-10-05本次Reviewer approved與Human decision為新增紀錄，不倒填歷史gate。
