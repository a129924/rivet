# 驗證產物歸屬修正：技術規格

需求見 [requirements](requirements.md)。本文件是逐檔清單唯一可追溯來源；plan／step 引用本文件，不複製維護清單。

## 已鎖定邊界

正式 Presentation（UI、types、artwork、bundle）、PRReaderWebViewBridge、TS pipeline 本體、GitHubIntegration（OAuth、provider／scope、clients、DPK adapter）與正式測試保留。
root products／targets／dependencies 不變；僅改必要 source／test paths。Reader 保留 Bundle.module 與 resources 宣告。
StaticIsolationTests 只鎖定完整 product／target 集合，沒有兩組 Demo／Harness 舊路徑斷言，不預設修改它。
format／lint 僅接回搬移前已涵蓋的檔案，不擴掃所有 experiments 或順手修全局問題。

## 配號與契約鎖定

初稿 E011–E015 為 B1–B5 的候選目的地；目前已鎖定 B1 使用 E011、B2 使用 E012、B3 使用 E013；E014–E015 仍待各批前確認。E011 尚非已合併或已完成的驗證。Explorer 已查五個工作樹與 75 個本機 refs，未見 E011 以上；本輪重新列出遠端四個 branches：dev、main、docs/e010-postmerge-registry 與本 feature，SHA 均對應已查本機 refs；未見 E011 占用。本 feature 的 E011 只收納原 rivet-login-ui 功能驗收展示，不重寫其 topic 性質。
每批前重新查索引／占用並鎖定編號；若衝突，回修本唯一清單並交獨立審查，不能臨場套用舊號或擴張範圍。
每批先鎖定 baseline、old/new、ReadOnly／Written／Deleted／Modify、設定與入口、允許差異及必要檢查。B1／B2 列已鎖定；其餘批次未確認前仍不是該批實作契約。

## 唯一逐檔清單

基準：`a554a4fee772d3976d5ca2c9331865a604e901e2`。共 73 檔（B1–B5：4／7／23／30／9）。hash 是搬移前檔案 bytes 的 SHA-256；數量不是永久 assertion。
各列 old 為該批 Deleted、new 為 Written，另有下節留原位的 Modify 清單；集合互斥。未列檔案不可寫入；ReadOnly 是實際讀取但不可改的檔案，不以整目錄替代精確集合。

