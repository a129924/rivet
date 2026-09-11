# GitHub Access Token Failure Contract：需求

## Goal

建立 `GithubIntegration` 的單一、可注入、同步且 typed-throws 的 GitHub access-token store/provider contract，並將其 target 外 consumer fixture 納入可重複執行的本地驗證。此切片固定 token 尚未保存與 token store persistence failure 的 provider mapping，供未來 GitHub-specific integration capability 使用，而不跨越任何 Domain Bounded Context 邊界。

## Non-Goal

本 topic 不交付任何 credential persistence、authorization、transport 或 Domain behavior；這些 capability 均須由獨立 topic 鎖定。

## In-Scope

- 單一 root Swift package library product 與 target：`GitHubIntegration`，其 target path 為 `Sources/BoundedContexts/GitHubIntegration`。
- `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- 唯一新增的 explicit public conformance 為 `TokenStoreOperation: Sendable`；此 conformance 僅滿足 Swift 6 warnings-as-errors 的跨隔離 diagnostics，不擴大 token/store/provider API 的 concurrency behavior。`TokenStoreError` 與 `GitHubCredentialError` 作為 `Error` 有 Swift 隱含的 `Sendable` 關係；本 topic 不額外宣告其 `Sendable` conformance。
- typed-throws `GitHubTokenStore` 與 `GitHubTokenProvider` protocols。
- 注入 `any GitHubTokenStore` 的 `TokenStoreGitHubTokenProvider`，以及固定的 `nil`／store-error provider mapping。
- `GitHubIntegration` test target，位置為 `Tests/GitHubIntegrationTests/`。
- 一個獨立 consumer fixture package，位置為 `Tests/GitHubIntegrationConsumer/`，只驗證根 package 對外匯出的 `GitHubIntegration` public API。
- routine consumer validation wrapper `scripts/check-github-integration-consumer.sh`、其 pre-commit local hook 與 `docs/toolchain.md` 的使用說明；三者只驗證既有 fixture，不新增 root target/module 或 CI。
- 對已鎖定 token contract 的最小 architecture writeback；不重開 existing `GithubIntegration` shared-module boundary。

## Out-Of-Scope

- Keychain 或任何 concrete credential persistence adapter、設定 UI。
- REST authorizer/API adapter、OAuth、refresh、re-auth、401 retry、多帳號、GitHub Enterprise、GraphQL 或 Apollo。
- HTTP status、transport、Domain failure mapping、endpoint、DTO 或 business meaning。
- `async`、cancellation，以及除 `TokenStoreOperation: Sendable` 外的任何新增 explicit `Sendable` conformance 或 concurrency behavior。
- root `Package.swift`、`GitHubIntegration` product/target、production source 與既有 public API；consumer fixture 不得以 `@testable` 或 internal API 驗證取代 public consumer 驗證。

## Success Criteria

- consuming code 可經公開 protocol 注入 store，取得原樣的 `GitHubAccessToken`。
- 未保存 token 的正常狀態只由 provider 表示為 `.missingCredential`。
- Store 的 persistence/I/O failure 只由 provider 包裝為 `.tokenStore(TokenStoreError)`，並保留 operation 與 underlying error。
- 新 target 不依賴 `RivetHTTPClient`、PR Inbox、PR Reader 或其他 Domain target，也不 import Security、Keychain 或 Apollo。
- `TokenStoreOperation` 可作為 `Sendable` value 使用；此不新增 token、store 或 provider 的 explicit `Sendable` conformance 或 concurrency behavior，亦不否定 error types 因符合 `Error` 而有的 Swift 隱含 `Sendable` 關係。

## ReadOnly

- `RivetHTTPClient` 及其 tests。
- root `Package.swift`、`GitHubIntegration` product/target declaration、所有 `Sources/BoundedContexts/GitHubIntegration/` production source 與其 public API。
- PR Inbox、PR Reader 與所有其他 Domain target/source/tests。
- 既有 HTTP、GraphQL、未列於 Modify 的 architecture diagrams 與 Bounded Context boundary decisions。

## Written

- 實作階段新增下列 `GitHubIntegration` target source：
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
  - `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- 實作階段新增 `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift` 與 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 contract/provider and static-isolation tests。
