# GitHub Access Token Failure Contract：需求

## Goal

建立 `GithubIntegration` 的單一、可注入、同步且 typed-throws 的 GitHub access-token store/provider contract。此切片固定 token 尚未保存與 token store persistence failure 的 provider mapping，供未來 GitHub-specific integration capability 使用，而不跨越任何 Domain Bounded Context 邊界。

## Non-Goal

本 topic 不交付任何 credential persistence、authorization、transport 或 Domain behavior；這些 capability 均須由獨立 topic 鎖定。

## In-Scope

- 單一 root Swift package library product 與 target：`GitHubIntegration`，其 target path 為 `Sources/BoundedContexts/GitHubIntegration`。
- `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- typed-throws `GitHubTokenStore` 與 `GitHubTokenProvider` protocols。
- 注入 `any GitHubTokenStore` 的 `TokenStoreGitHubTokenProvider`，以及固定的 `nil`／store-error provider mapping。
- `GitHubIntegration` test target，位置為 `Tests/GitHubIntegrationTests/`。
- 對已鎖定 token contract 的最小 architecture writeback；不重開 existing `GithubIntegration` shared-module boundary。

## Out-Of-Scope

- Keychain 或任何 concrete credential persistence adapter、設定 UI。
- REST authorizer/API adapter、OAuth、refresh、re-auth、401 retry、多帳號、GitHub Enterprise、GraphQL 或 Apollo。
- HTTP status、transport、Domain failure mapping、endpoint、DTO 或 business meaning。
- `async`、cancellation 與 `Sendable` contract。

## Success Criteria

- consuming code 可經公開 protocol 注入 store，取得原樣的 `GitHubAccessToken`。
- 未保存 token 的正常狀態只由 provider 表示為 `.missingCredential`。
- Store 的 persistence/I/O failure 只由 provider 包裝為 `.tokenStore(TokenStoreError)`，並保留 operation 與 underlying error。
- 新 target 不依賴 `RivetHTTPClient`、PR Inbox、PR Reader 或其他 Domain target，也不 import Security、Keychain 或 Apollo。

## ReadOnly

- `RivetHTTPClient` 及其 tests。
- PR Inbox、PR Reader 與所有其他 Domain target/source/tests。
- 既有 HTTP、GraphQL、architecture diagram 與 Bounded Context boundary decisions。

## Written

- 實作階段新增下列 `GitHubIntegration` target source：
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- 實作階段新增 `Tests/GitHubIntegrationTests/` 下的 contract/provider tests。
- 本 topic 的四份 planning artifacts。

## Modify

- Root `Package.swift`：只新增 `GitHubIntegration` product、target 與 test target；不改變既有 target dependency。
- `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/README.md`：只回寫本 topic 已實作的 shared-module token contract，維持 existing boundary wording 與 deferred capabilities。

## Deleted

無；不得刪除、搬移或更名既有檔案。

## TestCase

- token raw value 原樣保留與傳遞，測試不可輸出 secret。
- store 成功讀取 token 時，provider 原樣回傳。
- store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- store 在 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，且保留 `.load` 與 underlying error。
- 外部 mock store 可實作三個 typed-throws methods，並透過公開 initializer 建構 `TokenStoreError`。
- provider 可由 `init(store:)` 注入 mock store 並符合 `GitHubTokenProvider`。
- 驗證 target dependency/import isolation，以及 root `swift test` 與 `git diff --check`。

## Implementation Handoff

實作僅能寫入 Written 與 Modify 欄位列出的 targets。必須先取得獨立 Plan-Reviewer 對四份 artifacts 的明示 `approved` verdict；完成後交由獨立 Tester，再交由獨立 Reviewer。若最終 Reviewer 明示 `approved`，topic delivery 才可依 human 授權進行 commit、push 與 draft PR；draft PR 後停止於 human review boundary。
