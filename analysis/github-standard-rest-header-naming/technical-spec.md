# 標準 REST 標頭命名技術規格

## 內部命名

`HeadersProvider.inboxREST` 改為 `standardREST`。Provider 的 `makeRESTDefaults(configuration:)` 回傳中代表標準組合的 tuple label 與對應區域值採 `standardREST`。Factory 對應的私有欄位、初始化標籤及內部引用採相同名稱，包含內建值、注入配置與組合選擇三條引用。

`GitHubHeadersFactory.standard` 與 `GitHubHeaderRequirement.standardREST` 是套件呼叫契約。空需求選標準 REST，重複需求視為一次，同時指定標準與登入用 REST 拋出 `conflictingRESTRequirements`。可注入配置維持既有組合邏輯，回傳標頭可由呼叫端獨立修改。

| 組合 | 預設輸出 |
| --- | --- |
| 標準 REST | `Accept: application/vnd.github+json`、`User-Agent: Rivet`、`X-GitHub-Api-Version: 2026-03-10`。 |
| 登入 REST | 相同 Accept、`User-Agent: RivetLoginRuntime`。登入探查沿用既有 Bearer 套用。 |
| OAuth 交換及刷新 | `Accept: application/json`、`Content-Type: application/x-www-form-urlencoded`。 |

維護「固定請求標頭」的長期文件，補記現有 Reader 背景讀取與 PR 清單採標準 JSON 時的適用契約。資料與呼叫端遷移皆不適用。 [執行計畫](../../plan/github-standard-rest-header-naming/github-standard-rest-header-naming.plan.md)
