# GitHub Client Scope Composition — Plan

Topic：`github-client-scope-composition`；Plan-Reviewer 已 approved，實作與獨立驗證已完成；待獨立 Reviewer 依人類限定例外再評估。
來源：[requirements](../../analysis/github-client-scope-composition/requirements.md)、[technical-spec](../../analysis/github-client-scope-composition/technical-spec.md)。
基線由派遣者提供：`dev`／`c4bb4b9f122c37d437f58335548543bcc96be5aa`，feature branch `feat/github-client-scope-composition`。
以下縮寫 G=`Sources/BoundedContexts/GitHubIntegration`、C=`Tests/GitHubIntegrationConsumer`、D=`docs/architecture/diagrams/github-oauth-dual-client-architecture`。

## Goal

公開雙 client contracts 與 caller-owned provider 的 ready scope，符合 14 項 AC。
只在指定 feature worktree 執行；禁止寫入 dev worktree。

## Non-Goal

不擴張產品、BC 或 OAuth 功能；不重新決定 locked API／ownership／lifecycle。

## In-Scope

REST protocol／default builders、GraphQL serving、scope／preparation errors、既有 technical errors visibility。
Internal factory seam、真實跨 client 離線驗證、consumer fixture 與精確 isolation allowlist。
長期文件、責任 canvas、canonical lifecycle v12 及必要驗證交付物。
獨立 planning review → bounded implementation → Tester → independent Reviewer。
完成審查後依已明示授權 topic commit、push、Draft PR，最後 human review。

## Out-Of-Scope

實際 BC adapter、endpoint、DTO、domain mapping、Port、產品 Facade、App／UI、登入。
Keychain OAuth、logout、多帳號、新 HTTP methods、retry、pagination、rate limit、cache。
DI container、singleton、UoW、close／dispose、OAuth／Apollo／generic HTTP 重構。
Public transport injection、provider 自動重建或重新 prepare、resource API probe。
修改歷史 v11、其他 topic、工具 config／hooks、root manifest／pins 或 regression test 實作。

## ReadOnly

除 Written／Modify 精確列出者外，全部 tracked/source 唯讀。
特別包括 provider、ports、fetcher、所有 BC、Presentation、generic HTTP 與歷史文件。
Root `Package.swift`、`Package.resolved`、工具設定、hooks 與現有 regression tests 唯讀。
允許 untracked build／test caches，但不因此取得 tracked edits 權限。
Graphify 固定 0.9.73，全部 CLI `GRAPHIFY_NO_AUTO_REFRESH=1`，缺 graph 用 rg／source。
不 build／extract／refresh／stamp／install／hooks／provider；不改工具基線。
PRLens 固定 0.11.0，只讀實作後真實 bounded diff 與 base/head，既有 config only。
外部 topic tmp local validate／render，runtime failure 用 direct diff；禁止 uploads／publish。

## Written

- `analysis/github-client-scope-composition/requirements.md`
- `analysis/github-client-scope-composition/technical-spec.md`
- `plan/github-client-scope-composition/github-client-scope-composition.plan.md`
- `plan/github-client-scope-composition/github-client-scope-composition.step.md`
- G/`GraphQL/GitHubGraphQLServing.swift`
- G/`Composition/GitHubClientScope.swift`
- G/`Composition/GitHubClientPreparationError.swift`
- `Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift`
- C/`Tests/GitHubIntegrationConsumerTests/ClientContractTests.swift`
- D/`token-lifecycle-v12.json`、`token-lifecycle-v12.html`
- D/`token-lifecycle-v12.delivery.json`、`token-lifecycle-v12.visual-check.json`、`token-lifecycle-v12.visual-check.html`
- D/`token-lifecycle-v12.visual-check.1440x900.light.png`、`token-lifecycle-v12.visual-check.1440x900.dark.png`
- D/`token-lifecycle-v12.visual-check.2048x1320.light.png`、`token-lifecycle-v12.visual-check.2048x1320.dark.png`
- 外部 topic tmp 的 untracked PRLens graph.json、render manifest、SVG 與必要 artifacts。

## Deleted

`[]`。

## Modify

