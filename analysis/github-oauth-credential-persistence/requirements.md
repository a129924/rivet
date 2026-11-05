# GitHub OAuth 正式憑證儲存：需求

- Topic：`github-oauth-credential-persistence`
- 狀態：LG81-Cap-R completed／approved（限定假完整bundle／指定環境DPK）；本輪僅收尾文件與交付提案。Cleanup、Human視覺／S08與PR整合仍未完成，舊unknown歷史保留。
- 配對：[技術契約](technical-spec.md)、[執行計畫](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.plan.md)、[帳本](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.step.md)。

## 意圖與明確 scope override

使用者已明確指出既有 `feat/github-persistent-connection` 與 E007 是他人的整套驗證工作，本 topic 必須獨立；這項指示取代先前將儲存 slice 接到該 Mission 的假設。不修改其 worktree、artifacts、實驗、帳本或 gates；本 topic 的實作、驗證與 Draft PR 不依賴 E007、S04c／S04e 或任何 renewal live 結果。

交付 non-BC GitHubIntegration 的正式 DPK adapter：完整 configuration／credential 保存、inspect、clientID-bound store、完整六欄 strict codec、有限錯誤，以及受控 provider restore／rotation 整合。保留既有 bundle、ports、provider、clients 與 generic HTTP 契約。

## 原交付 In Scope／Out of Scope（2026-10-20 歷史；新增 live 依末節）

納入 DPK Security adapter、兩個 items、public configuration／stores surfaces、同步 fake Security seam、同一 facade 內 actor 序列化、完整替換／失敗分類、fake-only tests、public consumer checks、長期文件與一張儲存 sequence 圖。

不包含登入／callback／UI、signed host、新 certificate／profile／安全設定、E007 或任何 live DPK 操作、真跨程序／重建／系統提示驗證、遠端 OAuth、provider／ports／clients／Package.swift 改寫、完整 logout／revoke、多帳號／跨程序協調、遷移、公開分發或新 BC。

## 驗收

| ID | 結果 |
|---|---|
| AC01 | Configuration 與 credential envelope 都完整往返；六欄無遺失，允許過期日期、空 scope |
| AC02 | 完整有效 envelope 的 clientID 與 bound ID 相符才交付 bundle；bound save不覆寫不同ID或不可讀舊資料，損毀資料不能提供可信ID |
| AC03 | 只接受 schemaVersion=1、非空 tokens、bearer、有限日期及必要正確欄位；不公開 Codable |
| AC04 | Absent、denied、unavailable、corrupt、identityMismatch、invalidConfiguration 可區分，錯誤不含 payload／raw status |
| AC05 | 整筆 update；missing 才 add、duplicate 僅一次完整 update；失敗不 delete／補寫舊值或混合欄位 |
| AC06 | Fake seam 證明所有 query flags／add protection、shared actor、完整替換及錯誤行為；不呼叫 live Security |
| AC07 | Provider 以正式 adapter 加 fake backend 完成 restore、受控到期 rotation；保存失敗後沿用既有停止契約，無額外 refresh／save |
| AC08 | Public consumer 可跨 target 使用新增 surfaces；既有契約與 regression checks 維持 |
| AC09 | 文件與一張 sequence 經必要工具驗證，明列未執行 live／signing／prompts 的限制，無秘密入證據 |
| AC10 | 獨立 Tester／Reviewer 後，依既有授權完成 topic commit、push、Draft PR，停 Human review |

## 授權與證據界線

使用者已授權在本 topic feature worktree 實作，無重大問題時 topic commit → push → Draft PR → Human review；不重複索取一般確認。仍須 staged diff 語意／message 檢查、獨立審查及實際證據，不包含 merge。

DPK 是本 topic 的實作方向；fake tests 只證明本地 adapter 邏輯，不能證明真 DPK、簽章／entitlement、跨程序 durability 或系統提示。這些限制留在文件／Draft PR／Human review，不形成依賴別人實驗的 code gate。2026-10-21 使用者已另授權 bounded live，依末節新增契約執行，不追溯改寫假測試結果。

## 2026-10-21 Human scope amendment：獨立真人驗證

使用者今日明確授權本 topic 新增真人 live 驗證；這取代先前「signed host／live DPK 不在本 topic」的永久排除，舊 AC01–AC10、fake-only 結果與 PR #60 歷史原樣保留。未執行不等於成功，S08 Human review 並未因新增需求而自動接受。這仍是同一 topic，不依賴、讀寫或借用他人的 E007／整套登入工作。

