# PR Inbox Swift Contract Baseline：Step Ledger

## Current Phase

最終 outcome／code review（Delivered-baseline Amendment Rework；RV-03 pending）

## Scope Register

- Goal：建立 root SwiftPM `RivetPRInbox` target 的 Core contract、refresh-only Facade 與 semantic fake。
- Non-Goal：GitHub Adapter、HTTP dependency、外部 query／DTO／network、UI、PR Reader、cache、sync、排序與 release。
- In-Scope：target-local Outcome、models、failure、Port、internal membership filter、Facade、manifest/test target、semantic fake tests 與 PR Inbox BC truth writeback。
- Out-Of-Scope：HTTP/auth/rate-limit／`InfraUnknownError`、GitHub pagination／incomplete-result、跨 BC contract、current/snapshot state。
- ReadOnly：`docs/github-api/`、`packages/RivetHTTPClient/`、GitHub Integration BC 文件、其他 BC source、既有 source-layout／HTTP client artifacts 與全域 architecture 文件。
- Written：四份本 topic artifacts、PRInbox target-local source、`Tests/RivetPRInboxTests/` tests/fake。
- Deleted：僅實際 source 建立時的 `Sources/BoundedContexts/PRInbox/.gitkeep`。
- Modify：root `Package.swift` 與 `docs/architecture/bounded-contexts/pr-inbox.md` 的既定 target／contract truth writeback。

## Amendment Scope Register

- Goal：以 `RivetPRInbox` target-local `Result` typealias 取代 custom `Outcome` enum，維持專案 success／failure 用語與 public API semantics。
- Non-Goal：重開 baseline target、source path、Facade、membership、failure 或任何 architecture decision。
- In-Scope：四份同 topic artifacts；`Sources/BoundedContexts/PRInbox/Outcome.swift`；直接證明 alias／public API 語意所需的既有 `Tests/RivetPRInboxTests/`。
- Out-Of-Scope：shared Core target、跨 BC type 或 Failure 搬移、新 dependency、GitHub Integration、`RivetHTTPClient`、其他 BC、全域 architecture、lint／format rules、manifest 與 BC 文件。
- ReadOnly：baseline 的其他 production source/tests、root `Package.swift`、PR Inbox BC 文件、`docs/github-api/`、`packages/RivetHTTPClient/`、GitHub Integration BC 文件、其他 BC source、既有 source-layout／HTTP client artifacts 與全域 architecture 文件。
- Written：四份同 topic artifacts；在 PR-02 approval 後僅 `Outcome.swift` 與直接必要的既有 PR Inbox tests。
- Deleted：無。
- Modify：`Outcome.swift` 的 custom enum declaration 改為 locked `Result` typealias；既有 PR Inbox tests 僅限直接必要的 alias/API semantics assertion。

## TestCase

| ID | 驗證 | Expected evidence |
| --- | --- | --- |
| TC-01 | manifest 與 target path | root manifest 可解析，`RivetPRInbox` 使用既有 PRInbox path。 |
| TC-02 | fake 與 targeted tests | Swift tests 通過，fake 僅提供 semantic candidate。 |
| TC-03 | membership | 僅保留 open 且直接要求目前使用者 review 的 item。 |
| TC-04 | empty inbox | 空集合回傳 `.success([])`。 |
| TC-05 | failure | `.unavailable` 原樣傳遞，無其他 failure case。 |
| TC-06 | dependency isolation | target、imports、manifest 沒有 HTTP client、GitHub integration 或 network dependency。 |
| TC-07 | scope isolation | diff 只含列明的 artifact、manifest、PRInbox source/tests 與 BC 文件；不驗證排序、pagination、external query 或 DTO。 |
| TC-08 | Result alias syntax | Swift 6 編譯 `public typealias Outcome<Success: Sendable, Failure: Error & Sendable> = Result<Success, Failure>`，且具體 `Outcome` 維持 Sendable。 |
| TC-09 | API semantic preservation | `ReviewRequestSource`、`PRInboxFacade` 與既有 tests 持續使用 `Outcome` 的 `.success(...)`／`.failure(...)`；membership、來源順序、empty success 與 `.unavailable` passthrough 不變。 |
| TC-10 | amendment scope isolation | diff 只含四份 topic artifacts、`Outcome.swift` 及直接必要的既有 PR Inbox tests；沒有 manifest、BC 文件、dependency、其他 BC 或規則變更。 |

## Ledger

