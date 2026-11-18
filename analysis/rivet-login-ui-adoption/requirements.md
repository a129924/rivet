# Login UI 元件化與選擇性採用需求

> 現行契約：本文件末段「R3：2026-11-18 E011 凍結與驗收歸屬修訂」優先適用於本輪。前文原規劃及 I01／I02 授權、實作與驗收保留為其版本歷史；不得以本輪要求倒推原作業越權，也不得把舊驗收直接套給新 host。

- Topic：`rivet-login-ui-adoption`
- 日期：2026-11-17
- Branch：`feat/rivet-login-ui-adoption`
- 基線：`origin/dev`，`1f31b35604adb5bb36326e52f9d6dbcff0cac763`
- 狀態：Human 已接受本次方案並授權受限實作；正式 planning review 尚待獨立 Plan-Reviewer。

## Goal

將既有正式 Login View 整理為可組合、可接線的 SwiftUI 元件，交付呈現模型、局部 UI 狀態及事件回呼。先查核正式與驗證來源，只採必要能力，不重建等效實作、不整套搬移驗證工具。正式元件脫離展示耦合，E011 繼續以同一元件加 fake inputs／events 展示。

## Non-Goal

不交付真實登入、production mapper／adapter、認證服務、憑證儲存、session／clients 或產品 App 整合。不建構登入 request、不呼叫登入 service、不管理認證 Task，不重建登入 VO。不重新設計已接受的品牌、40:60 雙欄與七態。

## Human 已鎖定的範圍

- 本次是正式 UI 元件化，不是端到端真實登入。
- 依職責拆分登入方式選擇、OAuth 區、PAT 表單與狀態提示，避免逐 label／button 碎片化。
- Parent 擁有流程 phase；子元件只擁有必要局部 UI 狀態並發事件。
- `RivetPresentation` 不直接依賴 `GitHubIntegration`。UI 與既有 VO 的關係只寫入文件，真正外層協調／Adapter 留後續 topic。
- 既有登入 VO 與長期 GitHubIntegration 契約唯讀，不自行修改或重建。
- `LoginOutcome` 不能單獨推導全部 UI phase；成功不代表 session／clients 建立。

## 有界採用 audit

觀察日期為 2026-11-17，正式快照為上述基線。涵蓋正式 Presentation、E011、相關測試、舊 UI 驗收及既有雙登入契約；E013／E014 僅查責任界線，不宣稱全專案盤點。下列 LU-A 識別是本輪補建，不冒充歷史識別、不回寫實驗歷史。

| 識別 | 能力 | 現況程度 | 採用方式／缺口 |
| --- | --- | --- | --- |
| LU-A01 | 品牌、40:60 雙欄、七態、資源 | 已採用，限原 UI 契約 | 重用正式元件與資源，不重建等效能力 |
| LU-A02 | PAT 編輯、Show／Hide、清除、字級 | 已採用，限原受測範圍 | 抽取調整，將局部狀態移至 PAT form，須新版回歸 |
| LU-A03 | 鍵盤焦點、accessibility、快速離開保護 | 已採用，限原受測版本／案例 | 抽取調整；舊聲音與時序證據不能替代新版驗收 |
| LU-A04 | 正式文案與接線介面 | 部分採用 | phase／callback 已有；正式 View 仍含展示硬字串及固定停用入口，本次補足 |
| LU-A05 | E011 host、Controls、假流程 | 本次已排除正式採用 | 留在 E011 作受控消費端，不搬入正式來源 |
| LU-A06 | E013／E014 認證與診斷工具 | 本次已排除 | 不屬本次 UI 需求及依賴 |

### 來源與限制

- 正式 View 來源版本：`dcc48b29686ab324fc19399ef607f462a507cce5`。
- E011 收納版本：`7e5f4fd44c64a956ed133096939d42f37de4ff2f`；收納沒有撤回正式 UI 採用。
- 正式接入：`Sources/Presentation/Login/`；`Package.swift` 的 `RivetPresentation` target 目前無 BC／認證依賴。
- 舊 Human 接受：`plan/rivet-login-ui/evidence/verification.md:683–689`，原帳本記錄 Human review passed。
- PAT／字級 helper 的正式測試位於 `Tests/RivetPresentationTests/RivetLoginPresentationTests.swift`。
- 既有 VO 實碼：`Sources/BoundedContexts/GitHubIntegration/Contracts/LoginAuthentication.swift`；長期契約：`docs/architecture/github-dual-login-contract.md`。
- 部分 README／長期 UI 摘要落後於舊 Human 接受紀錄，本次只校正相關現況，不追改原 topic 證據。
- 舊證據僅支持原受測版本／案例；本次重構後仍須新版驗收。沒有既有 adoption tracker 不構成未採用證據。

## 成功條件

1. 正式元件按互動責任組合，保持原布局、七態與既有六個 intent 語義。
2. 正式預設內容不含 simulated、Demo Controls 或 example-only；E011 透過自身內容資料繼續呈現展示限制。
3. PAT form、焦點與狀態宣告保有既有行為；新增 PAT 建立 intent 只發 callback，不開 browser。
4. 舊 initializer 呼叫語法可編譯；呈現模型、依賴及文件層 VO 對應明確。
5. 受控測試、必要原生操作、圖面驗證與獨立 code review 有可追溯證據；未驗證項保持 pending。
6. 採用紀錄分開程度與方式，LU-A04 只有正式實作、消費端接入及對應行為證據齊備才可升為已採用。

## 授權與交付邊界

Human 已接受方案，授權依既有流程實作；沒有重大問題時直接完成本 topic commit、push、Draft PR，交 Human review。這是本 topic 的直接授權，仍須依 staged diff 套用 git-commit-convention 並保留語意邊界，不擴張到其他 topic。

