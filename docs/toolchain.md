# Rivet 開發工具鏈

## Baseline

- Xcode 26.6（內建 Apple Swift 6.3）
- Swift language mode 6，Swift Package tools version 6.0
- Node.js 24.19.0 LTS
- Bun 1.4.0（PR Reader WebView 的 package manager 與 test runner）

## Apple 工具鏈初始化

完整 Xcode 必須安裝在 `/Applications/Xcode.app`，不能只安裝 Command Line Tools。完成安裝後，在互動式終端機執行：

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
swift --version
```

前兩個命令會要求 macOS 管理員密碼。預期版本為 Xcode 26.6 與 Apple Swift 6.3。

## Node 基線

專案根目錄的 `.node-version` 固定 Node 24.19.0，作為相容性後備。PR Reader WebView 使用 Bun，位於 `surfaces/pr-reader-webview`。

使用 NVM 的相容性工作流程時，可執行：

```sh
nvm use
```

## Coverage

Coverage 使用內建工具，不加入第三方 coverage package。

- Swift：`scripts/check-swift-coverage.sh` 執行 SwiftPM coverage，並要求至少 90% line coverage。
- TypeScript：`cd surfaces/pr-reader-webview && bun run test:coverage`，輸出 text 與 `coverage/lcov.info`，並要求 line、function、statement coverage 都至少 90%。
- 全部執行：`scripts/coverage.sh`。

Swift coverage 只能在完整 Xcode 選取後執行；coverage 不放入 pre-commit。
