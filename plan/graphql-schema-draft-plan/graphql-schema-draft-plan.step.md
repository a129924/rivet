# GitHub Integration GraphQL Schema Future Material：Step Ledger

## Current Phase

`PC-02` 已完成本次 planning reclassification；**current step 是 `PR-02` 的獨立 Plan-Reviewer**。沒有 schema、docs、map、source 或 generated output 的實作被本 ledger 放行。GitHub Integration BC 與 canonical diagrams 維持 retained。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-01 | Plan-Creator | superseded | 原 schema-only／retirement draft。 | 不可作為 current delivery contract。 | 其 retirement／delete／local-exclusive Infra 前提與後續 human 保留 GitHub Integration 的決定不相容。 |
| PR-01 | Plan-Reviewer | superseded | 原 planning review。 | 不可放行原 implementation path。 | 原 review 的範圍前提已撤回；不轉述為本次 approval。 |
| IM-01 | Implementer | superseded / not accepted | 原先宣稱的 retirement／architecture writeback。 | 不可視為 completed delivery。 | human 已決定保留 GitHub Integration BC／canonical diagrams；原本的 retirement、delete、invalidate 與 local-exclusive claims 不得採用。 |
| HG-01 | Human | historical material only | 可能曾存在的受控 acquisition。 | 不構成 current topic acceptance 或後續實作授權。 | 不記錄 token、命令、repository identity 或 provenance；candidate 必須由 future topic 重新判定是否可採用。 |
| IM-02 | Implementer | superseded / not accepted | 原先對 SDL materialization 的宣稱。 | 不可視為 completed schema delivery。 | `Schema.graphqls` 僅保留為 read-only candidate material，未被本 topic 接受。 |
| TE-01 | Tester | superseded / not accepted | 原 schema／map verification claim。 | 不可作為 current pass evidence。 | 其驗收以前述 retirement architecture 為前提，與 retained Integration boundary 不相容。 |
| RV-01 | Reviewer | not-started | 原 delivery review。 | 不可開始；沒有有效的 implementation 前提。 | 被 PC-02／PR-02 reclassification 取代。 |
| HC-02 | Human | not-started | 原 final delivery human gate。 | 不可開始。 | 無有效 delivery 可供接受。 |
| PC-02 | Plan-Creator | completed | 將 schema 與原 draft 重新分類為 future GitHub Integration topic material，並撤回不實的 retirement／delivery claims。 | 四份 artifacts 一致保留 Integration BC／canonical diagrams、candidate status 與 deferred contracts。 | 僅修改本 topic 四份 artifacts；未改 schema、docs、map、source、generated output，未接觸 token、commit、push、PR 或 resolve thread。 |
| PR-02 | Plan-Reviewer | pending | 獨立審查 PC-02 的 reclassification、gate reset 與 retained architecture consistency。 | 明示 verdict 為 approved、needs-rework 或 blocked；只有 approved 才能接受此草案作 future-topic material。 | 待獨立 Plan-Reviewer verdict；不授權實作。 |

## Blockers

- `PR-02` 是唯一 current gate。它只審查 planning reclassification，不能放行 schema asset、architecture writeback 或 GraphQL implementation。
- candidate SDL 的正式位置、是否採用、provenance、secret hygiene、Rover acquisition、schema verification、Apollo adapter／interceptor、operation／codegen 與 token／failure contract 全部未鎖定，必須由 future GitHub Integration topic 處理。

## Handoff

交給獨立 Plan-Reviewer。若 verdict 是 `approved`，此草案只成為 future topic 的 research material；若要實作任何 asset 或 adapter，仍需由 Planner 建立新的正式 topic 與 gate。若 verdict 是 `needs-rework`、`blocked` 或 `human-check`，停止並交還 human。

## Last Updated

2026-09-09（Plan-Creator 依 human「保留 GitHub Integration BC／canonical diagrams；GraphQL draft／schema asset 改為未來 Integration topic 素材」決定完成 PC-02；未宣稱任何 schema delivery、thread resolve 或 human approval。）
