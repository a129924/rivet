# PR Reader GitHub 變更檔案端點技術規格

## 基線與責任

原計畫基線為 `dev` 的 `1e8af39ac826d5512e670a2eb3a9b9c4a3f0afaf`。建立 feature worktree 前核對執行基線 `47e4b45983df38ee9a5e2784cf7aceb25a75b2f9`（#88）。兩個基線間的 #84 詳情端點、端點測試及 `GitHubRESTDestination` 無差異。端點歸 PR Reader Infra，使用現有 `RivetPRReaderGitHub` 和 `RivetPRReaderGitHubTests`。

## 鎖定的介面與建址流程

- `GitHubPullRequestChangedFilesEndpoint` 為 internal 實例，`init(id: ReaderPullRequestID)` 固定持有 PR 識別，`method` 為 `.get`。
- `makeURL(page: Int = 1) throws -> HTTPURL` 每次接收頁碼。先驗證 `page > 0`，非正值拋端點驗證錯誤，正值以十進位寫入 query。
- 用 `GitHubPullRequestDetailEndpoint(id: id).makeURL().value.path` 重用 #84 路徑及識別驗證。Owner/repository 依原 ASCII 路徑元件規則、PR 編號依原正整數規則。既有驗證錯誤透過 `throws` 傳出。
- 附加 `/files`，將 `page` 及 `per_page=100` 依序交給 `GitHubRESTDestination.makeURL`，取得 `https://api.github.com/repos/{owner}/{repo}/pulls/{number}/files?page={page}&per_page=100`。流程為同步 URL 建構。

```text
GitHubPullRequestChangedFilesEndpoint(id:) 固定持有 PR 識別
└─ makeURL(page: Int = 1) 每次接收頁碼
   ├─ 驗證 page > 0
   ├─ GitHubPullRequestDetailEndpoint(id: id).makeURL()
   │  └─ 驗證 PR 識別並取得原 PR 路徑
   └─ GitHubRESTDestination.makeURL()
      └─ 組裝 /files?page={page}&per_page=100
```

[需求](requirements.md) · [PR #84](https://github.com/a129924/rivet/pull/84) · [GitHub Changed Files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files)
