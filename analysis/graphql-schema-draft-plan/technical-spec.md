# GitHub GraphQL Schema Future Material：技術規格

## Locked Architecture Contract

- GitHub Integration 僅提供 lower shared authorization capability；consuming Domain BC 的 local Infra 擁有 GitHub identity、外部 protocol data、DTO、HTTP status 與 infrastructure-failure mapping。PR Inbox 與 PR Reader 各自擁有自己的 Core Port，且不直接相依；Integration 不擁有、引用或符合 Domain-owned Port。
- future `GitHubGraphQLAdapter` 屬於 consuming Domain BC 的 local Infra/GitHub boundary，並封裝 `ApolloClient`；它不經 `RivetHTTPClient.Transport`，也不經本 topic 已鎖定的 REST authorizer → `RivetHTTPClient` flow。
- Apollo token interceptor、GraphQL token delivery、failure、refresh、re-auth、operation、codegen 與具體 adapter contract 尚未決定。它們不得從現有 SDL candidate、REST lifecycle 或 `GitHubTokenProvider` direction 推論。

## Candidate Material Contract

`Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` 目前只是 conflict tree 中的 candidate material：

- 它不代表已接受的 shared-capability schema snapshot，不代表 PR Reader local Infra ownership，亦不證明 Rover acquisition、provenance、secret hygiene、schema completeness 或 GraphQL capability。
- PR-02 pending 時，本次不移動、修改、驗證、下載、複製或刪除該檔案。其 staged presence 不構成 Implementer delivery，也不構成 Tester pass；PR-02 approved 僅接受此 reclassification，仍不授權 asset move。
- 未來 consuming Domain BC 的 GitHub GraphQL adapter／schema topic 必須先決定 exact local Infra/GitHub asset path、candidate 是否可採用或必須重新取得、provenance／secret policy、schema verification、Apollo adapter boundary、operation／codegen 與 token／failure contract；未獲授權前一律不實作。GitHub Integration lower shared capability 不取得 asset 或 Domain Port ownership。

## File Contract

| Change kind | Exact paths |
| --- | --- |
| Modify | `analysis/graphql-schema-draft-plan/{requirements.md,technical-spec.md}`；`plan/graphql-schema-draft-plan/{graphql-schema-draft-plan.plan.md,graphql-schema-draft-plan.step.md}` |
| Read-only candidate | `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` |
| Read-only retained architecture | `docs/architecture/bounded-contexts/github-integration.md`；`docs/architecture/diagrams/github-integration-http-client-boundary/` |

所有其他 source、docs、diagram、map 與 generated output 都不因本草案而改動。後續實作的 exact write boundary 必須由新的 consuming Domain BC local-Infra GitHub adapter／schema topic 決定；不得沿用本草案推定 source path 或刪除目標。

## Gate Reset

原草案中聲稱的 GitHub Integration retirement、architecture writeback、IM-01 completed、HG-01／IM-02／TE-01 delivery evidence，均不再是可接受的 current delivery facts：它們與 human 保留 Integration BC／canonical diagrams 的決定不相容。

- 這不否定可能曾存在的 external acquisition material；它只表示該 material 尚未被本 topic 接受為 delivery。
- 原 `RV-01` 與 `HC-02` 不可繼續作為 delivery gate，因為其前提已撤回。
- 新的 PC-02 → PR-02 只審查本次 reclassification；它不授權 schema、docs、map、source 或 generated output 的實作。
