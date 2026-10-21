# 正式 OAuth 能力與獨立驗證 App：受限執行計畫

- Topic：`github-first-sign-in`；2026-10-20，Plan-Creator amendment，已獲獨立 Plan-Reviewer A02 approved（無required fix）。
- Branch：`feat/github-first-sign-in`；base／PR target：`dev`；基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22`。
- 沿用原 feature worktree／[Draft PR #61](https://github.com/a129924/rivet/pull/61)，不建新 worktree／PR、不在 dev 實作、不 merge。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[step](github-first-sign-in.step.md)。


## V：繁中 synthetic／offline 校準受限計畫（現行；V02 pending）

原feature／feat/github-first-sign-in／DraftPR61，基線fbbc2fb0，不新worktree／PR／merge。技術集中 [technical-spec V](../../analysis/github-first-sign-in/technical-spec.md)。Human已同意本機繁中offline；installed前置已由外部Tester核實，不當語義pass。現在V01只Modify四planning、Written/Deleted0；V02獨立approved前不改工具／新fixture。U06舊16／6/9＋2/7及57tests／P/Q/R/T與App/canvas原證據保留，OAuth0。

### V 精確候選 manifest（只在 V02 後分slice授權）

Modify11（每項精確檔，不是目錄授權）：

1. `apps/GitHubSignInVerification/tools/pkce_negative_probe.py`
2. `apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py`
3. `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift`
4. `apps/GitHubSignInVerification/tools/README.md`
5. `analysis/github-first-sign-in/requirements.md`
6. `analysis/github-first-sign-in/technical-spec.md`
7. `plan/github-first-sign-in/github-first-sign-in.plan.md`
8. `plan/github-first-sign-in/github-first-sign-in.step.md`
9. `README.md`
10. `docs/architecture/github-first-sign-in.md`
11. `plan/github-first-sign-in/evidence/pkce-semantic-review.md`（只追加V，不改既有U／歷史段落）

Written1：`apps/GitHubSignInVerification/tools/fixtures/semantic-review-zh-v1.json`（獨立Tester建／Reviewer先核freeze，Implementer只schema/hash）。Deleted0。正式source/API、App/tests、rootpackage、舊Englishfixture、過去evidence段落／frozen圖、他topic及6他人Appdirty全部readonly；不讀寫／暫存／還原外部dirty。譯文runner binary／synthetic檢查輸出僅外部scratch，不加repo檔；語義收據在既有evidence追加。任何未列path先回修計畫。

### V 路由：先真引擎語義，再UI，沒有新增Human批准停點

| ID | Owner role | 完成條件／允許子集 |
|---|---|---|
| V01 | Plan-Creator | 只四planning新增V契約，現在完成後交V02，不自審 |
| V02 | Plan-Reviewer | 獨立approved才V03；formal verdict pending |
| V03 | Tester→Reviewer | 建新bilingual16，核source/ref/labels/schema後freeze／交schema+SHA；只新fixture與自身evidence/step |
| V04a | Implementer | helper同一translate function＋固定synthetic-only runner／controlled接點；必要CLI test、helper、自身evidence/step；不先接ChineseGUI |
| V05a | Tester | 先真on-device runner16序列／每例一次／無retry／360秒總watchdog、不開GUI；輸出只新frozen synthetic給Reviewer |
| V06a | Reviewer | 獨立逐例fidelity16/16及translator來源核查，明示approved才V04b；一例失真／錯誤／未ready停止，不請Human／不改標 |
| V04b | Implementer | 在既定工具內完成v2UI／Chinese CLI與tests，再更新指定docs；不得讀holdout答案 |
| V05b | Tester | 完整controlled／strictformat／lint／v1回歸／privacy與protocol；不自動開Human校準 |
| V06b | Reviewer | 獨立code／scope／安全／實際fidelity與evidence；fixes回原bounded slice→Tester→Reviewer |
| 工具交付 | Implementer | requiredfixclosed後依原topic授權commit/push原Draft61／local bounded PR Lens，不新增發布批准停點、不merge |
| V07 | Human；Tester記錄 | 明確操作 `python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review-zh`，只中文新9+7；現在pending、不自動啟動 |

V05a有技術失敗立即停；V06a發現語義失真停後續，不浪費接GUI／再請Human。先驗成功也不預填V05b/V06b或Human達標。任何live／OAuth／新code授權均0，舊英文16不重跑、不當V成績。

### 每個 slice 開始／完成都必須同九欄

- In-Scope：列該row責任、技術節與精確manifest子集；不得把整mission任改。
- Out-Of-Scope：live/OAuth／正式Swift契約／任意語言／雲端下載／舊16改標或重判／他人dirty。
- ReadOnly：正式source/App/tests／舊fixture／歷史evidence／圖／他topic與非本slice檔案；V03freeze後fixture也readonly。
- Written：planned與actual分列；只有V03可建唯一新fixture，Implementer不能建立標準答案。
- Deleted：0。
- Modify：開始逐檔列必要子集，完成記實際diff與來源；本輪V01只有四planning。
- Goal：該階段可觀察結果／gate；先translator fidelity再UI，不把不同層級證據互代。
- Non-Goal：不怪Human、不把機譯／controlled／inventory當proof／遠端／Humanpassed，不保證全機無網路／任意秘密偵測／OSzero。
- TestCase：VT IDs、synthetic/實際引擎/Human層級、命令／SHA／結果；未執行與已通過分開，不放expectedlabels到Human或工具。

### VT 驗證／停止

| ID | 驗證 |
|---|---|
| VT01 | installed-only／canRequestDownloads=false／isReady、固定en→zh-Hant、20秒deadline及不可用失敗；不translationTask/prepare/cloud/download；mac26+工具限制、正式mac15不改 |
| VT02 | v1exact兩key/五field與100秒不變；v2exact兩key/七field、16KiB/4096/512bounds、stderr任一byteunknown、120秒parent、finite translation_status／source軸與proof獨立 |
| VT03 | 新16source/ref/labels先獨立核freeze；同函式test-only固定path/hash／stdin空／無任意dump／正常binary無入口；真engine16/16polarity/modality/因果/角色／無增刪因，任一不符即停 |
| VT04 | 完整譯文<=8192bytes／空白不可信超限拒顯、不截斷；URL/control/bidi/opaque保守gate；先gatecleanup→launch、無英文fallback、中文固定機譯非proof標示、30/20/60秒及cancel/late/exception |
| VT05 | 獨立中文offline命令不進live/IDsecret/socket/browser；shuffle且工具不讀比ref/labels／不自評，只safeopaqueobs由Tester核分；v1與原57相關回歸不冒充Vpassed |
| VT06 | Human將來只看新中文16、9/9＋7/7才達標，全unknown不pass；不改ref/label配合，不自動點UI，達標也無live額度 |

本輪不執行測試或圖工具。V04/V05只做工具範圍tests、helper strictformat／SwiftLint，不掃App/tests或改他人dirty；新真engine輸出清楚標synthetic，agent永不見live原文／譯文。未來publication沿原PR真diff的受限PR Lens策略；不新圖／module／實驗或工具設定。現交V02，不自行宣告approved。

### V 最新外部狀態紀錄

外部獨立Plan-Reviewer已明示V02 approved、無required fix，可由V03起續行，無額外offline停點。V03獨立Tester造新fixture in-progress；V04a Implementer core／runner in-progress，可並行且不依賴labels，但真翻譯必等V03 Reviewer核標freeze。V04b GUI仍pending，必等V06a16/16 fidelity明示approved。OAuth0，技術／manifest不變；此為外部事實登錄，不是新增quality結論。


### V 本輪 actual 結果與 bounded 文件回寫

V03新fixture已獨立approved／frozen；V04a只保留installed-only translator core與compile-time固定fixture runner作研究證據，正常binary無dump、CLI未改。V05a唯一真引擎序列16/16技術成功（2.646s、exit0、stderrfalse），58受控／compile／strict通過；獨立V06a語義fidelity failed／needs-rework，至少8處術語／角色失真，不編造精確語義通過數。另一次bounded code Reviewer approved、無required fix／不需額外驗證，僅研究工具code，不推翻fidelity失敗。中文GUI／CLI／Human校準未執行且停止，不宣稱繁中能力已交付。語言包installed、OAuth新增0；U06／PQRT／App/API/canvas歷史保留。Human最新允許規劃AI閱讀經安全檢查的描述，並接受資料可能離Mac／留於對話服務及gate殘餘風險；僅規劃，實際原文揭露／bridge／具體欄位與傳遞方式尚未批准，OAuth0，不擴V實作。

Actual implementation僅 `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift`、`apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py` 的研究core／test變更，及V03由獨立Tester建立並核准freeze的新 `semantic-review-zh-v1.json`。CLI.py沒有改，Chinese protocol/UI/CLI等planned能力未交付；先前11Modify／1Written是允許範圍，不是實際完成清單。獨立Reviewer已允許保留core+compile-time固定fixture runner作研究證據，不將V04b等標完成。

原scratch JSONL不可再讀且無原bytes hash，語義來源只限Tester同次工具輸出直接轉交Reviewer的實際synthetic譯文，不以reference重建、不追補／重跑。V06a失敗依既定門檻停止V04b／V05b／V06b與V07；新增bounded code review approved只涵蓋保留的研究工具，無required fix／不需額外驗證，不等於後半Chinese產品能力review完成。Human最新只允許AI reader方案規劃；具體欄位／傳遞與實際原文揭露／bridge仍未批准，留後續獨立草稿／review，不擴本V。

本次docs-only九欄：

- In-Scope：記actual研究core／技術成功與fidelity失敗、來源限制、停止及Human決策界線。
- Out-Of-Scope：code／fixture／CLI／GUI／live/OAuth、重跑或追補scratch、批准新reader/privacy方法、commit/push。
- ReadOnly：所有code/fixtures、正式App/tests及6他人dirty、舊evidence段落／U/Q/P/R/T／圖／非manifest檔；不讀label或機密。
- Written：0（本文件slice；V03新fixture另屬Tester既有結果）。
- Deleted：0。
- Modify：requirements.md、technical-spec.md、plan、step四planning；README.md；tools/README.md；docs/architecture/github-first-sign-in.md；既有evidence/pkce-semantic-review.md，均沿原精確paths，只本slice owned docs。
- Goal：可交獨立文件review的真實研究結果，不宣稱中文能力交付。
- Non-Goal：不自產quality結論，不把codeapproval／技術16/16當語義passed，不編造精確通過數。
- TestCase：只登錄已明示58controlled／compile／strict與唯一engine16/16、2.646s／exit0／stderrfalse及外部fidelity/code verdict；本角色不跑新驗證。

## U：Human-only 語義 review（規劃來源保留；最新離線交付事實見本節末）

來源 `9f603f81d77040a2e06ad178062e8cfecc4de468`；原 feature／branch／Draft PR61 不變。Human 同意原文可見性方案進入規劃，不等於實作或新 OAuth 授權；初步 Reviewer 四 fixes 滿足不是 U02 formal verdict；現獨立 Plan-Reviewer 已另明示 U02 approved、無 required fix，只核准本次四檔 planning，整體停 Human／human-check。技術方案集中於 [technical-spec U 節](../../analysis/github-first-sign-in/technical-spec.md)，本節不重寫歷史判準或證據。

### U 規劃階段九欄（歷史；現行離線授權見後段）

- In-Scope：U01 四文件 amendment、U02 獨立 formal planning review，之後停 Human。
- Out-Of-Scope：任何 CLI／helper／fixtures／tests 實作、offline Human 校準、工具／Git／發布／新 OAuth。
- ReadOnly：全部 code／tests／正式 source/API／experiments／frozen 圖／P/Q/R/T 歷史 evidence／其他 topic；正常 App／再次 API／canvas passed 不重做。
- Written：無。
- Deleted：無。
- Modify：僅 `analysis/github-first-sign-in/requirements.md`、`analysis/github-first-sign-in/technical-spec.md`、`plan/github-first-sign-in/github-first-sign-in.plan.md`、`plan/github-first-sign-in/github-first-sign-in.step.md`；只新增 U 節。
- Goal：給 Human 具體可審查的 gate→清理→私有 pipe/helper→獨立語義 attestation 方案。
- Non-Goal：不把 attestation 當 proof、不改 outcome／pkce_rejection_proven、不重建舊原文、不聲稱全盲／任意秘密偵測／OS無留痕或物理zero。
- TestCase：以下 US01–US05 只列未來規劃，均未執行；本輪只文件閱讀與新增 U 節。

### U 規劃時 phase 與停止點（歷史）

| ID | Owner role | 完成條件／目前授權 |
|---|---|---|
| U01 | Plan-Creator | 只四文件新增 U：manifest、privacy/protocol、獨立校準與限制；不產生 implementation approval |
| U02 | Plan-Reviewer | completed；獨立 Plan-Reviewer 明示 formal verdict approved、無 required fix；下一 phase Human boundary／human-check，不放行未來實作 |

U02 後停 Human，即使 approved 也不自動派 Implementer／Tester／Reviewer 做工具或離線校準；它只是規劃 verdict。未來 implementation、synthetic holdout、offline Human calibration、code review 及任何 live 都須另行放行，不能沿用早前 topic 發布／實作授權越過此新 Human boundary。R→T 1/1 已耗盡，本輪新 OAuth=0，不選 case／不執行。

### 既定 manifest（規劃時 NOT AUTHORIZED；現已授權 bounded offline，paths 不變）

以下不是本輪 allowlist；僅供 U02 審查預計 blast radius。未來每個 bounded slice 的開始／完成 handoff 仍列同九欄，planned allowed paths 與 actual Written／Modify／Deleted evidence 分開，不新增 shared module／target。

Modify 9：

1. `apps/GitHubSignInVerification/tools/pkce_negative_probe.py`
2. `apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py`
3. `apps/GitHubSignInVerification/tools/README.md`
4. `analysis/github-first-sign-in/requirements.md`
5. `analysis/github-first-sign-in/technical-spec.md`
6. `plan/github-first-sign-in/github-first-sign-in.plan.md`
7. `plan/github-first-sign-in/github-first-sign-in.step.md`
8. `README.md`
9. `docs/architecture/github-first-sign-in.md`

Written 3：

1. `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift`（private Swift／AppKit script）
2. `apps/GitHubSignInVerification/tools/fixtures/semantic-review-cases.json`（純 synthetic holdout；獨立 Tester 建、Reviewer 核標凍結）
3. `plan/github-first-sign-in/evidence/pkce-semantic-review.md`（未來只存安全結果、來源與限制，不存原文）

Deleted 0。正式 source/API、App、既有輸入／交換／TTY／loopback 安全與 outcome/proof 政策、experiments／frozen 圖／歷史 evidence／其他 topic 全部唯讀；工具擴充只限 opt-in Human review gate、cleanup與private helper protocol，不改 OAuth 交換或做新 negative case。未來若需要其他檔案，先回 planning，不借目錄授權擴寫。

### US 驗證判準（規劃來源；實際結果見最新實作紀錄）

| ID | 規劃中的驗證／停點 |
|---|---|
| US01 | strict pure-error shape、4096 UTF-8 bytes完整不截斷、已知context的literal/common URL/JSON/HTML/case/Base64及URL/control/bidi/opaque gates；命中整段不顯示；未知秘密／任意編碼能力不保證 |
| US02 | gate後finally detach/clear所有當次敏感參照，再launch；匿名stdin總16KiB、strict JSON；stdout512bytes有限schema，stderr不forward；invalid/extra/duplicate/trailing/partial/nonzero一律static unknown；強error衝突強制conflict |
| US03 | default no UI／no auto reveal、30秒密封、明示一次reveal60秒／無第二次、100秒parent watchdog、取消／異常清理；AppKit copy/export/restoration先synthetic實證，操作約束不冒充技術保證 |
| US04 | Tester建16例holdout→Reviewer核標凍結→Human不看expectedlabels離線校準；3mismatch/3grant/3config/7abstain，9/9decisive正確且7/7unknown才pass；全unknown不pass，失敗禁止live／不得改標 |
| US05 | provider_semantic_observation/review_source=local_human與既有outcome/proof獨立；拒絕raw出stdout/stderr/log/file/env/argv/screenshot/clipboard；無原文不可由agent獨立稽核；歷史/預算不改 |

正常 App/canvas 與歷史 tests 不因 U 規劃重跑。Graphify／PR Lens／Archify 本輪不執行、不生圖或map。U02 正式規劃核查 approved、無 required fix 保留；gate/UI/protocol 的 bounded offline 已授權且實作事實見末段，獨立驗證與 Human 校準不得預填通過。未來若另給 live 額度，wrong 僅為推薦候選且不能保證判定；需 Human 明訂 case／次數，不回填舊案。

### U 最新授權／狀態：bounded offline implementation（現行，原停點保留歷史）

U02 技術方案仍為獨立 approved、無 required fix。主 agent 先前增加的「offline 實作再批准」停點現移除：依原同 topic 必要回修／實作授權與 Human 在工具修改／離線測試脈絡的續行要求，只在上列 **9 Modify／3 Written、Deleted 0** 內啟動離線實作、Tester、Reviewer 與 synthetic Human calibration 準備。原 NOT AUTHORIZED 文句為先前狀態，不再限制這些 bounded offline 工作；技術／manifest／US 判準皆不改。未來 live 仍 NOT AUTHORIZED、新 OAuth=0；Human 校準不自動開始。

本次 Plan-Creator 仍只改四 planning，先凍結給原 Plan-Reviewer 確認授權／狀態紀錄；不執行 implementation／tests／Git。兩份他人 dirty Swift hosted tests 完全排除：不讀寫、不暫存／還原，不因驗證掃入它們。

| ID | Owner role | 現行 status／完成條件 |
|---|---|---|
| U03 | Implementer | completed；工具凍結交付，既定技術／manifest不變 |
| U04 | Tester | completed；P2回修後獨立親跑57tests、strict format／SwiftLint exit0；不代Human校準／live |
| U05 | Reviewer | approved；外部獨立Reviewer最終明示P2closed／無其他required fix，限工具交付與Human正式offline校準 |
| U06 | Human；Tester記錄 | pending／human-check 停點；工具及獨立 review 準備完成後，由 Human 明確參與 synthetic 校準；未參與保持 pending，不自動開窗／代填結果 |

U03–U05 可做受控工具開發與 synthetic 技術驗證，不能把未來 Human 9/9 decisive＋7/7 unknown 預填通過，也不以全 unknown 宣稱校準 pass。U06 是人類互動停點；即使日後校準通過也不給 live 額度。其後 topic 發布沿原授權與獨立 verdict，本輪先完成可測工具，不在本次 planning 記錄中做 commit／push／PR 操作。

#### U03 bounded implementation 九欄（planned slice）

- In-Scope：既定 parent privacy gate、先清理再 helper、private Swift/AppKit protocol／timeout／有限安全輸出與單一 Human offline 入口：`python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review`。此分支無網路、不要求 ID／secret，不印 expected labels；只按既定 helper 單 record protocol 循序送入 16 個 frozen synthetic cases，每次顯示仍須 Human 明示，不自動校準。
- Out-Of-Scope：live／新 OAuth／自動 Human 校準／改 proof/outcome／改判準／自訂 holdout labels／正式 App／他人 dirty tests。
- ReadOnly：正式 source/API、App hosted tests、OAuth 傳輸／TTY／loopback政策、experiments、圖與歷史 evidence；沿原 manifest readonly。
- Written：planned helper `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift`、`plan/github-first-sign-in/evidence/pkce-semantic-review.md`；holdout 檔由 U04 Tester 建，不由 Implementer 自訂標準。
- Deleted：0。
- Modify：既定 9 Modify 的必要子集；開始交接逐檔展開，完成才記 actual diff；不擴 paths。
- Goal：交付可測的 offline 工具與明確安全／技術限制，供獨立驗證。
- Non-Goal：不宣稱 Human 校準／語言全面準確或 PKCE 遠端原因通過。
- TestCase：US01–US03／US05 的 synthetic 技術測試，US04 僅準備接點；結果待實際交接。

#### U04 Tester 九欄（planned slice）

- In-Scope：獨立離線 privacy/protocol/timeout/cleanup/UI限制測試，由 Tester 定義 fixture schema、建立純 synthetic 16-case holdout及 expected labels，交 Reviewer 核標凍結；Implementer 不建立標準答案，校準入口依此 frozen schema 整合。
- Out-Of-Scope：產品實作修改、Human 自動校準、live／secret／新 OAuth、為結果改標。
- ReadOnly：工具實作、全部正式 source/API／App hosted tests／歷史 evidence／圖；不觸碰他人 dirty tests。
- Written：planned `apps/GitHubSignInVerification/tools/fixtures/semantic-review-cases.json`；僅 synthetic，不含任何 live 原文。
- Deleted：0。
- Modify：新 `pkce-semantic-review.md` 與 step 的自身事實；不改工具 source 或技術判準。
- Goal：提交可追溯的獨立受控結果、holdout 與未驗證能力清單。
- Non-Goal：不代 Reviewer 核准、不把 synthetic 技術 pass 當 Human 語義校準 pass。
- TestCase：US01–US05 適用離線部分；16 labels／3+3+3+7 組成供 U05 回查，Human 成績保持 pending。

#### U05 Reviewer 九欄（planned slice）

- In-Scope：獨立 code/scope/privacy/protocol/evidence review，以及 holdout 核標與凍結；required fixes 明示路由。
- Out-Of-Scope：自行改受審 source、改標配合結果、執行 Human 校準／live、新 OAuth。
- ReadOnly：受審工具、holdout、正式 source/API、他人 dirty tests、歷史 evidence 與圖。
- Written：無。
- Deleted：0。
- Modify：新 `pkce-semantic-review.md` 與 step 的自身 verdict／事實，不改 manifest 或技術政策。
- Goal：給可追溯獨立 verdict，標示可交 Human 校準準備或 required fixes。
- Non-Goal：不批准 live／新預算，不冒充 Human 已看過原文或校準已過。
- TestCase：US01–US05 的受控證據、holdout labels／組成／凍結來源核查；Human 9+7 結果不預填。

#### U06 Human offline calibration 九欄（planned 人類停點）

- In-Scope：U03–U05 完成後，等待 Human 明確參與既定 frozen synthetic holdout；Tester 僅記安全成績／來源。
- Out-Of-Scope：自動開啟／校準、expected labels 提示、live description／新 OAuth、失敗後改標。
- ReadOnly：frozen 工具與 holdout、正式 source/API、他人 dirty tests、全部歷史／圖。
- Written：無。
- Deleted：0。
- Modify：Human 真實參與後，只更新新 `pkce-semantic-review.md` 與 step 的安全結果；尚未參與不寫 pass。
- Goal：取得 9/9 decisive 正確且 7/7 unknown 的實際離線校準，或如實記 failed／pending。
- Non-Goal：不保證全面語言準確、不變更 proof/outcome、不因此開 live 或取得額度。
- TestCase：US04 既定 16-case 與既定判準；目前 pending，人類未開始。

### U 最新執行狀態紀錄

既定 offline confirmation approved／無 required fix 保留，9 Modify／3 Written 範圍內 U03 工具已實作並凍結：`python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --calibrate-semantic-review`，無網路／ID-secret；private Swift/AppKit helper與parent gate／cleanup／pipe已有實作。U03 completed；P2 selectors/stderr回修後，獨立U04親跑57項controlled tests通過、strict format／SwiftLint exit0，U04 completed；獨立U05最終approved、P2closed／無其他required fix。完整UI／clipboard／restoration／timeout與U06 Human9+7仍pending，單次smoke不當自然timeout或holdoutpassed。

已允許安全替代：SystemRandom打散synthetic，UI不見labels/id；工具不讀／比較expected_category、不自評，末尾僅opaque correlation_id＋有限observations由獨立Tester核分。原自評寫入被auto-review拒絕未執行、未重試，未改9+7標準／manifest／原proof/outcome。U06仍Human停點、不自動校準；新增OAuth0，live另需明確授權，R→T1/1與全部歷史不改。本次只登錄外部U04／U05事實，不自產approval、不改code／fixture／凍結evidence。原topic commit／push／更新DraftPR61授權有效，可交Implementer完成既定12file工具交付，之後停U06 Human，不另造發布授權停點。

### U06 結果處置：docs-only 記錄與停止（現行唯一寫入範圍）

基線 `f420901a1076537c4f7aa0404fe31509b8bdc889`，原feature／branch／DraftPR61不變。外部獨立Tester已核frozen fixture SHA與16唯一映射：decisive6/9、abstain2/7，calibration_threshold_met=false，未達9/9＋7/7。U06 completed-not-qualified、method needs-rework，停Human方法決策、禁止live。Human不懂英文是方法前提未滿足，不是人類過失；57controlledpass／U05codeapproved保留，不宣稱OAuthbug或PKCEfailed。獨立Reviewer已approved結果處置，僅准本docs記錄與停止，不授權新方法或code。

本slice九欄：

- In-Scope：安全16筆實際選擇、外部核分／處置、英文方法不適用與停止狀態。
- Out-Of-Scope：改frozen fixture／labels、重跑16、新UI／code／OAuth、翻譯方案實作／安裝／下載、Git／發布。
- ReadOnly：除下列8tracked docs以外全部；包括6份他人dirty App/tests，不讀寫／暫存／還原；凍結工具／fixture／四SHA／P/Q/R/T及smoke歷史不改。
- Written：0。
- Deleted：0。
- Modify：僅下列8個精確paths；只加最新U06結果，當時pending保留為歷史。
- Goal：如實記completed-not-qualified、calibration_threshold_met=false與Human方法決策停點，禁止live。
- Non-Goal：不責怪Human、不改proof/outcome、不把57tests或機譯當語義校準／遠端PKCE證明。
- TestCase：僅登錄外部Tester的16unique/SHA核對、6/9及2/7；不自行重算、測試或讀expectedlabels／raw。

Modify8：`analysis/github-first-sign-in/requirements.md`；`analysis/github-first-sign-in/technical-spec.md`；`plan/github-first-sign-in/github-first-sign-in.plan.md`；`plan/github-first-sign-in/github-first-sign-in.step.md`；`README.md`；`docs/architecture/github-first-sign-in.md`；`apps/GitHubSignInVerification/tools/README.md`；`plan/github-first-sign-in/evidence/pkce-semantic-review.md`。

smoke為此前受手動操作中止的獨立事件，不算16case，不回改當時pending。App/API/canvaspassed、P/Q/R/T unknown與共享R→T1/1耗盡不變，新OAuth0。新語言方案另待Human；Apple官方on-device framework只可作未授權研究候選，不能將機譯當proof，任何新本機元件讀description仍需Human確認。本次不執行任何新元件工作。

### V 前置狀態：僅記錄資產缺口，尚不建立實作計畫

最新Human已同意本機繁中offline候選及新增Apple on-device元件讀gate後description，原文／譯文僅本機記憶體短暫Human視窗，agent不看不存；不雲端／不自下載，live仍未授權、OAuth0。外部一次唯讀inventory compile/run exit0／stderrfalse，en→zh-Hant及en→zh-TW皆supported非installed，所需資產未齊而候選目前不可用；詳technical-spec的V前置facts，不作新工具／experiment或方法通過證據。

Human已同意自行下載，等待完成回報才重查；既有inventory仍supported非installed，本輪未翻譯／下載／新查，不建立V工具implementation plan／新fixture，不執行session／prepareTranslation／UI／OAuth。此docs slice仍Modify8、Written0、Deleted0，沿U06九欄及相同readonly邊界，只登錄前置facts／授權／停點；不改U06 frozen16obs／6/9＋2/7未qualified，不把機譯當proof。

## T 輪現行最小診斷改善（優先於R停止及Q/P/A/S寫入授權）

來源HEAD90646c2；原feature/feat/github-first-sign-in/原DraftPR61，不dev實作、不建worktree/PR、不merge。User已要求實作最小改善，採technical-spec§11的version3 actualprepared觀測＋bounded grammar/hints，不以無法保證遠端結論停止。沿用R唯一未使用額度，**共享R→T規劃時0/1、T06後現1/1用盡**，不是新增預算；case選wrong，一次fresh單POST，不第二次。

現行T06已完成：唯一wrong的localprepared一致，HTTP400 invalid_grant/無token但完整grammar未命中，依事前§11仍indeterminate；共享R→T1/1用盡，停止新授權。以下pending及流程為執行前契約，實際結果見T06摘要及v3 evidence，T07複核中。

### T精確manifest

Modify：

- `apps/GitHubSignInVerification/tools/pkce_negative_probe.py`
- `apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py`
- `apps/GitHubSignInVerification/tools/README.md`
- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`
- `README.md`
- `docs/architecture/github-first-sign-in.md`

