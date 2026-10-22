# 新驗證 host：自動契約證據

## R03 Implementer 自驗（2026-10-21）

這是 implementation 自驗，非獨立 approval、非真 GitHub／DPK／提示結果。所有 source／UI／adapters／coordinator／probe／clock／receipt／測試均 App-local；production public／internal visibility 保持 topic 前原契約。

| 命令（repository 相對） | 實際結果 | 界線 |
|---|---|---|
| `xcodebuild build -project apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj -scheme GitHubConnectionVerification -destination 'platform=macOS,arch=arm64' -derivedDataPath <private> CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=` | exit0／BUILD SUCCEEDED | unsigned，不驗證真簽章／DPK |
| 相同 project／scheme／destination／私有DerivedData及unsigned參數的 `xcodebuild test` | exit0；最終xcresult Passed、78total／78passed／0failed／0skipped；29 XCTest＋49 Swift Testing、參數另107 runs | fake-only，scheme testguard全livecounters0 |
| `swift test --filter 'GitHubIntegrationTests\|RivetPresentationTests' --skip KeychainTokenStoreTests` | exit0；202tests／22suites pass | 既有rootbaseline；跳過真legacyKeychain suite，不刪測試 |
| `swift test --package-path Tests/GitHubIntegrationConsumer --scratch-path <private>` | exit0；12tests／3suites pass | 既有publicconsumer、不加正式contract |
| `swift format lint --strict --recursive apps/GitHubConnectionVerification/Sources apps/GitHubConnectionVerification/Tests` | exit0 | 24Swift leaves |
| `swiftlint lint --strict --quiet apps/GitHubConnectionVerification` | exit0、0violations | 不改規則／不disable |
| `plutil -lint`：新 Info.plist／entitlements／project.pbxproj | exit0、各OK | scheme另以XML及host測試核對 |

TDD：先讓 tracker 僅回 notStopped，實際unsigned hosted build通過後，`VerificationLifecycleObservationTests` 真正紅燈：5tests／1suite、33issues，包含credentialRejected／rotationIndeterminate／afterRequestStarted與accepted-savefail；這不是最初missing import／Optional pattern／不可用internal snapshot建構等編譯修正。補 App-local Mutex tracker 後完整suite綠燈；最後命名及error型別匹配收斂後再跑最終78／0／0。未放寬productionvisibility以滿足測試。

tracker 只包實際 refresh／save，已測terminal分類及query不加load／fetch／save；beforeRequest／knownTechnical／configuration可重試；初次savefail不誤停；成功save清accepted標記，第二輪accepted-savefail仍停；provider原兩次已過期輪替limit維持非terminal。錯誤原樣傳遞。原coordinator latch tests在新module繼續驗settlement／admission／reauth退休／取消／grant或savefail不復活／temporary retry原provider；控制時鐘、receipt私有exclusive及secret negative cases亦通過。

App-local HTTP refresh 測試使用固定endpoint、escaped form／headers、30秒、取消階段、可信純error與混token／錯status／未知body、有限dates；既有provider公共行為回歸。三個舊root測試使用internal TokenSnapshot initializer的stale合成斷言未搬入新App，原production測試仍完整保留、已回歸，不新增testhook。

私人原生 logs／xcresults／hash handoff pointer 由 Dispatcher 讀取；不入版控raw device／Apple identity或本機絕對路徑。本輪沒有啟動真人App、真DPK、瀏覽器登入或Apple設定。

## R04 獨立 Tester（2026-10-21）

verdict=approved，requiredFixes=[]；適用 TC01–TC07，僅放行 R05 獨立 Reviewer，不代表真人或 topic 完成。Tester 未修改受審 source／tests／manifest，自有私有 snapshot 逐檔核對 App30檔及正式基線；43個交接SHA與61個immutableSHA皆相符。

| 獨立命令／scope | 實際結果 |
|---|---|
| 自有完整當前 source snapshot 的 `xcodebuild test`，沿上述project／scheme／destination／unsigned參數、自有DerivedData及xcresult | exit0；原生xcresult Passed，78total／78passed／0failed／0skipped；49 Swift Testing（8 suites）＋29 XCTest，19動態參數tests另107runs |
| 同私有source／DerivedData的 `xcodebuild build` | exit0，BUILD SUCCEEDED |
| `xcodebuild -showBuildSettings`＋scheme／plist／source核對 | 新product／module／bundle／testhost／testkey皆屬驗證App；Swift6、macOS15、ONLY_ACTIVE_ARCH=YES、ENABLE_DEBUG_DYLIB=NO、nonSandbox；repo不填私有簽章identity |
| 當前 source 排除整個 apps 的獨立snapshot，普通 `swift build --package-path <private-production-snapshot>` | exit0，Build complete；未補stub或改production檔 |
| 該snapshot的 `swift test --filter 'GitHubIntegrationTests\|RivetPresentationTests' --skip KeychainTokenStoreTests` | exit0；202tests／22suites pass |
| 該snapshot public consumer的 `swift test --package-path <private-production-snapshot>/Tests/GitHubIntegrationConsumer --scratch-path <private>` | exit0；12tests／3suites pass |
| 新App24Swift strict format／SwiftLint、三plistlint、schemeXML、pins／privacy、`git diff --check` | 全exit0；0violations；App pins與root逐項相同 |

完整fakehosted重跑涵蓋 PKCE／state／exactcallback／cancel／denied／exchange與strict sixfield、DPK fake兩item／partialsave／repair／redaction、relaybounds；localrefresh的純error／mixed／status／cancellation與finiteDate。Tracker同generation經實際fetch／save觀察，terminal／nonterminal分類、initialsave不誤停、accepted-savefail／第二輪失敗會停，查詢不增加load／fetch／save；不新增snapshot-demand觀察。Coordinators的latch tests通過實際settlement／admission／原provider重試／reauth退休／取消或grant/savefail不復活；earlytestguard liveconstruction／credential／network counters均0。受控clock單次trustedrestore、save後real、observe不force及privateexclusive receipt敏感negativecases通過。

