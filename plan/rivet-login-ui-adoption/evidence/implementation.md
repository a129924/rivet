# I01：Login UI 元件化實作與自驗

- 日期：2026-11-17；owner=Implementer；topic `rivet-login-ui-adoption`。
- Branch `feat/rivet-login-ui-adoption`，base `1f31b35604adb5bb36326e52f9d6dbcff0cac763`；本輪來源為feature工作區尚未commit，不虛構SHA。
- P02獨立Plan-Reviewer對話 verdict=approved，required fixes=無。I01依既有核准契約執行，不由作者自審planning或code。

## 實作與接入

公開root只組合責任元件，PAT state移到form；phase仍parent-owned。正式content預設去展示文字，E011本地copy接同一正式元件。新增createPersonalAccessToken intent／canCreateToken，View不開browser。既有VO只文件對應，無GitHubIntegration import、request建構、service／Outcome mapper、儲存或session。

## Red／green與命令結果

| 檢查 | 實際結果／限制 |
| --- | --- |
| red：`swift test --filter RivetLoginContentTests` | exit1；新增tests因尚無RivetLoginContent／status type、新initializer與create intent而編譯失敗，為目標API尚未實作；同時root既有認證test編譯缺陷亦存在 |
| 第一次root green嘗試 | Presentation／E011模組編譯成功；root仍在FakePATSecurity編譯失敗，未宣稱tests通過 |
| 外部focused manifest首次全跑 | Login cases皆pass；PR Inbox source-location test因scratch相對布局不同失敗，已修scratch布局，未改正式測試來跳過 |
| 外部focused manifest相同相對布局 | exit0，32 tests／7 suites pass（含Presentation、Login helper／content與E011 model） |
| `swift build --product RivetLoginDemo`（正式root manifest） | exit0，正式host消費端可建置 |
| scoped `swift format lint --strict` | exit0 |
| scoped `swiftlint lint --strict --no-cache` | exit0，13 Swift files，0 violations；初次不帶--no-cache遇全域cache寫權限，非lint violation |
| lifecycle v2-r1 | showcase／deliver／四尺寸visual-check exit0；人工四圖實看pass，自動visualReview仍pending，見BUILD與receipts |

32 tests只支持實際helper／content／model行為，沒有把它當真正SwiftUI control互動證據。TC01的public初始化由一般import consumer測試；TC02只已有helper／model部分，form identity／Show-Hide需native補驗；TC03 callback與新建立入口需native驗；TC04／TC08有source／文件有界核對；TC05 native矩陣／focus時序待Tester；TC06 Human聲音與最終接受pending。沒有自行啟動真登入、browser、Keychain或變更使用者設定。

## root基線失敗證據

compiler診斷：`FakePATSecurity` 不符合 `GitHubOAuthSecurityClient`；protocol要求 `delete(_ query: [CFString: Any]) -> OSStatus`，既有fake未提供。`git show 1f31b35:<path>` 與工作區逐bytes比較為相同，GitHubIntegration來源／tests與Package無本topic diff。

| 基線檔 | 與base比較 | SHA-256 |
| --- | --- | --- |
| `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift` | identical | `5464aa6927ce945f13d29ae3fe442244b7d06d47084a2c4ae205d61c608c728d` |
| `Tests/GitHubIntegrationTests/GitHubPATDataProtectionStoreTests.swift` | identical | `2b06626eb0201ceefae0f2671a08f9c9e1983803f8a3a8471c51b203cfb017d4` |
| `Package.swift` | identical | `fa4132032dbb0561189857b43c6fc55b29b13dc6b406ee527e2fdbf53ff33ffe` |

這是未改來源的有界證據，不是已親跑另一整份clean baseline suite；交獨立Tester／Reviewer判斷，未擴scope修認證測試。

## 外部focused manifest與parity

使用repository外topic scratch，四組source／test目錄以symlink直接指向本feature，保持原相對布局。Swift tools6.0、Swift language mode6、macOS15、package／target名稱、dependencies與Presentation Resources.process規則與正式manifest對應；沒有新增compiler flags或替代正式source。只隔離無關target／Apollo，不宣稱驗證root integration。

