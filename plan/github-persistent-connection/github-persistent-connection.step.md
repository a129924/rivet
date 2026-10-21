# GitHub 持續連線：驗證產物歸屬回修帳本

- Topic：`github-persistent-connection`；最後更新：2026-10-21，Implementer（R10本輪topic交付與原DraftPR更新）。
- Phase：原DraftPR human review；Current step：R11；Current status：human-check。
- Upstream verdict：approved（2026-10-21 獨立Reviewer R09；requiredFixes=[]；成果／宣稱／來源核對完成，只交已授權R10，R11Humanreview未代填）。
- 本輪Human指令撤回正式產品定位，交付完整獨立驗證App／可行性結果／限制。沿原featureworktree、branch `feat/github-persistent-connection`、DraftPR #62／base dev；不在dev實作，不改PR #61。
- 四正式artifacts：[requirements](../../analysis/github-persistent-connection/requirements.md)、[technical-spec](../../analysis/github-persistent-connection/technical-spec.md)、[plan](github-persistent-connection.plan.md)、本step。

## 現行 Steps（只有本節是本輪路由）

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker／verdict |
|---|---|---|---|---|---|
| R01 | completed | Plan-Creator | 本輪scope、精確actionmanifest、Appidentity／依賴／歷史與真人分段寫入四artifacts | 2026-10-21本四份修訂；非自審／approval | verdict=null，交R02 |
| R02 | completed | Plan-Reviewer | 獨立審scope及四artifacts，明示verdict／fixes | 下列 R02 獨立審查收據及四 artifacts 受審 SHA | approved；requiredFixes=[]；R03 待 Implementer 執行 |
| R03 | completed | Implementer | planD19／M01-M02污染撤回，完整App-local實作與自驗，W05逐檔清單 | verification-host-manifest／contracts／isolation；下列R03自驗收據 | 僅implementation完成；交R04獨立Tester，非自審approval |
| R04 | completed | Tester | 獨立TC01–TC07、排除整個驗證App仍productionbuild/test | verification-host-contracts／isolation／review；下列獨立收據 | approved；requiredFixes=[]；只交R05 |
| R05 | completed | Reviewer | 獨立source／dependency／terminaltracker／testsreview | verification-host-review R05及私有獨立收據 | approved；requiredFixes=[]；只交R06 |
| R06a | completed | Tester＋Human | 新host原Team/cert選定、簽章／有效profile／新identitygroup與新固定位置核對；Human提示觀察 | verification-host-live：本輪真machine／逐段Human0，未用舊host結果 | approved；requiredFixes=[]；僅R06 scope |
| R06b | completed | Tester＋Human | 新host首次真OAuth→DPKconfig／credential保存→GET/user有效帳號 | verification-host-live：本輪真machine／逐段Human0，未用舊host結果 | approved；requiredFixes=[]；僅R06 scope |
| R06c | completed | Tester＋Human | 同binary完整退出、新PIDrestoreAPI | verification-host-live：本輪真machine／逐段Human0，未用舊host結果 | approved；requiredFixes=[]；僅R06 scope |
| R06d | completed | Tester＋Human | 真CleanBuild不同binary同identitysamepath、新PIDrestoreAPI | verification-host-live：本輪真machine／逐段Human0，未用舊host結果 | approved；requiredFixes=[]；僅R06 scope |
| R06e | completed | Tester＋Human | 受控providerexpiry→真GitHubrefresh→真DPKsave→API、realclock恢復 | verification-host-live：本輪真machine／逐段Human0，未用舊host結果 | approved；requiredFixes=[]；僅R06 scope |
| R06f | completed | Tester＋Human | 新observePID讀回輪替六欄digest並API、不force／不refresh/save | verification-host-live：本輪真machine／逐段Human0，未用舊host結果 | approved；requiredFixes=[]；僅R06 scope |
| R07 | completed | Implementer | 文件宣稱及revision圖／nativeQA／工具實證 | v2 BUILD／visual-review／tool-evidence、R07 manifest與下列作者收據 | 僅作者完成；交R08獨立Tester，未自審approval |
| R08 | completed | Tester | 獨立TC08/TC09證據／圖／privacy／immutablehash核對 | contracts／isolation／review R08與私有獨立收據 | approved；requiredFixes=[]；只交R09 |
| R09 | completed | Reviewer | 獨立成果／宣稱／scope／新舊來源review | verification-host-review R09及私有獨立收據 | approved；requiredFixes=[]；只交R10 |
| R10 | completed | Implementer | stagedtopic語意/message→mandatoryhooks→commit→真PRLensmap／有限Graphify→正常push→更新原DraftPR並readback | 下列真commits／53pathmap／6項hooks與Draft62readback | 停R11Humanreview，不merge；最後receiptcommit與finalhead由Dispatcher交接讀回 |
| R11 | pending | Human | 原DraftPRhumanreview | 尚待 | 最終停點，不代填接受 |

## Blockers

- 尚無已證實不可解除技術 blocker。R02 已由獨立 Plan-Reviewer 明示 approved／requiredFixes=[]；R03完成implementation，R04獨立Tester及R05獨立Reviewer均approved／requiredFixes=[]；R06a–f新host真人機器結果及逐段Human實答已完成，R07文件圖經R08獨立Tester及R09獨立Reviewer approved／requiredFixes=[]，R10已完成本輪topic提交／push／原DraftPR更新；停R11，不代Humanreview或merge。
- 新驗證host六段均已以本輪來源驗證：首次授權保存API、完整退出還原、真正Clean重建、受控真refresh及輪替新程序讀回；setup／build及五結果段Human均實答0。R07文件／revision圖及R08獨立Tester已完成；R09最終獨立成果審查已approved；R10已真commit／map／push並更新原DraftPR，仍待R11Humanreview；不把DraftOPEN當接受或merge。
- profile更新後讀回仍unknown／Human已接受限制，不阻擋現scope，不開第三輪E007；不擴張成豁免其他新hostlive。
- 重大scope／正式API不可撤回、新certificate／安全設定／cache變動／付費要求即停並報具體必要性；不得默認保留production污染或借舊identity。

## Human Check 與授權

2026-10-21 Human已明確授權本輪規劃／必要審查→獨立App回修→適當測試→必要真人逐段通知→topiccommit／push／更新原DraftPR #62→humanreview。不重問是否開始或已授權commit。stageddiff語意與message、mandatoryhooks、獨立角色仍遵守。不得merge。

沿用原免費PersonalTeam／既有AppleDevelopmentcertificate；rawsecret只在SecureField，rawidentity／profile／私有path不入repo。原Rivet.app、真DPKitems、Appleprofiles／certificate保留；新namespace不遷移它們。每真人段通知留意授權視窗，Human實際回報才記count；舊host各段0次保持歷史，不能複製到R06。

## 本輪九欄與交接

| 欄位 | 本輪交接 |
|---|---|
| In-Scope | planD／M／W精確manifest及TC01–TC10，完整獨立驗證流程與歸屬宣稱回修 |
| Out-Of-Scope | 正式產品整合、PR #61合流／去重、新正式API、E007新run、logout/revoke、Apple安全變動 |
| ReadOnly | planR及dev／其他worktrees；E007／舊native圖／原版本observationsimmutable |
| Written | 新App與新版evidence／revision圖精確leaves |
| Deleted | D表19個本topic新增舊production路徑 |
| Modify | M01–M06；四正式檔精確回base，banner-only歷史導覽／證據 |
| Goal | 完整流程App可操作，production脫離App仍build/test；來源真實可追溯 |
| Non-Goal | 宣稱正式產品完成、保留驗證production契約／共用UI／開關／工具、預填真人結果 |
| TestCase | TC01–TC10及R06六段，依slice逐檔與case交付，不能只帶目錄 |

Handoff：phase=原DraftPRreview；current_step=R11/human-check；upstream_verdict=R09approved／requiredFixes=[]；R10依授權完成topic提交／真map／normalpush／更新原DraftPR62，assigned_role=Human；next_objective=Humanreview，不merge。最後doc-only收據commit與最終refs／cleanworktrees由Dispatcher實際讀回，不把自指SHA寫成本頁hash。以下歷史不是現行 handoff。

## R02 獨立 Plan-Reviewer 收據（2026-10-21）

- 明示 verdict：**approved**；requiredFixes：`[]`。本角色獨立於四份 artifacts 作者，只審 planning 可執行性，不批准尚未執行的 source／測試／新 host 真人結果，也不替 Human 接受。
- 已讀專案 README／design-principles／AGENTS／architecture README／OAuth 長期文件、plan-reviewer 與 SDD 兩份 references；對照 PR #61 實際獨立 App 入口、project 產品依賴與分離 amendment、既有 public ports／provider terminal policy，未修改該 PR。
- 四份 artifacts 一致定位完整獨立 GitHubConnectionVerification 驗證工具；D19＋M01/M02 四檔撤回基準、production／root tests／Package zero-diff 與 App 缺席測試可核對；本地 refresh／endpoints／DTO 及同 generation wrapper tracker 可沿既有 public ports 實作，不需新增正式 API／visibility，也不以再呼叫 snapshot 觀察停止。
- 新 bundle／group／service／環境 key／product／scheme／module／test host／常駐 UI 均明示驗證；九欄及精確 from/to／新 leaves／保留清單、逐檔 action/hash 記錄足以約束搬移。E00732 與舊 native 圖 immutable、舊 host provenance／banner-only、profile renewal unknown／Human 例外和新 host 六段 pending 互不混用。
- 必要自動測試、terminal／settlement／clock／receipt、production 排除 App build/test、逐段 Human 新真人驗證、revision 圖真工具 QA、PR Lens 真 commit 覆蓋與 Graphify bounded fallback 均已涵蓋；原 branch／worktree／PR62、不動 dev／不合流 #61、不 merge 的交付邊界一致。工具如需未列 native leaf 依既定最小 amendment 再查，不擴目錄授權。
- 受審 SHA-256：requirements `2598a7def3021d930fdfab4b3dfa1a5745a3294d80f0c35cdfbf367f51440773`；technical-spec `161d40239f7d7c4b9ed6e424b24f5f0e53d4db7ea18526d26ef9d2df66862f59`；plan `13ca04cf409943b3a545f664ba11d75b6c009d10feb0e328e0ad0687e787e6bc`；本 step 收據前 `cf9b27bc4e6e6df26dbb57b7a96044620ab957f5a4c4d25593b3d8d203c3a228`。本次只記自身 R02 收據／狀態，不修受審 requirements／spec／plan；未執行 build／tests／App／憑證／Git mutation／發布。寫後停止本角色檔案修改，供既定 R03 handoff。

## R03 Implementer 實作與自驗收據（2026-10-21）

- 引用外部R02 approved／requiredFixes=[]，依D19／M4／W01–W05受限執行；沒有重設scope／新增正式API／visibility／gate／與PR61去重合流。19個原正式新增路徑已搬入新驗證App並刪舊，四既有正式檔確認HEAD未偏離後精確還base16606b89，rootSources／Tests／Package整體zero-diff。逐檔舊／新SHA、30新Appleaves與61immutable保留項見 [manifest](evidence/verification-host-manifest.md)。
- App target／scheme／product／module／bundle／group／service／env／TEST_HOST全新驗證identity；畫面常駐「驗證用途，非Rivet正式產品」。App僅依既有GitHubIntegration／RivetHTTPClient publicproducts與系統frameworks，不連RivetPresentation。App-local endpoints／sixfieldDTO／refresh自持有限policy；productioninternal不可見測試改用publicports，不擴權。
- Coordinator每providergeneration建本地Mutex tracker，以實際fetcher.refresh／store.save wrappers記錄terminal facts；純查詢不呼snapshot／prepare／網路／store。初次grant保存不誤停，accepted後savefail停、每次成功save清marker，第二輪失敗仍停；twoexpiredrotationlimit保持非terminal。原settlement／singleadmission／retirement／noresurrection／repair表與錯誤分類保留。
- TDD實際trackerplaceholder紅燈：5tests／1suite、33issues；補最小本地狀態後綠燈。最終普通unsignedbuild exit0，完整fakehostedtests xcresult78passed／0failed／0skipped（29XCTest＋49SwiftTesting、參數107runs）；featurebaseline202tests／22suites、publicconsumer12／3均pass。最初機械編譯／工具參數失敗有私有log，不冒稱行為red；最終命名／error匹配收斂後重新核完整78。
- 在owned0700獨立scratch逐檔複製當前1128trackedfiles、排除整個apps，普通swiftbuild exit0及相同productiontests202／22pass，production檔不需改。24Swiftleaves strictformat／SwiftLint0violations、plistlint3OK、schemeXML／pins一致／imports／buildsettings與diffprivacy檢查通過。沒有install依賴／改hook／跳必要檢查。
- E00732／舊native圖29逐bytes不變；舊evidence5與舊導覽3未改，banner與長期docs／revision圖留既定R07。W05 live／review只建立pending框架，所有新host真人／Human提示null；availability不等開始。未啟動真App／DPK／瀏覽器，不動原安裝App／真items／Appleassets／dev。
- 本角色只宣稱R03implementation完成，交R04Tester→R05Reviewer；未commit／push／改PR或自審通過。從handoff後停止repo／step寫入，供獨立驗證。profile更新仍未驗證、Human接受限制保持。

