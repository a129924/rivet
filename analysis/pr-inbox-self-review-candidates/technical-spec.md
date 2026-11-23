# PR Inbox 自查候選技術規格

## 核定範圍

- 在 `RivetPRInbox` 加入 `SelfReviewSource`、`SelfReviewCandidate` 和 `PRInboxFacade.init(selfReviewSource:)`。自查分支依 `isOpen && isAuthoredByCurrentUser` 篩選並保留來源順序。原直接指派的 initializer、Port、候選型別與篩選語意一併支援。
- Inbox 擁有獨立的 `RivetPRInboxGitHub` 基礎設施 target，供 caller 注入既有 `GitHubRestClient`。Core、UseCase 與 Port 保持無網路依賴。adapter 負責呼叫 `GET /user` 取得登入名稱及跨 repository 查詢 `GET /search/issues`。固定查詢為 `q=is:pr is:open author:<login>`，以 `user.login` 與 PR state 轉成自查候選。作者欄位為 GitHub 合法的 null 時，該筆不具自查資格。 [GitHub 作者查詢](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests#search-by-author) · [REST Search](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)
- 每頁 100 筆，最多十搜尋頁。僅跟隨同一 HTTPS endpoint 且保留條件的下一頁，保留頁序。完整空集合成功。權限、取消、非預期回應、畸形 DTO 或不完整分頁均映射 `.unavailable`，含後頁失敗。Scope 仍由 caller 擁有。
- E020 的 SwiftPM CLI 重用正式 adapter 與 Facade。現有 OAuth bundle 和確認的樣本標題由 Human 在本機無回顯輸入，僅留記憶體。帳號與樣本識別由公開正例決定。以同一 client 的 `GET /user` 驗證帳號，總計最多 11 個應用層 GET、60 秒、零重試，輸出有限狀態及布林。保留 E019 的獨立 package 與歷史。

## 驗收

受控測試涵蓋自身 open 與 Draft、其他作者 open、自己已關閉、空集合、跨頁順序、DTO、缺失身分、取消和後頁失敗。既有直接指派測試和 E019 測試維持通過。E020 真實成功須確認 #72 仍為 open、受測 OAuth 帳號與作者一致，Facade 回傳與 PR 詳情一致的四欄。可歸因的偏差為失敗。權限、帳號、索引或完整性不足時為無法判定。缺乏本機前置時為未執行，Draft PR 可先交付受控驗證。
