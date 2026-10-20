# 圖的重建與驗證

現行責任圖為 `scene-v2.js` → `index-v2.html`；流程圖為 `authorization-sequence-v3.json` → `authorization-sequence-v3.html`，反映正式 OAuth 能力＋獨立驗證 App，正式 Rivet 產品 UI 未交付。舊 scene/index 與 frozen v1/v2、HTML、receipt、截圖均原樣保留為基線歷史來源，不作現行產品事實。

作者文字繁體中文，固定 Viewer UI／HTML lang 為 English fallback；不發布 artifact.cafe。先將 ARCHIFY_SKILL／CANVAS_SKILL 指向已安裝 skill：

```sh
node "$CANVAS_SKILL/scripts/validate.js" docs/architecture/diagrams/github-first-sign-in/scene-v2.js
node "$CANVAS_SKILL/scripts/build.js" --scene docs/architecture/diagrams/github-first-sign-in/scene-v2.js --out docs/architecture/diagrams/github-first-sign-in/index-v2.html --title '正式 OAuth 與獨立驗證 App' --kicker 'GITHUB SIGN-IN VERIFICATION' --sub '<b>驗證入口</b> → <b>正式 OAuth</b> → <b>程序內組合</b> → <b>API 結果</b>' --slug github-first-sign-in-verification
node "$ARCHIFY_SKILL/bin/archify.mjs" validate sequence docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v3.json --quality showcase --json
node "$ARCHIFY_SKILL/bin/archify.mjs" deliver sequence docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v3.json docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v3.html --quality showcase --json
node "$ARCHIFY_SKILL/bin/archify.mjs" visual-check docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v3.html --repo-root . --json
```

已驗證 candidate 不可再編輯，修圖需先列新 revision；generated HTML不可直接覆寫。v3交付9checks、0errors/warnings，hash見v3.delivery.json。四viewport與四截圖詳見v3.visual-check.json；自動visualReview=pending不等於人已實看，見visual-review.md。
