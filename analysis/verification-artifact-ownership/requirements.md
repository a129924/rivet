# 驗證產物歸屬修正：需求

## 狀態與來源

Topic：`verification-artifact-ownership`。基準 revision：`a554a4fee772d3976d5ca2c9331865a604e901e2`。
本文件沿用 Human 已接受的分類、集中原則與五批方向，以及本輪補充；不重比目錄或 package 方案。

## 同意範圍澄清

先前同意繼續工作，包含避免半改狀態、安全收尾、恢復一致性及保留成果的考量。
「允許安全收尾」、「接受功能／畫面／驗證結果」、「採用長期架構與歸屬」互不推導。
新增本次澄清與後續決策，不否認或改寫既有同意、驗收、commit、PR、來源版本、測試與限制；不假稱當時已逐字記錄現在的限制。
不得以過往 approved、驗收、合併或已寫入架構文件，證明原位置已獲永久採用。

## Goal / In-Scope

集中收納僅限五組已盤點的獨立驗證執行環境，以及其專用工具、host、控制介面、fixture、Runtime、資源與專屬測試。

| 批次 | 環境／分類 | 原 topic |
|---|---|---|
| B1 | Login Demo／功能驗收展示 | `rivet-login-ui` |
| B2 | Reader Harness／功能驗收展示 | `pr-reader-webview-runtime-reading` |
| B3 | 首次登入 App＋PKCE tools／可行性驗證 | `github-first-sign-in` |
| B4 | 持續連線 App／可行性驗證 | `github-persistent-connection` |
| B5 | DPK runner／正式 adapter 功能驗收 | `github-oauth-credential-persistence` |

目的地集中於對應的 experiments 編號資料夾，以用途說明區分展示與可行性實驗。編號配置不是重做實驗、撤回採用或改寫原 topic 性質。
首次登入 App 與 tools 同組但保留子目錄、案例、輪次、版本及各自結果；重用關係保留為引用，不複製工具，不追溯改歸某個後續實驗。
逐檔分類、old/new 路徑、hash 與允許差異以 [technical-spec](technical-spec.md#唯一逐檔清單) 為唯一來源。

## Non-Goal / Out-Of-Scope

- 正式產品能力及正式測試不因具有驗證用途而搬入 experiments。Presentation、WebView bridge、GitHubIntegration 與正式 Core 保留。
- 保留 root package 現有 products、targets、dependencies、resource 宣告；不移除驗證 target、不另拆 package、不重設依賴架構。
- 不新增共用抽象、治理框架、正式產品能力，不將驗證實作提升到 production。
- 不修改行為、API、簽章身分、entitlements 語意、儲存設定；不重構 Runtime 或合併重複實作。
- 不修改系統權限、解除安全限制、擴大環境修復，不啟動真人 OAuth、真 API、DPK live 或舊校準。
- 混合職責先列明，不順手拆分；歷史 fixture、pin、hashes、receipts 與結果不可改寫。

## 成功條件

- R1：僅五組驗證環境集中，正式能力／測試與 root graph 維持。
- R2：每批來源、資源、測試、建置與操作入口完整接線，可獨立驗證與回復。
- R3：實作前鎖定精確 old/new 路徑、四組檔案集合與允許內容差異；純搬移 bytes 不變。
- R4：分列必要驗證／補充檢查；記錄實際執行案例、到達階段、失敗位置、原因及證據，不只比較數量。
- R5：blocked／skipped 不算通過；未執行到本批 source、資源或入口，不得以基線相同宣稱無回歸或完整驗收，也不得進入下一批。
- R6：失敗先停下一批；授權內路徑修正可批內補齊重驗，超界／行為／外部副作用／不安全才回報，必要時撤回且不覆蓋無關修改。
- R7：E009 現行 pin 的相容性須實測；保留舊證據，不能靠沒有 source 硬編碼推論新產物相容。
- R8：正式規劃 gate 由獨立 Plan-Reviewer 明示 approved 且 required fixes=0；與實作／發布授權分開。

## B3 搬移前受限修正：本次新增授權

Human以Execution Authorized允許決定空白配置的預期契約、受限修正與重建基線後再續B3。依既有hosted test與正式OAuth factory的有效性規則，驗證App的環境配置入口須拒絕缺值、空字串及經whitespacesAndNewlines判定為空的值；有效值保留原bytes，不自動trim憑證。
此為搬移前獨立、可追溯的行為修正，僅限App composition與對應專屬測試；不更改正式GitHubOAuthAppConfiguration initializer／OAuth factory／API、簽章、儲存或E009 pin。先獨立審查並提交修正，再建立新的搬移基線；搬移本身仍維持bytes不變。先前基線失敗與原hash保留，確切檔案及修後搬移hash僅在唯一spec維護。

## B3／E009 現行pin更新：本次明確授權

Human本次授權E009現行pin的精確更新契約，綁定最終來源、建置命令與產物；沿用五批實作／commit／push／同DraftPR69／Human review授權。只在原B3批次內，對搬移後、必要tests通過且獨立建置的最終App重新綁定現行pin，保留歷史pin／hashes／receipts；這是明確追加的受限例外，不由先前approval推導。不得移除或弱化bundle／executable／digest／既有程序／TTY／launch身分保護，不新增真人OAuth／API／DPK或PKCE額度。

## VO-RB4：本次限定型別註記授權

Human明確授權該測試的限定型別註記候選及離線驗證。僅允許B4搬移前的authorizationUsesStatePKCEAndNoSecret()將query binding註為[String: String]，保留Dictionary表達式與全部expectations、inputs及runtime；這是單獨compiler相容修正，不偽稱純搬移。若可解除compilerassertion，完整guarded suite與獨立審查後提交修正、建立修後搬移基線，再依原五批授權續B4／B5。原crash與原hash保留，不授權skip、換工具鏈／flags／依賴／簽章／儲存或live。

本次限定型別註記候選A（query binding）已實測仍觸發同一compilerassertion並還原。續提同一方法／同一行的候選B，僅為Dictionary constructor顯式給<String, String>；這是對本次型別註記授權範圍的局部實作解讀，先交獨立Plan-Reviewer核scope，不增加行為、test期待或編譯條件。

候選B constructor泛型亦未解除compilerassertion，已還原。續提同一Dictionary表達式的候選C，僅明示map closure參數及tuple回傳型別（constructor亦保持明示泛型）；仍是限定該測試的型別註記目的，先獨立scope審查，不以A/B approval推導C，不改資料／期待或編譯環境。

## VO-RB4 本輪結果與新增邊界

A、B 均未解除原 compiler assertion，C 在獨立 scope／contract approved 後實測仍 build-for-testing exit65。C 這次 log 沒有原 assertion，改為 test module emit 階段三處 ambiguous type lookup；不能據此宣稱原 crash 的底層原因已解或完整相容性通過。C 已還原原始 bytes，三個候選都未保留為 source 修正。
本次僅授權該 query 表達式型別註記；新診斷涉及其他測試檔及 helper 型別宣告，尚未取得精確修正契約。先停 B4／B5，不把不同錯誤或未執行 bodies 當作無回歸；所需最小下一步是人類決定是否另准限定測試型別消歧，再獨立鎖定精確差異、重建完整離線基線。此輪不實作該提案、不修改 production 或 Runtime。
