# GitHub Integration Authorization Boundary：計畫

## Goal

在不改變任何 Swift 實作的前提下，鎖定 GitHub Integration 擁有 future authorization seam：由 Integration future `GitHubTokenProvider` 交付 `GitHubAccessToken`，並在每個 GitHub REST request 交給 `RivetHTTPClient` 前注入或覆寫 Bearer `Authorization`；GraphQL 維持 Apollo-only route，不套用此 flow。

## Non-Goal

不建立任何 Swift source、module、package、target、protocol、Keychain item 或 executable auth behavior；不實作 OAuth、refresh、401 retry、Keychain adapter、URLSession transport、DTO、GitHub API adapter 或 core Port failure mapping。

## In-Scope

- 初版 credential 為使用者預先提供的一個 fine-grained PAT。
- 鎖定 declaration-only future direction：GitHub Integration 內的 `GitHubTokenProvider` 負責 token delivery，並交付 Integration-owned `GitHubAccessToken`。其具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 延後至獨立 failure-contract topic；本 topic 不預先選擇任何 failure representation。
- GitHub Integration future authorizer 為每個 GitHub REST request 設定或覆寫 `Authorization: Bearer …`；`GitHubGraphQLAdapter` → `ApolloClient` 不經 authorizer → `RivetHTTPClient` flow。
- 鎖定 Archify lifecycle 的 renderer locale limitation：正式支援僅 `en` 與 `zh-CN`；因作者內容為繁體中文，source JSON 省略 `meta.locale`，Viewer UI 與 generated HTML language attribute 依 renderer fallback 維持英文。這不是將繁體中文錯標為 `zh-CN` 的授權。
- 已發生的 review-audit planning correction 已經獨立 PR-05 Plan-Reviewer `approved`；該 verdict 僅接受 correction 的 workflow／provenance，不重開既有 architecture、path 或 contract decision，亦不改變 HR-03 與 HR-04 各自獨立 pending 的狀態。
- 兩個 canvas review fixes 已經獨立 PR-06 Plan-Reviewer `approved`：恢復 `Transport → Foundation URLSession／GitHub.com API` 的 compile-time／ownership edge；並讓 `adapter → client` 的 route 與 label 繞過 token-provider／authorizer，避免被誤讀為 runtime flow。canvas 仍只表達 ownership／compile-time boundary。
- 獨立 Tester 已完成 TE-05：兩個 canvas-only review fixes 的 validator／build／enhance／accessibility、source/build byte identity、syntax、diff 與 artifact-local containment checks 均通過。browser CLI 的 fresh viewport 兩次逾時，未形成 browser evidence，且不得宣稱為 browser pass；這不影響 artifact-local containment TestCase。獨立 RV-05 已 `approved`；canvas delivery 已由 commit `7f6f9fa` 提交。IM-05 的未提交敘述只保留為 delivery 前的 historical evidence，不得誤稱 current uncommitted；HR-05 仍是 pending，且不得取代 HR-03 或 HR-04 各自獨立 pending 的 human gate。既有 GitHub Integration BC、architecture navigation 與 lifecycle artifact 的交付範圍不因本輪 canvas-only fix 而重開。
- PR #17 本輪 bounded remediation 僅補齊 RV-05 後的可稽核 delivery gate，並限縮 BC wording：只有 `GitHubRESTAdapter` 的 request 經 authorizer 後使用 `RivetHTTPClient`；`GitHubGraphQLAdapter` 封裝 `ApolloClient`、不經 `RivetHTTPClient.Transport`，Apollo token interceptor 留待獨立 topic。此 correction 不改變 Integration-owned PAT、deferred concrete signature／failure／refresh／re-auth 或 locale fallback 的既定決策。

## Out-Of-Scope

- generic `TokenProvider`、`RivetHTTPClient` token dependency、constructor 變更或 HTTP package auth API。
- `GitHubTokenProvider` 的具體 Swift signature、`throws`／`Outcome` 選擇，或 credential failure、refresh／re-auth contract。
- OAuth-shaped token payload 的採用、refresh token、401 retry、多帳號、GitHub Enterprise、PAT UI、Keychain identity／adapter。
- concrete network、HTTP status／decode policy、DTO、PR Inbox／PR Reader mapping，以及 core failure mapping。
- 直接手改 generated lifecycle HTML 或 visual-check sidecar、設定 `meta.locale: "zh-CN"`、為 language thread 重新 deliver lifecycle artifact，或變更 architecture-canvas 的獨立 language handling。
- 將 canvas 擴張成 runtime sequence、token-delivery／failure contract，或改變 deferred signature、PAT-only 與 locale fallback 的既定結論。
- 將 REST authorizer 套用到 GraphQL／Apollo、建立或選擇 Apollo token interceptor 的具體 contract，或改變 Apollo 不經 `RivetHTTPClient.Transport` 的既定 boundary。

