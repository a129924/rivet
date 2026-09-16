# GitHub OAuth Token Schema：Step Ledger

## Current Phase

plan-review。PC-01 僅建立本 topic planning artifacts；尚未進入 Swift implementation。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | Plan-Creator | completed | 建立同 slug 的 requirements、technical spec、plan 與 step ledger。 | 四份文件一致鎖定 GitHub OAuth App internal DTO → immutable `Sendable` bundle、fixture constants、ReadOnly/Written/Modify/Deleted、non-goals 與 role-separated gates。 | 四份 `github-oauth-token-schema` planning artifacts。 |
| PR-01 | Plan-Reviewer | pending | 獨立審查 planning artifacts 的 scope、technical contract、path allowlist、test plan 與 workflow gates。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；只有 `approved` 可前進 IM-01。 | 待獨立 Plan-Reviewer verdict。 |
| IM-01 | Implementer | pending | 僅於 PR-01 approved 後，在 feature worktree 實作 bounded schema slice。 | 只新增 DTO/bundle source 與 focused tests，並只修改 static isolation、public consumer、architecture writeback；無 PAT/runtime/store/Keychain/client/retry/migration drift。 | 待 Implementer report。 |
| TE-01 | Tester | pending | 獨立驗證 IM-01 snapshot。 | Focused tests、root `swift test`、consumer fixture、static isolation、`git diff --check` 通過；fixture tokens 不出現在 test output。 | 待 Tester verdict。 |
| RV-01 | Reviewer | pending | 獨立審查 code、docs、changed paths 與 verification evidence。 | 明示 verdict；確認 DTO internal、bundle/public values Sendable、six-field contract/fixtures/expiry mapping 無 drift，且 ReadOnly paths 未被改動。 | 待 Reviewer verdict。 |
| DL-01 | Implementer | pending | 僅在 RV-01 approved、無 blocker 與 human delivery authority 後，依 topic commit、non-force push 並開 draft PR。 | 單一 topic commit、remote branch verified、draft PR 已開；不 rebase、force push、merge、release 或處理未授權 comment。 | 待 delivery record。 |
| HC-01 | Human | pending | Review draft PR。 | Human 明確接受、要求修正或停止。 | 待 human decision。 |

## Blockers

- PR-01 非 approved 時，不得實作或測試 implementation snapshot。
- 任一角色發現 PAT、credential union、OAuth request/refresh runtime、TokenStore/provider implementation、Keychain、client、retry、migration、GHES fallback、non-expiring credential 或 ReadOnly-path drift，必須回報 `needs-rework`／`blocked`，不得自行擴張。
- `GitHubOAuthTokenResponse` 若需公開可見、或既有 access-token contract 不再是 `Sendable`，停止並交還 human；不得以改寫既有 contract 迴避。
- DL-01 前必須有獨立 Tester 與 Reviewer 的最新合格 verdict；historic verdict 不得替代本 topic verdict。

## Human Check

- issuer 已鎖定為 GitHub OAuth App；不重開為 GitHub App user access token。
- public bundle 僅代表可 refresh、會過期 credential；future refresh 成功以完整 bundle 原子取代舊 bundle。本 topic 不實作 future lifecycle。
- draft PR 開啟即到 human review boundary；不得自動 merge、release、刪 branch、rebase、force push 或處理 code-review comments。
- 若 reviewer 給出 `blocked`、`human-check`、scope drift、contract drift 或 workflow drift，停止自動前進並交還 human。

## Last Updated

2026-09-16 — PC-01 建立 planning contract；等待獨立 PR-01。
