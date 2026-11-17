# Login UI 元件化與選擇性採用計畫

- Topic：`rivet-login-ui-adoption`
- 日期：2026-11-17
- Branch：`feat/rivet-login-ui-adoption`
- Base：`origin/dev`／`1f31b35604adb5bb36326e52f9d6dbcff0cac763`
- Human 已接受對話方案並授權受限實作、無重大問題時 topic commit／push／Draft PR；本文件尚待獨立 Plan-Reviewer。

## Goal

以既有正式 Login 為基礎，選擇性採用已驗證能力，交付可組合 SwiftUI 元件、呈現模型、局部狀態及 callbacks，移除正式來源展示耦合。文件記錄既有 VO 對應，實際外層協調留後續。規格以 [technical-spec](../../analysis/rivet-login-ui-adoption/technical-spec.md) 的元件表、公開 initializer／content schema、狀態及 VO 對應為受限契約。

## Non-Goal

不重建品牌／布局／七態或登入 VO，不交付真實認證、request 建構、service 呼叫、認證 async／取消管理、production mapper／Adapter、儲存、session／clients、產品 App 整合。不擴 BC、package／target 或整個專案架構盤點。

## In-Scope

- Internal LoginMethodSelection、LoginOAuthSection、LoginPATForm、LoginStatusNotice 與公開 RivetLoginView 組合；不碎片化每個 label／button。
- Parent-owned phase、局部 form／focus state、既有六個 intent 與新增 createPersonalAccessToken；content 模型與相容 initializer。
- E011 同正式元件加 fake inputs／events，相關測試、採用紀錄與長期 UI／入口摘要。
- 文件層 UI／VO 對應與 UI lifecycle v2；Graphify 有界導航及 PR Lens 實際 diff 理解輔助。

## Out-Of-Scope

OAuth／PAT concrete service、真 VO／service runtime 接入、browser／network／Keychain／DPK、session／clients、production mapper／Adapter、E013／E014 搬移、舊 topic 證據改寫、系統架構重畫、merge／release／發布。

## 檔案操作範圍

`Written` 是新增檔案，`Modify` 是修改既有檔，`Deleted` 是整檔刪除。移除重複 View 片段不等於刪檔。

| 標籤 | 受限範圍 |
| --- | --- |
| ReadOnly | Package.swift；設計原則；GitHubIntegration 既有來源／長期契約；原型；舊 rivet-login-ui analysis／plan／驗收；E011 README；E013／E014；舊凍結 lifecycle 圖；既有 graph、工具規範與 PR Lens config |
| Written | Sources/Presentation/Login/ 下的 LoginMethodSelection.swift、LoginOAuthSection.swift、LoginPATForm.swift、LoginStatusNotice.swift、RivetLoginContent.swift 及必要 LoginStyles.swift；Tests/RivetPresentationTests/ 的元件行為測試；本 topic 四 artifacts；docs/feasibility-adoption.md；原 UI 圖目錄下 lifecycle v2 規格／HTML／凍結快照／receipt／視覺 sidecars |
| Modify | RivetLoginView.swift、RivetLoginPresentation.swift；受影響正式 Login 測試；E011 host／model／tests；docs/presentation/login-ui.md；README.md／docs/architecture/README.md 中相關過期摘要；圖面 BUILD.md 及現行文件連結 |
| Deleted | 無 |

不改 Package.swift，不需新 target。E011 README、舊 topic 與舊凍結圖只讀；v2 為後繼版本，不覆寫舊 bytes。PR Lens graph／render 只放 repository 外 topic scratch。計畫允許的證據寫入限本 topic plan 目錄與列明圖目錄；不另設必要 summary／release artifact。

## 採用與實作順序

1. 以 requirements 的有界 audit 為基線，重用正式 phase／intents／PAT helper／字級／品牌／資源；只調整本次必要能力。既有依賴已滿足，不等待認證服務。
2. 先更新長期 UI 契約及相關過期摘要，保留舊來源／限制；按 technical-spec 拆分責任元件與呈現模型，維持40:60穩定布局、七態、表單 identity 與 focus 取消保護。
3. 新增 createPersonalAccessToken intent、content／canCreateToken 預設參數；更新 exhaustive switch 與 E011 消費端。View 不持 URL／開 browser；E011 本地提供 demo content 與 fake events，不呼真 VO／service。
4. 保存新版有界行為證據與圖面 receipts，更新獨立 adoption record；所有程度依實際證據判定，不因計畫已核准標為已採用。
5. 交獨立 Tester、Reviewer；沒有重大問題時由獲授權 Implementer 完成 topic commit／push／Draft PR，停 Human review。

## TestCase

