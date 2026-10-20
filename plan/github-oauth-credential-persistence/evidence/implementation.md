# Implementer 交接

## 範圍與 TDD

僅在 feat/github-oauth-credential-persistence feature worktree實作；未修改 dev、其他topic或E007。九欄與精確leaves依 plan W02／W03／M01／M02；無repo刪檔、無live Security或簽章操作。

- 基線：既有 OAuthTokenProviderTests 19 tests 通過。
- Red：新增 fake Security 契約測試後 `swift test --filter GitHubOAuthDataProtectionStoresTests` exit1，缺 GitHubOAuthDataProtectionStores／GitHubOAuthSecurityClient，確認缺少新實作。
- Green：同命令 exit0，13 tests，包含25個corrupt payloads、7個access statuses、3個write failures。沒有改既有provider期望。
- Full non-live regression：`swift test --skip KeychainTokenStoreTests` exit0，269 tests／31 suites。明確跳過既有legacy Keychain live suite，沒有宣稱其本輪通過。
- 本次Swift source／test strict SwiftLint通過；跨targetconsumer及全repo format／lint交獨立Tester重驗。

## 行為

完整兩items、strict version1 codec、clientID read-check-write保護、explicit DPK query／protection、update-add-duplicate單次retry及finite errors已交付；shared actor在同步Security calls間無suspension。測試包含完整替換、configuration-first partial save、並行views及provider persist-stop。Readonly provider／ports／clients／Package.swift不改。

Static isolation初次回歸只因舊檔案/import allowlist有2 issues；已經Plan-Creator＋獨立Plan-Reviewer核准精確amendment，再只補兩個檔案與新adapter的Security例外，其他限制維持。機械修正後269 tests通過。

## 文件與圖

長期文件、單張storage sequence已完成；Archify最終9/9 showcase、0errors／warnings，四尺寸containment及四lightdark截圖通過，Agent已實際看圖。Human visual acceptance pending。PR Lens待真commit後完成；Graphify無圖採source fallback。

## 獨立驗證交接

請Tester獨立執行適用T01–T08，核fake-only/publicconsumer/strictformatlint與圖receipt；之後交獨立Reviewer。真DPK、跨程序、簽章、prompts、GitHub登入未驗證，不依賴別人E007，不宣稱Mission整套完成。

## Tester 回修

獨立 Tester 發現 StaticIsolationTests 新 OR 條件的 opening_brace lint；Implementer 改為相同兩個 paths 的 Set.contains，未變更期望或放寬範圍。指定檔重新 format，交 Tester 只重驗必要 lint／format 與 static case。
