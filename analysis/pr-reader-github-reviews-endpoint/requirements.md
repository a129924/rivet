# PR Reader 審閱紀錄端點需求

Topic 為 `pr-reader-github-reviews-endpoint`。人類核准 Endpoint-only processed-plan，授權獨立 feature worktree 實作與受限交付。

## 目標

在既有 `RivetPRReaderGitHub` 提供 internal GET 端點。呼叫端提供一筆 `ReaderPullRequestID` 與頁碼，即可同步取得 GitHub.com 單一 PR 審閱紀錄的 URL。端點保留同一 PR 識別，讓後續 Source 對不同頁碼建立請求。

## 驗收

- RE01 核對 GET、GitHub.com 首頁及續頁 URL、正數頁碼。
- RE02 無效 owner、repository、PR 編號或頁碼時，回報驗證錯誤。
- RE03 既有 Reader REST 測試、Swift 格式、Lint 及核定差異檢查通過。記錄五項本機審閱的實際證據。

完整清單讀取、REST client 與標頭接線、Link 分頁與歸屬查核、DTO 與 Reader failure、快照及 UI 歸後續 topic。

[執行計畫](../../plan/pr-reader-github-reviews-endpoint/pr-reader-github-reviews-endpoint.plan.md) · [GitHub Reviews API](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request)