| 批次 | old／Deleted | new／Written（B1/B2/B3 鎖定；其餘候選） | baseline SHA-256 | 允許差異 |
|---|---|---|---|---|
| B1 | `Sources/RivetLoginDemo/main.swift` | `experiments/E011/Sources/RivetLoginDemo/main.swift` | `8f4f4acea31d0a938f6e876d3e86be2315993dc57ef28c442a9137ec03cf1d1f` | 純搬移；bytes 不變 |
| B1 | `Sources/RivetLoginDemoRuntime/LoginDemoHost.swift` | `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoHost.swift` | `979ae090b03f1ee79e37d3feebbbcf054cca669ef38231765a9e689357060bb8` | 純搬移；bytes 不變 |
| B1 | `Sources/RivetLoginDemoRuntime/LoginDemoModel.swift` | `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoModel.swift` | `3b00d2aa9968081fb1efb1290ea505de53bfeeb0959d30f0d6a1bcf8fc27f809` | 純搬移；bytes 不變 |
| B1 | `Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift` | `experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift` | `9341a7f1fb49cd751f1b42cc705ad3b0b18bd2c3ec9c9799cd54a0e85b32b9a0` | 純搬移；bytes 不變 |
| B2 | `Sources/RivetPRReaderHarness/main.swift` | `experiments/E012/Sources/RivetPRReaderHarness/main.swift` | `22e7ed610b4ae19729c1e3b1cf58ab10c7abca129f18637060e09ad3e793ae8f` | 純搬移；bytes 不變 |
| B2 | `Sources/RivetPRReaderHarnessRuntime/ReaderFixture.swift` | `experiments/E012/Sources/RivetPRReaderHarnessRuntime/ReaderFixture.swift` | `7ddc1985bd169fb6732c79ddcc4fd925b4ad805f9ce4dc4ca7596bdff1b5e05b` | 純搬移；bytes 不變 |
| B2 | `Sources/RivetPRReaderHarnessRuntime/ReaderHarness.swift` | `experiments/E012/Sources/RivetPRReaderHarnessRuntime/ReaderHarness.swift` | `faef52206be47355f38f3af2f320b4c9dea2319180fadafb0f560e85058de1d3` | 純搬移；bytes 不變 |
| B2 | `Sources/RivetPRReaderHarnessRuntime/Resources/index.html` | `experiments/E012/Sources/RivetPRReaderHarnessRuntime/Resources/index.html` | `9ad4f8f5f7f868a8bb5dae6623ac87714fc2dd3c47ac658933646328fe84e3b2` | 純搬移；bytes 不變 |
| B2 | `Sources/RivetPRReaderHarnessRuntime/Resources/reader.css` | `experiments/E012/Sources/RivetPRReaderHarnessRuntime/Resources/reader.css` | `5d8c29401dc1b0143a98746c75c030de39b5d6c3703b888109f5ac45e37775eb` | 純搬移；bytes 不變 |
| B2 | `Sources/RivetPRReaderHarnessRuntime/Resources/reader.js` | `experiments/E012/Sources/RivetPRReaderHarnessRuntime/Resources/reader.js` | `2ab5fdf0daad9aff9ccefb1f61021b54c1ce57fc8019b85b84a3c2f47abd4cba` | 純搬移；bytes 不變 |
| B2 | `Tests/RivetPRReaderHarnessRuntimeTests/ReaderHarnessTests.swift` | `experiments/E012/Tests/RivetPRReaderHarnessRuntimeTests/ReaderHarnessTests.swift` | `4b4f07c751d434d9ee80c5754801e61abb4d537a292134759329a13135e6a137` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj` | `experiments/E013/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj` | `f148863c49fc65aeb2ddd9415abe60b3fb850f4a13ff324a78cf00aff777b05c` | 例外：local package reference 路徑 |
| B3 | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `experiments/E013/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `95e886eb7c970b3ce2795e2e46e409187437cfcf2b4850c4033f5f5ab7c9b86e` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme` | `experiments/E013/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme` | `1b6e21c4c93a39b9037494014c50b9a7562c3768f185c15e2f1a8d179e36b464` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Resources/Info.plist` | `experiments/E013/GitHubSignInVerification/Resources/Info.plist` | `5e55d677babb03eced4a1756a08e58b0fd1e17790cdd8d1bc43edb337ca46040` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift` | `experiments/E013/GitHubSignInVerification/Sources/GitHubAccountProbe.swift` | `f00b2544f79dd9931e8a811d0ba60a0dc188fca89e9d7d2e24f3a225754267fc` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift` | `experiments/E013/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift` | `3d04f11e8fa4a9f5d023701b0b59da8541571bccd3312ac0f53de973d554e383` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Sources/GitHubConnectionPresentation.swift` | `experiments/E013/GitHubSignInVerification/Sources/GitHubConnectionPresentation.swift` | `a87adf9d9279b3b3d2783a9a63e3188a7e0a8fc165b9b44bfe543e70c90221d8` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Sources/GitHubConnectionView.swift` | `experiments/E013/GitHubSignInVerification/Sources/GitHubConnectionView.swift` | `caf7dd5421020e6a6365fb8ba582c1732669cce52a01499a1b3aacbef6ac9b06` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Sources/GitHubLoopbackCallbackRelay.swift` | `experiments/E013/GitHubSignInVerification/Sources/GitHubLoopbackCallbackRelay.swift` | `efd06a28d84f2ac261b5f2de520bfd310e05d39de4778c4a32fd5f4996d07dce` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift` | `experiments/E013/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift` | `1686c418d887ef7b3debfa3a7e1fb70cd3cfeee835af45840f47d9d9eacd8071` | VO-RB3獨立受限修正後搬移基線 SHA `bce66b2292b5c0b17272355cb2fbe2c8bdbd780c4fec5d8fe0a1dc280ddc2b1f`；原盤點hash保留；後續搬移bytes不得再變 |
| B3 | `apps/GitHubSignInVerification/Sources/InMemoryOAuthCredentialStore.swift` | `experiments/E013/GitHubSignInVerification/Sources/InMemoryOAuthCredentialStore.swift` | `1593b22f78093977e7bfddbc909c6a972c7cfa4e48e1e18e23666c61d32f1e85` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Tests/GitHubAccountProbeTests.swift` | `experiments/E013/GitHubSignInVerification/Tests/GitHubAccountProbeTests.swift` | `119f6a615c9e030b018048211deaa27c8887a1fc30516b6d6ddcbbd3c24570f0` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Tests/GitHubConnectionCoordinatorTests.swift` | `experiments/E013/GitHubSignInVerification/Tests/GitHubConnectionCoordinatorTests.swift` | `6d0c85edfce9a5f32ad2a04278950e4ad3a8b3624e80b33c40fc318dd4c4174d` | VO-RB3獨立受限修正後搬移基線 SHA `2d9a8a0dfb0c96c4af74479f06469474d2f7de312eca47a6bf02496c3c69e131`；原盤點hash保留；後續搬移bytes不得再變 |
| B3 | `apps/GitHubSignInVerification/Tests/GitHubConnectionPresentationTests.swift` | `experiments/E013/GitHubSignInVerification/Tests/GitHubConnectionPresentationTests.swift` | `dcd8c94f72c076494d82698724527376412afc76b34f4ba85723ac2251691c8b` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` | `experiments/E013/GitHubSignInVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` | `257743d91b919cc3061da0ce0f8517f3792c42611115d6561247d9370f3cf8f3` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/Tests/InMemoryOAuthCredentialStoreTests.swift` | `experiments/E013/GitHubSignInVerification/Tests/InMemoryOAuthCredentialStoreTests.swift` | `12a3b8c5686c4d173bc3be8d28412a7ea1a656dc4d8cd10e3003871bc502fab5` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/tools/README.md` | `experiments/E013/GitHubSignInVerification/tools/README.md` | `7856d56582268332231f6ef3acd1bc8f49bc9fc069548be693bd31165524a6a1` | 例外：現行連結／操作路徑／用途 |
| B3 | `apps/GitHubSignInVerification/tools/fixtures/semantic-review-ai-v1.json` | `experiments/E013/GitHubSignInVerification/tools/fixtures/semantic-review-ai-v1.json` | `38946829d2181e6a279e34de5ad1ce6221fb67fc53f53efbaf7a67b0c6001245` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/tools/fixtures/semantic-review-cases.json` | `experiments/E013/GitHubSignInVerification/tools/fixtures/semantic-review-cases.json` | `d1567758e9dfb2861886510f8c41a3a03174be805c6b7979e8f28d850e9a2ea5` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/tools/fixtures/semantic-review-zh-v1.json` | `experiments/E013/GitHubSignInVerification/tools/fixtures/semantic-review-zh-v1.json` | `2be946fe6ce64f5ed29e39aaa8c183e336b5112271e1482f7410f9ee3d387827` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/tools/pkce_negative_probe.py` | `experiments/E013/GitHubSignInVerification/tools/pkce_negative_probe.py` | `26894482d275636d4e736a648b0366ee6ce6b980e5fafb0683b80b40544ff0b9` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift` | `experiments/E013/GitHubSignInVerification/tools/pkce_semantic_review.swift` | `8505134d2130f1f99a1339cb9abbccabe894c2db73575c60d759d542a5a5e405` | 純搬移；bytes 不變 |
| B3 | `apps/GitHubSignInVerification/tools/test_pkce_negative_probe.py` | `experiments/E013/GitHubSignInVerification/tools/test_pkce_negative_probe.py` | `62d1849c1d1b16351b27b4b6ea1247c75a24a8c6fdf9b3c32908e733c3fde0c5` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.pbxproj` | `experiments/E014/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.pbxproj` | `3b2760a3926d367f56442fc874424f8b0ec477d9c6de5849b8c08928d0846f42` | 例外：local package reference 路徑 |
| B4 | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `experiments/E014/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `4e66093bdf1d34c83ead4e62c2d021dedd2bb97eeb1761875ec60492d18ebbad` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/xcshareddata/xcschemes/GitHubConnectionVerification.xcscheme` | `experiments/E014/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj/xcshareddata/xcschemes/GitHubConnectionVerification.xcscheme` | `56460cebf87cbd370aee73397efc8234ea933a22a98599592d107a01be5f8334` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/README.md` | `experiments/E014/GitHubConnectionVerification/README.md` | `1032b7c6b755c39bccdb8cebc65b3258868f7a9f730520286da865d171a48659` | 例外：現行連結／操作路徑／用途 |
| B4 | `apps/GitHubConnectionVerification/Resources/GitHubConnectionVerification.entitlements` | `experiments/E014/GitHubConnectionVerification/Resources/GitHubConnectionVerification.entitlements` | `526bac7f8ee939569becdf3d59ab86e83bf68c0bafda5ff3d660c5683dab6dc8` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Resources/Info.plist` | `experiments/E014/GitHubConnectionVerification/Resources/Info.plist` | `e2ed6f2d2d4c13585030e105a6dd691b80b2348971e94b4ffb907c576835156a` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubAccountProbe.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubAccountProbe.swift` | `f8d5d398c90f6f57cd295b770d172825ae0ef22d86e171a71540d7066fe693c8` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift` | `3ab95f7484101a4c2c85654ec8b576453bdcfeee0f30609b37f330fa9b39653d` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubConnectionPresentation.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionPresentation.swift` | `bd59393f946a904a4653e493ffe9f1b1b9f5acd64a8b6129ab9dd1d73eec8320` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift` | `12797a0bc7bbf9b5f03d0724937277b64dceeeb9444da97d5faec9b12d477d86` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubConnectionView.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionView.swift` | `58e844f31353e6865bebfc152a961f02fce03f04899138c4c40959c5d3125274` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubExpiryValidation.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubExpiryValidation.swift` | `f9e3e13295d64c10a866863c8b6053f59b25ee726cb4ef82230bb65de5db5f2e` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubLoopbackCallbackRelay.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubLoopbackCallbackRelay.swift` | `88df3fa9cd08945f36b49e224bf2a18d6d29a082650d3b1840d32eba76b6f929` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubOAuth.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuth.swift` | `cc237ef8da173d83694b762a89a64c69781a9650199cdb51cb2c64d1f4114e10` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubOAuthAppConfiguration.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuthAppConfiguration.swift` | `474f1568b95f9925de8664df6d62906f736962a98fca44c9ff6993fe9d9dcca7` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubOAuthAuthorizationSession.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuthAuthorizationSession.swift` | `2908a2833cf05d176d160552e7b9a8e73b6fdd8bf07309977c9848bacb950733` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift` | `experiments/E014/GitHubConnectionVerification/Sources/GitHubOAuthDataProtectionStores.swift` | `b2e55652df45e573c138a6acdf5495586dbec03268fbd4aad08a1558a565a282` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/VerificationLifecycleObservation.swift` | `experiments/E014/GitHubConnectionVerification/Sources/VerificationLifecycleObservation.swift` | `4fe4a6c7366bacfe3e18f5e0d28777851c454360441d8217a0938e43781aeb38` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/VerificationOAuthEndpoints.swift` | `experiments/E014/GitHubConnectionVerification/Sources/VerificationOAuthEndpoints.swift` | `501e31c49ff643ccd03f1c141f2c7e5bdbb8f3e23baccdbad0302f45a20ca560` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/VerificationOAuthHTTPTokenFetcher.swift` | `experiments/E014/GitHubConnectionVerification/Sources/VerificationOAuthHTTPTokenFetcher.swift` | `d84aa4ac00eaf5bb664854b883e5c1c7a1975e451ed426d182bd541434a68dae` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Sources/VerificationOAuthTokenResponse.swift` | `experiments/E014/GitHubConnectionVerification/Sources/VerificationOAuthTokenResponse.swift` | `503850bae2215567f04d9a537190b471f3b67a5a6b85efc550eb36693385ba40` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubConnectionCoordinatorTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubConnectionCoordinatorTests.swift` | `b761d9bb9507f38ad7b76fc6e0963d46173d3926e7b018394ca57b55404c6b99` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubConnectionVerificationIsolationTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubConnectionVerificationIsolationTests.swift` | `7594a2e625c60a06c7ab0c73451d1f480644f617e02a324222bfa390af6d510c` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubExpiryValidationTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubExpiryValidationTests.swift` | `1778698b127f27606e418cad21396f6f7e28759c165c19784cf642e7d90de624` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubLoopbackCallbackRelayTests.swift` | `90f18b4e2750a03a85168eef4f031c6996263f1ee19c14a9e6fb1c2a38f93eb2` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubOAuthAuthorizationSessionTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubOAuthAuthorizationSessionTests.swift` | `edf6c72d36da48d337727f30d4f53606d903f361af332d8e2dc10bde86232680` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubOAuthDataProtectionStoresTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubOAuthDataProtectionStoresTests.swift` | `d5fbf39e8f17a1ab90a60ca0e0d922d7ed8eef8621a56c7b63ba38b8e88c19da` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/GitHubOAuthFactoryTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/GitHubOAuthFactoryTests.swift` | `b2546c157961b3c2b0eef9f4a2e72f8573c13d13f6aad851d2436b7bf9cf7732` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/VerificationLifecycleObservationTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/VerificationLifecycleObservationTests.swift` | `67552f47ddcace141ad37cbdbd23fe44f6711f2bf09bba197da61350917620bb` | 純搬移；bytes 不變 |
| B4 | `apps/GitHubConnectionVerification/Tests/VerificationOAuthHTTPTokenFetcherTests.swift` | `experiments/E014/GitHubConnectionVerification/Tests/VerificationOAuthHTTPTokenFetcherTests.swift` | `8aad87dcfefc95472da444775661fd9e620158fa03652c05aca0c0b94324fbcd` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj` | `experiments/E015/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/project.pbxproj` | `2154f06f13c0447b7661443633602ce80d2843dc02bc82d992aca3d824e07ece` | 例外：local package reference 路徑 |
| B5 | `validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme` | `experiments/E015/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme` | `0a467b796189b4ad6bec9d15dfaab48180b62d0ff8829b51892b8a8708f15604` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme` | `experiments/E015/github-oauth-credential-persistence/CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme` | `a68aa5a591df5cabd8264313723d408c5543cf58a0f4231053a66daee97bf800` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/README.md` | `experiments/E015/github-oauth-credential-persistence/README.md` | `0290d1d81a9e40e820914feaba69aa0114c454b75ed2ce2044dfbd508ba5d698` | 例外：現行連結／操作路徑／用途 |
| B5 | `validation/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements` | `experiments/E015/github-oauth-credential-persistence/Resources/CredentialStorageProbe.entitlements` | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/Resources/Info.plist` | `experiments/E015/github-oauth-credential-persistence/Resources/Info.plist` | `b1b4e5d6f462610f3944db7f32ec976ad7ec52efe20159eee12d970bfb68118d` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/Sources/main.swift` | `experiments/E015/github-oauth-credential-persistence/Sources/main.swift` | `78eede7ec1132d7dc84d6762d0e61c737d6eac9e51950b623194fda05b680213` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/Tests/test_live_protocol.py` | `experiments/E015/github-oauth-credential-persistence/Tests/test_live_protocol.py` | `f0b5f63a15a09b23dd22db15a0d06f67ac28b07d9ab248ff9025413efb7d3b80` | 純搬移；bytes 不變 |
| B5 | `validation/github-oauth-credential-persistence/scripts/credential_storage_live.py` | `experiments/E015/github-oauth-credential-persistence/scripts/credential_storage_live.py` | `b4e28abb50c348f93870aadb4ad6256805c275039c7242530cb7fa19c8d40916` | 例外：模板定位及兩處精確路徑替換；不改邏輯 |

## 留原位的接線與明列新增清單

下表也是本文件唯一清單的一部分。每批開始前把該批實際檔案集合鎖定在此，交接只引用列，不複製另一清單。純搬移檔案不改 bytes；路徑例外只能改該列明示內容。

| 批次 | 精確檔案 | 集合／允許差異 |
|---|---|---|
| B2 | `experiments/E012/README.md` | Written：原Reader fixture驗收用途、root build/tests、本機cache與暫存wrapper入口；不新增工具／package |
| B2 | `Sources/PRReaderWebViewBridge/BridgeSession.swift` | ReadOnly：正式bridge不搬不改 |
| B1 | `experiments/E011/README.md` | Written：本驗收展示用途、原 topic、root build／test 與既有 wrapper 包裝／啟動操作，不新增工具或 package |
| 各批 | `analysis/verification-artifact-ownership/technical-spec.md` | Modify：本唯一清單的批次鎖定與允許差異／證據，不複製另一清單 |
| 各批 | `plan/verification-artifact-ownership/verification-artifact-ownership.plan.md` | Modify：建置命令、適用基線與驗證證據 |
| 各批 | `plan/verification-artifact-ownership/verification-artifact-ownership.step.md` | Modify：角色交接、獨立 verdict 與真實狀態 |
| B1 | `Sources/Presentation/Resources/Login/GitHubMark.pdf` | ReadOnly：正式資源保留，僅比對搬移前後 bundle bytes |
| B1 | `Tests/RivetPresentationTests/RivetLoginPresentationTests.swift` | ReadOnly：受影響正式測試保持原歸屬與內容 |
| B1/B2 | `Package.swift` | Modify：僅 source／test path；產品、target、依賴、resource 宣告不刪改 |
| B1/B2 | `scripts/check-swift-format.sh` | Modify：接回原有涵蓋的新路徑 |
| B1/B2 | `scripts/check-swiftlint.sh` | Modify：接回原有涵蓋的新路徑，不改執行環境 |
| B2 | `surfaces/pr-reader-webview/package.json` | Modify：僅 bundle:reader 輸出路徑 |
| 各批 | `experiments/README.md` | Modify：經確認的新編號／用途／原 topic 索引，不改舊結果 |
| 各批 | `README.md` | Modify：現行連結與本次澄清，不改舊輪結論 |
| B1 | `docs/presentation/login-ui.md` | Modify：現行 Demo 路徑／操作入口，不改 UI 採用與驗收歷史 |
| B2/B3/B4 | `docs/architecture/README.md` | Modify：僅現行工具路徑與本次歸屬說明 |
| B3 | `docs/architecture/github-first-sign-in.md` | Modify：現行路徑／E009 角色與限制，不改歷史結論 |
| B3/B4 | `docs/design-principles.md` | Modify：現行工具路徑與本次歸屬說明，不重設架構 |
| B4 | `docs/architecture/github-oauth-dual-client.md` | Modify：現行工具路徑，不改 production 契約 |
| B5 | `docs/architecture/github-oauth-credential-persistence.md` | Modify：現行 runner 路徑，不改正式 adapter 契約及歷史 |
| B1/B2 | `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | ReadOnly：保留 target 集合，未證明受影響不得改 |
| B3 | `experiments/E009/LaunchVerification.swift` | ReadOnly：不自動更新或移除 binary pin |
| B3 | `experiments/E009/README.md` | ReadOnly：保留舊 pin／建置來源紀錄 |