- PR-comment corrective route 新增 `Tests/GitHubIntegrationConsumer/Package.swift` 與 `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`；前者以 `../..` local-path dependency 指向 root package，設定 macOS 15／Swift 6，且只宣告一個依賴 package `Rivet` 的 `GitHubIntegration` product 的 test target；後者只 `import GitHubIntegration`，不得使用 `@testable`。
- `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 canonical factual writeback：只將 `GitHubIntegration` access-token contract 從「若建立／未來／尚未實作」更新為已實作，並明確保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- 本 topic 的四份 planning artifacts。
- AM-09 只寫入四份 planning artifacts；不寫入 Swift source、consumer fixture 或 `.swiftlint.yml`。
- AM-10 新增 routine validation wrapper `scripts/check-github-integration-consumer.sh`；不改動 fixture public test、Swift production source 或 lint configuration。

## Modify

- Root `Package.swift`：只新增 `GitHubIntegration` product、target 與 test target；不改變既有 target dependency。
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：唯一許可的新增 explicit source conformance 是 `TokenStoreOperation: Sendable`；`TokenStoreError` 與 `GitHubCredentialError` 僅維持因 `Error` 而有的 Swift 隱含 `Sendable` 關係，不額外宣告 conformance，也不得改變其他 public API、token behavior 或 failure mapping。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：將 substring checks 改為 structured package/target graph assertion、驗證四個 production source paths 的 exact set、枚舉實際 target sources 並檢查禁止 imports，另驗收 `TokenStoreOperation: Sendable` compile contract；不得新增其他 test source 或擴大 test scope。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：本次只補 multiline-attribute import parser edge case，維持既有 structured graph/source/import assertions；不得改變 production source set 或 package target graph。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：僅 mask Swift `#/…/#` raw-regex literal content 後再擷取 imports；mask 必須保留 newline 並以 delimiter-aware close 判定結尾，不擴張至其他 literal 或 lexer scope。`Apollo` 與 `ApolloAPI` 都是 forbidden module root；維持 existing graph/source assertions、production source set 與 package target graph。
- 新增 `scripts/check-github-integration-consumer.sh`：僅包裝既有 fixture 的 routine validation；以 task-scoped `mktemp -d` scratch path 與 `trap` 清理 scratch，並只在 eligibility 通過時精確處理 fixture `.build`。
- `.pre-commit-config.yaml`：在 local `swift-format` hook 之後、`swiftlint` hook 之前加入上述 wrapper hook；不得變更 SwiftLint rule/configuration 或其他 hook 的責任。
- `docs/toolchain.md`：記錄 routine consumer validation command、pre-commit ordering、task scratch 與 exact fixture cleanup safety contract；不得擴張為 CI policy。
- pre-integration merge 僅允許以 non-force merge 整合 `origin/dev`；`docs/architecture/bounded-contexts/README.md` 的 conflict 只可 resolve 單一 semantic hunk，並同時保留本 topic 的 `GitHubIntegration` 已實作 token contract/deferred capabilities，以及 `dev` 的 `RivetHTTPClient` generic `Auth`／`AuthFlow` contract（HTTP client 不 drive flow）說明。
- `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md` 的 minimal factual writeback 是已完成的 historical record；AM-10 對 bounded-context index 的唯一新權限是指定 non-force merge 的單一 semantic hunk，不得另行回寫。
- `docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md`：只回寫已實作的 `GitHubIntegration` access-token contract，並保留 Keychain、authorizer、REST 與 OAuth lifecycle 為 deferred；不得新增 API、scope 或 architecture decision。
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與其生成的 `index.html`：將 `GitHubIntegration` 由「尚未實作」更正為已實作的 lower shared GitHub-specific module，並僅表達本 topic 的 access-token contract 與既有 deferred capabilities；不改變 BC、dependency 或 responsibility boundary。圖的更新必須依 `architecture-canvas` 完成 validation/build，且不得發布 artifact.cafe。
- pre-integration merge 僅允許以 non-force merge 整合 `origin/dev`；`docs/architecture/README.md` 的 conflict 只可處理單一 semantic hunk，並同時保留本 topic 的 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。
- AM-10 只允許上述 wrapper、pre-commit hook、toolchain doc、static-isolation test 與 bounded-context index merge hunk；不得修改 `.swiftlint.yml`、root manifest、target/product、production API 或 CI。

