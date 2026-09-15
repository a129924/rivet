# GitHub OAuth Dual Client Architecture：需求

## Goal

建立可審查的長期架構文件依據，鎖定已存在且可 refresh 的 GitHub OAuth credential bundle 的 shared token lifecycle：同一個 `OAuthTokenProvider` 供 GitHub REST 與 Apollo GraphQL client 共用，使兩者在 access token 過期或收到一次 401 時，安全取得新版 snapshot 並各自重送原工作一次。

本 topic 是 **documentation-only architecture topic**。它不交付可執行 OAuth、client 或 token lifecycle。

## Non-Goal

- 初次 OAuth sign-in、authorization code + PKCE、callback、logout、revoke、多帳號、PAT、GitHub Enterprise 或跨裝置同步。
- Swift runtime、OAuth flow、REST／GraphQL client、Apollo interceptor、module、package、test、API、Domain Port 或 BC failure contract。
- 修改既有 generic `AuthRequester`／`Auth`／`AuthFlow` runtime。
- 改寫或刪除歷史 `github-integration-auth-boundary` topic。

## In-Scope

- 記錄 `GithubIntegration` 為 BC 外 shared GitHub-specific integration module，不建立或重建為 Bounded Context。
- 記錄 layer 外的 application composition root Facade：建立 bare `RivetHTTPClient`／`URLSessionTransport`、`KeychainTokenStore`、`OAuthTokenFetcher`、唯一共享的 `OAuthTokenProvider`，並注入 GitHub REST client 與 GraphQL client；這不改變各 BC 的 `Facade → UseCase → Port` 層級方向。
- 記錄 TokenStore、Fetcher、Provider、TokenSnapshot、REST request 與 Apollo operation 的責任與所有權。
- 記錄 REST client 取得 bare HTTP sender／request executor 與 TokenProvider；它保有並重送自己的 request。
- 記錄 snapshot version、restore、expiry、rotation、single-flight、一次 401 retry 與 permanent／transient failure boundary；transient technical failure 的「保留 credential」僅適用於尚未接受遠端 rotation 的失敗。遠端 rotation 已接受後的本地 persistence failure 不宣稱舊 bundle 仍可用，reconciliation 留待後續 topic。
- 記錄 REST 與 GraphQL 不互相呼叫；GraphQL 不經 REST route；Provider 不持有、不接收或重送 request／operation。
- 保留 v1／v2 lifecycle artifacts 作 immutable rejected evidence，並新增 canonical manifest 指出已驗證交付的 v3 為本 topic 的 canonical lifecycle；v3 補上 transient technical-failure terminal outcome。責任／依賴 canvas 僅修正 colour，不改變責任、依賴或 runtime-sequence boundary。
- 建立本 topic 的四份 planning artifacts；經獨立 Plan Review 核准後，才可交付 long-lived docs 與圖表。

## Out-Of-Scope

- GitHub endpoint／DTO、GraphQL schema、PR Inbox／PR Reader adapter、Domain failure mapping、rate limit、pagination 或一般 retry policy。
- Keychain service/account identity、entitlement 與首次 credential 寫入流程；OAuth App 與 GitHub App 的選擇。
- 403 以外的 status policy；403、repository permission 與 resource visibility 均不視為 token 失效。
- 任何 runtime API signature、型別實作、failure representation 或 package/source-path 決定。

## ReadOnly

### Phase 1

除本 topic 的四份 planning artifacts 外，全部 repository path 為 ReadOnly，尤其是 Swift runtime、package manifest、tests、BC contracts、`docs/architecture/`、既有 diagrams 與歷史 topics。

### Phase 2

除已核准的 long-lived docs allowlist 外，全部 repository path 為 ReadOnly；`RivetHTTPClient`、所有 Swift source、package、tests、BC documents 與 `github-integration-auth-boundary` topic 均不得修改。

## Written

Phase 1 只建立：

- `analysis/github-oauth-dual-client-architecture/requirements.md`
- `analysis/github-oauth-dual-client-architecture/technical-spec.md`
- `plan/github-oauth-dual-client-architecture/github-oauth-dual-client-architecture.plan.md`
- `plan/github-oauth-dual-client-architecture/github-oauth-dual-client-architecture.step.md`

Phase 2 僅在 independent Plan Review 明示 `approved` 後，才可寫入下列 long-lived docs allowlist：

- `docs/architecture/github-oauth-dual-client.md`
- `docs/architecture/README.md`
- `docs/architecture/diagrams/github-oauth-dual-client-architecture/`

## Modify

- Phase 1：無。
- Phase 2：只有 independent Plan Review `approved` 後，得修改 `docs/architecture/README.md` 作為新 architecture document 與 diagrams 的導覽；不得改寫既有 architecture contract。

## Deleted

無。不得刪除任何檔案、topic、diagram 或歷史記錄。

## Supersession Traceability

`github-integration-auth-boundary` 記錄的 PAT-only、REST-only authorizer direction 已由本 topic 的 OAuth dual-client lifecycle 取代。舊 topic 保留為歷史依據；本 topic 不回寫、改寫或刪除它。

## Acceptance Criteria

1. 四份 artifacts 使用相同 slug，並一致標明 documentation-only scope 與 ReadOnly boundary。
2. 四份 artifacts 一致說明 `GithubIntegration` non-BC shared module、raw／OAuth-unaware generic `RivetHTTPClient`，以及 internal `AuthRequester` 以 injected `Requester` 與 caller `Auth` 建立並驅動 generic `send → execute → receive` flow 的 boundary；Auth decision 屬 flow，不屬 GitHub OAuth lifecycle。
3. 四份 artifacts 一致說明 shared provider、client-owned retry、snapshot version 與 single-flight。
4. 四份 artifacts 一致限制 credential precondition 為既有 refreshable bundle，不選擇 OAuth App 或 GitHub App。
5. v1／v2 lifecycle artifacts 保留為 immutable rejected evidence，canonical manifest 指出已驗證交付的 v3 為 canonical lifecycle；v3 明確補上 transient technical-failure outcome；post-rotation persistence failure 不宣稱舊 bundle 可用。
6. Phase 1 沒有 long-lived docs、圖表、Swift、package、test、API 或 BC contract 寫入。
7. Phase 2 的任何寫入以前，必須有 independent Plan Review 的明示 `approved` verdict。

## TestCase

- **TC-01**：Phase 1 changed paths 精確限於四份指定 artifacts。
- **TC-02**：文件明示 runtime、package、tests、BC contracts 與長期 architecture docs 在 Phase 1 為 ReadOnly。
- **TC-03**：文件明示 Facade 注入同一 provider；REST 與 GraphQL 不互相呼叫，Provider 不擁有 request／operation。
- **TC-04**：文件明示同版本 concurrent 401 single-flight、每個原工作最多 retry 一次，403 不 refresh。
- **TC-05**：文件區分 authentication-required（無 credential、permanent refresh failure、第二次 401）與 transient technical failure；僅 pre-rotation technical failure 保留 credential，post-rotation persistence failure defer reconciliation 且不宣稱舊 bundle 可用。
- **TC-06**：文件明示 application composition root 不改變 BC 的 `Facade → UseCase → Port`，REST client 依賴 bare HTTP sender／request executor 與 TokenProvider。
- **TC-07**：v1／v2 lifecycle artifacts 保留為 immutable rejected evidence；canonical manifest 指出已驗證交付的 v3 為 canonical lifecycle，且 v3 包含 transient technical-failure terminal outcome；canvas colour 修正不改變語意。
- **TC-08**：Plan Review 未核准時，不建立 long-lived docs 或任何正式 canvas／lifecycle artifact。
