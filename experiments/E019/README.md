# E019：PR Inbox 的 GitHub 審閱請求查詢

## 驗證什麼

確認現有 GitHub OAuth REST client 能否讓既有 `PRInboxFacade.refresh()` 取得真實、仍開啟且直接要求目前帳號審閱的 PR，並讓 owner、repository、number、title 四欄與獨立核對的正例一致。

設計日期為 2026-11-18。建立前在目前工作樹及可見 Git 歷史核對 E019 未占用。

## 為什麼

GitHub Search 可用 `is:pr is:open user-review-requested:@me` 跨 repository 尋找候選項目。真實帳號能否透過既有 REST Scope 得到與已知 PR 一致的資料，取決於帳號、repository 存取與搜尋索引，需要用一筆獨立核對的正例驗證。基線 `0a71be9` 已提供 REST Scope、Inbox Port 和 Facade。 [GitHub REST Search](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests) · [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination) · [Rivet API 盤點](../../docs/github-api/rest-inbox-discovery.md) · [正式技術規格](../../analysis/pr-inbox-github-adapter-feasibility/technical-spec.md)

## 成功與失敗判準

| 實驗狀態 | 判準 |
| --- | --- |
| 成功 | 受控測試符合契約，真實回應中的正例四欄一致，而且已提供的反例均排除。缺少真實反例時，真實證據限正例。 |
| 失敗 | 查詢完整且樣本狀態已確認，缺漏、誤納或錯誤欄位可歸因到查詢或 adapter。 |
| 無法判定 | 已嘗試，但帳號、權限、索引時差、網路、回應完整性或預算限制使證據不足。 |
| 未執行 | 啟動前缺少有效 OAuth bundle 或獨立核對的正例。 |

上述判準於執行前鎖定。輸入確認後，最多 11 個應用層 GET，含一次帳號核對及最多十頁 Search。驗證時窗為 60 秒，零應用層重試。到期會取消驗證，CLI 只輸出有限狀態。

## 環境與前置條件

- 使用獨立 SwiftPM package。受控驗證環境為 arm64 macOS 26.5.2（25F84）、Apple Swift 6.3.3、Apollo iOS 2.1.2。所用 [Package.resolved](Package.resolved) 對應既有 pin。
- 真人驗證需要本機終端、未到期的現有 OAuth access token 與 refresh token、兩者的到期時間，以及能存取正例 repository 的帳號。由 Human 預先從 GitHub PR 詳情確認同帳號的直接審閱關係、open 狀態與四欄。有現成僅要求團隊審閱或已關閉的反例時，同樣預先確認。
- CLI 對樣本和憑證皆在本機終端無回顯讀入，值僅留程序記憶體。實驗 store 拒絕寫入，fetcher 拒絕刷新。受控測試只使用合成回應。

## 重現步驟

1. 從 repository 根目錄執行 `swift test --package-path experiments/E019`。受控測試由 Facade 走到實驗 source，注入預先排定的 REST 回應。
2. 真人前置就緒時，在本機終端執行 `swift run --package-path experiments/E019 pr-inbox-probe`。輸入獨立核對確認、GitHub 帳號、正例的 `owner/repo#number` 與標題。如有反例，輸入以逗號分隔的反例識別。之後輸入現有 OAuth bundle、RFC 3339 到期時間及 scopes，反例和 scopes 可留空。
3. CLI 用既有 Scope 呼叫一次 `GET /user` 確認同一帳號，再執行一次 Facade refresh。Search 依原順序使用 `rel=next`，各頁均成功且完整才回傳資料。持久證據只記 JSON 的狀態、計數、布林值與執行版本。
4. `sampleMatched` 表示當次樣本吻合，需與受控證據合併判定。`sampleMismatch` 需要判斷索引時差與可歸因性。CLI 顯示的 `notExecuted` 為未執行，其餘技術錯誤與 `timeout` 屬證據不足。CLI exit code 為 0（sampleMatched）、1（已嘗試但其餘狀態）或 2（notExecuted）。

## 是否成功

真實實驗狀態為**未執行**。尚無本機現有 OAuth bundle 與同帳號獨立核對的正例。真實驗證任務尚待完成，真實 GitHub GET 數為零。

## 結果與證據

- Implementer 受控驗證於 2026-11-18 完成。Swift Testing 12 項測試通過，含精確 query／headers、base repository 四欄映射與順序、空集合、closed 候選過濾、錯誤映射、後頁失敗、迴圈與畸形連結、搜尋上限、十頁界線與逾時前置。 [測試原碼](Tests/InboxSearchTests/GitHubReviewRequestSourceTests.swift)
- Red 階段用未實作的 source 驗證其中一個測試，測試取得 `.unavailable` 並失敗。完成 adapter 後所有受控測試通過。Swift format strict 與 SwiftLint strict 通過。以無控制終端啟動 CLI，exit 2 且僅輸出 `{"status":"notExecuted"}`。
- 呼叫關係為 CLI → `PRInboxFacade.refresh()` → 實驗 `ReviewRequestSource` → 既有 `scope.rest` → GitHub Search。上述受控證據支持請求組裝、轉換和失敗邊界。真人證據仍待取得。

- 獨立 Tester 重跑 12 項受控測試、strict format、SwiftLint strict 與無控制終端檢查，均通過。獨立 Reviewer 核准交付 Draft，真實驗證仍為未執行。
- Archify 本機序列圖達 showcase 9/9、0 errors、0 warnings，四個桌面尺寸 containment 與淺深色視覺檢視通過。規格 SHA-256 為 `ea701427b7502c8d45b983c121f7e9802ab6dcf680dfb7aef23baaa372a83206`，HTML SHA-256 為 `4daebfbf8acaad773cffa3881ab583920977cbb34d2bf277c9960238f23a752b`。Viewer 固定介面為英文。
- Floorplan 本機地圖含 500 個已描述程式檔、零未指派，標出 4 張 E019 卡片。Graphify 0.9.73 缺既有 graph，採限域原始碼核對。PR Lens 0.11.0 依 Draft PR 的實際 base/head 產圖，結果由交付收據記錄。

## 結論與限制

目前已完成可重現的驗證程式。正式 adapter 採用仍需真人依原判準驗證並經獨立核對。GitHub 搜尋索引可能延遲，連續頁的結果若出現缺漏線索或 total 變動會回傳 `.unavailable`。通過一筆正例時，結論適用於該帳號、資料與時間點。未涵蓋全帳號可見性、續期流程、產品 UI 或真實反例尚未提供時的團隊排除證據。
