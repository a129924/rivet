# 單一 PR 的變更檔案讀取技術規格

- `RivetPRReaderGitHub` 新增套件內 `GitHubPullRequestChangedFilesSource.init(client:)` 與 `fetchChangedFiles(for:) async -> Outcome<[ReaderFile], PRReaderFailure>`，接收 `ReaderPullRequestID`。#89 建立各頁 canonical URL。所有請求沿用既有 REST client、`.standardREST`、GET 和空 body，只接受 200。
- 讀取可解析的 `Link`，`next`、`last` 各至多一個。該兩種 link 須符合 `GitHubRESTDestination.isAllowed`，路徑符合原 PR 的名稱或數字 ID 形式，查詢限唯一的 `page` 與 `per_page=100`。頁碼須為正整數，`next.page` 恰為下一頁。有 `last` 時，缺 `next` 須滿足 `last.page == currentPage`，有 `next` 須滿足 `last.page >= next.page`。違反時回 `.unavailable`。
- 首次遇到有效的數字 repository ID `next` 時，用 #84 GET 原 PR 詳情一次，核對正整數 `base.repo.id`、`base.repo.full_name` 與 `number`。名稱使用 ASCII 大小寫不敏感比較。已驗證 ID 只存在於單次呼叫，後續數字 ID 的 `next` 和 `last` 均須相符。只有數字 ID `last` 時檢查頁碼，不觸發詳情 GET。任何續頁都由 #89 重建原 PR 網址，維持原目的地。
- 有 `next` 的頁須含 100 檔，續頁至少一檔，各頁至多 100 檔且最多 30 個檔案頁。合法陣列累積達 3,000 檔即失敗，包含同頁有無法投影的欄位。合法無 `next` 時交付完整清單。
- 原樣 `filename` 同時作為 path 與 `ReaderFileReference`，以 Swift `String` 相等性防止重複。空 `filename` 或識別重複回 `.contentNotRepresentable`。增刪數必須為可表示的非負 `Int`。明確映射 added、removed、modified、renamed、copied。對 changed、unchanged 及沒有可證保真映射的值回失敗。保留字串型別的 `previous_filename` 和 `patch`，缺席或 null 時保留 nil。
- 每頁依已觀察到的取消、HTTP、陣列與上限、分頁、逐檔投影依序判定。沿用 `GitHubResponseClassifier`。任一請求的認證或權限拒絕、404、原因未明的 403，以及無效起始識別與首個檔案頁的 `.invalidRequest` 回 `.notReadable`。續頁或詳情查核的 `.invalidRequest`、取消、限流、傳輸、其他非 200、分頁與詳情無法核對、上限回 `.unavailable`。200 檔案回應非合法陣列或必要資料、型別、識別和狀態無法保真時回 `.contentNotRepresentable`。

```text
fetchChangedFiles(for:)
├─ #89 組出檔案頁 → REST client GET
├─ 檢查取消、HTTP、陣列數量及 Link
│  └─ 首次有效數字 ID next → #84 詳情 GET → 核對歸屬
└─ 投影與查重 → 續頁、完整清單或單一 Reader failure
```

[GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api) · [PR 詳情](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request) · [變更檔案與上限](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files)
