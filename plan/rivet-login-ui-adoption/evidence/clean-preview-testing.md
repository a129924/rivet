# T04：乾淨原生 preview 差異驗證

- 日期：2026-11-17；owner=獨立 Tester；topic `rivet-login-ui-adoption`。
- 來源：feature branch `feat/rivet-login-ui-adoption`，HEAD `a7a2fad277ada1dfaeed26d0fad6178c40123f03` ＋ I02 未 commit diff；不虛構新 SHA。
- 結果：**INCOMPLETE（native coverage）**。自動差異檢查通過；原生啟動被 automatic approval review 拒絕，沒有新 native pass。交 R04 分類，不給 correctness approval。
- 保留 T02、T03、H01–H08、R02、R03 的原來源與限制，不重做或推翻；HC01 最終 Human 視覺／UI 接受仍 pending，沒有 merge。

## 獨立自動檢查

使用正式 root manifest、既有 cache 與正常 SwiftPM sandbox；不使用 `--disable-sandbox`，沒有依賴更新／新下載。兩次 SwiftPM 命令都使用下列旗標：

```text
--skip-update --disable-automatic-resolution --disable-keychain --disable-netrc
```

命令環境以 `GIT_CONFIG_COUNT=2` 將 `protocol.https.allow` 與 `protocol.http.allow` 設為 `never`；未改 HOME 或全域設定。`--skip-update` 的 deprecated warning 不當作失敗。

| 實際命令 | 結果 |
| --- | --- |
| `swift test <上述flags> --filter 'LoginPreviewConfigurationTests|LoginDemoModelTests|RivetLoginContentTests'` | exit 0；15 tests／3 suites，0.003s；新 configuration、原 Demo routing、正式 content 覆蓋 |
| `swift build <上述flags> --product RivetLoginDemo` | exit 0；0.25s；正式 product |
| `swift format lint --strict <本次5個Swift檔>` | exit 0，無診斷 |
| `swiftlint lint --strict --no-cache <本次5個Swift檔>` | exit 0，5 files，0 violations／0 serious |
| `git diff --check` | exit 0 |

五檔為：`RivetLoginView+Previews.swift`、E011 `main.swift`、`LoginPreviewConfiguration.swift`、`LoginPreviewHost.swift`、`LoginPreviewConfigurationTests.swift`。沒有重跑不相關全套 361 tests，也沒有重產 lifecycle。

八種 scene 對應、12 組無效參數、合法字級與 copy／fake callbacks 是配置／model／content 的測試證據，不取代 native 呈現或 Human 接受。

## 核心與包裝來源核對

以下13檔逐 bytes 等同 HEAD `a7a2fad`：正式 `LoginMethodSelection`、`LoginOAuthSection`、`LoginPATForm`、`LoginStatusNotice`、`LoginStyles`、`RivetLoginArtwork`、`RivetLoginContent`、`RivetLoginPresentation`、`RivetLoginView`；`Package.swift`／`Package.resolved`；E011 `LoginDemoHost`／`LoginDemoModel`。既有正式核心、依賴、原展示 copy／model 未改。

獨立 wrapper 為 feature 內 ignored 路徑 `.build/clean-preview-i02/RivetLoginPreview.app`：

- CFBundleIdentifier=`local.rivet.login-ui-preview`；CFBundleExecutable=`RivetLoginDemo`；CFBundleName／DisplayName=`Rivet`。
- wrapper binary SHA-256=`4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`；核對時與正式 `.build/debug/RivetLoginDemo` bytes 相同。
- 讀取實際入口確認該 bundle ID 無 args 時加入 `--preview`；原 executable 無此 bundle ID／無 `--preview` 仍走原 Demo。
- 讀取實際 host 確認只使用 `RivetLoginView(content: .standard)`、中性 footer／failure、單窗設定與一般 Quit／Edit menu。這是 source 證據，不宣稱原生窗口已親驗。

## Native 權限拒絕：實際觀察

先以 CUA inventory 確認沒有執行中的 `local.rivet.login-ui-preview`；原 `RivetLoginDemo` 與外部 native fixture 存在，未操作或停止它們。

唯一啟動嘗試：工具 `mcp__cua_repl.js`，action 為 `cua.getApp`，target 為上述 exact feature wrapper（不附 args，原定驗證預設 clean Welcome）。

自動審查回覆原文：

> This action was rejected due to unacceptable risk.
> Reason: 此動作會啟動 feature worktree 產出的本機應用程式；雖然使用者已授權 clean preview，但依電腦使用政策，執行未明確驗證來源的軟體仍需在操作當下取得確認。

工具另明確要求不得以 workaround 或 indirect execution 繞過拒絕。Tester 未改用 CLI／raw executable、未重試啟動，也未操作其他 app。CUA completion summary「已記錄預覽啟動待確認」已成功送出。

此為 action approval 拒絕，不能歸類成 app crash、窗口 bug 或 native pass。沒有取得 preview PID、AX tree、screenshot 或實際 UI 狀態，不能宣稱已恢復 Welcome／Light13 或已留開供 Human。

## Coverage 與後續

| 項目 | 本輪證據／缺口 |
| --- | --- |
| 新 CLI／configuration／原 Demo route | 最小 tests 通過；原 Demo source bytes 未改 |
| `.standard` 與中性 footer／failure | content／configuration 測試與 source 核對通過；native copy 未親看 |
| 無 args clean 單窗、品牌／GitHub 資源、無 Controls／overlay／測試 menu | 啟動被拒，native 未驗；只保留 source 設定證據 |
| Welcome→waiting→Escape→PAT→submit 驗證中 | 未操作，不能宣稱 fake callbacks native pass |
| Dark21 token failure、browser failure、completed | configuration 測試覆蓋；native 未驗 |
| Welcome／Light13 留開 | 未完成，需 Human 操作當下確認後以 exact wrapper 啟動並觀測 |
| T02／T03／H01–H08 | 原結果保留，不用本輪拒絕推翻，亦不外推為 clean preview 已接受 |

自動檢查與來源核對已足以交 R04 審查；原生部分待主對話依自動審查要求取得 Human 操作當下確認，再安排 bounded T04 補驗。沒有新增權限流程或將未知標 pass，HC01 最終接受維持 pending。

所有 raw command logs／exit codes 保留 repository 外 T04 topic scratch；本文件只用相對路徑。exec session `75955` 已正常 exit 0，沒有本輪尚在執行的 unified exec session；本輪沒有啟動新 preview process，沒有停止原 Demo／fixture。

`current_step: T04 coverage INCOMPLETE`；`next_step: R04 獨立審查已取得結果及 native 待確認限制`；`status: INCOMPLETE`。
