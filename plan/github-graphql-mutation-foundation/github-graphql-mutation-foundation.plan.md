# GitHub GraphQL Mutation Foundation：執行契約

## 基準、分支與前置 Gate

- Topic：github-graphql-mutation-foundation。
- git-branch-name：`feat/github-graphql-mutation-foundation`；依 repository-local git-branch-naming，無 owner 慣例使用 type/workitem。
- Feature worktree：`../rivet.worktrees/agent-20261013-github-graphql-mutation-foundation`；只在此 feature 寫入，dev worktree 不修改。
- Base：`dev@53aa6ad1adbe79c69c3800a9b87e7a7f03a51fd8`；未來 PR target：dev。
- Setup 已確認 branch attached／clean，fetch origin 後 dev 比較為 0／0。四份 artifacts 本次建立，formal Plan-Reviewer 已獨立明示 approved、無 findings；進入受限實作。
- 先前對話內容 approval 不替代四份實際文件的 formal gate。

## swift-implementation 九欄

這是既有實作 phase 的契約，不是新增 skill。路徑分類均指受限實作工作。

| 欄位 | 契約 |
| --- | --- |
| Goal | 同 target 呼叫端提交 typed Mutation／variables，取得合法 GraphQL response 或既有 technical failure。 |
| In-Scope | Internal Mutation 入口、executor witness、私有共用 execution helper、request-local Bearer、HTTP 分類、401-only 一次 recovery、取消與並發驗證、Query regression。 |
| Non-Goal | 不交付產品寫入、跨 target 使用或新認證設計。 |
| Out-Of-Scope | Public API、跨 target 契約、composition root、BC Adapter、產品 operation／DTO、codegen pipeline、Files Viewed／thread resolution／review／merge、UI、Subscription／streaming／incremental response、pagination、rate limit、一般 retry／backoff、新 credential lifecycle／PAT／Keychain／初次 OAuth 整合、Apollo 升級、新 dependency、通用 GraphQL abstraction、業務 idempotency／補償／reconciliation。 |
| ReadOnly | Provider、token contracts、REST、stores、OAuth adapter、BC implementation、Reader SDL、Package.swift／Package.resolved、packages/RivetHTTPClient/、consumer fixture、quality scripts、技能與工具設定、historical 圖表；既有 GraphQL HTTP interceptor／error 與 StaticIsolation source 不修改。 |
| Written | Tests/GitHubIntegrationTests/GraphQL/ 下新增 GitHubGraphQLMutationTests.swift、ApolloGraphQLMutationIntegrationTests.swift；手寫 fixture 加既有 support，不新增 SDL／codegen。 |
| Modify | Sources/BoundedContexts/GitHubIntegration/GraphQL/ 下 GitHubGraphQLClient.swift、ApolloGraphQLClient.swift；Tests/GitHubIntegrationTests/GraphQL/ 下 GraphQLTestSupport.swift、GraphQLSession.swift、GraphQLIsolationTests.swift。Session 只增加 Mutation／mixed concurrency 必要 deterministic 支援。 |
| Deleted | 無。 |
| TestCase | 下節完整測試矩陣與 exact commands。 |

先行 planning 新增為同 slug requirements.md、technical-spec.md、plan.md、step.md 四份文件，不算 Swift 新增產物。

獨立文件同步 Modify：README.md、docs/design-principles.md、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md，以及 PR Inbox／PR Reader 兩份 BC 長期文件的 integration 交付狀態句。維持 BC behavior／契約／依賴。另同步既有 canvas／canonical lifecycle 文案與驗證產物；不擴張 Swift production allowlist。

## 實作契約與測試矩陣

精確 client／executor signatures、私有共用 closure helper、TaskLocal、Apollo requestConfiguration 與 provider ownership 依 technical-spec。Apollo 固定 2.1.2、POST、APQ off、retry 0、Mutation NetworkOnly／writeResultsToCache false。

