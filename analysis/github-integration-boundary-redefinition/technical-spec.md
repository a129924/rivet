# GithubIntegration Boundary Redefinition：技術規格

## 現況 Inventory

| 項目 | 現況 | 本 topic 的處置 |
| --- | --- | --- |
| `GithubIntegration` runtime module／package／target | 不存在。 | 不建立；僅定義 future shared-module boundary。 |
| 集中式 `GithubService` | 不存在。 | 不建立。 |
| GitHub authentication、retry、rate-limit 實作 | 不存在。 | 不實作；僅列為 future technical-mechanism 類別。 |
| `RivetHTTPClient` | 已存在 generic、GitHub-unaware HTTP foundation。 | ReadOnly；不宣稱它是 `GithubIntegration` 的實作。 |
| PR Inbox | Core／UseCase／Port 不依賴 GitHub 或 HTTP。 | 維持 isolation。 |
| PR Reader | 僅 Infra 下存在 GitHub GraphQL SDL schema snapshot。 | 維持為 BC-local integration-facing asset，不搬移。 |
| `docs/github-api/README.md` | GitHub capability catalog introduction 與「共通規則」。 | 後續 documentation delivery 可修改 introduction，以及「共通規則」中 shared-module boundary wording；不定義 BC contract、model 或 authentication 實作。 |
| `docs/github-api/` 其餘 catalog 文件 | GitHub capability reference。 | ReadOnly inventory 依據；不修改 capability content。 |
| parent `dev` baseline 的 `docs/architecture/README.md` | 將 GitHub Integration 列為 Supporting BC，並導航至 authorization boundary canvas。 | supersede 該 active architecture claim；移除 navigation，保留 PR #17／舊 topic traceability。 |
| parent `dev` baseline 的 `docs/architecture/bounded-contexts/README.md` | 將 GitHub Integration 列入 BC index，並定義為只提供 lower shared authorization capability 的 Supporting BC。 | supersede 該 active index／boundary claim。 |
| parent `dev` baseline 的 `docs/architecture/bounded-contexts/github-integration.md` | Supporting BC 主文件，記錄 authorization seam、future token provider 與 request authorizer direction。 | 退役此 active 主文件；git history 保留 supersession traceability。 |
| parent `dev` baseline 的 `docs/architecture/diagrams/github-integration-http-client-boundary/` | active canvas 與 authorization lifecycle，將 GitHub Integration 畫為 lower shared authorization capability。 | 退役此 active canvas 與 lifecycle artifact，並移除 active navigation；git history 保留 supersession traceability。 |

## Dependency Map

目標 compile-time direction：

```text
BC Domain
    ↑
BC Application / UseCase / Port
    ↑ implements
BC Infrastructure GitHub Adapter
    ↓
GithubIntegration (shared GitHub-specific technical module)
    ↓
GitHub REST / GraphQL API
```

- 允許：BC Infrastructure GitHub Adapter → `GithubIntegration`。
- 禁止：`GithubIntegration` → 任一 BC；BC Domain／UseCase／Application Port → `GithubIntegration`；BC Domain → 其他 BC Domain。
- `GithubIntegration` 僅提供 raw transport 與 GitHub error technical classification；它不得產生 shared BC failure contract。Adapter 擁有 endpoint-specific media type、外部 GitHub DTO／GraphQL node 到 BC vocabulary 的 translation、該 classification 到 BC failure contract 的 mapping，以及 BC business meaning。

## KEEP／MOVE／SPLIT／REMOVE

| 分類 | 現況結論 | 後續準則 |
| --- | --- | --- |
| KEEP | 沒有可搬移的現有 `GithubIntegration` runtime component。`RivetHTTPClient` 維持既有 generic foundation。 | future module 僅可收納 GitHub raw transport、auth mechanism、共通 headers／API version、pagination、rate-limit、retry、GitHub error technical classification、shared configuration；不得收納 shared BC failure contract。 |
| MOVE | 未發現集中 module 中含 BC semantics 的 component。PR Reader GraphQL SDL 已在 BC Infra，維持原位。 | 任何 Pull Request、Review、Repository、Workflow 的 business interpretation 留在 owning BC adapter。 |
| SPLIT | 未發現混合 technical mechanism 與 BC semantics 的既有 component。 | 若未來 component 同時執行 transport 並解釋 BC meaning，拆為 shared mechanism 與 BC-local adapter。 |
| REMOVE | 無 retired runtime code；但舊 Supporting BC 主文件與 authorization boundary canvas 會錯誤地維持 superseded auth/API 方向為 active architecture truth。 | 退役 `docs/architecture/bounded-contexts/github-integration.md` 與 `docs/architecture/diagrams/github-integration-http-client-boundary/`；git history 保留 supersession traceability。 |

