# I2 正式採用原生 Inbox 清單技術規格

## 正式呈現

- 保留 `PullRequestRowPresentation` 的完整欄位 initializer 與既有公開 `String` 欄位型別。新增接受可缺作者及時間標籤的 initializer，允許各自省略。缺值在列及 Accessibility 組裝時省略，分隔符只放在存在的值之間。Title、repository、編號、context 及次要 metadata 沿用既有版面優先序與無障礙語意。
- 以 `InboxListStatus.swift` 提供由呼叫端驅動的共用狀態呈現。此元件呈現載入、成功零筆、首次讀取失敗及完整舊列可能非最新，提供狀態文字與標題語意，載入時提供進度。列是否可讀及顯示由呼叫端決定。
- `InboxWorkspace`、`PullRequestList` 沿用既有正式元件。正式 Presentation 的責任限於顯示、原生清單與既有對外事件，查詢、OAuth 與分頁留在現有模組。

## E025 接線

`InboxSession` 沿用 owner／repository／編號組成的 `InboxRow.Identity`。在 E025 建立與正式 List 的 `String` ID 對應，確保同編號跨 repository 有不同 ID，標題及位置變化不影響 ID。List 的 binding 在當前快照解析有效選取，重新整理成功時以同一份快照發布列及選取。已選 ID 有效則保留，已移除則選首個可選列，零筆清除選取。錯誤及等待沿用仍可讀的最後完整快照。候選及順序沿用正式來源。

E025 視窗以既有 `InboxWorkspace` 顯示正式 List 及共用狀態，並綁定 E025 自己的焦點。原焦點目標在狀態切換後失效時，焦點依原生互動契約落到適用狀態標題。E025 維持未開放 Reader，`canOpen` 為 false。E024 維持既有完整欄位及 Open intent 的原生驗收入口。

進度、零筆、錯誤與舊資料提示依完整快照顯示。第二頁暫停控制與驗收提示屬 E025，真人前置檢查亦沿用現有 E025 路徑。可讀舊列及有效選取在第二頁等待或失敗期間保留，當次的部分結果不發布。

## 驗證設計

Row 測試涵蓋完整、僅作者、僅時間及兩者皆缺，並核對 Accessibility 字串。E025 Session 測試覆蓋穩定 ID、同編號異 repository、快照替換、選取保留及回退。NLA-01～06 的原生畫面、Accessibility、朗讀、鍵盤事件與焦點證據依執行計畫收集。 [原生互動契約](../../docs/presentation/native-interaction-contract.md) · [執行計畫](../../plan/pr-inbox-native-list-adoption/pr-inbox-native-list-adoption.plan.md)
