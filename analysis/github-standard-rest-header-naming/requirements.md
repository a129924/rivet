# Repository PR 清單的標頭契約與命名需求

Topic `github-standard-rest-header-naming`，基線為 `dev` 的 `7a283f8dbf1f6c1d84e5b1013c8f7663c5abb500`。

## 意圖與範圍

標準 REST 標頭已由 PR Inbox 與 PR Reader 共用。將 `GitHubIntegration` Provider 和 Factory 中代表此組合的內部命名一併對齊 `standardREST`。針對標準 JSON，Repository PR 清單可沿用既有 `.standardREST`。GitHub 建議該操作使用 `Accept: application/vnd.github+json`。 [GitHub List pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)

本 topic 可獨立驗收。PR 清單 Endpoint、adapter、專用標頭、API 版本升級、OAuth 授權流程、替代媒體型別、條件式標頭和 304 處理均在範圍之外。

## 成功條件

- 標準組合輸出 JSON Accept、`Rivet` User-Agent 與 `2026-03-10` API 版本，Inbox 與 Reader 仍以既有套件介面選用。
- 登入專用 REST、OAuth token 標頭和 `conflictingRESTRequirements` 通過既有離線驗收。
- 基線與改後各執行相同測試範圍，保存兩邊 SHA 與結果。改動可單獨撤回，無資料遷移。

Human 已確認整條內部命名範圍、四檔與獨立 worktree。符合單一 topic、既有驗收及獨立審查無重大問題時，人類已預先確認可執行一次 commit、推送 feature branch 並開以 `dev` 為目標的 Draft PR，之後停在 Human review。 [執行計畫](../../plan/github-standard-rest-header-naming/github-standard-rest-header-naming.plan.md)
