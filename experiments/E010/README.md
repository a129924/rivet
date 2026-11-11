# E010：DPK profile 自然到期與資料恢復可行性

## 驗證什麼

**現行停點：S06-RT07 Human review／等待原W2協作。** RT02四契約、RT03 v2具體metadata命令與RT05 metadata outcome已各自獨立approved、required_fixes=[]；這不是本次文件closure的核准。唯一metadata操作已完成、私人IO已停止；已確認集合按Human新增例外留至原D=2026-11-20T07:22:03.379959Z，不當minimum必要性或RP清理成功。W1 baseline六欄／Human0提示的限定成功保持，完整自然expiry／P1 W2／Rebuilt W3仍pending，清cache不是W2新gate、不重設S／t0／namespace／grants或三窗。

原metadata M0=2026-11-10T09:42:56Z／total hard09:57:56Z不變；私人IO及RT05結果審查已完成，文件收尾未在原15分鐘閉環，09:58:03中斷時仍未完成closure。已核實上次首guard拒寫、兩docs沒有部分更新。本次Human另准**僅文件收尾至10:20:00Z（18:20）**，不是resume原metadata窗口、補查或延時；本次窄Review仍待派遣。以下RP11及其他段落保留各自歷史，以本RT結果為現況。

**RP階段停點歷史：S06-RP11 Human recovery handoff；RP檔案縮減已受控停止，minimum未完成。** RP05 v3 code／params已獨立approved，唯一diagnose完成封存；RP07具體刪方案needs-rework／blocked，RP08未執行，dispatch／attempt／delete全0。RP09只接受blocked結果紀錄，minimumComplete=false／recoveryRequired=true；target與sidecar IO已提前停止，不resume／補查。本次RP10僅兩docs作者facts完成，待原Reviewer窄closure，不預填該核准。原W1 baseline機制／限定seed-fresh UX成功保留，完整自然expiry／P1／W2／Rebuilt／W3仍待驗證。

本run `b90f5f16-d3c8-452f-af91-86b88d6dc64e` 的actual t0=2026-11-10T07:22:03.379959Z、cutoff07:47:03.379959Z／deadline07:52:03.379959Z，D=2026-11-20T07:22:03.379959Z；原S06:52:05Z／latest09:35Z／V11/21T06:52:05Z／今日H10:20Z（18:20）不變，不延W1。P0 expiry=2026-11-17T07:28:08Z（台灣11/17 15:28:08）；W2由Human真expiry後喚醒，原D／三窗口不延。Source22仍[NG manifest](evidence/ng-date-preparation-20261110/source-manifest.json)的b8c567…；以下純準備／舊CL1／closed run與舊CLI保留各自歷史，不混用。

**CL1已完成檔案清理歷史：CL1-08 Human review。** CL1-02／04／06獨立approved、required_fixes=[]；CL1-05只有一次actual caller，3459清冊nodes完成刪除、root另rmdir，cap內一次exact-root absence確認true。cleanupComplete=true／recoveryRequired=false／retainedTargetNodes=[]。target操作已於06:40:42停止；CL1-07本次只兩docs作者facts完成待原Reviewer最後窄closure，不預填其核准。原C0／DATE10殘留與W1停止紀錄保留歷史，不是現在仍有此root；檔案清理成功不等Keychain item absence／profilecycle／DPK UX／主假設通過。

**C0失敗結果歷史：CL08 Human review／recovery handoff。** 獨立C0清理job已結束，並非resume原W1。CL05唯一approved v3入口在hardstop後首guard即拒絕：completed0／rootRemoved=false／cleanupComplete=false／recoveryRequired=true。CL06 approved、required_fixes=[]僅接受此失敗結果紀錄，不代表清理成功；CL07本次只兩docs作者事實收尾待窄closure、未預填該核准。原DATE10／舊W1及E005／E006／所有歷史保留；不再target／capture／raw／handles／服務操作，不新真人主線、排程或延長C0。

**DATE W1結果歷史：DATE10 Human recovery handoff。** DATE06本人一次同步已收到；DATE07本W1受控停止，cleanup／minimum未完成，不能resume。DATE08本次有限結果／failed-cleanup紀錄與Human追加均獨立approved、required_fixes=[]，不解除殘留blocker或代表完整主線完成。DATE09本次只同步兩docs，待原Reviewer窄closure、不預填其核准。以下DATE準備與舊GUI／PF／closed W1保留歷史，非新操作授權。

DATE原W1歷史（後有獨立CL清理job，非resume）：本run `3581e693-8019-4068-a40f-311488fab764`：t0=2026-11-10T03:36:15.334210Z（台灣11:36:15），cutoff04:01:15.334210Z／deadline04:06:15.334210Z，D=2026-11-20T03:36:15.334210Z；S=11/10T03:02:07Z／V=11/21T03:02:07Z不變。所有殘留root讀／刪／重核已於04:05:21停止，原W1 deadline已過，不resume／新window。原[22-source DATE manifest](evidence/date-preparation-20261110/source-manifest.json) aggregate `caae3528d9fbc44cd2e0eebfc19b1d3bc914b8e303efb432e39f189a8adc7824`保持，DATE01–05準備approval不改；下方未起root／待DATE06及舊日期CLI均為當時快照。

**2026-11-10 PF準備回修完成，現在停PF07 Human review。** PF02 actual Plan-Reviewer、PF04 Tester及PF05 Reviewer均approved、required_fixes=[]，只接受本次純producer回修；不解除真Xcode hook／assets／live blocker，不resume舊W1或啟新輪。僅GUIcopy generator移除兩target inline fallback，異常target／config／原值／數量fail-closed；template／Scheme／Swift與原Signing／leaf／fullgroup／profile／nonce等gates保持。下方GUI09 closed-run及遷移紀錄保留歷史，舊GUIPostHookRequired根因仍unknown。

