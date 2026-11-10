# 獨立 Tester：契約與實際交接

> 歷史來源：基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22` 的舊 host／當時 dirty source；以下原始結果保留。舊「正式 app」說法不代表產品 UI 已交付，不冒充搬後驗證 App 重驗；本次結果見 [verification-host-amendment.md](verification-host-amendment.md)。

2026-10-20，Tester；受審 source base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`，branch `feat/github-first-sign-in`。dirty source/project/tests 指紋 SHA-256：`6b5aba527e080c9d65ab7481abf9a17f3a98b8906d8da5e8b324cc249cceec13`。計算方式：所有本 topic changed/new 且位於 Sources、Tests、apps 的檔案，relative path 排序；依序串接 UTF-8 path、NUL、完整 bytes、NUL。這是 dirty 快照識別，不是假造 commit。tracked patch SHA 見 compatibility.md；文件證據後續更新不改此 source 指紋。

## 九欄

- In-Scope：S05 最終 source 的受控測試、consumer compatibility、root/app strict checks、正式 app 獨立 build/test 與證據分層。
- Out-Of-Scope：改產品 code、操作 dev/其他 worktree、commit/push/PR、讀取個人 secret、重跑 live OAuth 或反向 PKCE。
- ReadOnly：四 planning artifacts、相關授權與 app source/tests、既有 bundle/provider/scope/client、工具／圖證據。
- Written：本 Tester 新增 `plan/github-first-sign-in/evidence/contracts.md`、`plan/github-first-sign-in/evidence/compatibility.md`；ignored build outputs 不入 repo。全 topic 實際 new paths 見下列 inventory。
- Deleted：無；`git diff --diff-filter=D --name-only` 為空。
- Modify：本 Tester 僅更新 `plan/github-first-sign-in/github-first-sign-in.step.md` 的 S05 結果及主 agent 明示的現行事實；全 topic tracked modifications 見下列 inventory。
- Goal：把最終親跑結果、覆蓋與限制交獨立 Reviewer。
- Non-Goal：不把所有 TC、Human、圖視覺或遠端 lifecycle pending 改成 passed，不替 Reviewer 核准。
- TestCase：對照下表；親跑命令與結果見 compatibility.md。

## TC 對照與限制

| TC | 已有受控證據／範圍 | 限制 |
|---|---|---|
| TC01 | Session S256/query、offline_access、secret 不進 URL；relay 真 loopback | live browser open failure/ready ordering 未有獨立 deterministic 測試 |
| TC02 | 錯 state/重複 code/code+error、authority/path/userinfo/fragment、單次 claim 與重複 callback | 非每個 query 邊界皆有參數化測試，交 Reviewer 核對 |
| TC03 | session zero lifetime/deny/cancel、callback latch；coordinator authorize latch 阻止取消後重啟與遲到身分；R1 真 provider gated refresh 取消/settlement | live 五分鐘 timer 未注入 clock；未測完整 timeout-vs-exchange/coordinator race |
| TC04 | form/mapping、missing/mixed/error envelopes、非法值與日期/Bearer；HTTPClient 舊測試回歸 | production ephemeral/redirect/cookie/timeout 以 source 設定核對，非本次新增 transport 行為測試全部覆蓋 |
| TC05 | 六欄 store save/replace、跨 instance nil；configuration redaction | 未作程序記憶體安全清除承諾；重啟不恢復依 app source/static store，不冒充重啟 UI 操作 |
| TC06 | 原 provider identity prepare retry、同 scope 重複 probe；舊 lifecycle/REST/GraphQL 全套回歸 | R1 新增 cancelledRefreshSettlesBeforeNewAuthorizationAndProvider：過期 bundle 驅動真 provider/scope，gated refresh 時取消阻止第二 authorize；release 後真 store rotation save/publish snapshot，取消後不 probe/identity；settled 後新授權建立不同 provider。完整 app 8 tests passed；未另獨立阻塞 store.save 本身 |
| TC07 | app ad hoc build/8 hosted tests、API status/identity decode、Presentation busy；fake startup零authorize/prepare | UI 全失敗路徑未逐一真操作；無 hosted live OAuth |
| TC08 | 正常授權與再次/user 為主 agent/Human 明示觀察，見 product-e2e.md | 本 Tester 未重做 live；缺失/錯誤 verifier各新code反向測試仍 Human pending；不宣稱遠端refresh/401全路徑 |
| TC09 | 讀取工具與圖 receipt/實看紀錄；root static isolation 與 consumer通過 | Archify實看為Implementer紀錄；canvas因URL policy未能實看，Human pending；Graphify無圖fallback；PR Lens待真commitdiff |

