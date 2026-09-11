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
- 新增獨立 consumer fixture package，只驗證 root package 匯出的 `GitHubIntegration` public API，不新增 root module 或 target。
- 最小更新 `docs/design-principles.md`、architecture README、bounded-contexts index 與 PR Inbox BC 文件，記錄已實作的 shared-module token contract，且維持其餘 GitHub integration capability deferred。
- 以 `architecture-canvas` validation/build 更新 bounded-context map 的 `scene.js` 與生成 `index.html`，不再將此受限 module 標示為未實作；不得發布 artifact.cafe。

## Out-Of-Scope

- 新增 module/target，或將 folder organization 解讀為 architecture boundary。
- `RivetHTTPClient`、PR Inbox、PR Reader 或任何 Domain target 的依賴、source、tests 或 manifests 變更；唯一允許的是 PR Inbox BC 文件的 factual architecture writeback。
- Keychain、Security、REST、GraphQL/Apollo、OAuth、token lifecycle 或 HTTP status policy。
- root `Package.swift`、既有 `GitHubIntegration` product/target、production source、public API、failure contract 或 dependency graph 變更；consumer verification 不得使用 `@testable`。

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

Tests/GitHubIntegrationConsumer/
├── Package.swift
└── Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift
```

- `CredentialTypes.swift` 包含四個 value/error types。
- 兩個 protocol 各自位於同名 Contracts file。
- provider implementation 位於 Providers file；只負責 store injection 與 specified mapping。
- consumer fixture 是獨立 package，固定 local path `../..`、macOS 15／Swift 6、單一 test target，並只依賴 package `Rivet` 的 `GitHubIntegration` product；其 test 僅 `import GitHubIntegration`。

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

`RivetHTTPClient`、PR Inbox、PR Reader、所有 other Domain target/source/tests、既有 HTTP/GraphQL source/tests、root `Package.swift`、既有 `GitHubIntegration` product/target 與所有 production source/public API、除 bounded-context map 外的 architecture diagrams，以及既有 BC boundary decisions。

### Written

- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
- `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift` 的 contract/provider tests 與 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 static-isolation test。
- `Tests/GitHubIntegrationConsumer/Package.swift` 與 `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` 的 external public-consumer verification。
- `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 canonical factual writeback：只更新為已實作的 `GitHubIntegration` token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- 四份同 slug planning artifacts；AM-09 只寫入這四份 artifacts，不寫入 Swift source、consumer fixture 或 `.swiftlint.yml`。

### Modify

- Root `Package.swift`：只加入 `GitHubIntegration` product、target、test target 與 source/test paths。
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：只新增 explicit `TokenStoreOperation: Sendable`；`TokenStoreError` 與 `GitHubCredentialError` 僅維持因 `Error` 而有的 Swift 隱含 `Sendable` 關係，不額外宣告 conformance；不改變其他 API 或 failure mapping。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：以 structured package/target graph assertion 取代 substring checks，驗證四個 production source paths 的 exact set、枚舉實際 target sources、檢查禁止 imports，並驗收 `TokenStoreOperation: Sendable` compile contract；不得新增其他 test source 或 scope。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：只補 multiline-attribute import parser edge case，維持既有 structured graph/source/import assertions；不得改動 package graph 或 production source set。
- `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md`：僅回寫本 topic 已鎖定的 contract 事實；不改變 BC boundary 或 deferred responsibility。
- `docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`：只將「若建立／未來／尚未實作」的 `GitHubIntegration` token-contract 描述更新為已實作，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred；不得新增 API、scope 或 architecture decision。
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與生成 `index.html`：只同步已實作的 access-token contract 與 deferred capability，必須以 `architecture-canvas` validation/build 產生；不得發布 artifact.cafe。
- pre-integration merge：只允許 non-force merge `origin/dev`；只 resolve `docs/architecture/README.md` 的單一 semantic hunk，且必須同時保留本 topic 的 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。
- AM-09 verification workflow 不修改 tracked source、fixture 或 config；只在 safety checks 通過時處理 ignored generated output 的 exact path。

### Deleted

不得刪除、搬移或更名任何 tracked file。AM-09 唯一許可的 deletion 是 safety checks 通過後的 ignored generated output `Tests/GitHubIntegrationConsumer/.build`；不得刪除其他 target 或 path。

## TestCase

