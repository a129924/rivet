# GitHub Integration Authorization Boundary：技術規格

## Locked Architecture Contract

GitHub Integration 擁有 authorization seam 與其 policy。未來 contract direction 為：

```swift
GitHubTokenProvider // Integration-owned token-delivery seam
GitHubAccessToken  // Integration-owned value type
```

這只是 declaration-only direction，不在本 topic 建立 Swift declaration。未來 provider 有 token-delivery operation 並交付 `GitHubAccessToken`，但具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 全部延後至獨立 failure-contract topic；本 topic 不預先選擇任何 failure representation。`GitHubAccessToken` 是 GitHub Integration 的 value type；它不退化為 `String`，也不成為 `RivetHTTPClient` 的公開 type。

初版只支援一個使用者預先提供的 fine-grained PAT。該 credential 可由 future provider 在每次 GitHub request 前交付給 Integration authorizer。authorizer 設定或覆寫 `Authorization: Bearer …` 後，才將 raw request 交給 `RivetHTTPClient`。

## Boundary Rules

- `RivetHTTPClient` 不持有 `TokenProvider`，不接受 token 作為 constructor dependency，沒有 public authorization API，也不負責 credential lookup、refresh、401 retry 或 GitHub policy。
- Keychain 與使用者設定的 PAT 都是 Outside。此 topic 不鎖定 Keychain service/account identity、entitlement、讀寫 adapter 或 UI。
- GitHub Integration 在跨越 PR Inbox／PR Reader 的 core Port 前隔離 token、OAuth、HTTP status、DTO 與 infrastructure details。各 core BC 的 failure mapping 是後續 adapter topic 的責任。
- 現有 HTTP package 的 raw response／transport-error passthrough contract 維持不變。

## Lifecycle Contract

1. Integration 準備 GitHub request。
2. future `GitHubTokenProvider` 取得既有的單一 PAT，交付 `GitHubAccessToken`；其 exact operation signature 與 credential failure behavior 未在本 topic 決定。
3. future Integration authorizer 將 request 的 `Authorization` 設定或覆寫為 Bearer token。
4. `RivetHTTPClient` 執行未帶 GitHub authorization policy 的 raw request chain。

此 lifecycle 不包含 OAuth、refresh、401 retry、concrete Keychain call、concrete network implementation、DTO mapping 或 core failure mapping。

## Lifecycle Renderer Locale Limitation

Archify 正式支援的 locale 僅有 `en` 與 `zh-CN`。lifecycle 的作者內容為繁體中文，故 source JSON 必須省略 `meta.locale`，不得將繁體中文內容錯標為 `zh-CN`。在此 omission 下，Viewer UI 與 generated HTML 的 language attribute 會依 renderer fallback 維持英文；這是 renderer limitation，不是作者內容的語言決策。

本 topic 不直接修改 generated lifecycle HTML、visual-check sidecar 或 source locale，亦不因這個 thread 重新 deliver。唯一後續 delivery 是由 Implementer 在 lifecycle artifact-local `BUILD.md` 如實記錄上述 limitation 與可重現規則。此規則僅適用 Archify lifecycle，不能推論或覆寫同目錄 architecture-canvas 的獨立 language handling。

## Deferred OAuth-Shaped Payload

使用者提供的 `access_token`、`expires_in`、`refresh_token`、`refresh_token_expires_in`、`scope`、`token_type` JSON schema 是 OAuth-shaped payload；它不改變本 topic 的 fine-grained PAT-only decision。此 topic 不採用、保存、解析或暴露該 schema，也不以它擴大未來 provider contract。若未來評估 OAuth，必須以獨立 topic 重新鎖定 lifecycle、storage、refresh、failure 與 Port isolation。

## Delivery Responsibility 與歷史偏差

Plan-Creator 的 scope 僅限四份正式 planning artifacts；它不得交付或驗證長期 docs、architecture README、BC 文件、canvas、lifecycle HTML 或 generated evidence。Plan-Reviewer 通過後，獨立 Implementer 才能對這些 long-lived artifacts 執行受限 delivery；其後由獨立 Tester 驗證、獨立 Reviewer 出具 verdict，最後才交由 human review。

歷史事實：在本次 workflow remediation 前，long-lived docs、canvas、canonical lifecycle artifact 與兩組 containment candidate 曾於 Plan-Creator 階段出現在 worktree。這不是 approval，也不倒填為正確角色交付。繼任 Implementer 必須在 final delivery 前移除兩組 candidate，並重新確認 canonical artifacts；Tester 與 Reviewer 必須獨立驗證結果。

planning artifacts 記錄本次 contract 與後續實作切片，不能被誤當成已存在的 Swift API 或已完成的文件交付。
