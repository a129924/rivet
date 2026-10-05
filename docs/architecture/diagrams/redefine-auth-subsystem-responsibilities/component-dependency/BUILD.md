# 重建 Component Dependency Canvas

`scene.js` 是圖表內容與語意的唯一真相，且本 topic 將它保持 ReadOnly。global
`architecture-canvas` template 的 raw build 固定輸出 `<html lang="en">`；本 artifact 只透過
`enhance-document-language.js`，恰好一次將這個 root attribute 轉為 `<html lang="zh-Hant">`，
並從 raw scene 衍生可見、可聚焦捲動的等價語意區：完整十個元件（name、about、所有 text）、
十二條有向依賴（source、target、原 label）及所有 context／caveats。無 label 的邊不新增語意。

不得手改 `index.html`。enhancer 對缺少、重複或不同的 root tag fail-closed，並以同目錄 temporary file
寫入後 atomic rename。`verify-document-language.js` 對 raw 與 final 逐 byte 比較，除了那一個 root
language value 與唯一、完整且安全 HTML escaping 的靜態語意區以外不接受任何差異。
scene、canvas geometry、ownership、原 viewer runtime／互動皆保持 byte-equal；不得隱藏等價內容。
Tab 可聚焦語意區，PageDown／PageUp／Home／End 可原生捲動內容；既有 viewer 的方向鍵仍為
canvas pan，不改 runtime。browser accessibility tree 驗證不代表原生 VoiceOver 通過。
未有原生實測時，VoiceOver／Increase Contrast／inactive 狀態均維持待驗。

在本目錄設定 `CANVAS_SKILL` 為 `architecture-canvas` skill 根目錄，執行以下兩次完整流程：

```sh
set -eu
RUN_ONE="$(mktemp -d)"
RUN_TWO="$(mktemp -d)"

node "$CANVAS_SKILL/scripts/validate.js" scene.js
node "$CANVAS_SKILL/scripts/build.js" \
  --scene scene.js \
  --out "$RUN_ONE/raw.html" \
  --title "RivetHTTPClient — 認證責任目標" \
  --kicker "RivetHTTPClient — 認證責任目標" \
  --sub "<b>AuthRequester</b> 持有原始請求 → <b>AuthFlow</b> 擁有策略／狀態 → <b>Requester</b> 執行通用輸入／輸出" \
  --slug redefine-auth-subsystem-responsibilities-component-dependency
node enhance-document-language.js --input "$RUN_ONE/raw.html" --output index.html
node verify-document-language.js --raw "$RUN_ONE/raw.html" --final index.html

node "$CANVAS_SKILL/scripts/validate.js" scene.js
node "$CANVAS_SKILL/scripts/build.js" \
  --scene scene.js \
  --out "$RUN_TWO/raw.html" \
  --title "RivetHTTPClient — 認證責任目標" \
  --kicker "RivetHTTPClient — 認證責任目標" \
  --sub "<b>AuthRequester</b> 持有原始請求 → <b>AuthFlow</b> 擁有策略／狀態 → <b>Requester</b> 執行通用輸入／輸出" \
  --slug redefine-auth-subsystem-responsibilities-component-dependency
node enhance-document-language.js --input "$RUN_TWO/raw.html" --output "$RUN_TWO/final.html"
node verify-document-language.js --raw "$RUN_TWO/raw.html" --final "$RUN_TWO/final.html"
cmp -s index.html "$RUN_TWO/final.html"
```

兩次生成必須 byte-identical。temporary raw HTML 只存在於系統 temporary directory，不得加入 Git。
validate output 必須維持 `5 bands · 10 boxes · 12 edges · 0 errors · 0 warnings`；再依 topic 的 visual
驗收檢查交付 `index.html` 於 1440×900、1600×1000、1920×1080、2048×1320，並人工確認 1440／2048 的 light／dark
沒有 visual drift。
