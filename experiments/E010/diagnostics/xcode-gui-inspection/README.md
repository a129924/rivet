# Xcode GUI 配置查閱：離線 runbook

本文件是 `github-oauth-dpk-profile-continuity-feasibility` 的獨立診斷補充，不是第五份正式 planning artifact、E008 新輪或 adapter 實作。**本次只交付 runbook／workflow；GUI T01–T03 全部未執行。** 沒有建立使用者私有副本、開啟 Xcode、開始十五分鐘計時，也沒有實際 GUI 值、版本或提示觀察。

[舊 E008 README](../../README.md)、[requirements](../../../../analysis/github-oauth-dpk-profile-continuity-feasibility/requirements.md)、[technical-spec](../../../../analysis/github-oauth-dpk-profile-continuity-feasibility/technical-spec.md)、[plan](../../../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.plan.md) 與 [step](../../../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.step.md) 保留原 bytes。它們的「當時未授權發布」、pending 或已 closed 記錄是原時點快照。本次 commit by topic／push／Draft PR 授權來自目前 Human 請求，不回寫或改判舊紀錄；實際發布狀態以後續交接及 PR 為準。寫作交接時先交獨立 Tester／Reviewer，尚未 stage／commit／push／開 PR；commit message 仍依專案規範取得 Human 確認。

## 九欄範圍

| 欄位 | 契約 |
|---|---|
| Goal | 只規劃如何從同一個 Xcode 私有 project window 讀到配置與路徑，分開回答 T01 路徑、T02 配置、T03 普通 Build 對應。 |
| Non-Goal | 不證明 Build 成功、可執行 host／簽章資格／profile／DPK／OAuth／UX，不交付正式 adapter。 |
| In-Scope | 現在只有此新目錄的 runbook、單一靜態 workflow 及必要本機 artifact QA；未來經 Human 明確授權及 ready 才準備一份停用簽章副本，作一次受限 GUI 配置查閱。 |
| Out-Of-Scope | Build／Run／Test／Archive／Clean；任意 `xcodebuild`、`prepare.py`、E008 driver／`--begin-anchor`；Apple 帳號、Team 選取、Signing & Capabilities／Fix／Download／Register、簽章／profile／Keychain；Finder／全域搜尋或 CLI fallback。沒有新 Swift／helper／production／API／adapter。 |
| ReadOnly | 舊四份 artifacts、E008 README／17 source／所有歷史 receipts/index、E006/E007、其他 worktrees；未來只讀同 exact window 的配置，不以其他 project、CLI 解析或舊 GUI 值代替。 |
| Written | 現在只此補充目錄；未來另獲批准才建立單一 private copy、最小 manifest／授權內 workspace 和 owned output/index cache。Xcode 開啟可能更新 workspace／index／Recent／view mode，必須事前逐項說明並取得範圍同意；不默認無磁碟寫入。 |
| Deleted | 現在不刪舊檔；未來只清 proven-owned 診斷 root／cache，證據先報告／依另准方式保存；不能把推算的產品路徑當刪除目標。 |
| Modify | 舊 source、harness、四檔及 immutable 證據不改。未來只在私有副本改明列停簽／owned output 設定及必要 view state，不能現場調參救通關。 |
| TestCase | 下列 T01–T03 各用「未執行／成功／失敗／無法判定」，三項分判，只支持實際覆蓋範圍；目前全部未執行。 |

## 未來操作前的授權與時間

Human 必須另明確授權 **prepare／write／exact open／read／close／cleanup** 的對象與範圍，並確認準備階段可開始全程觀察。準備前才記本次十五分鐘的實際開始時間；包含複製、檢查、開窗、等待 ready、查閱、報告與清理。這是獨立 GUI 診斷時間預算，**不是 E008 t0／namespace／grant 或第四個測量窗口**。本次未啟動。

Archify／PR Lens／Graphify 的製作、驗證與審查只安排在 GUI 診斷時計啟動前，或已關窗且清理後。若意外占用已啟動的窗口，全部時間仍計入原十五分鐘；不暫停、不重設、不延長。

GUI 前另取得當下 fresh ready，綁本次副本及階段；不能借舊 Human 回覆、資料或授權。第十二分鐘停止新查閱，末三分鐘只作安全報告、關閉與清理；不延長、不重設或自動重試。若缺 ready、已用完查閱時間或前提不能證明，即停止查閱；清理未完成就如實交接殘留，不宣稱總能在期限內移除，也不建立排程／daemon。

只處理可唯一辨識的 exact project window。焦點換到其他 project、window binding 不足、出現帳號／資產／簽章提示、必須擴範圍才能繼續時立即停；不授權該提示、不修設定、不搜尋替代候選。只要 scope 內無法安全關閉，也先報告，不能碰其他視窗或強制終止他人程序。

