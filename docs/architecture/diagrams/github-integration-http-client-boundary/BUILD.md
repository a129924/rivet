# 重建 GitHub Integration 與 HTTP Client 邊界圖

此 artifact 的交付流程固定為 validate → build → enhance → verify。不可只執行 architecture-canvas 的 build，否則會覆寫 `lang="zh-Hant"` 與可近用性增強。

在此目錄設定 `CANVAS_SKILL` 為 architecture-canvas skill 根目錄，然後執行：

```sh
set -e
RAW_DIR="$(mktemp -d)"
node "$CANVAS_SKILL/scripts/validate.js" scene.js
node "$CANVAS_SKILL/scripts/build.js" \
  --scene scene.js \
  --out "$RAW_DIR/index.html" \
  --title "Rivet — GitHub Integration 與 HTTP Client 邊界" \
  --kicker "RIVET — GITHUB INTEGRATION BOUNDARY" \
  --sub "<b>Integration Adapter</b> 符合 <b>核心 Port</b>，並依賴 <b>預定 transport foundation</b>" \
  --slug github-integration-http-client-boundary
node enhance-accessibility.js \
  --input "$RAW_DIR/index.html" \
  --output index.html \
  --label "GitHub Integration 與 HTTP Client 邊界"
node verify-accessibility.js --input index.html
```

`scene.js` 是圖表資料的唯一真相；enhancer 從 runtime scene 資料生成文字替代內容，verifier 檢查交付的可近用性約束。
