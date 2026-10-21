# 驗證 host 歸屬回修清單（R03）

此清單只記 Implementer 自驗；獨立 Tester／Reviewer 與新 host 真人結果仍待後續。基準 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`，回修起點 `ca00bc074f77fa21a7fac1aaae07dc1059de5b01`；未碰 dev 或 PR #61。

## 搬移並刪除舊 production 路徑（19）

舊 SHA 是原版本 bytes；新 SHA 是本次 App-local bytes。不是原樣 rename：module／visibility／identity／依賴已收斂。

| Deleted（舊） | Written（新） | 原 SHA-256 | 新 SHA-256 |
|---|---|---|---|
| `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift` | `apps/GitHubConnectionVerification/Sources/GitHubOAuthAppConfiguration.swift` | `b38dc9bee34b1e840cecee7774266a2446e8fab4d95ce5477f2c6f02870dfb3f` | `474f1568b95f9925de8664df6d62906f736962a98fca44c9ff6993fe9d9dcca7` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift` | `apps/GitHubConnectionVerification/Sources/GitHubOAuth.swift` | `8eda511d00b89096f5eb604b8cc63e428df849af3bebbf02962f9c69754a3ecc` | `cc237ef8da173d83694b762a89a64c69781a9650199cdb51cb2c64d1f4114e10` |
| `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationSession.swift` | `apps/GitHubConnectionVerification/Sources/GitHubOAuthAuthorizationSession.swift` | `604d50fcd15f314a489351aee749c5dc4f9b81565cdc4a28a1cb2432eb8c4fb8` | `2908a2833cf05d176d160552e7b9a8e73b6fdd8bf07309977c9848bacb950733` |
| `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift` | `apps/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift` | `1b16ec8b8a12b09f3a5e3694be1077b00b52bb62d394bb356c490fbf23e5c2e5` | `b2e55652df45e573c138a6acdf5495586dbec03268fbd4aad08a1558a565a282` |
| `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift` | `apps/GitHubConnectionVerification/Tests/GitHubOAuthFactoryTests.swift` | `feebd60bcc39db020eb156b5404623746f42afc24511960d98b9035c8359619b` | `b2546c157961b3c2b0eef9f4a2e72f8573c13d13f6aad851d2436b7bf9cf7732` |
| `Tests/GitHubIntegrationTests/GitHubOAuthAuthorizationSessionTests.swift` | `apps/GitHubConnectionVerification/Tests/GitHubOAuthAuthorizationSessionTests.swift` | `ca3691a24323cfcc437d50031f554e66de71e81266add48feaea5cce5ddb5fac` | `edf6c72d36da48d337727f30d4f53606d903f361af332d8e2dc10bde86232680` |
| `Tests/GitHubIntegrationTests/GitHubOAuthDataProtectionStoresTests.swift` | `apps/GitHubConnectionVerification/Tests/GitHubOAuthDataProtectionStoresTests.swift` | `4a93082f908c40f167bdf4bdc4079ced9cd050ba95b9a6f201d9011907d150bf` | `d5fbf39e8f17a1ab90a60ca0e0d922d7ed8eef8621a56c7b63ba38b8e88c19da` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift` | `apps/GitHubConnectionVerification/Sources/GitHubConnectionPresentation.swift` | `b7fb55bb837a1a6577d3041a4b13c3431636e90db4dfaee860a9def803c0bf10` | `bd59393f946a904a4653e493ffe9f1b1b9f5acd64a8b6129ab9dd1d73eec8320` |
| `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift` | `apps/GitHubConnectionVerification/Sources/GitHubConnectionView.swift` | `681c086fa72914fed0557338be833d43c98fd38b9eb61d394b8fa65bf4732b72` | `58e844f31353e6865bebfc152a961f02fce03f04899138c4c40959c5d3125274` |
| `apps/Rivet/Sources/RivetApp.swift` | `apps/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` | `dbde174c7115de5fb096d09c19a71b6b933448e8160bdf9e39c43abca303b742` | `12797a0bc7bbf9b5f03d0724937277b64dceeeb9444da97d5faec9b12d477d86` |
| `apps/Rivet/Sources/GitHubConnectionCoordinator.swift` | `apps/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift` | `3e485cb590a7c0fdbabdf6d39dde8860a604266d70c1fa496570578fa6fb6837` | `3ab95f7484101a4c2c85654ec8b576453bdcfeee0f30609b37f330fa9b39653d` |
| `apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift` | `apps/GitHubConnectionVerification/Sources/GitHubLoopbackCallbackRelay.swift` | `b8fa70f0eb357316d69d7e1a6e964508355708793053018afd738c3f3dee3ed4` | `88df3fa9cd08945f36b49e224bf2a18d6d29a082650d3b1840d32eba76b6f929` |
| `apps/Rivet/Sources/GitHubAccountProbe.swift` | `apps/GitHubConnectionVerification/Sources/GitHubAccountProbe.swift` | `7db900775746a49583344600a79509c6f75a14352483b4ef78abed350e556eaf` | `f8d5d398c90f6f57cd295b770d172825ae0ef22d86e171a71540d7066fe693c8` |
| `apps/Rivet/Resources/Info.plist` | `apps/GitHubConnectionVerification/Resources/Info.plist` | `733e24e4a9848b28d9fae0eda9ac0b322af568881dcb46244625acfaf1782fd7` | `e2ed6f2d2d4c13585030e105a6dd691b80b2348971e94b4ffb907c576835156a` |
| `apps/Rivet/Resources/Rivet.entitlements` | `apps/GitHubConnectionVerification/Resources/GitHubConnectionVerification.entitlements` | `526bac7f8ee939569becdf3d59ab86e83bf68c0bafda5ff3d660c5683dab6dc8` | `526bac7f8ee939569becdf3d59ab86e83bf68c0bafda5ff3d660c5683dab6dc8` |
| `apps/Rivet/Rivet.xcodeproj/project.pbxproj` | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.pbxproj` | `ddf42ca3511f297456cb82c30b8c1a74413da785c103a4409ebc6fff058df62f` | `3b2760a3926d367f56442fc874424f8b0ec477d9c6de5849b8c08928d0846f42` |
| `apps/Rivet/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme` | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/xcshareddata/xcschemes/GitHubConnectionVerification.xcscheme` | `3832ea8a70762b06eb77421a7f18abbab1ca62ba7749276fd7ed164e0638c4a6` | `56460cebf87cbd370aee73397efc8234ea933a22a98599592d107a01be5f8334` |
| `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift` | `apps/GitHubConnectionVerification/Tests/GitHubConnectionCoordinatorTests.swift` | `73fab0479c8e5a5ad84b2947e9ad5af6d86233bfd11722389f9e927bfc5f3fe9` | `b761d9bb9507f38ad7b76fc6e0963d46173d3926e7b018394ca57b55404c6b99` |
| `apps/Rivet/Tests/GitHubLoopbackCallbackRelayTests.swift` | `apps/GitHubConnectionVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` | `d8afc7a0e854d91fd52584be7f8e9a622959e5bf94987134e972908897595b1e` | `90f18b4e2750a03a85168eef4f031c6996263f1ee19c14a9e6fb1c2a38f93eb2` |

## 既有正式檔精確還原（4）

| Modify | 修後 SHA-256（與16606b89相同） |
|---|---|
| `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift` | `d1844a3052fdc0b3ddc02a61d92e2ecdfe08db957f6bd232b8babbf0a6ec5765` |
| `Tests/GitHubIntegrationTests/OAuthTokenProviderTests.swift` | `980d93ab790a7de230a218909afcce9504fb1d50a375afa7bc2b80f6fe46348a` |
| `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | `b251828338b90861eb03f8c63b358d138b2b2315f6960a879403474508613c7f` |
| `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` | `c53914f4ab8b2a91f69790dd0c38f9611eca842fff3c5a4d88806faf3924be34` |

