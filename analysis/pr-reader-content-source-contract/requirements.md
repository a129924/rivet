# PR Reader Content Source Core 契約：需求

## Goal

建立 `pr-reader-content-source-contract`，交付 PR Reader 自有、可編譯的 Domain Port 與單一 PR 完整語意閱讀快照。Core 以每檔可選 `patch` 作唯一 diff payload；metadata-only 檔案仍可成功回傳。

## In-Scope

- root SwiftPM `RivetPRReader` library／Core target 與其 test target；PR Reader Core 自有的 `Outcome`、PR identity、快照模型、檔案參照、檔案變更、review／check 語意及 `PRContentSource`。
- 一次取得單一 PR 的完整快照：背景、有序 conversation、reviews、inline threads、files、可缺的 review decision 與 check rollup。Port producer 保證 snapshot 的 PR ID 與 request 相同、同一快照內檔案參照唯一、檔案順序保留。
- Reader failure 僅為 `.notReadable`、`.unavailable`、`.contentNotRepresentable`。最後一種用於未來 mapper 無法保真表示必要資料；合法 optional nil 不構成 failure。本 topic 不實作 mapper。
- fake Port／Core value 測試、SwiftPM 編譯與 target 依賴隔離驗證；同步既有 root package graph 靜態測試的 exact expected sets，使其接受新增 Reader product／targets 且完整保留既有 graph assertions；完成後將已成立的 Core 契約與新 failure 語意回寫 PR Reader BC 文件。

## Out-Of-Scope

- Facade、UseCase、Client Protocol、Adapter、GitHub／HTTP／GraphQL／transport、live fetch、cache、巨大 diff 分段或任何寫入。
- Swift／WebView bridge、TS contract 擴充、viewed 持久化與事件回查。Core 不提供 WebView `snapshotId`、snapshot-local `fileId` 或 `viewed`。
- 不在本 topic 決定 PR ID 對 WebView `pullRequestId` 的 encoding、snapshot 版本生命週期、file reference 映射／回查、Swift 權威 viewed 來源、過期事件處理或 patch／count 轉換。
- 不搬移、驗證、接受或納入目前的候選 GraphQL SDL；不建立 shared BC Core／Failure，也不修改 PR Inbox 或 TS contracts。其他既有 BC tests 維持唯讀，唯一 test-only compatibility 例外是 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 root graph expected-set 同步。

## Non-Goal

本 topic 不交付真實資料讀取、Reader Infra／mapper、完整 Swift／WebView 相容性、TS 六狀態擴充、viewed persistence 或任何 GitHub 寫入。fake fixture 通過不代表這些能力已完成。

## Success Criteria

- SwiftPM 可編譯 Reader-only Core，且其 public Port 能以 Reader PR ID 回傳 `Outcome<PRContentSnapshot, PRReaderFailure>`。
- 多檔、有序、六種檔案變更、review／check 狀態、可選 patch 與合法 optional nil 均可由 Core value 表達；無 patch 檔案保留 metadata，不因缺少整份 unified diff 失敗。
- `checkRollup == nil` 與存在但 checks 為空可區分；不同名稱的 run 與 commit status 可共存並維持順序。
- Reader Core 不依賴 PR Inbox、GitHub、HTTP、transport 或 WebView；沒有宣稱 Swift／WebView 已接線。
- 四份同 slug planning artifacts 經獨立 Plan-Reviewer 明示 `approved` 前不得進入實作；完成後仍需獨立 Tester、Reviewer 與 human review。

## Existing Evidence and Constraints

- `docs/architecture/bounded-contexts/pr-reader.md` 將完整閱讀快照、Reader-owned Port 與 Swift viewed 權威列為邊界；現有 failure 敘述尚待實作完成後回寫新增的 `.contentNotRepresentable`。
- `surfaces/pr-reader-webview/src/diff-rendering/contracts/diff-view-model.ts` 的 `patch?` 為 optional、`status` 僅四種；`diff-snapshot.ts` 與 `viewed-state-change.ts` 使用 WebView 自有的 PR／snapshot／file identity。本 Core 六種狀態不能直接宣稱可完整送入現有 TS contract。
- baseline `Package.swift` 原先沒有 Reader target；IM-01 working tree 已加入該 graph；`Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls` 是未驗證 candidate，不可因建立 Core target 而納入。
- IM-01 runtime evidence：focused Reader 11 tests、`swift build`、`swift package dump-package` 通過；root `swift test` 唯一 failure 是既有 `GitHubIntegrationTests.StaticIsolationTests.packageDeclaresTheLockedTargetGraph` 的 products／targets exact set 尚未包含新 Reader graph。這是 package graph compatibility sync，不改 public API、BC 責任或產品範圍。

## Planning Status

PR-01 曾由獨立 Plan-Reviewer 明示 `approved`。IM-01 runtime evidence 隨後發現 root full-suite 唯一 failure 是既有 package graph exact set 未同步；Plan-Reviewer 對此 implementation blocker 明示 `needs-rework`。本輪僅修正四份 artifacts，加入單一 test-only compatibility path 與驗收；修訂後仍待 fresh independent re-review，不構成 implementation、test 或 delivery approval。

## Last Updated

2026-09-23
