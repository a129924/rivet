# PR Reader Content Source Core 契約：Step Ledger

## Current Phase

RV-01 已由獨立 Reviewer 明示 `approved`，findings none；目前進入 `DL-01` delivery／commit preparation。尚未 stage、commit、push 或開 draft PR，HC-01 仍 pending。

## Topic

`pr-reader-content-source-contract`；所有規劃與未來實作僅限 feature worktree。`dev` worktree 不得寫入本 topic 任何檔案。

## Scope Register

- Goal：Reader-owned、可編譯 `PRContentSource` 與完整單一 PR Core 快照，逐檔可選 patch。
- In-Scope：Reader Core target、public semantic values／failure／Port、fake tests、manifest、完成後 PR Reader BC truth writeback。
- Out-Of-Scope：Facade／UseCase／Client Protocol／Adapter／live fetch、Swift／WebView bridge、TS 六狀態擴充、viewed persistence、GraphQL SDL asset 處理。
- ReadOnly：README、設計原則、全域架構、TS contracts、GitHub API catalog、其他 BC source、既有 tests、候選 SDL、PR Reader 根目錄 `.gitkeep`；唯一 test-only 例外為下列 Modify path。
- Written：四份同 slug artifacts；approval 後 Reader `Core/` source 與 `Tests/RivetPRReaderTests/`。
- Deleted：無。
- Modify：approval 後 root `Package.swift`；實作完成後 PR Reader BC 文件的 Core／failure truth；唯一新增 path `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 僅同步 products／targets exact expected sets，保留既有 entries、mapping、assertions、helpers 與 behavior，不加入 Reader semantic assertions。
- Non-Goal：不宣稱真實資料取得、WebView 接線、viewed persistence 或 GitHub 寫入完成。

## TestCase

- TC-01 至 TC-08 依 [執行計畫](pr-reader-content-source-contract.plan.md)：manifest、public fake Port、六狀態／有序多檔、patch／optional、check rollup、review／三 failure、SwiftPM build／focused Reader tests／root swift test、exact root graph 與包含唯一 test-only 例外的 diff／docs scope。
- fake fixture 僅驗 public shape 與表示能力；snapshot ID 相等、file reference 唯一屬 future producer contract，待 concrete mapper 另驗。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立同 slug requirements、technical spec、plan、step，記錄已鎖定範圍、public shape、後續決策與驗收。 | 四份 artifacts 已寫於 feature worktree；不構成審查或 gate approval。 |
| PR-01 | approved | Plan-Reviewer | 獨立審查四份 artifacts 的一致性、Reader／WebView 邊界、六狀態依賴、failure、scope、測試與 workflow；明示 verdict。 | 獨立 Plan-Reviewer 明示 `approved`：四份 artifacts 一致，Core-only target、optional patch、六狀態、三種 failure、TS／bridge 後續邊界及 fake-test 限制均符合既定契約；required fixes 無。Human 已明確同意記錄此結果；本 verdict 僅通過 planning review。 |
| IM-01 | completed | Implementer | 僅在有效 planning approval 後，於 feature worktree 完成受限 Core、tests、manifest、唯一 root graph compatibility test 與 PR Reader BC truth writeback，交接變更及實作證據。 | 原 Implementer 明示完成：唯一 static graph test 只同步核准的 products／targets expected sets；focused `swift test --filter PRReader` 11 tests／2 suites pass；root `swift test` 101 tests／14 suites pass；`swift build` pass；`swift package dump-package` pass 且 Reader path／dependencies 正確；`git diff --check` pass。changed paths 僅四份 artifacts、`Package.swift`、Reader Core 6 files、Reader tests 2 files、PR Reader BC doc、唯一 graph test；dev worktree clean。producer ID／reference obligations 仍待 concrete mapper；未交付 Infra／bridge／viewed／TS compatibility。此為 Implementer evidence，只 handoff TE-01。 |
| TE-01 | approved | Tester | IM-01 完成後，獨立驗證 TC-01 至 TC-08 與必要命令，回報逐項結果或 blocker。 | 獨立 `/root/swift_tester` 明示 `approved`：fresh writable rerun `swift test --filter RivetPRReader` 11 tests／2 suites exit 0（初次 sandbox cache 權限 run 不採信）；root `swift test` 101 tests／14 suites exit 0；`swift build` exit 0；`swift package dump-package` 只新增 Reader product／regular target／test target且 dependencies 正確；package describe JSON 顯示 Core path 只有 6 個 Swift files、SDL 未納入；`git diff --check` pass；staged diff empty；changed paths 符合 allowlist；唯一 graph test 只有 expected-set additions 與 line wrap；dev clean 且 base 相同。Contract coverage 完整；remaining gaps 僅 out-of-scope producer／Infra／TS／bridge／viewed。此 verdict 只通過 TE-01。 |
| RV-01 | approved | Reviewer | TE-01 後獨立審查 public contract、scope、BC truth、測試證據與阻礙分類，明示 verdict。 | 獨立 `/root/code_reviewer` 明示 `approved`，findings none：public API 與 spec 完全一致；Core 使用 per-file optional patch 且無 top-level unified diff；target／dependencies／exact graph、BC truth、changed-path allowlist、dev clean、`git diff --check` 與 TE-01 evidence 均接受。remaining risks 僅 out-of-scope producer／TS／bridge／viewed。Reviewer 補跑因 sandbox cache／build DB 權限 exit 1，不列為新驗證證據且不影響 TE-01 既有 fresh pass。此 verdict 只放行 DL-01 preparation。 |
| DL-01 | pending | Implementer | 僅在 RV-01 `approved` 且無重大問題時，依使用者授權完成 topic commit、push、以 `dev` 為 base 開 draft PR；保留 staged diff 語意檢查與 human-confirmed commit。 | RV-01 已 `approved`，進入 commit preparation；尚待 staged diff 由 `$git-commit-convention` 檢查語意邊界並提出 message，且須取得 human 對 commit message 的確認。尚未 commit／push／draft PR，不 merge、不 release。 |
| HC-01 | pending | Human | 在 draft PR 檢查 Core-only 契約、failure truth、TS prerequisite 與未接線邊界。 | DL-01 後停止自動前進；待 human review。 |
| PR-02 | needs-rework | Plan-Reviewer | 審查 IM-01 blocker 是否需要回到 planning，並明示修正範圍。 | 明示 `needs-rework`：唯一新增 Modify path 為 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 exact graph expected-set compatibility sync；同步 TC-01／TC-07／TC-08 與 planning status，修訂後 fresh re-review。required scope 不改 public API、BC 責任或產品能力。 |
| PC-02 | completed | Plan-Creator | 只修訂四份正式 artifacts，加入唯一 test-only compatibility 例外、exact graph 規則、runtime evidence 與 re-review route。 | 四份 artifacts 已同步；未修改 Swift source／tests、未實作、未 commit／push／PR，不構成 re-approval。 |
| PR-03 | approved | Plan-Reviewer | Fresh independent review PC-02：確認唯一 test-only path、exact expected-set 變更、既有 graph assertions preservation、TC-01／TC-07／TC-08、IM-01 pause 與 workflow。 | 獨立 `/root/formal_plan_reviewer` 明示 `approved`，required fixes 無：四份 artifacts 只新增 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` Modify；products 只加 `RivetPRReader`，targets 只加 `RivetPRReader`／`RivetPRReaderTests`；既有 assertions、helpers、mappings、behavior 保留，TC-01／TC-07／TC-08 已同步，原 contract 無 drift，且 static test 尚未修改。僅放行恢復同一 IM-01。 |

## Blockers

- 目前沒有已知 implementation、verification 或 review blocker；IM-01 completed、TE-01 approved、RV-01 approved。唯一 current step 是 DL-01 delivery／commit preparation。
- Producer ID／reference obligations 仍待 future concrete mapper 驗證；Infra、Swift／WebView bridge、viewed persistence 與 TS compatibility 未交付，均不得由 IM-01、TE-01 或 RV-01 推導完成。

## Human Check

- 使用者已授權無重大問題且獨立 gates 通過後 commit、push、開 draft PR；RV-01 現已 `approved`。但 repository 的 `$git-commit-convention` 仍要求先由 staged diff 檢查語意邊界、提出 commit message，並取得 human confirmation；DL-01 未完成前 HC-01 維持 pending。
- draft PR 開立後停在 `HC-01`，交還人類審閱。不得自行 merge、release 或將 human review 標成完成。

## Last Updated

2026-09-23
