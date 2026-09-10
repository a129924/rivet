# GitHub Integration Authorization Boundary：計畫

## Goal

在不改變任何 Swift 實作的前提下，鎖定 GitHub Integration 提供 future lower shared authorization capability：由 shared-capability `GitHubTokenProvider` 交付 `GitHubAccessToken`，供 consuming Domain BC local-Infra REST adapter 在 GitHub REST request 交給 `RivetHTTPClient` 前注入或覆寫 Bearer `Authorization`；Domain-local GraphQL adapter 維持 Apollo-only route，不套用此 flow；Integration 不實作或符合 Domain-owned Port。

## Non-Goal

不建立任何 Swift source、module、package、target、protocol、Keychain item 或 executable auth behavior；不實作 OAuth、refresh、401 retry、Keychain adapter、URLSession transport、DTO、GitHub API adapter 或 core Port failure mapping。

## In-Scope

- 初版 credential 為使用者預先提供的一個 fine-grained PAT。
- 鎖定 declaration-only future direction：GitHub Integration lower shared capability 的 `GitHubTokenProvider` 負責 token delivery，並交付 `GitHubAccessToken`。其具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 延後至獨立 failure-contract topic；本 topic 不預先選擇任何 failure representation。
- consuming Domain BC local-Infra `GitHubRESTAdapter` 可使用 shared authorizer 為每個 GitHub REST request 設定或覆寫 `Authorization: Bearer …`，再交給 `RivetHTTPClient`；同一 BC local-Infra `GitHubGraphQLAdapter` → `ApolloClient` 維持 Apollo-only、不經 `RivetHTTPClient.Transport`。Apollo token interceptor 與 GraphQL credential consumption 留待獨立 topic。
- 鎖定 Archify lifecycle 的 renderer locale limitation：正式支援僅 `en` 與 `zh-CN`；因作者內容為繁體中文，source JSON 省略 `meta.locale`，Viewer UI 與 generated HTML language attribute 依 renderer fallback 維持英文。這不是將繁體中文錯標為 `zh-CN` 的授權。
- 已發生的 review-audit planning correction 已經獨立 PR-05 Plan-Reviewer `approved`；該 verdict 僅接受 correction 的 workflow／provenance，不重開既有 architecture、path 或 contract decision，亦不改變 HR-03 與 HR-04 各自獨立 pending 的狀態。
- 兩個 canvas review fixes 已經獨立 PR-06 Plan-Reviewer `approved`：恢復 `Transport → Foundation URLSession／GitHub.com API` 的 compile-time／ownership edge；並讓 `adapter → client` 的 route 與 label 繞過 token-provider／authorizer，避免被誤讀為 runtime flow。canvas 仍只表達 ownership／compile-time boundary。
- 獨立 Tester 已完成 TE-05：兩個 canvas-only review fixes 的 validator／build／enhance／accessibility、source/build byte identity、syntax、diff 與 artifact-local containment checks 均通過。browser CLI 的 fresh viewport 兩次逾時，未形成 browser evidence，且不得宣稱為 browser pass；這不影響 artifact-local containment TestCase。獨立 RV-05 已 `approved`；canvas delivery 已由 commit `7f6f9fa` 提交。IM-05 的未提交敘述只保留為 delivery 前的 historical evidence，不得誤稱 current uncommitted；HR-05 仍是 pending，且不得取代 HR-03 或 HR-04 各自獨立 pending 的 human gate。既有 GitHub Integration BC、architecture navigation 與 lifecycle artifact 的交付範圍不因本輪 canvas-only fix 而重開。
- PR #17 本輪 bounded remediation 僅補齊 RV-05 後的可稽核 delivery gate，並限縮 BC wording：只有 consuming Domain BC local-Infra `GitHubRESTAdapter` 的 request 經 shared authorizer 後使用 `RivetHTTPClient`；同一 BC local-Infra `GitHubGraphQLAdapter` 封裝 `ApolloClient`、不經 `RivetHTTPClient.Transport`，Apollo token interceptor 留待獨立 topic。此 correction 不改變 PAT-only、deferred concrete signature／failure／refresh／re-auth 或 locale fallback 的既定決策。
- human 已明確確認 HR-01、HR-02 為「被後續 revision 取代」，不是 human approval；HR-03、HR-04、HR-05 仍各自獨立 pending，不受此事實影響。
- 本輪僅建立兩張 canonical diagram 的 REST-only wording correction chain：canvas 與 lifecycle 都必須明示 authorizer／request preparation 只描述 GitHub REST request。獨立 Implementer 必須依各 artifact 的正式流程重建 generated output；這不把 canvas 變成 runtime sequence，亦不把 REST lifecycle 推論為 GraphQL／Apollo 行為。
- human 已決定保留 GitHub Integration BC／canonical diagrams，並將 conflict tree 的 GraphQL SDL／draft 改為 future consuming Domain BC local-Infra GitHub adapter／schema topic material。GraphQL 維持 Apollo-only route；GitHub Integration 僅提供 lower shared capability，不擁有 candidate、Domain Port 或 adapter／schema。本輪不接受、驗證、移動或實作 SDL；candidate material 不會產生 PR Reader local-exclusive Infra、Apollo interceptor 或 token／failure contract。
- PC-10 的「中央 Integration boundary」reconciliation 是歷史方向，已由後續 human 的 Domain-owned Port／local Infra 決定取代；不得作為 current contract。
- human 已鎖定 local Infra pattern：每個 Domain BC owns its Port；future concrete GitHub adapter 位於該 BC 的 Infra（示意為 `<BC>/Infra/GitHub`，非本 topic 的 path／target 決定）並實作該 Port，擁有 endpoint／operation、DTO、infrastructure-failure 正規化與 local failure mapping。GitHub Integration 只提供 lower shared authorization capability，不擁有、引用或符合 Domain Port，也不擁有上述 adapter 責任；零 BC-to-BC compile-time dependency 維持。
- 本輪五個 current threads 的 remediation 只建立可稽核 chain：map／README／GitHub Integration BC 改表達 local Infra pattern；canonical Integration boundary canvas 也必須移除 central adapter／Port conformer 語意，僅表達 lower shared capability 與 compile-time isolation。lifecycle receipt 以 BUILD 的 fresh `pass` 或 truthful `skipped` policy 更新；RV-07 取得獨立 fresh verdict；GraphQL candidate 在 PR-02 pending 保持不動，僅補 future local-Infra ownership／move gate。任何 delivery 必須在 new Plan-Reviewer gate 後才可開始。
- PC-15 僅收斂已鎖定 local-Infra direction 與 `docs/design-principles.md` 的 current wording。PR-15 approved 後，IM-09 corrective re-entry 必須將該文件的「GitHub Integration 隔離 GitHub 外部協定、身分、DTO 與 infrastructure failure」及「GitHub Integration 在其 Adapter 邊界正規化外部 infrastructure failure」改為：各 Domain BC 的 Core、UseCase 與 Port 不依賴 GitHub 外部協定或 transport；該 BC 的 future local Infra 擁有 concrete GitHub adapter、operation／endpoint、DTO、外部 infrastructure-failure 正規化與跨越 own Port 前的 Domain failure mapping；GitHub Integration 僅提供 lower shared authorization capability，不擁有、引用或符合任何 Domain-owned Port，也不擁有上述 adapter／DTO／failure responsibility。這只對齊既定決策，不重開架構。

