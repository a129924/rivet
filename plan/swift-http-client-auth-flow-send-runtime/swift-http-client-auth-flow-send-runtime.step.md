# Swift HTTPClient AuthFlow Send Runtime：Step Ledger

## Current Phase

review-pending。historical DL-02 已以 `c1c4bff` 完成 topic delivery、push 與當時五條 mapped thread resolution；這不是本輪 delivery claim。current post-delivery review-fix 已完成 PL-04、PR-04、IM-03 與 TE-03；尚未執行本輪 reviewer verdict、commit、push 或新的 thread resolution。

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
| RV-02 | Reviewer | approved | 在 TE-02 pass 後，獨立審查 implementation、tests、docs、diagrams 與 evidence。 | `approved`，無 scope／contract／workflow drift。 | Historical independent approval before DL-02; not a verdict for the current post-delivery correction. |
| DL-02 | Implementer | completed | RV-02 approved 後，以 human-confirmed commit message commit、push，更新既有 PR。 | single topic commit、push 與 corrected PR update evidence。 | Historical delivery completed at `c1c4bff`; the then-mapped five threads were resolved. This is historical fact only, not delivery evidence or a new delivery claim for PL-04. |
| HC-02 | Human | active | 審查 historical DL-02 更新後的 PR。 | human 明示下一步。 | Current PR review produced the four PL-04 mapped findings; it does not complete human review or authorize a new delivery. |
| PL-04 | Plan-Creator | completed | 將四則 post-delivery review finding 收斂為 package canvas ownership／compile-time correction、public terminal-error prose 與 ledger historical truth，並將 PR-02／PR-03 historical scope 與 PL-04 writable allowlist 分離。 | 四份 artifacts 一致限制 canvas 不表達 runtime dataflow，鎖定 `c44def5` 的指定 invariant、兩條 direct type edges、historical delivery truth 與 exact resolve gate。 | 本次 planning amendment；不構成 PR-04 approval、implementation、testing、review、delivery 或 thread resolution。 |
| PR-04 | Plan-Reviewer | approved | 獨立審查 PL-04 的 scope、四條 exact mapping、historical delivery wording、canvas ownership boundary 與 execution readiness。 | `approved`；否則 needs-rework、blocked 或 human-check。 | Independent Plan-Reviewer approval。 |
| IM-03 | Implementer | completed | 僅在 PR-04 approved 後，修改嚴格 allowlist：`docs/architecture/README.md`、package `scene.js` 與 pipeline `index.html`；將 runtime invariant 替換為 `c44def5` 的指定原文、加入兩條 AuthRequester type edges，並補 overview terminal-error prose。`BUILD.md` 只有 subtitle 被證實不一致時才可修改。 | 只變更 locked paths；不改 lifecycle、BC README、Swift behavior、Canvas interaction、build semantics 或 auth policy。 | Bounded IM-03 handoff；無本輪 delivery claim。 |
| TE-03 | Tester | passed | 獨立驗證 IM-03 的 Canvas source/artifact、docs truth、scope 與既定 checks。 | SwiftPM tests、`git diff --check`、Canvas validate/build/enhance/verify、source/generated consistency 與 rebuild 後 light/dark desktop manual visual evidence 均明確記錄。 | Independent Tester PASS：root suite 39、package suite 53；Canvas checks 5／15／23 均 zero warnings；rebuild byte-identical；4 張 manual light/dark desktop captures 均 pass；diff check pass，enhancer 維持相對 `c44def5` zero diff。 |
| RV-03 | Reviewer | pending | 在 TE-03 pass 後，獨立審查四項 review fixes、scope、contract、historical truth 與 Tester evidence。 | `approved`，沒有 scope／contract／workflow drift。 | 待 TE-03 handoff。 |
| DL-03 | Implementer | pending | 僅在 RV-03 approved 後，以 human-confirmed commit message commit、push，更新既有 PR，並 resolve 四條本輪 mapped threads。 | single bounded correction delivery、push 與四條 exact resolution evidence；五條 prior resolved threads 不變。 | 待 RV-03 approval；不得將 DL-02 historical evidence 視為本輪 delivery。 |
| HC-03 | Human | pending | 審查 DL-03 更新後的 PR。 | human 明示下一步。 | DL-03 完成後立即停止；不得 merge、release 或處理其他 comment。 |

