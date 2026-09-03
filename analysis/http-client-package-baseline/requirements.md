# HTTP Client package baseline：需求

## Goal

建立可由 Git 追蹤、但不含 Swift 行為的 `RivetHTTPClient` monorepo package skeleton，並鎖定其在 GitHub Integration Adapter 下的責任邊界與預定結構。

## Non-Goal

- 不建立 Swift product、target、module、source、tests 或公開 API。
- 不將子 package 接入根 `Package.swift`。
- 不實作 URLSession、HTTPClient、Requester、Transport、TokenProvider、OAuth、Keychain、DTO mapping、retry 或 failure mapping。
- 不新增 Bounded Context，或修改 PR Inbox、PR Reader、既有 BC Map 與 WebView diff pipeline。

## In-Scope

- 建立本 topic 的 analysis 與 plan artifacts。
- 建立 `packages/RivetHTTPClient/` 的 manifest 與 `Sources/`、`Tests/` 空白 skeleton。
- 新增 GitHub Integration 邊界圖與 HTTP Client package 結構圖。
- 回寫 GitHub Integration 文件與架構導覽，使長期文件可定位這兩張圖。

## Out-Of-Scope

- 根 SwiftPM dependency、target 或 product。
- 任何 `.swift`、外部 dependency、lockfile 或執行期 request flow。
- 發布 architecture artifact、commit 後的 merge 或 release。

## Acceptance Criteria

- 子 package 只有 Swift 6／macOS 15 manifest 與兩個空白 `.gitkeep`，沒有 product、target、dependency 或 `.swift` 檔案。
- 根 `Package.swift` 不變。
- GitHub Integration 文件明確表示 package 是 Adapter 的預定 transport foundation，而非新的 BC；HTTP、token 與 infrastructure failure 不可穿越核心 BC Port。
- 兩張 architecture-canvas 圖以繁體中文表達 declaration-only ownership 與 compile-time boundary；不敘述 runtime request flow。
