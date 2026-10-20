# GitHub 首次登入：受限執行計畫

- Topic：`github-first-sign-in`；2026-10-20，Plan-Creator 初稿，待獨立 Plan-Reviewer。
- Branch：`feat/github-first-sign-in`；base／PR target：dev；只在指定 feature worktree 實作。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[step](github-first-sign-in.step.md)。

## 1. 九欄與 bounded handoff

每個 `swift-implementation` bounded step 開始及完成交接均逐項列以下原拼寫九欄，實際逐檔展開本 manifest 的子集；這不是可任改整個目錄的授權。

- **In-Scope**：本 slice 允許的行為／責任；S03 授權、交換、factory；S04 程序內 store、host、coordinator、Presentation、API 與文件。
- **Out-Of-Scope**：儲存／重啟／DPK、多帳號、logout／revoke、PR 業務、其他 worktree、generic HTTP auth 及既有 lifecycle 重寫。
- **ReadOnly**：凍結的 public contracts／runtime policy、唯讀參考。檔案可讀不代表整份可寫；M01 的 additive imports／組裝例外明列，不把需接 factory 的檔案整份凍住。
- **Written**：開始交接是 planned allowed exact new paths；完成交接才是 actual new paths＋diff 證據。不得把允許清單複製成完成結果。
- **Deleted**：預設無；包含 rename 造成的刪除。若需要刪除，先回修契約並獨立審查，不能直接擴張。
- **Modify**：開始列允許既有檔與修改目的；完成列 actual changed paths／diff hunks，不改名為 Modified。
- **Goal**：該 slice 可觀察結果；S03 完整初次 bundle，S04 正式 app 至實際 API 身分結果與同程序重複操作。
- **Non-Goal**：不保證持久連線、全部遠端 refresh／401 證據、repository permission 或遠端撤銷。
- **TestCase**：TC IDs、預期／實際命令、輸入層級、結果、相對 evidence path；區分 passed／failed／未執行／Human pending。

交接記真實 revision、bounded diff、dirty patch 範圍／識別；工具暫存輸出獨立列，不混入 repository Written／Modify，更不能混入憑證。此 planning 建立階段只有四 artifacts 實際 Written；產品實作／tests／圖尚未執行，Deleted=無。

## 2. 精確檔案 manifest

Aliases 僅縮寫固定前綴；每個分號項是一個允許檔案，不授權任意新增目錄內容：G=`Sources/BoundedContexts/GitHubIntegration`；GT=`Tests/GitHubIntegrationTests`；A=`apps/Rivet`；P=`Sources/Presentation/GitHubConnection`；D=`docs/architecture/diagrams/github-first-sign-in`；E=`plan/github-first-sign-in/evidence`。

### Written：planned allowed 新檔

