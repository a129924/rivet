# PR Reader WebView Diff Runtime Orchestration — Execution Plan

## Summary

在 PR Reader WebView diff declaration baseline 上新增最小 TypeScript runtime orchestration。此計畫只實作 internal factories、Facade delegation 與四階段 UseCase short-circuit；不實作任何 concrete rendering capability。

## Goal and Boundaries

- **Goal**：讓內部 composition 能建立符合既定 `DiffFacade` 與 `DiffRenderUseCase` contract 的 runtime objects。
- **In-Scope**：UseCase four-stage flow、failure pass-through、Facade delegation、viewed `void` forwarding 與對應 runtime/type-level tests。
- **Out-Of-Scope**：concrete stages、Git diff／diff2html、DOM、安全 policy、Swift bridge／persistence、公開 API 與 dependency 變更。
- **Non-Goal**：不宣稱 diff 已可被解析、render 或顯示。

## Implementation Changes

- 在 `diff-render-use-case.ts` 實作 `createDiffRenderUseCase(dependencies)`，回傳符合既有 interface 的 object。`execute` 逐一消費前一 stage success value；每種既定 stage error 立即原樣回傳；Output success 回傳唯一 success outcome。
- 在 `diff-facade.ts` 實作 `createDiffFacade(dependencies)`，回傳符合既有 interface 的 object。`present` 單次委派 UseCase；viewed method 單次轉送通知、回傳 `void`。
- factories 保持 module-internal composition API：不修改 `index.ts`，不新增 public barrel export。
- 只修改 UseCase、Facade 與三個既有 test files；不改 contracts、ports、adapters、package manifest、lockfile 或 architecture docs。

## File Operations

| Operation | Scope |
| --- | --- |
| ReadOnly | 既有 contracts、ports、adapters、public barrel、package／lock、architecture 與 PR Reader BC docs。 |
| Written | 本 topic 的四份 formal planning artifacts。 |
| Modify | `usecases/diff-render-use-case.ts`、`facades/diff-facade.ts`、兩者 tests 與 `index.test.ts`。 |
| Deleted | 無。 |

## Test Plan

- Fake stage Ports 驗證完整 success 的 invocation order 與 success value forwarding。
- 對 `invalid-input`、`parse-error`、`render-error`、`output-error` 分別驗證 outcome pass-through 與下游未呼叫。
- 驗證 Facade `present` 單次 delegation、viewed change 單次 `notify`／`void` forwarding，且 viewed flow 不呼叫 UseCase。
- 驗證 public barrel 不輸出 factories，既有 public type surface 不變。
- 執行 `bun run check` 與 `bun test`。

## Assumptions and Human Boundary

- Stage Ports 依既有 union contract 回傳；未定義 exception 不處理。
- 未來 patch、metadata-only 與 DOM safety policy 不在此 execution contract。
- 必須取得獨立 Plan-Reviewer 的明示 `approved` 才可派遣 Implementer；完成 Reviewer approval 後，Git commit 前停止等待 human confirmation。
