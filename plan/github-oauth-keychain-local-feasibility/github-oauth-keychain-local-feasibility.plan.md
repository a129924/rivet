# Keychain 本機 OAuth 憑證保存可行性計畫

- Topic：`github-oauth-keychain-local-feasibility`
- 日期：2026-10-15
- [需求](../../analysis/github-oauth-keychain-local-feasibility/requirements.md)／[技術規格](../../analysis/github-oauth-keychain-local-feasibility/technical-spec.md)／[狀態帳本](github-oauth-keychain-local-feasibility.step.md)

## 目標與固定條件

驗證完全不依賴付費資格的本機 Keychain 完整 OAuth bundle 保存、fresh-process、真正同身分重建及 UX。既有付費 profile／簽章也不得作成功前提。首次最多一次明確系統授權；正常後續啟動及同身分重建零提示。責任維持 non-BC GitHubIntegration，不新增 public API、不改 provider ownership／既定架構。

DPK 優先檢查免費 host 前提，無法證實時只允許首次寫入前選 legacy 為唯一候選，不得測量失敗後 fallback；所選前提不足則無法判定。完整設計與官方來源見 technical-spec。歷史 legacy 八個測試與 E004 僅為背景，本輪不重跑整套 baseline 或 refresh runtime。

## swift-implementation：後續受限 Swift 實驗階段

此為階段名稱；未找到同名 skill，不宣稱使用該 skill。

| 欄名 | 受限契約 |
| --- | --- |
| **Goal** | 免費本機完整憑證的 fresh-process、真重建與提示 UX 可行性。 |
| **In-Scope** | 單一候選最小 Swift host、私有編碼器、固定假 A／B、T01–T06、遮蔽證據、精確清理、必要 workflow 與受限本地理解。 |
| **Out-Of-Scope** | 真 token／GitHub OAuth／登入 UI、正式 adapter、SQLite migration、跨程序 refresh、公開分發／notarization、新增帳號、超出下節窄範圍例外的建立／匯入憑證、付費、安全設定／既有 ACL 變更、發布。 |
| **ReadOnly** | production Sources／Tests、root manifests、歷史 topics／E001–E004、技能與 tool configs；架構文件作依據，唯一後續回寫目標除外。 |
| **Written** | 本 topic requirements／technical-spec／plan／step 四檔，新 experiment 的 host、八段 README、evidence、Archify spec／HTML／receipts／captures；PR Lens 僅 repository 外 topic scratch；限定自簽憑證／private key、匯入素材與專用實驗 Keychain 僅在 repository 外隔離 scratch，不進 repository 或輸出秘密。 |
| **Deleted** | 不刪既有 repository 檔案；僅本輪精確 UUID Keychain 項目、限定憑證的專用實驗 Keychain／repository 外秘密素材及確認屬本輪的 build 暫存，不刪證據或既有 Keychain。 |
| **Modify** | 本 topic 新檔後續更新；經實證與獨立 review 後，只於 `docs/architecture/github-oauth-dual-client.md` 回寫有條件結論，不核准採用、不擴其他 docs。 |
| **Non-Goal** | 不改 API、provider ownership、既定架構或歷史 topic，不以工具／build green 代替驗證。 |
| **TestCase** | 下列 T01–T06，正常完成後獨立負向；整輪 experiment 的所有退出路徑精確清理，writer／reader 正常結束保留 item。 |

主要 item 為 UUID 隔離 generic-password，單 `Data` 私有 DTO 整筆更新。六欄為 accessToken、refreshToken、accessTokenExpiresAt、refreshTokenExpiresAt、tokenType、grantedScopes；expiry 為 Date，A／B 的兩 token、兩 expiry、scope 均不同且 tokenType 均 bearer。DPK query 明設 true、legacy false，皆 synchronizable false。所有輸出遵守遮蔽限制。

## 分支與檔案影響

