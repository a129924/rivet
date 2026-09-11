# GitHub Access Token Failure Contract

## Summary

在 root Swift package 新增單一 `GitHubIntegration` library target，提供 GitHub-scoped token store/provider contract 與 store-backed provider。此 target 為 BC 外的 shared GitHub-specific integration capability；`Contracts/` 與 `Providers/` 僅為 target 內的 physical organization。

## Goal

提供可注入、同步、typed-throws 的 token store/provider contract，固定 missing credential 與 persistence/I/O failure 的 provider mapping，並以 routine consumer validation 維持 target 外 public-surface verification；不建立任何 persistence 或 authorization adapter。

## Non-Goal

不實作 Keychain、設定 UI、REST authorizer/API adapter、OAuth、refresh、re-auth、401 retry、多帳號、GitHub Enterprise、GraphQL、Apollo、HTTP/transport policy、Domain failure mapping、`async`、cancellation，或除 `TokenStoreOperation: Sendable` 外的新增 explicit `Sendable` conformance 或 concurrency behavior。

## In-Scope

- 新增 root `Package.swift` 的單一 `GitHubIntegration` product、target 與 test target；source path 為 `Sources/BoundedContexts/GitHubIntegration`，tests 為 `Tests/GitHubIntegrationTests/`。
- 新增 `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- 唯一新增的 explicit public conformance 為 `TokenStoreOperation: Sendable`，作為 Swift 6 warnings-as-errors remediation；`TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 具有 Swift 隱含 `Sendable` 關係，但不新增其 explicit conformance 或其他 concurrency behavior。
- 新增 typed-throws `GitHubTokenStore` 與 `GitHubTokenProvider` protocols。
- 新增 public `TokenStoreGitHubTokenProvider`，以 `init(store: any GitHubTokenStore)` 注入 store，並實作指定 failure mapping。
- 新增獨立 consumer fixture package，只驗證 root package 匯出的 `GitHubIntegration` public API，不新增 root module 或 target。
- 使既有 consumer fixture 成為 routine local validation：新增 wrapper、置入既有 pre-commit local hook 順序，並補齊 toolchain docs；不新增 CI。
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
- `scripts/check-github-integration-consumer.sh` routine consumer-validation wrapper。
- `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 canonical factual writeback：只更新為已實作的 `GitHubIntegration` token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- 四份同 slug planning artifacts；AM-09 只寫入這四份 artifacts，不寫入 Swift source、consumer fixture 或 `.swiftlint.yml`。

### Modify

- Root `Package.swift`：只加入 `GitHubIntegration` product、target、test target 與 source/test paths。
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：只新增 explicit `TokenStoreOperation: Sendable`；`TokenStoreError` 與 `GitHubCredentialError` 僅維持因 `Error` 而有的 Swift 隱含 `Sendable` 關係，不額外宣告 conformance；不改變其他 API 或 failure mapping。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：以 structured package/target graph assertion 取代 substring checks，驗證四個 production source paths 的 exact set、枚舉實際 target sources、檢查禁止 imports，並驗收 `TokenStoreOperation: Sendable` compile contract；不得新增其他 test source 或 scope。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：只補 multiline-attribute import parser edge case，維持既有 structured graph/source/import assertions；不得改動 package graph 或 production source set。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：僅 mask Swift `#/…/#` raw-regex literal content，再解析 imports；mask 保留 newline、以 delimiter-aware close 判定結尾，不擴張其他 literal/lexer scope。forbidden roots 必須同時包含 `Apollo` 與 `ApolloAPI`，不改動 graph/source assertions、package graph 或 production source set。
- `scripts/check-github-integration-consumer.sh`：以 exact `mktemp -d` scratch、`trap` cleanup、fixture `.build` eligibility probe/cleanup/absence verification 包裝既有 consumer test。
- `.pre-commit-config.yaml`：在 `swift-format` 後、`swiftlint` 前加入 wrapper local hook；不改 SwiftLint configuration/rules 或 CI。
- `docs/toolchain.md`：記錄 routine wrapper、pre-commit ordering、scratch/trap 與 exact cleanup safety behavior。
- pre-integration merge：只允許 non-force merge `origin/dev`；只 resolve `docs/architecture/bounded-contexts/README.md` 的單一 semantic hunk，保留已實作的 `GitHubIntegration` token contract/deferred capabilities，及 `dev` 的 `RivetHTTPClient` generic `Auth`／`AuthFlow` contract（HTTP client 不 drive flow）說明。
- `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md` 的 factual writeback 是 historical record；AM-10 對 bounded-context index 的唯一新權限是指定 merge hunk，不改變 BC boundary 或 deferred responsibility。
- `docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`：只將「若建立／未來／尚未實作」的 `GitHubIntegration` token-contract 描述更新為已實作，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred；不得新增 API、scope 或 architecture decision。
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與生成 `index.html`：只同步已實作的 access-token contract 與 deferred capability，必須以 `architecture-canvas` validation/build 產生；不得發布 artifact.cafe。
- pre-integration merge：只允許 non-force merge `origin/dev`；只 resolve `docs/architecture/README.md` 的單一 semantic hunk，且必須同時保留本 topic 的 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。
- AM-10 只允許上述 test、wrapper、pre-commit config、toolchain doc 與 bounded-context index merge hunk；不修改 root manifest、target/product、production API、fixture public tests、CI 或 `.swiftlint.yml`。

### Deleted