```swift
// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "Rivet", platforms: [.macOS(.v15)], targets: [
  .target(name: "RivetPresentation", path: "Sources/Presentation", resources: [.process("Resources")]),
  .target(name: "RivetLoginDemoRuntime", dependencies: ["RivetPresentation"], path: "experiments/E011/Sources/RivetLoginDemoRuntime"),
  .testTarget(name: "RivetPresentationTests", dependencies: ["RivetPresentation"], path: "Tests/RivetPresentationTests"),
  .testTarget(name: "RivetLoginDemoRuntimeTests", dependencies: ["RivetLoginDemoRuntime", "RivetPresentation"], path: "experiments/E011/Tests/RivetLoginDemoRuntimeTests"),
], swiftLanguageModes: [.v6])

```

重現：以 `$FEATURE_ROOT` 指feature checkout、`$FOCUSED` 指repository外scratch，建立與上述path相同的symlink至feature同名目錄，再執行 `swift test --package-path "$FOCUSED"`。正式 root Demo build仍另跑。下表可供Tester核對來源bytes，後續修正須更新證據。

| 正式來源／測試 | SHA-256 |
| --- | --- |
| `Sources/Presentation/Login/LoginMethodSelection.swift` | `17829627a157ac2347f3e89da817786458d19100dcc0fc7ee267b90f8e3ee9d3` |
| `Sources/Presentation/Login/LoginOAuthSection.swift` | `1ad81b7b81ad5b601b89814a21d6a10660f797c8be9078a38b6ad904757b2d0c` |
| `Sources/Presentation/Login/LoginPATForm.swift` | `56014bc66bf15f7bef880ea01950de25d98f2c5e5f2403b2263a386aead97b1a` |
| `Sources/Presentation/Login/LoginStatusNotice.swift` | `99c015fb5ba77f26dbbd813d27547e7082098044838e7fe7d20ead3e7d0199dd` |
| `Sources/Presentation/Login/LoginStyles.swift` | `8b3712069cbc98bc3b8a47527690281c0fb457623de362bebcaf847f95359aec` |
| `Sources/Presentation/Login/RivetLoginArtwork.swift` | `fc3ddf512ec076c89e7c97f6c0a11c856ca28f2b326188e1623b184416d9ab03` |
| `Sources/Presentation/Login/RivetLoginContent.swift` | `75692aa1c6edf4c2d3feee5328a93180c11441c72ddd7b3f972a8d9aaf6f60f4` |
| `Sources/Presentation/Login/RivetLoginPresentation.swift` | `aa6d55000cae1960ef75a546137e30d182c891b2f1b2b00af3d0ec076979b493` |
| `Sources/Presentation/Login/RivetLoginView+Previews.swift` | `c94201b639acd437e0bb60cc17778128caa00db9d9a7685b3123c01bcda06580` |
| `Sources/Presentation/Login/RivetLoginView.swift` | `838db5a5c01764156c4178f4b6dccfe78054004d5483f662db40d931c84f574c` |
| `Tests/RivetPresentationTests/RivetLoginContentTests.swift` | `e0b77d4b782a7f820b5824733cc95fb5a23bb5450b76e5288aa750e8a299177e` |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoHost.swift` | `59de88fb03df7c7aea4da6521af3fd13313ce5d5d97d1eb177f5ef1b34545408` |
| `experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift` | `72c8476021f4e7bc76b96f5aff84e8d9a66b8e070b6ef4a764c4d4db2d19713f` |

## 工具與交接

- Graphify：標準graph不存在，依既有契約採targeted source fallback，未extract／install／refresh／呼provider。
- PR Lens：主流程在真實commit diff後製作local map，本I01不產假map。
- Archify：原v1不改；初稿frozenbytes保留外部scratch，現行r1一次視覺修正後通過，人工圖面實看與Human產品UI接受分開。
- 下一步T01獨立Tester：重建／核對focusedmanifest、root基線缺陷、正式Demo build、scopedformat/lint、Native PAT identity/reset／callbacks／focus／字級矩陣、圖hash與視覺。TC06留Human，無需為此阻擋已授權Draft；其他未驗結果如實分類。
- 採用紀錄仍保守分列新版互動／接線的部分採用，待獨立行為證據續記，不把實作檔案存在當完成。
