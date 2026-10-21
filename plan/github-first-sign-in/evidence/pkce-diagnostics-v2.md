# Q 輪：反向 PKCE 有限診斷 version 2

## 來源與鎖定邊界

- 基線 `82489b68ff21e955611bde1e9028fff21dc68e74` + Q manifest受限diff；feature `feat/github-first-sign-in`、原Draft PR61。正式能力不是已確認bug。
- 獨立Plan-Reviewer Q02 approved、無required fix；事前判準見technical-spec §9，19個完整句、有限enum、case/conflict matrix；live後不擴表。
- CLI SHA256 `504b4a19766a216ba3ab5d9fbd7a9a516ac365bf910a7fc542c2fd73530f6484`；tools三檔相對路徑+NUL+bytes+NUL指紋 `b3ba30da83deaca08bf57ec8073a9cece4dba4da26225362e426685a9f845ae7`。本筆為Implementer來源，尚待獨立Tester/Reviewer，不是live放行。
- 原P兩次來源/結果完整保留於pkce-negative-verification.md，兩caseHTTP400/unknown/indeterminate，2/2已用完；raw body未保存，不能追補/重判。
- Canvas Human五項passed及新App正常OAuth/真API/再次查詢沿用原證據，不重做；圖不改。完整遠端refresh/401、正式產品登入UI仍pending或未交付。

## 受控驗證（Implementer）

- red：新增version2/case/template/safe欄位fixtures於舊工具，25tests中5error+1failure（新分類介面/模板/欄位未存在）。
- green：新版25tests exit0，全部fixture與本機loopback；沒有真OAuth/遠端請求或Human預算消耗。
- 覆蓋19模板/normalize、generic與unknown、強訊號衝突、case錯配、單獨invalid_code_verifier不可pass、keyword/否定/附加字/超長、token/malformed/HTTP、network/timeout分類、stdout/stderr sentinel脫敏與舊單POST/TTY fallback/loopback回歸。
- 受控tests通過不等於遠端PKCE通過。獨立Tester與Reviewer仍pending。

## Q 真人預算及結果

| case | 新授權使用量 | 觀察 | 結論 |
|---|---|---|---|
| missing | 1/1 | HTTP400 / invalid_grant；無token，description unknown、mentions_verifier=true | 無法判定 |
| wrong | 1/1 | HTTP400 / invalid_grant；無token，description unknown、mentions_verifier=true、wrong challenge不同 | 無法判定 |

目前總2/2用盡（先前0/2為當時狀態）。本輪已在獨立Tester/Reviewer required fixes關閉後執行；原執行規則：Human自行TTY隱藏輸入與瀏覽器授權，一次一步，只回報安全JSON。各獨立新code/單POST、不重用、不retry、不第三次。未知仍無法判定，不索取原文。不得將raw error/description/response/exception、callback/code/state/verifier/secret/token寫入logs/磁碟/截圖/證據。

## Q04 獨立 Tester（2026-10-21）

親查source HEAD `82489b68ff21e955611bde1e9028fff21dc68e74`，CLI SHA為 `504b4a19766a216ba3ab5d9fbd7a9a516ac365bf910a7fc542c2fd73530f6484`、tools指紋為 `b3ba30da83deaca08bf57ec8073a9cece4dba4da26225362e426685a9f845ae7`，與Implementer交接一致；這是基線加dirty Q diff，不假造已提交source。

| 親跑檢查 | 結果 |
|---|---|
| `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py`（授權升權以允許本機loopback） | exit0；25tests，OK，僅fixture/local socket，無真GitHub/瀏覽器 |
| `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --help` | exit0，固定提示 |
| missing/wrong CLI，stdin=DEVNULL及非TTY，capture stdout/stderr | 各exit2；version2安全JSON，input_unavailable/indeterminate/proven=false；stderr空，不輸入配置或授權 |
| 兩Python檔`ast.parse` | syntax pass，未寫bytecode |
| 19模板與technical-spec §9逐句比較 | count=19，每類與完整字串完全相同 |
| AST比較既有CLI所有function/class（分類/report所需classify/run_case/main除外） | 與基線完全相同，transport/TTY/loopback/generation/單次策略未變 |
| readonly diff/manifest/pycache | 正式Sources/Tests/packages/AppSwift/project/resources/rootPackage/experiments/全部圖/P舊evidence diff空；changed/untracked全在Qmanifest，無delete/rename，pycache0 |

QD01–QD04的25個fixtures覆蓋19模板/normalize、case對應、generic/unknown與強訊號衝突、keyword/否定/附加sentinel/513長字串/token/JSON/mixed/HTTP、network/timeout安全class、version2有限欄位、stdout/stderr sentinel、舊TTY防fallback/單POST/loopback回歸；受控green不代表遠端結果。QD05 source與範圍如上。正式Swift source未變，沿用既有275/13/9與strict證據，不重跑；Tester未跑hooks或Git mutation。

### 複核發現：非string description的presence語義

