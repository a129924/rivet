# GitHub Access Token Failure Contract

## Summary

在 root Swift package 新增單一 `GitHubIntegration` library target，提供 GitHub-scoped token store/provider contract 與 store-backed provider。此 target 為 BC 外的 shared GitHub-specific integration capability；`Contracts/` 與 `Providers/` 僅為 target 內的 physical organization。

## Goal

提供可注入、同步、typed-throws 的 token store/provider contract，並固定 missing credential 與 persistence/I/O failure 的 provider mapping，不建立任何 persistence 或 authorization adapter。

## Non-Goal

不實作 Keychain、設定 UI、REST authorizer/API adapter、OAuth、refresh、re-auth、401 retry、多帳號、GitHub Enterprise、GraphQL、Apollo、HTTP/transport policy、Domain failure mapping、`async`、cancellation，或除 `TokenStoreOperation: Sendable` 外的新增 explicit `Sendable` conformance 或 concurrency behavior。

## In-Scope

- 新增 root `Package.swift` 的單一 `GitHubIntegration` product、target 與 test target；source path 為 `Sources/BoundedContexts/GitHubIntegration`，tests 為 `Tests/GitHubIntegrationTests/`。
- 新增 `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- 唯一新增的 explicit public conformance 為 `TokenStoreOperation: Sendable`，作為 Swift 6 warnings-as-errors remediation；`TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 具有 Swift 隱含 `Sendable` 關係，但不新增其 explicit conformance 或其他 concurrency behavior。
- 新增 typed-throws `GitHubTokenStore` 與 `GitHubTokenProvider` protocols。
- 新增 public `TokenStoreGitHubTokenProvider`，以 `init(store: any GitHubTokenStore)` 注入 store，並實作指定 failure mapping。
- 最小更新 `docs/design-principles.md`、architecture README、bounded-contexts index 與 PR Inbox BC 文件，記錄已實作的 shared-module token contract，且維持其餘 GitHub integration capability deferred。
- 以 `architecture-canvas` validation/build 更新 bounded-context map 的 `scene.js` 與生成 `index.html`，不再將此受限 module 標示為未實作；不得發布 artifact.cafe。

## Out-Of-Scope

- 新增 module/target，或將 folder organization 解讀為 architecture boundary。
- `RivetHTTPClient`、PR Inbox、PR Reader 或任何 Domain target 的依賴、source、tests 或 manifests 變更；唯一允許的是 PR Inbox BC 文件的 factual architecture writeback。
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
- `TokenStoreOperation: Sendable` 為 `.load`、`.save`、`.delete`；此為唯一新增的 explicit public conformance。`TokenStoreError` 與 `GitHubCredentialError` 作為 `Error` 有 Swift 隱含 `Sendable` 關係，但本 topic 不額外宣告 conformance。
- `TokenStoreError` 公開保存 `operation`、`underlyingError`，並有 `init(operation:underlyingError:)`。
- `GitHubCredentialError` 為 `.missingCredential`、`.tokenStore(TokenStoreError)`。
- `GitHubTokenStore` 的 `load()`、`save(_:)`、`delete()` 都是 `throws(TokenStoreError)`；`load()` 回傳 optional token。
- `GitHubTokenProvider.token()` 是 `throws(GitHubCredentialError) -> GitHubAccessToken`。
- provider 將 `nil` 映射為 `.missingCredential`；將 store `TokenStoreError` 映射為 `.tokenStore(error)`，不改寫 error details。

## File-Impact Contract

### ReadOnly

`RivetHTTPClient`、PR Inbox、PR Reader、所有 other Domain target/source/tests、既有 HTTP/GraphQL source/tests、除 bounded-context map 外的 architecture diagrams，以及既有 BC boundary decisions。

### Written

- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
- `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift` 的 contract/provider tests 與 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 static-isolation test。
- `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 canonical factual writeback：只更新為已實作的 `GitHubIntegration` token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- 四份同 slug planning artifacts。

### Modify

- Root `Package.swift`：只加入 `GitHubIntegration` product、target、test target 與 source/test paths。
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：只新增 explicit `TokenStoreOperation: Sendable`；`TokenStoreError` 與 `GitHubCredentialError` 僅維持因 `Error` 而有的 Swift 隱含 `Sendable` 關係，不額外宣告 conformance；不改變其他 API 或 failure mapping。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：以 structured package/target graph assertion 取代 substring checks，驗證四個 production source paths 的 exact set、枚舉實際 target sources、檢查禁止 imports，並驗收 `TokenStoreOperation: Sendable` compile contract；不得新增其他 test source 或 scope。
- `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`：僅回寫本 topic 已鎖定的 contract 事實；不改變 BC boundary 或 deferred responsibility。
- `docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`：只將「若建立／未來／尚未實作」的 `GitHubIntegration` token-contract 描述更新為已實作，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred；不得新增 API、scope 或 architecture decision。
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與生成 `index.html`：只同步已實作的 access-token contract 與 deferred capability，必須以 `architecture-canvas` validation/build 產生；不得發布 artifact.cafe。
- pre-integration merge：只允許 non-force merge `origin/dev`；只 resolve `docs/architecture/README.md` 的單一 semantic hunk，且必須同時保留本 topic 的 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。

### Deleted

無；不得刪除、搬移或更名 existing files。

## TestCase

- `GitHubAccessToken` 原樣保存 raw value，test output 不含 secret。
- mock store 成功回傳 token 時，provider 原樣回傳。
- mock store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- mock store 的 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，保留 `.load` 與 original underlying error。
- 外部 mock store 可符合三個 typed-throws methods，並使用 public `TokenStoreError` initializer。
- provider 可由 `init(store:)` 注入 mock store，並符合 `GitHubTokenProvider`。
- `TokenStoreOperation` 的 explicit public `Sendable` conformance 可通過編譯期驗證；其他 token/store/provider contract 不新增 explicit conformance 或 concurrency behavior，並保留 error types 因 `Error` 而有的 Swift 隱含 `Sendable` 關係。
- static-isolation test 必須以 structured package/target graph assertion 驗證 single target、四個 production source paths 的 exact set、actual target source enumeration 與禁止 imports；不得用 substring check 取代此驗證。
- package target/test-target layout、target dependency 與 imports 維持 isolation；執行 root `swift test` 及 `git diff --check`。
- bounded-context map source/generated artifact 通過 `architecture-canvas` validation/build，並如實呈現已實作的受限 shared module。
- PR Reader BC 文件與 GitHub API README 如實呈現已實作的 token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- pre-integration merge 後確認 README resolved hunk 同時保留兩方指定 wording；不得 rebase、force push 或以單方版本覆寫 conflict。

## PR Comment Triage

五項 PR comments 的處置僅校正 planning truth：

- PC-01：`TokenStoreOperation: Sendable` 是唯一新增 explicit public conformance。
- PC-02：`TokenStoreError`、`GitHubCredentialError` 因 `Error` 有 Swift 隱含 `Sendable` 關係；不新增 explicit conformance 或 concurrency behavior。
- PC-03：RV-03 歷史 `needs-rework` verdict 保持不變。
- PC-04：DL-02 撤除 `eligible`，回復 `pending`。
- PC-05：既有 `PR-06 → IM-04 → TE-04` 已完成；TE-04 pass 後的 README conflict 使 delivery route 改為 `RV-04 → CF-01 → IN-01 → TE-05 → RV-05`，delivery 只依 RV-05 明示 `approved`。

## Implementation Handoff

1. 取得獨立 Plan-Reviewer 對本 topic 四份 artifacts 的明示 `approved` verdict。
2. Implementer 只在 feature worktree 依上述 layout 寫入 Written/Modify targets；human 授權的 amendment 限於 `CredentialTypes.swift` 的唯一新增 explicit `TokenStoreOperation: Sendable`、`StaticIsolationTests.swift` 的 graph/source/import/Sendable checks，以及列出的 canonical truth/map writeback。`TokenStoreError` 與 `GitHubCredentialError` 的 Swift 隱含 `Sendable` 關係不得成為新增 explicit conformance 或 concurrency behavior 的理由。`pr-reader.md` 與 GitHub API README 只能改為已實作 token contract、Keychain/authorizer/REST/OAuth lifecycle deferred。bounded-context map 必須透過 `architecture-canvas` validation/build 更新，且不得發布 artifact.cafe；不得新增其他 source/test，或重開其餘 locked API、failure mapping、target dependency、scope、Non-Goal 或 architecture decision。
3. RV-03 的 historical `needs-rework` verdict 不得重寫為 `approved`；DL-02 維持 `pending` 且不得標記 eligible。TE-04 已 pass，但 README base conflict 與未提交 comment fixes 使 merge/delivery 不安全。fresh corrective route 固定為 RV-04（獨立 Code-Reviewer，僅 review IM-04 snapshot）→ CF-01（authorized single comment-fix commit，非 delivery completion）→ IN-01（Code-Implementer non-force merge `origin/dev`，只 resolve README semantic hunk 並保留兩方指定 wording）→ TE-05（獨立 Tester）→ RV-05（獨立 Code-Reviewer fresh verdict）。
4. DL-02 僅當 RV-05 明示 `approved` 且既有 human delivery authority 存在時，才可進入；屆時 Implementer 才可 push，並只 resolve 已完成的 PR threads。不得 rebase、force push、自動 merge 或 release；PR 維持 human review boundary。
