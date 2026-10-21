# Canvas 與反向 PKCE 脫敏證據

- 基線：`d11f3438cbb0aefcbf4df961566db2849aaf0a60`；原feature branch/worktree與Draft PR61。
- P02外部Plan-Reviewer：approved，無required fix；fixed four-error allowlist與generic拒絕indeterminate，不修改正式契約。
- 現行canvas：Human逐步實際確認內容/流程/責任、拖曳、縮放可讀、聚焦說明、明暗兩主題，全部passed；來源index-v2.html未變，agent未繞過browser policy或代稱實看。
- 正常登入/再次查詢保留e941d88來源，本輪不重做。完整遠端refresh/401不執行，保持pending。

## P03 Implementer 受控結果

Python3.14.0；代表性red為工具module尚不存在（ModuleNotFoundError），後續20個fixture tests green。測試含真本機loopback但不連GitHub、不開真瀏覽器、不讀Human配置。CLI與測試無外部套件。曾修正兩個mock fixture問題（ProxyHandler class被mock、redirect stderr後isatty mock範圍），最終20tests exit0，不將中間失敗隱藏。

CLI source SHA-256：`bb0f566bf5aa6b4af54d3209faf7132c37a497d6d8515d99a0664ff82ba44eaa`（dirty source，非已提交新HEAD）。P04獨立Tester已親跑下列PK01–PK06；不代P05核准；source沒有正式Swift/App/GitHubIntegration修改。所有live結果暫為pending，不能從mock推斷。

## P06 Human 遠端結果（已執行；兩case皆無法判定）

| Case | 新授權預算 | 結果 | 限制 |
|---|---|---|---|
| missing | 1/1 | indeterminate | Human安全報告：HTTP400、unknown_error/unknown、remote_rejected=true、token_present=false；不能歸因PKCE |
| wrong | 1/1 | indeterminate | Human安全報告：HTTP400、unknown_error/unknown、remote_rejected=true、token_present=false、wrong_challenge_differs=true；不能歸因PKCE |

本輪總上限兩次新授權，沒有positive/API/retry/第三次。只有safe報告分類、必要布林/HTTP整數與來源可轉錄；不存clientID/secret/code/state/verifier/token/rawbody/URL/截圖。unknown/generic/network/config結果保持indeterminate，不因任意失敗就passed。全部Humanreview仍待確認。

## P04 獨立 Tester 親跑結果（2026-10-21）

Source HEAD：`d11f3438cbb0aefcbf4df961566db2849aaf0a60`；helper為dirty新增檔，不冒稱已提交新HEAD。CLI SHA-256與Implementer交接一致：`bb0f566bf5aa6b4af54d3209faf7132c37a497d6d8515d99a0664ff82ba44eaa`。tools三檔整體指紋：`46024b6a250ea25b628ebeea5ebc7a75f04eb88164e3a0ec80c6766558221180`；以排序相對path、NUL、bytes、NUL串接計SHA-256。

| 親跑檢查 | 實際結果 |
|---|---|
| `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py` | exit0；20 tests，OK；fixture／本機loopback，沒有真GitHub或真瀏覽器 |
| `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --help` | exit0；只有固定用途與TTY提示 |
| 同CLI `--case missing`，stdin為DEVNULL、非TTY | exit2；固定case/indeterminate/input_unavailable，stderr空；未prompt或授權 |
| 同CLI `--case wrong`，stdin為DEVNULL、非TTY | exit2；固定case/indeterminate/input_unavailable，stderr空；未prompt或授權 |
| `ast.parse`兩份Python檔案 | syntax pass，不寫bytecode |
| tools目錄遞迴檢查 | `__pycache__` 0項 |
| 正式唯讀source與基線diff | 空；Sources、Tests、packages、rootPackage/lock、App Sources/Tests/project/resources與experiments無修改 |
| frozen圖逐檔比對 | 23個既有spec/HTML/receipts/圖源／screenshots等bytes均與基線一致；只允許的三份工具／視覺文件另有文字修改 |

### PK01–PK06

- PK01：missing不含code_verifier；wrong為43字元且challenge不同；兩個fresh fixture state/verifier/challenge不同，authorize條件相同；無positive/API。
- PK02：callback GET/host/path/state/code-error排他、重複／錯誤／缺失欄位、fragment/issuer/header/body拒絕；無效後有效仍可claim，重複callback與exchange claim拒絕，mock sender只有一次、不retry。
- PK03：fake授權期限超過不送POST、header超限／逐段5秒總read deadline、connection上限（測試縮為2，正式常數16）、browser失敗、POST固定endpoint／form／timeout上限30秒／64KiB body；NoRedirect、ProxyHandler空字典、無cookieprocessor，source無cache/retry/logging。SIGALRM硬期限及恢復外層budget亦受控測試；非真遠端timeout驗收。
- PK04：四error allowlist僅2xx/400可pass；generic bad_verification_code即使描述提到verifier也indeterminate；config/unknown/mixed/malformed/HTTP異常不pass；任何top-level token key含空值/異常type/duplicate皆failed且不輸出token。
- PK05：安全report欄位allowlist、unknown error與exception sentinel不echo、輸入unexpected failure無traceback、interrupt有限分類與clear；真CLI無TTY兩case均failclosed且stderr空。僅使用getpass讀取配置，無args/env/file配置入口。
- PK06：git status/未追蹤檔及diff均落在P輪manifest，無刪除或rename；正式source與所有frozen圖無變。README的兩case各新process、一次一步及總兩次上限與契約一致；canvas五項passed為Human來源d11f343的轉錄，Tester未自行繞過policy或代稱實看。正常正向仍用e941d88來源；遠端missing/wrong尚未執行。