- G/`REST/GitHubRestClient.swift`、G/`REST/GitHubHTTPClientError.swift`
- G/`GraphQL/GitHubGraphQLClient.swift`、G/`GraphQL/GitHubGraphQLClientError.swift`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`
- `Tests/GitHubIntegrationTests/GraphQL/GraphQLIsolationTests.swift`
- C/`Package.swift`：僅必要 Apollo／ApolloAPI／RivetHTTPClient direct deps，版本不變。
- C/`Package.resolved`：僅必要 originHash，全部 pins 不變。
- `README.md`、`docs/design-principles.md`、`docs/architecture/README.md`
- `docs/architecture/github-oauth-dual-client.md`
- D/`README.md`、`scene.js`、`index.html`、`canvas-visual-review.md`
- D/`canvas-overview-1440x900.png`、`canvas-top-1440x900.png`、`canvas-bottom-1440x900.png`

Isolation tests 僅精確 allowlist，不放寬整個 target。

## TestCase

<a id="ac-verification-mapping"></a>

### AC01–AC14 驗收映射

以下為規劃時的 canonical 驗收映射；表中 pending 保留規劃歷史，實際逐條結果見 [T01 AC evidence matrix](github-client-scope-composition.step.md#ac-evidence-matrix)，預定檔案沿用 Written／Modify allowlist。
S=`Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift`；F=`Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/ClientContractTests.swift`。
S 的 command 為 `swift test --filter GitHubClientScopeTests`；F 的 command 為 `scripts/check-github-integration-consumer.sh`。

| AC | 驗證情境 | 預定檔／command／evidence |
| --- | --- | --- |
| AC01 | 一般 import 可見 REST 八 methods／default builders 與 GraphQL Query／Mutation contracts，無 @testable | F／consumer script；pending |
| AC02 | Consumer 注入 REST／GraphQL offline fakes，不連網或使用真 credential | F／consumer script；pending |
| AC03 | Restore／refresh／persist／Bearer 任一步失敗不得交付部分 scope／client | S／scope command；pending |
| AC04 | 有效 restore 與 expired credential 路徑：refresh → persist → snapshot → 本地 Bearer ready | S／scope command；pending |
| AC05 | 缺 credential、auth required、restore／refresh／persist、非法 Bearer、取消均有限且安全可觀察；failure envelope 無 credential／underlying／body | S + F／scope command + consumer script；pending |
| AC06 | 真實 REST／GraphQL 配受控 transport，同 provider 並行 stale 401 僅 single-flight，late 401 使用已前進 version | S／scope command；pending |
| AC07 | Scope 多 request 共用原 provider，不在 execution 重建 provider | S／scope command；pending |
| AC08 | Prepare 後 provider 更新，各 client 下一 execution 使用 fresh snapshot／Bearer | S／scope command；pending |
| AC09 | Prepare 只走 credential lifecycle；受控 resource transports 呼叫數維持零 | S／scope command；pending |
| AC10 | Prepare await 中 caller 取消，已接受 rotation 仍 persist、shared refresh 不取消，最後觀察取消不返回 scope | S／scope command；pending |
| AC11 | 原 provider terminal／rotation-indeterminate 後重複 prepare 保持失敗，不自動重建／reprepare 繞過；caller 保留原 instance | S／scope command；pending |
| AC12 | REST 四 methods 與 GraphQL Query／Mutation，401-only 最多一次 retry、partial／errors-only／raw response、取消／transport 保持 | F + S + 既有 readonly regression tests／consumer script + swift test；pending |
| AC13 | Precise isolation allowlists 與 dependency checks：BC Core／UseCase／Port 無 GitHub／OAuth／Apollo 依賴 | 已列 StaticIsolationTests.swift、GraphQLIsolationTests.swift／swift test；pending |
| AC14 | Ready 只代表本地 readiness，不保證未來 request、遠端 auth 或 repository permission；多 request lifetime 非 UoW | README.md、docs/design-principles.md、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md 與 v12／canvas；Reviewer 文字與圖 evidence，pending |

normal import 與 offline fake consumer 不用 `@testable`。
新增 scope readiness、sanitized errors、取消、failure ownership、非法 Bearer 與不探測 resource tests。
真實 REST／GraphQL 配受控 transport：共用 provider、跨 client single-flight、version 與 late 401。
每次 execution fresh snapshot、不重建 provider、不繞過 terminal／rotation-indeterminate。
保留四 REST methods、Query／Mutation、401-only 最多一次 recovery 與合法 responses／errors。
執行 `scripts/check-github-integration-consumer.sh`、`swift test`、既有 regression。
執行 `scripts/check-swift-format.sh`、`swiftlint lint --strict`、`scripts/check-swift-coverage.sh`，coverage ≥90%。
Archify v12：c9 checks 零 error／warning、sha／bytes delivery、四組 desktop visual checks。
人工視檢最小／最大 desktop 的 light／dark；canvas 依 architecture-canvas 驗證／build／visual。
作者繁體中文、Viewer English fallback；不 preview／publish，保留 v11 歷史。
Staged diff 依 commit convention 檢查語意邊界並提出 message，依最新明示授權執行，不重問許可。
最後更新：2026-10-14，Plan-Creator；執行狀態見同 topic step ledger。


<a id="topic-coverage-exception"></a>

### 本 topic 驗收限定例外（2026-10-14）

人類明示：「接受本 topic 限定例外，繼續交付（建議）」。本次僅接受 root coverage 未達 90% 的 topic-specific exception，不修改 API、ownership、source scope 或檔案 allowlist。
`scripts/check-swift-coverage.sh` 實際 exit 1、root line coverage 57.41% <90%，此 failure evidence 保留，不能記為 coverage pass。
主要 coverage 缺口在未修改的 readonly Presentation；Presentation 與 coverage script 為 base-equal，但未量測 exact base checkout coverage，不推論 base 的總百分比。
採納理由：獨立 Reviewer 先前 R01 human-check 的唯一契約缺口為 root coverage，未發現實作缺陷；本 topic scope coverage 100%、REST 100%、GraphQL 98.85%，且 root 264 tests／31 suites、consumer 12／3、HTTP 85／12 與 97.81%、format／strict lint 已通過。
全域 90% threshold、coverage script、exclusions、Presentation 與其他 readonly 邊界維持原狀；本例外不延伸其他 topic，也不允許為提高比例修改 readonly code 或排除 source。
T01 執行可按此限定例外記 completed；R01 原 human-check 的 coverage 決策已由人類解除，但仍須獨立 Reviewer reassessment，不由 Plan-Creator 自行 approved。
D01 仍待 R01 approved；最新直接 topic commit／push／Draft PR 授權維持，最後仍由人類 review Draft PR。
