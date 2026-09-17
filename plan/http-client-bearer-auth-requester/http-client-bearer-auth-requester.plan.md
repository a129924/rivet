# HTTP Client Bearer Auth Requester

## Summary

`RivetHTTPClient` 已交付 GitHub-free、同步、pure value transformation 的 Bearer authorization capability：caller 先套用 `BearerAuth`，再將回傳的 `HTTPRequest` 交給既有 bare `Requester`；既有 `HTTPClient → Requester → Transport` pipeline、typed-throws contract 與 URLSession responsibility 均不變。原始 delivery commit 為 `5439798bdb779708dc00c0ad71f97675b85a18b5`。

使用者已採納 PR #36 的全部四則 review thread。本修正版只授權 selected review remediation，不取代 original plan，也不重開既有 scope、architecture、path 或 request-execution contract decision。

建議 Git branch 名稱：`feat/http-client-bearer-auth-requester`。僅為命名建議；本 plan 不授權建立、切換或推送 branch。

## Selected Review Thread Manifest（固定）

此 remediation 只處理 PR #36 的下列 exact thread ID；它們的 mapping 不得替換或擴張：

| Thread ID | 已鎖定 remediation |
| --- | --- |
| `PRRT_kwDOUFu0Cc6jPk81` | delivery ledger 的 phase、status、evidence、blocker 與 Last Updated truthfulness。 |
| `PRRT_kwDOUFu0Cc6jPo1k` | historical delivery deviation：initial pre-commit 因 Swift format issue 與缺少 local Biome 被拒；後續 completed frozen-lockfile local dependency installation、formatter correction、focused／full tests、full pre-commit 與 independent review，不得誤記為本輪 approval。 |
| `PRRT_kwDOUFu0Cc6jPo1r` | `docs/architecture/README.md` 的最小已交付 capability truth writeback。 |
| `PRRT_kwDOUFu0Cc6jPo1x` | `BearerAuth` diagnostics／reflection token redaction 與 fake-sentinel regression coverage。 |

CR-07 僅可對這四個 exact ID 回覆實際修改與 fresh verification evidence，才可逐一 resolve；不得處理其他 comment。

## Swift Implementation Handoff

### Goal

保留既有 request transformation 與 bare execution boundary，同時完成 selected review remediation：忠實更新 delivery ledger、以最小 architecture README writeback 記錄既有 capability，並讓既有 `BearerAuth` 的一般 diagnostics／reflection representation 不意外暴露 token。

### Worktree Delivery Boundary

所有 implementation、verification、commit、non-force push、selected PR reply 與 thread resolution 都只能在 feature worktree 的 `feat/http-client-bearer-auth-requester` branch 執行。dev worktree 不得寫入、修改或執行任何 delivery mutation。

### Non-Goal

- 不建立 authenticated requester、authentication flow 或 credential lifecycle。
- 不使用或修改 `AuthFlow`、既有 `Auth` protocol、`AuthRequester`、`Requester`、`HTTPClient`、`Transport` 或 URLSession。
- 不處理 token acquisition、token provider／source、provider bridge、OAuth、PAT、Keychain、refresh、401 recovery、retry 或 request replay。
- 不引入 `BearerRequester`、GitHub 型別、`GitHubAccessTokenProvider`、`GitHubCredentialError`、untyped throws、endpoint、DTO、BC failure mapping 或其他 authentication scheme。
- 不修改 architecture diagram、Bounded Context 文件、其他 docs、package manifest，或任一未列於 remediation Modify allowlist 的 path。
- 不聲稱 redaction 可防止 debugger 或 process-memory 存取；它只處理 accidental diagnostics／reflection exposure。

### In-Scope