額外本機synthetic分類fixture：純object中error為invalid_grant、error_description為整數。實際report為indeterminate/json、description_present=false、description_class=absent、pkce_rejection_proven=false。原因是非string guard在設定presence前返回；§9明列description_present表示原欄存在，非string描述不能命中模板。現有test只核對json與proven=false，未核對這項presence欄位。此項不會誤報PKCE通過或洩漏內容，但診斷presence與原欄存在不符；已回報主agent，交獨立Reviewer判定required fix，不代核准。未改工具source。

### Q04 九欄

- In-Scope：QD01–QD05 fake回歸、help/noTTY/AST/hash/模板/manifest/readonly。
- Out-Of-Scope：live/機密/App操作/Git發布/正式code修改/重跑未變Swift。
- ReadOnly：工具與正式source、傳輸/TTY/loopback/生成、全部圖與P歷史證據。
- Written：無；只有既有新evidence內容更新。
- Deleted：無。
- Modify：本evidence與step自身Q04結果。
- Goal：提供獨立可核對的受控結果及presence語義疑點交Q05。
- Non-Goal：不替Reviewer核准、不預填Human或重判P。
- TestCase：25tests exit0及上述checks；疑點明示，不將測試green視全部契約已證明。

Q Human新額度仍0/2（missing/wrong各0/1），未執行。

## Q05 R1 metadata：獨立 Tester 定點重驗

2026-10-21。收到Implementer最小回修交接後，親跑完整25tests，exit0、OK；另以null/number/object/array四個synthetic error_description直接分類斷言：description_present=true、description_class=unknown、diagnostic_class=json、outcome=indeterminate、pkce_rejection_proven=false，全部通過。這只修presence事實，沒有把非string升級為可信verifier evidence。

親查最終CLI SHA-256 `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`；tools三檔指紋 `6e01680d63e2f0647ab33c38aaa71306d27270d0950e39ac52fb2c199178d073`（原相對path+NUL+bytes+NUL算法）。修正前504b4a開頭CLI SHA／b3ba30開頭tools指紋及上文Q04疑點是修前歷史，不冒充最終source。

兩Python檔AST syntax pass，pycache0；正式Swift/tests/project/rootPackage/experiments/全部圖與舊P證據相對82489b6 diff仍空。AST再次核對既有function/class（分類/report所需classify/run_case/main除外）與基線相同，傳輸、TTY、loopback、生成與單次策略未變。未重跑未變Swift、未live、未用Human預算。

本次九欄：In-Scope＝R1定點metadata/25tests/readonly/hash；Out-Of-Scope＝live/Git/code修改；ReadOnly＝工具與正式source/舊P/圖；Written/Deleted＝無；Modify＝本evidence與step自身R1；Goal＝獨立R1證據交Q05；Non-Goal＝不代Reviewer核准或Human通過；TestCase＝25tests+四metadatafixtures+AST/readonly/pycache checks pass。

先前presence required fix已取得獨立測試證據，關閉與live放行仍交獨立Reviewer明示；Q Human仍0/2。

## Q05 獨立 Reviewer 放行

外部明示approved；唯一R1 metadata已關閉。Presence先於token/shape拒絕如實記錄，非字串description仍unknown/indeterminate、不取得PKCE證明。Tester獨立25tests與四類metadata檢查通過；19模板/case/conflict及readonly邊界未變。固定R1最終CLI及tools指紋，才交Human Q06；兩case各0/1，總0/2。原版本與R1前證據保留為歷史，不當作當前live source。

## Q06 missing：Human 安全結果（2026-10-21）

Human回報下列version2安全JSON；只記有限enum/布林/HTTP，沒有原始error_description、response或機密。來源為82489b6+Q受限dirtydiff，CLI SHA `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`，收到結果後核對bytes未變。

```json
{"callback_claimed": true, "case": "missing", "description_class": "unknown", "description_mentions_verifier": true, "description_present": true, "diagnostic_class": "code_problem", "diagnostic_version": 2, "fresh_attempt": true, "http_status": 400, "outcome": "indeterminate", "pkce_rejection_proven": false, "reason": "generic_code_rejection", "remote_error": "invalid_grant", "remote_rejected": true, "signals_conflict": false, "single_exchange": true, "token_present": false, "verifier_field_omitted": true, "wrong_challenge_differs": null}
```

依事前§9：可信純error/remote_rejected=true表示GitHub拒絕；invalid_grant本身為一般grant/code問題，description僅提及verifier但完整模板unknown不能證明PKCE拒絕。故indeterminate，pkce_rejection_proven=false；不能宣稱enforcement通過或失效，也不認定正式OAuth有bug。missing新1/1已用完，不重跑、不追rawbody、不改模板。wrong新0/1，Q總1/2，僅剩另一次獨立wrong可執行。P舊2/2原樣保留。

## Q06 wrong：Human 安全結果（2026-10-21）

來源82489b6+Q受限dirtydiff；CLI SHA `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`於兩case之間及wrong回報後核對未變。Human安全version2報告：