**本次 GUI07 W1 已受控停止並 closed；目前停 GUI09 human-check，不 resume。** Human GUI06一次開始同步已收到，GUI04／GUI05 preparation approved歷史保留；GUI08本次controlled-stop／清理Final Reviewer與Human addendum Reviewer均approved、required_fixes=[]，僅接受本受限事件與證據。Human一次Debug Build成功／全程0提示／未Run，與機器缺pre/post hook、`GUIPostHookRequired`同時保留，原因unknown。0 App／0 SecItem／未seed，無P0 proof／完整global／baseline／retention／W2，完整profile cycle與DPK UX未驗證。下方各準備／遷移／待審文字均為當時快照，以本段與最新結果為準。

本 topic 的活動身分已由 DPK E008 遷為 E010；dev 的 E008 屬另一個 PKCE topic，不可查詢、resume 或清理。原PR #67離線遷移與下列環境／重現段落保留為歷史；本次GUI W1實際受控停止結果如下，沒有DPK測量。主假設仍是同 Mac/user、免費 Personal Team、同 leaf certificate／完整 group 下，P0 自然到期後以不同有效 P1 讀回原假 A；狀態 **未執行**。

原契約見 [requirements](../../analysis/github-oauth-dpk-profile-continuity-feasibility/requirements.md)、[technical-spec](../../analysis/github-oauth-dpk-profile-continuity-feasibility/technical-spec.md)、[plan](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.plan.md) 與 [step](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.step.md)。遷移 M01 已獨立 approved；M02 是作者交付；M03獨立Tester已approved、required_fixes=[]、resolved M-RF01；56方法／Swift7／兩版unsigned與回修focused結果均保留。M04獨立Reviewer已approved、required_fixes=[]；M05已依Human確認訊息正常commit819b26d。M06受控整合/本地登記草稿待M07核對、M08第二訊息確認與commit，尚未push/發布。

## 為什麼

PR #67 的原 DPK E008 與新 dev PKCE E008 路徑碰撞。Human 明確接受活動 E010、原始保全及失敗封存紀錄完整保留，topic／branch 不改。自然到期的未知與 profile-only／同 certificate 控制不變；本次遷移不回答 DPK 可行性，也不重新解讀歷史 prompt。

## 成功與失敗判準

遷移須原 193 檔逐筆 accounting，22 原檔快照保全，158 evidence＋13 frozen GUI 逐檔 SHA 不變，E010 身分一致且拒絕 E008，引用按原 blob／pointer／path／SHA 或 Markdown/HTML 原 context 解析。歧義、版本不符、缺少內容保持 unknown，不退回 PKCE 或新 active 近似 bytes。原自然週期判準仍為首次≤1、後續正常讀取零提示、六欄完整且精確清理；S06 human-check／S07 與完整 S08 pending 不變。

## 環境與前置條件

DATE純準備環境（歷史快照，非本次live結果）：兩runtime各3個GUI日期與兩既有fixtures，新source另版；legacy MAIN／其餘guards及producer fix保持。本人同步前無任何live或資產操作。以下unsigned／遷移環境是歷史，不新增本輪App Build權限。

本輪只有離線 pure fixtures／必要 unsigned Debug 與 Rebuilt 編譯權限：Swift 6.3.3、Python 3.14.0。沒有新 grants、namespace、private runroot、clock arm、Apple account/profile/certificate、App launch 或 Security/SecItem 操作。Generic App/project、bundle UUID 前綴、六欄 A、同 certificate/full-group、三窗／十日期限、no-rewrite 與既有 guards 保持。E010已在feature以no-commit/no-ff受控整合dev，兩registry新增登記草稿待M07/M08；尚未第二commit或PR更新。

## 重現步驟

本W1新測量已結束，prune準備blocked後沒有targetIO；不再補raw/sample／handles／inventory診斷或現場刪除。若需新cleanup，須另有明確受限窗口、actual retained／delete plan及獨立review，今天不自動開。正常最低材料與單fakeA留存至原D不等於整raw／cache長留已准；未完最小化交Human。後續W2僅真expiry後Human喚醒，不排程、不改舊W1；今日active18:20停。以下原run／CLI均歷史。

本run已停止且原W1期限已過。本階段僅讀永久safe evidence同步文件；不查看private root／raw／服務／檔案占用，不重測或重建控制。任何後續殘留root查看／重核／刪除均須新的Human具體授權；原整包或下列歷史CLI不能直接延續。

**以下11/5 GUI CLI順序、discover及unsigned命令只保留歷史，不是本輪啟動入口。** 本輪不能照舊GUI04/05或舊日期資料操作；只能以現行DATE契約及新context執行。

以下是**11/5 GUI原計畫的歷史命令快照**，不是DATE的授權／控制資料；其當時未執行聲明及後續受控停止結果分別保留。所有CLI從feature或其他外部工作目錄執行，不能把cwd置於待清runroot；只使用新run／新source／新三grant，原closed與原停簽副本不resume。

