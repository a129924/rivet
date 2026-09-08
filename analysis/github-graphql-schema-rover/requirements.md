# GitHub GraphQL Schema Rover — Requirements

## Goal

將 Apollo Rover 登錄為 Rivet 的開發工具，供以 GitHub token 對 GitHub GraphQL API 執行 introspection 並取得 GraphQL schema 時使用。

## In-Scope

- 以 Homebrew Brewfile 宣告 `rover` formula。
- 在開發工具鏈文件說明安裝與用途。

## Out-Of-Scope

- SwiftPM、Bun、runtime、lockfile、CI 或產品程式碼依賴。
- schema 下載腳本、schema 快照、token 管理或 GitHub Integration 實作。

## Success Criteria

- `brew bundle` 可安裝 Rover，並可用 `rover --version` 確認。
- 文件清楚說明 Rover 僅供開發期 GitHub GraphQL schema 研究，不是 Rivet runtime dependency。