## Deleted

不得刪除、搬移或更名任何 tracked file。AM-10 wrapper 的唯一許可 deletion 是 safety checks 通過後的 exact ignored generated output `Tests/GitHubIntegrationConsumer/.build`，以及由其 `mktemp -d` 取得並由 `trap` 清理的 task scratch directory；不得刪除其他 target 或 path。

## TestCase

- token raw value 原樣保留與傳遞，測試不可輸出 secret。
- store 成功讀取 token 時，provider 原樣回傳。
- store 回傳 `nil` 時，provider 拋出 `.missingCredential`。
- store 在 `load()` typed-throw `TokenStoreError` 時，provider 拋出 `.tokenStore`，且保留 `.load` 與 underlying error。
- 外部 mock store 可實作三個 typed-throws methods，並透過公開 initializer 建構 `TokenStoreError`。
- provider 可由 `init(store:)` 注入 mock store 並符合 `GitHubTokenProvider`。
- `TokenStoreOperation` 可通過編譯期 `Sendable` conformance check；不得藉此要求其他 public token/store/provider type 採用 `Sendable`。
- static-isolation test 以 structured package/target graph assertion 驗證 single `GitHubIntegration` target、四個 production source paths 的 exact set、實際 target source enumeration 與禁止 imports；不得用脆弱的 substring check 取代 graph/source validation。
- static-isolation parser 只 mask Swift `#/…/#` raw-regex content，保留其中 newline 並以 delimiter-aware close 判定結尾；raw-regex negative fixture 內的 fake `; import Apollo` 與 `; import ApolloAPI` 不得被視為 import，real multiline attribute import 則必須正確萃取 module root 並通過 positive assertion。實際 `Apollo`、`ApolloAPI` imports 都必須觸發 forbidden-import failure。
- 獨立 consumer package 以 root package 的 `GitHubIntegration` product 編譯，且不使用 `@testable`；其 public API test 驗證 token/error 的 public properties、initializers 與 cases，`TokenStoreOperation: Sendable`，外部 private typed-throws store mock，以及 provider 的 existential injection 與 success／missing／store-error mapping。
- `scripts/check-github-integration-consumer.sh` 以 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"` 建立 task scratch，並以 `trap` 只清理該 exact scratch path；它以 `--scratch-path "$RIVET_CONSUMER_BUILD_PATH"` 執行 fixture。對 `Tests/GitHubIntegrationConsumer/.build`，先拒絕 symlink 與 non-directory；只有現存的 non-symlink directory 經 `git check-ignore --no-index -q -- Tests/GitHubIntegrationConsumer/.build` 證實為 ignored output 時，才可 `rm -rf --` 該 exact path。不存在時直接做 absence verification；禁止 broad target、glob、其他 deletion 或 `.swiftlint.yml` 修改。eligibility、cleanup、trap cleanup 或最終 `test ! -e Tests/GitHubIntegrationConsumer/.build && test ! -L Tests/GitHubIntegrationConsumer/.build` 任一步失敗均為 blocker。wrapper 成功後，root `swift test`、完整 `swiftlint lint --strict` 與 diff checks 必須通過；pre-commit ordering 必須是 swift-format → consumer wrapper → swiftlint。
- 驗證 target dependency/import isolation，以及 root `swift test` 與 `git diff --check`。
- architecture map source 與生成 artifact 經 `architecture-canvas` validation/build 同步，並明確呈現「已實作的受限 token contract」與 deferred capability。
- `pr-reader.md` 與 GitHub API README 不再將已實作的 token contract 表示為「若建立／未來／尚未實作」，並仍明確保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- pre-integration merge 後確認 `docs/architecture/README.md` 的 resolved semantic hunk 同時保留 `GitHubIntegration` 已實作／deferred wording 與 HTTP decoded payload `Decodable & Sendable` sentence；不得用單方覆寫消除 conflict。

