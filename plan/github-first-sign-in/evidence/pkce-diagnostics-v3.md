# T 輪：有限診斷 version 3

## 來源與預算

2026-10-21，來源HEAD `90646c21bd9e6f0f19644f04efa39ef1c033a139` + T受限dirtydiff，原feature/feat/github-first-sign-in/[DraftPR61](https://github.com/a129924/rivet/pull/61)；啟動唯讀核對工作目錄乾淨，PR OPEN/Draft且相同HEAD。正式OAuth不是已確認bug。T02獨立planning review approved、無required fix。

原R保留唯一1次移交T，規劃時0/1；現已由Human執行，**共享R→T 1/1已用盡**，不是再新增1次；P/Q各舊2/2歷史獨立保留。Human只選wrong新code/單POST，理由是合法43字元verifier但proof與authorizechallenge不同，可減少missing欄位/格式歧義。不得positive/API/refresh401/第二次、重用code或retry。獨立Tester/Reviewer/required fixes完成且SHA凍結後才Human，一次一步只safe version3JSON。

CLI SHA256 `a72072c752baf4594704ecede984553db295303ca70141ef30a7280aa0324ba0`；test SHA256 `1e93c9ab39209ba858751a3e46db95ffaf3e5cf1471747f95d8c1753dd16d43e`；tools三檔相對path+NUL+bytes+NUL指紋 `bd446be3a71b7af6e0b17bcd8cfaa03084d6906f68cda68e74dfeedd5626bd3b`。本筆為Implementer來源，未宣稱獨立核可/真人通過。

## 新增資訊與固定邊界

- 精確schema/19legacy優先/bounded grammar/hints/case與conflict matrix見technical-spec§11；已在live前固定，不為結果擴表。支持句法非GitHub官方保證。既有官方GitHub授權/token-errors及RFC7636/6749來源沿用R調查，不推翻正常App的既有passed。
- 實際openerURL與實際urllib Request建立後/open前的同一物件被動觀測，非case推算或重建mirror；只對本機prepared inputs作有限比對，含Client ID/secret/redirect/code/原challenge及verifier提交shape，不輸出任何值。local_checks只保存布林/enum；observed guards與一致性gate缺席不能pass，重複觀測標不一致。
- callback_return_to_request_prepared只量acquire返回到Request建立，非code_age/遠端wire/服務端grant證明。未知仍可能無法判定，但額外詞彙hint與真實prepared狀態能提供較v2更多安全資訊；hint永不參與proof/conflict。
- 原始error/description/response/exception以及callback/code/state/clientID/secret/verifier/challenge/token均不輸出或保存；只在記憶體，observer finally解除/context clear。任何token仍failed優先、不使用/保存。正式Swift/provider/scope/lifecycle/publicAPI/實驗與所有frozen圖、PQR舊evidence皆readonly。

## T03 Implementer 受控結果

- red：34tests中5failures+7errors，version3/schema/grammar/observer尚不存在，符合新需求red。
- green：初版34tests exit0；補actual object identity、同原verifier/header mutation與失敗清理後最終36tests exit0。全部fixture/本機loopback，不開真OAuth/不連GitHub。
- RD01：RFC7636公開向量、finitegrammar各alias/成對quotes/prefix/suffix/verbs及legacy優先；RD02：否定/free tail/壞引號/unknownerror/config/case/conflict failclosed，hint全true不算proof；RD03：實際Request object identity、mutation client/redirect/code/secret/verifier/method/header/duplicates、未觀測不通過、tokenfailed優先；RD04：fakeclock bucket邊界0/5/30/負值、observer成功/失敗解除與清理、舊TTY防fallback/單POST/loopback回歸及stdoutstderr sentinel；RD05 scope/source/hash/manifest交獨立Tester確認。
- 正式Swift未變，未重跑root275/consumer13/App9歷史或正向/canvas/live refresh401；必要hooks在提交時如實記，不把fixturegreen當遠端PKCE證明。

## 真人執行狀態

| case | 唯一共享預算 | 觀察 | 判定 |
|---|---|---|---|
| wrong | 1/1已用盡 | prepared local consistent、valid_different、under_5s；HTTP400 invalid_grant、無token；grammar none | 無法判定 |

P舊unknown與Q invalid_grant/code_problem+descriptionunknown/mentiontrue，兩case皆indeterminate，原樣保留；R當時0/1停止為歷史，不代表T另有額度。正式App正常登入/user/再次查詢e941d88、canvas d11f343原passed不重做。完整遠端refresh401及完整PR Humanreview仍pending；正式產品登入UI未交付。

## T04 獨立 Tester（2026-10-21）

親查source HEAD `90646c21bd9e6f0f19644f04efa39ef1c033a139`，受驗為同feature的T dirtydiff，不冒稱已提交新版本。實際CLI SHA `a72072c752baf4594704ecede984553db295303ca70141ef30a7280aa0324ba0`、test SHA `1e93c9ab39209ba858751a3e46db95ffaf3e5cf1471747f95d8c1753dd16d43e`、tools三檔指紋 `bd446be3a71b7af6e0b17bcd8cfaa03084d6906f68cda68e74dfeedd5626bd3b`，與Implementer交接完全一致。

| 親跑命令／檢查 | 實際結果 |
|---|---|
| `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py`（授權升權容許本機loopback） | exit0；36tests，OK；只有fixture／本機socket，無真GitHub、瀏覽器或秘密 |
| `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --help` | exit0，固定用途提示 |
| missing/wrong CLI，stdin=DEVNULL、capture stdout/stderr | 各exit2；version3／input_unavailable／indeterminate／proof=false／local unobserved；stderr空，不prompt或授權 |
| Python AST／hash／no-cache | 兩Python syntax pass；SHA與交接一致，tools pycache0 |
| T scope／readonly | 九Modify＋唯一新evidence之外無變更，無delete/rename；正式source/tests/App/project/packages/rootPackage/experiments/全部圖／所有舊evidence相對基線diff空 |

### RD01–RD05 實際覆蓋

- RD01：36tests包含RFC公開S256向量、真loopback的authorize opener參數觀測、observed Request與opener.open參數為同一物件、實際body/header/method變更能被detect；client/redirect/code/secret/verifier重複／shape／valid_same均不能由case推為true。額外memory-only fixture再變更實際URL的client_id、redirect_uri、state、code_challenge，四者皆shape=false／indeterminate／proof=false。
- RD02：grammar三alias、四種成對quotes、固定prefix/suffix/verb與required/mismatch/invalid型態及legacy優先通過；未知/否定/附尾文/壞引號/超長及unknownerror拒絕；九hint全true也不能證明。
- RD03：case-specific可信error、strong/config/unknown/conflict、HTTP/shape/token優先與舊network/timeout回歸；run_case observed gate在unobserved/inconsistent時把原可passed結果降為固定local_observation_unconfirmed／indeterminate／proof=false，不改tokenfailed優先。
- RD04：fakeclock的0/4.999/5/29.999/30/負值bucket與一致性；額外nan、正inf、負inf三fixture皆time=unobserved、inconsistent、indeterminate／proof=false。不是code_age。prepared observation單次與duplicate拒絕、成功/失敗finally detach/clear、單POST、TTYgetpass防fallback均通過。
- RD05：受控stdout/stderr redaction及safe schema通過。額外capture真正main安全輸出，fixture client/secret/code/state/verifier/challenge/固定rawURLs及Traceback均未洩漏；version3與local_checks固定bool/enum、stderr空。未輸出任何生成值。

額外synthetic檢查只在記憶體使用現有test helper與mock transport，10個固定bool全true、exit0；沒有新增test檔、網路/OAuth或Human預算。

### 核心不變與限制

AST比較既有function/class（允許的Attempt/Deadline/authorize/send_token/run_case/classify/safe_result除外）無改動：challenge、exchange_fields、authorization_url、callback parser、headers限制、browser、NoRedirect/opener、hard time budget等原樣。diff核對authorize只把原URL綁定同一變數給observer與opener；send_token仍建立原固定endpoint/headers/form/POST的Request，僅在既有open前觀測同物件，原timeout/response cap/retry/redirect/proxy策略未改。main完整AST未變，TTY防fallback維持。

所有本機prepared觀測不等於遠端wire、code發行或grant狀態。沒有required test failure或新範圍疑點；唯step T02外部approved仍有舊pending/null佔位已回報主agent依明示外部verdict修正，不由Tester代判。正式Swift未變，沿用275/13/9舊結果，不重跑。未執行hooks、Git發布或live。共享R→T唯一額度仍0/1，無新增預算；P/Q/R歷史與正向/canvaspass來源未改。

### T04 九欄完成交接

- In-Scope：fake RD01–RD05、36tests、help/noTTY/AST/hash/schema/sentinel/readonly/manifest。
- Out-Of-Scope：live/機密/App操作/Git/code修改/未變Swift重跑/額外預算。
- ReadOnly：工具與正式source、核心傳輸/交換/TTY/loopback/生成、舊PQR evidence/圖。
- Written：無新檔。
- Deleted：無。
- Modify：本v3 evidence及step自身T04結果。
- Goal：獨立實跑與邊界證據交T05。
- Non-Goal：不代Reviewer核准、不把fixture或localprepared當PKCE遠端證明。
- TestCase：36tests及上述額外10bool、safe CLI/AST/hash/scope checks全pass；Human wrong仍待獨立Reviewer及freeze。

## T05 獨立 Reviewer放行與凍結

外部明示approved、無required fix。實際openerURL/同一Request被動觀測、bindings/negativegate/token優先、完整grammar/hints分離、finally清理及readonly符合§11；T04獨立36tests與10補充檢查通過，帳本佔位已同步。T06前再次核對CLI/test SHA與T04相同，固定以上version3/hash/grammar/判準，不因live結果改動。

共享R→T唯一額度仍0/1；只Human wrong新授權/新code/單POST，不positive/refresh401/第二次。選wrong的合法shape/differentproof與新增安全資訊理由見本文件及§11；不保證遠端必定可判定。只收安全JSON，不收配置/URL/rawresponse，執行後立即停止。

## T06 Human wrong 安全結果（2026-10-21）

T05核准後Human自行隱藏輸入配置並完成唯一一次新授權。Human回報以下version3安全JSON；本紀錄只是工具安全報告，不是agent讀取原始HTTP內容。來源90646c2+T受限dirtydiff；回報後親核CLI/test SHA與T05凍結完全相同，判準未修改。

```json
{"callback_claimed": true, "case": "wrong", "description_class": "unknown", "description_has_client_word": false, "description_has_expired_word": false, "description_has_invalid_word": false, "description_has_mismatch_word": true, "description_has_missing_word": false, "description_has_redirect_word": false, "description_match_source": "none", "description_mentions_challenge": true, "description_mentions_pkce": false, "description_mentions_verifier": true, "description_present": true, "diagnostic_class": "code_problem", "diagnostic_version": 3, "fresh_attempt": true, "http_status": 400, "local_checks": {"authorization_observed": true, "authorization_shape_valid": true, "callback_return_to_request_prepared": "under_5s", "client_id_same": true, "code_same": true, "local_consistency": "consistent", "redirect_same": true, "submitted_verifier": "valid_different", "token_request_observed": true, "token_request_shape_valid": true}, "outcome": "indeterminate", "pkce_rejection_proven": false, "reason": "generic_code_rejection", "remote_error": "invalid_grant", "remote_rejected": true, "signals_conflict": false, "single_exchange": true, "token_present": false, "verifier_field_omitted": false, "wrong_challenge_differs": true}
```

### 已新增的實際安全資訊

- authorization_observed及token_request_observed為true；同一opener URL及同一urllib prepared Request之shape/bindings核對通過，client_id_same/redirect_same/code_same均true。這是當次本機prepared inputs一致性，不再只是由case推算。
- submitted_verifier=valid_different、wrong_challenge_differs=true、omitted=false，表示當次準備的form有合法43字元不同proof；callback_return_to_request_prepared=under_5s，量的是callback返回到準備Request，不是code_age。
- remote_rejected=true、HTTP400 invalid_grant/code_problem、無token。描述詞彙提示verifier/challenge/mismatch為true；完整class仍unknown、match_source=none、signals_conflict=false、pkce_rejection_proven=false。

### 判定與仍有的缺口

按事前§11，local consistency是必要條件，不能取代可信完整verifier語義。純hint不參與proof，完整grammar未命中、一般invalid_grant仍只能indeterminate。不能從三個hint重建句子，不能說遠端肯定因mismatch拒絕；false client/redirect/expired hints也不排除這些原因。當次secret同輸入的比較不證明配置與舊成功App相同或服務端認可，under_5s不證明遠端code發行時間/未過期。本機gate已獲得實際一致報告，但服務端grant/code/client/redirect狀態及原描述語義仍未確定。

因此本輪wrong為**無法判定**，不是PKCE enforcement passed/failed，也不是已確認正式OAuth bug。不能因prepared gate通過或keyword同時出現就升級結果。已完成診斷改善與一次Human執行，歸因驗收仍未獲證。

共享R→T唯一1/1已用盡，立即停止新授權/重試/positive/refresh401/第二次，不重用code、不索取rawbody或機密、不live後擴grammar。P/Q舊各2/2及R當時未用的歷史原樣保留，不將R/T算成兩次額度。正常App/user/再次查詢e941d88、canvas d11f343原passed不重做；完整遠端refresh401與完整PR Human review仍pending。交T07獨立Tester/Reviewer核對，未代核准。

## T07 獨立 Tester：唯一Human安全結果複核（2026-10-21）

逐欄核對交付的Human version3 JSON與T06轉錄完全一致：HTTP400、invalid_grant/code_problem/generic_code_rejection，可信遠端拒絕、無token/conflict/proof；description_class=unknown、match_source=none。verifier/challenge/mismatch hints為true，其餘hint為false。local_checks七個observed/shape/binding布林全true，submitted_verifier=valid_different、time=under_5s、local_consistency=consistent；fresh/callback/single/wrong_challenge均true、omitted=false。只有有限enum/布林/HTTP整數，未含rawresponse或機密。這是Human提供工具安全報告的核對，不是Tester取得遠端body或配置。

按凍結§11，local一致性與negative提交正確僅滿足必要本機gate；一般invalid_grant與unknown完整描述仍不提供verifier_mismatch證據。keywords不參與proof，不能重建句子；false hints不排除其它grant問題。under_5s只量callback返回到Request prepared，不是code_age、發行時間或服務端接受狀態。因此indeterminate/proven=false符合既定判準，不宣稱PKCE通過、失效或正式OAuth有bug。

親查凍結CLI SHA仍 `a72072c752baf4594704ecede984553db295303ca70141ef30a7280aa0324ba0`，test SHA仍 `1e93c9ab39209ba858751a3e46db95ffaf3e5cf1471747f95d8c1753dd16d43e`；未變更工具/測試/grammar。tools README僅同步結果與停止後，當前三檔指紋為 `ae1dad2d8a1e9fb813fd8c23be88d4d57497a4b264328144f2f06bd51d1febbe`（排序相對path+NUL+bytes+NUL）。上文bd446be3開頭指紋是live前README版本，不能當作結果文件更新後指紋。來源仍90646c2+T受限dirtydiff。

正式Sources/Tests/App/project/packages/rootPackage/experiments、全部圖及所有舊PQR evidence相對基線diff空；九Modify＋唯一新v3evidence之外無變更，無delete/rename、pycache0。README、長期first-sign-in文件、toolsREADME及四planning現行T結果一致，三planning末有T06實際摘要；舊0/1/pending為執行前歷史，不覆蓋最新1/1。

共享R→T唯一1/1已用盡：R原未用的同一次移交T，不另加一次；停止新授權、交換、retry、code重用、positive/API/refresh401。P/Q舊各2/2與indeterminate、R調查、正向e941d88及canvaspass來源保持不變，完整遠端refresh401及PRHumanreview仍pending。未重跑36tests或live、未讀秘密、未Git。沒有新增requiredfix，交T07獨立Reviewer，不代核准。

### T07 Tester 九欄

- In-Scope：safeJSON/凍結§11/來源hash/預算/文件/readonly最小複核。
- Out-Of-Scope：live/重跑36/秘密/App操作/Git/工具或判準變更。
- ReadOnly：CLI/tests/正式source/舊PQR evidence/frozen圖及其它docs。
- Written：無。
- Deleted：無。
- Modify：本v3 evidence與step自身T07結果。
- Goal：交獨立Reviewer有限、可追溯且不誤報proof的結果。
- Non-Goal：不代核准、不從hint推論原句或PKCE原因。
- TestCase：Human報告全欄一致、CLI/testhash凍結、readonly/manifest/pycache/最新文件核對通過。

## T07 獨立最終 Reviewer verdict

外部明示approved、無required fix，可T08。safe report/凍結§11/文件一致，localprepared一致已獲報告而完整語義未命中，維持indeterminate；未以hint肯定原因、以falsehint排其它原因或把under_5s當code_age。共享R→T1/1已用盡，舊來源/證據/readonly保留。可commit/push/更新原DraftPR61，停止新授權/重試，停Humanreview不merge。

## T08 交付來源與停止點

主提交 `403287a2c4d9abd081fb841ba56369a250c415a7` 已push原feat/github-first-sign-in；原DraftPR61已更新v3實作/新增本機資訊/Human wrong觀察/indeterminate原因/共享1/1用盡及歷史保留，讀回OPEN、isDraft=true、相同HEAD。staged精確10檔、diffcheck與全部既有precommit hooks（whitespace/EOF/Swiftformat/consumercontract/SwiftLint/renderer）passed，未繞過。CLI/test bytes與T05凍結及T06真人來源相同，未live後改判準。

PRLens pinned0.11.0以真base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44` → head `403287a2c4d9abd081fb841ba56369a250c415a7` 本機scratch validate/render通過，4lanes/15nodes/21edges/4steps，manifest head已核對；無上傳/新server。Graphify仍無可用圖，受限targeted sourcefallback、不build/extract/provider/upload；Archify/canvas frozen不改、原Human證據沿用。

本筆只文件收尾，隨後commit/push及最終HEAD map/原PR同步，不改工具或重做授權。診斷改善已交付；本次localprepared gate通過，但遠端PKCE原因仍indeterminate，沒有passed/failed結論。共享R→T唯一1/1已用盡，停止所有新授權/重試/第二次/positive/refresh401；P/Q/R與App/canvas歷史保留，完整Humanreview待完成，不merge。
