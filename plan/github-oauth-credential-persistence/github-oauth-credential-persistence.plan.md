# GitHub OAuth 正式憑證儲存：受限執行計畫

- Topic：`github-oauth-credential-persistence`。
- Branch：`feat/github-oauth-credential-persistence`；base／Draft PR target：`dev`；base supplied by dispatcher：origin/dev 16606b89。
- 工作位置：本 topic 專屬 feature worktree，禁止修改別人的 persistent-connection worktree／E007。
- 配對：[需求](../../analysis/github-oauth-credential-persistence/requirements.md)、[技術契約](../../analysis/github-oauth-credential-persistence/technical-spec.md)、[帳本](github-oauth-credential-persistence.step.md)。
- `swift-implementation` 為交接標題，不是同名 skill。分支符合 git-branch-naming 小寫 ASCII／連字號、無既定 owner 時 feat/work-item；不另換分支。

## 1. 九欄 bounded contract

| 欄位 | 精確範圍 |
|---|---|
| In-Scope | additive configuration／DPK stores、兩 items strict codec、有限錯誤、同步 Security seam／shared actor、fake-only provider／consumer驗證、長期文件與單張 storage sequence |
| Out-Of-Scope | 登入／callback／UI、signed host、E007／live Security／profile／prompts、provider／ports／clients／package改寫、新BC、logout、遷移、多帳號／跨程序協調 |
| ReadOnly | 下列 R leaf／既有 foundations；與 Modify 無重疊；其他檔案不因可讀而可寫 |
| Written | 下列 W01–W04 精確 leaves；W01 本次建立後是既有 artifacts，不重建；不存在才建立，已有非本topic內容先停核對 |
| Deleted | Repository 無；只清本輪 proven-owned temporary test／外部工具 scratch，不碰正式items或Human assets |
| Modify | 僅 M01–M02；M03四artifacts依角色維護，不讓Implementer代填approval |
| Goal | 正式adapter可由caller注入，完整保存／還原／替換，fake契約與provider停止行為可獨立驗收 |
| Non-Goal | 假測試冒充真DPK、cross-process、signing／prompts或完整登入；依賴他人整套Mission gate |
| TestCase | T01–T08；每次handoff明列本段精確leaves、命令／輸入／證據，不能以整表授權任改 |

## 2. 精確 manifest

W01（四份正式 artifacts；後續依 M03 維護）：
- analysis/github-oauth-credential-persistence/requirements.md
- analysis/github-oauth-credential-persistence/technical-spec.md
- plan/github-oauth-credential-persistence/github-oauth-credential-persistence.plan.md
- plan/github-oauth-credential-persistence/github-oauth-credential-persistence.step.md

W02（Implementer 新 source／test）：
- Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift
- Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift
- Tests/GitHubIntegrationTests/GitHubOAuthDataProtectionStoresTests.swift

W03（文件／圖；前綴 `docs/architecture/diagrams/github-oauth-credential-persistence/`，每一項為固定leaf）：
- docs/architecture/github-oauth-credential-persistence.md
- 該前綴下 storage-sequence.json、storage-sequence.html、BUILD.md、tool-evidence.md、visual-review.md。
- 同前綴 storage-sequence.delivery.json、storage-sequence.visual-check.json、storage-sequence.visual-check.html、storage-sequence.visual-check.1440x900.light.png、storage-sequence.visual-check.1440x900.dark.png、storage-sequence.visual-check.2048x1320.light.png、storage-sequence.visual-check.2048x1320.dark.png。
- Archify 自己的私有 same-directory frozen snapshot 僅限工具建立／清理，不授權手寫其他檔；若工具需額外保留／追蹤leaf，先回 Plan-Creator 明列並獨立審查。

W04（各角色 evidence；前綴 `plan/github-oauth-credential-persistence/evidence/`）：
- planning-review.md（Plan-Reviewer）、implementation.md（Implementer）、tests.md（Tester）、review.md（Reviewer）、publication.md（發佈執行者）。
- 各role只寫自己的事實／判讀，不代他人產approval或覆蓋歷史結論；需revision先明列新leaf。

M01（consumer驗證及靜態隔離 allowlist 機械更新）：
- Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift
- Tests/GitHubIntegrationTests/StaticIsolationTests.swift：僅在 expectedPaths 新增 Contracts/GitHubOAuthAppConfiguration.swift、Stores/GitHubOAuthDataProtectionStores.swift；Security import allowlist 僅額外允許 Stores/GitHubOAuthDataProtectionStores.swift，保留既有 legacy Keychain 例外及所有其他檔案限制，不改隔離 policy。

Planning amendment（2026-10-20）：本追加僅容納新增 adapter 必要的既有靜態 allowlist 更新，不增加產品 scope、測試豁免或 gate。由獨立 Plan-Reviewer bounded 回查；結果可在既有 evidence/planning-review.md 追加歷史，不新增 evidence leaf。本角色未修改測試或執行驗證。