Written唯一：`plan/github-first-sign-in/evidence/pkce-diagnostics-v3.md`。Deleted/rename：無。CLI僅私有診斷/Attempt/Deadline/authorize/send_token/run_case為被動prepared觀測允許更動；交換算法/endpoint/timeout/retry/TTY防fallback/loopback安全規則不可改，exchange_fields不改。所有正式Swift/credential/provider/scope/refresh401、其它code/tests、實驗、圖、全部舊PQR evidence、其它docs/topic/worktree皆ReadOnly，不新API/module。不重做e941d88正常positive/API或canvaspass，不讀App配置。

### 每slice九欄

- In-Scope：T03a §11私有observations/grammar/hints與tests；T03b允許docs/新evidence與來源預算提示。
- Out-Of-Scope：正式API/傳輸策略/交換算法/endpoint/timeout/retry/TTY/loopback安全改動、新module、positive/API/refresh401、回改舊evidence。
- ReadOnly：上述完整ReadOnly及90646c2來源，R歷史停止不等於本輪禁止已授權私有改善。
- Written：唯一v3 evidence，開始為planned，完成才actual。
- Deleted：無。
- Modify：每slice從九個精確paths列actualhunks/paths；不以全清單代完成。
- Goal：actualprepared本機一致性與bounded全句關係診斷，safe version3結果有可辨識新資訊。
- Non-Goal：不證明遠端wire/code發行時間/grant狀態，不保證遠端PKCE結果可判定，不新增預算。
- TestCase：RD01–RD05及實際命令/來源/結果/限制；Human前freezeSHA，wrong新唯一1次pending。

