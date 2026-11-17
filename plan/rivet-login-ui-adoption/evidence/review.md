# R01：獨立成果審查

- 日期：2026-11-17；owner=Reviewer；topic `rivet-login-ui-adoption`。
- 來源：feature 工作區尚未 commit，base `1f31b35604adb5bb36326e52f9d6dbcff0cac763`；不虛構 head SHA。
- **verdict: approved，僅放行 D01／D02 的 topic commit、push 與 Draft PR，之後停 Human review。**
- **Required fixes：無。** 未發現可定位的本 topic correctness／scope blocker；這不是 native UI、root 全套測試或最終 topic 接受通過。

## 審查範圍與依據

讀取四份 planning artifacts、I01／T01 evidence、正式 Login sources、一般 import content tests、E011 host／model 消費端、長期 UI／採用紀錄及 lifecycle r1；包含 untracked 新檔，未只看 tracked diff。未改 production／planning contract、未 stage／commit、未重跑 GUI 或測試。

- `RivetLoginView` 的 token-form 位於同一 conditional 分支；tokenEntry 與 token-origin failure 均組合相同 `LoginPATForm`，沒有以 phase／content／字級另加 identity。E011 Reset 的既有 parent identity 保留。
- PAT 編輯／Show-Hide／欄位焦點集中於 form；submit 經既有 `takeSubmission()` 取值即清除，空值不發事件；Back／disappear 清除，Create 有可用性 guard 且不清編輯。這些是 source 判讀，沒有取代 native 行為證據。
- Root 只依 parent phase 選區段並轉發 intents；子元件使用切片資料與回呼。焦點／宣告的 await 後檢查 cancellation 與 active 輸入，disappear 清除 active；未發現可定位的新時序錯誤，runtime 仍待驗。
- Public initializer 新增參數有預設值、callback 留末端；新增 enum case 的下游 exhaustive-switch 相容性影響已揭露。一般 import tests 證明舊／新呼叫可編譯；E011 既有 phase-intent switch 有 default，新增建立意圖不推進假流程。
- 正式 content 無展示／session 保存宣稱；E011 本地 `LoginDemoCopy` 消費同一正式元件。VO 對應符合既有 `.oauth`／`.pat`、PAT 本地建構及有限 Outcome，沒有 production mapper、認證、儲存或 session 接入。
- `Package.swift` 與受保護來源、舊 topic、E011 README、E013／E014、原 lifecycle JSON／HTML diff 為零。13 份 I01 列明的正式來源／測試 SHA 仍與受測 evidence 相符。新／改文字檔未見本機絕對路徑標記。
- 採用程度保留新版互動／接線的部分採用，不以文件存在或舊 Human pass 冒稱新版完成。九項分類與實際檔案範圍一致。

## 圖面

r1 spec 為 4216 bytes、SHA `cbe8f9ddf635ca045a0605af215ff7f9b13fa44132be96c93c1e9890c5056980`；HTML 為 704284 bytes、SHA `03b51e535c45e125b72c3484ef085b36f8f0d36374fe8b9abeb2ae7d4490c340`，均與 receipt 相符。Reviewer 另實看 r1 的 1440 Light 截圖，未見 clipping、錯誤回復方向或把 VO 對應畫成真認證接入；主 rail 與 side branches 可讀。未重新 render／deliver，不宣稱已獨立看完四張或 Human 視覺接受。自動 `visualReview: pending` 保留，作者實看與產品 VoiceOver 各自分列。

## 已知限制與交付分類

| 項目 | 分類與影響 |
| --- | --- |
| Root 全測試缺 `FakePATSecurity.delete(_:)` | 既有基線測試編譯阻擋；T01 親跑重現，protocol／test／Package bytes 等 base，與本 topic diff 無關。不要求越界修認證測試，可揭露於 Draft；不能稱 root suite pass。 |
| Focused 32 tests／7 suites、正式 Demo build、scoped format／lint | T01 獨立執行通過；支持 helper／content／model／編譯與有界靜態檢查，不支持真 SwiftUI control 互動。 |
| TC02／TC03／TC05 native gaps | CUA 窗口不可讀／probe aborted，沒有可定位產品 failure，也沒有 native pass。列為 Draft Human review checklist：PAT identity／清除／Show-Hide、選擇與鍵盤／Create 回呼、字級／七態／焦點時序。允許在明確揭露下交付 Draft，**不可據此合併或標最終 UI 已接受**。 |
| TC06 VoiceOver／最終 UI | Human pending；維持既有 Draft 後停點，不新增事前 approval，也不沿用舊版本接受。 |
| PR Lens／Graphify | Graphify 無可用 graph 的 source fallback 符合契約；PR Lens 由交付階段以實際 commit diff 本機製作，不是 correctness approval。 |

## 路由與後續

允許 D01／D02，前提是僅提交已審 topic 範圍，PR target=dev、保持 Draft，描述明列 root 編譯阻擋與 native 未驗 checklist，不 merge／tag／release。Delivery 記錄可補真實 commit／PR 與暫存 process 收尾事實，但不得回填 native pass、改寫 T01 incomplete 或擴張受審 source。

`current_step: R01 completed`；`next_step: D01`；`status: COMPLETE`（本輪有界獨立 review）；`verdict: approved`（僅 Draft 交付）。
