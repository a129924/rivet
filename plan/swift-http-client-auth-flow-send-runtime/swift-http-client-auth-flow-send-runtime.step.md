# Swift HTTPClient AuthFlow Send Runtime：Step Ledger

## Current Phase

review-pending。PR-03 已 approved、IM-02 已 completed、TE-02 已 passed；等待獨立 Reviewer 審查 corrected implementation、evidence 與 delivery readiness。TE-02 的 human-authorized evidence exception 與 generated `visualReview` sidecar pending 狀態維持不變。

先前的 PR-01、IM-01、TE-01、RV-01、DL-01 與 HC-01 僅對已 supersede 的 HTTPClient driver 有效，現全部失效；既有 commit 與 Draft PR 不可視為本次架構的 delivery 或 human-review readiness evidence。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-02 | Plan-Creator | completed | 將 driver ownership 改鎖定為 AuthRequester，重設 boundary、tests、gates 與 prior-delivery truth。 | 四份 artifacts 一致，明確無 HTTPClient auth shim。 | 本次 amendment artifacts。 |
| PR-02 | Plan-Reviewer | approved | 獨立審查 planning artifacts、scope／contract drift 與 implementation readiness。 | `approved`；否則 needs-rework 或 human-check。 | Independent Plan-Reviewer approval。 |
| PL-03 | Plan-Creator | completed | 將 PR review correction 收斂為限定 diagram 修正，將 enhancer 鎖定回 merge-base，並重設失效 gate。 | 四份 artifacts 一致；enhancer 為 ReadOnly 且相對 `c44def5` zero diff；BUILD.md 僅允許 ownership／dependency-only subtitle，scene.js 另允許 internal tag 與 Auth dependency。 | 本次 correction artifacts。 |
| PR-03 | Plan-Reviewer | approved | 獨立審查 PL-03 與四份 artifacts，確認沒有重開已鎖定 AuthRequester contract 或擴張 Canvas runtime scope。 | `approved`；否則 needs-rework、blocked 或 human-check。 | Independent Plan-Reviewer approval。 |
| IM-02 | Implementer | completed | 完成 PR-03 批准後的限定 diagram correction：恢復 enhancer 至 `c44def5` 且 zero diff、修改 ownership／dependency-only subtitle、補 package canvas internal tag／Auth edge 與 lifecycle failure/no-receive branch。 | 只修改允許的 diagram files；不改 HTTP/Auth implementation contract、Canvas runtime semantics、BUILD build semantics 或其他 scene content。 | Corrected bounded implementation handoff。 |
| TE-02 | Tester | passed | 執行 TC-01～TC-08 與 diagram verification。 | focused/full SwiftPM、diff check、Archify、Canvas 均通過；並在 ledger 記錄獨立 manual visual review evidence。 | Human-authorized evidence exception: temporary capture paths are no longer retrievable by this agent. Independent Tester manual review PASS of `page-2026-09-14T06-48-04-134Z.png`, `page-2026-09-14T06-48-33-542Z.png`, `page-2026-09-14T06-49-29-620Z.png`, and `page-2026-09-14T06-50-33-136Z.png` (1440×900 light/dark; 2048×1320 light/dark): no clipping／overflow; ownership-only subtitle、planes、internal AuthRequester 與 Auth injection/dependency readable; no semantic collision; balanced 2048 composition. Generated `visualReview` sidecar remains pending unchanged. |
| RV-02 | Reviewer | pending | 在新的 TE-02 pass 後，獨立審查 implementation、tests、docs、diagrams 與 evidence。 | `approved`，無 scope／contract／workflow drift。 | Reset pending corrected implementation and Tester evidence. |
| DL-02 | Implementer | pending | RV-02 approved 後，以 human-confirmed commit message commit、push，更新既有 PR。 | single topic commit、push 與 corrected PR update evidence。 | Reset pending; prior PR history is not current delivery evidence. |
| HC-02 | Human | pending | 審查更新後的 PR。 | human 明示下一步。 | Reset pending corrected PR update. |

## File Boundary

### Goal

由 internal `AuthRequester`（非 HTTPClient）drives generic AuthFlow，並回傳最後 successful response 或 typed direct-finish error。

### Non-Goal

concrete auth policy、OAuth／GitHub／Apollo integration、public AuthRequester API、Requester semantics 變更與 Canvas feature 擴張。

### In-Scope

