# GitHub Integration Authorization Boundary：需求

## Goal

鎖定 GitHub Integration 的 authorization ownership。未來由 GitHub Integration 擁有的 `GitHubTokenProvider` 交付 `GitHubAccessToken`，並由 Integration 內的 request authorizer 為每一個 GitHub request 設定或覆寫 `Authorization: Bearer …`；`RivetHTTPClient` 保持通用，不認識 token、credential lifecycle 或 GitHub authorization policy。

初始 credential 是使用者預先提供的一個 fine-grained PAT。此 topic 只鎖定 boundary 與未來 direction，不建立 Swift 實作或 executable behavior。

## Non-Goal

- 不建立 Swift source、module、package、target、protocol、Keychain item 或可執行 authorization 行為。
- 不實作 OAuth、refresh token、401 retry、PAT UI、Keychain adapter、URLSession transport、GitHub API DTO 或 PR Inbox／PR Reader adapter。
- 不決定 Keychain 的 service/account identity、entitlement 或儲存／寫入流程。
- 不改變 `RivetHTTPClient` 的 public API、constructor、headers、transport 或 error contract。

## In-Scope

- 記錄 GitHub Integration 擁有 future authorization seam 的長期 architecture boundary。
- 鎖定 declaration-only direction：未來 GitHub Integration 內的 `GitHubTokenProvider` 負責 token delivery，並交付 Integration-owned `GitHubAccessToken`；它不是 `String` 或 HTTP package type。具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 均延後至獨立 failure-contract topic 決定。
- 鎖定每個 GitHub request 的 future flow：取得既有 PAT → authorizer 設定或覆寫 Bearer `Authorization` → `RivetHTTPClient` 執行 raw request。
- 將 Keychain 與使用者設定的 PAT 表示為 Outside；token、OAuth、HTTP status、DTO 與 infrastructure details 不跨越 PR Inbox／PR Reader core Port。
- 建立本 topic 的正式 planning artifacts。長期 BC 文件與圖表的受限 delivery 必須在 Plan-Reviewer 通過後，交由獨立 Implementer 執行，並經獨立 Tester、Reviewer 與 human review。

## Out-Of-Scope

- generic `TokenProvider`，或 `HTTPClient` constructor／public API 的 token dependency。
- `GitHubTokenProvider` 的具體 Swift signature、`throws`／`Outcome` 選擇，或 credential failure、refresh／re-auth contract。
- token refresh、refresh token schema、OAuth grant、401 retry、多帳號、GitHub Enterprise 與跨裝置同步。
- concrete network request、HTTP status policy、decode policy、DTO mapping，以及各 core BC 的 failure mapping。
- 任何 core Port 的 credential、OAuth、HTTP 或 infrastructure type。

## Acceptance Criteria

1. 四份正式 artifacts 使用相同 slug，且 plan 保留 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify、TestCase、Future Swift Implementation Slices。
2. 獨立 Implementer 交付後，長期文件與兩張圖一致表達 Integration-only ownership、fine-grained PAT-only 初版，以及 HTTP package 不具 auth lifecycle。
3. 獨立 Implementer 交付的 lifecycle artifact 僅表達 declaration-only request preparation；不得描述 OAuth、refresh、401 retry 或 concrete network implementation。
4. 獨立 Tester 與 Reviewer 確認 topic diff 不含 Swift source、module、package、manifest 或 HTTP package 變更，才交由 human review。

## Evidence Sources

- `README.md`：Rivet 目前仍以 architecture baseline 為主，正式 topic 需留下可追溯的 analysis、plan 與 docs。
- `docs/design-principles.md`：OAuth／Keychain、HTTP status、DTO 與 infrastructure failure 不得洩漏到核心 BC；不得因未來需求提早建立抽象。
- `docs/architecture/bounded-contexts/github-integration.md`：GitHub Integration 是隔離 GitHub 外部資料與 infrastructure failure 的 Supporting BC；`RivetHTTPClient` 是可採用的內部 transport foundation。
