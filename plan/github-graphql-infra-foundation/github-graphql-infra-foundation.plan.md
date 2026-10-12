# GitHub GraphQL Infrastructure Foundation：Bounded Execution Plan

## 契約、工作位置與授權

本次是增強既有 topic plan，未取代原計畫。依 2026-10-07 Human決定交付 internal foundation，撤換 public execute／外部 direct-client AC；其餘 locked scope、target、provider、行為保持。

- Feature worktree：`../rivet.worktrees/agent-20261007-github-graphql-infra-foundation`；branch：`feat/github-graphql-infra-foundation`。
- 建立基線：`a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f`，來自 dev；未來 Draft PR base：dev。
- 所有 repository 寫入只在 feature worktree，dev不得新增或修改任何檔案；工具須明示 feature workdir。外部 scratch僅供已授權工具 evidence，不含產品source。
- artifacts 落地後交獨立 Plan-Reviewer；只有正式 approved才可 implementation。Human接受對話與授權 delivery不代替正式 gate。
- Human已條件式授權無重大問題時 topic commit → push → Draft PR → human review。Commit前仍依 git-commit-convention檢查 staged語意邊界並提出 message，由獲授權 Implementer執行；不把已取得的 push／Draft PR授權重新當作 blocker。Merge／release不在授權內。

## Planning／Tracking Allowlist

Plan-Creator只建立本 topic requirements、technical-spec、plan、step四份 artifacts，以及最小更新 `plan/github-oauth-token-provider-runtime/github-oauth-token-provider-runtime.step.md`：保存本次2026-10-05 Reviewer／Human acceptance、2026-10-07 internal Goal narrowing，保留歷史evidence與provider終態null。此紀錄不改 provider implementation／policy、不造 historical approval或新測試。

## swift-implementation：九欄

Owner：Implementer；前置條件為獨立正式 Plan-Reviewer approved與當前模式／授權允許。以下分類只適用本 step。

- **In-Scope**：internal Query foundation、snapshot Bearer、parser前HTTP分類、401 recovery／一次重送、finite error、集中取消helper、唯一internal Apollo testing seam與必要驗證。
- **Out-Of-Scope**：跨 target GraphQL使用或public capability、BC operations／schema／DTO／mapping／Port／failure；OAuth concrete adapters／sign-in／PKCE／callback、REST、Mutation、Subscription、pagination、rate-limit、一般retry、可調式cache與通用GraphQL abstraction。
- **ReadOnly**：既有 token／credential contracts、OAuth provider、stores／OAuth definitions、BC Core／UseCase／Port、其他 targets、RivetHTTPClient、Reader SDL與參考文件。`.vscode/`／使用者檔案不動；planning／tracking／docs另有step，不混入此step的寫入分類。
- **Written**：下列四個 GraphQL production files；所有新增GraphQL tests／test-only query／fake-session helpers／必要isolation extension；root與consumer當前缺少的Package.resolved。它們尚未建立，不記move／delete；`.build`／cache／node_modules生成物不屬source allowlist。
- **Deleted**：無。
- **Modify**：root Package.swift，既有 Tests/GitHubIntegrationTests/StaticIsolationTests.swift、Tests/GitHubIntegrationConsumer/Package.swift與Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift。只作bounded dependencies／path與visibility／必要regression更新；consumer不新增Apollo direct dependency，無需改動的檔案保持原狀。2026-10-07 Human 限定追加 `scripts/check-github-integration-consumer.sh`：只在既有 SwiftPM subshell 清除 `git rev-parse --local-env-vars` 列出的 local Git variables，不改測試／cleanup／hooks／config／gates。
- **Goal**：GitHubIntegration內部可用concrete OAuthTokenProvider執行authenticated Query，僅401安全recovery一次，保留合法Apollo response。
- **Non-Goal**：不提供public GraphQL client／跨target入口，不交付產品登入或BC adapter，不新增module／target／product、REST目錄、provider protocol或外層policy／mapper abstraction；不保證wire request次數或provider await prompt cancellation。
- **TestCase**：依下列驗收矩陣完成wrapper interaction、真Apollo chain、取消／concurrency、Swift 6、internal visibility／isolation與正常consumer regression。不能用source inspection或historical provider tests取代新evidence。

```text
Sources/BoundedContexts/GitHubIntegration/GraphQL/
├── GitHubGraphQLClient.swift
├── ApolloGraphQLClient.swift
├── GitHubGraphQLHTTPInterceptor.swift
└── GitHubGraphQLClientError.swift

Tests/GitHubIntegrationTests/GraphQL/
└── 新增 GraphQL tests／query／fake-session helpers／isolation extension
```

既有 shared StaticIsolationTests與consumer保持原位。新增protocol位於ApolloGraphQLClient.swift，不增第五個production file。根target與其test target加入exact Apollo2.1.2必要dependencies；其他target圖與既有isolations保留。

## 實作與驗收矩陣

