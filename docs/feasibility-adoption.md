# 可行性成果選擇性採用紀錄

## Rivet Login UI：2026-11-17

Topic：`rivet-login-ui-adoption`。識別 LU-A01–LU-A06 為本輪補建，不回寫實驗 README 或改判實驗四狀態。Human 已接受正式 UI 元件化範圍；真正認證整合另行處理。

### 來源、條件與授權

- 觀察基線 `1f31b35604adb5bb36326e52f9d6dbcff0cac763`；正式 View 來源 `dcc48b29686ab324fc19399ef607f462a507cce5`，E011 收納 `7e5f4fd44c64a956ed133096939d42f37de4ff2f`。
- 原素材與 UI topic 只支持其特定版本、有限字級與原生案例；舊 Human 接受見 `plan/rivet-login-ui/evidence/verification.md:683–689`，不是本次二進位驗收。
- 正式需求及鎖定決策見本 topic requirements／technical-spec；已授權受限 UI 實作與 Draft 交付。正式接入由 E011 消費 Presentation，無反向依賴。

### 初次實作查核的能力、依賴與當時程度（歷史）

| 識別／能力 | 方式與理由 | 依賴及滿足方式 | 程度／實際接入與證據限制 |
| --- | --- | --- | --- |
| LU-A01 品牌／雙欄／七態／資源 | 重用正式能力，非重新搬素材 | 現有 RivetLoginBrand、palette、resources、phase | 已採用，限原 UI 契約；本次 root 組合仍使用原資源，Demo build與focused tests支持接入，native重構回歸待獨立驗證 |
| LU-A02 PAT 編輯／字級 | 抽取調整到 LoginPATForm，沿用既有 helper | RivetLoginTokenInput、Typography 已具備；不重建 PersonalAccessToken VO | 部分採用（本次抽取）；helper／字級 tests綠燈，form 的 identity／Show-Hide／callbacks 真 UI 證據待 Tester |
| LU-A03 焦點／宣告／快速離開 | 按元件責任調整，保留 task 取消 guard | 既有 SwiftUI focus／accessibility 與有限 AppKit announcement | 部分採用（本次重構）；source／build已接入，native時序及Human聲音待驗，不沿用舊pass冒充新版 |
| LU-A04 正式文案／接線介面 | 改寫產品預設與抽取 host demo copy；新增建立 intent | 既有 phase／intents；此次新增 content與可用性；E011 fake callbacks | 部分採用；公開 API／文案自測及Demo build已完成，真UI事件驗證待Tester；VO對應只在文件，不代表真認證採用 |
| LU-A05 E011 host／Controls／假流程 | 不採用到production；保留受控消費端 | E011維持既有targets，使用同一正式元件 | 已排除搬移；只調整host接線與copy，無library demo mode |
| LU-A06 E013／E014 認證／診斷 | 不採用；不符合本次UI範圍 | 真request／service／async／storage／session不是本次必要依賴 | 已排除；原工具／來源未搬入、未修改，不把驗證成功當正式登入完成 |

### 初次已完成項目與當時缺口（歷史）

正式元件與呈現資料已實作，E011 host 實際接入；32 個 focused tests／7 suites及正式 Demo build通過。測試只支持執行過的helper、content與model案例，不支持尚未執行的native互動。root suite受未改基線編譯缺陷阻擋，見本 topic I01 evidence；不宣稱root通過。

必要依賴由既有正式 UI 能力及此次content／事件介面滿足，未依賴其他實驗整包。能力等效與來源關係分開：登入 VO 是既有正式契約，只引用其對應，不宣稱由本次 E011 採用。未完成的native、獨立Tester／Reviewer、Human聲音與最終UI接受保留，下一步沿原流程補證，不修改原topic歷史。

### 歷次更新

- 2026-11-17：唯讀audit先記LU-A01–03原契約已採用、LU-A04部分、LU-A05–06本次排除。實作後新增各子能力的新版缺口判定，原接受紀錄保留；本次來源為base＋feature工作區尚未commit，不填虛構SHA。待獨立驗證後按實際證據續記，不覆蓋本輪限制。

### Draft 交付補充：2026-11-17

