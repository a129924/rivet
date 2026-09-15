# Plan：GitHub OAuth 雙 Client 架構文件 Topic

## Goal

交付可長期追溯的 GitHub OAuth dual-client architecture documentation，鎖定 shared `OAuthTokenProvider` 與 REST／GraphQL 的 request ownership；不交付 runtime implementation。

## Non-Goal

不實作或修改 OAuth sign-in、PKCE、callback、logout、多帳號、Swift source、client、Apollo、module、package、test、API、Domain／BC contract 或 generic `AuthFlow` runtime。

## In-Scope

- Phase 1：建立四份 planning artifacts，記錄已鎖定的 OAuth lifecycle architecture。
- Phase 2：在 independent Plan Review `approved` 後，建立 long-lived architecture document 與 validated diagrams。
- `GithubIntegration` non-BC shared module、bare `RivetHTTPClient`、layer 外 application composition root、Provider lifecycle、REST／GraphQL consumer boundaries、401 one retry 與 failure classification。
- 保留 v1／v2 lifecycle artifacts 作 immutable rejected evidence、建立 canonical manifest、補強已驗證交付的 v3 lifecycle 的 transient technical-failure terminal outcome，以及不改語意的 canvas colour fix。

## Out-Of-Scope

- initial OAuth sign-in／PKCE／callback、logout／revoke、多帳號、PAT、GitHub Enterprise；OAuth App 或 GitHub App 選擇。
- endpoint／DTO／schema、Domain failure mapping、rate limit、pagination 或一般 retry policy。
- 修改歷史 `github-integration-auth-boundary`；僅在新文件保留 supersession traceability。

## ReadOnly

- **Phase 1**：除四份 listed artifacts 外，全部 repository path ReadOnly。
- **Phase 2**：除 long-lived docs allowlist 外，全部 repository path ReadOnly；Swift runtime、package、tests、BC contracts、`RivetHTTPClient` 與歷史 topic 不得修改。

## Written

### Phase 1

- `analysis/github-oauth-dual-client-architecture/requirements.md`
- `analysis/github-oauth-dual-client-architecture/technical-spec.md`
- `plan/github-oauth-dual-client-architecture/github-oauth-dual-client-architecture.plan.md`
- `plan/github-oauth-dual-client-architecture/github-oauth-dual-client-architecture.step.md`

### Phase 2

僅在 independent Plan Review `approved` 後建立：

- `docs/architecture/github-oauth-dual-client.md`
- `docs/architecture/diagrams/github-oauth-dual-client-architecture/` 內必要的 architecture-canvas 與 archify artifacts。

## Modify

- **Phase 1**：無。
- **Phase 2**：僅可修改 `docs/architecture/README.md` 以新增新文件與圖表導覽。

## Deleted

無。不得刪除任何 repository file、topic、diagram 或歷史記錄。

## Phase 0：Preflight

- **Owner**：Explorer。
- **Input**：獨立 feature worktree、既有 AGENTS.md、README、design principles、architecture README 與相關 GitHubIntegration／RivetHTTPClient documents。
- **Exit**：確認本 topic 在獨立 worktree 進行；若 worktree 或 scope 不符合，停止交還 human。

## Phase 1：Planning Artifacts

- **Owner**：Plan-Creator。
- **Action**：只建立四份 listed artifacts，不寫 long-lived docs 或圖表。
- **Locked content**：
  - layer 外 application composition root Facade 建立唯一共享 Provider，注入 REST 與 GraphQL client，不改 BC 的 `Facade → UseCase → Port`。
  - TokenStore 儲存完整 credential bundle；Fetcher 僅以 bare HTTP refresh；TokenSnapshot 僅是 access token + version。
  - lifecycle precondition 是既有 refreshable credential bundle，不選擇 OAuth App／GitHub App。Provider 擁有 restore、expiry、refresh、rotation、version、single-flight；不持有 request／operation。
  - REST 注入 bare HTTP sender／request executor 與 TokenProvider，並重送自己的 HTTPRequest；GraphQL 以 Apollo retry 自己的 operation；兩者不互相呼叫。
  - stale version 直接取現行 snapshot；same stale version concurrent 401 single-flight refresh；每個原工作最多 retry 一次。
  - 無 credential、permanent refresh failure、second 401 為 authentication-required；僅未接受遠端 rotation 前的 transient technical failure 保留 credential。post-rotation persistence failure 不宣稱舊 bundle 可用並 defer reconciliation；403／權限／資源可見性不 refresh。
  - `RivetHTTPClient` 維持 GitHub-unaware；`Auth`／`AuthFlow` 維持 independent generic declarations-only contract，HTTPClient 不 drive flow。
