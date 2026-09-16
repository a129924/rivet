# github-keychain-token-store：Step Ledger

## Topic State

- Branch: `feat/github-keychain-token-store`
- Worktree policy: 所有 topic work 僅在 feature worktree；不得在 dev worktree 修改、測試或交付。
- Current phase: 實作（publication preparation）；`RV-05` 已 approved，等待獨立 Implementer 的 `IM-05` 執行使用者已授權的 commit／push／exact thread 1 resolve。
- Current step: `IM-05`
- Current upstream verdict: `approved`（`RV-05`）
- Current Reviewer verdict: `approved`（`RV-05`）。Historical Reviewer verdicts: `RV-02` 為 `approved`；`RV-01` 的 `needs-rework` 維持記錄。
- Correction trigger: 已選定 PR #32 thread 1 的 cross-process acceptance finding、IM-02 child-`swift test` route 的 deadlock，以及 IM-03 one-shot `swift -e` child route 的 exit 1。remote 已驗證 PR #32 為 open、non-draft，base 為 `dev`、head 為 `feat/github-keychain-token-store`；不得推論 thread resolved、fix 已 push 或 human approval state。

## Steps

| ID | Owner role | Status | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| PC-01 | Plan-Creator | completed | 四份同 slug artifacts 建立並記錄 mission、base query、failure normalization、file scope 與 human boundary。 | 四份正式 artifacts 已在 feature worktree 建立；未修改 Swift、tests、long-lived docs 或 Git state。 |
| PC-02 | Plan-Creator | completed | 只修正四份 artifacts，記錄方案 A signed-host route 與其 verification boundary。 | artifacts correction 已完成；未修改 Swift、tests、long-lived docs 或 Git state。 |
| PC-03 | Plan-Creator | completed | 只修正四份 artifacts，將 policy 改為 human 鎖定的 legacy macOS Keychain，移除 DPK/accessibility/signed-host route，恢復 SwiftPM real integration route。 | artifacts correction 已完成；未修改 Swift、tests、long-lived docs 或 Git state。 |
| PC-04 | Plan-Creator | completed | 只修正四份 artifacts，將已受管 signed-host project/source/hosted-test/runner artifacts 列入精確 Deleted scope，並保護非受管 Xcode user artifacts。 | artifacts correction 已完成；未刪除任何實際檔案，亦未修改 Swift、tests、long-lived docs 或 Git state。 |
| PR-01 | Plan-Reviewer | completed | 獨立確認 cumulative artifacts 符合 SDD contract、方案 B legacy base query、SwiftPM real integration、static isolation、docs coordination 與 worktree policy。 | Plan-Reviewer 已明示 `approved` verdict。 |
| HC-01 | Human | completed | Human 僅授權 feature worktree 更新四份 long-lived docs：`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md`。 | 四份 docs writeback authorization 已明示；此 completed history 不涵蓋或推論 commit、push、draft PR URL、human PR approval 或 merge decision。 |
| HC-02 | Human | pending | Ready PR 已存在：PR #32 為 open、non-draft，base `dev`、head `feat/github-keychain-token-store`；在現有 user-authorized commit／push 後，thread 1 local fix 才可 resolve，之後仍由 Human 作 PR approval 與 merge decision。 | thread 1 local fix 已由 RV-05 reviewed；remote head 目前仍僅含 `2ebd845`，不含該 fix。commit、push、thread resolve、human PR approval 與 merge decision 均尚未發生，不包含 Keychain manual verification。 |
| IM-01 | Implementer | completed | 在 feature worktree 完成 Written／Modify scope、HC-01 授權的四份 docs writeback，並精確移除 Deleted 清單的五個受管 signed-host artifacts。 | Implementer 明示完成 legacy SwiftPM testing path，並逐一移除 `Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/project.pbxproj`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/xcshareddata/xcschemes/KeychainIntegrationHost.xcscheme`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost/AppDelegate.swift`、`Tests/KeychainIntegrationHost/KeychainIntegrationHostTests/KeychainTokenStoreIntegrationTests.swift`、`scripts/run-keychain-integration-tests.sh`；不涵蓋 non-managed Xcode user artifacts。 |
| TE-01 | Tester | completed | 執行 SwiftPM real legacy Keychain integration、unit/public/static、consumer、format、SwiftLint、diff、docs、deletion 與 dev result checks。 | Tester 已明示 `approved` verdict；evidence 包含 focused 7 個 Keychain tests、full `swift test` 53 個 tests、format、SwiftLint、consumer、diff、docs、精確 deletion 與 dev result。 |
| RV-01 | Reviewer | needs-rework | 獨立審查 implementation、SwiftPM Keychain evidence、opaque-error/secret boundary、docs coordination、worktree policy 與 workflow scope，並在 ledger correction 後作出 re-review conclusion。 | 現有 Reviewer verdict 為 `needs-rework`，要求本 ledger correction；尚未有 `approved` conclusion，且不得由其他 completed status 推論。 |
| PC-05 | Plan-Creator | completed | 只修正 `.step.md`，記錄已明示的 PR-01／HC-01／IM-01／TE-01 facts 與 RV-01 needs-rework，不改變 implementation verdict。 | 僅此 ledger 已修正；未修改 code、tests、long-lived docs、其他 artifacts 或 Git state。 |
| PR-02 | Plan-Reviewer | completed | 獨立核對 PC-05 ledger correction 是否準確記錄已明示 workflow facts；不得重新判定 implementation、testing 或 RV-01 實作審查結論。 | Plan-Reviewer 已明示 `approved` verdict；scope 僅限 ledger correction。 |
| RV-02 | Reviewer | completed | 僅驗證 PC-05／PR-02 已修正先前 workflow ledger finding；不得重審未變的 implementation、testing 或其他 code conclusion。 | Reviewer 已明示 `approved` verdict；不產生或取代任何 human conclusion。 |
| PR-03 | Plan-Reviewer | completed | 僅核對本次 PR-02 verdict／RV-02 routing 的 ledger correction；不得重新判定 implementation、testing 或任何 Reviewer verdict。 | Plan-Reviewer 已明示 `approved` verdict；evidence scope 僅限 ledger routing correction。 |
| PC-06 | Plan-Creator | completed | 只修正四份 topic artifacts，納入 PR #32 thread 1 選定的 cross-process acceptance：既有 KeychainTokenStoreTests 的 parent／child `Process` flow、non-secret identity environment、exit-status-only result、deferred cleanup 與無 target/product/package/Xcode/helper expansion。 | 四份 artifacts 已累積更新；未修改 code、tests、long-lived docs 或 Git state；未覆寫歷史 approval、commit、PR state 或 HC-01 human boundary。 |
| PC-07 | Plan-Creator | completed | 只修正四份 topic artifacts：保留 HC-01 completed shared-doc authorization history，建立獨立的 HC-02 PR human boundary，並鎖定 child `Process.currentDirectoryURL` 為 repository root。 | 四份 artifacts 已累積更新；未修改 code、tests、long-lived docs 或 Git state；未改變其他 scope 或 historical verdict。 |
| PR-04 | Plan-Reviewer | superseded | 原本重新審查 PC-07 的 repository-root child route；該 route 已因 IM-02 deadlock 由 PC-08 one-shot route 取代。 | 未記錄或推論任何額外 PR-04 verdict；其未完成 route history 由 PR-05 取代。 |
| IM-02 | Implementer | blocked | child `swift test --skip-build --filter` route 的 implementation 無法完成；不得繼續使用 reader mode、filter 或 repository-root／`repositoryRoot` helper。 | 已明示的 blocked history 是 child route deadlock；沒有因此產生 commit、push、PR、human approval 或新的 implementation verdict。 |
| TE-02 | Tester | superseded | 原本在 IM-02 完成後驗證 child-`swift test` route；IM-02 已 blocked，該 route 不得執行。 | 未產生 Tester verdict；one-shot route 的 verification 改由 TE-03 處理。 |
| PC-08 | Plan-Creator | completed | 只修正四份 topic artifacts，採 Planner decision-complete one-shot child query route：adapter save UUID-service sentinel、`/usr/bin/env swift -e`、inherited environment with service/account override、legacy raw query、null stdout/stderr、exit-status-only 與 no-package access。 | 四份 artifacts 已累積更新；未修改 code、tests、long-lived docs 或 Git state；未覆寫 prior verdict、PR state 或 human boundary。 |
| PR-05 | Plan-Reviewer | superseded | 原本審查 PC-08 one-shot `swift -e` route；該 route 的 IM-03 已 exit 1 blocked。 | 未記錄或推論任何額外 PR-05 verdict；其未完成 route history 由 PR-06 取代。 |
| IM-03 | Implementer | blocked | one-shot `/usr/bin/env swift -e` direct Security query route exit 1；不得重用該 route 或新增 temporary direct-Security script。 | 已明示的 blocked history 為 child exit 1；沒有因此產生 commit、push、PR、human approval 或新的 implementation verdict。 |
| TE-03 | Tester | superseded | 原本在 IM-03 完成後驗證 one-shot route；IM-03 已 blocked，該 route 不得執行。 | 未產生 Tester verdict；SwiftPM helper route 的 verification 改由 TE-04 處理。 |
| RV-04 | Reviewer | superseded | 原本在 TE-03 有結果後審查 one-shot route；TE-03 未執行。 | 未產生 Reviewer verdict；SwiftPM helper route 的 review 改由 RV-05 處理。 |
| PC-09 | Plan-Creator | completed | 只修正四份 topic artifacts，採 Planner existing `swiftpm-testing-helper` subprocess route：current helper executable、existing bundle-path arg、精確 helper args、reader-mode fresh internal load、null stdout/stderr、exit-status-only 與 no package expansion。 | 四份 artifacts 已累積更新；未修改 code、tests、long-lived docs 或 Git state；未覆寫 prior verdict、PR state 或 human boundary。 |
| PC-10 | Plan-Creator | completed | 只修正四份 topic artifacts，將 active cross-process contract 統一為 parent save 與 reader fresh adapter compare 的同一個 non-secret、source-held fixed sentinel；environment 仍只傳 reader/service/account。 | 四份 artifacts 已累積更新；未修改 code、tests、long-lived docs 或 Git state；未改變 helper/filter/package legacy history、historical verdict 或 human boundary。 |
| PR-06 | Plan-Reviewer | completed | 重新審查 PC-09／PC-10 是否正確替換 IM-03 blocked route，並維持 legacy Keychain、secret boundary、同一 fixed-sentinel contract、same-process adapter-load preservation、existing-helper-only scope 與 HC-02 boundary。 | Plan-Reviewer 已明示 `approved` verdict。 |
| IM-04 | Implementer | completed | 於既有 `Tests/GitHubIntegrationTests/KeychainTokenStoreTests.swift` 使用 existing `swiftpm-testing-helper` subprocess 完成 cross-process acceptance；不改 adapter、target、product、`Package.swift`、Xcode host、repository helper executable 或 long-lived docs。 | Implementer 已完成 current helper／existing bundle-path 的 fresh reader implementation，包含同一 non-secret source-held fixed sentinel、reader-mode environment、null stdout/stderr、exit-status-only 與 exact cleanup。 |
| TE-04 | Tester | completed | 驗證 helper-subprocess acceptance、reader-mode no-spawn branch、same-process adapter-load preservation、full SwiftPM suite、static/public/consumer checks 與 diff scope。 | Tester 已明示 `approved` verdict；evidence 為 focused pass、Keychain 8/8、Static 30/30、full 54、format、lint、consumer 與 diff。 |
| RV-05 | Reviewer | completed | 獨立審查 helper-subprocess cross-process proof、secret boundary、legacy Keychain policy、existing-helper-only scope 與 workflow evidence。 | Reviewer 已明示 `approved` verdict；審查依據包含 TE-04 focused pass、Keychain 8/8、Static 30/30、full 54、format、lint、consumer 與 diff evidence。 |
| IM-05 | Implementer | pending | 在既有 user authorization 下，準備 topic commit、push，並僅在已發表的 exact change 對應 PR #32 thread 1 後 resolve 該 thread；不得處理其他 thread、PR scope、human approval 或 merge。 | Implementer 明示 commit、push 與 exact thread 1 resolve 的實際結果；在它們尚未發生前不得推論 remote head、thread resolved、human approval 或 merge。 |
| RV-03 | Reviewer | superseded | 原本在 TE-02 有結果後審查 child-`swift test` route；該 route 已因 IM-02 blocked 而不執行。 | 未產生 Reviewer verdict；one-shot route 的 review 改由 RV-04 處理。 |