| ID／slice | 精確相對 paths | 用途 |
|---|---|---|
| W01 Planning | `analysis/github-first-sign-in/requirements.md`; `analysis/github-first-sign-in/technical-spec.md`; `plan/github-first-sign-in/github-first-sign-in.plan.md`; `plan/github-first-sign-in/github-first-sign-in.step.md` | 四份正式 artifacts；建立後依對應角色更新 |
| W02 S03 | `G/Contracts/GitHubOAuthAppConfiguration.swift`; `G/OAuth/GitHubOAuth.swift`; `G/OAuth/GitHubOAuthAuthorizationSession.swift`; `G/OAuth/GitHubOAuthCodeExchanger.swift`; `G/OAuth/GitHubOAuthAuthorizationError.swift` | additive configuration／factory／session／exchange／安全 errors |
| W03 S03 | `GT/GitHubOAuthFactoryTests.swift`; `GT/GitHubOAuthAuthorizationSessionTests.swift`; `GT/GitHubOAuthCodeExchangerTests.swift` | deterministic clock／random／HTTP seams、PKCE／callback／response tests |
| W04 S04 | `A/Rivet.xcodeproj/project.pbxproj`; `A/Rivet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`; `A/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme`; `A/Sources/RivetApp.swift`; `A/Sources/GitHubConnectionCoordinator.swift`; `A/Sources/GitHubLoopbackCallbackRelay.swift`; `A/Sources/GitHubAccountProbe.swift`; `A/Sources/InMemoryOAuthCredentialStore.swift`; `A/Resources/Info.plist` | 正式 app／local root package products／platform adapter／完整程序內 store；不新增 persistent adapter／entitlements；新增 lock 僅為 Xcode generated dependency lock，沿用 root Apollo 2.1.2、revision `38c202227d0f09508e573dcf22f54885cfb0c5d4`，不修改 root lock |
| W05 S04 | `A/Tests/GitHubConnectionCoordinatorTests.swift`; `A/Tests/GitHubLoopbackCallbackRelayTests.swift`; `A/Tests/GitHubAccountProbeTests.swift`; `A/Tests/InMemoryOAuthCredentialStoreTests.swift`; `P/GitHubConnectionPresentation.swift`; `P/GitHubConnectionView.swift`; `Tests/RivetPresentationTests/GitHubConnectionPresentationTests.swift` | app hosted fake-only tests／display-ready leaf；無新 module |
| W06 S04 docs | `docs/architecture/github-first-sign-in.md`; `D/scene.js`; `D/index.html`; `D/authorization-sequence.json`; `D/authorization-sequence-v2.json`; `D/authorization-sequence.html`; `D/BUILD.md`; `D/visual-review.md`; `D/tool-evidence.md` | 長期責任、architecture-canvas、Archify sequence 與驗證紀錄 |
| W07 evidence | `E/contracts.md`; `E/compatibility.md`; `E/product-e2e.md`; `E/reviewer-verdict.md` | Tester／Reviewer／Human 的脫敏實際證據；非新增正式 artifact／gate |

Archify basename `authorization-sequence` 只另允許同名 `.delivery.json`、`.visual-check.json`、`.visual-check.html`、`.visual-check.1440x900.light.png`、`.visual-check.1440x900.dark.png`、`.visual-check.2048x1320.light.png`、`.visual-check.2048x1320.dark.png`，及 deliver 產生的同目錄 frozen-spec snapshot（精確名稱／SHA 必須記 receipt）。Canvas 可另寫 `D/canvas-light.png`、`D/canvas-dark.png` 作實看證據。其他必要輸出先明列 amendment，不掃寫整目錄。Build outputs 用 ignored `.build/github-first-sign-in/`；PR Lens 用外部 topic scratch，不入 repository。

### Bounded manifest amendment：desktop geometry v2

只額外允許新檔 `D/authorization-sequence-v2.json`，用於既有授權 sequence 的 desktop geometry 修正。原 `D/authorization-sequence.json` 已通過九項 validate／deliver 並 frozen，不得修改；本 amendment 不改 OAuth scope、流程語意、contract 或產品程式碼。v2 重新 validate／deliver 後仍交付既有 `D/authorization-sequence.html`，receipt／visual-check／screenshots 沿用上述原 basename allowlist，不另開 v2 輸出系列。若 deliver 實際產生同目錄 frozen-spec snapshot，僅允許該次工具生成的精確 snapshot，名稱／SHA 依實際 receipt 記錄；未產生不得宣稱存在。此 amendment 尚待原獨立 Plan-Reviewer 審查，不自行宣告 approved。

### Modify：planned allowed 既有檔

| ID | 精確相對 paths | 限制 |
|---|---|---|
| M01 S03 | `G/OAuth/GitHubOAuthHTTPTokenFetcher.swift` | 只有必要 imports／additive internal configuration bridge 或 initializer；不改 refresh payload、response policy、redirect、cancel／rotation classification 或 visibility。若新 factory 可直接呼叫既有 init，保持檔案未改 |
| M02 S03 | `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`; `GT/StaticIsolationTests.swift` | 前者只增加 public construction／visibility／source compatibility 覆蓋；後者只精確新增 W02 sourcePaths 及其中實際必要的 RivetHTTPClient imports exceptions，不放寬 core isolation、不改舊期望配合新政策 |
| M03 S04 docs | `README.md`; `docs/design-principles.md`; `docs/architecture/README.md`; `docs/architecture/github-oauth-dual-client.md` | 回寫實際能力、責任與圖連結，保留 E001–E003 限制；Human live pending 不寫成已成功 |
| M04 | W01 四份 planning artifacts | 各角色只記自己事實與外部明示 verdict；不代 Reviewer／Human 填核准 |

