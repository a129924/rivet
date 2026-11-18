# E020：PR Inbox 自查候選的 GitHub 驗證

## 驗證什麼

驗證既有 `PRInboxFacade.refresh()` 能透過正式自查來源列出目前 OAuth 帳號自己開的 open PR，對照一筆獨立核對的真實正例。

## 為什麼

新版自查範圍使用作者與開啟狀態。受控 fixture 能驗證查詢、DTO、分頁與 Facade 篩選。真實驗證補足 OAuth 帳號、搜尋索引與真實輸出欄位的證據。E019 的直接指派實驗另有原始紀錄。 [E019](../E019/README.md) · [自查技術規格](../../analysis/pr-inbox-self-review-candidates/technical-spec.md)

## 成功與失敗判準

成功需受控測試通過，受測 OAuth 帳號經同一 REST client 的 `GET /user` 核對為 `a129924`，且 Facade 回傳與 PR 詳情一致的 owner、repository、number、title。查詢完整且樣本狀態已確認時，可歸因的缺漏、誤納或映射偏差為失敗。帳號、權限、索引、回應完整性或時限不足時為無法判定。出發前缺少有效本機前置為未執行。

真人驗證最多發送 11 個應用層 GET，含一次帳號核對和最多十個搜尋頁。驗證上限為 60 秒，零應用層重試。期限起於完成輸入，驗證 host 拒絕 refresh 與存檔。

## 環境與前置條件

使用 macOS、Swift 6 與既有 Apollo 2.1.2 pin。Human 先在 GitHub PR 詳情確認 [mlops-async#72](https://github.com/a129924/mlops-async/pull/72) 仍開啟且作者是 `a129924`。準備未到期的既有 OAuth access token、refresh token 及各自的 RFC 3339 到期時間，並確認 OAuth 帳號有讀取權限。

## 重現步驟

1. 從專案根目錄執行 `swift test --filter 'GitHubSelfReviewSourceTests|PRInbox'`。
2. 前置就緒時，在本機終端執行 `swift run --package-path experiments/E020 pr-inbox-self-review-probe`。輸入確認、PR 完整標題及既有 OAuth 資料，所有欄位無回顯，scopes 可留空。
3. CLI 讀取帳號，再經同一 Facade 取得清單，比對正例四欄。保留布林值、計數、狀態與版本。程式以 exit 0 表示樣本吻合，exit 2 表示未執行，其餘為 exit 1，需依事前判準判讀。

## 是否成功

本次瀏覽器 OAuth 真人驗收為**成功**。Human 確認可用 `a129924` 在 GitHub 開啟 [mlops-async#72](https://github.com/a129924/mlops-async/pull/72)。同一 OAuth 帳號下的 `PRInboxFacade.refresh()` 回傳該 PR，四欄吻合。

先前手動輸入 bundle 的驗收狀態為未執行。CLI 在輸入階段回傳 `notExecuted` 並以 2 結束，當時 E020 GitHub GET 為 0。

## 結果與證據

2026-11-18 透過 GitHub PR 詳情確認 [mlops-async#72](https://github.com/a129924/mlops-async/pull/72) 開啟，作者為 `a129924`。這提供樣本的獨立資料，受測 OAuth bundle 尚未核對。

獨立 Tester 在 arm64 macOS 26.5.2 與 Swift 6.3.3 通過完整 Swift 測試 365 項與 E019 回歸 12 項。strict format 與 SwiftLint 通過。E020 CLI 建置通過，無控制終端僅輸出 `notExecuted`，exit 2，stderr 為空。獨立 Reviewer 核准 Draft 交付。

先前手動輸入 bundle 的驗收使用 Draft PR #78 的 `9e4bd9b` 版本。主機從 `2026-11-18T09:17:18Z` 等候本機輸入，至 `2026-11-18T09:19:51Z` 收到 `{"status":"notExecuted"}`。執行檔 SHA-256 為 `04736702c13d9a542a5cd7705b21eeee5b6785725980407543a941fd3c23a354`。CLI 收據未指出哪個欄位未通過，無法由收據判定原因。公開 PR 資料在啟動前已確認 #72 仍為 open，作者是 `a129924`。

依 Human 的後續指示，瀏覽器 OAuth 入口已在本機暫存建置。沿用 `9e4bd9b` 的 Rivet OAuth 授權流程、loopback callback 與既有 E020 Facade 驗收，同一程序內接收 OAuth 結果。無控制終端的受控檢查通過，回傳 `notExecuted` 並以 2 結束。此工作樹尚無可供入口使用的 Rivet OAuth App 設定。本機舊 Rivet.app 的 provisioning profile 已於 2026-10-27 到期。準備瀏覽器入口時，尚未發起 OAuth 授權或 E020 GitHub GET。

### 瀏覽器 OAuth 真人驗收

- 使用 Draft PR #78 的 `9e4bd9b` 來源。暫存入口以 `swift build --product pr-inbox-self-review-probe` 建置，執行檔 SHA-256 為 `9d2b788f1bee851fbabfa4a4c27187a496b5a74a45cf3fdf61343997f14810d0`。本機終端驗收從 `2026-11-18T09:40:20Z` 到 `2026-11-18T09:41:00Z`。
- Human 在無回顯終端確認使用 `a129924` 開啟 #72，並在瀏覽器完成 Rivet 的 OAuth 授權。入口在同一程序將 OAuth 結果交給既有 E020 Facade 流程。授權前後均從 GitHub PR 詳情核對 #72 為 open，作者為 `a129924`，標題一致。 [PR #72](https://github.com/a129924/mlops-async/pull/72)
- CLI 回傳 `sampleMatched`、exit 0、`accountMatched=true`、`fieldsMatch=true`、`getCount=2`、`queueCount=7`。兩個應用層 GET 分別為帳號核對與搜尋。Facade 回傳的 owner、repository、number、title 與正例一致。

## 結論與限制

真人驗收涵蓋本輪 `a129924` 帳號與 #72 這一筆正例。自查候選包含符合作者及開啟條件的 Draft。自查完成狀態留待後續定義。