新增最小 validation App 與 guarded runner，連結本 repository 的公用 GitHubIntegration adapter；只驗 credential item／假 bundle。範圍是準備／純控制與 unsigned build 先經獨立驗證審查，再逐段 Human fresh ready 下 setup、保存 A、fresh reader A、整筆替換 B、fresh reader B、真正重建、rebuilt reader B、精確清理。不是登入 App，不增加產品 delete／logout API，不改 production store、ports、Package.swift 或既有假測試結果。

| ID | 新增 live 驗收（原 AC 不重標） |
|---|---|
| LC01 | 同一輪 UUID service 初始不存在；production public adapter 保存並逐欄讀回固定假 A，首次保存／存取提示 ≤1 |
| LC02 | writer 已終止；新的 process UUID／PID reader A 逐欄讀回，提示 0 |
| LC03 | 以完整 B 替換；確認全部六欄等於預期 B，記實際提示數而不另設未授權門檻；fresh reader B 提示 0 |
| LC04 | 真 xcodebuild 重建且 marker 已改、binary hash 不同；同 App ID／private group／certificate／有效 profile／DR／固定位置，新程序完整還原 B 且提示 0 |
| LC05 | 每段前 fresh ready，後段記實際提示數／有限 actions／完整觀察並綁 machine SHA；setup／rebuild 授權提示與 runtime 分段。未答或觀察不足為 unknown，不推定 0、不前進依賴段 |
| LC06 | 僅刪本 run 已有 absence＋write-attempt ownership proof 的精確 credential item；刪後 public adapter load 為 nil；私有 owned root 精確清理且必要脫敏 evidence 保留 |
| LC07 | production adapter source hashes、實際 build／簽章／profile 證據與不同 binary／fresh process 證據俱全；單靠 signature exit0、hash不同或 ad-hoc 不算通過 |

Setup 只使用 Human 指定既有 identity／profile；不 inventory 其他 App／帳號資產，不用 allowProvisioningUpdates。需新 certificate、信任／安全設定或付費即停。無新 profile／renewal 要求，也沒有 E007 的 45 分鐘窗口。先只準備工具；每段 ready 與提示觀察必須當次取得，初輪授權不代填所有階段。


## 2026-10-21 setup retry 候選準備 amendment

本節只授權將必要工具補修做到可審查，再交 Human 決定是否執行；不要求 Human 先核准純準備，也不把準備授權當 Automatic execution 採用。沿同 run `8ad8fb3b-51d9-4162-98fb-067521a37b4e`、immutable run／identity／private PBX，不建新 Mission、namespace 或實驗。

原正式 setup 是 `unknown/build`，原 public machine SHA256=`899ed35b0279c730e6c39bb1c4bc927612f7e6c81897b2d3062ff13a5db46d19`。Human 已明確全程觀察、0次提示，Tester 已綁原 SHA 保存；manual 與 formal 兩份觀察歷史均保留。0次不等於 build 成功，原已消耗 ready 不可重用。

唯一候選：沿已凍結的 App-target Automatic 設定，移除 runner 全域六項簽章／身份 overrides，禁止 portal provisioning 更新／device registration／authentication keys，僅嘗試既有 cached assets。缺失即 error stop，不新建或更新 cert／profile，不改 trust／security、不付費。Human 已採用本 run 現有 profile；這不等於已採用 Automatic 政策。Apple 文件支持不授予 portal 更新權限，未提供所有本機 cache／Apple assets 絕對零變更保證，此界線須於執行前明示並由 Human 決定；尚不宣稱 cached Automatic build 可行。

僅允許同 run 的一次獨立 `retry-1`：新政策採用 proof＋全新 setup ready，immutable attempt 綁原失敗／原 Human SHA、manifest／identity／PBX／baseline DR及獨立接受的 runner SHA；所有 guards 和實際 Human 觀察成功才解鎖 save-a。原 machine／Human bytes永不覆寫；retry directory或attempt任一存在即耗用唯一額度並選retry狀態，directory-only／partial／缺receipt均為retry unknown、effectiveSetupAttempt=null，不fallback initial、不解鎖save-a且禁止第三次，保留目錄及恢復proof。完整流程／精確 leaves 依 technical-spec §5.1 與 plan §5.1。純準備先 L01 獨立規劃審查→Implementer→Tester→Reviewer，之後才問當段 execution adoption／ready；不執行新 retry 或 live。


## 2026-10-21 Human 採用：最小可診斷工具補修（準備限定）