## Blockers

- `HC-02` 的 Ready PR 已存在；其 human approval／merge decision 仍待 Human 作出。這不是已發生的 human approval，且 remote head 不含本地 thread 1 fix；`IM-05` 的 user-authorized publication 必須先完成，thread 1 才可 resolve。
- IM-02 deadlock 與 IM-03 exit 1 是已記錄的 blocked history；不得重用任一路線。`PR-06`、`IM-04`、`TE-04` 與 `RV-05` 已完成；目前只待 IM-05 publication preparation。
- 不存在 signed host、team、codesign 或 device-lock precondition；它們已不屬方案 B scope，也不得被用作本 topic blocker 或 verification claim。

## Human Check

- `HC-01` 的 docs writeback authorization 已完成並保留為歷史。`HC-02` 的 Ready PR human approval 與 merge decision 仍 pending；`IM-05` 僅記錄現有 user authorization 的 topic commit／push／exact thread 1 resolve，並不取代 Human decision。沒有 signing、team、codesign、device-lock、restart 或 Keychain manual verification human gate。
- 除 IM-05 已記錄的 user-authorized publication preparation 外，其他 commit、push、PR、merge、release、Keychain Sharing／sync、access group、Data Protection Keychain 與新的 accessibility policy 均不受此 ledger 授權。

## Last Updated

- 2026-09-16：Plan-Creator 記錄 RV-05 completed／approved 與 TE-04 evidence。thread 1 local fix 已 reviewed，但 remote head 仍僅含 `2ebd845`；尚未 commit、push 或 resolve。IM-02／IM-03 blocked history、previous gates 與 HC-02 pending human approval／merge 均保留，沒有新增 human approval。下一個 owner 是獨立 Implementer 的 IM-05 publication preparation。
