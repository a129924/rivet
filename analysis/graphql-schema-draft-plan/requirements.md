# GitHub Integration GraphQL Schema Future Material：需求

## Goal

將目前衝突樹中的 GitHub GraphQL SDL 與其草案，重新界定為未來 **GitHub Integration GraphQL adapter／schema snapshot topic** 可評估的素材；它不是 PR Reader local Infra 的已交付 schema，也不構成任何 GraphQL runtime、adapter 或 authentication capability。

GitHub Integration 仍是 Supporting BC，並保留其既有 Bounded Context 文件與 canonical diagrams。此草案不得以 retirement、delete 或 invalidate 的語言推翻已鎖定的 BC／boundary 決定。

## In Scope

- 將 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` 視為待未來 topic 接受、搬移或重新取得的 **candidate material**；目前不宣稱其 provenance、完整性、路徑或 repository delivery 已被接受。
- 記錄未來 GitHub Integration GraphQL topic 必須先鎖定 schema asset 的正式位置、取得／provenance、Apollo adapter、operation／codegen 與 failure contract，才可將 candidate material 轉為交付。
- 保留 Integration-owned authorization boundary：REST authorizer 與 `RivetHTTPClient` 的關係不延伸至 GraphQL；Apollo token interceptor、token delivery 與 failure／refresh／re-auth contract 均維持 deferred。
- 建立與本草案同 slug 的 analysis／plan artifacts，讓後續 Planner 取得不把現有 staged material 誤當完成交付的起點。

## Out of Scope

- 將 candidate SDL 視為目前正式 source asset、驗證其內容、重跑 Rover、接觸 token，或宣稱 schema acquisition 已完成。
- 刪除、退休或否定 GitHub Integration BC、其 placeholder source location、BC 文件或 canonical diagrams。
- 建立 `GitHubTransport`、BC-local exclusive GitHub Infra、REST／GraphQL adapter、Apollo client／interceptor、operation、codegen、runtime、DTO、Core Port mapping 或 failure implementation。
- 改變既定 REST-only authorizer／Apollo-only route、PAT-only、deferred concrete signature、failure、refresh、re-auth 或 human-gate 決定。

## Success Criteria

- 所有本草案文件都將 SDL 明確稱為 future-topic candidate material，而非已接受或已交付的 PR Reader asset。
- 不再存在把 GitHub Integration 表述為 retired、deleted 或 invalidated 的本草案 contract。
- 任何後續實作均以獨立 human-approved topic 鎖定 exact path、schema acquisition、adapter／interceptor 與 token／failure contract；在此之前沒有 implementation gate 可視為完成。