沒有 required test failure。受控20tests不證明真GitHub的PKCE拒絕；新兩case各0/1預算維持pending。完整遠端refresh/401本輪不做。Swift source未變，沿用已記錄275 root／13consumer／9app與strict checks，不全量重跑。此Tester未執行Git hooks、stage、commit、push或PR；後續hooks若跑由執行者照實記。

### P04 九欄完成交接

- In-Scope：fake-only PK01–PK06、CLIhelp/noTTY、安全輸出、syntax/hash/readonly/manifest檢查。
- Out-Of-Scope：真OAuth、live App、讀配置／機密、遠端refresh/401、Git mutations、其他worktree。
- ReadOnly：正式Swift/source/tests/project/consumer/rootPackage/experiments/frozen圖及工具source。
- Written：無新檔；測試用-B且不產生pycache。
- Deleted：無。
- Modify：本evidence與 `plan/github-first-sign-in/github-first-sign-in.step.md` 的P04自身實際結果。
- Goal：給獨立Reviewer可核對的測試與安全範圍證據。
- Non-Goal：不代P05approved，不將mock或generic拒絕當遠端通過。
- TestCase：20tests及上述checks全部pass；兩個遠端案例仍Human pending。

## P05 R1 required fix（Implementer）

獨立Reviewer needs-rework唯一項：isatty不足以防止getpass在echo控制失敗時fallback。原P03a受限slice回修，未改manifest或正式能力：兩次getpass置於warnings.catch_warnings，GetPassWarning轉error並映射input_unavailable。新增fixture模擬第一/第二次輸入warning，不進run_case、不echo sentinel、無traceback。Implementer全21tests green；最新CLI SHA `659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699`，舊20tests/SHA保留為R1前來源。需Tester定點重驗及Reviewer複核後才交Human。

## P05 R1 getpass fallback：獨立 Tester 定點重驗

2026-10-21。Reviewer 唯一 required fix 的實作交接：兩次getpass均包於warnings filter，GetPassWarning轉為error並有限分類input_unavailable。新fixture分別模擬第一次與第二次getpass warning，確認不進run_case、不echo sentinel、不輸出warning/traceback。

Tester親跑相同 `python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p test_pkce_negative_probe.py`：exit0，21 tests、OK。另親跑兩case無TTY：各exit2、固定case／indeterminate／input_unavailable安全JSON、stderr空；兩Python檔AST syntax pass，tools內pycache 0。只有fixture與本機loopback，沒有真GitHub或真瀏覽器。

最終CLI SHA-256：`659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699`。最終tools三檔指紋：`7321ee98b28a637ea43bd3a9aa517f45b24f9ea88edd7c1388e4438eb31aa75b`（沿用排序相對path+NUL+bytes+NUL算法）。上文20tests與bb0f566開頭的SHA／舊tools指紋是修正前P04歷史快照，保留原結果，不冒稱為最終source。

本次Tester只新增本R1記錄與step自身結果；未修改工具source，無新檔／刪除／Git／live／新預算消耗，不重跑未變Swift。P06 missing及wrong各0/1、遠端結果pending。修正充分性由獨立Reviewer再判定，不代核准。

## P05 最終外部 verdict

獨立Reviewer approved，R1已關閉；允許P06一次一步交Human，沒有新授權預算。最終工具SHA `659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699`，兩個遠端case仍pending；不把21個fixture通過當成GitHub通過。

## P06 missing：Human 實際安全報告（2026-10-21）

工具來源SHA `659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699` 未變，基線d11f343加本輪dirty helper。Human自行操作並提供工具安全JSON：callback_claimed=true、case=missing、fresh_attempt=true、http_status=400、outcome=indeterminate、reason=unknown_error、remote_error=unknown、remote_rejected=true、single_exchange=true、token_present=false、verifier_field_omitted=true、wrong_challenge_differs=null。

事實只支持單次新授權與交換收到遠端error，並未回傳token key；無allowlisted verifier-specific錯誤，不得判PKCE enforcement passed。不讀取原body/description或機密、不事後擴allowlist、不重跑missing；missing已用1/1，wrong仍0/1待執行。這是Human提供工具安全輸出，非agent直接觀察HTTP body。

