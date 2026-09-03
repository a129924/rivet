# pr-reader-webview-diff-runtime-rendering — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-runtime-rendering`
- Current phase: Plan-Reviewer review
- Ledger rule: step status 與 checklist 不構成 approval；只有指定獨立角色的明示 verdict 可通過 gate。

## Goal

以既有 contracts 建立 PR Reader WebView diff 的 internal TypeScript runtime orchestration：Facade delegation、四 stage short-circuit 與 viewed `void` forwarding。

## Non-Goal

不實作 concrete stage、Git diff／diff2html、patch policy、DOM／HTML safety、Swift bridge、viewed persistence、公開 API 或 dependency 變更；不宣稱使用者可閱讀 rendered diff。

## In-Scope

- UseCase／Facade internal factories 與既定 runtime delegation。
- 四階段 success progression、failure pass-through、short-circuit 與 viewed forwarding tests。
- 本 topic 的四份 formal planning artifacts。

## Out-Of-Scope

- concrete Validator、Parser、Renderer、Output，及任何 Git diff template 或 opaque input schema。
- WebView DOM／UI、安全 policy、Swift transport、acknowledgement、retry 或 persistence。
- contracts、ports、adapters、public barrel、manifest、lockfile、architecture／BC docs。

## File Operations

- ReadOnly: contracts、ports、adapters、`index.ts`、package／lockfile、architecture 與 PR Reader BC docs。
- Written: 本 ledger、同 slug 的 requirements、technical spec 與 execution plan。
- Deleted: 無。
- Modify: `usecases/diff-render-use-case.ts`、`facades/diff-facade.ts`、兩者 tests、`index.test.ts`。

## TestCase

- Full success stage order 與 value forwarding。
- `invalid-input`、`parse-error`、`render-error`、`output-error` 的原樣回傳與短路。
- Facade `present` delegation、viewed `notify` single-call／`void` forwarding、public barrel non-leakage。
- `bun run check` 與 `bun test`。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 依 human accepted plan 建立同 slug 的四份正式 artifacts，完整記錄 scope、file operations、non-goal 與 test cases。 | Artifacts 已由 Plan-Creator 建立；此 completion 不是 Plan-Reviewer approval。 |
| PR-01 | pending | Plan-Reviewer | 獨立檢查四份 artifacts 的 scope、locked contracts、file impact、test plan 與 workflow handoff，並明示 `approved`、`needs-rework`、`blocked` 或 `human-check` verdict。 | 尚無獨立 Plan-Reviewer verdict。 |
| IM-01 | pending | Implementer | 僅在 PR-01 明示 `approved` 後，受限實作兩個 internal factories、UseCase four-stage orchestration、Facade delegation 與指定 tests。 | 尚無；不得在 PR-01 approval 前實作。 |
| TE-01 | pending | Tester | 在 Implementer 明示完成交接後，執行 runtime／type-level scenarios、`bun run check` 與 `bun test`，提供明示 test verdict。 | 尚無。 |
| RV-01 | pending | Reviewer | 在 Tester 明示驗證結果後，獨立審查 implementation scope、contracts、tests 與 evidence，明示 verdict。 | 尚無。 |
| HC-01 | pending | Human | 在 Reviewer 明示 `approved` 後，確認是否允許依 topic 進行 commit、push 與 draft PR handoff。 | 尚無；此為 Git 動作前 human boundary。 |

## Blockers

- 無已知 scope 或 contract blocker。
- 現行 gate 為 PR-01 的獨立 Plan-Reviewer verdict；`PC-01 completed` 不構成 approval。

## Human Check

- 若 PR-01、TE-01 或 RV-01 回傳 `blocked` 或 `human-check`，停止自動前進並交還 human。
- RV-01 明示 `approved` 後，仍需 HC-01 明示確認才可進行 commit、push 或 draft PR。

## Last Updated

- Updated by: Plan-Creator
- Update reason: 建立 initial planning contract 與 execution ledger。
- Update status: PC-01 completed；PR-01 pending，唯一下一步為獨立 Plan-Reviewer review。
