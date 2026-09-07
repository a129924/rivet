# PR Reader GitHub GraphQL SDL Schema Snapshot：需求

## Goal

為 PR Reader 的 future GitHub Infra 建立 repository-managed GitHub GraphQL SDL schema snapshot，唯一交付檔案是：

`Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls`

此 snapshot 是後續 GraphQL operation 與 codegen topic 的輸入，不代表那些能力已被授權或實作。

## Architecture Intent

- 每個 Domain BC 在自身 Infra 擁有 GitHub REST／GraphQL adapter、operation／endpoint、DTO mapping 與 failure mapping；不建立 GitHub Integration BC，也不建立 BC-to-BC compile-time dependency。
- PR Reader 的 GitHub GraphQL asset 屬於 `PRReader/Infra/GitHub/GraphQL/`。若未來 PR Reader 需要 REST，位置是 sibling `PRReader/Infra/GitHub/REST/`；本 topic 不得預先建立該空目錄。
- PR Inbox 未來自行在 `PRInbox/Infra/GitHub/REST/` 維護其協定資產；本 topic 不改動 PR Inbox source assets。
- 未來的 `GitHubTransport` 是 non-BC technical package，統一處理 request execution、authorization injection、rate limit 與 technical transport failure。只有各 BC 的 Infra 未來可依賴它；Domain Core、UseCase 與 Port 不得依賴它。
- `RivetHTTPClient` 保持 generic technical HTTP foundation；它不是 GitHub Integration 或 `GitHubTransport` 的實作。

## In Scope

- 以 human-controlled Rover `v0.41.0` 的 default SDL stdout、repository 外安全提供的 GitHub token，以及固定 GitHub endpoint／headers 下載 GitHub GraphQL SDL。
- 將下載的 SDL 加上固定三行、且不含秘密的 provenance comments 後，管理為上述單一 schema path。
- 退休 GitHub Integration BC 的長期文件、placeholder source directory 與專用 boundary diagram，並將 PR Inbox／PR Reader 的 local Infra ownership 與 future `GitHubTransport` boundary 回寫到已授權文件與 BC map。
- 建立本 topic 同 slug 的四份正式 artifacts。

## Out of Scope

- `.graphql` operation、fragment、GraphQL codegen、Apollo runtime/configuration、generated source。
- `GitHubTransport`、REST／GraphQL transport、credential store、token injection、rate-limit handling 的任何實作。
- REST endpoint、OpenAPI snapshot、REST DTO／adapter，及任何空 REST directory。
- PR Reader Port、UseCase、adapter、DTO、failure mapping，或其他 BC 的產品／source 改動。
- target、module、package 結構調整；任何 GitHub schema operation type validation 的宣稱。

## Success Criteria

- schema 只存在於 PR Reader 指定 GraphQL path，且內容是未轉換的 Rover SDL output，前置固定三行 provenance comments。
- schema provenance 記錄 GitHub endpoint、實際下載 UTC 時間與固定 API version `2022-11-28`，且不含 token、Authorization、帳號或 repository identity。
- human 未提供安全外部 token／環境時停止於 human boundary；agent 不要求貼出、接收或執行 token。
- retirement 與 architecture writeback 明確表達 local BC Infra ownership、non-BC future `GitHubTransport`，以及 generic `RivetHTTPClient`；不將 deferred implementation 寫成既有能力。