若限定搜尋找到其他現行入口，先把精確檔案及允許路徑差異加入此表並交審，不能事後擴張白名單。歷史 plan／evidence 舊路徑保留，經本表追溯新位置；不回填舊 receipts。

## 專項接線與不可變證據

B3：PKCE Python、Swift helper、fixtures 保持鄰接（Path(__file__).with_name）；fixture、輪次與結果不合併。
B5：TEMPLATE、dpk_prepare 的固定模板定位、project root package reference，以及複製模板與 dpk_prepare 兩處精確比對／替換須一起改；保留唯一匹配檢查。SOURCE_FILES 的正式來源不搬。現有 manifests 不引用 B1–B4，維持第五批。

### E009 binary pin

E009 仍是現行受控入口，不能列為 historical-only：docs/architecture/github-first-sign-in.md 的現行操作指向 launcher；E009 README 記重建失配須核對／重凍結。
LaunchVerification.swift 的 expectedBinarySHA256 為 `66aa6f9af216198df2e982aa2e9295fc16f9124e05a848aadac9676ae57dba2f`。它檢查 bundle ID、可執行檔及 SHA；--preflight --app-bundle 分支成功後直接返回，不讀憑證或 launch。
B3 必須對最終新產物實際記錄來源 revision、允許 diff、build recipe、bundle／executable 身分、artifact SHA 與受控 preflight 結果。沒有 source 路徑硬編碼，不表示新 binary 符合舊 pin。
本契約不允許改 pin。失配時 blocked；若確有更新現行 pin 必要，先回修此契約，列必要性、精確允許差異、新來源／建置／產物綁定，經獨立審查與適用授權才處理，保留舊 pin／hashes／receipts，不弱化檢查，不宣稱重新完成真人驗證。