### T流程

| Step | Owner role | 完成條件 |
|---|---|---|
| T01 | Plan-Creator | 四planning具§11固定grammar/觀測/manifest/共享預算與九欄 |
| T02 | Plan-Reviewer | 獨立approved，不沿用R/Q核准 |
| T03a/T03b | Implementer | approved後boundedimplementation/docs，各slice開始/完成九欄 |
| T04 | Tester | fake RD01–RD05/既有回歸及ReadOnly核對 |
| T05 | Reviewer | 獨立code/scope/evidence review，requiredfixesclosed |
| T06 | Human | live前freezeSHA，一次一步ask-question，僅wrong新code單POST，共享R→T0/1→1/1 |
| T07 | Tester → Reviewer | safe version3 JSON/來源/分類/預算/限制獨立記錄及複核 |
| T08 | Implementer → Human | topiccommit/push/更新原DraftPR61/localPRLens受限Graphify→Humanreview |

R0/1只是額度歷史，T沿用同1次；任何帳本不能並列成R剩1次加T新1次。T06若失敗或indeterminate也消耗該唯一授權，無第二次、不補rawbody或live後改表。不讀secret，Human只在terminal隱藏輸入，不貼callback/配置。沒有重大scope問題依已授權commit/push/原PR更新完成，不重問。

