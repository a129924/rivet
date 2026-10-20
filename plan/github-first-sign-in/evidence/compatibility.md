# 獨立建置與相容性驗證

> 歷史來源：基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22` 的舊 host／當時 dirty source；以下原始結果保留。舊「正式 app」說法不代表產品 UI 已交付，不冒充搬後驗證 App 重驗；本次結果見 [verification-host-amendment.md](verification-host-amendment.md)。

2026-10-20，Tester；僅在本 topic feature worktree 執行，未更改產品原始碼、commit、push 或操作既有 live app。

- Branch：`feat/github-first-sign-in`；source base HEAD：`16606b89b8e3e6b61523c23aa0be9653c1ea7b44`。
- 驗證對象為 dirty source，並非此 HEAD 已包含新能力。tracked binary patch SHA-256：`0e151f14e58b6b19d47bf8ecbf94f578b87244509123ecb3a4a65c631fdcd12c`（不涵蓋 untracked）；完整 changed/new source/project/test 指紋見 contracts.md。

| 親跑命令 | 結果 |
|---|---|
| `swift test` | exit 0；276 tests、35 suites passed |
| `scripts/check-github-integration-consumer.sh` | exit 0；13 tests、3 suites passed |
| `scripts/check-swift-format.sh` | exit 0 |
| `scripts/check-swiftlint.sh` | 最終 exit 0；130 files、0 violations |
| `swift format lint --strict --recursive apps/Rivet/Sources apps/Rivet/Tests` | exit 0 |
| `swiftlint lint --strict apps/Rivet/Sources apps/Rivet/Tests` | exit 0；9 files、0 violations |
| `xcodebuild -project apps/Rivet/Rivet.xcodeproj -scheme Rivet -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/VerificationDerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build test` | exit 0；TEST SUCCEEDED；8 tests、4 suites passed（R1最終重驗；先前為7） |

測試前首次 sandbox 嘗試寫 feature build logs 受限，未啟動該批測試；依既有授權以 require_escalated 重跑成功。Lint 首次發現新 session test opening_brace，交 Implementer 修正後重跑；其後 SwiftLint cache 寫入受限造成非零結束碼，提升權限重跑才列最終 pass。未修改工具設定或安裝套件。

Root/consumer/app 測試 logs 位於 ignored `.build/github-first-sign-in/tester-*.log`，不加入版控；最終 lint logs 位於外部 topic scratch。測試未印入真實配置或 callback。

## Warnings

Consumer build 出現既有 `JSONSemanticDecodingError.kind` 的 `Kind` 非 Sendable warning；該 HTTPClient 檔案與本 topic diff 相比未修改。Xcode 報 AppIntents metadata extraction skipped（無 framework dependency），及已簽署 XCTest support binaries 不 strip；未造成 build/test 失敗。本次未另改 baseline warnings。

## 範圍與限制

獨立 DerivedData 不覆寫目前 Human live app。Hosted tests 使用 `RIVET_UNIT_TEST_MODE=1`；偽依賴測試驗證啟動零 authorize/prepare、重複查詢及同 provider prepare retry，未使用真實 OAuth App secret。測試通過不等於 Human acceptance 或獨立 Reviewer approved。

## R1 最終 app 重驗

Reviewer required fix 為一個 app test 檔新增真 provider gated refresh settlement case；產品source未改。Tester 親跑相同 xcodebuild 命令，完整8 tests／4 suites passed、exit0、TEST SUCCEEDED；app兩個strict checks均exit0，SwiftLint9files零違規。外部 logs：`/private/tmp/rivet-first-sign-in-r1-tester.log`與`/private/tmp/rivet-first-sign-in-r1-tester-lint.log`。最終 source/project/test dirty fingerprint：`6b5aba527e080c9d65ab7481abf9a17f3a98b8906d8da5e8b324cc249cceec13`。Root/consumer非受影響範圍，沿用原獨立結果。

本輪 hosted app 的系統 log 另出現 `com.apple.linkd.autoShortcut` connection 4097 提示；測試仍通過，未將系統服務訊息當產品OAuth失敗，也未擴大修改。