### Login wrapper

既有外置 wrapper 的符號路徑為 $TOPIC_SCRATCH/native/RivetLoginDemo.app；證據為 plan/rivet-login-ui/evidence/verification.md 及 docs/presentation/login-ui.md。
既有 bundle ID 為 local.rivet.login-ui-demo，wrapper 使用 executable 與 Rivet_RivetPresentation.bundle。Explorer 讀到歷史 binary SHA `50a30cdc872292f8cd4de5a689b52ae2ab9d6451613067ff8440ba68b384d67f`，不等於本 feature 新產物可用性。
既有包裝方法已鎖定：保留歷史 Info.plist bytes 與 bundle ID，只在本次獨立 scratch 的 native-baseline／native-post 各複製一份 wrapper；以本次 debug binary 與 Rivet_RivetPresentation.bundle 替換各自 copy，open 該 app。不得改歷史 wrapper、簽章身分或正式 UI。用途文件可提供同一 plist keys 的可重現包裝命令，不新增 repo script／target／package。主對話已親驗 baseline UI，post-move 仍須實際驗證。

## B2 實作前鎖定

B2 E012未見占用：已查現有本機refs及遠端四branches（SHA對應已查refs）；不改E011／E009。唯一表B2七列均純搬移、bytes不變，三resources亦不得重產不同內容。TS pipeline留原處，只改bundle:reader輸出。
本批source／test targets沿用root同名target與依賴／resources宣告；format／lint只再接回E012 Sources／Tests。現行docs/architecture/README只補E012入口連結，不重畫凍結圖、不改正式BC契約。
原文件swift run可執行，但原始程序不具CUA app識別；沿用歷史暫存app-wrapper驗法，不新增repo工具或簽章設定。wrapper只包同一已建置binary；既有SwiftPM resource accessor優先查app根目錄的Rivet_RivetPRReaderHarnessRuntime.bundle，否則查build目錄。baseline初次畫面由build目錄載入，post須記錄實際URL並驗new資源與Viewed，不用copied資源存在假稱已載入。暫存wrapper識別僅local.rivet.reader-harness-verification，沒有production簽章／profile或storage。

