# 實驗索引

基礎索引日期：2026-11-11；PR #69 收納／合併事實更新：2026-11-13；PR #71 契約、PR #72 本地登出與 PR #73 PAT 儲存合併事實更新：2026-11-16。此索引依已合併交付及其有限證據整理；PR #67／E010 各輪狀態保留原記錄時點，由其獨立工作線維護。各輪前提、歷史結果與授權以原紀錄為準；實驗成功、驗證任務完成、PR 合併與正式採用是不同狀態。 PR #74 runtime 合併與 Git 收尾事實更新：2026-11-17。 PR #76 可行性方案合併與 Git 收尾事實更新：2026-11-17。 PR #75 Login UI 採用、驗收分離與 Git 收尾事實更新：2026-11-18。 PR #77 OAuth 冷啟動還原及 hosted 驗收／Git 收尾事實更新：2026-11-18。

## PR #77：OAuth 冷啟動還原、正式 hosted 驗收與清理（2026-11-18）

[PR #77](https://github.com/a129924/rivet/pull/77) 已於 `2026-11-18T09:32:51Z` 合併至 `dev` 並關閉。固定 merge 為 `b9f969f05347e8c4227fb742205814bef95f7604`，parents 為 `0087cb404b652cb0565fe6482474e4b6b668e7ba`／最後 feature `cab8ba4fd9d0485b081828865abeacb815478172`。Merge 與 feature 的差異只在兩份實驗索引，保留上游結案更新；merge／tag 是來源保存點，不是新的 build 或 live 執行。

**正式能力**：non-BC `GitHubIntegration` 的 caller-owned `GitHubOAuthStartupRestorer` 從既存 configuration／完整 credential 還原 scope，必要刷新及完整保存後才回本地 ready，區分未設定、未登入、需要登入、取消與技術失敗。重疊回 busy，取消等待原工作收尾，明示重試保留原 provider。沿用既有 stores／fetcher／provider／scope，不新增 BC 或改寫 refresh／401 policy。[正式契約](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/docs/architecture/github-oauth-startup-restore-runtime.md)記錄邊界；產品啟動／UI 接線、重新授權、PAT 連線與跨程序協調仍未由本題交付。

**驗收歸屬**：active `experiments/E018/` 已退役，現由[正式 hosted integration tests](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/Tests/GitHubIntegrationHostedTests/README.md)提供 Offline／手動 Live schemes、薄 App host 與 Swift Testing bundle；依賴組裝、觀測及斷言在測試碼，使用唯一正式 runtime。Runner 的 nested bundle 路徑與 App-bound inside-out signing 已修正，保留 deep／strict verification；只簽 App 內副本，不動系統 SDK 或新增 Apple 資產。這是正式測試設施，不是新的實驗編號或產品 E2E。

**分層證據**：原 M04 的 root 375 tests／46 suites、consumer 22／6 為該輪歷史；修後 N 的 27 mocks、完整 Offline 2 個原生正向與 2 個預期原生負向均符合預期。正式 hosted Live 的 first／fresh 各正常執行一次，各 1 passed／0 skipped，ready、GitHub API、完整 credential readback、configuration 保持及程序退出通過；fresh 與 first 為不同程序、同完整憑證與帳號。兩段 Human 各重新回報全程觀察、0 次提示，獨立 attestation 各綁原 machine SHA，原 machine／pending 欄位不回填。[N 有限結果與安全收據](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/plan/github-oauth-startup-restore-runtime/evidence/hosted-live.md)

兩段憑證當時均未到期，prepare／final refresh、save 全為 0；**本輪 hosted 未涵蓋真 refresh／rotation-save**。原 E018 `0debe0b` 的自然到期真 refresh／save 各 1 次與 fresh 結果保留為[獨立歷史](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)，不能挪為新設施 coverage。N actual source aggregate 為 `7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`，artifact 為 `bc78a4ab7c3bf85b7dbf179acef35e21bdff222e9148d6c55b0c4541da1afc9d`；工具修正收錄於 `f68c386`，preflight 與 actual phase 產物分開。兩次失敗準備與後續成功 inside-out preflight 原樣保留，未消耗或重設 Live phase；first／fresh 各 1/1 已用盡，不續行。

獨立 NR13 準備與 N06 有限結果審查 approved、無 required finding；此結果限當次同機／GUI user、既有 certificate、當時有效 profile、exact group 與唯一 owner，不證明普遍權限、profile 續期、跨環境或斷電 durability。PR 合併不回填原 artifacts 的 Human／圖面 pending，也不把本地 ready 當普遍遠端成功。

Annotated tag `v0.1.71-github-oauth-startup-restore-runtime` 已推送並讀回：local／remote object 均為 `49593cb67449ca8f84d587677345f4e5368320f3`，peeled 精確指向上述 merge；不指後續索引 commit，亦非 GitHub Release。原 `feat/github-oauth-startup-restore-runtime` remote／local／tracking refs、managed feature worktree 目錄與 registration 已正常刪除並核 absent；remote 用最後 head 的 expected-head lease 保護刪除，local 用 `git branch -d`，沒有強制移除或 prune。Ignored Floorplan 19 檔已逐檔 bytes／mode／SHA 相符封存在 Git 私有 archive，未 track／push；可重建 caches 隨原 worktree 移除，外部 App／signed artifacts／run records、DPK／Keychain／Apple 資產與其他工作線不動。

兩索引以獨立 `docs/github-oauth-startup-restore-runtime-postmerge` 工作樹維護，沿既有慣例安全 fast-forward 保存至 remote dev，不在 dev 編輯；文件分支／工作樹須待安全交付與 fresh clean 後另行收尾，不預填成功。本次只整理 Git 與索引事實，未執行新的 hosted／OAuth／DPK 驗收或改寫原 evidence；正常文件提交 hooks 的 consumer contract 等檢查不當作新的 live 結果。

## PR #75：正式 Login UI 選擇性採用、驗收分離與清理（2026-11-18）

[PR #75](https://github.com/a129924/rivet/pull/75) 已於 `2026-11-18T08:46:47Z` 合併至 `dev` 並關閉；merge 為 `e7a4b8422e524f59a7bfa1bb514838f2d829a8cb`，parents 為 `0a71be99759373606de9bd3994a30b2c5c3f40cb`／最後 feature head `5167e4c454af9dbbba48a3b2be024d5b8528e088`。Merge 與 feature tree 不同：保留上游兩份實驗索引更新；本節記錄保存來源，不冒稱 merge 是新受測 build。

**本輪能力**：重用既有 `RivetLoginContent.standard` 與正式元件，將 `Sources/Presentation/Login/` 的 `RivetLoginView` 組合為四個 internal 職責元件；外層持有 phase／呈現文案，PAT 元件管理編輯、Show／Hide 與焦點，以有限 intents 回報互動。[正式契約](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/docs/presentation/login-ui.md)及[採用決策](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/docs/feasibility-adoption.md)記錄選擇性重用、調整與排除；不做 E011 的1:1搬移。`RivetPresentation` 不依賴 `GitHubIntegration`，不重建 Login VO。

**驗收歸屬**：直接正式測試在 `Tests/RivetPresentationTests/`，controlled `#Preview` 由 wrapper 接收 intents／持有受控 phase。獨立視窗、選單、鍵盤／焦點與 Human VoiceOver 的必要環境由最小 [acceptance tool](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/tools/acceptance/login-ui/README.md) 提供，依賴同一份正式 `RivetPresentation`；自己的 parent／configuration／fixtures 不依賴 E011 `LoginDemoModel`，沒有複製正式 View 或為 fake 新增 Service／DI。乾淨畫面使用正式預設文案，控制項留在專用驗收選單。[實作與依賴證據](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-implementation.md)

**E011 凍結**：指定基線 `d2332bfff25510a3f78c1fbc8b0d2d9cf953b223`，E011 tree=`b6a1e6e1196e64999af9591ec32f09211f1936c6`；本 PR 只對六項差異有界回復（三項恢復／三項 PR-added 刪除），merge 對該基線的 E011 diff 為空，未整目錄覆蓋。原 plan 曾納入 E011 的歷史與舊接受不改；它是歷史來源，停止承擔新版驗收。Frozen consumer 可建置，但以現行正式預設文案重建不保證歷史 Demo 模擬語意等效；歷史重現需完整凍結 revision 或舊 binary，未新增正式 demo mode。

[自動驗證](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-testing.md)保留實際來源：root focused 16 tests／4 suites（正式9／凍結 Demo7）、tool8 tests／2 suites、兩個 product builds 與局部 format／lint／腳本／plist 檢查。修後 code `9d14a3f6bf878a215de0d39d4fb05ec05970ec80`、binary SHA-256 `6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1` 完成 [F01–F06 原生差異](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-native.md)及 [V01／V02 Human 聲音](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-voiceover-human.md)。Human 已明示[接受本輪驗收支援分離、封裝修正與差異補驗結果](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-human-acceptance.md)，獨立 R07 approved／無 required fixes；舊 HC01／4d binary 接受依原版本保留。Canvas 仍未驗，不外推全矩陣、所有語音競態或分發環境。

**產品整合**：本輪正式 UI 能力與上述有限接受完成；真登入 request 建構／外層 Adapter、認證服務接線、憑證儲存、session、導覽與完整產品 App 組裝不在本 topic。既有 `PersonalAccessToken`／`LoginRequest`／`LoginOutcome` 的對應依契約留待外層協調；有限 Outcome 不能單獨表示全部 phase，成功 UI 不代表已建立 session。PR 合併不將這些工作改為完成。

Annotated tag `v0.1.70-rivet-login-ui-adoption` 已推送並讀回：local／remote object 同為 `054a9267fcedd730c8d56f9be1f6e272df726153`，peeled commit 精確為上述 merge，不指向後續索引 commit，亦非 GitHub Release。原 `feat/rivet-login-ui-adoption` 的 remote／local／tracking refs、managed worktree 目錄與 registration 已在 fresh clean／head／merge lineage／tag 核對後正常移除；遠端以 expected-head lease 保護刪除，本地以 `git branch -d`，無強制移除或 prune。舊 accepted Preview 的3檔已逐檔 bytes／SHA／mode 相符封存於 Git 私有 archive，未 track／push；可重建 build／node_modules 隨原工作樹移除，新版外部驗收 App 與其他工作線不操作。

兩索引在獨立 `docs/rivet-login-ui-adoption-postmerge` 工作樹維護，沿既有 postmerge 慣例以安全 fast-forward 保存至 remote dev，dev 工作樹只同步、不編輯；文件 branch／worktree 只在兩檔安全提交推送、fresh clean 後才收尾，不預填其成功。本次不重跑 Swift／原生／VoiceOver，不改舊 artifacts／接受紀錄或其他實驗結果；提交檢查另依本次實際執行回報。

## PR #76：OAuth 啟動／重連可行性方案合併與清理（2026-11-17）

[PR #76](https://github.com/a129924/rivet/pull/76) 已於 `2026-11-17T08:52:59Z` 合併至 `dev` 並關閉；merge 為 `ddfa281a2e73a65a1fa995a268b416115e988b68`，parents 為 `ab77391b73291deb1ce3d96cef72f981aeb3104a`／最後 feature head `2ac31dc85bd92f1892c34e656ab77900524a97fe`。Merge tree 與最後 feature 相同；主成果 commit `a2d2bbaeed98c480d9bc92531c872430adc9c125` 之後的 `2ac31dc` 僅補交付收據。這是文件／圖面保存版本，不是新執行 build。

交付為 OAuth-only 的[來源驗證](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/analysis/github-oauth-connection-orchestration/source-audit.md)、[能力盤點](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/analysis/github-oauth-connection-orchestration/adoption-audit.md)與[選擇性採用方案](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/docs/feasibility-adoption.md)，沒有新增 E 編號、正式 orchestration 或產品 UI 接入。A01–A03 為既有 primitives 已具備、上層接入仍缺的部分採用；A04 正式 owner 未採用、A05 驗證專屬構件排除、A06 源自 E014 的關係不確定。E014 同名 App-local adapter 不等於正式 adapter；不因名稱或合併推定採用。

原碼支持有條件組合：冷啟動保留設定缺漏／credential absent／讀寫失敗差異；可重試暫時錯誤沿原 provider；重新授權須 signOut 永久退休、等待已開始保存並 clear 成功後才登入，完整成功後才新 provider／scope。取消後新 credential 可能已保存，不 rollback 或復活舊連線；唯一 owner／writer、世代結果過濾及完整組裝行為仍需後續契約與驗證。Scope ready 不表示遠端身份／權限成功，初次登入有限 Outcome 未變。

獨立 Plan-Reviewer／Tester／Reviewer 已完成，required fixes 閉合；Tester 核對20份來源 SHA、37個相對 links、兩 v2 圖各9/9 showcase、四尺寸 containment／readability及8張明暗截圖。兩圖首版 containment 失敗與 v2 修正分開保留。[驗證](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/plan/github-oauth-connection-orchestration/evidence/verification.md)／[審查](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/plan/github-oauth-connection-orchestration/evidence/review.md)不等於 Swift runtime 或新 live 通過；本輪未新建實驗、未重跑完整 Swift runtime／OAuth／DPK。Commit hooks 均通過；首次缺 Biome 已依 frozen lockfile 補齊本地依賴，package／lockfile 未變。

Floorplan 是本機 ignored 的20檔繁中現況地圖（正式12／E014 5／tests 3），不是 PR 追蹤檔或正式架構；描述20/20、50 links、10人工核對關係、0 dangling，routes0/0不代表 endpoint 驗證，Health 不作安全審查。PR Lens 0.11.0 對實際 base→`2ac31dc` 的39檔 diff 本機 validate／render，未上傳；Graphify 0.9.73 無既有 graph，採原碼 fallback、不建圖。[工具與交付限制](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/plan/github-oauth-connection-orchestration/evidence/publication.md)保留原時點 Draft／HC01 pending；PR 現已合併另記於此，不將合併當圖面 Human 視覺接受或正式流程已接通。

Annotated tag `v0.1.68-github-oauth-connection-orchestration-feasibility` 已推送並讀回：local／remote object 均為 `b35f79646f8495e560c13454f67e0bfdefe1152b`，peeled commit 精確為上述 merge；不是後續索引維護 commit、runtime pin 或 GitHub Release。原 feature branch `docs/github-oauth-connection-orchestration` 的 remote／local／tracking refs、managed worktree 目錄與 registration 已 fresh 核 absent，正常刪除、未 force／prune。本機 Floorplan 23檔已逐檔 bytes／SHA 相符封存在 Git 私有 archive，未 track／push；原工作樹內可重建的 node_modules 隨工作樹移除，未操作其他工作線、App／DPK／Keychain 或 Apple 資產。

兩索引在獨立 `docs/github-oauth-connection-orchestration-postmerge` 工作樹維護，沿既有 postmerge 慣例以安全 fast-forward 保存至 remote dev；dev 工作樹只同步、不編輯。本段記錄原 feature 已完成清理，文件維護 branch／worktree 只在兩檔安全提交／推送後才收尾，不預填後續成功。其他實驗結果、來源、額度與 E010 各輪狀態原樣保留。

## PR #74：OAuth／PAT 正式登入 runtime 合併與清理（2026-11-17）

[PR #74](https://github.com/a129924/rivet/pull/74) 已於 `2026-11-17T04:02:54Z` 合併至 `dev` 並關閉；merge 為 `4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e`，parents 為 `1f31b35604adb5bb36326e52f9d6dbcff0cac763`／最後 feature head `163047f0a295707f957bce96025b4cd9e79f36f9`。Merge tree 與最後 feature 相同，只證明交付來源保存，不是新的受測 build 或 live 驗收。Runtime 程式提交為 `fa93773ed090a4d07eb96f6bd43f3ab0b922cbb5`；後續 `163047f` 僅補交付紀錄，程式／測試／驗證入口未變。

正式 non-BC `GitHubIntegration` 已提供 `GitHubLoginService: LoginAuthenticating`、caller-owned 共用 coordinator、候選 token 的 `/user` probe 及 browser／loopback OAuth 通道。兩路均先驗證再保存至既有 OAuth／PAT DPK stores，另一方式憑證保留；重疊登入立即拒絕。取消傳遞且等待原工作／通道收尾，最後同步檢查後無 await；已保存後取消不補償刪除。[長期契約](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/docs/architecture/github-dual-login-runtime.md)不交付產品 UI、session／clients 交接、啟動恢復、refresh／401 擴充、登出、帳號切換、migration 或 legacy 適配。

本 topic 新增[隔離驗證入口](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/experiments/github-dual-login-runtime/README.md)，沒有新增 E 編號；它是可移除的獨立 Swift package，root Package 不依賴它。本輪只 build，未啟動 binary，不能把此工具存在或 build 成功當作 signed DPK host ready、真 GitHub／Security 或 fresh-process 驗收。E013／E014 與既有儲存結果仍屬各自來源，不回填本次 TC08。

原受控證據為 focused 20 tests／4 suites、完整 root 358 tests／45 suites、public consumer 19 tests／5 suites、format、strict lint（155 files／0 violations）、CLI build 與完整 hooks；正式 Plan-Reviewer／成果 Reviewer approved、required fixes 0。[實作](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/evidence/implementation.md)、[獨立驗證](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/evidence/verification.md)與[審查](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/evidence/review.md)保留實際分層。Archify showcase 9/9、0 errors／warnings、deliver、四尺寸 containment 與 Agent 視覺檢視通過，[圖證據](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/docs/architecture/diagrams/github-dual-login-runtime/BUILD.md)的 Human 接受仍 pending。PR Lens 0.11.0 已依實際 diff 在本機 validate／render，產物未上傳；Graphify 0.9.73 無既有 graph，採 source-search fallback，未建圖。

TC08 真 OAuth／PAT、當次 signed host readiness、fresh-process 讀回、圖 Human 視覺及 topic 最終接受仍 pending；PR 合併不代替這些證據。[固定帳本](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/github-dual-login-runtime.step.md)的 Draft／human-check 依原交付時點閱讀，本次不改原 artifacts／證據／圖、不重跑 live。

Annotated tag `v0.1.67-github-dual-login-runtime` 已建立、推送並讀回核對：local／remote object 均為 `8910b7ee3ee6498b47ab5a14522b553534ada7ad`，peeled commit 精確為上述 merge；不是後續文件 commit、live build pin 或 GitHub Release。原 `feat/github-dual-login-runtime` 在 fresh clean／無 untracked／head／merge lineage／tag／locks 核對後，已正常刪 remote branch、移除 managed feature worktree 並以 `git branch -d` 刪 local branch；local／remote／tracking refs、目錄與精確 registration 均已核 absent，未 force／prune。

兩索引在獨立 `docs/github-dual-login-runtime-postmerge` managed worktree 編輯；文件依既有 postmerge 慣例只作安全 fast-forward 保存到 remote dev，dev 工作樹只 `--ff-only` 同步、不在 dev 編輯。文件分支／維護 worktree 於文件安全保存及 fresh clean 後才收尾，不預填後續動作成功。E010、登入 UI adoption 等其他 worktree、外部驗證產物、Keychain／DPK 與 Apple 資產均不操作。


## PR #73／E017：正式 PAT DPK 儲存合併與清理（2026-11-16）

[PR #73](https://github.com/a129924/rivet/pull/73) 已於 `2026-11-16T09:42:56Z` 合併至 `dev` 並關閉；merge 為 `cd76cd3faa192134b77b1c1816bbef2c184ede7b`，最後 feature head 為 `8ffcff3ed2bcf01cccc80ce30078b5c0bcfdbaec`。Merge parents 是 `f89120d61278af6cd696f134762e75487b94ee8a`／上述 feature head；merged tree 同時保存 PR #72 的 E016、本題 E017 與正式 PAT Sources，並非與 feature tree 相同。Merge／後續文件版本是保存點，不是新 live 受測來源。

正式 non-BC `GitHubIntegration` 的 [PAT adapter](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift)提供 caller-owned 單一 GitHub.com PAT 保存、讀回與整筆替換，具明確 namespace、嚴格資料還原、有限錯誤、同實例協調與診斷遮蔽；公開值沿用 `PersonalAccessToken`。[長期契約](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/docs/architecture/github-pat-dpk-storage.md)不包含登入 runtime／UI、遠端有效性、session／clients、legacy 遷移或產品 delete。

採用與驗收鏈為 E006／E007／E015 既有成果 → 正式 Sources 實作 → 原 source `5465d3c7308e74bc2b3b51878acd190d4f2babda` 的 E016 路徑實機驗收 → 現行 [E017 host](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/experiments/E017/github-pat-dpk-storage/README.md)。原 run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 以非機密樣本完成保存 A→writer 結束→fresh A→整筆 B→fresh B→真正同身分 clean/build→rebuilt fresh B→exact-owned cleanup／正式 load=nil。六 runtime 均 accepted、Human whole observed=true／各0提示；setup／rebuild 另各全程0。Full identity 相同、binary不同及實際 Rebuilt compiler flag 均有證據。[真人紀錄](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/live-validation.md)、[有限結果](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/live-run-39c22b57.json)與 [P07 approved review](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/live-review.md)固定原來源，不將合併或改號冒充重驗。

原 `55aa57a` read A／cleanup 的 unknown／accepted=false 與 `0b0692e` setup unknown 保留；55 namespace 的新唯讀 recovery 只證當次正式 load=nil、accepted／Human全程0，沒有重 delete。E016→E017 十檔移轉中八檔 bytes 相同、runner只改兩字串，Python54、全新 scratch 兩 unsigned builds 各113 fake checks、R02／R05 approved僅支持離線歸屬接線，沒有新 signed／Run／DPK驗收。[移轉 mapping](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/e016-e017-relocation.md)保留固定舊來源及九項 E016 source keys／hash；[移轉測試](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/e016-e017-tests.md)／[獨立 review](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/e016-e017-review.md)另列。E016 歸 PR #72，E017 歸本題。

結果限當次同機／GUI使用者／有效簽章與存取身分，驗收 profile 有效至2026-11-23；不證 renewal、certificate rotation、其他環境／公開分發、斷電 durability、真 PAT 遠端有效性或產品登入。E007 renewal 原無法判定與 Human 接受限制不改。HC04 圖的 Human 視覺及 HC05 topic 最終 Human review 仍 pending，PR合併不代替接受；[原帳本](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md)的 Draft／未merge文字是當時快照，不回寫原 evidence／圖。

本次已將精確兩份 untracked Xcode 個人 metadata 可回復保存在 Git common 私有0700 archive，0600 manifest僅存私人來源對照；bytes／mode／owner讀回核符後只移出兩 source leaves，feature fresh clean／無untracked。Archive不commit／push，外部私有 Xcode／signed artifacts／runs／proofs及Apple／DPK資產保持。

Annotated tag `v0.1.66-github-pat-dpk-storage` 已建立／推送並讀回核對：local／remote tag object 同為 `cd8fa8ea85c3f44e059de4fde47b8d1a304677ea`，peeled commit 精確為上述 merge `cd76cd3faa192134b77b1c1816bbef2c184ede7b`；不指後續文件 commit 或原 live binary，不是 GitHub Release。原 `feat/github-pat-dpk-storage` 在 fresh clean／無untracked／head／merge lineage／locks／無active mutation核對後，已正常移除managed feature worktree、以 `git branch -d` 刪local branch，並在remote仍為feature `8ffcff3` 時刪exact remote ref；local／remote／tracking refs、worktree目錄／精確registration均已核不存在，未force／prune。

PR #73 的十四個branch型blob／tree URL已固定為上述merge permalinks，逐項object與最後feature相同，body其他bytes不變；讀回仍closed／merged。兩索引由獨立 `docs/github-pat-dpk-storage-postmerge` managed worktree交付，文件commit由本次Git history定位；原hooks照常，remote dev只接受safe fast-forward，dev工作樹只作clean gate後的 `--ff-only` baseline同步、不在dev編輯。本文件分支／worktree只於文件安全保存remote及fresh clean後正常移除，不預填該後續動作成功。E010工作線、外部私有Xcode／signed artifacts／runs／proofs、DPK／Apple資產與原topic artifacts／evidence／圖不操作；本次不重跑實驗，也不將merge／Git清理代替HC04／HC05接受。

## PR #72／E016：正式本地登出與有限 DPK 結果（2026-11-16）

[PR #72](https://github.com/a129924/rivet/pull/72) 已於 `2026-11-16T09:00:10Z` 合併至 `dev` 並關閉；merge 為 `88ec4a0e13bf68fb489fd9b06895591a0663ba53`，最後 feature head 為 `641789fad88d2a3ad7e3fe990fa56d1c0e540fe3`。Merge parents 為 `5713025e3312c0fbc9a7b02a222db0b91d6e1b58`／上述 feature head，tree 與最後 feature 相同。這是交付保存點，不是新的 live 受測版本。

正式 non-BC `GitHubIntegration` 提供 `OAuthTokenProvider.signOut()`、永久退休舊 provider、已開始寫入結束後精確 clear credential，保留 configuration；晚到 restore／refresh 不發布或重新保存由正式受控 tests 支持。[本地登出長期契約](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/docs/architecture/github-oauth-dual-client.md#本地登出)與[精確清除契約](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/docs/architecture/github-oauth-credential-persistence.md#本地-credential-清除)固定引用合併來源。

獨立 [E016 八段紀錄](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/experiments/E016/README.md)以受測來源 `bb6752aa483a68043174723a6b3ff2653abe79ce`、同一 frozen signed binary／profile、固定 synthetic credential／configuration／sentinel，於真 DPK 完成 first seed/readback→正式 signOut→同程序 absent，以及新 exact process 的 fresh 只讀 absent／configuration／sentinel intact。兩程序歸屬與退出有證據，Human 各完整觀察、提示 class 為 zero；Tester／Reviewer接受本次有限成功。Merge／最後 feature head 均不是此 live 受測來源，不能拿合併後版本冒充重驗。[Live 與收據綁定](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/plan/github-oauth-local-sign-out/evidence/e016-live.md)及[安全結果 projection](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/experiments/E016/evidence/success-summary.json)保留分層證據。

014bab2 的簽章後 certificate extraction 工具停止、ff672c7 first 的 indeterminate／缺 exact-process 證據及 fresh 未執行均保留；後者已耗額度，Human 另授權的 bb6752a first／fresh 額度也已用完。原 public 的 Human unknown／false 由獨立 attestation 綁 SHA 補充，不覆寫原收據。隔離 configuration／sentinel 殘留未清，沒有追加 cleanup。結果只適用當次同機／GUI 使用者／既有 signer、有效 profile、exact group、frozen binary 與唯一 writer；不外推真 OAuth、UI、其他 profile、跨 writer 或 durability。本次 live 沒有 refresh/network，不取代原受控競態 tests，亦不回改 E010／E015 歷史。

Annotated tag `v0.1.65-github-oauth-local-sign-out` 已建立／推送並讀回核對：local／remote tag object 同為 `96fba09f65a1c2f42fe8501fa4bd5623ea57bafd`，peeled commit 精確為上述 merge；不是後續文件 commit、live build pin 或 GitHub Release。原 `feat/github-oauth-local-sign-out` local／remote branch 與 tracking refs 已正常刪除並核 absent，未 force。兩索引由 `docs/github-oauth-local-sign-out-postmerge` 文件分支維護；本輪不重跑實驗、不清 DPK 或 Apple 資產，也不將 PR 合併視為原 topic Human 最終接受或圖面接受。

## PR #71：OAuth／PAT 雙登入契約合併與清理（2026-11-16）

[PR #71](https://github.com/a129924/rivet/pull/71) 已於 `2026-11-16T02:15:39Z` 合併至 `dev` 並關閉；merge 為 `4ddca1864557c2858266c2cc6d0a21f1e0bb7237`，最後 feature head 為 `3cdbde753ebefb26564d1135376d043e682b13e7`。兩親 merge 的 tree 與最後 feature 相同，只證明交付來源保存，不是新 build 或重新受測。

本次是既有 non-BC `GitHubIntegration` 的正式技術契約，不新增 E 編號或驗證 App。交付 OAuth／PAT 請求 VO、PAT 本地 trim／空值拒絕、共同 Sendable async Protocol、有限 Outcome、取消義務與診斷遮蔽；`.success` 不帶帳號、session、token capability 或 clients。真登入、UI 接線、遠端帳號驗證、儲存與 refresh／401 未由此交付。[固定長期說明](https://github.com/a129924/rivet/blob/4ddca1864557c2858266c2cc6d0a21f1e0bb7237/docs/architecture/github-dual-login-contract.md)與[技術規格](https://github.com/a129924/rivet/blob/4ddca1864557c2858266c2cc6d0a21f1e0bb7237/analysis/github-dual-login-contract/technical-spec.md)界定公開契約。

原交付的獨立驗證為 focused 8 tests、GitHubIntegration 229 tests／25 suites、既有 consumer 15 tests／3 suites、format／SwiftLint／diff check，以及完整 commit hooks 通過。Archify showcase 9/9、0 errors／warnings、deliver 與四尺寸 containment 已通過，最小／最大 light／dark 截圖經獨立審視；PR Lens pinned 0.11.0 在本機 validate／render 通過並綁定最後 feature head，Graphify 無既存 graph 而採 source-search fallback，未建圖。詳見[固定交付帳本](https://github.com/a129924/rivet/blob/4ddca1864557c2858266c2cc6d0a21f1e0bb7237/plan/github-dual-login-contract/github-dual-login-contract.step.md)。這些是原受控證據，本輪不將文件提交 hooks 視為新一輪 topic 驗收，也未重新產圖或新增真人結果；合併也不代替圖的 Human 視覺接受。原帳本 Draft／human-check 文字按當時交付快照閱讀。

Annotated tag `v0.1.64-github-dual-login-contract` 已建立／推送並讀回核對：local／remote tag object 同為 `7eacd8e747eb5be78936cf237fa9f15b7a6671a4`，peeled commit 精確為上述 merge；不是後續文件 commit 或 GitHub Release。

原 `feat/github-dual-login-contract` local／remote branch 與原 managed feature worktree 已在 fresh clean／head／lineage／tag 核對後正常刪除，相關 tracking ref、目錄與註冊均已核不存在，未 force／prune。PR 的五個分支型審閱入口已改為固定 merge permalinks。兩份索引在獨立 `docs/github-dual-login-contract-postmerge` managed worktree 維護，不在 dev 編輯；該後續文件分支與維護 worktree 尚待本輪文件安全交付後收尾。E010、local-sign-out 等其他工作線與安全資產未操作。

## PR #69：已合併的獨立驗證環境收納

| 編號 | 用途與來源 | 狀態 |
| --- | --- | --- |
| [E011](E011/README.md) | `rivet-login-ui` 的歷史 Login Demo、控制介面、Runtime 與專屬測試；凍結於 `d2332bf`，不再承擔新版正式能力驗收 | PR #69 收納與舊 Human 採用依原版本保留；PR #75 驗收改用直接正式 tests／controlled Preview／獨立 acceptance tool，不改 E011 基線。 |
| [E012](E012/README.md) | `pr-reader-webview-runtime-reading` 的fixture host／Runtime／資源／專屬測試，功能驗收展示 | B2位置修正；不重做原功能開發、不搬正式bridge／Core或TS pipeline；結果見topic帳本。 |
| [E013](E013/GitHubSignInVerification/tools/README.md) | `github-first-sign-in` 首次登入驗證App與專用PKCE tools／fixture，可行性驗證環境 | B3完整接線與現行pin結果見topic帳本；歷史真人／PKCE證據保留，不提升產品能力。 |
| [E014](E014/GitHubConnectionVerification/README.md) | `github-persistent-connection` 持續連線App／Runtime／專屬測試，可行性驗證環境 | B4集中；不改正式能力、簽章／儲存或歷史真人結果，離線搬移結果見topic帳本。 |
| [E015](E015/github-oauth-credential-persistence/README.md) | `github-oauth-credential-persistence` 正式DPK adapter的獨立功能驗收runner／專用測試 | B5集中；正式adapter/tests留root，歷史真人／pins／receipts保持；本次離線結果見topic帳本。 |

此配號僅集中收納驗證環境，不代表重做實驗、撤回既有採用或新增永久工具例外。下方既有索引與來源快照保留原紀錄。

### PR #69 合併與清理事實（2026-11-13）

[PR #69](https://github.com/a129924/rivet/pull/69) 已合併並關閉，目標為 `dev`，`mergedAt=2026-11-13T06:16:39Z`；merge commit 為 `4c2153963fe7c41cc36b56f2a4fe3ae3b79ba6c2`，最後 feature head 為 `a4c4f6bc23f00ae746ad48c69f6779ca993a1d03`。兩親 merge tree 與最後 feature 相同；這是來源保存點，不是新 build 或真人量測。

本次交付分列純搬移、必要接線，以及兩項獨立受限修正：`ccf9d21` 空白配置拒絕與 `3fe0c9a` 測試型別消歧，不將整份 PR 稱為無行為差異的純搬檔。正式能力／正式測試與 root products／targets／dependencies 保留；唯一逐檔歸屬與允許差異見[固定 technical-spec](https://github.com/a129924/rivet/blob/4c2153963fe7c41cc36b56f2a4fe3ae3b79ba6c2/analysis/verification-artifact-ownership/technical-spec.md)。

E015 最新離線補測為197項：**195 passed／2 skipped，0 failure／error**；原189項逐案保持、六項 focused 真正通過，Tester／Reviewer／最後行政窄複核均 approved、required fixes0。兩項 skipped 為可信歷史 captured context 與 pinned 公開 DER 材料缺口，非已確認 Runtime failure／required fix；原189/8等歷史及所有真人限制不回寫。完整來源／flags／結果與最小必要材料見[固定補測證據](https://github.com/a129924/rivet/blob/4c2153963fe7c41cc36b56f2a4fe3ae3b79ba6c2/plan/github-oauth-credential-persistence/evidence/live-preparation-tests.md)。

Annotated tag `v0.1.63-verification-artifact-ownership` 已建立並推送；local／remote tag object 同為 `c5039b06d294a1cd0139fba2528ee5e09d886ede`，peeled commit 精確為上述 merge。它不指向後續文件 commit，也不是 GitHub Release；沒有新增真人 OAuth／API／DPK、fixture 或 pin 更新。

原 `chore/verification-artifact-ownership` local／remote branch 已在核對相同 a4c4f6b、merge lineage 與 tag 保存後正常刪除，未 force。兩份索引的本次事實更新由 `docs/verification-artifact-ownership-postmerge` 後續文件分支交付；沿用原 managed worktree 完成，未在 dev 工作樹實作，worktree 只在文件安全提交／推送後移除。其他 worktree 與 E010 獨立收尾工作不動。

## 既有實驗與已合併交付

| 編號 | 驗證問題 | 目前可支持的結果 |
| --- | --- | --- |
| [E001](E001/README.md) | OAuth App 的瀏覽器／loopback callback | 成功：真實授權取得非空 code、state 相符；未交換 token。 |
| [E002](E002/README.md) | S256 token exchange 與 credential 相容性 | 正向 exchange、六欄 schema 與一次 API 成功；反向 PKCE 及總體無法判定，2/2 授權用盡。 |
| [E003](E003/README.md) | 遠端 refresh 與 rotation | T01–T04 成功：初始 API、新 token pair、相同帳號 API、舊 refresh token 明確遭拒。 |
| [E004](E004/README.md) | GRDB／SQLite 與 provider lifecycle | 本機真磁碟、跨程序、原子輪替與失敗處理成功；fetcher／clock 為 fake，未驗證真 GitHub 或秘密保護。 |
| [E005](E005/README.md) | 免費 legacy Keychain 完整 bundle 與提示 UX | 最後 human-only 輪資料機制成功、候選 UX 失敗：真正重建讀回出現一次提示。 |
| [E006](E006/README.md) | 免費 Personal Team／DPK 與重建 UX | 2026-10-19 受限輪資料機制與 UX 成功；有效 profile、同身分／同機條件限定，使用假 OAuth bundle。 |
| [E007](E007/README.md) | 同身分 profile 更新後 DPK 讀回 | 兩輪無法判定；renewal read 均未執行。Human 接受此未知限制，不升格為驗證成功。 |
| [E008](E008/README.md) | missing-verifier 拒絕的 PKCE 歸因 | 無法判定：HTTP400 拒絕、無 token；provider 要求 enum 一致，當次因果判讀分歧，1/1 用盡。 |
| [E009](E009/README.md) | 手動獨立 browser 的首次登入／同意／帳號結果 | M03 在 Human 回報與來源契約層級受限成功；M04 建置與 mock 檢查不構成另一次真人成功。 |
| [E010](E010/README.md) | DPK profile 自然到期後原假憑證恢復 | W1 seed／fresh 六欄相符、Human 各全程0提示，僅受限 baseline 成功；W2 真到期／P1、W3 Rebuilt 與完整週期待驗，RP cleanup blocked。 |
| [E016](E016/README.md) | 正式本地 signOut／精確 credential clear 的獨立 DPK first／fresh 驗收 | PR #72 已合併；bb6752a 真 DPK／synthetic 兩程序有限成功，Human 各完整觀察 zero；舊停點／已耗額度與 configuration／sentinel 殘留保留，不代表真 OAuth／UI 或普遍環境。 |
| [E017／PR #73 PAT 儲存](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/experiments/E017/github-pat-dpk-storage/README.md) | 正式 PAT adapter 的獨立儲存驗收host | source5465原E016路徑真DPK六runtime accepted／Human各全程0；現E017只做離線改號驗證，不冒稱新live pass，HC04／HC05 pending。 |
| [GitHubConnectionVerification](E014/GitHubConnectionVerification/README.md) | 獨立驗證 App 的登入、保存、重啟、重建、受控到期真刷新、輪替後讀回與 API | PR #62 的受限可行性結果；真 GitHub／儲存、fake-only 測試與受控觸發分開，不等正式產品登入。 |
| [PR #60 正式 OAuth 憑證儲存](https://github.com/a129924/rivet/pull/60) | 正式 adapter 的完整假 bundle 保存、跨程序、整筆替換與同身分真正重建 | 2026-11-05 指定環境真 DPK 受限通過；五 runtime Human 全程0提示，獨立審查核准；不代表真 OAuth／遠端 refresh／API 或完整產品登入。 |
| [PR #66 原生登入 UI／Demo](https://github.com/a129924/rivet/pull/66) | 原生 Presentation 元件、假資料 Demo 與 Human 驗收 | 2026-11-11 指定聲音、大字與焦點案例通過，Human明確採用。正式 backend／OAuth 串接屬後續能力。 |
| [PR #75 正式 Login UI 元件化](https://github.com/a129924/rivet/pull/75) | 選擇性採用、phase／intents 契約、局部互動與獨立驗收支援 | 已合併；HC01／HC02按各自版本接受，E011凍結、Canvas未驗；真認證／session／產品接線不在本題。 |
| [PR #71 OAuth／PAT 雙登入契約](https://github.com/a129924/rivet/pull/71) | GitHubIntegration 的請求 VO、共同 Protocol 與受控結果 | 正式 non-BC 技術契約；success 無帳號／session／clients，未交付真登入，不新增 E 編號。 |

結果的證據層級、主要缺口與決策限制另見 [驗證總覽](VALIDATION-SUMMARY.md)。本索引不授權執行任何 README 中的重現命令、新 OAuth、重試或秘密清理。

這份導覽以 [PR #62](https://github.com/a129924/rivet/pull/62) 合併點 `aa16de91` 為 E001–E007 與持續連線 App 的來源快照，另補已合併 [PR #61](https://github.com/a129924/rivet/pull/61) 的固定來源 `14d0832f`，以及已合併 [PR #63](https://github.com/a129924/rivet/pull/63) 的固定來源 `fccaf2b6`；各來源當時的產品 UI 範圍依原版本閱讀。前輪整合另保留 `613a505025774b3841ab73b4ed3b8774be38274a` 內已合併 PR #65／E008 的後續事實；不以後輪結果回填先前輪次。本輪保留 PR #60 正式憑證儲存的合併紀錄，另列 PR #66 原生登入 UI／假資料 Demo 的合併與 Human 採用事實。

## PR #61：正式初次 OAuth 與獨立登入驗證

[正式能力與驗證 App 歸屬](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/docs/architecture/github-first-sign-in.md)及[X 收尾安全證據](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/plan/github-first-sign-in/evidence/pkce-semantic-review.md)固定引用 PR #61 合併點；實際工具來源仍是 `4dbf3df`。`GitHubIntegration` 留下正式初次 OAuth 能力，`GitHubSignInVerification` 收納驗證外殼；該來源當時正式 Rivet 產品登入 UI 尚未交付；目前產品入口依其自身工作線判讀。X 已完成 native 正常 copy／Human 手貼核對及唯一 wrong 單交換：HTTP400 invalid_grant、無 token，兩獨立 AI 對 provider 描述一致判為 verifier mismatch claim。這僅支持該次負向觀察，原自動 indeterminate／proof=false 不改；新 X 1/1 用盡，不再執行授權或研究。與 PR #62 的持續連線 App／refresh 證據分開，E002 及 missing 歷史無法判定不回改。

## PR #63／E009：手動首次登入的受限結果

[PR #63](https://github.com/a129924/rivet/pull/63) 已於 2026-10-22T03:51:18Z 合併，合併點 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`、最後 feature head `fe9af0dbbbbf2cf72befd45fec23488e5ebf55c2`。[E009 保存紀錄](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/experiments/E009/README.md)與[長期結論](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/github-account-login-feasibility.md)固定引用該合併點；它不是 M03 真人執行 build。

M03 的四項判準於 Human 回報層級受限成功：看到登入、完成登入、看到並同意授權、同流程有效帳號。Human 另確認獨立 session 原先未登入、帳號先前未授權，以及同一次新版手動流程、300 秒內、未重啟／再啟動／改用舊網址。Agent 沒有全程 UI 或 network trace；詳見[分層摘要](VALIDATION-SUMMARY.md)。C01 對 L01 的撤回、A07 及反向 PKCE 歷史原樣保留。

M04 已交付同 repository 的驗證 host、必要 runtime／tests 與一次性開發端 launcher；之後兩次同步 dev 的合併只處理相容性與相關 mock／build 核驗，沒有新的真人 OAuth。這些工具與結果不代表正式產品入口、production secret custody、持久化或普遍 PKCE enforcement 已完成。

#63 的收尾已完成：annotated tag `v0.1.57-github-account-login-feasibility` 指向 `fccaf2b6`，原 topic local／remote branch 與 managed worktree 已正常移除，未 force。當時由 Draft PR #64 交付、尚未合併的文字保留為提交前快照；#64 現已合併，實際收尾見下節。未吸收並行 topic 成果。

## E008 交付事實

[PR #65](https://github.com/a129924/rivet/pull/65) 已於 2026-10-22 合併並關閉，目標為 `dev`，merge commit 為 `0276ff3385495ed7fb0444e02b3b6da0757dd17a`。執行來源仍是 `d067c2c6adad7b1bcb19639c3f0ca58fc437e251`，結果提交為 `0644fdda1fb6bd9bb4fe5e4b064d3e97d65b59ad`；合併不改寫原結果。

E008 驗證紀錄任務已完成，但主要假設仍無法判定；單次預算已耗盡，不追加判讀者、OAuth 或研究。正式 OAuth 與歷史證據保持原契約，原始描述未寫入 repo 或檔案。詳細有限資料見 [安全 JSON](E008/safe-result.json) 及[封存語義結果](../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json)。

## PR #64 合併與收尾（2026-11-03）

[PR #64](https://github.com/a129924/rivet/pull/64) 已合併並關閉，GitHub `mergedAt` 為 2026-11-03T06:04:24Z；merge commit `71d395cc9ca3cfe645b13a93ee0e83f22c255edd`，最後 feature head `572e366e03471324cd745a4e4a103d19374e5009`。兩索引已隨該 PR 納入 dev；合併不改寫各實驗原結果。

R64 的來源範圍契約與 E006 措辭兩項回修已交付；獨立 Tester 22／22、Reviewer approved，兩個評論 thread 已由主方讀回 resolved、未解決數0。E006 僅支持「切換至 Rebuilt configuration 真正重建」，不稱 Clean；PR #62 的獨立 App 真正 Clean／Build 證據保留。原 D／R64 的 pending 文字是當時快照，不代表本次交付仍待執行。

Annotated tag `v0.1.59-github-connection-validation-summary` 已推送並核對 peeled commit 為上述 merge，未指向後續維護 commit，亦非產品 release。原 `docs/github-connection-validation-summary` local／remote branch 與本輪 feature worktree 已正常移除，無 force／prune；其他 feature worktree、App、Keychain／Apple 資產未動。完整分層與限制見[驗證總覽](VALIDATION-SUMMARY.md)。


## PR #60：正式 OAuth 憑證儲存（2026-11-10）

[PR #60](https://github.com/a129924/rivet/pull/60) 已合併關閉，GitHub `mergedAt=2026-11-10T03:30:48Z`，merge commit 為 `c8c989a2e4be99e73c9cdc17e82cc16ada7a489c`，最後 feature head 為 `89bd01a27375137fb76ae1933efe6d4b7a36d23d`。兩親 merge 的 tree 與最後 feature 相同；固定引用[正式儲存契約](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/docs/architecture/github-oauth-credential-persistence.md)、[LG81-Cap-R 獨立審查](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/live-preparation-review.md)及[逐段 live／Human 紀錄](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/live-validation.md)。合併點是保存版本，不冒充真人 build 或新量測。這是正式 adapter topic，不新增 E 編號，也不吸收 E007／完整登入工作。

`GitHubOAuthDataProtectionStores` 是 caller-owned 正式 DPK adapter。Fake Security／受控 provider 只驗 codec、錯誤分類、完整替換與 rotation 保存失敗停止；真 DPK 的完整假六欄驗收則於 2026-11-05 完成：A 保存→Writer 結束→fresh Reader A→整筆替換 B→fresh Reader B→同身分真正 clean/build→新程序還原 B，五個 runtime Human 均全程觀察0提示，經獨立審查通過。[非真人整合測試](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/tests.md)與[成果審查](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/review.md)另列，不能當真遠端 refresh／OAuth／API。建置／簽章提示依各段原文，不將首 sign 的 permission-only 觀察擴成所有提示0次。

本輪真 DPK 只驗 credential item、完整假 bundle 及原指定同機／簽章／有效 profile 條件；不推論 configuration item live、profile 更新／過期恢復、certificate rotation、系統拒絕、斷電 durability、所有環境或產品採用。LC06 的 DPK item 清理、圖 Human visual 與 S08 接受未因此完成。E004 的 SQLite／合成控制界線、E005 的 legacy 0／0／1 UX 失敗、E007 renewal unknown 及所有舊成功／失敗／unknown／額度原樣保留。

已核 annotated tag `v0.1.60-github-oauth-credential-persistence` 的 local／remote object 與 peeled merge `c8c989a2e4be99e73c9cdc17e82cc16ada7a489c` 一致；標籤不指後續文件維護 commit，亦非 GitHub Release。兩個原 Xcode 個人 metadata 已於 Git 私有 archive 原樣保存並讀回 bytes／SHA／權限後移出原位置，未 track／push，未清 DPK 或 Apple assets。此段記錄文件準備時已完成的部分；原 feature branch／worktree 移除仍須待文件安全存入遠端及 fresh gates，本文不預填尚未發生的刪除。


## PR #66：原生登入 UI／Demo 與 Human 採用（2026-11-11）

[PR #66](https://github.com/a129924/rivet/pull/66) 已合併並關閉，GitHub `mergedAt=2026-11-11T06:55:06Z`，merge commit 為 `2c7679a8399f634dc6429fcd8bfd6018a5a0693f`，最後 feature head 為 `9eda244ff15c3928eedad2731d3680c52473d17f`。本節記錄 non-BC `RivetPresentation` 的原生元件與七態假資料 `RivetLoginDemo` 交付。實際受測程式來源為 `dcc48b29686ab324fc19399ef607f462a507cce5`，backend／OAuth 串接維持後續能力。[元件與 Demo 操作](https://github.com/a129924/rivet/blob/2c7679a8399f634dc6429fcd8bfd6018a5a0693f/docs/presentation/login-ui.md)

2026-11-11 Human 明確回覆「通過，採用目前這版」。本輪包含 PAT 驗證中自動狀態、Welcome／真 Retry 兩個 waiting 入口的清楚狀態與無明顯重複、Cancel／Escape 返回及主按鈕朗讀，還有 Demo 局部 21pt 五畫面、17pt 同 PAT 表單保值／focus 與 13pt rapid 回歸。舊無聲／診斷、後續 AX 時序、15格工具矩陣與原1009d高對比／Reduce Motion等證據保留各自來源。[Human 採用及實際驗收範圍](https://github.com/a129924/rivet/blob/2c7679a8399f634dc6429fcd8bfd6018a5a0693f/plan/rivet-login-ui/evidence/verification.md)

Annotated tag `v0.1.61-rivet-login-ui` 已正常建立、推送並核對 local／remote object 與 peeled commit，精確保存上述 PR merge。原 `feat/rivet-login-ui` remote branch 已在確認仍為9eda244後正常刪除，原 managed worktree 及 local branch 隨後正常移除，目錄、註冊與該分支 tracking ref 皆已核不存在。其餘兩個 worktree 註冊保留。Tag 的保存範圍止於 merge2c7679a，後續 experiments 文件維護使用獨立版本。

## E010：W1 baseline 受限完成，完整自然週期待驗（PR #67 尚未合併）

本節分列尚未合併的 [PR #67](https://github.com/a129924/rivet/pull/67)，不混入上游已合併結果。首筆遷移 commit `819b26d20272cfcc9e664c4dccba867bcd34c92d` 保存 E010 活動身分、22 原檔快照、158 evidence／13 frozen GUI 與 typed map；原 DPK E008 只作歷史，現行 E008 PKCE 子樹保持原樣。[活動入口](E010/README.md)與[引用對照](E010/history/renumbering-map.json)分開歷史 receipt 與活動 source；五個歷史 source 版本缺失仍為 unknown。

原 10/21／10/22 兩輪 closed run 因 host／product provenance 不足停止，當時沒有 App/SecItem/seed 或跨週 item；零 item 私有檔案清理不是 DPK delete/read-absent。其後 2026-11-10 的新 W1 已完成一次 seed 與一次 fresh，六欄相符，Human 各全程觀察0提示，僅支持本輪 baseline 機制與限定 UX。來源見[最新22-source manifest](E010/evidence/ng-date-preparation-20261110/source-manifest.json)、[W1 baseline](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/index.json)及[close addendum](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/close-addendum.index.json)；原 canonical prompt unknown 與記錄時點 pending flags 不覆寫。

W2 真自然到期／P1 讀回原 A、W3 Rebuilt 與完整 profile 週期仍 pending。P0 expiry 為台灣 **2026-11-17 15:28:08**，原 D 為 **2026-11-20 15:22:03.379959**，不延長、不重設 A／namespace。RP cleanup 仍 blocked／delete=0；[RT index](E010/evidence/retention-scope-20261110T094256Z/index.safe.json)記錄4602 retained metadata entries，不是 minimum 完成，也不解除 RP blocker。

三筆 `01265ad`／`c0e6414`／`d30f5c4` 共312檔已正常發布。2026-11-11 查核時，PR #67 為 Ready for review、尚未 merged。E001–E009、E005 UX 失敗、E006 受限成功及各輪 unknown／逾時歷史保持；E010 不藉此核准新的正式 adapter 採用、產品登入或公開分發。

## E017 — PAT DPK 儲存

[`github-pat-dpk-storage`](E017/github-pat-dpk-storage/README.md) 專屬驗證 host 直接使用正式 PAT adapter；工具現由 E016 搬至 E017，E016 保留給 [PR #72](https://github.com/a129924/rivet/pull/72)。來源 `5465d3c`／run `39c22b57` 的原 E016 路徑 在指定有效簽章環境完成 A→fresh A→整筆 B→fresh B→真正同身分 clean/build→rebuilt fresh B→exact-owned cleanup／load=nil；六 runtime accepted、Human 各全程 0 提示，setup／rebuild 另各 0，獨立 P07 approved。圖與 topic Human 最終接受仍 pending；舊 unknown 原樣保留，與 E015 OAuth 歷史結果分開，不新增產品登入。

本次只調整 PAT 工具歸屬；[移轉 mapping 與兩條證據鏈](../plan/github-pat-dpk-storage/evidence/e016-e017-relocation.md)保存原 commit links。既有真人結果與 evidence 的 E016 source keys／hash 不變，不表示 E017 新來源已完成 live 驗收。


## PR #67：合併與受限 Git 收尾（2026-11-11）

上方 E010 段落及其中「Ready／尚未 merged」保留為合併前查核快照。[PR #67](https://github.com/a129924/rivet/pull/67) 已合併並關閉，GitHub `mergedAt=2026-11-11T08:48:57Z`（台灣16:48:57）；actual merge 為 `a554a4fee772d3976d5ca2c9331865a604e901e2`，最後 feature head 為 `7fa4bfffc5989a351790dca6a1695758c906950c`。兩親 merge 保存相同 feature tree，只證明交付版本已納入 dev，不是新的實驗量測、完整週期通過或新的正式 adapter 採用。[Active 修正 6504801](https://github.com/a129924/rivet/commit/6504801b3b43a6ae937cbd898d9354d53ffc8543) 已交付 GUI recovery selection 來源與 Swift probe 參數檢查；兩個 review threads 均已回覆並 resolved，未解決數0。[新22-source manifest](E010/evidence/pr67-review-fixes-20261111/source-manifest.json)的 aggregate `d253834a…` 與[獨立 Tester 收據](E010/evidence/pr67-review-fixes-20261111/tester-validation.json)只歸屬 active 純修正；舊 W1 frozen source `b8c567…`／grant 未升級，未作 live migration，frozen recovery 是否觸發舊 bug 仍 unknown。

W1 仍只支持一次 seed／一次 fresh 六欄相符、Human 各全程0提示的受限 baseline；W2 真自然到期／P1 讀回原 A、W3 Rebuilt 與完整 profile 週期仍 pending。P0 expiry 為台灣 **2026-11-17 15:28:08**，原 D 為 **2026-11-20 15:22:03.379959**；原 A／namespace 不重設，期限不延長。RP cleanup 仍 blocked／delete=0；RT 的4602 retained metadata entries 不是 minimum 完成。Git 合併不改判 E001–E009、原失敗／unknown 或上述限制。

Annotated tag `v0.1.62-e010-dpk-profile-continuity-baseline` 已正常建立、推送並核對 local／remote tag object `53f1efd44b4d4cdbf0b2ada8752620a2b667e8b5` 與 peeled commit，精確保存上述 merge；不是 GitHub Release 或後續文件版本。原 `chore/github-oauth-dpk-profile-continuity-feasibility` remote branch 已以 expected head `7fa4bff…` 的 server lease 正常刪除，並讀回不存在；dev 與 tag lineage 保留。Local branch／原 managed feature worktree 仍保留，因兩份 AQ local-only 診斷檔尚在、W2／W3 實際 physical path 依賴仍 unknown，未強制移除或搬檔；外部72檔 handoff archive 未改，亦未清理 App／Keychain／Apple 資產。

## E010 本輪結案（2026-11-18）

前述 E010 待執行與 PR #67 合併段落均為當時的歷史紀錄。PR #67 已合併，annotated tag `v0.1.62-e010-dpk-profile-continuity-baseline` 指向原合併版本 `a554a4fee772d3976d5ca2c9331865a604e901e2`，原始 W1 證據保留於該版本。

- **W1 受限基線**　一次 seed 保存假憑證 A，再以同一 binary 於新程序讀回原 A 一次，六欄全部相符。Human 在兩階段各全程觀察，提示各為 0 次。[W1 機器與 Human 證據索引](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/index.json)、[seed 安全索引](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/seed-review-candidate/index.json)。
- **本輪決定**　W2（P0 自然到期後以 P1 讀回原 A）與 W3（Rebuilt）均未執行，完整 profile 週期未完成。依 Human 決定結束本輪，W2／W3 不再續行，也不啟用新的 recovery host。結案與後續復原評估的本機封存證據尚未發布。
- **清理與交接**　結案清理未執行，清理及最小化均未完成，`recoveryRequired=true`。目前 A 是否仍在及完整殘留範圍均未確認。沿用既有最低限度復原交接，原 D 維持 **2026-11-20 15:22:03.379959（Asia/Taipei）**，整包留存未獲延長。[歷史 RP 受控停止索引](E010/evidence/retention-prune-validation-20261110T085343Z/final.index.safe.json)、[歷史 RT metadata 索引](E010/evidence/retention-scope-20261110T094256Z/index.safe.json)。

## PR #68 合併與 Git 收尾（2026-11-18）

PR #68 於 2026-11-18 14:57:36（Asia/Taipei）合併至 `dev` 並關閉。實際合併提交為 `ed1825d4194ba329eb785b2f6192618e23d6475a`，最後來源提交為 `57a1b1753537fd49fcfbb19764f65768bdfdd1b5`，兩者的文件樹一致。[PR #68](https://github.com/a129924/rivet/pull/68)、[已發布的結案紀錄](https://github.com/a129924/rivet/blob/ed1825d4194ba329eb785b2f6192618e23d6475a/experiments/VALIDATION-SUMMARY.md)。

Annotated tag `v0.1.69-e010-documentation-closeout` 已推送。本機與遠端的 tag object 均為 `a36075b5b2ae60018ee0211a8a9ef6e38f8152d3`，解參照後皆指向上述 PR #68 合併提交。原 W1 基線標籤 `v0.1.62-e010-dpk-profile-continuity-baseline` 仍指向 PR #67 合併提交 `a554a4fee772d3976d5ca2c9331865a604e901e2`。

原 `docs/e010-postmerge-registry` 遠端分支已用最後來源提交做租約保護後刪除。本機分支與原 managed worktree 已正常移除，已核對本機、追蹤及遠端分支參照與原 worktree 的目錄及註冊均不存在。

E010 依 Human 決定結束本輪。W1 受限基線為一次 seed 保存假憑證 A、一次以同一 binary 於新程序讀回 A，六欄相符，Human 在兩階段各全程觀察且提示各為 0 次。W2／W3 均未執行，完整 profile 週期未完成，本輪不再續行或啟用新的 recovery host。[W1 證據索引](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/index.json)。

實驗結案清理未執行，清理及最小化仍未完成，`recoveryRequired=true`。目前 A 是否仍在及完整殘留範圍均未確認。沿用既有最低限度復原交接，原 D 為 **2026-11-20 15:22:03.379959（Asia/Taipei）**，整包留存期限未獲延長。

## E018 — 正式 OAuth 冷啟動還原 live（2026-11-18）

[歷史驗證host與界線](https://github.com/a129924/rivet/blob/0debe0b8c088e60500b4a1e4969000666e495c97/experiments/E018/README.md)直接使用正式GitHubOAuthStartupRestorer／stores／fetcher。First自然到期真refresh/save各1後ready，fresh新程序同完整credential／同帳號且refresh/save0；Human兩段全程各0提示。新host AppID不同於舊E014，未重跑舊App或profile延續性實驗。兩live slots用完，停止重試；[安全證據](../plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)與Human最終接受分列。

E018 active 工具已退役，後續測試設施見 [正式 hosted integration tests](../Tests/GitHubIntegrationHostedTests/README.md)。歷史結果與額度不轉移至新設施。