## File Boundary

### Goal

由 internal `AuthRequester`（非 HTTPClient）drives generic AuthFlow，並回傳最後 successful response 或 typed direct-finish error。

### Non-Goal

concrete auth policy、OAuth／GitHub／Apollo integration、public AuthRequester API、Requester semantics 變更與 Canvas feature 擴張。

### In-Scope

- HTTPClient auth overload 移除、AuthRequester source/test 新增、HTTPClient bare regression coverage。
- docs／diagrams ownership correction：internal AuthRequester tag、AuthRequester → Auth edge 與 Requester failure/no-receive branch。
- post-delivery correction：package canvas 僅保留 ownership／compile-time invariant，自 `c44def5` 恢復 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`，加入 AuthRequester → HTTPRequest／HTTPResponse edges；architecture overview 明列 public no-response terminal error；ledger 如實保留 DL-02 historical delivery。

### Out-Of-Scope

- Auth／AuthFlow／Requester／Transport declarations、HTTP request-response values、manifest、facades、GitHubIntegration、其他 BC、historical topic artifacts。
- Canvas runtime behavior、enhancer implementation 與 BUILD.md build semantics。
- lifecycle source／generated artifact／visual evidence、bounded-context README、HTTPURL validation／transport-failure semantics，以及五條 prior resolved threads。

### Written

- four planning artifacts；implementation 新增 `AuthRequester.swift` 與 `AuthRequesterTests.swift`。
- 上列 implementation files 屬 PR-02 historical scope；PL-04 不新增檔案。

### Modify

- PR-02 historical scope 曾修改 `HTTPClient.swift`、`HTTPClientError.swift`、`HTTPClientTests.swift`、`TestDoubles.swift`；這些 paths 在 PL-04 是 ReadOnly。
- PR-02／PR-03 historical scope 曾修改 architecture overview／BC README、AuthFlow lifecycle source-generated-evidence、HTTP package structure source-generated output，以及 BUILD.md 的 ownership／dependency-only topology subtitle、scene.js 的既定 internal tag／Auth dependency；它們不是 PL-04 writable authorization。
- PL-04 writable allowlist 嚴格為 `docs/architecture/README.md` public terminal-error prose、package `scene.js` 的指定 runtime-invariant replacement／兩條 direct type edges，以及由 pipeline 產生的 `index.html`。`BUILD.md` 只有 subtitle 被證實不一致時才是 conditional writable path；現有 subtitle 維持不變。

### ReadOnly

- `Auth.swift`、`Requester.swift`、`Transport.swift`、`URLSessionTransport.swift`、HTTP request-response values、manifest、Auth tests、method facades。
- `enhance-accessibility.js`（先恢復 feature branch 對 dev 的 merge-base `c44def5` 版本且 zero diff）、Canvas runtime semantics、BUILD.md build semantics 與現有 subtitle、GitHubIntegration、other BCs、map and historical topic artifacts。PL-04 唯一 `scene.js` 例外是自 `c44def5` 恢復指定 invariant 原文與新增兩條 direct type edge；`BUILD.md` 只有 subtitle 被證實不一致時才是 conditional writable path；其餘 scene content 仍為 ReadOnly。
- PL-04 的 lifecycle artifacts、bounded-context README、既定 Requester failure/no-receive branch、HTTPURL validation／transport-failure contract semantics、Canvas layout／interaction，以及五條 prior resolved threads。

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
| TC-08 | documentation artifacts | lifecycle 維持既定 Requester failure/no-receive branch；package canvas 有 internal AuthRequester tag、AuthRequester → Auth／HTTPRequest／HTTPResponse direct dependencies，只表達 ownership／compile-time truth，且 invariant 逐字為 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`；Canvas rebuild gates 與 independent light/dark desktop manual visual review 已記錄。 |
| TC-09 | public terminal error prose | architecture overview 將 `HTTPClientError.authFlowFinishedWithoutResponse` 列為 public、non-transport generic terminal error，不改變 transport failure responsibility。 |

