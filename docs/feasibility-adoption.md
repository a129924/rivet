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
