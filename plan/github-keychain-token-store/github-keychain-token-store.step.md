# github-keychain-token-store：Step Ledger

## Topic State

- Branch: `feat/github-keychain-token-store`
- Worktree policy: 所有 topic work 僅在 feature worktree；不得在 dev worktree 修改、測試或交付。
- Current phase: Human boundary；待 draft PR 建立後由 Human 作 review／approval／merge decision。
- Current step: `HC-01`
- Current upstream verdict: `approved`（`RV-02`）
- Current Reviewer verdict: `approved`（`RV-02`）；`RV-01` 的 historical `needs-rework` 維持記錄。

## Steps

| ID | Owner role | Status | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| PC-01 | Plan-Creator | completed | 四份同 slug artifacts 建立並記錄 mission、base query、failure normalization、file scope 與 human boundary。 | 四份正式 artifacts 已在 feature worktree 建立；未修改 Swift、tests、long-lived docs 或 Git state。 |
| PC-02 | Plan-Creator | completed | 只修正四份 artifacts，記錄方案 A signed-host route 與其 verification boundary。 | artifacts correction 已完成；未修改 Swift、tests、long-lived docs 或 Git state。 |
| PC-03 | Plan-Creator | completed | 只修正四份 artifacts，將 policy 改為 human 鎖定的 legacy macOS Keychain，移除 DPK/accessibility/signed-host route，恢復 SwiftPM real integration route。 | artifacts correction 已完成；未修改 Swift、tests、long-lived docs 或 Git state。 |
| PC-04 | Plan-Creator | completed | 只修正四份 artifacts，將已受管 signed-host project/source/hosted-test/runner artifacts 列入精確 Deleted scope，並保護非受管 Xcode user artifacts。 | artifacts correction 已完成；未刪除任何實際檔案，亦未修改 Swift、tests、long-lived docs 或 Git state。 |
| PR-01 | Plan-Reviewer | completed | 獨立確認 cumulative artifacts 符合 SDD contract、方案 B legacy base query、SwiftPM real integration、static isolation、docs coordination 與 worktree policy。 | Plan-Reviewer 已明示 `approved` verdict。 |
| HC-01 | Human | pending | 已完成的 human decision 僅授權 feature worktree 更新四份 long-lived docs：`docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md`。在 user-authorized topic commit／push／draft PR preparation 後，仍待 Human 作 PR review、approval 與 merge decision。 | 四份 docs writeback authorization 已明示；尚未發生 commit、push、draft PR URL、human PR approval 或 merge decision，均不得推論或宣稱。 |
| IM-01 | Implementer | completed | 在 feature worktree 完成 Written／Modify scope、HC-01 授權的四份 docs writeback，並精確移除 Deleted 清單的五個受管 signed-host artifacts。 | Implementer 明示完成 legacy SwiftPM testing path，並逐一移除 `Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/project.pbxproj`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost.xcodeproj/xcshareddata/xcschemes/KeychainIntegrationHost.xcscheme`、`Tests/KeychainIntegrationHost/KeychainIntegrationHost/AppDelegate.swift`、`Tests/KeychainIntegrationHost/KeychainIntegrationHostTests/KeychainTokenStoreIntegrationTests.swift`、`scripts/run-keychain-integration-tests.sh`；不涵蓋 non-managed Xcode user artifacts。 |
| TE-01 | Tester | completed | 執行 SwiftPM real legacy Keychain integration、unit/public/static、consumer、format、SwiftLint、diff、docs、deletion 與 dev result checks。 | Tester 已明示 `approved` verdict；evidence 包含 focused 7 個 Keychain tests、full `swift test` 53 個 tests、format、SwiftLint、consumer、diff、docs、精確 deletion 與 dev result。 |
| RV-01 | Reviewer | needs-rework | 獨立審查 implementation、SwiftPM Keychain evidence、opaque-error/secret boundary、docs coordination、worktree policy 與 workflow scope，並在 ledger correction 後作出 re-review conclusion。 | 現有 Reviewer verdict 為 `needs-rework`，要求本 ledger correction；尚未有 `approved` conclusion，且不得由其他 completed status 推論。 |
| PC-05 | Plan-Creator | completed | 只修正 `.step.md`，記錄已明示的 PR-01／HC-01／IM-01／TE-01 facts 與 RV-01 needs-rework，不改變 implementation verdict。 | 僅此 ledger 已修正；未修改 code、tests、long-lived docs、其他 artifacts 或 Git state。 |
| PR-02 | Plan-Reviewer | completed | 獨立核對 PC-05 ledger correction 是否準確記錄已明示 workflow facts；不得重新判定 implementation、testing 或 RV-01 實作審查結論。 | Plan-Reviewer 已明示 `approved` verdict；scope 僅限 ledger correction。 |
| RV-02 | Reviewer | completed | 僅驗證 PC-05／PR-02 已修正先前 workflow ledger finding；不得重審未變的 implementation、testing 或其他 code conclusion。 | Reviewer 已明示 `approved` verdict；不產生或取代任何 human conclusion。 |
| PR-03 | Plan-Reviewer | completed | 僅核對本次 PR-02 verdict／RV-02 routing 的 ledger correction；不得重新判定 implementation、testing 或任何 Reviewer verdict。 | Plan-Reviewer 已明示 `approved` verdict；evidence scope 僅限 ledger routing correction。 |

## Blockers

- `HC-01` 的 PR review／approval／merge decision 待 draft PR 建立後由 Human 作出；這不是已發生的 human approval。
- 不存在 signed host、team、codesign 或 device-lock precondition；它們已不屬方案 B scope，也不得被用作本 topic blocker 或 verification claim。

## Human Check

- `HC-01` 的 docs writeback authorization 已完成；draft PR 建立後的 human review、approval 與 merge decision 仍 pending。沒有 signing、team、codesign、device-lock、restart 或 Keychain manual verification human gate。
- commit、push、PR、merge、release、Keychain Sharing／sync、access group、Data Protection Keychain 與新的 accessibility policy 均不受此 ledger 授權。

## Last Updated

- 2026-09-16：Plan-Creator 記錄 RV-02 的 approved verdict。PR-01／PR-02／PR-03、TE-01 與 RV-02 已 approved；RV-01 保留為 historical needs-rework。HC-01 的 docs writeback authorization 已記錄，但 draft PR 建立後的 human review／approval／merge decision 仍 pending。下一個 routing 是 user-authorized topic commit／push／draft PR preparation，之後交回 Human。
