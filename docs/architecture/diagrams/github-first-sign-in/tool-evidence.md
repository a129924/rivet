# 工具證據

Graphify 0.9.73：本次以 GRAPHIFY_NO_AUTO_REFRESH=1 核對pin；未找到現存可用圖，沿用targeted rg/source fallback。未extract/build/install/provider，未假稱graph coverage。

Archify v3：本次validate/deliver showcase九checks、零errors/warnings；receipt記spec／artifact SHA，路徑已正規化為repository-relative。visual-check四viewport及四截圖通過，Implementer實看見visual-review.md。舊v1/v2已frozen並原樣保留。

Architecture canvas v2：新scene-v2.js與index-v2.html標示獨立驗證App／正式OAuth能力／產品UI未交付；validate/build零errors/warnings。互動視覺沿用已知policy限制，Human pending，沒有嘗試繞過。

PR Lens 0.11.0：提交後依原PR真base/head diff在外部topic scratch產生並validate/render；保留unchanged OAuth/runtime鄰居與file refs、walkthrough。實際provenance與結果在原Draft PR及交付回報；不建立repo .pr-lens、不上傳附件、不代替Reviewer。基線e63eeb2的舊map僅代表當時diff。

## 2026-10-21 現行 canvas Human 互動驗收

來源 `d11f3438cbb0aefcbf4df961566db2849aaf0a60`，文件連結的 `index-v2.html`（scene-v2.js），圖檔未修改。Human自行開啟後逐步明示：文字/箭頭、流程與責任邊界通過；拖曳平移正常；縮放正常且文字/箭頭可讀；點選聚焦與說明正常；明暗切換正常且兩種主題皆可讀。此為Human實際觀察，不是agent重開瀏覽器或自動截圖的實看證據。先前browser file-URL policy限制與當時pending歷史保留，沒有alternate browser/server/rawCDP繞過。現行canvas人工互動項目passed；不因此表示反向PKCE或遠端refresh/401通過。
