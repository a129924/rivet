# GitHub GraphQL Schema Future Material — Execution Plan

## Summary

本計畫只重新分類既有 GitHub GraphQL SDL candidate，供未來 consuming Domain BC 的 local GitHub GraphQL adapter／schema topic 評估。它不交付 schema、不建立 GraphQL capability，也不改變 GitHub Integration 作為 lower shared capability 的邊界。

## In Scope

- 以此同 slug 四份 artifacts 記錄 candidate material 與後續 topic 的必要決策。
- 保留 GraphQL Apollo-only route 與 REST-only authorizer boundary；GitHub Integration 僅提供 lower shared capability，不擁有 GraphQL adapter／schema；不預選 Apollo token interceptor 或 token／failure contract。
- 如實撤回與目前 human architecture decision 相衝突的 retirement／delete／invalidate contract 與 delivery status。
- 鎖定 ownership direction：Domain BC owns Port 與 local Infra/GitHub adapter；GitHub Integration 只提供 lower shared capability，不擁有 candidate 或 Domain Port。PR-02 pending 時 candidate 維持 read-only；PR-02 approved 也只放行 reclassification，不放行 move。

## Non-Goal

- 不建立、搬移、驗證、下載、刪除或接受 `Schema.graphqls`。
- 不更動 GitHub Integration BC、canonical diagrams、bounded-context map、active architecture docs、Swift source、package、module、target、operation、codegen、Apollo runtime 或 `RivetHTTPClient`。
- 不執行 Rover、接觸 GitHub token，或將 candidate 的 staged presence 當成 human gate、Implementer delivery、Tester pass 或 Reviewer approval。
- 不將現有 `PRReader/Infra/GitHub` path 誤稱為 accepted ownership，或在 future consuming Domain topic 未鎖定 exact path、provenance 與 verification 前移動／刪除／materialize candidate。

## Write Boundary

| Category | Paths |
| --- | --- |
| Modify | `analysis/graphql-schema-draft-plan/{requirements.md,technical-spec.md}`；`plan/graphql-schema-draft-plan/{graphql-schema-draft-plan.plan.md,graphql-schema-draft-plan.step.md}` |
| Read-only candidate | `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` |
| Read-only retained architecture | `docs/architecture/bounded-contexts/github-integration.md`；`docs/architecture/diagrams/github-integration-http-client-boundary/` |

## Test Plan

- Plan-Reviewer 確認 candidate material、not-delivered status、retained Integration BC、REST-only／Apollo-only boundary，以及 deferred adapter／interceptor／token／failure contract 互不矛盾。
- Reviewer 確認不存在 retirement、delete、invalidate、已完成 acquisition 或 completed implementation 的 current claim。
- Plan-Reviewer 確認 local Infra ownership 不會讓 GitHub Integration 實作／依賴 Domain Port；current candidate path 在 PR-02 pending 時仍為 read-only。
- 不執行 schema、Rover、secret、renderer 或 source validation；那些檢查只有在 future topic 鎖定 exact asset path、acquisition 與 verification contract 後才能開始。

## Human Boundary

PR-02 approved 後，這份草案只成為 future material；未來 consuming Domain BC topic 若欲採用 candidate、選定 local Infra/GitHub asset path、接觸 credential、取得 SDL、建立 Apollo adapter／interceptor、operation／codegen 或任何 token／failure contract，均需新的 human decision 與正式 planning chain。此計畫不授權任何一項。
