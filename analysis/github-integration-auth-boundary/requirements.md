# GitHub Integration Authorization Boundary：需求

## Goal

鎖定 GitHub Integration 的低階共用 authorization capability。未來 capability 的 `GitHubTokenProvider` 可交付 `GitHubAccessToken`，並供 consuming Domain BC 的 local-Infra `GitHubRESTAdapter` 在每一個 GitHub REST request 前設定或覆寫 `Authorization: Bearer …`；`RivetHTTPClient` 保持通用，不認識 token、credential lifecycle 或 GitHub authorization policy。各 consuming Domain BC 的 local-Infra `GitHubGraphQLAdapter` 維持 Apollo-only route，不經 `RivetHTTPClient`；Integration 不實作、引用或符合 Domain-owned Port。

初始 credential 是使用者預先提供的一個 fine-grained PAT。此 topic 只鎖定 boundary 與未來 direction，不建立 Swift 實作或 executable behavior。

## Non-Goal

- 不建立 Swift source、module、package、target、protocol、Keychain item 或可執行 authorization 行為。
- 不實作 OAuth、refresh token、401 retry、PAT UI、Keychain adapter、URLSession transport、GitHub API DTO 或 PR Inbox／PR Reader adapter。
- 不決定 Keychain 的 service/account identity、entitlement 或儲存／寫入流程。
- 不改變 `RivetHTTPClient` 的 public API、constructor、headers、transport 或 error contract。

## In-Scope

