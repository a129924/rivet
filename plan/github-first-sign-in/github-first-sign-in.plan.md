# 正式 OAuth 能力與獨立驗證 App：受限執行計畫

- Topic：`github-first-sign-in`；2026-10-20，Plan-Creator amendment，已獲獨立 Plan-Reviewer A02 approved（無required fix）。
- Branch：`feat/github-first-sign-in`；base／PR target：`dev`；基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22`。
- 沿用原 feature worktree／[Draft PR #61](https://github.com/a129924/rivet/pull/61)，不建新 worktree／PR、不在 dev 實作、不 merge。
- 配對：[requirements](../../analysis/github-first-sign-in/requirements.md)、[technical-spec](../../analysis/github-first-sign-in/technical-spec.md)、[step](github-first-sign-in.step.md)。

## 1. 現行 Goal 與九欄

交付為「正式 OAuth 實作能力＋獨立 GitHubSignInVerification App」。正式 Rivet 產品登入 UI 尚未交付。基線已完成 OAuth，本次只搬移並澄清驗證外殼，不重做正式能力。

每個 implementation slice 開始與完成交接均保留以下九欄，開始是 allowed paths，完成才記 actual paths／diff／結果，不能把允許清單抄成已完成。

| 欄位 | 本次受限內容 |
|---|---|
| In-Scope | A03a App/project/target/entry rename、app-local UI搬移；A03b 文件／圖修訂 |
| Out-Of-Scope | 正式產品登入或帳號管理、CurrentUserReader、新共用module/public API、其他topic/worktree、持久化及lifecycle重寫 |
| ReadOnly | 正式OAuth及既有credential/provider/scope/clients/refresh/rotation/single-flight/401、PR Inbox／Reader、frozen圖與歷史結果 |
| Written | 下列rename目的及新修訂圖／amendment evidence，逐slice展開精確paths |
| Deleted | 下列16個rename來源；除此無刪除授權 |
| Modify | 搬後host識別／存取範圍／引用、四planning、指定長期docs／工具證據 |
| Goal | 驗證App可build/test、明示驗證身份，正式OAuth與共用PR Inbox保持不變 |
| Non-Goal | 不把驗證UI說成產品交付；不宣稱新host真登入、反向PKCE或所有遠端refresh已驗證 |
| TestCase | TC01–TC09的適用regression／AT01–AT05搬移驗證；記實際命令、層級、pass/fail/pending與相對evidence |

## 2. 精確 manifest（本 amendment 的唯一寫入授權）

### Rename＝Deleted 來源＋Written 目的（A03a）

共16檔，apps/Rivet原13檔完整搬移，加上共用UI兩檔及其測試。每列均允許搬後必要內容修改，不代表行為重寫。

| Deleted：來源 | Written：目的 |
|---|---|
| `apps/Rivet/Rivet.xcodeproj/project.pbxproj` | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj` |
| `apps/Rivet/Rivet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` |
| `apps/Rivet/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme` | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme` |
| `apps/Rivet/Sources/RivetApp.swift` | `apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift` |
| `apps/Rivet/Sources/GitHubConnectionCoordinator.swift` | `apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift` |
| `apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift` | `apps/GitHubSignInVerification/Sources/GitHubLoopbackCallbackRelay.swift` |
| `apps/Rivet/Sources/GitHubAccountProbe.swift` | `apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift` |
| `apps/Rivet/Sources/InMemoryOAuthCredentialStore.swift` | `apps/GitHubSignInVerification/Sources/InMemoryOAuthCredentialStore.swift` |
| `apps/Rivet/Resources/Info.plist` | `apps/GitHubSignInVerification/Resources/Info.plist` |
| `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubConnectionCoordinatorTests.swift` |
| `apps/Rivet/Tests/GitHubLoopbackCallbackRelayTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` |
| `apps/Rivet/Tests/GitHubAccountProbeTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubAccountProbeTests.swift` |
| `apps/Rivet/Tests/InMemoryOAuthCredentialStoreTests.swift` | `apps/GitHubSignInVerification/Tests/InMemoryOAuthCredentialStoreTests.swift` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift` | `apps/GitHubSignInVerification/Sources/GitHubConnectionPresentation.swift` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift` | `apps/GitHubSignInVerification/Sources/GitHubConnectionView.swift` |
| `Tests/RivetPresentationTests/GitHubConnectionPresentationTests.swift` | `apps/GitHubSignInVerification/Tests/GitHubConnectionPresentationTests.swift` |

允許搬後修改：project/scheme/app entry/product/test target/module、bundle identifier、TEST_HOST／BUNDLE_LOADER、imports/path references；從App移除RivetPresentation dependency；UI及Presentation型別移除public，無新module；窗口／畫面明示驗證App及非正式產品登入UI；User-Agent、queue label與靜態callback頁字串明確驗證用途。test key改 `GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE`，entry早於live建立檢查，scheme一致；protocol、callback policy及lifecycle不變。Package.resolved內容原樣搬移，不更新dependencies。

### Modify（A01／A03b／對應角色記錄）

- `analysis/github-first-sign-in/requirements.md`
- `analysis/github-first-sign-in/technical-spec.md`
- `plan/github-first-sign-in/github-first-sign-in.plan.md`
- `plan/github-first-sign-in/github-first-sign-in.step.md`
- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/github-oauth-dual-client.md`
- `docs/architecture/github-first-sign-in.md`
- `docs/architecture/diagrams/github-first-sign-in/BUILD.md`
- `docs/architecture/diagrams/github-first-sign-in/visual-review.md`
- `docs/architecture/diagrams/github-first-sign-in/tool-evidence.md`
- `plan/github-first-sign-in/evidence/contracts.md`
- `plan/github-first-sign-in/evidence/compatibility.md`
- `plan/github-first-sign-in/evidence/product-e2e.md`
- `plan/github-first-sign-in/evidence/reviewer-verdict.md`

