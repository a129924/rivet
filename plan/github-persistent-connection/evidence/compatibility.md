# S06a：Public API 與相容性獨立驗證

- 日期：2026-10-20 UTC 07:47；角色：獨立 Tester。
- Verdict：`approved`；requiredFixes：`[]`；交 S06b Reviewer，非產品採用或成果審查批准。
- 環境：macOS 26.5.2（25F84）、arm64、Apple Swift 6.3.3、Xcode 26.6（17F113）；root package language mode 6、最低 macOS 15，Apollo exact 2.1.2。只記公開工具版本，不保存 Team／profile／certificate raw identifiers。

## 實際執行

| 檢查 | 結果 |
|---|---|
| `scripts/check-github-integration-consumer.sh` | 獨立執行 exit 0，13 tests／3 suites pass；fresh build 25.86 秒；script 自建臨時 scratch 並清除，fixture `.build` 保持不存在 |
| `swift test --filter GitHubIntegrationTests --skip KeychainTokenStoreTests` | 獨立執行 exit 0，211 tests／22 suites pass；incremental build 1.33 秒；含 StaticIsolation 與既有雙 client lifecycle regression |
| `swift format lint --strict <S05 精確 11 檔>` | exit 0，唯讀檢查，沒有 formatter 寫回 |
| `swiftlint lint --strict <同 11 檔>` | exit 0，0 violations／0 serious |
| `git diff --check` | exit 0；唯讀，未 stage／commit／push |