1. 機器先固定新t0／W1與控制；public DER／inbox／configuredproject／任何Auto均在其後。Human只私下將選定既有public certificate以 `.cer/DER` 放新inbox，不.p12、不identity/privatekey、不貼ID或截圖；`gui_build.py --live --root <本輪私有root> --freeze-public-leaf` 本機核trust/date並freeze。任何Auto前固定不了原leaf就停止。
2. `gui_build.py --live --root ... --configure` 只做本輪configured/frozen copies與owned outputs；Human開**新**project，私下選既有免費PT／Automatic。不要開舊10檔副本、不要手動Manage Certificates＋／rotate／revoke；遇明示newcert要求即停、不答應，私下本人login/MFA/TouchID/keyauth自行完成。沒有GUI能鎖某leaf的保證，post實際錯leaf就拒絕。
3. 機器 `--arm p0` 後，Human toolbar選 **DPKContinuityProbe／My Mac**，只一次⌘B（Debug），不Run／Test／Clean／Archive。有限回報成功或失敗、是否未Run；不貼Signing、Team、profile、rawlog。Agent據真回報 `--attest p0 --reported-success --did-not-run`（失敗不加success），再 `--finalize p0`；hook缺失／late／原leaf不符不補Build。`continuity.py --live --root ... --setup-only`、`--complete-global` 後，依固定 `--window 1 --stage preflight|seed|fresh` 分段執行，一次Add且無觀察UXunknown。
4. Human於safe候選所報**實際P0 expiry後**喚起同對話，非新授權／ready。原W2先 `--window 2 --stage expired` 分層診斷，再 `--arm p1`，Human同scheme原Debug只一次⌘B；attest／finalize p1通過才能 `p1-setup`、`p1-read`。W3 `--arm rebuilt`，Human改選 **DPKContinuityProbe-Rebuilt／My Mac**，其Run設定明確Rebuilt但仍只⌘B不Run；再attest／finalize rebuilt、`rebuild-setup`、`rebuilt-read`、`cleanup`。P1不更新／slot已用不retry／profile-only Build／cache補查。
5. 僅原三窗／D內條件式最多一次 `--arm recovery` cleanup-only GUI Build，同originalleaf/fullgroup，不恢復測量／新窗。曖昧seed launch/Add即可能owneditem，不因缺seed receipt跳清理。Human停Build／關本輪project後，Agent據真回報 `--record-closed --build-stopped --project-closed`；safe候選留本ownedroot，模型readability＋safety對同SHA雙ACK後才公開／精確清raw。未知owner／process／handles／期限不足留recoveryRequired，D後僅既准最低交接，不自動讀／簽／清。

`gui_build.py` hook／finalize的stdout只有本機白名單enum／bool／date／hash**候選**，不是compiler exit/full log或正式UX結論；不得cat任何privateproject／raw profile／subject／stderr來補證。全CUA（含初始化、AX與截圖）禁用。

活動 source 仍限本目錄 `Sources/`、`Resources/`、`scripts/`、`Tests/` 與 project；以下是遷移時的全套純驗證歷史命令，本輪不執行：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s experiments/E010/Tests -p 'test_*.py' -v
```

歷史 unsigned 準備入口（DATE不授權App Build）：`python3 experiments/E010/scripts/prepare.py --out <fresh-private-tmp>/unsigned --unsigned-build`；兩版固定 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`，不得 launch 產物。這不是 live 命令授權。舊 receipts／腳本／凍結 GUI runbook 只供離線閱讀，不可執行舊 E008 recipe；歷史相對連結可能不再直接有效，請用 [typed map](history/renumbering-map.json) 核對原 context。

## 是否成功

- RT metadata scope：單次完成、RT05獨立approved，只證明當時集合／歸屬metadata與唯一capture；沒有原內容fresh SHA、必要性／A再讀或DPK／RP清理成功。文件收尾超過原15分鐘，本次新授權僅續文件，完整主假設仍未完成。
- 本NG W1：P0前提、baseline資料機制及限定seed／fresh UX已獨立approved；完整expiry／P1／W2／Rebuilt／W3及feasibility仍未完成。
- 本RP retention prune：**blocked／未完成**，4595-node歷史snapshot及具體方案已封存，但RP07未核准執行、RP08未執行；dispatch／attempt／delete全0，minimumComplete=false／recoveryRequired=true，不宣稱DPK absence或完整clean。原W1早前無runner／allowlist的blocked紀錄保留為歷史。
- NG準備：NG04／NG05 approved；12 necessary pure方法與22 direct consent cases通過，只是準備證據。NG07後來已完成W1 baseline／限定seed-fresh UX；真自然profilecycle尚未完成。
- C1獨立exact-root檔案清理：**完成**，cap內root absent／retained=[]／recoveryRequired=false；CL1-06獨立approved。不是Keychain item absence或完整profilecycle／UX驗證。
- 獨立CL清理：**未完成，recoveryRequired=true**；v3逾時入口安全拒絕、刪除0，CL06只核失敗紀錄一致，不當cleanup通過。
- DATE準備：DATE04／05獨立approved歷史保持；DATE07已起W1但P0前提不足／無法判定，profilecycle主假設未執行、DPK UX未執行／無法判定。
- 本W1 filesystem cleanup／minimum：**未完成，recoveryRequired=true**；DATE08有限紀錄approved不等cleanup成功或完整feasibility通過。
- 自然 profile cycle／原 A 恢復／DPK UX：**未執行**；完整 feasibility 任務未完成。
- 兩輪歷史 controlled-stop：前提不足／無法判定，零 item 的 owned filesystem 清理完成；不是 DPK delete/read-absent。10/22 僅 cleanup 越 cutoff 3.954765 秒，仍在原 deadline 前；沒有 reset 或新測量。
- 本次 M02：遷移作者實作已交付；新 E010 離線證據見下方收據，M03原M-RF01 needs-rework歷史保留；修正後已由同Tester focused approved、required_fixes=[]，M04已受限approved；整合/登記仍待M07/M08，不沿用原E008 approval。

## 結果與證據

RT03 v1因top-level泛認定／側車wildcard needs-rework，v2只依exact歷史metadata及精確6個sidecar regular角色，獨立approved；命令／參數原bytes保留。RT04只有1次metadata操作（非19項tests）：Tio=2026-11-10T09:55:49.988154Z，end09:55:50.252745Z；primary4595=3345 files＋1250 dirs＋0 links，sidecar原6 regular＋新增capture1，總4602 retained entries。唯一新檔 `retention-exception-scope-20261110.metadata.private.json` 已在審定sidecar以O_EXCL0600寫入／自身readback驗證；既有regular body讀取0、內容SHA重算0、DPK0、delete0、新App0。這是09:55:50的scope snapshot，不推之後額外增量或minimum必要性。

