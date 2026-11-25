# PR Reader 單一 PR raw unified diff 技術規格

## 基線與責任

對話查證基線為 `d8e2ffed24c64da728cfb394da8d5a521b03642d`。執行基線為 `dev` 的 `612b97ed2ec1344b6bc39eb3b69ff7e245a83742`。兩者間合併的 PR #91 提取詳情端點原有的識別驗證供一般討論留言端點共用，詳情 `GET`、URL 和識別驗證契約仍適用。回寫 Reader BC 文件時保留 #91 新增的一般討論留言端點紀錄。 [PR #91](https://github.com/a129924/rivet/pull/91)

Reader Infra 宣告要取得 diff 表示格式並擁有 Reader failure 映射。`GitHubIntegration` 組合固定標頭，既有 REST client 負責認證、執行及既有的 `401` 復原。

## 固定標頭

新增 package 需求 `.pullRequestUnifiedDiffREST`。在 `HeadersProvider` 以標準 REST 標頭的值建立 diff 組合，只改 `Accept` 為 `application/vnd.github.diff`。沿用設定的 User-Agent 與 API 版本，內建值為 `Rivet` 與 `2026-03-10`。空需求選擇 `.standardREST`，相同需求重複出現視為一次，兩種以上不同需求回傳既有的 `conflictingRESTRequirements`。背景來源沿用 `.standardREST` 和 `application/vnd.github+json`。

## 入口、執行與結果

在既有 `RivetPRReaderGitHub` target 新增 package `GitHubPullRequestUnifiedDiffSource`，以 `init(client: any GitHubRestClient)` 注入 client，提供 `fetchUnifiedDiff(for id: ReaderPullRequestID) async -> Outcome<Data, PRReaderFailure>`。

先檢查取消，沿用 `GitHubPullRequestDetailEndpoint(id: id).makeURL()` 驗證識別並建立 URL，取得 diff 標頭後以 `client.get(url:headers:body:nil)` 委派。GET 返回後再檢查取消。只有 HTTP `200` 成功，直接交付 `response.body`，包含空內容及非 UTF-8 位元組。非 `200` 透過共用 `GitHubResponseClassifier` 分類，再映射為 Reader 結果。

| 情況 | Reader 結果 |
| --- | --- |
| 無效識別、client 的 `authenticationRequired` 或 `invalidRequest` | `.notReadable` |
| `401`、`404`、權限拒絕或原因未明的 `403` | `.notReadable` |
| `406`、`304`、限流、服務端、其他非 `200` 或其他執行失敗 | `.unavailable` |
| 取消 | `.unavailable`，優先於回應或同時發生的 client 失敗 |

Adapter 每次至多委派一次 GET，不增加重試或 fallback。既有 REST client 保有其 `401` 復原策略。

## 預期呼叫樹

```text
GitHubPullRequestUnifiedDiffSource.fetchUnifiedDiff(for:)
├─ 檢查取消 → GitHubPullRequestDetailEndpoint.makeURL()
├─ GitHubHeadersFactory.make(requirements: [.pullRequestUnifiedDiffREST])
├─ GitHubRestClient.get(..., body: nil)
│  └─ GitHubHTTPClient.executeGet → 現有 Bearer 與 REST transport
└─ 檢查取消，再處理回應
   ├─ 200 → 回傳 response.body
   └─ 其他 HTTP 狀態 → GitHubResponseClassifier → PRReaderFailure
```

[需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-raw-unified-diff/pr-reader-github-raw-unified-diff.plan.md)
