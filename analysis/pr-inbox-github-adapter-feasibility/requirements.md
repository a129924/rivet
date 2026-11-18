# PR Inbox GitHub adapter 可行性驗證需求

## 意圖與決策

以 E019 判定現有 OAuth REST client 與 PR Inbox Facade 能否組成無 UI 的待審閱查詢。成功時才有依據另案規劃正式 adapter。現有設計確立 Inbox 僅收錄 GitHub.com 上開啟且直接請求目前帳號審閱的 PR。文件說明查詢條件與分頁，正例能否在真實帳號下經既有 Facade 回傳仍需觀察。 [PR Inbox](../../docs/architecture/bounded-contexts/pr-inbox.md) · [REST Inbox Discovery](../../docs/github-api/rest-inbox-discovery.md)

## 範圍與交付

- 在獨立 feature worktree 新增正式四檔與 E019 的 SwiftPM CLI、實驗用 source、受控測試及八段 README。產品接線、UI、正式 adapter、PAT、DPK／Keychain、新 OAuth 授權與更新留待其他工作。
- 真實驗證限現有 OAuth、唯讀 GitHub.com API、一次 Facade refresh、最多 11 個 GET 與 60 秒、零重試。Human 須從 PR 詳情獨立核對同帳號的現有正例，有現成的 team-only 或已關閉反例時一併核對。憑證與 PR 比對資料留本機程序，持久證據限去識別計數、比對結果及錯誤分類。
- 成功需受控測試符合契約、真實正例四欄一致、已提供的反例均排除。缺現有有效 OAuth 或獨立核對的正例時，真實驗證記為「未執行」，已獨立審查的程式與受控證據可交付 Draft PR。證據充分的 E019 結果才支持正式採用規劃。
- 無未解重大問題時，依使用者直接授權做單一 topic commit、正常 push、建立以 `dev` 為 base 的 Draft PR，交 Human review。產品資料與工具圖面均留本機。
