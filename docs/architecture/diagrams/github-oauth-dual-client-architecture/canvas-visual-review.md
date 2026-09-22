# Canvas 視覺檢視

所有證據的檢視區均為 **1440 × 900**，使用 architecture-canvas 互動式檢視器的深色主題。本輪以暫時本機 HTTP 檢視器載入重建後的 `index.html`，不發布至 artifact.cafe。

| 證據 | 縮放／平移 | 可證明的範圍 | 人工檢視結果 |
| --- | --- | --- | --- |
| [canvas-overview-1440x900.png](canvas-overview-1440x900.png) | 46% 適合畫面；檢視狀態 `#0.460,380,48` | 五個責任區、外觀層到兩個用戶端的主要依賴、共享整合、HTTP 基礎與外部系統均完整可見。此圖用於完整性，不宣稱所有小字可讀。 | 五個責任平面與主要依賴路徑完整可見，沒有元件重疊或不相關路徑穿越。 |
| [canvas-top-1440x900.png](canvas-top-1440x900.png) | 60%；檢視狀態 `#0.598,278,-73` | 標題、層級外組裝根節點、GitHub REST／GraphQL 用戶端，以及 GithubIntegration、已交付的 OAuthTokenProvider、TokenSnapshot、OAuthCredentialStore、OAuthTokenFetcher 的文字與相互依賴。 | 文字可讀；GithubIntegration 僅有轉接器使用介面，並不擁有限界上下文的 Port、DTO 或失敗對應；OAuthTokenProvider、TokenSnapshot 與介面的「已交付」狀態，以及 Keychain／HTTP 轉接器延後狀態沒有碰撞，且不將用戶端重試誤畫為已交付。 |
| [canvas-bottom-1440x900.png](canvas-bottom-1440x900.png) | 60%；檢視狀態 `#0.598,278,-73` | 共享整合、RivetHTTPClient、URLSessionTransport、AuthRequester、Keychain 與 GitHub 外部 API，以及 REST → 純 HTTP 執行器連線的完整下半路徑。 | 文字可讀；AuthRequester 仍僅驅動通用 AuthFlow；HTTP 基礎與外部系統沒有碰撞，且 OAuth 轉接器延後標示不會暗示 Keychain／HTTP 轉接器已交付。 |

[canvas-1440x900.png](canvas-1440x900.png) 同步為本輪的 60% 詳細檢視區。此 canvas 只表達責任與依賴，未表達執行期序列。本機檢視器的唯一主控台錯誤是缺少 `favicon.ico` 的 404，與 canvas 執行期或內容無關。