### B3 實作前鎖定

E013未占用：重新確認76個localrefs的實體artifact paths，遠端四heads均與已查refs對應。來源d62e0ef，B3唯一表23/23舊hash吻合；本節鎖定唯一表B3全部new路徑，不另複製逐檔清單。
唯一source內容例外為project.pbxproj兩個XCLocalSwiftPackageReference：root relativePath由../..改../../..；HTTPClient由../../packages/RivetHTTPClient改../../../packages/RivetHTTPClient，各精確一次。其餘21個非README檔含scheme、plist、source/tests、fixtures、Python及Swift helper皆純搬移bytes不變；tools/README只改現行操作路徑、用途及安全離線操作說明，不改凍結結果／預算。
必要Modify僅本表列明的README／docs current導覽與本topic三檔、experiments索引；不改lint涵蓋（B3原本不在root lint迴圈）、root manifest／targets／products／dependency版本、scheme guard、簽章／儲存及E009 pin。沒有新增repo檔案或工具。
E009仍現行受控入口。適用unsigned獨立build之binary先核身分／SHA，再跑既有--self-test與--preflight；若baseline已失配即blocked，不聲稱已驗final移後產物、不搬source。若baseline適用則post最終產物仍須另驗；失配停止下一批，若已搬移只依本批mapping與原bytes反向撤回，不覆蓋其他修改，保留receipts。更新pin仍是未授權人類決策，不自行調整。

