# PR Reader GitHub 一般討論留言端點需求

## 目的

Reader 呼叫端後續需要讀取單一 PR 的一般討論留言。這次交付該 REST 端點的 URL 建構能力。給定同一筆 `ReaderPullRequestID`，讓套件內的 Reader Infra 針對不同頁碼建立 GitHub.com 的 GET 目的地。

使用者核准 endpoint-only processed-plan，原 mission 草案查證基線為 `47e4b45983df38ee9a5e2784cf7aceb25a75b2f9`。此次執行基線為 `dev` 的 `d8e2ffed24c64da728cfb394da8d5a521b03642d`，納入 Changed Files #89。 [原查證基線](https://github.com/a129924/rivet/commit/47e4b45983df38ee9a5e2784cf7aceb25a75b2f9) · [執行基線](https://github.com/a129924/rivet/commit/d8e2ffed24c64da728cfb394da8d5a521b03642d)

## 範圍

- PR Reader Infra 擁有 internal GET 端點、PR 識別與頁碼驗證、URL 建構，以及既有測試 target 中的離線單元測試。
- 端點使用 `/repos/{owner}/{repo}/issues/{n}/comments`，其中 `n` 為 PR 編號，`page` 預設 `1`，`per_page` 固定 `100`。 [GitHub 留言端點](https://docs.github.com/en/rest/issues/comments#list-issue-comments)
- 後續 Adapter 負責 HTTP 執行、標頭、Link 分頁、留言轉換與 Reader 失敗映射。已確認的按需 repository ID 查核保留給後續 Adapter。完整快照、UI、寫入與持久化均在本次範圍外。

## 驗收

同一實例能建立預設首頁、第 2 頁及其他正數頁碼的完整 GET URL。無效 owner、repository、PR 編號或頁碼會拋錯。詳情與 Changed Files 端點通過既有回歸。精確案例及本機工具交接見[執行計畫](../../plan/pr-reader-github-conversation-comments-endpoint/pr-reader-github-conversation-comments-endpoint.plan.md)。

使用者授權獨立 feature worktree。通過驗證與獨立審查、無重大問題且 staged diff 符合單一 topic 時，依 `git-commit-convention` 核對 staged diff 與 commit message，提交一個 commit、推送 feature branch、開啟以 `dev` 為目標的 Draft PR 並讀回，停在 Human Review。
