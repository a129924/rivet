# HTTP Client Bearer Auth Requester：需求

## Goal

保留已交付的 `RivetHTTPClient` GitHub-free、同步且無副作用的 Bearer request transformation；caller 先套用 authorization，再將轉換後的 request 交給既有 bare `Requester` 發送，既有 HTTP execution pipeline 與 typed-throws surface 維持不變。

本次是使用者已採納 PR #36 全部四則 review thread 的受限 remediation。既有 scope、architecture、request-execution path 與 public transformation contract 均維持鎖定；只補正 delivery ledger、最小 long-term truth writeback，以及既有 `BearerAuth` 的 diagnostics／reflection token redaction。

建議 branch 名稱為 `feat/http-client-bearer-auth-requester`。此為命名建議；本 topic 不定義或執行 Git 操作。

## Selected Review Thread Manifest（固定）

下列 ID 是本次 remediation 唯一可回覆與 resolve 的 PR #36 thread；mapping 不得重開或替換：

| Thread ID | 已鎖定 remediation |
| --- | --- |
| `PRRT_kwDOUFu0Cc6jPk81` | delivery ledger 的 phase、status、evidence、blocker 與 Last Updated truthfulness。 |
| `PRRT_kwDOUFu0Cc6jPo1k` | historical delivery deviation：initial pre-commit 因 Swift format 與 local Biome 缺失被拒，之後完成 frozen-lockfile local dependency installation、formatter correction、focused／full tests、full pre-commit 與 independent review；此歷史不構成本輪 approval。 |
| `PRRT_kwDOUFu0Cc6jPo1r` | `docs/architecture/README.md` 的最小 long-term truth writeback。 |
| `PRRT_kwDOUFu0Cc6jPo1x` | `BearerAuth` diagnostics／reflection token redaction 與其 regression coverage。 |

CR-07 只能對這四個 exact ID 回覆實際修改與本輪 verification evidence，之後才逐一 resolve；不得處理其他 comment。

## Execution and Delivery Boundary

所有 implementation、verification、commit、non-force push、selected PR reply 與 thread resolution 都只能從 feature worktree 的 `feat/http-client-bearer-auth-requester` branch 執行。dev worktree 不得寫入、修改或執行任何 delivery mutation。

## Non-Goal

- 不建立 authenticated requester、authentication flow 或 credential lifecycle。
- 不使用或修改 `AuthFlow`、既有 `Auth` protocol 或 `AuthRequester`。
- 不處理 token acquisition、OAuth、PAT、Keychain、refresh、401 recovery、retry 或 request replay。
- 不引入 GitHub 型別、token-source protocol、token provider bridge、`BearerRequester`、untyped `throws`，或與 `GitHubAccessTokenProvider`／`GitHubCredentialError` 的相容性設計。
- 不修改 `Requester`、`HTTPClient`、`Transport`、URLSession 或它們既有的 typed-throws surface。
- 不修改 architecture diagram、Bounded Context 文件或其他 docs；本次 architecture writeback 僅限一處已交付 public capability 的最小事實陳述。

## Original Delivered Capability

- `RequestAuthorization` 與 `BearerAuth` 已由初始 topic delivery 建立，初始交付 commit 為 `5439798bdb779708dc00c0ad71f97675b85a18b5`。
- `BearerAuth` 以 `String` token 初始化，透過既有大小寫不敏感 `HTTPHeaders.authorization` setter，產生含 `Authorization: Bearer <token>` 的新 `HTTPRequest`。
- caller 明確執行 `auth.applying(to: request)` 後，再將回傳值交給既有 `requester.execute(...)`；發送責任不移轉。
- original capability 的 transformation tests 與 bare execution regression coverage 仍是本次 remediation 的回歸基線，而非本次新建的 public capability。

## In-Scope

- 修正四份正式 planning artifacts，使其忠實記錄 selected review remediation、已交付 provenance、後續 verification/review/delivery gates 與 human boundary。
- Human 已針對本次 remediation 的 formatter/linter conflict 授權唯一、檔案內且緊鄰 `BearerAuth` declaration 的 `// swiftlint:disable:next opening_brace` suppression。`SwiftFormat` 繼續擁有多行 `BearerAuth` conformance declaration 的 layout，opening brace 必須位於下一行；不得修改全域 `.swiftlint`、其他 file rule 或任何工具設定。
- 最小修改既有 `BearerAuth`，使一般 `String(describing:)`、debug description 與 reflection 不暴露 stored token，同時保持既有 public initializer 與 `RequestAuthorization` contract 不變。
- 在既有 `BearerAuthTests` 加入使用明確 fake token sentinel 的 redaction regression coverage，驗證描述與 reflection 不含 sentinel；不得使用真實 token。
- 最小修改 `docs/architecture/README.md`，記錄 `RivetHTTPClient` 的 caller-applied pure `RequestAuthorization`／`BearerAuth` transformation capability，並明示 bare `Requester → Transport` execution responsibility 不變，且沒有 AuthFlow、credential provider、GitHub dependency、retry 或 lifecycle。
- 重新執行 focused BearerAuth tests、root SwiftPM suite 的 `swift test`、standalone `RivetHTTPClient` SwiftPM suite 的 `swift test`、完整 pre-commit。兩個 full suite 必須各自記錄實際 evidence。
- docs verification 固定為 N/A：本次僅修改 `docs/architecture/README.md` 的 prose，已確認 repository 沒有適用於此 README-only change 的 docs validator；不得由 Tester 臨時決定或取代此決定。

