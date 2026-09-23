# PR Inbox / PullRequestList：Step Ledger

## Current Phase

Topic／Mission completed。Human 於 2026-09-23 提供完整 HC-01 證據：HR-01 pass（單擊只更新 Selection、Count 不增）；HR-02 pass（更新後雙擊的 Selection 與 Last Open ID 為同一 ID、Count 恰 +1）；HR-03 pass（Selection 不變、Count +1）；HR-04 pass（↑／↓／Home／End 只改 Selection、不 Open）；HR-05 pass（失焦不攔截、不增 Count）；HR-06 pass（恢復焦點保留有效 Selection、不自動 Open、鍵盤恢復）；HR-07 pass（Missing／Non-selected／Unsafe 均不增 Count且不改 Selection）；Visual／structural pass；Long List internal vertical scrolling pass；VoiceOver pass。固定 x 逐列單擊 finding 已由 Human 撤回且不再重現。Human decision 原值：`採用 PullRequestList`；HC-01 completed。

所有歷史 needs-rework／fix／test／review trace 保留於 Ledger。PC-10 已完成 final ledger-only sync；獨立 Plan-Reviewer PR-03 明示 `approved`（Findings：None），確認 PC-10 忠實記錄 Human evidence／decision，且 contract、scope 與歷史未漂移。

- Current Step：None
- Next Action：Stop
- Topic Status：completed／stopped；不得自動開始下一 component。

## Topic／workspace

- Slug：`pr-inbox-pull-request-list`；owner：non-BC `RivetPresentation`。
- Base：`dev`；work branch：`codex/pr-inbox-pull-request-list`；Human/operator 已準備專用 worktree。
- Preparation evidence：初始 HEAD/local `dev`/local `origin/dev` = `4ba15ae`，clean，branch 唯一 attach。Plan-Creator 未執行 Git。Implementation entry 需重核；drift 停於 human-check。
- Goal：原生 `PullRequestList` 單選、焦點、鍵盤與 safe Open PR intent，重用 Row。
- Non-Goal／Out-of-Scope：不改 Row；不做 Inbox parent/filter、Reader/workspace navigation、app/context menu、mapper、BC/Integration、網路、持久化或下一 Mission。完整 Inbox 首列 fallback 與 app-menu counterpart 留給未來 parent。
- In-Scope：List、Preview、受限 tests 與驗證後 Presentation 現況回寫。

## Artifact Register

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/pr-inbox-pull-request-list/requirements.md` | present / PC-01 written | 意圖、scope、成功條件、human boundary |
| `analysis/pr-inbox-pull-request-list/technical-spec.md` | present / PC-01 written | API、selection/focus/Open 與 Preview locked behavior |
| `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.plan.md` | present / PC-01 written | exact paths、execution contract、PL-01～PL-06 |
| `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md` | present / PC-01 written | phase、owner、evidence、verdict、blockers、Human Check |

## Exact Path Register

ReadOnly：

- `Package.swift`
- `docs/design-principles.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/native-interaction-contract.md`
- `plan/pr-inbox-pull-request-row/pr-inbox-pull-request-row.step.md`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`
- `Tests/RivetPRInboxTests/StaticIsolationTests.swift`

Written：

- `analysis/pr-inbox-pull-request-list/requirements.md`
- `analysis/pr-inbox-pull-request-list/technical-spec.md`
- `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.plan.md`
- `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestList+Previews.swift`
- `Tests/RivetPresentationTests/PullRequestListTests.swift`

Modify：

- `README.md`
- `docs/architecture/README.md`

Deleted：None。

## TestCase Register

- PL-01：initial `nil`、valid、empty；selection helper tests/Preview；F-01 parent obligation、AC-NI-009、UIIR-NI-003。
- PL-02：single selection、Up/Down/Home/End、focus exit/return；Human Preview/VoiceOver；CMD-NI-001、§7。
- PL-03：single click no Open；unselected-row double-click same ID exactly once；Enter；missing/nonselected/unsafe guard；helper tests + Human 原生事件及 debug-only 三種 guard probes，顯示 selection/focus/intent ID／次數；F-02、CMD-NI-002、AC-NI-011、UIIR-NI-006。
- PL-04：valid ID preserved、stale to `nil`、initial `nil` stays、empty、unique IDs、no focus theft；helper/fixture tests；F-01/F-15 parent obligation、AC-NI-009、UIIR-NI-003。
- PL-05：native selected/a11y/inactive/contrast、Row width degradation、no horizontal scroll、long vertical scroll；Human 用 inactive／Increase Contrast Preview 變體、視窗失活／恢復及 VoiceOver 檢查；§7–§10、AC-NI-014/016/017/027/035/036。
- PL-06：no BC coupling、Row/Package/static isolation unchanged、debug/release/focused/root pass、path allowlist；SwiftPM + Reviewer；§1、§13。

