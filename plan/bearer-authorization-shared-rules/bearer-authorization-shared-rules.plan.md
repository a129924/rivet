# 既有 Bearer Authorization 入口共用規則：受限執行計畫

## 共用十欄步驟契約與 allowlist

本計畫依 [requirements](../../analysis/bearer-authorization-shared-rules/requirements.md) 與 [technical-spec](../../analysis/bearer-authorization-shared-rules/technical-spec.md) 執行。每步的 `In-Scope`、`Out-Of-Scope`、`ReadOnly`、`Written`、`Deleted`、`Modify`、`Goal`、`Non-Goal`、`TestCase` 均由下列共用定義與步驟表共同確定：

- **In-Scope／Goal**：僅執行該步列明的產出與完成條件，實作行為以 technical-spec 為準。
- **Out-Of-Scope／Non-Goal**：requirements 的所有排除範圍；不得跨越該步 phase 或取代獨立審查。
- **ReadOnly**：該步 Written／Modify 以外的所有檔案；包含 Manifest、`HTTPHeaders`、`HTTPRequest`、`RequestAuthorization`、GraphQL wrapper／executor、provider、Token lifecycle、REST worktree、其他 topic 與既有圖表。
- **Written／Modify**：僅限下列 allowlist 及該步指定群組；沒有列明者為無。
- **Deleted**：所有步驟皆無。
- **TestCase**：依步驟表指定的 planning 檢查或 T1–T6；目前尚未執行產品驗證。

