# 讀取單一 PR 的 Files Viewed 狀態｜技術規格

Topic 為 `pr-reader-github-files-viewed-source`。執行基線為 `41fdb0e30e2ecc4edc68e4ac944ace32ffe2592d`。 [需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-files-viewed-source/pr-reader-github-files-viewed-source.plan.md)

## 套件契約

在 `RivetPRReaderGitHub` 新增 `package`、`Sendable` 的 `GitHubPullRequestFilesViewedSource`，以 `init(client: any GitHubGraphQLServing)` 接收既有 client。入口 `fetchFilesViewed(for: ReaderPullRequestID) async -> Outcome<[ReaderFileViewed], PRReaderFailure>` 回傳來源檔案清單。

`ReaderFileViewed` 為套件內型別，提供 `path: String`、`change: FileChange`、`additions: Int`、`deletions: Int` 及 `viewedState: ReaderFileViewedState`。`FileChange` 沿用 Reader Core。Apollo 型別只在 Infra 使用，結果獨立於快照。

| GraphQL 欄位值 | 套件內對應值 |
| --- | --- |
| `ADDED`、`DELETED`、`MODIFIED` | `.added`、`.removed`、`.modified` |
| `RENAMED`、`COPIED`、`CHANGED` | `.renamed`、`.copied`、`.typeChanged` |
| `UNVIEWED`、`VIEWED`、`DISMISSED` | `.unviewed`、`.viewed`、`.dismissed` |

路徑交付原始字元，僅拒絕空字串。依原始 UTF-8 位元組判重，保留空白與 UTF-8 不同但 Unicode 正規等價的路徑。已解碼的增刪數須為非負。 [GitHub 變更檔案](https://docs.github.com/en/graphql/reference/pulls#pullrequestchangedfile) · [PatchStatus](https://docs.github.com/en/graphql/reference/pulls#patchstatus) · [FileViewedState](https://docs.github.com/en/graphql/reference/pulls#fileviewedstate)

## 查詢與分頁

- 新增 `PullRequestFilesViewed` query，使用既有 GraphQL client、GitHub.com GraphQL POST 與 Bearer 認證。循 Checks 入口驗證 PR 識別及正數 GraphQL `Int` 範圍，無效輸入不發出請求。
- 每頁使用同一 `owner`、`name`、`number`。選取外層 repo 的 `id`、`nameWithOwner`，PR 的 `id`、`number`、`repository.id`、`headRefOid`，以及 `files(first: 100, after: $after)` 的 `totalCount`、`pageInfo.hasNextPage`、`pageInfo.endCursor` 和逐檔 `nodes`。檔案節點只查 `path`、`changeType`、`additions`、`deletions` 與 `viewerViewedState`。
- 每頁核對 repo 全名、外層與 PR 內的 repo ID、PR 編號，並以首頁 repo ID、PR node ID、head OID 和總數比對續頁。首頁省略 `after`，續頁按 GraphQL 回應的有效非空白游標前進，游標判重限本次讀取。依頁次及頁內原序累積結果。
- 有續頁時須有資料、尚未達總數，且下一游標未用過。空續頁失敗，末頁筆數必須等於總數。合法零筆為首頁同時是末頁、`totalCount == 0` 且 `nodes == []`。本次完整性以核對通過的分頁序列為準，各頁可反映不同時間的 viewer 狀態。 [GitHub GraphQL 分頁](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)

## 失敗與取消

| Reader 失敗 | 契約 |
| --- | --- |
| `.notReadable` | 無效起始識別、明確認證失敗（`.authenticationRequired` 或 HTTP 401）、任一頁可確認的 repository／PR 缺席或定位存取拒絕。依 Checks 的定位錯誤證據處理無 GraphQL 錯誤的定位缺席，以及只含可確認定位拒絕的 GraphQL 錯誤。 |
| `.unavailable` | 取消、`files: null`、一般續頁失敗、無法確認歸屬／游標／筆數、檔案欄位層級拒絕、混合 GraphQL 錯誤或含錯誤的部分資料、限流、裸 HTTP 403、解碼或傳輸失敗。 |
| `.contentNotRepresentable` | 已解碼的 `nodes: null` 或 `null` 元素、未知檔案 enum、空路徑、負增刪數或重複路徑。 |

在首請求前、每次請求回來後與成功交付前觀察取消，取消優先於晚到的回應及認證錯誤。任一失敗即捨棄已累積的資料。 [PR Reader 失敗契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)

## Apollo 產碼

使用 repo 固定 SDL 與 Apollo 2.1.2。將 query 列入既有 `operationSearchPaths`，SwiftPM target 的 `exclude` 同步追加其 operation 文件。用合併後的 operation 清單清潔離線重生，保留基線的 Checks、兩個 Review Threads operations 及 Review Merge State query。驗收後只將長期契約及重生命令回寫 PR Reader 文件。 [既有重生流程](../../docs/architecture/bounded-contexts/pr-reader.md#graphql-schema-再生成)