- **Exit**：四份 artifacts complete，交由獨立 Plan-Reviewer；此階段不得自行判定 approved。

## Phase 1 Gate：Independent Plan Review

- **Owner**：Plan-Reviewer（不得是 Phase 1 Plan-Creator）。
- **Pass criteria**：scope 仍為 documentation-only；architecture contract 一致；ReadOnly／Written／Modify／Deleted 與 allowlist 一致；沒有未鎖定 runtime API；deferred topics 與 historical traceability 明確。
- **Triage**：
  - `approved`：進入 Phase 2。
  - `needs-rework`：只派 Plan-Creator 修 planning artifacts，再重新獨立審查。
  - `blocked` 或 `human-check`：停止並交還 human。

## Phase 2：Long-lived Documentation

- **Owner**：獨立 Implementer；僅在 Plan Review `approved` 後。
- **Action**：
  - 寫入 long-lived docs allowlist。
  - 保留 v1／v2 lifecycle artifacts 作 immutable rejected evidence，在 diagrams allowlist 新增 canonical manifest，將已驗證交付的 v3 lifecycle 指為 canonical artifact。
  - 使用 `architecture-canvas` 建立繁體中文責任／依賴 canvas，不表達 runtime sequence；本輪 canvas 僅作 colour fix，不改 diagram semantics。
  - 使用 `archify` 建立繁體中文 v3 lifecycle：snapshot → Bearer → 401 → provider recovery → one retry／terminal outcome，並補上 transient technical-failure terminal outcome 與 post-rotation persistence failure 的 deferred reconciliation boundary。
  - 兩種圖表均通過對應 skill validation，且不發布 artifact.cafe。
- **Exit**：交由獨立 Reviewer，不進行 Git delivery。

## Final Review and Human Boundary

- **Owner**：Reviewer（不得是 Implementer）。
- **Verification**：changed-path allowlist、`git diff --check`、long-lived wording／diagram semantics、各 skill validation。
- **Stop condition**：Reviewer 通過後交還 human review。未取得 human 明示指示前，不 commit、push、開 PR 或擴張為 runtime topic。

## TestCase

- **TC-01**：Phase 1 僅新增四份 listed artifacts。
- **TC-02**：四份 artifacts 都標示 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify 與 TestCase。
- **TC-03**：artifact contract 維持 `GithubIntegration` non-BC shared module 與 `RivetHTTPClient` generic boundary。
- **TC-04**：artifact contract 維持 Provider／client ownership、single-flight、one retry、permanent／transient distinction、post-rotation persistence failure 的 deferred reconciliation 與 403 no-refresh。
- **TC-05**：independent Plan Review 未 `approved` 前，沒有 `docs/architecture/` 或 diagrams 寫入。
- **TC-06**：Phase 2 保留 v1／v2 作 immutable rejected evidence、加入 canonical manifest 並指認已驗證交付的 v3 canonical lifecycle；v3 包含 transient technical-failure terminal outcome，canvas colour fix 不改語意。
- **TC-07**：Phase 2 僅可寫入 allowlist，圖表經 validation 且不發布 artifact.cafe。
- **TC-08**：每個完成階段執行 `git diff --check`；此 check 由指定驗證角色執行，非 Plan-Creator approval。
