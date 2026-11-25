# 指定 repository 的 open PR 清單技術規格

Topic `github-repository-open-pull-requests-adapter`。需求責任由既有套件內 Adapter target 承接。 [需求](requirements.md)

## 套件內介面與請求

在 `RivetRepositoryPullRequestsGitHub` 提供 `package`、`Sendable` 的 `GitHubRepositoryOpenPullRequestsQuery`，以 `init(rest: any GitHubRestClient)` 注入 client。入口為 `fetch(owner: String, repository: String) async -> Result<[GitHubRepositoryPullRequestSummary], GitHubRepositoryOpenPullRequestsFailure>`。摘要的套件內唯讀欄位為 `number: Int` 與 `title: String`。摘要與 `Error` 失敗型別均為 `package`、`Sendable`、`Equatable`。

由既有 `GitHubRepositoryOpenPullRequestsEndpoint` 驗證識別、建立第 1 頁和產生每個後續請求的 URL。由 `GitHubHeadersFactory.standard.make(requirements: [.standardREST])` 準備標頭，呼叫注入 client 的 `get(url:headers:body:)`，body 為 `nil`。每頁只接受 HTTP `200`。沿用現有 client 的認證、redirect 阻擋與 `401` 復原。

由 `HTTPResponse` 解碼每頁的 PR 陣列，驗證編號為正整數、標題為字串、狀態為 `open`。按來源順序累加摘要，保留標題原文、Draft、其他作者和重複項目。以 `Link` 決定是否再查。尾頁驗證完成後一次回傳全部結果，零筆回傳成功空陣列。各次呼叫的累加清單與 repository ID 證據皆為查詢區域狀態。 [GitHub List pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)

## 已確認的分頁規則

1. 讀取 `HTTPResponse.headers.link`。缺少標頭，或標頭語法有效且沒有 `next`，即為尾頁。解析時區分 `<…>`、引號與分隔符，以 ASCII 不分大小寫在 `rel` 單值或關係清單識別 `next`。空白標頭、破損語法、同一條目或跨條目重複的 `next`（含大小寫變體），以及帶 `anchor` 的 `next` 皆為分頁失敗。 [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api) · [RFC 8288](https://www.rfc-editor.org/rfc/rfc8288.html)
2. `next` 須為通過 `GitHubRESTDestination.isAllowed` 的絕對 URL。路徑原樣分段須為 `/repos/{owner}/{repo}/pulls` 或已證明的 `/repositories/{id}/pulls`。owner 與 repository 以 ASCII 不分大小寫比對。拒絕額外或百分比編碼的路徑分段。查詢只接受唯一 `per_page=100`、唯一 `page` 與選填的唯一 `state=open`。頁碼須為可表達的正整數並恰等於當前頁加一。加法溢位、重複、往回、跳頁或額外查詢參數皆為分頁失敗。
3. 身分證據來自原 Endpoint 取得且已驗證的本次頁面。當 `base.repo.full_name` 與輸入同名，且 `base.repo.id` 為正整數，兩值共同證明別名。記錄第一個已證明的 ID 並檢查後續證據一致性。缺少部分或全部證據的頁面仍可產生摘要。證據型別錯誤、已提供的名稱與輸入不符、已提供的 ID 非正整數或 ID 證據互相矛盾時回 `.invalidResponse`。數字別名需與已證明 ID 相符，缺少證據或 ID 不符時回 `.invalidPagination`。此流程只讀取清單 Endpoint；數字別名採離線 fixture 驗收。官方分頁文件的數字路徑範例使用 issues。
4. 通過驗證的 `next` 只提供頁碼。實際請求仍由同一 Endpoint 產生具原 repository、`state=open`、`per_page=100` 的 GET。

## 失敗契約

| Case | 條件 |
|---|---|
| `.invalidRepository` | 初始 owner 或 repository 識別遭 Endpoint 拒絕。 |
| `.requestFailed` | 標頭組裝失敗、client 請求失敗或非 `200` HTTP 回應。 |
| `.invalidResponse` | JSON 解碼或資料驗證失敗。 |
| `.invalidPagination` | 無法驗證 Link 或安全延續。 |
| `.cancelled` | 觀察到 Task 取消，或 REST client 拋出 `CancellationError`。 |

在每次請求前、await 返回後及交付前觀察 Task 取消。只回傳失敗分類，各類失敗皆終止查詢並捨棄累加結果。

驗收使用既有測試 target 透過一般 `import` 呼叫正式入口，由 actor 替身記錄 `executeGet`。 [驗收案例與本機工具交接](../../plan/github-repository-open-pull-requests-adapter/github-repository-open-pull-requests-adapter.plan.md)
