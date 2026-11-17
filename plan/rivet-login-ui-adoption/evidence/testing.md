# T01：獨立驗證結果與 native coverage 缺口

- 日期：2026-11-17；owner=Tester；topic `rivet-login-ui-adoption`。
- Branch：`feat/rivet-login-ui-adoption`；base `1f31b35604adb5bb36326e52f9d6dbcff0cac763`；受測為本 feature 尚未 commit 的工作區，不虛構新 SHA。
- 本輪驗證結果：**INCOMPLETE coverage**。已完成有界測試與診斷，未取得 native control 操作證據，不給 code correctness approval；交 R01 Reviewer 分類缺口及其交付影響。
- 未修改 production、既有測試、Package 或 planning contract；只新增此 evidence 並更新 T01 帳本。沒有 stage／commit／push。

## 親自執行的檢查

| 檢查 | 實際結果 | 支持範圍與限制 |
| --- | --- | --- |
| 獨立 focused `swift test --package-path "$TEST_SCRATCH"` | exit 0；32 tests／7 suites pass | 實際 public content／initializer、PAT helper、Presentation 及 E011 model；不當作 SwiftUI control 互動證據 |
| root `swift test --skip-update --disable-automatic-resolution` | exit 1；編譯 GitHubIntegrationTests 失敗，tests 未全執行 | `FakePATSecurity` 不符合 `GitHubOAuthSecurityClient`，缺 `delete(_:)`；不是 assertion failure，不稱 root suite pass |
| root `swift build --skip-update --disable-automatic-resolution --product RivetLoginDemo` | exit 0；0.76s | 正式 root manifest 的 Demo product 可建置；deprecated skip-update warning 非 build failure |
| scoped `swift format lint --strict` | 無診斷；命令完成 | Login Swift、content tests、受影響 E011 host／tests；未改檔 |
| scoped `swiftlint lint --strict --no-cache` | 13 files，0 violations／0 serious | 不是全 repository lint 結論 |
| `git diff --check` | exit 0 | 本次 tracked diff whitespace 檢查 |
| Archify final r1 `validate lifecycle ... --quality showcase --json` | exit 0；ok=true；9/9 checks；composition 0 errors／0 warnings | 驗證 exact frozen JSON；沒有重新 deliver 或改 HTML |
| 圖 JSON／HTML SHA 與 byte count | 全部符合 committed-candidate receipt | 見下表；自動 visual-check receipt 四尺寸均 ok，`visualReview: pending` 原樣保留 |

上述 format／lint／diff-check 以單一 shell 執行並完成 exit 0，format 無輸出、lint 明列零違規、diff-check 無診斷；沒有偽造分開的 command receipts。

## focused manifest parity 與原始來源

Tester 自行建立 repository 外暫存 manifest，不沿用作者建置產物。四個 source／test 目錄以 symlink 指向本 feature 同名目錄，維持原相對布局，避免 source-location tests 因 scratch 改變而失真。

- package name `Rivet`，tools version 6.0，Swift language mode 6，macOS 15。
- `RivetPresentation` 無認證依賴，resources 使用 `.process("Resources")`。
- `RivetLoginDemoRuntime` 只依賴 `RivetPresentation`。
- `RivetPresentationTests`、`RivetLoginDemoRuntimeTests` target 名稱／dependencies／來源對齊正式 manifest。
- 只隔離無關 BC／Apollo targets；沒有替代正式 source 或增加編譯 flag，不宣稱覆蓋 root integration。
- focused log 最後明列 `Test run with 32 tests in 7 suites passed`。

## root blocker 的獨立有界核對

親跑 compiler 診斷位於 `Tests/GitHubIntegrationTests/GitHubPATDataProtectionStoreTests.swift:339`；protocol requirement 位於 `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift:76`。以 `git show <base>:<path>` 對工作區逐 bytes 比較如下：

| 檔案 | equals base | SHA-256 |
| --- | --- | --- |
| GitHubOAuthDataProtectionStores.swift | true | `5464aa6927ce945f13d29ae3fe442244b7d06d47084a2c4ae205d61c608c728d` |
| GitHubPATDataProtectionStoreTests.swift | true | `2b06626eb0201ceefae0f2671a08f9c9e1983803f8a3a8471c51b203cfb017d4` |
| Package.swift | true | `fa4132032dbb0561189857b43c6fc55b29b13dc6b406ee527e2fdbf53ff33ffe` |

這證明本 topic 未改造成該缺項的來源；沒有另外建立 clean baseline checkout 跑完整 suite，也沒有越界修認證測試。

## Native 驗證：嘗試與實際觀察

### E011 正式 host

依 E011 README 的既有 wrapper 方式，在 Tester 外部 scratch 建立 `.app`，使用 feature `.build/debug/RivetLoginDemo` 與 `Rivet_RivetPresentation.bundle`，bundle ID `local.rivet.login-ui-demo`；沒有改既有 wrapper、signing、設定或 production source。

- 複製當下正式 binary 與 wrapper binary SHA 相同：`7b63a99043763cad44fa48f2089cd39f00e6ea555acc0b6d7621f51fbc7ef669`。
- CUA 初始 inventory 沒有執行中的 RivetLoginDemo；由 exact 本次 wrapper path 啟動。
- CUA inventory 隨後顯示 RivetLoginDemo running，但兩次 `getApp` 均回 `cgWindowNotFound`（server error -10005），未取得 AX tree／screenshot。
- 有界 process 檢查確認 PID `38714` 的 executable 為本次 exact scratch wrapper；`sample` 顯示在 `NSApplication.run` 的正常 event loop，沒有據此推論 UI 已呈現或可操作。
- 沒有輸入 token、點擊任何 Login control、呼叫 browser／GitHub／Keychain。

