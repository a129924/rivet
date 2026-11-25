# 指定 repository 的 open PR Endpoint 技術規格

## 套件介面

`RivetRepositoryPullRequestsGitHub` 是 regular target，路徑為 `Sources/RivetRepositoryPullRequestsGitHub`，直接依賴 `GitHubIntegration` 和 `RivetHTTPClient` product。新增 `RivetRepositoryPullRequestsGitHubTests`，直接依賴待測 target 與其兩個依賴。新 target 無 library product，既有正式 targets 不建立對新 target 的依賴。

`package struct GitHubRepositoryOpenPullRequestsEndpoint: Sendable` 提供下列套件內介面。

```swift
package init(owner: String, repository: String)
package let method: HTTPMethod = .get
package func makeURL(page: Int = 1) throws -> HTTPURL
```

## 目的地與驗證

- 實例固定 owner 與 repository。以 `GitHubRESTDestination.makeURL` 建立 `https://api.github.com/repos/{owner}/{repo}/pulls`，query 固定依序為 `state=open`、`per_page=100` 與 `page=N`。 [GitHub REST PR 清單](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)
- 組 URL 前分別驗證 owner 與 repository。保留大小寫，每個欄位只接受 ASCII 英數及 `-._`，拒絕空字串、`.` 與 `..`。採現有 PR 詳情 Endpoint 的安全 path component 規則。
- 頁碼為正整數，省略時用第 1 頁。無效輸入拋出 Endpoint 私有驗證錯誤。URL 組裝錯誤沿用共用 destination 的拋錯。
- Endpoint 的責任是組裝 method 與 URL。Headers、REST 執行、Link 的解析與清單資料轉換由後續 Adapter 處理。

## 文件與復原

GitHub API Catalog 的 Repository Pull Request List 條目新增型別與 URL 契約的套件能力記錄，保留產品瀏覽與 Adapter 的後續排程。回退 topic 變更即可移除型別與文件，沒有資料遷移。

- [需求](requirements.md)
- [執行計畫](../../plan/github-repository-open-pull-requests-endpoint/github-repository-open-pull-requests-endpoint.plan.md)