Human已明確「確認」採用最小工具補修方向；只授權同topic候選準備／non-live驗證，不授權新run、第三次setup、再次保存A、實際signedbuild／launch／DPK或安全設定變更。最新受限契約為spec／plan§5.2，舊結果與§5.1歷史不覆寫。

原run `8ad8fb3b-51d9-4162-98fb-067521a37b4e` 的保存A仍unknown/guard；machine SHA=`2d1ac7df2f6265abaecf797ece11f3ce159eb103682d76be254db3cadd583c60`，Human whole0已綁原SHA，Human收據SHA=`011039badb381ee2f188a403e0068e84d31f3299db17bd7326cb6f13079968fc`。無App／absence／write-attempt收據、open-W返回0或目前無PID均不證明未寫入。Debugger路徑因本機Developer mode disabled且open無公開wait-for-debugger flag停止，不改權限繞過。

只修改既有validation host／runner／tests／README：可信bootstrap後，早期args/request/identity/Bundle/entitlement失敗也能寫獨立finite診斷收據；diagnostic-only零store／SecItem。原namespace exact唯讀確認是另個未來Human段落，只load、不save/delete；nil只證目前空，存在／拒絕／error即停。沒有ownership不清理，不建立通用recovery框架。原run全部檔案、current binary及收據唯讀保留；新host使用獨立freeze／來源證據，不能冒稱舊Writer重現或已修復。具體build/sign、診斷launch、namespace read各段皆須未來freshready與事後實際提示觀察；無安全恢復方案就停。


## 2026-10-22：啟動紀錄缺口 amendment（準備授權；DPK暫停）

Human明確接續PR60「先處理啟動紀錄缺口，DPK暫停」。授權唯讀定位、必要launcher補修、non-live測試與獨立審查；不是App launch／sign/build／DPK／清理授權。不新增Mission，沿本topic／branch／PR，E007／dev／他人工作線維持隔離。

D05新host build/sign success、Human全程0次與既有Keychain受限成功歷史保持原證據範圍。D06仍unknown／Human全程0次，原consumed marker、兩空logs、缺Appreceipt事實及原保存A unknown全部保留；不從缺PID／marker推歷史無寫或放行清理。

本輪只準備runner、Python tests、README三個既有leaves。補native spawn／return／signal／exception／timeout及receipt檢查的有限持久紀錄、寫入失敗fallback與exact Human SHA綁定。凍結host沒有attempt nonce／requestSHA／processUUID的診斷收據，因此新receipt即使格式有效，也不能排除D06遲到；本輪交付launcher可觀察性，hostConfirmed維持false／整體unknown，不承諾確認host執行。

未來若另獲單次純launch授權，沿同diagnostic root明確一次diagnostic-launch-amendment-1，不建立新namespace或改舊manifest/source snapshots。改用固定無效argv sentinel，避免diagnostic環境未送達時落入legacy save-a；兩條既有Swift分支皆在args guard停止。確切schema／private leaves／測試／停點依spec／plan§5.3；本輪不建立任何真人inputs、attempt／ready或執行App。準備先獨立Plan-Reviewer→Implementer→Tester→Reviewer，之後才問具體純launch段落freshready。


## 2026-10-22：LG14 正向名稱預篩候選（僅工具準備）

沿Human standing「必要工具補修、非真人測試與審查」及Reviewer授權更正，允許先規劃／non-live驗證proc_name正向預篩；不是另建Mission或實際launch ready。只有可信成功名稱可確定排除已知host/open時，才不讀該PID的path；名稱未知即停，可能目標／截斷／別名歧義仍完整path及selected-open argv查核。不得直接略過任何ESRCH/ENOENT。詳spec／plan §5.3 LG14補充。

LG13 stdout SHA `c1eac0c28c5b3dcc31cf7218d0ff1263a41dd32f31214611ca09a701e8863c9e`、Human全程0、snapshot-path/zero/notFound/noD/noSpawn保持，不推斷無關PID／race／精確errno；D05/D06、原保存A unknown與Keychain受限成功均不改。候選只三個既有runner/tests/README leaves，host/source snapshots／manifest及所有真人資料唯讀。本輪不真launcher／全UID快照／App／DPK／新ready或原root清理；未來同CLI必待新freeze獨立審查及當段freshready。


## 2026-10-22 LG20：停止真人，修復程序查核結構（候選待審）

