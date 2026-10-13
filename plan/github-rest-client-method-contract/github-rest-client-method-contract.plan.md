# GitHub REST method 契約執行計畫

- Topic：`github-rest-client-method-contract`
- 責任：既有 non-BC GitHubIntegration
- Branch：`feat/github-rest-client-method-contract`
- Baseline：`79f473b2fc51572b39455b65db010c2a8b55093f`，建立 feature worktree 時與 dev／origin/dev 一致。
- 狀態：實作與獨立驗證已完成；Plan-Reviewer／Reviewer approved，等待已授權交付及 human review。
- 依據：[requirements](../../analysis/github-rest-client-method-contract/requirements.md)、[technical-spec](../../analysis/github-rest-client-method-contract/technical-spec.md)、[step ledger](github-rest-client-method-contract.step.md)。

本契約九欄位供 swift-implementation 受限交接使用；不新增 implementation.json 或其他必要 artifact。所有修改僅在 feature worktree；dev worktree 禁止寫入。branch 依 repository-local git-branch-naming，以新增能力 feat 與 topic slug 組成，未捏造 owner。

## Goal

讓同一 target 呼叫端透過可替換契約執行 GET／POST／PUT／PATCH，以 builder／完整 request 雙入口取得 raw response／既有 technical failure，統一處理首次 HTTP 401 的最多一次 recovery。

## Non-Goal

不宣稱交付建立 review、合併 PR、通知已讀、產品登入或 BC 業務能力；不新增 BC。

## In-Scope

- internal Sendable 八入口契約、四 methods request 組裝、完整 request method 一致性與既有 GitHub URL guard。
- request-local Bearer、HTTP 401-only 一次 replay、既有 technical errors／cancellation／provider snapshot single-flight。
- GET caller／測試相容調整，精確 isolation allowlist、測試與長期文件／既有圖表同步。
- graphify 受限唯讀導航、archify 既有 lifecycle 修訂、真實 provenance 可表達時的 PR Lens 本機 change map。
- 依使用者後續明確授權，在正式審查／驗證完成且無重大問題後直接 topic commit、push feature branch、建立以 dev 為 base 的 Draft PR，交 human review；不新增中途確認。

## Out-Of-Scope

DELETE／HEAD／OPTIONS、stream body、跨 target 公開、BC Adapter／Port／DTO／failure mapping、產品寫入／UI、新 token 類型、credential lifecycle／Keychain／generic HTTP runtime 重構、新 package／BC、一般 retry／backoff／pagination／rate limit、共通 headers／API-version policy。

graphify extraction／建圖、安裝／升級／自動 refresh、repository config／hooks 更動、地圖上傳／發布、自動 preview、PR Lens auth／analyze／canvas／PR actions，以及為產圖而新增 commit 均不包含。使用者已另行授權 GitHub Draft PR；PR Lens 的 local-only 限制不取消此交付授權。不含 merge、release 或發布 artifact.cafe。

## ReadOnly

下列範圍只讀；未列於 Written／Modify 的 repository 檔案也預設只讀：

- Sources/BoundedContexts/GitHubIntegration/Contracts/、Providers/、GraphQL/、OAuth/、Stores/；provider、snapshot、credential lifecycle ports 不變。
- Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClientError.swift。
- packages/RivetHTTPClient/ source、tests、manifest；各 BC／Presentation／其他 targets；所有 manifests／resolved dependencies、tooling／CI configs／hooks／.gitignore。
- GraphQL／provider tests 與既有 GraphQLTestSupport；Tests/GitHubIntegrationTests/REST/GitHubHTTPTransportTests.swift，只執行 regression。
- docs/architecture/diagrams/github-oauth-dual-client-architecture/token-lifecycle-v10.* 及更早 lifecycle specs／HTML／receipts／captures，全部保留。
- docs/architecture/diagrams/github-oauth-dual-client-architecture/canvas-1440x900.png，保留歷史 evidence。
- 若存在，.github/pr-lens.yml 只讀；不存在不建立。可用的既有 graphify graph 只讀，不 refresh。
- 其他 topic analysis／plan 文件及 dev worktree，均不得修改。

## Written

允許新增下列精確檔案；後續調整仍限同檔，不擴張清單：

- Sources/BoundedContexts/GitHubIntegration/REST/GitHubRestClient.swift
- Tests/GitHubIntegrationTests/REST/GitHubRestClientTests.swift
- analysis/github-rest-client-method-contract/requirements.md
- analysis/github-rest-client-method-contract/technical-spec.md
- plan/github-rest-client-method-contract/github-rest-client-method-contract.plan.md
- plan/github-rest-client-method-contract/github-rest-client-method-contract.step.md

在 docs/architecture/diagrams/github-oauth-dual-client-architecture/ 下，只允許新增：

