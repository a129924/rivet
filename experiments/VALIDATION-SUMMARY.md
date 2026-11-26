# GitHub 連線驗證結果摘要

基礎結果彙整日期：2026-11-11；PR #69 合併／版本事實更新：2026-11-13；PR #71 契約、PR #72 本地登出與 PR #73 PAT 儲存合併事實更新：2026-11-16。原生登入 UI／Demo 與各輪 Human 採用、E010 原記錄時點狀態保持；分列雙登入契約及本地登出／E016 的交付事實，不擴張其他實驗結果。 PR #74 runtime 合併與 Git 收尾事實更新：2026-11-17。 PR #76 可行性方案合併與 Git 收尾事實更新：2026-11-17。 PR #75 Login UI 採用、驗收分離與 Git 收尾事實更新：2026-11-18。

來源基準為 [PR #62](https://github.com/a129924/rivet/pull/62) 於 2026-10-21T06:56:54Z 的合併點 `aa16de91b560027325419b7bc904d831851c9fcb`。E001–E007 與持續連線段落保留該來源；另於下節補已合併 PR #61 的固定來源 `14d0832f042720889993d769b4cbfb720078e6b1`，並補 PR #63 的合併點 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`。本次於 2026-11-03 整合 `613a505025774b3841ab73b4ed3b8774be38274a` 內已合併 PR #65／E008 的後續事實。本次保留 PR #60 的固定來源，另納入已合併 PR #66 的原生 UI／Demo 及 Human 明示採用結果。[導覽](README.md)列出各來源入口。

## PR #101 Rivet 視覺語言採用與整合驗收

PR #101 於 `2026-11-26T07:51:34Z` 合併至 `dev` 並關閉。合併提交為 `e53214ed9327174c316724c4b8ba28e227526d4f`，最後 feature head 為 `2fde547722e6a4197fe755a05c76a5ce177e81de`。HC-05 審閱的 `144c20f` 交付共用四色及 branch glyph 和 Login 接線，最後 feature 提交只補結案帳本。 [PR #101](https://github.com/a129924/rivet/pull/101) · [結案帳本](https://github.com/a129924/rivet/blob/v0.1.97-rivet-design-language-adoption/plan/rivet-design-language-adoption/rivet-design-language-adoption.step.md) · [驗證證據](https://github.com/a129924/rivet/blob/v0.1.97-rivet-design-language-adoption/plan/rivet-design-language-adoption/evidence/cd-verification.md)

| 證據 | 結果與適用條件 |
| --- | --- |
| 視覺與原生操作 | 八組同 fixture、明暗、字級與尺寸的 Login 前後圖中，七組像素一致。Waiting 的 1,288 個差異像素限於轉圈動畫。以合成輸入驗證 PAT 編輯、顯隱、原生焦點、Retry／Escape、捲動與 disabled；Increase Contrast 檢查亦通過。Human 回報三組 VoiceOver 實聽通過，獨立 CD04 核准。 |
| 隔離整合 | 以 `f556a65` 整合已採用來源。Presentation Debug／Release、套件隔離與 root 589 項測試／72 suites 通過。實際合併當時的 `dev` 為 `5127b5d`，與包含結案帳本的預測合併樹相比，差異只有兩份實驗索引；產品來源、測試、套件與 Presentation 契約一致。 |
| 審閱資料 | PR Lens 驗證並渲染 Ready head `2fde547` 的本機變更圖。五個核准 Swift 檔案的 Graphify AST 摘要與該 head 核對一致。 |
| 驗收界線 | SwiftPM bundle fallback 未獨立隔離。Variant B 的七項原生缺口留給未來 PR Inbox topic，正式 Inbox 仍待自有 Plan Amendment 與獨立 Plan Review。 |

語意 annotated tag `v0.1.97-rivet-design-language-adoption` 已推送並讀回。本機與遠端的 tag 物件均為 `35b61bdec426c18f222bd4c107a01dace5193e69`，解參照後指向合併提交。本機、遠端、遠端追蹤分支及 feature worktree 的目錄與 Git 註冊均已移除。 [實驗索引](README.md#pr-101-rivet-視覺語言採用與清理) · [語意 tag](https://github.com/a129924/rivet/tree/v0.1.97-rivet-design-language-adoption)

## PR #104 PR Reader 行內留言來源選擇與離線驗收

PR #104 於 `2026-11-26T07:39:37Z` 合併至 `dev` 並關閉，共變更 7 個檔案。合併提交 `f556a65f64ed9fef0b0958d82d6e83d4efd30844` 與受測的 feature 提交 `04b553673eb671da26ba4a08b7f2b12fbb8a466f` 的 Git tree 相同。 [PR #104](https://github.com/a129924/rivet/pull/104) · [執行帳本](https://github.com/a129924/rivet/blob/v0.1.96-pr-reader-github-inline-review-source-selection/plan/pr-reader-github-inline-review-source-selection/pr-reader-github-inline-review-source-selection.step.md)

| 證據 | 結果與適用條件 |
| --- | --- |
| 讀取契約 | GraphQL 完整結果優先，完整空清單也算成功。只有 GraphQL 回 `.unavailable` 且 Task 尚未取消時才改讀同一 PR 的 REST。驗收確認兩種來源原序、REST 平面留言與 thread 狀態缺席、來源重疊、後頁失敗及取消後捨棄晚到結果。 |
| 獨立驗收 | IS01–IS06 通過。Reader SwiftPM 回歸 171 項測試、16 組通過，含 9 項新測試。嚴格 Swift 格式、585 檔 SwiftLint 零違規、差異檢查及提交鉤子均通過。獨立規劃與成果審查均核准。 |
| 本機審閱 | PR Lens 0.11.0 依實際 PR base 與 head 驗證並渲染一張 SVG。Archify 通過 showcase 9/9、四種桌面尺寸與亮暗目視檢查。Show Me 呼叫樹與受控請求一致。Floorplan 涵蓋 956 個程式檔，標示 2 張本題卡片。Graphify 無可追溯的既有圖，採原碼核對。 |
| 驗收界線 | 使用受控 GraphQL 和 REST 回應進行離線驗收。實際 GitHub.com API 呼叫、完整快照組裝及產品接線留待後續驗證。清理階段沿用上述受測版本及證據。 |

語意 annotated tag `v0.1.96-pr-reader-github-inline-review-source-selection` 已推送並讀回。本機與遠端的 tag 物件均為 `ffdad58e9d604fad764431e3a020e0ea207c748a`，解參照後皆指向合併提交。已核對本機、遠端及遠端追蹤分支、feature worktree 目錄和 Git 註冊均已移除。停止該工作樹的 Floorplan 預覽後，私下封存 126 個本機檔案，並逐檔核對 SHA-256、大小及權限模式。 [實驗索引](README.md#pr-104-pr-reader-行內留言來源選擇與清理) · [語意 tag](https://github.com/a129924/rivet/tree/v0.1.96-pr-reader-github-inline-review-source-selection)

## PR #99 PR Reader 行內審閱留言端點與離線驗收

PR #99 於 `2026-11-25T10:01:44Z` 合併至 `dev` 並關閉，共變更 7 個檔案。合併提交 `64d0ce9f70c2abaeca7e2ec7204aab9a92add419` 與離線受測的 feature 提交 `680853ab989842e4b64a8070f492388c5e8e1917` 的 Git tree 相同。 [PR #99](https://github.com/a129924/rivet/pull/99) · [執行帳本](https://github.com/a129924/rivet/blob/v0.1.92-pr-reader-github-inline-review-comments-endpoint/plan/pr-reader-github-inline-review-comments-endpoint/pr-reader-github-inline-review-comments-endpoint.step.md)

| 證據 | 結果與適用條件 |
| --- | --- |
| 端點契約 | 核對 `GET /repos/{owner}/{repo}/pulls/{number}/comments`、同一 PR 的首頁和第 2 頁 URL、頁碼 31 與 `Int.max`、固定 `per_page=100`，以及無效 PR 識別或非正數頁碼的拋錯。 |
| 獨立驗收 | Reader GitHub 套件 101 項測試、10 組全數通過，含 5 項新端點測試。Swift 格式、217 檔 SwiftLint 零違規、差異空白檢查及提交鉤子均通過。獨立成果審查核准，無必修項。 |
| 本機審閱 | PR Lens 0.11.0 依實際 PR base 與 head 驗證並渲染一張 SVG。Archify 通過 showcase 9/9、四種桌面尺寸與明暗目視檢查。Show Me 呼叫樹與實作相符。Floorplan 涵蓋 586 個程式檔並標記 1 張本題卡片。Graphify 缺可追溯的既有圖，已用原碼核對。 |
| 驗收界線 | 本輪以離線測試驗證同步 URL 建構。HTTP 執行、續頁讀取與留言映射由後續 Adapter 交付。 |

Annotated tag `v0.1.92-pr-reader-github-inline-review-comments-endpoint` 的本機與遠端解析均指向合併提交。已核對本機、遠端及遠端追蹤分支，以及 feature worktree 的目錄與 Git 註冊均已移除。停止該 worktree 的 Floorplan 預覽後，私下封存 68 個 Floorplan、13 個端點驗證與 Archify、5 個 PR Lens 檔案，逐檔核對 SHA-256、大小與權限模式。 [實驗索引](README.md#pr-99-pr-reader-行內審閱留言端點與清理) · [語意 tag](https://github.com/a129924/rivet/tree/v0.1.92-pr-reader-github-inline-review-comments-endpoint)

## PR #78 PR Inbox 自查候選與 E020 真人結果（2026-11-23）

[PR #78](https://github.com/a129924/rivet/pull/78) 已於 `2026-11-23T06:47:33Z` 合併至 `dev` 並關閉。合併提交為 `6ac0ae02b63db99e4f0a8cb0ee65edeb6f399559`，最後 feature 提交 `bd01556` 收錄 E020 真人驗收紀錄。

| 證據 | 結果 |
| --- | --- |
| 正式自查來源 | `GET /user` 確認 OAuth 帳號後，以 `is:pr is:open author:<login>` 查詢。既有 Facade 依作者及開啟狀態篩選，包含自己開的 open Draft。受控驗證通過 365 項 Swift 測試及 12 項 E019 回歸測試。 [PR Inbox 契約](../docs/architecture/bounded-contexts/pr-inbox.md) |
| E019 直接指派 | 保留既有受控結果。真人查詢未執行。 [E019 原紀錄](E019/README.md) |
| E020 瀏覽器 OAuth 真人驗收 | 以 `9e4bd9b` 的來源在本機完成登入及單筆驗收。Human 確認可用 `a129924` 在 GitHub 開啟 mlops-async#72。Facade 回傳該 PR，owner、repository、number、title 四欄一致。CLI 回報 `sampleMatched`、exit 0、`getCount=2`、`queueCount=7`。 [E020 驗收紀錄](E020/README.md) · [正例 PR](https://github.com/a129924/mlops-async/pull/72) |

真人驗收涵蓋當次帳號與該筆正例。自查完成狀態仍待定義。上述受控及真人證據均沿用原受測版本。

Annotated tag `v0.1.72-pr-inbox-self-review-candidates` 已推送並讀回，指向上述合併提交。原 feature worktree 的 Floorplan 已私下封存並核對 73 檔。原本機分支、遠端分支、追蹤 ref、worktree 目錄及 Git 註冊均已核對移除。

## PR #77：正式 OAuth 冷啟動還原與 hosted 有限結果（2026-11-18）

[PR #77](https://github.com/a129924/rivet/pull/77) 於 `2026-11-18T09:32:51Z` merged／closed 至 `dev`。Merge `b9f969f05347e8c4227fb742205814bef95f7604` 的 parents 是 `0087cb404b652cb0565fe6482474e4b6b668e7ba`／最後 feature `cab8ba4fd9d0485b081828865abeacb815478172`；與 feature 僅兩份實驗索引不同。Merge／tag 保存來源，不代表新 build 或新的 live 受測版本。

| 證據層級 | 已支持事實與限制 |
| --- | --- |
| 正式 Sources | Caller-owned `GitHubOAuthStartupRestorer` 沿既有 stores／fetcher／provider／scope 還原既存 OAuth 連線，必要完整保存後才 ready；有限結果、busy、取消收尾與同 provider 重試由[正式契約](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/docs/architecture/github-oauth-startup-restore-runtime.md)界定。不是新 BC，不含產品啟動／UI、重新授權或 PAT 連線。 |
| 原受控驗證 | M04 root 375 tests／46 suites、consumer 22／6 是原輪次親跑紀錄。N 修正後 27 mocks、完整 Offline 的 first／fresh 各 1 原生正向與 assertion／throw 各 1 預期原生負向通過聚合判定；不能當作真 OAuth／DPK。 |
| 原 E018 歷史 | Active E018 已退役。[原收據](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)保留 `0debe0b` 工具來源、first 自然到期真 refresh／save 各 1、fresh 同完整 credential／帳號與 Human 各全程 0 提示；舊 slots 已用盡。此結果不轉移到新設施。 |
| 正式 hosted N live | [新設施](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/Tests/GitHubIntegrationHostedTests/README.md)直接組裝唯一正式 runtime。First／fresh 各一次、各 1 passed／0 skipped、不同程序且退出，ready／API／完整 readback／configuration 保持通過；fresh 同完整 credential／帳號。兩段 Human 各獨立全程 0 提示、各綁原 machine SHA，沒有回填原 machine／pending 欄位。[N 結果與四份 safe／Human 收據](https://github.com/a129924/rivet/blob/b9f969f05347e8c4227fb742205814bef95f7604/plan/github-oauth-startup-restore-runtime/evidence/hosted-live.md)。 |
| Coverage | 兩段當時均未到期，prepare／final refresh、save 全 0，**沒有本輪真 refresh／rotation-save coverage**；不強制到期、不登入／seed／clear、不新增 Apple 資產。本次不是產品 E2E，不保證普遍 repository 權限、其他環境、profile 續期或 durability。 |
| 獨立審查與版本 | NR13 準備／N06 結果 approved、無 required finding。N source aggregate `7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`、actual artifact `bc78a4ab7c3bf85b7dbf179acef35e21bdff222e9148d6c55b0c4541da1afc9d`；`f68c386` 收錄同一工具修正。初回 nested path 與第二回 framework seal 的失敗準備保留；修後 inside-out preflight 與 actual phase 產物分列，未以新 root 重設額度。 |

適用當次同機／GUI user、既有 certificate／有效 profile／exact group 及唯一 owner；first／fresh 各 1/1 已用盡，停止額外操作。既有 OAuth runtime／contracts、原五份 E018 evidence 與 Human 觀察保持；合併不將原 artifacts 的 Human／圖面 pending 改判通過。原 E014、E010 等實驗的結果、預算與限制仍依各自來源。

語意 annotated tag `v0.1.71-github-oauth-startup-restore-runtime` 已建立／推送且讀回核符：local／remote object 同為 `49593cb67449ca8f84d587677345f4e5368320f3`，peeled 精確為上述 merge，不是新 live binary、後續索引 commit 或 GitHub Release。原 feature local／remote／tracking refs、managed worktree 目錄／registration 均已正常刪除並核 absent；expected-head lease 僅保護精確 remote 刪除，沒有 force removal／prune。Ignored Floorplan 19 檔先以原 bytes／mode／SHA 私有封存，未 track／push；外部私有 App、signed artifacts／run proofs、DPK／Keychain／Apple 資產未清理。

兩份索引在獨立 postmerge 文件工作樹更新並沿既有 safe fast-forward 慣例保存至 remote dev，dev 不直接編輯；文件 branch／worktree 尚待安全交付後另行清理。本次未另跑 root Swift suite 或新增 native／OAuth／DPK 驗收；正常文件提交 hooks（含 consumer contract）不當新 live 結果，歷史 evidence 不反寫。

## PR #75：Login UI 能力與驗收支援的分層證據（2026-11-18）

[PR #75](https://github.com/a129924/rivet/pull/75) 於 `2026-11-18T08:46:47Z` merged／closed 至 `dev`。Merge `e7a4b8422e524f59a7bfa1bb514838f2d829a8cb` 的 parents 是 `0a71be99759373606de9bd3994a30b2c5c3f40cb`／最後 feature `5167e4c454af9dbbba48a3b2be024d5b8528e088`；merge tree 與 feature 不同，保留上游兩份實驗索引更新。Merge／tag 是來源保存點，不能當作新的 build 或驗收版本。

| 證據層級 | 支持範圍與限制 |
| --- | --- |
| 正式 UI 能力 | `Sources/Presentation/Login/` 的公開 `RivetLoginView` 組合四個 internal 元件，重用 `.standard`；外層 phase／content、局部 PAT 編輯／Show-Hide／焦點與有限 intents 分責。Presentation 不依賴 GitHubIntegration，不建認證請求、不重建既有 Login VO。[長期契約](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/docs/presentation/login-ui.md)／[採用選擇與限制](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/docs/feasibility-adoption.md)。 |
| 直接 tests／controlled Preview | root focused16 tests／4 suites 中正式9 tests／3 suites、凍結 Demo7 tests／1 suite；tool8 tests／2 suites只證 parent／configuration，兩 product builds及局部靜態檢查通過。`#Preview` wrapper接收intent／更新受控phase，但實際Canvas連續操作仍未驗，compiled／unit／原生host不代替它。[T06與修後差異](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-testing.md)。 |
| 獨立原生差異 | 修後 code `9d14a3f6bf878a215de0d39d4fb05ec05970ec80`；source manifest SHA-256 `3e748de3a3b19225e1a03160d90318037a0be8430b13b911ec2e958b34bdd988`；binary `6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1`；app tree `ccfbbd965a9a8b40e4b3df22562f7542d02b2dc28a93f9a3b4a6df2988877cae`。F01–F06包含fresh Light／Dark、暫時排除build fallback下資源實載、必要鍵盤／焦點／PAT互動／大字捲動；fallback已還原、app未改。只支持所列環境／代表案例。[原生紀錄](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-native.md)／[runtime收據](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-runtime-receipt.json)。 |
| Human VoiceOver／接受 | V01返回Welcome讀到Continue、無晚到舊帳號驗證語音；V02返回PAT讀到區塊、可直接輸入、無晚到舊驗證語音。先前操作未完成／跨App焦點干擾仍保留，不當元件失敗或刪歷史。[Human聲音](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-voiceover-human.md)；[HC02](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-human-acceptance.md)明示「接受本輪驗收支援分離、封裝修正與差異補驗結果」，[獨立R07](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/plan/rivet-login-ui-adoption/evidence/acceptance-ownership-native-review.md) approved／無required fixes。舊HC01／4d binary接受仍屬其原版本；不外推所有race、語音或完整矩陣。 |

E011 是凍結歷史來源：基線 `d2332bfff25510a3f78c1fbc8b0d2d9cf953b223`、tree `b6a1e6e1196e64999af9591ec32f09211f1936c6`，本 PR 六項差異有界回復後，merge 對基線 E011 diff 為空。原plan允許修改的歷史及舊結論保留，未整目錄覆蓋或繼續維護它。Frozen consumer可編譯，但HEAD重建的現行正式預設文案不保證舊Demo模擬語意；歷史重現需完整舊revision／binary，沒有加正式demo mode。

驗收先用直接正式tests／controlled Preview；獨立視窗、選單、鍵盤／焦點及Human語音需要的原生環境才由 [tools/acceptance/login-ui](https://github.com/a129924/rivet/blob/e7a4b8422e524f59a7bfa1bb514838f2d829a8cb/tools/acceptance/login-ui/README.md) 組裝。同一份正式View由受控phase／content／onIntent驅動，工具自己的parent／config／fixtures不依賴E011，不複製View、不新增fake Service／DI，正式能力無反向依賴。乾淨正式文案與專用驗收選單分開。RF01／RF02 needs-rework與RF03封裝失敗／修正依原來源保留，不將修後通過倒填舊版。

**本輪能力完成程度**：正式UI元件化與驗收支援分離已交付，HC01／HC02各按受測版本獲Human接受；Canvas未驗仍是明列限制。**產品整合狀態**：真認證、外層Adapter／非同步協調、憑證儲存、session、登入後導覽與完整產品App組裝不在本topic。既有 `PersonalAccessToken`／`LoginRequest`／`LoginOutcome` 的對應由未來外層接線；Outcome只有成功／失敗／取消，不能單獨代表所有UI phase，成功呈現不保證session。其他topic已交付runtime／stores也不代表本UI已接通。

語意 annotated tag `v0.1.70-rivet-login-ui-adoption` 已推送並讀回，local／remote object=`054a9267fcedd730c8d56f9be1f6e272df726153`、peeled精確指向上述merge，不是後續索引commit或GitHub Release。原feature remote／local／tracking refs與managed worktree目錄／registration已正常刪除並核absent；remote expected-head lease僅保護精確刪除，無強制移除／prune。舊accepted Preview的3檔bytes／SHA／mode已核符封存Git私有archive、不track／push；新版外部App不動。兩索引由獨立 `docs/rivet-login-ui-adoption-postmerge` 工作樹編輯，dev只ff-only同步；文件安全提交推送後才清理該維護branch／worktree，不預填成功。本次僅整理事實，不重跑Swift／native／語音、不重寫舊證據、不吸收E010或其他工作線成果；[原feature清理與索引位置](README.md#pr-75正式-login-ui-選擇性採用驗收分離與清理2026-11-18)另列。

## PR #76：可行性／採用方案的證據與收尾（2026-11-17）

[PR #76](https://github.com/a129924/rivet/pull/76) 於 `2026-11-17T08:52:59Z` merged／closed 至 `dev`。固定 merge `ddfa281a2e73a65a1fa995a268b416115e988b68` 的 parents 是 `ab77391b73291deb1ce3d96cef72f981aeb3104a`／最後 feature `2ac31dc85bd92f1892c34e656ab77900524a97fe`，tree 與 feature 相同；主成果 `a2d2bba`、後續交付 metadata `2ac31dc` 均保存於 merge。來源查核基準仍為 `ab77391`，merge／tag 不是新 runtime 或 live 執行版本。

| 層級 | 已支持事實與限制 |
| --- | --- |
| 文件／原碼可行性 | 既有 configuration／store／factory／provider／scope／登入服務可支持有條件候選組裝；[source-audit](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/analysis/github-oauth-connection-orchestration/source-audit.md)區分事實、推論與缺口。正式 owner／世代交接、UI 接入與整條組合尚未實作，沒有新增 production／tests／package 變更。 |
| 採用程度 | [audit](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/analysis/github-oauth-connection-orchestration/adoption-audit.md) A01–A03 部分採用（primitives 已有、目標整合未接）、A04 未採用、A05 明確排除、A06 E014 來源關係不確定。[方案](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/docs/feasibility-adoption.md)交付不等於正式已採用；沒有整包搬入 E014。 |
| 閱讀既有測試 | 正式 signOut 測試定義含晚到 refresh／已開始 save 的兩 barrier；scope／login 定義支持有限判讀。PAT during-save barrier 不冒稱 OAuth-specific 親測。本輪不需新實驗，未建立新 E 編號，不把閱讀或 build 當假設成功。 |
| 獨立驗證與審查 | Plan-Reviewer／成果 Reviewer approved、required fixes 無；[TE01](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/plan/github-oauth-connection-orchestration/evidence/verification.md)核對20 source SHA、37相對links及受限 diff，首輪 broken link 修正歷史保留。正常 hooks 全通過；首次缺 Biome 的環境問題以 frozen install 解除，未改依賴版本／lockfile。consumer contract 是 compile 檢查，不是完整 Swift runtime tests。 |
| 圖面與程式導覽 | 兩份最終 v2 Archify 各9/9 showcase、0 composition errors／warnings，四尺寸 containment／readability與8張明暗截圖 SHA 符合；首版 visual 失敗保留。Floorplan 本機20檔、20/20描述、50links／10人工關係、0 dangling；僅限列明範圍，Swift解析不證明 async／actor／動態 binding 完整行為。routes0/0及範圍外 E013 server loud 提醒不當 endpoint／安全驗證。 |
| 本機變更圖與導覽工具 | PR Lens pinned0.11.0 以實際 base `ab77391`→published head `2ac31dc` 的39檔 diff validate／render；6nodes／5edges／0 runtime flows，未上傳。Graphify0.9.73 無可用既有 graph，依規範以 targeted source reads，不新建圖。 |
| 新 live／正式流程 | 未執行新 OAuth、真 DPK、Swift runtime suite 或新實驗；正式 orchestration／UI 未接通。E014 2026-10-21 受限 live、其他 topic 的儲存／登出證據與所有歷史狀態不回填。 |

取消後新 credential 可能已保存，禁止當作 absent／自動 rollback；舊 provider 不復活。signOut 先退休、等待已開始 save／clear 成功後才登入，仍須排除其他程序／可寫 provider，且不能撤銷既送出的 request。這些是候選組裝依賴，不表示完整交接已測。初次 authenticate Outcome 不細分保存錯誤、OAuth-only 不擴 PAT 連線；現有 public initializer 的 PAT store 只是既有建構依賴。

本輪查核任務及方案已交付，原實驗四狀態、各 topic Human 接受與正式採用程度分開。[原帳本](https://github.com/a129924/rivet/blob/ddfa281a2e73a65a1fa995a268b416115e988b68/plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.step.md)的 Draft／HC01 pending 保留提交時點；PR merge 已是新事實，但沒有獨立圖面 Human 視覺確認，不因此外推其通過。

Annotated tag `v0.1.68-github-oauth-connection-orchestration-feasibility` 的 local／remote object 同為 `b35f79646f8495e560c13454f67e0bfdefe1152b`，peeled commit 同為上述 merge；不是新 release 或後續文件維護 commit。原 `docs/github-oauth-connection-orchestration` local／remote／tracking branch 與 managed feature worktree 目錄／註冊已正常移除，fresh absence 均核對，未 force／prune。Ignored Floorplan 23檔已先原樣封存 Git 私有 archive 並逐檔核 SHA，未 track／push；其他 worktree／App／秘密／Apple 資產未清理。

兩份索引由獨立 postmerge 文件 worktree 編輯並沿既有安全 fast-forward 慣例保存到 dev；此處不預填維護 branch／worktree 後續移除。這是索引與 Git lifecycle 更新，不新增實驗、runtime 或產品完成主張，也不改 E010／E001–E017 的原結果與預算。

## PR #74：登入 runtime 的交付、證據與 Git 收尾（2026-11-17）

[PR #74](https://github.com/a129924/rivet/pull/74) 於 `2026-11-17T04:02:54Z` merged／closed 至 `dev`。固定 merge `4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e` 的 parents 為 `1f31b35604adb5bb36326e52f9d6dbcff0cac763`／最後 feature `163047f0a295707f957bce96025b4cd9e79f36f9`，tree 與 feature 相同。Runtime commit `fa93773ed090a4d07eb96f6bd43f3ab0b922cbb5` 之後只有交付 metadata；merge／tag 是保存點，不是新 build 或新的真人受測來源。

| 證據層級 | 已支持結果與界線 |
| --- | --- |
| 正式 runtime／受控依賴 | OAuth／PAT 共同入口、候選 token `/user` 驗證後才保存、另一 store 保留、整次登入與收尾期間拒絕重疊、取消傳遞／等待 settled／最後同步 check。原 focused20 tests、root358 tests／45 suites、consumer19 tests／5 suites、format、strict lint155 files／0 violations與hooks通過；R02與R05 approved、required fixes0。不是本次cleanup重驗或真遠端／Security結果。 |
| 隔離工具與圖 | [獨立 Swift package](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/experiments/github-dual-login-runtime/README.md)只 build、未執行 binary，root不反向依賴、無新E編號。Archify9/9／0errors0warnings、deliver、四尺寸containment與Agent看圖通過，Human視覺pending。PR Lens0.11.0只本機validate／render；Graphify0.9.73無圖採原始碼fallback，未建圖。 |
| 真 GitHub／DPK／Human | TC08真OAuth／PAT、當次有效signed host、fresh-process讀回尚未執行；圖Human與topic最終接受pending。舊E013／E014、OAuth完整bundle或PAT儲存live不得回填；合併不代表產品登入UI、session／clients或refresh／恢復流程已交付。 |

[長期契約](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/docs/architecture/github-dual-login-runtime.md)、[獨立測試](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/evidence/verification.md)、[成果審查](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/evidence/review.md)、[交付帳本](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/plan/github-dual-login-runtime/github-dual-login-runtime.step.md)及[圖收據](https://github.com/a129924/rivet/blob/4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e/docs/architecture/diagrams/github-dual-login-runtime/BUILD.md)固定引用保存來源；原pre-merge狀態按歷史快照閱讀，不改原證據。儲存正式能力沿用原stores，沒有legacy遷移／delete或active-mode紀錄；已保存後觀察取消可回cancelled且不回滾。

Annotated tag `v0.1.67-github-dual-login-runtime` 已建立／推送並核 local／remote object 均為 `8910b7ee3ee6498b47ab5a14522b553534ada7ad`，peeled精確指向merge `4912c5a8d89a1f8e5cbac8d4e9ae4be5bacd009e`；不是新live、後續文件版本或GitHub Release。原feature local／remote／tracking refs與managed worktree已正常刪除並核absent，無force／prune。兩索引以獨立postmerge文件分支維護，remote dev只接受安全fast-forward，dev不直接編輯；本次文件hooks不當新runtime驗收。臨時文件worktree只在內容安全保存及fresh clean後收尾，不預填成功；其他工作線／App／Keychain／Apple資產不動。


## PR #73／E017：PAT 儲存的三層證據與 Git 收尾（2026-11-16）

[PR #73](https://github.com/a129924/rivet/pull/73) 已於 `2026-11-16T09:42:56Z` merged／closed，目標為 `dev`。固定merge `cd76cd3faa192134b77b1c1816bbef2c184ede7b` 的parents是 `f89120d61278af6cd696f134762e75487b94ee8a`／最後feature `8ffcff3ed2bcf01cccc80ce30078b5c0bcfdbaec`；tree同時含PR72 E016、本題E017及正式Sources，不宣稱與feature tree相同。實際live來源仍是 `5465d3c7308e74bc2b3b51878acd190d4f2babda`，不是merge／後續文件版本。

| 證據層級 | 支持的結果與界線 |
| --- | --- |
| 正式 Sources／受控測試 | non-BC GitHubIntegration 的 caller-owned PAT actor提供保存／讀回／整筆替換、namespace隔離、嚴格還原、有限錯誤、同實例協調與診斷遮蔽。原獨立root324 tests／40 suites、consumer18／4通過；不含登入runtime／UI、遠端帳號驗證、session／clients、legacy遷移或產品delete。[長期契約](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/docs/architecture/github-pat-dpk-storage.md)／[正式adapter](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift)。 |
| 原 E016 路徑／真 DPK／非機密PAT | source5465、run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 完成A保存→writer結束→fresh A→整筆B→fresh B→真正同身分clean/build→rebuilt fresh B→exact-owned cleanup／正式load=nil；六runtime accepted、Human whole observed=true／各0，setup／rebuild另各全程0。Full identity相同、binary不同且Rebuilt compiler flag實際生效。P06完成、P07獨立approved。[逐段紀錄](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/live-validation.md)／[安全export](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/live-run-39c22b57.json)／[P07 review](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/live-review.md)。 |
| 現 E017／離線移轉 | 十tracked files一對一搬移，八檔bytes相同，runner僅docstring編號／HOST兩字串。Python54、全新scratch Debug／Rebuilt unsigned builds各113 fake checks、paths／links／private stats核對與R02／R05 approved；沒有新signed build／Run／DPK／Human重驗。[Mapping](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/e016-e017-relocation.md)／[R04 tests](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/e016-e017-tests.md)／[R05 review](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/evidence/e016-e017-review.md)。 |

能力採用鏈是E006／E007／E015成果→正式PAT Sources實作→原E016路徑source5465實機驗收→現E017驗收工具歸屬；E016現屬PR72。原九項E016 source keys／hash、原簽章身分與namespace均保持，不能把改號或unsigned結果當成E017新版本live通過。原source `0b0692e` setup unknown、`55aa57a` read A／cleanup unknown／accepted=false保持；55 namespace新readonly recovery只證當次正式load=nil、accepted／Human全程0，無再次save／delete，不追補舊unknown。

Live只適用原同機／GUI使用者、有效profile／簽章與相同存取身分；驗收profile有效至2026-11-23，不保證今日以外環境、renewal／過期恢復、certificate rotation、多程序協調、公開分發、crash／斷電durability、真PAT遠端有效性或產品登入。E007兩輪renewal未知與Human接受限制不變。HC04圖Human視覺／HC05最終topic review仍pending，merge不代Human接受；原[帳本](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md)／evidence／圖保留當時交付快照，不改判歷史。

精確兩份原untracked Xcode個人metadata已在Git common私有0700 archive保留原bytes／mode／owner，0600 manifest保存私人來源對照；核符後僅移出兩source leaves，feature現clean／無untracked。Archive不進Git／不push，原外部私有Xcode、signed artifacts／runs／proofs及DPK／Apple資產均保留。

Annotated tag `v0.1.66-github-pat-dpk-storage` 已建立／推送並讀回核對：local／remote tag object 同為 `cd8fa8ea85c3f44e059de4fde47b8d1a304677ea`，peeled commit 精確為上述 merge `cd76cd3faa192134b77b1c1816bbef2c184ede7b`；不指後續文件 commit 或原 live binary，不是 GitHub Release。原 `feat/github-pat-dpk-storage` 在 fresh clean／無untracked／head／merge lineage／locks／無active mutation核對後，已正常移除managed feature worktree、以 `git branch -d` 刪local branch，並在remote仍為feature `8ffcff3` 時刪exact remote ref；local／remote／tracking refs、worktree目錄／精確registration均已核不存在，未force／prune。

PR #73 的十四個branch型blob／tree URL已固定為上述merge permalinks，逐項object與最後feature相同，body其他bytes不變；讀回仍closed／merged。兩索引由獨立 `docs/github-pat-dpk-storage-postmerge` managed worktree交付，文件commit由本次Git history定位；原hooks照常，remote dev只接受safe fast-forward，dev工作樹只作clean gate後的 `--ff-only` baseline同步、不在dev編輯。本文件分支／worktree只於文件安全保存remote及fresh clean後正常移除，不預填該後續動作成功。E010工作線、外部私有Xcode／signed artifacts／runs／proofs、DPK／Apple資產與原topic artifacts／evidence／圖不操作；本次不重跑實驗，也不將merge／Git清理代替HC04／HC05接受。

## PR #72／E016：本地登出的三層證據與 Git 收尾（2026-11-16）

[PR #72](https://github.com/a129924/rivet/pull/72) 已於 `2026-11-16T09:00:10Z` 合併至 `dev` 並關閉。固定 merge 為 `88ec4a0e13bf68fb489fd9b06895591a0663ba53`，最後 feature head 為 `641789fad88d2a3ad7e3fe990fa56d1c0e540fe3`；merge parents 是 `5713025e3312c0fbc9a7b02a222db0b91d6e1b58`／上述 head，merge tree 與 feature 相同。此保存來源與 live 受測 commit `bb6752aa483a68043174723a6b3ff2653abe79ce` 分開，不將合併／文件版本稱為重測來源。

| 證據層級 | 本次支持與限制 |
| --- | --- |
| 正式 src／受控 Swift | non-BC GitHubIntegration 的 signOut 永久退休舊 provider，等待已開始 save 結束後精確 clear credential；晚到 restore／refresh 不發布／寫回、舊 clients 後續需求與401 recovery拒絕由受控 tests驗證。保留configuration，不提供遠端 revoke或產品UI。[長期契約](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/docs/architecture/github-oauth-dual-client.md#本地登出)／[精確清除](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/docs/architecture/github-oauth-credential-persistence.md#本地-credential-清除)。 |
| 真 DPK／synthetic／兩程序 | E016 bb6752a first seed完整假credential/configuration/sentinel、逐欄readback、正式signOut及同程序credential absent；fresh不同exact process只讀確認absent、configuration/sentinel intact。兩exact processes歸屬／退出、同frozen source/binary/profile及Human各complete zero有證據，Tester／Reviewer核准本次有限成功。[八段紀錄](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/experiments/E016/README.md)／[live與收據綁定](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/plan/github-oauth-local-sign-out/evidence/e016-live.md)／[success projection](https://github.com/a129924/rivet/blob/88ec4a0e13bf68fb489fd9b06895591a0663ba53/experiments/E016/evidence/success-summary.json)。 |
| 真 OAuth／refresh／產品 UI | 本次live未執行真OAuth、refresh/network或UI驗收。晚到refresh競態沿原受控測試，不能把synthetic DPK成功當作遠端能力或普遍零提示保證。 |

適用條件為當次同機、同GUI使用者、既有signer／有效profile／exact group、同frozen binary與唯一writer；不外推其他profile、跨writer／跨機、產品UI或斷電durability。原public的Human unknown／false不回填，Human獨立attestation各綁原publicSHA；成功projection是獨立彙整，不冒充原receipt。014bab2的簽章後工具停止、ff672c7 first indeterminate、fresh未執行及其程序／public缺口不改；舊first與新授權first/fresh兩組額度都已使用完，不恢復或重試。隔離configuration／sentinel仍保留，沒有cleanup；本輪索引更新不執行App／DPK，也不吸收E010／E015的不同驗收。

語意 annotated tag `v0.1.65-github-oauth-local-sign-out` 的 local／remote object 均核為 `96fba09f65a1c2f42fe8501fa4bd5623ea57bafd`，peeled精確指向上述merge，不指向live受測source或後續文件commit，亦非GitHub Release。原feature local／remote branch `feat/github-oauth-local-sign-out` 及tracking refs已正常刪除並核absent，未force。兩索引在獨立 `docs/github-oauth-local-sign-out-postmerge` 文件分支編輯，不在dev實作；PR合併／Git收尾不代替原topic Human最終接受或圖面視覺接受。

## PR #71：雙登入契約的受控證據與 Git 收尾（2026-11-16）

[PR #71](https://github.com/a129924/rivet/pull/71) 已於 `2026-11-16T02:15:39Z` 合併並關閉。固定 merge 為 `4ddca1864557c2858266c2cc6d0a21f1e0bb7237`，最後 feature head 為 `3cdbde753ebefb26564d1135376d043e682b13e7`；兩親 merge tree 相同，只證明來源保存，不是本輪新測量版本。

這是既有 non-BC `GitHubIntegration` 的正式技術契約，不是新增 E 實驗或真登入服務。[長期契約](https://github.com/a129924/rivet/blob/4ddca1864557c2858266c2cc6d0a21f1e0bb7237/docs/architecture/github-dual-login-contract.md)、[公開規格](https://github.com/a129924/rivet/blob/4ddca1864557c2858266c2cc6d0a21f1e0bb7237/analysis/github-dual-login-contract/technical-spec.md)與[原驗證／交付帳本](https://github.com/a129924/rivet/blob/4ddca1864557c2858266c2cc6d0a21f1e0bb7237/plan/github-dual-login-contract/github-dual-login-contract.step.md)均固定引用 merge。

| 證據層級 | 原交付支持與限制 |
| --- | --- |
| 受控 Swift 契約 | focused 8 tests、GitHubIntegration 229 tests／25 suites、既有 consumer 15 tests／3 suites 通過；focused 新契約使用一般 import，涵蓋 PAT 本地規則、共同結果、診斷遮蔽及取消。三組數字各按原測試邊界閱讀，不相加宣稱獨立案例總數；consumer 15 不冒稱包含新契約。 |
| 靜態與提交檢查 | format、SwiftLint 140 files／0 violations、diff check 與完整 commit hooks 通過。首次缺 renderer 依賴的 hook 失敗後，以相同 lock 的既有依賴補足 feature 的 ignored cache，重試全通過；沒有略過 hook 或改工具配置。 |
| 文件與導覽工具 | Archify showcase 9/9、0 errors／warnings、deliver／hashes、四尺寸 containment 通過；最小／最大 light／dark 截圖經獨立審視。PR Lens pinned 0.11.0 在本機 validate／render 通過、綁定最後 feature head 的真實 diff；Graphify 無既存 graph，採 source-search fallback，沒有 build／upload。 |

成功結果只有無 payload `.success`，不交付帳號、session、token capability 或 clients；取消仍是 conformer 義務，不是 Protocol 自動執行。上述受控結果不證明 GitHub 真實授權、PAT 遠端有效性、UI 串接、持久化、refresh／401 或產品登入完成。這輪文件整理不新增 topic 測試／真人證據，提交 hooks 照常執行，不視為重新驗收或驗圖；PR 合併不等於圖的 Human 視覺接受，原帳本的 Draft／human-check 是交付時點快照，不回寫歷史。

語意 annotated tag `v0.1.64-github-dual-login-contract` 已正常建立／推送，local／remote object 都是 `7eacd8e747eb5be78936cf237fa9f15b7a6671a4`，peeled commit 都是上述 merge；不指後續文件 commit，未建立 GitHub Release。原 `feat/github-dual-login-contract` local／remote branch、tracking ref 與原 managed feature worktree 已在最新 clean／head／merge lineage／tag 核對後正常移除，目錄／註冊均不存在，沒有 force／prune。PR 五個分支審閱連結已固定至 merge。

本輪兩份索引由獨立 `docs/github-dual-login-contract-postmerge` managed worktree 編輯，dev 只 fast-forward；該文件分支與維護 worktree 仍待文件安全交付後清理，不預填其成功。E010、local-sign-out、其他 worktree、App／Keychain／Apple 資產不在本輪操作範圍。

## PR #69：驗證產物歸屬與受限離線補測（2026-11-13）

[PR #69](https://github.com/a129924/rivet/pull/69) 已於 `2026-11-13T06:16:39Z` 合併至 `dev` 並關閉；merge `4c2153963fe7c41cc36b56f2a4fe3ae3b79ba6c2`、最後 feature `a4c4f6bc23f00ae746ad48c69f6779ca993a1d03`，兩者 tree 相同。E011–E015 集中五組獨立驗證環境；正式能力與正式測試保留，不新增產品登入、package 或共用抽象。索引位置見[README 的已合併收納表](README.md#pr-69已合併的獨立驗證環境收納)，逐檔真相只引用[固定 technical-spec](https://github.com/a129924/rivet/blob/4c2153963fe7c41cc36b56f2a4fe3ae3b79ba6c2/analysis/verification-artifact-ownership/technical-spec.md)。

- 純搬移：依原始或已核准修後基線保持 bytes／mode。
- 必要接線：source／test 路徑、project refs、資源／操作入口、路徑斷言與導覽；E009 現行 pin 依原 VO-PIN3 精確授權綁來源／產物，歷史 pin／receipts 保留。
- 兩項受限修正：`ccf9d21` 拒絕空白配置是行為修正；`3fe0c9a` 僅測試型別消歧，資料與期待不變。兩者各自提交／驗證，不能把整份 PR 說成無行為差異的純搬檔。

E015 的六個 focused case 由最終來源新建 CLI，使用 DEBUG、互斥 LAUNCH_REPORT_ONLY／DPK_VALIDATION_ONLY 等必要 flags，實際通過。完整197項為 **195 passed／2 skipped、0 failure／error**，原189項逐案保持。Epicurus Tester、Plato Reviewer 與最後行政窄複核均 approved／required fixes0；精確命令／環境／來源版本與產物綁定見[固定補測證據](https://github.com/a129924/rivet/blob/4c2153963fe7c41cc36b56f2a4fe3ae3b79ba6c2/plan/github-oauth-credential-persistence/evidence/live-preparation-tests.md)。

兩個 skipped 仍缺可信原 captured context 的 source／app tree 與 context／proof／request bytes，以及符合原 certificate hash、已允許使用的公開 DER 副本。這是限定查證範圍內的材料不足覆蓋缺口，非已確認 Runtime failure／required fix，不阻擋六項成果交付；不宣稱整台電腦無副本、不猜測缺料原因、不新造替代資料／重建歷史／查 Keychain／改 pin。原189/8、各輪 pending／失敗、E001–E010、PR #60／#61／#62／#63／#65／#66等原證據均按其來源閱讀；本次 merge 不重新驗證真人流程或把合併點冒充實際測量版本。

語意 annotated tag `v0.1.63-verification-artifact-ownership` 已推送，tag object `c5039b06d294a1cd0139fba2528ee5e09d886ede` 的 local／remote 值一致，peeled commit 為上述 merge；不是後續文件 commit 或 GitHub Release。原 feature local／remote branch 已在 fresh SHA／lineage 核對後正常刪除；文件以獨立 postmerge 分支保存，managed worktree 於文件安全推送後才移除，不碰 E010 或其他 worktree／安全資產。

## 快速總覽（保留上游各輪限制）

| 實驗／交付 | 觀察與來源 | 未由此證明的事項 |
| --- | --- | --- |
| [E001](E001/README.md) | 2026-10-07 真實 OAuth callback、非空 code、state 相符、exit 0。 | token exchange、refresh、儲存或正式產品登入。 |
| [E002](E002/README.md) | 真實正向 token、六欄 bundle、GET /user 成功；反向歸因不足。總體無法判定。 | PKCE enforcement；不將後續 X 或 E008 補成此輪成功。 |
| [E003](E003/README.md) | 2026-10-08 T01–T04 遠端測量成功，舊 refresh token 重用回 bad_refresh_token。 | 自然到期、provider 自動刷新、401 recovery、持久化或所有遠端配置。 |
| [E004](E004/README.md) | 2026-10-14 T01–T06、真 SQLite／跨程序／rollback 成功；fake refresh 與受控失敗。 | 加密、真遠端 rotation、sandbox、斷電 durability 或正式 adapter 採用。 |
| [E005](E005/README.md) | 最後 human-only 輪六欄保存與同身分重建讀回成功；Human 提示數首次／fresh／重建為 0／0／1，候選 UX 失敗。 | 所有免費 Keychain 路徑失敗、DPK 不可用或必須付費。早期 unknown 與 machine receipt 原值保留。 |
| [E006](E006/README.md) | 2026-10-19 假 bundle，首次／fresh／真重建讀回完整且 Human 均零提示，受限成功。 | profile 更新／過期恢復、certificate rotation、真 OAuth、公開分發。2026-10-16 controlled-stop／逾時歷史保留。 |
| [E007](E007/README.md) | 兩輪 renewal 前提未成立，renewal read 均未執行，結果無法判定；Human 已接受該未知限制。 | 不同 profile 的讀回成功；新版 export-clean 的受控檢查不代替原真人輪或新增真人驗收。 |
| [E008](E008/README.md) | 2026-10-22 單次安全 JSON 與兩名獨立先封存 enum；依固定判準無法判定。 | 普遍 PKCE enforcement、OAuth 漏洞、完整 wire 或正式安全決策變更。 |
| [E009](E009/README.md) | M03：Human 確認獨立未登入 session、未授權帳號、同輪登入／同意／300 秒內有效帳號；來源契約支持。 | agent 直接見證歷史 UI／network、2FA、完整零配置 UX、產品 readiness 或 PKCE。後續 build 不回填真人來源。 |
| [E010](E010/README.md) | 新 W1 seed／fresh 六欄相符、Human 各全程0提示；原遷移／controlled-stop 歷史保留。 | W2 真自然到期／P1、W3 Rebuilt／完整週期、minimum 完成或新的正式 adapter 採用；RP delete=0，RT 僅 metadata。 |
| [E016／PR #72 本地登出](E016/README.md) | bb6752a 真DPK／synthetic first／fresh成功，兩exact processes退出及Human各complete zero，受控refresh競態另列。 | 不證真OAuth／UI／其他profile／crosswriter／durability；舊indeterminate、兩組已耗額度及configuration／sentinel殘留保持。 |
| [E017／PR #73 PAT 儲存](https://github.com/a129924/rivet/blob/cd76cd3faa192134b77b1c1816bbef2c184ede7b/experiments/E017/github-pat-dpk-storage/README.md) | 原source5465／E016路徑真DPK、A／B跨程序、同身分真重建、owned cleanup／nil，六runtime Human各全程0；E017離線移轉另列。 | 不證新E017來源live、真PAT遠端有效性、renewal／rotation／分發／durability或HC04／HC05接受；舊unknown保持。 |
| [E019](E019/README.md) | 直接指派查詢的 12 項受控測試通過。 | 真人查詢未執行。 |
| [E020](E020/README.md) | OAuth 真人驗收通過。mlops-async#72 四欄吻合，2 個唯讀 GET。 | 證據限當次帳號與單筆正例，自查完成狀態待定義。 |
| [PR #60 正式 OAuth 憑證儲存](https://github.com/a129924/rivet/pull/60) | 2026-11-05 正式 adapter／完整假六欄的真 DPK、跨程序 A／B、整筆替換及同身分真重建通過；五 runtime Human 全程0提示。 | 不是新 E 編號；不證真 OAuth／遠端 refresh／API、configuration item live、profile 更新、普遍環境、LC06 或完整產品驗收。 |
| [PR #66 原生登入 UI／Demo](https://github.com/a129924/rivet/pull/66) | 2026-11-11 Human完成指定狀態朗讀、局部大字與focus／rapid案例，明確通過並採用。 | 假資料展示範圍，正式 backend／OAuth 與系統字級偏好整合屬後續能力。Human大字為21pt五畫面及17pt同PAT，15格矩陣沿用工具來源。 |
| [PR #75 正式 Login UI 元件化](https://github.com/a129924/rivet/pull/75) | 正式組合元件、獨立驗收支援；6a binary的必要原生／Human語音差異通過並獲HC02接受。 | E011凍結；Canvas未驗；不證真認證、外層Adapter、儲存／session／產品接入或新merge build驗收。 |
| [PR #71 OAuth／PAT 雙登入契約](https://github.com/a129924/rivet/pull/71) | 合併來源保存與既有受控契約／工具驗證，非新增 E。 | success 無帳號／session／clients；不證真登入、UI 接線、遠端有效性或新的 Human 視覺接受。 |

## E001–E007：已知結果與不能推論之處

| 來源 | 已觀察的結果 | 證據界線與缺口 |
|---|---|---|
| [E001](E001/README.md) | 2026-10-07 真 GitHub 瀏覽器授權回到本機 loopback，code 非空、state 相符，exit0。 | 沒有 token exchange；不證保存、refresh 或產品登入。 |
| [E002](E002/README.md) | 同日正向 exchange 成功，回應符合完整六欄並可建 public bundle；一次 GET /user 成功。 | 反向 PKCE 及 overall **無法判定**；兩次授權額度 2／2 已用完，不能將正向成功當作 PKCE enforcement 成功，也不自行第三次授權。 |
| [E003](E003/README.md) | 2026-10-08 一次真 refresh 產生新 pair、六欄相容，新 token API 與初始 user ID 相同；舊 refresh token 唯一重用回 `bad_refresh_token` 且無新 token。 | 只證該次真交換與輪替；沒有驗證持久化、既有 provider 自動刷新、自然到期或產品流程。 |
| [E004](E004/README.md) | 真 SQLite／GRDB 與獨立程序，配合假 credentials、fake refresh／受控 clock，驗證完整 bundle、交易 rollback、single-flight 及 accepted-save-failure 停止契約。 | 是真儲存加合成 OAuth 控制；不證真 GitHub、秘密加密、斷電耐久或正式儲存採用。 |
| [E005](E005/README.md) | Legacy Keychain 的完整假 bundle 資料機制成功；最新 human-only 首次／fresh／同身分重建提示為 **0／0／1**。 | 重建多一次憑證提示，既定零提示 UX **失敗**。早期 ad-hoc 身分不足與 UX unknown 保留；不能外推 DPK 或付費資格結論。 |
| [E006](E006/README.md) | 2026-10-19 假 bundle 存於真 DPK；免費 Personal Team、原 certificate、有效且相同 profile 下，fresh-process 與切換至 Rebuilt configuration 真正重建後六欄相符，首次／fresh／重建提示 **0／0／0**。 | 非真 OAuth／refresh，也未更新 profile。2026-10-16 setup 中止、DPK／UX 未測及清理超過原 deadline 的 unknown 歷史不被後輪成功覆蓋。 |
| [E007](E007/README.md) | 兩輪均安全收尾，但 **profile 更新後讀回未執行、無法判定**。第一輪 B 仍為相同 profile bytes；第二輪 backup／restore-check 的 provenance xattr 不符，在移出前停止。 | 第二輪 cache move／refetch／B Build 均0，不能說已更新後失敗或成功。Human 已接受「profile 更新後讀回未驗證」限制；不改為 pass，不開第三輪。 |

E007 [第一輪](E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/final.index.json)與[第二輪](E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/final.index.json)收據保持原工具版本。其後 `bf0db99` 僅版本化修正 runner／protocol tests／README，其他29份 E007 歷史不變：[新舊 SHA 清單](../plan/github-persistent-connection/evidence/verification-host-manifest.md)、[C03–C05 獨立驗證及審查](../plan/github-persistent-connection/evidence/verification-host-review.md)。36個 Python tests 與4組獨立 fresh-process CLI 只證合成故障下先耐久匯出、checkpoint 與可恢復清理；不是新版 runner 真人、第三輪 E007、物理斷電耐久或 renewal 證據。7個未變 SwiftCore tests 未重跑。

## PR #62：新獨立驗證 App 的整條流程

2026-10-21 的 [GitHubConnectionVerification](https://github.com/a129924/rivet/blob/aa16de91b560027325419b7bc904d831851c9fcb/apps/GitHubConnectionVerification/README.md) 明示「驗證用途，非 Rivet 正式產品」。真實服務與儲存結果見[新 host 真人證據](../plan/github-persistent-connection/evidence/verification-host-live.md)：

| 流程 | 本輪結果 |
|---|---|
| 簽章與前提 | 原免費 Personal Team／既有 Apple Development certificate、新驗證 identity／private group、有效 embedded profile、固定安裝位置。 |
| 登入 → 保存 → API | Human 在新 App 完成真 GitHub 授權，真 DPK 保存設定／完整 bundle，GET /user 顯示有效帳號。 |
| 完整退出 → 新程序 | 相同 binary／位置的新 PID 還原完整 bundle，無重新授權或 refresh，同帳號 API 成功。 |
| 真正 Clean／Build → 還原 | 舊 built product 確認不存在後重編譯／link／簽章；不同 binary、同身分／profile、同位置替換，新程序還原及 API 成功。 |
| 受控到期 → 真刷新／保存 | 只改 provider 注入 clock，真 GitHub refresh attempt1／accepted1、真 DPK save1；accepted＝persisted 六欄 digest，保存後回 real clock，同帳號 API 成功。 |
| 輪替後再退出 → 新程序 | 未強制到期、未重新授權，完整讀回新 digest＝前次 accepted／persisted，無 refresh／save，同帳號 API 成功。 |

六個流程共有七項 Human 分段提示觀察：setup／Team／build前、build完成，以及後續五個結果段，均為 **0次**。機器結果與 Human 回報分列，不能用沒有機器錯誤推定零提示。

初 grant 程序的 exclusive observe receipt 在空設定階段已寫出，**未觀測 grant 後 digest**；第一次完整已保存 bundle digest 在 fresh 程序直接觀測。新舊六欄 digest 不同及 aggregate tokenPairChanged 只證 pair 整體改變，不宣稱兩個 token 各自 hash。受控 provider expiry 觸發的是真 GitHub refresh，不等自然等候到期；未改 OS clock、response 真實接收時間或保存日期。

自動驗證另列：[契約測試](../plan/github-persistent-connection/evidence/verification-host-contracts.md)為 fake-only unsigned hosted **78 tests**；[隔離驗證](../plan/github-persistent-connection/evidence/verification-host-isolation.md)以當前 source 排除整個 App 後，production 普通 build、**202 tests／22 suites**、consumer **12 tests／3 suites**通過。真 legacy Keychain suite 明示未跑，未刪原測試。production Sources／Tests／Package／locks 還原 topic 前 `16606b89` 基線，沒有驗證專用正式 API、共用 UI、控制或反向依賴；逐檔歸屬與版本見[manifest](../plan/github-persistent-connection/evidence/verification-host-manifest.md)，獨立結果見[review](../plan/github-persistent-connection/evidence/verification-host-review.md)。這些通過不等正式產品登入能力已完成。

## PR #61：正式初次 OAuth 能力與單次反向收尾

[PR #61](https://github.com/a129924/rivet/pull/61) 已於 2026-10-22T03:17:27Z 合併；本節以合併點 `14d0832f042720889993d769b4cbfb720078e6b1` 的[長期說明](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/docs/architecture/github-first-sign-in.md)及[安全證據](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/plan/github-first-sign-in/evidence/pkce-semantic-review.md)為索引。真實執行的工具來源仍為 `4dbf3df`，不把文件合併 commit 冒充測量版本。

正式 `GitHubIntegration` 保留初次 OAuth configuration／factories／session／code exchange／errors，沿用既有 credential／provider／scope／clients。獨立 `GitHubSignInVerification` 收納配置及驗證 UI、loopback relay、coordinator、程序內完整 store、probe 與 hosted tests；使用真 OAuth／API，該來源當時正式 Rivet 產品登入 UI 尚未交付；目前產品入口依其自身工作線判讀。來源 `e941d88` 的正常登入、真 API 與同程序再次查詢成功，與 PR #62 的 DPK／跨重啟／refresh 驗收分開。

| X 收尾層級 | 實際結果與界線 |
|---|---|
| Native 正常操作 | 明確 click copy、Human 手貼公開 synthetic 句並逐字核對通過；不涵自然 timeout／cancel／Enter／late、OS 清除或無留痕。 |
| 唯一 wrong HTTP 事實 | 新授權／新 code／單 POST；HTTP400 invalid_grant、remote_rejected=true、無 token。本機 prepared 一致，提交合法但不同 verifier、challenge 不同。 |
| Provider 描述語義 | 兩獨立 AI 先封存一致 `verifier_mismatch_asserted`，來源 `provider_description_ai_review`；屬 provider 對當次拒絕的 mismatch claim，不是普遍 enforcement 或遠端 wire 證明。 |
| 保留的自動結果 | v3 outcome=indeterminate、pkce_rejection_proven=false、description_class=unknown、match_source=none；AI 軸不改既有判準或歷史。 |

新 X 預算 **1/1 已用盡**，本輪結束、沒有 retry／第二次／追加研究。P／Q 各 2/2、共享 R→T 1/1 的耗盡與舊 unknown、missing 無法判定均不回改；E002 的 2/2 與 overall unknown 仍是其獨立歷史。僅支持這次新授權、合法但不同 proof 的交換被拒且 provider 歸因 verifier 不符，不泛化所有設定／帳號／missing。正式登入 topic 的完整遠端 refresh／401 未因此驗證；PR #62 的受控到期真 refresh 是另一驗證 App 與來源的結果。

67 項工具受控測試與獨立 code review 沿原凍結證據，X 沒有重跑它們。原文只走已批准的單欄 clipboard／Human 手動 AI 閱讀例外；索引不保存描述原文、秘密、callback、code、state 或 token，不保證剪貼簿／同步／AI 服務留存消失。

## PR #63／E009：首次登入、授權與有效帳號

[PR #63](https://github.com/a129924/rivet/pull/63) 於 **2026-10-22T03:51:18Z** 合併，固定來源為 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`，最後 feature head 為 `fe9af0dbbbbf2cf72befd45fec23488e5ebf55c2`。[E009 原始分層紀錄](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/experiments/E009/README.md)及[長期結論與 C01 更正](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/github-account-login-feasibility.md)採固定 permalink，保留原索引來源版本；本次合併後 E009 亦可由本機相對路徑查閱。合併 commit 是保存來源，不冒充真人或本機 build 的執行版本。

### M03：Human 回報與事前判準

Human 親自回報五步：使用工具的本次網址手動開啟；看見登入頁並完成登入；看見授權頁並親自同意；看見 callback 收到提示；返回工具看見 API 成功與帳號結果。另逐項確認三個前置／同輪條件：獨立／無痕 browser session 不共用原登入狀態且開始時未登入；測試帳號操作前尚未授權此 App；使用 E009 新版同一次手動準備的網址，API 成功在 300 秒內，期間未重啟／再啟動／改用舊網址。

| 事前判準 | 判讀與來源 |
|---|---|
| 看見 GitHub 登入頁 | Human 明示確認。 |
| 完成登入 | Human 明示確認；未獨立確認是否出現 2FA。 |
| 看見並親自同意授權 | Human 明示確認。 |
| 同流程取得有效帳號 | Human 確認同輪 API 成功／帳號結果，配合原碼契約支持。 |

因此 **M03 為受限成功**，僅成立於上述 Human 陳述的單輪條件；不等於 agent 獨立看見全程。

| 證據層級 | 實際取得與限制 |
|---|---|
| Human 觀察 | 上述五步與三項補充確認；不以 agent 未見錯誤代替。 |
| Agent 觀察 | 當時程序 executable 路徑、磁碟 binary／六份 source snapshot 指紋核對；M03 binary 為 `990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877`。不是歷史 PID／整輪關聯收據。 |
| 來源推論 | 同一 session／relay 的網址、callback 與單次 exchange，之後 probe；HTTP 200、正 id、trim 後非空 login 才是有效帳號。不是當輪 HTTP status／body／token POST 的獨立擷取。 |
| 未取得 | 全程 UI、network trace／server log、精確起訖與獨立計時、歷史 session 關聯、實際配置供給者／是否使用互動 launcher、當時主對話 ready 收據及 2FA 提示。 |

C01 已撤回 L01 的「新授權成功」判定，仍為無法判定；M03 是其後的新證據，沒有覆寫更正、A07 或 M01／M02 當時的未執行紀錄。A07 的 `e941d88` 真 API／再次查詢及 E002、P／Q、R→T、X 的來源、額度與判讀均保持各自歷史；M03 不新增反向 PKCE 證明或額度。

### M04 工具交付與合併相容性

PR #63 已納入同 repository 的初次 OAuth runtime、完整 `GitHubSignInVerification` host／必要 tests，以及 E009 一次性開發端 launcher。手動網址沿用同一 session／state／verifier、最多 300 秒、單輪後停止；開發端以 hidden TTY 供給程序環境配置，登入驗證者沒有配置欄位。Launcher 契約含 binary／程序身分核對、拒絕既有 App，不以秘密 argv／檔案／log 傳遞；這是工具機制，不追溯證明 M03 實際如何供給。

M04 的 hosted mock 為 17 definitions／18 executions、0 failures，root 275 tests／34 suites；helper synthetic／strict checks 與六 commit hooks 通過。其後兩次同步 dev 的合併只處理文件／source 相容性；涉及 host 的最後一次依序 build-for-testing、test-without-building、normal build 通過，仍為 17 definitions／18 executions、0 failures，未重跑 root 全 suite 或新增真人授權。最後本機候選 binary 為 `66aa6f9af216198df2e982aa2e9295fc16f9124e05a848aadac9676ae57dba2f`；M04 先前 `781e1413…`／`96ee9b…` 與 M03 `990917ac…` 均保留各版歷史。合併、重建或 mock 通過都不構成新的 live 結果，也不保證其他環境重建同 hash。

結果不外推完整零配置產品 UX、正式產品入口、production secret custody、persistence、公開發行或普遍 PKCE enforcement；不吸收並行 PKCE／產品 UI topic 成果。

### #63 已完成的 Git 收尾

Annotated tag `v0.1.57-github-account-login-feasibility` 已推送，遠端 peeled commit 與 `fccaf2b6` 一致；原 topic local／remote branch 與 managed worktree 已正常移除，沒有 force 或 GitHub Release。這是 #63 當時的收尾事實；當時 #64 尚未合併的交付快照不回寫，#64 後續結果另見文末。

## E008：三層結果

1. **交換觀察**：Human 手動提供的 [CLI 安全 JSON](E008/safe-result.json) 回報 HTTP400、invalid_grant、remote_rejected=true、token_present=false；新嘗試、單次 exchange、本機一致性與 verifier 欄位省略均有有限欄位紀錄。本機 prepared inputs 不等於完整遠端 wire 證明。
2. **Provider 聲明**：[封存結果](../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json) 中，A／B 的 provider_claim 同為 verifier_required；A 的 pkce_causality=not_asserted，B=asserted。原始描述不保存，不重建原句或追加第三人重判。
3. **主要假設**：因當次因果判讀分歧，依執行前固定判準維持**無法判定**。CLI 的 outcome=indeterminate、pkce_rejection_proven=false 原樣保留；HTTP、錯誤碼、關鍵字及要求 enum 不能單獨取代因果共識。

執行來源 `d067c2c6adad7b1bcb19639c3f0ca58fc437e251`；工具凍結未改。[獨立 Tester](../plan/github-pkce-missing-verifier-feasibility/evidence/live-verification.md) 與 Reviewer 接受的是有限證據的如實整合，required fixes=0；不是 missing-verifier 假設成功。任務完成、1/1 額度用盡，不補次；未使用 token 呼叫 API，也未執行 revoke。

[PR #65](https://github.com/a129924/rivet/pull/65) 已於 2026-10-22 合併並關閉，merge commit 為 `0276ff3385495ed7fb0444e02b3b6da0757dd17a`。PR 合併只更新交付狀態，不解除因果缺口；E008 README 與 step 中的 Draft／待 review 文字保留為當時交付快照。

## 版本與仍未驗證的範圍

2026-10-20 舊 Rivet 名義 host 的[原端到端紀錄](../plan/github-persistent-connection/evidence/product-e2e.md)及圖、0次提示保留為 `ca00bc0` 歷史，正式產品歸屬與完成宣稱已撤回，不能冒充新 App 驗收。舊 source `7e81b77` 僅供追溯；新舊真人 build 都依當時工作樹 source SHA、私有 project 與原生 build log 識別，不偽稱由後來才產生的 commit 建置。

下段有效 profile／private group／原 certificate 等前提專指 PR #62 的 DPK 持續連線驗證；PR #63／E009 的獨立 SignIn host 使用 [ad hoc 簽章、不需 Team／profile／Keychain entitlement](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/architecture/github-first-sign-in.md#L19)，不套用該組儲存前提。

已知可行性依賴有效 profile、同 Mac／GUI 使用者、相同 AppID／private group／原 certificate 等前提。以下均保留未驗證：

- 自然 access-token 到期等待。
- profile 更新後讀回（Human 已接受限制）及已過期 profile 的恢復。
- certificate rotation、跨使用者／跨機器及公開分發。

本摘要涵已合併 PR #62／#61／#63／#65／#60，以及 PR #66 原生登入 UI／Demo 的各自固定來源。另節分列尚未合併 PR #67 的 E010 受限進度，不混入上述已合併來源範圍，也不吸收其他 worktree 的成果。其他尚未合併工作依其自身工作線記錄。原 PR #62 的文件與 Git 收尾仍依[本 topic 帳本](../plan/github-persistent-connection/github-persistent-connection.step.md)追溯；#63 已完成收尾另列於上節。兩份索引已由 PR #64 合併至 dev；其先前 Draft／pending 記錄保留為原時點快照，後續實際收尾另見文末。

## 決策邊界

各實驗的成功只適用其來源版本、前提與觀察層級；測試／build 通過、文件審查通過、驗證任務完成或 PR 合併均不能代替主要假設的證據。E002 反向／舊 missing 未知、E005 候選 UX 失敗、E007 renewal 未驗證與 E008 無法判定分別保留；既有 X wrong 的單次支持性證據不代替 missing。

PR #66 的原生登入 UI／假資料 Demo 已依自身工作線取得 Human 採用，詳見文末。正式 backend／OAuth 串接、adapter 的後續擴展、安全決策及憑證 lifecycle 仍依各自既有流程。

## PR #64：文件驗審完成與實際清理（2026-11-03）

[PR #64](https://github.com/a129924/rivet/pull/64) 已於 GitHub `mergedAt=2026-11-03T06:04:24Z` 合併並關閉。固定 merge 為 `71d395cc9ca3cfe645b13a93ee0e83f22c255edd`，最後 feature head 為 `572e366e03471324cd745a4e4a103d19374e5009`；它是文件交付版本，不是新的真人執行 build。

[R64 保存契約與交接](https://github.com/a129924/rivet/blob/71d395cc9ca3cfe645b13a93ee0e83f22c255edd/plan/github-persistent-connection/github-persistent-connection.step.md)記錄本輪 Tester R64-T01–T05 **22／22 通過**與 Reviewer **approved／required fixes=[]**。兩項修正分別補齊 #61／#62／#63／#65 的現行來源契約，以及 E006 的 Rebuilt configuration 重建措辭；[範圍 thread](https://github.com/a129924/rivet/pull/64#discussion_r4451328613)與 [E006 thread](https://github.com/a129924/rivet/pull/64#discussion_r4451328654)已由主方 API 讀回 resolved，未解決數0。這不沿用原 D04／D05 作新核准，也不新增實驗或產品採用結果。

E006 原 partial Human receipt 只記切換 Rebuilt configuration；Debug／Rebuilt 的不同 binary hash 與後續完整 Human 觀察支持既有受限 0／0／0，沒有 Clean 操作證據。E006 原判定／收據不改；#62 獨立持續連線 App 的真正 Clean／Build 段保持原證據。M03 的 Human／agent／source 界線、C01／A07、各輪 PKCE 預算及 indeterminate、DPK 前提與產品限制均保留。

本次已核對 annotated tag `v0.1.59-github-connection-validation-summary` 的本機／遠端 object 與 peeled commit 一致，精確指向 `71d395cc…`；不是後續文件維護 commit 或 GitHub Release。原 topic local／remote branch 與本輪 managed feature worktree 已正常移除；無 force／prune，其他 feature worktree 與所有 App／Keychain／Apple 資產未操作。PR #64 原文件交付與 Git 清理完成不代替實驗主要假設的證據，舊 D／R64 pending／交付前狀態只按當時版本閱讀。


## PR #60：正式 OAuth 憑證儲存的三層證據（2026-11-10）

[PR #60](https://github.com/a129924/rivet/pull/60) 已於 `2026-11-10T03:30:48Z` 合併並關閉；固定 merge 為 `c8c989a2e4be99e73c9cdc17e82cc16ada7a489c`，最後 feature head 為 `89bd01a27375137fb76ae1933efe6d4b7a36d23d`。兩親／相同 tree 只證明交付版本已保存，不等於新真人 build。本文以該 merge 的[長期儲存契約](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/docs/architecture/github-oauth-credential-persistence.md)、[LG81-Cap-R 獨立審查](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/live-preparation-review.md)、[逐段 machine／Human 結果](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/live-validation.md)、[非真人測試](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/tests.md)與[成果 review](https://github.com/a129924/rivet/blob/c8c989a2e4be99e73c9cdc17e82cc16ada7a489c/plan/github-oauth-credential-persistence/evidence/review.md)為索引；不重跑仍適用的成功驗收。

| 證據層級 | 已支持的結果與限制 |
|---|---|
| Fake Security／受控 provider | 正式 adapter 的完整 codec、query／有限錯誤、clientID 保護、整筆替換與 accepted rotation 後本地保存失敗停止契約；受控 fetcher／clock 不是真遠端 rotation。 |
| 真 DPK／完整假憑證 | 2026-11-05 透過正式 public adapter 完成 A 保存→Writer 結束→fresh Reader A→整筆替換 B→fresh Reader B→同身分真正 clean/build→新程序讀 B。完整六欄、attempt／程序／binary／operation／ACK／final 歸屬及原同身分條件有證據，LG81-Cap-R approved、無必修。五個 runtime Human 全程觀看、0提示；其他 build／sign 觀察依原文，不擴首 sign 的 permission-only 回報。 |
| 真遠端 OAuth／refresh／API | 本 topic 未驗證；不拿 E003 或 PR #62 的遠端結果回填，也不將假 token 的完整保存當作真 OAuth 連線成功。 |

Live 適用原驗收時指定 Mac／GUI 使用者、原 certificate／Team／AppID／group、有效且相同 profile 與位置；不因此證明本日 profile 狀態、profile 更新／過期恢復、certificate rotation、多程序協調、公開發行或所有環境。Configuration item live、系統拒絕、crash／斷電 durability 與新 merge binary 真人驗收亦未由此證明。原失敗／unknown、receipt／quota 保留；LC06 DPK item 清理、圖 Human visual／S08 接受及整體產品完成不因 PR 合併而自動通過。

E004 仍是真 SQLite 搭配假 refresh／clock，不證秘密保存；E005 legacy Keychain 最新 Human 0／0／1 維持 UX 失敗；E007 的兩輪 renewal read 未執行仍為 unknown。這些原 rows／來源不改，PR60 另列正式 adapter 的指定環境結果，不新增實驗編號。

Annotated tag `v0.1.60-github-oauth-credential-persistence` 已正常建立／推送並讀回 object／peeled merge 一致，精確指向 `c8c989a2e4be99e73c9cdc17e82cc16ada7a489c`，不是 GitHub Release 或後續文件 commit。兩個原 untracked Xcode 個人 metadata 已在 Git 私有0700 archive 保留原 bytes／mode／owner 與私有來源對照，讀回核符後只移出兩 source leaves；archive 不進 Git、不 push，DPK item／Apple assets 未清理。這只是文件準備時的 Git 收尾事實，branch／managed worktree 刪除仍以文件先安全存入 remote dev 及當段 fresh gates 為前提；未執行項不預填成功。


## PR #66：原生登入 UI／Demo 的交付與採用（2026-11-11）

[PR #66](https://github.com/a129924/rivet/pull/66) 已於 `2026-11-11T06:55:06Z` 合併並關閉，目標為dev，merge `2c7679a8399f634dc6429fcd8bfd6018a5a0693f`、最後 feature `9eda244ff15c3928eedad2731d3680c52473d17f`。本節歸屬已合併的 Presentation 交付，E001–E009 的實驗編號、結果與額度保持原來源。交付內容為 non-BC `RivetLoginView` 與七態假資料 `RivetLoginDemo`，正式 backend／OAuth 串接及 macOS 系統文字大小偏好整合屬後續能力。[長期 UI／Demo 說明](https://github.com/a129924/rivet/blob/2c7679a8399f634dc6429fcd8bfd6018a5a0693f/docs/presentation/login-ui.md)

| 來源層級 | 保存版本與可追溯範圍 |
| --- | --- |
| 合併／最後 feature | Merge `2c7679a8399f634dc6429fcd8bfd6018a5a0693f` 保存最後 feature `9eda244ff15c3928eedad2731d3680c52473d17f` 及 Human 採用 metadata。 |
| 實際受測程式 | Source `dcc48b29686ab324fc19399ef607f462a507cce5`，View SHA-256 `cf1f007065af1449c5ca945dafd00fe81fbba1187479e0d501f72d651e51f1a8`。 |
| 受測執行檔 | Debug／wrapper SHA-256 `50a30cdc872292f8cd4de5a689b52ae2ab9d6451613067ff8440ba68b384d67f`，release `25a8136f02e9d974d27c8a644f37304ace8e7cc80ccb007c9c3db56a79dcd9c5`。Merge 是保存版本，執行來源依原受測指紋判讀。 |

2026-11-11 Human 最終明確回覆「通過，採用目前這版」。本輪實際通過案例包括

- PAT 真 Return 自動讀出驗證中狀態，Welcome 與真 browser failure Retry 進 waiting 均讀出清楚狀態、無明顯重複，Escape 返回 Welcome 並讀主按鈕。
- Demo 局部21pt的 Welcome／PAT／PAT Failure／Waiting／Connected 五畫面排版、必要捲動及操作可達，包含 Show／Hide續編輯、失敗後重新輸入與 Cancel返回。Human 已釐清 Cancel 返回 Welcome 後曾再進waiting。
- 17pt同PAT表單內容／focus保留與排版可達，13pt Return→waiting→立即Escape後焦點及朗讀穩定。

PAT本次聲音證據為自動驗證狀態有聲，重複次數未單獨確認。Human大字範圍為上述21pt五畫面及17pt同表單，15格矩陣仍為先前程式版本 `9f8955c40696cee6d77739da6d22d659287cfbc0` 的工具原生取證。原1009d七類Human pass、高對比／Reduce Motion、spinner旋轉觀察、舊兩次無聲／probe／模糊同句與後續AX快照時序，均保留各自原始紀錄。[採用結論與逐項來源](https://github.com/a129924/rivet/blob/2c7679a8399f634dc6429fcd8bfd6018a5a0693f/plan/rivet-login-ui/evidence/verification.md)

該來源的既有自動檢查為 focused15 tests／root289 tests、debug／release、format、scoped SwiftLint（136 files、0 findings）與完整hooks通過。Root strict保留37項既有experiments加2項原樣素材，共39項非零紀錄。PR Lens pinned0.11.0的map範圍止於source dcc，validate／render0、38個exact-head refs與XML labels已核；Graphify採缺圖source fallback，Archify沿用凍結七態。[來源與工具交付紀錄](https://github.com/a129924/rivet/blob/9eda244ff15c3928eedad2731d3680c52473d17f/plan/rivet-login-ui/evidence/verification.md)

User本輪授權後，annotated tag `v0.1.61-rivet-login-ui` 已正常建立及推送，local／remote tag object 均為 `2649261883b4c0f89ce47647f5b83ee1a291f309`，peeled commit 均為上述merge2c7679a。原remote branch刪除前親核仍指feature9eda244，隨後正常刪除remote branch、移除原managed worktree並以 `git branch -d` 刪除local `feat/rivet-login-ui`。Remote／local／target tracking ref及worktree目錄／註冊均已核不存在，其餘兩個worktree註冊保留。Tag固定保存PR merge，後續文件維護為獨立版本。

## E010：W1 baseline 受限完成，完整自然週期仍 pending（PR #67）

此節分列尚未合併 PR #67 的獨立 DPK profile-continuity 進度，不把 Ready for review 當作 merged。[E010 README](E010/README.md)保留原 10/21／10/22 Human Build success 與有界 host／matching Report 缺口並存：當時未取得 selected App／actual proof／完整 global，沒有 App/SecItem/seed 或跨週 item。原 grants/run 均 closed，該兩輪零 item 私有 root 已精確清理；10/22 僅 cleanup 越 cutoff 3.954765 秒但在 deadline 前，舊收據不改，不當 Keychain delete/read-absent。

遷移保存22原檔快照與171同 bytes 移動資料，原193檔逐筆 accounting；[typed map](E010/history/renumbering-map.json)的1952 file refs 與3 non-file aggregate digests 分開，五個歷史 source 版本無法取得，不能稱所有舊 source 可重建。M03 Tester／M04 Reviewer approved 只核受限遷移與離線準備。

其後 2026-11-10 的新 W1 已有同 binary 的一次 seed／一次 fresh，六欄相符，Human 各全程觀察0提示；獨立審查僅接受本輪 baseline 機制與限定 UX。此結果不推論完整自然 profile 週期、一般零提示 UX 或新 certificate 數量。來源見[最新22-source manifest](E010/evidence/ng-date-preparation-20261110/source-manifest.json)、[W1 baseline index](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/index.json)及[close addendum](E010/evidence/ng-validation/b90f5f16-d3c8-452f-af91-86b88d6dc64e/baseline-review-candidate/close-addendum.index.json)；machine／Human 分層，原 canonical prompt unknown 與記錄時點 pending flags 保留。

W2 真自然到期／P1 讀回原 A、W3 Rebuilt、完整 S07/S08 與主假設仍 pending。P0 expiry 為台灣 **2026-11-17 15:28:08**，原 D 為 **2026-11-20 15:22:03.379959**；原 A／namespace／三窗與期限不重設或延長。RP cleanup blocked／delete=0；[RT metadata index](E010/evidence/retention-scope-20261110T094256Z/index.safe.json)及[machine receipt](E010/evidence/retention-scope-20261110T094256Z/machine.safe.json)只記一次 metadata 操作的4602 retained entries，minimumComplete=false，不稱 minimum 或 RP 清理成功。

三筆 `01265ad`／`c0e6414`／`d30f5c4` 共312檔已正常 commit／push，各六個正常 hooks 通過；這不是新的真人結果或 GitHub CI 通過證據。2026-11-11 查核時，PR #67 為 Ready for review、尚未 merged。E010 的受限結果不核准新的正式 adapter 採用，不吸收 PR #60 的正式 adapter 證據，也不改 E001–E009 歷史。


## PR #67：合併版本與受限收尾事實（2026-11-11）

前一 E010 節的 Ready／未 merged 文字是合併前查核快照。[PR #67](https://github.com/a129924/rivet/pull/67) 已於 `2026-11-11T08:48:57Z`（台灣16:48:57）合併並關閉；actual merge `a554a4fee772d3976d5ca2c9331865a604e901e2` 保存最後 feature `7fa4bfffc5989a351790dca6a1695758c906950c` 的相同 tree。這是既有 E010 交付版本的保存，不把 Git 合併當作完整實驗、資料清理或新的正式 adapter 採用。[Active fix 6504801](https://github.com/a129924/rivet/commit/6504801b3b43a6ae937cbd898d9354d53ffc8543) 修正 GUI recovery producer selection 與 Swift probe argv guard；兩個必要 review threads 已回覆並 resolved，未解決數0。[新來源 manifest](E010/evidence/pr67-review-fixes-20261111/source-manifest.json)的22-source aggregate `d253834a…` 與[獨立 Tester 收據](E010/evidence/pr67-review-fixes-20261111/tester-validation.json)是 active 純修正證據，未移植至舊 W1 frozen source `b8c567…` 或升級原 grant；frozen recovery 可能仍含原 bug、是否觸發 unknown。

W1 seed／fresh 六欄相符、Human 各全程0提示的受限 baseline 結果保留；W2 真自然到期／P1 讀回原 A、W3 Rebuilt、完整 S07/S08／profile 週期及主假設仍 pending。P0 expiry 台灣 **2026-11-17 15:28:08** 與原 D **2026-11-20 15:22:03.379959** 不延長，原 A／namespace 不重設。RP cleanup blocked／delete=0；RT 僅記4602 retained metadata entries，minimumComplete=false。原 PR60／66 及其他實驗 rows／來源／成功、失敗與 unknown 保持各自證據界線。

Annotated tag `v0.1.62-e010-dpk-profile-continuity-baseline` 的 local／remote object 均為 `53f1efd44b4d4cdbf0b2ada8752620a2b667e8b5`，peeled commit 均為上述 actual merge；不是 GitHub Release 或後續維護 commit。原 feature remote branch 已在 server expected head `7fa4bff…` lease 保護下正常刪除，並讀回不存在，dev 與 tag lineage 仍在。Local branch／原 managed feature worktree 因兩份 AQ local-only 檔案及 W2／W3 實際 physical path 依賴 unknown 而保留，未 force remove、未搬檔；外部72檔 archive、原 W1／history／安全證據／圖及 App／Keychain／Apple 資產均未藉此清理。Git 收尾的已完成部分不解除原實驗留存與後續驗收條件。

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
