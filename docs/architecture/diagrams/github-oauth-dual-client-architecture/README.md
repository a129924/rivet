# GitHub OAuth 雙 Client 圖表

本目錄的責任／依賴 canvas 為 [index.html](index.html)；它只表達元件責任與依賴，不表達 runtime sequence。

Canvas 標示 public `GitHubRestClient` 四 methods／雙入口與 `GitHubGraphQLServing` Query／Mutation，concrete clients 保持 internal。Caller composition root 建立並保留 provider；`GitHubClientScope.prepare(provider:)` 完成本地 readiness 後交付雙 client。Scope 強持有同一 provider，支援多 request lifetime，非 UoW；產品組裝、完整 REST endpoint、BC adapters、Keychain OAuth 與產品登入仍延後。

作者內容採繁體中文；Archify 固定 Viewer UI 與 HTML lang 依 skill fallback 為 English。未 preview、publish 或 upload。

## Canonical Token Lifecycle

本目錄唯一 canonical token lifecycle 為：

- 規格：[token-lifecycle-v12.json](token-lifecycle-v12.json)
- 已交付圖表：[token-lifecycle-v12.html](token-lifecycle-v12.html)
- Delivery receipt：[token-lifecycle-v12.delivery.json](token-lifecycle-v12.delivery.json)
- 四 desktop 視覺證據：[token-lifecycle-v12.visual-check.json](token-lifecycle-v12.visual-check.json)／[captures](token-lifecycle-v12.visual-check.html)

後續 lifecycle delivery 使用 v12 規格；v11 保留為 immutable historical evidence，不覆寫。v12 承接 v11 的 expiry-valid snapshot、401-only recovery、一次 retry、輪替未知與 persistence failure terminal policy，新增 caller-owned provider／ready Scope、prepare failure／cancellation 不交付與逐次 fresh snapshot 說明。

v12 showcase 檢查 9／9、composition 0 errors／0 warnings。第一次 desktop check 在 1440×900 有 35px overflow；精簡重複卡片文案後重新 validate／deliver，四尺寸 containment pass。1440×900 與 2048×1320 light／dark 四張實際檢視，節點、標籤與路線無碰撞，最大尺寸未見多餘下方空帶；`visual_review: passed`、`correction_rounds: 1`。自動 receipt 的 `visualReview: pending` 保留原值，不視為人工檢視結論。

Delivery receipt 僅將 `input`／`output` 正規化為 repository-relative paths；SHA-256、bytes 與 validation 保留工具原值。精確 digest 見 receipt；未手動修改交付 HTML。

## 保留的歷史 Evidence

`token-lifecycle.json`、`token-lifecycle.html` 與其 `token-lifecycle.visual-check.*` sidecars 是 v1 immutable rejected evidence，僅保留 traceability。它們不是 canonical artifact，不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v2.json`、`token-lifecycle-v2.html` 與其 delivery／visual-check receipts 是 v2 immutable rejected evidence。v2 的 delivery 成功，但 visual-check 因 desktop viewport 垂直 overflow 失敗；它們不是 canonical artifact，不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v3.json`、`token-lifecycle-v3.html` 與其 receipts 是 v3 immutable rejected evidence；它缺少本 topic 最終鎖定的 expiry-valid snapshot、second-401 terminal 與 post-rotation persistence visible/deferred outcome，不得作為後續 delivery input。

`token-lifecycle-v4.json`、`token-lifecycle-v4.html` 與其 receipts 是 v4 immutable rejected evidence。v4 通過 showcase validation 與 delivery，但 visual-check 因 desktop viewport 垂直 overflow 失敗；不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v5.json`、`token-lifecycle-v5.html` 與其 receipts 是 v5 immutable rejected evidence。v5 通過 showcase validation、delivery 與 visual-check，但仍含非必要英文作者文案；不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v6.*` 保留為先前已驗證交付的 immutable historical evidence；不得覆寫或刪除。本次 v7 增加 typed refresh 分類、輪替未知停止與已知技術失敗再次更新路徑。

`token-lifecycle-v7.*` 保留為上一版已驗證交付的 immutable historical evidence；不得覆寫或刪除。

`token-lifecycle-v10.*` 保留為前一版已驗證交付的 immutable historical evidence；不得覆寫或刪除。v11 更新 REST 四 methods／雙入口與 GraphQL Mutation 的交付文案，不改 lifecycle 或 ownership。

`token-lifecycle-v11.*` 保留為上一版已驗證的 immutable historical evidence；v12 為本次公開 contracts 與 Scope composition 的 canonical 版本。
