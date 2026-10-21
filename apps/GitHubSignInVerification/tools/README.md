# 單次反向 PKCE 驗證

## T 輪現行：diagnostic_version 3

Human已指示續行最小改善，取代R當時停止指示；R原保留的唯一額度移交T，共享R→T現已 **1/1用盡**，沒有新增一次。獨立Tester/Reviewer核可且版本SHA凍結後Human已執行wrong唯一一次，結果無法判定，**不要再執行下列歷史命令**。T只選wrong一次，不再missing/positive/API/refresh401/第二次；每次新process/state/challenge/code、單次token POST，無retry或code重用。正常App登入/再次查詢與canvaspassed保留，P/Q/R舊evidence及預算不改。

以下是T06已執行的唯一case命令，僅作可追溯歷史，不是再次執行指示：

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case wrong
```

仍只在原feature本機互動TTY getpass隱藏輸入自己的Client ID/Secret；不讀既有App配置，不用args/env/file/tee/log/screenshot，不貼URL/callback或配置。只回報最後version3安全JSON，完成後停下，不自動追加授權。

### 新增安全資訊與固定判準

- `local_checks`觀測實際交給browser opener的同一URL、以及實際交給urllib open的同一prepared Request。不是由case推算或重建mirror。布林只表示本機shape/binding/code/secret比較；submitted_verifier/timebucket/local_consistency只用有限enum。未觀測false/unobserved，不默認成功；重複觀測/inconsistent不能通過。這不是遠端wire、code發行時間或服務端grant證明。
- description保留19個legacy完整句優先，再用事前固定bounded grammar辨識有限field alias、成對引號及prefix/suffix，必須fullmatch整句、<=512字元；不接受任意尾文、否定句或substring通過。`description_match_source`只為legacy_exact/bounded_grammar/none/not_applicable，不輸出原句。grammar是支持句法，不是GitHub官方保證。
- 新的challenge/pkce/missing/mismatch/invalid/expired/client/redirect詞彙hints只作有限布林；即使全部true也不是proof。未知error不被grammar升級，強configuration/auth/redirect與conflict仍阻止通過。
- 最終passed除可信error/HTTP2xx或400/無token/knownerror/required或mismatch對應case/無conflict，還必須local_consistency=consistent及正確negative提交。wrong必須valid_different；valid_same/omitted/invalid或未觀測均不能passed。若遠端分類可pass但本機gate不符，reason=local_observation_unconfirmed、indeterminate/proven=false。任一token key仍failed優先，不使用/保存token。
- 詳細固定schema/grammar/hints與matrix見[technical-spec §11](../../../analysis/github-first-sign-in/technical-spec.md#11-t-輪現行diagnostic-version3取代r停止指示保持正式能力不變)；[本輪來源與證據](../../../plan/github-first-sign-in/evidence/pkce-diagnostics-v3.md)。callback_return_to_request_prepared只量acquire返回至Request建立前，不能稱code_age。

所有raw值只在記憶體處理；observer在finally解除並清除context，絕不輸出/保存原始error/description/response/例外文字或秘密。只輸出固定提示和version3有限enum/bool/HTTP整數。P/Q/R歷史不能用新版語義重判。

## R 輪歷史停止提示（2026-10-21）

唯讀調查來源21e2542，未找到有依據的新遠端歸因辨識契約，依Human限制本輪不修改CLI/分類、不選case、不安排真人授權，R **0/1未使用**。下列missing/wrong命令與兩次額度是P/Q歷史操作說明，不是R執行指示，不得自行重跑或消耗R唯一額度。P/Q各2/2及unknown/indeterminate結果保留，不追原始描述、不改模板；已成功的App登入/API不重做。詳見[調查證據](../../../plan/github-first-sign-in/evidence/pkce-diagnostic-investigation.md)。

此 Python standard-library CLI 只驗證 GitHub.com 對缺少／錯誤 verifier 的遠端拒絕。它不載入正式 GitHubIntegration、Swift App 記憶體或既有 credential，不建立連線或執行 API／refresh／401。正式產品登入 UI 未交付。

正常登入與再次查詢已由來源 e941d88 驗證，本工具不重做 positive。E002 沒有 missing case，且其 generic bad_verification_code 判準不能沿用；本工具保留該結果為「無法判定」。

## P／Q歷史前置與操作（T現行規則優先）

使用 macOS、可用的 Python 3 與本機互動 TTY。在原 feature worktree 終端執行；不用 agent exec session、管線、檔案、環境變數或命令參數傳入配置。不加 tee／log capture，不截圖配置或瀏覽器回呼。兩個案例由 Human 各自隱藏輸入與先前正向相同的 client ID／secret；callback 配置沿用 127.0.0.1/oauth/callback，當次port由系統分配。工具不自行改外部OAuth App設定。

先執行 missing，完成後只回報安全 JSON 分類，等下一步再執行 wrong：

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case missing
```

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case wrong
```

每次 process 只產生一個新 state／verifier／S256 challenge 並開啟一次瀏覽器授權，接收新 code 後只送一次 token POST。不重用 code、不 retry、不先 positive、沒有自動接續另一案例。本輪授權上限為兩次，各 case 一次；中止或結果不明不自動第三次。若某 case 已送出，即使失敗也不能重用該 code。

Client ID／Secret 皆 getpass 隱藏輸入，無TTY直接安全結束。按 Ctrl-C 可中止。所有嘗試資料只在記憶體，沒有寫檔／log／traceback；不聲稱 Python immutable strings 可安全抹除，也不控制使用者瀏覽器／OS自身的既有留痕。回呼頁只顯示靜態提示，不echo URL；請回終端，不要複製 callback。

missing 完全省略 code_verifier 欄位；wrong 送另一個43字元base64url verifier，先確認其challenge與授權challenge不同。其餘固定HTTPS endpoint、offline_access、同次redirect、headers與form encoding保持相同。callback先ready後開瀏覽器，限定127.0.0.1、GET、exact Host/path/state及單次claim；8KiB headers、每連線5秒、最多16connections、授權到POST總5分鐘。POST完整I/O硬性上限為剩餘授權期限或30秒較小者，response上限64KiB；無redirect、proxy env、cookie、cache或retry。

## Q歷史判準：diagnostic_version 2

- `passed`：可信純error、HTTP2xx或400、無token/格式問題、訊號無衝突，且missing對應verifier_required、wrong對應verifier_mismatch。四個verifier error不再一律通過：單獨invalid_code_verifier只屬verifier_invalid_unspecified，不能證明拒絕原因。
- `failed`：JSON object存在access_token或refresh_token key，包含空值、混合error與異常type；不使用、不保存token。
- `indeterminate`：一般code拒絕、配置/redirect/授權、網路/HTTP/JSON/逾時、未知或衝突訊號及case不符。`remote_rejected=true`只代表可信error，`pkce_rejection_proven=true`才表示本工具固定判準已獲證。

有限error、19個完整description模板、normalize與case/conflict matrix在[technical-spec §9](../../../analysis/github-first-sign-in/technical-spec.md#9-q-輪現行診斷版本2優先於-8-的舊p四errorcode判準)事前鎖定。description只在記憶體內完整比對：最多512字元，strip/lower/空白折疊/至多一個末尾句點；不輸出原文。模板是synthetic supported wording，非GitHub官方保證。invalid_grant涵蓋多種grant問題，本身不是PKCE證據；unknown error不能被description升級。`description_mentions_verifier`只是提示，不參與passed；否定句、附加字、未知描述不當證據。live後不擴表配合結果。

stdout只輸出固定提示與安全JSON：case、outcome、reason、有限remote_error、HTTP整數/必要布林，加diagnostic_version、diagnostic_class、description_class、description_present、description_mentions_verifier、signals_conflict、pkce_rejection_proven。無clientID、secret、code、state、verifier、token、原始error/description/body/URL或exception文字。退出碼passed=0、failed=1、indeterminate=2；不能單憑非零當PKCE enforcement通過。

P輪兩次已用完，missing/wrong均HTTP400、unknown/indeterminate；原始回應未保存，不可追補或重判。Q輪新版各case另一次新授權/新code/單POST，總上限2次；不重用、不重試、不第三次。逐步交Human，required fixes關閉後才live。

來源：[GitHub授權契約](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)、[token錯誤說明](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)、[RFC7636 §4.6](https://www.rfc-editor.org/rfc/rfc7636.html#section-4.6)、[RFC6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2)。

## 受控測試

```sh
python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p 'test_pkce_negative_probe.py'
```

只有fixture與本機loopback，沒有真OAuth、秘密或GitHub呼叫。-B避免產生__pycache__；不安裝依賴、不改工具設定。P歷史證據見topic `evidence/pkce-negative-verification.md`；Q新版見 `evidence/pkce-diagnostics-v2.md`，不得把mock green當成真實passed。

## T06 已執行，停止新授權

wrong安全version3報告顯示actualprepared local consistent/valid_different/under_5s；HTTP400 invalid_grant、無token，verifier/challenge/mismatch hints true但完整description grammar none。依事前判準仍indeterminate，不把hint或本機一致當PKCE證明。共享R→T唯一1/1已用盡，停止重試/第二次；不追原文、不擴grammar、不重做positive/API/refresh401。CLI/tests與真人前SHA未改；本次只更新README結果，工具三檔fingerprint會隨README改變，勿把pre-live三檔fingerprint當更新後值。


## U：Human-only semantic review（現行只授權離線）

已實作私有parent gate、先清理再pipe/helper，以及`provider_semantic_observation`獨立軸。它只記`review_source=local_human`與有限enum/布林，不改既有`outcome`或`pkce_rejection_proven`。未保存原文，所以agent/Reviewer不能獨立稽核Human對原句的判讀。

Human下一步在**原feature worktree的終端**執行單一命令（需獨立Tester/Reviewer完成後由Human明確參與）：

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review
```

