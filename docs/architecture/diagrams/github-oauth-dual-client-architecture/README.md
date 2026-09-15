# GitHub OAuth 雙 Client 圖表

本目錄的責任／依賴 canvas 為 [index.html](index.html)；它只表達元件責任與依賴，不表達 runtime sequence。

## Canonical Token Lifecycle

本 topic 唯一的 canonical token lifecycle 是：

- 規格：[token-lifecycle-v6.json](token-lifecycle-v6.json)
- 已交付圖表：[token-lifecycle-v6.html](token-lifecycle-v6.html)
- 交付與視覺檢查 receipt：`token-lifecycle-v6.delivery.json` 與 `token-lifecycle-v6.visual-check.json`

後續 lifecycle delivery 只可使用 `token-lifecycle-v6.json` 作為輸入。

delivery receipt 的 `input` 與 `output` 僅作 repository-relative path normalization；其餘工具輸出欄位、specification／artifact SHA-256、bytes 與 validation 保持原值。

## 保留的歷史 Evidence

`token-lifecycle.json`、`token-lifecycle.html` 與其 `token-lifecycle.visual-check.*` sidecars 是 v1 immutable rejected evidence，僅保留 traceability。它們不是 canonical artifact，不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v2.json`、`token-lifecycle-v2.html` 與其 delivery／visual-check receipts 是 v2 immutable rejected evidence。v2 的 delivery 成功，但 visual-check 因 desktop viewport 垂直 overflow 失敗；它們不是 canonical artifact，不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v3.json`、`token-lifecycle-v3.html` 與其 receipts 是 v3 immutable rejected evidence；它缺少本 topic 最終鎖定的 expiry-valid snapshot、second-401 terminal 與 post-rotation persistence visible/deferred outcome，不得作為後續 delivery input。

`token-lifecycle-v4.json`、`token-lifecycle-v4.html` 與其 receipts 是 v4 immutable rejected evidence。v4 通過 showcase validation 與 delivery，但 visual-check 因 desktop viewport 垂直 overflow 失敗；不得作為後續 delivery input，也不得覆寫或刪除。

`token-lifecycle-v5.json`、`token-lifecycle-v5.html` 與其 receipts 是 v5 immutable rejected evidence。v5 通過 showcase validation、delivery 與 visual-check，但仍含非必要英文作者文案；不得作為後續 delivery input，也不得覆寫或刪除。
