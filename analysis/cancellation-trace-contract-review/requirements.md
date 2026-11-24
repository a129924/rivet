# Cancellation Trace & Contract Review 需求

基線為 `dev` 的 `386af9e`。追查 Swift 取消的發起、傳遞、觀察、錯誤轉換、工作收尾與結果消費。交付原始碼 trace、各層現有契約、八情境證據、風險矩陣、三個契約方案與最小後續建議。

PR Reader 的範圍是 `PRContentSource` nonthrowing Port、測試 conformer 與獨立 E012 WebView fixture。以 E020 CLI 原始碼走查實際接線的 PR Inbox Adapter、REST、OAuth provider 及 HTTP Transport。E020 是既有 Inbox 驗證，歷史結果依原版本解讀。產品 Reader GitHub 路徑、產品狀態提交與選取行為依實際接線判定。

工作依序為靜態分析、既有離線測試、只在會改變建議時執行隔離實測、獨立成果審查。正式 Swift、公開介面、既有測試、產品接線、retry 政策與真 GitHub／OAuth／Keychain 操作排除於本 topic。既有 E012／E020、實驗索引與 dev worktree 原有修改均為唯讀。

驗收涵蓋請求前、HTTP I/O 中、snapshot 中、refresh 中、回應返回前、DTO decode 前、Task 完成後、並行 caller 八種情境。以明確的證據類型和限制區分原始碼、既有測試、實測及未驗證行為。取消傳遞與 stale-result protection 各自評估。新契約留待 Human 確認。
