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

真實驗證狀態為**未執行**，真實 E020 GitHub GET 為 0。受測 OAuth bundle 尚未於本機提供。

## 結果與證據

2026-11-18 透過 GitHub PR 詳情確認 [mlops-async#72](https://github.com/a129924/mlops-async/pull/72) 開啟，作者為 `a129924`。這提供樣本的獨立資料，受測 OAuth bundle 尚未核對。

獨立 Tester 在 arm64 macOS 26.5.2 與 Swift 6.3.3 通過完整 Swift 測試 365 項與 E019 回歸 12 項。strict format 與 SwiftLint 通過。E020 CLI 建置通過，無控制終端僅輸出 `notExecuted`，exit 2，stderr 為空。獨立 Reviewer 核准 Draft 交付。

## 結論與限制

真實可行性仍待使用同一 OAuth 帳號取得樣本。自查候選包含符合作者及開啟條件的 Draft。自查完成狀態留待後續定義。
