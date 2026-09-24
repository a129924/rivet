# PR Reader Content Source Core 契約：執行計畫

## Goal

建立 `RivetPRReader` 可編譯 Core 與 `PRContentSource` Domain Port，一次回傳單一 PR 的完整 Reader 語意快照；每檔可選 patch 是 Core 的唯一 diff payload，metadata-only 檔案仍可成功。topic slug 固定為 `pr-reader-content-source-contract`。

## In-Scope

- root SwiftPM library product、只取 `Sources/BoundedContexts/PRReader/Core` 的 target，以及 Reader Core test target。Core 有 target-local `Outcome`／`Result` alias，public `PRContentSource: Sendable` 以 `ReaderPullRequestID(owner, repository, number)` 非同步取得 `Outcome<PRContentSnapshot, PRReaderFailure>`。
- `PRContentSnapshot.id` 與 request ID 相同；包含 background、有序 conversation、reviews、inline threads、files，以及 optional `reviewDecision`、`checkRollup`。每檔有 Reader-owned、同 snapshot 唯一的 reference，保留原順序、path、optional previousPath、change、additions、deletions、optional patch。Core 不新增 validator。
- File change 六種：added／removed／modified／renamed／copied／typeChanged；Review state 五種；Review decision 三種；check run／commit status 與 rollup 的 case 集合、可選 conclusion、checks 順序依 [技術規格](../../analysis/pr-reader-content-source-contract/technical-spec.md) 的 public shape。check rollup 缺席與存在但 checks 空集合須能區分。
- Failure 僅 `.notReadable`、`.unavailable`、`.contentNotRepresentable`；最後一種是 human 授權的必要資料無法保真閱讀語意，不把合法 optional nil 誤判為 failure。本 topic 不實作 mapper。
- Core fake Port／value tests、SwiftPM 編譯與隔離檢查；完成後只將已成立的 Core 契約與 failure truth 回寫 PR Reader BC 文件。

## Out-Of-Scope

- Core 不依賴 PR Inbox、GitHub、HTTP、transport 或 WebView；不加 Facade、UseCase、Client Protocol、Adapter、live fetch、GraphQL asset 處理、cache、巨大 diff 分段、review 寫入或任何真實資料來源。
- 不加入頂層 `unifiedDiff`；未來 Infra 使用 raw unified diff 時的拆檔／保真規則另決定。缺 patch 仍保留 file metadata，不回傳 Reader failure。
- 不擴充 TS 四種檔案狀態，不實作 Swift／WebView bridge 或 viewed persistence；TS 六狀態擴充必須另立 topic，完成其 planning／human gate。擴充前不能宣稱六種 Core status 可完整接入 WebView。
- 後續 bridge 再決定 PR ID → `pullRequestId` encoding、`snapshotId` 生命週期、Reader reference → snapshot-local `fileId` 映射與事件回查、Swift 權威 `viewed` 來源、`ViewedStateChange` 的三重識別驗證、過期事件處理及 patch／count 轉換。本 topic 不宣稱 Swift／WebView 已接線。

## ReadOnly