- 四份正式 planning artifacts 的 correction，記錄 user-adopted all-four-thread remediation、initial delivery provenance、truthful gates 與 human boundary。
- Human 已授權唯一的 `BearerAuth.swift` file-local formatting policy exception：SwiftFormat 保留多行 conformance declaration 與下一行 opening brace；SwiftLint `opening_brace` 只可藉由緊鄰該 declaration 的單一 `// swiftlint:disable:next opening_brace` directive 抑制。不得改動全域 `.swiftlint`、其他 file rule、SwiftFormat configuration 或工具設定。
- 最小修改既有 `BearerAuth.swift`，加入 token-free `CustomStringConvertible`、`CustomDebugStringConvertible` 與 `CustomReflectable` representation；existing `init(token:)` 和 `RequestAuthorization.applying(to:)` signature 必須完全不變。
- 最小修改既有 `BearerAuthTests.swift`，以明確 fake token sentinel 驗證 `String(describing:)`、debug description 與 reflection 不含 sentinel，且 mirror 不揭露 token child。
- 最小修改 `docs/architecture/README.md`，記錄 caller-applied pure `RequestAuthorization`／`BearerAuth` capability、bare `Requester → Transport` responsibility 不變，且沒有 AuthFlow、credential provider、GitHub dependency、retry 或 lifecycle。
- focused BearerAuth tests、repository root 的 `swift test`、`packages/RivetHTTPClient` 內的 `swift test`、完整 pre-commit、已鎖定為 N/A 的 README-only docs verification、獨立 Reviewer review，以及 approved 後的一個 remediation delivery。兩個 full SwiftPM suite 必須分別保存 actual evidence。

### Out-Of-Scope

- Bearer-specific token acquisition failure、transport delegation failure、network side effect、response handling與 typed-throws tests。
- `RequestAuthorization.swift` 或任何 request-execution／Auth／GitHub integration surface 的修改。
- logs、error payload、public metadata 或其他 diagnostics mechanism；唯一允許的新 observability behavior 是 token-free description／debug／mirror result。
- PR title/body、reviewer、label、merge、rebase、force push 或不在這四則內的 review comments。

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

無。本次 remediation 不建立或刪除任何檔案；`RequestAuthorization.swift`、`BearerAuth.swift` 與 `BearerAuthTests.swift` 是 initial delivery 的既有 artifact，不能誤記為本輪新增。

### Modify

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/BearerAuth.swift`：既有 diagnostics／reflection redaction，以及唯一、緊鄰 `BearerAuth` declaration 的 `// swiftlint:disable:next opening_brace` directive；保留 SwiftFormat-required multiline layout。
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`
- `docs/architecture/README.md`

### Deleted

無。

### TestCase

- TC-01：維持 `Authorization: Bearer <token>` 注入，並覆寫 `Authorization`、`authorization` 或混合大小寫的既有 header。
- TC-02：維持 `applying(to:)` 不改變輸入 request；輸出 request 保留原 URL、method、body 與非 Authorization headers。
- TC-03：維持 `any RequestAuthorization` existential 使用 `BearerAuth` 時的 transformation 結果。
- TC-04：使用明確 fake token sentinel，驗證 `String(describing:)`、`debugDescription` 與 reflection 均不含 sentinel，且 mirror 不揭露 token child。
- TC-05：執行 focused BearerAuth tests、repository root 的 `swift test` 與 `packages/RivetHTTPClient` 內的 `swift test`；兩個 full SwiftPM suite 的實際 command、result 與 evidence 必須分開記錄，確認 bare request execution 無回歸。
- TC-06：執行完整 pre-commit，fresh proof 必須明確證明 SwiftFormat 與 SwiftLint 均通過，且 `BearerAuth.swift` 只有一個緊鄰 declaration 的 `opening_brace` suppression。docs verification 固定為 N/A，理由是本次僅為 `docs/architecture/README.md` prose change，repository 沒有適用的 docs validator；不得以 Tester 臨時判斷取代。

## Remediation Sequence

1. Plan-Creator 只更新四份 planning artifacts，將 initial delivery 與 selected review remediation 明確區分，且不寫入 implementation／docs artifact。
2. 獨立 Plan-Reviewer 以 fresh gate 審查 correction 的 scope、manifest、diagnostics redaction contract、唯一 file-local `opening_brace` exception、test plan、ledger 與 workflow gate；只有明示 `approved` 可進入 implementation。
3. Implementer 僅在 feature worktree 的 `feat/http-client-bearer-auth-requester` branch、三個 Modify paths 內實作 redaction、test 與最小 README truth writeback；`BearerAuth.swift` 僅可新增一個緊鄰 declaration 的 `// swiftlint:disable:next opening_brace` directive 並保留 SwiftFormat-required layout。不可修改 ReadOnly paths、全域或其他檔案 rule，亦不可重開 execution／architecture decision，且不得寫入 dev worktree。
4. Tester 僅在同一 feature worktree 獨立執行 TC-01 至 TC-06；root SwiftPM suite 與 standalone `RivetHTTPClient` SwiftPM suite 必須有分開的 actual evidence，並以 full pre-commit fresh proof 明確證明 SwiftFormat 與 SwiftLint 均通過。docs verification 依已鎖定 N/A justification 記錄。任何失敗均為 blocker，不得由 historical success 或 approval 取代。
5. Reviewer 獨立審查 source、docs、tests、verification evidence、secret exposure、scope／contract／workflow drift，包含唯一 directive、兩項 formatting tool 成功證據與無全域／其他檔案 rule 變更；只有明示 `approved` 可進入 delivery。
6. Implementer 僅在 feature worktree 的 `feat/http-client-bearer-auth-requester` branch 以單一 commit `fix(http-client): 補強 Bearer authorization review feedback` 交付、non-force push，然後只在 `PRRT_kwDOUFu0Cc6jPk81`、`PRRT_kwDOUFu0Cc6jPo1k`、`PRRT_kwDOUFu0Cc6jPo1r`、`PRRT_kwDOUFu0Cc6jPo1x` 回覆實際修改與 fresh verification evidence、再逐一 resolve。不得在 reply、commit message 或 diagnostics 寫入 token 或 fake sentinel，亦不得對 dev worktree 或其他 thread 進行 mutation。
7. thread resolution 完成後立即停在 human review boundary；不得自動 merge、rebase、force push、修改 PR metadata 或處理其他 comments。