原生 Human VoiceOver／最終 UI 接受 pending 不阻擋已授權 Draft 交付，但不能記成通過。未授權 merge、tag、release 或正式發布；認證／憑證／session 範圍仍排除。

## 文件關係

- [技術規格](technical-spec.md)
- [受限計畫](../../plan/rivet-login-ui-adoption/rivet-login-ui-adoption.plan.md)
- [執行帳本](../../plan/rivet-login-ui-adoption/rivet-login-ui-adoption.step.md)


## R3：2026-11-18 E011 凍結與驗收歸屬修訂

### 現行 Goal 與 In-Scope

只保留本 topic 已交付的正式 Login 能力／公開 API／content／child 行為，不重建元件或登入 VO。E011 回到有來源證據的凍結版本；正式能力改由直接正式測試、受控 #Preview 優先驗證，只有原生視窗／選單／Return／Escape／focus／Human VoiceOver 的必要差異使用 tools/acceptance/login-ui 最小 host。

- 本輪 preflight：feature HEAD `44ddbeea6235e9b785b41a9f787c92f52aa85eaf`，PR／local／tracking 一致；當前 PR base/dev 為 `d2332bfff25510a3f78c1fbc8b0d2d9cf953b223`。這是本輪起始快照，不改寫原查核基線。
- E011 freeze 選 d2332bfff25510a3f78c1fbc8b0d2d9cf953b223，tree=`b6a1e6e1196e64999af9591ec32f09211f1936c6`；7e5f4fd、1f31b35、ab77391、d233 四個已查基線的 E011 tree 相同。不是任選舊版。
- 本輪起始 HEAD 的 E011 tree=`a1fd3793fecdccf52c192158939629b58ca7c685`；只允許 plan R3 列出的三檔逐項回復及三個本 PR 新檔移除，之後整棵 E011 tree 須等於 freeze。tree 比對是驗證，不是整目錄覆寫命令。
- 正式 root Package.swift 在兩版的 blob 同為 `af69162fa848074fe62c9a4fd8d4056e3e3c6102`，root Package.resolved／gitignore／設定唯讀。

### 現行 Non-Goal 與 Out-Of-Scope

不繼續擴充 E011 host/model/fixtures/tests，不依賴 LoginDemoModel，不加 fake Service／DI，不 copy 正式 View 或登入 VO，不新增正式 public harness API。不接認證、儲存、session／navigation。新 package 只屬 acceptance tool，不改 root product/package/target。若 root readonly 設定確需變更，須先提出具體最小 proposal；先完成不依賴該變更的工作，不自行改設定或 install／refresh／升級依賴。

### 無法同時成立的四約束

Frozen host 不傳 content；正式 initializer 預設 `.standard`、新增參數有預設，舊呼叫預期語法相容；model switch 有 default 可處理未識別 intent。但 `.standard` 現為產品文案，因此「E011 source 凍結／formal .standard／不加 formal demo mode／HEAD 重建舊 Demo 語意逐字不變」不能全滿足。

採最小處理：正式 `.standard` 及無 demo mode 保持，E011 是歷史 source，不再作本輪正式驗收入口。不加入 footer／bundle 偵測或 legacy default demo，不宣稱 HEAD 重建等效。若要歷史原貌，只能引用完整 freeze revision 或既有 binary；本輪不重播。若 Human 再要求逐字歷史重播，另提具體方案，不自改 readonly 設定。

### 採用程度、歷史與新驗收

LU-A01–04 正式能力與既有來源關係保持；本輪是驗收 consumer／ownership 修正，不抹去已採用證據，也不因新 host 存在宣稱新 host 已驗收。LU-A05 改為凍結歷史工具，不再作本輪消費端；本輪新增 acceptance tool 是驗證素材，不是新產品能力。程度與方式／來源分開記錄。

HC01 completed 保留：Human 接受來源 `3c9baf3d1cebfb58f3356ea8c9ab4d29a09fc26b`、preview source `42e99faca1048c1278a498f2a1a147f2afdb5240`、binary SHA-256 `4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`。這不授權或證明新 binary 啟動／新 host 接受。原 I01／I02、T01–T05／R01–R05、H01–H08 與失敗／拒絕／pending 歷史不刪改。

本輪只補受影響的 controller/config/host/resources/window/focus/callback 及新 Preview 連續切態。正式 core bytes 不變的舊 tests 是歷史證據，不直接稱新 host pass。新 host 的必要 Human VoiceOver 受影響案例保留新停點；先 build／獨立 review，再提出 exact app/source/binary SHA 與案例，取得原生工具所需當下確認後才啟動。

### 本輪成功條件與交付

1. E011 六項操作有明確 base/blob 證據，整棵 tree 等 freeze；未碰 model／README 等未變檔，root manifests/locks/settings 未變。
2. 正式 Login API/content/核心 child bytes 保留；直接正式 tests／test-private fixture/spy 與 controlled #Preview 不依賴 E011，能有限回寫 phase、只記 event kind／次數，不保存 token。
3. Preview／必要 host 在同 form identity 下更新字級／content；明確 Reset 才可換 identity。固定 phase／ignoreIntent 不當互動證據。
4. tools/acceptance/login-ui 只以 path 依賴 root RivetPresentation product，自有有限 parent/config/fixtures/window/menu/tests；乾淨主畫面預設 .standard、中性 footer/failure，無 auth/task/timer/storage/session/nav。
5. 新版獨立驗證／review／Human 待驗界線及 actual source/binary/gaps 如實記錄，不擴成產品登入整合完成。
6. 原直接 topic commit／push／Draft PR 授權持續有效；仍無 PR merge 授權。Human 新 binary／受影響 VoiceOver 停點與可 Draft 的 source/docs 邊界分開，不抹去未驗。
