# 指定 repository 的 open PR 清單需求

Topic `github-repository-open-pull-requests-adapter`。以經查證的 `dev` `d8e2ffed24c64da728cfb394da8d5a521b03642d` 為執行基線。前置標頭命名及 Endpoint 已併入，基線另包含相鄰但獨立的 PR Reader changed-files Endpoint。 [Headers #87](https://github.com/a129924/rivet/pull/87) · [Endpoint #88](https://github.com/a129924/rivet/pull/88)

## 產品意圖

套件內呼叫端已知 repository 的 owner、repository 名稱，並持有已配置的 `GitHubRestClient`。正式入口應一次交付憑證可讀的完整 open PR 清單、成功空清單或可辨識的整次失敗。每筆摘要包含編號與標題，涵蓋 Draft 與其他作者的 PR，保留 GitHub 的頁內與跨頁順序。

## 範圍與成功條件

- 使用既有 `RivetRepositoryPullRequestsGitHub` target、`GitHubRepositoryOpenPullRequestsEndpoint`、`.standardREST` 與注入的 REST client。套件內呼叫端可直接取得查詢結果。
- 依 GitHub `Link` 讀至尾頁。無效 repository 識別在送出請求前遭拒。任一頁的請求、內容或分頁延續失敗，或查詢遭取消，呼叫端只收到失敗。
- 每次請求均限同一個 GitHub.com repository 的 open PR。對數字路徑別名須從本次成功頁面取得 repository 身分證據，再使用原 Endpoint 重建下一頁請求。
- 驗收採離線受控回應，從正式入口觀察實際送出的請求、結果及失敗分類。記錄長期契約至 API Catalog。 [API Catalog](../../docs/github-api/rest-inbox-discovery.md#repository-pull-request-list)

## 延後能力

產品 repository 選擇與瀏覽、PR Inbox／Reader 接線、跨 repository 搜尋、closed／merged PR、額外篩選與排序、快取、GitHub 資料寫入、OAuth 變更、套件外 API 及即時 GitHub 驗收。

長期資料由 GitHub 持有。此切片無本地持久化、事件或資料遷移。詳細契約及受限執行範圍見 [技術規格](technical-spec.md) 與 [執行計畫](../../plan/github-repository-open-pull-requests-adapter/github-repository-open-pull-requests-adapter.plan.md)。
