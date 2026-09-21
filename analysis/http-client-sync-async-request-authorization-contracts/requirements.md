# HTTP Client Sync／Async Request Authorization Contracts：需求

## Goal

在 BC 外、GitHub-unaware 的 `RivetHTTPClient` 公開可並存的同步與非同步 request-authorization transformation contracts，讓 caller 在 bare HTTP execution 前自行套用；不改變 execution path。

## Locked Decisions

- 保留 `RequestAuthorization: Sendable` 及 `func applying(to:) -> HTTPRequest` 完全不變、未 deprecated、未引入 `await`。
- 新增 public `AsyncRequestAuthorization: Sendable`，其 method 為 `func applying(to request: HTTPRequest) async throws -> HTTPRequest`。
- async failure surface 是一般 `Error`，直接交還 caller；不得映射、包裝或改變 `HTTPClientError`、`Requester`、`Transport` 或 `HTTPClient` failure surface。
- 兩個 contract 都只處理 `HTTPRequest → HTTPRequest` 的 caller-applied pure transformation；不是 execution abstraction。

## In-Scope

- 新增 public async protocol。
- 新增獨立 sync／async package-external existential contract tests。
- 最小更新 architecture overview 與既有 HTTP client package structure canvas。
- 使用既有 canvas workflow rebuild generated artifact。

## Out-of-Scope

- `BearerAuth`、任何 concrete conformer、caller adoption。
- `HTTPClient`、`Requester`、`Transport`、`Auth`、`AuthFlow`、GitHubIntegration、credential/token、network dispatch、retry、refresh、401 policy。
- sync/async adapter、type erasure、protocol inheritance 或 interoperability policy。
- package manifests、BC documents、其他 topic artifacts、canvas build tooling、Git／PR／release。

## Success Criteria

- sync API 維持 source-compatible；async API 為 additive public contract。
- async existential 可成功轉換 request，亦可將 conformer 的一般 error 原樣交還 caller。
- 兩條 contract 都不構成 execution abstraction，且不依賴 GitHub 或 credential type。
- architecture overview 與 package canvas 如實表達 transformation 與 bare `Requester → Transport` execution 分離。

## Human Boundary

- HC-01 已由 Human 在對話中明示「可實現」完成，作為本四份 artifact 的 pre-write authorization。
- commit、push、PR、merge 與 release 仍未授權；它們是 RV-01 後的獨立 Human delivery boundary。