Human要求先解決反覆prelaunch guard、暫停真人與DPK；standing必要工具補修／non-live／獨立審查持續適用，不新增內部planning Human gate。LG19真stdout SHA `4a3c8419d6ec28852517c0886cb99aa57bef54244e1b250651dda25d653cd23c`、snapshot-name returnedzero/notFound、Human全程0、noD/noConsume/noSpawn維持unknown，不推退出／race／精確errno，也不改LG13／D06／原保存A與既有Keychain成功歷史。

本輪只以帶status/starttime的公開SDK fullinfo取代proc_name，正向識別zombie及非目標；live候選仍核完整path/open argv並前後比instance/classification。完全消失／reaped但無正向可信狀態者仍guard，不以errno略過或用沒有complete flag的UID列表宣稱完整absence。新有限aggregate觀測必能區分已觀測zombie排除、metadata不可得、permission、instance/classification改變及真衝突，限制依spec/plan LG20；不擴host/provider/產品API。僅non-live準備，真人／DPK／舊root清理全部暫停。


## LG26：path失敗後的單次同instance證據（候選待審）

沿Human必要工具補修／non-live授權，真人/DPK暫停。LG25 unknown/guard及真stdoutSHA `fd7147ccaa91aa6584f5dafa661e8ffd981eb63816b1e56c305bde8f9c8fcc6a`、Human本段0次全程觀察均保留；較早instanceChecked aggregate不能綁此次失敗項目。本輪只為path API失敗補一次同PID fullinfo後查，保存原path診斷；同instance可信zombie才可正向排除，其他結果仍guard，查不到不稱reaped。不改名字預篩或既有aggregate意義；精確有限schema／測試／三葉manifest依spec/plan LG26。


## LG31（2026-11-03）：離線啟動回報綁定

Human明確允許先完成最小planning／implementation／non-live tests／獨立review；舊context恢復不再是本輪離線前提。只增加本topic驗證工具的diagnostic-only request/report/ACK綁定，不擴OAuth或產品API。舊N尚未可信定位、原fixed run及兩known metadata位置missing的事實保留；不得重建舊manifest／identity／binary／receipt、補造ready或reset quota。

目標是讓未來明確授權的一次host回報可與attempt/context/request bytes及預期binary/實際live instance交叉核對；nonce/processUUID不是authentication或fresh proof。新operational context、signed build/verify、資產採用及Human launch只作後續文案，尚未授執行；目前free profile有效期unknown。全部舊成功/unknown與LG29/LG30歷史保留，不把fake當signed-host或DPK證據。精確契約依spec/plan LG31。


## LG36（2026-11-03）：profile-free 純診斷方案，僅規劃授權

Human已確認Personal Team及原certificate指紋／關聯private key可見，未證實私鑰可使用；歷史匹配profile已過期。停止將profile取得當純啟動診斷的必要前提：只規劃同target／原registered AppID、BID、CodeIdentifier、原DER-Team的零restricted-entitlement variant。此採用仍待Human；目前只授四artifacts及獨立planning review，不授實作／tests／compile／build／sign／App／profile／新context。原146/LG35僅原version成果，舊DPK gates與所有歷史、資產、quota不改。

成功條件是variant只能執行launch-report-only、legacy/env-loss/unknown不進credential capability，並在後續另授操作時維持同原certificate及完整binding歸屬標準；profile-free成功不代表DPK或原host權利驗收。舊N不阻方案；沒有權利claim不等於更改registered AppID/BID/signingTeam。細節依spec/plan LG36。


## LG44（2026-11-04）：原 certificate 解析與一次透明簽章補修

沿Human既有routine工具排障／non-live／獨立審查授權，修正準備工具對整份certificate文字搜尋OU的耦合；只在可信獨立subject輸出解析原Team，不變更原DER pin、class/EKU/OID、日期、信任及身分條件。LG43 operation unknown/sign-preparation/guard與Human全程0均保留；沒有原decoder輸出，不認定已找到歷史根因。

只runner/tests/README與owner原evidence；main、五模板、production、unsigned App/build原bytes唯讀。未來只允許同準備目錄一個明確sign-preparation amendment-1，綁原LG43 operation／caller／config／consumed，不reset原額度、不新namespace掩失敗。先完成工具與實際私有caller/config獨立審查，再取得新sign freshready；本次只planning，不查Keychain／簽章／context／launch或測試。細節依spec／plan LG44。


## LG52（2026-11-04）：LG51 report-timeout 受限修補