- `README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、現有 WebView diff contracts、`docs/github-api/`、其他 BC source、既有 tests 與 PR Reader 候選 `Infra/GitHub/GraphQL/Schema.graphqls`；唯一 test-only 例外為 Modify 所列 root graph expected-set 同步。
- `Sources/BoundedContexts/PRReader/.gitkeep` 保留；新 target 僅編譯 `Core`，不得搬動或納入候選 SDL。

## Written

- `analysis/pr-reader-content-source-contract/requirements.md` 與 `technical-spec.md`。
- `plan/pr-reader-content-source-contract/pr-reader-content-source-contract.plan.md` 與 `.step.md`。
- 獲獨立 Plan-Reviewer approval 後的 `Sources/BoundedContexts/PRReader/Core/` public Core source，以及 `Tests/RivetPRReaderTests/` 的 fake Port／Core value tests。

## Deleted

無。

## Modify

- `Package.swift`：只增加 `RivetPRReader` product／Core target／test target，不新增依賴。
- `docs/architecture/bounded-contexts/pr-reader.md`：實作完成後只回寫已成立的 Core 契約、逐檔 optional patch 與 `.contentNotRepresentable` failure truth；不得把後續 bridge、Infra、viewed 或 TS 六狀態描述為已實作。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：唯一新增 test-only compatibility path。只將 products expected set 加入 `RivetPRReader`，targets expected set 加入 `RivetPRReader`、`RivetPRReaderTests`；保留所有既有 entries、GitHubIntegration product mapping、target type／path／dependency assertions、helpers 與其他 behavior。不得搬移／重構測試，不得加入 Reader semantic assertions。

## Public API／Interface

[技術規格](../../analysis/pr-reader-content-source-contract/technical-spec.md) 的 public shape 是本次唯一契約：Reader-owned ID／reference、完整快照與各 enum cases、`PRContentSource.fetchContent(for:)`、target-local `Outcome`。public values 必須能由一般 client import 建構；Port 只回傳 Reader 自有 failure。snapshot 不含 WebView `snapshotId`／`fileId`／`viewed`，也不含頂層 `unifiedDiff`。

## Non-Goal

不交付 Reader Infra／mapper、真實資料讀取、完整 Swift／WebView 相容性、TS status 擴充、viewed 持久化或任何 GitHub 寫入；fake fixture 通過不代表上述能力完成。

## TestCase

| ID | 驗收 | Expected evidence |
| --- | --- | --- |
| TC-01 | manifest／target | `swift package dump-package` 可解析；exact root graph 只新增 `RivetPRReader` product、`RivetPRReader` target、`RivetPRReaderTests` target，所有既有 entries、GitHubIntegration product mapping、target type／path／dependency assertions 不變；Reader source target 僅指 `Core`，test target 依賴 Reader。 |
| TC-02 | public contract | 一般 `import RivetPRReader` 可建構所有 public value，fake `PRContentSource` 可 async 回傳 `Outcome<PRContentSnapshot, PRReaderFailure>`。 |
| TC-03 | 多檔與順序 | fake 成功快照含同一 PR ID、有序多檔、唯一 Reader references、六種 file changes；值保留區別與順序。 |
| TC-04 | patch 與 optional | 同一快照含 patch 與 metadata-only 無 patch 檔；合法 optional nil、空 conversation／reviews／threads／files 可表達且不要求整份 unified diff。 |
| TC-05 | checks | 可區分 `checkRollup == nil`、存在但 checks 空集合；有序 checks 可同時容納兩個不同 `name` runs 與 commit status，run conclusion 可 nil。 |
| TC-06 | review／failure | review state／decision 與三種 failure 均可表達；合法 optional nil 不被建模為 failure。 |
| TC-07 | compile／isolation | `swift build`、focused Reader tests 與 root `swift test` 全綠；exact root graph test 接受 Reader 三個新節點且既有 graph assertions 不變；Reader target dependencies／imports 不含 PR Inbox、GitHubIntegration、RivetHTTPClient、HTTP、transport、WebView 或候選 SDL。 |
| TC-08 | scope／docs | `git diff --check` 與檔案影響檢查僅涵蓋四份 artifacts、Reader Core／tests、manifest、PR Reader BC truth writeback，以及唯一允許的 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` expected-set 同步；TS、SDL、其他 BC source／tests、全域架構文件未改。 |

TC-03 的 ID 相等與 reference 唯一 fixture 只能驗表示能力。它們是 producer obligation，沒有 concrete source／mapper 的本 topic 不得宣稱已 runtime 驗證。

## Execution and Gates

1. Plan-Creator 建立四份同 slug artifacts；獨立 Plan-Reviewer 必須對正式 artifacts 明示 `approved`。先前文字草案即使獲使用者接受，也不是正式 Plan-Reviewer gate。
2. approval 後由獨立 Implementer 僅在 feature worktree 建立 Core、tests、manifest 變更與 PR Reader BC truth writeback；root graph compatibility 僅可更新上述唯一 test-only path 的 exact expected sets。若遇重大契約衝突、scope drift、不能保真或其他未授權路徑需求，停止回報，不自行擴張。
3. Implementer 完成交接後由獨立 Tester 驗證 TC-01 至 TC-08，再交獨立 Reviewer 明示 verdict。Reviewer 的 `needs-rework` 回交 Implementer，`blocked`／`human-check` 停止；只有 `approved` 可進入 delivery。
4. 使用者已授權無重大問題時以 topic commit、push 並開 draft PR 供 human review。delivery 仍須遵守 staged diff 語意邊界與 human-confirmed commit 規則，以 `dev` 為 PR base；完成後停止於 Human Check，不 merge 或 release。

## Assumptions and Current Gate

PR-02 是 package graph exact set 未同步所觸發的歷史 `needs-rework`；修訂後 PR-03 已由獨立 Plan-Reviewer 明示 `approved`。IM-01、DL-01 與 HC-01 均已 `completed`，TE-01 與 RV-01 均已 `approved`；PR #42 目前為 OPEN／Ready（`isDraft=false`）。詳細即時狀態與 evidence 以 [Step Ledger](pr-reader-content-source-contract.step.md) 為準。`patch` 缺席、合法 optional nil 與必要資料無法保真是不同情況；只有最後者使用 `.contentNotRepresentable`。

## Last Updated

2026-09-23
