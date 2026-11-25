# PR Reader GitHub 變更檔案端點需求

Topic 為 `pr-reader-github-changed-files-endpoint`。Human 已核定 endpoint-only 範圍、逐次指定頁碼的介面和兩頁共用同一端點實例的驗收方式。

## 意圖與範圍

Reader Infra 呼叫端持有一筆 GitHub.com PR 的 `ReaderPullRequestID`，需要可靠地建構該 PR 的 Changed Files REST 目的地，供後續讀取實作使用。本切片交付端點實例與離線測試。後續 topic 處理 adapter、認證 client 與標頭、`Link`、3,000 檔完整性、DTO、`ReaderFile`、Reader failure、清單及 UI。

## 成功條件

- 同一個端點實例以 `makeURL()` 取得第一頁，以 `makeURL(page: 2)` 取得第二頁。兩個 HTTPS GET URL 使用同一 PR 路徑，各自帶正確的 `page` 與固定 `per_page=100`。
- 顯式頁碼接受所有正 `Int`，包含 `31` 和 `Int.max`。頁碼為零或負數時拋錯。
- Owner、repository 或 PR 編號違反 #84 詳情端點的規則時拋錯。以既有 Reader GitHub 測試 target 完成回歸。

[技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-changed-files-endpoint/pr-reader-github-changed-files-endpoint.plan.md) · [GitHub Changed Files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files)
