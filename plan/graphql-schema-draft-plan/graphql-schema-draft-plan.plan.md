# PR Reader GitHub GraphQL SDL Schema Snapshot — Execution Plan

## Summary

退休 GitHub Integration BC，並交付一份供 PR Reader future GitHub Infra 使用的 repository-managed GitHub GraphQL SDL schema snapshot。此 Mission 是 schema-only：沒有 operation、codegen、runtime、transport、REST 或 PR Reader application contract 的實作。

## Implementation Changes

- 建立 `Schema.graphqls`，路徑固定為 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls`；只允許它作為本 topic 新增 source asset。
- schema 必須以前述技術規格的三行 exact provenance comments 開頭，然後是未轉換 Rover default SDL output。human 以 Rover `v0.41.0`、固定 endpoint `https://api.github.com/graphql`、固定 `Accept`／`X-GitHub-Api-Version: 2022-11-28`／`User-Agent` headers與外部 Bearer token 在受控終端執行；agent 不執行下載，且沒有安全環境即停在 human boundary。
- 移除 GitHub Integration BC doc、空 placeholder source directory 與完整 dedicated GitHub Integration／HTTP Client boundary diagram artifact。
- 只在授權文件與 BC map 回寫：各 BC future local GitHub Infra ownership、BC-local failure isolation、future non-BC/unimplemented `GitHubTransport`、generic `RivetHTTPClient`，以及不建立 BC-to-BC dependency。
- 不建立 `PRReader/Infra/GitHub/REST/`。PR Inbox future REST path 僅作架構說明，不新增檔案或目錄。

### Write Boundary

| Category | Paths |
| --- | --- |
| Create | `analysis/graphql-schema-draft-plan/{requirements.md,technical-spec.md}`；`plan/graphql-schema-draft-plan/{graphql-schema-draft-plan.plan.md,graphql-schema-draft-plan.step.md}`；唯一 source asset `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` |
| Modify | `docs/design-principles.md`；`docs/architecture/README.md`；`docs/architecture/bounded-contexts/{README.md,pr-inbox.md,pr-reader.md}`；`docs/github-api/README.md`；`docs/architecture/diagrams/bounded-context-map/{scene.js,index.html}` |
| Delete | `docs/architecture/bounded-contexts/github-integration.md`；`Sources/BoundedContexts/GitHubIntegration/.gitkeep` and empty directory；`docs/architecture/diagrams/github-integration-http-client-boundary/` |
| Read-only | all other repository paths, including historical artifacts, `RivetHTTPClient`, HTTP client diagram, BC product source, manifests, targets, modules, packages, operations and generated source |

## Test Plan

- Human-only: validate Rover `v0.41.0` default SDL stdout, fixed endpoint and four required headers, zero exit, non-empty SDL, mode `0600` same-parent temporary/staging files, cleanup trap, same-parent `mv`, fixed three provenance comment lines and no token-like secret in the resulting schema. Do not print matched secret content.
- Static schema presence: read-only search confirms `PullRequestReviewThread`, `PullRequestReviewComment`, `reviewThreads(`, `isResolved:`, `isOutdated:` and `comments(`. This is presence evidence only, not GraphQL validation.
- Architecture: validate and build the bounded-context map using `architecture-canvas`; inspect a temporary nonpublished render to confirm no central GitHub Integration and only the two local Infra boundaries plus a dashed future `GitHubTransport` box.
- Repository hygiene: active docs/map have no retired GitHub Integration identifier, `git diff --check` passes, and changed/deleted paths match this plan exactly.

## Human Gate

The Rover download requires a repository-external token and controlled terminal. The human accepts the Authorization header argv exposure risk and must keep its value out of shell history, terminal/log capture, shared hosts, repository files and configuration. Absence of that environment yields `human-check`; it does not authorize a substitute source or agent credential handling.

## Assumptions

- GitHub API version is locked to `2022-11-28` and recorded only in the third provenance comment.
- The schema snapshot is a source asset for a later topic, not evidence that any GraphQL client or PR Reader capability exists.
- Any need for a REST directory, operation, codegen, API mapping, transport behavior, failure contract, target/module/package change or change outside the write boundary is scope drift and must stop for human direction.
