# Rivet 開發工具鏈

## Baseline

- Xcode 26.6（內建 Apple Swift 6.3）
- Swift language mode 6，Swift Package tools version 6.0
- Node.js 24.19.0 LTS
- Bun 1.4.0（PR Reader WebView 的 package manager 與 test runner）
- pre-commit 4.6.2（Git hook runner）
- SwiftLint 0.65.1（Swift lint）
- Rover（GitHub GraphQL schema introspection 開發工具）

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

## 日常品質檢查

全域工具：Bun、pre-commit、SwiftLint 與 Rover。Swift formatter 使用 Xcode toolchain 內建的 `swift format`，不另外安裝 formatter。

Xcode toolchain 內建的 Swift formatter（`swift format`）是 trailing-comma 格式的唯一權威。SwiftLint 的 `trailing_comma` rule 已停用，避免兩個工具對 multiline collection literal 的結尾逗號提出相互衝突的要求。

## GitHub GraphQL Schema Research

根目錄的 `Brewfile` 宣告 Apollo Rover。執行 `brew bundle` 安裝後，以 `rover --version` 確認工具可用。

Rover 僅供開發者以自己的 GitHub token 對 GitHub GraphQL API 做 introspection、取得 schema 時使用；它不是 Rivet 的 runtime dependency，不加入 SwiftPM、Bun 或產品執行流程。

PR Reader WebView 的 TypeScript 與 Biome 是 local dev dependencies；安裝與執行都使用 Bun：

```sh
cd surfaces/pr-reader-webview
bun install --frozen-lockfile
bun run format
bun run format:check
bun run lint
bun run typecheck
bun run check
```

Swift CLI 檢查：

```sh
scripts/check-swift-format.sh
swiftlint lint --strict
swift test
```

`.pre-commit-config.yaml` 會執行 whitespace、Swift format、SwiftLint 與 renderer `bun run check`；coverage 不放入 pre-commit。

## Coverage

Coverage 使用內建工具，不加入第三方 coverage package。

- Swift：`scripts/check-swift-coverage.sh` 執行 SwiftPM coverage，並要求至少 90% line coverage。
- TypeScript：`cd surfaces/pr-reader-webview && bun run test:coverage`，輸出 text 與 `coverage/lcov.info`，並要求 line、function、statement coverage 都至少 90%。
- 全部執行：`scripts/coverage.sh`。

Swift coverage 只能在完整 Xcode 選取後執行；coverage 不放入 pre-commit。
