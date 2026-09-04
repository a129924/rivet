# PR Inbox Swift Contract Baseline：需求

## Goal

在 root SwiftPM package 建立 `RivetPRInbox` library product／target，使用既有 `Sources/BoundedContexts/PRInbox/` source path，提供 PR Inbox 自有的 Core contract、refresh-only Facade 與可測試的 semantic fake 基線。

## Non-Goal

不建立 GitHub Integration Adapter、HTTP client dependency、外部 query、DTO、真實網路、UI、PR Reader、Presentation Session、cache 或 sync。

## In-Scope

- root `RivetPRInbox` library product、source target 與 test target。
- target-local `Outcome`、`InboxItem`、`ReviewRequestCandidate`、`PRInboxFailure`、`ReviewRequestSource`、internal refresh use case 與 `PRInboxFacade`。
- semantic fake source 與 Swift Testing。
- PR Inbox BC 文件對本 target 與 Core contract 邊界的長期事實回寫。

## Out-Of-Scope

- `RivetHTTPClient` 或任何外部 package dependency。
- GitHub search query、pagination、incomplete-result policy、HTTP/auth/rate-limit、`InfraUnknownError`、GitHub DTO 與 failure mapping。
- 排序、snapshot/current state、cache、sync、跨 BC contract、Git、release、PR 或 artifact 發布。

## Success Criteria

- refresh 只回傳 open 且明確直接要求目前使用者 review 的 Inbox item；空集合是成功結果。
- failure 僅以 PR Inbox 自有 `.unavailable` 表達並原樣傳遞。
- target、source import 與 manifest 均不依賴 HTTP client 或外部 integration。
- 四份同 slug artifacts 可完整描述本次受限實作、驗收與 human boundary。
