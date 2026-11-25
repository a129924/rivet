# PR Reader 一般討論留言讀取技術規格

## 入口與請求

在既有 `RivetPRReaderGitHub` 新增 `package struct GitHubConversationCommentsSource: Sendable`，提供 `package init(client: any GitHubRestClient)` 與 `package func fetchConversationComments(for: ReaderPullRequestID) async -> Outcome<[ReaderComment], PRReaderFailure>`。GitHub 一般留言端點也適用於 issue，呼叫端須事先確認 PR 身分。首頁由 #91 建構，使用 `page=1&per_page=100`。留言與查核請求均使用既有 REST client 的 `get`、`.standardREST` 及 `nil` body。 [GitHub 留言端點](https://docs.github.com/en/rest/issues/comments#list-issue-comments)

## 分頁與身分查核

- 以 URI 與引號邊界解析 `Link`，`next`、`last` 各至多一個。拒絕畸形 link 及有 `anchor` 的 `next` 或 `last`。兩種 relation 的 URL 都須通過既有 GitHub REST 目的地檢查。路徑只接受未百分比編碼的 `/repos/{owner}/{repository}/issues/{n}/comments` 或 `/repositories/{id}/issues/{n}/comments`。具名 owner／repository 以 ASCII 大小寫不敏感比對，PR 編號須吻合，數字 repository ID 須為正 `Int`。
- 查詢限唯一的正數 `page` 和唯一的 `per_page=100`，`next.page` 必須恰為當前頁加一。有 `last` 時，有 `next` 則 `last.page >= next.page`，無 `next` 則 `last.page == currentPage`。缺 `Link` 或合法無 `next` 時完成。錯誤、矛盾、跳頁、循環或溢位回 `.unavailable`。 [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api#using-link-headers)
- 首次遇到其餘條件均有效的數字 `next` 時，用 `GitHubPullRequestDetailEndpoint(id:).makeURL()` 向原 PR 送一次詳情 GET。只接受 `200` 且通過共用身分查核的回應。已確認 ID 限同一次 fetch 重用，同頁或後續的數字 `last` 與後續數字 `next` 都須吻合。只有數字 `last` 時檢查目的地形狀和頁碼，已有確認 ID 時一併比對。通過查核後，以 #91 重建原 PR 的具名續頁網址。 [GitHub PR 詳情](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)
- 從 #92 抽出同 target 的 internal `GitHubPullRequestRepositoryIdentity`，提供靜態純解碼介面 `verifiedRepositoryID(in: HTTPResponse, for: ReaderPullRequestID, matching: Int) -> Int?`。兩個 adapter 各自確認 `200` 後才呼叫。沿用 `JSONDecoder` 和既有 DTO，`number`、`base.repo.id` 為 `Int`，`base.repo.full_name` 為 `String`。要求 `number` 等於原 PR 編號，`full_name` 為 ASCII 且以不分大小寫方式等於原 `owner/repository`，`base.repo.id` 等於正數候選 ID。吻合回傳 ID，否則回 `nil`。Helper 的責任限於解碼與比對。
- Changed Files 來源保留自己的詳情 URL 建構、`get`、取消、失敗映射、分頁限制與檔案 DTO。只替換原身分解碼與核對部分，維持 `nil` 回 `.unavailable`。其詳情 `401`、非限流 `403` 與 `404` 沿用 `.notReadable`。

## 投影與失敗

- 將留言頁 `200` 陣列逐筆轉成 `ReaderComment`。正 `Int64` `id` 轉十進位字串，`body` 保留原始 Markdown。缺席或 `null` 的 `user` 轉 `nil` 作者。有 `user` 時須提供非空字串 `login`，原樣保留。必要資料缺失、錯型態或無法保真時回 `.contentNotRepresentable`。按頁次與頁內順序保留所有項目，合法空清單成功回 `[]`。
- 留言頁的非 `200` 由 `GitHubResponseClassifier` 分類。認證或權限拒絕、未分類 `403`、`404` 與留言端點的 `410 Gone` 回 `.notReadable`。無效起始識別、首頁 `.invalidRequest` 及留言請求的 `.authenticationRequired` 同樣回 `.notReadable`。續頁 `.invalidRequest`、限流、傳輸或服務失敗與其餘非 `200` 回 `.unavailable`。 [GitHub 留言端點狀態碼](https://docs.github.com/en/rest/issues/comments#list-issue-comments) · [GitHub REST 限流](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api#exceeding-the-rate-limit)
- 留言來源中的詳情 URL 建構、非 `200`、拋錯、解碼失敗、身分不符或取消均回 `.unavailable`，涵蓋詳情的 `401`、`403` 與 `404`。
- 請求前、等待結束及交付前檢查取消。已觀察到的取消回 `.unavailable`。任何失敗均捨棄累積留言。 [Reader failure 契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)

[需求](requirements.md) · [執行計畫與驗收](../../plan/pr-reader-github-conversation-comments-source/pr-reader-github-conversation-comments-source.plan.md)