完整 trigger、observable result 與 evidence method 以同 slug `.plan.md` TestCase Register 為準。

## Ledger

| ID | Status | Owner role | Completion condition | Verification evidence / verdict |
| --- | --- | --- | --- | --- |
| WP-01 | completed | Human | 從乾淨 `dev` 建立指定 branch 與唯一 attach 專用 worktree。 | 上游 operator 回報 HEAD/dev/origin-dev=`4ba15ae`、clean、唯一 attach；Plan-Creator 未執行 Git。 |
| PC-01 | completed | Plan-Creator | 只建立四份同 slug planning artifacts，保持已鎖定 plan/adjustment 一致；不碰其他 path 或執行 Git。 | 四份 Artifact Register paths 寫入；self-check 只確認文件完整性，不產生品質 verdict。 |
| PR-01 | needs-rework | Plan-Reviewer | 獨立審查四份文件的 scope、九欄、exact paths、selection/Open/Preview、tests、workflow 與 human boundary。 | Explicit verdict：`needs-rework`；finding：Preview 缺三種 Open no-op guard 及 inactive／Increase Contrast 的可操作證據入口。 |
| PC-02 | completed | Plan-Creator | 只回修四份文件的 Preview/evidence 規格及 workflow truth，不改 API、selection、Row、path/scope。 | 四份文件已同步 debug-only guard probes、intent ID／次數與 inactive／contrast 觀察方式；無自我核准。 |
| PR-02 | approved | Plan-Reviewer | 獨立複審 PC-02 required fix、四份文件一致性與既有 locked decisions 未漂移。 | Explicit verdict：`approved`；Findings：None；可進 IM-01。 |
| PC-03 | completed | Plan-Creator | 只同步四份文件的 PR-02 verdict 與 IM-01 current state；不改產品契約、path、tests 或 commands。 | 四份文件一致記錄 PR-02 approved 與 IM-01 pending；PC-03 不產生 verdict。 |
| IM-01 | completed | Implementer | PR-02 `approved` 後只依 Written/Modify allowlist 實作；交付 bounded source/Preview/tests/docs 與驗證 evidence。 | 三個產品 Written paths 已新增，README／architecture overview 已更新；focused 4/4、root 74/74、debug/release build pass；Human-only native UI 尚未驗證。 |
| TE-01 | approved | Tester | IM-01 明示完成後獨立驗證 PL-01～PL-06 可自動部分並記錄人工部分。 | Explicit verdict：`approved`，限 automated scope；focused 4/4、root 74/74、debug/release pass；Human-only native UI pending。 |
| RV-01 | needs-rework | Reviewer | TE-01 後獨立審查實作、測試、文件及 scope/contract/workflow drift。 | Explicit verdict：`needs-rework`。Required fixes：PL-04 補 release-safe fixture ID uniqueness Swift Testing，不引用 DEBUG Preview symbols；ledger 同步 IM-01／TE-01／RV-01 實際狀態。 |
| PC-04 | completed | Plan-Creator | 只同步四份正式文件的 IM-01／TE-01／RV-01 事實與下一個 rework route；不改 scope/API/paths/TestCase 或產品檔案。 | 四份 workflow truth 已同步；PC-04 不產生 verdict。 |
| IM-02 | completed | Implementer | 只在既有 `Tests/RivetPresentationTests/PullRequestListTests.swift` 補 PL-04 fixture ID uniqueness Swift Testing，不引用 DEBUG Preview symbols；不改 API/selection/其他產品範圍。 | 僅既有 List 測試檔新增 release-safe fixture uniqueness test；已交 TE-02。 |
| TE-02 | approved | Tester | 獨立驗證 IM-02 bounded test fix、focused/root/debug/release 與 path scope。 | Explicit verdict：`approved`，限 automated scope；debug/release focused 5/5、root 75/75、build/path/whitespace pass；Human-only native UI pending。 |
| RV-02 | approved | Reviewer | 獨立複審 IM-02／TE-02 evidence 與 RV-01 required fixes。 | Explicit verdict：`approved`；Findings：None。Source-format-sensitive parsing 是維護限制，非 blocker。 |
| PC-05 | completed | Plan-Creator | 只同步四份正式文件的 IM-02／TE-02／RV-02 結果與 HC-01 current state；不改 contract 或產品檔案。 | 四份 workflow truth 已同步；PC-05 不產生 verdict。 |
| RV-03 | needs-rework | Reviewer | 獨立分類 HC-01 HR-02 雙擊失敗並確認回修範圍。 | Explicit verdict：`needs-rework`。Static findings：雙擊在 Row `simultaneousGesture`；Enter／雙擊共用 guard；Preview Clear／Count 接線正常。根因未定；required fix 為受限診斷／修正並重驗 HR-02，不重開 path/contract。 |
| PC-06 | completed | Plan-Creator | 只同步四份正式文件的 HR-02／03 Human 觀察、RV-03 verdict 與受限回修路由；不改產品契約或檔案。 | 四份 workflow truth 已同步；PC-06 不產生 verdict。 |
| IM-03 | completed | Implementer | 在既有 exact path/contract 內受限定位並修正 HR-02 雙擊；不得改 Row、API、selection policy 或新增 scope。 | 原 Row `TapGesture` 改 List native `primaryAction`；只改 List／Preview／Test。Plan-Reviewer 對空 menu 掛點條件明示 `approved`。尚待 Human 實際重驗 HR-02。 |
| TE-03 | approved | Tester | 獨立驗證 IM-03 的 bounded fix、regression 與既有 automated gates。 | Explicit verdict：`approved`，限 automated scope；debug/release build、focused 6/6、root 76/76、static/path/whitespace pass；native Human evidence pending。 |
| RV-04 | needs-rework | Reviewer | 獨立審查 IM-03／TE-03 evidence 與 HR-02 required fix。 | Explicit verdict：`needs-rework`，唯一 required fix 為同步 stale ledger；production source/test 未見 bounded contract defect。這不是 approval，須獨立複核。 |
| PC-07 | completed | Plan-Creator | 只同步本 ledger 的 IM-03／TE-03／RV-04 既成事實及複核路由，不改產品契約或檔案。 | Ledger 已記錄完成狀態與 RV-04 原 verdict；PC-07 不產生 verdict。 |
| RV-05 | approved | Reviewer | 獨立複核 PC-07 的 ledger correction、既有 IM-03／TE-03 evidence 與 bounded scope。 | Explicit verdict：`approved`，限 PC-07 ledger correction 與 RV-04 finding 複核；可回 HC-01 由 Human 重驗 HR-02，不等同 Human acceptance。 |
| RV-06 | needs-rework | Reviewer | 分類 HC-01 新 PL-02 逐列單擊選取 finding 與受限回修範圍。 | Explicit verdict：`needs-rework`；同一水平 x 逐列單擊時部分 PR 未更新 Selection，水平移動後才可選；與已通過 HR-02 分開處理。 |
| IM-04 | completed | Implementer | 只在既有 List exact path 以 bounded fix 修正 row 全寬 hit target；不改 API、selection policy 或 Row。 | 一行 production fix：在 List Row／tag 間加入 `contentShape(Rectangle())`；isolated native AX／CGEvent 同一水平 x 逐列單擊由 0/6 → 6/6，無 Open，並有 HR-02／Enter regression evidence。 |
| TE-04 | approved | Tester | 獨立驗證 IM-04 bounded fix、regression、既有 automated gates 與 path。 | Explicit verdict：`approved`，限 automated scope；debug/release build、focused 6/6、root 76/76、static/path/whitespace pass；Human GUI recheck pending。 |
| RV-07 | approved | Reviewer | 獨立審查 IM-04 one-line production fix 與 TE-04 evidence。 | Explicit verdict：`approved`，限 source/test bounded review；未重跑 GUI，不取代 Human PL-02 重驗。 |
| PC-08 | completed | Plan-Creator | 只同步本 ledger 的 HR-02／HR-03 Human 結果、PL-02 finding 與 RV-06→IM-04→TE-04→RV-07 路由。 | Ledger 已同步當時既成事實；PC-08 不產生 verdict。 |
| RV-08 | human-check | Reviewer | 分類更新後的 HR-02／HR-03 Human evidence 與固定 x 單擊 finding 撤回，決定是否需 code rework。 | Explicit verdict：`human-check`；HR-02／HR-03 通過，固定 x finding 經 Human 撤回／關閉，無 code rework；其餘 Human checks 與最終決策仍 pending。 |
| PC-09 | completed | Plan-Creator | 只同步本 ledger 的最新 Human 結果、finding 撤回與 RV-08 verdict；不改產品或契約。 | Ledger 已同步；PC-09 不產生 verdict。 |
| HC-01 | completed | Human | 以完整 Human Review evidence 檢查 selection、Open、keyboard/focus、guards、visual/structure、long-list scrolling 與 VoiceOver，並明示最終決策。 | 2026-09-23：HR-01 pass（單擊只 Selection、Count 不增）；HR-02 pass（Selection／Last Open ID 同 ID、Count 恰 +1）；HR-03 pass（Selection 不變、Count +1）；HR-04 pass（↑／↓／Home／End 只改 Selection、不 Open）；HR-05 pass（失焦不攔截、不增 Count）；HR-06 pass（恢復焦點保留有效 Selection、不自動 Open、鍵盤恢復）；HR-07 pass（Missing／Non-selected／Unsafe 均不增 Count且不改 Selection）；Visual／structural pass；Long List internal vertical scrolling pass；VoiceOver pass。固定 x 逐列單擊 finding withdrawn／not reproduced。Human decision 原值：`採用 PullRequestList`。 |
| PC-10 | completed | Plan-Creator | 只同步本 ledger 的完整 HC-01 evidence、Human decision 與 Topic completion；不改產品或 contract。 | Ledger 已忠實記錄 Human 明示結果；PC-10 不產生 verdict。 |
| PR-03 | approved | Plan-Reviewer | 獨立複核 PC-10 final ledger sync 是否忠實、一致且未擴張 Human evidence。 | PR-03 completed；explicit verdict：`approved`；Findings：None。確認 HR-01～HR-07、Visual／structural、Long List vertical scrolling、VoiceOver、finding withdrawn 與 Human decision 原值皆忠實，HC-01／Mission／Topic completed，contract／scope／history unchanged。 |

