# 正式產品驗收

> 歷史來源：基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22` 的舊 host／當時 dirty source；以下原始結果保留。舊「正式 app」說法不代表產品 UI 已交付，不冒充搬後驗證 App 重驗；本次結果見 [verification-host-amendment.md](verification-host-amendment.md)。

2026-10-20。Human 自行輸入個人 OAuth App 配置、完成瀏覽器授權。Agent 在正式 Rivet.app 觀察到 API 查詢成功及有效身分欄位；再操作「再次查詢」，完成後仍顯示成功及一致身分，未重新開瀏覽器。

本紀錄不保存帳號值、Client ID、secret、callback URL、code、state、tokens、bundle 或 screenshot。機密欄位在 UI 為遮蔽 SecureField。

- 正常 S256 授權 → 完整 bundle → 真實 /user：observed passed。
- 同程序再次 API：observed passed；原 provider／scope identity 另由受控 tests 證明。
- 缺失／錯誤 verifier 的新 code 反向測試：Human pending。
- 全部遠端 refresh／401 recovery：未宣稱。
- 重啟還原：Out-Of-Scope。

當時為本 topic 的 in-progress 本機 build，最終 source 的受控重建結果另見 compatibility.md；仍需 Draft PR 後 Human review。