Human授權連續唯讀、離線planning／必要修補／non-live及獨立審查；不需另問內部採用。先釐清真Swift wire/FS/native self-metadata，再增加可信bootstrap後有限entry/failure回報與native結果記錄。允許後續必要unsigned CLI及新unsigned App準備；本段只planning，真sign／LS／新context／私鑰仍最後另freshready。原LG51 sign/context success及launch unknown/report-timeout、Human全窗口permissionRequests=0/wholeObserved=true保持，不拆造各段數字或其他actions。

只原topic四工具葉與owner evidence；原App/contexts/receipts/source/build/ready/quota immutable。不以-n、kill、security/trust/ACL／certificate/Team/BID/profile變更排障。後續僅同prep root明確一次LG51-report-timeout-amendment-1，鏈接原失敗SHA，不重置或隱藏原額度；必要新main導致新build/sign，不能假稱原signedartifact適用。詳spec/plan LG52。


## LG60（2026-11-04）：原簽章身分的有效 profile 取得，Human Execution Authorized

Human 已授權本次 profile acquisition：原 Personal Team／AppID，允許標準 Xcode Automatic provisioning 所需的下載、建立、安裝 profile，以及流程必要的 development certificate 新增副作用；不得手動 Manage Certificates／Fix Issue、撤銷既有 cert、改 trust／ACL、換 Team／AppID 或付費。最終 profile 必須包含原 certificate DER SHA256 `5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440` 並符合所有授權／有效期條件；綠燈或下載成功不等於驗收成功。這取代先前 noAuto／noNewCert 導致的取得停點，只放行 profile，不放行 App 簽章／LaunchServices／DPK／context／cleanup。必要 unsigned build 可用，不能暗中升格 signed build。LG59 與全部成功／unknown／spent 歷史保持。精確操作與 once manifest 見 spec LG60；先 LG61 獨立規劃審查，再執行，不另索一般 ready；真正不可代辦的登入／2FA／unlock／私鑰授權才集中交 Human。


## LG65：限時 DPK 接線（2026-11-04）
Human授權最小接線、affected nonlive測試、獨立review與unsigned準備；09:06:29Z–10:06:29Z為不可延長窗口，含Human等待。LG64有效profile與原身份沿既有受審證據，不重provision。禁止新/撤銷cert、profile更新、AutomaticSigning、trustACL、換Team/AppID、付費、Git發佈；真人sign/App/DPK須準備及獨立審查後集中fresh授權。首次save≤1、freshA/B/rebuiltB=0已鎖；replace0與每build/sign階段原key當次授權≤1是待Human採用提案。原成功/unknown/ownership/spent保留、不cleanup。精確delta見spec LG65。


## LG73（2026-11-05）：新真人窗口候選，不開窗

只規劃可由準備審通後Human明確採用並freshready才建立的新live authority。User「可以繼續」只授offline，不延長／重設2026-11-04已關窗口，不重用ready/quota。提案新ready起至多60分鐘，含Human等候；替換0提示及每build/sign原key當次授權≤1仍待Human採用，首次save≤1及freshA/B/rebuiltB=0不變。LG70-R已核offline里程碑不重做；profile/原身份及一切禁止事項保持。精確最小delta見spec LG73；本作者不改source、不開新window/真context/sign/App/DPK。

RF-LG74-01最小修訂：新Human record/authority必綁同一本機kernel boot-session canonical hash；跨開機或不可得先拒絕，精確來源與bytes只定義spec LG73，不新增權限/leaf或開窗。


## LG82（2026-11-05）：受限交付收尾

來源為User本輪收尾授權及Planner bounded audit approved。LG81-Cap-R已獨立approved、required fixes=[]；LC01–05／07本輪完整A→freshA→整筆B→freshB→真同身分重建→freshB與必要Human結果成立，只限假bundle與指定環境。AC01–08沿S05/S06；AC09原圖技術驗證成立、Human visual仍pending。LC06 cleanup未做且本輪禁止，S08 Human acceptance不代填。舊窗口／成功／unknown／資產及額度均不改，不重跑驗收。

本輪只將長期能力文字、驗證限制與帳本現在式對齊證據，準備publication既有leaf內的PR更新草案及exact-stage／commit-message提案。PR仍Draft；本輪不commit/push/merge/rebase或寫GitHub，前文早期publication授權不作本次執行依據。五個base衝突與public configuration差異尚未整合，不能因此否定DPK結果，也不能據此變更原公開契約。精確manifest／九欄／步驟以plan LG82與spec CD01–05為準；不新增Mission／summary／release／VERSION或新工具驗證。
