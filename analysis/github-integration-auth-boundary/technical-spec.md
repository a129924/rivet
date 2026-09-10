# GitHub Integration Authorization Boundary：技術規格

## Locked Architecture Contract

GitHub Integration 提供 lower shared authorization capability；它不擁有任何 Domain adapter 或 Domain Port。未來 contract direction 為：

```swift
GitHubTokenProvider // shared capability 的 token-delivery seam
GitHubAccessToken  // shared capability 的 value type
```

這只是 declaration-only direction，不在本 topic 建立 Swift declaration。未來 provider 有 token-delivery operation 並交付 `GitHubAccessToken`，但具體 Swift signature、`throws`／`Outcome` 選擇、credential failure，以及 refresh／re-auth contract 全部延後至獨立 failure-contract topic；本 topic 不預先選擇任何 failure representation。`GitHubAccessToken` 屬 shared capability 的 value type；它不退化為 `String`，也不成為 `RivetHTTPClient` 的公開 type。

初版只支援一個使用者預先提供的 fine-grained PAT。該 credential 可由 future provider 在每次 **consuming Domain BC local-Infra GitHub REST request** 前交付給 shared authorizer。authorizer 設定或覆寫 `Authorization: Bearer …` 後，才將該 REST raw request 交給 `RivetHTTPClient`。這不描述同一 Domain BC local-Infra GitHub GraphQL adapter 的 Apollo route。

## Boundary Rules

- `RivetHTTPClient` 不持有 `TokenProvider`，不接受 token 作為 constructor dependency，沒有 GitHub／token-specific authorization policy API，也不負責 credential lookup、refresh、401 retry 或 GitHub policy。這不否定 package 已有或未來可有的通用 `Authorization` header surface；該通用 header surface 不擁有 GitHub credential lifecycle 或 policy。
- Keychain 與使用者設定的 PAT 都是 Outside。此 topic 不鎖定 Keychain service/account identity、entitlement、讀寫 adapter 或 UI。
- 各 Domain BC 的 local Infra 擁有其 GitHub endpoint／operation 組裝、DTO 與 infrastructure-failure 正規化；在跨越自己的 core Port 前隔離 token、OAuth、HTTP status 與 infrastructure details，並負責該 BC 的 failure mapping。GitHub Integration 僅提供 lower shared authorization capability，不跨越、引用或符合任何 core Port，也不擁有 endpoint、DTO 或 infrastructure-failure mapping。
- 現有 HTTP package 的 raw response／transport-error passthrough contract 維持不變。
- 只有 consuming Domain BC local-Infra `GitHubRESTAdapter` 的 request 經 shared authorizer 後使用 `RivetHTTPClient`。同一 BC local-Infra `GitHubGraphQLAdapter` 封裝 `ApolloClient`，不經 `RivetHTTPClient.Transport`；Apollo token interceptor 及其 token-delivery、failure、refresh、re-auth 行為均留待獨立 topic。

## Lifecycle Contract

1. consuming Domain BC local-Infra `GitHubRESTAdapter` 準備 GitHub REST request。
2. future shared-capability `GitHubTokenProvider` 取得既有的單一 PAT，交付 `GitHubAccessToken`；其 exact operation signature 與 credential failure behavior 未在本 topic 決定。
3. future shared authorizer 將 request 的 `Authorization` 設定或覆寫為 Bearer token。
4. `RivetHTTPClient` 執行未帶 GitHub authorization policy 的 REST raw request chain。

此 lifecycle 不包含 consuming Domain BC local-Infra GitHub GraphQL adapter／Apollo route、OAuth、refresh、401 retry、concrete Keychain call、concrete network implementation、DTO mapping 或 core failure mapping。

兩張 canonical diagram 的 wording 也必須保留同一限制：canvas 的 future authorizer 只描述 GitHub REST request，但仍只表達 ownership／compile-time boundary；lifecycle 的 request preparation／authorizer 只描述 GitHub REST request，且不表示 GraphQL／Apollo route。source wording 變更後，必須由獨立 Implementer 依 canvas 的 validate → build → enhance → verify 與 lifecycle 的 showcase validate → deliver（及 BUILD 規定的 visual-check policy）正式重建 output；此 topic 不以 generated output 手動 patch。

## Lifecycle Renderer Locale Limitation

Archify 正式支援的 locale 僅有 `en` 與 `zh-CN`。lifecycle 的作者內容為繁體中文，故 source JSON 必須省略 `meta.locale`，不得將繁體中文內容錯標為 `zh-CN`。在此 omission 下，Viewer UI 與 generated HTML 的 language attribute 會依 renderer fallback 維持英文；這是 renderer limitation，不是作者內容的語言決策。

本 topic 不直接修改 generated lifecycle HTML、visual-check sidecar 或 source locale，亦不因這個 thread 重新 deliver。唯一後續 delivery 是由 Implementer 在 lifecycle artifact-local `BUILD.md` 如實記錄上述 limitation 與可重現規則。此規則僅適用 Archify lifecycle，不能推論或覆寫同目錄 architecture-canvas 的獨立 language handling。

## Deferred OAuth-Shaped Payload

使用者提供的 `access_token`、`expires_in`、`refresh_token`、`refresh_token_expires_in`、`scope`、`token_type` JSON schema 是 OAuth-shaped payload；它不改變本 topic 的 fine-grained PAT-only decision。此 topic 不採用、保存、解析或暴露該 schema，也不以它擴大未來 provider contract。若未來評估 OAuth，必須以獨立 topic 重新鎖定 lifecycle、storage、refresh、failure 與 Port isolation。

## Retained Integration Reconciliation