- token-lifecycle-v11.json
- token-lifecycle-v11.html
- token-lifecycle-v11.delivery.json
- token-lifecycle-v11.visual-check.json
- token-lifecycle-v11.visual-check.html
- token-lifecycle-v11.visual-check.1440x900.light.png
- token-lifecycle-v11.visual-check.1440x900.dark.png
- token-lifecycle-v11.visual-check.2048x1320.light.png
- token-lifecycle-v11.visual-check.2048x1320.dark.png

Repository 外另允許每 topic 獨立系統暫存目錄中的 pr-lens/graph.json 及 pr-lens/rendered/，僅作非正式 local validation 產物，不提交、不發布、不作第五份 artifact。正常 build caches 不屬交付 artifacts，不提交。

## Deleted

無檔案刪除。executeGET 改名是既有 source 修改，不是刪除檔案。

## Modify

只允許修改：

- Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClient.swift
- Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift
- Tests/GitHubIntegrationTests/StaticIsolationTests.swift
- README.md
- docs/design-principles.md
- docs/architecture/README.md
- docs/architecture/github-oauth-dual-client.md
- docs/architecture/diagrams/github-oauth-dual-client-architecture/README.md
- docs/architecture/diagrams/github-oauth-dual-client-architecture/scene.js
- docs/architecture/diagrams/github-oauth-dual-client-architecture/index.html
- docs/architecture/diagrams/github-oauth-dual-client-architecture/canvas-visual-review.md
- docs/architecture/diagrams/github-oauth-dual-client-architecture/canvas-overview-1440x900.png
- docs/architecture/diagrams/github-oauth-dual-client-architecture/canvas-top-1440x900.png
- docs/architecture/diagrams/github-oauth-dual-client-architecture/canvas-bottom-1440x900.png
- Written 列出的新增檔案，限同 topic 必要調整；四份 artifacts 更新內容一致性、實際 status／evidence／verdict。

替身與新 REST test transport／gates 限 GitHubRestClientTests.swift 或 GitHubHTTPClientTests.swift，不新增未列名 support 檔。source/import allowlist 只精確新增契約，不放寬整個 integration／tests。文件與圖只同步本次交付及 canonical links，不擴張架構或宣稱產品能力。

## 既定實作決定

完整八 signatures 以 technical-spec.md 的 Locked interface 為唯一依據：get/post/put/patch(url: HTTPURL, headers: HTTPHeaders, body: Data?) 與 executeGet/Post/Put/Patch(_ request: HTTPRequest)，全部 async throws 回 HTTPResponse；internal protocol GitHubRestClient: Sendable。

- 四 builder 在 protocol extension 提供同 signature 組裝實作，沒有 default arguments／其他 arity overload；caller 明傳 headers/body，execution requirement 動態派送。
- GitHubHTTPClient 符合契約，保留 concrete 名稱／init／transport factories／error；executeGET 改 executeGet，不加 alias。
- 共用 private execution 先驗證 expected method／URL，再取得 used snapshot；同步 validation 與既有 async cancellation boundary 順序不變。
- URL 保持 HTTPS api.github.com、無 user/password/fragment、port 缺省或 443；原大小寫處理與 query/path 保留，GET body 保留。
- 原始 request 套用 request-local Bearer；首次實際 401 將 used snapshot 交 provider，從原 request 僅更換 Authorization replay 一次；第二 401 authenticationRequired。
- 非 401 raw response 原樣，transport／timeout 不 recovery。existing technical classification／CancellationError 正規化不變；不取消 shared refresh，不承諾 provider await 立即返回。
- 並發／late stale 401 使用既有 provider version／single-flight；不改 provider／GraphQL／generic HTTP runtime。

## TestCase

| ID | 情境 | 必要證據 |
| --- | --- | --- |
| TC01 | existential 八入口、明傳參數、替身與預設 builder | 記錄輸入／回傳；custom builder witness spy 生效；預設 builder 組裝並派送 execution witness |
| TC02 | 四 methods × 雙入口成功／保真 | method、Bearer、query／headers／非空 Data body 保留，包括 GET；原始輸入不變，raw response 一致 |
| TC03 | 四完整 request method mismatch／共用 URL guard | invalidRequest；load／refresh／send 零次；既有非法目的地與合法大小寫／443／query，涵蓋 builder 委派 |
| TC04 | 四 methods × 雙入口 401→成功 | 實際 used snapshot recovery；request 僅 Authorization 更換；最多兩次發送 |
| TC05 | 四 methods × 雙入口 401→401 | authenticationRequired，無第三送 |
| TC06 | 非 401／transport 代表案例與 GET regression | success／redirect／403／429／5xx raw status／headers／body；timeout／network／non-HTTP failure 無 recovery |
| TC07 | credential／token failure 代表案例與 GET regression | missing／rejected、restore／refresh／persist、非法 initial／replacement Bearer 維持分類及發送上限 |
| TC08 | 寫入代表案例及 GET cancellation | credential 前、401 後 recovery 前、shared refresh 期間、wrapped／transport cancellation；取消不 replay，shared refresh 保留 |
| TC09 | POST／PATCH 共用 provider 並發與 late stale 401 | deterministic gates／request IDs；single-flight 一次；各 request 保真；late 401 current replacement，不新增 refresh |
| TC10 | 隔離與相容 regression | GET／GraphQL／provider／redirect tests；精確 allowlist；外部 consumer public contract 維持 |
| TC11 | 文件／圖與受限集合 | 文／圖／code 一致；canonical／歷史 evidence 正確；diff 全位於允許集合 |