以上初次 I01／T01 觀察保留為歷史。交付實作 commit 為 `d762f935ec2d4e220e7bc2135e6b80daa21bef3e`，整合 base 為 `ab77391b73291deb1ce3d96cef72f981aeb3104a`；[Draft PR #75](https://github.com/a129924/rivet/pull/75) 以 dev 為目標，未 merge。

獨立 Tester 已完成有界驗證，focused32 tests／7 suites、Demo build／scoped checks與圖hash通過，但TC02／03／05 native未驗；R01及post-rebase補充皆approved僅Draft交付。原root基線編譯失敗由上游修正，整合後root361 tests／46 suites實際通過，不覆蓋舊失敗。

LU-A02／03／04的native互動／時序及Human聲音／最終UI接受仍缺證據，維持部分採用；不把root全測通過當成native UI已驗。來源與接入關係不變，沒有新建登入VO或接認證／儲存／session。最新缺口改由Draft Human checklist續驗，詳見本topictesting／review／delivery evidence。

### 原生補驗更新：2026-11-17

本輪受測正式來源`83543b0`，原生互動證據見`plan/rivet-login-ui-adoption/evidence/native-ui.md`。以下為新增觀察，不改寫前述I01／T01及Draft交付當時的部分採用歷史；R02將獨立審查此分類。

| 能力 | 本輪程度 | 新增接入／行為證據與剩餘限制 |
| --- | --- | --- |
| LU-A01 品牌／雙欄／七態／資源 | 已採用，限受測UI契約 | E011與公開元件fake consumer實際呈現；48組AX／呈現與代表性視覺／捲動證據；最終Human視覺接受另列 |
| LU-A02 PAT編輯／字級 | 已採用，限受測UI契約 | 同identity切態、Show-Hide、字級／copy保留、trim／單次提交／立即清除、離開與Reset均由原生UI操作補證 |
| LU-A03 焦點／宣告／快速離開 | 部分採用 | 可觀察鍵盤焦點與切態後不拉回已補證；VoiceOver聲音／焦點及宣告時序仍缺Human證據 |
| LU-A04 正式文案／接線介面 | 已採用，限UI介面 | 正式預設與E011展示copy分離，fake parent原生事件計數補證七種intents／Create可用性；VO仍僅文件對應，沒有真認證接線 |
| LU-A05／06 驗證host／認證診斷搬移 | 已排除，理由不變 | 外部fixture只作本次驗證，未搬進production，未新增VO／Adapter／儲存／session |

採用程度不等於Human最終接受或產品登入交付；沒有用root測試數量代替本次native行為。

### Human VoiceOver 補驗更新：2026-11-17

正式來源`1d5f2a0`與T02的Swift元件相同；[T03](../plan/rivet-login-ui-adoption/evidence/voiceover-human.md)記錄Human實際聆聽的H01–H08及外部fixture雜訊。前述LU-A03部分採用保留為當時缺口，以下只新增本輪證據，不回填舊結果。

| 能力 | 最新程度 | 行為依據與限制 |
| --- | --- | --- |
| LU-A03 焦點／宣告／快速離開 | 已採用，限所列受測UI案例 | 已有正式source／E011及公開consumer接入、T02鍵盤證據，本輪Human確認正常流程與同主窗Account→Welcome／Token→PAT；後者PAT焦點、直接輸入及無晚到舊語音有明示回報。不是所有race／OS語音佇列保證，最終視覺／UI接受仍pending。 |
| LU-A01／02／04 | 已採用，原受限範圍不變 | 本輪無正式元件修改；聲音補證不擴成真VO／service／Adapter整合。 |
| LU-A05／06 | 已排除，理由不變 | 展示／外部測試host僅作受控消費端，快捷鍵不進production；認證／儲存／session不在本topic。 |

證據來源是Human對話回報，無音檔或精確時間量測；跨視窗Controls未驗及原`⌘⇧3／4`截圖衝突不算元件失敗，也不算通過。第二組只改外部host兩個快捷鍵為`⌘⇧7／8`後取得新確認，第一組與先前結果保留。採用方式及來源關係不變，本輪更新經[R03獨立審查](../plan/rivet-login-ui-adoption/evidence/voiceover-review.md)approved，僅限補證與既有Draft更新；不因checkbox或文件存在推定approval。

### Human 正式 UI 接受：2026-11-17

Human明確回覆「接受目前這版正式 Login UI／UX」，[HC01紀錄](../plan/rivet-login-ui-adoption/evidence/human-acceptance.md)對應交付`3c9baf3`、乾淨預覽程式`42e99fa`及binary SHA4d4cf13f719e…。前述T03／R03當時的最終接受pending保留為歷史；最新正式文案與視覺／UI已獲Human接受。

LU-A01／02／03／04維持「已採用，限既有所列UI契約／受測案例」，採用方式不變；本次只是Human接受，不增加未執行的native／VoiceOver結果或外推所有環境。LU-A05／06仍排除正式搬移；驗證host與乾淨預覽是分開的消費端，真認證／Adapter／儲存／session仍不在本topic。原來源與歷史限制不覆寫，PR仍Draft／未merge。

### R3：2026-11-18 驗收 consumer／ownership 修訂

- 正式LU-A01–04能力、來源關係及既有Human接受保持；本輪不改public API/content/child/helper或登入VO，也不拿舊結果直接填新host通過。原I01/I02當時授權、T/R歷史、H01–H08、HC01/source3c9baf3／preview42e99fa／binary4d4cf13...保留。
- LU-A05現行方式為凍結歷史source：E011定點回復至d2332bf／tree b6a1e6e1196e64999af9591ec32f09211f1936c6，不再用作本輪正式驗收。Frozen host依現.standard可編譯不證明舊demo文案等效；歷史重現須完整freeze revision或舊binary，不新增formal demo mode或footer/bundle特判。
- 驗收改由直接正式tests與DEBUG controlled#Preview優先；必要native工具位於tools/acceptance/login-ui，僅依賴RivetPresentation，自有有限parent/config/fixtures/window/menu，submit立即丟棄payload，只記kind/count。新tool是驗證素材，不是新產品能力或認證Adapter，不重新採用E011模型／服務。
- I03先做source/build/test，工具單元測試只支持工具parent；真Canvas、same-window callbacks/focus/resources、新host及必要Human差異仍待獨立補驗。先獨立review，再提出exact新app/source/binary SHA取得當下確認，舊接受不授權新binary啟動。產品認證、儲存、session整合維持排除。
- 目前實作與新驗收結果見本topic acceptance-ownership-implementation／testing／review；只有實際發生才記新證據，不覆寫前述歷史或其他OAuth registry段落。

### R3 最終接受：2026-11-18

Human明確回覆「接受本輪驗收支援分離、封裝修正與差異補驗結果」，[HC02接受紀錄](../plan/rivet-login-ui-adoption/evidence/acceptance-ownership-human-acceptance.md)對應受測code`9d14a3f`、交付證據`196f42c`、source manifest `3e748de3…`、binary `6a7867b5…`與app tree `ccfbbd96…`。F01–F06有限native／獨立資源runtime與V01／V02 Human聲音回報已有R07 bounded approved；LU-A01–04正式能力及LU-A05凍結歷史consumer／新tool的驗收歸屬依上述來源成立，沒有新增產品認證接入。前述R3待驗及舊E011授權是當時歷史，不倒改。

Canvas仍未驗，Human接受提示已列gap，不填pass；不外推完整矩陣、所有race或其他SwiftPM／分發環境。真auth／Adapter／store／session／navigation／產品App仍排除，原HC01及所有歷史判定保持原版本。Draft維持、未merge；本次接受記錄沒有新tests／build／native結果。

## github-oauth-connection-orchestration — 2026-11-17

### 來源與目標

來源 revision `ab77391b73291deb1ce3d96cef72f981aeb3104a`；[需求](../analysis/github-oauth-connection-orchestration/requirements.md)、[來源驗證](../analysis/github-oauth-connection-orchestration/source-audit.md)、[有界盤點](../analysis/github-oauth-connection-orchestration/adoption-audit.md)。A01–A06 是本輪補建識別，沒有改寫 E014 的驗證四狀態或歷史 Human 結果。

目標是 OAuth 冷啟動與重新授權的可行性／採用方案。正式來源仍未接產品 owner；本次交付文件與地圖，production zero diff，不是正式組裝完成。

### 選擇性採用方案

| 能力 | 選擇與依賴 | 接入及預定驗證 | 完成程度 |
| --- | --- | --- | --- |
| A01 冷啟動 | 重用正式 configuration store、clientID-bound credential store、GitHubOAuth factory、OAuthTokenProvider、GitHubClientScope；不新建重複 storage 或改 public API。 | 未來組裝端載入 configuration，保留 nil／error 差異；prepare 後才交付本地 ready。正式接入位置尚未授權，不補造檔案。 | 部分採用：primitives 已有；正式 startup 未接。 |
| A02 錯誤區分 | 沿用 missingCredential／authenticationRequired／credentialLifecycle stage／invalidAuthorizationToken，保留 configuration store error。 | 未來測 absence、讀取／刷新／保存失敗、取消；不擴初次 authenticate Outcome。 | 部分採用：errors 已有；呈現與復原未接。 |
| A03 退休與交接 | 重用正式 signOut；依賴 clearing store、排除其他 writers、owner 序列化與舊世代結果丟棄。 | signOut 成功後才 authenticate；clear failure 停止；取消／失敗不復活舊連線。signOut 不代表所有舊網路工作 settled。 | 部分採用：退休 primitive 已有；整合未接。 |
| A04 新 provider | 完整 authenticate success 後，才用同 clientID-bound store 建新 provider／prepare；暫時錯誤 retry 原 provider。 | 未來驗完整交接；若 save 後才取消，新 credential 可能存在，不 rollback／不當成 absent。 | 未採用：正式 owner 不存在。 |
| A05 驗證專屬構件 | 排除 E014 UI／probe／clock／receipt／App-local adapter 及清 reference retire；不整包搬入。 | E014 僅有限歷史參考，不承接新 source 的 live 保證。 | 已排除。 |
| A06 來源關係 | 既有等效能力足以形成方案；未查明的實驗來源不作採用主張。 | 若需宣稱源自 E014，須另有歷史證據。 | 不確定。 |

### 依賴、限制與實際交付

既有登入服務建構仍需提供 PAT store（建構不操作 Security，OAuth 分支不讀寫 PAT）；這是既有 public initializer 依賴，不擴張成 PAT 連線。必要 primitives 已存在；尚缺正式 owner、產品接入、世代／並行策略實作與組合行為證據。沒有把方案、primitive 測試定義或 E014 成功當正式已採用；本輪沒有重跑 Swift tests 或 live，也沒有新可行性實驗。

後續正式實作須另鎖接入位置、allowlist、interfaces 與驗收。本紀錄保留「部分採用／未採用／已排除／不確定」分類；本輪採用方案交付 **COMPLETE**，正式 orchestration 實作未執行。

### 歷次更新

2026-11-17 首次記錄本 topic，依 source-audit 與 adoption-audit 建立方案；不覆寫其他 topic 或實驗歷史。圖面及製圖檢查見[執行帳本](../plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.step.md)。

## OAuth 冷啟動連線還原正式採用

Topic `github-oauth-startup-restore-runtime` 將既有configuration store、clientID-bound credential store、正式fetcher、provider與scope組裝為caller-owned入口；採用唯一provider、保存後發布、busy與取消settlement，不複製E014 App-local coordinator、UI、probe或驗證控制。

[正式契約](architecture/github-oauth-startup-restore-runtime.md)與[受控證據](architecture/diagrams/github-oauth-startup-restore-runtime/BUILD.md)獨立於E014真人結果。Root375tests／consumer22tests通過；未做新OAuth／DPK、不宣稱產品UI或遠端認證完成，Human review pending。

### 2026-11-18：正式入口 E018 live 追加

原e31a75a受控交付後，Human另行授權live。新E018直接連結正式restorer／stores／fetcher，沒有複製E014runtime或重開其額度；first自然到期真refresh/save各1，fresh同完整credential／同帳號且refresh/save0，兩段Human各全程0提示。實際新host AppID不同、現有profile授權exact舊group，不能回填舊App profile續期。資料保存不rollback、不cleanup；詳[獨立證據](../plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)。

### 2026-11-18：正式 hosted 設施 N輪有限Live

Active E018退役後，正式hosted test bundle／runner沿用唯一正式還原實作，以新授權各完成first／fresh一次；ready、API、完整credential讀回及同帳號新程序continuity通過，Human本輪兩段各全程0提示。兩段未到期、refresh／save全0，不把舊E018的自然到期refresh結果挪為本輪coverage。工具nested／inside-out signing修正與原失敗preflight各留來源；[N輪結果與限制](../plan/github-oauth-startup-restore-runtime/evidence/hosted-live.md)已由N06獨立有限結果審查approved、無required finding，Human最終接受pending，不擴產品功能或普遍環境保證。