## 其餘新 App leaves

| Written | 用途 | SHA-256 |
|---|---|---|
| `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | Xcode生成、一致既有pins | `4e66093bdf1d34c83ead4e62c2d021dedd2bb97eeb1761875ec60492d18ebbad` |
| `apps/GitHubConnectionVerification/README.md` | 工具操作及限制 | `b85cc76d8c88b182e669e9ec92b23ee98fbf3c203ec4d66c88f00cc431f82d0b` |
| `apps/GitHubConnectionVerification/Sources/GitHubExpiryValidation.swift` | App-local完整實作／fake-only測試 | `f9e3e13295d64c10a866863c8b6053f59b25ee726cb4ef82230bb65de5db5f2e` |
| `apps/GitHubConnectionVerification/Sources/VerificationLifecycleObservation.swift` | App-local完整實作／fake-only測試 | `4fe4a6c7366bacfe3e18f5e0d28777851c454360441d8217a0938e43781aeb38` |
| `apps/GitHubConnectionVerification/Sources/VerificationOAuthEndpoints.swift` | App-local完整實作／fake-only測試 | `501e31c49ff643ccd03f1c141f2c7e5bdbb8f3e23baccdbad0302f45a20ca560` |
| `apps/GitHubConnectionVerification/Sources/VerificationOAuthHTTPTokenFetcher.swift` | App-local完整實作／fake-only測試 | `d84aa4ac00eaf5bb664854b883e5c1c7a1975e451ed426d182bd541434a68dae` |
| `apps/GitHubConnectionVerification/Sources/VerificationOAuthTokenResponse.swift` | App-local完整實作／fake-only測試 | `503850bae2215567f04d9a537190b471f3b67a5a6b85efc550eb36693385ba40` |
| `apps/GitHubConnectionVerification/Tests/GitHubConnectionVerificationIsolationTests.swift` | App-local完整實作／fake-only測試 | `7594a2e625c60a06c7ab0c73451d1f480644f617e02a324222bfa390af6d510c` |
| `apps/GitHubConnectionVerification/Tests/GitHubExpiryValidationTests.swift` | App-local完整實作／fake-only測試 | `1778698b127f27606e418cad21396f6f7e28759c165c19784cf642e7d90de624` |
| `apps/GitHubConnectionVerification/Tests/VerificationLifecycleObservationTests.swift` | App-local完整實作／fake-only測試 | `67552f47ddcace141ad37cbdbd23fe44f6711f2bf09bba197da61350917620bb` |
| `apps/GitHubConnectionVerification/Tests/VerificationOAuthHTTPTokenFetcherTests.swift` | App-local完整實作／fake-only測試 | `8aad87dcfefc95472da444775661fd9e620158fa03652c05aca0c0b94324fbcd` |

## Immutable 保留清單

E00732檔及舊版 native 圖29檔逐 bytes 與 ca00bc0 相同；保留原未判定結論／收據／圖，不能當新版 source 或驗收。

| ReadOnly | SHA-256 |
|---|---|
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.delivery.json` | `e51d01dbb5f0ae4907c329e9751a743a2efb5dfa04df254024c7b64c0d6f6068` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.html` | `4b091d99201520e4da7e66a96edaea50f4e3337d53cfa082ff026cc6180c1b9b` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.json` | `3992e84bf63911be420a93558157b9611f5826b83bd232552a8034f7440b553c` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.visual-check.1440x900.dark.png` | `694179bd1958f04ad5864adb112e89a984b436c2c4c20e50e53280969ef341c0` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.visual-check.1440x900.light.png` | `c1dd1b4769668f4a183540a0ced1deb84ad1997e3c06a938326efb04c5d4dea0` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.visual-check.2048x1320.dark.png` | `6f91c78750a4bd95f1e2754947556fa26c30290a823f49b62d13e00f52d91c0a` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.visual-check.2048x1320.light.png` | `dfdfd5da4b200e03cf709508b9d610e513e5c7527a837ece4fac22ade2679abc` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.visual-check.html` | `a05d3c9a39611f0948222080b4a31cfbd8584db16adaf9f9ecca9b8ad718429e` |
| `docs/architecture/diagrams/github-persistent-connection/authorization-sequence.visual-check.json` | `2c872315aed58b46e91471a78ad833328794c83af83112b83ad4f11ca9280cf7` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.delivery.json` | `d7ae732009feb777c15195b1e25983d341a7abd1cd2b53f3d42b431a96944c76` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.html` | `b6d98dab3380ae10c40685045d5b926f035a88c90fbbe66044fc84e1832172ca` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.json` | `730a7d58eb2ee283a2da01560049e2478a6986128e54f80f76c49dd611ecd66e` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.visual-check.1440x900.dark.png` | `ca9da5291f0dd8b10272ba191729744a73ab98825ad1e4acac5f42e02697c008` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.visual-check.1440x900.light.png` | `15a90c6b2ba95c0943da8c10f9775ee4911947c181a6730812ccd416c03ce3dc` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.visual-check.2048x1320.dark.png` | `24395095187c12454f63de155d66bf12458813228af04b08c45ca0f7e80ae206` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.visual-check.2048x1320.light.png` | `ccb5e246bb3e91714e3a1f57285fa8d1c63d9f1302f0022f836d516daafc74a6` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.visual-check.html` | `267409a77608860c67a0226ecdb52f09d7bce0e31ac8e73abc79e5f3628a025d` |
| `docs/architecture/diagrams/github-persistent-connection/connection-lifecycle.visual-check.json` | `f3dd23257dec54fb5896de1136486b99d7faf8617e4ab04afb7fe57e34a6e600` |
| `docs/architecture/diagrams/github-persistent-connection/responsibility-canvas.html` | `61a8f9b558407ae9d1d04c63b56221325d2d666cd660fa110ef80cd4763e69ae` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.delivery.json` | `6150007cd2d91031767babcfb22afc9351ddfbc43788a143839bd54b5854ec72` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.html` | `6e4824e66f0b68ecedfec14e39a60da625a75a51eb60cab57c80d5ccbf341c8a` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.json` | `9c65826b91c5d0204422f73770135646f107ba9b7018ca2e0c5dec18a979c542` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.visual-check.1440x900.dark.png` | `e0656c6352eec9109c191af035ccf7215295e8fff848deca574afa6ba6cd20ac` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.visual-check.1440x900.light.png` | `313b7749ace69ba1067d40f49ee833617ad264c6cb40fc8e54555687c6a469d5` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.visual-check.2048x1320.dark.png` | `b4fa9f34230f2f4f2dde868fcffde5f4455f23ec12cecdc0374b5ddbe162f455` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.visual-check.2048x1320.light.png` | `da525eea86d8ed55a89f2bb0fbc5b2645186c33cc50e4274a77005f9e6b58ad1` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.visual-check.html` | `12d451b73396e40051ec81b593fd1b1579a593f7b7f7e604de855554285e40f7` |
| `docs/architecture/diagrams/github-persistent-connection/restore-refresh-reauth-sequence.visual-check.json` | `d76220d5c4a563cdbd3fcf78dc1f4a93124b75da7e917f5876760bca2b9d3595` |
| `docs/architecture/diagrams/github-persistent-connection/scene.js` | `187bba542b1e1f2b17e960a74863b39b5e0a2633d4655bfb2d638f27ceff95d3` |
| `experiments/E007/ProfileRenewalProbe.xcodeproj/project.pbxproj` | `8cb08f416dc753c49b9bc3ea447ce5c75fa3ffb97388d198895b7a50ad0e6b7b` |
| `experiments/E007/ProfileRenewalProbe.xcodeproj/xcshareddata/xcschemes/ProfileRenewalProbe.xcscheme` | `93b4e8876aafc7dfdeb35e24c837cb5ab6266dc3133c34f08fab8e610c97b3d5` |
| `experiments/E007/README.md` | `01d0969f2b65568c7aa6ea706e4fe652bb665a4e5e06913294b819eb57ecd7f4` |
| `experiments/E007/Resources/Info.plist` | `9d7ad64ccf83deee5e1b6a09802362214640b19e6f1ba25313aa02a14b33f8c4` |
| `experiments/E007/Resources/ProfileRenewalProbe.entitlements` | `0ca405fd010ca452795f066ee4271c29b33785f65df8747a5b6e0a1909b936df` |
| `experiments/E007/Sources/ProfileRenewalProbe.swift` | `1c55ea950ddd9841cf1ba372ef7da190e6bb86127f798dfd8983d71edfe73958` |
| `experiments/E007/Tests/test_protocol.py` | `7798a5c8463ebec7e0b8574247f81679cab07e56b52e4a311cc8bf985036e65f` |
| `experiments/E007/evidence/preparation-review-r1.json` | `f9bae387090bb05323c0c5abbecd5c021219ec84ebd23ed6f087562028dba4ae` |
| `experiments/E007/evidence/preparation-review.json` | `04a53e1c0310ef5e3b9d1a7c46571de117e048e8b5c913aa02bb32c5852991eb` |
| `experiments/E007/evidence/preparation-tests-r1.json` | `74e49d9b193e5e4369cb01c494f415b61b261b14ae01a7516e515c0a95e2d9c6` |
| `experiments/E007/evidence/preparation-tests.json` | `14a228214834db283aec28b5d8a3e7ceba094cc3e07a07e5325acafa115fc2a5` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/cleanup.human.json` | `09b767236ea09242cdb0ec87fde4a9f7690035a5c70e7b01493ffec9ee9de8e7` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/cleanup.machine.json` | `25b179ce18daedcb70f5325ab23ebaba492d8a0d4df9e9e9d2dc8d1f9216c9cd` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/final.index.json` | `7e93e99c0035e5417aff7051689b2fc4973a60614532225ceb5bad03b3956b76` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/phase-1.human.json` | `7f22395ecfcc37113e265c371b73def4e176db4c977c8dd46ef566744f45f6f2` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/phase-1.machine.json` | `02ec2588d7673bfb2656759945978980c5ddacd731e184b1c5b28c1068a3fe0d` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/preflight.machine.json` | `4eb17a3bdce8bc974067379bc7ab21eb9301c941aaeb0d0de3ba85271f834c51` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/reviewer-verdict.json` | `b4457017a0509a897094220240b3d268c7e6b258d9530e1933c99aef8b7973e7` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/tester-validation.json` | `224614d9ddc0d0eaccdd27a844d04e3189bdc83dcafbf788a32067cb85e89455` |
| `experiments/E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/window.json` | `53539a9422d03a84eebb7c6ad55ef2845993b2e9b89490bbb9aac4f01503c54f` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/cache-recovery.machine.json` | `b817492a883c4d32b4cdd9c5106695b80777575accbbb49986a41b6be8cbc6b6` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/cache-transition.machine.json` | `32a8fc78a9a645bb1fcf828820bccfffc59847e64b2f5fb46115dc0eb77b9c75` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/cleanup.human.json` | `aa8942c0da28cff0e149d007041219ee644ba44d4ed2e8d0c7070d299127eeea` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/cleanup.machine.json` | `26125b6a8f902420f9aa49497559226f32139bc3eb8c5c7fb10c169b4122afef` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/final.index.json` | `874b50d21938d94606bd386edafe4c93cddbc3472af852598c4fad5af6f85548` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/phase-1.human.json` | `55164b78e9a0df1c0d62b47940fc807b3e2ac2ccc89b7658f45c2f0b312ae464` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/phase-1.machine.json` | `af8830c32241409bf9a125f02be1de8fccc764598bfca789eac182b603db826c` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/preflight.machine.json` | `a65c857e564678ac9a8a7a98227aab4e61a8e6fbe9a336ed14a67f2fa4489096` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/reviewer-verdict.json` | `9cd28d7bb548849e310005c72d1811ccde889033bf41fff0f735532cd5d2457b` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/tester-validation.json` | `fcd273cd697a34f21d02536452805fcc588e24bad7dc143b5a6118d646a5b133` |
| `experiments/E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/window.json` | `c6bd6786abce95affb4105ec983bc6154e507016913e24937d39d29f6de829d1` |
| `experiments/E007/scripts/run_profile_renewal.py` | `62ca01370b78578db5ac3e45836b747765d7b201dbbf77438458a6003b90c484` |

## 其他 actions 與分段歸屬

- 本輪四 planning artifacts 由 R01／R02 更新；本 R03 僅追加自身 step。四長期 docs、舊 evidence5／舊圖導覽3 的 banner 及新圖屬 R07，尚未修改，不以本輪 App 搬移冒稱完成。
- 本目錄五個 `verification-host-*` evidence 為 W05 新增；contracts／isolation 記本次實證，live／review 僅建立 pending 框架，後續獨立角色追加。mutable step／evidence 的最終 hashes 由 handoff／獨立核對提供，避免自指。
- 所有其他 production Sources／Tests、Package.swift／Package.resolved、packages、BC／既有PR UI、工具與hooks、其他topic及PR #61保留；對base之root Sources／Tests／Package整體diff為空，不留額外productionAPI／UI／validationkeys。
- 原安裝 Rivet.app、其真 DPK、Apple profiles／certificate 一律未操作；新App真人全部pending。沒有移除安裝資料、原生receipt、或他人變更。
- 本輪未刪repo外資產；private DerivedData／production snapshot／logs為本角色新建，未移用dev deps或改工具設定。

## R07 全本輪交付快照與 actions（現行）

本節是R07handoff快照，前面R03表保持當時來源。原R06引用manifest SHA `fc13ed33cf9ee480f500348e18f1d304fd03325ee3920658e7482d04f528baa0` 的完整原檔另保留於本輪私有handoff，不反改R06。後續角色可追加mutable帳本／evidence，其hash屬後續版本；source／native圖如改需另記變更。

W01 AppREADME於R07只doc-only更新新host現況，原hash `b85cc76d8c88b182e669e9ec92b23ee98fbf3c203ec4d66c88f00cc431f82d0b`，新hash `1032b7c6b755c39bccdb8cebc65b3258868f7a9f730520286da865d171a48659`。其他29App檔與R06相同，所有原R03／R05／R06三十檔收據保持原值，不宣稱current30全一致。

| action | 路徑 | R07 snapshot SHA-256／刪除來源 |
|---|---|---|
| Modify | `README.md` | `2df98a1e6108a68ab375f5a0bbe5d9188dce2482dcf995edfe9d205ea1229bd2` |
| Deleted | `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift` | `ca00bc0：b38dc9bee34b1e840cecee7774266a2446e8fab4d95ce5477f2c6f02870dfb3f` |
| Deleted | `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift` | `ca00bc0：8eda511d00b89096f5eb604b8cc63e428df849af3bebbf02962f9c69754a3ecc` |
| Deleted | `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationSession.swift` | `ca00bc0：604d50fcd15f314a489351aee749c5dc4f9b81565cdc4a28a1cb2432eb8c4fb8` |
| Modify | `Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift` | `d1844a3052fdc0b3ddc02a61d92e2ecdfe08db957f6bd232b8babbf0a6ec5765` |
| Deleted | `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift` | `ca00bc0：1b16ec8b8a12b09f3a5e3694be1077b00b52bb62d394bb356c490fbf23e5c2e5` |
| Deleted | `Sources/Presentation/GitHubConnection/GitHubConnectionPresentation.swift` | `ca00bc0：b7fb55bb837a1a6577d3041a4b13c3431636e90db4dfaee860a9def803c0bf10` |
| Deleted | `Sources/Presentation/GitHubConnection/GitHubConnectionView.swift` | `ca00bc0：681c086fa72914fed0557338be833d43c98fd38b9eb61d394b8fa65bf4732b72` |
| Modify | `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift` | `c53914f4ab8b2a91f69790dd0c38f9611eca842fff3c5a4d88806faf3924be34` |
| Deleted | `Tests/GitHubIntegrationTests/GitHubOAuthAuthorizationSessionTests.swift` | `ca00bc0：ca3691a24323cfcc437d50031f554e66de71e81266add48feaea5cce5ddb5fac` |
| Deleted | `Tests/GitHubIntegrationTests/GitHubOAuthDataProtectionStoresTests.swift` | `ca00bc0：4a93082f908c40f167bdf4bdc4079ced9cd050ba95b9a6f201d9011907d150bf` |
| Deleted | `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift` | `ca00bc0：feebd60bcc39db020eb156b5404623746f42afc24511960d98b9035c8359619b` |
| Modify | `Tests/GitHubIntegrationTests/OAuthTokenProviderTests.swift` | `980d93ab790a7de230a218909afcce9504fb1d50a375afa7bc2b80f6fe46348a` |
| Modify | `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | `b251828338b90861eb03f8c63b358d138b2b2315f6960a879403474508613c7f` |
| Modify | `analysis/github-persistent-connection/requirements.md` | `2598a7def3021d930fdfab4b3dfa1a5745a3294d80f0c35cdfbf367f51440773` |
| Modify | `analysis/github-persistent-connection/technical-spec.md` | `161d40239f7d7c4b9ed6e424b24f5f0e53d4db7ea18526d26ef9d2df66862f59` |
| Deleted | `apps/Rivet/Resources/Info.plist` | `ca00bc0：733e24e4a9848b28d9fae0eda9ac0b322af568881dcb46244625acfaf1782fd7` |
| Deleted | `apps/Rivet/Resources/Rivet.entitlements` | `ca00bc0：526bac7f8ee939569becdf3d59ab86e83bf68c0bafda5ff3d660c5683dab6dc8` |
| Deleted | `apps/Rivet/Rivet.xcodeproj/project.pbxproj` | `ca00bc0：ddf42ca3511f297456cb82c30b8c1a74413da785c103a4409ebc6fff058df62f` |
| Deleted | `apps/Rivet/Rivet.xcodeproj/xcshareddata/xcschemes/Rivet.xcscheme` | `ca00bc0：3832ea8a70762b06eb77421a7f18abbab1ca62ba7749276fd7ed164e0638c4a6` |
| Deleted | `apps/Rivet/Sources/GitHubAccountProbe.swift` | `ca00bc0：7db900775746a49583344600a79509c6f75a14352483b4ef78abed350e556eaf` |
| Deleted | `apps/Rivet/Sources/GitHubConnectionCoordinator.swift` | `ca00bc0：3e485cb590a7c0fdbabdf6d39dde8860a604266d70c1fa496570578fa6fb6837` |
| Deleted | `apps/Rivet/Sources/GitHubLoopbackCallbackRelay.swift` | `ca00bc0：b8fa70f0eb357316d69d7e1a6e964508355708793053018afd738c3f3dee3ed4` |
| Deleted | `apps/Rivet/Sources/RivetApp.swift` | `ca00bc0：dbde174c7115de5fb096d09c19a71b6b933448e8160bdf9e39c43abca303b742` |
| Deleted | `apps/Rivet/Tests/GitHubConnectionCoordinatorTests.swift` | `ca00bc0：73fab0479c8e5a5ad84b2947e9ad5af6d86233bfd11722389f9e927bfc5f3fe9` |
| Deleted | `apps/Rivet/Tests/GitHubLoopbackCallbackRelayTests.swift` | `ca00bc0：d8afc7a0e854d91fd52584be7f8e9a622959e5bf94987134e972908897595b1e` |
| Modify | `docs/architecture/README.md` | `1d9e77238bd51d0c537a6b08a9b54591df905a59418d9d1de0a096b2fce9cfb7` |
| Modify | `docs/architecture/diagrams/github-persistent-connection/BUILD.md` | `ab3b43b1e92b607a40a64de943c68618b069bf491cb4ba4752fb90b811cf325b` |
| Modify | `docs/architecture/diagrams/github-persistent-connection/tool-evidence.md` | `6c3b470157f3c7d0258b1e1343c61e6056fe23c4235c89927413bdd76cda8d0d` |
| Modify | `docs/architecture/diagrams/github-persistent-connection/visual-review.md` | `00b50e9a4d2586ccc658872bb707e81a677bcf3005130cce258e053b8650ba4c` |
| Modify | `docs/architecture/github-oauth-dual-client.md` | `53d42f5e917f4b32d605e21fdfd93b289aecc5c5dbce2872ce6c5a0fdc16ccf3` |
| Modify | `docs/design-principles.md` | `65b072e3a86f7f68b97f3a8c332fcb066c238779f0ca83ebf38536ab75bc7486` |
| Modify | `plan/github-persistent-connection/evidence/compatibility.md` | `c3cf2ff9ddeef293af4af2f0e9502996d05a60d5e56ddf6a9ec8cf44a2fb9eae` |
| Modify | `plan/github-persistent-connection/evidence/contracts.md` | `c01e7fcfaf61001e27013acab69daeddeb210dd03de4bc5476ad7b4fd16d2497` |
| Modify | `plan/github-persistent-connection/evidence/final-review.md` | `8fb4e69fa3e6d5618457d0e4e0f5307b1d96eb8e675e52a7cce0dc57d162a478` |
| Modify | `plan/github-persistent-connection/evidence/product-e2e.md` | `661fc65522dd1f68dbdd60f42492b418ec3d0911aa238a41c6d1f09ca53462be` |
| Modify | `plan/github-persistent-connection/evidence/storage-live.md` | `b79711365bc0e2b5fd712cb2988788ec563babd3c8f4664ca9fd36c03ddd98d6` |
| Modify | `plan/github-persistent-connection/github-persistent-connection.plan.md` | `13ca04cf409943b3a545f664ba11d75b6c009d10feb0e328e0ad0687e787e6bc` |
| Modify | `plan/github-persistent-connection/github-persistent-connection.step.md` | `2c75eff9aa59df13ffac99521952df56683b84b4e99433616c1cfed06c714bb7` |
| Written | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.pbxproj` | `3b2760a3926d367f56442fc874424f8b0ec477d9c6de5849b8c08928d0846f42` |
| Written | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `4e66093bdf1d34c83ead4e62c2d021dedd2bb97eeb1761875ec60492d18ebbad` |
| Written | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/xcshareddata/xcschemes/GitHubConnectionVerification.xcscheme` | `56460cebf87cbd370aee73397efc8234ea933a22a98599592d107a01be5f8334` |
| Written；R07 doc-only Modify | `apps/GitHubConnectionVerification/README.md` | `1032b7c6b755c39bccdb8cebc65b3258868f7a9f730520286da865d171a48659` |
| Written | `apps/GitHubConnectionVerification/Resources/GitHubConnectionVerification.entitlements` | `526bac7f8ee939569becdf3d59ab86e83bf68c0bafda5ff3d660c5683dab6dc8` |
| Written | `apps/GitHubConnectionVerification/Resources/Info.plist` | `e2ed6f2d2d4c13585030e105a6dd691b80b2348971e94b4ffb907c576835156a` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubAccountProbe.swift` | `f8d5d398c90f6f57cd295b770d172825ae0ef22d86e171a71540d7066fe693c8` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift` | `3ab95f7484101a4c2c85654ec8b576453bdcfeee0f30609b37f330fa9b39653d` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubConnectionPresentation.swift` | `bd59393f946a904a4653e493ffe9f1b1b9f5acd64a8b6129ab9dd1d73eec8320` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` | `12797a0bc7bbf9b5f03d0724937277b64dceeeb9444da97d5faec9b12d477d86` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubConnectionView.swift` | `58e844f31353e6865bebfc152a961f02fce03f04899138c4c40959c5d3125274` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubExpiryValidation.swift` | `f9e3e13295d64c10a866863c8b6053f59b25ee726cb4ef82230bb65de5db5f2e` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubLoopbackCallbackRelay.swift` | `88df3fa9cd08945f36b49e224bf2a18d6d29a082650d3b1840d32eba76b6f929` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubOAuth.swift` | `cc237ef8da173d83694b762a89a64c69781a9650199cdb51cb2c64d1f4114e10` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubOAuthAppConfiguration.swift` | `474f1568b95f9925de8664df6d62906f736962a98fca44c9ff6993fe9d9dcca7` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubOAuthAuthorizationSession.swift` | `2908a2833cf05d176d160552e7b9a8e73b6fdd8bf07309977c9848bacb950733` |
| Written | `apps/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift` | `b2e55652df45e573c138a6acdf5495586dbec03268fbd4aad08a1558a565a282` |
| Written | `apps/GitHubConnectionVerification/Sources/VerificationLifecycleObservation.swift` | `4fe4a6c7366bacfe3e18f5e0d28777851c454360441d8217a0938e43781aeb38` |
| Written | `apps/GitHubConnectionVerification/Sources/VerificationOAuthEndpoints.swift` | `501e31c49ff643ccd03f1c141f2c7e5bdbb8f3e23baccdbad0302f45a20ca560` |
| Written | `apps/GitHubConnectionVerification/Sources/VerificationOAuthHTTPTokenFetcher.swift` | `d84aa4ac00eaf5bb664854b883e5c1c7a1975e451ed426d182bd541434a68dae` |
| Written | `apps/GitHubConnectionVerification/Sources/VerificationOAuthTokenResponse.swift` | `503850bae2215567f04d9a537190b471f3b67a5a6b85efc550eb36693385ba40` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubConnectionCoordinatorTests.swift` | `b761d9bb9507f38ad7b76fc6e0963d46173d3926e7b018394ca57b55404c6b99` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubConnectionVerificationIsolationTests.swift` | `7594a2e625c60a06c7ab0c73451d1f480644f617e02a324222bfa390af6d510c` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubExpiryValidationTests.swift` | `1778698b127f27606e418cad21396f6f7e28759c165c19784cf642e7d90de624` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` | `90f18b4e2750a03a85168eef4f031c6996263f1ee19c14a9e6fb1c2a38f93eb2` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubOAuthAuthorizationSessionTests.swift` | `edf6c72d36da48d337727f30d4f53606d903f361af332d8e2dc10bde86232680` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubOAuthDataProtectionStoresTests.swift` | `d5fbf39e8f17a1ab90a60ca0e0d922d7ed8eef8621a56c7b63ba38b8e88c19da` |
| Written | `apps/GitHubConnectionVerification/Tests/GitHubOAuthFactoryTests.swift` | `b2546c157961b3c2b0eef9f4a2e72f8573c13d13f6aad851d2436b7bf9cf7732` |
| Written | `apps/GitHubConnectionVerification/Tests/VerificationLifecycleObservationTests.swift` | `67552f47ddcace141ad37cbdbd23fe44f6711f2bf09bba197da61350917620bb` |
| Written | `apps/GitHubConnectionVerification/Tests/VerificationOAuthHTTPTokenFetcherTests.swift` | `8aad87dcfefc95472da444775661fd9e620158fa03652c05aca0c0b94324fbcd` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/BUILD.md` | `480915da2dec357ace17a1a52d1adfd29c8982e7a0693fe4d81a82fb7aa8c86f` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.delivery.json` | `346e1cc36c47735167f255b2dc54aa23bb96c58cf26f388cdf6f3cf15179aab9` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.html` | `6822566a659e4251115984c843b07bb3ecb9a61e51cf44fcc0cecc0e119a343d` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.json` | `90ff2756f6c5869166f71fc9a95f847b193b4996e645b9bbd5940555cc5124d9` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.visual-check.1440x900.dark.png` | `43ba883643d3a1921860fc3720db63ab676e43e2eaf00dda3bc00733e5462ec9` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.visual-check.1440x900.light.png` | `3f2044a12d05802838dd8738960d1e8329922e1ef7a552d6a5d85059a1c54af0` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.visual-check.2048x1320.dark.png` | `fdaec2a292db2dc289fcf28f2917b879f44efdff38373ad08a0438c7369aa93f` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.visual-check.2048x1320.light.png` | `88721f1be92792e32f5868f0de61908052c0516cedface70153675dee0012dc7` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.visual-check.html` | `a05d3c9a39611f0948222080b4a31cfbd8584db16adaf9f9ecca9b8ad718429e` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.visual-check.json` | `0eec394a5b3683a520ef6248e826402623ceae00596df077cc33f03b0a8ecd32` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.delivery.json` | `7fffb03cb40cf493f3764017fcc55ffa25fc53ee0b0aab1bd53b2b47cd41b8f8` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.html` | `9363d40a2d3e6618c10160e95b5e81dc844b7c7cd38e126ac0e43f35a1eb7136` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.json` | `b0d231066fa456a88d717d85976a07baa53e712be1c917763bdf5aec3faef0e4` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.visual-check.1440x900.dark.png` | `8fd25654c632b8e0af2033cbb97bb8f11e9358e893431e7f62ebaee729e25d91` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.visual-check.1440x900.light.png` | `5ea4ea437290ec5cb588cbb652f183ccf855bfd8544c184c9411e695b19b7a04` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.visual-check.2048x1320.dark.png` | `36f12e9ccb55afba49f0ebc935ca5ac4bf4b46843411635c652c47aa68e0f48a` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.visual-check.2048x1320.light.png` | `37f173d2574bdad31558486ac994edacbc946ad18c1650e5079711bf8bfdd5f4` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.visual-check.html` | `267409a77608860c67a0226ecdb52f09d7bce0e31ac8e73abc79e5f3628a025d` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/connection-lifecycle.visual-check.json` | `1d590cd7eecd2b0253c5e24f2639ad13719a91974c9d8f47dcdea42b547d0996` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/responsibility-canvas.html` | `881e4605adbb93646ae87647c1e54f48001e3a96f08f7bf8ab25cbe1321f0a55` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.delivery.json` | `54e4f9d7126bc1aba3c7d8e938d12a530739ff318671028bba152375c024abb3` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.html` | `6acdda69e45e85fcfb6d516651c2ffb9aefdf337742c4fd751fc9febce6e58fc` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.json` | `e93b852eb17c738352cf9cc9bafb1cd77df3d63221e20bb60af67a0a6552600a` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.visual-check.1440x900.dark.png` | `05d60807f14db3e99c5f0c1c26a6fc0b30c57f2865d2398f2c816b7d9e8fe504` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.visual-check.1440x900.light.png` | `aa5c9293bd68e89e00507b930ecf05a80540bffd59eea428c265560ea99bb1fe` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.visual-check.2048x1320.dark.png` | `3de1610cc085639330a7612b701f6715215ca835bb7ab51d7f39f3a2eb4a905a` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.visual-check.2048x1320.light.png` | `73e1730d95074809ef3c0613523da8fc1f45b1327b3e689dd46e1498a4879f6d` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.visual-check.html` | `12d451b73396e40051ec81b593fd1b1579a593f7b7f7e604de855554285e40f7` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/restore-refresh-reauth-sequence.visual-check.json` | `1b62e866348b48742b7f1e0a25b71a604c50df5445b8f2bb118d3407c49eab23` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/scene.js` | `5aff38f4cb087c540c861f126cb5fb85811988d7a305f13e140719f3cbf06948` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/tool-evidence.md` | `e1488f29ed69aa9ea61d56fe0a8f7b17af98bbb707aa85b047f03cfc0a7a7b76` |
| Written | `docs/architecture/diagrams/github-persistent-connection/verification-host-v2/visual-review.md` | `84cde84cb7bae1bf248d6c3fbba41d7162fc02a4c54bc646328f05a343cd3f74` |
| Written | `plan/github-persistent-connection/evidence/verification-host-contracts.md` | `d87da11921620c1763fca2ef95ae9aa0c7fc3684546c9d32be7d3c7c72c4b372` |
| Written | `plan/github-persistent-connection/evidence/verification-host-isolation.md` | `39e9800fdc84409e8d3b3611e4f2e8eea8e130616da212a4f8f9eb2a410b3578` |
| Written | `plan/github-persistent-connection/evidence/verification-host-live.md` | `8c5c0b8aa09e5c566429f7926cd8da1932979afbad224b5fcae14711f4f05ea1` |
| Written | `plan/github-persistent-connection/evidence/verification-host-manifest.md` | `本表自指，最終SHA由私有handoff／獨立Tester綁定` |
| Written | `plan/github-persistent-connection/evidence/verification-host-review.md` | `53ee9bbc4c486ed226f4c3ad652bf33c3b740a8ad8181c735f60e28a39aeb311` |

### 明示保留與原生收據

- 上方R03 ReadOnly表列E00732＋舊native29，共61個精確路徑與SHA，R07再核均同R06／ca00bc0；不是因文件banner而改native。
- 新版R06live原SHA `8c5c0b8aa09e5c566429f7926cd8da1932979afbad224b5fcae14711f4f05ea1` 保持；R04／R05／R06原機器／Human收據及sourcehash值不回填。
- 八個historybanner路徑皆只prepend，原ca00bc0全文suffix逐bytes一致；其中舊source相對路徑是原版本定位，應依原commit查閱，不能將其當當前實作。
- 所有其餘productionSources／Tests、Package／locks、既有PRUI與packages／工具config／hooks／其他topic／PR61／dev／原App與DPK／Apple資產保留；rootSources／Tests／Package對16606b89diff為空。
- 全本輪每個變更路徑已在本表列action；productionDeleted19＋Modify4、新App30及其餘planning／docs／evidence／v2按核准manifest。未新增目錄級授權或非核准nativeleaf。

## R10 提交與輔助工具版本

本輪source歸屬commit `b63af3e51d04487f651ba2fb521fd056f53f1af1` 將本表D19／M4／App30一次提交；原R03／R05／R06實測在本commit之前，仍以原sourcehash／privateproject／native收據追溯，沒有改寫成從此commit建置。53from/to union已由真ca00bc0→此head的PRLensmap全覆蓋，後docs／evidence／v2不在map範圍。

R10只追加既定step／本manifest／v2tool-evidence的真commit與工具facts；沒有新repoleaf或source/native/live變更。R07／R08／R09表列SHA保持各自受審快照，mutable本檔與step避免自指；最終發布hash由私有handoff與獨立Dispatcher讀回。本輪語意分組／完整hooks／push／原DraftPR62更新按既定授權，未merge。
