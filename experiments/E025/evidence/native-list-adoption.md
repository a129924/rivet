# E025 正式原生清單採用驗收

2026-11-27（Asia/Taipei）。功能分支 `feat/pr-inbox-native-list-adoption` 以 `dev` `3468eaa` 為基線。驗收使用 macOS 26.5.2（25F84）、arm64 及 Swift 6.3.3。 [執行計畫](../../../plan/pr-inbox-native-list-adoption/pr-inbox-native-list-adoption.plan.md)

- E025 原生執行檔 SHA-256 為 `e270901c3dbb6e426c54acb2fe5629477d868a7e1befec32ac507d3a83df12e3`。既有 E024 入口的執行檔為 `aea5af987ba9a6b97c0be9535e982a62f65d3372fa354a8219cad6a55f8a2037`。
- 原生執行檔取自本 topic 的受測工作樹。對 `InboxListStatus.swift`、`PullRequestRow.swift`、`PullRequestRowPresentation.swift`、`InboxSession.swift` 和 `InboxVerificationWindow.swift` 依此順序執行 `shasum -a 256`，再對輸出取 SHA-256，結果為 `478027ccd134a0d0f2a4e573b23f19a53d20417ff8b2a3342cc92a3240133bf1`。
- 獨立 Tester 執行 E025 `verify.sh test` 7 項（參數展開 10 案）、`verify.sh regression` 21 項、`verify.sh build` 與 `swift test --filter RivetPresentationTests` 28 項，全部通過。焦點最後一次修正後獨立重跑 E025 測試與建置。根套件 `swift test` 653 項（80 suites）通過。嚴格 Swift format、SwiftLint 和 `git diff --check` 通過。
- 修正前的缺值測試重現四筆 Accessibility 字串分隔錯誤。修正後四種組合皆通過，另有四欄 initializer 測試確認作者與時間均缺席的輸入。

## 原生結果

| 案例 | 結果與觀察 |
| --- | --- |
| NLA-01 | 通過。實測 940 pt 與 420 pt 均顯示三筆可辨識的原生列，順序為 `sample/core #42`、`sample/ui #42`（Draft fixture）、`sample/runtime #17`。原生視窗截圖與 Accessibility 對應。 |
| NLA-02 | 通過。視窗成為作用中時，清單取得焦點並選取首列。選 `sample/ui #42` 後，改名重排到第三列仍選同一筆，移除後回 `sample/core #42`，更新至空時清除選取。 |
| NLA-03 | 通過。首載以第二頁暫停情境觀測進度與載入標題焦點。首次零筆及有列更新至空皆顯示成功空狀態，沒有可操作列，焦點落在該狀態標題。 |
| NLA-04 | 通過。首次失敗只有錯誤標題。更新失敗保留完整舊列與已選 `sample/ui #42`，並顯示可能非最新。有／無舊列的第二頁等待及失敗快照均無 `sample/partial #91`。 |
| NLA-05 | 視覺、Accessibility 與模型測試通過。隔離宿主以同版正式元件在 940 pt 顯示四種組合，只有兩欄齊全時有分隔點，Automation 可讀到四組完整標題及 PR 識別。VoiceOver 控制 AppleEvent 逾時，未取得實際朗讀。朗讀與停頓仍待 Human Review。 |
| NLA-06 | 通過。E025 原生上下鍵移動選取。E024 的 Enter 對 `sample/ui#42`、雙擊對 `sample/core#42` 各送出一次，失焦、不可開啟及移除目標都沒有增加事件。切換至其他 App 再返回後保留原生選取。 |

本次 14 個 E025 快照與 E024 事件紀錄留於本機驗收產物。I2-07 沿用已接受的真人上屏證據。 [原受控驗收](acceptance.md) · [原真人驗收](i2-07-live.md)

## 審查產物

- Graphify 0.9.73 已確認可用。此版缺對應本機圖，依計畫直接核對接線原碼。
- Archify sequence 通過 `showcase` 九項檢查與 1440×900、1600×1000、1920×1080、2048×1320 的視窗容納檢查。
- show-me 採用 E025 原生畫面呈現重排保留、成功零筆及兩種錯誤。
- Floorplan 以隔離副本核對 16／16 個檔案描述及原碼接線。範圍為 E025、正式 Presentation 元件及直接查詢依賴。
- PR Lens 使用本 topic 實際 commit 差異製作本機審查圖。交付狀態以 Draft PR 為準。
