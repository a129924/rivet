# Canvas 視覺檢視

所有 evidence 的 viewport 均為 **1440 × 900**，使用 architecture-canvas 互動式 viewer 的 dark theme。本輪以 ephemeral 本機 HTTP viewer 載入重建後的 `index.html`，不發布至 artifact.cafe。

| Evidence | Zoom / pan | 可證明的範圍 | 人工檢視結果 |
| --- | --- | --- | --- |
| [canvas-overview-1440x900.png](canvas-overview-1440x900.png) | 36% fit；viewer hash `#0.357,376,48` | 五個 band、Facade 到兩個用戶端的主要依賴、共享 integration、HTTP 基礎與外部系統均完整可見。此圖用於完整性，不宣稱所有小字可讀。 | 五個責任平面與主要依賴路徑完整可見，沒有元件重疊或不相關路徑穿越。 |
| [canvas-top-1440x900.png](canvas-top-1440x900.png) | 46%；viewer hash `#0.464,273,-73` | 標題、layer 外組裝根節點 Facade、GitHub REST／GraphQL 用戶端，以及 GithubIntegration、OAuthTokenProvider、TokenSnapshot、KeychainTokenStore、OAuthTokenFetcher 的文字與相互依賴。 | 文字可讀；OAuthTokenProvider 內「未來可符合 async GitHubAccessTokenProvider」標籤沒有碰撞，且不將 lifecycle implementation 誤畫為已交付。 |
| [canvas-bottom-1440x900.png](canvas-bottom-1440x900.png) | 60%；viewer hash `#0.603,138,-229` | shared integration、RivetHTTPClient、URLSessionTransport、AuthRequester、Keychain 與 GitHub 外部 API，以及 REST → bare HTTP executor edge 的完整下半路徑。 | 文字可讀；AuthRequester 注入 `Requester` 與 caller `Auth`、僅驅動 generic flow 而非 GitHub OAuth；HTTP 基礎、外部系統與垂直依賴路徑沒有碰撞。 |

既有 [canvas-1440x900.png](canvas-1440x900.png) 保留作為先前 evidence，未以局部圖宣稱完整畫布可見。此 canvas 只表達責任與依賴，未表達 runtime sequence。本機 viewer 的唯一 console error 是缺少 `favicon.ico` 的 404，與 canvas runtime 或內容無關。