## ReadOnly

以下限制只適用於 **Tester 與 Reviewer 的驗證／審查階段**；該兩個角色對列出的 targets 僅讀，不得以驗證或審查名義修改。

- `README.md`、`docs/design-principles.md`、`docs/architecture/README.md` 與既有 Bounded Context 文件。
- `packages/RivetHTTPClient/` 的 source、tests、manifest 與 HTTP package structure canvas。
- root package、product source surface、既有 HTTP topics 與 core BC contracts。

## Written

- `analysis/github-integration-auth-boundary/requirements.md`
- `analysis/github-integration-auth-boundary/technical-spec.md`
- `plan/github-integration-auth-boundary/github-integration-auth-boundary.plan.md`
- `plan/github-integration-auth-boundary/github-integration-auth-boundary.step.md`

## Deleted

由後續 Implementer 在 final docs／diagram delivery 前移除兩組非交付 generated candidate：

- `docs/architecture/diagrams/github-integration-http-client-boundary/github-authorization-lifecycle.containment-candidate*`
- `docs/architecture/diagrams/github-integration-http-client-boundary/github-authorization-lifecycle.containment-candidate-2*`

本 Plan-Creator remediation 不執行刪除。

## Modify

以下清單只授權 **Implementer 在其實作／交付階段** 修改；它不與 ReadOnly 衝突，因為後者不適用於 Implementer 的實作階段。除下列清單與其明列的 canonical artifact 外，Implementer 不得擴張修改範圍。依本輪 human 明示授權，Plan-Creator 只可先在 feature worktree 提出下列 BC wording 的受限 correction；該草稿不構成 delivery，仍須經 PR-07、IM-06、PR-08、TE-06、RV-06 與 DL-01。

- 後續 Implementer 修改 `docs/architecture/bounded-contexts/github-integration.md`：加入 authorization ownership、PAT-only limitation、Keychain Outside 與 core Port isolation。
- 後續 Implementer 修改 `docs/architecture/README.md`：連結 declaration-only lifecycle artifact，並描述其限制。
- 後續 Implementer 修改 `docs/architecture/diagrams/github-integration-http-client-boundary/scene.js`：區分 future Integration abstractions 與既有 HTTP package，且維持其 non-runtime-boundary purpose。
- 後續 Implementer 交付唯一允許的 canonical lifecycle source、HTML 與 canonical visual-check evidence：`github-authorization-lifecycle.json`、`github-authorization-lifecycle.html`、`github-authorization-lifecycle.visual-check.*`；不得將 containment candidate 納入交付。
- language thread 的唯一後續 delivery 是後續 Implementer 修改 lifecycle artifact-local `BUILD.md`，明示 Archify 僅正式支援 `en`／`zh-CN`、繁體中文作者內容必須省略 `meta.locale`，以及 Viewer UI／generated HTML 回退英文；不修改 lifecycle JSON、generated HTML、receipt 或 visual evidence，亦不重新 deliver。
- 本輪 canvas-only Implementer delivery 已僅修改 `docs/architecture/diagrams/github-integration-http-client-boundary/scene.js` 與由 artifact-local build 產生的 `index.html`：恢復 `Transport → Foundation URLSession／GitHub.com API` 的 compile-time／ownership edge，並將 `adapter → client` route／label 保持在 token-provider／authorizer 外側；canvas delivery 已由 commit `7f6f9fa` 提交。不得新增 runtime sequence edge 或更動其他 target。
- 本輪 REST／GraphQL wording correction 的正式 delivery 僅可修改 `docs/architecture/bounded-contexts/github-integration.md`：限縮 authorizer → `RivetHTTPClient` 為 `GitHubRESTAdapter` request，明列 `GitHubGraphQLAdapter` → `ApolloClient` 不經 `RivetHTTPClient.Transport`，並將 Apollo token interceptor 留給獨立 topic；不得改動圖表、HTTP package、Swift source 或既定 PAT／deferred-signature／locale contract。

## TestCase

