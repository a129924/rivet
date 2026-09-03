# HTTP Client package baseline

## Goal

建立不含 Swift 實作的 `RivetHTTPClient` monorepo skeleton，鎖定它在 GitHub Integration Adapter 下的責任邊界與預定結構。

## Non-Goal

不建立 Swift module product、target、HTTP API、local package dependency、URLSession 行為、TokenProvider 實作、OAuth／Keychain、DTO mapping 或 retry policy。

## In-Scope

- 建立 `http-client-package-baseline` 的四份 analysis／plan topic artifacts。
- 建立 `packages/RivetHTTPClient/` 的 manifest 與 `.gitkeep` skeleton。
- 以兩張 architecture-canvas 圖表達 Integration 邊界與 HTTP Client 預定結構。
- 回寫 GitHub Integration 與架構導覽文件。

## Out-Of-Scope

- 根 `Package.swift` 的 dependency 或 target 變更。
- 任何 `.swift` source、test、product、target 或第三方套件。
- 修改既有 PR Inbox、PR Reader、WebView diff pipeline 或全域 BC Map。
- 發布 architecture artifact。

## ReadOnly

- `AGENTS.md`、`README.md`、設計原則與根 `Package.swift`。
- `architecture-canvas` 的 scene format、驗證與建置規則。

## Written

- `analysis/http-client-package-baseline/` 下的 `requirements.md`、`technical-spec.md`。
- `plan/http-client-package-baseline/` 下的 `.plan.md`、`.step.md`。
- `packages/RivetHTTPClient/Package.swift`、`Sources/.gitkeep`、`Tests/.gitkeep`。
- 兩個新 canvas artifact 的 `scene.js`、generated `index.html`、artifact-local `BUILD.md` 與 diagram-local accessibility enhancer／verifier。

## Modify

- `docs/architecture/README.md`：加入兩張 HTTP Client architecture canvas 的導覽。
- `docs/architecture/bounded-contexts/github-integration.md`：記錄 package 是 Integration Adapter 的 transport foundation、不是新 BC，且不跨越核心 BC failure boundary。

## Deleted

無。

## Implementation

- 子 package manifest 採 Swift 6／macOS 15 baseline，暫不宣告 product、target 或 dependency。
- `Sources/` 與 `Tests/` 只保留 `.gitkeep`，不得加入任何 `.swift` 檔。
- 根 package 維持不變；待後續 implementation topic 建立 module product 後，才加入 local path dependency。
- Integration boundary canvas 呈現核心 BC Port、GitHub Adapter、預定 `RivetHTTPClient`、TokenProvider implementation boundary、URLSession 與 GitHub API。
- HTTP Client canvas 僅呈現預定的 `HTTPClient → Requester → Transport → URLSession` 編譯期依賴，以及 TokenProvider、endpoint、request／response contract；所有內容標示為 declaration-only，非既有 API。
- 具體 failure mapper 與 TokenProvider 實作者均屬後續實作決策；package 結構圖不得指定任一實作者，TokenProvider 實作邊界只在 Integration boundary canvas 表達。
- 兩張圖以 `scene.js` 為唯一真相，使用繁體中文與 `lang="zh-Hant"`；不以箭頭或文字描述 runtime request flow。
- 每張圖以 diagram-local enhancer／verifier 從 runtime `BOXES`／`EDGES`／`TEXTS` 產生可鍵盤巡覽的文字替代內容與圖表註記；不得維護第二份圖資料，且 fallback 不得遮蔽操作提示。
- 每張圖的 artifact-local `BUILD.md` 以 `set -e` 固定記錄 validate → build → enhance → verify 與 metadata／accessible label；不得只重建原始 HTML 而遺失可近用性增強，或在驗證失敗後繼續交付舊產物。
- strapline 的文字 runs 必須使用對應責任 plane 的 `planeColor(...)`，不得依賴 template 未宣告的 palette key。

## TestCase

- TC-01：四份 topic artifacts 均存在，且內容與此 scope 一致。
- TC-02：子 package manifest 可由相容的 Swift 6 toolchain 解析，且沒有 product、target、外部 dependency。
- TC-03：package skeleton 僅含 manifest 與 `.gitkeep`，不存在 `.swift` source 或 test。
- TC-04：根 `Package.swift` 沒有新增 local dependency、target 或 product。
- TC-05：GitHub Integration 文件明確保留 HTTP、token 與 infrastructure failure 在 Adapter 邊界。
- TC-06：兩張 canvas 各自通過 architecture-canvas validate 與 build，視覺檢查無溢位或碰撞，且不宣稱已有實作。
- TC-07：兩份 HTML 的文字替代內容與圖表註記由 runtime `BOXES`／`EDGES`／`TEXTS` 生成，並通過 diagram-local accessibility verifier 與重建一致性檢查。
- TC-08：canvas 快捷鍵僅在可聚焦 stage 處理；fallback 與工具列可使用原生鍵盤操作，且 artifact-local 操作介面與 accessible names 為繁體中文。
- TC-09：每個 diagram folder 的 `BUILD.md` 都記錄可重現的 validate → build → enhance → verify 流程與固定 label，且產出的 HTML 通過 accessibility verifier。
- TC-10：每個 `BUILD.md` 均以 `set -e` fail-fast；兩個 scene 的 strapline 都只使用對應 plane 的顏色，無 template 未宣告的 palette key。

## Assumptions

- package 名稱固定為 `RivetHTTPClient`。
- 兩張圖中的 HTTPClient、Requester、Transport、TokenProvider 與資料 contracts 都是未來實作意圖。
- manifest 驗證使用 task-specific temporary module cache，不變更 Xcode selection 或 repository 設定。