human 已鎖定 GitHub Integration 仍是 Supporting BC，且現有 BC 文件與 canonical diagrams 必須保留。衝突樹中的 GraphQL SDL 只作為 future consuming Domain BC local-Infra GitHub adapter／schema topic 的 candidate material；本輪不驗證、移動、接受或以它建立 PR Reader local-exclusive ownership。GitHub Integration 僅提供 lower shared capability，不擁有 candidate、Domain Port 或 adapter／schema。

### Historical PC-10 Writeback Chain（Superseded）

下列 six-active-docs 與 bounded-context-map 的 writeback 是 PC-10 當時的歷史 chain，不是 current implementation authorization：

- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/architecture/bounded-contexts/pr-reader.md`
- `docs/github-api/README.md`
- `docs/architecture/diagrams/bounded-context-map/scene.js` → formal generated `index.html`

該歷史 chain 曾要求 docs 移除 GitHub Integration retirement claim，並以當時的 retained-Integration wording 重建 map。其中央 Integration construct／排除 local-Infra 的範圍已被後續 human 鎖定的 Domain-owned Port／local Infra direction 取代；不得將它當成 current contract、current acceptance，或 IM-09 的 Modify authorization。

## Local GitHub Infra Direction

human 已進一步鎖定：Domain BC 擁有自己的 Port；未來 concrete REST／GraphQL GitHub adapter 都屬於該 Domain BC 的 Infra，示意位置為 `<BC>/Infra/GitHub`。這個示意不決定任何 source path、Swift target、module 或 package。local REST adapter 可以使用 GitHub Integration 所提供的較低層 shared capability；local GraphQL adapter 維持 Apollo-only route，而它是否消費 credential capability 留待獨立 topic。GitHub Integration 不擁有、引用、符合或依賴任何 Domain-owned Port；Domain Core、UseCase 與 Port 也不依賴 GitHub Integration capability。

因此 Bounded Context Map 只可表達：每個 Domain Port 與 local adapter 的 ownership、local Infra 對 shared GitHub capability 的受限使用、shared capability 對 GitHub.com Outside 的邊界，以及 PR Inbox／PR Reader 的零相互 dependency。不得畫出 Integration → Domain Port edge、central Integration adapter conformer，或任何 runtime REST／GraphQL／authorization flow。GitHub Integration 保留作為 lower shared authorization capability 的長期 responsibility label；endpoint、DTO、infrastructure-failure 正規化與 Domain failure mapping 都由 consuming Domain BC local Infra 擁有。其具體 physical boundary 仍需 future topic 決定。

現行 architecture writeback 只可在 PR-15 approved 後依 IM-09 corrective re-entry 的 exact scope 進行：`docs/design-principles.md`、architecture README、bounded-contexts README／PR Inbox／PR Reader／GitHub Integration 文件、bounded-context map source／formal output、canonical Integration boundary canvas 的 source／BUILD／formal output，以及 lifecycle receipt policy 所允許的 current-bound receipt 或 truthful skipped cleanup。`docs/design-principles.md` 的精確替換是：Domain local Infra 擁有 concrete GitHub adapter、operation／endpoint、DTO、外部 infrastructure-failure 正規化與 own-Port 前的 Domain failure mapping；GitHub Integration 僅提供 lower shared authorization capability，不擁有、引用或符合任何 Domain Port，也不擁有 adapter／DTO／failure mapping。這是為落實既定 local-Infra direction 的 current chain；它不恢復 PC-10 的 central-adapter acceptance，也不擴張到 SDL、Swift、HTTP package 或未列明路徑。

## Current Lifecycle Receipt Gate

current lifecycle visual-check receipt 若宣稱 `pass`，它必須綁定 current canonical HTML 的 SHA-256 與 byte size。Implementer 只能依 `BUILD.md` 選擇：正式重跑 `visual-check` 並交付 current-bound receipt 與 sidecars，或在 Chrome／Chromium 無法使用時交付 `skipped` receipt 並移除過期 capture sidecars。Tester 必須驗證此 binding／cleanup，Reviewer 必須單獨對 IM-07 取得 fresh RV-07 verdict；RV-08 不得替代 RV-07。

## GraphQL Candidate Move Gate

`Schema.graphqls` 在 `graphql-schema-draft-plan` 的 PR-02 pending 期間維持 read-only，且本 topic 不移動它。PR-02 即使 approved 也只接受 reclassification，不放行 asset move。未來需要 GraphQL 的 Domain BC 必須另立 adapter／schema topic，先鎖定 consuming BC、candidate provenance、exact path（預期在該 BC 的 local Infra/GitHub boundary）、採用或重新取得、verification、Apollo adapter／interceptor 及 token／failure contract，才可執行任何 move／delete／materialization；GitHub Integration lower shared capability 不擁有 asset、Domain Port 或 adapter／schema。

## Delivery Responsibility 與歷史偏差

Plan-Creator 的 scope 僅限四份正式 planning artifacts；它不得交付或驗證長期 docs、architecture README、BC 文件、canvas、lifecycle HTML 或 generated evidence。Plan-Reviewer 通過後，獨立 Implementer 才能對這些 long-lived artifacts 執行受限 delivery；其後由獨立 Tester 驗證、獨立 Reviewer 出具 verdict，最後才交由 human review。

歷史事實：在本次 workflow remediation 前，long-lived docs、canvas、canonical lifecycle artifact 與兩組 containment candidate 曾於 Plan-Creator 階段出現在 worktree。這不是 approval，也不倒填為正確角色交付。繼任 Implementer 必須在 final delivery 前移除兩組 candidate，並重新確認 canonical artifacts；Tester 與 Reviewer 必須獨立驗證結果。

planning artifacts 記錄本次 contract 與後續實作切片，不能被誤當成已存在的 Swift API 或已完成的文件交付。