## Acceptance

- original public API 與 nonthrowing transformation semantics 維持不變，`BearerAuth` 繼續只負責 caller-applied request transformation。
- description、debug description 與 reflection 不暴露 fake token sentinel 或 stored token；固定 representation 不洩漏 token length 或衍生 metadata，且不宣稱抵禦 debugger／process-memory 存取。
- architecture README writeback 精確反映已交付 capability，不擴張到 AuthFlow、credential provider、GitHub dependency、retry、lifecycle 或 execution ownership。
- diff 除四份 planning corrections 外，只包含三個 Modify paths；無新檔、無刪除、無 ReadOnly path 寫入；`BearerAuth.swift` 只有一個緊鄰 declaration 的 `opening_brace` suppression，且無全域或其他 file rule 變更。
- 只有獨立 Reviewer 明示 `approved` 且 focused tests、root SwiftPM suite、standalone `RivetHTTPClient` SwiftPM suite、full pre-commit 都有 fresh actual success evidence（後者明確證明 SwiftFormat 與 SwiftLint 均通過），並以 README-only docs-validator N/A justification 記錄後，才能在 feature worktree 依既有 human authorization commit、non-force push、reply、resolve，並停在 human review boundary。

## Assumptions

- `HTTPRequest` 是 value type，`HTTPHeaders.authorization` setter 以既有 lower-case canonical storage 唯一覆寫 Authorization，並保留其他 headers。
- initial delivery 曾先因 Swift formatting 與缺少 local Biome 被 pre-commit 拒絕，之後已完成 frozen-lockfile local dependency installation、formatter correction、focused／full tests、full pre-commit 與 independent review；此歷史不構成本次 remediation 的 approval 或 verification evidence。
- 本輪 remediation 曾發現 SwiftFormat 要求 `BearerAuth` 多行 declaration 的 opening brace 位於下一行，而 SwiftLint `opening_brace` 拒絕該 layout；Human 已選擇最小 file-local directive，而非 global tooling change。此 policy decision 不是 fresh test、Plan-Reviewer 或 Reviewer approval。
- 本次 README change 是使用者明確授權的最小 long-term truth writeback；不需要圖或 BC document 更新。
- README-only prose change 沒有 repository docs validator；docs verification 的 N/A 與理由已鎖定，Tester 只如實記錄，不重新決定。
