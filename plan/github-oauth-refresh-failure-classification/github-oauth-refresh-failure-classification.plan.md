# GitHub OAuth refresh 失敗分類執行計畫

Topic：github-oauth-refresh-failure-classification
Branch：feat/github-oauth-refresh-failure-classification
Base：dev，初始 commit 6c65a3ec5932ae01d14309c2171d2f8eef41c4cd（PR #48 已合併）
Worktree：../rivet.worktrees/agent-20261008-github-oauth-refresh-failure-classification

## swift-implementation 執行契約

G = Sources/BoundedContexts/GitHubIntegration；T = Tests/GitHubIntegrationTests；D = docs/architecture/diagrams/github-oauth-dual-client-architecture。下列為 exact allowlist，不是 directory glob。

| 欄位 | 契約 |
| --- | --- |
| Goal | 提供可靠 refresh failure 分類、provider 狀態與 GraphQL mapping |
| Non-Goal | 不擴張登入、REST、其他 BC 或 generic HTTP 的責任 |
| In-Scope | technical-spec 已鎖 API／adapter／state／取消、migration、tests、長期文件／圖、本機 PR Lens |
| Out-Of-Scope | REST GET、產品登入、初次 exchange、Keychain、device flow、secret 部署、reconciliation、一般 retry／rate limit、live OAuth、圖表發布 |
| Written | 下列新檔案與 v7 family |
| Modify | 下列既有檔案 |
| ReadOnly | packages/RivetHTTPClient 全部 tracked files、其他 BC／Presentation、其餘 GI DTO／snapshot／stores／Apollo／acquisition、E001–E003／歷史 topic／v1–v6、scripts／AGENTS／skills／hooks／.gitignore／.github config／allowlist 外 tracked files |
| Deleted | 無 |
| TestCase | TC01–TC12，結果寫 step evidence |

### Written

- analysis/github-oauth-refresh-failure-classification/requirements.md
- analysis/github-oauth-refresh-failure-classification/technical-spec.md
- plan/github-oauth-refresh-failure-classification/github-oauth-refresh-failure-classification.plan.md
- plan/github-oauth-refresh-failure-classification/github-oauth-refresh-failure-classification.step.md
- G/Contracts/OAuthTokenRefreshError.swift
- G/OAuth/GitHubOAuthHTTPTokenFetcher.swift
- T/GitHubOAuthHTTPTokenFetcherTests.swift
- Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/OAuthRefreshContractTests.swift
- D/token-lifecycle-v7.json
- D/token-lifecycle-v7.html
- D/token-lifecycle-v7.delivery.json
- D/token-lifecycle-v7.visual-check.json
- D/token-lifecycle-v7.visual-check.html
- D/token-lifecycle-v7.visual-check.1440x900.light.png
- D/token-lifecycle-v7.visual-check.1440x900.dark.png
- D/token-lifecycle-v7.visual-check.2048x1320.light.png
- D/token-lifecycle-v7.visual-check.2048x1320.dark.png

### Modify

- Package.swift
- G/Contracts/OAuthTokenFetcher.swift
- G/Providers/OAuthTokenProvider.swift
- G/GraphQL/GitHubGraphQLClient.swift
- T/OAuthTokenProviderTests.swift
- T/GraphQL/GraphQLTestSupport.swift
- T/GraphQL/GitHubGraphQLClientTests.swift
- T/StaticIsolationTests.swift
- Tests/RivetPRInboxTests/StaticIsolationTests.swift
- README.md
- docs/design-principles.md
- docs/architecture/README.md
- docs/architecture/github-oauth-dual-client.md
- docs/architecture/bounded-contexts/README.md
- docs/github-api/README.md
- D/README.md
- D/scene.js
- D/index.html
- D/canvas-visual-review.md
- D/canvas-overview-1440x900.png
- D/canvas-top-1440x900.png
- D/canvas-bottom-1440x900.png