- HTTPClient auth overload 移除、AuthRequester source/test 新增、HTTPClient bare regression coverage。
- docs／diagrams ownership correction：internal AuthRequester tag、AuthRequester → Auth edge 與 Requester failure/no-receive branch。

### Out-Of-Scope

- Auth／AuthFlow／Requester／Transport declarations、HTTP request-response values、manifest、facades、GitHubIntegration、其他 BC、historical topic artifacts。
- Canvas runtime behavior、enhancer implementation 與 BUILD.md build semantics。

### Written

- four planning artifacts；implementation 新增 `AuthRequester.swift` 與 `AuthRequesterTests.swift`。

### Modify

- `HTTPClient.swift`、`HTTPClientError.swift`、`HTTPClientTests.swift`、`TestDoubles.swift`。
- architecture overview／BC README、AuthFlow lifecycle source-generated-evidence、HTTP package structure source-generated output，以及 BUILD.md 的 ownership／dependency-only topology subtitle、scene.js 的同一 subtitle／internal tag／Auth dependency。

### ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、HTTP request-response values、manifest、Auth tests、method facades。
- `enhance-accessibility.js`（先恢復 feature branch 對 dev 的 merge-base `c44def5` 版本且 zero diff）、Canvas runtime semantics、BUILD.md build semantics、scene.js 中 internal tag／Auth dependency／subtitle 以外的內容、GitHubIntegration、other BCs、map and historical topic artifacts。

### Deleted

無檔案 deletion、move 或 rename；僅移除 HTTPClient 的 auth overload／tests。

## TestCase

| ID | Scenario | Expected result |
| --- | --- | --- |
| TC-01 | bare HTTPClient | one request/response behavior and facades unchanged; no auth overload. |
| TC-02 | one send | new flow, one start, one requester send, one receive, returns response. |
| TC-03 | multi send | same Requester executes ordered requests; returns final response. |
| TC-04 | direct finish | typed no-response error; zero send and receive. |
| TC-05 | repeated execute | injected Auth persists; each execution makes a distinct flow. |
| TC-06 | requester failure | exact error escapes; no receive or follow-up action/retry. |
| TC-07 | non-success status | 4xx/5xx raw response reaches flow. |
| TC-08 | documentation artifacts | internal AuthRequester tag、AuthRequester → Auth edge 與 Requester failure/no-receive branch 正確；all diagram gates pass and independent manual visual review is documented. |

## Review Thread Mapping and Resolve Completion

既有 PR review history 與其 thread IDs 是外部 immutable traceability；本 topic 不重寫、複製或替換它們。

| Thread ID | Mapped correction | Resolve completion condition |
| --- | --- | --- |
| `r4002558496` | lifecycle `AuthRequester` state 的 tag 改為 internal package ownership，並重建 HTML 與 visual-check evidence。 | Internal tag 已出現在 source 與 generated artifact，且獨立 visual review 已記錄。 |
| `r4002598251` | `enhance-accessibility.js` 恢復為 feature branch 對 dev 的 merge-base `c44def5`，並維持 zero diff。 | 相對 `c44def5` 的 enhancer diff 為零；BUILD build semantics 未變。 |
| `r4002598254` | package canvas 加入 `AuthRequester → Auth` injected dependency，並重建 artifact。 | source 與 generated artifact 均表達該 dependency，且圖表驗證與 visual review 已記錄。 |
| `r4002598257` | lifecycle 加入 Requester failure terminal branch，明示 error 直接向上傳遞且不呼叫 `receive(_:)`。 | source、generated artifact 與 TC-06 evidence 均確認 failure/no-receive branch。 |
| `r4002598261` | TE-02 維持 pending，直到 independent manual visual review evidence 記錄完成。 | visual-check evidence 與 ledger 均已記錄 independent manual review，且 Tester 明示 TE-02 pass。 |

五個 mapped correction 全部完成、獨立 Tester pass、獨立 Reviewer approval 且 correction 已 push 至 PR 後，才可 resolve 對應既有 thread；不得新增、替換或遺失 thread ID。

## Stop Conditions

- PR-03 或 RV-02 requires rework, blocker or human-check：停止並交 Dispatcher；不得自行交付或重開已鎖定 ownership。
- PR-03 與 RV-02 approval 前不得 commit、push、更新 PR 或 resolve thread；既有 PR history 不可視為 current delivery evidence。
- DL-02 完成 PR update 後立即停止於 HC-02；不得自行 merge、release 或處理 review comment。
