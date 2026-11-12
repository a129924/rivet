# 驗證產物歸屬修正：步驟帳本

最後更新：2026-11-12。分支chore/verification-artifact-ownership；B1／B2完成。VO-RB3契約Gauss approved0、Raman18hosted／67PKCE passed0、Noether成果approved0，原空白配置阻擋解除；先獨立提交修正再續B3final／E009原pin檢查。B3未搬，B4–B5未開始。
四實體文件已落檔；先前 draft-only approved／0 fixes 不挪作正式 gate。逐檔資料只引用 [spec](../../analysis/verification-artifact-ownership/technical-spec.md#唯一逐檔清單)。

| ID | Status | Owner role | 完成條件 | 驗證證據／缺口 |
|---|---|---|---|---|
| VO-P01 | completed | Explorer | 五組分類、E009角色、wrapper及主要接線查證 | 基準a554a4f；E009現行入口；73file單一spec；候選配號未reserve |
| VO-P02 | completed | Tester | 限定離線基線已執行並分類 | plan基線；不表示失敗解除或必要項全到達 |
| VO-P03 | completed | Plan-Creator | 四正式文件落檔，納最新驗證／pin要求 | 本四檔；未自判品質或gate |
| VO-P04 | completed | Plan-Reviewer | 正式實體審查 approved 且 required fixes=0 | Popper 已審四實體，approved，required fixes=0；73/73 source hash 相符 |
| VO-P05 | in-progress | Explorer | 各批前配號／mapping／差異／入口鎖定 | B1 E011／B2 E012已完成；B3 E013 mapping／入口已鎖spec，Nash契約approved0，execution blocked；B4–B5 pending |
| VO-B01 | completed | Implementer | B1契約內完整搬移，交Tester | 四檔100%rename，三target path／lint／索引／入口同批；必要post已到達，Meitner最終approved |
| VO-T01 | completed | Tester | B1必要項真正到達並給出結果 | 主對話post編譯／62tests／新wrapper資源入口已驗；Kepler獨立親跑62pass0fail0skip，readback artifacts相符 |
| VO-R01 | completed | Reviewer | B1獨立成果審查與限制分類 | Meitner最終approved、required fixes0；README離線cache操作RF已關閉；只限B1 |
| VO-PB2 | completed | Plan-Reviewer | B2契約明示approved且required fixes0 | Feynman正式approved／0fix，7/7hash核對；僅preimplementation |
| VO-B02 | completed | Implementer | B2同批接線並交Tester→Reviewer | 七檔puremove／三target／bundle輸出／lint／導覽同批完成；post主對話必要項已驗；Tester Chandrasekhar passed0；Reviewer Schrodinger approved0，准續B3 |
| VO-PB3 | completed | Plan-Reviewer | B3契約approved且required fixes0 | Nash最終approved0，RF-1 closed；不放行失敗baseline |
| VO-B03 | blocked | Implementer | B3接線及E009最終產物相容性，交Tester→Reviewer | 未搬source；baseline17tests中1fail／2issues，需行為決策；final binary／pin未知，不自動更新 |
| VO-B04 | not-started | Implementer | B4完整搬移，交Tester→Reviewer | 依賴前批；無搬移 |
| VO-B05 | not-started | Implementer | B5完整搬移，交Tester→Reviewer | 依賴前批；無搬移 |
| VO-D01 | in-progress | Implementer | 已審bounded topic commit、push、Draft PR交Human | B1／B2已commitpush同DraftPR69；B3處置文件待獨立審查／發布，未宣稱五批完成 |

## Blockers

| ID | 狀態／問題 | 解除條件 |
|---|---|---|
| BL-P | resolved | Popper 正式 approved、required fixes=0；不等於五批執行通過 |
| BL-N | B1–B3配號已確認；B4–B5 pending | E011/E012已完成；E013占用／hash查證並鎖定，B3 baseline blocked |
| BL-B1 | resolved（B1） | baseline／post真正source build、62tests、wrapper資源／入口與獨立成果approved0，commit7e5f4fd |
| BL-W | resolved（B1） | recipe、baseline與post新wrapper／PDF資源／離線操作均已實際驗證；未覆蓋歷史freeze |
| BL-PK | 本輪baseline已解除；歷史失敗保留 | Socrates normalhost親跑67pass／0fail／0error／0skip，loopback／helper已到；不解除BL-B3 |
| BL-E9 | 現行E009 pin與新binary相容性未知 | B3實測最終身分／hash／既有preflight；失配先回報／修契約 |
| BL-O | B4／B5 source build及必要入口未驗；歷史DPK有8skip | B3 baseline source build已pass但hosted有1fail；final及post未驗，不能放行後批 |
| BL-B3 | resolved（VO-RB3） | Gauss契約approved0、Raman18hosted／67PKCE pass0、Noether成果approved0；原失敗保留，不代替BL-E9 |

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

## B1 搬移前實測與停止（前輪歷史）

Tester Newton 在 feature branch／基準 a554a4fee772d3976d5ca2c9331865a604e901e2，僅跑一次既定 swift build 離線命令，exit 1。
manifest 編譯因 ModuleCache 寫入 Operation not permitted 及 .build/repositories 寫入限制受阻，另報無法載入目標標準函式庫；底層權限原因未調查，維持 unknown。
未到 product source、資源或入口；model／Presentation tests、wrapper／bundle 資源與新版原生入口皆未驗。沒有以相同失敗判定無回歸。
Tester 確認 tracked staged／unstaged diff 不變，未修改系統權限、環境、安全限制，未重試或啟動真人流程。
B1 not-started，B2–B5 not-started。僅文件 WIP 交付，不交接任何半套來源給下一批。

## 主對話受限執行上下文查證（前輪歷史，2026-11-12）

Human 新增有限授權：本次可用 SwiftPM／compiler 標準參數把輸出、scratch、cache 指到可寫位置；不改系統／全域／簽章／安全／版本，不停用 sandbox，不在 dev 實作。
主對話（非 side chat）於 revision 2103e5624ec7597aca2c7eefac879b6c330aa4b6 執行原 build、可寫路徑 dump-package 與完整 build；完整命令及證據僅見 [plan 的本輪重現](verification-artifact-ownership.plan.md#主對話-b1-局部建置路徑重現2026-11-12)。
實測 scratch/cache/modules/logs 可寫，新 Swift／PackageDescription cache 實際產生；完整 build exit1、1.113s，錯誤改為 sandbox-exec: sandbox_apply: Operation not permitted。
標準 sandbox 啟動被拒的背後政策原因 unknown；不直接沿用先前推測，不把不同條件的失敗當成等價。
VO-T01 仍 blocked：未到 B1 source、tests、資源或入口；VO-B01–VO-B05 仍 not-started。沒有搬移或安全繞過；本輪只補現有 plan／step 的命令與證據，不複製單一逐檔清單。
本輪文件增補已由獨立 Plan-Reviewer Nietzsche 審查：approved，required fixes=0；只確認文件與主環境原始證據一致，不放行 B1，也不挪用前輪 approval。最小下一步交 Human：以能啟動標準 SwiftPM sandbox 的適用環境重跑同參數基線，成功後仍須完成 B1 必要 source／tests／資源／入口驗證。

## Execution Authorized：B1 基線重建及實作前鎖定

主對話以 Human 本次授權的正常本機執行上下文完成標準 sandbox manifest、B1 source build、62tests／6suites與 baseline新wrapper原生UI；詳 plan 本輪新基線。早先受限上下文失敗保留，不改寫成已通過。
BL-B1 的原主環境受限上下文阻擋在新環境已解除；B1搬移後必要驗證仍未執行。BL-W 的既有recipe已確認且baseline真驗；不得宣稱post已驗。
E011與B1四移檔＋操作README、必要接線已鎖在唯一spec；B2–B5仍未開始。B1實作前契約補充待獨立Plan-Reviewer審查，不挪用前輪approved；審查前不搬來源。

### B1 實作前增補審查回修

Kant 正式審查 needs-rework、required fixes1：現行摘要／狀態須與新基線一致。已只更新現行表格與歷史標籤，保持B1未搬／post未驗；修正待原Plan-Reviewer複核，不自行填approved。

### B1 實作完成交接（post 前快照）

獨立 Plan-Reviewer Kant 最終 B1-preimplementation approved，unresolved required fixes0；唯一帳本 RF 已關閉，不視為 post 通過。
Implementer 已依 plan 的 swift-implementation 九欄與 spec 唯一列完成 B1：四移檔 bytes 相同，僅必要接線與用途／操作文件。實際 Written／Deleted／Modify 集合依 spec B1 列；B2–B5未動，正式 UI／測試與root graph保留。
TestCase TC-VO-002／003／008／009／010 尚待本批 post build／tests／資源／入口及獨立 Tester／Reviewer；不以 baseline 放行。

### B1 post 與獨立 Tester 完成

主對話post build與62tests通過，親驗新wrapper／PDF與假流程操作；Kepler獨立親跑62pass0fail0skip／6suites，核對4hash／3target E011輸入／正式graph與lockfiles保持，format／lint／shell語法通過。細節見plan完成交接及外置receipts；不另維護檔案清單。
BL-B1／BL-W 已在本次授權正常host條件下解除；原受限上下文失敗仍為歷史。B1成果待獨立Reviewer，B2–B5未開始，不由Tester或作者宣稱gate。

### B1 最終成果審查與交付

獨立 Reviewer Meitner 首輪 needs-rework 僅1項：README新空cache缺少具體準備。已於同一允許README補齊本機barecache、Package.resolved revision、copy後核對與失敗即停，未新增工具或版本。
主對話實跑修後README第一段：exit0／25.972s，固定本機cache、source編譯與62tests6suites通過；log SHA ed058de529a63e85d3ff07ca50c6d756d0e8105d183d3dad314063e78e091788。Reviewer核對stagedREADME／receipt／rawlog一致，最終B1 approved、required fixes0，唯一RF關閉。
本結論只限B1。B2–B5尚未開始，E009 pin與其他topic歷史未改；本次提交依Human既有直接commit／push／Draft PR授權，最後交Human review，不自行merge。

## 接續B2–B5：唯讀確認及B2 preflight

已由主對話確認feature乾淨、HEAD/upstream/PR69head均7e5f4fd，B1 Meitner approved／0fix記錄仍在；不把Human摘要當即時事實。正常host與本次scratch/cache仍可用。
B2 E012與七移檔／必要接線鎖在spec；baseline實際bundle同bytes、68Swift tests、99TS與CUA Viewed往返已驗。原受限coverage失敗／raw-entry CUA識別限制分列於plan，不算pass。現等獨立Plan-Reviewer，沒有提前搬檔。
B1交付不是topic完成。Human已重申全部五批授權；B2成果approved後續B3，B3遇具體pin／外部副作用或其他人類邊界才停，不能自行省略後批。

### B2 實作交接（post待驗）

Feynman正式B2-preimplementation approved、required fixes0。Implementer依plan九欄與spec唯一B2列完成七檔puremove與必要接線／E012操作README；Written／Deleted／Modify／ReadOnly只引用spec，不另建清單。
必要post：同條件product／68Swift tests／TScheck99tests／bundle同bytes／實際resource URL與Viewed往返；補充hash／graph／lint／入口語法。B3–B5未動，必待獨立Tester與Reviewer明示結果才前進。

### B2 post 主對話完成

新路徑source編譯與連結、68Swift tests／6suites、TScheck／99tests、bundle同bytes及原生資源／Viewed設定取消實際通過；完整命令與logSHA見plan，外置receipts見B1_RUN/logs/B2。wrapper實際使用SwiftPM build-bundle fallback，未誤稱獨立可攜包。Tester／Reviewer結果尚待，不由作者放行B3。

### B2 獨立 Tester

Chandrasekhar passed、required fixes0；68Swift tests／6suites與99TS tests、check／format／lint、7hash與graph／bundle／README語法均通過，必要項skip／blocked／unknown0。UI只核主對話證據；詳plan及logs/B2/tests-independent-summary.json。仍待獨立Reviewer，B3–B5未動。

### B2 最終成果審查與交付

Schrodinger正式approved、required fixes0、unresolved required fixes0；已核staged diff、七檔bytes、必要build／tests／resource／native入口及獨立Tester。Reviewer／Tester未重跑nativeUI；README全新空cache全流程未另跑，不增加驗收宣稱。B2完整提交後B2 commit d62e0ef已push；B3 baseline hostedtest失敗blocked，B4–B5未開始；B3–B5未開始搬移，E009 pin不自動更新。

### B3 preflight鎖定（未搬移）

B2 d62e0ef完整提交且hooks通過；E013編號與23sourcehash主對話查證完成，精確路徑與允許差異只見spec。九欄與正常host／標準sandbox／離線Xcode及PKCErecipe見plan。B3先取得新條件baseline；必要項未到或E009 pin拒絕則停，不從B2 approval推導B3通過。B4–B5未動。

### B3 必要baseline失敗（本輪現況）

主對話正常host build-for-testing exit0已編譯App／testbundle；test-without-building exit65，17tests／5suites中16pass、1fail／2issues：原CoordinatorTests252，空白配置相關canStart=true與期待衝突。具體source鏈與logSHA見plan，不把原因猜成權限或搬移回歸。E009僅compile／self-test成功，未跑App preflight，final artifact／pin相容性仍unknown。
B3 blocked／source未搬，B4–B5未動；不得進下一批或為全通過修改行為／測試。待PKCE Tester與獨立Reviewer分類；必要最小下一步是另行決策configuration與test衝突後重建基線，本輪只記錄證據與停止。

### B3 契約審查回修

Nash首輪needs-rework、required fixes1：九欄Modify錯含搬移後的內容例外，與Written集合重疊。已僅將例外引用歸Written，Modify限定留原位的列，未改清單／允許差異／scope；待Nash複核。execution仍因必要hosted baseline失敗blocked，不由契約回修解除。

### B3 正式獨立判定

Nash契約最終approved、required fixes0／unresolved0、RF-1 closed；Jason獨立成果verdict blocked，禁止搬移／後批，失敗文件及停止處置approved、required fixes0。23source保持原位及原bytes，問題與搬移無關；超出scope的行為／test決策保留1個阻擋，不將契約approved或文件0fix挪成成果gate。本輪等待PKCE Tester後只補事實／發布文件，不繼續source實作。

### B3 PKCE獨立結果與最終停點

Socrates指定命令一次，67pass／0fail／0errors／0skip，8.413s／exit0；兩loopback與helper／protocol真到達，23sourcebytes不變，詳plan及外置逐case receipt。局部passed0，不解除hostedfail；B3 execution blocked，B4–B5未開始。
本輪只有B2實作commit d62e0ef及B3契約／失敗證據文件；B3 source未搬、root／正式能力未改，沒有半套批次或pin改動。最新文件／PKCEreceipt交Jason複核後，依Human既有授權提交文件、push更新同DraftPR69並交Human，不自行merge或宣稱topic完成。

### 本輪停止文件最終審查

Jason核對最新三份文件與PKCE五份證據後，文件／停止處置最終approved、required fixes0、unresolved0；B3 execution仍blocked，不放行B3或B4／B5。主對話末查：B3／B4／B5共62個old source均原位原hash，對應new路徑不存在；dev工作樹乾淨且HEAD維持a554a4f。只提交本輪三份契約／證據文件；B2已完成的d62e0ef保留，不撤回已驗成果。更新同DraftPR69交Human review，不merge，不宣稱topic完成。

## 本次 Execution Authorized：VO-RB3

已唯讀確認feature／upstream／PR69均ec94bec且乾淨，沿同一worktree。Human允許受限修正及基線重建，再續B3；不再重問同範圍。直接依既有test／factory拒絕純空白，正式initializer不改；精確允許差異僅spec，九欄與TC-VO-012在plan。

| ID | Status | Owner role | 完成條件 | 證據／缺口 |
|---|---|---|---|---|
| VO-PRB3 | completed | Plan-Reviewer | 本次兩檔受限修正契約approved／0fix | Gauss approved／0fix，23原hash與newpaths未存在核對 |
| VO-RB3 | completed | Implementer | 只改明列兩檔、red／green／完整基線後交Tester | 兩檔最小修正／main18pass，最終format快照交Raman；未取代B3pin／postgate |
| VO-TRB3 | completed | Tester | 修正後完整hosted／PKCE及補充檢查實際執行 | Raman passed0；最終hosted18／PKCE67、formatlint與hash通過；不代替B3pin／post |
| VO-RRB3 | completed | Reviewer | 獨立成果approved／0fix，准解除行為阻擋 | Noether最終approved／0fix，只解除本次行為阻擋；不放行pin更新／真人流程 |

Gauss正式VO-RB3契約approved、required fixes0、unresolved0。先新增直接configuration測試取得red；本次approval不代替完整green與成果gate。

### VO-RB3 Implementer → Tester

Gauss契約approved0後，新增直接配置test：首次方法filter只有0tests，已明示未達；完整red18tests真失敗，最小guard後green18tests／5suites全部pass。只兩個允許source／test改動及現行配置規則／四文件，修後SHA維持spec單一來源，未搬source。完整命令／logSHA見plan；獨立Tester與Reviewer仍待，不把main green當gate。

### VO-RB3 Tester → Reviewer

Raman獨立passed／0fix：hosted18tests5suites與PKCE67全部pass，0skip／blocked／unknown；兩檔formatlint／hash及其餘21原bytes通過，未改repo。新版xcresult補充讀回cache限制分開保留，legacy讀回成功；不外推主對話權限、不修環境。Noether已完成diff review無RF，待完整Tester結果後給最終verdict。

### VO-RB3 成果最終approved與交付

Noether最終approved、required fixes0、unresolved0；Raman最終18hosted／67PKCE及兩檔formatlint／hash已納，原期待與正式契約保持。BL-B3解除，原17testfailure仍保留歷史。獨立fixcommit後續B3必要baseline-final／E009preflight，該入口／pin與全部post仍未驗；不自動放行搬移、B4或pin更新。
