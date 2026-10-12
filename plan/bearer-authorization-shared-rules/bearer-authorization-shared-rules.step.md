# 既有 Bearer Authorization 入口共用規則：狀態帳本

## Current state

- Topic：`bearer-authorization-shared-rules`。
- Branch：`feat/bearer-authorization-shared-rules`。
- Feature worktree：`agent-20261012-bearer-authorization-shared-rules`；所有後續工作僅在此處，dev 工作目錄不得修改。
- Base：`origin/dev`，`1c8ff51bb5b569bb63a5c80e44dc59bc711d0226`（Observer 提供的建立交接）。
- Phase：S5 獨立成果審查已明示 approved，待執行已授權的 topic commit／push／Draft PR，之後 human review。
- 四份 artifacts 已實際落檔；S2 由獨立 Plan-Reviewer 明示 approved（planning readiness），原文及受審版本見下方紀錄。
- Current step：S5／completed；下一動作交 Implementer 依人類預授權執行 topic commit／push／Draft PR。目前尚未 commit、push 或建立 PR。
- Planner 歷史 verdict：先前 `approved` 僅限當時 planning-preparation readiness，不構成本次修訂批准。
- Plan-Reviewer verdict：`approved`（planning readiness）；Reviewer verdict：`approved`（S5 成果審查）。
- 產品實作已完成；Implementer 局部 red／green 與品質檢查見下方，不取代獨立 S4／S5。

## Steps 與證據

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| S1 | completed | Plan-Creator | 已確認修訂的四份 artifacts 落檔且可讀。 | 本次建立 requirements、technical-spec、plan、step 四檔；相對路徑列於下方，僅檔案建立證據，未自審。 |
| S2 | completed | Plan-Reviewer | 獨立審查本次修訂並明示 verdict。 | 獨立 Plan-Reviewer `plan_reviewer` 明示 `approved`（planning readiness）；原文、證據及受審 SHA-256 見下方紀錄。 |
| S3 | completed | Implementer | 完成受限修改並交接。 | helper、兩 overload、GraphQL 委派、錯誤、T1–T6 所需測試及文件已完成；局部證據見下方，交獨立 Tester。 |
| S4 | completed | Tester | 執行修訂後 T1–T6 與必要命令，記錄實際結果。 | 最終版本 package 85 tests／12 suites、root 194 tests／25 suites、consumer 9 tests／2 suites，以及 format、lint、renderer hook、diff check 均 exit 0；見下方獨立驗證證據。 |
| S5 | completed | Reviewer | 依成果及 Tester 證據明示 verdict。 | 獨立 Reviewer `plan_reviewer` 明示 `approved`、findings 無需修正；原文結論與證據引用見下方 S5 紀錄。 |

S1 artifacts：

- `analysis/bearer-authorization-shared-rules/requirements.md`
- `analysis/bearer-authorization-shared-rules/technical-spec.md`
- `plan/bearer-authorization-shared-rules/bearer-authorization-shared-rules.plan.md`
- `plan/bearer-authorization-shared-rules/bearer-authorization-shared-rules.step.md`

S2／S5 審查後，唯一由 Plan-Creator 僅將 verdict 原文及證據引用記入本帳本，不重新判定；Observer 與 Reviewer 不修改。所有 step IDs、owners 與未執行狀態保留；S1 因本次實際建立文件轉為 completed。

### 獨立規劃審查紀錄

- 審查角色：獨立 Plan-Reviewer；agent `plan_reviewer`，由 Observer 交接本次明示結果。
- Verdict 原文：`approved`（planning readiness）。
- Findings：無需修正。
- 證據摘要（依審查者交接紀錄）：以 source 確認 helper／overloads／唯讀資料足夠、GraphQL 映射與 401-only recovery、現有 caller 僅 tests、target dependency，以及 T1–T6 完整。
- 本記錄由 Plan-Creator 僅忠實記錄，未重新判定、實作或執行測試。

受審版本 SHA-256（本次帳本記錄前已確認與交接版本相符；`.step.md` hash 指記錄本 verdict 前的受審版本）：

| Artifact | SHA-256 |
| --- | --- |
| `analysis/bearer-authorization-shared-rules/requirements.md` | `12e610e16771d6ceac21f934b20b7392f6ec0246fcb868429e254021282fd5f8` |
| `analysis/bearer-authorization-shared-rules/technical-spec.md` | `69a384d53e42d4072d176908ac100800b32e479c332f105055b9499b71c772c6` |
| `plan/bearer-authorization-shared-rules/bearer-authorization-shared-rules.plan.md` | `a709ae439bf137e1a9be5684883552e1f511cb32d397f765cf249c4b0710fa43` |
| `plan/bearer-authorization-shared-rules/bearer-authorization-shared-rules.step.md` | `c916c4c7a781b6e209e50215125e972e6c0c203f2271be71fc5054b2934ababd` |