## 單一停簽私有副本（未執行）

未來選定 Human 同意的持久位置，例如 `~/Library/Application Support/RivetExperiments/xcode-gui-inspection-<本次識別>`；它不是 DPK namespace。要求非 Git／非 tmp、0700、owner matching，root 與既有路徑元件均無 symlink。現在沒有建立或讀取該位置。

僅複製舊 E008 的八個最小 build inputs：

- `DPKContinuityProbe.xcodeproj/project.pbxproj` 與同 project 的 `xcshareddata/xcschemes/DPKContinuityProbe.xcscheme`。
- `Sources/DPKContinuityProbe/` 的 `AppMain.swift`、`LiveGate.swift`、`LiveStore.swift`、`ProbeCore.swift`。
- `Resources/Info.plist` 與 `Resources/DPKContinuityProbe.entitlements`。

不複製或執行 scripts、tests、帳號、certificate、profile 或真 token。私有 manifest 記 source／copy 前後 SHA、唯一 root／project binding、owner／mode／symlink 結果、批准的設定差異及已知生成 cache；不改來源檔。除明列 private project 設定差異，四 Swift／scheme／resources 不改；Xcode 另有遷移或未批准改動就停，不補救。

**開窗前**，在私有 project 的 Debug／Rebuilt、project／target 及適用 conditional settings 全部確認：

| 設定 | 必須成立 |
|---|---|
| `CODE_SIGNING_ALLOWED` | `NO` |
| `CODE_SIGNING_REQUIRED` | `NO` |
| `CODE_SIGN_STYLE` | `Manual` |
| `DEVELOPMENT_TEAM`、`CODE_SIGN_IDENTITY` | 空 |
| `PROVISIONING_PROFILE_SPECIFIER`、`PROVISIONING_PROFILE` | 空 |
| `SYMROOT`、`OBJROOT` | 綁此已批准 owned root |
| per-project DerivedData | 綁此 owned root；不能依賴 global default |

這一段只用獲准私有設定的 scoped 檔案檢查，不執行 `xcodebuild` 或任何 build／asset 命令。停簽或 owned DD 未證明就不 open。沒有 Team、profile 或資格來源值可推測填入；不去選 Team／Signing & Capabilities／Fix／Download／Register。此副本配置不是原 signed host 證據。

可預先設定且只核對此私有 project 的 workspace／per-user owned DD；不得改 Xcode global preferences。開啟與索引可能自動寫 workspace、index、Recent、view mode，應在 Human 授權前揭露已知位置與未知副作用；無法接受的寫入範圍就不開。這不授權為了收尾修改或清空全域 Recent，也不能假稱所有 Xcode cache 都會在指定位置。

## 同窗 GUI 只讀查閱（未執行）

以下 UI 名稱是預定查閱路徑，**不是已觀察到的版本或值**。只能使用 Human 已准的同一份 private project；open exit code、同名 window 或 template 不能代替實際 project/window binding。

1. 在 GUI fresh ready 後開 exact project。核 frontmost/window/project、單一 app target、scheme 與 My Mac；任何多候選／無法綁定即停。GUI 多列不自行推成第二個真 target，也不調 scheme 來消除差異。
2. Edit Scheme 只讀查閱 Build for Running 與 Run 的 Debug configuration，分別記來源；以 Cancel 關閉，不改 checkbox 或 configuration。沒有安全不寫設定的退出方式則停，不自行套用。**Run Debug 不能證明普通 Build 使用哪個 configuration。**
3. 同 target 的 Build Settings 選 All、Levels、Show Setting Names，核 Debug／Resolved 的來源層級，再以 Show Values 看完整值；只能改獲准的檢視狀態，不編輯設定。記每項是 GUI 實讀／Human 陳述／未驗，不能用 CLI 或 source 推論補空欄。
4. 只從這次 GUI 讀 `TARGET_BUILD_DIR`（T，完整絕對路徑）、`WRAPPER_NAME`（W，相對 wrapper 路徑）與 `EXECUTABLE_PATH`（E，相對路徑且包含 wrapper）。File Inspector 只作同 project／檔案來源交叉核對，不能替代 Resolved 值或證明 Build 產物來源。

路徑判讀必須逐項成立：

