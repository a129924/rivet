# Architecture Documentation Baseline — Technical Spec

## Knowledge Model

| 區域 | 責任 | 不承載的內容 |
| --- | --- | --- |
| `docs/` | 已確認且長期有效的產品與架構真相 | 暫時研究、未鎖定推論、實作進度 |
| `analysis/<topic>/` | requirements、選項比較與技術推論 | BC 主責任或已完成的架構真相 |
| `plan/<topic>/` | 受限範圍、artifact path、驗收與執行順序 | 取代 docs 的長期設計說明 |

## Architecture Documentation

- `docs/architecture/README.md` 是 architecture 主題索引，保存跨 BC 不變量。
- `docs/architecture/bounded-contexts/<bc>.md` 是每個 BC 的唯一主文件。
- `docs/architecture/diagrams/<slug>/` 保存互動式圖的作者來源與 HTML artifact。

## Diagram Contract

- `bounded-context-map` 與 `repository-knowledge-map` 使用 `architecture-canvas`：scene.js 為來源，index.html 為建置結果。
- `topic-lifecycle` 使用 `archify` workflow：JSON spec 為來源，index.html 為 deliver 結果。
- 圖的作者內容為繁體中文。所有驗證必須通過；不將 visual-check contact sheet 或暫存驗證輸出加入 Git。

## Agent Routing

根目錄 `AGENTS.md` 只做入口與路由：規定 first-read、文件責任、正式 topic artifact 與圖形 skill 選擇；它不取代設計原則或 BC 文件。