## Out-Of-Scope

- generic `TokenProvider`、`RivetHTTPClient` token dependency、constructor 變更或 HTTP package auth API。
- `GitHubTokenProvider` 的具體 Swift signature、`throws`／`Outcome` 選擇，或 credential failure、refresh／re-auth contract。
- OAuth-shaped token payload 的採用、refresh token、401 retry、多帳號、GitHub Enterprise、PAT UI、Keychain identity／adapter。
- concrete network、HTTP status／decode policy、DTO、PR Inbox／PR Reader mapping，以及 core failure mapping。
- 直接手改 generated lifecycle HTML 或 visual-check sidecar、設定 `meta.locale: "zh-CN"`、為 language thread 重新 deliver lifecycle artifact，或變更 architecture-canvas 的獨立 language handling。
- 將 canvas 擴張成 runtime sequence、token-delivery／failure contract，或改變 deferred signature、PAT-only 與 locale fallback 的既定結論。
- 將 REST authorizer 套用到 GraphQL／Apollo、建立或選擇 Apollo token interceptor 的具體 contract，或改變 Apollo 不經 `RivetHTTPClient.Transport` 的既定 boundary。
- 以本輪 wording correction 重新開啟 PAT、deferred concrete signature／failure／refresh／re-auth、locale fallback、GraphQL Apollo boundary，或將 canvas 擴張為 runtime dataflow。
- 接受、搬移、下載、驗證或宣稱 GraphQL SDL 已交付；建立 PR Reader local-exclusive GitHub Infra、`GitHubTransport`、Apollo interceptor 或任何 GraphQL／token／failure implementation。
- 讓 GitHub Integration 充當各 Domain-owned Port 的 conformer，或畫出 Integration → Domain Port edge；選定 `<BC>/Infra/GitHub` 的實際 module／target／path。
- 在 GraphQL draft PR-02 pending 時移動、刪除或修改 `Schema.graphqls`，或把 future ownership gate 視為 asset delivery。

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
- 本輪 REST／GraphQL wording correction 的正式 delivery 僅可修改 `docs/architecture/bounded-contexts/github-integration.md`：限縮 authorizer → `RivetHTTPClient` 為 `GitHubRESTAdapter` request，明列 future consuming Domain BC local-Infra `GitHubGraphQLAdapter` → `ApolloClient` 不經 `RivetHTTPClient.Transport`，並將 Apollo token interceptor 留給獨立 topic；不得改動圖表、HTTP package、Swift source 或既定 PAT／deferred-signature／locale contract。
- 本輪 diagram wording correction 的正式 delivery 只可修改兩組 canonical source 與其正式 generated output：canvas `scene.js` → `index.html`（依 validate → build → enhance → verify）；lifecycle `github-authorization-lifecycle.json` → `github-authorization-lifecycle.html`（依 showcase validate → deliver，並依 BUILD 的 visual-check policy 如實處理 canonical evidence）。兩組 source 的 authorizer／request wording 都必須限於 GitHub REST request。不得修改 BC 文件、HTTP package、Swift source、PAT／deferred-signature／locale／GraphQL Apollo contract，亦不得將 canvas 畫成 runtime sequence。
- **歷史 PC-10 reconciliation scope（已被 PC-13／IM-09 current contract 取代，非現行 Modify authorization）**：曾限於 `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`，以及 bounded-context map `scene.js` → formal generated `index.html`，並曾以中央 Integration construct 表達 retained boundary。此歷史範圍不得用來排除 Domain-local Infra，也不得作為 current acceptance、delivery 或 allowed-path 依據。
- 本輪 local-Infra／receipt remediation 的 Implementer 只可修改：`docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`、`docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/bounded-contexts/github-integration.md`，bounded-context map `scene.js` → formal generated `index.html`，canonical Integration boundary canvas 的 `scene.js`、`BUILD.md` → formal generated `index.html`，以及 lifecycle 的 `github-authorization-lifecycle.visual-check.json` 與 BUILD policy 要求的 capture sidecars。`docs/design-principles.md` 必須以 Domain-local Infra 擁有 adapter／operation／endpoint／DTO／外部 infrastructure-failure 正規化與 own-Port 前 Domain failure mapping，取代任何將這些責任歸給 GitHub Integration 的敘述；Integration 只保留 lower shared authorization capability，且不擁有、引用或符合 Domain Port。README／BC docs 必須表達同一個 Domain-owned Port、Domain-local REST／GraphQL GitHub adapter 與 Integration lower shared capability contract；map 與 canonical Integration canvas 都不得含 Integration → Domain Port edge、central conformer 或 runtime flow。canonical Integration canvas 必須依其 `BUILD.md` 的 validate → build → enhance → verify 正式交付，且 `scene.js` 是唯一資料真相；不可手改 output。lifecycle receipt 必須有 current HTML SHA／size 的 fresh pass binding，或 truthful skipped receipt 加 stale sidecar removal。`Schema.graphqls`、GraphQL draft asset、Swift／HTTP package 一律不得修改。

