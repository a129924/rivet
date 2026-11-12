# 驗證產物歸屬修正：步驟帳本

最後更新：2026-11-12。分支 chore/verification-artifact-ownership；目前 phase：正式規劃 approved；B1 主環境路徑重定向後仍 blocked；僅交付文件 WIP。
四實體文件已落檔；先前 draft-only approved／0 fixes 不挪作正式 gate。逐檔資料只引用 [spec](../../analysis/verification-artifact-ownership/technical-spec.md#唯一逐檔清單)。

| ID | Status | Owner role | 完成條件 | 驗證證據／缺口 |
|---|---|---|---|---|
| VO-P01 | completed | Explorer | 五組分類、E009角色、wrapper及主要接線查證 | 基準a554a4f；E009現行入口；73file單一spec；候選配號未reserve |
| VO-P02 | completed | Tester | 限定離線基線已執行並分類 | plan基線；不表示失敗解除或必要項全到達 |
| VO-P03 | completed | Plan-Creator | 四正式文件落檔，納最新驗證／pin要求 | 本四檔；未自判品質或gate |
| VO-P04 | completed | Plan-Reviewer | 正式實體審查 approved 且 required fixes=0 | Popper 已審四實體，approved，required fixes=0；73/73 source hash 相符 |
| VO-P05 | pending | Explorer | 各批前配號／mapping／差異／入口鎖定 | spec唯一清單；B1新版wrapper生成入口待定位 |
| VO-B01 | not-started | Implementer | B1契約內完整搬移，交Tester | 必要build／tests／新版入口未驗；前置未解除不搬 |
| VO-T01 | blocked | Tester | B1必要項真正到達並給出結果 | Newton 在同一基準只跑一次 build：manifest／cache 權限先失敗，未到 source／資源／入口；不放行 B1 |
| VO-R01 | pending | Reviewer | B1獨立成果審查與限制分類 | 無結果；未完成不得B2 |
| VO-B02 | not-started | Implementer | B2同批接線並交Tester→Reviewer | 依賴B1通過；無搬移 |
| VO-B03 | not-started | Implementer | B3接線及E009最終產物相容性，交Tester→Reviewer | 新binary pin未知；不自動更新 |
| VO-B04 | not-started | Implementer | B4完整搬移，交Tester→Reviewer | 依賴前批；無搬移 |
| VO-B05 | not-started | Implementer | B5完整搬移，交Tester→Reviewer | 依賴前批；無搬移 |
| VO-D01 | pending | Implementer | 已審bounded topic commit、push、Draft PR交Human | Human直接授權；不得將文件WIP誤稱五批完成 |

## Blockers

| ID | 狀態／問題 | 解除條件 |
|---|---|---|
| BL-P | resolved | Popper 正式 approved、required fixes=0；不等於五批執行通過 |
| BL-N | 配號候選／未保留 | 各批前核對索引與新占用，必要時回修唯一清單交審 |
| BL-B1 | 主對話已重現原 cache 寫入阻擋；標準參數改用可寫目錄後，manifest 的 sandbox_apply 仍被拒，未到 product | 取得可啟動 SwiftPM 標準 sandbox 的適用執行環境；保持 sandbox，不修改權限或繞過限制 |
| BL-W | 歷史wrapper存在，但新版生成入口／新資源載入未驗 | 定位既有recipe並鎖定，驗新產物；不覆蓋舊freeze |
| BL-PK | loopback權限／helpercompile阻擋，部分原因unknown | 逐case證據及適用離線環境；不猜測根因或啟真人流程 |
| BL-E9 | 現行E009 pin與新binary相容性未知 | B3實測最終身分／hash／既有preflight；失配先回報／修契約 |
| BL-O | GUI／Xcode／DPK build未驗，DPK有8skip | 分必要／補充及到達階段，不把skip算pass，不取未知外部輸入 |

## Human Check

Human已接受scope五批並授權四文件建立與正式交審；現已Default mode，先前Plan Mode寫入限制不再適用。
本訊息另明確授權feature worktree實作、commit by topic、push與Draft PR→Human review；不由planningapproved推導，仍受必要驗證／重大問題停點限制。
系統權限、安全限制、環境擴修、真人流程、pin更新不在新增授權內；規劃通過不授權merge。
Explorer與Tester既有交接保留，作者沒跑測試不等於整輪無測試。文件WIP可交付，但必要項未驗不得宣稱搬移完成。

## 審查紀錄

正式 Plan-Reviewer：Popper；verdict：**approved**；required fixes：**0**；unresolved required fixes：**0**。此為四實體正式審查，不沿用對話 approval。
受審快照 SHA-256（本節為審查後行政記錄，step hash 指補記前的受審快照）：
- requirements：7f2b752e3721bd73ddbe103eaa8dbbcc509174f9983470ce41c7e31843b43f25
- technical-spec：ceb7d2963d38f5e5241ae4f56a0630b37055eb1edb4c4234af18a50f4c26308b
- plan：5b53b79df81add18ae7ed05061dc69f400d6cab812d78604811aee8390f9cb44
- step：2b70dbaf195b436cca63cca180745d7b2aa5e9ba4916acb1914480785ef9d114

## B1 搬移前實測與停止

Tester Newton 在 feature branch／基準 a554a4fee772d3976d5ca2c9331865a604e901e2，僅跑一次既定 swift build 離線命令，exit 1。
manifest 編譯因 ModuleCache 寫入 Operation not permitted 及 .build/repositories 寫入限制受阻，另報無法載入目標標準函式庫；底層權限原因未調查，維持 unknown。
未到 product source、資源或入口；model／Presentation tests、wrapper／bundle 資源與新版原生入口皆未驗。沒有以相同失敗判定無回歸。
Tester 確認 tracked staged／unstaged diff 不變，未修改系統權限、環境、安全限制，未重試或啟動真人流程。
B1 not-started，B2–B5 not-started。僅文件 WIP 交付，不交接任何半套來源給下一批。

## 本輪主對話查證更新（2026-11-12）

Human 新增有限授權：本次可用 SwiftPM／compiler 標準參數把輸出、scratch、cache 指到可寫位置；不改系統／全域／簽章／安全／版本，不停用 sandbox，不在 dev 實作。
主對話（非 side chat）於 revision 2103e5624ec7597aca2c7eefac879b6c330aa4b6 執行原 build、可寫路徑 dump-package 與完整 build；完整命令及證據僅見 [plan 的本輪重現](verification-artifact-ownership.plan.md#主對話-b1-局部建置路徑重現2026-11-12)。
實測 scratch/cache/modules/logs 可寫，新 Swift／PackageDescription cache 實際產生；完整 build exit1、1.113s，錯誤改為 sandbox-exec: sandbox_apply: Operation not permitted。
標準 sandbox 啟動被拒的背後政策原因 unknown；不直接沿用先前推測，不把不同條件的失敗當成等價。
VO-T01 仍 blocked：未到 B1 source、tests、資源或入口；VO-B01–VO-B05 仍 not-started。沒有搬移或安全繞過；本輪只補現有 plan／step 的命令與證據，不複製單一逐檔清單。
本輪文件增補已由獨立 Plan-Reviewer Nietzsche 審查：approved，required fixes=0；只確認文件與主環境原始證據一致，不放行 B1，也不挪用前輪 approval。最小下一步交 Human：以能啟動標準 SwiftPM sandbox 的適用環境重跑同參數基線，成功後仍須完成 B1 必要 source／tests／資源／入口驗證。
