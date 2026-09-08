# PR Reader GitHub GraphQL SDL Schema Snapshot：技術規格

## Locked Decisions

### Asset and provenance

唯一新增 source asset 為：

`Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls`

檔案必須由下列三行 comment 開頭，依此順序、各自恰一行；第二行尖括號內容由 human 填入實際 UTC download time：

```graphql
# GitHub GraphQL endpoint: https://api.github.com/graphql
# Downloaded at (UTC): <YYYY-MM-DDTHH:MM:SSZ>
# GitHub API version: 2022-11-28
```

第三行後接 Rover 原樣輸出的 SDL。不得有其他 provenance sidecar、metadata、header、token、Authorization value、帳號、repository identity 或 response payload。此 topic 不規定 schema 的 hash、operation validation 或 codegen。

### Human-only acquisition gate

- 只有 human 在受控終端、以 repository 外安全提供的 GitHub token 與 Rover `v0.41.0` 下載 schema。Rover invocation 固定採 default SDL stdout behavior，不得要求 JSON 或任何 alternative output format，並且固定為 endpoint `https://api.github.com/graphql`、`Accept: application/vnd.github+json`、`X-GitHub-Api-Version: 2022-11-28`、`User-Agent: RivetSchemaSnapshot/1.0` 與 `Authorization: Bearer <external-token>` headers。下列是 locked shape；`<external-token>`／`${GITHUB_TOKEN}` 不得複製到 repository content 或 agent-visible handoff。

```sh
rover graph introspect https://api.github.com/graphql --header 'Accept: application/vnd.github+json' --header 'X-GitHub-Api-Version: 2022-11-28' --header 'User-Agent: RivetSchemaSnapshot/1.0' --header "Authorization: Bearer ${GITHUB_TOKEN}"
```
- Rover stdout 先寫入 `Schema.graphqls` parent directory 的 mode `0600` temporary file。human 必須使用 `umask 077`；mode `0600` 僅適用於下載期間的 temporary／staging files。cleanup trap 必須在 `EXIT`、`INT`、`HUP` 或 `TERM` 清除每個 temporary／staging file。只有 Rover 為 zero exit 且 SDL 非空，才能把三行 provenance comments 與未變更 SDL 組合至 mode `0600` staging file；再由同一 parent directory 的 `mv` 取代 `Schema.graphqls`。否則清除所有 temporary file，既有 schema 維持不變。Git 不保留 `0600` mode；repository-managed `Schema.graphqls` 不規定、驗證或宣稱任何檔案 mode。
- agent 不得執行 Rover、要求 token、取得 token、將 token 寫入 env/config/file，或輸出／記錄它。human 接受 Authorization header 在 Rover process argv 的風險，並必須避免 shell history、terminal/log capture 與 shared host。下載失敗或產出為空時清除 temporary file，既有 schema 維持不變。
- 若沒有受控終端、Rover 或安全 token，這是 `human-check`；不得以 public schema URL、手寫 SDL、替代 CLI 或 stored credential 取代。

### BC and technical boundary

- GitHub Integration BC 退休。PR Inbox 與 PR Reader 各自在自己的 Infra 隔離 GitHub external protocol、adapter、operation／endpoint、DTO mapping 和 technical failure 到 BC-own failure mapping；兩個 BC 不互相建立 compile-time dependency。
- `GitHubTransport` 僅能在 architecture docs/map 中表達為 future、unimplemented、non-BC technical boundary。它未來可處理 GitHub REST／GraphQL request execution、authorization injection、rate limit 與 technical transport failure；唯有 BC Infra 可依賴它。
- Domain Core、UseCase 與 Port 不得依賴 `GitHubTransport`。`RivetHTTPClient` 仍是 generic technical HTTP foundation，既非 retired GitHub Integration BC，亦不是 `GitHubTransport` implementation。
- 此 topic 不建立 `PRReader/Infra/GitHub/REST/` 或任何其他 REST assets。

## File Contract

| Change kind | Exact paths |
| --- | --- |
| Create | 本 topic 的四份 artifacts；`Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` |
| Modify | `docs/design-principles.md`；`docs/architecture/README.md`；`docs/architecture/bounded-contexts/README.md`、`pr-inbox.md`、`pr-reader.md`；`docs/github-api/README.md`；`docs/architecture/diagrams/bounded-context-map/scene.js` 與 generated `index.html` |
| Delete | `docs/architecture/bounded-contexts/github-integration.md`；`Sources/BoundedContexts/GitHubIntegration/.gitkeep` 與其空 directory；`docs/architecture/diagrams/github-integration-http-client-boundary/` 全部 artifact files |

所有未列路徑均為 read-only。特別禁止改動任何歷史 artifacts、`RivetHTTPClient`、HTTP client diagram、PR Inbox／PR Reader product source、manifest、package、target、module、operation 與 generated code。

## Architecture Writeback Contract

- design principles、architecture README、BC index 和 API catalog 不得再將 GitHub Integration 描述為 BC、central adapter 或外部契約 owner。
- PR Inbox／PR Reader BC docs 各自只記錄其 future local Infra ownership 和 failure isolation；不得虛構 adapter、transport、DTO、failure case 或 API contract 已存在。
- BC map 刪除 central Integration plane、central adapter／normalizer／identity context 與其 edges；以兩個各自 BC-local Infra/failure-isolation boundary 表示各自封裝 external GitHub protocol。`GitHubTransport` 僅為 dashed future/non-BC technical box，沒有已存在的 dependency edge 或 implementation claim。
- map 內保留 `RivetHTTPClient` 為 generic technical foundation 的角色，不將它連結成 GitHub-specific implementation。

## Verification Contract

- schema acquisition 的 evidence 是 Rover 成功、非空 SDL 與三行 exact provenance；不宣稱 GraphQL schema type validation、operation validation、codegen 或 runtime verification。
- 使用 read-only `rg` 確認 schema 的 exact provenance comments，並在 SDL 中確認 `PullRequestReviewThread`、`PullRequestReviewComment`、`reviewThreads(`、`isResolved:`、`isOutdated:`、`comments(` 存在。
- active docs/map verification 不以 `GitHub Integration` 的零搜尋結果作為條件，因為明確 retirement wording 與 nonownership wording 仍是必要的架構事實。改為確認 retired BC doc、placeholder source directory 與 dedicated boundary diagram root 均不存在；確認 map scene 不含 `github-integration`、`github-adapter`、`identity-context`、`failure-normalizer` 或 `infra-unknown` 的 box／edge identifiers；並以 `rg` 檢視 active docs 中每個剩餘的 `GitHub Integration` 提及均為明確 retirement 或 nonownership wording，不宣稱它仍是 BC、集中 owner 或 adapter。
- `architecture-canvas` 對 BC map 進行 validate/build，並只在 temporary copy 進行 nonpublishing visual check；不得發布 artifact.cafe。
- 執行 `git diff --check` 與 allowed-path isolation check。token／secret scan 對新 schema 與本 topic 改動的文字檔執行；命中時僅輸出 path 與 count，不輸出內容。