先依swift-tdd建立精準tests，在已approved契約下實際編譯internalfetch／seam／requestchain，再完成fixedconfiguration與docs。API sketch只是設計，不是假compile evidence；若固定契約無法成立，交回實際failure與bounded required fix，不另創gate。

| 情境 | 必須驗證 |
| --- | --- |
| authenticated200 | snapshot Bearer、固定POSTendpoint、原query／variables、一次sessionexecution |
| 401→200 | 完整used snapshot回provider，replacement Bearer，samequery／variables，最多一次recovery、兩次execution |
| 401→401 | authenticationRequired；無第二recovery、第三execution；namedmaximum固定1 |
| empty／non-JSON401、empty403 | parser前辨識；401recovery，403httpStatus且不refresh |
| partial data＋errors、errors-only | 原Apollo response保留，不generic throw或refresh |
| missing／restore／refresh／persist | finite mapping保留stage，無任意underlying／secret diagnostics |
| network／parser／其他HTTP | executionFailed或httpStatus，不refresh／額外execution |
| APQerror／cache | APQoff，payload不觸發額外execution；explicit不寫cache，不僅assertnetworkOnly |
| cancellation | await／send前後與throwpath；caller取消優先；CancellationError／URLError.cancelled／stage-wrapped cancellation；不recovery／retry、不cancelsharedrefresh，await返回後不send |
| concurrentqueries | TaskLocal／各URLRequest Bearer隔離；真provider single-flight與stale-version ownership；client不建refreshstate |
| Swift6／boundary | generic／TaskLocal／noncopyable實際compile，真Apollochain；client／fetch／seam／error internal；exactpathimportallowlist與既有provider／BC isolation |
| consumer | 正常import的既有publicAPI regression；無Apollo directdependency或外部@testable產品可用性宣稱 |

## Docs Writeback Allowlist

Owner：Implementer；只在feature回寫仍成立的狀態：README.md、docs/design-principles.md、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md、docs/architecture/bounded-contexts/pr-inbox.md、docs/architecture/bounded-contexts/pr-reader.md。

只修改shared internal foundation的交付狀態／責任說明；跨target GraphQL、BC adapters、OAuth concrete adapters仍deferred；E001／其他topic evidence不改，既定長期shared-consumer responsibility不重開。

既有docs/architecture/diagrams/github-oauth-dual-client-architecture/下，只更新canvas scene.js／canonical index.html與其必要validation／visual evidence、README，以及canonical token-lifecycle-v6.json／html／delivery／visual-check receipts與必要generatedimages。按architecture-canvas／archify完整驗證，作者文案繁體中文、receipt paths repository-relative。只更新internalGraphQL交付狀態與既定契約；v1–v5 immutable historical evidence不覆寫或刪除，不發布artifact.cafe。

不修改其他docs／topics、CI、quality scripts或lintpolicy；唯一 Human 限定例外為上述 consumer script 的 nested Git environment sanitation。

## Human 授權的可恢復 Delivery 修復

2026-10-07 Human 另授權先將受損 exact feature index 與非 generated 工作內容備份至獨立可恢復 scratch，保留 manifest／SHA256；只從 feature HEAD 重建 index，不 checkout／reset／刪除任何 working files，不動 dev index 或 shared cache。重建前後須確認全部工作檔 hash 不變，再只 stage 原 allowlist 加上述唯一 script。

最初 commit-hook checkout failure 與後來 index 污染分開記錄：Implementer 診斷曾把真 feature `GIT_INDEX_FILE` 傳給 nested SwiftPM，極可能把 index 覆寫為 Apollo tree；不得全歸咎於原 hook。後續污染驗證只能使用 disposable Git fixture／index，驗證 normal／polluted environment 與 fixture index hash 不變。兩項限定修復完成後重新交既有 Tester／Reviewer；本修復輪不 commit／push／PR，沒有新增產品 scope 或重開鎖定決策。

## Verification、Navigation與Delivery

Implementer明示完成handoff → Tester先跑新GraphQLfocused tests，再跑StaticIsolationTests、consumer wrapper、root swift test、非改寫式format／SwiftLint／diffchecks與diagramvalidation → 獨立Reviewer檢查scope／contract／取消／retry／concurrency／docs → approved且無重大blocker後由Implementer依既有conditionalauthority作topiccommit／push／DraftPR → HumanReview停止。

僅用 $graphify 查證本 topic 的既有接點與受影響範圍；發現缺漏就回報，不自行擴大 scope、建立 graph 或重開已鎖定決策。

先前graphify0.9.73未找到usablegraph，revision／freshness／query未驗證；sourcefallback不是graph evidence。每次CLI `GRAPHIFY_NO_AUTO_REFRESH=1`；不build／extract／掃全home/cache，缺graph不新增gate。Delivery時才用$pr-lens為actualdiff在外部scratch產生本地map供humanreview，不建repo `.pr-lens`或改config、不upload；不得把map當approval。

遇到scope／path／lockeddecision衝突、compile／verification無法滿足契約或角色明示blocked／human-check時停止並附證據。已取得的條件式deliveryauthority不解除任何正式review／testgate；DraftPR之後不自動merge／release。
