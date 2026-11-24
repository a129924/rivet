# GitHub 請求標頭步驟

最後更新 2026-11-24。基線 `dev` `b3e5428`，執行分支 `feat/github-request-headers-provider`。目前 phase 為交付，當前步驟 H06。獨立成果審查已核准。

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| H01 | completed | Plan-Creator | 四份同 slug 正式文件落地 | 本 topic requirements、technical-spec、plan 和 step。 |
| H02 | approved | Plan-Reviewer | 獨立審查四檔、九欄、授權和停止點 | 獨立 Plan-Reviewer 核對四檔、feature 基線及 Human 停點，無必修發現。 |
| H03 | completed | Implementer | 實作三個 production 組合、配置與 Factory，先驗證核心再接四處 | REST 基線 15 項通過。核心測試先因缺少需求型別編譯失敗，核心實作後 6 項通過。接線後 focused SwiftPM 119 項、12 suites 通過。 |
| H04 | completed | Tester | 獨立驗證 TC01–TC05、實際標頭與既有回歸 | 指定 SwiftPM filter 119 項、12 suites 通過。Swift 嚴格格式、專案 SwiftLint（184 檔）、topic SwiftLint（13 檔）與 diff check 均 exit 0。全樹裸 SwiftLint 511 筆均已核對基線。 |
| H05 | approved | Reviewer | 獨立審查程式、文件、測試證據與 topic 範圍 | 獨立 Reviewer 核對 20 個 topic 檔、三組標頭、Factory 衝突及認證邊界，無必修或重大問題。 |
| H06 | in-progress | Implementer | 記錄本機工具證據，核對 staged diff，依事前確認提交、推送及開 Draft PR | 預定訊息「feat(github-integration): 集中固定 GitHub 請求標頭」。提交雜湊、Draft PR 及依該差異產出的 PR Lens 結果見交付回報。 |
| H07 | pending | Human | 審閱 Draft PR 與有限證據 | 待使用者審閱。 |

## Blockers

目前無已知必須由使用者先決定的 blocker。

## 本機工具證據

Show Me 於對話計畫提供。Archify sequence 通過 showcase 9/9、零錯誤與警告，交付後通過四種桌面尺寸及明暗截圖目視檢查。Floorplan 副本涵蓋 542 個程式檔、7 個 topic 卡片，已在本機開啟。Graphify 0.9.73 使用 GRAPHIFY_NO_AUTO_REFRESH=1 核對，缺少既有圖時以限定原始碼查證。PR Lens 依提交後的實際差異產出。

## Human Check

使用者已明確確認實作無重大問題時，以一個 topic commit 推送並開 Draft PR。預先確認以 staged diff 語意單一且範圍相符為條件，提交前仍需記錄檢查和建議 message。條件不成立時於提交前交回 Human，條件成立時在 Draft PR 送出後停下等 Human review。本紀錄隨 topic commit 交付。Draft PR 與遠端狀態於實際送出後讀回，接著交給 Human 審閱。