前五份長期docs改實際責任與新入口／命令／圖連結；不得再宣稱正式Rivet登入UI已交付。既有evidence只加基線來源／歷史限定聲明，不改舊測試或live結果，新結果放下列新證據。各角色只記自己事實與外部明示verdict。

### Written：新修訂圖與證據（A03b／A04／A05）

前綴 D=`docs/architecture/diagrams/github-first-sign-in`，每一項為精確檔案，不是整目錄授權：

- `D/scene-v2.js`
- `D/index-v2.html`
- `D/authorization-sequence-v3.json`
- `D/authorization-sequence-v3.html`
- `D/authorization-sequence-v3.delivery.json`
- `D/authorization-sequence-v3.visual-check.json`
- `D/authorization-sequence-v3.visual-check.html`
- `D/authorization-sequence-v3.visual-check.1440x900.light.png`
- `D/authorization-sequence-v3.visual-check.1440x900.dark.png`
- `D/authorization-sequence-v3.visual-check.2048x1320.light.png`
- `D/authorization-sequence-v3.visual-check.2048x1320.dark.png`
- `plan/github-first-sign-in/evidence/verification-host-amendment.md`

舊scene/index與已frozen的v1/v2 spec、HTML、receipts／screenshots原樣保留，不直接覆寫。新spec驗證後freeze；若工具另產生必要snapshot，先將精確名稱納amendment，再寫入，不借整目錄授權。Generated outputs只來自對應skill工具；衍生資料放ignored `.build/github-first-sign-in/VerificationHostDerivedData`；PR Lens用外部topic scratch，不入repo。

### ReadOnly

全部 `Sources/BoundedContexts/GitHubIntegration`（包括本topic正式OAuth五檔與原refresh/runtime）、GitHubIntegration tests／consumer source、通用HTTPClient、root `Package.swift`／`Package.resolved`、共用Presentation除上列搬移來源以外全部檔案、PR Inbox／Reader、experiments、其他topic/worktree、skills/runtime/AGENTS/hooks/config/.gitignore唯讀。必要新改檔未列manifest前不得寫入。Graphify／PR Lens策略沿用下文，不新增外部服務或repo工具設定。

## 3. Amendment 步驟

| Step | Owner role | 完成條件 |
|---|---|---|
| A01 | Plan-Creator | 四planning現行契約一致，先列rename/delete與Human Decision，保留歷史來源 |
| A02 | Plan-Reviewer | 獨立審manifest／責任／九欄／測試與locked decisions，明示verdict |
| A03a | Implementer | A02 approved後，bounded搬移App與UI、移除共用依賴，開始／完成均九欄 |
| A03b | Implementer | 文件與修訂圖反映正式能力／驗證host／未交付產品UI，工具驗證及限制分列 |
| A04 | Tester | 明示交接後獨立root／consumer／app／format／lint／隔離／diff／圖檢查 |
| A05 | Reviewer | 獨立code/scope/evidence review；required fixes回Implementer及Tester重驗，再複審 |
| A06 | Implementer | A05 approved後staged語意檢查→topic commit→push→更新原Draft PR61，真diff PR Lens |
| A07 | Human；Tester記錄 | 原Draft PR human review；新驗證App真登入及反向PKCE維持實際結果或pending |

使用者已授權同topic回修、commit／push／原Draft PR更新，不重問發布授權。不能merge；重大scope／contract問題才停止受影響工作交Human。舊S01–S08為歷史交付，不等於本amendment核准。

## 4. TestCase 與驗證命令

TC01–TC06：沿用基線callback/state/S256／交換完整bundle／取消settlement／store／provider-scope多次使用及lifecycle regression，搬移不改OAuth政策。TC07：新host fake-only tests及真實API probe判定；TC08：Human live與反向PKCE；TC09：docs／圖／受限工具及diff來源。不能把舊命令或舊host結果當成搬後重驗。