### RD tests（fake-only，無新傳輸策略）

| ID | Cases |
|---|---|
| RD01 | RFC7636 publicvector；actualURL/Request觀測且不mirror；故意mutation client/redirect/code/state/challenge/method/duplicateform/verifiershape皆可detect；未observed不默認true、不pass |
| RD02 | §11每grammar型態/三alias/成對quotes/有限prefix/suffix，legacy19優先；negation/extratail/不成對引號/超長/未知句拒絕；hint有無不影響proof |
| RD03 | known/unknownerror、strong優先、description/caseconflict、token優先failed、shape/HTTP/network/timeout矩陣；classify獨立可測但run_case須actualconsistency及negativegate |
| RD04 | fakeclock timebucket在0/5/30邊界與負/非有限；callback-return而非code_age；observer每prepared事件至多一次及finally解除/Attempt.clear；單POST/no retry/TTY fallback既有回歸 |
| RD05 | capture全部stdout/stderr含secret/clientID/code/state/verifier/challenge/rawURL/body/error/exception sentinel；safeversion3 enums/bools；sourceReadonly/舊PQR evidence/預算/凍結SHA與safeJSON來源核對 |

Fake命令：`python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p 'test_pkce_negative_probe.py'`。root/consumer/appsource未動沿用已通過證據，必要hooks實跑照實記。Human僅在T05approved後於原featureterminal執行一次`python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case wrong`，確認safeversion3JSON，不另跑missing或positive。

