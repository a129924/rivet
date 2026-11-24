# PR Inbox 採用 GitHub REST 回應分類器需求

## 目標與基線

將 Phase A 已驗證的 `GitHubResponseClassifier` 接入 `GitHubSelfReviewSource`。這是本地 `dev` 基線 `909c20c7982fe990b50896e857467ea85acdc773` 上唯一正式採用 GitHub REST 的業務 Adapter。PR #80 已將 Phase A 合入該基線。接線涵蓋 `/user` 與 `/search/issues` 的每一頁，PR Inbox 持續以同一業務結果表達暫時無法取得自查候選。

已確認的落差：PR Reader 尚無正式 GitHub Adapter。草稿中的 Reader 403 分流沒有 production 基線，Inbox 現有拒絕分支也沒有專屬限流 helper 可移除。現有共用 `get` 僅接受 HTTP 200，其他回應直接映射為 `.unavailable`。 [Phase A 需求](../github-rest-response-classification/requirements.md) · [PR Inbox 契約](../../docs/architecture/bounded-contexts/pr-inbox.md)

## 範圍與成功條件

- GitHubIntegration 解釋遭拒絕的 HTTP 回應。Inbox Adapter 保有成功狀態契約與業務映射，並沿用既有 target 依賴。分類器僅需同一 Swift package 的可見性。
- 帳號與所有搜尋頁仍只接受 HTTP 200，沿用原有解碼、業務驗證、空集合與分頁行為。所有分類後的 HTTP 失敗，包括未知原因 403，仍映射 `.unavailable`。任一頁失敗回傳整體失敗。
- 正式 REST client 保有認證與 401 復原。認證需求、無效請求、傳輸、憑證生命週期及取消仍沿用既有拋錯路徑。
- 用離線回歸與精確原始碼查核證明接線。分類規則、公開 API、Endpoint、headers、DTO、分頁、transport、OAuth lifecycle、重送與取消契約列為範圍外。

## 已確認的交付邊界

人類已確認改接 PR Inbox，採用行為保留，並明確授權完整 processed-plan、獨立 feature worktree 及其中的實作。若獨立驗證與審查均無重大問題，授權本 topic 單一 commit、推送 feature branch 並開一個以 `dev` 為目標的 Draft PR，交還 Human review。授權止於 Draft PR 交付。若重大問題或混入無關變更，停止於發布前。分支與驗收細節見[執行計畫](../../plan/github-rest-response-classifier-adoption/github-rest-response-classifier-adoption.plan.md)。