不得刪除、搬移或更名任何 tracked file。AM-10 wrapper 唯一許可的 deletion 是 eligibility 通過後的 exact ignored generated output `Tests/GitHubIntegrationConsumer/.build`，以及由 `mktemp -d` 建立、`trap` 清理的 exact task scratch directory；不得刪除其他 target 或 path。

## TestCase

- `GitHubAccessToken` 原樣保存 raw value，test output 不含 secret。
- mock store 成功回傳 token 時，provider 原樣回傳。
- mock store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- mock store 的 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，保留 `.load` 與 original underlying error。
- 外部 mock store 可符合三個 typed-throws methods，並使用 public `TokenStoreError` initializer。
- provider 可由 `init(store:)` 注入 mock store，並符合 `GitHubTokenProvider`。
- `TokenStoreOperation` 的 explicit public `Sendable` conformance 可通過編譯期驗證；其他 token/store/provider contract 不新增 explicit conformance 或 concurrency behavior，並保留 error types 因 `Error` 而有的 Swift 隱含 `Sendable` 關係。
- static-isolation test 必須以 structured package/target graph assertion 驗證 single target、四個 production source paths 的 exact set、actual target source enumeration 與禁止 imports；不得用 substring check 取代此驗證。
- import parser 僅 mask Swift `#/…/#` raw-regex literal，保留 newline 且 delimiter-aware close；negative fixture 的 fake `; import Apollo` 與 `; import ApolloAPI` 必須不被擷取，real multiline attribute import 必須正確擷取 module root。實際 `Apollo`、`ApolloAPI` imports 都產生 forbidden-import failure。
- wrapper 以 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"` 建立 scratch，透過 `trap` 只清理此 exact scratch path，並以 `--scratch-path "$RIVET_CONSUMER_BUILD_PATH"` 執行 fixture。fixture `.build` 若為 symlink 或 non-directory 即 blocker；若存在，必須先以 `git check-ignore --no-index -q -- Tests/GitHubIntegrationConsumer/.build` 證實 ignored，才可 `rm -rf --` exact path；不存在時直接驗證 absence。禁止 broad target、glob、其他 deletion 與 `.swiftlint.yml` 修改；cleanup/trap/final absence 任一步失敗即停止。成功後 root `swift test`、完整 `swiftlint lint --strict` 與 diff checks 通過，且 pre-commit hook 順序為 swift-format → wrapper → swiftlint。
- consumer verification 不得觸及 root manifest、target/product、production source 或任何已鎖定 public contract。
- package target/test-target layout、target dependency 與 imports 維持 isolation；執行 root `swift test` 及 `git diff --check`。
- bounded-context map source/generated artifact 通過 `architecture-canvas` validation/build，並如實呈現已實作的受限 shared module。
- PR Reader BC 文件與 GitHub API README 如實呈現已實作的 token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- pre-integration merge 後確認 bounded-context index resolved hunk 同時保留兩方指定 wording；不得 rebase、force push 或以單方版本覆寫 conflict。
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

1. PR-14 已取得獨立 Plan-Reviewer 的明示 `approved`／`pass` verdict；不再重複要求 planning approval。
2. PR-14 已 approved。IM-06 Implementer 只修改 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 Swift `#/…/#` raw-regex mask（保留 newline、delimiter-aware close，不能擴張其他 literal/lexer scope）與 `Apollo`／`ApolloAPI` forbidden roots；negative fixture 必含 fake `; import Apollo` 與 `; import ApolloAPI`、positive fixture 為 real multiline attribute import；新增 `scripts/check-github-integration-consumer.sh`、修改 `.pre-commit-config.yaml`（swift-format 後、swiftlint 前的 local hook）與 `docs/toolchain.md`。wrapper 必須使用 exact `mktemp`/`trap` scratch、`git check-ignore --no-index` eligibility probe、exact fixture `.build` delete 與 final absence verification。不得修改 fixture public tests、root manifest、target/product、production source/API、failure mapping、CI、`.swiftlint.yml`、scope、Non-Goal 或 architecture decision。
3. RV-03 的 historical `needs-rework` verdict 不得重寫為 `approved`。historic `DL-02a → RV-05 → DL-02b` route 已在後續 delivery 後失去 current-gate 身分：feature branch、remote branch 與 PR head 已同步至 `67a2cb7`，`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此記錄不回填或推論 RV-05 verdict。
4. 路由固定為 `PR-14 → IM-06 → TE-10 → RV-07 → CF-02 → IN-02 → TE-11 → RV-08 → DL-04`。TE-10 必須執行 wrapper、root `swift test`、完整 `swiftlint lint --strict` 與 diff checks；wrapper 的 eligibility、cleanup、trap cleanup 或 absence verification 任一失敗均為 blocker。RV-07 是 pre-integration review；僅其 approved 後可建立 CF-02 authorized non-delivery commit，commit 含 reviewed fixes/artifacts 但不得 push、resolve threads、rebase 或 force push。IN-02 前 feature worktree 必須 clean，才可 non-force merge `origin/dev` 並只處理 `docs/architecture/bounded-contexts/README.md` single semantic hunk；combined hunk 必須保留已實作 token contract/deferred capabilities 及 generic `Auth`／`AuthFlow`／HTTP client 不 drive flow wording。TE-11 驗證 merge snapshot，RV-08 是 fresh merge review；僅 RV-08 approved、無 blocker 與既有 human delivery authority 同時成立後，DL-04 才可 push 並只 resolve completed threads。不得 rebase、force push、自動 merge 或 release；PR 維持 human review boundary。