### ReadOnly／Deleted

凍結 bundle／store／fetcher public signatures、OAuthTokenProvider 全部 lifecycle／snapshot／single-flight／rotation semantics、GitHubClientScope、既有 REST／GraphQL policy；不新增 disposition／quiescence。G 的既有 provider、contracts、composition、clients、endpoints 除 M01 外不修改。通用 RivetHTTPClient、PR Inbox／Reader、既有 Presentation PRInbox、root Package.swift／Package.resolved、其他 tests、experiments、其他 topic／worktree 均唯讀。

Skills／runtime／AGENTS／hooks／工具 config／.gitignore 不修改；`.github/pr-lens.yml` 若存在只讀。Deleted 預設無。不得靠改 dev 或儲存線繞過 sandbox／ownership。

## 3. 步驟與交付順序

| Step | Owner role | 範圍／完成條件 |
|---|---|---|
| S01 | Plan-Creator → Plan-Reviewer | 四份 artifacts 與 manifest；獨立 planning verdict，非自行放行 |
| S02 | Plan-Reviewer | 回查 technical-spec §6 的 Human ownership amendment／來源 SHA；僅判本 topic 分工，非等待 E007／儲存採用 |
| S03 | Implementer | W02／W03、必要 M01／M02 的 bounded 九欄交接；完整初次授權與交換能力 |
| S04 | Implementer | W04–W06／M03；完整程序內 store、app／scope／API、文件及圖；分子 slice 交九欄 |
| S05 | Tester | TC01–TC07 受控／build／compatibility；TC09 文件圖／工具證據；TC08 與真 OAuth 分列 Human pending |
| S06 | Reviewer | 獨立 bounded code／scope／evidence review；required fixes 回 Implementer，再由 Tester／Reviewer 核查 |
| S07 | Implementer | 無重大問題且上游允許時，staged 語意檢查 → topic commit → push → Draft PR 回 dev；真 IDs／URL，不能 merge |
| S08 | Human；Tester 記錄 | Draft PR 後 Human review；需要個人 secret 的正式登入／重複 /user／反向 PKCE 記真結果或 pending |

S01／S02 需要獨立 Plan-Reviewer 明示 approved 才能 S03。S02 不要求儲存線完成 adoption／全部 planning 回修；其未來產品實作前必須遵守 Human split。S05／S06 的受控結果與 code review 是 S07 前置。使用者已明示 commit/push/Draft PR 授權，不因舊逐次確認預設重問；staged diff 仍須依 git-commit-convention 檢查語意與 message。Human live pending 不是 code 已完成的證據，也不是停止可完成實作或 Draft PR 的理由。

## 4. TestCase 與驗證命令

| ID | Cases／結果 |
|---|---|
| TC01 | 正確 authorize query、offline_access、獨立 state／verifier、S256、dynamic redirect；listener ready 前不開瀏覽器、open failure 可重試 |
| TC02 | method／host／port／path／userinfo／fragment、缺失／重複 state／code／error、錯 state、code+error；無效 callback 保持有效等待、單次 claim、重複／遲到零額外交換 |
| TC03 | 五分鐘 deadline、cancel／denied／timeout／exchange race；generation gate、listener cleanup、真 settlement 前不能新嘗試；用 clock／latch，無 sleep 推測 |
| TC04 | 固定 endpoint、form encoding、完整 fields、無 redirect／cache／cookies、三十秒上限、不重送；HTTP／OAuth／network／mixed／incomplete response、Bearer／date validation、同 receivedAt mapping |
| TC05 | 完整六欄 in-memory load／save／rotation save、無 Security／檔案路徑、啟動不 restore；redaction／安全 failures，不保存原始機密或帳號值證據 |
| TC06 | caller-owned provider／scope identity、多 request、prepare 失敗同 instance retry、old refresh／save latch settlement、新 bundle 後新 provider；既有 lifecycle／REST／GraphQL regression 不變；StaticIsolationTests 精確 source manifest／imports whitelist 維持隔離 |
| TC07 | hosted fake-only live-call counters=0、正式 ad hoc build／launch、UI 進行中／取消／失敗／retry、GET /user 200+valid login/id、非200／decode failure不宣稱成功、再次查詢不重新授權 |
| TC08 | Human 於正式 app 輸入自有 OAuth App；正常 S256+完整 bundle+/user+再次查詢；缺失／錯誤 verifier 各用獨立新 code；未執行記 Human pending，不預填PKCE enforcement |
| TC09 | ownership／source-doc-diagram 一致；canvas validate/build＋實看、Archify 九 checks／deliver／四viewport／lightdark實看；Graphify fallback或source-confirm；PR Lens真diff來源與validate/render或明確限制 |

