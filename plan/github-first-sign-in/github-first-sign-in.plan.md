# 正式 OAuth 能力與獨立驗證 App：受限執行計畫

- Topic：`github-first-sign-in`；2026-10-20，Plan-Creator amendment，已獲獨立 Plan-Reviewer A02 approved（無required fix）。
- Branch：`feat/github-first-sign-in`；base／PR target：`dev`；基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22`。
- 沿用原 feature worktree／[Draft PR #61](https://github.com/a129924/rivet/pull/61)，不建新 worktree／PR、不在 dev 實作、不 merge。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[step](github-first-sign-in.step.md)。


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
