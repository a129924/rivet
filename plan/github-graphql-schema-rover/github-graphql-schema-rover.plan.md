# GitHub GraphQL Schema Rover — Implementation Plan

## Goal

以 Homebrew 將 Apollo Rover 加入 Rivet 的開發工具鏈。

## In-Scope

- 建立本 topic 的四份正式 artifacts。
- 在根目錄 Brewfile 宣告 `rover`。
- 記錄 Rover 的安裝方式與非 runtime 用途。

## Out-Of-Scope

- SwiftPM、Bun、runtime、lockfile、CI、schema 快照、下載腳本與 token 管理。

## File Impact

- 新增 `Brewfile` 與本 topic 四份 artifacts。
- 修改 `docs/toolchain.md`。

## Test Cases

- `brew bundle check` 在已安裝依賴的環境確認 Brewfile。
- `rover --version` 可執行。
- 審閱 diff，確認未變更 runtime manifest、lockfile 或產品程式碼。
