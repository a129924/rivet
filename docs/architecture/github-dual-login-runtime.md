# OAuth／PAT 正式登入 runtime

`GitHubLoginService` 是既有 non-BC GitHubIntegration 的 caller-owned Sendable 服務，符合既有 `LoginAuthenticating`。這是服務能力，尚未接產品登入 UI、session 或 clients；真實 runtime 整合驗收與 Human 接受仍 pending。

## 組裝與互斥

組裝端提供 `GitHubOAuthAppConfiguration`、`GitHubOAuthDataProtectionStores`、`GitHubPATDataProtectionStore` 與 `GitHubLoginCoordinator`。同一目的地或共用任一目的地的 instances 必須共享 coordinator；整次 OAuth／PAT 登入含收尾互斥，重疊請求直接 authenticationFailed，取消優先。其他程序／仍可persist的provider不得同時寫入為組裝前提，不提供跨程序鎖定或session退休。

## 驗證後保存

OAuth 使用既有正式 session／exchange，選擇性採用 E013 loopback／browser 機制的新正式元件，不import實驗。Listener限127.0.0.1動態port與固定callback path；startup10秒、授權300秒，無效callback繼續等待，失敗不保存。Browser opener在MainActor並先檢查取消。

兩路以候選token直接執行HTTPS GitHub.com `/user`，套用既有Bearer純轉換、Accept與RivetLoginRuntime User-Agent；HTTP redirects由既有redirect blocker拒絕。僅200、正整數id與非空白login為有效帳號。沒有scope.prepare、restore、refresh或401 retry；identity不保存、不交付。

驗證後才保存OAuth完整bundle或PAT，另一store不動，不記active-mode、不遷移legacy。`.success`為無payload標記，代表驗證與save完成；所有階段錯誤映射有限failure，不回傳原始error或敏感資料。

## 取消與提交

Authenticate預先取消零工作。登入worker轉傳取消並等待原工作settled；提交前同步check，已開始的save等待結束。正式relay等listener及accepted connections回報cancelled才完成shutdown。Coordinator直到完整收尾才釋放，最後同步check後無await。取消優先，可在已保存後回cancelled；不rollback/delete或回寫舊值。

## 驗證邊界

受控測試涵蓋兩路排序／完整bundle、failure、取消barrier、跨instance互斥、probe與loopback。Public consumer只construction／compile，不呼真Security。既有PAT P07僅支持5465d3c指定環境storage，不是本runtime的新live。

[獨立入口](../../experiments/github-dual-login-runtime/README.md)為可移除package；signed live配置與TC08仍Human停點。[正式 sequence 圖](diagrams/github-dual-login-runtime/runtime-sequence.html)與[圖形證據](diagrams/github-dual-login-runtime/BUILD.md)已完成 showcase／四尺寸 containment／Agent light-dark 檢視；Human 視覺接受仍 pending。來源與命令結果見[執行帳本](../../plan/github-dual-login-runtime/github-dual-login-runtime.step.md)。程式撤回不刪已保存憑證，沒有產品登出或delete能力。
