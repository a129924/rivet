# PR Reader 行內審閱留言端點需求

Topic 為 `pr-reader-github-inline-review-comments-endpoint`。Human 已核准 Endpoint-only `processed-plan`，授權在獨立 feature worktree 實作和依條件交付。規劃基線 `c9c9f17a0d7732574d25a652ce088c65dcefea06` 包含既有 Reviews 端點與來源。 [PR #96](https://github.com/a129924/rivet/pull/96) · [PR #98](https://github.com/a129924/rivet/pull/98)

## 目標與範圍

PR Reader Infra 的呼叫端持有一筆 `ReaderPullRequestID`，可指定正整數頁碼並同步取得該 PR 的 GitHub.com 行內審閱留言 GET URL。預設第 1 頁，每頁固定 100 筆。此里程碑交付端點、識別與頁碼驗證、離線驗收和 BC 契約回寫。 [GitHub REST 端點規格](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request)

後續 Adapter 里程碑處理 HTTP 執行、REST client 與標頭接線、`Link` 分頁及續頁歸屬查核、DTO 與 `PRReaderFailure` 映射和完整留言清單。GraphQL 備援、快照組裝、UI、GitHub 寫入及資料遷移另行處理。

## 驗收

- **IC01** 同一 PR 可建構 `.get` 的首頁及指定頁碼 URL，固定每頁 100 筆。
- **IC02** 無效 owner、repository、PR 編號或非正數頁碼會拋出驗證錯誤。
- **IC03** Reader GitHub 回歸測試、Swift 格式、Lint、差異空白和九欄範圍核對通過。五項本機審閱另記錄實際證據及限制。

[技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-inline-review-comments-endpoint/pr-reader-github-inline-review-comments-endpoint.plan.md)
