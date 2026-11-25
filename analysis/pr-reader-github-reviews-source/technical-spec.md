# PR Reader 單一 PR 審閱紀錄讀取技術規格

## 入口與請求

在 `RivetPRReaderGitHub` 新增 `package struct GitHubPullRequestReviewsSource: Sendable`，提供 `package init(client: any GitHubRestClient)` 與 `package func fetchReviews(for: ReaderPullRequestID) async -> Outcome<[ReaderReview], PRReaderFailure>`。使用 #96 的 Reviews 端點建構首頁與續頁，從 `page=1` 起，固定 `per_page=100`。Reviews 與查核詳情皆使用既有 client 的 GET、`.standardREST` 及 `nil` body。 [GitHub Reviews API](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request)

## 分頁與歸屬

- 從 #94 擷取 Link 解析器至 `GitHubPullRequestPageLinks`，僅供 Reader GitHub target 的一般留言與審閱紀錄兩條固定路徑使用，沿用 #94 的 Link 語法與判定。一般留言改為呼叫擷取後的解析器。Changed Files 沿用自己的解析器。
- 審閱紀錄的 `next`／`last` 通過既有 GitHub REST 目的地檢查後，只接受 `api.github.com` HTTPS 的 `/repos/{owner}/{repo}/pulls/{n}/reviews` 或 `/repositories/{id}/pulls/{n}/reviews`。路徑須保留原 PR 編號。具名 owner 與 repo 以 ASCII 大小寫不敏感方式比對，數字 repo ID 須為正數。Query 僅接受唯一正數 `page` 與唯一 `per_page=100`。
- `next` 必須等於當前頁加一。`last` 有 `next` 時不得早於 `next`，無 `next` 時必須等於當前頁。拒絕畸形、歧義、錯誤目的地、跳頁、循環、溢位與矛盾頁碼。缺 Link header 或合法無 `next` 時完成。
- 首次收到有效的數字 `next`，以原 PR 詳情端點 GET 並要求 `200`，經 `GitHubPullRequestRepositoryIdentity` 核對 `number`、`base.repo.full_name` 與 `base.repo.id`。確認的 ID 限本次讀取重用，核對同頁及後續的數字 `next`／`last`。只有數字 `last` 且尚無已確認 ID 時，核對該 Link 的目的地形狀及當前分頁的頁碼關係。通過查核後用 #96 端點重建具名續頁。 [PR #94](https://github.com/a129924/rivet/pull/94) · [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api#using-link-headers)

## 投影與失敗

- `200` 陣列逐筆投影。正 `Int64` ID 轉十進位字串，原樣保留 `body`，包含空字串。缺席或 `null` 的 `user` 映為 `nil` 作者，存在時保留非空字串 `login`。依序將 `APPROVED`、`CHANGES_REQUESTED`、`COMMENTED`、`DISMISSED`、`PENDING` 映為 `.approved`、`.changesRequested`、`.commented`、`.dismissed`、`.pending`。忽略 `submitted_at`、`commit_id`。保留頁序與頁內順序，合法空清單回 `.success([])`。 [Rivet API Catalog](../../docs/github-api/rest-discussion-reviews.md#review-summary)
- HTTP `200` 無法解碼為陣列、必要欄位無法保真投影或狀態未知時，回 `.contentNotRepresentable`。無效起始識別、首頁 `.invalidRequest`，以及任何實際 Reviews 頁的 `.authenticationRequired`、HTTP `401`、非限流 `403`（含原因未明的 `403`）、`404`，回 `.notReadable`。
- 沿用 `GitHubResponseClassifier`。限流、傳輸、其餘 client 或 HTTP 失敗、續頁驗證失敗、詳情查核失敗與取消回 `.unavailable`。請求前、等待後及結果交付前檢查取消，取消優先於晚到的 response 或 client 失敗。任何失敗捨棄累積紀錄。 [Reader Failure Contract](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)

[需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-reviews-source/pr-reader-github-reviews-source.plan.md)
