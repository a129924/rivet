# OAuth 啟動／重連：技術驗證設計

基準 `ab77391b73291deb1ce3d96cef72f981aeb3104a`；日期 2026-11-17。需求見 [requirements](requirements.md)，受限範圍見 [plan](../../plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.plan.md)。本文件定義研究與圖面設計，不宣布正式 orchestration 已實作。

## 原碼優先的主要問題

既有 configuration／store／provider／scope，加上正式 signOut 與登入服務，能否安全組合冷啟動與重新授權，阻止舊 provider 晚到工作覆寫新狀態？

正式來源根目錄為 `Sources/BoundedContexts/GitHubIntegration/`；其中 `Providers/OAuthTokenProvider.swift`、`Composition/GitHubClientScope.swift`、`Login/GitHubLoginService.swift` 與 `Tests/GitHubIntegrationTests/OAuthLocalSignOutTests.swift` 是本題主要查核入口。目錄名稱不改變 GitHubIntegration 為 non-BC 的既定責任。E014 同名 App-local adapter 不等於正式 adapter；來源關係、namespace 與實際接入必須由原碼核實，不能由名稱推定採用。

初步來源包含 GitHubOAuthDataProtectionStores、GitHubOAuth factories、OAuthTokenProvider、GitHubClientScope、GitHubLoginService，及對應受控 tests、OAuth 儲存／雙 client／雙登入 runtime 長期契約、E014 與本地 signOut 證據。實作階段須逐項查實位置與版本，寫入 `source-audit.md`；目前初步定位不替代審查後的證據判讀。

- Configuration load、clientID-bound store、公開 fetcher factory、caller-owned provider 與 prepare 為既有 primitives。
- Scope 僅接受 OAuthTokenProvider；missingCredential、authenticationRequired 與 credentialLifecycle 的 restore／refresh／persist 分開。取消不交付 scope；ready 只表示本地準備。
- signOut 永久退休、等已開始 save、再 clear；晚到 load／refresh 不發布／不保存。不能用 E014 丟掉 references 取代此保證。
- Login success 無 payload，代表驗證及 save 完成；各階段 failure 收斂有限 Outcome。共享 login coordinator 不排除其他程序或仍可寫入的 provider，組裝端須滿足唯一 owner／writer 前提。

## 擬議組裝與介面界線

```text
冷啟動〔候選組裝，尚未正式接入〕
  load configuration → clientID-bound store／fetcher → provider → prepare scope
  分別保留：未設定／未登入／需登入／生命週期失敗／本地 ready
重新授權〔候選組裝，尚未正式接入〕
  signOut 舊 provider → 等 save／clear 收尾
  失敗：停止；不得開始 authenticate
  authenticate → 完整收尾
  success：新 provider → prepare 新 scope
  cancelled／failure：不復活舊連線
```

可重試暫時錯誤沿用原 provider；terminal persist 等狀態不自動重建。clear 後取消不還原舊 credential；已開始新保存後取消不 rollback。本輪不新增 public API、不決定正式 orchestrator 檔案落點。

## 實驗必要性與判準

預設文件／原碼及既有受控證據足以回答的項目不新建實驗。`source-audit.md` 逐項說明是否仍有決策性未知；不能因缺 tracker、未執行測試或沒有新 E 編號就判能力失敗。

只有答案必須執行確認且影響方案選擇時，才用一輪 fake-only 最小 harness。兩個區辨時點為舊 refresh 尚未回來、舊 save 已開始；以 barrier 記錄 retirement／save／clear／新 save／新 scope 次序與來源身分。

- 成功：舊結果不能覆寫或發布；新 bundle 完整保存後才交付新 provider／scope。
- 失敗：舊結果覆寫、退休世代復活，或保存失敗仍 ready。
- 無法判定：未進指定 barrier／競態，或無法辨識寫入來源。

尚未嘗試記未執行；四狀態與驗證任務完成否分開。限一輪 fake harness、兩時點；需修改正式 contract 才能驗證即停止依賴動作。執行前查當時未占用 E 編號，最小內容限 README、harness 與合成 fixture／結果，不覆寫歷史、不讀真秘密、不做 live。保存八段紀錄、日期、環境、輸入、指令、來源與限制。Build／test 通過不能取代主要假設判準。