## Out-Of-Scope

- 任何 Bearer-specific token acquisition failure、transport delegation failure、network side effect、response handling或 typed-throws tests。
- Bearer 以外的 authentication scheme、endpoint、DTO、BC failure mapping、GitHub API client adoption。
- 除 token-free diagnostics／reflection representation 外，任何 logs、diagnostics、public metadata 或 error payload 的新增或重設計。
- Debugger 或 process-memory 存取防護；本次 redaction 只降低意外 diagnostics／reflection 洩漏風險，不宣稱 token 不存在於 process memory 或不可被 debugger 讀取。
- 任一未列於 remediation artifact manifest 的 source、test、manifest、package target、adapter、documentation 或 diagram path。

## Success Criteria

- 已交付的 `RequestAuthorization`／`BearerAuth` transformation 行為維持不變：Authorization 值精確為 `Bearer <token>`，大小寫不同的既有 Authorization value 只被該值取代一次，輸入 request 保持不變。
- `String(describing:)`、`debugDescription` 與 `Mirror(reflecting:)` 不包含測試使用的 fake token sentinel；redaction 不改變 initializer 或 `RequestAuthorization.applying(to:)` signature。
- `BearerAuth.swift` 只含一個、緊鄰 declaration 的 `opening_brace` suppression，並保留 SwiftFormat 所需的多行 opening-brace layout；不改動全域或其他檔案的 formatter/linter rule。
- `docs/architecture/README.md` 只新增上述已交付 capability 的長期真相，不改變既有 execution responsibility 或 architecture decision。
- focused BearerAuth tests、root SwiftPM suite、standalone `RivetHTTPClient` SwiftPM suite 與完整 pre-commit 均成功，且兩個 suite 各有獨立 actual evidence；full pre-commit 的 fresh evidence 必須明確證明 SwiftFormat 與 SwiftLint 均通過。docs verification 依已鎖定 N/A justification 記錄；獨立 Reviewer 明示 `approved` 後，才可進行單一 remediation commit、non-force push、truthful PR replies 與 thread resolution。

## Remediation Artifact Manifest

### Planning Artifact Corrections

- `analysis/http-client-bearer-auth-requester/requirements.md`
- `analysis/http-client-bearer-auth-requester/technical-spec.md`
- `plan/http-client-bearer-auth-requester/http-client-bearer-auth-requester.plan.md`
- `plan/http-client-bearer-auth-requester/http-client-bearer-auth-requester.step.md`

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/RequestAuthorization.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift`
- 所有 architecture diagram、Bounded Context 文件與未列出的 docs／tracked paths。

### Written

無。本次 remediation 不建立任何新檔案；原 capability 的 source 與 test files 是 initial delivery provenance，不得誤記為本輪新建。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/BearerAuth.swift`：既有 redaction conformance，加上且僅加上一個緊鄰 `BearerAuth` declaration 的 `// swiftlint:disable:next opening_brace` directive，並保留 SwiftFormat 所需 layout。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`
- `docs/architecture/README.md`

### Deleted

無。

## TestCase

- TC-01：維持 Bearer header 注入，並覆寫不同大小寫的既有 Authorization header。
- TC-02：維持輸入 request 不變，輸出 request 保留 URL、method、body 與其他 headers。
- TC-03：維持透過 `any RequestAuthorization` existential 使用 `BearerAuth` 時的 transformation 行為。
- TC-04：以明確 fake token sentinel 驗證 `String(describing:)`、`debugDescription` 與 reflection 均不含該值。
- TC-05：執行 focused BearerAuth tests、repository root 的 `swift test` 與 `packages/RivetHTTPClient` 內的 `swift test`；root 與 standalone suite 的實際 command、result 與 evidence 必須分開記錄，確認 bare request execution 無回歸。
- TC-06：完整 pre-commit 通過，fresh evidence 必須明確證明 SwiftFormat 與 SwiftLint 均通過；docs verification 固定記為 N/A，理由是 README-only prose change 沒有 repository docs validator。所有失敗均如實回報，不得以 approval 取代證據。
