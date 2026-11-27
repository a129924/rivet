# I3 Swift 實作計畫

基線 `dev` `8b391ec`。隔離分支 `chore/pr-inbox-i3-last-updated-verification`。E026 在本機及可見歷史未占用。

## Goal

從受控自查回應在原生 Inbox 列顯示最後更新的相對時間，日期缺席時仍可閱讀及選取。

## Non-Goal

本輪以既有 Variant B、正式列及自查行為做可行性驗證。正式資料契約採用另立 topic。

## In-Scope

建立 E026 及其立即使用的共用宿主。驗證初載、手動刷新、缺值、完整發布、來源順序、選取、失敗保留、寬窄版及 VoiceOver。

## Out-Of-Scope

E025 歷史遷移、正式 Sources 或根 manifest／lockfile 變更、正式 App 接線、真人 GitHub／OAuth、其他 BC、Draft 徽章、作者、篩選、時間排序及定時更新。

## ReadOnly

- `Package.swift`
- `Package.resolved`
- `packages/RivetHTTPClient/Package.swift`
- `Sources/BoundedContexts/GitHubIntegration/REST/GitHubRestClient.swift`
- `Sources/BoundedContexts/PRInbox/InboxItem.swift`
- `Sources/BoundedContexts/PRInbox/PRInboxFacade.swift`
- `Sources/PRInboxGitHub/Endpoints/GitHubSelfReviewSearchEndpoint.swift`
- `Sources/PRInboxGitHub/GitHubSelfReviewSource.swift`
- `Sources/Presentation/PRInbox/InboxWorkspace.swift`
- `Sources/Presentation/PRInbox/InboxListStatus.swift`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/github-api/rest-inbox-discovery.md`
- `docs/presentation/native-interaction-contract.md`
- `experiments/E025/Package.swift`
- `experiments/E025/Package.resolved`
- `experiments/E025/README.md`
- `experiments/E025/Sources/InboxI2Verification/FixtureREST.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxI2VerificationApp.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxQuery.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxSession.swift`
- `experiments/E025/Sources/InboxI2Verification/InboxVerificationWindow.swift`
- `experiments/E025/Tests/InboxI2VerificationTests/InboxSessionTests.swift`
- `experiments/E025/scripts/verify.sh`
- `experiments/E025/evidence/acceptance.md`
- `experiments/E025/evidence/i2-07-live.md`
- `experiments/E025/evidence/native-list-adoption.md`

## Written

- `experiments/support/InboxExperimentSupport/Package.swift`
- `experiments/support/InboxExperimentSupport/Sources/InboxExperimentSupport/InboxExperimentWorkspace.swift`
- `experiments/support/InboxExperimentSupport/Sources/InboxExperimentSupport/InboxExperimentSession.swift`
- `experiments/E026/Package.swift`
- `experiments/E026/Package.resolved`
- `experiments/E026/README.md`
- `experiments/E026/Sources/InboxI3Verification/InboxI3VerificationApp.swift`
- `experiments/E026/Sources/InboxI3Verification/InboxI3FixtureREST.swift`
- `experiments/E026/Sources/InboxI3Verification/InboxUpdateTimeREST.swift`
- `experiments/E026/Sources/InboxI3Verification/InboxI3Query.swift`
- `experiments/E026/Tests/InboxI3VerificationTests/InboxUpdateTimeTests.swift`
- `experiments/E026/scripts/verify.sh`
- `experiments/E026/evidence/i3-last-updated.md`

## Deleted

`None`

## Modify

- `experiments/README.md`，Human 接受驗收後補記索引。
- `docs/presentation/pr-inbox-visual-adoption.md`，Human 接受驗收後補記有限結果。

## TestCase

| ID | 觸發與預期 | 證據與對照 |
| --- | --- | --- |
| I3-01 | 12:00Z 固定時鐘下，10:00Z 的 PR 於寬版顯示「2 小時前」，VoiceOver 可讀 ID 與時間。 | 原生畫面與實聽，原生契約 §10。 |
| I3-02 | 同批含日期缺漏、null、非字串與無效值。合格列皆可用，缺時間的列無孤立分隔。 | 斷言、畫面與實聽，§10–11。 |
| I3-03 | 同號不同 repo，分頁等待保留舊快照。成功時一次發布來源順序、新時間與舊有效選取。後續完整成功若缺時間即清除舊時間。 | 分頁證據、順序及選取 ID，I2-02／05。 |
| I3-04 | 原選取消失回首列，零筆成功清除選取。 | 狀態與 ID，I2-02／03。 |
| I3-05 | 首次失敗顯示錯誤。第二頁暫停及失敗時保留舊列和時間，實際失敗後顯示可能非最新。 | 分頁到達、快照及選取，AC-NI-009／032。 |
| I3-06 | 940／420 pt 同組資料。窄版保留標題、PR 識別與選取。有效時間仍可由 VoiceOver 讀取。 | 原生畫面、視窗量測與實聽，AC-NI-016／017。 |

Graphify 實作前有界導覽並回讀原碼。Archify 接線後製作繁中 sequence 並執行 showcase 驗證。PR Lens 用實際 diff 驗證及渲染。show-me 提供實際場景對照。Floorplan 在隔離副本核對 E026、共用宿主及正式依賴。工具產物保留於本機隔離目錄。

規劃先建立步驟帳本，依各階段更新其證據。台北時間 18:20 收斂，交付條件仍有欠項時回報具體狀態。獨立 Plan Review 後在 feature worktree 實作。Tester 執行 E026 verify.sh test、regression、build 及 Presentation 回歸，核對 I3-01～06。獨立 Reviewer 核對差異與證據。使用者已授權未見重大問題時一次 topic commit、推送與開 Draft PR 到 dev，交回 Human Review。驗收結論與兩份長期文件待 Human 接受。
