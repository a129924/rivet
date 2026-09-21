# HTTP Client Sync／Async Request Authorization Contracts

## Summary

在 BC 外、GitHub-unaware 的 `RivetHTTPClient` 新增 declarations-only `AsyncRequestAuthorization`。既有同步 `RequestAuthorization` 完全不變；兩者均由 caller 套用 `HTTPRequest → HTTPRequest` transformation，且不負責 request execution。

建議 branch 名稱為 `feat/http-client-sync-async-request-authorization-contracts`；本 topic 不執行任何 Git 動作。

## Swift Implementation Handoff

### Goal

公開可並存的同步與非同步 request-authorization transformation contracts，讓 caller 可在 bare HTTP execution 前自行套用；不改變 execution path。

### Non-Goal

不提供 authorization runtime、concrete implementation、credential lifecycle、sync/async adaptation、request dispatch、retry/refresh/401 recovery、GitHub policy 或 caller migration。

### In-Scope

- 新增 public `AsyncRequestAuthorization: Sendable`：

  ```swift
  public protocol AsyncRequestAuthorization: Sendable {
    func applying(to request: HTTPRequest) async throws -> HTTPRequest
  }
  ```

- 保留 `RequestAuthorization: Sendable` 及其同步、nonthrowing signature 完全不變。
- 新增獨立 sync／async package-external existential contract tests。
- 最小更新 architecture overview 與 HTTP client package structure canvas，並依既有 canvas workflow rebuild generated artifact。

### Out-Of-Scope

- `BearerAuth` 與其 tests。
- 所有 existing HTTP execution、auth-flow、GitHubIntegration、credential、adapter 或 adoption surface。
- package manifests、BC documents、其他 topic artifacts、canvas build tooling、Git／PR／release。

### Written

- `analysis/http-client-sync-async-request-authorization-contracts/requirements.md`
- `analysis/http-client-sync-async-request-authorization-contracts/technical-spec.md`
- `plan/http-client-sync-async-request-authorization-contracts/http-client-sync-async-request-authorization-contracts.plan.md`
- `plan/http-client-sync-async-request-authorization-contracts/http-client-sync-async-request-authorization-contracts.step.md`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/AsyncRequestAuthorization.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/RequestAuthorizationTests.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/AsyncRequestAuthorizationTests.swift`

### Deleted

- 無。不得刪除、搬移或重新命名任何 API、source、test 或 artifact。

### Modify

- `docs/architecture/README.md`
- `docs/architecture/diagrams/http-client-package-structure/scene.js`
- `docs/architecture/diagrams/http-client-package-structure/index.html`，且只能由既有 workflow 生成。

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/RequestAuthorization.swift`、`BearerAuth.swift`、既有 `BearerAuthTests.swift`。
- `HTTPClient`、`Requester`、`Transport`、`Auth`、`AuthFlow`、所有 existing execution source/tests、所有 package manifests。
- `docs/architecture/bounded-contexts/`、GitHubIntegration、其他 topics 與 architecture documents。
- `docs/architecture/diagrams/http-client-package-structure/BUILD.md`、accessibility tooling 及所有其他 canvas assets。
- 除 Written／Modify allowlist 外的全部 repository paths。

### TestCase

| ID | Scenario | Expected result |
| --- | --- | --- |
| TC-01 | Sync existential contract | 新增 test file 的 private fake conform `RequestAuthorization`；經 `any RequestAuthorization` 呼叫 `applying(to:)`，取得 fake 定義的 transformed `HTTPRequest`。 |
| TC-02 | Async existential success | 新增 test file 的 private fake conform `AsyncRequestAuthorization`；經 `any AsyncRequestAuthorization` `try await applying(to:)`，取得 fake 定義的 transformed `HTTPRequest`。 |
| TC-03 | Async failure propagation | private failure fake 拋出 private sentinel；sentinel conform `Error & Sendable & Equatable`。catch 後斷言 received value 等於原 sentinel，且不映射為 HTTP、credential 或 GitHub error。 |
| TC-04 | Existing-contract regression | 完整 package tests 證明既有 sync contract 與 `BearerAuth` behavior 仍可編譯及通過；本 topic 不修改其 source/test。 |
| TC-05 | Boundary review | diff 與 source review 確認新 protocol 不持有、呼叫或注入 `HTTPClient`、`Requester`、`Transport`、`Auth` 或 `AuthFlow`。 |
| TC-06 | Package verification | standalone `RivetHTTPClient` `swift build` 與 `swift test` 通過。 |
| TC-07 | Repository quality | repository `swift test`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check` 通過。 |
| TC-08 | Canvas writeback | contracts plane 並列兩個 owned-contract boxes，表達 caller-applied transformation 與 `HTTPRequest` dependency；不得有至 execution/auth-flow surfaces 的 edge。依既有 `BUILD.md` workflow 執行 validate → scratch build → enhance → verify；validator 為 0 errors、0 warnings，accessibility verification 通過，並人工檢視 rebuilt light/dark desktop rendering。 |

## Verification

- focused sync／async contract suites。
- `RivetHTTPClient` standalone `swift build` 與 `swift test`。
- repository `swift test`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check`。
- canvas validator 必須 0 errors、0 warnings；enhance/accessibility verifier 通過；人工檢視 rebuilt light/dark desktop rendering。
- Reviewer 確認 diff 僅在 allowlist，尤其 `RequestAuthorization.swift`、`BearerAuth.swift`、execution chain、`BUILD.md` 與 manifests 均未變。

## Assumptions

- Human 已鎖定一般 `async throws`／`Error` 為 async contract 的 failure surface。
- 本 topic 不新增任何未鎖定的 runtime、authorization 或 adoption behavior。
