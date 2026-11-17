# R04：獨立驗證證據

日期：2026-11-17。執行角色：主 agent（未撰寫 runtime 的 Tester）；feature branch `feat/github-dual-login-runtime`，base `1f31b35`，受測為提交前工作樹。

## 已親跑

| 命令 | 結果 |
|---|---|
| `swift test`（最終修正後） | exit 0；358 tests／45 suites passed |
| `scripts/check-swift-format.sh` | exit 0 |
| `scripts/check-swiftlint.sh` | exit 0；155 files、0 violations |
| `scripts/check-github-integration-consumer.sh` | exit 0；19 tests／5 suites passed |
| `swift build --package-path experiments/github-dual-login-runtime` | exit 0；只建置，未執行 binary |
| `git diff --check` | exit 0 |

Consumer／CLI 的獨立執行早於最後 browser closure 的等價 MainActor warning 修正；之後完整 root tests 358 全通過，提交 hook 另列其最終結果。

## 首次完整測試與處置

首次完整測試 358 tests 中只有靜態隔離測試的 3 issues：新增四個 Login source 尚未加入 inventory；relay 的 Network 及 probe 的 RivetHTTPClient imports 尚未逐檔放行。Implementer 僅更新精確 inventory／逐檔例外，沒有 skip 或放寬其他檔案。修正後再次完整執行取得以上通過結果。既有 PAT test fake 缺少 OAuth clearing port requirement 的最小 stub 見 implementation 證據。

## 原始執行紀錄指紋

完整本機 log 置於 repository 外，不納入版本控制。以下 SHA-256 只辨識執行紀錄，不包含憑證指紋。

- final root tests: `12b76e24a1b13501d053ce6688830a30e298c3a75ba15000521d57027543230d`
- consumer: `2c31998b76748854d4125249142ca3a418f03f3746ffaa004ef62863a6f99ef5`
- CLI build: `073cd60442ffe95ebfeda56887114cc29c970cbed6870ffaa3b1644e72d07679`

## 最終 root 測試來源

- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginAccountProbe.swift`：`25e7b6de2b751c3c7e0ebee1cece3ffd971a254f8070323356f356f2aeb523ed`
- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginCallbackRelay.swift`：`f0f95e27263fa9987cf20eb0101e6d30645d748d753f61e0b40d776271c9fda3`
- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginOAuthFlow.swift`：`dc84b708695aac43d2db8b43124ef64cb301286171ec3da06a0bd0ded1d8d6b6`
- `Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginService.swift`：`ebcc235531b278b00e80a6039556b2b62dd7c8958d3bf5d83597153430a7877c`
- `Tests/GitHubIntegrationTests/GitHubLoginAccountProbeTests.swift`：`344d8137f8721a9b980ceaae9e28ab2c1e074b2c84c633ed4845f6acd5b68883`
- `Tests/GitHubIntegrationTests/GitHubLoginCallbackRelayTests.swift`：`35e866219cbd4a7204eb4527d20e6c62e2fef6cb40c4e3023765271bd16b9095`
- `Tests/GitHubIntegrationTests/GitHubLoginOAuthFlowTests.swift`：`0b5c68358803b169e83c9278c2a20b2a1bfa8366b65f4e5efc41c6e79767c12d`
- `Tests/GitHubIntegrationTests/GitHubLoginServiceTests.swift`：`06a02065bb038bfe7da22d7698604d6452c7d5f522d5b745a365712a7cc91c55`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：`983868642bb1c3edeef3a7f773666035641c71cc9ed54b2e72e6bf378e7494d5`
- `Tests/GitHubIntegrationTests/GitHubPATDataProtectionStoreTests.swift`：`29df1616359821bb6ad1e77da9e554680dcf0c36742d2431919d1a2a09712345`

## 限制與停點

TC08／真 OAuth／真 PAT／正式 DPK 往返未執行；沒有讀取真憑證、簽章資產或使用其他 topic 的 live 額度。Archify 與最終獨立 Reviewer 結論另列，不能由本測試結果推定 Human 視覺或最終接受。