## TestCase

| ID | 驗收 |
| --- | --- |
| TC-01 | 四份 planning artifacts 使用相同 slug，並包含本計畫指定 headings 與 Human Check。 |
| TC-02 | Implementer delivery 後，文件與兩張圖都表達 GitHub Integration 只提供 token／provider 的 lower shared capability；Domain-local adapter 才消費 capability，HTTP package 不取得、持有、refresh 或處理 token。 |
| TC-03 | Implementer delivery 後，canonical lifecycle 僅表達 request preparation、取得既有 PAT、Bearer header injection／overwrite 與 HTTP client raw execution；不含 OAuth、refresh、401 retry、concrete network、DTO 或 core mapping。 |
| TC-04 | Tester 獨立驗證 existing architecture canvas 的 artifact-local validate → build → enhance → verify，及 canonical lifecycle 的 Archify showcase validate → deliver → visual-check。 |
| TC-05 | Tester 確認兩組 containment candidate 已由 Implementer 移除，且交付只含 canonical lifecycle JSON／HTML／canonical visual-check evidence；Reviewer 再確認 `git diff --check` 與無 Swift／HTTP package drift。 |
| TC-06 | language thread delivery 僅改 lifecycle artifact-local `BUILD.md`，如實記錄 `en`／`zh-CN` renderer limitation、`meta.locale` omission 與英文 fallback；diff 不含 lifecycle JSON、generated HTML、visual-check sidecar 或 architecture-canvas language handling 變更。 |
| TC-07 | review-audit planning correction 由 PR-05 獨立 Plan-Reviewer 審查；在其 verdict 前，Phase 與 Handoff 明確指向 PR-05，且 HR-03、HR-04 維持各自 pending human gate。 |
| TC-08 | PR-06 approved 後，canvas-only delivery 恢復 `Transport → Foundation URLSession／GitHub.com API` compile-time／ownership edge；`adapter → client` 的 route 與 label 不穿過或指向 token-provider／authorizer；artifact-local validate → build → enhance → verify、source/build byte identity、syntax、diff 與 artifact-local containment 均通過，且無 runtime sequence、token contract、Swift／HTTP package 或其他文件 drift。IM-05 的「變更仍未 commit」僅是 delivery 前的 historical Implementer evidence；canvas delivery 已由 commit `7f6f9fa` 提交，不得將該歷史敘述誤讀為 current uncommitted 狀態。browser CLI fresh viewport 若未取得 evidence，不得誤稱 browser pass，且不影響此 artifact-local containment TestCase。 |
| TC-09 | BC wording 明確限定只有 consuming Domain BC local-Infra `GitHubRESTAdapter` request 經 shared authorizer 後使用 `RivetHTTPClient`；同一 BC 的 local-Infra `GitHubGraphQLAdapter` → `ApolloClient` 不經 `RivetHTTPClient.Transport`，且 Apollo token interceptor 留待獨立 topic。驗證不得將 REST authorization lifecycle 推論為 GraphQL 行為，也不得改變 PAT-only、deferred concrete signature／failure／refresh／re-auth 或 locale fallback。 |
| TC-10 | RV-05 後的 `DL-01` 保有 owner、pending/completed status、completion criteria 與可稽核 commit、push、exact-thread-resolution evidence；只有獨立 RV-06 approved 後才能完成 DL-01。其 delivery 待 resolve 精確清單只包含 `PRRT_kwDOUFu0Cc6gF0CL` 與 `PRRT_kwDOUFu0Cc6gF0CR`；`PRRT_kwDOUFu0Cc6gHnG1` 已由外部處置 resolved，不納入 DL-01。DL-01 completed 前，HR-05 必須維持 pending，且不得取代 HR-03 或 HR-04。 |
| TC-11 | TE-06 scope audit 發現的 `PRRT_kwDOUFu0Cc6gHnG1` 已被獨立列入 thread audit；其 correction 只將 IM-05 的未提交敘述限為 historical pre-delivery evidence，並綁定 canvas delivery commit `7f6f9fa`。獨立 Tester 已確認遠端 `isResolved=true`，故此 thread 為外部已完成的 resolution，不納入 DL-01 的待 delivery 精確清單。此 correction 不改變 REST-only／Apollo-only boundary、既定 deferred 決策或 HR-03、HR-04、HR-05 的狀態。 |
| TC-12 | human 已確認 HR-01、HR-02 均為「被後續 revision 取代」，並非 human approval；HR-03、HR-04、HR-05 維持各自 independent pending human gate。ledger 不得再將 DL-01 或其 F0CL／F0CR 清單表示為 pending：delivery commit `d43aa09` 已 push，兩個精確 threads 均已 resolved；`PRRT_kwDOUFu0Cc6gHnG1` 維持外部 resolved。 |
| TC-13 | PR-09 approved 後，兩張 canonical diagram 的 source 及正式 generated output 都只以「GitHub REST request」描述 request preparation／authorizer。canvas 維持 ownership／compile-time boundary，不新增 runtime edge；lifecycle 不描述 GraphQL／Apollo。Tester 必須獨立執行 canvas validate → build → enhance → verify 與 lifecycle showcase validate → deliver，並依 BUILD 如實驗證或分類 visual-check 結果；Reviewer 再確認 source／output 同步、scope、`git diff --check`、無 Swift／HTTP package drift，以及新的精確 thread audit／delivery清單。 |
| TC-14 | `PRRT_kwDOUFu0Cc6gIli5`、`PRRT_kwDOUFu0Cc6gIli9`、`PRRT_kwDOUFu0Cc6gIljC`、`PRRT_kwDOUFu0Cc6gIljF` 是本輪唯一可由 DL-02 在 approved delivery 後 resolve 的精確清單；audit 必須個別對應 finding、correction 與 pending status。DL-02 前不得由 local planning edit 宣稱 resolve；DL-02 後仍須記錄 commit、push 與每個 remote resolution evidence，且不得 merge PR。 |
| TC-15 | **歷史／已被後續 local-Infra direction 取代，非 current acceptance。** 此條只記錄 PR-10 當時的 six-active-docs／map reconciliation：docs 曾移除 GitHub Integration retirement、local-exclusive GitHub Infra 或 future `GitHubTransport` claim，map 曾以中央 Integration construct 與 PR Inbox／PR Reader Core／Port isolation 表達 non-runtime boundary。不得以此條恢復 central adapter／Port conformer，或用來取代 PR-13 後由 TC-16、TC-17、TC-19、TC-20 驗收的 current IM-09 contract；SDL candidate 當時亦未驗證、未接受。 |
| TC-16 | PR-13 approved 後，README／BC docs、bounded-context map 與 canonical Integration boundary canvas 一致表達：Domain BC owns Port；concrete REST／GraphQL GitHub adapter 是該 BC local Infra（`<BC>/Infra/GitHub` 僅為示意）；GitHub Integration 只提供 lower shared capability。兩張 canvas 都不存在 Integration → Domain Port edge、central conformer、PR Inbox ↔ PR Reader 或其他 BC-to-BC compile-time dependency，且不增加 runtime dataflow。 |
| TC-17 | current lifecycle receipt 若為 `pass`，其 HTML SHA-256 與 byte size 等於 canonical HTML；若 visual-check 環境不可用，receipt 必須如 BUILD 所定義為 `skipped` 並移除所有 stale capture sidecars。Tester 不得把任一舊 pass receipt 當作 current evidence。 |
| TC-18 | RV-07 由 fresh、獨立 Reviewer 審查 IM-07 diagram delivery；RV-08 不得替代該 verdict。`PRRT_kwDOUFu0Cc6ghcy-`、`PRRT_kwDOUFu0Cc6ghcy_`、`PRRT_kwDOUFu0Cc6ghczD`、`PRRT_kwDOUFu0Cc6ghczF`、`PRRT_kwDOUFu0Cc6ghczL` 只有在本輪 independent review、delivery commit、push 與 remote evidence 均完成後才可 exact resolve；不得 merge PR。 |
| TC-19 | `graphql-schema-draft-plan` 的 PR-02 pending 期間，`Schema.graphqls` 維持 read-only、未移動、未驗證、未接受。future domain adapter／schema topic 必須先鎖定 consuming BC、local Infra path、provenance、verification 與 adapter／interceptor／token／failure contract，才可處理 asset move；GitHub Integration shared capability 不擁有該 asset 或 Domain Port。 |
| TC-20 | PR-13 approved 後，IM-09 的 exact Modify scope 包含 canonical Integration boundary canvas 的 `scene.js`、`BUILD.md` 與由正式 renderer 產生的 `index.html`。Tester 驗證 validate → build → enhance → verify、source/output identity、無手改 output、scope 與 `git diff --check`；canvas 只表達 shared capability／ownership／compile-time isolation，不畫 REST／GraphQL runtime flow 或 Integration adapter conformer。 |
| TC-21 | PR-15 approved 後，IM-09 corrective re-entry 必須將 `docs/design-principles.md` 的 current contract 對齊為：Domain BC local Infra 擁有 concrete GitHub adapter、operation／endpoint、DTO、外部 infrastructure-failure 正規化與 own-Port 前的 Domain failure mapping；GitHub Integration 僅提供 lower shared authorization capability，且不擁有、引用或符合 Domain Port。Tester 重新確認此文件與 README／BC docs／兩張 canvas 一致、沒有 Integration-owned adapter／DTO／failure mapping、沒有 BC-to-BC compile-time dependency，且 scope 不含 SDL、Swift 或 HTTP package。 |

