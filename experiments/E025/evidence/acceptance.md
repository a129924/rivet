# E025 · I2 驗收紀錄

2026-11-27（Asia/Taipei）。arm64 macOS 26.5.2（25F84）、Xcode 26.6（17F113）、Swift 6.3.3。分支 `chore/pr-inbox-i2-verification` 以 `dev` `0623246ae36da158c4d858e9290087b28e9ae9db` 為基線。

- 受測來源為工作樹 E025。來源清單 SHA-256 為 `88cf3d5820ad0787a1e08c4d5ab890132fdf287aaca30b3e754acfeca1e8802b`，與獨立 Tester 核對一致。 [逐檔來源 SHA-256](source-sha256.txt)
- 原生組裝與執行同一個 `InboxI2Verification.app`，binary SHA-256 為 `1f3770deb47b18f822781790f9b5464c9dbcc20034ca97bb867df9285fcb2356`。截圖為該 App 原生視窗，數值來自其 Accessibility 視窗寬度。
- 獨立 Tester 執行 `verify.sh test` 7 項測試、10 個參數化後實際案例，`verify.sh regression` 21 項測試、38 個實際案例，均通過。首次回歸的套件巢狀 `dump-package` 受預設 Clang cache 權限阻擋，重跑時只在暫存 wrapper 為該子命令指定可寫快取及關閉巢狀 SwiftPM sandbox。Strict format、strict SwiftLint、Bash 語法、diff 空白及路徑核對均通過。
- 紅測試的可歸因失敗是重排改名後選取為 `nil`。完成後同一測試保留 `sample/ui #42`。

| 案例 | 實際結果 | 記錄 |
| --- | --- | --- |
| I2-01 | 通過。畫面依序顯示 `sample/core #42`、`sample/ui #42`（fixture Draft）、`sample/runtime #17`。他人 open 與自己 closed 資料排除。 | [原生清單](native/01-wide.png) · [Accessibility](native/01-wide.txt) |
| I2-02 | 通過。原生選取第二列 B，重新整理後改標題的 B 位於第三列且仍選取。再移除 B，選到首列 A。 | [更新前](native/03-selected-before.txt) · [重排畫面](native/04-reordered.png) · [重排紀錄](native/04-reordered.txt) · [移除後](native/08-removed.txt) |
| I2-03 | 通過。完整成功零筆顯示空清單。首次空與更新後空均沒有選取或可操作列。 | [更新後畫面](native/09-empty-after-update.png) · [首次空](native/10-first-empty.txt) |
| I2-04 | 通過。首次失敗顯示「無法取得 Pull Request」且無列。已有完整清單時維持原資料與已選第三列，標示可能非最新。 | [首次失敗](native/11-first-failure.png) · [更新失敗](native/05-stale.png) · [更新失敗紀錄](native/05-stale.txt) |
| I2-05 | 通過。REST 進到第二頁後停住。等待中與回傳失敗後，兩個情境的原生清單均無第一頁獨有的 `sample/partial #91`。可讀舊列及已選第三列保留。 | [有舊列等待](native/06-page-wait-with-rows.png) · [有舊列失敗](native/07-page-fail-with-rows.txt) · [無舊列等待](native/12-page-wait-without-rows.png) · [無舊列失敗](native/13-page-fail-without-rows.txt) |
| I2-06 | 通過。940 pt 與 420 pt 截圖均可讀標題、owner/repo、編號。作者、時間、Draft 徽章與孤立分隔點均省略。 | [寬版 940 pt](native/01-wide.png) · [窄版 420 pt](native/02-narrow.png) · [窄版 Accessibility](native/02-narrow.txt) |
| I2-07 | 未執行。標準 provisioning profile 位置無適用檔案。已知本機 Rivet 及驗證 App 內嵌 profile 均已過期，歷史 hosted profile 也已過期。E025 以未配置產物驗證顯示前置缺失。既有憑證與真實樣本未進入驗收。 | [前置不足紀錄](native/14-live-precondition.txt) |

I2-01～06 受控驗收通過。I2-07 尚缺與既有 OAuth 工作階段相符的有效 profile 與 App 配置，因此 I2 整體尚未完成。

後續已更新 profile 並完成真人原生上屏。上表保留首次驗收結果。 [I2-07 補驗](i2-07-live.md)
