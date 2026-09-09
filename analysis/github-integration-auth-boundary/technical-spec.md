# GitHub Integration Authorization Boundary：技術規格

## Locked Architecture Contract

GitHub Integration 擁有 authorization seam 與其 policy。未來 contract direction 為：

```swift
GitHubTokenProvider // Integration-owned token-delivery seam
GitHubAccessToken  // Integration-owned value type
```

這只是 declaration-only direction，不在本 topic 建立 Swift declaration。未來 provider 有 token-delivery operation 並交付 `GitHubAccessToken`，但具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 全部延後至獨立 failure-contract topic；本 topic 不預先選擇任何 failure representation。`GitHubAccessToken` 是 GitHub Integration 的 value type；它不退化為 `String`，也不成為 `RivetHTTPClient` 的公開 type。

初版只支援一個使用者預先提供的 fine-grained PAT。該 credential 可由 future provider 在每次 **GitHub REST request** 前交付給 Integration authorizer。authorizer 設定或覆寫 `Authorization: Bearer …` 後，才將該 REST raw request 交給 `RivetHTTPClient`。這不描述 `GitHubGraphQLAdapter` 的 Apollo route。

## Boundary Rules

- `RivetHTTPClient` 不持有 `TokenProvider`，不接受 token 作為 constructor dependency，沒有 GitHub／token-specific authorization policy API，也不負責 credential lookup、refresh、401 retry 或 GitHub policy。這不否定 package 已有或未來可有的通用 `Authorization` header surface；該通用 header surface 不擁有 GitHub credential lifecycle 或 policy。
- Keychain 與使用者設定的 PAT 都是 Outside。此 topic 不鎖定 Keychain service/account identity、entitlement、讀寫 adapter 或 UI。
- GitHub Integration 在跨越 PR Inbox／PR Reader 的 core Port 前隔離 token、OAuth、HTTP status、DTO 與 infrastructure details。各 core BC 的 failure mapping 是後續 adapter topic 的責任。
- 現有 HTTP package 的 raw response／transport-error passthrough contract 維持不變。
- 只有 `GitHubRESTAdapter` 的 request 經 Integration-owned authorizer 後使用 `RivetHTTPClient`。`GitHubGraphQLAdapter` 封裝 `ApolloClient`，不經 `RivetHTTPClient.Transport`；Apollo token interceptor 及其 token-delivery、failure、refresh、re-auth 行為均留待獨立 topic。

## Lifecycle Contract

1. `GitHubRESTAdapter` 準備 GitHub REST request。
2. future `GitHubTokenProvider` 取得既有的單一 PAT，交付 `GitHubAccessToken`；其 exact operation signature 與 credential failure behavior 未在本 topic 決定。
3. future Integration authorizer 將 request 的 `Authorization` 設定或覆寫為 Bearer token。
4. `RivetHTTPClient` 執行未帶 GitHub authorization policy 的 REST raw request chain。

此 lifecycle 不包含 `GitHubGraphQLAdapter`／Apollo route、OAuth、refresh、401 retry、concrete Keychain call、concrete network implementation、DTO mapping 或 core failure mapping。

兩張 canonical diagram 的 wording 也必須保留同一限制：canvas 的 future authorizer 只描述 GitHub REST request，但仍只表達 ownership／compile-time boundary；lifecycle 的 request preparation／authorizer 只描述 GitHub REST request，且不表示 GraphQL／Apollo route。source wording 變更後，必須由獨立 Implementer 依 canvas 的 validate → build → enhance → verify 與 lifecycle 的 showcase validate → deliver（及 BUILD 規定的 visual-check policy）正式重建 output；此 topic 不以 generated output 手動 patch。

## Lifecycle Renderer Locale Limitation

Archify 正式支援的 locale 僅有 `en` 與 `zh-CN`。lifecycle 的作者內容為繁體中文，故 source JSON 必須省略 `meta.locale`，不得將繁體中文內容錯標為 `zh-CN`。在此 omission 下，Viewer UI 與 generated HTML 的 language attribute 會依 renderer fallback 維持英文；這是 renderer limitation，不是作者內容的語言決策。

本 topic 不直接修改 generated lifecycle HTML、visual-check sidecar 或 source locale，亦不因這個 thread 重新 deliver。唯一後續 delivery 是由 Implementer 在 lifecycle artifact-local `BUILD.md` 如實記錄上述 limitation 與可重現規則。此規則僅適用 Archify lifecycle，不能推論或覆寫同目錄 architecture-canvas 的獨立 language handling。

## Deferred OAuth-Shaped Payload

使用者提供的 `access_token`、`expires_in`、`refresh_token`、`refresh_token_expires_in`、`scope`、`token_type` JSON schema 是 OAuth-shaped payload；它不改變本 topic 的 fine-grained PAT-only decision。此 topic 不採用、保存、解析或暴露該 schema，也不以它擴大未來 provider contract。若未來評估 OAuth，必須以獨立 topic 重新鎖定 lifecycle、storage、refresh、failure 與 Port isolation。

## Retained Integration Reconciliation

human 已鎖定 GitHub Integration 仍是 Supporting BC，且現有 BC 文件與 canonical diagrams 必須保留。衝突樹中的 GraphQL SDL 只作為 future GitHub Integration GraphQL adapter／schema snapshot topic 的 candidate material；本輪不驗證、移動、接受或以它建立 PR Reader local-exclusive ownership。

後續 implementation 的唯一 architecture writeback 是下列六份 active docs 與 bounded-context map：

- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/architecture/bounded-contexts/pr-reader.md`
- `docs/github-api/README.md`
- `docs/architecture/diagrams/bounded-context-map/scene.js` → formal generated `index.html`

這些 docs 必須刪除 local-exclusive Infra、future `GitHubTransport` 及 GitHub Integration retirement 的 claim，回到 Integration 作為集中 external protocol／identity／DTO／infrastructure-failure boundary。map 必須重建中央 Integration construct，以及 PR Inbox／PR Reader Core／Port isolation；canvas 只表達 ownership／compile-time boundary，不加入 REST、GraphQL、authorization 或 runtime dataflow edge。具體 GraphQL adapter、Apollo interceptor、token delivery、failure、refresh 與 re-auth 仍為 deferred topic。

## Delivery Responsibility 與歷史偏差

Plan-Creator 的 scope 僅限四份正式 planning artifacts；它不得交付或驗證長期 docs、architecture README、BC 文件、canvas、lifecycle HTML 或 generated evidence。Plan-Reviewer 通過後，獨立 Implementer 才能對這些 long-lived artifacts 執行受限 delivery；其後由獨立 Tester 驗證、獨立 Reviewer 出具 verdict，最後才交由 human review。

歷史事實：在本次 workflow remediation 前，long-lived docs、canvas、canonical lifecycle artifact 與兩組 containment candidate 曾於 Plan-Creator 階段出現在 worktree。這不是 approval，也不倒填為正確角色交付。繼任 Implementer 必須在 final delivery 前移除兩組 candidate，並重新確認 canonical artifacts；Tester 與 Reviewer 必須獨立驗證結果。

planning artifacts 記錄本次 contract 與後續實作切片，不能被誤當成已存在的 Swift API 或已完成的文件交付。