最初受限sandbox無法寫既有Clang／SwiftPMcache，屬環境setup；循正式escalation重跑後build/tests通過，沒有改source／放寬檢查／裝依賴／跳hook。unsigned host在testguard下執行，未登入、未碰真DPK／Appleprofiles；KeychainTokenStoreTests是唯一明示跳過的真legacyKeychain suite。202／12為目前還原基線的實際結果，不套舊226／13。

私有完整收據SHA `6e4a6724f82e039a1f391579b066b024bf9d3b28b9e52e7ec0ce38701964a1b1`，由Dispatcher的私有handoff定位；無rawdevice／identity／path入版控。主要原生log SHA：

| Log | SHA-256 |
|---|---|
| hosted-allowed.log | `1010fa72b03a2464a3216cc3d4cf682b751e4409327b0071f850dabbb2341cd0` |
| xcresult-summary.log | `1784bf167ce57ab200c0f56c54898e146003407f75a4902e34e15f4d95496d50` |
| unsigned-build.log | `890c33020de832df1ff1b107267ca5ae1b525a0ebe9877799c13d688bf933446` |
| production-build.log | `9078f0387f84b9655f201e942776a03f93ed1ad1a56d047eabf492e067435b7b` |
| production-tests.log | `d5a724e31546629c1354225869ee162ceb0902d2694c10b650d2de51ab81eae7` |
| consumer-tests.log | `a04b3f32047c61ed1d99734e83ff493cc7c43149fa863ee87046196c2ea6c28b` |

真簽章／DPK／GitHub／完整退出／重建／受控真refresh及新host提示數仍全pending；profile更新讀回仍未驗證且Human已接受限制。R07文件與新版圖尚未完成，不拿舊正式產品宣稱當現行結論。

## R08 獨立 Tester：TC08／TC09 與來源回查（2026-10-21）

verdict=approved，requiredFixes=[]；本角色獨立於R07文件／圖作者，適用TC08／TC09及必要TC01來源核對，只交R09獨立Reviewer。未重跑已通過Swift／live，未改受審source／docs／圖；未操作App／DPK／Apple資產或Git。

- 106action路徑與實際status精確相同、87個R07handoff檔hash全符，v2恰32leaves。R07 manifest SHA `6a68de61f1ae7fb9943958bf5cf7a800d74f71278806c426004d36f3c35e6e92`作該階段快照，後續mutable角色收據hash另由handoff綁定，不反改作者manifest。
- 三張spec重新執行 `archify validate <sequence|lifecycle> <spec> --quality showcase --repo-root . --json`，各9checks／0errors／0warnings。native delivery的spec／HTML hash鏈、visual-check artifact hash、12PNG尺寸及native `visualReview: pending`核符。
- 對三份canonical HTML bytecopy，在全新owned scratch以pinnednative `visual-check --repo-root <private-root> --json`獨立重跑；四尺寸1440×900、1600×1000、1920×1080、2048×1320各containment／readability均pass。未覆寫canonical HTML／native收據／PNG。12張canonical最小／最大light／dark PNG已逐張view_image親看，labels／箭頭／legend／dock／cards可讀無裁切、最大縱向平衡。
- Canvas獨立validator 5bands／19boxes／17edges、0errors／0warnings；依BUILD相同nativebuild參數於scratch重建，HTML與canonical逐bytes相同。作者真capture hash核符後親看；另以全新privateChromeprofile、1440×1100、有界2000ms載入獨立rebuiltHTML擷取真PNG並親看。獨立截圖SHA `a2e9c00d7a12ac3af532ebe2da7dd5d6de8f4e0bf07ad236600d92f611784554`。
- 直接對照source：session交回bundle、Coordinator完整save後才newprovider；relay→session、publicport注入／runtime呼叫不等production反向import；tracker只包真refresh／save；settlement／samegenerationretry／退休不復活與clock回real一致。未把Canvas關係箭頭說成compile-time逆依賴。
- 四長期docs及App README定位驗證tool／有限可行性；受控expiry、首grant後digest未觀測／R06c首次讀初bundle、aggregatepairChanged、profile更新unknown／Human接受、原hostcommit前sourcehash歷史皆分清。R06live與11個有限來源收據hash保持，7項Human0與初／新六欄digest鏈符；非重跑真人或另行Human接受。
- 143個current相對links存在；8歷史檔只核新banner links並確認原全文suffix逐bytes同ca00bc0，不把舊source定位當current；privacy／本機path／rawsecret／whitespace掃描通過。三圖作者繁中／固定ViewerUI與HTMLlang Englishfallback，沒有手改nativepending或公開發布。
- 實際PR Lens版本0.11.0、Graphify0.9.73；本輪Graphify版本呼叫明確 `GRAPHIFY_NO_AUTO_REFRESH=1`。無usablegraph／repoPRLensconfig，targetedsourcefallback如實；本輪source尚無新commit，真rename-aware map／validate-render／coverage留R10，不冒稱已完成，不建graph／裝hook／改config或upload。

完整私有獨立收據SHA `13cd20f8af19d5fd342613af002d56656bfc10353bc883ce64426707a3e334b3`，綁87受審hash、獨立validate／visual-run、Canvas圖與限制，paths僅私有pointer。R09／R10／R11仍pending；自然到期、profile更新讀回／certificate rotation／分發未驗證，不是正式產品採用或全topic完成。
