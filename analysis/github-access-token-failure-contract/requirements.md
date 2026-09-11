# GitHub Access Token Failure Contract：需求

## Goal

建立 `GithubIntegration` 的單一、可注入、同步且 typed-throws 的 GitHub access-token store/provider contract。此切片固定 token 尚未保存與 token store persistence failure 的 provider mapping，供未來 GitHub-specific integration capability 使用，而不跨越任何 Domain Bounded Context 邊界。

## Non-Goal

本 topic 不交付任何 credential persistence、authorization、transport 或 Domain behavior；這些 capability 均須由獨立 topic 鎖定。

## In-Scope

- 單一 root Swift package library product 與 target：`GitHubIntegration`，其 target path 為 `Sources/BoundedContexts/GitHubIntegration`。
- `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- 唯一新增的 explicit public conformance 為 `TokenStoreOperation: Sendable`；此 conformance 僅滿足 Swift 6 warnings-as-errors 的跨隔離 diagnostics，不擴大 token/store/provider API 的 concurrency behavior。`TokenStoreError` 與 `GitHubCredentialError` 作為 `Error` 有 Swift 隱含的 `Sendable` 關係；本 topic 不額外宣告其 `Sendable` conformance。
- typed-throws `GitHubTokenStore` 與 `GitHubTokenProvider` protocols。
- 注入 `any GitHubTokenStore` 的 `TokenStoreGitHubTokenProvider`，以及固定的 `nil`／store-error provider mapping。
- `GitHubIntegration` test target，位置為 `Tests/GitHubIntegrationTests/`。
- 對已鎖定 token contract 的最小 architecture writeback；不重開 existing `GithubIntegration` shared-module boundary。

## Out-Of-Scope

- Keychain 或任何 concrete credential persistence adapter、設定 UI。
- REST authorizer/API adapter、OAuth、refresh、re-auth、401 retry、多帳號、GitHub Enterprise、GraphQL 或 Apollo。
- HTTP status、transport、Domain failure mapping、endpoint、DTO 或 business meaning。
- `async`、cancellation，以及除 `TokenStoreOperation: Sendable` 外的任何新增 explicit `Sendable` conformance 或 concurrency behavior。

## Success Criteria

- consuming code 可經公開 protocol 注入 store，取得原樣的 `GitHubAccessToken`。
- 未保存 token 的正常狀態只由 provider 表示為 `.missingCredential`。
- Store 的 persistence/I/O failure 只由 provider 包裝為 `.tokenStore(TokenStoreError)`，並保留 operation 與 underlying error。
- 新 target 不依賴 `RivetHTTPClient`、PR Inbox、PR Reader 或其他 Domain target，也不 import Security、Keychain 或 Apollo。
- `TokenStoreOperation` 可作為 `Sendable` value 使用；此不新增 token、store 或 provider 的 explicit `Sendable` conformance 或 concurrency behavior，亦不否定 error types 因符合 `Error` 而有的 Swift 隱含 `Sendable` 關係。

## ReadOnly

- `RivetHTTPClient` 及其 tests。
- PR Inbox、PR Reader 與所有其他 Domain target/source/tests。
- 既有 HTTP、GraphQL、未列於 Modify 的 architecture diagrams 與 Bounded Context boundary decisions。

## Written

- 實作階段新增下列 `GitHubIntegration` target source：
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- 實作階段新增 `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift` 與 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 contract/provider and static-isolation tests。
- `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 canonical factual writeback：只將 `GitHubIntegration` access-token contract 從「若建立／未來／尚未實作」更新為已實作，並明確保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- 本 topic 的四份 planning artifacts。

## Modify

- Root `Package.swift`：只新增 `GitHubIntegration` product、target 與 test target；不改變既有 target dependency。
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：唯一許可的新增 explicit source conformance 是 `TokenStoreOperation: Sendable`；`TokenStoreError` 與 `GitHubCredentialError` 僅維持因 `Error` 而有的 Swift 隱含 `Sendable` 關係，不額外宣告 conformance，也不得改變其他 public API、token behavior 或 failure mapping。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：將 substring checks 改為 structured package/target graph assertion、驗證四個 production source paths 的 exact set、枚舉實際 target sources 並檢查禁止 imports，另驗收 `TokenStoreOperation: Sendable` compile contract；不得新增其他 test source 或擴大 test scope。
- `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`：只回寫本 topic 已實作的 shared-module token contract，維持 existing boundary wording 與 deferred capabilities。
- `docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`：只回寫已實作的 `GitHubIntegration` access-token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle 為 deferred；不得新增 API、scope 或 architecture decision。
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與其生成的 `index.html`：將 `GitHubIntegration` 由「尚未實作」更正為已實作的 lower shared GitHub-specific module，並僅表達本 topic 的 access-token contract 與既有 deferred capabilities；不改變 BC、dependency 或 responsibility boundary。圖的更新必須依 `architecture-canvas` 完成 validation/build，且不得發布 artifact.cafe。
- pre-integration merge 僅允許以 non-force merge 整合 `origin/dev`；`docs/architecture/README.md` 的 conflict 只可處理單一 semantic hunk，並同時保留本 topic 的 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。