| ID | Status | Owner role | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立四份正式 artifacts，記錄 locked scope、contract、change map、TestCase 與 human boundary。 | 同一 slug 的 requirements、technical spec、plan、step 均存在。 | 本 topic 四份 artifact paths 已寫入；此 handoff 不構成 approval。 |
| PR-01 | pending | Plan-Reviewer | 獨立檢查四份 artifacts 的一致性、PR Inbox boundary、scope、public contract、TestCase 與停止條件。 | Plan-Reviewer 提供明示 verdict。 | 待獨立審查；不得由 ledger status 推導 approval。 |
| IM-01 | pending | Implementer | 僅在 PR-01 明示 `approved` 後，實作受限 root target、PRInbox source/tests 與 BC truth writeback。 | TC-01 至 TC-07 的實作前提已納入交接，且沒有未授權 path 變更。 | 待 PR-01 approval 與 Implementer handoff。 |
| TE-01 | pending | Tester | 獨立執行已定義的 manifest、targeted tests、dependency 與 scope checks。 | 回報 TC-01 至 TC-07 的逐項結果與 blocker。 | 待 Implementer 明示完成交接。 |
| RV-01 | pending | Reviewer | 獨立審查實作 scope 與 Tester evidence。 | Reviewer 提供明示 verdict。 | 待 Tester handoff。 |
| PC-02 | completed | Plan-Creator | 更新四份同 slug artifacts，記錄 delivered-baseline 的 `Result` typealias amendment、受限 change map、TC-08 至 TC-10 與 human boundary。 | 四份 artifacts 對 amendment scope、typealias contract、validation 與 routing 一致。 | 2026-09-04 已更新四份同 topic artifacts；不構成 PR-02 approval。 |
| PR-02 | completed | Plan-Reviewer | 獨立審查 amendment artifacts 的 `Result` typealias syntax、target-local ownership、Failure boundary、change map、TC-08 至 TC-10 與 workflow。 | Plan-Reviewer 提供明示 verdict。 | 已收到獨立 Plan-Reviewer 明示 `approved`。 |
| IM-02 | completed | Implementer | 在 PR-02 明示 `approved` 後，將 `Outcome.swift` custom enum 改為 locked `Result` typealias，並只在必要時修改直接受影響的既有 tests。 | 僅授權 amendment paths 變更，且不改既有 facade/membership/failure semantics。 | 已完成；實際 scope 僅 `Sources/BoundedContexts/PRInbox/Outcome.swift` 與 `Tests/RivetPRInboxTests/ContractTests.swift`。 |
| TE-02 | completed | Tester | 獨立執行 manifest、Swift tests、format、lint、coverage、diff check，並回報 TC-08 至 TC-10 與既有 baseline semantics 未受影響的結果。 | 每一個指定 command 與 testcase 都有明示結果或 blocker。 | 已收到 Tester 對 TC-01 至 TC-10 明示 `approved`；commands：`swift package dump-package`、`swift test`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`scripts/check-swift-coverage.sh`、`git diff --check`。 |
| RV-02 | needs-rework | Reviewer | 獨立審查 amendment scope、code 與 Tester evidence。 | Reviewer 提供明示 verdict。 | 已收到 `needs-rework`：plan 仍含 custom `Outcome` enum declaration，且 ledger 未如實記錄 PR-02、IM-02、TE-02 evidence。 |
| PC-03 | completed | Plan-Creator | 只修正四份同 topic artifacts：以 locked `Result` typealias 取代 plan 中殘留的 custom declaration，並對齊已收到的 evidence 與後續 gates。 | 四份 artifacts 對 amendment contract、scope、verdict 與下一個獨立審查 gate 一致；不修改 source、tests 或其他 path。 | 本次 artifacts 回修已寫入；不構成 PR-03 approval。 |
| PR-03 | completed | Plan-Reviewer | 獨立審查 PC-03 artifacts：確認所有 amendment contract 中的 `Outcome` declaration 均為 locked `Result` typealias，且 evidence／phase／routing 無虛構 approval。 | Plan-Reviewer 提供明示 verdict。 | 已收到獨立 Plan-Reviewer 明示 `approved`。 |
| RV-03 | pending | Reviewer | 在 PR-03 明示 `approved` 後，獨立重審未變更的 amendment source／test scope 與 TE-02 evidence。 | Reviewer 提供明示 verdict。 | PR-03 已 `approved`；待 RV-03 verdict，不得重跑或重寫未授權 scope。 |
| HC-02 | pending | Human | 審閱 RV-03 結果與既有 draft PR #12 的 amendment diff。 | Human 明示後續決策。 | RV-03 verdict 後停止自動前進；不可自行 merge、release 或處理 review comments。 |

## Blockers

- baseline 已交付於 feature branch `feat/pr-inbox-swift-contract-baseline` 的 commit `2db4d13` 與既有 draft PR #12；歷史 PC-01 至 RV-01 status 保留原樣，不得回填為 approval。
- RV-02 已明示 `needs-rework`。PC-03 已完成其 artifact-only 回修，且 PR-03 已明示 `approved`；目前等待 RV-03 verdict，尚無 source、test 或 scope blocker。

## Human Check

- PR-03 的 `approved` 僅代表 planning artifacts 可前進至 RV-03，不代表 RV-03 approval 或 delivery 結果。
- RV-03 明示結果後停止自動前進，交由 human 審閱既有 draft PR #12；不可自行 merge、release 或處理 review comments。

## Last Updated

2026-09-04