- 記錄 GitHub Integration 提供 future lower shared authorization capability 的長期 architecture boundary；它不是集中 Domain adapter 或 Domain Port conformer。
- 鎖定 declaration-only direction：future shared capability 的 `GitHubTokenProvider` 負責 token delivery，並交付 `GitHubAccessToken`；它不是 `String` 或 HTTP package type。具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 均延後至獨立 failure-contract topic 決定。
- 鎖定 consuming Domain BC local-Infra REST adapter 的 future flow：取得既有 PAT → 使用 shared authorizer 設定或覆寫 Bearer `Authorization` → `RivetHTTPClient` 執行 REST raw request；不將此 flow 套用至 GraphQL／Apollo。
- 限縮 adapter routing：每個 consuming Domain BC 的 local-Infra `GitHubRESTAdapter` 才會使用 shared authorizer 後交給 `RivetHTTPClient`；同一 BC 的 local-Infra `GitHubGraphQLAdapter` 封裝 `ApolloClient`，不經 `RivetHTTPClient.Transport`。Apollo token interceptor 與任何 shared credential consumption 均留待獨立 topic。
- 將 Keychain 與使用者設定的 PAT 表示為 Outside；token、OAuth、HTTP status、DTO 與 infrastructure details 不跨越 PR Inbox／PR Reader core Port。
- 兩張 canonical diagram 的 authorizer／request preparation wording 都必須限於 GitHub REST request；Integration boundary canvas 只表達 lower shared capability、local-Infra ownership 與 compile-time isolation，不畫 Integration → Domain Port edge、central conformer 或 runtime route。lifecycle 不推論 GraphQL／Apollo route。正式 delivery 由獨立 Implementer 依各 artifact 的 build／deliver contract 重建 generated output。
- human 已決定保留 GitHub Integration BC 與 canonical diagrams。衝突樹中的 GitHub GraphQL SDL 僅是 future consuming Domain BC local-Infra GitHub adapter／schema topic 的 candidate material；它不建立 PR Reader local-exclusive Infra ownership，也不鎖定 adapter、Apollo interceptor、token delivery、failure、refresh 或 re-auth contract。GitHub Integration 僅提供 lower shared capability，不擁有 candidate、Domain Port 或 adapter／schema。
- human 已鎖定 local Infra direction：每個 Domain BC 自己擁有 Port，未來若需要 GitHub adapter，必須由該 BC 的 Infra（示意為 `<BC>/Infra/GitHub`，非本 topic 的 source-path／target 決定）實作自己的 Port 與 failure mapping。GitHub Integration 只提供較低層共用 capability；它不擁有、引用或符合任何 Domain-owned Port，且 Domain Core／UseCase／Port 不依賴該 capability。
- map／README correction 必須表達 local adapter ownership、Integration lower shared capability 與 Outside boundary；不得畫出 Integration → Domain Port edge，也不得建立 PR Inbox ↔ PR Reader 或任何 BC-to-BC compile-time dependency。圖仍只表達 ownership／compile-time boundary，不加入 runtime REST／GraphQL／authorization dataflow。
- lifecycle HTML 的 visual-check receipt 必須與 current canonical HTML 的 SHA-256 與 byte size 同步。後續 delivery 只能二擇一：成功重跑正式 `visual-check` 並交付 current-bound receipt／sidecars，或依 artifact-local `BUILD.md` 交付 truthful `skipped` receipt 並移除過期 capture sidecars；不得將舊 pass receipt 當成 current evidence。
- RV-07 必須取得獨立、fresh Reviewer verdict；RV-08 的 retained-Integration reconciliation review 不得取代或回填 RV-07。GraphQL candidate location 的任何搬移仍受 `graphql-schema-draft-plan` 的 PR-02 pending gate 限制，本輪只定義 future ownership／move gate，不移動 asset。
- 現行受限 implementation 僅可在 PR-15 approved 後依 IM-09 corrective re-entry 的 exact scope 改寫：`docs/design-principles.md`、`docs/architecture/README.md`、bounded-contexts 的 README／PR Inbox／PR Reader／GitHub Integration 文件、bounded-context map 的 `scene.js` → formal `index.html`、canonical Integration boundary canvas 的 `scene.js`／`BUILD.md` → formal `index.html`，以及 lifecycle current-receipt policy 所允許的 receipt／sidecar。`docs/design-principles.md` 必須將 adapter、operation／endpoint、DTO、外部 infrastructure-failure 正規化與 own-Port 前 Domain failure mapping 明確歸屬 consuming Domain BC local Infra；GitHub Integration 只保留 lower shared authorization capability，不擁有、引用或符合 Domain Port。所有 current wording 必須表達同一 contract；不得保留 central adapter／Port conformer，也不得引入 runtime flow。早期 PC-10 的中央 Integration／移除 local-Infra wording已被後續 local-Infra direction 取代，不是本輪現行 scope。
- human 已確認 HR-01、HR-02 為「被後續 revision 取代」，不是 approval；HR-03、HR-04、HR-05 仍維持彼此獨立 pending human gate。
- 鎖定 lifecycle artifact 的 renderer locale limitation：Archify 正式支援的 locale 僅有 `en` 與 `zh-CN`。由於作者內容為繁體中文，lifecycle JSON 必須省略 `meta.locale`；Viewer UI 與 generated HTML 的 language attribute 因 renderer fallback 維持英文。唯一允許的後續交付是於 artifact-local `BUILD.md` 明示此限制；不需要重新 deliver。
- 建立本 topic 的正式 planning artifacts。長期 BC 文件與圖表的受限 delivery 必須在 Plan-Reviewer 通過後，交由獨立 Implementer 執行，並經獨立 Tester、Reviewer 與 human review。

## Out-Of-Scope

