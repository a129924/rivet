# Canvas 視覺檢視

2026-10-14 在 feature worktree 依 architecture-canvas 重建 canonical index.html。scene 驗證為 5 bands、16 boxes、17 edges、0 errors、0 warnings。使用獨立暫存 Chrome profile 載入本機檔案，未 preview server 或發布 artifact.cafe。下列深色截圖均為 1440 × 900，已逐張實際檢視。

| 證據 | 縮放／平移 | 可證明的範圍 | 檢視結果 |
| --- | --- | --- | --- |
| [canvas-overview-1440x900.png](canvas-overview-1440x900.png) | 46%；#0.460,380,48 | 五個責任平面與依賴全景 | 元件、邊界與路由完整；全景小字不作可讀性證據 |
| [canvas-top-1440x900.png](canvas-top-1440x900.png) | 70%；#0.700,140,10 | Caller／Scope／clients／provider ownership | Caller 保留 provider，Scope local-ready 才交付雙 clients；文字與邊界未碰撞 |
| [canvas-bottom-1440x900.png](canvas-bottom-1440x900.png) | 70%；#0.700,140,-650 | generic HTTP 與外部系統 | GraphQL 使用獨立路線；完整 REST endpoint、BC adapters 與 Keychain OAuth 仍延後 |

虛線表示 Rivet 擁有的責任契約；實線表示應用表面、技術基礎或外部系統。Provider 仍獨占 lifecycle，Scope 只做多 request composition；不是 UoW。`canvas-1440x900.png` 為舊 evidence，未更新。

Archify v12 showcase 9／9、composition 0 errors／0 warnings；1440×900、1600×1000、1920×1080、2048×1320 containment 全數通過。已實看最小與最大 light／dark 四張，未見節點、標籤或路由碰撞；最大尺寸整體均衡，無多餘下方空帶。第一次最小尺寸 35px overflow 以精簡重複卡片文案修正後重新交付；`visual_review: passed`、`correction_rounds: 1`。自動 receipt 的 `visualReview: pending` 保留原值。作者繁體中文，固定 Viewer UI／HTML lang 採 English fallback。