- `GitHubAccessToken` 原樣保存 raw value，test output 不含 secret。
- mock store 成功回傳 token 時，provider 原樣回傳。
- mock store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- mock store 的 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，保留 `.load` 與 original underlying error。
- 外部 mock store 可符合三個 typed-throws methods，並使用 public `TokenStoreError` initializer。
- provider 可由 `init(store:)` 注入 mock store，並符合 `GitHubTokenProvider`。
- `TokenStoreOperation` 的 explicit public `Sendable` conformance 可通過編譯期驗證；其他 token/store/provider contract 不新增 explicit conformance 或 concurrency behavior，並保留 error types 因 `Error` 而有的 Swift 隱含 `Sendable` 關係。
- static-isolation test 必須以 structured package/target graph assertion 驗證 single target、四個 production source paths 的 exact set、actual target source enumeration 與禁止 imports；不得用 substring check 取代此驗證。
- multiline-attribute import parser edge case 必須維持正確 module-root extraction 與 forbidden-import validation。
- 獨立 consumer fixture 固定在同一 shell 先執行 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"`，再執行 `swift test --package-path Tests/GitHubIntegrationConsumer --scratch-path "$RIVET_CONSUMER_BUILD_PATH"`；scratch directory 為 task-scoped temporary path。其後唯一允許的 cleanup 是 exact path `Tests/GitHubIntegrationConsumer/.build`：若不存在（亦非 symlink），不執行 cleanup，直接驗證 absence；若存在或為 symlink，必須先確認為非 symlink directory，並以 `git check-ignore -q -- Tests/GitHubIntegrationConsumer/.build` 證明為 ignored generated build output，才可執行 `rm -rf -- Tests/GitHubIntegrationConsumer/.build`。禁止 broad target、glob 或其他 path；non-directory、symlink、non-ignored、cleanup 或清理後 `test ! -e Tests/GitHubIntegrationConsumer/.build && test ! -L Tests/GitHubIntegrationConsumer/.build` 任一步失敗即為 workflow blocker 並停止。test 只 `import GitHubIntegration`；驗收 token/error public properties、initializers、cases、`TokenStoreOperation: Sendable`、private external typed-throws store mock、provider existential injection 與 success／missing／store-error mapping。只有 absence verification 通過後完整 `swiftlint lint --strict` 與 diff checks 必須通過，且不得修改 `.swiftlint.yml`。
- consumer verification 不得觸及 root manifest、target/product、production source 或任何已鎖定 public contract。
- package target/test-target layout、target dependency 與 imports 維持 isolation；執行 root `swift test` 及 `git diff --check`。
- bounded-context map source/generated artifact 通過 `architecture-canvas` validation/build，並如實呈現已實作的受限 shared module。
- PR Reader BC 文件與 GitHub API README 如實呈現已實作的 token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- pre-integration merge 後確認 README resolved hunk 同時保留兩方指定 wording；不得 rebase、force push 或以單方版本覆寫 conflict。
- historical delivery route `DL-02a → RV-05 → DL-02b` 已不再是 current gate：其後 feature branch、remote branch 與 PR head 已同步至 `67a2cb7`，`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此事實不補造 RV-05 verdict；任何新 PR comment 依當前 evidence 獨立 triage。

## PR Comment Triage

五項 PR comments 的處置僅校正 planning truth：

- PC-01：`TokenStoreOperation: Sendable` 是唯一新增 explicit public conformance。
- PC-02：`TokenStoreError`、`GitHubCredentialError` 因 `Error` 有 Swift 隱含 `Sendable` 關係；不新增 explicit conformance 或 concurrency behavior。
- PC-03：RV-03 歷史 `needs-rework` verdict 保持不變。
- PC-04：amendment 當時的 final thread-resolution gate 維持 `pending`，不得以歷史 evidence 取代 RV-05 remote approval。後續 delivery 已關閉該 historical route；它不提供新 comment 的 resolution authority。
- PC-05：`DL-02a → RV-05 → DL-02b` 是當時 remote 尚未承載已驗證 head 時的 corrective route。其後 delivery 已使 feature branch、remote branch 與 PR head 同步至 `67a2cb7`；`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此記錄不補造 RV-05 verdict，也不是後續 PR comment 的 gate。
- PC-06：multiline attribute parser 與 external public-consumer verification 為新 threads；human 授權 consumer fixture amendment，兩者必須走 fresh gate，historic delivery route 不提供 resolution authority。

## Implementation Handoff

1. 取得獨立 Plan-Reviewer 對本 topic 四份 artifacts 的明示 `approved` verdict。
2. fresh Plan-Reviewer approval 後，Implementer 只在 feature worktree 寫入 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 multiline-attribute import parser edge case，及唯一新增的 `Tests/GitHubIntegrationConsumer/Package.swift`、`Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`。fixture 固定 `../..` local-path dependency、macOS 15、Swift 6、唯一 test target，並只依賴 package `Rivet` 的 `GitHubIntegration` product；public test 固定 `import GitHubIntegration`、禁止 `@testable`。它以 private external typed-throws store mock 驗證 public value/error surface、`TokenStoreOperation: Sendable`、provider existential injection 與既定 mapping。不得修改 root manifest、target/product、production source、public API、failure mapping、scope、Non-Goal 或 architecture decision。
3. RV-03 的 historical `needs-rework` verdict 不得重寫為 `approved`。historic `DL-02a → RV-05 → DL-02b` route 已在後續 delivery 後失去 current-gate 身分：feature branch、remote branch 與 PR head 已同步至 `67a2cb7`，`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此記錄不回填或推論 RV-05 verdict。
4. TE-06 因 default consumer `.build` 被 SwiftLint 掃描而 blocked，PR-10 判定既有 combined command 不可執行。human 已授權 AM-09 minimal cleanup amendment；fresh revalidation route 固定為 Plan-Reviewer → Tester。Tester 必須在同一 shell 先執行 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"`，再以 `--scratch-path "$RIVET_CONSUMER_BUILD_PATH"` 執行 consumer test；其後只可處理 `Tests/GitHubIntegrationConsumer/.build`。若 exact path 不存在且非 symlink，跳過 cleanup；否則它必須是 non-symlink directory，且 `git check-ignore -q -- Tests/GitHubIntegrationConsumer/.build` 證明為 ignored generated build output，才執行 `rm -rf -- Tests/GitHubIntegrationConsumer/.build`。不得使用 broad target、glob 或清理任何其他 target/path；non-directory、symlink、non-ignored、cleanup 或清理後 `test ! -e Tests/GitHubIntegrationConsumer/.build && test ! -L Tests/GitHubIntegrationConsumer/.build` 任一步失敗即分類為 workflow blocker 並停止。absence verification 通過後才執行完整 `swiftlint lint --strict` 與 diff checks；接著 Code-Reviewer → human-authorized commit/push/thread-resolution。不得重新實作 consumer files、修改 `.swiftlint.yml`，或援引 historic route 作為 approval。multiline parser 與 consumer threads 僅在 fresh reviewer verdict 明示 approved、無 blocker 且 human delivery authority 存在時才能 resolve；不得 rebase、force push、自動 merge 或 release；PR 維持 human review boundary。