[RT machine](evidence/retention-scope-20261110T094256Z/machine.safe.json) SHA `262aecf6275decea09492afd9f954d6d6cb7bde7a79becf14b73619b27fb06e8`與[index](evidence/retention-scope-20261110T094256Z/index.safe.json) SHA `0fa18586a2e695bcc8530fac05261593260f21d0f616cf1f1e8c8843cd061cd5`，RT05已對各同SHA readability／safety雙ACK；index三refs吻合。Scope metadata SHA `9d9e01df7e28599cfd2d52884bb622b6c96c070fb971c20a73b0f9fdfeea4541`只指新生成metadata，不是現行原內容SHA。RP plan仍blocked／minimumComplete=false／recoveryRequired=true／delete0，source22及原RootData未修改。

RP02 actual PlanReview approved；RP03 v1經RP04發現RF01 hash隱私投影邊界缺口，v2修正並獨立17方法通過；RP05再指出RF02 reference型別／RF03 handles期間漂移，v3獨立19方法通過／0 skip（0.102s）及code／params approved。這些pure gates不當live或cleanup成功，舊版本／收據原bytes保留。

本RP唯一diagnose C0=2026-11-10T08:53:43.881395Z、operator end08:53:46.051922Z，exit2是review-required正常停點。原diagstop09:13:43.881395Z／target hardstop09:23:43.881395Z／closure hardstop09:38:43.881395Z不延；R0 08:10:57Z／offline gates上限09:10:57Z／total09:55:57Z／H10:20Z均保留。封存snapshot為4595 nodes（3345 regular／1250 dirs／0 links），提案4368 DerivedData delete／227 retain、50 raw uncovered／32 unknown retention；14 refs為2 exact／12 path-only／0 unresolved，這不證明cache皆可刪，也不代表目前fresh清冊或占用clear。

RP07-RF01確認原plan概括DerivedData可刪，沒有排除Logs／`.xcactivitylog`／`.dia`等診斷素材。只依已封存metadata於09:01:05.569103Z補證：union去重33 nodes（23 regular／10 dirs）、Logs subtree21、`.xcactivitylog`2／`.dia`12；未讀log內容或新掃root，其他4335未命中也沒有因此獲得可重建性證明。已審caller只有diagnose／execute及fixed O_EXCL plan／完整tuple，沒有subset／revised-plan入口；不能默改plan、重製清冊或沿用approval。新增白名單／修訂入口須另有明確planning授權及審查。

[受控停止紀錄](evidence/retention-prune-validation-20261110T085343Z/controlled-stop.safe.json) SHA `e076c735c435bf49d2de5ee015abe89520e5f86c71e17edccb4f34af4eee592a`／[final index](evidence/retention-prune-validation-20261110T085343Z/final.index.safe.json) SHA `45cfaa44ff40aa579c74230838942b11429a1193c546097826b4423d4ad5cf2b`，RP09獨立approved、兩份同SHA readability／safety雙ACK、6 refs吻合，只接受blocked處置。RP08未執行、dispatch／attempt／delete全0；original root／raw／cache未由本job刪除或搬移，minimumComplete=false／recoveryRequired=true。09:06:34.028754Z是feature stop-record寫入時間，非freshcheck；精確最後inventory／sidecar讀取時間未單獨記錄、維持null，不以operator end或metadata record代填。

本RP新增sidecar之home-relative位置為 `Library/Application Support/RivetExperiments/E010-retention-prune-rp-20261110T081057Z`；已捕六份private control roles／SHA見safe stop record，當前完整entryset／extras／數量與minimum必要性unknown，不再查看。原root 4595 nodes只是last-known snapshot，沒有本job mutation，不概括全root／raw或整sidecar長留已准。單fakeA／P0最低材料原D=2026-11-20T07:22:03.379959Z不延；本job未觸A／P0、App／DPK／Apple資產，其他歷史source／圖／收據不動。下列NG10早期prune紀錄為本RP前歷史，現況以本節RP11停點為準。

本W1唯一GUI Debug成功／本人未Run，同次pre/post、actualP0同原leaf／完整group及proof通過。seed操作區間07:37:45.795661–07:37:47.283955Z，fresh操作區間07:41:37.781934–07:41:38.681681Z；同binary SHA `b6f952bf46d980b784f72aa143b380adabf0ff23f8687cacf16e47a109fd5962`，兩次六欄true／OSStatus0，fresh noRewrite。Human兩段各全程0提示、各綁machine SHA，setup／signing段亦0；原canonical receipt的prompt=null／UX unknown與精度不覆寫，Human sidecars另存，不能把工具操作區間當精確Human回覆時間。W1 baseline機制與限定UX已獨立approved；不推完整profilecycle／UX或newcert數量成立。

[baseline index](evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/index.json)／[seed index](evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/seed-review-candidate/index.json)／[close index](evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/close-addendum.index.json)均已獨立approved及同SHA雙ACK。normal retained-1已實寫，但minimumRawPruningCompleted=false；07:44:03是最後實際fresh handles clear，不能稱現在仍clear。其後[prune blocked receipt](evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/retention-prune-preparation.safe.json) SHA `efcd9a52ebe77d98699902c7b4bacdc7026e13331920902b338157cb80348394`僅source唯讀準備、no targetIO，deleteAllowlist=[]／無runner／無actual prune／無deletion，cache／raw實際數量unknown。Source實際proof產品是 `gui/p0/Products`，不是建議字面 `gui-products/p0`；未把建議cache路徑當實際inventory，也未用finalize-only或全root刪除破壞A／P0host／futureP1配置。

