# PAT 儲存 sequence

作者內容繁體中文；固定 Viewer UI／HTML lang 使用 English fallback。此圖是儲存契約示意，不是真 DPK 或真人驗收證據。

- 規格：`storage-sequence.json`；交付：`storage-sequence.html`。
- Archify showcase：九項 artifact checks、composition 0 errors／0 warnings；收據見 `validation.json`、`delivery.json`。
- `visual-check` 四尺寸 containment 通過，light／dark 截圖與收據同目錄保存；自動收據中的 `visualReview=pending` 不改寫。
- Agent 實際檢視 1440×900 light 與 2048×1320 dark：文字、訊息、圖例與卡片可讀，未見路徑遮擋或裁切。獨立 Tester 另已檢視四張最小／最大 light／dark，未見裁切或路徑遮擋。Human 視覺接受仍 pending。
- 修正紀錄：初版過高；寬比例候選未過 readability，回到原寬並收斂垂直節奏，再修正最後訊息的五像素 timeline 邊界，最終重新 validate／deliver／visual-check。保留語意與字級，沒有裁切、隱藏 overflow 或手改 HTML。

重建使用 Archify 的 sequence validate、deliver 與 `visual-check --repo-root`；不得修改交付 HTML，或將自動截圖當成人類接受。未發布 artifact.cafe。
