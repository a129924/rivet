# PR Reader WebView Diff Runtime Orchestration — Technical Spec

## Locked Decisions

- Primary BC 為 PR Reader；本 topic 遵守已鎖定的 runtime 路徑：`Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`。
- `DiffFacade` 僅保留 `present(snapshot)` 與 `requestViewedStateChange(change)` 兩個 public methods；公開 `index.ts` 不變。
- `DiffRenderUseCase` 是四個 stage Port 的唯一協調者，也是 `DiffOutputPort` 的唯一 caller；Facade 不依賴 Output Port。
- 兩個 factories 是 internal module exports，不從 public barrel 匯出：

```ts
createDiffRenderUseCase(
  dependencies: DiffRenderUseCaseDependencies,
): DiffRenderUseCase

createDiffFacade(
  dependencies: DiffFacadeDependencies,
): DiffFacade
```

- `execute(snapshot)` 依序執行 `validator.validate`、`parser.parse`、`renderer.createRenderPlan`、`output.output`。只有前一 stage 回傳 success 才可呼叫下游；error outcome 原樣回傳，禁止包裝、重分類或繼續執行。
- Output success 映射為 `{ type: "success" }`。未定義 thrown exception 不新增 failure mapping，也不在本 topic catch。
- `present(snapshot)` 只呼叫一次 `useCase.execute(snapshot)` 並回傳其 outcome。
- `requestViewedStateChange(change)` 只呼叫一次 `viewedStateChange.notify(change)` 並回傳 `void`；不等待、不 retry、不呼叫 UseCase、不修改 snapshot。
- 既有 opaque types 保持 opaque。runtime tests 僅使用 test-local sentinel 或 type assertion，不得建立 production schema。

## File Impact Contract

| Category | Paths / policy |
| --- | --- |
| ReadOnly | contracts、ports、adapters、`index.ts`、package manifest、lockfile、architecture／PR Reader BC docs。 |
| Written | 同 slug 的 requirements、technical spec、plan、step ledger 四份 artifacts。 |
| Modify | UseCase、Facade 及它們各自 tests、public-surface regression test。 |
| Deleted | 無。 |

## Explicit Exclusions

- 禁止 concrete Validator、Parser、Renderer、Output、Git diff template、diff2html 或 patch policy。
- 禁止 DOM／HTML、escaping／security policy、UI，及 Swift／WebView bridge 或 viewed persistence。
- 禁止新增 public API、Port、stage、failure kind、dependency，或改變 snapshot 與 Swift ownership contract。

## Verification Contract

- Runtime tests 必須建立可觀察的 fake dependencies，以驗證順序、值傳遞、四種 failure short-circuit、Facade delegation 與 viewed forwarding。
- Type-level regression 必須證明 factories 不經 public barrel 洩漏，且既有 public contracts 不變。
- 實作後執行 `bun run check` 與 `bun test`；任何失敗交給對應 Implementer 回修，不以 workaround 擴張 scope。

## Stop Conditions

- 若需定義 concrete stage input、Git diff／patch 行為、DOM safety、Swift transport、persistence 或新的 public／failure contract，停止並另開 topic 或交還 human。
- 規劃 artifacts 必須先由獨立 Plan-Reviewer 明示 `approved`；未取得 approval 不得實作。