## Future Swift Implementation Slices

1. **Shared capability foundation**：建立 GitHub Integration lower shared capability、`GitHubAccessToken`、`GitHubTokenProvider` 及 fake-provider tests；需由獨立 topic 鎖定 module/package path、token-delivery signature 與 failure contract，且不得讓它實作 Domain-owned Port。
2. **Keychain credential adapter**：讀取單一 PAT；需先鎖定 Keychain service/account identity、entitlement、credential failure contract 與測試策略。
3. **Domain-local GitHub REST request authorizer consumption**：每個 consuming Domain BC 的 local REST adapter 使用 shared capability 取得 token、設定或覆寫 `Authorization`，並保留 URL、method、body 與其他 headers；GraphQL／Apollo token interceptor 是獨立 topic。
4. **Domain-local GitHub API data adapter／DTO**：僅為一個已選定 read operation，在 consuming Domain BC 的 Infra/GitHub boundary 建立授權 request、endpoint／DTO handling 與 infrastructure-failure 至該 Domain failure contract 的 mapping；可使用 lower shared authorization capability，但不得將這些責任放入 GitHub Integration。
5. **Domain-local GitHub adapter**：各 PR Inbox／PR Reader slice 各自在該 Domain BC 的 Infra/GitHub boundary 實作自己的 Port 與 failure mapping；它可採用 lower shared GitHub capability，但不建立 GitHub Integration → Domain Port dependency。

每個 slice 都必須是獨立正式 topic，經 Plan-Reviewer gate 後才可實作，並停在其 human boundary。
