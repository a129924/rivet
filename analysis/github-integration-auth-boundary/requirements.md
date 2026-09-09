# GitHub Integration Authorization Boundary：需求

## Goal

鎖定 GitHub Integration 的 authorization ownership。未來由 GitHub Integration 擁有的 `GitHubTokenProvider` 交付 `GitHubAccessToken`，並由 Integration 內的 request authorizer 為每一個 GitHub REST request 設定或覆寫 `Authorization: Bearer …`；`RivetHTTPClient` 保持通用，不認識 token、credential lifecycle 或 GitHub authorization policy。`GitHubGraphQLAdapter` 維持 Apollo-only route，不經此 authorizer → HTTP client flow。

初始 credential 是使用者預先提供的一個 fine-grained PAT。此 topic 只鎖定 boundary 與未來 direction，不建立 Swift 實作或 executable behavior。

## Non-Goal

- 不建立 Swift source、module、package、target、protocol、Keychain item 或可執行 authorization 行為。
- 不實作 OAuth、refresh token、401 retry、PAT UI、Keychain adapter、URLSession transport、GitHub API DTO 或 PR Inbox／PR Reader adapter。
- 不決定 Keychain 的 service/account identity、entitlement 或儲存／寫入流程。
- 不改變 `RivetHTTPClient` 的 public API、constructor、headers、transport 或 error contract。

## In-Scope

- 記錄 GitHub Integration 擁有 future authorization seam 的長期 architecture boundary。
- 鎖定 declaration-only direction：未來 GitHub Integration 內的 `GitHubTokenProvider` 負責 token delivery，並交付 Integration-owned `GitHubAccessToken`；它不是 `String` 或 HTTP package type。具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 均延後至獨立 failure-contract topic 決定。
- 鎖定每個 GitHub REST request 的 future flow：取得既有 PAT → authorizer 設定或覆寫 Bearer `Authorization` → `RivetHTTPClient` 執行 REST raw request；不將此 flow 套用至 GraphQL／Apollo。
- 限縮 adapter routing：只有 `GitHubRESTAdapter` 的 request 會經 Integration-owned authorizer 後交給 `RivetHTTPClient`；`GitHubGraphQLAdapter` 封裝 `ApolloClient`，不經 `RivetHTTPClient.Transport`。Apollo token interceptor 留待獨立 topic。
- 將 Keychain 與使用者設定的 PAT 表示為 Outside；token、OAuth、HTTP status、DTO 與 infrastructure details 不跨越 PR Inbox／PR Reader core Port。
- 兩張 canonical diagram 的 authorizer／request preparation wording 都必須限於 GitHub REST request；canvas 保持 ownership／compile-time boundary，lifecycle 不推論 GraphQL／Apollo route。正式 delivery 由獨立 Implementer 依各 artifact 的 build／deliver contract 重建 generated output。
- human 已決定保留 GitHub Integration BC 與 canonical diagrams。衝突樹中的 GitHub GraphQL SDL 僅是 future GitHub Integration GraphQL adapter／schema snapshot topic 的 candidate material；它不建立 PR Reader local-exclusive Infra ownership，也不鎖定 adapter、Apollo interceptor、token delivery、failure、refresh 或 re-auth contract。
- 為恢復 retained boundary，後續受限 implementation 必須只改六份 active architecture docs 與 bounded-context map：六份 docs 移除 local-exclusive Infra／future `GitHubTransport`／Integration retirement claims；map 的 `scene.js` 經正式 renderer 產出 `index.html`，重建中央 GitHub Integration construct、Core／Port isolation 與非 runtime 的 boundary 表達。
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

## Acceptance Criteria

1. 四份正式 artifacts 使用相同 slug，且 plan 保留 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify、TestCase、Future Swift Implementation Slices。
2. 獨立 Implementer 交付後，長期文件與兩張圖一致表達 Integration-only ownership、fine-grained PAT-only 初版，以及 HTTP package 不具 auth lifecycle。
3. 獨立 Implementer 交付的 lifecycle artifact 僅表達 declaration-only request preparation；不得描述 OAuth、refresh、401 retry 或 concrete network implementation。
4. 獨立 Tester 與 Reviewer 確認 topic diff 不含 Swift source、module、package、manifest 或 HTTP package 變更，才交由 human review。
5. language thread remediation 僅於 lifecycle artifact-local `BUILD.md` 記錄 Archify 的 `en`／`zh-CN` renderer limitation、繁體中文作者內容的 `meta.locale` omission，以及英文 Viewer／HTML fallback；不改動 lifecycle JSON、generated HTML、receipt 或 visual evidence。
6. BC 文件明確區分 REST 與 GraphQL route：僅 REST request 經 authorizer 後使用 `RivetHTTPClient`；GraphQL 保持 Apollo-only route，且 Apollo token interceptor 明確延後至獨立 topic。
7. 兩張 canonical diagram 的 source 與正式 generated output 一致以 GitHub REST request 限縮 authorizer／request wording；不產生 GraphQL／Apollo runtime flow，且 canvas 仍不表達 runtime sequence。

## Evidence Sources

- `README.md`：Rivet 目前仍以 architecture baseline 為主，正式 topic 需留下可追溯的 analysis、plan 與 docs。
- `docs/design-principles.md`：OAuth／Keychain、HTTP status、DTO 與 infrastructure failure 不得洩漏到核心 BC；不得因未來需求提早建立抽象。
- `docs/architecture/bounded-contexts/github-integration.md`：GitHub Integration 是隔離 GitHub 外部資料與 infrastructure failure 的 Supporting BC；`RivetHTTPClient` 是可採用的內部 transport foundation。