PRLens真base/head diff僅local scratch validate/render，Graphify既有受限sourcefallback；無新圖ownership，不改frozen圖/toolconfig、不上傳。正式產品登入UI及遠端refresh401仍未交付／本輪不驗證。

---

## R 輪現行docs-only調查收斂（優先於Q/P/A/S寫入及live契約）

來源HEAD21e2542；原feature worktree／feat/github-first-sign-in／原DraftPR61，無dev實作、新worktree/PR或merge。User授權新一次且無可靠資訊增益則停止；本輪決定不消耗，R **0/1未使用**，不選case、不改CLI/判準、不live。P2/2與Q2/2 indeterminate歷史readonly；e941d88正常login/user/requery及canvasHumanpassed沿用。

### 精確manifest

Modify：

- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`
- `README.md`
- `docs/architecture/github-first-sign-in.md`
- `apps/GitHubSignInVerification/tools/README.md`

最後三檔僅追加R現行停止／預算與來源提示，不改舊Q歷史判準或結果。Written唯一新檔：`plan/github-first-sign-in/evidence/pkce-diagnostic-investigation.md`。Deleted/rename無。其餘所有code/tests（包括CLI與test）、正式Swift、rootPackage、全部圖、舊所有evidence、其它docs/topics/worktrees、工具config全部ReadOnly。較舊Q/P allowlist不能作本輪寫入授權。

### R03 bounded slice九欄

- In-Scope：只寫允許docs/evidence，調查fact/inference/noevidence分層、來源與停止結論。
- Out-Of-Scope：CLI/分類/transport更動、新模板、live/選case、讀配置/rawbody、新experiment/module/publicAPI、positive/API/refresh/401。
- ReadOnly：上述全部readonly及21e2542來源；舊P/Q原結果與e941d88正常pass不可重判。
- Written：唯一pkce-diagnostic-investigation.md，開始記planned、完成才actual。
- Deleted：無。
- Modify：該slice從七個精確Modify paths選actualpaths/hunks；不掃改其它docs。
- Goal：有來源的調查與停止理由，R0/1未用、PKCE仍indeterminate。
- Non-Goal：不宣稱所有bug已排除、正式OAuth有bug或enforcement通過；不擴預算。
- TestCase：RI01–RI03，實際命令/布林/來源/hash/限制，不能把本機檢查冒充live。

### R流程與最小驗證

| Step | Owner role | 完成條件 |
|---|---|---|
| R01 | Plan-Creator | 四planning最小追加，明示無live及manifest |
| R02 | Plan-Reviewer | 獨立planning verdict，舊Qapproved不替代 |
| R03 | Implementer | approved後docs/evidence bounded開始/完成九欄 |
| R04 | Tester | 獨立最小facts/hash/manifest/readonly/來源驗證，可親跑11bool，不重跑25或Swifttests |
| R05 | Reviewer | 獨立docs/scope/evidence review及required fixes關閉 |
| R06 | Implementer → Human | staged語意→topiccommit/push→更新原DraftPR/localmap必要同步→Humanreview |

RI01：核對technical-spec§10 source facts及官方來源，11bool若親跑則記命令/輸入為RFC公開向量與syntheticfixture、全部結果，無網路/機密。RI02：21e2542相對diff只在本manifest，CLI/tests/正式source/舊evidence/圖hash不變；R0/1未用，P/Q不改判。RI03：每層fact/inference/noevidence及停止理由與來源一致；正常pass/反向indeterminate/未驗證refresh401分列，無rawdescription/secret/URL/code/state/token值。

root已完成11bool檢查是上游實際事實；Tester須獨立核對或親跑後記自己的結果，不把planning當測試收據。不需重跑25tests或Swift受控suite，必要hooks實際執行照實記。無新人類驗證步驟，無OAuth命令讓Human執行。

Graphify沿既有受限sourcefallback；PRLens若交付head變更須以真base/head在localscratch必要同步validate/render，無上傳。無圖內容變更，不重畫、不重新發布。無重大scope/contract問題時依已授權同topic commit/push/更新原PR完成，不重問；人類停點為PR review，不消耗R授權。

---

## Q 輪現行最小診斷 amendment（2026-10-21；先於P/A/S歷史契約）

基線 `82489b68ff21e955611bde1e9028fff21dc68e74`，原feature/feat/github-first-sign-in/原DraftPR61，不新worktree/PR、不dev實作、不merge。已授權同topic commit/push/更新原PR，不重問。P輪2/2 unknown/indeterminate原樣保留且不可追補原body/重用/改判；Q新增兩次授權額度，missing/wrong各fresh單POST各一次。不得重做positive/API/remote refresh/401。

現行執行結果：Q06已完成，missing/wrong均indeterminate，各1/1總2/2用盡；以下pending及流程表是執行前條件，詳末尾Q06實際摘要及新evidence。不改原判準，Q07複核進行中。

### Q精確manifest（取代較舊廣泛寫入授權）

Modify：

- `apps/GitHubSignInVerification/tools/pkce_negative_probe.py`（僅有限分類/安全診斷version2）
- `apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py`（新版matrix及既有回歸）
- `apps/GitHubSignInVerification/tools/README.md`（新版安全輸出及Human逐步命令/額度）
- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`
- `docs/architecture/github-first-sign-in.md`
- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/github-oauth-dual-client.md`

最後五份長期docs僅同步最新觀察/限制，不添加產品需求。Written唯一新檔：`plan/github-first-sign-in/evidence/pkce-diagnostics-v2.md`。Deleted/rename：無。舊`pkce-negative-verification.md`及其它歷史evidence、全部圖、E001–E003、SwiftApp、rootPackage、GitHubIntegration與既有lifecycle、其它topic/worktree全部ReadOnly。CLI transport/TTY-getpass警告防fallback/loopback/PKCE生成/單次與無retry策略亦ReadOnly，不能因診斷需求改它們。CanvasHumanpassed與e941d88正常login來源沿用，無新圖/ownership改變。

### 每implementation slice九欄

- In-Scope：Q03a有限診斷分類/測試/工具README；Q03b新證據及允許文件最新狀態。
- Out-Of-Scope：transport/TTY/loopback/生成政策、正式能力bug修正、新API/module、重判P結果、positive/API/refresh/401。
- ReadOnly：上列ReadOnly及82489b6來源；Q不是較舊P寫入授權延伸。
- Written：唯一新pkce-diagnostics-v2.md，開始記planned、完成才actual。
- Deleted：無。
- Modify：每slice從Q精確list選actualpaths/hunks，不把清單視為完成。
- Goal：有限OAuth診斷及case-specific verifier證據，Human可辨識version2。
- Non-Goal：不保證遠端回應命中模板，不把generic拒絕/invalid_grant當enforcement證明。
- TestCase：QD01–QD05、實際命令/結果/來源；新Humanmissing/wrong執行前pending。

### Q流程

| Step | Owner role | 完成條件 |
|---|---|---|
| Q01 | Plan-Creator | 四planning最小追加manifest/固定判準/來源，保留P結果 |
| Q02 | Plan-Reviewer | 獨立approved後才Q03，不能沿用P核准 |
| Q03a/Q03b | Implementer | 兩slice開始/完成九欄，分類/測試與文件 |
| Q04 | Tester | fake-only QD01–QD05與既有回歸、readonly檢查 |
| Q05 | Reviewer | 獨立review、required fixes完成且approved才live |
| Q06 | Human | ask-question一次一步，先missing再wrong各freshprocess／一次授權／單POST；總2次 |
| Q07 | Tester → Reviewer | safe version2結果來源/分類/限制記錄並獨立複核 |
| Q08 | Implementer → Human | review後staged語意→topiccommit/push/原PR更新/local真diffmap→humanreview |

unknown/indeterminate/failed如實記，不自動增加授權、取得rawbody或事後改表；重大scope/contract問題才停受影響工作交Human。正式能力非已確認bug，不宣稱PKCE enforcement通過。

### QD驗證

| ID | Cases |
|---|---|
| QD01 | §9每個固定description完整模板、<=512/normalize/absent/nonstring/超長；known/unknowncode與所有case矩陣 |
| QD02 | required/mismatch/invalid-unspecified、case不符、強config/redirect/auth優先及已知description衝突；badcode/invalidgrant單獨不pass |
| QD03 | 僅提及verifier/否定詞/前後附sentinel/未知模板/未知error不得pass；token優先failed/JSONduplicate/mixed/HTTP/network/timeout有限分類 |
| QD04 | capture全部stdout/stderr含rawerror/desc/secret/code/state/token/URL/exception sentinels不得洩漏；diagnostic_version=2與全safeenum/bool；TTY/getpass防fallback與無retry既有regression |
| QD05 | transport/TTY/loopback/PKCE生成及readonlysource相對82489b6未改；P舊證據原樣，version2新結果只入新evidence；Human總2次、一次一步 |

Fake command：`python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p 'test_pkce_negative_probe.py'`。Human在原featuredirectory本機terminal、每步等待結果：`python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case missing`，再獨立新process `--case wrong`；輸入由原安全getpass處理，不將機密貼對話。收到diagnostic_version=2才記本輪；舊version不得冒充新結果。root/consumer/app未改者沿用既有證據，必要hooks照實記，不重做live正常授權。

Graphify既有受限sourcefallback；PRLens僅local scratch真base/head diff重新validate/render，不上傳、不改toolconfig。無新圖，frozen artifacts全readonly。

---

## P 輪現行最小 amendment（2026-10-21；先於既有 A/S 歷史契約適用）

- Source HEAD：`d11f343`；feat/github-first-sign-in／原feature worktree／Draft PR61不變。只在feature實作，不建新worktree/PR、不merge；已授權同topic commit/push/更新原PR，不重問發布授權。
- Human已驗收來源d11f343的index-v2.html：內容／流程／責任、拖曳、縮放可讀、聚焦說明、light/dark皆通過。file-URL policy原限制不繞過；不重畫frozen圖。
- 依序canvas驗收記錄→反向PKCE工具與受控驗證→Human兩case。正常授權/再次API沿用e941d88，不重做；遠端refresh/401本輪不做。正式產品登入UI仍未交付。

### 唯一現行 manifest

Written（精確新檔）：

- `apps/GitHubSignInVerification/tools/pkce_negative_probe.py`
- `apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py`
- `apps/GitHubSignInVerification/tools/README.md`
- `plan/github-first-sign-in/evidence/pkce-negative-verification.md`

Modify（只限本輪契約、canvas真實Human結果、PKCE實際結果/限制，不改舊證據結論）：

- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`
- `docs/architecture/github-first-sign-in.md`
- `docs/architecture/diagrams/github-first-sign-in/visual-review.md`
- `docs/architecture/diagrams/github-first-sign-in/BUILD.md`
- `docs/architecture/diagrams/github-first-sign-in/tool-evidence.md`
- `plan/github-first-sign-in/evidence/verification-host-amendment.md`
- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/github-oauth-dual-client.md`

最後四長期入口只允許同步最新Human觀察與仍pending限制，無新產品承諾。Deleted：無；rename：無。App Swift sources/tests/project/scheme、root Package與lock、GitHubIntegration所有source/tests/consumer、既有lifecycle、E001–E003及其它experiments、所有frozen圖spec/HTML/receipts/圖源、其他topic/worktree、skill/tool設定全部ReadOnly。先前A/S允許寫入的source/圖不能當成本輪授權。

### 每個 implementation slice 九欄

- In-Scope：P03a獨立stdlib CLI與fake tests／README；P03b允許文件與canvas來源紀錄。
- Out-Of-Scope：正式session bypass、SwiftApp變更、新sharedmodule/experimenttopic、positive/API/remote refresh/401、保存機密、其他topic/worktree。
- ReadOnly：上述完整ReadOnly清單及d11f343來源。
- Written：該slice從四個精確新檔選取的planned／actualpaths，不把清單當完成。
- Deleted：無。
- Modify：該slice精確允許文件＋用途；完成記actualdiff。
- Goal：反向missing/wrong各fresh單次交換且不誤報PKCE通過，canvasHuman事實有來源。
- Non-Goal：不把generic拒絕當PKCE通過、不宣稱遠端refresh/401或產品UI交付。
- TestCase：PK01–PK06、實際命令/結果/證據/限制；Human遠端兩case執行前均pending。

### 步驟與停點

| Step | Owner role | 完成條件 |
|---|---|---|
| P01 | Plan-Creator | 四planning追加最小manifest／判準／九欄，保留A/S與正向live歷史 |
| P02 | Plan-Reviewer | 獨立明示approved才可實作；不沿用A02核准 |
| P03a/P03b | Implementer | 各slice開始/完成九欄；新工具/測試/README與允許文件 |
| P04 | Tester | fake-only PK01–PK06、差異/readonly確認、必要checks；不live |
| P05 | Reviewer | 獨立source/scope/evidence review，requiredfix完成後明示verdict |
| P06 | Human | 一次一步ask-question；missing與wrong各新process各一次授權，最多兩次；不讓機密進對話 |
| P07 | Tester → Reviewer | 安全結果轉錄、來源/限制與分類複核；非通過結果仍如實保留，不因indeterminate自動擴做 |
| P08 | Implementer → Human | 獨立核可後topiccommit→push→更新原DraftPR61/local真diffPRLens→humanreview；不merge |

Human最多兩次新授權已明確授權；不額外跑positive、不自動重試。若failed token_present或indeterminate，不使用token、不擴跑/改正式契約，記結果與scopegap如適用，再交Human；indeterminate不是passed，也不必為完成文件偽造結論。P06需Human輸入，停在該humanboundary，不讀既有secret。

### TestCase／命令／判準

| ID | 受控驗證與實際結果要求 |
|---|---|
| PK01 | missing form沒有code_verifier key；wrong 43字元且challenge不同；每次fixture新state/verifier/challenge/code，不positive或API |
| PK02 | 正確host/path/GET/state/排他code-error才單次claim；缺失/重複/錯state/重複callback零額外POST；fresh不同、無retry/code reuse |
| PK03 | fake deadline／timeout／oversize／body／HTTP異常／redirect／proxy/cookie/cache配置及取消cleanup；header8KiB/connection16/read5s/auth5min/response64KiB/POST30s有界 |
| PK04 | token或mixed/空token值→failed；只pure allowlisted verifier error及2xx/400→passed；bad_verification_code/config/expired/network/unknown/shape/http→indeterminate |
| PK05 | stdout finite allowlist、getpass-only/noTTY failclosed；unknownerrors不echo；秘密/rawpayload/URL/exception/traceback不落stdout/stderr/磁碟；fake sentinel redaction |
| PK06 | readonlysource相對d11f343不變；canvasHuman來源與正常login分列；README可重現，兩case新process/一次一步、safe evidence無機密；PRLens真diff/Graphify受限 |

```sh
python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p 'test_pkce_negative_probe.py'
```

Human在原feature directory的本機terminal依序（每一步前等待Human結果）：

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case missing
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case wrong
```

