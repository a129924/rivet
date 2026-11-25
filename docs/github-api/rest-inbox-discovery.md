# REST Inbox Discovery

自查查詢官方校驗日期為 2026-11-18。

## Repository Pull Request List

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls` |
| 用途 | 取得指定 repository 的 PR；預設只回傳 open PR。 |
| 成功結果 | `200 OK` 與 PR list response；conditional request 時 GitHub 另列 `304 Not Modified`。 |
| 重要 query | `state`, `head`, `base`, `sort`, `direction`, `per_page`, `page` |
| 重要欄位 | number、title、body（nullable）、user、head（其中 `repo` 為 nullable）、base、state、draft（可能缺席）、`_links` |
| 分頁 | `per_page` 最大 100；依 Link header 取下一頁。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)、[GitHub REST OpenAPI `pull-request-simple` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`draft` 未列於 `required`；`head.repo` 為 nullable） |

此 endpoint 適合單一 repository 範圍瀏覽。套件內的 `RivetRepositoryPullRequestsGitHub` 提供 `GitHubRepositoryOpenPullRequestsQuery`，接受已配置的 `GitHubRestClient`、owner 與 repository。既有 `GitHubRepositoryOpenPullRequestsEndpoint` 驗證識別，並為每頁建立固定 `state=open` 與 `per_page=100` 的 GET。查詢使用 `.standardREST`，每頁只接受 HTTP `200`，沿著有效的 `Link` 讀到尾頁。

下一頁須延續同一 repository 與查詢條件，頁碼須恰為當前頁加一。數字 repository 路徑須符合本次頁面已證明的 `base.repo.id` 和 `base.repo.full_name`。通過驗證後由原 Endpoint 建立下一頁請求。成功結果依 GitHub 的原始順序回傳 PR 編號與標題，包含 Draft 和其他作者的 PR。零筆為成功空陣列。無效識別、請求失敗、內容無效、無法安全分頁或取消均回傳整次查詢的失敗分類。產品瀏覽仍屬後續唯讀能力。

## 跨 repository 自查候選

使用同一 OAuth REST client 呼叫 `GET /user` 取得登入名稱，再執行 `GET /search/issues`，查詢為 `q=is:pr is:open author:<login>`。每頁最多 100 筆，依同一查詢的 Link 讀到完整尾頁，搜尋上限為 1,000 筆。從 PR 的 `user.login` 與 `state` 驗證作者及開啟狀態，空集合為成功。若回應有 `incomplete_results` 或任一頁失敗，整次更新回傳 `.unavailable`。Private repository 仍須由 OAuth credential 擁有對應權限。 [GitHub 作者查詢](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests#search-by-author) · [REST Search](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)

## 跨 repository 直接審閱指派（E019）

| 項目 | 定義 |
| --- | --- |
| 狀態 | E019 歷史驗證範圍 |
| Operation | `GET /search/issues` |
| 必要 query | `q=is:pr is:open user-review-requested:@me` |
| 用途 | 尋找直接要求目前使用者 review 的 open PR。 |
| 成功結果 | `200 OK` 與 search response；conditional request 時 GitHub 另列 `304 Not Modified`。 |
| 重要輸出 | response 的 `total_count`、`incomplete_results` 與 items 中的 number、title、state、user（nullable）、repository_url、pull_request、updated_at |
| 分頁與上限 | `per_page` 最大 100，使用 `page` 取得後續頁，並依 Link header 的 next URL traversal。單一 Search query 最多提供 1,000 筆結果。Search API 另有 rate-limit 限制，實作時必須處理 `incomplete_results` 與分頁；超過上限時的切分 query 或不完整結果 UX 留給未來 implementation topic 決定。 |
| 認證／權限 | 此 catalog 固定使用代表目前使用者的 `@me`，因此必須以有效 token 呼叫；查詢 private resources 時 token 另須具有 repository access。多資源查詢只回傳 token 可存取的資源。 |
| 官方來源 | [Search issues and pull requests](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)、[REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)、[search access errors](https://docs.github.com/en/rest/search/search#access-errors-or-missing-search-results)、[GitHub REST OpenAPI `issue-search-result-item` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`user` 為 nullable） |

`review-requested:USERNAME` 用於指定使用者；`user-review-requested:@me` 是「直接要求我 review」的明確 qualifier。E019 驗證範圍為直接指派。

## Sources

- [List pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)
- [Search issues and pull requests](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)
- [Filtering and searching issues and pull requests](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests)
