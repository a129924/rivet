# Login UI 元件化與選擇性採用需求

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
