# GitHub Access Token Failure Contract：技術規格

## Goal

在不改變既有 GitHub Integration shared-module boundary 的前提下，鎖定可注入、同步、typed-throws 的 access-token store/provider contract 及其唯一 failure mapping。

## Non-Goal

不建立 Keychain、UI、REST/GraphQL adapter、OAuth 或 token lifecycle；不將 credential/store failure 定義為 Domain Bounded Context failure contract。

## In-Scope

- 單一 root-package `GitHubIntegration` product、target 與 test target。
- 四個 public credential/store value/error types、兩個 typed-throws protocols 與一個 public store-backed provider。
- 固定的 physical layout、target dependency isolation、minimal factual architecture writeback 及 contract tests。
- 一個只作 target 外 public API verification 的獨立 consumer fixture package；它不新增 root target/module。

## Out-Of-Scope

- 新 module/target、`RivetHTTPClient` 或 Domain source/test changes。
- Security/Keychain、REST/GraphQL/Apollo、OAuth、refresh、re-auth、401 retry、多帳號、Enterprise、HTTP policy、`async`、cancellation，以及除 `TokenStoreOperation: Sendable` 外的新增 explicit `Sendable` conformance 或 concurrency behavior。
- 對 root `Package.swift`、`GitHubIntegration` product/target、production source、public API、failure contract 或 target dependency 的變更；fixture test 不得使用 `@testable`。

## Locked API Contract

`GitHubIntegration` 是 root Swift package 的單一 library target/product，target path 固定為 `Sources/BoundedContexts/GitHubIntegration`。`Contracts/` 與 `Providers/` 僅用於 target 內的 physical organization；它們不建立新的 module 或 target。

```swift
public struct GitHubAccessToken {
  public let rawValue: String

  public init(rawValue: String)
}

public enum TokenStoreOperation: Sendable {
  case load
  case save
  case delete
}

public struct TokenStoreError: Error {
  public let operation: TokenStoreOperation
  public let underlyingError: any Error

  public init(operation: TokenStoreOperation, underlyingError: any Error)
}

public enum GitHubCredentialError: Error {
  case missingCredential
  case tokenStore(TokenStoreError)
}

public protocol GitHubTokenStore {
  func load() throws(TokenStoreError) -> GitHubAccessToken?
  func save(_ token: GitHubAccessToken) throws(TokenStoreError)
  func delete() throws(TokenStoreError)
}

public protocol GitHubTokenProvider {
  func token() throws(GitHubCredentialError) -> GitHubAccessToken
}

public struct TokenStoreGitHubTokenProvider: GitHubTokenProvider {
  public init(store: any GitHubTokenStore)

  public func token() throws(GitHubCredentialError) -> GitHubAccessToken
}
```

- `GitHubAccessToken` 不驗證、正規化、格式化或記錄 raw token。
- `TokenStoreError` 必須保留 triggering operation 及 exact underlying error，並提供 public initializer，讓外部 conformer 可建立 typed error。
- 唯一新增的 explicit public conformance 是 `TokenStoreOperation: Sendable`，以滿足 Swift 6 warnings-as-errors。`TokenStoreError` 與 `GitHubCredentialError` 作為 `Error` 有 Swift 隱含的 `Sendable` 關係，但本 topic 不為它們額外宣告 conformance；也不引入 actor isolation、`async`、cancellation 或其他 concurrency behavior。
- store `load()` 的 `nil` 是正常的未設定 credential 狀態。
- provider 只在 store 回傳 `nil` 時拋出 `.missingCredential`；store `load()` 拋出 `TokenStoreError` 時，只映射為 `.tokenStore(error)`。
- 本 topic 不定義 save/delete 的 provider method、persistence adapter、authorization 或 credential recovery UX。

## Physical Layout

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