| ID | 驗證情境與接受條件 |
| --- | --- |
| TC01 | 舊 initializer／trailing closure 可編譯，新增 public data 可由一般 consumer 使用；七態與新增 intent 的消費端完整 |
| TC02 | PAT 外圍 trim、保內部空白、空值不送、送出即清／隱藏、Show／Hide、failure 重填、離開／Reset 清除；字級／content 更新不重建 form |
| TC03 | GitHub／PAT 選擇、Back、Cancel／Escape、Retry、Submit 事件正確；create 停用不發事件、啟用只發一次且不清輸入 |
| TC04 | Parent phase 不被 View 自改；E011 fake inputs／events 驗介面，無 GitHubIntegration import、request 建構、service 或 Outcome mapper |
| TC05 | 七態與兩種 failure origin、Light／Dark、780×500、13／17／21 pt 操作可捲動到達；快速切態／離開不發過期焦點／宣告 |
| TC06 | Human VoiceOver 聲音與最終 UI 接受；可 pending 交付 Draft，不能以舊結果或自動檢查冒稱新版通過 |
| TC07 | 正式 Presentation／E011 tests、root Swift tests、Demo build、受影響 Swift format／lint；既有無關 findings 分列，不稱全域通過 |
| TC08 | 文件 VO 對應與實碼一致；Outcome 不被當成完整 phase／session，connected 只表示本次登入完成 |
| TC09 | Archify v2 showcase／deliver／四尺寸 visual-check 證據完整，人工檢視截圖與 pending 狀態分列；PR Lens 如可用須對應真 diff |

保留既有有效測試，新增測試覆蓋行為與接線，不以重複資料欄位斷言代替互動驗證。沒有執行或環境受限的檢查明列，交 Reviewer 判斷是否重大問題；不得自稱通過。

## 工具節點與 fallback

### Graphify

只用 pinned graphifyy 0.9.73；每次 CLI invocation 均有 `GRAPHIFY_NO_AUTO_REFRESH=1`。只對存在且可確認來源 revision 的 graph 執行 bounded query／path／explain，query budget 1500，重要關係再查 source。基線標準 graphify-out/graph.json 不存在，使用 targeted source reads，不建立 graph。Runtime 缺失／不相容、graph 過期或 query 失敗，記具體限制回原始碼；不 install／extract／refresh／provider／upload／hook／config。

### Archify

限現有 UI lifecycle v2，不擴為系統架構，不把文件層 VO 對應畫成已接線 runtime。作者繁中，Viewer UI／HTML lang 英文 fallback，不發布。讀 lifecycle／common schema，作者 JSON 後 showcase validate 全部9checks／0errors／0warnings；deliver 凍結 exact spec bytes 並保存 receipts，再用 repo-root visual-check 四桌面尺寸並人工看截圖。pending／skipped／非零不稱 pass；只修診斷項，連續兩輪未改善則停止圖面接受並回報未解診斷。不得手改已交付 HTML。

### PR Lens

只有實際 base／head 或有界 diff 後才根據 `git diff --find-renames` 做 local change map，記真 SHA 與未commit狀態、不造 head。包含相關 unchanged 鄰居與 file refs。只用 pinned CLI0.11.0 validate／render，產物在 repository 外 topic scratch。存在 .github/pr-lens.yml 時先讀並套用，無適用 config 才 --no-config；基線該檔不存在。不改 repository config／.pr-lens／.gitignore，不上傳、發布或開server。工具／map失敗或增加閱讀負擔時記限制、回直接diff review；map不是correctness review。本輪尚無實作diff，不產假map。

## 採用紀錄與完成判斷

docs/feasibility-adoption.md 各能力記來源版本與來源關係、正式需求、適用條件、選定／排除理由、必要依賴及滿足方式、採用方式、程度、正式位置／實際消費端接入、行為證據、缺口、觀察日期與歷次更新。程度與重用／調整／重寫／不採用分欄；缺tracker不當未採用證據。LU-A04在新版實作、接入與行為證據未齊前維持部分採用；Human聲音／最終UI接受未驗明記pending，不等於實作或UI已全面接受。

## Review、Git 與停點

四 artifacts 落盤後先交獨立 Plan-Reviewer 明示 approved，才可實作；其後 Implementer→Tester→獨立 Reviewer。Plan-Creator 不自審也不實作。

Human 已明確授權：本 topic 沒有重大問題時直接 commit→push→Draft PR→Human review，不重問相同授權。Commit 前仍依 git-commit-convention 從 staged diff 檢查單一 topic 語意邊界與 message，僅納入本 topic；PR target=dev，維持 Draft。Human VoiceOver／最終 UI 接受 pending 本身不阻擋 Draft，但描述必須揭露未驗與證據限制。若有 required fix／重大問題、未解scope或權限邊界，停止相依動作；不merge、tag、release或發布。

- [需求](../../analysis/rivet-login-ui-adoption/requirements.md)
- [技術規格](../../analysis/rivet-login-ui-adoption/technical-spec.md)
- [執行帳本](rivet-login-ui-adoption.step.md)