- generic `TokenProvider`，或 `HTTPClient` constructor／public API 的 token dependency。
- `GitHubTokenProvider` 的具體 Swift signature、`throws`／`Outcome` 選擇，或 credential failure、refresh／re-auth contract。
- token refresh、refresh token schema、OAuth grant、401 retry、多帳號、GitHub Enterprise 與跨裝置同步。
- concrete network request、HTTP status policy、decode policy、DTO mapping，以及各 core BC 的 failure mapping。
- 任何 core Port 的 credential、OAuth、HTTP 或 infrastructure type。
- 將 lifecycle JSON 設為 `meta.locale: "zh-CN"`、直接手改 generated lifecycle HTML／sidecar，或為 language thread 重新 deliver artifact。此限制僅針對 Archify lifecycle；不得因此變更同目錄 architecture-canvas 的獨立 language handling。
- 將 REST authorizer 延伸為 GraphQL／Apollo token interceptor，或在本 topic 設計其 operation、failure、refresh 或 re-auth contract。
- 將 candidate SDL 視為已驗證、已接受或已實作的 schema snapshot；改動、搬移、驗證或重新取得 SDL，或以本輪 active-doc／map correction 解決 GraphQL topic 的交付問題。
- 讓 GitHub Integration 實作、引用或符合 Domain-owned Port，或把 local adapter 寫成 Integration-owned central adapter；選定 `<BC>/Infra/GitHub` 的真實 package、target 或 source path。
- 在 `graphql-schema-draft-plan` 的 PR-02 approved 前移動、刪除或另行 materialize `Schema.graphqls`，或將 candidate 現有路徑誤稱為 accepted ownership。

## Acceptance Criteria

1. 四份正式 artifacts 使用相同 slug，且 plan 保留 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify、TestCase、Future Swift Implementation Slices。
2. 獨立 Implementer 交付後，長期文件與兩張圖一致表達 Domain-local adapter ownership、Integration 的 lower shared capability、fine-grained PAT-only 初版，以及 HTTP package 不具 auth lifecycle。
3. 獨立 Implementer 交付的 lifecycle artifact 僅表達 declaration-only request preparation；不得描述 OAuth、refresh、401 retry 或 concrete network implementation。
4. 獨立 Tester 與 Reviewer 確認 topic diff 不含 Swift source、module、package、manifest 或 HTTP package 變更，才交由 human review。
5. language thread remediation 僅於 lifecycle artifact-local `BUILD.md` 記錄 Archify 的 `en`／`zh-CN` renderer limitation、繁體中文作者內容的 `meta.locale` omission，以及英文 Viewer／HTML fallback；不改動 lifecycle JSON、generated HTML、receipt 或 visual evidence。
6. BC 文件明確區分 Domain-local REST 與 GraphQL route：local REST adapter 才使用 shared authorizer 後的 `RivetHTTPClient`；local GraphQL adapter 保持 Apollo-only route，且 Apollo token interceptor 明確延後至獨立 topic。
7. 兩張 canonical diagram 的 source 與正式 generated output 一致以 GitHub REST request 限縮 authorizer／request wording；不產生 GraphQL／Apollo runtime flow，且 canvas 仍不表達 runtime sequence。
8. local Infra correction 明確表達 Domain BC owns Port／local adapter，GitHub Integration 僅提供 lower shared capability，且不存在 Integration → Domain Port 或任何 BC-to-BC compile-time dependency；`docs/design-principles.md` 亦不得再將 adapter、DTO 或 infrastructure-failure mapping 歸屬 GitHub Integration。
9. lifecycle visual-check receipt 若為 `pass`，其 artifact SHA-256／byte size 必須等於 current canonical HTML；若環境不能重跑，只有 BUILD 定義的 `skipped` receipt 與過期 sidecar cleanup 可作 truthful policy path。
10. RV-07 與 RV-08 保持兩個獨立 Reviewer verdict；GraphQL candidate 在 PR-02 pending 時維持 read-only，future move 僅可由獨立 domain adapter／schema topic 在新 gate 後決定。

## Evidence Sources

- `README.md`：Rivet 目前仍以 architecture baseline 為主，正式 topic 需留下可追溯的 analysis、plan 與 docs。
- `docs/design-principles.md`：現行外部協定／DTO／infrastructure-failure 的責任敘述是 PC-15 的唯一 planning correction input；IM-09 corrective re-entry 必須將其對齊為 Domain-local Infra ownership，而不改變「不得洩漏到核心 BC」或「不得因未來需求提早建立抽象」。
- `docs/architecture/bounded-contexts/github-integration.md`：GitHub Integration 是隔離 GitHub 外部資料與 infrastructure failure 的 Supporting BC；`RivetHTTPClient` 是可採用的內部 transport foundation。