- `CredentialTypes.swift` 定義 `GitHubAccessToken`、`TokenStoreOperation`、`TokenStoreError`、`GitHubCredentialError`。
- `GitHubTokenStore.swift` 只定義 `GitHubTokenStore`。
- `GitHubTokenProvider.swift` 只定義 `GitHubTokenProvider`。
- `TokenStoreGitHubTokenProvider.swift` 只定義 store-backed provider implementation。
- test target 的 source 留在 `Tests/GitHubIntegrationTests/`；test partition 不增加 target 或 module。
- consumer fixture 是獨立 Swift package：`Package.swift` 以 `../..` local-path dependency 指向 root package，使用 macOS 15／Swift 6，且只宣告一個 test target；其 dependency 必須是 package `Rivet` 的 `GitHubIntegration` product。fixture 的 test 只 `import GitHubIntegration`，不得 `@testable import`。

## Dependency and Scope Boundaries

- `GitHubIntegration` 不依賴 `RivetHTTPClient`、PR Inbox、PR Reader 或任何 Domain target；這些 target 也不依賴或修改此切片。
- 新 target 不 import Security、Keychain 或 Apollo，不建立 REST/GraphQL authorizer、adapter、endpoint、DTO、OAuth 或 token lifecycle policy。
- `GitHubCredentialError` 是此 shared capability 的 credential/store contract，不是任何 Domain Bounded Context failure contract；consuming Domain Infra 未來仍自行進行 Domain failure mapping。
- 不新增 `async`、cancellation，或除 `TokenStoreOperation: Sendable` 外的 explicit concurrency conformance／behavior；`Error` 的 Swift 隱含 `Sendable` 關係不屬本 topic 新增的 contract，且不改變既有 package dependency graph。

## ReadOnly

- `RivetHTTPClient`、PR Inbox、PR Reader、所有其他 Domain source/tests，以及既有 HTTP/GraphQL source/tests。
- root `Package.swift`、既有 `GitHubIntegration` product/target declaration，以及所有 production source／public API。
- 除 `docs/architecture/diagrams/bounded-context-map/scene.js` 與其生成 `index.html` 外的現有 architecture diagrams、BC ownership 與 target boundaries。

## Written

- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubTokenProvider.swift`
- `Sources/BoundedContexts/GitHubIntegration/Providers/TokenStoreGitHubTokenProvider.swift`
- `Tests/GitHubIntegrationTests/GitHubTokenProviderTests.swift` 的 contract/provider verification 與 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 static-isolation verification。
- `Tests/GitHubIntegrationConsumer/Package.swift` 與 `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` 的 external public-consumer verification。
- `docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的 canonical factual writeback：只將 `GitHubIntegration` access-token contract 更新為已實作，並保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred。
- AM-09 只寫入四份 planning artifacts；不寫入 Swift source、consumer fixture 或 `.swiftlint.yml`。

## Modify

- Root `Package.swift` 的 single target/product/test-target declaration。
- `Sources/BoundedContexts/GitHubIntegration/Contracts/CredentialTypes.swift`：唯一許可的新增 explicit source conformance 是 `TokenStoreOperation: Sendable`；`TokenStoreError` 與 `GitHubCredentialError` 僅維持因 `Error` 而有的 Swift 隱含 `Sendable` 關係，不額外宣告 conformance；不得改變其他 public API、token behavior 或 failure mapping。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：以 structured package/target graph assertion 取代 substring checks，驗證四個 production source paths 的 exact set、枚舉 actual target sources 並檢查禁止 imports，並驗收 `TokenStoreOperation: Sendable` compile contract；不得新增其他 test source 或 test scope。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：只新增 multiline-attribute import parser edge case，維持既有 structured graph/source/import assertions 與 package graph；不得改動 production source set。
- `docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-inbox.md` 的 minimal factual writeback；不得宣稱 Keychain、authorizer 或 raw transport 等 deferred capability 已實作。
- `docs/architecture/bounded-contexts/pr-reader.md`、`docs/github-api/README.md` 的 minimal factual writeback：不得再將已實作的 token contract 表示為「若建立／未來／尚未實作」，並必須保留 Keychain、authorizer、REST 與 OAuth lifecycle deferred；不得新增 API、scope 或 architecture decision。
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與生成 `index.html`：以 `architecture-canvas` validation/build 同步；只將 `GitHubIntegration` 的已實作 token contract 與 deferred capability 如實呈現，不新增 BC、module、target、dependency 或 policy，且不得發布 artifact.cafe。
- pre-integration merge 僅允許 non-force merge `origin/dev`；`docs/architecture/README.md` 的 conflict 只可 resolve 單一 semantic hunk，並保留 `GitHubIntegration` implemented/deferred wording 與 `dev` 的 HTTP decoded payload `Decodable & Sendable` sentence。
- AM-09 verification workflow 不修改 tracked source、fixture 或 config；只在 safety checks 通過時處理 ignored generated output 的 exact path。

