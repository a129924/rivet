# Missing-verifier workflow 圖交付

- diagram_type：workflow；作者內容繁體中文，靜態，8 個節點。
- 固定 Viewer UI／HTML lang 使用 English fallback；圖只描述受限契約，不是本輪真人操作證據。
- specification：`missing-verifier.workflow.json`；SHA-256 `149c5316f483cb20b91a7bfbe00db899a9422841eb2e88d20c069b0de5eba83c`，3309 bytes。
- output：[missing-verifier.html](missing-verifier.html)；SHA-256 `242f1b39415282de81361f4e3773255cdf86398840260326ce22e35c5e09ce70`，702647 bytes。
- validation：[receipt](missing-verifier.validation.json)，showcase 9/9、0 errors、0 warnings。
- delivery：[receipt](missing-verifier.delivery.json)，exit 0；spec／HTML bytes 凍結。
- visual-check：[自動量測](missing-verifier.visual-check.json)及[截圖索引](missing-verifier.visual-check.html)，exit 0。
- 1440×900、1600×1000、1920×1080、2048×1320：scrollWidth／scrollHeight 均等於 viewport，無水平或垂直溢出。
- 自動 receipt 的 `visualReview: pending` 原樣保留。Implementer 已親看 1440×900 light 與 2048×1320 dark；完整人工檢視結論請見 [Tester evidence](../../../../plan/github-pkce-missing-verifier-feasibility/evidence/offline-verification.md)，不以自動量測代替視覺結論。
- 修正紀錄：初始節點間距修正後可通過結構檢查，但桌面高度溢出；兩輪視覺收斂中，先減少重複節點／卡片，再使用兩泳道與診斷指定的標籤／箭頭調整。最終驗證重新執行；沒有隱藏 overflow、縮字或裁切。
- correction_rounds：2（視覺收斂；含交付前針對診斷逐項修正）。
- 未開 preview server、未上傳或發布 artifact.cafe。

## 重現

在 repo 根目錄，以已安裝 archify skill 的 `bin/archify.mjs` 為 CLI，依序執行：

```text
validate workflow docs/architecture/diagrams/github-pkce-missing-verifier-feasibility/missing-verifier.workflow.json --quality showcase --json
deliver workflow docs/architecture/diagrams/github-pkce-missing-verifier-feasibility/missing-verifier.workflow.json docs/architecture/diagrams/github-pkce-missing-verifier-feasibility/missing-verifier.html --quality showcase --json
visual-check docs/architecture/diagrams/github-pkce-missing-verifier-feasibility/missing-verifier.html --repo-root <repo-root> --json
```

validate／deliver 的已保存 JSON 將本機 root 正規化為 repo 相對路徑；未改動 spec、HTML 或 SHA。visual-check 自帶的相對路徑 receipt 保持原樣。重新產圖後必須重新驗證、交付與看圖，不能沿用本次 receipts。
