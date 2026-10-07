# E002 — 受限執行計畫

- Topic：`github-oauth-pkce-token-exchange-feasibility`
- Branch：`chore/github-oauth-pkce-token-exchange-feasibility`
- Base dev／origin/dev：`a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f`。
- 配對文件：[requirements](../../analysis/github-oauth-pkce-token-exchange-feasibility/requirements.md)、[technical-spec](../../analysis/github-oauth-pkce-token-exchange-feasibility/technical-spec.md)、[step](github-oauth-pkce-token-exchange-feasibility.step.md)。
- 原正式 Plan-Reviewer gate：approved；code-bounded Reviewer approved，原圖 human-check 為歷史。A001 獨立 Plan-Reviewer approved／無 required fix；A05 runner＋v3 成果 Reviewer approved、HC-DIAGRAM 解除；目前 S06 stage／semantic check／commit 準備，尚未 commit／push。

## Swift 實作契約

| 欄位 | 契約 |
| --- | --- |
| In-Scope | E002 runner、S256／state／exchange、local DTO → public bundle、一次 /user、局部測試、遮蔽 README、一張 sequence、受限 Graphify／PR Lens。 |
| Out-Of-Scope | refresh／rotation、Keychain、正式登入 UI、REST／GraphQL client、secret 部署、schema 放寬、Graphify build、merge／release。 |
| ReadOnly | root Package.swift／Sources／Tests、E001、其他 docs、.gitignore／hooks／AGENTS／工具設定；唯一文件 append 例外見 Modify。dev 所有檔案唯讀。 |
| Written | 四份同 slug artifacts；experiments/E002 的 Package.swift、Sources、Tests、README、diagrams JSON／HTML／receipts／captures；具真實 commit provenance 時才寫 repo 外 topic PR Lens scratch。 |
| Deleted | 無。 |
| Modify | 四 artifacts 與 E002；只在真實實證及獨立 review 完成後可 append docs/architecture/github-oauth-dual-client.md 的受限結論。未實測維持該文件唯讀。 |
| Goal | 四個實證軸與資料邊界有可重現量測；先交付已局部驗證 runner，真實 HC-LIVE 可 pending。 |
| Non-Goal | 產品採用／架構改變／secret 部署決策；mock／圖／map 不能宣稱真實 OAuth 成功。 |
| TestCase | T01–T10；最多兩次真實新授權，不自動新增測量。 |

## 實作與驗證順序

1. Plan-Creator 建立四檔，交獨立 Plan-Reviewer 明示 verdict；只有 approved 才交 Implementer。
2. Implementer 依 technical-spec 在 feature worktree 以 bounded Swift TDD 實作 E002；不改 root／E001，不使用 internal DTO。完成局部 red／green 證據、README 與一張 Archify sequence，交 Tester。
3. Tester 執行 `swift build --package-path experiments/E002`、`swift test --package-path experiments/E002`，只對 E002 Swift files 做 `swift format lint --strict` 與 strict SwiftLint；檢查 diff allowlist、敏感輸出、graph HTML hash／containment。既有工具設定不改。各證據寫 step／README，不跑真實 OAuth。
4. Reviewer 獨立檢查 correctness、memory／output hygiene、scope、來源關係、圖的實際視覺，以及 source fallback 限制；尚未形成 commit 時採 bounded tracked diff、allowlist untracked／file hashes，PR Lens deferred。
5. 無重大問題且 Reviewer approved，Implementer 依 staged diff 作 `$git-commit-convention` 語意檢查、提出繁中 message，再依本輪人類既有授權 commit by topic，無須再次索取例行 permission。
6. Reviewer 使用 first topic commit 的真實 base／head 完成 repo 外 PR Lens local map／validate／render。失敗回 direct diff，記工具未完成，不為 map 增造 commit。
7. Implementer 只以同 topic 收尾 README／step 的真實驗證與工具狀態，必要時再作同 topic 文件 commit；若形成新 head，Reviewer 以最終真實 base／head 更新 map 或明示 map 涵蓋的 SHA／缺口，避免冒稱最終 map 已更新。repo 外 PR Lens 產物不 commit。
8. Implementer non-force push 此 topic branch，建立指向 dev 的 Draft PR 作 human review 入口（若適用），不得 merge。交人類 review；HC-LIVE 另保持 pending，安排人工 TTY／browser 後才可能量測與文件 append。

## TestCase 與驗收