## R04 Tester 獨立交付（2026-10-21）

- 適用TC01–TC07；43交接SHA、D19from/to、M4basebytes與Sources／Tests／Package整體zero-diff、E00732／舊native29（另對ca00bc0）皆相符；受審62statusleaves／30Appleaves精確manifest通過。
- 自有當前source snapshot新Appunsignedbuild exit0、完整fakehosted原生xcresult78passed／0failed／0skipped（49SwiftTesting＋29XCTest，動態參數107runs）；localtracker／refresh／settlement／noresurrection／earlyguard0live／controlledclock及receiptnegative均pass。24Swiftstrictformat／SwiftLint0、三plist／scheme／pins／privacy／diffcheck通過。
- 自有另一份當前source snapshot排除整個apps，普通swiftbuild exit0、productiontests202／22及publicconsumer12／3pass，production無需修改。KeychainTokenStoreTests明示skip避免真legacyKeychain；首次sandboxcache權限失敗後循正式escalation重跑，非sourcefailure或略過檢查。
- 本角色未改source／tests／受審manifest、真App／DPK／Apple資產／dev，無Gitmutation；只追加自己的contracts／isolation／review及step。原生logs／xcresult與完整私有收據SHA `6e4a6724f82e039a1f391579b066b024bf9d3b28b9e52e7ec0ce38701964a1b1`可追溯。
- verdict=approved，requiredFixes=[]；交R05獨立Reviewer，從此停止repo／step寫入。R06全部新hostlive／Human提示仍pending／null；availability不等freshready。R07舊宣稱與新版圖修正尚未完成；profile更新仍未驗證、Human接受限制不變，不宣稱整topic完成。

## R05 Reviewer 獨立交付（2026-10-21）

