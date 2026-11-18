# PR Inbox GitHub adapter 可行性驗證技術規格

## 鎖定設計

- 使用獨立 SwiftPM package 與既有 `RivetPRInbox`、`GitHubIntegration`、`RivetHTTPClient`。實驗 `ReviewRequestSource` 注入既有 `GitHubRestClient`，經 `PRInboxFacade.refresh()` 驗證公開 Port 與 Outcome。
- 發送 `GET https://api.github.com/search/issues`，`q=is:pr is:open user-review-requested:@me`、`per_page=100`、`Accept: application/vnd.github+json`、`X-GitHub-Api-Version: 2026-03-10`。僅跟隨同一 GitHub HTTPS API endpoint 未走過的 `rel=next`。最多十個搜尋頁次，保持頁內與跨頁順序。 [GitHub REST Search](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests) · [REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination)
- 從 `repository_url` 取基底 repository 的 owner 與 repository，結合 number、title、state 與 `pull_request` 建立候選項目。直接審閱資格來自固定查詢。空集合是成功。非 200、無效 DTO 或分頁、傳輸錯誤、取消、`incomplete_results=true` 或搜尋上限超過 1,000 筆皆回傳 `.unavailable`。後頁失敗時，前頁資料一併捨棄。
- CLI 以本機無回顯方式接收已有且未到期的 `GitHubOAuthCredentialBundle` 與獨立核對的樣本，留在程序記憶體。以實驗 store 和 fetcher 拒絕保存與刷新，使用 `GitHubClientScope.prepare(provider:)` 的 `rest`。先一次 `GET /user` 比對帳號，再一次 Facade refresh。驗證預算合計 11 GET／60 秒／零重試。只輸出有限結果、計數與布林。
- 受控測試透過既有 client protocol 注入合成回應，使用 `swift test --package-path experiments/E019`。真人從同一帳號的 GitHub PR 詳情先確認實際狀態、直接審閱要求及四欄，再用 `swift run --package-path experiments/E019 pr-inbox-probe` 比對。已存在的 team-only 或已關閉反例可提供排除證據。

## 結果分類

| 結果 | 事前判準 |
| --- | --- |
| 成功 | 受控測試符合契約，真實正例四欄一致，已提供的反例均排除。缺少真實反例時，真實證據限已核對正例。 |
| 失敗 | 查詢完整、樣本狀態已確認，缺漏、誤納或欄位錯誤可歸因到查詢或 adapter。 |
| 無法判定 | 已嘗試，但帳號、權限、索引時差、網路、回應完整性或預算限制使證據不足。 |
| 未執行 | 啟動前缺少有效 OAuth bundle 或已獨立確認的正例。 |

README 區分受控與真實觀察，保存環境、版本、命令、去識別證據、實驗狀態及本輪驗證任務完成判斷。無法判定需記錄缺口與決策限制。正式採用以 E019 成功且獨立核對為前提。
