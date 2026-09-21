# GitHub OAuth Token Provider Runtime：Step Ledger

## Current State

- Topic：`github-oauth-token-provider-runtime`
- Branch 建議：`feat/github-oauth-token-provider-runtime`（僅命名建議）
- Current phase：`outcome-review`
- Upstream verdict：Plan-Reviewer `approved` 與最新 Tester `approved`（均經 Dispatcher handoff）；Reviewer 尚未審查。
- Current verdict：`tester-approved`
- Last updated：2026-09-21 — 已記錄最新 Tester `approved` evidence；outcome review 等待獨立 Reviewer recheck，不等於 Reviewer 或 human approval。

## Steps

| ID | Status | Owner role | Completion condition | Verification evidence |
| --- | --- | --- | --- | --- |
| `planning-artifacts` | completed | Plan-Creator | 四份同 slug formal artifacts 存在，且記錄 locked scope、API、runtime semantics、allowlist、tests 與 human boundary。 | `requirements.md`、`technical-spec.md`、`.plan.md`、`.step.md` 已建立；未執行 source/test implementation。 |
| `plan-review` | completed | Plan-Reviewer | 獨立審查四份 artifacts，明示 `approved`、`needs-rework`、`blocked` 或 `human-check`。 | Upstream Plan-Reviewer verdict：`approved`（經 Dispatcher handoff；human 已授權記錄）；此筆不是 Implementer 自行審查。 |
| `implementation` | completed-with-canvas-rework | Implementer | 僅在 `plan-review` 明示 `approved` 後，於 Written/Modify allowlist 實作 provider runtime；若 Tester 回報 canvas-only rework，僅修 canvas contract。 | red：`swift test --filter OAuthTokenProviderTests` 明確因新 API 不存在而編譯失敗。green：同 command 12/12、`swift test --filter StaticIsolationTests` 31/31、`swift build` 通過；`git diff --check` 通過。第一輪 canvas rework：作者文案改為繁體中文（保留 code identifiers），保留 provider 已交付狀態；validate 為 5 bands／15 boxes／16 edges、0 errors／0 warnings，並完成本機 viewer 1440×900 visual check 與主控台 0 errors／0 warnings。第二輪：依 Dispatcher 提供的 Tester 精確 baseline，僅將重建 artifact 的 title `Rivet — GitHub OAuth 雙用戶端架構`、kicker `RIVET — GITHUB OAUTH 雙用戶端架構`、strapline `組裝 → 共享權杖生命週期 → 原工作所有權留在用戶端` 還原；再次 validate 為 0 errors／0 warnings、build 成功。唯讀確認 `.playwright-cli/` 為 `.gitignore` 忽略、沒有 tracked 檔且僅含 Playwright YAML／console evidence 後，精確清除該暫存目錄。 |
| `verification` | completed | Tester | 完成獨立 runtime、root、static isolation、expired-demand single-flight、allowlist、diff、dev baseline 與 canvas evidence 驗證，並明示 verdict。 | Tester verdict：`approved`。focused `OAuthTokenProviderTests` 13/13；root suite 78/11；`StaticIsolationTests` 31/2；gate-based expired-demand single-flight evidence 通過；allowlist、`git diff --check`、dev baseline 與 canvas contract evidence 通過。 |
| `outcome-review` | pending | Reviewer | 收到 Tester `approved` handoff 後，獨立重新檢查 scope、contract、tests 與 documentation evidence。 | 等待 Reviewer recheck；不得由 Tester verdict 推論 Reviewer approval。 |
| `human-boundary` | pending | Human | 接收 approved outcome 後決定後續 delivery；不自動 commit、push、PR 或 release。 | 等待 independent Reviewer verdict 與 human decision。 |

## Blockers

- 無已知 implementation 或 canvas rework blocker。
- `GitHubAccessToken` 是否可 additive conform `Equatable` 的 blocker 已由 Human 選擇 A 解除；僅允許修改 `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift` 以加入此 conformance。

## Hook Remediation Evidence

- Commit hook diagnostics 的 bounded remediation：移除 `TokenSnapshot` 的 explicit synthesized initializer；修正 `OAuthTokenProviderTests` import、換行與 `for-in` gate waiter loops；將 OAuth static isolation test 移至 primary struct 外的 extension，保留全部 source surface、signature、forbidden-marker 與 import assertions，並將檔案壓至 799 行。
- `bun install --frozen-lockfile` 首次因 sandbox 無法建立 ignored `node_modules` 失敗；同一命令升權後成功安裝 9 個依賴。`scripts/check-swift-format.sh`、`scripts/check-github-integration-consumer.sh`、`scripts/check-swiftlint.sh` 與 `surfaces/pr-reader-webview` 的 `bun run check` 均通過；`swift test --filter OAuthTokenProviderTests` 為 13/13，`swift test --filter StaticIsolationTests` 為 31/31。
- 完整 `pre-commit run --all-files` 的升權被安全策略拒絕，因其 fixer 可能寫入 allowlist 外路徑；未將其宣稱為通過，改以四個 non-fixer hook entrypoint 與雙 focused Swift suite 作安全等價驗證。

## Human Check

- Tester 與獨立 Reviewer 完成前，不得將 Implementer evidence 視為 outcome approval。
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
    "canvas 僅更新 provider status；所有作者文案使用繁體中文，code identifiers 保持原樣"
  ],
  "upstream_verdict": "Plan-Reviewer approved via Dispatcher handoff; Tester approved via Dispatcher handoff",
  "blockers": [],
  "assigned_role": "Reviewer",
  "next_objective": "獨立重新檢查 Tester approved evidence、scope、contract、tests 與 documentation evidence"
}
```

此 handoff 記錄 Tester `approved` evidence；不等於 Reviewer 或 human outcome approval。
