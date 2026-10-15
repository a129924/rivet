# Keychain 本機 OAuth 憑證保存可行性：技術規格

- Topic：`github-oauth-keychain-local-feasibility`
- 日期：2026-10-15
- [需求](requirements.md)／[執行契約](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.plan.md)／[狀態帳本](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.step.md)

## 文件優先與候選 preflight

先讀既有原始碼及 Apple 官方文件；若文件足以回答某項前提即保存來源、條件與限制，不用實驗冒充資格確認。跨程序、真重建及提示行為仍需要本機實證。

DPK 優先，檢查登入使用者情境、app-like host、main executable 的 entitlement、所需有效嵌入 profile 與免費資格來源；library entitlement 不代替 host。只檢查本輪 host，不盤點個人 identity inventory。既有付費 profile／簽章不能作免費成功前提。

若無法證實免費 DPK 前提，可在首次 Keychain 寫入前選 legacy 為唯一候選，於 README 固定機制與原因。測量失敗後不得換機制或默默 fallback。所選候選仍無法確認免費來源或可比較的重建身分時，記前提不足／無法判定；不得把缺前提當作機制失敗或必須付費。

DPK 所有查詢明設 `kSecUseDataProtectionKeychain=true`，legacy 明設 `false`；皆明設 `kSecAttrSynchronizable=false`。使用相同已選 backend 作寫入、讀取、替換、負向操作及清理。

## Host、單 item 與完整 bundle

建立獨立最小 Swift host，不改 root manifests、production Sources／Tests 或 public API。主要 generic-password item 使用本輪 UUID namespace、精確 service／account／backend。完整私有 DTO 編為單一 `Data`，以整筆更新替換，不分拆 token 或日期欄位，不改既有 production Keychain identity／ACL。

DTO 對應既有 `GitHubOAuthCredentialBundle` 六欄，不改該型別：

| 欄位 | 保存／比較語意 |
| --- | --- |
| `accessToken` | 固定假 token，還原後逐欄比較。 |
| `refreshToken` | 固定假 token，還原後逐欄比較。 |
| `accessTokenExpiresAt` | `Date`，非相對有效秒數。 |
| `refreshTokenExpiresAt` | `Date`，非相對有效秒數。 |
| `tokenType` | A／B 均為 bearer。 |
| `grantedScopes` | 原字串還原比較。 |

A／B 的兩個 token、兩個 expiry 與 scope 均不同；資料固定且全為假值。host 模式為 `write-a`、`read-a`、`replace-b`、`read-b`、`write-invalid`、`read-invalid`、`delete`、`read-absent`。不新增 production `OAuthCredentialStore` delete requirement，不驅動 provider runtime。

## Fresh process、真正重建與提示

T02 writer 完整結束後，兩個獨立 fresh reader 逐欄比較 A。T03 改 build marker 並真正重建，證明 binary hash 不同，不只重跑舊 binary。維持固定 host 路徑、bundle ID、簽章方式及候選；檢查 designated requirement／entitlements／access groups 一致性，只保存一致性布林值，不輸出個人簽章識別資訊。無免費穩定身分時不能宣稱 T03 完成。

主要正常流程所有系統提示如實記錄，對應首次最多一次、正常後續與同身分重建零提示。不能把主要流程重複提示排除 UX 計數。T04 整筆換 B，新程序確認六欄全 B、無混合。

## 負向與整輪實驗退出清理

先完成 T02–T04 正常流程，再做 T05。沒有項目回 nil；malformed data 為 decode failure；非 `errSecItemNotFound` 的 Security status 不得回 nil。真 denial 只在本輪獨立負向項目自然可觀察時驗證；不改主要 host 身分、ACL 或安全設定製造提示。無自然 denial 即保留缺口，可明標 synthetic 注入驗證分類，不能當真 Keychain 拒絕證據。

統一 cleanup 屬於整輪 experiment 的退出路徑，不屬於每個 writer／reader 子程序的退出路徑。writer／reader 正常結束必須保留 item，供 T02 跨程序、T03 真重建及 T04 替換測量使用。任一寫入嘗試後，整輪正常完成、失敗、停止或例外退出時，才由整輪退出路徑嘗試清理全部本輪主要／負向項目，依精確 UUID namespace／service／account／backend 刪除並確認不存在。不刪 production 或歷史項目。無法清理時保存殘留非秘密 UUID 識別、原因與待處理操作；本輪驗證任務完成為否。不放寬安全設定解除清理障礙。

## 證據與工具

輸出僅含必要狀態、逐欄比較布林值、提示觀察、遮蔽身分比較與清理結果；不輸出 token、個人簽章識別資訊、秘密或非公開資料。新實驗八段 README 分開設計與實際執行、日期、版本、命令、真實／synthetic、觀察／推論及限制。

工具版本、範圍、預算與失敗處理依執行契約，不以工具代替本機證據。Archify 只描述實驗 workflow，不新增架構決策或 architecture canvas。對長期文件只可在獨立證據審查後回寫有條件結論，不宣稱正式 adapter／產品登入交付或核准採用。

## 依據

- [TN3137：On Mac keychain APIs and implementations](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)
- [TN3125：Inside Code Signing: Provisioning Profiles](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
- [Apple DTS：file-based Keychain 限制](https://developer.apple.com/forums/thread/845980)
- `docs/architecture/github-oauth-dual-client.md`
- `Sources/BoundedContexts/GitHubIntegration/Stores/KeychainTokenStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift`
- `Tests/GitHubIntegrationTests/KeychainTokenStoreTests.swift`
- `plan/github-keychain-token-store/github-keychain-token-store.step.md`

上述是依據位置；本規劃不把尚未執行的 preflight、測量或圖驗證寫成結果。

## 實際候選與證據限制

E005 在首次寫入前明確選 legacy，無 profile 的 ad-hoc host 不依賴付費資格；未嘗試 DPK。T02／T04／真 absent／malformed 與精確清理成立；T03 真重建產生不同 designated requirement，沒有 acceptance read。正常 UX 提示沒有人工觀察，整體無法判定。受控 SIGINT／SIGTERM 與清理期間重複訊號的 fake harness 不當真 Keychain／UX 證據；真寫入後受控例外清理有獨立新 UUID receipt。完整結果見 E005 八段 README，既定 production contract 不變。

### Human 觀察的獨立保存

同環境／同判準 E005 後續補測使用新 UUID，machine promptCount 原樣為 null；Human 另明確回報整輪全程觀察 0 提示，以獨立 JSON 的 machine receipt SHA-256 綁定時窗。此為 Human 陳述的實際桌面觀察，不是程式 exit code 推論，也不改寫初輪證據。T02／T04 本輪原 binary 的零提示可採為受限 UX 證據；不涵蓋 T03 未執行的 acceptance read 或其他 host。整體無法判定與正式 adapter deferred 保持。