## Target Boundary

`GithubIntegration` 是 shared GitHub-specific integration module，不是 BC、shared domain layer 或 centralized semantic facade。它對所有 BC 無知，且不定義 domain-facing abstraction 或 shared BC failure contract。它只負責 raw transport、GitHub error technical classification、authentication、共通 request headers／API version mechanism、pagination、rate-limit、retry 與 shared configuration；各 BC adapter 保留 endpoint-specific media type、選擇欄位、translation、將 classification 映射為 BC failure contract 與解釋 GitHub state 的責任。即使多個 BC 使用相同 GitHub endpoint，這些 BC-local semantics 也不共享。

## Documentation Delivery Contract

在 planning review 後，僅可修改下列長期真相與保留的 Bounded Context Map：

- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/architecture/bounded-contexts/pr-reader.md`
- `docs/github-api/README.md` 的 catalog introduction 與「共通規則」中 shared-module boundary wording（其餘 catalog capability content 維持 ReadOnly）
- `docs/architecture/diagrams/bounded-context-map/scene.js` 與其 generated `index.html`

同一受限 delivery 必須退役下列 superseded active assets，並移除所有 active navigation：

- `docs/architecture/bounded-contexts/github-integration.md`
- `docs/architecture/diagrams/github-integration-http-client-boundary/`

delivery allowlist 亦包含下列既有 planning artifacts，且只可刪除或標記其指向上述 retired asset 的失效 writeback；不得建立 replacement target 或修改任何 HTTP behavior、API、test、scope 或 gate：

- `analysis/swift-http-response-header-conveniences/requirements.md`
- `analysis/swift-http-response-header-conveniences/technical-spec.md`
- `plan/swift-http-response-header-conveniences/swift-http-response-header-conveniences.plan.md`
- `plan/swift-http-response-header-conveniences/swift-http-response-header-conveniences.step.md`
- `analysis/swift-http-response-json-decoding/requirements.md`
- `analysis/swift-http-response-json-decoding/technical-spec.md`
- `plan/swift-http-response-json-decoding/swift-http-response-json-decoding.plan.md`
- `plan/swift-http-response-json-decoding/swift-http-response-json-decoding.step.md`

圖表必須用繁體中文表達 ownership 與 compile-time dependency boundary，經 architecture-canvas validate/build 驗證；不表達 runtime sequence，不發布 artifact.cafe，也不得將 future module 寫成已實作 API。

## Risks 與 Deferred Decisions

- baseline 差異風險：parent `dev` baseline 實際把 GitHub Integration 定義為 Supporting BC，且以 lower shared authorization capability、主文件與 authorization canvas 表達；documentation delivery 必須 supersede 這些 active sources，以已鎖定的 `GithubIntegration` shared-module boundary 校正詞彙，且不改變 `RivetHTTPClient` 的 generic position。
- 歷史 traceability：PR #17 與舊 topic 不刪除、不就地改寫；退役的 active Supporting BC 文件與 canvas 由 git history 保留。其 pending gates 不構成本 topic 的前置條件、blocker 或 human gate。
- 跨 topic correction 風險：allowlist 僅校正已退役 asset 的 writeback 引用；不得藉此重開 HTTP header 或 JSON decoding 的功能、API、tests、scope、gate、schema ownership 或 implementation。
- 延後：module path、Swift API、credential lifecycle、REST／GraphQL client strategy、retry／rate-limit／pagination policy、error type、schema relocation、BC adapter implementation、dependency rewiring 與 compatibility strategy。
