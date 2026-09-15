# GitHub OAuth Dual Client Architecture：Step Ledger

## Goal

以受限、可審查的 documentation-only topic 鎖定 OAuth shared lifecycle architecture，並在 human boundary 前停止於未提交的文件交付。

## Non-Goal

不把本 ledger 視為 runtime implementation、OAuth flow、client、module、package、test、API 或 Git delivery 的授權。

## In-Scope

本 ledger 追蹤 Phase 1 四份 planning artifacts、獨立 Plan Review gate，以及核准後的 long-lived documentation delivery。

## Out-Of-Scope

initial sign-in／PKCE／callback、logout、多帳號、PAT、GitHub Enterprise、Domain adapter／DTO／failure mapping、runtime retries 與任何未鎖定 API。

## ReadOnly

- **Phase 1**：四份 listed artifacts 以外的 repository path 全部 ReadOnly。
- **Phase 2**：long-lived docs allowlist 以外的 repository path 全部 ReadOnly；Swift、package、tests、BC contracts、`RivetHTTPClient` 與歷史 topics 永遠 ReadOnly。

## Written

- Phase 1：四份同 slug planning artifacts。
- Phase 2（只在 PR-01 approved 後）：`docs/architecture/github-oauth-dual-client.md` 與 `docs/architecture/diagrams/github-oauth-dual-client-architecture/`。

## Modify

- Phase 1：無。
- Phase 2（只在 PR-01 approved 後）：`docs/architecture/README.md`。

## Deleted

無刪除授權。

## Ledger

| Step | Owner | Required action | Entry condition | Exit / evidence | Status |
| --- | --- | --- | --- | --- | --- |
| EX-01 | Explorer | 讀取 AGENTS、README、design principles、architecture README 與相關 GitHubIntegration／RivetHTTPClient 文件 | 獨立 feature worktree 可用 | 基線與 historical topic 可追溯 | complete |
| PC-01 | Plan-Creator | 建立四份 planning artifacts | EX-01 complete | 僅四個 Phase 1 paths 寫入；交 PR-01 | complete |
| PR-01 | Independent Plan-Reviewer | 審查 planning artifacts 與 scope／contract readiness | PC-01 complete | 初審 `needs-rework`：requirements 未列出精確 Phase 2 long-lived docs allowlist；PC-02 修正後，re-review verdict `approved`，作為 Phase 2 entry gate | approved |
| PC-02 | Plan-Creator | 只修正 PR-01 指出的 planning drift | PR-01 = needs-rework | 在 requirements 補上精確 Phase 2 allowlist，重新交 PR-01 | complete |
| IM-01 | Independent Implementer | 寫入 approved long-lived docs allowlist 與兩種 diagrams | PR-01 = approved | diagrams validated；交 TE-01／RV-01 | ready |
| TE-01 | Tester | 驗證 allowlist、`git diff --check`、diagram validation evidence | IM-01 complete | pass／fail／exception verdict | blocked by IM-01 |
| RV-01 | Independent Reviewer | 審查 wording、圖表語意、scope 與 workflow drift | TE-01 complete | approved／needs-rework／blocked／human-check verdict | blocked by TE-01 |
| HR-01 | Human | 檢查未提交 documentation diff | RV-01 = approved | human decides commit／push／PR or further work | blocked by RV-01 |

## Locked Contract Checklist

- [x] `GithubIntegration` 是 BC 外 shared GitHub-specific integration module，非 Bounded Context。
- [x] `RivetHTTPClient` 是 generic、GitHub-unaware bare HTTP foundation；`Auth`／`AuthFlow` 不由 HTTPClient runtime drive，亦不承擔 OAuth lifecycle。
- [x] Facade 建立唯一 `OAuthTokenProvider`，並注入 REST 與 GraphQL client。
- [x] TokenStore 僅持有完整 credential bundle；Fetcher 僅用 bare HTTP；TokenSnapshot 僅提供 access token + version。
- [x] Provider 擁有 memory snapshot、restore、expiry、refresh、rotation、version、single-flight；不持有 request／operation。
- [x] REST 保有 HTTPRequest；GraphQL 保有 Apollo operation；各自在 401 recovery 後最多 retry 一次，不互相呼叫。
- [x] stale version 直接得到 current snapshot；相同 stale version concurrent 401 only single-flight refresh。
- [x] no credential、permanent refresh failure、retry 後 second 401 → authentication-required；transient failure 保留 credential → technical failure。
- [x] 403、repository permission、resource visibility 不 refresh。
- [x] `github-integration-auth-boundary` 僅保留 supersession traceability，不可修改。

## TestCase

- **TC-01**：PC-01 的 changed paths 只有四份 artifacts，沒有 runtime／package／tests／BC contracts／long-lived docs。
- **TC-02**：四份 artifacts 都包含 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify、TestCase。
- **TC-03**：PR-01 確認 contract 未把 `GithubIntegration` 變為 BC，未讓 generic HTTPClient／AuthFlow 承擔 OAuth lifecycle。
- **TC-04**：PR-01 確認 shared Provider、snapshot version、single-flight、client-owned one retry、failure distinctions 與 403 no-refresh 一致。
- **TC-05**：IM-01 只在 PR-01 `approved` 後發生，且 changed paths 限 allowlist。
- **TC-06**：TE-01 確認 architecture-canvas／archify 使用繁體中文、分別通過 validation，且沒有 artifact.cafe publication。
- **TC-07**：RV-01 通過後停止於 HR-01；未經 human 授權不 commit、push 或開 PR。