| ID | 本次新增驗證 |
|---|---|
| AT01 | 新project/scheme/app entry/target/product/module與bundle references一致；build/test成功；舊apps/Rivet來源不殘留 |
| AT02 | hosted scheme key與entry一致；fake-only零livecall；原coordinator/relay/probe/store測試搬後通過 |
| AT03 | UI／Presentation測試改App-local且public移除；共用RivetPresentation不含驗證UI；PRInbox與rootPackage原樣 |
| AT04 | OAuth source與原lifecycle相對基線無diff；root tests、consumer及適用format/lint通過 |
| AT05 | 新圖明示三者邊界並驗證；歷史evidence來源標版本，新host live與反向PKCE/canvas pending如實保留；PR Lens取原PR真base/head diff |

Tester命令（此plan不表示已執行）：

```sh
swift test
scripts/check-github-integration-consumer.sh
scripts/check-swift-format.sh
scripts/check-swiftlint.sh
xcodebuild -project apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj -scheme GitHubSignInVerification -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/VerificationHostDerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build test
swift format lint --strict --recursive apps/GitHubSignInVerification/Sources apps/GitHubSignInVerification/Tests
swiftlint lint --strict apps/GitHubSignInVerification/Sources apps/GitHubSignInVerification/Tests
```

依實際CLI接受語法執行適用app檢查；不掃寫其他檔。可唯讀source/diff確認newtestkey與public隔離，不需要為純rename新增鏡像tests。舊276 root／13consumer／8app與live結果明示屬基線；搬後實際數量由Tester記，不預填。新host真登入若需重做，由Human自行輸入機密；不讀取或重貼舊callback/code/state/secret。

## 5. 工具、證據與停止條件

### Graphify

Pin 0.9.73；每次 CLI 連 help/version 皆設 GRAPHIFY_NO_AUTO_REFRESH=1。本輪預期 graph 位置未找到可用圖，採 targeted rg/source。以後只有現存圖才核對 revision、用真 node labels 作 budget=1500 bounded query，重要關係 source-confirm。不存在、過期、不支援或失敗就 targeted search；不 extract／build／install／semantic／provider／watcher／server／hooks／config／version stamp。

### PR Lens

Pin 0.11.0、local-only；只在實際 bounded diff 後讀 diff 與必要 context，記真 base/head IDs，dirty patch 另記邊界／hash，不能捏造 head 或為工具自行 commit。外部 topic scratch 作 graph／validate／render，保留 unchanged direct neighbors、file refs 及非trivial map 的 walkthrough。讀實際 output manifest；現有 .github/pr-lens.yml 有才只讀套用，否則 no-config；不建立 repo .pr-lens、不 install／API／uploads／comments／servers。若 schema 無法忠實描述當下 dirty diff，記限制並用直接 diff review；不代替 Reviewer。

### Archify／architecture-canvas

A03 文件圖作者文字繁中；固定 UI／HTML lang English fallback。責任邊界依 architecture-canvas 讀 scene contract、author scene-v2.js、validate/build、實看；不得用 sequence 或 PR Lens 代替。授權流程採 Archify sequence：先 matching schema＋common＋matching example，下一個工具動作寫 candidate；不預先鑽 renderer。Showcase 九 checks、零 composition errors／warnings；validate 後 freeze、deliver 收據。visual-check 四 viewport 1440x900／1600x1000／1920x1080／2048x1320，實看最小／最大 lightdark screenshots。自動 visualReview=pending 不等於已實看；非零如實記；連續兩輪不改善即停報 diagnostics。不能發布 artifact.cafe／start preview server。

Graphify／PR Lens 是導覽／理解輔助，不是新增 OAuth 業務驗收或外部服務依賴；失敗記 concrete limitation，保留 source／diff fallback與既有 review gate。必要長期圖交付未完成則文件仍 pending，不冒稱完成。工具暫存、DerivedData、機密輸入皆不入版控；evidence 只放必要脫敏結果。

出現 scope／locked contract 衝突、越界刪改、無法符合既有 bundle、真實結果推翻契約、需新系統安全設定或外部 OAuth App 變更時，停止受影響動作並回 human-check／Scope Gap，繼續不受影響的已授權工作。個人 secret／live互動待 Human，不擅取 gh credential，不以未執行宣稱通過，不越過獨立 verdict。

## A07 真人驗證狀態（2026-10-21）

以上A03 Non-Goal與AT05的pending是搬移實作當時狀態，不預填遠端通過。現已由Human在來源 `e941d88` 獨立驗證App自行輸入配置並完成授權；agent觀察真實API成功與再次查詢通過，未重新授權。這是既有A07驗收事實，不變更範圍／manifest／contract。反向PKCE、canvas互動、完整遠端refresh/401與全部Human review仍未因此通過；最新來源與歸因見step及verification-host-amendment evidence。
