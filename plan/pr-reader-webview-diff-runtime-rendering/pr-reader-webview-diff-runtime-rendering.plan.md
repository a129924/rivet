# PR Reader WebView Diff Runtime Orchestration — Execution Plan

## Summary

在 PR Reader WebView diff declaration baseline 上新增最小 TypeScript runtime orchestration。此計畫只實作 internal factories、Facade delegation 與四階段 UseCase short-circuit；不實作任何 concrete rendering capability。

## Goal and Boundaries

- **Goal**：讓內部 composition 能建立符合既定 `DiffFacade` 與 `DiffRenderUseCase` contract 的 runtime objects。
- **In-Scope**：UseCase four-stage flow、failure pass-through、Facade delegation、viewed `void` forwarding、兩個受限 PR fixes 與對應 runtime/type-level tests；以及兩個 docs 的唯一 truth amendment。
- **Out-Of-Scope**：concrete stages、Git diff／diff2html、DOM、安全 policy、Swift bridge／persistence、公開 API 與 dependency 變更。除明示的兩個 docs 句子外，架構與 BC 文件亦維持 out-of-scope。
- **Non-Goal**：不宣稱 diff 已可被解析、render 或顯示。

## Implementation Changes

- 在 `diff-render-use-case.ts` 維持 `createDiffRenderUseCase(dependencies)` 的既有範圍。`execute` 逐一消費前一 stage success value；每種既定 stage error 立即原樣回傳；Output success 必須正規化為新建的唯一 `{ type: "success" }`，不得保留 Output 的額外欄位。
- 在 `diff-facade.ts` 實作 `createDiffFacade(dependencies)`，回傳符合既有 interface 的 object。`present` 單次委派 UseCase；viewed method 單次轉送通知、回傳 `void`。
- factories 保持 module-internal composition API：不修改 `index.ts`，不新增 public barrel export。
- 將 `index.test.ts` 的 factory non-leak assertion 改為以 `typeof import("./index")` 取得 value export map，再斷言兩個 factory key 不存在；不得以 type-only import 檢查 value export。
- 唯一獲授權的 docs 修改是 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` 各自明示：Facade／UseCase orchestration 已有 runtime 實作；Validator、Parser、Renderer、Output 四個 concrete stages、DOM、Swift bridge、viewed-state persistence 仍未實作。不得加入其他架構結論。
- 不改 contracts、ports、adapters、public barrel、package manifest 或 lockfile。

## File Operations

| Operation | Scope |
| --- | --- |
| ReadOnly | 既有 contracts、ports、adapters、public barrel、package／lock，以及兩個明示 docs 之外的 architecture 與 PR Reader BC docs。 |
| Written | 本 topic 的四份 formal planning artifacts。 |
| Modify | `usecases/diff-render-use-case.ts`、`facades/diff-facade.ts`、兩者 tests、`index.test.ts`，以及僅含既定 truth amendment 的 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/pr-reader.md`。 |
| Deleted | 無。 |

## Test Plan

- Fake stage Ports 驗證完整 success 的 invocation order 與 success value forwarding。
- 對 `invalid-input`、`parse-error`、`render-error`、`output-error` 分別驗證 outcome pass-through 與下游未呼叫。
- Output fake success 帶額外欄位時，驗證 UseCase 結果為新建的 `{ type: "success" }`；既定 error outcome 不重包裝。
- 驗證 Facade `present` 單次 delegation、viewed change 單次 `notify`／`void` forwarding，且 viewed flow 不呼叫 UseCase。
- 以 `typeof import("./index")` 的 value export map 驗證 public barrel 不輸出 factories，既有 public type surface 不變。
- 執行 `bun run check` 與 `bun test`。

## Assumptions and Delivery Handoff

- Stage Ports 依既有 union contract 回傳；未定義 exception 不處理。
- 未來 patch、metadata-only 與 DOM safety policy 不在此 execution contract。
- `0f1cb1e` 已在可追溯 gate 完成前產生，屬 historical deviation；此前無獨立 PR-01 verdict 或 approval 的可追溯證據，不得回填或改寫為已符合 PR-01。
- 必須取得本次獨立 Plan-Reviewer 的 PR-04 明示 `approved` 才可派遣 Implementer 執行 PR fixes 與最小 docs amendment。
- RV-02 明示 `approved` 後，依 human 已明示的本輪授權：commit by topic、push，並只 resolve 已驗證處理的四個 review threads；不新增 pre-delivery human gate。delivery 後停止於 human PR review。