CLI實作/分類/安全界線以technical-spec §8為locked contract。P04只跑fake tests與必要靜態/差異checks；root/consumer/app source未動時沿用既有275/13/9及strict evidence，hooks若執行照實記。新CLI不得產生__pycache__或rawlog證據。長期docs/證據只記安全case/status/分類/布林及來源，不貼callback/任何機密。

Graphify延用0.9.73/no-auto-refresh/無可用圖targetedsource fallback；PRLens0.11.0僅本機scratch真base/head diff validate/render，不上傳、不改repo工具設定。不新建／修改Archify或責任圖，現行canvasHuman通過與filepolicy限制並存，無需重跑視覺工具。

---


## 1. 現行 Goal 與九欄

交付為「正式 OAuth 實作能力＋獨立 GitHubSignInVerification App」。正式 Rivet 產品登入 UI 尚未交付。基線已完成 OAuth，本次只搬移並澄清驗證外殼，不重做正式能力。

每個 implementation slice 開始與完成交接均保留以下九欄，開始是 allowed paths，完成才記 actual paths／diff／結果，不能把允許清單抄成已完成。

| 欄位 | 本次受限內容 |
|---|---|
| In-Scope | A03a App/project/target/entry rename、app-local UI搬移；A03b 文件／圖修訂 |
| Out-Of-Scope | 正式產品登入或帳號管理、CurrentUserReader、新共用module/public API、其他topic/worktree、持久化及lifecycle重寫 |
| ReadOnly | 正式OAuth及既有credential/provider/scope/clients/refresh/rotation/single-flight/401、PR Inbox／Reader、frozen圖與歷史結果 |
| Written | 下列rename目的及新修訂圖／amendment evidence，逐slice展開精確paths |
| Deleted | 下列16個rename來源；除此無刪除授權 |
| Modify | 搬後host識別／存取範圍／引用、四planning、指定長期docs／工具證據 |
| Goal | 驗證App可build/test、明示驗證身份，正式OAuth與共用PR Inbox保持不變 |
| Non-Goal | 不把驗證UI說成產品交付；不宣稱新host真登入、反向PKCE或所有遠端refresh已驗證 |
| TestCase | TC01–TC09的適用regression／AT01–AT05搬移驗證；記實際命令、層級、pass/fail/pending與相對evidence |

