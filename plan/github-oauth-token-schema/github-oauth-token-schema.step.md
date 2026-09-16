# GitHub OAuth Token Schema：Step Ledger

## Current Phase

pr-comment-review-and-fix；FR-01 已給出現況 `approved`，且 human 已接受 workflow-reconciliation 紀錄。原始 `PR-01` 未留下 independent verdict，然而 implementation 與 delivery 已於該 gate 前發生。不得回填或推定歷史 approval、verification verdict，亦不得將此偏差視為自動放行。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | Plan-Creator | completed | 建立同 slug 的 requirements、technical spec、plan 與 step ledger。 | 四份文件一致鎖定 GitHub OAuth App internal DTO → immutable `Sendable` bundle、fixture constants、ReadOnly/Written/Modify/Deleted、non-goals 與 role-separated gates。 | 四份 `github-oauth-token-schema` planning artifacts。 |
| PR-01 | Plan-Reviewer | not-run | 原始 gate：獨立審查 planning artifacts 的 scope、technical contract、path allowlist、test plan 與 workflow gates。 | 明示 `approved`、`needs-rework`、`blocked` 或 `human-check`；原始 workflow 僅允許 `approved` 後前進 IM-01。 | 沒有 recorded independent verdict；不得事後回填。 |
| IM-01 | Implementer | performed-out-of-order | 在 feature worktree 實作 bounded schema slice。 | 實際 snapshot 僅新增 DTO/bundle source 與 focused tests，並只修改 static isolation、public consumer、architecture writeback；其發生順序違反原始 PR-01 prerequisite，不能標示 completed。 | commit `06eda57` 的 9-file snapshot；原始 PR-01 是 `not-run`。 |
| TE-01 | Tester | evidence-not-recorded | 獨立驗證 IM-01 snapshot。 | Focused tests、root `swift test`、consumer fixture、static isolation、`git diff --check` 通過，且 fixture tokens 不出現在 test output。未有可在本 ledger 引用的獨立 verdict，故不得視為已完成。 | 待 fresh verification evidence。 |
| RV-01 | Reviewer | needs-rework | 獨立審查 code、docs、changed paths 與 verification evidence。 | 明示 verdict；確認 DTO internal、bundle/public values Sendable、six-field contract/fixtures/expiry mapping 無 drift，且 ReadOnly paths 未被改動。 | PR #35 ledger workflow comments：`discussion_r4023671208`、`discussion_r4023708744`。 |
| DL-01 | Implementer | performed-out-of-order | 依 topic commit、non-force push 並開 draft PR。 | 既有 delivery 已發生，但原始 prerequisite 未滿足，因此不得標示為 contract-complete 或視為放行。 | commit `06eda57`、remote `feat/github-oauth-token-schema`、PR #35（目前 ready for review）。 |
| FR-01 | Plan-Reviewer | approved | Fresh independent review：審查 planning contract、ledger 偏差紀錄與既有 snapshot 的 scope/path consistency。 | 明示現況 `approved`、`needs-rework`、`blocked` 或 `human-check`。不得 retroactively approve PR-01、補造 Tester/Reviewer evidence，或自動放行 delivery。 | 2026-09-16 fresh independent Plan-Reviewer verdict：`approved`；此為現況 verdict，非 PR-01 的歷史 approval。 |
| HC-01 | Human | accepted | 在 FR-01 verdict 後決定 PR #35 的後續處置。 | Human 明確接受、要求修正或停止。 | 2026-09-16 human 明確確認接受 workflow-reconciliation 紀錄；此 acceptance 不回填 PR-01，亦不取代後續獨立 verification/review evidence。 |

## Blockers

- 原始 PR-01 未執行，既有 implementation/delivery snapshot 是已記錄的 workflow deviation；FR-01 不得追溯放行 PR-01，也不得把歷史 snapshot 重新標示為依序完成。
- FR-01 與 HC-01 已完成本次 reconciliation gate；僅可進入既有、獨立角色執行的 review-comment fix workflow，不得將此視為 PR-01 的歷史放行或 PR delivery contract-complete。
- 任一角色發現 PAT、credential union、OAuth request/refresh runtime、TokenStore/provider implementation、Keychain、client、retry、migration、GHES fallback、non-expiring credential 或 ReadOnly-path drift，必須回報 `needs-rework`／`blocked`，不得自行擴張。
- `GitHubOAuthTokenResponse` 若需公開可見、或既有 access-token contract 不再是 `Sendable`，停止並交還 human；不得以改寫既有 contract 迴避。
- 所有 future verification 必須有可追溯的獨立 evidence；historic 或未記錄的 verdict 不得替代 FR-01 與 HC-01。

## Human Check

- issuer 已鎖定為 GitHub OAuth App；不重開為 GitHub App user access token。
- public bundle 僅代表可 refresh、會過期 credential；future refresh 成功以完整 bundle 原子取代舊 bundle。本 topic 不實作 future lifecycle。
- human 已接受 workflow-reconciliation 紀錄；後續僅依既有獨立角色與 review-comment fix gate 推進，不得自動 merge、release、刪 branch、rebase 或 force push。
- 若 reviewer 給出 `blocked`、`human-check`、scope drift、contract drift 或 workflow drift，停止自動前進並交還 human。

## Last Updated

2026-09-16 — 原始 PR-01 未執行即產生 commit `06eda57` 與 PR #35；FR-01 已以現況 `approved` 完成 fresh independent review，human 已接受 workflow-reconciliation 紀錄。PR-01 維持 `not-run`，後續可進入既有 review-comment fix gate。
