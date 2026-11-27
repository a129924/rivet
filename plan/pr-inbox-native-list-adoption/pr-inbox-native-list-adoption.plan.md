# I2 正式採用原生 Inbox 清單執行計畫

Topic `pr-inbox-native-list-adoption`。分支 `feat/pr-inbox-native-list-adoption`。由 `dev` 的 `3468eaa` 建立獨立功能工作樹。執行及驗證均在功能工作樹或其隔離副本。 [需求](../../analysis/pr-inbox-native-list-adoption/requirements.md) · [技術規格](../../analysis/pr-inbox-native-list-adoption/technical-spec.md) · [步驟帳本](pr-inbox-native-list-adoption.step.md)

## Goal

正式 `RivetPresentation` 原生清單呈現四個 PR 欄位，開發者能辨識載入中、成功零筆、讀取失敗及資料可能非最新。以接入後的 E025 原生受控案例與既有 Presentation 回歸驗收。

## Non-Goal

沿用 Variant B、macOS 原生互動、PR Inbox 候選及來源順序。完整分頁、查詢失敗及 OAuth 工作階段沿用現有責任。

## In-Scope

正式列支援缺作者與缺時間，完整欄位介面相容。提供共用狀態呈現並接入 E025。E025 呼叫端保有查詢、OAuth、選取、焦點、fixture、分頁暫停及驗收紀錄。重排與改名保留有效 PR，移除時回首列，完整零筆時清除選取。等待及錯誤依完整快照呈現。以 E024 涵蓋既有完整欄位與 Open intent 回歸。

## Out-Of-Scope

正式 App 主視窗、登入及 OAuth 變更、Reader 或 repository 導覽、App menu、離線與復原策略、PR Inbox 或其他 BC 的業務及基礎設施變更、I3 欄位及篩選。真人證據沿用 I2-07。

## ReadOnly

- `Package.swift`
- `Package.resolved`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/native-interaction-contract.md`
- `Sources/Presentation/PRInbox/InboxWorkspace.swift`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Tests/RivetPresentationTests/PullRequestListTests.swift`
- `experiments/E024/README.md`
- `experiments/E024/Sources/InboxI1Verification/InboxWindow.swift`
- `experiments/E025/Package.swift`
- `experiments/E025/Package.resolved`
- `experiments/E025/Sources/InboxI2Verification/FixtureREST.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxQuery.swift`
- `experiments/E025/Sources/InboxI2Verification/LiveConnection.swift`
- `experiments/E025/scripts/verify.sh`
- `experiments/E025/evidence/acceptance.md`
- `experiments/E025/evidence/i2-07-live.md`

## Written

- `analysis/pr-inbox-native-list-adoption/requirements.md`
- `analysis/pr-inbox-native-list-adoption/technical-spec.md`
- `plan/pr-inbox-native-list-adoption/pr-inbox-native-list-adoption.plan.md`
- `plan/pr-inbox-native-list-adoption/pr-inbox-native-list-adoption.step.md`
- `Sources/Presentation/PRInbox/InboxListStatus.swift`
- `experiments/E025/evidence/native-list-adoption.md`

## Deleted

None。

## Modify

- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxSession.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxVerificationWindow.swift`
- `experiments/E025/Tests/InboxI2VerificationTests/InboxSessionTests.swift`
- `experiments/E025/README.md`
- `docs/presentation/pr-inbox-visual-adoption.md`

## TestCase

| ID | 情境 | 結果與證據 | 追溯 |
| --- | --- | --- | --- |
| NLA-01 | 候選清單在 940 pt 及 420 pt | 四個欄位可掃讀，保有緊湊列距與原生選取，合格 Draft 依來源順序入列。保存實測寬度、畫面及 Accessibility。 | I2-01、06；AC-NI-014、016、017 |
| NLA-02 | 選 `sample/ui #42`，重排、改名、移除，再更新至空 | 重排或改名仍選同一筆，移除後選 `sample/core #42`，完整結果零筆時清除選取。核對 Session 測試與原生選取。 | I2-02、03；F-01、UIIR-NI-003、AC-NI-009 |
| NLA-03 | 首載、首次成功零筆、更新後成功零筆 | 首載有進度，零筆有成功空狀態且無可操作列。原焦點目標失效時落到適用的狀態標題。記錄畫面及焦點。 | I2-03；§4、§10、AC-NI-026 |
| NLA-04 | 首次失敗、更新失敗、有或無舊列的第二頁等待與失敗 | 首次錯誤無列。完整可讀舊列及有效選取保留，失敗後標示可能非最新。第二頁暫停與失敗後均無 `sample/partial #91`。核對暫停點、畫面及 Accessibility。 | I2-04、05；§4、§10、AC-NI-009、026 |
| NLA-05 | 作者與時間皆有、僅作者、僅時間、皆缺 | 完整輸入沿用原呈現，缺值在寬版也無占位或孤立分隔點，VoiceOver 保留標題與 PR 識別。核對 Row 測試與原生朗讀。 | I2-06；§8、§10、AC-NI-016、017 |
| NLA-06 | E025 原生選取及 E024 既有完整欄位呼叫端 | 鍵盤選取、焦點切換及視窗失活後恢復符合既有行為。E024 合法 Enter 或雙擊各輸出一次正確 ID 的 Open intent，失焦、失效或不可開啟時無事件。核對原生事件及正式 List 測試。 | §3、§6、§7；AC-NI-011、014、036 |

## 實作與審查工具

| 工具 | 用途和證據 |
| --- | --- |
| Graphify | 實作前依現有本機圖的來源版本做有界查詢，每次呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。重要關係回讀原碼。沒有適用圖或資料缺漏時以原碼核對，記錄限制。 |
| Archify | 接線後以實際程式繪製繁中 sequence，涵蓋完整結果、分頁等待與失敗保留舊列。以 `showcase` 檢查九項驗證，使用 `deliver`、`visual-check` 並檢視截圖。Viewer UI 採英文 fallback。 |
| PR Lens | 審查前以實際 base/head 或涵蓋新增檔的有界 diff 畫本機變更圖，保留正式 List、Workspace 及 PR Inbox Facade 等鄰接元件。用固定版本 CLI 驗證、渲染並核對 manifest。 |
| show-me | 用合成資料示意或實際 E025 原生畫面展示選取保留、首列回退、零筆與有無舊列失敗。每個畫面對應 NLA 案例。 |
| Floorplan | 在同一受測版本的隔離副本建立或更新 `floorplan/index.html`，核對 E025、Session、正式元件與查詢依賴。Swift 關係以 manifest 或原碼核實，記錄掃描限制。 |

工具產物放在工作樹外的本機專用目錄或隔離副本。採用證據記錄來源版本、驗證命令與觀察結果。產品完成條件為 NLA-01～06、既有回歸與獨立成果審查。

## 執行與交付

1. Plan-Reviewer 獨立審查同 slug 四份文件。明示 `approved` 後，依 Human 已授權的範圍進入功能工作樹實作。
2. Implementer 補正式 Row 缺值相容與共用狀態，再將 E025 接上正式 List，驗證視覺、選取、焦點及快照。
3. Tester 執行 E025 `verify.sh test`、`regression`、`build`，另跑正式 `swift test --filter RivetPresentationTests`，完成 NLA-01～06 並記錄證據。Reviewer 獨立核對實作與結果。
4. 無重大問題時，依 staged diff 檢查單一 topic commit，推送功能分支，開以 `dev` 為目標的 Draft PR，交 Human Review。公開介面相容性、責任或檔案範圍需變更時回到規劃。I3 另行決定。
