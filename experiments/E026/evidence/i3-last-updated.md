# E026 · I3 驗收證據

受控查詢使用 `/user` 的 `sample` 與 `/search/issues` 的 open PR 搜尋。固定參考時間為 `2026-11-27T12:00:00Z`，格式為 `zh-Hant-TW`。完整輸入由 [受控回應](../Sources/InboxI3Verification/InboxI3FixtureREST.swift) 生成。

| 情境 | 輸入與觀察目標 |
| --- | --- |
| I3-01／02 | `sample/ui#42` 在 10:00Z 更新，標籤為「2 小時前」。`sample/core#42` 為「3 小時前」。另外四筆分別缺欄位、為 null、數字及無效字串。 |
| I3-03／04 | 選取第二列 `sample/ui#42`。第二頁成功後同 ID 到第三列，標籤為「1 小時前」。下一次成功可移除時間，之後移除 PR 時選 `sample/core#42`，零筆後清除選取。 |
| I3-05 | 第一次 503 顯示查詢失敗。第二頁 503 時，第一頁讀到的 11:30Z 資料不發布，原時間和 `sample/ui#42` 選取維持，狀態為可能非最新。 |
| I3-06 | 同一原生 App 在 940／420 pt 下核對寬窄呈現。VoiceOver 應讀到 PR 識別及有效時間。 |

受控測試、正式回歸與原生結果見本次審查紀錄。重現時檢出 Draft PR 上記錄的完整受測 commit，讓 E026、共用宿主及正式依賴一併重現。

## 驗證結果

- E026 `verify.sh test` 4 項通過。涵蓋有效與錯值、同號跨 repo、第二頁等待、完整成功與失敗、取消、舊標籤清除及選取回退。
- 獨立 Tester 執行 `verify.sh regression`，48 項／13 suites 通過。E026 `verify.sh build` 成功。新增 Swift 檔的嚴格 Swift format 與 SwiftLint 通過。
- 獨立 Tester 在原生 940 pt 視窗觀察 `sample/ui #42` 和 `sample/core #42` 分別顯示「2 小時前」及「3 小時前」。四個缺值案例仍可讀，無多餘分隔符號。
- 420 pt 窄版保有 PR 識別及所選的 `sample/ui#42`，時間視覺隱藏。兩種寬度的 Accessibility 資料均提供 `sample/ui#42` 的「2 小時前」。實際 VoiceOver 聲音留待 Human 實聽。
- 原生分頁成功期間，第二頁等待時同一筆 `sample/ui#42` 仍選取並保留「2 小時前」。完成後移到第三列，同一 ID 仍選取且更新為「1 小時前」。