```json
{"callback_claimed": true, "case": "wrong", "description_class": "unknown", "description_mentions_verifier": true, "description_present": true, "diagnostic_class": "code_problem", "diagnostic_version": 2, "fresh_attempt": true, "http_status": 400, "outcome": "indeterminate", "pkce_rejection_proven": false, "reason": "generic_code_rejection", "remote_error": "invalid_grant", "remote_rejected": true, "signals_conflict": false, "single_exchange": true, "token_present": false, "verifier_field_omitted": false, "wrong_challenge_differs": true}
```

fresh/callback/single_exchange及wrong_challenge_differs為true，missing已omit、wrong未omit，兩個獨立新授權/新code/單POST。GitHub可信拒絕，但invalid_grant/code_problem屬一般grant/code原因；description_present/mentions_verifier為true、完整description_class為unknown，不符合事前固定完整模板。沒有token或conflict，pkce_rejection_proven=false，依§9仍indeterminate。不能僅靠提及verifier判通過，也不宣稱PKCE失效或正式OAuth有bug。

### Q 最終結果與具體缺口

missing及wrong各1/1、總2/2新預算已用完；P舊2/2另保留，不重用code、不retry、不追加第三次。新版已把先前unknown error診斷為有限invalid_grant/code_problem，但原始description未保存、未命中19個固定完整模板；安全hint只能證明它提及verifier，無法區分具體verifier語義與其它grant問題。此為本輪可靠歸因缺口，不索取rawbody、不事後擴表。兩case皆**無法判定**，不是passed/failed。停止真人授權。正常login/API/canvas沿用既有來源、不重做；完整遠端refresh/401繼續pending，完整PR Human review待完成。交Q07獨立Tester/Reviewer核對，不代核准。

## Q07 獨立 Tester：Human脫敏結果複核（2026-10-21）

以交付的兩份Human version2安全JSON逐欄核對Q06兩段轉錄，19個有限欄位及各case差異完全一致：皆HTTP400、invalid_grant/code_problem/generic_code_rejection、description_present=true、description_mentions_verifier=true、description_class=unknown、remote_rejected=true、token_present=false、signals_conflict=false、pkce_rejection_proven=false；fresh/callback/single皆true。missing省略verifier且wrong_challenge_differs=null，wrong未省略且wrong_challenge_differs=true。這是Human提供工具報告的核對，不是Tester直接觀察遠端response或比對機密。

依事前§9，invalid_grant自身只屬code_problem；unknown完整description不能取得required/mismatch證據，mentions_verifier只作hint、不參與passed。兩case皆indeterminate與既定判準一致；不宣稱PKCE enforcement通過、失效或正式OAuth有bug。原始描述未保存，不以安全hint追補語義、不事後改模板。

親查CLI SHA仍 `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`，tools三檔指紋仍 `6e01680d63e2f0647ab33c38aaa71306d27270d0950e39ac52fb2c199178d073`；基線仍82489b6加Q dirtydiff。正式Swift/tests/project/rootPackage/packages/experiments、全部圖與P舊證據相對基線diff空，pycache0。五份長期docs的Q最新結果均同步HTTP400/invalid_grant/code_problem、unknown description、兩case無法判定及2/2用盡。發現requirements舊pending語句後已回報主agent，其後親讀requirements/spec/plan三份新增Q06實際摘要，與本結果一致，原規劃語句作歷史，不改事前判準。

Q missing/wrong各1/1、Q總2/2用盡；P舊2/2另保留，不混算或回改。停止新授權、code重用及retry，不索取任何rawbody或秘密。Canvas Human來源d11f343及正向e941d88沿用，未重做；完整遠端refresh/401仍未執行，完整PR Human review未完成。

### Q07 Tester 九欄

- In-Scope：safeJSON/文件轉錄/§9分類/來源/hash/預算/readonly最小複核。
- Out-Of-Scope：live/全測試/機密/App操作/Git/code或模板修改。
- ReadOnly：CLI、歷史P、正式source、frozen圖及允許docs。
- Written：無。
- Deleted：無。
- Modify：本evidence及step自身Q07結果。
- Goal：給Q07獨立Reviewer可追溯且不誤報通過的證據。
- Non-Goal：不代Reviewer核准或歸因未知description。
- TestCase：兩safe報告逐欄一致、SHA/指紋不變、readonlydiff空、五長期docs及三planning最新摘要一致；不重跑已pass25tests。

Tester複核完成，交Q07獨立Reviewer，不等於遠端PKCE通過或整體Human接受。

## Q07 獨立最終 Reviewer verdict

外部明示approved、無required fix，可Q08。兩案version2安全結果符合凍結§9，invalid_grant+unknown description僅支持indeterminate；verifier hint非證明。來源/Human歸因/限制/Q總2/2一致，P歷史保留，未見秘密或誇大結論。允許同topic commit/push/更新原DraftPR61，停止新增授權/重試/擴模板，停Humanreview，不merge。
