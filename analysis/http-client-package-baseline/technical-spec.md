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

兩圖的虛線都代表 Rivet 擁有、尚未實作的抽象；實線代表可替換的 Foundation／外部 surface。Adapter implementation 必須指向核心 Port 或 package contract，不能反向；scene 不得將構想畫成已實作 API，且不得表達 runtime sequence、回傳資料流、錯誤種類、重試或 token refresh policy。

每個 diagram folder 必須有 artifact-local enhancer 與 verifier。enhancer 從 generated canvas 的 runtime `BOXES`／`EDGES` 產生正常文件流中的中文文字替代內容，讓鍵盤與螢幕閱讀器取得相同節點與關係；不得手抄第二份 node／edge 資料。verifier 必須確認 `zh-Hant`、可聚焦 region、canvas 對輔助技術隱藏、文字 fallback 與 runtime scene generation。

## Written

- 本 topic 的四份 artifacts。
- 子 package manifest、`Sources/.gitkeep`、`Tests/.gitkeep`。
- 兩個 diagram folder 的 `scene.js`、generated `index.html`、`enhance-accessibility.js` 與 `verify-accessibility.js`。

## Modify

- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/github-integration.md`

## Deleted

無。

## Validation

- 以相容 Swift 6 toolchain 執行 `swift package dump-package --package-path packages/RivetHTTPClient`。
- 確認子 package 不含 `.swift`、product、target 或 dependency，並確認根 `Package.swift` 沒有 diff。
- 各 canvas 先以 architecture-canvas validate，再 build `index.html`；檢查 `lang="zh-Hant"`、繁體中文作者內容與宣告式邊界。