### 外部最小 public consumer

經 Dispatcher 明確同意，另建只依賴本 feature `RivetPresentation` 的外部 SwiftPM executable，用 fake parent 提供 phase／content／13-17-21 pt／canCreateToken 與相同 root identity 切態；事件計數由 parent 持有。這不是 production hook，沒有實作 request／VO／認證／儲存／session。

- `swift build --product LoginAdoptionProbe`：exit 0，7.98s。
- manifest SHA：`e50067f0ef71d1118825dcad8f74930a2774e536b1f31c41edf7f7f18b9370c2`。
- probe source SHA：`dc9d71a8965527ef286087b71836b32c1a3a4ae68a15b6506307cc760298f783`。
- executable SHA：`5f1b7b8036638161ef96da718cda79167f9202abe610a1b72df040b953894ab5`。
- bundle ID `local.rivet.login-ui-adoption-tester`；public source以 symlink 指向本 feature；此 harness 與 focused test manifest 分開，未改正式 target。
- 最後 `CUA getApp(exact probe wrapper)` 未取得窗口結果，等待 468.7s 後由 Dispatcher 中斷。該次可能部分啟動，結果 **unknown／aborted**，不記 cgWindowNotFound 或 native pass。
- 已依指示停止進一步 native 嘗試，送出 CUA completion summary「已記錄原生視窗讀取限制」。沒有藉其他 UI 工具繞過 CUA。

## 尚未驗證的必要 native 案例

| TestCase | 有證據部分 | 缺口 |
| --- | --- | --- |
| TC01 | public content／舊新 initializer 編譯與 focused tests pass；Demo build pass | 沒有 native control 操作證據 |
| TC02 | helper trim／clear／visibility model tests pass | 實際 PAT form identity（tokenEntry↔token failure）、Show／Hide、字級／copy 更新保留文字、submit 清除、離開／Reset 清除未親驗 |
| TC03 | E011 model event tests pass | native 選擇／Back／Cancel／Escape／Retry／Submit；Create disabled 不發事件、enabled 單次事件且不清輸入未親驗 |
| TC04 | 正式 manifest 的 Presentation 無 GitHubIntegration 依賴；已讀 UI 為 parent phase／callback 組合 | 不把 source／model 證據當 UI runtime 接線已驗；不驗真認證 |
| TC05 | 原生 host 與 public consumer 可建置 | 七態／兩種 failure origin、Light／Dark、780×500、13／17／21 pt 的 native 矩陣、快速離開後 focus／宣告時序皆未親驗 |
| TC06 | 無新版 Human 聲音／UI 接受證據 | Human VoiceOver 聲音、最終 UI 接受維持 pending |
| TC07 | focused pass、Demo build、scoped lint／format／diff check | root 全 suite 因上述既有編譯缺陷未通過 |
| TC08 | content tests排除 demo／session claims；文件保留後續 Adapter 邊界 | VO mapping 的完整實碼審查留 R01，不宣稱本 Tester 已建立 runtime mapper |
| TC09 | exact圖 hash／bytes、showcase9/9；保留四尺寸 containment receipt | Tester 未重新操作圖面 viewer 或人工查看截圖；作者 visual inspection與自動 pending分列，不冒稱獨立視覺接受；PR Lens由主流程處理 |

這些 native gaps 是驗證 coverage 不足，沒有觀測到可定位的產品 assertion／互動 failure。Reviewer 須依契約分類為 required fix、補證據或可揭露限制的 Draft 停點，Tester不自行放行 commit／PR，也不改寫 Human 接受條件。新版互動採用程度仍維持部分採用。

## 圖面獨立核對

| exact candidate | SHA-256 | bytes核對 |
| --- | --- | --- |
| `login-lifecycle-v2-r1.json` | `cbe8f9ddf635ca045a0605af215ff7f9b13fa44132be96c93c1e9890c5056980` | 4216，相同 |
| `login-lifecycle-v2-r1.html` | `03b51e535c45e125b72c3484ef085b36f8f0d36374fe8b9abeb2ae7d4490c340` | 704284，相同 |

自動 receipt 的 1440×900、1600×1000、1920×1080、2048×1320 均 containment ok；artifact hash與上述 HTML一致。只獨立重跑 validate，不重新 deliver／render／修改 frozen bytes。初稿失敗產物未見於當前待提交清單，現行連結指向 r1。

## 暫存與 process 收尾資訊

所有測試 manifest／harness／raw logs 保留在 repository 外 Tester topic scratch，以 `$TEST_SCRATCH` 表示；文件不寫本機絕對路徑。沒有尚未完成的 unified exec session：focused／root／Demo build／probe build／sample 均已收到結束結果。

- 自己啟動且已確認的 E011 PID：`38714`；最後觀察時仍執行本次 wrapper。未在收尾階段再操作或終止 app。
- Probe 最後 CUA 呼叫 aborted；是否仍有 process／tool 背景執行未知，PID 未取得。
- 安全收尾方式：先以 exact 本次 scratch app executable path 核對 PID，再只向核對成功的 PID 發 SIGTERM；不得按共用 bundle ID 或模糊 process name 停止其他 app。未執行此收尾 mutation。

## 交接

`current_step: T01 coverage INCOMPLETE`；`next_step: R01 Reviewer 分類已知 root blocker 與 native gaps`；`status: INCOMPLETE`。無 correctness approval、無 native pass、無 Human 接受聲明。
