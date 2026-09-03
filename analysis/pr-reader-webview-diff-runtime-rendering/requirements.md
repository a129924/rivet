# PR Reader WebView Diff Runtime Orchestration — Requirements

## Goal

讓既有 declaration-only PR Reader WebView diff pipeline 具備最小可執行的 TypeScript orchestration：Presentation 可透過 `DiffFacade.present` 依既定順序呼叫四個已存在的 stage Port，並取得既定 render outcome；viewed-state request 可單向轉送給既定 notification Port。

## In-Scope

- 在既有 `DiffRenderUseCase` module 建立 internal factory 與四階段 runtime orchestration。
- 在既有 `DiffFacade` module 建立 internal factory 與 `present`／`requestViewedStateChange` 的 runtime delegation。
- 以既有 dependency descriptors 注入 `validator`、`parser`、`renderer`、`output`、`useCase` 與 `viewedStateChange`。
- 以 Bun runtime tests 驗證 success、四種既定 failure、short-circuit 與 viewed notification forwarding。
- 修正 public-barrel regression test，使其以 `typeof import()` 檢查 value export，而非以 type import 假設 value factory 不外洩。
- 修正 UseCase 的 Output success handling：只回傳新的 `{ type: "success" }`，既定 error outcome 仍原樣轉送；以 Output success 帶額外欄位的 test 鎖定此行為。
- 依 human 授權對 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` 做最小 truth amendment：僅明示「Facade／UseCase orchestration 已有 runtime 實作；Validator、Parser、Renderer、Output 四個 concrete stages、DOM、Swift bridge、viewed-state persistence 仍未實作。」
- 建立本 topic 的正式 SDD artifacts。

## Out-Of-Scope

- Validator、Parser、Renderer、Output 的 concrete implementation，及任何新增 Port、stage 或 dependency。
- `GitDiffTemplate`、diff2html、patch 格式、metadata-only file policy、opaque success input schema。
- DOM、HTML escaping、安全 policy、WebView UI、collapse 或 syntax highlighting。
- Swift bridge、message transport、acknowledgement、retry、viewed persistence 或 optimistic snapshot update。
- 公開 barrel、既定 Facade API、failure kinds、Swift ownership、package manifest 與 lockfile 的變更。
- 除本輪授權的 `docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` truth amendment 外，所有 architecture／BC 文件變更。

## Success Criteria

- UseCase 僅在前一 stage success 時依 Validator → Parser → Renderer → Output 順序呼叫下游；任一既定 stage error 原樣終止並回傳。
- Output success 正規化為新的唯一 `{ type: "success" }`，不得保留 Output success 的額外欄位；既定 failure 原樣轉送、不 retry，亦不捕捉或分類未定義 thrown exception。
- Facade 的兩個既定 public methods 維持不變；`present` 單次委派 UseCase，viewed request 單次、best-effort `void` 轉送 notification Port。
- internal factories 不得由 public `index.ts` 匯出。

## Non-Goal

本 topic 不讓使用者看見可渲染 diff；它只提供供後續 concrete-stage topic 注入的 orchestration。Parser、render plan 與 DOM output 仍未定義。

## ReadOnly

- `contracts/`、`ports/`、`adapters/` 下既有 declaration contract。
- public `index.ts`、package configuration 與 lockfile。
- 除本輪唯一授權的最小 truth amendment 外，`docs/architecture/README.md` 與 `docs/architecture/bounded-contexts/pr-reader.md` 的所有內容。

## Written

- `analysis/pr-reader-webview-diff-runtime-rendering/requirements.md`
- `analysis/pr-reader-webview-diff-runtime-rendering/technical-spec.md`
- `plan/pr-reader-webview-diff-runtime-rendering/pr-reader-webview-diff-runtime-rendering.plan.md`
- `plan/pr-reader-webview-diff-runtime-rendering/pr-reader-webview-diff-runtime-rendering.step.md`

## Deleted

無。不得刪除 declaration contract、Port、Adapter、public barrel 或既有 tests。

## Modify

- `surfaces/pr-reader-webview/src/diff-rendering/usecases/diff-render-use-case.ts`
- `surfaces/pr-reader-webview/src/diff-rendering/facades/diff-facade.ts`
- `surfaces/pr-reader-webview/src/diff-rendering/usecases/diff-render-use-case.test.ts`
- `surfaces/pr-reader-webview/src/diff-rendering/facades/diff-facade.test.ts`
- `surfaces/pr-reader-webview/src/diff-rendering/index.test.ts`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/pr-reader.md`

## TestCase

- Full success：四個 fake Port 依順序呼叫，每個下游接收前一 stage 的 success value，結果為新的 `{ type: "success" }`。
- `invalid-input`：Validator failure 後，Parser、Renderer、Output 不得呼叫。
- `parse-error`：Parser failure 後，Renderer、Output 不得呼叫。
- `render-error`：Renderer failure 後，Output 不得呼叫。
- `output-error`：前三個 stage success，Output failure 原樣回傳。
- Facade `present`：單次傳遞 snapshot 給 UseCase，並原樣回傳 success 或 failure outcome。
- Viewed request：單次通知 Port、回傳 `void`，不得呼叫 UseCase 或修改 snapshot。
- Output success normalization：當 Output fake 的 success value 帶有額外欄位時，UseCase 結果仍只能是新的 `{ type: "success" }`；四種既定 error 不得被重包裝。
- Public surface：以 `typeof import("./index")` 的 value export map 驗證 factory 不得由 barrel 取得，既有 Facade 與 contracts 仍可 typecheck。

## Open Research

無。本 topic 不處理 patch template、無 patch policy 或 DOM safety；它們保留給後續 concrete-stage topic。
