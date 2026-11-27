# I3 技術規格

E026 擁有受控搜尋回應、固定時鐘、相對日期格式、App 入口、測試與證據。每次查詢建立獨立 REST 包裝，從同一個成功搜尋回應讀取日期，把原始回應交給正式自查 adapter 與 Facade。包裝不新增請求。正式查詢決定候選、來源順序、分頁與完整成功。

完整成功時，E026 以 owner、repository、number 對應候選和日期。缺欄位、null、型別錯誤或不可解析日期只省略該列時間。用固定 `2026-11-27T12:00:00Z` 與 `zh-Hant-TW` 組成 `relativeTimeLabel`。查詢失敗或取消時放棄本次日期。

`experiments/support/InboxExperimentSupport` 由 E026 透過 `../support/InboxExperimentSupport` 引用，並使用同一 checkout 的正式 Rivet。共用宿主接收已組成的呈現資料和實驗操作，負責 Variant B、正式清單、更新狀態、完整清單一次發布及選取。現有 ID 存在便保留，消失則選首列，空結果清除選取。失敗保留上一份完整快照及有效選取。有有效日期時，正式列於可用寬度達 480 pt 時顯示它，VoiceOver 可讀時間值。

E025、正式 Sources 與根套件 manifest／lockfile 為唯讀。E026 使用同一 checkout 的正式產品及既有 pins。驗收記錄完整受測 commit，以便同版重現三方接線。

[需求](requirements.md) · [執行計畫](../../plan/pr-inbox-i3-last-updated-verification/pr-inbox-i3-last-updated-verification.plan.md)
