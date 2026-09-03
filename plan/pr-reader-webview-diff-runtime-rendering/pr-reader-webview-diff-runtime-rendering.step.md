# pr-reader-webview-diff-runtime-rendering — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-runtime-rendering`
- Current phase: Plan-Creator correction after PR-03 needs-rework
- Ledger rule: step status 與 checklist 不構成 approval；只有指定獨立角色的明示 verdict 可通過 gate。

## Goal

以既有 contracts 建立 PR Reader WebView diff 的 internal TypeScript runtime orchestration：Facade delegation、四 stage short-circuit 與 viewed `void` forwarding。

## Non-Goal

不實作 concrete stage、Git diff／diff2html、patch policy、DOM／HTML safety、Swift bridge、viewed persistence、公開 API 或 dependency 變更；不宣稱使用者可閱讀 rendered diff。

## In-Scope

- UseCase／Facade internal factories 與既定 runtime delegation。
- 四階段 success progression、failure pass-through、short-circuit 與 viewed forwarding tests。
- Output success 正規化、public-barrel value export non-leak regression test。
- 本 topic 的四份 formal planning artifacts，及兩個 docs 的唯一 truth amendment。

## Out-Of-Scope

- concrete Validator、Parser、Renderer、Output，及任何 Git diff template 或 opaque input schema。
- WebView DOM／UI、安全 policy、Swift transport、acknowledgement、retry 或 persistence。
- contracts、ports、adapters、public barrel、manifest、lockfile，以及兩個明示 docs 的唯一 truth amendment 以外的 architecture／BC docs。

## File Operations

- ReadOnly: contracts、ports、adapters、`index.ts`、package／lockfile，以及 `docs/architecture/README.md`／`docs/architecture/bounded-contexts/pr-reader.md` 的唯一 truth amendment 以外內容。
- Written: 本 ledger、同 slug 的 requirements、technical spec 與 execution plan。
- Deleted: 無。
- Modify: `usecases/diff-render-use-case.ts`、`facades/diff-facade.ts`、兩者 tests、`index.test.ts`；`docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` 僅可明示「Facade／UseCase orchestration 已有 runtime 實作；Validator、Parser、Renderer、Output 四個 concrete stages、DOM、Swift bridge、viewed-state persistence 仍未實作。」

## TestCase

- Full success stage order 與 value forwarding。
- `invalid-input`、`parse-error`、`render-error`、`output-error` 的原樣回傳與短路。
- Output success extra-field 正規化為新建 `{ type: "success" }`，以及既定 errors 原樣轉送。
- Facade `present` delegation、viewed `notify` single-call／`void` forwarding，以及採 `typeof import("./index")` 的 public barrel value export non-leakage。
- `bun run check` 與 `bun test`。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立 initial 同 slug 四份正式 artifacts。 | Artifacts 曾由 Plan-Creator 建立；不構成 Plan-Reviewer approval。 |
| PR-01 | not-completed — historical deviation | Plan-Reviewer | initial artifacts 的獨立審查。 | `0f1cb1e` 前無獨立 PR-01 verdict 或 approval 的可追溯證據；不得回填為任何 verdict 或 approval。 |
| IM-01 | completed — historical deviation | Implementer | initial runtime orchestration implementation。 | Commit `0f1cb1e` 先於可追溯 gate 記錄產生；當時無獨立 Plan-Reviewer approval。此事實不構成 gate pass。 |
| TE-01 | pending | Tester | initial implementation 的獨立驗證。 | 未保有原始 test evidence；不得標示 completed 或 approved。 |
| RV-01 | pending | Reviewer | initial implementation 的獨立 review。 | 未保有原始 review evidence；不得標示 completed 或 approved。 |
| PR-02 | needs-rework | Plan-Reviewer | 本次 retrospective planning review，辨識 workflow／truth drift 並提出保守補正需求。 | 明示 `needs-rework`；此 retrospective verdict 不追溯滿足 PR-01。 |
| PC-02 | completed | Plan-Creator | 如實記錄 historical deviation，加入兩個 PR fixes 與最小 docs amendment，且保留 mission／其他 exclusions。 | 本次 planning artifact amendment；不是 approval。 |
| PR-03 | needs-rework | Plan-Reviewer | 獨立審查 PC-02 amendment 的 scope、historical ledger、PR fixes、docs 限界與 handoff。 | 本次明示 verdict 為 `needs-rework`；不構成 implementation gate pass。 |
| PC-03 | completed | Plan-Creator | 依 PR-03 needs-rework 修正 historical PR-01 表述與 delivery／human handoff。 | 本次最小 ledger／plan amendment；不是 approval。 |
| PR-04 | pending | Plan-Reviewer | 獨立審查 PC-03 correction 的 historical ledger 與 delivery／human handoff，並明示 verdict。 | 尚無 verdict；`approved` 前不得開始 IM-02。 |
| IM-02 | pending | Implementer | 僅於 PR-04 `approved` 後，實作兩個 PR fixes 與明示 docs truth amendment。 | 尚無；不得提早實作。 |
| TE-02 | pending | Tester | IM-02 明示完成後，執行指定 runtime／type-level tests、`bun run check` 與 `bun test`。 | 尚無。 |
| RV-02 | pending | Reviewer | TE-02 verdict 後，獨立審查 IM-02 scope、contracts、docs amendment 與 evidence。 | 尚無。 |
| DL-01 | pending | Implementer | 僅於 RV-02 `approved` 後，依既有 human 明示授權 commit by topic、push，並只 resolve 已驗證處理的四個 review threads。 | 尚無；human 已明示授權本輪在 RV-02 approved 後 delivery，且不得 resolve 未驗證 thread。 |
| HC-01 | pending | Human | DL-01 delivery 完成後進行 PR review。 | 尚無；為 delivery 後的人類 PR review stop。 |

## Blockers

- 無新的 scope 或 contract blocker。
- 已知 workflow deviation：`0f1cb1e` 先於可追溯 gate 記錄，且此前無獨立 PR-01 verdict 或 approval 的可追溯證據；不得將它補記為 gate pass。
- 現行唯一下一步為 PR-04 的獨立 Plan-Reviewer review；PR-04 `approved` 是 IM-02、TE-02、RV-02、delivery 與 human boundary 的前提。

## Human Check

- PR-04、TE-02 或 RV-02 回傳 `blocked` 或 `human-check` 時，停止自動前進並交還 human。
- RV-02 明示 `approved` 後，依既有 human 授權進入 DL-01；HC-01 是 delivery 後的人類 PR review stop，不是 pre-delivery gate。不得以 historical IM-01 取代本輪 gate。

## Last Updated

- Updated by: Plan-Creator
- Update reason: 依 PR-03 needs-rework 修正未有證據的 PR-01 verdict 表述，並校正 delivery／human handoff。
- Update status: PR-01 not-completed historical deviation；PR-02、PR-03 needs-rework；PC-03 completed；唯一下一步為獨立 Plan-Reviewer 的 PR-04 review。