## PR Comment Triage

本次五項 PR comments 均為已授權的 planning-truth correction，不新增 API、scope 或 architecture decision：

- PC-01：將「唯一 public `Sendable`」更正為唯一新增 explicit conformance `TokenStoreOperation: Sendable`。
- PC-02：明確記錄 `TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 而有的 Swift 隱含 `Sendable` 關係；不新增 explicit conformance 或 concurrency behavior。
- PC-03：RV-03 的歷史 verdict 保持 `needs-rework`，不得重寫為 `approved`。
- PC-04：amendment 當時的 final thread-resolution gate 維持 `pending`，且不得以 LR-01 取代 reviewer approval。後續 delivery 已關閉該 historical route；它不提供新 comment 的 resolution authority。
- PC-05：`DL-02a → RV-05 → DL-02b` 是當時 remote 尚未承載已驗證 head 時的 corrective route。其後的 delivery 已將 feature branch、remote branch 與 PR head 同步至 `67a2cb7`；`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此記錄不補造 RV-05 verdict，也不是後續 PR comment 的 gate。
- PC-06：multiline attribute import parser 與 external public-consumer verification 為新的 threads；human 已授權 consumer fixture amendment。兩者必須進入新的獨立 route，不得援引 historic delivery route 作為 resolution authority。

## Implementation Handoff

PR-14 已 approved。AM-10/AM-11 fresh route 固定為 `PR-14 → IM-06 → TE-10 → RV-07 → CF-02 → IN-02 → TE-11 → RV-08 → DL-04`：Implementer 先只修改 `StaticIsolationTests.swift`（僅 Swift `#/…/#` raw-regex mask，保留 newline、delimiter-aware close；`Apollo`／`ApolloAPI` forbidden roots）、新增 `scripts/check-github-integration-consumer.sh`、修改 `.pre-commit-config.yaml`（swift-format 後、swiftlint 前的 local wrapper hook）與 `docs/toolchain.md`。raw-regex negative fixture 必含 fake `; import Apollo` 與 `; import ApolloAPI`，且 real multiline attribute import 為 positive fixture。Tester 執行 wrapper、root tests、SwiftLint 與 diff checks；RV-07 只作 pre-integration review。僅 RV-07 approved 後，Implementer 才可建立 CF-02：包含已 review fixes/artifacts 的 authorized non-delivery commit，不得 push、resolve threads、rebase 或 force push。IN-02 前 feature worktree 必須為 clean；再 non-force merge `origin/dev`，且只 resolve `docs/architecture/bounded-contexts/README.md` 的單一 semantic hunk。合併結果必須同時保留已實作的 `GitHubIntegration` token contract/deferred capabilities，及 `RivetHTTPClient` generic `Auth`／`AuthFlow` contract 與「HTTP client 不 drive flow」說明。TE-11 驗證 merge，RV-08 review merge snapshot；僅 RV-08 approved、無 blocker 與既有 human delivery authority 同時存在時，DL-04 才可 push 並只 resolve 已完成 threads。wrapper 的 scratch 與 fixture cleanup 必須完全符合上述 exact-path、non-symlink、`git check-ignore --no-index`、absence-check 與 blocker rules。不得修改 API、root package、production source、fixture public tests、CI 或 `.swiftlint.yml`；不得 rebase、force push、merge PR 或 release。
