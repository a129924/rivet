# T07：新版驗收 host 原生差異初驗

> 前段保留binary9219…的原生初驗與RF03發現；本文末為修後6a7867… artifact的獨立封裝檢查。修後尚未launch，不能沿用初版native或啟動確認。

- 日期：2026-11-18；owner=Tester（主agent，非I03程式作者）。
- 受測來源：source commit5b256c5，文件head2e00167ef178fc0275d2dbaf2d7d12e412b474c0；28項source receipt為6c1d5266c7f10f2340ed383604fd8a74b3ff7f00a0411c276bd9df86a195921d。
- Human本輪明示：「許啟動新版 RivetLoginAcceptance.app，補驗上述必要原生差異」，承接上一回合exact binary SHA9219bd7656c55287ecb6ab1adc6d37f7f9b51e9b9217c15846cb27d8e0460b10。啟動前、測後已核對binary及28份source符合receipt；未重新build或修改source。
- App ID local.rivet.login-ui-acceptance；app tree原receipt6be23f92067767340b21cd00644943f7ffe72adbba3872de320ab94762c59eb3。
- 結果：**INCOMPLETE**。下列Dark原生操作有直接CUA／AX／畫面證據，但發現獨立資源封裝路徑缺口；Light及Human聲音未完成。交獨立R07分類，不自審、不把舊HC01套新版。

## 直接原生觀察（限本binary）

全程使用CUA操作已確認app，輸入僅本地合成字串，不使用真PAT／OAuth／憑證／session；不保存提交payload為event receipt。主對話有直接AX輸出與三張代表性Dark截圖，未另保存圖片檔；不能假稱Reviewer已親看未轉交圖片。

| Case | 實際操作與結果 |
| --- | --- |
| N01 default | 成功啟動一個Rivet主窗，預設system外觀在當機呈現Dark13；正式Welcome、footer及GitHub圖示可見，主畫面無Demo Controls／fake／simulation／測試overlay；keyboard focus在Continue with GitHub |
| N02 Return | Continue上Return→waiting；Cancel的可及性文字可見，focus到Cancel；Acceptance receipt=beginGitHubSignIn／Count1 |
| N03 Escape | 主窗直接Return→waiting→Escape→Welcome，focus回Continue。另一次有開menu的流程，CUA仍回傳menu AX，使用其明示Cancel secondary action關閉後核對Welcome；receipt cancelSignIn／Count2，未將menu AX現象當聲音結果 |
| N04 PAT | 真正點PAT入口→secure field／正式label且focus到欄位，直接輸入合成文字；Show保留文字並轉可見欄位，無另點欄位即可繼續編輯 |
| N05 settings identity | 用Acceptance menu選17pt、Controlled content、再回Standard；合成文字與Show狀態保持，field label隨content更新；AX focus保持欄位 |
| N06 create | menu開啟create availability，不清文字；實際點建立入口不離開PAT、未開browser。Reset後另一段實際點擊確認receipt=createPersonalAccessToken／Count2（同段前一筆submit為Count1） |
| N07 failure/font/scroll | menu PAT→token failure保留輸入／Show狀態；切21pt後可捲至底部，直接截圖可見錯誤、Submit與footer；再回PAT仍保值。這是Dark21代表畫面，非完整48組矩陣 |
| N08 Reset | menu明確Reset→secure空欄、Show、Submit disabled、focus到欄位；選13pt後仍空，沒有保留舊輸入。Reset保留phase／其他呈現設定符合工具契約 |
| N09 submit | PAT中輸入合成文字後Return→正式Verifying token；receipt=submitToken／Count1。menu回PAT→secure空欄／Submit disabled，舊值不在欄位 |
| N10 recovery | PAT Back→Welcome，focus Continue；menu browser failure→Try again focus；Return→waiting、Escape→Welcome且focus Continue。這些確認實際回呼／呈現，不宣稱每筆未觀測receipt均單次 |
| N11 menu transitions | menu Verifying account→Welcome，最終AX focus Continue；Verifying token→PAT，最終secure field focus，不點欄位即可直接輸入合成字串；Reset清除。每次為有界序列操作，不稱未量測的race／延遲朗讀已通過 |
| N12 completion | menu Completed→正式Sign-in completed／This sign-in attempt completed successfully，Dark13截圖可見；此工具受控phase不表示真登入或session |

八種畫面變體均有本輪實際AX觀察；字級13／17／21與Standard／Controlled只有上述代表操作，不外推所有組合。標準Edit／Quit和Acceptance均出現在menu bar；未讀取／貼入使用者clipboard或修改系統設定。可見Github圖示尚不能證明取自app內bundle，詳下節。

## 資源封裝缺口（待獨立審查分類）

生成的resource_bundle_accessor.swift實際先以 `Bundle.main.bundleURL.appendingPathComponent("Rivet_RivetPresentation.bundle")` 查找，失敗才用當次SwiftPM絕對buildPath。現行build-app.sh卻複製至 `Contents/Resources/Rivet_RivetPresentation.bundle`，而非app根目錄；正式LoginStyles的圖示直接使用Bundle.module。

因此app包裝內確有正確PDF bytes，但不在此accessor優先查找位置。目前建置目錄仍存在，可見圖示與fallback相容，不能宣稱已完成脫離build cache的獨立資源載入。這是依生成碼與實際路徑的來源推論，沒有用debugger偽裝runtime trace；也沒有為探測而刪／改cache或正式元件。

最小候選修正：僅工具腳本按當前accessor將同一正式bundle置於app根目錄，更新app／source receipt；正式View、資源bytes、rootmanifest與E011不改。修後需fresh process且受控排除buildPath fallback來補實際圖示驗證，不能直接沿用本次可見圖示作pass。