- App 路徑為 **T/W**；main executable 路徑為 **T/E**。E 已包含 wrapper，不能計算成 App/E。
- T 必須 absolute；W、E 必須 relative，E 的 wrapper components 與 W 相同。空值、未展開變數、多值、`..` escape、錯 root binding 一律停，不改參數、不 fallback。
- 以 path components／canonical containment 核 T、T/W、T/E 均屬已綁定的 owned root；不能用字串 prefix 判斷，例如同字首 sibling 不是 child。
- 只對驗證通過的 scope 內既有元件作 owner／no-symlink 檢查；尚未存在的尾段只記計算值，從最近既有祖先核 canonical containment，不建立產品來讓檢查通過。不要沿未先證明安全的 GUI path 查其他位置。
- 因禁止 Build，此次即使能算出路徑，也不證明該 App／executable 存在、可用、已簽章或曾執行。沒有完整值／來源／binding，就把相關案例記無法判定並停止。

## 分項結果與報告（目前全部未執行）

| 案例 | 必須分開回答 | 未來「成功」最多支持 | 現在 |
|---|---|---|---|
| T01 路徑 | T／W／E 的 GUI 值與來源、T/W 與 T/E、canonical owned containment | 本次只讀配置的路徑推導成立；不證實際產品存在 | **未執行** |
| T02 配置 | exact window／project／target／scheme／My Mac／Run Debug 與停簽／output binding | 實際查到的配置對應成立；不證普通 Build 或簽章資格 | **未執行** |
| T03 普通 Build 對應 | 是否另有直接 GUI 證據連結普通 Build 的 configuration／target／來源 | 只有實際直接證據涵蓋的對應；不執行普通 Build | **未執行** |

每項均使用：尚未進行為「未執行」；滿足本項必要證據為「成功」；在前提已完整下有可重現矛盾為「失敗」；缺欄位／來源或無法觀察為「無法判定」。T03 沒有直接對應證據時必須無法判定，不能由 Run Debug 推成成功；即使 T01／T02 成功仍是 partial coverage，不延伸成 Build／host／DPK／UX 成功。停止不等於所有案例技術失敗。

預設以 safe chat 報告三項狀態、實際覆蓋、缺口、提示 Human 原話與清理結果；沒有觀察就未知，不填 0。私人 T 或 project 路徑留在已准私有材料，公開只保留相對表示、bool／hash；不輸出個人絕對路徑、Team／certificate subject／device／帳號識別。若 Human 另准 JSON 證據，才 exclusive 寫完整 canonical bytes、落盤後 SHA、回讀核對；**先報告／保存並核對，後刪私有材料**，不覆寫既有收據。這與本目錄已授權的離線 Archify QA JSON 分開。

## 關閉與精確清理（未執行）

在末三分鐘或受控停止時，先回報分項結果，確認 exact project／Build 已停止，僅關該已綁定的 private window。再核 root／manifest／owner／無 symlink／無持有 handles，且必要證據已按授權保存；符合才刪 proven-owned root 與明確屬本次的 cache。

刪除對象來自事前 manifest 與實際 ownership，不是從 T/W、T/E 或其他計算字串直接挑目標。未知外部 cache、其他 project／parent、全域 DerivedData／Recent、Apple 資產不動；全機外部是否有產物／殘留維持 unknown。不能證明已停止、歸屬、無 handles 或安全保存時，保留最小材料，明列 cleanup 未完成／具體殘留，交 Human 決策，不 force removal、擴掃或清空他人資料。

## 本機 workflow 與交接

Workflow 畫的是計畫授權→準備→GUI fresh ready→只讀核對→分項結果→報告／清理，所有 GUI 案例仍未執行。作者內容為繁體中文；省略 `meta.locale`，所以固定 viewer UI 與 `<html lang>` 使用 English fallback。靜態、預設 classic，未加 subtitle／animation／自訂 preset；圖的 artifact QA 不是 GUI 或 feasibility 驗證。

唯一 final 圖為 [workflow.v2.html](workflow.v2.html)（[spec](workflow.v2.json)）；[showcase validation](workflow.validation.json)、[delivery SHA receipt](workflow.delivery.json) 與 [作者實際 visual-review](visual-review.md) 分別留存。自動 visual-check 的 `visualReview=pending` 只代表它不代做人眼檢查；作者另外實際查看截圖才另記結果。失敗稿／修正歷程與舊 180 候選的 SHA 保護證據保留於本輪外部 preparation scratch，不改舊檔，不新建 runtime／GUI evidence。

Graphify 本輪未找到可用既有 graph，未 extract／refresh／install／provider／upload，改用有限 source 查閱；若後續真有可用 graph，先驗 revision／source hashes 與 untracked coverage，再以 `GRAPHIFY_NO_AUTO_REFRESH=1`、budget 1500 查詢並回 source 核對。PR Lens 等真實新 bounded committed diff 後才依既定本機 validate/render，不用它發布 PR。本次先交 Tester，再交獨立 Reviewer；這份 runbook 的完成不自行產生 approval 或真人 ready。
