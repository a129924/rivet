# GitHub Integration Authorization Boundary：計畫

## Goal

在不改變任何 Swift 實作的前提下，鎖定 GitHub Integration 擁有 future authorization seam：由 Integration future `GitHubTokenProvider` 交付 `GitHubAccessToken`，並在每個 GitHub request 交給 `RivetHTTPClient` 前注入或覆寫 Bearer `Authorization`。

## Non-Goal

不建立任何 Swift source、module、package、target、protocol、Keychain item 或 executable auth behavior；不實作 OAuth、refresh、401 retry、Keychain adapter、URLSession transport、DTO、GitHub API adapter 或 core Port failure mapping。

## In-Scope

- 初版 credential 為使用者預先提供的一個 fine-grained PAT。
- 鎖定 declaration-only future direction：`GitHubTokenProvider.token() throws -> GitHubAccessToken`。
- GitHub Integration future authorizer 為每個 GitHub request 設定或覆寫 `Authorization: Bearer …`。
- Plan-Reviewer 通過後，由獨立 Implementer 將已批准且可長期成立的 boundary 回寫到 GitHub Integration BC 文件、architecture navigation、Integration/HTTP boundary canvas 與 lifecycle artifact；其後由獨立 Tester、Reviewer 與 human review 依序驗證。

## Out-Of-Scope

- generic `TokenProvider`、`RivetHTTPClient` token dependency、constructor 變更或 HTTP package auth API。
- OAuth-shaped token payload 的採用、refresh token、401 retry、多帳號、GitHub Enterprise、PAT UI、Keychain identity／adapter。
- concrete network、HTTP status／decode policy、DTO、PR Inbox／PR Reader mapping，以及 core failure mapping。

## ReadOnly

- `README.md`、`docs/design-principles.md`、`docs/architecture/README.md` 與既有 Bounded Context 文件。
- `packages/RivetHTTPClient/` 的 source、tests、manifest 與 HTTP package structure canvas。
- root package、product source surface、既有 HTTP topics 與 core BC contracts。

## Written

- `analysis/github-integration-auth-boundary/requirements.md`
- `analysis/github-integration-auth-boundary/technical-spec.md`
- `plan/github-integration-auth-boundary/github-integration-auth-boundary.plan.md`
- `plan/github-integration-auth-boundary/github-integration-auth-boundary.step.md`

## Deleted

由後續 Implementer 在 final docs／diagram delivery 前移除兩組非交付 generated candidate：

- `docs/architecture/diagrams/github-integration-http-client-boundary/github-authorization-lifecycle.containment-candidate*`
- `docs/architecture/diagrams/github-integration-http-client-boundary/github-authorization-lifecycle.containment-candidate-2*`

本 Plan-Creator remediation 不執行刪除。

## Modify

- 後續 Implementer 修改 `docs/architecture/bounded-contexts/github-integration.md`：加入 authorization ownership、PAT-only limitation、Keychain Outside 與 core Port isolation。
- 後續 Implementer 修改 `docs/architecture/README.md`：連結 declaration-only lifecycle artifact，並描述其限制。
- 後續 Implementer 修改 `docs/architecture/diagrams/github-integration-http-client-boundary/scene.js`：區分 future Integration abstractions 與既有 HTTP package，且維持其 non-runtime-boundary purpose。
- 後續 Implementer 交付唯一允許的 canonical lifecycle source、HTML 與 canonical visual-check evidence：`github-authorization-lifecycle.json`、`github-authorization-lifecycle.html`、`github-authorization-lifecycle.visual-check.*`；不得將 containment candidate 納入交付。

## TestCase

| ID | 驗收 |
| --- | --- |
| TC-01 | 四份 planning artifacts 使用相同 slug，並包含本計畫指定 headings 與 Human Check。 |
| TC-02 | Implementer delivery 後，文件與兩張圖都表達 token／provider 只屬於 GitHub Integration；HTTP package 不取得、持有、refresh 或處理 token。 |
| TC-03 | Implementer delivery 後，canonical lifecycle 僅表達 request preparation、取得既有 PAT、Bearer header injection／overwrite 與 HTTP client raw execution；不含 OAuth、refresh、401 retry、concrete network、DTO 或 core mapping。 |
| TC-04 | Tester 獨立驗證 existing architecture canvas 的 artifact-local validate → build → enhance → verify，及 canonical lifecycle 的 Archify showcase validate → deliver → visual-check。 |
| TC-05 | Tester 確認兩組 containment candidate 已由 Implementer 移除，且交付只含 canonical lifecycle JSON／HTML／canonical visual-check evidence；Reviewer 再確認 `git diff --check` 與無 Swift／HTTP package drift。 |

## Future Swift Implementation Slices

1. **Integration contract foundation**：建立 GitHub Integration module、`GitHubAccessToken`、`GitHubTokenProvider` 及 fake-provider tests；需由獨立 topic 鎖定 module/package path。
2. **Keychain credential adapter**：讀取單一 PAT，驗證 delivery、missing 與 access failure；需先鎖定 Keychain service/account identity 與 entitlement 策略。
3. **GitHub request authorizer**：每次 request 取得 token，設定或覆寫 `Authorization`，並保留 URL、method、body 與其他 headers。
4. **Concrete HTTP transport**：實作 URLSession-backed `Transport`，維持 raw response 與 transport-error passthrough。
5. **GitHub API data adapter／DTO**：僅為一個已選定 read operation 建立授權 request 與 Integration-internal DTO handling。
6. **PR Inbox 或 PR Reader adapter**：各自獨立將 Integration output 映射到對應 core Port 與 failure contract。

每個 slice 都必須是獨立正式 topic，經 Plan-Reviewer gate 後才可實作，並停在其 human boundary。
