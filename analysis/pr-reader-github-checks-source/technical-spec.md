# 讀取單一 PR 的 Checks 技術規格

## 套件入口與查詢

在 `RivetPRReaderGitHub` 新增 `package` 級 `GitHubPullRequestChecksSource.init(client:)`，注入 `any GitHubGraphQLServing`。`fetchChecks(for: ReaderPullRequestID) async -> Outcome<ReaderCheckRollup?, PRReaderFailure>` 交付既有 Reader 結果。沿用 `GitHubPullRequestDetailEndpoint.validateIdentity` 並限制 GraphQL PR 編號為 `1...Int32.max`。未取消時無效輸入回 `.notReadable`，零請求。

`PullRequestChecks` query 沿 `repository(owner:name:) → pullRequest(number:) → statusCheckRollup`。選取 repository 的 `id`、`nameWithOwner`、PR 的 `id`、`number`、`repository.id` 與 `headRefOid`，以及 rollup 的 `id` 和 `state`。`contexts(first: 100, after:)` 選取 `totalCount`、`pageInfo.hasNextPage`、`pageInfo.endCursor` 及 `nodes`。兩個 union fragment 分別選下列欄位，並保留 `__typename`。使用既有 `GitHubGraphQLServing` 路徑與 Apollo JSON POST／Bearer transport。 [GitHub PR](https://docs.github.com/en/graphql/reference/pulls#pullrequest) · [GitHub rollup](https://docs.github.com/en/graphql/reference/commits#statuscheckrollup)

| 來源 | 必要欄位與映射 |
| --- | --- |
| Rollup | `state` 對應 `ReaderCheckState`。 |
| `CheckRun` | `id` 用於完整性檢查。`name`、`status`、`conclusion` 映射為 `.run(name:status:conclusion:)`。合法 `conclusion: null` 保留缺值。 |
| `StatusContext` | `id` 用於完整性檢查。`context`、`state` 映射為 `.commitStatus(context:state:)`。 |

已知 enum 逐一對應既有 Reader case。名稱與 context 依來源保留。Node ID 留在 Infra。

## 分頁與交付

1. 首頁省略 `after`。每頁核對 repository 的 `nameWithOwner` 與 requested owner／repository 不區分大小寫相符、PR 編號相符，且 PR 的 repository ID 指向包覆它的 repository。
2. 首頁定位一致、無 GraphQL errors 且 rollup 為 `null` 時回 `.success(nil)`。rollup 存在時，以首頁的 repository ID、PR ID、head OID、rollup ID、整體 state 和 `totalCount` 作為續頁比對基準。任一可辨識變動或續頁 rollup 消失回 `.unavailable`。
3. 依頁次與頁內原序累積明細，任何重複 Node ID 回 `.unavailable`。不同 Node ID 即使名稱或 context 相同也保留。續頁出現空 `nodes` 清單回 `.unavailable`。每次 `hasNextPage` 為真時，當頁須有明細且有非空白、未使用的 `endCursor`。下一次請求使用該原始游標。無效游標時停止發出請求。
4. 核對終頁累積筆數等於首頁及各頁的 `totalCount`，交付 `ReaderCheckRollup`。首頁合法空明細為 `nodes: []`、`totalCount: 0` 且沒有續頁。末頁允許無 `endCursor`。完整性以此次可驗證序列為準。

## 失敗與取消

| 條件 | 結果 |
| --- | --- |
| 無效輸入、已解碼且無 errors 的 repository／PR 定位缺席、`.authenticationRequired`、明確 HTTP 401 | `.notReadable`。 |
| 結構化定位拒絕 | `.notReadable` 限所有 GraphQL errors 都是 `FORBIDDEN` 或 `NOT_FOUND`，且原始完整 path 為 `["repository"]` 或 `["repository","pullRequest"]`。採 `type` 或 `extensions.type`，同時存在時須一致。 |
| Checks 欄位拒絕、其餘 GraphQL errors（包括 partial data）、無根資料、裸 HTTP 403、限流、傳輸、Apollo 解碼失敗、身分或游標矛盾、總數不符、續頁空清單或重複 ID | `.unavailable`。 |
| 可解碼但無法保真映射的 null nodes 清單、null node、未知 union／enum 或空白必要識別值 | `.contentNotRepresentable`。 |
| 取消 | `.unavailable`。每次請求前、await 返回後、交付前檢查，取消優先於晚到成功或錯誤。 |

失敗均捨棄已累積資料。 [PR Reader Failure Contract](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract) · [GitHub 限流](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api)

## Apollo 離線產碼

沿用基線 SDL、Apollo CLI 與 runtime `2.1.2`、`ReaderGitHubGraphQL` namespace 及既有 embedded-in-target 設定。正式產碼前以基線 `Schema.graphqls`、`ReviewThreads.graphql`、既有 config 及固定離線程序，在乾淨暫存輸出中重生並比對基線。新增 query 後，僅把 `PullRequestChecks.graphql` 追加到既有 `operationSearchPaths`。將同一 SDL、新舊兩份 operation 檔及目前 config 放入乾淨暫存目錄，沿用基線 CLI、生成檔頭註解及單一 LF 正規化步驟一起重生。比對兩個既有 reviewThreads operation 仍存在，以及生成差異可重現且限 Checks 所需。`Package.swift` 僅新增原始 operation 檔的 exclude。 [Reader schema 與重生方式](../../docs/architecture/bounded-contexts/pr-reader.md) · [執行計畫](../../plan/pr-reader-github-checks-source/pr-reader-github-checks-source.plan.md)