| ID | 驗收 |
| --- | --- |
| TC-01 | 四份 planning artifacts 使用相同 slug，並包含本計畫指定 headings 與 Human Check。 |
| TC-02 | Implementer delivery 後，文件與兩張圖都表達 token／provider 只屬於 GitHub Integration；HTTP package 不取得、持有、refresh 或處理 token。 |
| TC-03 | Implementer delivery 後，canonical lifecycle 僅表達 request preparation、取得既有 PAT、Bearer header injection／overwrite 與 HTTP client raw execution；不含 OAuth、refresh、401 retry、concrete network、DTO 或 core mapping。 |
| TC-04 | Tester 獨立驗證 existing architecture canvas 的 artifact-local validate → build → enhance → verify，及 canonical lifecycle 的 Archify showcase validate → deliver → visual-check。 |
| TC-05 | Tester 確認兩組 containment candidate 已由 Implementer 移除，且交付只含 canonical lifecycle JSON／HTML／canonical visual-check evidence；Reviewer 再確認 `git diff --check` 與無 Swift／HTTP package drift。 |
| TC-06 | language thread delivery 僅改 lifecycle artifact-local `BUILD.md`，如實記錄 `en`／`zh-CN` renderer limitation、`meta.locale` omission 與英文 fallback；diff 不含 lifecycle JSON、generated HTML、visual-check sidecar 或 architecture-canvas language handling 變更。 |
| TC-07 | review-audit planning correction 由 PR-05 獨立 Plan-Reviewer 審查；在其 verdict 前，Phase 與 Handoff 明確指向 PR-05，且 HR-03、HR-04 維持各自 pending human gate。 |
| TC-08 | PR-06 approved 後，canvas-only delivery 恢復 `Transport → Foundation URLSession／GitHub.com API` compile-time／ownership edge；`adapter → client` 的 route 與 label 不穿過或指向 token-provider／authorizer；artifact-local validate → build → enhance → verify、source/build byte identity、syntax、diff 與 artifact-local containment 均通過，且無 runtime sequence、token contract、Swift／HTTP package 或其他文件 drift。IM-05 的「變更仍未 commit」僅是 delivery 前的 historical Implementer evidence；canvas delivery 已由 commit `7f6f9fa` 提交，不得將該歷史敘述誤讀為 current uncommitted 狀態。browser CLI fresh viewport 若未取得 evidence，不得誤稱 browser pass，且不影響此 artifact-local containment TestCase。 |
| TC-09 | BC wording 明確限定只有 `GitHubRESTAdapter` request 經 authorizer 後使用 `RivetHTTPClient`；`GitHubGraphQLAdapter` → `ApolloClient` 不經 `RivetHTTPClient.Transport`，且 Apollo token interceptor 留待獨立 topic。驗證不得將 REST authorization lifecycle 推論為 GraphQL 行為，也不得改變 Integration-owned PAT、deferred concrete signature／failure／refresh／re-auth 或 locale fallback。 |
| TC-10 | RV-05 後的 `DL-01` 保有 owner、pending/completed status、completion criteria 與可稽核 commit、push、exact-thread-resolution evidence；只有獨立 RV-06 approved 後才能完成 DL-01。其 delivery 待 resolve 精確清單只包含 `PRRT_kwDOUFu0Cc6gF0CL` 與 `PRRT_kwDOUFu0Cc6gF0CR`；`PRRT_kwDOUFu0Cc6gHnG1` 已由外部處置 resolved，不納入 DL-01。DL-01 completed 前，HR-05 必須維持 pending，且不得取代 HR-03 或 HR-04。 |
| TC-11 | TE-06 scope audit 發現的 `PRRT_kwDOUFu0Cc6gHnG1` 已被獨立列入 thread audit；其 correction 只將 IM-05 的未提交敘述限為 historical pre-delivery evidence，並綁定 canvas delivery commit `7f6f9fa`。獨立 Tester 已確認遠端 `isResolved=true`，故此 thread 為外部已完成的 resolution，不納入 DL-01 的待 delivery 精確清單。此 correction 不改變 REST-only／Apollo-only boundary、既定 deferred 決策或 HR-03、HR-04、HR-05 的狀態。 |

## Future Swift Implementation Slices

1. **Integration contract foundation**：建立 GitHub Integration module、`GitHubAccessToken`、`GitHubTokenProvider` 及 fake-provider tests；需由獨立 topic 鎖定 module/package path、token-delivery signature 與 failure contract。
2. **Keychain credential adapter**：讀取單一 PAT；需先鎖定 Keychain service/account identity、entitlement、credential failure contract 與測試策略。
3. **GitHub REST request authorizer**：每次 REST request 取得 token，設定或覆寫 `Authorization`，並保留 URL、method、body 與其他 headers；GraphQL／Apollo token interceptor 是獨立 topic。
4. **GitHub API data adapter／DTO**：僅為一個已選定 read operation 建立授權 request 與 Integration-internal DTO handling。
5. **PR Inbox 或 PR Reader adapter**：各自獨立將 Integration output 映射到對應 core Port 與 failure contract。

每個 slice 都必須是獨立正式 topic，經 Plan-Reviewer gate 後才可實作，並停在其 human boundary。
