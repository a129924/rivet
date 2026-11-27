# E026 · PR Inbox 最後更新時間

這是受控 macOS 原生驗證。E026 經正式 PR Inbox 查詢取得同一搜尋回應，將有效的更新時間交給正式 PR 列。共用宿主位於 `experiments/support/InboxExperimentSupport`，與正式產品使用同一 checkout。

從含 E026 的整個 repository 版本執行。建置使用現有 Apollo 快取和根套件 pins。若快取在其他位置，以 `APOLLO_CACHE_SOURCE` 指定 bare repository。

```bash
bash experiments/E026/scripts/verify.sh test
bash experiments/E026/scripts/verify.sh regression
app="$(bash experiments/E026/scripts/verify.sh build)"
open "$app"
```

初次載入會顯示有效、缺席、null、錯誤型別及不可解析的日期。確認 `sample/ui #42` 為「2 小時前」，並選取它。改用「第二頁成功、重排更新」後重新整理，等畫面顯示已到第二頁，再按「完成第二頁」。選取應留在移至第三列的 `sample/ui #42`，時間變為「1 小時前」。接著用「移除已選 PR 的時間」、「移除已選 PR」及「空清單」驗證清除舊時間、首列回退與空狀態。

要驗證舊清單保留，先載入有效日期並選取 `sample/ui #42`，再選「第二頁失敗」。比較等待前、等待中與完成後的清單。縮窄至 420 pt 檢查 PR 識別及選取，並以 VoiceOver 核對有時間及缺值的列。

[驗收證據](evidence/i3-last-updated.md)