此入口沒有client ID/secret輸入、沒有socket/browser/OAuth/token POST；讀取獨立Tester建立且Reviewer凍結的16-case synthetic fixture，SHA256固定為`d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5`。程式只投影description，在記憶體打散順序，不讀expected label值；每個case重啟單record helper，不把ID或label送helper，中途只有進度，不提示正誤。末尾才輸出SHA256(id)前16hex的opaque correlation_id與安全Human觀察，由獨立Tester另行核分，工具不自評score。expected labels由Tester/Reviewer擁有，Implementer不建立或為結果改標。Human校準目前pending，不會由測試或此文件自動開啟。

每次先顯示密封窗，30秒未明示即丟棄；按「顯示一次」才顯示完整原句，最多60秒。可選三種明確拒絕原因或無法判定；條件/否定/例子/多候選/矛盾/不完整都應選無法判定。沒有case/outcome/expected label提示；Human可能已知上下文，不能保證全盲。9/9 decisive正確且7/7 unknown才過該frozen set，全unknown不算通過；獨立Reviewer核標後由Tester記分，不是工具自動通過。

Swift helper以匿名stdin只收`protocol_version=1`及description；總16KiB、描述4096 UTF-8 bytes，嚴格拒絕重複/多餘鍵、trailing/type/UTF8/size錯誤。stdout最多512bytes只有限schema，stderr不forward；parent總watchdog100秒，異常/逾時/nonzero皆未知。編譯只在外部temporary scratch產生無原文binary，原句不經argv/env/file。無參數預設CLI仍不開semantic UI；將來的opt-in review plumbing不代表本輪有任何live額度。

Parent先在當次已知context下gate：strict pure OAuth error、完整未截斷UTF8<=4096，literal/case/common URL/JSON/HTML/Base64已知敏感值、URL/control/bidi、24+ opaque identifier-like序列命中均整段不顯示。然後detach observer、清理Attempt/context/body/fields/code及main配置參照，確認cleanup後才launch。這只是有限偵測與參照生命週期控制，不保證未知秘密、任意混合編碼、immutable strings或OS/allocator物理zero。

Helper停用文字選取/編輯/自動偵測、空白app menu、不提供copy/export，window不restorable且sharingType none；目前僅實作與protocol受控驗證，尚未以synthetic互動完整驗證copy/export/restoration、timeout和異常關閉，不能宣稱OS無留痕或任意截圖防護。請勿截圖/複製/記錄原文；agent/Reviewer/CUA不得看live原文。

本輪新增OAuth=0；共享R→T1/1已用盡，P/Q/R/T歷史不可回填或重判。正常App/API/canvaspassed不重做。任何將來live仍須另行明確授權，不能因offline校準通過自動執行。