唯一 branch：`chore/github-oauth-keychain-local-feasibility`，base 為 `dev`；實際 feature worktree 已由主工作 session 建立，起點 `origin/dev` 的 `913c063`。不加入無既定慣例的 owner；規劃時 local／remote-tracking 未見衝突，fresh remote 未查，不冒稱遠端新查證。

僅在已建立的 feature worktree 寫入，不改 dev 工作樹。新實驗建檔前重新查 `experiments/` 編號；E001–E004 已占用，E005 僅規劃時可用。使用未占用編號，不覆寫歷史。產物只在 Written 範圍，長期結論只回寫 Modify 指定文件。

## T01–T06 與驗收

| 案例 | 必要操作與證據 |
| --- | --- |
| T01 前提 | 記錄日期、OS／Swift、host、backend、簽章／profile、免費來源與未知項；首次寫入前固定候選與判準。 |
| T02 完整還原 | writer 保存 A 後結束；兩個 fresh reader 各逐欄比較六欄，記錄所有提示。 |
| T03 真重建 | 改 build marker、重建並證明 hash 不同；固定 host 路徑／bundle ID／簽章方式／backend，記 designated requirement／entitlements／access groups 一致性布林值，新程序讀 A。無免費穩定身分不能說完成。 |
| T04 完整替換 | 整筆替換 B，新程序讀回全 B，沒有新舊欄位混合。 |
| T05 失敗邊界 | T02–T04 正常完成後才負向。absent→nil；malformed→decode failure；非 errSecItemNotFound 不得 nil。真 denial 僅獨立項目自然觀察，不改主要 host 身分／ACL／安全設定製造提示。無自然 denial 保留缺口，synthetic 分類證據明標；正常流程全部提示計入 UX，不可轉分類排除。 |
| T06 清理 | 整輪實驗結束時，以精確 namespace／service／account／backend 清理主要與負向項目並確認不存在，逐項保存結果；不於 writer／reader 正常結束時刪除。 |

成功需免費前提、完整還原、真重建、替換、清理及 UX 達標；真 denial 缺口可保留並支持其餘完整證據下的受限成功。前提滿足時可重現不完整／無法恢復／反覆提示為失敗；機制成功與 UX 失敗分開。沒跑或前提不足不能稱假設失敗。

## 工具使用時點、產物與失敗處理

所有工具共用本輪總額。不安裝／更新、不啟動服務、不改設定、不發布，不以工具結果取代實驗證據。

### Graphify 0.9.73

程式理解時先查既有 graph／revision，query budget 1500，再 source verify。每次 CLI 明設 `GRAPHIFY_NO_AUTO_REFRESH=1`。規劃時 repository 未見 graphify-out，外部未全面查；無圖或 runtime failure 即 rg fallback。不自建／refresh graph、不 install／改 config／啟動 watcher／配置 semantic provider。保留 revision、query 與 source 核對／fallback 紀錄。

### PR Lens 0.11.0

有真實 bounded diff 與非捏造 provenance 才用 pinned CLI validate／render，涵蓋 changed、unchanged 鄰近內容及 references，產物只在 repository 外 topic scratch。無可代表變更的 base／head 時 deferred、使用 direct diff；相同 commit 不假造 diff，不為工具 commit。有既有 overlay 則唯讀使用，無 overlay 則 scratch no-config。不 commit／create PR／upload／server／install／改 config。topic commit／Draft PR 僅依下節已授權交付流程，不由 PR Lens 工具代做。

### Archify 2.16

host 與整輪實驗退出行為明確後，產出一張繁中 static classic workflow，涵蓋成功、停止／例外及整輪 exact cleanup；writer／reader 正常退出保留 item。不新增 architecture 圖、不加 animation、不發布 artifact.cafe。省略 meta.locale，不誤用 zh-CN；揭露固定 Viewer UI／HTML lang fallback English。

保存 spec、HTML、showcase／deliver receipts 與 captures。showcase 九項 checks 零 error／warning，依序 deliver、visual-check 四個桌面尺寸並實際查看 captures。receipt 的 `visualReview: pending` 原樣保留，另記人工視覺檢查狀態。兩次連續修圖未改善即停並列未完成項。

