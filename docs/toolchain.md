# Rivet 開發工具鏈

## Baseline

- Xcode 26.6（內建 Apple Swift 6.3）
- Swift language mode 6，Swift Package tools version 6.0
- Node.js 24.19.0 LTS

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

專案根目錄的 `.node-version` 固定 Node 24.19.0，供未來的文件工具與前端 surface 使用。此 baseline repository 目前沒有 Node package、依賴鎖檔或可執行的 renderer。

使用 NVM 的相容性工作流程時，可執行：

```sh
nvm use
```

Node 版本在開始第一個需要它的 bounded context 或 surface 前再鎖定 package manager 與依賴。