| ID | 案例與預期 |
| --- | --- |
| T01 | 正向真實：新 code＋正 verifier＋offline_access；exchange／schema／API 分軸。非空 access token 才作唯一 /user，即使 schema 不相容。200＋有效 JSON id／非空 login 為 API 成功。 |
| T02 | 反向真實：正向 exchange 成功後，另一組新 state／challenge／code＋合法但不匹配 verifier；不重用 code。任何非空 access／refresh token 失敗；OAuth body＋受控歸因，含糊無法判定。 |
| T03 | mock S256 RFC 向量、隨機 verifier／challenge、授權包含 challenge／S256。 |
| T04 | mock state 缺漏／重複／不符、code 缺漏／空字串均不 POST。 |
| T05 | mock form encoding、精確 redirect、必備欄位、每 code 一次 POST 無 retry。 |
| T06 | mock 六欄缺漏／型別、bearer enum、scope 空字串、receivedAt＋兩個 expiry mapping，public bundle 建構。 |
| T07 | mock HTTP 200 OAuth error 不算成功、反向任何非空 token 失敗。 |
| T08 | mock callback 180 秒／HTTP 30 秒邊界、取消與 cleanup，不重試。 |
| T09 | mock／inspection stdout／stderr／證據與 error path 無敏感值，runner 無持久存取；browser／OS 留痕明示未驗證。 |
| T10 | bounded build／test／format／strict lint／diff allowlist；Archify 九項／SHA／四 viewport containment 與獨立視覺；Graphify source fallback／PR Lens 真實 provenance。 |

真實結果四軸皆成功才總體成功；任一有效 failure 為總體失敗，其餘缺測為無法判定。前置不足／拒絕／網路／timeout 停止，最多兩次新授權、各 callback 180 秒／HTTP 30 秒、不 retry。圖／map 的交付品質不改寫 OAuth 結果。

README 必含目標／原因／事前判準／實際環境／App 查證狀態／無 secret 重現步驟／分軸與總體結果／遮蔽證據／限制，以及真實未執行與工具 fallback。不得補造 scope／port／browser／token 相容證據。

## 授權與停止條件

最新使用者明確授權「只在 feature 實現，不得 dev 任何檔；無重大問題直接 commit by topic → push → human review」。此授權覆蓋原對話稿末段例行 commit／push 再確認停點；仍須 staged diff 語意檢查與提出 message，不借用 E001 授權，不 merge／release。

scope／locked decision 衝突、正式 review needs-rework 回對應角色；重大 blocker／human-check 停止並回報。HC-LIVE 只表示未提供 client ID／secret、需人工 TTY／browser，不阻已測試 runner 的 commit／push／human review；不得讀既存 secret、請使用者把 secret 放聊天或隱式真實授權。

Archify 最多兩輪 focused repair，連續兩次最佳 error count 未改善即停止；圖／工具 fallback 如實記 needs-rework／blocked／pending，由對應角色分類，不能用工具輸出替代 review。仍成立結論只能在真實實證及 review 後 append 長期 docs；未實測本次不 append。

## A001：追加圖修復預算

2026-10-07 — 使用者已批准追加最多兩輪圖修復且不改驗收。此明示 amendment 只覆蓋原「不得自行增加原兩輪預算」的後續預算停點：原 2／2 失敗歷史保留，追加已用 1／2 獨立計數（累計 3／4），總上限四輪，無其他 scope／授權變動。

先由 Plan-Creator 記錄四檔 → 獨立 Plan-Reviewer approved → Implementer 只修 E002 sequence 新 v3／v4 版本 → Tester 複驗 hashes、showcase／四尺寸 containment／captures → 獨立 Reviewer 視覺與 blocker classification。既有 v1／v2 不覆寫、不補造缺失 provenance。程式 code-bounded approved 與既有測試證據保留；除非新變更／失敗造成新疑慮，不重跑 runner 實作或真實 OAuth。

原 showcase 九項、零 errors／warnings、四 desktop 無 overflow、最小／最大 light／dark captures、獨立實際視覺 acceptance 全部不變。每追加輪皆記診斷與實際計數；兩次連續未改善最佳 objective error count，或追加兩輪耗盡仍未達標，停止 human-check，不自行加輪或豁免。

HC-LIVE 仍 pending、真授權 0／2；code-bounded approval 不冒稱整體 approved。A05 成果 Reviewer 已明示 approved；正式圖入口為 experiments/E002/diagrams/pkce-token-exchange-v3.html，原失敗／缺口保留為歷史。沿原 S06 起的 commit → PR Lens → non-force push → human review 路由；既有人類授權保留，目前未 commit／push，dev 仍唯讀。
