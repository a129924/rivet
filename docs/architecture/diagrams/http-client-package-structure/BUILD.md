# 重建 HTTP Client package 結構圖

此 artifact 的交付流程固定為 validate → build → enhance → verify。不可只執行 architecture-canvas 的 build，否則會覆寫 `lang="zh-Hant"` 與可近用性增強。

在此目錄設定 `CANVAS_SKILL` 為 architecture-canvas skill 根目錄，然後執行：

```sh
set -e
RAW_DIR="$(mktemp -d)"
node "$CANVAS_SKILL/scripts/validate.js" scene.js
node "$CANVAS_SKILL/scripts/build.js" \
  --scene scene.js \
  --out "$RAW_DIR/index.html" \
  --title "RivetHTTPClient — 預定 package 結構" \
  --kicker "RIVETHTTPCLIENT — DECLARATION-ONLY" \
  --sub "<b>HTTPClient</b> → <b>Requester</b> → <b>Transport</b> → <b>Foundation</b>；<b>HTTPClient</b> → <b>TokenProvider</b>" \
  --slug http-client-package-structure
node enhance-accessibility.js \
  --input "$RAW_DIR/index.html" \
  --output index.html \
  --label "HTTP Client package 結構"
node verify-accessibility.js --input index.html
```

`scene.js` 是圖表資料的唯一真相；enhancer 從 runtime scene 資料生成文字替代內容，verifier 檢查交付的可近用性約束。