## Deleted

不得刪除 tracked file。AM-09 僅允許在 safety checks 通過後刪除 ignored generated output `Tests/GitHubIntegrationConsumer/.build`；不得操作其他 target 或 path。

## TestCase

- public value/error/protocol surface 可由 target 外的 mock test code 使用。
- 成功 path 原樣回傳 token；`nil` 與 `TokenStoreError` path 分別映射唯一指定 credential error case。
- `.tokenStore` 保存 error identity、operation 與 underlying error。
- 編譯期確認 `TokenStoreOperation` 符合 `Sendable`；不以此推論或要求其他 public contract 具備 concurrency conformance。
- static-isolation test 以 structured package/target graph assertion 驗證 package manifest 的 single target、四個 production source paths 的 exact set、實際 target source enumeration 與禁止 imports；不得使用 substring check 取代 graph/source validation。
- multiline-attribute import parser edge case 仍正確萃取 imported module root，並進入 forbidden-import 驗證。
- external consumer fixture 固定在同一 shell 先執行 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"`，再執行 `swift test --package-path Tests/GitHubIntegrationConsumer --scratch-path "$RIVET_CONSUMER_BUILD_PATH"`；scratch directory 為 task-scoped temporary path。其後的唯一許可 cleanup target 是 `Tests/GitHubIntegrationConsumer/.build`：若不存在（亦非 symlink），不執行 cleanup，直接驗證 absence；若存在或為 symlink，只有它是非 symlink directory，且 `git check-ignore -q -- Tests/GitHubIntegrationConsumer/.build` 證明它是 ignored generated build output 時，才執行 `rm -rf -- Tests/GitHubIntegrationConsumer/.build`。禁止 broad target、glob 與其他 path；non-directory、symlink、non-ignored、cleanup 或清理後 `test ! -e Tests/GitHubIntegrationConsumer/.build && test ! -L Tests/GitHubIntegrationConsumer/.build` 任一步失敗均為 workflow blocker 並停止。不使用 `@testable`，並驗證 `GitHubAccessToken` 與 error types 的 public property/initializer/case surface、`TokenStoreOperation: Sendable`、private external typed-throws store mock、provider existential injection，及 success／missing／store-error mapping；只有 absence verification 通過後，完整 `swiftlint lint --strict` 與 diff checks 必須通過。
- fixture 不得要求 root manifest、target/product、production source 或已鎖定 public API 有任何變更。
- package manifest 將 source/test path 納入單一 `GitHubIntegration` target，且無不允許 dependency/import。
- root test suite 與 whitespace diff check 通過。
- bounded-context map 的 authored source 與 generated artifact 經 `architecture-canvas` validation/build 同步，且不再將此受限 module 標示為未實作。
- `pr-reader.md` 與 GitHub API README 如實表達已實作的 token contract，並維持 Keychain、authorizer、REST 與 OAuth lifecycle 為 deferred。
- pre-integration merge 後驗證 README resolved hunk 同時保留上述兩方 wording，且沒有 rebase、force push 或單方覆寫。

