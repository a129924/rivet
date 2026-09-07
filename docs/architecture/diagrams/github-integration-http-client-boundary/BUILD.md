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
  --sub "<b>Integration Adapter</b> 符合 <b>核心 Port</b>，並採用 <b>最小 HTTP interface</b>" \
  --slug github-integration-http-client-boundary
node enhance-accessibility.js \
  --input "$RAW_DIR/index.html" \
  --output index.html \
  --label "GitHub Integration 與 HTTP Client 邊界"
node verify-accessibility.js --input index.html
```

`scene.js` 是圖表資料的唯一真相；enhancer 從 runtime scene 資料生成文字替代內容，verifier 檢查交付的可近用性約束。

## 重建 declaration-only authorization lifecycle

此 artifact 的 source 是 `github-authorization-lifecycle.json`；它與 canvas 的責任邊界不同，只表達 declaration-only lifecycle。設定 `ARCHIFY_SKILL` 為 Archify skill 根目錄，然後依序執行：

```sh
set -e
node "$ARCHIFY_SKILL/bin/archify.mjs" validate lifecycle \
  github-authorization-lifecycle.json --quality showcase --json
node "$ARCHIFY_SKILL/bin/archify.mjs" deliver lifecycle \
  github-authorization-lifecycle.json \
  github-authorization-lifecycle.html --quality showcase --json
node "$ARCHIFY_SKILL/bin/archify.mjs" visual-check \
  github-authorization-lifecycle.html --json
```

`deliver` 會將 frozen JSON 交付為 canonical HTML；`visual-check` 會同步更新 HTML SHA 綁定的 visual-check receipt、contact sheet 與 light／dark screenshot sidecars。若 Chrome／Chromium 無法使用，visual-check 會以非零結果與 `skipped` receipt 如實停止，並移除過期 capture sidecars；不得保留舊 evidence 並稱為 fresh pass。提交 receipt 前，將 `artifact.path` 保持為 repository-relative path，並移除 Chrome executable 的本機路徑；保留 Chrome product identity 與其他量測結果。