命令的 11 檔即 [contracts production hashes](contracts.md#受測-production-hashes) 的 5 檔與下列 6 個 tests；沒有掃寫其他路徑或修改工具設定。完整 logs 留 private scratch，本檔不保存原始 payload。

Consumer fresh build 有既有唯讀 dependency `packages/RivetHTTPClient/Sources/RivetHTTPClient/Response/JSONSemanticDecodingError.swift` 的 Sendable warning：`kind` 使用未 conform Sendable 的 nested `Kind`。本 slice 沒有修改該檔，build／tests 成功；不宣稱 compiler 零 warnings，也不在此越界回修 generic HTTP package。沒有其他測試環境 blocker。

## Source 與正常 import 核對

- Consumer 沒有 `@testable import`：公開 configuration、DPK pair／store existentials、初次 session、refresh fetcher、provider disposition 可建構並通過 Sendable generic assertion；session 只取消，不 exchange。legacy Keychain consumer 只建構，不 load／save／delete。
- Provider 的 baseline diff 僅新增三個 disposition 值與從既有 unavailableError 直接推導的唯讀方法；snapshot／shared task／refresh policy 未改。既有 provider 測試只 additive 加一個 observation test，沒有改舊期望。
- StaticIsolation diff 僅四個已核准 source paths、factory／session 的 HTTPClient imports、factory／store 的 Security 例外。legacy store 的 Foundation／Security 精確集合仍維持，session 沒有 Security 例外；其餘 parser、相等集合斷言與禁用模組規則不變。
- Ports／bundle／scope／REST／GraphQL／Package.swift／generic HTTP auth 無本 slice 修改；source compatibility 測試保留既有正常 import、typed refresh、REST builders、GraphQL contracts。

## 受測 tests hashes

| Repository-relative path | SHA-256 |
|---|---|
| `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift` | `feebd60bcc39db020eb156b5404623746f42afc24511960d98b9035c8359619b` |
| `Tests/GitHubIntegrationTests/GitHubOAuthAuthorizationSessionTests.swift` | `ca3691a24323cfcc437d50031f554e66de71e81266add48feaea5cce5ddb5fac` |
| `Tests/GitHubIntegrationTests/GitHubOAuthDataProtectionStoresTests.swift` | `4a93082f908c40f167bdf4bdc4079ced9cd050ba95b9a6f201d9011907d150bf` |
| `Tests/GitHubIntegrationTests/OAuthTokenProviderTests.swift` | `a64baa8bdc555f0999266acec5aa95c882ee610e75a2f1dfa157b641897b42e9` |
| `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | `36a8343e9e5b987b8366c9448b5f3945ff973db99fb9f6890cc8a496de57f90a` |
| `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` | `055501906bac6dccdf0f801617631284869ec451c0e87a964e9a41630ca155f0` |

## 限制

這是 fake-only 契約與 source compatibility 驗證。沒有實際 signed Rivet host／unit-test-mode entry／簽章 profile／Keychain 提示／GitHub permission 或真 API 的證據；不將 compile／construction 稱作連線可用。S07／S08 與 V06–V09 未完成。Human 僅解除 renewal 預驗前置，其他 gate 不變。


# S08a：產品 host 獨立建置／相容性（2026-10-20 UTC 08:11）

- 環境同 S06a：Apple Silicon arm64、macOS 26.5.2、Xcode 26.6／Apple Swift 6.3.3。
- 獨立 hosted xcresult 為 23 passed／0 failed／0 skipped；正式 unsigned build exit 0；root integration＋Presentation 226 tests／25 suites pass。精確八個 changed Swift 檔 strict format／SwiftLint 0 violations，project／Info／entitlements plist lint 與 diff check exit 0。命令及十二個 source/resource/test hashes 詳見 contracts.md 的 S08a 區段。
- 第一個未限 arch 的 hosted build 發生 x86_64／arm64 module mismatch，沒有測試結果；改用實際 arm64 destination／ONLY_ACTIVE_ARCH=YES 後成功。未驗證 Intel host，不因此改 package／source。unsigned test build 的 Apple XCTest support「signed binary 不 strip」warnings 不代表產品已簽章；沒有宣稱 compiler 全程零 warnings。
- 本角色新生成的 project workspace Package.resolved，經 baseline 未追蹤、mtime 在本 Tester scratch 開始後與 hosted build 期間內核對，已精確移除；root Package.resolved 未改，沒有 stage 或 Git mutation。自身 logs／DerivedData／xcresult 僅留 private scratch，不入 repository。
- 正式配置 source 核對：macOS deployment 15、Swift 6／complete concurrency、Apple Development 自動簽章、ENABLE_DEBUG_DYLIB=NO、non-Sandbox；private Team 未填、RIVET_BUNDLE_IDENTIFIER 可由私有 build settings 注入，Info 與 entitlements 同用 AppIdentifierPrefix＋bundle ID 作 private group，service 固定 local.rivet.github.oauth.v1。有效 embedded profile／原 certificate／group 實際授權尚未核對，不能以設定字串代替真資產。
- 整體 S08a needs-rework（RF-P01 受控 expiry／有限驗收途徑缺口）；已跑 fake 部分 approved。未越過 S08b／V06／V07／Human gate，未修改任何 production／tests／Apple assets。


# S08a RF-P01 bounded 重驗補記

獨立 hosted 29 passed／0 failed／0 skipped，unsigned build與精確三Swift strictformat／SwiftLint／diffcheck均exit0；三檔hash見contracts.md。未變root226回歸不重跑，原結果保留。Xcode本輪新生project lock在確認前不存在、非symlink、未追蹤且mtime在本輪後，已精確移除；rootlock不動。沒有改source／tests／Appleassets或執行livecredential／GitHub。RF-P01解除，整步human-check而非全產品approved。


正式GUI無override的首Build實際出現architecture/module mismatch（App x86_64、localpackages arm64），與先前只platform=macOS命令失敗同因。這將原「命令條件」限制具體提升為產品預設GUI build缺口RF-P02，不能宣稱正常XcodeBuild已通過。由原Implementer在同project既有Debug設定回修，未私改架構／簽章或重跑。


RF-P02經正常GUI⌘B獨立解除，不靠命令override；actual signed App arm64、Swift6／macOS15／nonSandbox／debugdylib關。原certificateSHA256=`5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440`；profileSHA256=`f8bc28109f7df3933ec3f20772d7d7afe73e7a155d6519e80c6d4b53c57d8802`；binarySHA256=`aadf4f3a95a8c82056615e2b76df9ea04a0860b6b302c0a3a8c246e613308268`；actualGUIactivitylogSHA256=`cdeff9d83906ec710e5c7ef1ab736d30f45f3aac3df9bf1aa74c20f2f56f710f`。原failedBuild記錄不改；不外推Intel通過。


S08a最終approved／requiredFixes=[]：formalproject的Debug單欄修正已以真正常GUI／cleanrebuild獨立核實；final signed binarySHA256=`8693fbc21152cb7413cd4529934370beb3b9631b0f95ce5102bd4af5f61c14bf`、同原cert／group／產品ID／有效profile、actualarm64Swift6/macOS15/nonSandbox/debugdylib關。真儲存／重啟／rebuild／受控觸發真refresh／輪替後新程序均完成且逐段Human0。此不外推Intel／公開發行／profile更新；不新增無關測試。


# S10a 文件／工具獨立核對（第一輪）

- S09沒有Swift變更；69個S08已鎖source/packagehash仍符，沿用已獨立執行的hosted29／root226／consumer13證據，不無故重跑或把新版29與早期23相加。
- 七份M03／W07Markdown共79個local links存在，無trailingwhitespace／使用者絕對路徑／private-keypattern；32個W07圖leaves精確符合核准manifest，無額外snapshot輸出。此native runtime未保留永久frozenleaf，delivery對canonicalJSON與HTML的bytes/SHA綁定已核，未捏造缺失快照。
- 三Archifyshowcase及scratch獨立四尺寸visualchecks全pass，Canvasscene→HTML重建byteidentity與幾何validatorpass；12原截圖和實際Canvas獨立親看。完整技術檢查不取代RF-D01圖責任語意回修。原作者visual-review.md與canonicalreceipts完全未改。
- Tester shell PATH找不到pr-lens，依既有技能指定pinnedruntime實際核version0.11.0成功；Graphify每次CLI均GRAPHIFY_NO_AUTO_REFRESH=1，version0.9.73成功。無repoPRLensconfig／Graphifygraph，既定targetedsourcefallback符合事實；沒有install／config／graphbuild／發布。S12真codecommit後PRLens真base/headmap仍待既定授權步驟，不現在造假provenance。
- 本輪needs-rework／requiredFixes=[RF-D01]只指scene的session→stores錯誤直接關係；S11Human圖表／最終接受仍pending，S10b亦未批准。


# S10a RF-D01 最終補記

獨立sourceownership／單邊data及真endpointgeometry／Canvasvalidator0/0／scratch重buildbyteidentity／新實際截圖親看／metadatahash-link-privacy-whitespace核對全部通過。RF-D01已解除，S10a最終approved、requiredFixes=[]；詳contracts.md最終段。三Archify及所有Swift/live證據未變，不重跑已pass項。

技術交付可交S10bReviewer，不代S11Human視覺／整體接受。先前knownlimits保持：renewalunknown／Human唯一例外、正常初digest未測、aggregatepairchange不代表個別tokenhash、expiry受控非自然8h、有效免費profile7日／certrotation與公開發行不外推。PRLens真map仍依approvedS12在真codecommit後做，Graphify既有圖不存在維持sourcefallback，沒有新config／install／發布。