Outcome record Reviewer approved、required_fixes=[]，對blocked receipt readabilityACK／safetyACK均true，只接受紀錄／blocked處置，最小化仍未完成。單fakeA＋最低材料原資格留至D=11/20T07:22:03.379959Z；這不概括全raw／cache長留，不默認延時、最低材料全已縮妥或新cert數量。當前Human recovery handoff；任何新cleanup須新明確受限窗口／實際方案／獨立review，不能今天自開補掃。W2／W3仍依Human真expiry後喚醒與原D／三窗／有效grant，今日H18:20停active。

以下NG純準備與舊run／CL清理結果各自保留，不覆其原canonical或推翻歷史。

NG04獨立12 unique方法pass／0skip；22 Python／Swift direct consent cases一致（4accept／18reject），指定三檔pure helper、matching macosx26.5 SDKROOT與原window-chain／legacy guards保持。[新manifest](evidence/ng-date-preparation-20261110/source-manifest.json) SHA `20986bd64a542370334b270a671aef6ccd5276ce8338b8e2c287d75c42202608`，作者收據與[Tester收據](evidence/ng-date-preparation-20261110/tester-preparation-check.json)另版保存；不借此認定真GUIhook／signedhost／P0P1／DPK／UX成功。

NG05對同Tester候選SHA `03be37ff6e6026b256f5ef21546b575d17b1c3b38e31c7c9a626d8002b06184b`之readability／safety ACK均true後，Tester核12檔fresh owner／manifest／hash／dev-inode／nosymlink／lsof clear，於07:16:08.148144–07:16:08.486196Z精確刪完自身audit root、lstat absent／residual0。[新cleanup append](evidence/ng-date-preparation-20261110/tester-diagnostic-cleanup.json) SHA `174141331cc6b6a371dd89d51e7809c382efac4bd5b4946ecd81aa56ffb01d70`不覆原manifest／作者／Tester收據；作者audit未動，不稱全tmp清空。以下CL1／C0／DATE結果保留各自歷史。

C1=2026-11-10T06:17:27Z、diagstop06:37:27Z／Cend06:47:27Z，不延。CL1-03先固定完整caller／params／兩sealed locators與SHA，CL1-04實際審查及雙ACK通過；原v3 derivative只改一行C1期限，舊private plan僅歷史data不執行其C0 inline。一次actual caller於06:39:11.888016–06:39:13.219342Z，4項fresh prechecks全true；完成3459清冊nodes（2352 regular／1107 dirs／0 links），root另rmdir、不含在3459。CL1-06已逐項核completed hashes及順序等於已審清冊。06:40:42.645712–06:40:42.646408Z一次FD-relative／nofollow exact-root後置核對absent=true，早於Cend；之後不再target／capture／handles／服務操作。

前2次automatic approval review均CreateProcess before-dispatch：先因疑Implementer自寫approval，後獨立Reviewer親寫批准檔仍因代理來源不trusted而拒，actual caller均0。原role/tool證據及批准SHA `555f0fcee1007e04ca7b14ce1f42c6b2ba40a4bf824005c4d1955db653f501fd`保留。Human新直接接受CL1-04及exact target原C1內不可逆刪除、fresh全guards／不延時／不觸其他根，機器06:38:08Z收到後，同action審核才允06:39:11.781428Z實際dispatch。沒有改endpoint／間接bypass／code／params／approval，也不是3次實際執行或actual重試。

[執行結果](evidence/cleanup-c1-20261110T061727Z/execution-result-c1.safe.json) SHA `2335fd9cf39d38df57b7aac75d231ba397d57c60c18afd227940f3e99ac35d7e`、[absence後置證據](evidence/cleanup-c1-20261110T061727Z/execution-postcondition-c1.safe.json) SHA `7e66f67e4c3623929db4f4e2bc4345979b2a7918d09cc993275d1823d704635b`保留actualdeleted／retained與proof；cleanupComplete=true／recoveryRequired=false／retainedTargetNodes=[]，原9份C0 capture與sealed private snapshots隨root移除，無新C1 capture，fresh 0 links未follow任何symlink target。原C0 failed／DATE17／圖／maps等永久bytes及source22／DATE準備保持；其他RivetExperiments roots／原10檔prep／Apple資產／KeychainDPK／user security／Git未動，不聲明全機cleanup。主線仍未執行；Human review後若另安排真人，須新主輪planning／時間授權，不復用舊W1、不自改source或開App。

以下C0／DATE／PF／舊GUI是各自歷史結果，不覆原失敗收據。

獨立CL的C0=2026-11-10T05:33:07Z、diagstop05:53:07Z／hardstop06:03:07Z，不延。CL02 actual Plan-Review approved；CL03於05:50:46.523901Z seal之最後fresh snapshot為3459 nodes（2352 regular／1107 dirs／0 links），9份新增capture已納清冊，當時handles clear／ownership／parents與root binding通過。這與原W1的232／94／3／102是不同時間快照，不能推現在仍clear。初次永久safe發布以O_WRONLY fd做readback產生errno9，曾誤分類capture fail；後只讀已落safe更正，原紀錄保留。CL04 v2因path scan race／首clock guard太晚needs-rework；v3修訂後獨立approved且inventory／plan同SHA readability／safety雙ACK，v1／v2不可執行。

