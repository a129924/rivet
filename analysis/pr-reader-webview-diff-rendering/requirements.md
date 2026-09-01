# PR Reader WebView Diff Rendering — Requirements

## Goal

定義 Swift 向 PR Reader WebView 提供檔案 diff 快照，以及 TypeScript 對該快照進行後續處理所需的穩定介面契約。此 topic 只建立 TypeScript 型別與 interface declarations，為零依賴的後續實作切片提供邊界。

## In-Scope

- 定義 `DiffViewModel`、檔案狀態、viewed-state 變更與公開結果型別。
- 定義 `Validator → Parser → Renderer → Output` 的 stage-specific result unions 與 opaque 中間資料。
- 定義 `Adapter ↔ Port → UseCase → Facade` 的 Port、UseCase 與 Facade 方法簽名。
- 定義 `viewed` 的 ownership、通知時機與 WebView 本地暫態狀態邊界。
- 對介面進行 strict TypeScript type-level tests 與既有檢查。

## Out-Of-Scope

- 具體 validator、parser、renderer、RenderPlan schema、DOM、UI、collapse、syntax highlighting 或 raw diff 格式解析。
- Swift bridge、Swift target、GitHub REST／GraphQL mapping、viewed-state 持久化或 acknowledgement。
- 新增套件、package manifest 或 lockfile 變更。
- PR Reader Bounded Context、架構文件或其他產品行為的變更。

## Success Criteria

- Swift 可提供一個完整、有序的 `readonly DiffViewModel[]` snapshot；TS 公開入口與相鄰 stages 的型別相容性可由 typecheck 驗證。
- Snapshot 可表達檔案路徑、rename、變更類型、可選 patch、增刪計數與 viewed 狀態。
- `present` 僅回傳既定 success／error outcome；viewed 變更為單向、非同步的通知，不等待 acknowledgement。
- 介面保持零依賴，且不偷渡任何具體 rendering 或 transport 決策。

## Non-Goals

- 不以此 topic 定義 GitHub-like 視覺、紅綠行、檔案 header、錯誤畫面或任何瀏覽器副作用。
- 不將 `viewed` 的 WebView 本地 collapse 偏好當作 Swift snapshot 的一部分。