## PR Comment Triage

本次五項 PR comments 均只修正 planning truth：

- PC-01：唯一新增 explicit public conformance 是 `TokenStoreOperation: Sendable`。
- PC-02：`TokenStoreError` 與 `GitHubCredentialError` 因 `Error` 保有 Swift 隱含 `Sendable` 關係；不新增 explicit conformance 或 concurrency behavior。
- PC-03：RV-03 的 historical `needs-rework` verdict 不得改寫。
- PC-04：amendment 當時的 final thread-resolution gate 維持 `pending`；不得以歷史 reviewer evidence 取代 fresh remote review。後續 delivery 已關閉該 historical route；它不提供新 comment 的 resolution authority。
- PC-05：`DL-02a → RV-05 → DL-02b` 是當時 remote 尚未承載已驗證 head 時的 corrective route。其後 feature branch、remote branch 與 PR head 已同步至 `67a2cb7`；`origin/dev` 已在 history，README conflict 已以 non-force merge 解決，PR 為 mergeable clean。此記錄不補造 RV-05 verdict，也不是後續 PR comment 的 gate。
- PC-06：multiline-attribute import parser 與 external public-consumer verification 是新的 PR threads。human 明確授權唯一 consumer fixture package；兩項修正必須走 fresh gate，historic route 不提供 resolution authority。

## Implementation Handoff and Gate

本次 fresh amendment 由 human 明確授權，僅允許 `StaticIsolationTests.swift` 的 multiline-attribute import parser edge case，以及 `Tests/GitHubIntegrationConsumer/Package.swift`、`Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`。fixture manifest 固定為 `../..` local-path dependency、macOS 15、Swift 6、唯一 test target，並以 package `Rivet` 的 `GitHubIntegration` product 為唯一 dependency。public test 固定 `import GitHubIntegration` 而非 `@testable`，以 private external typed-throws mock 驗證 public value/error surface、`TokenStoreOperation: Sendable`、provider existential injection 與三條既定 mapping。consumer verification 必須在同一 shell 先執行 `RIVET_CONSUMER_BUILD_PATH="$(mktemp -d)"`，再執行 `swift test --package-path Tests/GitHubIntegrationConsumer --scratch-path "$RIVET_CONSUMER_BUILD_PATH"`；該 scratch directory 為 task-scoped temporary path。其後 human-authorized cleanup 僅限 `Tests/GitHubIntegrationConsumer/.build`：若 exact path 不存在且非 symlink，跳過 cleanup；否則它必須是 non-symlink directory，且 `git check-ignore -q -- Tests/GitHubIntegrationConsumer/.build` 證明為 ignored generated build output，才執行 `rm -rf -- Tests/GitHubIntegrationConsumer/.build`。禁止 broad target、glob 或其他 path；non-directory、symlink、non-ignored、cleanup 或清理後 `test ! -e Tests/GitHubIntegrationConsumer/.build && test ! -L Tests/GitHubIntegrationConsumer/.build` 任一步失敗，即分類為 workflow blocker 並停止。只有 absence verification 通過後才能執行完整 `swiftlint lint --strict` 與 diff checks，不得修改 `.swiftlint.yml`。不得修改 root manifest、target/product、production source、public API、failure contract、scope、Non-Goal 或 architecture decision。PR-10 為 needs-rework；AM-09 的 fresh revalidation route 是 Plan-Reviewer → Tester（two-step same-shell temporary-scratch consumer test，exact ignored `.build` cleanup 與 absence verification，再完整 SwiftLint/diff checks）→ Code-Reviewer → human-authorized delivery，不重新實作 consumer files。只有 fresh reviewer verdict 為 approved 且 human authority 存在時，Implementer 才可 commit、push 並 resolve 已完成 threads。不得 rebase、force push、merge 或 release；PR 維持 human review boundary。
