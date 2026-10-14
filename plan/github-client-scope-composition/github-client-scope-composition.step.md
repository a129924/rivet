# GitHub Client Scope Composition — Step Ledger

- Topic：`github-client-scope-composition`
- Current phase：Draft PR 已交付；等待 H01 人類 review
- Current step：H01
- Current status：pending
- Upstream verdict：approved；派遣者傳遞獨立 R01 Reviewer 限定例外後 reassessment，無 required fixes。
- 最後更新：2026-10-14，Implementer（記錄派遣者提供的獨立 R01 verdict 與實際交付狀態）。
- 帳本狀態與 checkbox 不等同 approval；不得自行宣稱 gate 通過。

## 已知基線

派遣者提供 `dev` base `c4bb4b9f122c37d437f58335548543bcc96be5aa`。
派遣者提供 branch `feat/github-client-scope-composition`，原始狀態 clean。
Implementer 已以唯讀 Git 確認指定 feature branch；所有寫入在指定 feature worktree，未 commit／push／開 PR。
Caller 保留 provider、public scope readiness、雙 contracts 與限定檔案清單均已鎖定。
所有實作只能在指定 feature worktree；dev worktree 不得寫入。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 四份同 slug artifacts materialized，承接 locked scope 與 allowlist | requirements、technical-spec、plan、step 已建立；非品質 verdict |
| P02 | completed | Plan-Reviewer | 獨立檢查四 artifacts、workflow、API、scope、14 AC 與 path contract；明示 verdict | 派遣者傳遞獨立再審查 approved；14-row AC mapping fix 後無 remaining findings |
| I01 | completed | Implementer | 僅依 approved plan 公開 contracts／errors，完成 scope readiness 與 internal factory | 公開 REST／GraphQL contracts 與 errors；private provider 強持有、準備前後取消檢查、本地 Bearer validation、internal factory；provider／transport policy 未修改 |
| I02 | completed | Implementer | 完成 scope tests、normal-import consumer fixture、精確 isolation allowlist | Scope 13 tests pass、normal-import consumer 12 tests pass、受影響 regression 143 tests pass；詳細 evidence 見下 |
| I03 | completed | Implementer | 回寫長期文件、責任 canvas、canonical lifecycle v12 與 skill evidence | 長期四文件、責任 canvas 0 errors／warnings；v12 9／9＋四 desktop containment＋七張 captures 已實看 |
| T01 | completed | Tester | 獨立執行 14 AC 對應驗證、consumer、regression、format、lint、coverage；依 2026-10-14 人類限定例外接受 root 未達 90% | root 264／31、consumer 12／3、format、strict lint 通過；root coverage script exit 1、57.41% 未達 90%，failure evidence 保留；HTTP 85／12、97.81%；詳見 T01 evidence |
| R01 | completed | Reviewer | 獨立審查實作、測試 evidence、scope drift、secrets 與 long-term docs；依人類限定例外再評估並明示 verdict | 派遣者提供獨立 reassessment approved；全部 source public boundary、取消、ownership、14 AC 與 36-path allowlist 已審；plan:123／step:65 例外記錄真實，無 required fixes |
| D01 | completed | Implementer | 依已明示授權檢查 staged diff、提出 message、topic commit／push／Draft PR | feature commit `002855b58487575bc4beeb55a6a23deb85806198` 已 push；Draft PR #57，base dev；全部 commit hooks 最終通過；本機 PRLens validate／render 通過 |
| H01 | pending | Human | Review Draft PR，決定後續合併或修正 | [Draft PR #57](https://github.com/a129924/rivet/pull/57)；等待人類 review，不自動 merge／release |

## P02 檢查輸入

- `analysis/github-client-scope-composition/requirements.md`
- `analysis/github-client-scope-composition/technical-spec.md`
- `plan/github-client-scope-composition/github-client-scope-composition.plan.md`
- `plan/github-client-scope-composition/github-client-scope-composition.step.md`

獨立 reviewer 應確認九個 plan fields、Deleted=[]、precise allowlist 與 readonly 邊界。
確認 prepare final cancellation check、sanitized errors、shared provider 與每 execution fresh snapshot。
確認 existing transport／401-only retry／terminal／rotation persistence 語意未被重新決定。
確認 consuming Apollo vocabulary 不進 BC Core／UseCase／Port。
文件已建立不代表 planning sufficiency 或 implementation readiness 已通過。

## 驗證交接要求

Implementer 必須提供實際 changed paths、bounded diff 與完成交接，不補造執行證據。
Tester 記錄每條 command、結果、coverage 與未驗證項目；不以 fake-only 證據取代真實跨 client recovery。
Reviewer 明示 `approved`／`needs-rework`／`blocked`／`human-check`，不得自審。
圖 evidence 包含 v12 c9 checks、零 errors／warnings、sha／bytes、四 desktop outputs 與視檢。
責任 canvas 使用 architecture-canvas，lifecycle 使用 archify，各遵守 validation／visual。
Graphify／PRLens 限制與 fallback 以 plan／spec 為準，禁止為工具改 config 或假 commit。
PRLens outputs 留外部 topic tmp，不另增第五份 formal artifact。

## Blockers

目前無已明示 scope／API／path blocker。
P02 初審 needs-rework 的 canonical 14-row 映射已補；派遣者傳遞獨立再審查 approved。Implementer 未自行宣稱 planning gate 或 code review 通過。
若審查指出 drift，交回 Plan-Creator required fix，再交原獨立 Plan-Reviewer。
若實作需碰 readonly path，停止該部分並回報，不自行擴張 allowlist。

## Human Check

2026-10-14 人類明示：「接受本 topic 限定例外，繼續交付（建議）」。限定例外見 [Plan 驗收限定例外](github-client-scope-composition.plan.md#topic-coverage-exception)。
Root coverage script 實際 exit 1、57.41% <90% 保留；主要缺口為未修改 Presentation，未量測 exact base checkout coverage。全域 90% threshold、script、exclusions 與 readonly 邊界不變。
決策理由：先前獨立 R01 human-check 僅 coverage 契約缺口、無實作缺陷；root 264／31、consumer 12／3、HTTP 85／12＋97.81%、format／strict lint 與 Scope 100%／REST 100%／GraphQL 98.85% 證據保留。
Coverage 人類決策已解除；R01 獨立 reassessment pending，不自行 approved。D01 仍待 Reviewer approved。
文件導覽 v11 href 已由 Implementer 修正至已存在 canonical v12，diff check pass；下方原注意事項保留為歷史 evidence。

人類已授權 feature-only implementation，後續 topic commit、push、Draft PR 與 human review。
最新明示授權優先於舊的 commit 再確認規則；仍先檢查 staged diff 並提出 message。
D01 不需重複詢問同一授權；不得自動 merge、release 或 publish artifact.cafe。
H01 是 Draft PR 人類 review 停點。
新增 scope／contract decision 或無法解除 blocker 必須交還人類。

## Routing

P01 → 獨立 P02 approved → I01／I02／I03 → T01 → 獨立 R01。
`needs-rework` 回對應產出角色；保留 required fix 與再驗證證據。
`blocked`／`human-check` 停止自動前進並交還人類。
R01 approved → 授權 D01 → H01 human review。
歷史交接：Implementer 完成 I01–I03 時 T01／R01／D01 尚待執行；現 T01 已完成執行並依人類限定例外接受，R01 reassessment 與 D01 仍 pending，未自行給獨立品質 verdict。

AC01–AC14 canonical evidence mapping 見 [Plan 驗收映射](github-client-scope-composition.plan.md#ac-verification-mapping)；規劃時 T01 尚待執行；現實際獨立 T01 evidence 與 AC matrix 見下。


## I01–I03 實際 Evidence

- TDD red：先新增 missing-credential scope test，`swift test --filter GitHubClientScopeTests` 因缺少 `GitHubClientScope`／`GitHubClientPreparationError` 編譯失敗；實作後同一測試 green，1 test pass。
- 最終局部 Scope：`swift test --filter GitHubClientScopeTests`，13 tests／1 suite pass。涵蓋有效／過期 restore readiness、不探測 API、sanitized restore／refresh／persist、非法 Bearer、terminal／rotation-indeterminate／persist 後重複 prepare、prepare 前／中／final cancellation、underlying 與 typed cancellation，以及真實 REST＋Apollo 受控 transports 的 single-flight、late 401 與 fresh snapshot。
- Consumer：`scripts/check-github-integration-consumer.sh`，12 tests／3 suites pass；一般 `import GitHubIntegration`、離線 REST default builders／八 methods、Query／Mutation fake、public scope／errors；無 @testable、無真實 credential／API。Direct dependencies 維持 Apollo 2.1.2；resolved pins 與檔案均未改。
- Regression：`swift test --filter 'GitHubClientScopeTests|GitHubHTTPClientTests|GitHubRestClientTests|GitHubGraphQLClientTests|GitHubGraphQLMutationTests|ApolloGraphQLIntegrationTests|ApolloGraphQLMutationIntegrationTests|GraphQLIsolationTests|StaticIsolationTests'`，143 tests／11 suites pass（新增最後 underlying CancellationError case 前；之後 Scope 13 tests pass）。Readonly regression test 實作未改。
- Quality：`scripts/check-swift-format.sh` pass；`swiftlint lint --strict`，152 files／0 violations（包含最終新增取消測試與繁體中文 API 文件註解後重驗）。只格式化本 topic changed Swift files。此為當時交接要求；獨立 Tester 後續已執行完整 root／consumer／format／lint／coverage，結果見 T01，coverage 仍未達 90%。
- Canvas：architecture-canvas validate／build 成功，5 bands／16 boxes／17 edges／0 errors／0 warnings；overview／top／bottom 三張 1440×900 captures 實際檢視。詳見圖目錄 `canvas-visual-review.md`。
- Archify v12：validate／deliver 成功，9／9 showcase，composition 0 errors／0 warnings。四 desktop 1440×900／1600×1000／1920×1080／2048×1320 containment pass；最小與最大 light／dark 四張實看，`visual_review: passed`、`correction_rounds: 1`。初次 35px overflow 以精簡重複卡片文案修正，重新 validate／deliver 後採最終 receipts；沒有修改 HTML 或 v11。
- v12 specification SHA-256：`63b4c97aa33146c7210987ac0f7bb0245811a411219460c54361be675d405c5e`，7073 bytes。
- v12 artifact SHA-256：`26bbe388b107661560f79582b6c15feddd6f2477786a9addfde34484ed1fe421`，713218 bytes。Receipt 僅 input／output 正規化為 repo-relative path；auto visualReview pending 原值保留。
- Graphify：無已知現成 graph，以 targeted rg／source fallback；未執行 Graphify CLI／build／extract／refresh／stamp／install／hooks。工具版本由派遣者提供確認，不重驗。
- PRLens：pending delivery stage，須對真實 committed base/head bounded diff 執行；本次未造 commit 或 graph，也未 remote actions。
- Scope gaps：無 required readonly-path change；未實作 deferred 產品／BC／OAuth 功能。此為 I01–I03 歷史交接狀態；其後 T01 已執行，R01 仍待限定例外後 reassessment，不視為 approved。

## T01 獨立驗證 Evidence（2026-10-14）

Tester 僅更新本 step；未修改產品／test source、commit、push、PR 或 dev。下列是執行證據，不是 Reviewer approval。

| Command | 實際結果 |
| --- | --- |
| `swift test` | exit 0；264 tests／31 suites pass，包含 Scope 13 test definitions 與全部既有 regression；macOS Keychain 與真實 WKWebView fixtures 均通過 |
| `scripts/check-github-integration-consumer.sh` | exit 0；12 tests／3 suites pass；無 `@testable`，fixture `.build` 驗證後不存在；scratch cleanup 成功 |
| `scripts/check-swift-format.sh` | exit 0 |
| `swiftlint lint --strict` | exit 0；152 files，0 violations／0 serious |
| `scripts/check-swift-coverage.sh` | exit 1；instrumented root 264 tests／31 suites pass，但 root line coverage 57.41% <90%；腳本於 root 門檻停止，不能稱整份 script pass |
| `swift test --package-path packages/RivetHTTPClient --enable-code-coverage` | 補充獨立執行 exit 0；85 tests／12 suites pass；對應 `llvm-cov report` line coverage 97.81%（503 lines／11 missed） |
| `git diff --check` | exit 0 |

Coverage 分類：正常 macOS scope 下成功建置／測試／讀取 profile，沒有 cache／Keychain／filesystem failure。Root `llvm-cov report` 為 2280 lines／971 missed＝57.41%。主要缺口在 readonly Presentation：三個 Previews 共 430 lines 皆未覆蓋；PullRequestList 15.29%、PullRequestRow 11.79%、InboxHeader 10.14%。本次新增 GitHubClientScope 49 lines／0 missed＝100%；既有 REST concrete 100%、GraphQL concrete 98.85%。Presentation 與 coverage script 均 base-equal；未另執行 base checkout 的 coverage，故不冒稱已量測 base 總百分比。不得透過修改 readonly tests／UI／script 或排除 source 來補造通過；交 Reviewer 分類既有 coverage blocker，必要時由人類決定限定例外或新的 bounded work。

### AC evidence matrix

S=`GitHubClientScopeTests`，F=normal-import `ClientContractTests`。以下 tests 均由本次完整 root／consumer 成功執行。

| AC | 實際證據 |
| --- | --- |
| AC01 | F `restRequirementsAndDefaultBuildersWorkThroughNormalImport` 呼叫八 methods／四 default builders；`graphQLQueryAndMutationUseAnOfflineInjectedContract` 以 public existential 呼叫 Query／Mutation；consumer 全域搜尋無 @testable |
| AC02 | F offline REST actor 與 GraphQL fake，不發送真實網路；public Scope 僅以 local credential prepare |
| AC03 | S missing credential、三 lifecycle stages throws，以及 invalid Bearer factory 未被建構 assertion；scope 只在 prepare 成功後返回，沒有 partial delivery API |
| AC04 | S `preparationCompletesLifecycleWithoutResourceProbe(expired:)` 兩分支，驗證 load／refresh／save counts；過期需 refresh＋persist 才 ready |
| AC05 | S missingCredential、sanitized restore／refresh／persist、credentialRejected、invalid Bearer、wrapped／typed／underlying cancellation；F public safe Sendable errors；有限 envelope 無 secret／underlying／initial |
| AC06 | S `realClientsShareRecoveryAndLateUnauthorizedUsesAdvancedVersion(late:)` 真實 REST＋Apollo controlled transports，並行 stale 401 與 late 401 兩分支，refresh／persist 各 1、兩路 initial→replacement |
| AC07 | 同 S 多次 execution 仍 load 1／refresh 1；Scope private provider 強持有且 clients 接收同一原 instance（source read） |
| AC08 | 同 S recovery 後下一 REST 與 GraphQL Mutation execution 都用 replacement Bearer，非 prepare token |
| AC09 | S local readiness 有效／過期兩分支的 resource request arrays 均 empty |
| AC10 | S `cancellationDuringAcceptedRotationStillPersistsAndDoesNotReturnScope` 在 save await 取消，save 1、fetcher 未被取消、原 provider snapshot replacement，prepare 不返回；pre-cancel 與 final-cancel 亦通過；既有 GraphQL shared-refresh cancellation／uncancelled waiter regression 通過 |
| AC11 | S terminal credentialRejected／rotationIndeterminate／afterRequestStarted cancellation 重複 prepare；persist failure 重複 prepare；fetcher 1、保留原 provider |
| AC12 | F 四 REST methods／Query／Mutation；完整 root 既有 REST／GraphQL／Apollo suites 驗證 401-only／最多一次 retry、partial／errors-only／raw responses、transport／取消；無 regression source 改動 |
| AC13 | root precise StaticIsolation／GraphQLIsolation 與 PRInbox／PRReader isolation suites pass；only enumerated source additions／import exceptions，root manifests／pins unchanged |
| AC14 | 四份長期文字均明示 local-ready 限定、多 request lifetime 非 UoW、不保證 remote／permission；S `readinessDoesNotGuaranteeFutureRemoteSuccess` 返回 REST raw403／GraphQL httpStatus403 且 refresh0；圖 receipts 綁定 frozen digest，最終內容判定留 Reviewer |

未發現 AC01–AC14 缺少關鍵 offline behavioral evidence；這不覆蓋實際 GitHub resource API、產品登入或未授權 BC adapter。

### Scope 與圖證據

- 36 changed paths 全部屬 Written／Modify exact allowlist，Deleted=[]；provider／ports／fetcher／BC／Presentation／generic HTTP／root manifest／root pins／歷史 v11 無 diff。Consumer manifest 僅新增必要 direct dependencies；consumer resolved 亦 unchanged。
- Changed text 掃描無使用者本機絕對路徑。無 Graphify build、resource API probes、remote writes 或 PRLens 假 commit；PRLens 保持 delivery pending。
- 重新計算 v12 JSON：7073 bytes，SHA `63b4c97aa33146c7210987ac0f7bb0245811a411219460c54361be675d405c5e`；HTML：713218 bytes，SHA `26bbe388b107661560f79582b6c15feddd6f2477786a9addfde34484ed1fe421`，與 frozen delivery／visual receipts 一致。
- 唯讀核對 delivery 9／9、0 errors／warnings；visual receipt 四 desktop containment pass、四 light／dark captures；canvas review 記錄 5 bands／16 boxes／17 edges／0 errors／warnings 與三張實看 captures。沿用派遣者提供 same-digest 作者已實看 evidence，Tester 未重繪或冒稱獨立新 visual pass。
- 歷史文件導覽注意事項（現已由 Implementer 修正、v12 目標存在且 diff check pass）：`docs/architecture/README.md` 第78行 token lifecycle 仍指 `token-lifecycle-v11.html`；圖目錄 README 第13–18、42行與雙 client 架構第18行已明示 canonical v12。交 Implementer 修正此既有 allowed file 的 href，再由 Reviewer 檢查；純導覽修正不需要重跑 Swift checks。

歷史 T01 結論為 needs-rework：明列 coverage ≥90% 未達，當時待 Reviewer 分類。後續 Reviewer R01 human-check 僅列此 coverage 契約缺口，未發現實作缺陷；人類於 2026-10-14 接受本 topic 限定例外，T01 執行現記 completed，但 coverage script 仍為 failed，R01 reassessment pending，不能直接進 D01。


## R01 獨立再評估與 D01 交接（2026-10-14）

派遣者明示獨立 Reviewer reassessment `approved`，無 required fixes。Reviewer 已審全部 source public boundary、取消、ownership、AC01–AC14、36-path allowlist 與長期文件；唯一 coverage human-check 已由人類 topic 限定例外解除。這是上游獨立 verdict 的轉錄，不是 Implementer 自審。上文 reassessment pending 敘述均為當時歷史狀態。

D01 已核對 local／remote dev base 相同、指定 feature branch 未有遠端同名分支或既有 PR、dev worktree clean。36 changed paths 全符合精確 allowlist，無刪除。依人類已授權 topic commit／push／Draft PR 繼續；root coverage exit 1 與 57.41% failure evidence 保留，H01 仍 pending。


## D01 實際交付 Evidence（2026-10-14）

- Feature commit：`002855b58487575bc4beeb55a6a23deb85806198`，`feat(github-integration): 公開雙 client 契約與共用 provider 的 ready scope`；36 allowed paths，Deleted=[]。已 push `origin/feat/github-client-scope-composition`，未 force。
- [Draft PR #57](https://github.com/a129924/rivet/pull/57) 已建立並實際核對 `isDraft=true`、base=`dev`、head=`feat/github-client-scope-composition`，當次 head OID 與 feature commit 相同；本 ledger audit 後再核對最終 head。
- Commit hooks：whitespace、EOF、Swift format、normal-import consumer、SwiftLint、renderer 最終全部通過。首次 renderer 因本地缺少 `biome` exit 127；僅依既有 frozen lockfile 安裝 untracked dependencies 後重跑成功，無工具版本／tracked dependency／config／hook 修改。
- PRLens 0.11.0：對實際 `git diff --find-renames <base>...<head>` 建立外部 topic tmp 本機 component change view；3 lanes／9 nodes／10 edges、4 walkthrough steps，unchanged provider／generic HTTP／Apollo neighbors 與 source file refs 已保留。首次 graph validate exit 0、light render exit 0；manifest 實際檢查為 1 SVG、1301×428、15494 bytes，head 綁定上述 feature commit。Audit commit 後以最終 PR head 重建並再 validate／render；輸出不進 repo、不上傳或附 PR。
- Graphify 無現成 graph，採 targeted rg／source fallback；未 build／extract／refresh／stamp／install／hooks。
- Root coverage script exit 1、57.41% <90% 仍為已接受的 topic 限定例外，未改全域門檻；未量測 exact base checkout coverage。獨立 R01 approved 無 required fixes。
- H01 pending：保留 feature worktree 供人類 review；dev branch／base／clean 狀態維持。不 merge、release、刪除 worktree 或 publish artifact.cafe。
