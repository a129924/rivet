# GitHub OAuth 雙 Client 圖表

本目錄的責任／依賴 canvas 為 [index.html](index.html)；它只表達元件責任與依賴，不表達 runtime sequence。

Canvas 標示 OAuth provider／adapter ports、internal GraphQL Query／Mutation 與 REST GET／POST／PUT／PATCH 雙入口／401-only 一次復原為已交付；跨 target client 使用、完整 REST、Keychain credential adapter 仍延後。長期 composition root 與雙 client 的責任、依賴不變。

Canonical lifecycle 同步標示 internal Query／Mutation 與 REST 四 methods／雙入口的交付狀態；產品登入仍延後，provider restore／refresh／persist 保留技術階段。作者內容採繁體中文；Archify 固定 Viewer UI 與 HTML lang 依 skill fallback 為 English。

## Canonical Token Lifecycle

本 topic 唯一的 canonical token lifecycle 是：

- 規格：[token-lifecycle-v11.json](token-lifecycle-v11.json)
- 已交付圖表：[token-lifecycle-v11.html](token-lifecycle-v11.html)
- 交付與視覺檢查 receipt：`token-lifecycle-v11.delivery.json` 與 `token-lifecycle-v11.visual-check.json`

後續 lifecycle delivery 只可使用 `token-lifecycle-v11.json` 作為輸入。

v8 showcase validation 通過，但 1440×900 visual-check 有 1px 垂直 overflow；v9 同樣通過 validation，但有 24px overflow。兩者保留為 rejected evidence，不得作為 canonical，也不得覆寫。v10 保留為前一版 immutable historical evidence。v11 showcase 9／9、composition 0 errors／0 warnings；四種桌面尺寸 containment pass，light／dark captures 已人工檢視（visual_review: passed；correction_rounds: 0）。

delivery receipt 的 `input` 與 `output` 僅作 repository-relative path normalization；其餘工具輸出欄位、specification／artifact SHA-256、bytes 與 validation 保持原值。

## 保留的歷史 Evidence

`token-lifecycle.json`、`token-lifecycle.html` 與其 `token-lifecycle.visual-check.*` sidecars 是 v1 immutable rejected evidence，僅保留 traceability。它們不是 canonical artifact，不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v2.json`、`token-lifecycle-v2.html` 與其 delivery／visual-check receipts 是 v2 immutable rejected evidence。v2 的 delivery 成功，但 visual-check 因 desktop viewport 垂直 overflow 失敗；它們不是 canonical artifact，不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v3.json`、`token-lifecycle-v3.html` 與其 receipts 是 v3 immutable rejected evidence；它缺少本 topic 最終鎖定的 expiry-valid snapshot、second-401 terminal 與 post-rotation persistence visible/deferred outcome，不得作為後續 delivery input。

`token-lifecycle-v4.json`、`token-lifecycle-v4.html` 與其 receipts 是 v4 immutable rejected evidence。v4 通過 showcase validation 與 delivery，但 visual-check 因 desktop viewport 垂直 overflow 失敗；不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v5.json`、`token-lifecycle-v5.html` 與其 receipts 是 v5 immutable rejected evidence。v5 通過 showcase validation、delivery 與 visual-check，但仍含非必要英文作者文案；不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v6.*` 保留為先前已驗證交付的 immutable historical evidence；不得覆寫或刪除。本次 v7 增加 typed refresh 分類、輪替未知停止與已知技術失敗再次更新路徑。

`token-lifecycle-v7.*` 保留為上一版已驗證交付的 immutable historical evidence；不得覆寫或刪除。

`token-lifecycle-v10.*` 保留為前一版已驗證交付的 immutable historical evidence；不得覆寫或刪除。v11 更新 REST 四 methods／雙入口與 GraphQL Mutation 的交付文案，不改 lifecycle 或 ownership。