| 群組 | 精準 allowlist |
| --- | --- |
| A：planning | Written：`analysis/bearer-authorization-shared-rules/{requirements.md,technical-spec.md}`；`plan/bearer-authorization-shared-rules/{bearer-authorization-shared-rules.plan.md,bearer-authorization-shared-rules.step.md}`。 |
| B：production | Modify：`packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/{AuthorizationHeader.swift,BearerAuth.swift}`；`Sources/BoundedContexts/GitHubIntegration/GraphQL/{GitHubGraphQLHTTPInterceptor.swift,GitHubGraphQLClientError.swift}`。 |
| C：tests | Written：`Tests/GitHubIntegrationTests/GraphQL/GitHubGraphQLAuthorizationTests.swift`。Modify：`packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`；`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；`Tests/GitHubIntegrationTests/GraphQL/{ApolloGraphQLIntegrationTests.swift,GraphQLTestSupport.swift}`。 |
| D：docs | Modify：`docs/architecture/{README.md,github-oauth-dual-client.md}`。 |

B／C／D 維持既定 allowlist；新 Headers overload 與其 public 可見性驗證不需要新增檔案範圍。Plan-Reviewer 若明示 needs-rework，Plan-Creator 可依 required fix 修改 A 中受影響的既有 planning artifacts，不得自行擴大 B／C／D。

## 受限步驟

| ID／Owner | In-Scope／Goal | Written／Modify | TestCase／完成條件 |
| --- | --- | --- | --- |
| S1／Plan-Creator | 將已確認修訂的四份內容落檔。 | Written A。 | 四檔存在、同 slug，具備可供獨立審查的需求、public 契約、委派路徑、驗收與帳本。 |
| S2／Plan-Reviewer | 獨立審查本次修訂的 sufficiency、locked decisions、allowlist 與 workflow。 | 審查者無；交接後由 Plan-Creator 僅 Modify `.step.md` 記錄 verdict 原文及證據引用。 | 明示 `approved` 才可進 S3；其他 verdict 依流程回修或停止。 |
| S3／Implementer | 完成 helper、BearerAuth 兩 overload、GraphQL 委派、錯誤映射、必要測試與文件。 | Written／Modify B、C、D；Modify `.step.md` 記錄實作交接。 | 完成 T1–T6 所需測試實作；diff 不超出 allowlist，明示交付待 Tester 驗證。 |
| S4／Tester | 執行 T1–T6 與必要命令。 | 僅 Modify `.step.md` 驗證證據；允許 generated build artifacts。 | 記錄命令、位置、結果與失敗分類；失敗交 Implementer 回修。 |
| S5／Reviewer | 依實際 diff 與 Tester 證據獨立審查成果及 drift。 | 審查者無；交接後由 Plan-Creator 僅 Modify `.step.md` 記錄 verdict 原文及證據引用。 | 明示 verdict 並依流程路由；成果 approved 且無重大問題後才進已授權的交付。 |

S2／S5 的 verdict 記錄只由 Plan-Creator 執行，僅能修改 `.step.md`，不得重判 verdict、改寫結論或修改其他 artifacts。Observer 與審查者不修改帳本。S3 需要 S2 明示 approved；S4 需要 S3 明示完成交接；S5 需要 S4 實際驗證證據。任何 step status 均不等同 approval。

## 驗收與必要命令

T1–T6 均待按本次修訂確認與執行：

- **T1：共同 Token 文法。** 兩入口使用既有 `AuthorizationHeaderTests` 相同有效／無效案例，涵蓋允許字元、尾端 padding、空值、非法 padding、空白、CR/LF、NUL、Unicode 與非法符號；BearerAuth 初始化拋 `.invalidToken`，GraphQL 映射 `.invalidAuthorizationToken`，錯誤不含 Token。
- **T2：Headers overload。** 驗證 public 可見性、空 Headers、各種 Authorization 大小寫及同時存在的變體、其他 entries 保留、輸入不變與 idempotency；結果與既有純轉換一致。
- **T3：Request overload。** 所有初始化呼叫改用 `try`；驗證 Request overload 與 Headers overload 的結果語意一致，保留 URL／Method／Body、原始 Request 不變、nonthrowing existential applying，以及 diagnostics／reflection redaction。
- **T4：直接 Interceptor。** 驗證 GraphQL 經 BearerAuth Headers overload 的轉接結果、原 Request 不變、非法 Token 時 `next` 零次、下游 test sentinel 原樣傳遞。Foundation representation 按 HTTP 語意比較。
- **T5：完整 Apollo chain。** 初始非法 snapshot 回 `.invalidAuthorizationToken`，session Request 0、recovery／fetcher 0；合法首 Request 收到 401 後取得非法 replacement，回同一錯誤，session Request 只有 1、既有 recovery／fetcher 只有 1，沒有 retry send 或額外 recovery。
- **T6：回歸與隔離。** 成功、取消、HTTP status、一次 401 recovery／第二次 401、partial／errors-only、network／parser failure、並行 snapshot 隔離、精準 import 例外及 consumer contract。

必要命令均從 feature worktree 根目錄執行：

```sh
swift test --package-path packages/RivetHTTPClient
swift test
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
scripts/check-github-integration-consumer.sh
```

命令已由既有 manifests、工具鏈文件與 scripts 確認，尚未執行。使用本地替身，不依賴真實 GitHub 或有效 Credential。失敗回交適當角色，不由 Tester 直接修改產品。

## 交付授權與停止條件

人類已接受計畫並明確授權：只在 branch `feat/bearer-authorization-shared-rules` 的既有 feature worktree 實作；若無重大問題，完成 topic commit、push、Draft PR，再交 human review。不得修改 dev 工作目錄。

此授權不取代 S2／S4／S5。S5 approved 且無 unresolved 重大問題後，交 Implementer 依 staged diff 檢查語意邊界、使用 git-commit-convention 擬定 message，執行已獲授權的 bounded topic commit、push 與 Draft PR；人類的本次直接交付授權優先於先前等待額外 commit 確認的記錄。不得 merge、release 或將 Draft PR 標記為 human review 已完成。

Plan-Creator 本次僅建立 A 四檔，不實作、不測試、不執行 Git。四檔落檔後即交獨立 Plan-Reviewer；修訂前 readiness 不自動代表本次 planning approved。新的 scope、path、contract 衝突或重大 blocker 須停止並交還人類。