- Typed success、partial、errors-only、非法 response；empty／non-JSON 401 與其他非成功 HTTP status 的 parser 前分類。
- First 401 recovery、second 401 terminal、非法 initial／replacement token、provider restore／refresh／persist failure。
- Timeout、transport／parse failure、payload errors 不重送；實際 body、operation、variables 保真，各次 Bearer 正確、每 execution 最多兩次發送。
- 各 await 前後取消 checkpoints／正規化、shared refresh ownership；deterministic Query／Mutation mixed single-flight 與 late stale 401，不以時間等待推論並發。
- 真 Apollo chain 零 cache read／write、無 APQ fallback／隱藏 retry；Query、REST、provider、isolation、外部 consumer regression。

Tester 接收明示完成交接後執行；目前均未執行：

```sh
swift test --filter 'GraphQL'
swift test --filter StaticIsolationTests
swift test
swift test --package-path packages/RivetHTTPClient
scripts/check-github-integration-consumer.sh
scripts/check-swift-format.sh
swiftlint lint --strict
git diff --check
```

不要求真實 GitHub 寫入，不宣稱 cancellation／transport failure 可撤銷遠端寫入或保證未執行。

## 圖表與審查工具

- Graphify：pinned runtime 0.9.73 已確認，repository 無 usable graph／metadata，採 targeted source fallback。若後續有 usable graph，先核 revision／source，再 bounded query 並回查 source。每次 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1；不 build／extract／install／stamp，不啟用 providers、hooks、watchers 或 upload。Fallback 不阻擋 topic。
- PR Lens：pinned runtime 0.11.0 已確認，repository 無 .pr-lens 或 .github/pr-lens.yml。Schema 要求真實不同 base／head commit SHA；未 commit diff 採 direct bounded diff review，不為 map 單獨 commit。已授權 topic commit 後，以真實且涵蓋變更的 base／head 執行 git diff --find-renames base...head 核對，在 topic 專屬外部 scratch 產生含 unchanged neighbors／file references 的 graph、SVG、manifest。先 validate 再 render light，無設定使用 --no-config；若當時存在 overlay 則讀既有設定。不寫 repository config，不 upload／publish map。此限制不影響使用者直接授權的 Draft PR。無前提時 fallback，不新增 gate。
- Archify：以 docs/architecture/diagrams/github-oauth-dual-client-architecture/token-lifecycle-v11.json 更新 token-lifecycle-v11.html、delivery／visual-check receipts 與 captures，維持 canonical，歷史不覆寫。依 pinned runtime 執行 validate lifecycle --quality showcase --json、同 quality deliver、含 --repo-root --json 的 visual-check。要求九項檢查、零 error／warning、四種 desktop containment；實際檢視 light／dark 截圖，pending 不記人工 pass。作者文案繁體中文，固定 Viewer UI／HTML lang 英文 fallback 揭露，不 preview／publish。
- Architecture Canvas：依既有 architecture-canvas 技能同步既有交付文案並驗證，不新增主題／責任邊界，不發布 artifact.cafe。

## 角色、交付與停止條件

Formal Plan-Reviewer approved → Implementer → Tester → Reviewer → staged semantic check／topic commit → push → 真實 base／head 的 local PR Lens map → Draft PR → Human review。

使用者已明確授權無重大問題時直接 commit by topic、push、Draft PR；依 git-commit-convention 檢查 staged diff 語意邊界並提出 message，無須再次要求已獲授權動作的 permission。既有 hooks 不略過，不能以此授權略過正式 gates。

Draft PR 可用 gh 或已連線 GitHub connector。gh CLI token invalid；主 agent 已確認 connector 為 a129924 且對 a129924/rivet 有 push／admin 權限，故不列為本地 planning blocker；git push 按正常途徑驗證。PR target dev，draft true。無 merge／release。

needs-rework 交回對應角色；blocked／human-check 停止。若需要 public API、產品 operation、新 dependency、Apollo 升級、provider lifecycle 或既定 path／contract 變更，附 evidence 回報具體 gap，不自動擴張。
