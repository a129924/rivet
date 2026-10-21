# R 輪：反向 PKCE 診斷缺口唯讀調查

## 決定與來源

2026-10-21，沿用原feature／feat/github-first-sign-in／[Draft PR61](https://github.com/a129924/rivet/pull/61)，來源HEAD `21e2542ba1198b2498d9c616784185de887b5dcc`，調查開始工作目錄乾淨。原PR讀回OPEN/Draft、相同HEAD。未在dev實作，未新增worktree/PR、未merge。

本輪未找到有依據、能可靠增加遠端拒絕原因辨識的有限契約；依Human明示條件停止新真人驗證，R預算 **0/1 未使用**，未選case。本輪只交付文件，不修改工具/19模板/通過判準。這是現有材料下的工程判斷，不宣稱任何未來方案均不可能。R02獨立planning review approved、無required fix；後續Tester/Reviewer尚待實際核對。

CLI SHA256 `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`；三tools檔相對路徑+NUL+bytes+NUL指紋沿用 `6e01680d63e2f0647ab33c38aaa71306d27270d0950e39ac52fb2c199178d073` 為R修改前來源。工具README會新增R提示，因此CLI/tests bytes保持不變而三檔整體指紋會改，不能拿舊三檔指紋冒充文件更新後指紋。新README指紋由Tester實際核對。

## 查讀依據（2026-10-21）

- [GitHub OAuth授權](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)：S256／原verifier關係；code有效10分鐘；client/redirect契約；127.0.0.1 loopback允許當次port不同於設定port。
- [GitHub token errors](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)：client/redirect/code/email等錯誤；本次查讀頁面沒有給予Q19個synthetic PKCE完整句的官方保證。不是宣稱遍查所有GitHub內部實作或所有診斷方案。
- [RFC7636 §4.1/4.2/4.6及AppendixB](https://www.rfc-editor.org/rfc/rfc7636.html)：verifier字元/長度、S256、mismatch以invalid_grant拒絕及公開測試向量。
- [RFC6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2)：invalid_grant涵蓋invalid/expired/revoked/redirect/client等問題，非PKCE專用。
- 來源：tools/pkce_negative_probe.py的challenge/Attempt/authorization_url/exchange_fields/callback_code/authorize/send_token/classify/run_case；正式GitHubOAuth.swift／GitHubOAuthAuthorizationSession.swift／GitHubOAuthCodeExchanger.swift／Contracts/GitHubOAuthAppConfiguration.swift；App GitHubConnectionCoordinator.swift與relay。只讀source，不讀取或比較任何既有App配置/秘密。

## 候選原因、證據與限制

| 候選 | 已確認事實 | 推論／尚無證據 | 本輪判斷 |
|---|---|---|---|
| 固定完整句辨識限制 | §9 normalize後只做19句exact lookup；長度>512或未知完整句保持unknown；Q兩案description存在且提及verifier但class unknown | 無原文，不能知道是措辭/引用符號/額外context/長度、真正的PKCE語義或其它原因 | 已確認分類覆蓋有限；不是已確認遠端拒絕原因 |
| 預期missing/mismatch拒絕 | CLI missing省略欄位、wrong送不同合法verifier且先比較challenge；RFC mismatch相容invalid_grant | GitHub是否正因本項拒絕未證；keyword不等於肯定語義 | 候選相容，仍無法判定 |
| S256/format組裝bug | CLI32randombytes→43base64url，SHA256 ASCII→base64url無padding；Swift同算法；RFC公開向量通過 | 未找到實際組裝bug；fixture不證明過往wire與遠端state | 無支持bug的證據，不改正式OAuth |
| stale/reused code | 每process新Attempt；相符callback只能claim一次；單POST且無retry，期限300秒；GitHub文件code10分鐘 | 本機流程降低重用/延遲疑慮，但未觀察服務端code狀態/實際issued-at；不能證明遠端未過期或未被別處使用 | 未確認，不補造歷史時間或runtime欄位 |
| client/redirect關聯 | authorize與token form取同clientID及當次redirect變數；fixture encode/decode一致；loopbackport可動態 | Human實際配置是否同已成功App與服務端綁定未確認；不讀秘密來比對 | 尚無證據；動態port差異自身不是bug |
| CLI/App差異 | urllib禁proxy vs URLSession；form空白+ vs%20；callbackparser細節不同；App送原verifier、CLI故意omit/wrong | form空白兩種編碼等價，不能以bytes差異直接歸因；App正向成功不是CLI每次配置/負向原因的對照證明 | 正向驗收有效且不重做；無差異已獲證為拒絕原因 |
| 配置空白/輸入差異 | App只以trim判全空後保存原字串；CLI檢非空/長度而不trim，兩者都不trim實際送出值 | 不能推論Human有空白/錯輸；未讀或要求任何配置 | 尚無證據，不據此修工具或否定App |

## 實際新增資訊與停止理由

新增的是可追溯的本機算法/組裝核對及候選排查邊界，沒有新增遠端語義資訊。safe runtime wire booleans可驗證實際本機request關聯或延遲，但不能揭露GitHub如何驗證grant；只多猜模板或keyword也不能保證唯一一次授權具有新的可靠歸因資訊。因此本輪不改CLI、未選missing/wrong、不開瀏覽器、不消耗唯一授權。

若將來取得可靠且可在live前固定的有限語義契約，wrong使用合法verifier但錯誤proof，可能比missing更聚焦mismatch；這只是未來候選理由，不是本輪執行安排或自動授權。可能需要的額外依據是提供者有明確語義的診斷契約，或另經授權且能隔離其它grant變數的設計；本輪不擴預算、不新增正向對照、不索取原始描述/回應。

## 主agent受控唯讀檢查

以Python -B在原feature記憶體內import既有CLI，無socket/browser/GitHub/config輸入；只輸出11個固定bool，不輸出生成值或原文：

| 檢查 | 結果 |
|---|---|
| RFC7636 AppendixB公開S256向量 | true |
| missing/wrong各case的same-client/redirect roundtrip | 各true |
| 兩case code fixture的form encode/decode roundtrip | 各true |
| 兩case S256/method query roundtrip | 各true |
| 兩case verifier43字元base64url合法shape | 各true |
| missing omission／wrong合法proof的challenge不同 | 各true |

共1+2×5=11 bool，全true、exit0。只證明公開向量及synthetic fixture本機條件；不是歷史真人wire或服務端grant證據、不回填舊報告。不改任何tests/code，不以此稱PKCE enforcement passed。獨立Tester可重現，不重跑已通過25tests或未變Swift。

## 歷史、預算與狀態

| 輪次／項目 | 預算／來源 | 狀態 |
|---|---|---|
| P missing/wrong | 各1/1、P2/2；舊pkce-negative-verification.md | HTTP400 unknown，兩案indeterminate，原樣readonly |
| Q missing/wrong | 各1/1、Q2/2；pkce-diagnostics-v2.md及acdbcb8對應CLI | HTTP400 invalid_grant、無token、descriptionunknown/mentiontrue，兩案indeterminate，原樣readonly |
| R新授權 | 0/1未使用，未選case | 未執行；缺可靠新歸因方案而停止，不是passed/failed |
| 正常App登入/user/再次查詢 | e941d88既有Human及agent觀察 | passed保留，不推翻/不重做 |
| 現行canvas | d11f343 index-v2.html既有Human確認 | passed保留，frozen圖不改 |
| 完整遠端refresh/401 | 本輪不執行 | pending |
| 正式Rivet產品登入UI/持久化/完整PR Humanreview | 未由本輪交付或驗收 | 未交付／pending |

不重用code、不retry、不追加第二次授權或正向對照；既有App機密未讀取，rawbody/description/exception及callback/code/state/secret/verifier/token未索取、讀取或保存。僅公開RFC向量和synthetic fixtures在記憶體使用。

## R04 獨立 Tester（2026-10-21）

親查來源HEAD `21e2542ba1198b2498d9c616784185de887b5dcc`，只讀原feature；本輪無工具或tests變更、無live。

### RI01：可重現本機及官方來源核對

親跑Python `-B` heredoc，memory-only import既有CLI：RFC7636 AppendixB公開向量；兩case各自使用synthetic client/secret/code/redirect，呼叫authorization_url與exchange_fields，再以urllib.parse urlencode/parse_qs roundtrip。輸出僅11個固定bool，未輸出任何新state/verifier/challenge/code/config值；未開socket/browser/OAuth。

| 獨立檢查 | missing | wrong |
|---|---|---|
| client/redirect query與form roundtrip相同 | true | true |
| code含&、+與空白的form roundtrip | true | true |
| S256 challenge/method query roundtrip | true | true |
| verifier/wrong_verifier合法43字元base64url shape | true | true |
| missing真omit／wrong送不同challenge的合法proof | true | true |

另RFC7636公開S256向量=true。共11/11 true、命令exit0。這是本次獨立synthetic本機結果，不回填P/Q wire或服務端grant證據；未執行25tests或Swift/正向live。

亦只讀核對既有CLI與正式configuration/factory/exchanger來源：Apptrim僅判空、實際原字串保存；兩流程的變數關聯及編碼與調查描述一致，未讀取任何實際配置。查讀四份已列的GitHub官方／RFC公開文件（純文件GET，不是OAuth端點或授權）：GitHub code十分鐘、原verifier與loopback動態port說明；RFC7636 S256/mismatch規則及RFC6749多義invalid_grant與本調查一致。GitHub token-error頁所列範例沒有給予19個synthetic模板的普遍保證；不把未列範例推論成提供者永不返回特定文字。

### RI02：hash、精確manifest與readonly

- CLI SHA256 `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`；test SHA256 `48f4bc33f2150eedeb3ac5fb309fa7240473cd903ed7b6bbd383a072edc73a2c`。兩檔bytes與21e2542完全相同。
- tools三檔更新README後的指紋為 `efa508498f0c274b16e30f635228f118f1b8e8ed3fb88a55dffa0ab4bf1b7c94`（排序相對path+NUL+bytes+NUL）；原6e01680開頭指紋僅為R前歷史，未冒充現行。
- git diff/untracked聯集均在七Modify＋唯一Written的R manifest；無刪除或rename。正式Sources/Tests/packages/AppSwift/project/resources/rootPackage/experiments、全部圖、所有舊evidence的tracked diff空；新investigation為唯一未追蹤evidence。沒有其它docs/worktree變更。
- tools pycache0；允許修改Markdown內所有相對文件連結目標存在。這是target existence檢查，不宣稱外部網頁或所有anchor自動驗證。

### RI03：結果分層與停止點

候選matrix與§10清楚區分：source/synthetic可驗的fact、可能相容但未確認的推論、實際client/服務端grant/未保存描述的no evidence。本輪未發現可重現的組裝bug證據，不等於所有bug已排除；固定句覆蓋有限不等於已確認遠端拒絕原因。停止是現有材料下的工程判斷，不宣稱未來任何方案都不可能。

R未選case、0/1未使用，沒有授權安排。P/Q各2/2及indeterminate歷史原樣保留；e941d88正向與canvas來源通過不被推翻或重做。完整遠端refresh/401仍未執行，完整PR Humanreview仍pending。未保存機密、原始描述或真實callback/request值。沒有required驗證失敗，交R05獨立Reviewer，不代核准。

### R04 九欄完成交接

- In-Scope：RI01–RI03來源、11bool、hash/manifest/readonly/links及fact/inference/noevidence分層。
- Out-Of-Scope：工具/code/test修改、live/選case、秘密/App讀取、Git發布、重跑25/Swift。
- ReadOnly：CLI/tests/正式source/圖/全部舊evidence及其它docs。
- Written：無新檔。
- Deleted：無。
- Modify：本investigation evidence與step自身R04事實。
- Goal：獨立可追溯且有限的調查驗證交R05。
- Non-Goal：不代Reviewer核准、不證明遠端PKCE或耗用R額度。
- TestCase：11bool、bytes/hash/manifest/readonly/pycache/相對連結核對通過；全部限制如上。

## R05 獨立 Reviewer verdict

外部明示approved，無required fix，可R06。來源／公開向量／synthetic與歷史wire/遠端證據分層一致，11bool未用來重判P/Q或證明PKCE；R0/1未用/未選case，停止理由未誇大成未來不可能，正向/canvaspassed保留。Tester hash/manifest/readonly核對一致。只允許提交文件/push/更新原DraftPR61，停Humanreview，不修改工具或新增授權，不merge。

## R06 交付與停止點

主提交 `d8ad344d8eeb9586414620cd0ed9265ab0f9d25f` 已push原feat/github-first-sign-in；原DraftPR61已更新R候選原因/事實推論未知/資訊增益缺口/0/1未用停止，P/Q原文歷史保留；讀回OPEN、isDraft=true、相同HEAD。staged精確8份文件、diffcheck與全部既有hooks（whitespace/EOF/Swiftformat/consumercontract/SwiftLint/renderer）passed，未繞過。code/tests與CLI SHA保持21e2542來源，沒有新增遠端證據。

本機PRLens pinned0.11.0對真base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44` → head `d8ad344d8eeb9586414620cd0ed9265ab0f9d25f` validate/render通過，4lanes/15nodes/21edges/4steps，manifest head已核對；外部scratch、無上傳/server。Graphify沿用受限sourcefallback，不build/extract/provider/upload；Archify/canvas frozen bytes未改。

本筆為僅文件收尾，隨後同步最終HEAD/localmap/原PR；R仍0/1未用、未選case、不安排授權，不重用或重試，也不建立正向對照。舊P/Q皆無法判定，正常App與canvas既有passed保留；完整遠端refresh/401、正式Rivet產品登入UI及整體Humanreview未因此完成，不merge。
