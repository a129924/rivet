# HTTP Client package baseline：技術規格

## Package Skeleton

`packages/RivetHTTPClient/Package.swift` 僅宣告 package name、`macOS(.v15)`、Swift language mode 6 與 tools version 6.0。它不得宣告 products、targets 或 dependencies。

`packages/RivetHTTPClient/Sources/.gitkeep` 與 `packages/RivetHTTPClient/Tests/.gitkeep` 必須是空檔案。它們只固定日後 source 與 test 的位置，不表示 module、target 或 API 已存在。

根 `Package.swift` 維持不變：沒有可 export 的子 package product 前，不宣告未使用的 local dependency。

## Architecture Writeback

GitHub Integration 文件只可新增此 skeleton 的邊界事實：`RivetHTTPClient` 是此 Supporting BC Adapter 未來可採用的內部 transport foundation；它不是新 BC，也不將外部 HTTP、token 或 infrastructure failure 暴露給 PR Inbox 或 PR Reader。

新增兩個 architecture-canvas artifacts：

- `github-integration-http-client-boundary` 表達核心 Port、GitHub Adapter、預定 package、TokenProvider implementation boundary、Foundation URLSession 與 GitHub API。
- `http-client-package-structure` 表達預定 `HTTPClient → Requester → Transport → URLSession` dependency direction，及 TokenProvider、Endpoint、Request、Response contracts。

虛線代表尚未實作的 Rivet abstraction；實線代表已存在的 repository artifact、Foundation 或外部 surface。Adapter implementation 必須指向核心 Port 或 package contract，不能反向；scene 不得將構想畫成已實作 API，且不得表達 runtime sequence、回傳資料流、錯誤種類、重試或 token refresh policy。Foundation 型別屬於 Outside plane；package manifest 是已存在 artifact，不得標為未實作 abstraction；Adapter 的具體內部 DTO 與 failure mapping 切分仍屬延後決策。package 結構圖不得指定 TokenProvider 的實作者；其實作邊界只由 Integration boundary canvas 表達。

每個 diagram folder 必須有 artifact-local `BUILD.md`、enhancer 與 verifier。`BUILD.md` 固定以 `set -e` fail-fast，並記錄 validate → build → enhance → verify 的完整指令、metadata 與 accessible label；不得只執行原始 build 而覆寫已交付的可近用性增強。scene 的 strapline 顏色必須使用其 `PLANES` 對應的 `planeColor(...)`，不得引用 template 未宣告的 palette key。enhancer 從 generated canvas 的 runtime `BOXES`／`EDGES`／`TEXTS` 產生正常文件流中的中文文字替代內容，讓鍵盤與螢幕閱讀器取得相同節點、關係與圖表註記；不得手抄第二份圖資料。fallback 必須位於操作提示下方，避免遮蔽互動說明。canvas 快捷鍵只能在可聚焦的 stage 處理，不得攔截 fallback 或工具列的 keyboard interaction；artifact-local hint、toolbar title 與 accessible name 必須使用繁體中文。verifier 必須確認 `zh-Hant`、可聚焦 region、canvas 對輔助技術隱藏、文字 fallback、runtime scene generation、stage-only keyboard handling 與繁中操作介面。

## Written

- 本 topic 的四份 artifacts。
- 子 package manifest、`Sources/.gitkeep`、`Tests/.gitkeep`。
- 兩個 diagram folder 的 `scene.js`、generated `index.html`、`BUILD.md`、`enhance-accessibility.js` 與 `verify-accessibility.js`。

## Modify

- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/github-integration.md`

## Deleted

無。

## Validation

- 以相容 Swift 6 toolchain 執行 `swift package dump-package --package-path packages/RivetHTTPClient`。
- 確認子 package 不含 `.swift`、product、target 或 dependency，並確認根 `Package.swift` 沒有 diff。
- 各 canvas 先以 architecture-canvas validate，再 build `index.html`；檢查 `lang="zh-Hant"`、繁體中文作者內容與宣告式邊界。