E014 僅支持原版本指定環境的真 OAuth／DPK、新程序／同身分重建、受控刷新、輪替後讀回與 API；不繼承其成功、不外推自然到期、profile 更新或分發。

## 能力盤點與採用方案

`adoption-audit.md` 限本題能力，列來源集合／版本、正式範圍、觀察日期、排除及覆蓋限制。每項採用程度使用已採用／部分採用／未採用／已排除／不確定，與重用／調整／重寫等方式分開；無紀錄或搜尋未中不能直接判未採用。已採用須正式實作、實際接入及行為證據，等效能力與實驗來源關係分開。

`docs/feasibility-adoption.md` 新增本 topic 段，保留其他內容；列需求→能力→證據版本→選定／排除→依賴→方式→候選接入→驗證缺口。僅為方案，不正式接入，不改實驗 README 的歷史結果。三個 skills 不建立額外 gate。

## 工具與視覺契約

- Graphify：僅既有 graph query／path／explain，固定 0.9.73；每 invocation 設 GRAPHIFY_NO_AUTO_REFRESH=1，query budget 1500。查 revision 後關鍵關係回原碼；無可用 graph 用 targeted rg，不建 graph、不安裝／上傳。
- Floorplan：繁中現況地圖，保留 identifier／相對 paths。範圍以 OAuth 相關正式 GitHubIntegration sources／相關 tests／docs 與 E014 對照為主，不因 scanner 可掃全 repo 就擴全 repo 研究。先 status；有圖 refresh，無圖 scan，再 describe／build。Swift 關係人工核實，必要 declared edges 必須有實際原碼依據；若 parser 不支援，記未涵蓋，不做假檔案或假 100%。描述／相對連結的分母是事前列明 scope；不可解析項保留在缺口，不默默縮分母。既有圖中無關內容不重寫。
- Floorplan 使用者內容：前後比對 notes／annotations／custom-flows 原始內容，備份前於 provenance 列具體清單，僅寫 floorplan/.backup/。Refresh 可重建被刪來源的衍生 descriptions index／graph／cache；若輸出略去 deleted refs 的 flow steps，回報 warning，但原始 custom-flows.json 不改。不得刪使用者內容，不執行 git rm --cached，不改 AGENTS／CLAUDE notes／repo root ignore／Git settings。若工具要求此類改動即停止該操作並報限制。
- Floorplan 僅本機 ignored 產物，provenance.md 記 source revision、scope、實際檢查／skipped／解析限制；recent-work 只載實際相關 code 變更，沒有則 tasks: []。只靜態 index.html，不 open server／Ask／網路／autoFix／發布。Health 提示不是安全審查；回報重要 warning，不修 production。將來正式實作後才依 actual diff 更新。
- Architecture-canvas：正式責任邊界；本輪無 boundary change，不新造架構圖。
- Archify：兩份圖為 cold-start.sequence 與 reauthorization.lifecycle，作者繁中，明分既有事實／擬議組裝。執行時才讀對應 schema／example，fresh stable IDs、showcase；omit locale、visual_preset、subtitle，說明固定 Viewer UI／HTML lang 英文 fallback。Validate 9 checks、0 errors／warnings；deliver 後 visual-check 四 desktop 尺寸（1440×900、1600×1000、1920×1080、2048×1320）及 light／dark 證據；Agent 檢視與 Human 接受分開，不發布。兩輪修復無改善依 skill 停止，不降品質條件偽裝成功。
- PR Lens：真實 base／head 或 bounded diff 才使用固定 0.11.0 本機 validate／render。graph／SVG 在 repo 外 topic 暫存目錄，保留 unchanged neighbors／實際 file refs；有既有 overlay 才讀取套用。無 diff 為 deferred，不虛構 provenance、不建 repo .pr-lens、不改 config／ignore、不安裝／上傳／留言。一般 Draft PR 由獲授權的交付角色建立，不由 PR Lens 發布。