這些 coverage limitations 必須由 Reviewer 判定是否 required fixes；S05 親跑 pass 不代表規劃中的每個情境都已有自動測試。

## 全 topic 實際 Written（git untracked，排除 ignored build outputs）

- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationError.swift`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationSession.swift`
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthCodeExchanger.swift`
- `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift`
- `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift`
- `Tests/GitHubIntegrationTests/GitHubOAuthAuthorizationSessionTests.swift`
- `Tests/GitHubIntegrationTests/GitHubOAuthCodeExchangerTests.swift`
- `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift`
- `Tests/RivetPresentationTests/GitHubConnectionPresentationTests.swift`
- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `apps/Rivet/Resources/Info.plist`
- `apps/Rivet/Rivet.xcodeproj/project.pbxproj`
- `apps/Rivet/Rivet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `apps/Rivet/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme`
- `apps/Rivet/Sources/GitHubAccountProbe.swift`
- `apps/Rivet/Sources/GitHubConnectionCoordinator.swift`
- `apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift`
- `apps/Rivet/Sources/InMemoryOAuthCredentialStore.swift`
- `apps/Rivet/Sources/RivetApp.swift`
- `apps/Rivet/Tests/GitHubAccountProbeTests.swift`
- `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift`
- `apps/Rivet/Tests/GitHubLoopbackCallbackRelayTests.swift`
- `apps/Rivet/Tests/InMemoryOAuthCredentialStoreTests.swift`
- `docs/architecture/diagrams/github-first-sign-in/BUILD.md`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v2.json`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.delivery.json`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.html`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.json`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.visual-check.1440x900.dark.png`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.visual-check.1440x900.light.png`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.visual-check.2048x1320.dark.png`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.visual-check.2048x1320.light.png`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.visual-check.html`
- `docs/architecture/diagrams/github-first-sign-in/authorization-sequence.visual-check.json`
- `docs/architecture/diagrams/github-first-sign-in/index.html`
- `docs/architecture/diagrams/github-first-sign-in/scene.js`
- `docs/architecture/diagrams/github-first-sign-in/tool-evidence.md`
- `docs/architecture/diagrams/github-first-sign-in/visual-review.md`
- `docs/architecture/github-first-sign-in.md`
- `plan/github-first-sign-in/evidence/compatibility.md`
- `plan/github-first-sign-in/evidence/contracts.md`
- `plan/github-first-sign-in/evidence/product-e2e.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`

## 全 topic 實際 Modify（git tracked diff）

- `README.md`
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`
- `docs/architecture/README.md`
- `docs/architecture/github-oauth-dual-client.md`
- `docs/design-principles.md`

本 inventory 為 S05 快照；後續 Reviewer evidence、commit/PR 或 PR Lens 外部輸出由各自 owner 補充，不預填尚未存在檔案。

## R1 required fix 獨立重驗

2026-10-20，依 Reviewer R1／Implementer 完成交接，只新增 app coordinator 測試，產品原始碼未變。Tester 重新執行完整 app build/test：8 tests、4 suites passed，exit0；app strict format及SwiftLint exit0、9files零違規。上述 TC06 refresh cancellation／settlement證據已補；其餘已披露限制不冒稱解除。Root276/consumer13結果沿用同一未變source，不額外重跑。修正是否充分由獨立Reviewer再判定。