### S3 實作與局部 TDD 證據

- Implementer 只修改 B／C／D allowlist 及本帳本；未修改 dev 工作目錄、Manifest、wrapper／executor、provider、REST、其他 topics 或既有圖表。未 commit／push／開 PR。
- `AuthorizationHeader` 抽出唯一 internal replacement helper；`BearerAuth` typed throwing 初始化、private immutable 完整 Header value、新 public nonthrowing Headers overload 與 Request 委派均完成。
- GraphQL 局部建立 BearerAuth 並轉接 Headers，映射 token-free `.invalidAuthorizationToken`。新增 import 導致兩個 `HTTPResponse` 同名，因此僅在既有 interceptor 將回傳型別限定為 `Apollo.HTTPResponse`；未新增抽象或改變 protocol。`next`／取消／status 仍在 catch 外。
- 新增直接 interceptor 測試及兩個 Apollo chain 失敗情境，使用既有 fake fetcher 的 test-only replacementToken；保留 snapshot、取消、401 recovery 原測試。
- Red：`swift test --package-path packages/RivetHTTPClient --filter BearerAuthTests` exit 1，缺少 Headers overload，dictionary 無法傳入原 Request overload；`swift test --filter 'GitHubGraphQLAuthorizationTests|invalidInitialToken|invalidReplacement'` exit 1，缺少 `.invalidAuthorizationToken`。皆為尚未實作目標契約的編譯失敗。
- Green：`swift test --package-path packages/RivetHTTPClient --filter 'BearerAuthTests|AuthorizationHeaderTests'` exit 0，18 tests／2 suites；`swift test --filter 'GitHubGraphQLAuthorizationTests|ApolloGraphQLIntegrationTests|StaticIsolationTests'` exit 0，60 tests／5 suites（filter 同時涵蓋其他 static isolation suites）。合法／非法 corpus 各 7／21 cases；初始非法 Token send 0／fetcher 0，非法 replacement send 1／fetcher 1 均通過。
- 最後 static isolation 改以精準 Set 表達例外，修正格式與 lint 的 opening-brace 衝突；此等價整理在上述局部測試之後，最終版本仍交 Tester 重驗。
- `scripts/check-swift-format.sh` exit 0；`scripts/check-swiftlint.sh` exit 0，106 files／0 violations；`git diff --check` exit 0。
- 既有 `JSONSemanticDecodingError.Kind` Sendable warning 曾在首次 package build 出現，檔案為唯讀且本次未修改；不視為本 topic 新增問題。最終 test code 的 unused-result warnings 已以明確 discard 清除。
- 局部原始 logs 置於外部暫存目錄的 `bearer-red-package.log`、`bearer-red-graphql.log`、`bearer-green-package.log`、`bearer-green-graphql.log`、`bearer-format.log`、`bearer-lint.log`。全套兩個 `swift test` 與 consumer check 留待 S4。

### S4 獨立 Tester 驗證證據

- 角色：獨立 Tester `tester`；所有命令在 feature worktree 執行，未使用 dev build 或修改產品／測試。S3 最後的 static isolation 精準 Set 整理已包含於本次全套驗證。
- `swift test --package-path packages/RivetHTTPClient`：exit 0，85 tests／12 suites。
- `swift test`：exit 0，194 tests／25 suites；包括 GitHubIntegration static isolation、直接 Interceptor 與完整 Apollo chain。
- `scripts/check-swift-format.sh`：exit 0。
- `scripts/check-swiftlint.sh`：exit 0，106 files／0 violations。
- `scripts/check-github-integration-consumer.sh`：exit 0，9 tests／2 suites；腳本使用獨立 scratch 並完成清理。
- 既有 renderer pre-commit hook `bun run check`：初次 exit 127，分類為 feature worktree 缺少生成依賴（`biome: command not found`），非產品迴歸；同目錄 `bun install --frozen-lockfile` exit 0，安裝 9 packages，未修改 lockfile 或其他 tracked 檔案。重驗 `bun run check` exit 0，format／lint 各檢查 45 files、未套用修正，typecheck 通過。
- `git diff --check`：exit 0。上述檢查未產生本 topic allowlist 外的 tracked diff。
- T1：有效／無效 Token corpus 的 BearerAuth 初始化與 GraphQL 映射皆通過；錯誤 diagnostics 不帶 Token。
- T2：一般 `import RivetHTTPClient` 驗證 public Headers overload；空 Headers、所有同時存在的 Authorization 變體替換、其他 entries、輸入不變及 idempotency 通過。
- T3：Request overload 與 Headers overload 一致、URL／Method／Body 保留、原始 Request、nonthrowing existential applying、redaction／reflection 通過。
- T4：直接 Interceptor 的 request 資料保留、HTTP 語意、idempotency、非法 Token `next` 零次及下游 sentinel 原樣傳遞通過。
- T5：`invalidInitialTokenNeverSendsOrRecovers` 通過，session Request 0、fetcher 0；`invalidReplacementStopsBeforeRetrySendOrExtraRecovery` 通過，session Request 1、fetcher 1，無 retry send 或額外 recovery。
- T6：全套成功、取消、HTTP status、401 recovery／第二次 401、partial／errors-only、network／parser failure、並行 snapshot 隔離與 import／consumer contract 通過。
- 原始 logs 留在外部暫存目錄：`bearer-s4-package.log`、`bearer-s4-root.log`、`bearer-s4-format.log`、`bearer-s4-lint.log`、`bearer-s4-consumer.log`、`bearer-s4-renderer-install.log`、`bearer-s4-renderer.log`。本次 package／root logs 無新增 warning 或 error。
- S4 completed；明示交獨立 Reviewer 依實際 diff 與上述證據執行 S5。本記錄不構成成果審查 approval；未 commit、push 或開 PR。

