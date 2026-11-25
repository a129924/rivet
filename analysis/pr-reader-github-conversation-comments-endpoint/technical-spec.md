# PR Reader GitHub 一般討論留言端點技術規格

## 責任與介面

端點歸 PR Reader Infra，使用既有 `RivetPRReaderGitHub` 及 `RivetPRReaderGitHubTests`。沿用 `ReaderPullRequestID`、`HTTPMethod`、`HTTPURL` 與 GitHubIntegration 的 `GitHubRESTDestination`。

- Internal `GitHubConversationCommentsEndpoint.init(id: ReaderPullRequestID)` 固定持有 PR 識別，`method` 為 `.get`。
- 同步 `makeURL(page: Int = 1) throws -> HTTPURL` 先驗證 `page > 0`。頁碼為零或負數時，拋端點驗證錯誤。
- 將 `GitHubPullRequestDetailEndpoint` 已有的識別 guard 提取為 internal `static validateIdentity(_:) throws`，由詳情及留言端點共用。保留正數 PR 編號、既有 ASCII owner／repository 規則與錯誤。Owner／repository 需為非空且只包含 ASCII 字母、數字、連字號、底線、句點，並拒絕 `.` 與 `..`。詳情端點繼續產生原 URL，Changed Files 照原呼叫路徑使用它。
- 驗證成功後，將 `/repos/{owner}/{repo}/issues/{n}/comments` 與依序排列的 `page={page}`、`per_page=100` 傳給 `GitHubRESTDestination.makeURL(path:queryItems:)`。頁碼以十進位字串表示，目的地固定使用 `https://api.github.com`。 [GitHub 留言端點](https://docs.github.com/en/rest/issues/comments#list-issue-comments)

```text
GitHubConversationCommentsEndpoint(id:).makeURL(page:)
├─ 驗證頁碼 > 0
├─ GitHubPullRequestDetailEndpoint.validateIdentity(_:)
└─ GitHubRESTDestination.makeURL(path:queryItems:)
```

## 交付界線

套件內呼叫端取得 URL 或驗證錯誤。HTTP client、標頭、Link、DTO、repository metadata 查核與 Reader failure 映射均由後續 Adapter 規劃承接。BC 文件僅記錄 Reader Infra 的端點歸屬與 URL 建構能力。

[需求](requirements.md) · [執行計畫](../../plan/pr-reader-github-conversation-comments-endpoint/pr-reader-github-conversation-comments-endpoint.plan.md)