## 2. 精確 manifest（本 amendment 的唯一寫入授權）

### Rename＝Deleted 來源＋Written 目的（A03a）

共16檔，apps/Rivet原13檔完整搬移，加上共用UI兩檔及其測試。每列均允許搬後必要內容修改，不代表行為重寫。

| Deleted：來源 | Written：目的 |
|---|---|
| `apps/Rivet/Rivet.xcodeproj/project.pbxproj` | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj` |
| `apps/Rivet/Rivet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` |
| `apps/Rivet/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme` | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme` |
| `apps/Rivet/Sources/RivetApp.swift` | `apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift` |
| `apps/Rivet/Sources/GitHubConnectionCoordinator.swift` | `apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift` |
| `apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift` | `apps/GitHubSignInVerification/Sources/GitHubLoopbackCallbackRelay.swift` |
| `apps/Rivet/Sources/GitHubAccountProbe.swift` | `apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift` |
| `apps/Rivet/Sources/InMemoryOAuthCredentialStore.swift` | `apps/GitHubSignInVerification/Sources/InMemoryOAuthCredentialStore.swift` |
| `apps/Rivet/Resources/Info.plist` | `apps/GitHubSignInVerification/Resources/Info.plist` |
| `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubConnectionCoordinatorTests.swift` |
| `apps/Rivet/Tests/GitHubLoopbackCallbackRelayTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` |
| `apps/Rivet/Tests/GitHubAccountProbeTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubAccountProbeTests.swift` |
| `apps/Rivet/Tests/InMemoryOAuthCredentialStoreTests.swift` | `apps/GitHubSignInVerification/Tests/InMemoryOAuthCredentialStoreTests.swift` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift` | `apps/GitHubSignInVerification/Sources/GitHubConnectionPresentation.swift` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift` | `apps/GitHubSignInVerification/Sources/GitHubConnectionView.swift` |
| `Tests/RivetPresentationTests/GitHubConnectionPresentationTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubConnectionPresentationTests.swift` |

允許搬後修改：project/scheme/app entry/product/test target/module、bundle identifier、TEST_HOST／BUNDLE_LOADER、imports/path references；從App移除RivetPresentation dependency；UI及Presentation型別移除public，無新module；窗口／畫面明示驗證App及非正式產品登入UI；User-Agent、queue label與靜態callback頁字串明確驗證用途。test key改 `GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE`，entry早於live建立檢查，scheme一致；protocol、callback policy及lifecycle不變。Package.resolved內容原樣搬移，不更新dependencies。

### Modify（A01／A03b／對應角色記錄）

- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`
- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/github-oauth-dual-client.md`
- `docs/architecture/github-first-sign-in.md`
- `docs/architecture/diagrams/github-first-sign-in/BUILD.md`
- `docs/architecture/diagrams/github-first-sign-in/visual-review.md`
- `docs/architecture/diagrams/github-first-sign-in/tool-evidence.md`
- `plan/github-first-sign-in/evidence/contracts.md`
- `plan/github-first-sign-in/evidence/compatibility.md`
- `plan/github-first-sign-in/evidence/product-e2e.md`
- `plan/github-first-sign-in/evidence/reviewer-verdict.md`

前五份長期docs改實際責任與新入口／命令／圖連結；不得再宣稱正式Rivet登入UI已交付。既有evidence只加基線來源／歷史限定聲明，不改舊測試或live結果，新結果放下列新證據。各角色只記自己事實與外部明示verdict。

### Written：新修訂圖與證據（A03b／A04／A05）

前綴 D=`docs/architecture/diagrams/github-first-sign-in`，每一項為精確檔案，不是整目錄授權：

- `D/scene-v2.js`
- `D/index-v2.html`
- `D/authorization-sequence-v3.json`
- `D/authorization-sequence-v3.html`
- `D/authorization-sequence-v3.delivery.json`
- `D/authorization-sequence-v3.visual-check.json`
- `D/authorization-sequence-v3.visual-check.html`
- `D/authorization-sequence-v3.visual-check.1440x900.light.png`
- `D/authorization-sequence-v3.visual-check.1440x900.dark.png`
- `D/authorization-sequence-v3.visual-check.2048x1320.light.png`
- `D/authorization-sequence-v3.visual-check.2048x1320.dark.png`
- `plan/github-first-sign-in/evidence/verification-host-amendment.md`

舊scene/index與已frozen的v1/v2 spec、HTML、receipts／screenshots原樣保留，不直接覆寫。新spec驗證後freeze；若工具另產生必要snapshot，先將精確名稱納amendment，再寫入，不借整目錄授權。Generated outputs只來自對應skill工具；衍生資料放ignored `.build/github-first-sign-in/VerificationHostDerivedData`；PR Lens用外部topic scratch，不入repo。

### ReadOnly

全部 `Sources/BoundedContexts/GitHubIntegration`（包括本topic正式OAuth五檔與原refresh/runtime）、GitHubIntegration tests／consumer source、通用HTTPClient、root `Package.swift`／`Package.resolved`、共用Presentation除上列搬移來源以外全部檔案、PR Inbox／Reader、experiments、其他topic/worktree、skills/runtime/AGENTS/hooks/config/.gitignore唯讀。必要新改檔未列manifest前不得寫入。Graphify／PR Lens策略沿用下文，不新增外部服務或repo工具設定。

## 3. Amendment 步驟

| Step | Owner role | 完成條件 |
|---|---|---|
| A01 | Plan-Creator | 四planning現行契約一致，先列rename/delete與Human Decision，保留歷史來源 |
| A02 | Plan-Reviewer | 獨立審manifest／責任／九欄／測試與locked decisions，明示verdict |
| A03a | Implementer | A02 approved後，bounded搬移App與UI、移除共用依賴，開始／完成均九欄 |
| A03b | Implementer | 文件與修訂圖反映正式能力／驗證host／未交付產品UI，工具驗證及限制分列 |
| A04 | Tester | 明示交接後獨立root／consumer／app／format／lint／隔離／diff／圖檢查 |
| A05 | Reviewer | 獨立code/scope/evidence review；required fixes回Implementer及Tester重驗，再複審 |
| A06 | Implementer | A05 approved後staged語意檢查→topic commit→push→更新原Draft PR61，真diff PR Lens |
| A07 | Human；Tester記錄 | 原Draft PR human review；新驗證App真登入及反向PKCE維持實際結果或pending |