## Light入口限制與無效嘗試

為補Light代表畫面，先用本app標準Quit結束instance，getAX回procNotFound與已結束一致。CUA無帶args啟動API，接著嘗試取得Apple Terminal準備同app的Light CLI啟動，被工具拒絕：

> Computer Use is not allowed to use the app 'com.apple.Terminal' for safety reasons.

沒有進Terminal、沒有執行命令，也沒有改用其他入口繞過此拒絕。其後以已允許的exact app重新開啟預設Welcome，未帶appearance參數；不能因此稱Light已補驗。若需改用shell標準open，須先由Human明示該工具方式；否則由Human操作既有CLI。這是工具能力／安全限制，不是正式元件Light失敗，不修改系統設定或刪除Light接受條件。

一次CUA點擊使用了切態前的舊element7，工具回invalid element ID；隨即依新AX的PAT入口19完成操作，沒有app修改。唯讀ps初次受sandbox限制，後以明示的唯讀escalation核對exact process；沒有以此控制GUI或繞過Terminal限制。以上不列app pass／failure。

## 目前狀態、歷史與下一步

最後已恢復預設Dark13／Standard Welcome、focus Continue。唯一exact app PID42461與reviewed binary路徑吻合，SHA未變、28source吻合、rootlock SHA仍7d3387a0b8f2bb5244bff91b9118e8ba17b3f71861a5a8a31c6693163449d4db。沒有停止其他app、修改dev／E011／正式source或重跑無關tests。

Human實際VoiceOver還未在新host回報，沒有音檔或語音逐字證據；AX focus不能代替聲音。需要的差異限新menu Account→Welcome與Token→PAT（最終朗讀／焦點／直接輸入／晚到舊語音），及實際修正影響範圍。原H01–H08／HC01／source3c9baf3／preview42e99fa／binary4d...接受保留，不重做全部舊案例；也不能把原接受當成本次host已接受。

交R07獨立分類資源缺口、Light入口與Human停點，必要修正留在工具既有allowlist。T07 coverage INCOMPLETE／HC02pending／PR Draft、未merge；沒有新Human接受。

## RF03 修後獨立封裝／source 檢查（尚未新 native）

Implementer只修tool腳本的bundle目的位置與receipt路徑，正式Swift／tests／資源bytes／root設定／E011不變。Tester於新external run親跑build-app.sh，exit0、cold product build與plist成功，沒有launch新app或移動任何fallback資源。

獨立逐項核對28source bytes、canonical source digest、app各entries bytes／mode／type及tree digest均符合新receipt。和初版6c1d source清單比較只有script不同；rootreadonly before／after與既有值相同，沒有重跑未變Swift的formal／toolunit。

| 修後檢查 | 結果 |
| --- | --- |
| Generated accessor首選位置 | 仍為Bundle.main.bundleURL／Rivet_RivetPresentation.bundle |
| 新app首選位置bundle | 存在；GitHubMark.pdf1812bytes，SHA37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1 |
| 舊錯誤Contents/Resources位置 | 不存在，沒有複製兩份resource掩蓋尋址問題 |
| 獨立純Foundation probe | Bundle(path: packaged bundle)及url(forResource:)成功，PDF位於該bundle、1812bytes；只證bundle可讀，非app fresh-process runtime證據 |
| bash syntax／diff-check | exit0 |
| GUI launch／fresh process／fallback排除 | 未執行，新app沒有Human當下確認；buildPath仍保留，未改cache來冒充驗收 |

目前準備的新artifact是同名RivetLoginAcceptance.app／local.rivet.login-ui-acceptance，來源head2e00167＋RF03受限工作區；可由完整receipt辨識：

- Source manifest SHA-256：`3e748de3a3b19225e1a03160d90318037a0be8430b13b911ec2e958b34bdd988`。
- Binary SHA-256：`6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1`。
- App tree SHA-256：`ccfbbd965a9a8b40e4b3df22562f7542d02b2dc28a93f9a3b4a6df2988877cae`。
- Script SHA-256：`9a88a9b2d2b0a90a0e19c3bd3059d5cc28a538d644f0c3c337c9683cda1059c1`。

同一正式Swift source在新scratch產生不同debug binary SHA，不能稱同binary，也不能把9219的當下確認套到6a。以上僅完成受影響的source／包裝準備；交R07作source-only差異復審，未自行改判requiredfix closed或native通過。

### 後續有界 native／Human 範圍

1. source-only復審後，取得目前exact新app的當下確認；為完成Light，須Human同時明示可用標準shell open帶既有appearance args。只改app自己的初始外觀，不改系統設定；未取得明示前不使用shell控制GUI，也不再操作被拒的Terminal UI。
2. 驗明並結束唯一舊9219 instance後，對新run唯一buildPath resource bundle做可逆且精確的暫移（保留bytes/hash與還原位置，不改source／global cache／app）。在fallback不在原位置時啟動fresh process，直接觀察Welcome與GitHub圖示，再依證據還原fallback；不得用已初始化Bundle.module的舊PID。
3. 補Light代表畫面與必要Dark對照、新資源載入、受影響基本鍵盤／回呼；保持既有N01–N12的原版本，不擴成48組重測。
4. Human只補新menu Account→Welcome與Token→PAT的最後朗讀／焦點／直接輸入／晚到舊語音；新host差異接受仍由Human明示，原HC01不重開。

目前T07 coverage仍INCOMPLETE，RF03 source-only復審pending，HC02／Light／Canvas／新artifact native pending。Raw script與probe logs保留repository外scratch；沒有新app PID／AX／截圖／聲音或Human接受，沒有merge。