工具 deferred／fallback／失敗與實驗四狀態分開。必要圖作業未完成標 INCOMPLETE，不宣稱整包完整；不自動延長時間。

## 時間、清理與停止

2026-10-15 02:41:28 UTC 起算，總額 90 分鐘；03:56:28 UTC（75 分鐘）停止新增測量／圖作業，04:11:28 UTC（90 分鐘）到總上限。最後十五分鐘優先清理、保存證據與八段紀錄。PR 提交交接不當作 Keychain 測量，不杜撰額外測量時間或結果。

統一 cleanup 是整輪 experiment 的退出路徑：writer／reader 子程序正常結束保留 item，供 T02 跨程序、T03 真重建、T04 替換使用。任一寫入嘗試後，整輪正常完成／失敗／停止／例外退出時才嘗試精確清理全部本輪主要及負向項目。殘留時記非秘密 UUID 識別、原因、待處理操作，驗證任務完成為否。需要新增帳號／超出限定例外的憑證操作／付費／安全設定變更、所選免費來源不明或時限到達即停止依賴操作並清理紀錄。

## 結果、角色與交付

八段 README 擇一記「未執行／成功／失敗／無法判定」，另記本輪驗證任務完成與理由。設計／執行日期、真實／synthetic、觀察／推論、適用限制及 cleanup 狀態分開。只支持本次 OS／host／身分與候選，不外推所有 macOS、簽章方式、新版本或公開分發。

四檔建立後先交獨立 Plan-Reviewer；正式明示 approved 後由 Implementer 做 host，Tester 獨立驗證、Reviewer 獨立審查證據。這是既有專案流程，不為工具新增 gate。完成後由 Implementer 回寫指定長期文件、依 staged diff 檢查語意邊界並提出 commit message、按 topic commit／push／開 Draft PR，交 Human review。使用者已明確授權直接 commit，不新增等待 commit 批准；不授權 merge／release／發布。實驗完成不核准正式採用。


## E005 T03 窄範圍補測授權

使用者已明確授權新增一張實驗專用自簽 Code Signing cert／private key，僅在 repository 外獨立實驗 Keychain 建立／匯入及精確清理，用於同一 legacy backend、相同假六欄的 T03 補測。這是 Out-Of-Scope 憑證操作的唯一例外，不改其他 scope、免費／UX 判準或 production contract。

在新 UUID OAuth item 首次寫入前，先完成兩次真正重建／同身分簽署與 DR 預檢，保留 first／second binaries，保存並核對不同 hash、designated requirement 相等及原身分條件一致。未成立即停，不用舊 ad-hoc 結果或只重跑 binary 代替 T03。成立後於固定 host 路徑還原 first（第一次 build）作 writer 保存 A，結束後換成 second（第二次 build）作 fresh reader 逐欄 acceptance read；保存並核對實際 writer／reader hash，兩端不得都用 second。所有提示如實記錄。

不得改既有 ACL、系統信任、預設 Keychain、全域 search-list，不新增帳號或付費；需要任一禁止改動即停。private key、密碼及匯入素材只在 repository 外隔離 scratch，不進 repo／證據／log。整輪退出 cleanup 除精確 OAuth 項目外，亦涵蓋本次專用 cert Keychain 與秘密素材，分開確認不存在；保留 receipts，不刪歷史或既有 Keychain。無法清理則記非秘密 UUID／原因，任務完成為否。

原 90 分鐘不延長：03:56:28 UTC 停止新增測量，最後十五分鐘優先清理紀錄，04:11:28 UTC 總上限。四檔修訂先交獨立 Plan-Reviewer，通過後依既有 Implementer→Tester→Reviewer 流程補測，不新增工具 gate；新結果獨立保存，歷史及其審查結論不覆寫。T03 acceptance 目前未執行；兩輪簽章 preflight 結果見 E005，不預先宣稱 T03 或主假設成功。
