# 儲存 sequence 重建

圖型為 sequence，Archify pin 2.16。從 repository root 執行，`$ARCHIFY_CLI` 指向本機已安裝的該版本 CLI；不安裝／更新或發布。

```sh
node "$ARCHIFY_CLI" validate sequence docs/architecture/diagrams/github-oauth-credential-persistence/storage-sequence.json --quality showcase --json
node "$ARCHIFY_CLI" deliver sequence docs/architecture/diagrams/github-oauth-credential-persistence/storage-sequence.json docs/architecture/diagrams/github-oauth-credential-persistence/storage-sequence.html --quality showcase --json
node "$ARCHIFY_CLI" visual-check docs/architecture/diagrams/github-oauth-credential-persistence/storage-sequence.html --repo-root . --json
```

每步須 exit 0 才前進。Validate 成功凍結候選；deliver 原子交付，不能改 trusted HTML。Delivery receipt 的 input／output 正規化為 repository-relative，hash／bytes／validation 保留工具原值；不記本機絕對路徑。

Visual-check 量測 1440×900、1600×1000、1920×1080、2048×1320 的 light containment，捕捉最小與最大尺寸的 light／dark 四張圖。工具 receipt 的 visualReview=pending 保留，不代表人工視覺接受。人工看圖記於 visual-review.md。

作者繁中；固定 Viewer UI／HTML lang 使用 English fallback。預設 Classic、無動畫。初版有垂直溢出；兩輪只調整畫布寬度、把重複角色補充合併至既有卡片，沒有縮字、裁切或隱藏 overflow。最終九項 showcase 零 errors／warnings、四尺寸 containment 通過。
