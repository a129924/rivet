# Swift HTTPClient AuthFlow Send Runtime

## Summary

Supersede draft-branch 的 `HTTPClient` AuthFlow driver。`HTTPClient` 僅負責 bare execution；新的 internal `AuthRequester` 注入 `Requester` 與 `any Auth`，以 generic loop 執行 flow。PR-02／PR-03 的已完成 implementation、lifecycle 與 BC writeback 是 historical scope；PL-04 只收斂 package canvas 的 ownership／compile-time truth、architecture failure prose 與 historical ledger truth，不改 Canvas runtime behavior。

## Goal

將 multi-request AuthFlow orchestration 放在 Requester decorator layer，保持 raw HTTP facade、Requester single-request semantics 與 AuthFlow policy ownership 清楚分離。

## Non-Goal

不實作或指定 OAuth、GitHub、token、Bearer header、401 refresh、retry cap、Apollo behavior 或 package-external AuthRequester API。

## Key Changes

- 移除 `HTTPClient.execute(_:auth:)`，不保留 compatibility overload；bare `execute(_:)` 與 HTTP facades 不變。
- 新增 internal `AuthRequester`，在每個 `execute(_:)` 新建 flow、一次 `start()`，並只按 `.send → Requester.execute → receive` 迴圈執行；`finish` 回傳最後 response 或 throw typed no-response error。
- Requester／Transport failure 直接傳遞；driver 不分析 raw status，也不自行產生 retry／token policy。
- architecture overview 將 public `HTTPClientError.authFlowFinishedWithoutResponse` 列為非 transport generic terminal error；不變更任何既定 transport failure responsibility。
- package canvas 自 `c44def5` 恢復並逐字採用 `不變量：HTTPURL validation 與 HTTPClientError 分別表達 URL construction、transport failure；HTTP status 維持 raw response`，以取代 `.send → raw response → receive` runtime invariant，並加入 `AuthRequester → HTTPRequest`、`AuthRequester → HTTPResponse` direct compile-time dependencies；保持既定 internal tag、`AuthRequester → Auth`／`AuthRequester → AuthFlow` dependencies。lifecycle 不在 PL-04 修改。`BUILD.md` 與 `scene.js` subtitle 只描述 package ownership／compile-time dependency，不可描述 runtime flow 或 raw response；現有 `BUILD.md` subtitle 不需變更。

## File Boundaries

### Written

- 本 topic 四份 planning artifacts。
- PR-02 historical implementation 曾新增 `AuthRequester.swift` 與 `AuthRequesterTests.swift`；AuthRequester 為 internal，test target 以 `@testable import` 存取。PL-04 不新增檔案。

### Modify

- PR-02 historical scope 曾修改 `HTTPClient.swift`、`HTTPClientError.swift`、`HTTPClientTests.swift`、`TestDoubles.swift`；它們在 PL-04 都是 ReadOnly。
- PR-02／PR-03 historical scope 曾修改 architecture overview／BC README、AuthFlow lifecycle source-generated-evidence 與 HTTP package-structure source-generated artifact；它們不構成 PL-04 writable paths。
- PL-04 writable allowlist 嚴格為 architecture overview 的 public terminal-error prose、package `scene.js` 的指定 invariant／兩條 direct type edges，以及由既定 pipeline 產生的 `index.html`。`BUILD.md` 只在 subtitle 被證實不一致時才可修改；現有 subtitle 不需變更。`scene.js` 其餘 build semantics、layout 與 scene content 維持不變。

### ReadOnly

- AuthFlow declaration、Requester／Transport chain、HTTP value types、manifest、Auth tests、request／verb facades。
- `enhance-accessibility.js` 必須先恢復為 feature branch 對 dev 的 merge-base `c44def5` 版本並維持 ReadOnly，且相對於 `c44def5` 必須是 zero diff；Canvas runtime behavior 不屬本 topic。
- PL-04 的 AuthFlow lifecycle source／generated artifact／visual evidence、bounded-context README、既定 Requester failure/no-receive branch、HTTPURL validation 與 transport-failure semantics 均為 ReadOnly；只自 `c44def5` 恢復 canvas 中指定 invariant wording，不重新定義 contract。
- 歷史 topic artifacts、GitHubIntegration、其他 BC 與 bounded-context map。

### Deleted

無檔案 deletion、move 或 rename；移除的僅為 HTTPClient auth overload 與其專屬 test assertions。

## TestCase

- bare HTTPClient raw dispatch／facades 維持不變，且不再提供 auth overload。
- AuthRequester 的 single send、multi send、direct finish、new-flow-per-execute、4xx／5xx raw response 與 no-retry failure semantics。
- focused/full SwiftPM、`git diff --check`、Canvas validate/build/enhance/verify、source/generated consistency、指定 invariant 逐字比對與 rebuild 後 light/dark desktop independent manual visual review；獨立 Tester 必須在 step ledger 記錄 manual evidence，才可完成 TE-03。Archify lifecycle 與 BC README 不重建或修改。

## Delivery Gates

1. 獨立 Plan-Reviewer 必須重新 approval 此 amendment；此前不得實作。
2. 獨立 Implementer 依 file contract 修改，然後由獨立 Tester 執行全部 test 與 diagram gates。
3. 獨立 Reviewer 審查 scope、internal visibility、無 HTTPClient auth shim、documentation truthfulness 與 Tester evidence。
4. 此 post-delivery correction 的獨立 Plan-Reviewer、Tester 與 Reviewer 依序批准後，才可由 Implementer 依 `git-commit-convention` 取得 human-confirmed commit message，更新 feature branch 與既有 PR。
5. push 後只能 resolve 四個本輪 mapped threads；五個 prior resolved threads 必須維持不變。更新 PR 後停在 human review；不 merge、release 或自處理其他 review comment。

既有 PR thread 的精確 ID mapping 與 resolve completion condition 只以 step ledger 為追蹤真相；本輪四個 mapped correction 完成、Tester pass、Reviewer approval 與 push 後才可 resolve。五個 prior resolved threads 僅保留 historical traceability，不得再次 resolve。
