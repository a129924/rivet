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
| NLA-05 | 視覺、Accessibility 與模型測試通過。隔離宿主以同版正式元件在 940 pt 顯示四種組合，只有兩欄齊全時有分隔點，Automation 可讀到四組完整標題及 PR 識別。首輪 VoiceOver 控制 AppleEvent 逾時。後續 Human 實聽四種組合均通過，詳見補驗。 |
| NLA-06 | 通過。E025 原生上下鍵移動選取。E024 的 Enter 對 `sample/ui#42`、雙擊對 `sample/core#42` 各送出一次，失焦、不可開啟及移除目標都沒有增加事件。切換至其他 App 再返回後保留原生選取。 |

本次 14 個 E025 快照與 E024 事件紀錄留於本機驗收產物。I2-07 沿用已接受的真人上屏證據。 [原受控驗收](acceptance.md) · [原真人驗收](i2-07-live.md)

## 審查產物

- Graphify 0.9.73 已確認可用。此版缺對應本機圖，依計畫直接核對接線原碼。
- Archify sequence 通過 `showcase` 九項檢查與 1440×900、1600×1000、1920×1080、2048×1320 的視窗容納檢查。
- show-me 採用 E025 原生畫面呈現重排保留、成功零筆及兩種錯誤。
- Floorplan 以隔離副本核對 16／16 個檔案描述及原碼接線。範圍為 E025、正式 Presentation 元件及直接查詢依賴。
- PR Lens 使用本 topic 實際 commit 差異製作本機審查圖。交付狀態以 Draft PR 為準。


## NLA-05 VoiceOver 人工補驗

2026-11-27（Asia/Taipei），Human 在由最新整合候選建置的隔離原生視窗逐列選取並實際聆聽，回覆「四列實聽皆通過」。驗收宿主執行檔 SHA-256 為 `bc603005eb0e5f2c495815734ee98db17643c3f106df138a88a1eb5919cdc022`。

| 組合 | PR 識別 | 人工實聽 |
| --- | --- | --- |
| 作者與時間皆有 | `sample/core #42` | 通過 |
| 僅作者 | `sample/ui #42` | 通過 |
| 僅時間 | `sample/ui #43` | 通過 |
| 作者與時間皆缺 | `sample/core #44` | 通過 |

四列均以完整標題、PR 識別、已選取語意、缺值自然省略及無空項、異常停頓或孤立分隔符為判準。結果依 Human 實聽回覆。

## 最新 dev 整合回歸

- 原受測基線 `3468eaa`。整合基線 `ce439a134fd19db5500f38f14c304499599c60b8` 包含 `2990163` 的 GitHub REST Redirect Policy、transport 與 isolation 測試，另有兩份實驗紀錄更新。根套件及 E025 manifests 和 pins 逐檔一致。已審查的 PR HEAD 為 `1f97ad586fc0715beea4212335735597798cda13`。
- GitHub 當時的測試合併 ref `fbe822b67e88b7813903298d90bed4ba2a7d1428` 仍以 `2990163` 為第一個 parent。獨立 checkout 使用最新 dev 與已審查 HEAD 組成本機整合候選 `1b2043e7f0f27cbc911fcb6ae4a2540dc9e575b8`，tree `5bbddee75f0529db692fb9bf4d8e5a13b041cb6e`，兩個 parent 逐一核對。與當時 GitHub merge ref 的 tree 差異僅在 `experiments/README.md` 與 `experiments/VALIDATION-SUMMARY.md`。測試完畢時遠端 dev 及已審查 HEAD 再次核對相符。
- 獨立 Tester 於 macOS 26.5.2（25F84）、Swift 6.3.3 測試。隔離 checkout 驗證前後皆乾淨，`git diff --check HEAD` 通過。

| 驗證 | 結果 |
| --- | --- |
| E025 `verify.sh test` | 通過。7 項、1 suite，展開 10 案。 |
| E025 `verify.sh regression` | 通過。21 項、6 suites，展開 39 案。 |
| E025 `verify.sh build` | 通過。App 含 `InboxI2Verification`、`Rivet_RivetPresentation.bundle` 及 `GitHubMark.pdf`。執行檔 SHA-256 為 `0f69f2a0b3f31950f822c9c479844927d28ef7161e94e15489e778107ac54b71`。 |
| `swift test --filter RivetPresentationTests` | 通過。28 項、8 suites，展開 38 案。 |
| 根套件 `swift test` | 通過。655 項、80 suites。 |

採用仍限於 E025 實驗接線及正式元件。真人 OAuth 上屏沿用既有 I2-07。 [PR #113](https://github.com/a129924/rivet/pull/113)


### PR #112 合併後的重新驗證

測試期間 `dev` 前進至 `25b23c449ff6f1d9d27e5176e393a545885dcc78`。PR #112 新增 `RivetPRWriteGitHub` 與其測試 target，沿用既有 Apollo pins，並更新 GitHubIntegration isolation 測試。E025 manifests、pins、正式 Inbox Presentation 及相關測試均與上一候選相同，NLA-05 人工結果沿用。 [PR #112](https://github.com/a129924/rivet/pull/112)

- 受測整合候選 `3919556ba8aae8a4d3baff0983b1680e1c6d3051`，tree `cf9edc43ab83f9ca6d0f9517cb49827cde3f35e1`，parents 為 `25b23c449ff6f1d9d27e5176e393a545885dcc78` 與補驗文件提交 `03d88b22979a4d204e6eabe0d1102645033cbc82`。驗證開始與結束時的 checkout 均乾淨。驗證結束後再次向 GitHub 確認 dev 與原已審查 HEAD。
- 獨立 Tester 以全新實體 SwiftPM scratch 執行指定驗證。E025 test 7 項（10 案）、regression 21 項（39 案）、build 與 App 資源檢查、RivetPresentationTests 28 項（38 案）及根套件 661 項（81 suites）均通過。E025 原生執行檔 SHA-256 為 `1549dab53e1e87c7d6e5e7882efed5b6ae88c352c66ba2d48c3ee38a6f81b695`。