### S5 獨立 Reviewer 成果審查紀錄

- 審查角色：獨立 Reviewer；agent `plan_reviewer`，由 Observer 交接本次明示結果。
- Verdict 原文：`approved`。
- Findings：無需修正。
- 原文結論：「已獨立審查實際 bounded diff、未追蹤的新測試與四份 planning artifacts」。
- 審查者確認：兩入口 BearerAuth Headers 委派、唯一 validate／format／replace、無 `try!`／吞錯／fallback、URLRequest 副本、catch 外的 next／cancel／status、`Apollo.HTTPResponse` 必要限定、精準 import、唯讀範圍、有效 tests、長期 docs 及 source-breaking 契約。
- 審查者確認 requirements／technical-spec／plan SHA-256 與上方 planning approval 版本相同；本次帳本後續狀態更新不改寫原受審版本 hash。
- 證據引用：本帳本「S3 實作與局部 TDD 證據」、「S4 獨立 Tester 驗證證據」及 Tester 原始 `bearer-s4-package.log`、`bearer-s4-root.log`、`bearer-s4-consumer.log`、`bearer-s4-lint.log`、`bearer-s4-renderer.log`。Reviewer 已讀原始 logs，確認 package 85、root 194、consumer 9 tests、lint 0 violations 與 renderer 成功；空的 `bearer-s4-format.log` 之 exit 0 依 Tester 明示交接記錄，不重跑。
- 本記錄由 Plan-Creator 僅忠實記錄 verdict 及證據引用，不重新判定、不實作、不執行測試。S1–S4 與驗證歷史保留。
- Next：交 Implementer 直接執行已獲 Human 授權的 topic commit、push、Draft PR，再交 human review；目前尚未執行這些 delivery 動作，不 merge／release。

## Blockers 與 Human Check

### Blockers

- 目前無已回報的未解除 blocker。歷史「四份 artifacts 未落檔」已由 S1 解除；「尚無本次 Plan-Reviewer verdict」已由 S2 的明示 approved 解除。
- S4 全套驗證已完成；原「S5 尚待執行」已由獨立 Reviewer 明示 approved 解除。下一動作為已授權交付，尚未執行 commit／push／Draft PR。
- 若出現新的 scope、path 或 locked decision 衝突，停止並交還人類，不以推論補足。

### Human Check

- 原 Q1–Q5 與「兩入口統一透過 BearerAuth、新增 public nonthrowing Headers overload」決策已確認，無須重問。
- 人類最新已接受計畫，授權 feature-only 實作及無重大問題時直接 topic commit、push、Draft PR，再交 human review；取代先前將這些 delivery 動作排除的記錄。
- S2、S3、S4、S5 已依明示交接完成；本次 Reviewer approved 與既有 Human 預授權允許交 Implementer 直接進行 topic commit／push／Draft PR，不再新增 message 確認 blocker。之後交 human review；不 merge／release。
- 本次 Plan-Creator 未實作、未測試、未 commit／push／開 PR；最終 merge／release 未獲授權。

## 最後更新

2026-10-12T16:32:12+08:00（Asia/Taipei），Plan-Creator：僅記錄獨立 Reviewer 明示 approved、原文結論及證據引用；S5 completed，保留 S1–S4 與全部驗證歷史。交 Implementer 執行已授權 topic commit／push／Draft PR，之後 human review；目前尚未執行交付，未 merge／release。