## Deleted

無；不得刪除、搬移或更名既有檔案。

## TestCase

- token raw value 原樣保留與傳遞，測試不可輸出 secret。
- store 成功讀取 token 時，provider 原樣回傳。
- store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- store 在 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，且保留 `.load` 與 underlying error。
- 外部 mock store 可實作三個 typed-throws methods，並透過公開 initializer 建構 `TokenStoreError`。
- provider 可由 `init(store:)` 注入 mock store 並符合 `GitHubTokenProvider`。
- `TokenStoreOperation` 可通過編譯期 `Sendable` conformance check；不得藉此要求其他 public token/store/provider type 採用 `Sendable`。
- static-isolation test 以 structured package/target graph assertion 驗證 single `GitHubIntegration` target、四個 production source paths 的 exact set、實際 target source enumeration 與禁止 imports；不得用脆弱的 substring check 取代 graph/source validation。
- 驗證 target dependency/import isolation，以及 root `swift test` 與 `git diff --check`。
- architecture map source 與生成 artifact 經 `architecture-canvas` validation/build 同步，並明確呈現「已實作的受限 token contract」與 deferred capability。
- `pr-reader.md` 與 GitHub API README 不再將已實作的 token contract 表示為「若建立／未來／尚未實作」，並仍明確保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- pre-integration merge 後確認 `docs/architecture/README.md` 的 resolved semantic hunk 同時保留 `GitHubIntegration` 已實作／deferred wording 與 HTTP decoded payload `Decodable & Sendable` sentence；不得用單方覆寫消除 conflict。

## PR Comment Triage

本次五項 PR comments 均為已授權的 planning-truth correction，不新增 API、scope 或 architecture decision：

- PC-01：將「唯一 public `Sendable`」更正為唯一新增 explicit conformance `TokenStoreOperation: Sendable`。
- PC-02：明確記錄 `TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 而有的 Swift 隱含 `Sendable` 關係；不新增 explicit conformance 或 concurrency behavior。
- PC-03：RV-03 的歷史 verdict 保持 `needs-rework`，不得重寫為 `approved`。
- PC-04：DL-02 撤除 `eligible`，恢復為 `pending`；不得以 LR-01 取代 reviewer approval。
- PC-05：既有 `PR-06 → IM-04 → TE-04` 已完成；TE-04 pass 後的 README conflict 使 delivery route 改為 `RV-04 → CF-01 → IN-01 → TE-05 → RV-05`，只有 RV-05 明示 `approved` 才可進入 delivery。

## Implementation Handoff

PR comment amendment 已由 human 明確授權：只允許唯一新增 explicit conformance `TokenStoreOperation: Sendable`（不額外宣告 `TokenStoreError` 或 `GitHubCredentialError` 的 `Sendable` conformance）、指定 canonical document/map 的 factual writeback，以及 `StaticIsolationTests.swift` 的 structured static-isolation remediation。Implementer 僅能寫入 Written 與 Modify 欄位列出的 targets：source 限 `CredentialTypes.swift` 的單一 explicit conformance，test 限 `StaticIsolationTests.swift` 的 graph/source/import/Sendable checks，`pr-reader.md` 與 GitHub API README 限「已實作 token contract、Keychain/authorizer/REST/OAuth lifecycle deferred」的 factual wording；不得新增其他 source、test、public API、scope 或 architecture decision。bounded-context map 必須以 `architecture-canvas` validation/build 同步，且不得發布 artifact.cafe。RV-03 的 historical `needs-rework` 保持原狀，DL-02 維持 `pending`。TE-04 已 pass，但 `docs/architecture/README.md` 與 `origin/dev` 的 base conflict，加上未提交 comment fixes，使 delivery／merge 不安全。最小 corrective route 固定為：RV-04 由獨立 Code-Reviewer 只 review IM-04 snapshot；其明示 `approved` 後，CF-01 以單一 authorized comment-fix commit 記錄既有 fixes（不是 delivery completion）；IN-01 由 Code-Implementer non-force merge `origin/dev`，只 resolve README 的單一 semantic hunk，保留兩方指定 wording；TE-05 由獨立 Tester 驗證 merge 結果，RV-05 由獨立 Code-Reviewer 發出 fresh verdict。只有 RV-05 明示 `approved`，才可進入 DL-02 的既有 human-authorized push 與已完成 PR thread resolution；PR 維持 human review boundary，不得 rebase 或 force push。
