# Swift HTTPClient AuthFlow Send Runtime

## Summary

Supersede draft-branch 的 `HTTPClient` AuthFlow driver。`HTTPClient` 僅負責 bare execution；新的 internal `AuthRequester` 注入 `Requester` 與 `any Auth`，以 generic loop 執行 flow。diagram 只修正此 ownership 與 Requester failure truth，不改 Canvas runtime behavior。

## Goal

將 multi-request AuthFlow orchestration 放在 Requester decorator layer，保持 raw HTTP facade、Requester single-request semantics 與 AuthFlow policy ownership 清楚分離。

## Non-Goal

不實作或指定 OAuth、GitHub、token、Bearer header、401 refresh、retry cap、Apollo behavior 或 package-external AuthRequester API。

## Key Changes

- 移除 `HTTPClient.execute(_:auth:)`，不保留 compatibility overload；bare `execute(_:)` 與 HTTP facades 不變。
- 新增 internal `AuthRequester`，在每個 `execute(_:)` 新建 flow、一次 `start()`，並只按 `.send → Requester.execute → receive` 迴圈執行；`finish` 回傳最後 response 或 throw typed no-response error。
- Requester／Transport failure 直接傳遞；driver 不分析 raw status，也不自行產生 retry／token policy。
- 將 flow ownership truth 回寫至 architecture prose、lifecycle 與 package structure：package canvas 標示 internal `AuthRequester`、加入 `AuthRequester → Auth` injected dependency；lifecycle 表達 Requester failure 直接向上傳遞且不呼叫 `receive(_:)`。`BUILD.md` 與 `scene.js` subtitle 僅描述 package ownership／compile-time dependency，不可描述 runtime flow 或 raw response。

## File Boundaries

### Written

- 本 topic 四份 planning artifacts。
- `AuthRequester.swift` 與 `AuthRequesterTests.swift`；AuthRequester 為 internal，test target 以 `@testable import` 存取。

### Modify

- `HTTPClient.swift`、`HTTPClientError.swift`、`HTTPClientTests.swift`、`TestDoubles.swift`。
- architecture overview／BC README、AuthFlow lifecycle source-generated-evidence、HTTP package-structure source-generated artifact。
- `BUILD.md` 只可修改 ownership／dependency-only topology subtitle；`scene.js` 只可修改同一 subtitle、internal `AuthRequester` tag 與 `AuthRequester → Auth` dependency；其餘 build semantics 與 scene content 維持不變。

### ReadOnly

- AuthFlow declaration、Requester／Transport chain、HTTP value types、manifest、Auth tests、request／verb facades。
- `enhance-accessibility.js` 必須先恢復為 feature branch 對 dev 的 merge-base `c44def5` 版本並維持 ReadOnly，且相對於 `c44def5` 必須是 zero diff；Canvas runtime behavior 不屬本 topic。
- 歷史 topic artifacts、GitHubIntegration、其他 BC 與 bounded-context map。

### Deleted

無檔案 deletion、move 或 rename；移除的僅為 HTTPClient auth overload 與其專屬 test assertions。

## TestCase

- bare HTTPClient raw dispatch／facades 維持不變，且不再提供 auth overload。
- AuthRequester 的 single send、multi send、direct finish、new-flow-per-execute、4xx／5xx raw response 與 no-retry failure semantics。
- focused/full SwiftPM、`git diff --check`、Archify delivery／visual review、Canvas delivery／visual review；獨立 Tester 必須在 step ledger 記錄 manual visual review evidence，才可完成 TE-02。

## Delivery Gates

1. 獨立 Plan-Reviewer 必須重新 approval 此 amendment；此前不得實作。
2. 獨立 Implementer 依 file contract 修改，然後由獨立 Tester 執行全部 test 與 diagram gates。
3. 獨立 Reviewer 審查 scope、internal visibility、無 HTTPClient auth shim、documentation truthfulness 與 Tester evidence。
4. Reviewer approval 後才由 Implementer 依 `git-commit-convention` 取得 human-confirmed commit message，更新 feature branch 與既有 Draft PR。
5. Draft PR 更新後停在 human review；不 merge、release 或自處理 review comment。

既有 PR thread 的精確 ID mapping 與 resolve completion condition 只以 step ledger 為追蹤真相；完成 mapped correction、Tester pass、Reviewer approval 與 push 後才可 resolve 既有 thread。