## P06 wrong：Human 實際安全報告（2026-10-21）

工具來源SHA `659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699` 未變，基線d11f343加本輪dirty helper。Human按下一個獨立wrong指令操作後提供安全JSON：callback_claimed=true、case=wrong、fresh_attempt=true、http_status=400、outcome=indeterminate、reason=unknown_error、remote_error=unknown、remote_rejected=true、single_exchange=true、token_present=false、verifier_field_omitted=false、wrong_challenge_differs=true。

此為Human提供工具安全輸出，非agent直接觀察原HTTP body。其它條件由工具固定；client配置由Human依步驟自行保持相同，agent未讀取或比對機密。工具為每process產生新state/verifier/challenge並單次claim/code exchange，不沿用missing code；兩個安全報告均fresh_attempt=true及single_exchange=true。

## 本輪判讀與停止點

- Canvas人工互動：passed，來源d11f343現行index-v2.html，Human五項逐步確認，沒有改圖或繞過browser policy。
- missing／wrong：均已執行，各1/1授權；GitHub HTTP400遠端拒絕、無token key，按事前固定判準均indeterminate。不能推論PKCE已enforce或不支援PKCE，也不把它當成network failure。
- 具體缺口：回應錯誤未命中事前四項verifier-specific allowlist，safe remote_error只能是unknown；原body/description未保存，不能追補原因或排除配置/其他OAuth原因。不得事後擴allowlist改判，也不重新取得code彌補本次。若未來需要更細診斷，須另定最小finite診斷契約與新授權預算。
- 本輪總2/2新授權已用完，停止新授權／交換，不重用code、不retry、不補跑positive/API。正常e941d88來源保留；完整遠端refresh/401未執行，保持pending。全部PR Human review仍未完成。
- 受控工具21tests與遠端結果分層，測試green不代表PKCE遠端passed；P07獨立Tester／Reviewer複核後交付紀錄。

## P07 獨立 Tester：脫敏證據複核（2026-10-21）

以主agent交付的兩份Human安全JSON逐欄核對上述P06轉錄：missing／wrong皆callback_claimed=true、fresh_attempt=true、single_exchange=true、HTTP400、remote_rejected=true、token_present=false、outcome=indeterminate、reason=unknown_error、remote_error=unknown；missing為verifier_field_omitted=true、wrong_challenge_differs=null，wrong為false／true。轉錄一致，只含有限分類與布林，沒有帳號或機密欄位。

來源HEAD仍d11f343；親查CLI SHA為 `659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699`，tools三檔指紋仍 `7321ee98b28a637ea43bd3a9aa517f45b24f9ea88edd7c1388e4438eb31aa75b`，與P05R1最終重驗一致，無工具變更。正式Sources/Tests/packages/AppSwift/project/rootPackage/experiments相對基線diff空；所有changed/untracked均在現行manifest，無刪除、pycache0。未重跑未變code的全測試，未取得rawbody或外部端點。

按事前固定分類核對：unknown_error不是四項verifier-specific allowlist，不得升級passed；遠端拒絕與無token key只能支持兩case皆indeterminate，既不證明enforcement，也不證明PKCE不支援。缺失與錯誤案例各1/1、總2/2已用完；停止所有新授權、POST、retry、code重用，不索取rawbody追補、不更動allowlist。

Canvas Human五項passed仍歸因d11f343 index-v2；正常登入／再次API仍歸因e941d88；遠端refresh/401本輪不做，全部Human review仍未完成。較早P03/P04/P05的pending與舊hash明確作歷史，最新P06結論及總預算已覆蓋現行狀態。

### P07 Tester 九欄

- In-Scope：安全JSON／來源／分類／預算／manifest與readonly最小複核。
- Out-Of-Scope：live、測試全跑、App／秘密讀取、工具／判準改動、Git。
- ReadOnly：CLI、tests、README、四planning與允許docs、全部正式source。
- Written：無。
- Deleted：無。
- Modify：本evidence與step自身P07事實。
- Goal：給獨立Reviewer來源一致且不誤報PKCE通過的證據。
- Non-Goal：不代Reviewer核准或歸因未知遠端錯誤。
- TestCase：安全報告欄位與事前分類一致；SHA／指紋／readonly／manifest核對通過，無新live。

Tester複核完成，交P07獨立Reviewer；不是PKCE remote passed或整體Human接受。

## P07 獨立 Reviewer 明示結果

2026-10-21，主agent轉錄外部Reviewer：**approved，無required fix**。兩個安全報告皆indeterminate，沒有以HTTP400或remoteRejected升級PKCEpassed；來源、Human歸因、各1/1總2/2預算及未知原因限制一致，無機密，歷史結果未改。可以commit/push更新原DraftPR61，不再授權/重試/改判準，停Humanreview且不merge。Reviewer只讀，未測試或遠端操作。