重用現有 GraphQLCredentialStore／GraphQLTokenFetcher／GraphQLGate 與 provider onInFlightTaskJoin seam，不修改 supports／provider，不重寫全部 provider tests；僅擴列名 REST test 檔中的 capture／per-execution responses／gates。

Tester 在 feature worktree 根目錄執行：

```sh
swift test --filter GitHubIntegrationTests
scripts/check-swift-format.sh
swiftlint lint --strict
scripts/check-github-integration-consumer.sh
swift test
```

附實際結果、TC 對應與未解 failure；未執行不標通過。圖表依下列 skills 取得驗證證據。不需真實 GitHub 寫入／UI 操作，無資料遷移。

## 指定 skills 使用安排

### graphify

使用 pinned graphifyy 0.9.73；EVERY CLI invocation（含 help／version）設 GRAPHIFY_NO_AUTO_REFRESH=1。只查可用既有 graph，bounded query budget 1500，核對 revision，重要關係 source verification。建立 worktree前未發現 graphify graph，故 targeted rg／source reads fallback；本次 explicit skill 使用不授權 extract／建圖。不得 install／upgrade／refresh／stamp／config／hooks／AGENTS 修改、provider／semantic／server。binary 路徑存在不代表 version／runtime 已驗；失效報具體錯誤後 source fallback。

### archify 與 architecture-canvas

只從 canonical token-lifecycle-v10.json 衍生 v11，更新四 methods／雙入口交付文案，不新增 sequence／ownership。作者繁體中文，固定 Viewer UI／HTML lang English fallback。showcase validate 9 checks、0 warnings／composition errors；通過後 deliver 固定 spec／HTML並保留 receipts。visual-check 檢查 1440×900、1600×1000、1920×1080、2048×1320 containment，實際檢視 light／dark captures；自動 receipt visualReview: pending 原樣保留，另記人工檢視。canvas 依 architecture-canvas 更新必要文案與驗證。不自動 preview、不發布；失敗依 skill 診斷／停點如實回報。

### pr-lens

使用 pinned CLI 0.11.0，僅 local validate／render；不 analyze／auth／canvas／API／upload／PR actions，不安裝。真實 bounded diff 與必要 source context 建圖，包含 unchanged neighbors 與 repository-relative file refs，不重探全 repo。

reference provenance 使用真實 commit base/head，未定義 working-tree revision。未 commit diff 直接 review，不用假 SHA／same-commit patch／虛構欄位產圖。使用者已另行授權 topic commit；取得能表達本 topic 的真實 distinct base/head 後，可讀 git diff --find-renames <base>...<head>，記錄 IDs，於 repo 外 per-topic 暫存產生 map；不得為產圖額外 commit。

若存在 overlay，唯讀載入並傳 renderer；無 overlay 的 scratch 驗證用 --no-config，不建立／修改 overlay、.pr-lens、.gitignore。validate／render 後核對 manifest／產物。無適當 provenance、CLI 失效、map 誤導時具體說明並直接 diff review。map 是理解輔助，不是 gate，不強迫 commit。PR Lens 本機圖禁止發布，不影響另行授權的 GitHub Draft PR。

## 執行順序與授權交付

P01 建檔 → P02 獨立 Plan-Reviewer 明示 approved → I01 bounded code/tests → I02 docs/diagrams → T01 Tester → R01 獨立 Reviewer → 已授權交付 → H01 human review。

無重大問題、Reviewer 明示 approved 後，由 Implementer 依 git-commit-convention 檢查 staged diff 語意邊界、採 topic commit，push feature branch，使用真實 repository／remote 以 dev 為 base 建立 Draft PR；正文依最終 diff、驗證與未解限制撰寫。使用者本次已明確授權直接 topic commit／push／Draft PR，優先於一般需再次確認 message 的技能規則；不另增中途確認。遇到重大問題、scope／architecture／path／locked decision 衝突、blocked／human-check 或未授權動作停止回報。不得 merge／release。

完成證據包括實際 TC／命令／圖表結果、獨立 verdict、commit SHA／push 結果／Draft PR URL 與 human-review pending。commit／PR 交付由後續角色執行；本次 Plan-Creator 不執行 Git／tests／runtime implementation。