## Routing／Blockers／Human Check

- 歷史 needs-rework／fix／test／review trace 完整保留於 Ledger。RV-08 `human-check` 後，Human 已完成 HC-01 並明示 `採用 PullRequestList`；PC-10 只同步這項既成事實。Topic／Mission completed，自動流程停止，不開始下一 Inbox component。
- PR-03 completed，獨立 Plan-Reviewer verdict=`approved`，Findings=None。Current Step：None；Next Action：Stop。不得新增後續 review gate、重開 Human acceptance／產品 contract／implementation，或授權 commit／push／PR／merge／release。
- Blockers：None。固定 x 逐列單擊 finding 已由 Human 撤回且不再重現；本次只記錄 Human 明示的 HR-01～HR-07、Visual／structural、Long List internal vertical scrolling、VoiceOver 與採用決策，不推論其他未明示檢查。
- Human Check：HC-01 completed；Human decision 原值：`採用 PullRequestList`，date：2026-09-23。此決策結束本 topic；不得自動開始下一 component。
- Verdict history：對話版計畫已核對，僅授權 materialization；PC-01 無 verdict；PR-01 `needs-rework`；PC-02 無 verdict；PR-02 `approved`（Findings：None）；PC-03 無 verdict；IM-01 completed；TE-01 `approved` automated scope；RV-01 `needs-rework`；PC-04 無 verdict；IM-02 completed；TE-02 `approved` automated scope；RV-02 `approved`（Findings：None）；PC-05 無 verdict；HC-01 曾 pending（HR-02 failed、HR-03 pass）；RV-03 `needs-rework`；PC-06 無 verdict；IM-03 completed；Plan-Reviewer 對空 menu 掛點條件 `approved`；TE-03 `approved` automated scope；RV-04 `needs-rework`（僅 ledger stale）；PC-07 無 verdict；RV-05 `approved`（限 ledger correction 與 RV-04 finding 複核）；RV-06 `needs-rework`；IM-04 completed；TE-04 `approved` automated scope；RV-07 `approved` bounded source/test；PC-08 無 verdict；RV-08 `human-check`（無 code rework）；PC-09 無 verdict；HC-01 completed，Human `採用 PullRequestList`；PC-10 無 verdict；PR-03 `approved`（Findings：None）且 completed；Current Step=None；Next Action=Stop。
## Last Updated

2026-09-23
