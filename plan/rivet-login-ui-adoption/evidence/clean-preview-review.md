# R04：乾淨 native preview 有界獨立審查

- 日期：2026-11-17；owner=Reviewer；topic `rivet-login-ui-adoption`。
- 來源：feature `feat/rivet-login-ui-adoption`，HEAD `a7a2fad277ada1dfaeed26d0fad6178c40123f03` ＋ I02 未 commit diff；不虛構新 SHA。
- **verdict: approved，僅限 I02 source／docs 的具體 topic commit／push／既有 Draft PR 更新。Required fixes：無。**
- 新 preview 的 native 執行仍停在 **Human 操作當下確認**；沒有啟動、單窗、AX、copy、事件或 Human 接受通過。HC01 最終 UI 接受 pending，不 merge。

## Source／contract／來源核對

讀取 I02 technical-spec／plan addendum、四份 artifacts、I02／T04 evidence、新 source／tests、main 分流與正式 #Preview 字串差異。沒有重做全專案 review、沒有執行 GUI／app／CUA／launch workaround、沒有重跑 tests／build，也未修改 production 或既有歷史。

- `LoginPreviewHost` 直接組合既有 `RivetLoginView(content: .standard)`；只持有一個 NSWindow，start 重入只帶回既有窗，close 結束 app。主入口以 `withExtendedLifetime` 保持 delegate／host，保留標準原生 Quit／Edit，沒有 Controls、overlay、事件計數、測試選單或 timer。
- Preview parent 重用既有 `LoginDemoModel`，只在初始化 `show` 選定 phase，再由相同 fake callbacks 回應。沒有 `completeSimulation`／`simulateReturn` 自動呼叫，也沒有 request／VO／認證 service／儲存／session；等待／驗證不自動成功。
- Footer 與兩種 failure 明確由 host／configuration 提供中性文字，不誤稱來自 `.standard`。正式 #Preview 僅改 footer／failure 字串；原 DemoHost／Controls／LoginDemoCopy 未搬入 preview，也未改寫其來源。
- 同一 executable 的 `--preview` 交由固定 parser；八個 state、system／light／dark 及有限 13...21 字級符合契約。缺值、未知／重複選項與不合法字級在 NSApplication／建窗前丟錯；main 輸出 usage、exit2。一般 executable 無 preview flag 仍走原 Demo；獨立 preview bundle ID 在無 flag 時加入 preview，避免直接 open 誤入展示入口。這些是 source／configuration 判讀，不宣稱已經 native 觀察。
- I02 列明 18 份來源／基線 hash 全部符合；其中正式 View／content／components／intents、Package／Resolved、原 DemoHost／Model 共13檔逐 bytes 等同 `a7a2fad`。受保護 E011 README、T02／T03／R02／R03 與凍結 lifecycle 路徑無 diff。新／改文字未見本機絕對路徑標記。

## 具體待啟動物的來源

只讀檢查 `.build/clean-preview-i02/RivetLoginPreview.app/Contents/Info.plist`：bundle ID `local.rivet.login-ui-preview`，executable `RivetLoginDemo`，Name／DisplayName=`Rivet`。Wrapper binary 逐 bytes 等同正式 `.build/debug/RivetLoginDemo`，SHA-256 為 `4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`，2541888 bytes，與 I02／T04 相符。

此核對使 source／待啟動物可具體追溯，**不撤銷、不繞過 automatic approval review 的 action 拒絕，也不是新的啟動授權**。若待啟動 binary 之後改變，須重新標明實際 bytes 與來源。

## T04 證據與 blocker 分類

| 項目 | 判斷與交付影響 |
| --- | --- |
| 15tests／3suites、正式 product build、5檔 strict format／lint、diff-check | T04 獨立親跑 exit0，支持 parser／配置、public content、fake model 與編譯／靜態差異。Reviewer未再跑，不當作 native 控制／窗口證據。 |
| 唯一 exact wrapper CUA 啟動被拒 | T04 保存 `This action was rejected due to unacceptable risk.`；理由要求在操作當下取得確認。這是 action authorization blocker，非 app crash 或已觀測到的 source defect；沒有新 PID／AX／screenshot，不重試或換 CLI／間接執行。 |
| 新 clean preview native coverage | 單窗／無展示文案、Welcome 預設路由、必要 callbacks、Dark21 failure／completed 及 Welcome 留開皆未驗。Source/docs 可具體交付，但 native 部分必須待 Human 當下確認後才補驗，不能稱已恢復或已接受。 |
| T02／T03／H01–H08 與 HC01 | 原受測來源、成功／無效嘗試及限制保留；不以新拒絕推翻舊證據，也不將舊證據外推為新 preview native pass。HC01 最終 Human 視覺／UI 接受仍 pending。 |

## 路由

允許依既有 Human 授權提交／推送本次已審 source/docs 並更新 Draft #75，揭露 T04 native blocked 與待確認項。然後停在 Human 操作當下 native 啟動確認，不能藉 commit、source review 或舊授權自動重試；主對話應對 exact wrapper 與已核對 binary 作具體確認。取得確認後的 bounded native 補驗仍需實際證據；不跨最終接受、不 merge。

`current_step: R04 completed`；`next_step: 既有 topic source/docs 交付，native 啟動停 HC01 當下確認`；`status: COMPLETE`（有界 source／contract／evidence review）；`verdict: approved`（受限交付，native 未批准／未驗）。