## Review Thread Mapping and Resolve Completion

PR review history 與 thread IDs 是 external immutable traceability；本 topic 不重寫、複製、替換或 reopen 它們。

### Historical Resolved Threads

下列五條已隨 historical DL-02 `c1c4bff` delivery resolved。它們保留為事實追溯，不是 PL-04 的待辦，亦不得再次 resolve。

| Thread ID | Historical mapped correction | Resolution state |
| --- | --- | --- |
| `r4002558496` | lifecycle `AuthRequester` state 的 tag 改為 internal package ownership，並重建 HTML 與 visual-check evidence。 | resolved in historical DL-02. |
| `r4002598251` | `enhance-accessibility.js` 恢復為 feature branch 對 dev 的 merge-base `c44def5`，並維持 zero diff。 | resolved in historical DL-02. |
| `r4002598254` | package canvas 加入 `AuthRequester → Auth` injected dependency，並重建 artifact。 | resolved in historical DL-02. |
| `r4002598257` | lifecycle 加入 Requester failure terminal branch，明示 error 直接向上傳遞且不呼叫 `receive(_:)`。 | resolved in historical DL-02. |
| `r4002598261` | TE-02 維持 pending，直到 independent manual visual review evidence 記錄完成。 | resolved in historical DL-02. |

### Current Pending Threads

| Thread ID | Mapped correction | Resolve completion condition |
| --- | --- | --- |
| `r4002938379` | package canvas 移除「generic 地送出 flow action 並回灌 raw response」runtime invariant，並自 `c44def5` 恢復 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`。 | IM-03 source 與 generated artifact 只表達 ownership／compile-time truth，且指定 invariant 逐字一致；TE-03 Canvas pipeline、source/generated consistency 與 manual visual evidence 通過；RV-03 approved；DL-03 push 完成。 |
| `r4002938384` | package canvas 加入 `AuthRequester → HTTPRequest` 與 `AuthRequester → HTTPResponse` direct compile-time dependencies。 | 兩條 edge 出現在 source 與 generated artifact；TE-03 Canvas checks／manual evidence 通過；RV-03 approved；DL-03 push 完成。 |
| `r4002938388` | ledger 如實將 DL-02 記為 historical `c1c4bff` delivery，並分離 current PL-04 review-fix pending state。 | PL-04 artifacts 與 step ledger 一致，不將 historical delivery 誤寫為 current delivery；PR-04、TE-03、RV-03 完成且 DL-03 push 完成。 |
| `r4002938393` | architecture overview 列出 public `HTTPClientError.authFlowFinishedWithoutResponse` 是 non-transport generic terminal error。 | docs prose 與 public enum 一致；TE-03 docs/static verification 通過；RV-03 approved；DL-03 push 完成。 |

四個 current mapped correction 全部完成、PR-04 approved、獨立 Tester pass、獨立 Reviewer approval 且 DL-03 已 push 至 PR 後，才可 resolve 對應四條 thread；不得 resolve 其他 thread。

## Stop Conditions

- PR-04 或 RV-03 requires rework, blocker or human-check：停止並交 Dispatcher；不得自行交付或重開已鎖定 ownership。
- PR-04、TE-03 與 RV-03 approval／pass 前不得 commit、push、更新 PR 或 resolve current thread；DL-02 historical evidence 不可視為 current correction delivery evidence。
- DL-03 完成 PR update 與四條 exact thread resolution 後立即停止於 HC-03；不得自行 merge、release 或處理其他 review comment。
