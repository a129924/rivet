# GitHub authenticated GET foundation — Bounded Execution Plan

建議 branch：feat/github-http-authenticated-get-foundation。Human 已在對話確認本 topic plan 並要求於獨立 feature worktree 實作、commit、push、開 Draft PR；此檔記錄受限範圍，仍須保存驗證與 human review 證據。

## Goal / Non-Goal / In-Scope / Out-Of-Scope
以同 slug requirements.md 與 technical-spec.md 為唯一行為及邊界契約；本次交付 internal GET、401-only 一次 recovery、安全目的地／redirect、取消與 technical error。其他 HTTP method、BC 對接、GraphQL、generic HTTP 及 public consumer capability 排除。

## ReadOnly
Package.swift、既有 provider／OAuth refresh adapter／GraphQL source、packages/RivetHTTPClient、v7 及更早 lifecycle 與所有未列入 Written／Modify 的 tracked files。

## Written
四份同 slug planning artifacts；Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClient.swift、GitHubHTTPClientError.swift；Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift、GitHubHTTPTransportTests.swift；版本化 token-lifecycle-v8／v9 rejected evidence 與 canonical v10 Archify 規格、HTML、驗證 evidence。

## Deleted
無。

## Modify
Tests/GitHubIntegrationTests/StaticIsolationTests.swift 的 REST 路徑及 import allowance；docs/design-principles.md、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md、docs/architecture/diagrams/github-oauth-dual-client-architecture/README.md 的 internal GET 狀態；同目錄既有 canvas 的過時 REST 狀態及必要視覺 evidence。保持歷史 v7 不變。

## TestCase
snapshot／Bearer／非 Authorization headers、401 success 與第二次 401、原 request 最多兩送、403／3xx／其他 status、provider 各 error、transport failure、caller cancellation、目的地與 redirect 禁止外洩。使用 fake ports／transport，不要求真實 credential。SwiftPM focused/root tests、static isolation、格式／lint、Archify 與 canvas 驗證、diff hygiene。

## Review aids and delivery
Graphify 僅查既有 graph，無 graph 則 targeted source fallback；不建 graph。實際 diff 後用 PR Lens 在 repository 外產生本地 change map，不 upload，亦非 approval。依 staged diff 檢查 commit 語意；Human 已要求本 topic commit、push 與 Draft PR，最終停於 human review。若必須新增 public contract、改 generic HTTP 或 ownership，停下交人類決策。