M02（長期文件，只更正實際能力、限制與連結）：
- README.md
- docs/design-principles.md
- docs/architecture/README.md
- docs/architecture/github-oauth-dual-client.md

M03：W01四份artifacts。Plan-Creator維護requirements/spec/plan；各role按實際證據維護step自己的交接，Dispatcher不代審查者核准。

R（必要唯讀leaf）：
- Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenFetcher.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthTokenRefreshError.swift
- Sources/BoundedContexts/GitHubIntegration/Contracts/TokenSnapshot.swift
- Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift
- Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientScope.swift
- Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientPreparationError.swift
- Tests/GitHubIntegrationTests/OAuthTokenProviderTests.swift
- Package.swift、docs/toolchain.md、docs/development-workflow.md、scripts/check-github-integration-consumer.sh、scripts/check-swift-format.sh、scripts/check-swiftlint.sh。
- 既有REST／GraphQL／HTTPClient／其他BC／tests／experiments均唯讀；tests 唯讀明確排除 M01 的 Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift 與 Tests/GitHubIntegrationTests/StaticIsolationTests.swift，後者僅允許上述兩個 expectedPaths 及單一新增 Security import 例外；其餘限制不變。其他topic artifacts不修改；AGENTS／skills／runtime／config／hooks／gitignore／version stamps不修改。既存.pr-lens config僅存在才讀，不建立。

## 3. TestCase 與執行順序

| ID | 輸入與驗證 |
|---|---|
| T01 | Fake-only設定／六欄往返、inspect／bound ID、bound save不同ID／corrupt／denied／unavailable不覆寫、合法過期日期／空scope、throwing public construction、diagnostics redaction |
| T02 | Strict codec negative：version／missing／null／wrong type／emptytokens／nonbearer／nonfinite date；錯誤分類與invalid config零Security calls |
| T03 | Fake query／attributes精確核對DPK／sync／group／service／account／protection；update→missing add→duplicate一次update；denied不retry／delete |
| T04 | 完整A→B替換；各寫入失敗不部分commit；兩items獨立、configuration-first partial-save不rollback；shared actor所有facades完整operation序列化 |
| T05 | 正式adapter＋fakeSecurity＋受控clock/fetcher：restore、到期rotation先save再snapshot；accepted rotation save失敗後同provider terminal persist，後續無額外refresh/save |
| T06 | swift test；scripts/check-github-integration-consumer.sh；scripts/check-swift-format.sh；scripts/check-swiftlint.sh；既有provider／雙client regression不改期望 |
| T07 | Archify一張sequence source-consistent；validate／deliver九checks零errorswarnings；visual-check1440×900／1600×1000／1920×1080／2048×1320 lightdark與人工截圖檢視，Human pending如實保留 |
| T08 | docs／PR敘述／diff scope一致；無secret與live成果誤稱；獨立review及commit/push/DraftPR實證、停Human review |

獨立 Plan-Reviewer approved → root Implementer bounded TDD（先fake failing tests，再實作T01–T05及consumer，跑T06；W02/M01）→ 文件／圖W03/M02 → 獨立Tester T01–T08適用部分 → 獨立Reviewer。Required fixes只回獨立Implementer，審查者不自行修改受審產出。工具產物／QA未完成不得宣稱文件完整；無法取得Human視覺觀察可標pending帶入DraftPR，不冒稱接受。

Tests均假資料、無liveSecurity／GitHub／signing；不因adapter實作完成而觸發真DPK。適用checks只跑read-only模式，不formatter掃寫其他檔；build/cache在generated scratch。

## 4. 工具、發佈與停點

Archify 2.16讀sequence schema/common/example後才寫候選，showcase九checks、零errorswarnings；validate成功freeze，deliver再visual-check。不發布artifact.cafe。圖的作者繁中、Viewer英文fallback；人工看lightdark截圖，auto visualReview=pending不改成Human pass。不能為過check刪語意或裁切溢出。

PR Lens 0.11.0：有實際bounded committed diff才取git diff --find-renames <base>...<head>及真IDs，在外部topic scratch validate/render、讀manifest／必要unchanged neighbors/fileRefs；無committed diff先標待做。Graphify0.9.73每CLI GRAPHIFY_NO_AUTO_REFRESH=1，既存graph才boundedquery/sourceverify；目前無graph則rg。不得build/refresh/install/改設定/upload/PR writes；輔助工具具體失敗可source/diff fallback，不新增gate。

Reviewer通過且無重大blocker後，依已授權topic commit→push→DraftPR到dev。依git-commit-convention檢查staged語意／message；既有明確授權不再重問一般確認。發佈執行者記真commitIDs／checks／DraftPR URL；不merge，停Human review。PR Lens於實際commit後、DraftPR前補真diff evidence；若只改工具evidence，另以實際最終HEAD再確認source關係，不捏造未存在ID。

Scope／path／public contract變更、工具新增需保留leaf或重大錯誤回planning／獨立審查；無法解除的外部權限停報具體阻礙。這不是E007／renewal／45分鐘live gate，不要求他人實驗或真簽章先通過才交付本topic。
