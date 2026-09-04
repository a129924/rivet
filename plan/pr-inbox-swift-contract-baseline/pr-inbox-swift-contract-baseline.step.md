# PR Inbox Swift Contract Baseline：Step Ledger

## Current Phase

規劃審查

## Scope Register

- Goal：建立 root SwiftPM `RivetPRInbox` target 的 Core contract、refresh-only Facade 與 semantic fake。
- Non-Goal：GitHub Adapter、HTTP dependency、外部 query／DTO／network、UI、PR Reader、cache、sync、排序與 release。
- In-Scope：target-local Outcome、models、failure、Port、internal membership filter、Facade、manifest/test target、semantic fake tests 與 PR Inbox BC truth writeback。
- Out-Of-Scope：HTTP/auth/rate-limit／`InfraUnknownError`、GitHub pagination／incomplete-result、跨 BC contract、current/snapshot state。
- ReadOnly：`docs/github-api/`、`packages/RivetHTTPClient/`、GitHub Integration BC 文件、其他 BC source、既有 source-layout／HTTP client artifacts 與全域 architecture 文件。
- Written：四份本 topic artifacts、PRInbox target-local source、`Tests/RivetPRInboxTests/` tests/fake。
- Deleted：僅實際 source 建立時的 `Sources/BoundedContexts/PRInbox/.gitkeep`。
- Modify：root `Package.swift` 與 `docs/architecture/bounded-contexts/pr-inbox.md` 的既定 target／contract truth writeback。

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

## Ledger

| ID | Status | Owner role | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立四份正式 artifacts，記錄 locked scope、contract、change map、TestCase 與 human boundary。 | 同一 slug 的 requirements、technical spec、plan、step 均存在。 | 本 topic 四份 artifact paths 已寫入；此 handoff 不構成 approval。 |
| PR-01 | pending | Plan-Reviewer | 獨立檢查四份 artifacts 的一致性、PR Inbox boundary、scope、public contract、TestCase 與停止條件。 | Plan-Reviewer 提供明示 verdict。 | 待獨立審查；不得由 ledger status 推導 approval。 |
| IM-01 | pending | Implementer | 僅在 PR-01 明示 `approved` 後，實作受限 root target、PRInbox source/tests 與 BC truth writeback。 | TC-01 至 TC-07 的實作前提已納入交接，且沒有未授權 path 變更。 | 待 PR-01 approval 與 Implementer handoff。 |
| TE-01 | pending | Tester | 獨立執行已定義的 manifest、targeted tests、dependency 與 scope checks。 | 回報 TC-01 至 TC-07 的逐項結果與 blocker。 | 待 Implementer 明示完成交接。 |
| RV-01 | pending | Reviewer | 獨立審查實作 scope 與 Tester evidence。 | Reviewer 提供明示 verdict。 | 待 Tester handoff。 |

## Blockers

無。

## Human Check

- Plan-Reviewer 以外不得將任何 ledger status 或 evidence 視為 approval。
- Reviewer 明示結果後停止自動前進，交由 human 決定後續 commit、push、draft PR 與 review 動作。

## Last Updated

2026-09-04