使用者已授權同topic回修、commit／push／原Draft PR更新，不重問發布授權。不能merge；重大scope／contract問題才停止受影響工作交Human。舊S01–S08為歷史交付，不等於本amendment核准。

## 4. TestCase 與驗證命令

TC01–TC06：沿用基線callback/state/S256／交換完整bundle／取消settlement／store／provider-scope多次使用及lifecycle regression，搬移不改OAuth政策。TC07：新host fake-only tests及真實API probe判定；TC08：Human live與反向PKCE；TC09：docs／圖／受限工具及diff來源。不能把舊命令或舊host結果當成搬後重驗。

| ID | 本次新增驗證 |
|---|---|
| AT01 | 新project/scheme/app entry/target/product/module與bundle references一致；build/test成功；舊apps/Rivet來源不殘留 |
| AT02 | hosted scheme key與entry一致；fake-only零livecall；原coordinator/relay/probe/store測試搬後通過 |
| AT03 | UI／Presentation測試改App-local且public移除；共用RivetPresentation不含驗證UI；PRInbox與rootPackage原樣 |
| AT04 | OAuth source與原lifecycle相對基線無diff；root tests、consumer及適用format/lint通過 |
| AT05 | 新圖明示三者邊界並驗證；歷史evidence來源標版本，新host live與反向PKCE/canvas pending如實保留；PR Lens取原PR真base/head diff |

Tester命令（此plan不表示已執行）：

```sh
swift test
scripts/check-github-integration-consumer.sh
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
xcodebuild -project apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj -scheme GitHubSignInVerification -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/VerificationHostDerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build test
swift format lint --strict --recursive apps/GitHubSignInVerification/Sources apps/GitHubSignInVerification/Tests
swiftlint lint --strict apps/GitHubSignInVerification/Sources apps/GitHubSignInVerification/Tests
```

依實際CLI接受語法執行適用app檢查；不掃寫其他檔。可唯讀source/diff確認newtestkey與public隔離，不需要為純rename新增鏡像tests。舊276 root／13consumer／8app與live結果明示屬基線；搬後實際數量由Tester記，不預填。新host真登入若需重做，由Human自行輸入機密；不讀取或重貼舊callback/code/state/secret。

## 5. 工具、證據與停止條件

### Graphify

Pin 0.9.73；每次 CLI 連 help/version 皆設 GRAPHIFY_NO_AUTO_REFRESH=1。本輪預期 graph 位置未找到可用圖，採 targeted rg/source。以後只有現存圖才核對 revision、用真 node labels 作 budget=1500 bounded query，重要關係 source-confirm。不存在、過期、不支援或失敗就 targeted search；不 extract／build／install／semantic／provider／watcher／server／hooks／config／version stamp。

### PR Lens

Pin 0.11.0、local-only；只在實際 bounded diff 後讀 diff 與必要 context，記真 base/head IDs，dirty patch 另記邊界／hash，不能捏造 head 或為工具自行 commit。外部 topic scratch 作 graph／validate／render，保留 unchanged direct neighbors、file refs 及非trivial map 的 walkthrough。讀實際 output manifest；現有 .github/pr-lens.yml 有才只讀套用，否則 no-config；不建立 repo .pr-lens、不 install／API／uploads／comments／servers。若 schema 無法忠實描述當下 dirty diff，記限制並用直接 diff review；不代替 Reviewer。

### Archify／architecture-canvas

A03 文件圖作者文字繁中；固定 UI／HTML lang English fallback。責任邊界依 architecture-canvas 讀 scene contract、author scene-v2.js、validate/build、實看；不得用 sequence 或 PR Lens 代替。授權流程採 Archify sequence：先 matching schema＋common＋matching example，下一個工具動作寫 candidate；不預先鑽 renderer。Showcase 九 checks、零 composition errors／warnings；validate 後 freeze、deliver 收據。visual-check 四 viewport 1440x900／1600x1000／1920x1080／2048x1320，實看最小／最大 lightdark screenshots。自動 visualReview=pending 不等於已實看；非零如實記；連續兩輪不改善即停報 diagnostics。不能發布 artifact.cafe／start preview server。

Graphify／PR Lens 是導覽／理解輔助，不是新增 OAuth 業務驗收或外部服務依賴；失敗記 concrete limitation，保留 source／diff fallback與既有 review gate。必要長期圖交付未完成則文件仍 pending，不冒稱完成。工具暫存、DerivedData、機密輸入皆不入版控；evidence 只放必要脫敏結果。

出現 scope／locked contract 衝突、越界刪改、無法符合既有 bundle、真實結果推翻契約、需新系統安全設定或外部 OAuth App 變更時，停止受影響動作並回 human-check／Scope Gap，繼續不受影響的已授權工作。個人 secret／live互動待 Human，不擅取 gh credential，不以未執行宣稱通過，不越過獨立 verdict。

## A07 真人驗證狀態（2026-10-21）

以上A03 Non-Goal與AT05的pending是搬移實作當時狀態，不預填遠端通過。現已由Human在來源 `e941d88` 獨立驗證App自行輸入配置並完成授權；agent觀察真實API成功與再次查詢通過，未重新授權。這是既有A07驗收事實，不變更範圍／manifest／contract。反向PKCE、canvas互動、完整遠端refresh/401與全部Human review仍未因此通過；最新來源與歸因見step及verification-host-amendment evidence。

### P06 最新執行狀態（2026-10-21）

以上遠端pending為P01規劃時狀態；現已由Human依固定helper與判準完成missing/wrong各一次新授權/單次交換，兩個安全報告均HTTP400、unknown_error/unknown、無token，結論皆indeterminate，不宣稱PKCE enforcement通過。工具最終SHA659809be53ac21a76e5417fffd9bd082c41cf3c1fe93116d3cb1a6cc32901699（d11f343基線後dirty source），兩case間未修改。總預算2/2已用盡，停止授權與重試，無rawbody可追補；後續診斷需另訂有限契約與新預算。Canvas Human驗收passed，遠端refresh/401本輪不做、保持pending，全部PR Humanreview尚未完成。詳見pkce-negative-verification evidence與step；範圍/manifest/既定判準不變。

### Q06 實際執行摘要（判準不變）

2026-10-21，Q05獨立approved/R1closed後，Human以凍結version2 CLI另取missing/wrong各一個新code、各單次exchange。兩案皆HTTP400 invalid_grant/code_problem/generic_code_rejection、remote_rejected=true、token_present=false；description存在並提及verifier，但description_class=unknown，signals_conflict=false、pkce_rejection_proven=false。按事前§9兩者皆indeterminate；不得以hint、HTTP400或一般invalid_grant當PKCE證明。missing/wrong各1/1、Q總2/2用盡，停止新授權/重試/擴模板；P舊2/2 unknown歷史保留。來源82489b6+Q受限diff、CLI SHA `0d1d912473f44315eeadecca94b8cf6f1e31caea06e1ed821dfe8679b3f01a51`。原始描述未保存，無法可靠專指拒絕原因；完整安全JSON/來源與限制見新pkce-diagnostics-v2.md。正式OAuth/credential/provider/scope/refresh/401未改，正常login/API/canvas不重做，完整遠端refresh/401及完整PR Human review仍pending。

### T06 實際結果（既定判準不變）

2026-10-21，T05 approved且版本SHA凍結後，Human完成共享R→T唯一wrong新授權/新code/單POST，現在1/1已用盡，停止任何重試/第二次。安全version3報告：actualprepared local_consistency=consistent、valid_different、client/redirect/code/shape一致、callback返回至準備Request under_5s；HTTP400 invalid_grant、無token，verifier/challenge/mismatch hints true但description_class=unknown/match_source=none，按§11仍indeterminate/proven=false。local gate是新增本機證據，不能替代完整語義；hints不證明原因、false hints不排除其它grant問題，under_5s不是code_age。CLI/test SHA未改，來源90646c2+T受限dirtydiff，詳v3 evidence。PQR舊結果/預算/正常App/canvaspassed保留，不追原文或擴表；遠端refresh401及完整Humanreview pending。