[CL05唯一v3結果](evidence/cleanup-20261110T053307Z/execution-result-v3.safe.json)為06:03:35.265949–06:03:35.276842Z，入口比hardstop晚28.265949秒，`caller-before-private-load`首guard正常拒絕，completedNodeSHA256=[]／completed0。沒有privateLoad／目標open／scan／lsof／delete／absence query、沒有重試；不是服務仍占用、ownership不符或DPK failed之新證據。rootRemoved=false／cleanupComplete=false／recoveryRequired=true，安全拒絕不等任務清理success；[approved v3 ACK](evidence/cleanup-20261110T053307Z/execution-approval-v3.safe.json)及所有永久舊版本保留，CL06僅失敗結果紀錄approved。

本次刪除清單為空；依最後snapshot整root／3459 nodes（含9新增capture）均未由本次刪除，現在未重核、minimum未完成，不概括授權whole raw長留。殘留home-relative位置仍為 `Library/Application Support/RivetExperiments/rivet-E010-3581e693-8019-4068-a40f-311488fab764`。後續任何root查看／重核／刪除須新Human具體授權；可行下一步僅另新有界窗口先fresh核，再用經審方案及明確sealed execution locators（原handoff缺漏已由既存寫入記錄補齊，不猜名）。Human「處理完可真人」條件尚未滿足，不能啟新主線。Source22/dateprep／immutable17／歷史圖及Apple資產／KeychainDPK未動，不稱全機零殘留。

以下DATE／PF／舊GUI結果保留各自歷史，不是CL後目前target狀態核對。

本W1原DER在Auto前freeze、same／trust／date合格，p0 slot已armed；Human最初未分類failure／hard-stop→Run unknown且setup-stop全程0→後續澄清only⌘B→依要求stop後回報BuildCanceled／Indexing→closed／NoRun→無其他需留project並正常退出Xcode。未有成功Build attestation或valid P0 proof／global／seed／baseline／retention。pre/post未見不證actions未執行；不推原BuildFailed／newcert已確認、Human沒Build或操作錯。`noExperimentAddByFrozenHarness`僅由凍結source及absent durable marker支持；actual App／SecItem totals仍null，不能寫全機0。主假設未執行；P0機制與DPK UX沒有可判成功的證據。

最後有限freeze為04:05:20.923160–04:05:21.539309Z（台灣12:05:21），原deadline前已停止全部root操作，當時仍fresh handles=false／102 Swift-compiler-service rows、main-Xcode row=false；rootAbsent=false／cleanupComplete=false／recoveryRequired=true。當時owned tree為232 regular files／94 dirs／3 symlinks、foreignOwner0／other0；owner／dev／inode binding吻合，treeNoSymlink亦未滿足。未展開links／kill共享服務／放寬guard／刪root子檔，整root留存且minimum recovery set尚未建立。殘留位置相對home：`Library/Application Support/RivetExperiments/rivet-E010-3581e693-8019-4068-a40f-311488fab764`。這是04:05:21紀錄而非目前重查；後續任何查看／重核／刪除都須新的Human具體授權。D後minimum故障例外不概括授權整root／全部raw長留。

summary-v2／pre-cleanup index同SHA readability／safety雙ACK後先保存safe再嘗試cleanup，未套到期例外。[本run final state](evidence/date-validation/3581e693-8019-4068-a40f-311488fab764/date07-final-cleanup-state.machine.json)與[final index](evidence/date-validation/3581e693-8019-4068-a40f-311488fab764/final-cleanup-state.index.json)、[Human append](evidence/date-validation/3581e693-8019-4068-a40f-311488fab764/human-observation-addendum.index.json)共17永久檔（原15＋追加2）保留。Human約台灣11:57–12:05:21全程0提示僅退出Xcode／cleanup stage觀察，不證DPK UX或清理成功；04:07:59是reporting時間，Human exact時間null／span近似，原machine unknown不覆寫。Apple資產留Human管理，數量及外部metadata unknown，不稱全機零殘留。DATE08兩次獨立approval只支持本次有限report／failed-cleanup紀錄，沒有解除blocker。

以下DATE準備／PF／舊GUI段落是各自歷史；當時清理成功或未啟動不套到本次殘留。

DATE04獨立驗證最終12 unique methods pass：首輪9 pass／3 compiler SDK setup errors，只修runner SDKROOT後重跑該3方法均pass，未改source、不當sourcefailed；首次env hash unknown，不補造唯一根因。22個Python／Swift直接consent cases一致（4 accept／18 reject），window-chain與legacy MAIN保留。collector首列漏數21→只重解析原log修正22、另存修正，不重編譯。[作者準備收據](evidence/date-preparation-20261110/preparation-check.json)與[Tester安全收據](evidence/date-preparation-20261110/tester-preparation-check.json)各保留原bytes；helper僅ProbeCore.swift＋LiveGate.swift＋WindowChainProbe.swift，無App／Security／SecItem／Developer資產／GUI。

DATE05對同一Tester候選SHA之readability／safety雙ACK後，Tester於03:30:40.421358–03:30:40.869671Z正常精確清理自己18檔audit root，root absent／residual0，lsof僅exact root空輸出；未用到期例外，[新cleanup append](evidence/date-preparation-20261110/tester-diagnostic-cleanup.json)不覆舊收據。該raw已gone不可重解析；作者DATE03 safe audit與其他tmp未動，不稱全tmp清空。以下PF／GUI結果是各自歷史，不移掛DATE approval。

PF04獨立親跑9必要pure方法通過／0 skip（1.574s），其中11個negative subcases均拒絕，並非另11方法；只允plutil純解析，無compiler／Build／GUI／資產／DPK。[新22-source manifest](evidence/producer-preparation-20261110/source-manifest.json)、[作者收據](evidence/producer-preparation-20261110/preparation-check.json)及[Tester收據](evidence/producer-preparation-20261110/tester-preparation-check.json)另版本保存；aggregate `e7fdeb2a5daabc5953041c51f03539916f7c70a8eb34e704e0b5b1a8079c7757`。原22-source完整snapshot／map保留，其餘466原保護檔未變。Tester實際核9個owned0700／nosymlink fixture roots於cleanup後lstat absent；無lsof／全域nohandles宣稱。安全audit外部保留，不代表cleanup failed或全tmp清空。PF05 approved僅prep，真GUIhook／P0P1／profilecycle／DPK UX仍未驗證。