- 直接source／dependency審查未發現requiredfix；D19撤回／M4回base、production Sources／Tests／Package／packages zero-diff，App-local完整驗證流程與同generation tracker／settlement／terminal／noresurrection符合鎖定契約，沒有新增正式API或PR61合流。
- 34source/project/test、61immutable、12原生log與4Tester evidence SHA相符；核R04 fakehosted78／0／0、productionApp缺席普通build／202tests／22suites、consumer12／3及strictformat／lint／plist／pins／deps收據。未重跑已綠suite、未操作live。詳 [R05收據](evidence/verification-host-review.md#r05-獨立-reviewer-收據2026-10-21)。
- verdict=approved；requiredFixes=[]；私有收據SHA `eb17d6faaaabd86a0bec5be73334013db1202ddd409bd20b4ecc1de7416e84d8`。只交R06a新host真人準備；R06全部pending／promptCount=null，availability不等已操作，R07文件圖及後續審查／發布尚未完成。舊host0次／舊approval不挪用，profile更新仍未驗證、Human已接受限制不變。
- 僅寫本角色review／step，沒有source／tests／Gitmutation／dev／真App／DPK／Apple／外部write；此刻停止repo寫入。

## R06a–f Tester 真人可行性驗證交付（2026-10-21）

- 新run t0=03:19:42Z（臺灣11:19:42），未另設45分鐘窗口。setup、build、首次授權、samebinaryfresh、Cleanrebuildfresh、controlledrefresh、rotatedfresh七項Human均逐段實答0；Human確認親自在新App輸ID／secret並完成真授權。沒有預填、借用舊host或以browser靜態文字當API成功。
- 精確正常Quit／新PID鏈80099→82770→85789→86552→90031；固定新安裝位置、常駐驗證label、每次validsameaccount。真Clean後builtproduct不存在、再GUI Build的原生compile／link／codesignlog、新binary633192…7f67異於初f81133…ad0f；原certificate／Team／group／有效profile與currentMac授權相符，非profile更新。
- 首receipt在空設定start已exclusive輸出，未觀測grant後digest；R06c新程序首次直接觀測完整已保存六欄19112c07…65547。R06e受控providerclock觸發真GitHub attempt1／accepted1／真DPKsave1，accepted=persisted新b27c24f9…c3e36、clock回real；R06f observe無force／refresh0／save0，restore=providerload=相同新digest。只證aggregatepairChanged，不宣稱自然到期／個別tokenhash。
- R05受審source與61immutable、repoApp30hash再次核未改；私有Xcode僅App Debug選Team、兩Debugrunpaths等tokenarray序列化與objectVersion56→60，已如實記，不將私有project說成repo byte-identical。production對base零diff保持。
- 來源／binary／profile／原生收據與Human/UI sidecar hashes、UTC界線及限制見verification-host-live。原新App／舊RivetApp與真DPK／Apple資產及ownedprivate證據全保留，無清理／revoke／第三輪E007；profile更新仍未驗證、Human接受限制不變。
- R06 bounded verdict=approved，requiredFixes=[]，Current R07 pending交Implementer；只更新live／review／自己step，從handoff後停止repo／step寫入。不自批R08/R09／全topic，不Git／merge；無下一真人需求。

## R08 獨立 Tester 文件圖與來源交付（2026-10-21）

- verdict=approved／requiredFixes=[]，適用TC08／TC09及必要manifest來源回查。106action＝status、87受審hash／32v2leaves、143currentlinks／privacy／diffcheck全通；8historybanner原ca00bc0suffix、61immutable、R06live／真機器／7Human0鏈及README-only新舊來源核符。production含packages對basezero-diff。
- 三Archify重新showcase9/9零錯警；全新ownedprivatebytecopy四尺寸visual-check全pass，12canonicalPNG逐張親看。Canvas獨立5bands19boxes17edges零錯警、nativebuild逐bytes相同，再以privateChrome截圖親看；Coordinator保存／publicport注入／tracker／settlement語意與source一致。nativepending不手改，非自動Human接受。
- 本角色讀必要archify／canvas／prlens／graphify技能；真PRLens0.11.0／Graphify0.9.73確認，後者每次禁autorefresh。無usablegraph／config，sourcefallback如實；真修訂commit map留R10。未Swift／live重跑、App／DPK／Apple／Git操作，不修受審source／docs／圖，只有自己的四個既定收據／step。
- 私有收據SHA `13cd20f8af19d5fd342613af002d56656bfc10353bc883ce64426707a3e334b3`；詳contracts／isolation／review。Current R09 pending交獨立Reviewer，停止所有repo／step寫入。profile更新unknown／Human接受、controlled非自然、首grant後digest未觀測及aggregatepairChanged限制保持，不自批全topic／發布／Humanreview。

## R09 最終獨立 Reviewer 交付（2026-10-21）

- verdict=approved；requiredFixes=[]。四正式契約與本輪驗證定位一致，四長期docs撤正式產品claims，新舊live來源／README-only版本界線及歸屬清單完整，無production新增契約或PR61合流。
- 87受審hash／R08四收據hash、61immutable／8原文suffix／R06十一machine-Human收據鏈及29個未改App compiled／resource／project／test葉檔核符，production對basezero-diff。新host七項Human0、兩真binary／獨立PID及六欄輪替鏈一致；首grant後digest未觀測、controlled非自然／aggregate非個別token與profile更新unknown限制不改。
- 親看真Canvas與三張nativePNG，ownership／Coordinator保存／tracker／settlement／noresurrection與source一致；核R08原生9/9／四尺寸／12PNG／Canvas5/19/17零錯警及byteidentity證據。未重跑綠Swift／live／native工具、不代修source／docs／圖。詳 [R09審查](evidence/verification-host-review.md#r09-最終獨立-reviewer-收據2026-10-21)。
- 私有獨立收據SHA `7f371d4cd30302b502a891d49ca7372b2f28c191da7d9e35c2ddc020dcf89945`；Current R10 pending，交既定已授權topiccommit／真PRLensmap／hooks／push／原DraftPR62更新，再R11Humanreview；不再加Human圖面接受gate、不merge／不預填發布或CI結果。只寫review／自身step，無App／DPK／Apple／dev／Gitmutation／外部write，完成停寫。

## 歷史帳本封存（2026-10-20，非本輪路由）

以下保留原 `ca00bc0` 帳本完整內容，包含當時正式產品定位、舊approval、Human接受、commits與PR交付；**正式產品定位及交付完成宣稱現已撤回**。舊S01–S12 status／verdict僅對原版本，不能放行R02–R11。sourcecommit7e81b77只供追溯，真人實際build在commit前，依原sourcehash／private收據鏈，不改寫為該commit之後執行。舊E007unknown與實際Human例外保留。舊原始內容如下：

---

# GitHub 持續連線：執行帳本

- Topic：`github-persistent-connection`
- Phase：S11 已接受；S12 topic commits／真 PR Lens map／正常 push／Draft PR 已交付，停 Human review。
- Current step：S12
- Current status：human-check（Draft PR #62 已 OPEN／isDraft=true／base=dev；交付完成後等待 Human review，不 merge）
- Upstream verdict：外部 Plan-Reviewer 已 approved 唯一 gate amendment 及 StaticIsolation 精確 manifest delta；S06a Tester 與 S06b Reviewer 均明示 approved／requiredFixes=[]，僅接受 integration fake-only 契約及相容性，交 S07。S08a Tester 與 S08b Reviewer 亦均明示 approved／requiredFixes=[]，只放行 S09。E007 當時 human-check／thirdRunAllowed=false 與後續 Human 接受決策分列保持。
- Branch：`feat/github-persistent-connection`，由 `origin/dev` 的 `16606b8` 建立，PR target `dev`；建立與乾淨狀態由呼叫端 Planner／Dispatcher 提供，本輪不另執行 Git。
- Worktree：指定本 topic feature worktree；本輪四份寫入均在該 worktree，不在 dev。
- 最後更新：2026-10-20，Implementer 記 S11 真 Human 接受與 S12 staged 語意／topic commits／本地工具交付進度。
- 契約：[requirements](../../analysis/github-persistent-connection/requirements.md)、[technical-spec](../../analysis/github-persistent-connection/technical-spec.md)、[plan](github-persistent-connection.plan.md)。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 | Blocker／verdict |
|---|---|---|---|---|---|
| S01 | completed | Plan-Creator | 建立同 slug 四份 artifacts，鎖定 scope／九欄／精確 manifest／V01–V09／Human boundary | 本四份文件的實際建立結果；不是品質 approval | verdict=null，交獨立 Plan-Reviewer |
| S02 | completed | Plan-Reviewer | 獨立回查 RF01 host 前提及 V01／V06／V08 | 正式回查明示 approved，required fixes=[]；technical-spec §0、plan §1 | approved；僅放行 S03 preparation |
| S03 | completed | Implementer | 原 W06 bounded fix 完成：Human 公開投影、可信 read marker／finalize 分類 | 28 pure tests；兩項負向 red→green；r1 Tester／Reviewer source SHA 核對 | RF-R01／RF-R02 已解除；非 live 結果 |
| S04a | completed | Tester | 獨立 r1 準備重驗 | preparation-tests-r1.json：28/28、strict format／SwiftLint、獨立 unsigned build exit0；SHA 74e49d9b193e5e4369cb01c494f415b61b261b14ae01a7516e515c0a95e2d9c6 | approved，requiredFixes=[]；v0 immutable 保留 |
| S04b | completed | Reviewer | 回查 RF-R01／RF-R02、source SHA／immutable v0 | preparation-review-r1.json；SHA f9bae387090bb05323c0c5abbecd5c021219ec84ebd23ed6f087562028dba4ae | approved，requiredFixes=[]；僅準備放行 |
| S04c | completed（第一輪／第二輪有限證據收尾） | Tester | 當次 Human ready／逐段觀察下執行受限 45 分鐘 renewal run；第二輪僅一次精確 cache 移出／refetch／B Build，分列四狀態、清理／恢復、限制 | 兩輪 run receipts／Human sidecars；第二輪 tester-validation.json SHA fcd273cd697a34f21d02536452805fcc588e24bad7dc143b5a6118d646a5b133；第一輪 SHA 保留於歷史段 | approved 僅證據／安全收尾；renewal 無法判定、read 未執行，runner taskComplete=false |
| S04d | completed（第一輪／第二輪有限證據收尾） | Reviewer | 依事前判準獨立判讀真 run／清理／cache 恢復／timebox／證據 | 第二輪 reviewer-verdict.json SHA 9cd28d7bb548849e310005c72d1811ccde889033bf41fff0f735532cd5d2457b；第一輪 SHA 保留於歷史段 | approved 僅有限證據；workflow=human-check，requiredFixes=[] |
| S04e | completed | Human | 接受同身分 profile 更新後讀回未驗證，僅解除 renewal 必須先驗成功的前置，其餘驗收維持 | Human 原文：「接受 profile 更新後尚未驗證的限制，修訂 gate 並繼續產品實作」；問題明示其他驗收維持、失效及重新授權保留 | 依實際 Human 決策完成；非 E007 pass、不再問採用，不允許第三輪 |
| S05 | completed | Implementer | W02／W03／M01／M02 bounded implementation 完成；可交 S06a Tester | 自驗：GitHubIntegration fake-only 211 tests／22 suites、consumer 13 tests／3 suites、11 檔 strict format／SwiftLint 0 violations | 僅 implementation 完成；待 S06a／S06b 獨立驗證，不宣稱真 OAuth／DPK／UX |
| S06a | completed | Tester | 獨立驗證 S05 contracts／public API／既有 lifecycle regression | evidence/contracts.md／compatibility.md：獨立 integration 211 tests／22 suites、consumer 13 tests／3 suites；精確 11 檔 format／SwiftLint strict 0、diff check 0 | approved，requiredFixes=[]；僅 fake-only，交 S06b Reviewer |
| S06b | completed | Reviewer | 獨立審查 integration，明示 verdict／fixes | evidence/final-review.md 的 S06b：source／bounded diff、11 hashes 與獨立 Tester 收據核對，diff check 0 | approved，requiredFixes=[]；只交既定 S07，不代表 topic final approval |
| S07 | completed | Implementer | W04／W05 最小 host／UI／relay／coordinator 與 fake-only hosted tests 完成，可交 S08a Tester | 自驗 unsigned Build exit 0；hosted 23 tests pass；root package 226 tests pass；8 檔 strict format／lint 0 | 只 implementation 完成；真簽章／DPK／GitHub／提示／refresh／E2E 尚未驗證 |
| S08a | completed | Tester | 獨立fake契約／正式signed產品真DPK-GitHub／退出新程序／同身分真正重建／受控expiry真refresh／輪替後新程序及Human提示 | contracts／compatibility／storage-live／product-e2e最終段：fakehosted29／0／0、root226／25；五live路徑成功、各Human0，最後receivedAtUTC08:58:02；source／receipt hashes分列 | approved、requiredFixes=[]；RF-P01／RF-P02已獨立解除；只交S08b，不等於topicfinal或S11接受 |
| S08b | completed | Reviewer | 獨立審查 W04／W05、RF-P01／P02 及真／controlled／fake 證據 | final-review.md S08b：12 leaves／59 linked hashes、4 真程序 receipts、GUI logs／installed signature-profile／全段 Human0 核對 | approved、requiredFixes=[]；只放行既定 S09，不等於 topic final／S11 接受 |
| S09 | completed | Implementer | W07／M03 source-consistent 長期文件、四圖與工具 evidence | 三張各 showcase 9/9／0 errors／0 warnings、四尺寸 containment pass、12 真截圖親看；Canvas 0/0 並實際截圖親看 | 交 S10a；Human visual pending，不發布、不改工具設定 |
| S10a | completed | Tester | 核V01–V09 evidence／docs／圖技術與source一致性，保留Human點 | contracts／compatibility S10a：三圖9/9零錯警／獨立四尺寸與12PNG親看；CanvasRF-D01重驗0/0、正確單邊責任／幾何／重建byteidentity／新截圖；69source／四liveSHA鏈／五Human0及linksprivacy核符 | approved、requiredFixes=[]；只交S10b，S11Human與S12真commit後工具／發佈保持pending |
| S10b | completed | Reviewer | 獨立成果／scope／workflow review，明示 verdict／required fixes | final-review.md S10b 第一輪及 RF-D02 bounded recheck；兩段現況已對齊，先前其他成果核對保留 | approved、requiredFixes=[]；只交 S11 Human，不等於其接受／發布／merge |
| S11 | completed | Human | 正式入口／真系統提示與成果 Human review／必要接受決策 | Human：圖面與成果可接受，繼續既定交付；receivedAtUTC2026-10-20 09:51:14 | 實際接受，非自動 pending 推定；授權既定 S12 |
| S12 | completed | Implementer | staged 語意檢查後 topic commits／真 code map／正常 push／Draft PR 回 dev | 下列真 commit IDs、原生 PR Lens manifest/SHA 與 Draft PR #62 readback | 停 Human review，不 merge；CI 未提供 checks，不冒稱 pass |

S11／S12 順序依授權語意：S11 記錄交付需要的真人入口／UX確認；S12 完成已授權 Draft PR 後仍停 Human review，不把 Draft PR 建立等同接受／merge。若實際入口驗收需等待 Human，先如實記 human-check，不藉 Draft PR 越過採用或驗收 gate。

## Blockers

- B01：S02 正式 Plan-Reviewer 已 approved，required fixes=[]；此前置已解除，並非採用批准。
- B02：準備 RF-R01／RF-R02 與方法 RF-M01 已解除；第一輪 A／B profile bytes 相同，第二輪在 cache 移出前完整恢復預檢未通過，兩輪 renewal read 均未執行而無法判定。首存／清理成功不補足 renewal 證據；Human 後續明確接受該未知，唯一採用前置阻擋已解除，未將 E007 改為 pass。
- B03：正式signed Rivet.app／adapters／首次登入／持續連線五主要live路徑已由S08a實際驗證；目前待S08b獨立成果審查與後續V09／最終Humanreview，不能當全topic已完成。
- B04：本輪 fresh ready／免費 Personal Team／既有 certificate 聲明及各段 Human 觀察均已到位；原窗口內清理完成，此缺口已解除，不代表 renewal 成功。

當時依獨立 Reviewer human-check 停於 S04e；其後 Human 已明確接受唯一未知限制並授權繼續，現路由為 S05 pending，待本 gate amendment 獨立回查。第一輪主假設無法判定與 phase 2 未執行分列；不當作失敗或成功、不重開其窗口。Human 已另授權唯一第二輪；獨立 Plan-Reviewer 已 approved 本方法 amendment、RF-M01 解除。該唯一第二輪後已完成，詳見下方結果；當時停於 S04e，後續 Human 決策如下，不新增 phase 或 gate。

## Human Check 與既有授權

- 已鎖定：DPK方向、首次 ≤1／fresh 0／rebuild 0、同 App ID／group／cert 的 renewal 未驗證由 Human 接受，僅解除該採用前置、自有 OAuth App 首次輸入 client ID／secret、單帳號 scope與既有 ownership。
- 已授權：先 feature worktree，再其內依計畫實作；無重大問題時 topic commit → push → Draft PR → Human review。發佈授權不需再以舊預設詢問，但 staged diff語意／message仍需檢查，不含 merge。
- 已提供：首存、B 設定／建置及清理各全段 0 提示；B 觀察不是 renewal read。不可推定：E007 成功、renewal 採用、正式入口真 UX驗收；free profile 過期期間不可用及 cert rotation 不外推。
- Human Apple assets保留，不新建額外certificate、不改安全設定、不要求付費；遇到即停。新授權只允許備份後暫移本輪精確 profile 本機快取並恢復，不含遠端刪除／撤銷。

## Handoff 契約

以下為準備期歷史 handoff（已完成，非目前路由）：本次 manifest amendment 交獨立 Plan-Reviewer，僅回查新增兩個精確 r1 收據路徑及既有 gate 不變，不重審整 topic、不新增 phase／gate。實作流為 S03 bounded fix → S04a r1 Tester → S04b r1 Reviewer；current_step=S03/needs-rework，不啟動 live 或替 Human 填觀察。

後續每個 Implementer handoff必須附同九欄 In-Scope／Out-Of-Scope／ReadOnly／Written／Deleted／Modify／Goal／Non-Goal／TestCase，逐檔展開本 slice manifest、V-ID、輸入類型與停止條件。只交精確子集，不授權整 topic 任改；不新增 gate或 workflow phase。

## 更新規則

各 role 只填自己實際完成的 evidence／status；checkbox或status不等於 approved。Dispatcher 不手算 gate、不修改帳本。needs-rework交對應產出角色、blocked／human-check交 Human。新實驗／修正不覆寫歷史 immutable receipts；source、docs、圖及真證據不得互相冒充。

## S03 實作交接：九欄

- In-Scope：E007 fake-only 準備、guarded runner、最小 App 與 pure controls。
- Out-Of-Scope：live、Apple assets、Security 實際存取、產品 adapters／UI、既有 lifecycle 改寫。
- ReadOnly：E001–E006、production、Package.swift、工具設定；只重用 E006 selected-App inspection。
- Written：W06 精確八檔：README、project.pbxproj、shared scheme、Sources/ProfileRenewalProbe.swift、Info.plist、entitlements、scripts/run_profile_renewal.py、Tests/test_protocol.py。
- Deleted：沒有 repository 刪檔；測試只清自己建立的 TemporaryDirectory。
- Modify：本 step，記錄外部 verdict 與本角色已完成的事實。
- Goal：使 renewal／Human 證據／時間／精確清理控制可獨立驗證，為真輪準備。
- Non-Goal：宣稱 DPK、profile renewal 或產品成功，或將 Human availability 當 fresh ready。
- TestCase：V01 preparation，21 pure cases（含 Swift core）；unsigned build、swift format／SwiftLint strict。Xcode sandbox 有 simulator/cache warnings，但 App build exit 0；不涉及 simulator 驗收。

Human 已表示「準備完成後可即時配合」，只表示 availability。獨立 Tester／Reviewer 通過前不開始 setup t0；仍需真正 fresh ready／免費來源聲明及逐段觀察。初始 runner 缺檔 red，以及無效 Human SHA 曾誤判成功的 red 已保留於實作交接描述；後者修正後為無法判定，未以 mock pass 作 live 證據。

## Preparation review bounded 回修與 manifest amendment

- RF-R01：Human 自由文字不得直接 export；採有限欄位／值的 projection，排除任意私人文字。RF-R02：guard failure／invalid machine 收據不構成有效 renewal 測量，不能判為主假設 failure。只回修既有 W06 source／控制測試及 README，不擴主問題。
- 本次只新增 plan manifest 的兩個 exact leaves：`experiments/E007/evidence/preparation-tests-r1.json`、`experiments/E007/evidence/preparation-review-r1.json`。原 `preparation-tests.json`／`preparation-review.json` 不覆寫；本文件不代 Tester／Reviewer 產生新收據或 approval。
- Human「準備完成後可即時配合」只是 availability，不是本段 fresh ready／提示觀察。E007 未 live、t0 未開始；45 分鐘／35 分鐘 cutoff 及 S04e 採用 gate 維持，正式 adapter 不前進。

## S03 r1 回修與獨立交接

RF-R01：公開 Human 觀察移除自由文字；有限欄位／actions／purposes projection、machine SHA 與 private observation SHA，export 敏感輸入負向測試。RF-R02：read-attempt marker 接同一 ProbeCore；先核可信 machine 身分／時間／形狀，guard／技術／invalid evidence 為無法判定。

Manifest amendment 已由獨立 Plan-Reviewer approved，僅新增兩個精確 r1 收據；v0 收據保留。r1 Tester approved 與 Reviewer approved 均不代表 profile renewal 或 DPK 採用成功。


## 2026-10-20 S04c／S04d 真實結果回寫

- Run：`experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/`。
- 台灣 t0 13:59:23.200801；原 cutoff 14:34:23、deadline 14:44:23 未變。首存 14:04:11.388 六欄相符；B profileDidNotChange 即停，未建立 phase 2 收據。
- Human 首存全段 0；B 設定／建置全段 0（非讀回）；清理全段 0。Human 已確認 Build 停止／私有專案關閉。
- UUID item 14:09:12.603 delete＋read-absent；owned private root 14:11:42.206791 移除，耗時 739.00599 秒。Apple assets 保留。
- final.index SHA `7e93e99c0035e5417aff7051689b2fc4973a60614532225ceb5bad03b3956b76`；Tester／Reviewer 與原 machine／Human 收據均未覆寫。
- Tester／Reviewer 明示 approved 只接受證據與安全收尾；experimentStatus=無法判定、renewalReadStatus=未執行、verificationClosureComplete=true、runnerTaskComplete=false、dpkAdoptionApproved=false。Current step 僅依其明示 workflow 記為 S04e human-check。
- 本次只維護 E007 README、requirements 研究現況及本 step 的事實／狀態，未重開 scope／九欄／manifest／gates。準備期「未開始」文字在歷史段落中保留原脈絡，非本輪現況。
- 文件回寫已由獨立 Plan-Reviewer 明示 approved、requiredFixes=[]；僅接受三檔事實一致性，仍停於 S04e human-check，不放行採用、重跑或產品實作。


## E007 第二輪方法 amendment：已獨立審查（開始前歷史紀錄）

- Human 已授權保留 topic 主軸，再做唯一一次方法明確的 E007 驗證；本次五檔文件修訂完成，無新檔、無 source／helper／測試修改，未 live、未操作 cache、未計時、未產生 approval。
- 方法：新 UUID／新 t0／新 45 分鐘（35 cutoff），A 首存與 Human 全段觀察後停／關 project；以 A embedded UUID 對兩個官方 cache 目錄的兩種副檔名作最多四個精確候選核對，先 exclusive 備份與恢復核對再暫移；原 certificate／精確 App ID／private group 不變，Human Xcode Build 一次。仍同 bytes／找不到安全範圍／超界即停，不再追查。
- 所有結果先原 A 精確 item cleanup／read-absent，再停 Build／關 project，逐檔恢復 cache bytes／metadata；衝突不覆寫，保留 backup／journal 並 human-check，禁止 export-clean。恢復核對及 Human 實際確認後才可 export／清 root；runner 不會自動守這個外部 cache 前提，明確是 Tester／Human 人工順序硬停止。
- Manifest 僅第二輪增加 `cache-transition.machine.json`／`cache-recovery.machine.json`；有限手動紀錄投影且明示來源，Tester 引其 SHA 與 final.index SHA，Reviewer 核對；既有 runner／final.index 及第一輪收據不改，不新增準備 revision。
- 已交獨立 Plan-Reviewer 並 approved 的精確五檔與九欄見 plan §6；受審範圍只限新受限方法、恢復與 evidence manifest，未重開產品 scope。當時仍需新的 Human 45 分鐘 fresh ready／免費來源／原 certificate 聲明，後已取得並執行；現在不再等待開始訊號。
- 第二輪真正不同有效 profile＋同身分／六欄／UX／精確恢復清理全部符合原判準，且 Tester／Reviewer 明示真成功、無重大問題時，S04e 依本次 Human「通過就回產品」條件授權記錄條件成立並回 S05，不再重問同一採用許可；現在不預填成功或 Human 觀察。第二輪仍無新 profile 即停止追查，是否接受未知並修 gate／換 store 由 Human 決定，不預填。


### RF-M01 受限回修與外部回查結果

- 外部獨立 Plan-Reviewer 明示 `needs-rework`，唯一 required fix 為 RF-M01：GUI DerivedData 未具體指定，可能把 CLI 舊 App 當 B／產生 root 外輸出。
- 本角色只補 E007 README §9.2 step 1／§9.3 step 8、technical-spec §5／plan V01 的一致引用與本段狀態。A 建置前在本輪私有 project-specific 設定指定 owned runroot/DerivedData、不改全域；A／B 各 Human GUI Build 一次，Tester 只 preflight／run，選各次實際 GUI built products 核對同 owned 輸出／來源／embedded profile。來源或輸出不明即停，不猜外部 DD、不另建或再 Build；原始路徑只私有 journal，有限布林放既有 tester-validation，無新框架。
- 回修時未改 requirements、source／tests／helper／manifest，未計時／live／操作 cache，未自判 required fix 已解除。後續原獨立 Plan-Reviewer 明示 approved、requiredFixes=[]，RF-M01 解除；此處只記錄外部 verdict，不再發明審查循環。
- 此為第二輪開始前的外部方法放行紀錄；當時尚未 live／t0，後續實際開始與停止結果如下，不表示現在仍待 fresh ready。S04e 採用條件未成立；Human「通過就回產品」條件授權未觸發。


## 2026-10-20 唯一額外第二輪結果回寫

- Run：`experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/`。新 Human「現在開始，能配合45分鐘」已實際使用。t0 UTC 06:58:27.242710（台灣14:58:27），原 cutoff 07:33:27／15:33:27、deadline 07:43:27／15:43:27 均未 reset／延長。
- A GUI Build 一次，project-specific owned DerivedData／實際 GUI product 來源／凍結 source／原 certificate 由 Tester 當輪核對；A save 07:04:39.596Z 六欄全 true，首段 Human 全程 0 提示，exact machine SHA `af8830c32241409bf9a125f02be1de8fccc764598bfca789eac182b603db826c`。
- 四候選全查、匹配一份；raw backup=1 bytes/hash 與 owner／mode／mtime／atime 相符，但 backup／restore-check 多一個系統 provenance xattr，原檔 xattrs=0。native raw data 確證集合差異，非路徑格式誤判；fullyVerifiedBackup=0、restoreCheckPassed=false，按前提在任何移出前停止。removed=0、refetch=0、B GUI Build=0、renewal read 未執行，phase 2 machine／Human sidecars 均不存在。不能說已 refetch 仍同 profile，不能外推普遍不可恢復。
- 備份非測量段 Human 只有限回報未見視窗，confirmedWholeStagePromptCount=null，並非全段確證零提示或 phase 2 觀察。
- 原 A UUID delete／read-absent 07:17:11.446Z 完成，Human 清理全段 0，machine SHA `26125b6a8f902420f9aa49497559226f32139bc3eb8c5c7fb10c169b4122afef`。原 cache 在 export 前 bytes／identity／metadata／xattrs 完全未變；requiredRestore=0、notRequired、restoreOperations=0，humanRecoveryConfirmed=false 是無須恢復確認，非待補。
- owned private root 07:20:14.453347Z（台灣15:20:14.453347）移除，elapsed=1307.210637 秒，符合原窗口；Apple assets 保留。七份 reviewed source／tests、第一輪全部 immutable receipts 未改。
- 第二輪 index SHA `874b50d21938d94606bd386edafe4c93cddbc3472af852598c4fad5af6f85548`；cache transition SHA `32a8fc78a9a645bb1fcf828820bccfffc59847e64b2f5fb46115dc0eb77b9c75`；cache recovery SHA `b817492a883c4d32b4cdd9c5106695b80777575accbbb49986a41b6be8cbc6b6`。兩份為 export 後追加的有限 manual-record-review 投影，Tester／Reviewer 另引 SHA，未改 index。
- Tester SHA `fcd273cd697a34f21d02536452805fcc588e24bad7dc143b5a6118d646a5b133`、Reviewer SHA `9cd28d7bb548849e310005c72d1811ccde889033bf41fff0f735532cd5d2457b` 均 approved、requiredFixes=[]，只接受證據與安全收尾；verificationClosureComplete=true 僅有限收尾，runnerTaskComplete=false、experiment=無法判定、renewalRead=未執行、dpkAdoptionApproved=false。
- Reviewer 明示 workflow=human-check／stopAutomaticProgress=true／thirdRunAllowed=false。唯一額外輪已用完，不再等新開始訊號、不自動第三輪。原條件式回產品授權未成立；當時 S04e 已詢問 Human 接受未知並修 gate、另選 store 或先停，後續實際回覆如下；原收據與判讀不改。
- 本次五檔僅事實回寫，待原獨立 Plan-Reviewer 有限核對；不改 scope／gate／manifest／source／原收據，不新增準備週期。


## Human 新決策與唯一 gate amendment（待獨立回查）

- 實際 Human 原文：「接受 profile 更新後尚未驗證的限制，修訂 gate 並繼續產品實作」。所答問題明示「只解除 renewal 必須先驗證的 gate，其他驗收維持，仍保留連線失效處理與重新授權路徑」。這是後續新的明確決策，S04e Human completed；不再等待採用／fresh 45 分鐘訊號。
- 只接受同身分 profile 更新後讀回尚未驗證的未知，受限採用 DPK；E007 兩輪仍無法判定、phase 2 未執行，immutable Reviewer 當時 human-check／dpkAdoptionApproved=false 不改，後續接受決策單獨追溯。
- 有效 embedded profile、同 Mac／GUI user／App ID／private group／原 certificate／固定位置維持；七日到期與過期不可用、已過期恢復／cert rotation／公開發行未驗證界線不擴大。產品 V06–V09、首次≤1／fresh 0／rebuild 0、輪替後新程序、真 GitHub 與受控時鐘分列、雙 client lifecycle／denied 不覆寫／accepted rotation 保存失敗停 provider／明確失效與 reauth 全保留。
- Current S05 pending：只待獨立 Plan-Reviewer 快速回查本 gate delta 與五檔事實一致性，approved 後直接交既有 S05 Implementer。不是新 phase／gate，不重問採用，不跑第三輪，不把實驗或產品未知寫成成功。
- 本次精確五檔修訂，不增檔／改 source／helper／immutable 收據／Git；執行細節及原 scope／manifest 不變。尚未產品實作或宣稱 refresh／端到端驗證完成。

### S05 Implementer 開工事實

- 上游獨立 Plan-Reviewer 已明示 gate amendment `approved`、`requiredFixes=[]`，准予原 W02／W03／M01／M02；此處引用外部結果，不自行批准。
- 僅 feature worktree 進行指定 integration source／tests；採 swift-tdd，建構與測試不進行真 Keychain credential operations／GitHub network（production 建構可用 OS 安全亂數），不改寫 E007 證據。


### S05 manifest amendment：精確靜態隔離測試維護（待外部回查）

- Implementer 發現既有 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `expectedPaths`／import allowlists 未包含已核准 W02 四 source；該 test 原 R04 唯讀，依 plan §1 交 Plan-Creator 作此精確 manifest 修訂，未由實作者自行放寬。
- M02 新增該單一 exact test 路徑，R04 明確排除此受限例外。只新增 W02 四條 expectedPaths，HTTPClient 只新增 factory／session，Security 只新增 factory／DPK store（聯集三個 source）；legacy 精確斷言與其他檔案禁用 Security、其他隔離斷言／parser／test 全保留。不新增 session Security 例外、不改 runtime policy。
- 本角色只改 technical-spec 的驗證維護說明、plan manifest／R04／精確範圍與本 append；source／test 全唯讀，未執行測試、Git 或產品實作，未覆寫 Implementer 正在維護的 S05 內容。
- 本 delta 待獨立 Plan-Reviewer 回查，尚未自行產生 approval。回查後原 Implementer 先示 red 再同步精確 allowlist 得 green，獨立 Tester 回歸 suite；沿原 S05／V08，不新增 phase／gate、檔案或產品契約。

### S05 Implementer 交付事實（待獨立 S06a／S06b）

- 四個新增 production 檔完成 configuration redaction、public factories、actor 一次性初次授權與 DPK pair adapter；concrete transport／Security／codec 皆 internal。Provider 只 additive enum／唯讀 disposition，不改現有 lifecycle policy、ports、clients 或 package。
- 依外部 Plan-Reviewer 對最小 manifest amendment 的 `approved`／`requiredFixes=[]`，同步 StaticIsolationTests 的四個精確 paths、兩個 HTTP import paths，以及兩個新增 Security import paths；原 legacy imports 精確斷言、其餘禁止條件與 parser 保留。
- Red：新增 factory test 的 `swift test --filter GitHubOAuthFactoryTests` 在尚未存在的四個 public API 名稱編譯失敗，可歸因於能力缺席。補實作後 callback／exchange／DPK tests 執行；milliseconds oracle 原以十進位常數 123456／234567 比對，實際 Foundation Date 數字為 123455.9999704361／234567.00003147125。測試改為比對原 Date 的 `timeIntervalSince1970 * 1000`，並保留六欄與 Date roundtrip 精確相等；未因該浮點 oracle 調整 production codec。
- Static red：第一次 `swift test --filter GitHubIntegrationTests --skip KeychainTokenStoreTests` 為 209 tests／22 suites，僅舊 path／imports allowlist 有 5 issues。取得上述獨立 amendment 後精確同步，最終同命令 **211 tests／22 suites pass**；新增 provider 觀測案例合併同一 test，額外 codec／form cases 按目前 suite 數列計。
- Green：`scripts/check-github-integration-consumer.sh` **13 tests／3 suites pass**；以正常 import 建構 configuration／stores／session／fetcher，並核對 Sendable、provider disposition。精確 11 個 changed Swift files 的 `swift format lint --strict` exit 0、`swiftlint lint --strict` **0 violations**；`git diff --check` exit 0。沒有放寬或修改工具設定。
- Fake-only 覆蓋：state／S256、exact callback scheme／host／port／encoded path、userinfo／fragment／重複 query 拒絕、code／error 排他、denied／cancelled／expiry、latch 並行 complete／一次消耗、late cancellation 不丟 accepted response；30 秒 ephemeral／無 cookie／cache與有限 exchange errors、六欄／正數期限／有限 receipt、form escaping。DPK 每項 query／add／update selectors、完整 update-first／absent add／duplicate 單次 update、共 actor 序列化、嚴格 version 1／client ID binding／expired 日期、missing／denied／unavailable／corrupt／identityMismatch、整筆替換與新 adapter 六欄還原。Provider 純觀測零 load／save／fetch side effects、既有 401／single-flight／accepted rotation persistence failure 回歸保留。
- 真 Keychain credential operations／GitHub network 未執行；DPK tests 全注入 fake Security，OAuth tests 全 fake exchange；public 建構僅允許 OS 安全亂數，不操作 credential。原真 KeychainTokenStoreTests 明確排除。本結果不證明真儲存、fresh process、簽章、提示 UX、真 GitHub／遠端 refresh 或 profile 更新，後續 V06–V09 與既有 Human 未知限制維持。
- 未 commit／push／開 PR；本角色交 S06a 獨立 Tester，未自行產生 approval。


### S06a Tester 獨立交付

- 依 S05 明示完成交接，獨立執行 integration fake-only 211 tests／22 suites、正常 import consumer 13 tests／3 suites，均 exit 0；非引用作者自驗。精確 11 Swift 檔 format／SwiftLint strict 0 violations，diff check 0。
- 已逐項核對 callback／PKCE／single-consumption／有限錯誤、完整六欄 strict codec／milliseconds oracle／同 ID／DPK scoped query、provider 純觀測與既有雙 client lifecycle，以及已批准的 StaticIsolation 精確例外。詳見 [contracts](evidence/contracts.md)、[compatibility](evidence/compatibility.md)，附 source／test hashes。
- Tester verdict=approved、requiredFixes=[]；只交既定 S06b 獨立 Reviewer，不代其 approval、不進 S07。production RNG 允許；沒有真 Keychain credential operations／GitHub requests，不稱所有 Security API 零呼叫。
- V06／V07、產品 V04／V05／V08、V09、signed host／提示／真遠端 refresh／產品 E2E 保持未驗證；E007 unknown 與 Human 唯一接受限制不改。僅新增兩份指定 evidence、更新本 S06a 事實及當前路由，沒有改 source／test／Git／Apple assets。


### S06b Reviewer 獨立交付

- 逐行核對四新增 production／三新增 tests 及 provider／consumer／StaticIsolation additive diff、既有 transport／DTO 邊界；兩份 S06a 收據與五 production／六 tests 目前 hashes 全相符，唯讀 diff check 0。沒有重跑 green suite、改 source／tests／設定或真 credential／GitHub operations。
- Verdict=approved、requiredFixes=[]，詳見 [S06b integration 審查](evidence/final-review.md#s06b-integration-審查2026-10-20-utc-0750)。僅放行既定 S07 W04／W05；不批准全 topic、不代 S08／S10 或 Human 驗收。
- 既有 generic HTTP Sendable warning、fake-only 與產品 V04–V09 未驗證界線如實保留；E007 兩輪 unknown 與 Human 唯一接受限制不改。S07 仍須實作 settlement／全 reauth retirement／repair table／test-mode safety，再依原步驟交獨立 Tester。

### S07 Implementer 開工事實

- S06a Tester／S06b Reviewer 均明示 approved、requiredFixes=[]，僅引用既有外部 verdict，進入原 W04／W05；未重開 S05 public API／DPK 採用或 E007。
- 本角色僅 feature worktree 的指定十二檔與本 S07 工作記錄；unsigned host／fake-only hosted tests，不進行真 Apple 設定、credential 或 GitHub 操作。

### S07 Implementer 交付事實（待獨立 S08a）

- 僅 W04 十檔／W05 兩檔與本角色帳本。建立 macOS 15／Swift 6、non-Sandbox、`ENABLE_DEBUG_DYLIB=NO` 的 Rivet App＋hosted XCTest target，root local package 的 GitHubIntegration／RivetPresentation products；Team／profile／固定安裝位置保留私人注入，未填入 Apple 身分或實驗資產。未修改 package、S05 sources／tests、其他 BC／Presentation 或工具設定。
- Root 在建構任何 live dependencies／restore Task 前檢查 `RIVET_UNIT_TEST_MODE=1`；shared TestAction 明訂此值，test root 只顯靜態內容。Hosted audit 確認 live construction／credential operation／network operation entries 三項均 0；所有實作測試用 fake stores／fetcher／authorization／listener-ready 事件，不執行真 GitHub 或 Keychain operations。
- Coordinator 唯一 admission gate 保留實際 unstructured operation Task 到 `Task.value` settled；取消 caller／operation 不提早移除 handle。舊 refresh 與 accepted rotation save 各由 latch 暫停，取消後 config write／reauth 全回 operationInProgress 且零新設定／授權；release 後才准新 bundle，最終仍是新 grant，無舊寫覆蓋。
- 同 App repair table、可信 credential ID 權威／未知原 App 明確確認、denied／unavailable explicit retry 不覆寫、configuration save 成功才授權皆完成。暫時 prepare retry 同 provider；stopped／authenticationRequired 不繞過；每條 reauth／repair 先退休舊 provider／scope，取消／grant／save failure 不復活，新完整 bundle 保存後才新建。GET /user 固定 headers、僅可信 200 account；新授權清除舊帳號，失敗不呈現歷史成功。
- Relay 綁 127.0.0.1 動態 port，ready 後建立既有 session／開瀏覽器；GET exact callback path、8 KiB limit、5 秒 connection read timer、五分鐘等待、其他 path 靜態 404；不輸出 target／query。靜態結束回應 send 完成後才交 callback，所有授權出口關 relay／cancel session。Presentation 是 display-ready input／intent 與 SecureField，無 OAuth／BC imports；僅 AppKit 窄橋是開啟預設瀏覽器。
- Red：`xcodebuild test -project apps/Rivet/Rivet.xcodeproj -scheme Rivet -destination 'platform=macOS,arch=arm64' -derivedDataPath <private-scratch> CODE_SIGNING_ALLOWED=NO -quiet` 已到 hosted test compile，因缺少 RivetComposition／RivetDependencyAudit／LoopbackRequestParser 而失敗，非簽章或環境失敗。補實作後初始 2 tests green，擴展契約後最終 xcresult **23 passed／0 failed／0 skipped**。
- 最終 hosted 命令同上加 `ONLY_ACTIVE_ARCH=YES`，`xcodebuild build` 同 project／scheme／destination／scratch／unsigned settings 亦 exit 0。`swift test --filter 'GitHubIntegrationTests|RivetPresentationTests' --skip KeychainTokenStoreTests` **226 tests／25 suites pass**，明確排除既有真 Keychain tests。S07 八個 Swift 檔的 `swift format lint --strict --recursive` exit 0、`swiftlint lint --strict` **0 violations**；`plutil -lint` project／Info／entitlements OK，`git diff --check` exit 0。
- TestCase：完整 fake 初次設定／授權保存／新 coordinator 還原；repair table 各分類、同 provider retry／stopped、所有失敗 reauth retirement、accepted callback 清除舊顯示／禁用取消、refresh/save settlement、GET headers/status、relay 限額／exact origin-form/path／單次交付／取消與受控 session deadline；無 sleep 驅動測試。真 NWListener/socket／browser、有效 profile／固定位置／fresh process／提示／真 DPK／真授權及遠端 refresh 仍待 V06–V09，不以 mock／unsigned build 冒充。
- 私有 generated DerivedData／xcresult 與有限工具原始 logs 未入 repo；沒有 commit／push／開 PR。本角色只交既定 S08a 獨立 Tester，未自行產生 gate approval。


### S08a Tester 獨立交付與 bounded required fix

- 獨立 hosted xcresult：23 passed／0 failed／0 skipped；root GitHubIntegration＋Presentation 226 tests／25 suites pass；unsigned build、八 Swift strict format／SwiftLint 0、project／Info／entitlements lint／diffcheck0。未引用 S07 作者自驗替代。初始未限 arch 命令失敗已分類 environment，原 arm64／ONLY_ACTIVE_ARCH 精確條件重驗成功，未改 source。
- 假資料驗證 settlement（refresh／save 雙 latch）、same provider retry、全部 reauth／repair retirement、repair table、test-mode entries 全零、relay bounded parser／有限錯誤與account probe，詳見 contracts.md／compatibility.md 的 S08a append。
- 整體 verdict=needs-rework、requiredFixes=[RF-P01]：coordinator 預設 Date.init 且 composition 無正式受控 expiry／有限驗收途徑，無法依 V07 以正式入口觸發真 refresh並證明完整輪替保存／新程序還原。只交既有 host／coordinator／原 tests bounded fix，正常真 clock／token receipt／lifecycle 不變；不新建 probe、不改OS clock或已保存日期。若超契約先回 planning，不自行擴張。
- fake-only 部分 approved；S08a 未完成，不越 S08b／S09。storage-live.md／product-e2e.md 為準備、notExecuted，所有 prompts=null；尚未啟動 live host／browser／credential operations或要求 Human 秘密。原免費 Team／certificate、private單一固定位置與有效profile等要在修正後由 root協調真人。
- 只新增兩份指定 live pending evidence、append兩份舊 receipts與本角色 step；本輪 Xcode 新生 project lock經 provenance核對後精確移除，rootlock不動；未改 source／tests／Appleassets／Git。

### RF-P01 Implementer bounded fix（待原 Tester 獨立回查）

- 依 S08a `needs-rework`／`requiredFixes=[RF-P01]`，僅改既有 RivetApp／coordinator／coordinator tests 與本記錄；S05／其他 source／public API／日期／OS clock／既有收據不動。此處只交付實作與自驗，不自行解除 required fix 或批准 S08a。
- 明確 opt-in：私人啟動環境 `RIVET_GITHUB_VALIDATION_MODE=expire-restored-once`，另給 `RIVET_GITHUB_VALIDATION_RECEIPT=<private-new-file>`；父目錄必須為當前 user 擁有、非公開權限的 directory，目的檔不存在。未設定 mode 為正常真 clock；unit-test-mode 先於驗收配置與任何 live dependency，完全忽略此 opt-in。非法設定停止配置，不在一般 UI 加驗收控制。
- 限已有可信、同 ID 保存 credential 的首次 restore，將 provider 判定 clock arm 到其原 access expiry；不依 clock 呼叫次數／不永久加時間。原 production fetcher 完全沿原 Date.init receipt。只在原 fetcher 接受完整新 bundle、原 store 真保存成功後，於 provider 判斷新 expiry 前解除控制回真時間；save failure 保留既有 stopped 契約，reauth retirement 亦結束本次控制。沒有改寫 bundle 日期、額外 credential read 或自動 retry。
- 同檔有限 private observation 記 schema／mode、真 PID＋觀測 UUID、refresh attempts／accepted／save counts、完整六欄 bundle SHA-256、token-pair-changed／clock-release／account-confirmed 布林；沒有 token／secret／code／callback／路徑／原始 response。operation 真 settled 後以 O_EXCL／O_NOFOLLOW、0600 匯出一次，既有檔不覆寫；未產生完整收據不能算驗收證據。
- 後續真 fresh-process 驗收：前段 controlled receipt 須 accepted=1／save=1、accepted digest=保存 digest、pair changed、clock released／account confirmed；真正退出後，移除 expiry 控制或使用 `RIVET_GITHUB_VALIDATION_MODE=observe` 配新的 private receipt，核對新程序恢復／provider-load digests 等於前段 saved digest、forced=false／refresh=0。此處只是可操作途徑，尚無真人結果；真程序退出／新啟動、DPK／GitHub來源仍須 Tester 外部 provenance，不以觀測 UUID或兩個 fake coordinator 冒充真新程序。
- TDD red：原 hosted 命令新增六個 RF-P01 cases，缺 GitHubExpiryValidation 型別而 fail。Green：同正式 scheme、arm64／ONLY_ACTIVE_ARCH=YES、CODE_SIGNING_ALLOWED=NO 的 `xcodebuild test` exit0，最終 xcresult **29 passed／0 failed／0 skipped**（原23＋新增6）。覆蓋 explicit off／test-mode、12次 clock 讀取不耗用控制、真 receipt 時間的新 token 於保存後可用且只 refresh一次、accepted save fail 不循環／reauth 可回真時間、observe新 coordinator 的完整 hash 還原、有限私有收據／0600／不可覆寫。新 coordinator 測試明記仍在同 hosted process，真 PID 相同而 observation ID 不同，不聲稱 fresh-process pass。
- 精確三個改動 Swift 檔 strict format exit0、SwiftLint **0 violations**、diff check0。沒有重跑已通過且未改的 root suites／新增框架或檔案；只清本角色 Xcode 自動產生的 untracked project lock，root lock 不動。實作交回既有 Tester；真 DPK／GitHub／remote refresh／Human 提示與 profile 前提仍 pending，未 commit／push／PR。


### S08a RF-P01 獨立重驗與真人前停點

- 原Implementerfinal後鎖三檔hash，獨立hosted29passed／0failed／0skipped、unsignedbuild與三檔strictformat／SwiftLint0／diffcheck0；六新增cases及productionclock／finiteprivate receipt逐項核對，RF-P01 approved、requiredFixes=[]。沒有重跑未改root226或自稱真refresh。
- Human所選個人Applications的Rivet.app唯讀preflight不存在，parent是userowned非symlink目錄，位置hash見storage-live.md；尚未寫入安裝位置。已備妥0700ownedprivateprojectcopy／manifest，只rebaselocalpackage，其他sourcecopy hashes相符，私有provenance可核。
- Current S08a human-check：等真正Humanready再選原Team／certificate、正式profile／AppID與project-specificDD並分段驗收；V06／V07仍notExecuted、prompt=null，不進S08b／S09。只是既定真人邊界，未新增gate。


### 正式首段與 RF-P02 停止

- Human真正readyUTC08:25:01後，私有project／ownedDerivedData／Signing畫面到位。首段實際回「0次可核對簽帳並建置」，receivedAtUTC08:29:26；只綁setup／Team段，不當Build／首存全段0。
- CUA核對PersonalTeam／AppleDevelopment／Signing無錯誤，source／linkedpackage hashes全符、產品ID固定；GUI⌘B卻請求x86_64而packages僅arm64，BuildFailed。未Run、未credential／browser、未新cert／安全設定操作。
- Tester needs-rework、requiredFixes=[RF-P02]：既有project Debug native-arch預設缺口，交原Implementer，受限同project設定／既有成功ONLY_ACTIVE_ARCH條件，不改runtime或sourcepath。RF-P01保留已解除；停止再build，Build段promptcount=null待Human。細節見contracts／compatibility／storage-live append。

### RF-P02 Implementer 最小建置設定修正（待原 Tester GUI 重驗）

- 上游 S08a Tester 明示 RF-P02 needs-rework：正式 GUI Debug Build 嘗試 x86_64，但 local package 為 arm64；未再 Build／Run 或啟動 credential／browser。此處只修正式 Debug configuration 缺漏，不重開採用、Team／App ID／certificate／runtime 策略。
- 自身先查正式 project 的解析設定：正常 My Mac destination 下 ARCHS=arm64 x86_64、NATIVE_ARCH=arm64、ONLY_ACTIVE_ARCH=NO，吻合外部 GUI failure。唯一 source delta 為 project 共用 **Debug** configuration 加 `ONLY_ACTIVE_ARCH=YES`，App／hosted target 繼承；沒有硬鎖 arm64、沒有改其他設定或任何 Swift／test／package。移除此單一欄位後 SHA 回到原 `f4ecf63c57f13ed7f4e3087f3a7fe4d2f861f946e0930d86d6d00cc235f06d15`，確認只一設定。
- Green：`xcodebuild build -project apps/Rivet/Rivet.xcodeproj -scheme Rivet -configuration Debug -destination 'platform=macOS' -derivedDataPath <private-scratch> CODE_SIGNING_ALLOWED=NO -quiet` exit0；**未傳 arch／ARCHS／ONLY_ACTIVE_ARCH override**。同參數 showBuildSettings 為 ARCHS=arm64／NATIVE_ARCH=arm64／ONLY_ACTIVE_ARCH=YES，built Rivet binary 的 lipo 為 arm64。`plutil -lint` project OK、`git diff --check` exit0。這是 unsigned／目前 Mac 的 Debug 證據，不是 GUI／signed／Intel 或 Release 驗證。
- Project SHA `ddf42ca3511f297456cb82c30b8c1a74413da785c103a4409ebc6fff058df62f`。本次低風險設定沒有鏡像 unit test，也未重跑未改的 29 hosted／package suite。僅清本角色自生 untracked project lock，root lock不動。
- 已停止寫入交原 Tester：只將此一 Debug 設定同步私有 project，保留 Human 已設定的原 Team／App ID／certificate，再由正常 GUI Build 驗證。未自行解除 RF-P02／批准 S08a，未操作真 credential／GitHub、未 Git。


### RF-P02 正常 GUI 獨立解除與正式首入口

- 僅一個DebugONLYACTIVE欄位的formal／privateobjectdiff皆核實，CUA實際解析Yes後GUI⌘B succeeded，無外部override；真signedGUI產物與source／profile／原certificate／AppID-group／目前MacprovisioningUDID／nativearm64／Swift6等前提通過。RF-P02 approved、requiredFixes=[]，非產品E2E批准。
- Human成功Build段0，receivedAtUTC08:37:40；只綁本段。安裝到再核absent的原固定位置，copyhash／signature全符，首launch與唯一精確安裝程序確認、初次設定畫面可操作。agent未輸入secret／點登入／開browser，首storage段prompts仍null等待Human。
- S08a human-check，V06／V07尚未完成，不進S08b；所有rawpaths／AppleIDs／profile／程序與logs只私有manifest，public僅finitehash／bool／實際Human觀察。


### S08a 真首連線與 same-binary fresh-process 機器結果

- Human首次launch／config／browser→App結果完整段0提示，receivedAtUTC08:44:52；App正式有效帳號由CUA確認，不單靠browser結束字串。
- 正常Quit並核原精確PID退出；同binary／同固定位置open--env observe新程序（非-n／globalenv），真新PID不同且安裝executable唯一。直接有效同帳號，0600receipt完整六欄restore/providerloadhash相等、forcedfalse／refresh0／save0／accountConfirmed。初normaldigest未測保留。
- 此freshprocess段Human提示仍pending／null；等待觀察回報才真正rebuild，不宣稱V06／V07全pass、不前進S08b。私有manifest保存PID／observationUUID／rawpaths，public只finitehash與booleans。


### S08a same-binary全段0與true-rebuild待Human

- samebinaryfresh段Human實際「皆為0次」，receivedAtUTC08:49:29，完整段0已到。
- 真正GUIclean核舊DDproduct消失後再BuildSucceeded，actualactivitylog重compile/link/sign四source、新binarybytes不同，所有同identity／原certificate／validprofile／macOS15Swift6/nativearm64等前提通過；未拿舊App充數或測renewal。
- 舊安裝provenours／原PID退出、ownedbackup保留後，同freeze位置換新binary；新PIDobserve有效同帳號、六欄hash與先前fresh相同、refresh/save0。Humanrebuild完整提示仍pending／null，等回覆才controlledexpiry真refresh；S08a仍human-check，未全pass。


### S08a rebuild全段0與受控expiry真refresh結果

- 真rebuild全段Human0，receivedAtUTC08:53:29；不外推renewal。
- 正常Quit／精確PID退出後，同已重建binary同位置expire-restored-once真新程序，原productionfetcher真accepted1／真DPKsave1、accepted=persisted六欄hash且與舊不同、tokenpairchanged；保存後clock回真時鐘、正式API同帳號有效。OSclock／bundle日期未改，不稱自然八小時。
- 現有receipt不含個別access/refreshhash，未額外讀rawbundle或捏造個別變化。此controlled段Human提示pending/null；rotation後observe新程序尚未執行，S08a仍human-check，不前進S08b。


### S08a 最終 Tester 交付（停止寫入，交 S08b）

- 最後durability完整段Human實際「0次授權畫面」，receivedAtUTC08:58:02，count0。五主要產品live路徑真實完成且各Human0，真資料與controlledexpiry／fakecontract分列，正常初digest未測／E007unknown等限制保持。
- Tester verdict=approved、requiredFixes=[]；RF-P01／RF-P02皆已獨立解除。S08a completed，current S08b pending，只交獨立Reviewer；不代S08b或S11批准、不提前S09／Git發布。四份evidence最新結論／有限hash鏈可核，rawPID／paths／Appleassets／receipts留原ownedprivate manifest供核證。
- 保留當前可用installedApp／liveDPKcredentials，不Quit／delete／rollback。privateownedproject/DD／舊Appbackup／公開DERcopies／logs／receipts先保留供Reviewer，後續按證據需要列精確cleanup候選，不含Appleprofile/certificate資產。


### S08b Reviewer 獨立交付

- 受限 source／tests／配置、RF-P01 時鐘與 finite receipt、RF-P02 Debug 單欄及現有 ownership 完成獨立審查；目前產品 12 leaves／59 linked hashes、private copies、四真程序 receipts／PID／完整六欄 digest 鏈、兩 GUI activity logs、installed signature／有效 profile／group／Mac 授權及五段 Human0 相符。
- 明示 verdict=approved、requiredFixes=[]；詳見 evidence/final-review.md S08b。沒有 source／tests／Apple assets／credential／Git 操作，沒有重跑已 green suite，也不把受控 expiry 或 aggregate token-pair 變更說成自然到期／個別 token hashes。
- 只放行既定 S09 docs／drawings／tool evidence；V09、S10 最終審查與 S11 Human 整體接受仍待完成。E007 unknown／已接受限制與原免費 profile 有效期界線維持，不自行清理目前可用產品與 live credential。


### S09 最小工具 manifest／執行時機修訂（待獨立回查）

- S08b 的外部 Reviewer `approved`／`requiredFixes=[]` 與 Current S09 pending 均保留。本次 Plan-Creator 只補既定 W07 必要作者輸入及既定 S09／S12 的輔助工具時機，不代 Implementer 製圖、不產生 gate approval。
- Architecture-canvas 技能要求只 author scene → validate → build，不能手寫 viewer；W07 唯一新增精確 leaf 為 `docs/architecture/diagrams/github-persistent-connection/scene.js`，與既定 `responsibility-canvas.html` 同目錄。Bundled build 的明確 `--out` 保持原 HTML 名稱；canvas 截圖只留 proven-owned scratch，不授權其他 repository outputs。
- PR Lens 0.11.0 的 graph 需要真實且不同 base／head commit SHA；S09 尚無 topic commit 時，既定 tool-evidence.md 先記具體 source／working-tree diff fallback 與 code commit 後補的事實。已授權 S12 在既有 gates 允許後，依 staged 語意／message 檢查先建立真 source／topic commit，再以真 base／該 head 製作 bounded code-change map、validate／render／核 output manifest；後續 docs／evidence topic commit 補真 IDs／manifest hashes／coverage，然後 push／Draft PR。Map 不聲稱涵蓋後續 docs commit，工具不可用仍走既有具體 fallback。
- Archify required QA、V09、S10／S11 與最終 Human review／不 merge 邊界不改；不將輔助工具時機澄清當新 gate，不預填任何圖／PR Lens／Graphify 成功。

| 欄位 | 本次文件 delta |
|---|---|
| In-Scope | W07 唯一 scene.js 精確 manifest、canvas 重建方式與真 code commit 後的 PR Lens 時機澄清 |
| Out-Of-Scope | 產品／API／架構／驗收條件／UX／採用 gate 變更、source／圖實作、實驗、Git 操作 |
| ReadOnly | 全部 production／tests／immutable evidence、skills／工具 config、requirements／technical-spec；其他長期文件與圖 |
| Written | 無；本次只授權後續 W07 的上述精確 scene leaf，不在此建立 |
| Deleted | 無 |
| Modify | `plan/github-persistent-connection/github-persistent-connection.plan.md`、`plan/github-persistent-connection/github-persistent-connection.step.md` |
| Goal | 既定工具產物可重建、來源與 commit 範圍真實，不阻斷原 topic 結果 |
| Non-Goal | 重設計、縮減驗收、手寫 viewer、捏造 commit／工具 pass、增加 phase／gate |
| TestCase | 獨立 Plan-Reviewer 僅回查本 delta；本角色未跑測試、未自審／approve，technical-spec 無必要引用變更而保持原檔 |

- 2026-10-20，Plan-Creator：本次只寫上述兩檔並交獨立 Plan-Reviewer；S09 工作尚未完成，保留待 Implementer／Tester／Reviewer 的既有順序。


### S09 Implementer：文件、責任圖與流程圖交付（2026-10-20）

- 引用外部既有 verdict：S08a Tester、S08b Reviewer 與 S09 精確 manifest amendment 的 Plan-Reviewer 均 approved／requiredFixes=[]；本角色只完成 W07／M03，不自批准 S10／S11。
- ReadOnly：所有 source／tests、四 formal 契約（除自身 step）、不可變 S08 evidence／E007、Apple assets／現有產品與 live credential。Written 僅 W07 核准的 diagram leaves；Modify 僅 README、design-principles、architecture README、github-oauth-dual-client 與自身 step。Deleted 無 repository 檔；沒有 Git／push／PR 或 Swift 重測。
- 四份長期文件補上正式產品入口、DPK pair schema／strict decode、App composition 的唯一 provider／scope／operationTask、settlement admission、repair／reauth／no resurrection 與最小 GET/user。保留 non-BC ownership、既有雙 client／generic HTTP auth 邊界；不把 PR 業務整合加入 scope。
- 真實結論只引用既有 S08：五條 live 路徑均各自 Human0；controlled expiry 只改 provider 判定，真 GitHub refresh accepted1／DPK save1，後續 fresh process 完整新六欄 hash 相符。明標非自然到期、初始正常 process digest 未觀測、只證 aggregate tokenPairChanged；profile renewal 仍 unknown／Human 例外、有效 profile／原身分前提及未驗證分發維持。
- Canvas：`scene.js` 純資料，5 bands／17 boxes／16 edges；`node <canvas-skill>/scripts/validate.js .../scene.js` exit0、0 errors／0 warnings；bundled build exit0，未手寫 viewer。最終 HTML 真 Chrome headless 1440×1100、全新私有 browser profile、有界 2000ms 初始化後擷取並用 view_image 親看；最終截圖私有 basename `rivet-s09-canvas-final.png`，不新增 repo leaf。
- 三張 Archify：`authorization-sequence`／`restore-refresh-reauth-sequence` type sequence、`connection-lifecycle` type lifecycle。每張執行 `node <archify-skill>/bin/archify.mjs validate <type> <relative-json> --repo-root . --json`，showcase 9/9、0 errors／0 warnings；再 deliver 至同 basename HTML，以原始 stdout 存 `.delivery.json`，原生 repository-relative paths，沒有 projection／手改 receipts。工具 pin2.16／runtime2.16.0-dev.0。
- 每張 deliver 後 `visual-check <relative-html> --repo-root . --json` exit0；1440×900、1600×1000、1920×1080、2048×1320 四尺寸無 overflow，最小／最大各 light／dark 共12張實際 PNG 已全部逐張 view_image 親看。最初 sequence 的小 viewport overflow 如實診斷並重建作者 revision／freeze，未縮字或裁切 viewer；lifecycle clearance 逐個收斂至0。作者繁中、固定 Viewer UI／HTML lang English fallback，原生 visualReview=pending 保留，詳見 BUILD／visual-review。
- 最終 JSON／HTML／delivery SHA 鏈核對一致，四尺寸數量及 pending 字樣機器核對通過；七份 Markdown 的 relative links 皆存在，無 trailing whitespace；核准圖目錄與四長期文件的本機絕對路徑／raw token／private-key pattern 掃描零命中。工具收據保持原生真實，不用截圖遮掩失敗。
- PR Lens0.11.0 runtime/help 可用，no-config；S09 尚無 topic source commit，不造假 base/head。依已核准順序將真 change-map validate/render 留 S12 code/topic commit 後；本輪 bounded direct source／working-tree 對照 fallback 已列於 tool-evidence。Graphify0.9.73 每次 invocation 均 GRAPHIFY_NO_AUTO_REFRESH=1；指定既有 graph 路徑不存在，改 targeted rg／source verify，不建 graph／hooks／config／stamp／外連。
- 精確 artifact／hash／命令／限制見 [BUILD](../../docs/architecture/diagrams/github-persistent-connection/BUILD.md)、[visual-review](../../docs/architecture/diagrams/github-persistent-connection/visual-review.md)、[tool-evidence](../../docs/architecture/diagrams/github-persistent-connection/tool-evidence.md)。S09 completed，交 S10a Tester 再 S10b Reviewer；S11 Human 接受仍 pending。從本次交接後停止本角色 step／artifact 寫入，供獨立驗證。


### S10a 第一輪獨立結果：RF-D01

- 真／controlled／fake／E007unknown與Human例外分列、69sourcehash與四live有限receipt鏈核對；無Swift／live重跑。三Archify重新showcase9/9零錯警、ownedscratch四尺寸visualchecks全0、原12PNG親看；Canvasvalidator0/0、scratch重buildbyteidentical並親看真截圖，canonical32檔未改。79localLinks／privacy／whitespace通過，pinnedPRLens／Graphify版本與sourcefallback核實。
- Tester needs-rework、requiredFixes=[RF-D01]：Canvas原scene有session→stores錯誤直接關係，與session只交回bundle／Coordinator.authorize才保存的既定source責任衝突。只交原Implementer在既有scene改正coordinator→stores、重新Canvasvalidate/build／實際截圖與既有hash證據；不改source／新gate／公開發布。
- S10b未進，S11Humanvisual／最終接受與S12真commit後PRLensmap仍pending；本角色未改原作者visual-review或代Human批准。


### RF-D01 Implementer bounded fix（2026-10-20）

- 引用外部 S10a needs-rework／requiredFixes=[RF-D01]；source 核對 session.complete 只 return bundle、Coordinator.authorize 才 credentialStore.save。原 Canvas session→stores 直接箭頭錯誤，修正 scope 僅此責任關係。
- scene 的該 edge 改 Coordinator→stores，且 pts 從 Coordinator 左邊界 [200,590] 經左 gutter [136,590]／[136,1030] 到 stores 左側 [196,1030]，加入「初次授權 bundle 完整保存」。不是只換 from ID；原 session→stores 關係與幾何已移除，沒有重複 Coordinator→stores。
- `node <canvas-skill>/scripts/validate.js docs/architecture/diagrams/github-persistent-connection/scene.js` exit0：5 bands／17 boxes／16 edges、0 errors／0 warnings；同 BUILD 命令重新 bundled build exit0，無手改 viewer。新私有 Chrome profile、1440×1100／有界 2000ms 初始化擷取真 PNG；已 view_image 親看箭頭起點、終點、gutter label、完整圖無裁切。
- 最終 scene SHA `187bba542b1e1f2b17e960a74863b39b5e0a2633d4655bfb2d638f27ceff95d3`；HTML SHA `61a8f9b558407ae9d1d04c63b56221325d2d666cd660fa110ef80cd4763e69ae`。BUILD 的兩 hash 與實際 bytes 一致；visual-review 僅追加本次真 QA，不改三張 Archify／原凍結收據。tool-evidence 不需變更。
- 新私有 screenshot basename `rivet-s09-canvas-rfd01.png`，SHA `b315a4a4b32929ec9915b775ccb9fa9007ca2be9da8e4fad700c96e753685d10`；新 `rivet-s09-rfd01-delivery-pointer.json` 以0600／O_EXCL建立並綁scene／HTML／screenshot，原截圖與pointer完全保留。未掃他人 scratch、未觸 App／credential。
- 本輪 Modify 僅 scene.js、responsibility-canvas.html、BUILD.md、visual-review.md、自身step；沒有新repo leaf／刪檔／Git／產品或測試source修改／不相關重測。相關Markdown links／privacy／whitespace issues=[]。三張Archify先前已通過結果保持，不重跑。
- 本角色交回同 Tester bounded retest；RF-D01 未自行標解除，S10a needs-rework 保留至外部 verdict，S10b／S11 不提前。此刻停止所有 repo／step 寫入。


### S10a RF-D01 獨立解除與最終交付（停止寫入）

- 只1條edge從session→stores改成正確coordinator→stores，其他scene純資料全不變；真起點／gutter／終點及label核符，錯邊已無、無重複。Canvas獨立validate5/17/16零錯警、scratch重build與canonicalbyteidentical，新真截圖SHA核對後親看無裁切或路由混淆。
- 必要四leaves／metadatahash-linksprivacy-whitespace通過，其餘三Archify與Swift/live證據未變，前輪獨立pass保留；不重跑或動可用產品。詳contracts／compatibility最終段。
- S10a Tester最終approved、requiredFixes=[]，RF-D01已解除，currentS10bpending交獨立Reviewer；S11Human圖表／整體接受及S12真codecommit後PRLensmap／DraftPR後review未代填。既有unknown／controlled／未測界線保持，非全topic完成。本角色停止step／evidence寫入。


### S10b 第一輪：唯一 RF-D02 長期文件現況

- S10a 明示 approved／requiredFixes=[] 且 RF-D01 已解除；S10b 已核對四份長期文件、圖作者／native receipts／最新 Canvas 真截圖及 source／live 證據邊界，其餘結果保留。
- Reviewer verdict=needs-rework，requiredFixes=[RF-D02]：docs/architecture/README.md「尚未定義」第85／87行仍把已交付 DPK credential adapter／產品登入／初次 OAuth 列 deferred，與同檔現況及正式 source 矛盾。只交原文件作者修這兩段，保留真正 deferred／既有邊界；之後由獨立 Reviewer bounded recheck，不重跑 source／圖／live／Swift。
- 完整 finding 與保留結果見 evidence/final-review.md S10b 第一輪。未修受審文件、未 Git／App／credential 操作；S11 Human 圖表及整體接受、S12 真 commit 工具／發布仍未執行。本 Reviewer 停止收據／step 寫入等待作者交接。


### RF-D02 Implementer：兩段現況 deferred 清單最小修正

- 引用外部 S10b needs-rework／requiredFixes=[RF-D02]，僅修 docs/architecture/README.md「尚未定義的項目」兩段：第一段末句移除已交付的 Keychain OAuth credential adapter／產品登入；第二段 deferred 清單移除已交付的 Keychain credential adapter 與初次 OAuth 授權整合。沒有新架構決策或重寫其他段落。
- 完整 REST endpoint、各 BC adapters、共通 headers／API version、rate limit、一般 retry、pagination、shared configuration 等真正 deferred 項目全部保留；non-BC ownership、provider／scope、DPK／產品交付與既有有效 profile／renewal unknown 限制不改。
- 文字 bounded diff 核對為恰好兩段刪除 stale 清單項，相關 Markdown relative links／privacy／whitespace 檢查無問題。只 Modify 架構 README 與自身 step；沒有 Written／Deleted、source／測試／圖／immutable receipts／產品操作，也未重跑 Swift 或圖工具，未 Git。
- RF-D02 待同一 Reviewer bounded recheck；不自判解除，不新增 Tester loop／phase／gate。S11 Human 圖表／整體接受與 S12 既定發布仍 pending。此刻停止所有 repo／step 寫入。


### S10b RF-D02 獨立解除與最終技術交付

- Reviewer 直接核對 architecture README 最終 SHA、兩段 deferred 清單／同檔產品現況及相關 links／privacy／whitespace；RF-D02 已解除。前輪其餘 source／圖／工具／live 證據與限制審查保持，不重跑已通過項。
- S10b 最終 verdict=approved、requiredFixes=[]，詳 evidence/final-review.md 的 bounded recheck；未代 S11 Human 視覺／整體接受或 S12 發布。Current S11 human-check，等待實際 Human 回覆，不自動越過。
- 本 Reviewer 只追加收據與自身狀態，沒有改受審文件／圖／source、Git／App／credential 操作，不新增 phase／gate／Tester loop；此刻停止寫入。


### S11 Human 接受與 S12 開工

- 主對話 Human 實際回答：「圖面與成果可接受，繼續既定交付」，receivedAtUTC=2026-10-20 09:51:14。已由主對話實際展示四圖，不是由工具 pending 推定接受；S11 因此完成。S10b 最終 approved／requiredFixes=[]、RF-D02 已獨立解除，原 Reviewer 停寫。
- 本輪沿既有明確授權 topic commit→push→Draft PR→Human review，使用 git-commit-convention 檢查每組 staged 語意與 message 後執行，不重問已確認的發布許可；不 merge／force push／通知指定第三方。原 branch feat/github-persistent-connection 符合無 owner 慣例的命名，base／PR target dev。
- 實際核對 feature worktree／branch／HEAD 與 origin/dev 均為原 base 16606b89b8e3e6b61523c23aa0be9653c1ea7b44；不在 dev 實作。escalated gh auth status 確認既有 keyring 帳號可用，沒有登入或顯示 raw token。


### S12 topic commits 與 PR Lens 真 provenance

- 首個 code commit `7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18`：`feat(github-connection): 建立可跨重啟持續使用的 GitHub 連線`，23個 W02／W03／W04／W05／M01／M02 code／tests／project leaves；staged 單一完整產品能力，diff --check／privacy通過。
- E007 commit `f4a45fa876d3edf9d7125070a63af6f81cd656c3`：`chore(e007): 保存 profile 更新驗證與未判定結果`，32個 W06／準備／兩輪immutable evidence leaves，保留 unknown 與 Human例外，不混產品code。每次 commit前均核staged語意/message，依已確認User直接topic交付授權執行。
- 原 pre-commit renderer hook 因 feature 缺 node_modules 首次退出127。沒有 skip／改hook／install：唯讀核dev package／bun.lock／tsconfig相同，將既有 dependencies複製到own0700private scratch，檢查內部symlinks無回dev目標，再由feature自己的temporarysymlink使用。首份copy非node_modules標準名稱造成Node module resolution失敗，僅修正owncopy名稱後完整hooks通過；兩個真commits的trim／EOF／Swiftformat／consumer／SwiftLint／renderer全Passed，無修改已驗source。收尾將精確移除本role symlink，dev前後status另核。
- 兩個本輪Xcode生成的manifest外SchemeUserState plist已核baseline未存在／untracked／regular/currentUID／非symlink、只有預期linkedpackage schemes與orderHint，精確移至ownprivatebackup，保留hash，不stage、不改gitignore或父目錄。
- PR Lens以真base至上述codehead的find-renames diff完成localvalidate/render：coverage23/23，5 unchanged source鄰居，4lanes／10nodes／13edges／1flow／4walkthroughsteps，4nativeSVG與2diagrams。manifest／graph／SVG真SHA、有限coverage與四張實際Chrome截圖親看已記tool-evidence；此map不涵蓋E007及後docscommits，不虛構最終PRhead。Graphify沿S09 sourcefallback，不新增graph或操作。
- 下一組 staged 僅45個正式plan／evidence／長期docs／圖leaves，message `docs(github-connection): 記錄持續連線契約驗收與架構圖`，出版前精確manifest與privacy核對後正常commit／push／DraftPR。S12未完成前不宣稱remote或PR結果。


### S12 已發布 Draft PR：Human review 停點

- 已依單一 topic 語意分組、每次 staged diff --check／privacy／message 檢查後提交：

```text
7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18 feat(github-connection): 建立可跨重啟持續使用的 GitHub 連線
f4a45fa876d3edf9d7125070a63af6f81cd656c3 chore(e007): 保存 profile 更新驗證與未判定結果
bd00c3e4b266b1703448b91aff220731241a5335 docs(github-connection): 記錄持續連線契約驗收與架構圖
```

- 正常 `git push --set-upstream origin feat/github-persistent-connection` 成功，沒有force／dev checkout或變更。以User明確要求的gh建立 [Draft PR #62](https://github.com/a129924/rivet/pull/62)，隨後實際readback：isDraft=true、state=OPEN、baseRefName=dev、headRefName=feat/github-persistent-connection；當次headRefOid=bd00c3e4b266b1703448b91aff220731241a5335，與local／remotehead相符，origin/dev仍原16606b89b8e3e6b61523c23aa0be9653c1ea7b44。
- 當次statusCheckRollup=[]，沒有CI checks可判定，不寫綠燈。code／E007／docs三組commit既有全部pre-commit hooks均Passed，沒有skip；不另重跑已綠29／226／13或真人流程。
- 本段與tool-evidence是最後doc-only交付收據，message `docs(github-connection): 記錄 Draft PR 與交付收據`；它不屬於PRLens的原code-head覆蓋範圍。此commit完成hooks後正常push，最終本地／遠端／Drafthead及乾淨feature與dev讀回由交接訊息提供；不將自指commitSHA硬寫成本段自身hash。
- 本role的temporaryfeature dependency symlink僅供完整hooks，最後hook後精確移除，不動dev deps／父dir；ownprivatecopy／兩generatedplist backups及PRLens／Chrome scratch保留供核。沒有新追蹤output／工具config／Apple設定／App或credential操作。
- S12交付範圍已達DraftPRHumanreview；不請指定第三方reviewer、不comment別人、不merge／tag／release。有效profile／七日到期／renewalunknown Human例外、controlled非自然到期／初始digest未測等限制完整保留。

## R07 Implementer 文件與 v2 圖交付（2026-10-21）

- 引用外部R04Tester、R05Reviewer及R06a–fTester approved／requiredFixes=[]；新host真授權、DPK、fresh／真CleanBuild／controlledrefresh／輪替後fresh與Human各段0只引用原R06收據。本role未重跑Swift／真App／DPK／Apple操作，不代R08／R09獨立批准。
- 四長期docs撤正式產品交付／正式DPKadapter等錯誤歸屬，保留topic前正式provider／scope／雙client責任，新增完整獨立驗證工具／有限可行性與限制。五舊evidence＋三舊圖導覽只prepend historybanner，原ca00bc0全文bytes作suffix保留；code7e81b77與commit前實際buildsourcehash界線明確。E00732／舊native29完全不改。
- 新v2精確32leaves：scene／CanvasnativeHTML、BUILD／visual／tool三MD，及三張Archify各9leaves。作者繁中、固定ViewerUI／HTMLlang Englishfallback、classicstill／無發布。Canvas真validate5bands／19boxes／17edges零錯警、nativebuild、1440×1100全新私有Chrome真截圖親看；runtimeport呼叫不等productionimport，沒有反向編譯依賴。
- 三Archify逐candidate真validate，最後deliver各showcase9/9、0errors／0warnings，nativevisual-check四尺寸皆pass；12個最小／最大light／darkPNG已全部view_image親看，不縮字／裁切／手改generatedreceipt。nativevisualReviewpending保持。lifecycle保留laneID與4個實際label／shortsegment診斷逐一修正，收斂後凍結；沒有新nativeleaf超manifest。
- PRLens真version0.11.0，本輪尚無sourcecommit不造map／basehead；R10真ca00bc0→修訂sourcehead後map與coverage，後docscommit範圍另標。Graphify唯一CLI帶GRAPHIFY_NO_AUTO_REFRESH=1，真version0.9.73；無既有graph，真targetedrg/sourcefallback，不buildgraph／config／hooks／install／upload。
- Dispatcher明示W01 AppREADME屬本輪文件修正，僅doc-only更新新host成功現況；原R03／R05／R06三十檔hash收據不改、READMEoldhash保留，其他29App檔對R06仍同bytes，不冒稱current30全一致。新manifest涵蓋所有source／planning／docs／evidence／v2及61immutable，mutable本身由外部handoff綁hash；95個現行docslinks、8banner-onlysuffix、privacy／whitespace／source-livehash／productionzero-diff皆核對。
- R07作者完成→R08Tester→R09Reviewer；尚未commit／push／改原DraftPR62、不merge。profile更新仍未驗證、Human已接受限制；controlled不等naturalexpiry、初grantpostdigest未觀測／R06c首次讀回、aggregatepairChanged界線不變。本role交接後停止所有repo／step寫入。

## R10 source topic commit 與真 map（2026-10-21）

- 外部R08Tester、R09Reviewer已approved／requiredFixes=[]，本role依Human明確本輪topiccommit→push→更新原DraftPR授權，不重問已確認的發布。每組先從stageddiff核單一語意與message，不skipmandatoryhooks；沒有merge／force／指定第三方通知。
- code `b63af3e51d04487f651ba2fb521fd056f53f1af1`，message `fix(github-connection): 將完整流程驗證隔離至獨立 App`；53from/to原始paths、rename-aware36entries，D19＋M4撤回及App30完整一組，不混其他docs。trim／EOF／Swiftformat／consumer／SwiftLint／renderer6項hooks均Passed。featurerenderer依賴由唯讀dev現有相同pins複製到own0700copy，5內部symlinks皆只指owncopy，未install或回連dev；最後hook後精確移除本roletemporaryfeaturelink。
- PRLens真ca00bc0→此codehead：4lanes／14nodes／16edges／1flow／3steps、53/53sourcepaths union＋7unchanged鄰居、真validate/render與4nativeSVG／Chrome截圖親看。後docs/evidence/v2commits明列不在map，詳v2/tool-evidence。Graphify沿既有禁refresh sourcefallback，不buildgraph／改config。
- 下一組staged僅53個planning／docs／evidence／v2leaves，message `docs(github-connection): 修正驗證定位與分版可行性證據`。尚未完成本輪push／原DraftPR更新，不提前填remote結果；source／真人／native圖皆不改、不重跑。

## R10 已更新原 Draft PR：本輪交付收據

- source `b63af3e51d04487f651ba2fb521fd056f53f1af1`：`fix(github-connection): 將完整流程驗證隔離至獨立 App`；docs `754e121ab23164f263fb048041a724b7b52a106c`：`docs(github-connection): 修正驗證定位與分版可行性證據`。兩組分別核staged單一語意／message／privacy／diffcheck後commit，trim／EOF／Swiftformat／consumer／SwiftLint／renderer全6項mandatoryhooks均Passed，無skip。
- normal `git push origin feat/github-persistent-connection` 成功，未force；使用Human明確授權的gh更新原[DraftPR62](https://github.com/a129924/rivet/pull/62) title／body為獨立驗證工具／可行性結果，不是正式產品，沒有重開PR。實際readback title/body與私有提交文件相符，OPEN／isDraft=true／base=dev／head=feat/github-persistent-connection，當次headRefOid=`754e121ab23164f263fb048041a724b7b52a106c`與local／remote相符。
- 當次statusCheckRollup=[]，沒有GitHubCIchecks可判斷，不冒稱green。PRbody明列productionbasezero／App缺席buildtest、78／202／12、七段Human0、新舊sourceversion／initialgrantdigest未觀察、controlled非natural、profilerenewalunknownHumanaccepted、E007保留及真map有限覆蓋。
- 本段與manifest／v2tool-evidence為最後doc-only收據，message `docs(github-connection): 記錄回修 Draft PR 與交付收據`；同樣正常hooks後push。它不在PRLens sourcehead覆蓋內，不循環重做map，也不改任何source／native圖／live收據。其最終commit／remotehead由交接實際提供。
- 完整交付停R11Humanreview；不merge／tag／release／assign第三方或comment別人。最後hook後精確移除本rolefeature node_modules symlink，保留ownedcopy／map／Chrome／所有原App／新驗證App／真DPK／Apple資產與私有驗收證據，不作其他cleanup。