PRInbox test amendment：僅將既有全 manifest 的 HTTPClient 字串禁令改為 PRInbox target dependencies 的結構檢查；維持 PRInbox source import 禁令，禁止修改該 BC production source。TC12 包含此隔離驗證。此 exact-path amendment 交獨立 Plan-Reviewer 核准後實作。

Canvas exact-filename amendment：已有 overview／top／bottom 三張 canonical screenshot 在本 topic 更新；canvas-1440x900.png 與 lifecycle v1–v6 historical evidence 不改。此 amendment 必須通過同一正式 Plan-Reviewer。

PR Lens scratch 為 repo 外本機產物，不納入 tracked allowlist。若 canvas skill 要求改寫 screenshot，先以 exact filenames 修 execution contract 並交 Plan-Reviewer；不得開放 diagram directory glob。

## TestCase

| ID | 驗收 |
| --- | --- |
| TC01 | 固定 POST endpoint／form／headers、特殊字元 escaping、無自動 retry |
| TC02 | 六欄／bearer／非空 token／正整數期限、空 scope、receivedAt mapping |
| TC03 | HTTP 200 bad_refresh_token；兩 provider 入口 authenticationRequired |
| TC04 | 可信 2xx／4xx 純 error 的 App configuration／送出前 known technical；保留 bundle、可後續 refresh |
| TC05 | timeout／network／5xx／unknown／malformed／mixed；包含已知 code 但 5xx 或 mixed 的交叉案例仍為 technical terminal，不認 authRequired |
| TC06 | terminal 後兩入口零 ports、不交付舊 snapshot、保留 store |
| TC07 | single-flight／version／stale recovery／persist-before-publish／persist failure terminal |
| TC08 | 無可信 response 的取消，before 非 terminal、after 當次取消且後續 noncancel technical |
| TC09 | 可信 response 後取消，known errors 決定狀態、有效 pair 仍 persist |
| TC10 | caller A cancelled／shared waiter B uncancelled，A 取消、B 實際結果、狀態一致 |
| TC11 | 兩入口 expired-rotation exhaustion nonterminal，後續可 refresh，不認 authRequired |
| TC12 | GraphQL expiry／401 mapping、最多重送一次／second401、新 bundle／provider 恢復、public compile／static isolation |

## 品質驗證與工具

Swift TDD red-green-refactor；focused／root swift test、public consumer script、static isolation、Swift format／lint、git diff check／allowlist，必要 pre-commit renderer checks。所有 tests 離線，不能把環境錯誤冒充 red behavior failure。

Archify 2.16：先 matching lifecycle/common schemas／example，再寫 candidate；每次 edit 後 validate showcase（九 checks、零 composition errors/warnings），deliver final freeze 與 SHA／byte receipt，再更新 v7 canonical links。visual-check 1440x900、1600x1000、1920x1080、2048x1320 containment，實看 responsive 與 min/max light/dark。自動 visualReview pending 不等於人工通過。責任 canvas validate/build／visual inspection，不發布。

Graphify 0.9.73：現無 graph，rg/source fallback；若提供 graph則 bounded query、revision/sourceverify、每次 GRAPHIFY_NO_AUTO_REFRESH=1，不能安裝／extract／stamp／改 hooks/config。PR Lens 0.11.0：真實 diff 後 repo 外 local validate/render、manifest、unchanged neighbors／file refs／主要變更edge、多處變更3–7步walkthrough，不代替 correctness review、不upload。工具失敗記實際錯誤與fallback。

## 角色／交付／授權

Plan-Creator 落檔 → 獨立 Plan-Reviewer approved → Implementer → Tester → 獨立 Reviewer → staged semantic check／topic commit → push → Draft PR（base dev）→ Human review。

Human 本次直接授權 commit by topic、push、open Draft PR；在沒有重大 blocker 且 checks通過後按該授權執行。仍先從 staged diff 提出符合 git-commit-convention 的 message。Human review 是最終停點；不 merge、release、移除 worktree 或清理其他 branch。