本run `2237b731-7367-4030-853c-e37b73ab0bba` 的t0為2026-11-05T09:04:18.788005Z，cutoff09:29:18.788005Z／deadline09:34:18.788005Z，D=2026-11-15T09:04:18.788005Z，均未重設。原public DER已在Auto前freeze且trust／date合格，但不等於P0 host成立。Human回報一次Debug Build成功、全程0提示、未Run；machine attest 09:23:11.102081–09:23:11.246149Z exit2 `GUIPostHookRequired`，pre/post hook均未見、原因unknown，不能推Human沒Build或DPK failed。

正常同SHA readability／safety雙ACK後，先保存安全證據再刪raw；cleanup於09:27:47.157786–09:27:49.114446Z（台灣17:27:47–49），在原cutoff與deadline前完成。本owned private root absent／owned residual 0，expiry exception=false；沒有item，故不是DPK delete／read-absent驗證。Human關閉／cleanup約台灣17:24–17:27:49全程0提示僅屬此stage觀察，精確Human時間仍null，原machine pending/null不覆寫；不代表DPK存取UX。Apple資產留Human管理，原closed10檔prep／其他projects未動，外部metadata unknown，不能稱全機零殘留；raw已gone不可補造。

[本輪安全證據](evidence/gui-validation/2237b731-7367-4030-853c-e37b73ab0bba/final-addendum.index.json)共17檔，由8／10／6 refs的分層indexes及[Human addendum](evidence/gui-validation/2237b731-7367-4030-853c-e37b73ab0bba/human-observation-addendum.index.json)追溯，不能稱17檔均由單一index涵蓋。cleanup.machine SHA `1c655660e8a73a2e4a83435008cec449556795c83f10c6a69d208c2644e5eab4`；final index SHA `93fcf3730925696b6d208de0836acc8f279b507b29386e41a9491445f76d0282`。Final Reviewer與Human append Reviewer均approved、required_fixes=[]，只支持本次controlled-stop／清理／紀錄一致；原三窗與完整S07／S08未完成。

以下GUI04／05及遷移段落保留為先前準備快照；當時pending不代表本次最新狀態。

GUI04最新focused Tester approved；GUI05原Reviewer正式 approved、required_fixes=[]，GUI-RF01／02／03全resolved，對應[新22-source manifest](evidence/gui-preparation-entry-fix-20261105/source-manifest.json)／[child-entry mock收據](evidence/gui-preparation-entry-fix-20261105/preparation-check.json)。真Python child穿actual `__main__`／accepted_asset／GUIwindow只驗synthetic接線，不是真Xcode／signedhost／DPK。GUI06 human-check的一次本人開始同步仍pending；S=2026-11-05T07:14:10Z，原純prep硬截止09:14:10Z不延，最晚t0為2026-11-06T07:14:10Z。

GUI05曾needs-rework的RF01/02已由作者限縮回修，尚待獨立focused驗證／複審，GUI06仍不可開始：[新22-source manifest](evidence/gui-preparation-review-fixes-20261105/source-manifest.json)／[3項mock回修收據](evidence/gui-preparation-review-fixes-20261105/preparation-check.json)。原GUI03 13＋37與GUI04 approved只屬原revision，原bytes另完整保全；本次不重跑或冒用其approval。CLI error只固定safe enum，合法scope內raw私存；timeout partial bytes原樣、text明示encoding／非原bytes，沒有真Signing／tooltimeout／DPK。

本輪GUI準備：[19-source原bytes快照](history/pre-gui-20261105T072258Z-d9618c4e/snapshot-map.json)、[22-source manifest](evidence/gui-preparation-20261105/source-manifest.json)、[作者準備收據](evidence/gui-preparation-20261105/preparation-check.json)。13 GUI pure／mock、37受影響相容、plist/XML/AST與純Swift chain／LiveStore parse通過；不代表真Xcode解析、GUI hook實測、signedhost、P1或DPK完成。authorverdict=null，待獨立GUI04/05。

[來源清冊](history/pr67-422d0c7/original-files.json) 以真實 origin commit `422d0c7dd07bf9a746a142d6a07a5cad60c947ed`／Git path／blob OID／SHA 記原 193 檔。[22 原檔 tree](history/pr67-422d0c7/tree/experiments/E008/README.md) 保留原 README、17 active 與四份 planning 文件；22 個檔案與 22 個可取得 source path/SHA 組合是不同統計。

M03 focused收據SHA `20ed1c8145c223cb26bd99aba65aa13243d3e870ef57bff8b497a66ac5594ad3` 明示approved、required_fixes=[]。只核已交付遷移：M-T05為批准base PKCE原blob保護，M-T06為首次占號既存記錄一致，沒有新的全球唯一/登記聲明。map／active manifest／準備收據保留受驗M-RF01快照；map內active-edited文件destinationSHA是當時版本，本文與step僅追加其後角色狀態，不能冒稱相同bytes。M04已獨立approved；M05正常commit819b26d、六hooks全Passed。M06 merge無衝突、兩registry新增E010待M07/M08；不預填第二commit/push/PR衝突readback。

M-RF01只將三筆 `priorEvidenceManifestSHA256` 聚合指紋分列為 `non-file-digest`，不做file lookup、不列缺失檔案。檔案引用為1952筆（JSON1873／Markdown72／HTML7）：1726 resolved、185 unresolved、25歷史文件版本SHA mismatch、5個缺失source版本涉及16筆；另外三筆聚合摘要獨立記錄。原三筆均保留實際pointer／原值，沒有修改其receipt。

