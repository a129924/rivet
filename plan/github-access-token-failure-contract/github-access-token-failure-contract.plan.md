# GitHub Access Token Failure Contract

## Summary

在 root Swift package 新增單一 `GitHubIntegration` library target，提供 GitHub-scoped token store/provider contract 與 store-backed provider。此 target 為 BC 外的 shared GitHub-specific integration capability；`Contracts/` 與 `Providers/` 僅為 target 內的 physical organization。

## Goal

提供可注入、同步、typed-throws 的 token store/provider contract，並固定 missing credential 與 persistence/I/O failure 的 provider mapping，不建立任何 persistence 或 authorization adapter。

## Non-Goal

不實作 Keychain、設定 UI、REST authorizer/API adapter、OAuth、refresh、re-auth、401 retry、多帳號、GitHub Enterprise、GraphQL、Apollo、HTTP/transport policy、Domain failure mapping、`async`、cancellation 或 `Sendable`。

## In-Scope

- 新增 root `Package.swift` 的單一 `GitHubIntegration` product、target 與 test target；source path 為 `Sources/BoundedContexts/GitHubIntegration`，tests 為 `Tests/GitHubIntegrationTests/`。
- 新增 `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- 新增 typed-throws `GitHubTokenStore` 與 `GitHubTokenProvider` protocols。
- 新增 public `TokenStoreGitHubTokenProvider`，以 `init(store: any GitHubTokenStore)` 注入 store，並實作指定 failure mapping。
- 最小更新 architecture README 與 bounded-contexts index，記錄已實作的 shared-module token contract，且維持其餘 GitHub integration capability deferred。

## Out-Of-Scope

- 新增 module/target，或將 folder organization 解讀為 architecture boundary。
- `RivetHTTPClient`、PR Inbox、PR Reader 或任何 Domain target 的依賴、source、tests 或 manifests 變更。
- Keychain、Security、REST、GraphQL/Apollo、OAuth、token lifecycle 或 HTTP status policy。

## Swift Physical Layout

```text
Sources/BoundedContexts/GitHubIntegration/
├── Contracts/
│   ├── CredentialTypes.swift
│   ├── GitHubTokenStore.swift
│   └── GitHubTokenProvider.swift
└── Providers/
    └── TokenStoreGitHubTokenProvider.swift

Tests/GitHubIntegrationTests/
```

- `CredentialTypes.swift` 包含四個 value/error types。
- 兩個 protocol 各自位於同名 Contracts file。
- provider implementation 位於 Providers file；只負責 store injection 與 specified mapping。

## Public Contract

- `GitHubAccessToken` 公開 `rawValue` 與 `init(rawValue:)`；不驗證、正規化、輸出或記錄 token。
- `TokenStoreOperation` 為 `.load`、`.save`、`.delete`。
- `TokenStoreError` 公開保存 `operation`、`underlyingError`，並有 `init(operation:underlyingError:)`。
- `GitHubCredentialError` 為 `.missingCredential`、`.tokenStore(TokenStoreError)`。
- `GitHubTokenStore` 的 `load()`、`save(_:)`、`delete()` 都是 `throws(TokenStoreError)`；`load()` 回傳 optional token。
- `GitHubTokenProvider.token()` 是 `throws(GitHubCredentialError) -> GitHubAccessToken`。
- provider 將 `nil` 映射為 `.missingCredential`；將 store `TokenStoreError` 映射為 `.tokenStore(error)`，不改寫 error details。

## File-Impact Contract

### ReadOnly

`RivetHTTPClient`、PR Inbox、PR Reader、所有 other Domain target/source/tests、既有 HTTP/GraphQL source/tests、architecture diagrams 與既有 BC boundary decisions。

### Written

- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
- `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- `Tests/GitHubIntegrationTests/` 的 contract/provider tests。
- 四份同 slug planning artifacts。

### Modify

- Root `Package.swift`：只加入 `GitHubIntegration` product、target、test target 與 source/test paths。
- `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`：僅回寫本 topic 已鎖定的 contract 事實；不改變 BC boundary 或 deferred responsibility。

### Deleted

無；不得刪除、搬移或更名 existing files。

## TestCase

- `GitHubAccessToken` 原樣保存 raw value，test output 不含 secret。
- mock store 成功回傳 token 時，provider 原樣回傳。
- mock store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- mock store 的 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，保留 `.load` 與 original underlying error。
- 外部 mock store 可符合三個 typed-throws methods，並使用 public `TokenStoreError` initializer。
- provider 可由 `init(store:)` 注入 mock store，並符合 `GitHubTokenProvider`。
- package target/test-target layout、target dependency 與 imports 維持 isolation；執行 root `swift test` 及 `git diff --check`。

## Implementation Handoff

1. 取得獨立 Plan-Reviewer 對本 topic 四份 artifacts 的明示 `approved` verdict。
2. Implementer 只在 feature worktree 依上述 layout 寫入 Written/Modify targets；不得重開 locked API、failure mapping、target dependency、scope 或 Non-Goal。
3. Tester 獨立執行 contract/isolation checks、root `swift test` 與 `git diff --check`，如實回報結果。
4. Reviewer 獨立審查 implementation、evidence、scope 與 workflow drift，發出明示 verdict。
5. 僅當 Reviewer 為 `approved` 且 human delivery authority 已存在時，Implementer 可進行 topic commit、push、draft PR。draft PR 開啟後停止並交還 human review；不得自動 merge 或 release。
