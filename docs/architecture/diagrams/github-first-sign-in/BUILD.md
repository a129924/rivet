# 圖的重建與驗證

作者：繁體中文；固定 Viewer UI／HTML lang 為 English fallback。圖不發布 artifact.cafe。

責任圖依 architecture-canvas：使用該 skill 的 scripts/validate.js 檢查 scene.js，零錯誤／零警告後 scripts/build.js 建置 index.html；目前 5 bands、18 boxes、17 edges。這是責任與依賴圖，不是 runtime sequence。

流程圖依 Archify sequence。v1 specification 已 frozen，保留作來源；桌面 containment 不通過後，以核准的 authorization-sequence-v2.json 修正幾何。v2 已通過 showcase 九項檢查，deliver 至 authorization-sequence.html。不得直接修改 frozen JSON 或生成 HTML；需要修圖時建立明列的新 candidate 並重新驗證／交付。

命令（先將 ARCHIFY_SKILL 指向已安裝 skill）：

```sh
node "$ARCHIFY_SKILL/bin/archify.mjs" validate sequence docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v2.json --quality showcase --json
node "$ARCHIFY_SKILL/bin/archify.mjs" deliver sequence docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v2.json docs/architecture/diagrams/github-first-sign-in/authorization-sequence.html --quality showcase --json
node "$ARCHIFY_SKILL/bin/archify.mjs" visual-check docs/architecture/diagrams/github-first-sign-in/authorization-sequence.html --repo-root . --json
```

實際交付 hashes 見 delivery.json；四 viewport containment receipt 與 light/dark screenshots 同目錄。視覺判讀另見 visual-review.md，不能以自動 visualReview=pending 宣稱實看通過。