[renumbering-map.json](history/renumbering-map.json) 分開 JSON pointer 與 Markdown/HTML link context，不改舊 receipt、HTML、ID、時間或 index。27 種歷史 source 組合有 22 種可從 frozen original／prior-source bytes 解析，另外 5 種明列 `content-unavailable-in-published-snapshot`，不補造原 Git blob。另有舊文件版本 SHA 不符、無版本 path-only、已清理 private／外部產物等 unknown；每筆保留 expected SHA、context、候選版本與原因，unknown 不當 resolved。

[新 active manifest](evidence/renumbering-active-source-manifest.json) 與 [新離線準備收據](evidence/renumbering-preparation-check.json) 僅核本次 E010 source。定稿前 54 個 core／identity pure methods 已通過、0 skip；最終含 map 檢查結果記在新收據。兩版 unsigned 編譯成功、main SHA 不同、無 debug dylib；不是簽章、DR、profile 或真人重建證據。

兩個原 run 的 [10/21 final index](evidence/run-20261021T035701Z-8e279f70/final-addendum.index.json)／[10/22 final index](evidence/run-20261022T054623Z-dfc25e14/final-addendum.index.json)、全部 14 indexes 及 Human/machine 原 bytes 均保留。原 Human Build success／零 setup 提示與 matching Report/product provenance 缺口同時保留，不推 Human 沒 Build、全機無 App、DPK 失敗或需付費。[凍結 GUI 計畫](diagnostics/xcode-gui-inspection/README.md) 及圖／QA 維持原 bytes，只是未執行的歷史離線計畫；GUI T01–03 未執行。

## 結論與限制

最新停S06-RT07 Human review／等待原W2協作。Human已明准09:55:50所記over-min集合至原D，不稱minimum或RP成功；並接受條件式正式結案discard之不可恢復診斷損失與sidecar scope。只有原W3／D內A exact delete/read-absent、必要Machine/Human成果同SHA readability＋safety雙ACK安全封存、fresh完整FS範圍／owner／handles／nofollow與原guards全過，才可結案清理，現在未執行。Sidecar沒有現成finalizer；若需新工具／window或guard不滿，停Human，不擴pruner，兩root清理分判。D後不自主操作，over-min不吞minimum資格或默續期。原W2須P0真expiry=2026-11-17T07:28:08Z（台灣11/17 15:28:08）後由Human喚醒，仍須source／root／receipt／有效grants／noAbort及原preflight；P1／W3同leaf／fullgroup／profile／DR／hash／六欄／提示／cleanup判準不變。不加cache gate、不重問整包或自排程，不核准正式adapter。本次兩docs作者facts待獨立窄Review。

以下是遷移／兩輪closed run當時快照，不代表本NG W1已保存A之現況：本題當時停 S06 human-check；兩輪 closed grants/root 不可重用，當時沒有原 A item 或跨週 retention。新 live／GUI／資產／recovery 與逐段 ready 必須另由 Human 決策，不能因改號放行。M03/M04已獨立受限approved；M05經Human訊息確認正常commit `819b26d20272cfcc9e664c4dccba867bcd34c92d`。其後dev `758aca9bb518f2a21f20f47609335fac49043370` 已用 `--no-commit --no-ff` 整合至feature、兩registry只增E010，仍待M07獨立核對與M08第二筆具體訊息Human確認，merge保持pending；尚未第二commit/push或更新PR #67。E005 legacy UX、E006 的受限成功及既有 controlled-stop／逾時歷史不改。正式 Keychain adapter、真 token/OAuth、產品登入、certificate rotation、公開分發與 merge/adoption 均不在本次範圍。

## PR67 review fixes：active-only 準備（2026-11-11）

本輪只修兩個已審 finding：GUI recovery 改讀 finalize 實際產生的 `selection/recovery.json`，仍經原 `accepted_asset`／grant／process-exit／asset／copy 後 hash guards；non-GUI 保留 attempt selection 路徑。純 Swift `WindowChainProbe` 的 count／timestamp guard 移至任何 argv index、root／global 讀取之前，無效參數維持 `rejected`／exit2。

Test-first 已重現 GUI 缺少錯誤 attempt selection／誘餌錯誤複製，以及 Swift noargs trap（原 return -5）。新增5項 focused pure tests 全通過；兩個受影響類別共36 tests、0 skip／0 failure，15.699秒，僅三份指定 Swift guard source 於 owned scratch 編譯。初次誘餌 fixture 的廣域 Popen mock 擋到純 plutil，已收窄並重新確認真正 red，未當成 review bug。新來源與作者驗證見[manifest](evidence/pr67-review-fixes-20261111/source-manifest.json)／[準備收據](evidence/pr67-review-fixes-20261111/preparation-check.json)；2026-11-11 的獨立 Tester 已親跑36 tests、0 failure／error／skip，16.600秒，approved／required_fixes=[]；[Tester 收據](evidence/pr67-review-fixes-20261111/tester-validation.json)保留原 bytes。此 Tester 結果記帳時，Code Reviewer 尚待審查，不預填通過。

這是新的 active source version，baseline 為 `1f11f861aebd463db37625d8e62c92361b361cc9`；原 NG manifest／source22 `b8c567…`、W1、history／safe evidence／圖及外部 handoff archive 不改。既有 live global 綁舊 source，configured／scheme 使用該輪 frozen-source；本修正未同步至私有副本，不沿用舊 grant 或繞 sourceChanged。Frozen recovery 可能仍含原 bug，是否觸發未知；若未來要 live 套用，需另有 bounded migration／grant 審查。W1/frozen 不升級，W2/W3／原 A／namespace／D 不重設，無新 live／App／DPK 或清理操作。
