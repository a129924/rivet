# Swift HTTPClient AuthFlow Send Runtime：Step Ledger

## Current Phase

review-pending。PR-02 已 approved、IM-02 已 completed、TE-02 已 passed；等待獨立 Reviewer 審查 implementation、evidence 與 delivery readiness。

先前的 PR-01、IM-01、TE-01、RV-01、DL-01 與 HC-01 僅對已 supersede 的 HTTPClient driver 有效，現全部失效；既有 commit 與 Draft PR 不可視為本次架構的 delivery 或 human-review readiness evidence。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-02 | Plan-Creator | completed | 將 driver ownership 改鎖定為 AuthRequester，重設 boundary、tests、gates 與 prior-delivery truth。 | 四份 artifacts 一致，明確無 HTTPClient auth shim。 | 本次 amendment artifacts。 |
| PR-02 | Plan-Reviewer | approved | 獨立審查 planning artifacts、scope／contract drift 與 implementation readiness。 | `approved`；否則 needs-rework 或 human-check。 | Independent Plan-Reviewer approval。 |
| IM-02 | Implementer | completed | 移除 HTTPClient auth driver，新增 internal AuthRequester 及 tests，更新 allowed docs／diagrams。 | Locked algorithm、file boundary、initial-fit preservation 均滿足。 | Bounded implementation diff。 |
| TE-02 | Tester | passed | 執行 TC-01～TC-08 與 diagram verification。 | focused/full SwiftPM、diff check、Archify、Canvas 與 visual evidence 完整通過。 | Independent Tester pass verdict。 |
| RV-02 | Reviewer | pending | 獨立審查 implementation、tests、docs、diagrams 與 evidence。 | `approved`，無 scope／contract／workflow drift。 | Pending independent Reviewer verdict。 |
| DL-02 | Implementer | pending | 依 human-confirmed commit message commit、push，更新既有 Draft PR。 | single topic commit、push 與 Draft PR update evidence。 | 尚無 commit、push 或 Draft PR update evidence。 |
| HC-02 | Human | pending | 審查更新後的 Draft PR。 | human 明示下一步。 | 尚未進入 human review。 |

## File Boundary

### Goal

由 internal `AuthRequester`（非 HTTPClient）drives generic AuthFlow，並回傳最後 successful response 或 typed direct-finish error。

### Non-Goal

concrete auth policy、OAuth／GitHub／Apollo integration、public AuthRequester API、Requester semantics 變更與 Canvas feature 擴張。

### In-Scope

- HTTPClient auth overload 移除、AuthRequester source/test 新增、HTTPClient bare regression coverage。
- docs／diagrams ownership correction，以及 initial-fit support preservation and verification。

### Out-Of-Scope

- Auth／AuthFlow／Requester／Transport declarations、HTTP request-response values、manifest、facades、GitHubIntegration、其他 BC、historical topic artifacts。
- initial-fit 以外的 Canvas behavior 改動。

### Written

- four planning artifacts；implementation 新增 `AuthRequester.swift` 與 `AuthRequesterTests.swift`。

### Modify

- `HTTPClient.swift`、`HTTPClientError.swift`、`HTTPClientTests.swift`、`TestDoubles.swift`。
- architecture overview／BC README、AuthFlow lifecycle source-generated-evidence、HTTP package structure source-generated output。

### ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、HTTP request-response values、manifest、Auth tests、method facades。
- Canvas support semantics、GitHubIntegration、other BCs、map and historical topic artifacts。

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
| TC-08 | documentation artifacts | ownership truth and all diagram gates pass; initial-fit resize and share/pan-zoom preservation do not regress. |

## Stop Conditions

- RV-02 requires rework, blocker or human-check：停止並交 Dispatcher；不得自行交付或重開已鎖定 ownership。
- RV-02 approval 前不得 commit、push 或更新 Draft PR；既有 Draft PR 不可視為 ready。
- DL-02 完成 Draft PR update 後立即停止於 HC-02；不得自行 merge、release 或處理 review comment。
