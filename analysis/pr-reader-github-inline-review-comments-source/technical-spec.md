# REST 行內審閱留言來源規格

`RivetPRReaderGitHub` 的 `package struct GitHubInlineReviewCommentsSource: Sendable` 以 `package init(client: any GitHubRestClient)` 注入 client。 `package func fetchInlineReviewComments(for: ReaderPullRequestID) async -> Outcome<[ReaderInlineReviewComment], PRReaderFailure>` 將 GitHub 請求與失敗隔離在 Reader Infra。結果為 `package` 值型別，符合 `Equatable` 及 `Sendable`，各欄位為 `package let`。REST 解碼型別私有。

| 欄位 | 契約 |
| --- | --- |
| 頁次 | `sourcePage: Int`，從 1 起。依來源頁次及頁內原序附加，保留重複項。 |
| 必要資料 | 正值 `Int64` 的 `id`、非空 `node_id` 與 `path`、原始 Markdown `body`。空正文有效。 |
| 數字關係 | `in_reply_to_id`、`pull_request_review_id` 為 `Int64?`。保留指向清單以外的回覆 ID。 |
| 文字定位 | `diff_hunk`、`side`、`start_side`、`commit_id`、`original_commit_id`、`subject_type` 為 `String?`。 |
| 數字定位 | `position`、`original_position`、`line`、`original_line`、`start_line`、`original_start_line` 為 `Int?`。 |

合法缺席或 `null` 映為 `nil`。保留部分範圍端點。合法空清單為 `.success([])`。 [GitHub 行內審閱留言端點](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request)

1. 既有 `GitHubInlineReviewCommentsEndpoint` 建構 GET，第 1 頁起、`per_page=100`。留言頁與詳情都用 `.standardREST` 與 `nil` body。
2. 映射當頁的 `200` 回應。共用 `GitHubPullRequestPageLinks` 核對 `next`／`last` 的目的地、路徑、查詢參數及頁碼。 `next` 須恰為下一頁。
3. 首次遇到有效的數字 repo `next` 或 `last`，用原 PR 詳情 GET 與 `GitHubPullRequestRepositoryIdentity` 依 `200`、PR 編號、`base.repo.full_name`、`base.repo.id` 查核。結果限當次讀取重用，數字 ID 矛盾即失敗。
4. 以原 PR 識別與驗證頁碼重建具名續頁 URL。合法且無 `next` 時交付完整清單。

無效起始識別、首頁 client `.invalidRequest`、留言請求認證失敗、`401`、`404`、`410`、`.forbidden` 或 `.unclassifiedForbidden` 映為 `.notReadable`。分類器辨識的限流、傳輸及其他請求失敗、分頁或詳情查核失敗、取消映為 `.unavailable`。留言 `200` 無法解碼為清單或無法保真映射時回 `.contentNotRepresentable`。請求前後與交付前確認取消，取消優先於晚到的回應或錯誤。任一失敗即捨棄累積資料。 [PR Reader 失敗契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)