### VO-RB3：搬移前空白配置受限修正

來源HEAD ec94bec，feature乾淨且與PR69／upstream一致。Human本次Execution Authorized明確允許受限修正與基線重建。只Modify唯一表B3兩個old檔：GitHubSignInVerificationApp.swift與GitHubConnectionCoordinatorTests.swift；本階段不搬移，Written／Deleted空集合。其餘source、project、tools／fixture、正式能力／正式測試、root graph與E009 pin均ReadOnly。
允許source差異僅configuration(environment:)的guard增加兩個trim後非空判斷，沿原clientConfiguration錯誤與原回傳值；makeCoordinator在配置不合法時既有disabled路徑不改，不抽新helper。test差異僅補直接composition配置的typed錯誤／空字串／純空白（含tab／CR／LF）案例，驗證有效字串原樣保留、invalid composition不標prepared且不可start，不更動原期待或略過失敗。
本topic四正式文件僅補本次授權、精確允許差異、適用基線、獨立結果與當前狀態；requirements為本次受限例外的必要記錄，原約束及歷史不刪。長期現行配置規則可於既有docs/architecture/github-first-sign-in.md補一段，無新圖面。
唯一表原baseline SHA代表a554a4f盤點bytes，保留不改。兩修正檔green後的搬移基線SHA補在各自同一列的允許差異欄，並綁獨立修正commit；後續B3搬移只比對修正後bytes，不把行為修改偽稱puremove。其他21檔仍依原baseline SHA／既定project及README例外。
