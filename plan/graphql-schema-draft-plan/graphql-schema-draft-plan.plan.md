# GitHub Integration GraphQL Schema Future Material — Execution Plan

## Summary

本計畫只重新分類既有 GitHub GraphQL SDL candidate，供未來 GitHub Integration GraphQL adapter／schema snapshot topic 評估。它不交付 schema、不建立 GraphQL capability，也不改變保留中的 GitHub Integration BC／canonical diagrams。

## In Scope

- 以此同 slug 四份 artifacts 記錄 candidate material 與後續 topic 的必要決策。
- 保留 Integration-owned GraphQL Apollo route 與 REST-only authorizer boundary；不預選 Apollo token interceptor 或 token／failure contract。
- 如實撤回與目前 human architecture decision 相衝突的 retirement／delete／invalidate contract 與 delivery status。

## Non-Goal

- 不建立、搬移、驗證、下載、刪除或接受 `Schema.graphqls`。
- 不更動 GitHub Integration BC、canonical diagrams、bounded-context map、active architecture docs、Swift source、package、module、target、operation、codegen、Apollo runtime 或 `RivetHTTPClient`。
- 不執行 Rover、接觸 GitHub token，或將 candidate 的 staged presence 當成 human gate、Implementer delivery、Tester pass 或 Reviewer approval。

## Write Boundary

| Category | Paths |
| --- | --- |
| Modify | `analysis/graphql-schema-draft-plan/{requirements.md,technical-spec.md}`；`plan/graphql-schema-draft-plan/{graphql-schema-draft-plan.plan.md,graphql-schema-draft-plan.step.md}` |
| Read-only candidate | `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` |
| Read-only retained architecture | `docs/architecture/bounded-contexts/github-integration.md`；`docs/architecture/diagrams/github-integration-http-client-boundary/` |

## Test Plan

- Plan-Reviewer 確認 candidate material、not-delivered status、retained Integration BC、REST-only／Apollo-only boundary，以及 deferred adapter／interceptor／token／failure contract 互不矛盾。
- Reviewer 確認不存在 retirement、delete、invalidate、已完成 acquisition 或 completed implementation 的 current claim。
- 不執行 schema、Rover、secret、renderer 或 source validation；那些檢查只有在 future topic 鎖定 exact asset path、acquisition 與 verification contract 後才能開始。

## Human Boundary

未來 topic 若欲採用 candidate material、選定正式 asset path、接觸 credential、取得 SDL、建立 Apollo adapter／interceptor、operation／codegen 或任何 token／failure contract，均需新的 human decision 與正式 planning chain。此計畫不授權任何一項。