受控 commands（由 Tester 執行；此文件不表示已跑）：

- `swift test --filter 'GitHubOAuth|OAuthTokenProvider|GitHubClientScope|GitHubHTTP|GitHubRest|GitHubGraphQL|ApolloGraphQL|GitHubConnectionPresentation'`。
- `scripts/check-github-integration-consumer.sh`。
- `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`，只 check、不 formatter 掃寫其他檔。若失敗先區分新改動與既有問題。
- `xcodebuild -project apps/Rivet/Rivet.xcodeproj -scheme Rivet -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/DerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build test`。Scheme 的 hosted tests 設 RIVET_UNIT_TEST_MODE=1，不啟動 live OAuth／Security。

只對實際修改與失敗新增必要驗證；不因工具輔助失敗無限擴測。TC08 若需額外安全輔助，先以 bounded test seam 規劃；不暴露產品 verifier 繞過開關，不索取或搜尋任何 secret。

## 5. 工具、證據與停止條件

### Graphify

Pin 0.9.73；每次 CLI 連 help/version 皆設 GRAPHIFY_NO_AUTO_REFRESH=1。本輪預期 graph 位置未找到可用圖，採 targeted rg/source。以後只有現存圖才核對 revision、用真 node labels 作 budget=1500 bounded query，重要關係 source-confirm。不存在、過期、不支援或失敗就 targeted search；不 extract／build／install／semantic／provider／watcher／server／hooks／config／version stamp。

### PR Lens

Pin 0.11.0、local-only；只在實際 bounded diff 後讀 diff 與必要 context，記真 base/head IDs，dirty patch 另記邊界／hash，不能捏造 head 或為工具自行 commit。外部 topic scratch 作 graph／validate／render，保留 unchanged direct neighbors、file refs 及非trivial map 的 walkthrough。讀實際 output manifest；現有 .github/pr-lens.yml 有才只讀套用，否則 no-config；不建立 repo .pr-lens、不 install／API／uploads／comments／servers。若 schema 無法忠實描述當下 dirty diff，記限制並用直接 diff review；不代替 Reviewer。

### Archify／architecture-canvas

S04 文件圖作者文字繁中；固定 UI／HTML lang English fallback。責任邊界依 architecture-canvas 讀 scene contract、author scene.js、validate/build、實看；不得用 sequence 或 PR Lens 代替。授權流程採 Archify sequence：先 matching schema＋common＋matching example，下一個工具動作寫 candidate；不預先鑽 renderer。Showcase 九 checks、零 composition errors／warnings；validate 後 freeze、deliver 收據。visual-check 四 viewport 1440x900／1600x1000／1920x1080／2048x1320，實看最小／最大 lightdark screenshots。自動 visualReview=pending 不等於已實看；非零如實記；連續兩輪不改善即停報 diagnostics。不能發布 artifact.cafe／start preview server。

Graphify／PR Lens 是導覽／理解輔助，不是新增 OAuth 業務驗收或外部服務依賴；失敗記 concrete limitation，保留 source／diff fallback與既有 review gate。必要長期圖交付未完成則文件仍 pending，不冒稱完成。工具暫存、DerivedData、機密輸入皆不入版控；evidence 只放必要脫敏結果。

出現 scope／locked contract 衝突、越界刪改、無法符合既有 bundle、真實結果推翻契約、需新系統安全設定或外部 OAuth App 變更時，停止受影響動作並回 human-check／Scope Gap，繼續不受影響的已授權工作。個人 secret／live互動待 Human，不擅取 gh credential，不以未執行宣稱通過，不越過獨立 verdict。
