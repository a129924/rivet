# E025 · I2-07 真人原生上屏

2026-11-27 13:47（Asia/Taipei），I2-07 通過。GitHub PR 詳情獨立確認樣本仍為 open。E025 以 940 pt 原生視窗顯示相同 PR，登入帳號與 PR 作者一致。 [GitHub PR #72](https://github.com/a129924/mlops-async/pull/72) · [受控驗收](acceptance.md)

| 欄位 | GitHub PR 詳情 | E025 原生列 |
| --- | --- | --- |
| owner | `a129924` | 相符 |
| repository | `mlops-async` | 相符 |
| number | `72` | 相符 |
| title | `feat(git-hooks): add WSL pre-commit bridge` | 相符 |

## 簽章與登入來源

- Xcode 取得新的 macOS development provisioning profile，有效至 2026-12-04 13:37（Asia/Taipei）。App ID、團隊、私有 access group 與原 Apple Development 憑證逐項比對相符，profile 授權目前這台 Mac。E025 通過 strict 簽章檢查。
- 新 profile 下可讀取原 OAuth 設定與憑證。舊 access token 已到期，原工作階段還原未完成。使用者明示可用 OAuth Login，確認舊 App 憑證被 GitHub 以 `incorrect_client_credentials` 拒絕後，在本機安全欄位輸入同一 Client ID 的有效 secret。
- 以正式登入服務完成 OAuth 交換、原帳號驗證與保存。新憑證寫入同一私有 access group 之下的 E025 專用 Keychain service，原服務名稱下的紀錄保持。登入工具結束後再啟動原生 E025，使用該連線載入 Inbox。
- E025 使用先前驗收過的程式來源及執行檔作為簽章輸入。原生 Accessibility 比對四欄，並在本機以 Vision 核對截圖可見的 repo、編號和標題。原始截圖留本機私有目錄，版本庫保留 SHA-256 與有限比對結果。 [機器收據](i2-07-live-receipt.json) · [原來源清單](source-sha256.txt)

I2-01～06 先前已通過。此次補齊 I2-07 真人原生上屏，七項驗收均通過。
