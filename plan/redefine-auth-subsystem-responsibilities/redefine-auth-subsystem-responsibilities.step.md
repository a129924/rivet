# Auth 子系統責任重定義：Step Ledger

## Current Phase

`delivery-ready-active`。PR-01 與 PR-02 均為 `needs-rework`；其 replacement gate
PR-03、PR-04 與 PR-05 均已由獨立 Plan-Reviewer 明示 `approved`。TE-01 維持 historical
`needs-rework`，TE-02 的 replacement verification `approved` 與 TE-03 independent
re-test `approved` 均維持歷史事實。RV-02 已明示 `approved`，三重 no-major-issue gate
已滿足，DL-01 現為 active；尚未進行 commit、push 或 draft PR。AuthFlow state diagram 的
desktop vertical containment limitation 仍是 exact human accepted non-pass exception；不得
誤記為 visual-check pass。現行 Model A runtime 仍保持 legacy；adopted Model C 是尚未
實作的 architecture target。

## Goal

以四份 planning artifacts 鎖定 Model C 的責任/capability boundary，並在獨立審查
核准後才交付文件與圖表；不在本 topic 執行 Swift implementation。

## Non-Goal

不修改 Swift source、tests、manifests、public API、OAuth dual-client lifecycle 或
existing topic artifacts；不鎖定 deferred action/decoration/failure/async/refresh API。

## In-Scope

本 ledger 追蹤 Phase 1 planning、PR-01／PR-02 historical rework、PR-03 initial final
replacement Plan Review gate、verification/delivery wording correction 的 PR-04 re-review、
核准後的 documentation/diagram delivery、independent verification/review、topic delivery
和 final human review。

## Out-Of-Scope

任何 production implementation、test implementation、package release、merge、OAuth
runtime、generic retry policy、concurrent 401 recovery 或不在 approved allowlist 的寫入。

## ReadOnly

- Phase 1：四份 listed artifacts 以外的所有 repository paths。
- 所有 phase：Swift source/tests/manifests、OAuth dual-client lifecycle docs/diagrams、
  existing topic artifacts；Phase 2 僅有 plan.md 列出的 long-lived docs/diagram
  allowlist 例外。

## Written

- Phase 1：四份 same-slug planning artifacts。
- Phase 2：僅在 PR-03 `approved` 後，新增 architecture responsibility document 和
  新 diagram namespace artifacts/evidence。

## Modify

- Phase 1：無既有檔修改。
- Phase 2：僅在 PR-03 `approved` 後，依 plan.md allowlist 修改 architecture overview、
  BC directory index、existing AuthFlow lifecycle artifact、HTTP client package canvas
  及其 artifact-local evidence。

## Deleted

無刪除授權。

## Ledger

| ID | Owner role | Status | Work | Entry condition | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| PC-01 | Plan-Creator | completed | 建立四份 formal planning artifacts。 | 指定 feature worktree、slug、adopted Model C 和 scope contract 已提供。 | 四份 artifacts 一致記錄 matrix、legacy/target distinction、Model A/B/C、allowlist、diagram gates、role separation 和 human boundary。 | 2026-09-17 建立的本 topic 四份 files；不構成 Plan Review approval。 |
| PR-01 | Independent Plan-Reviewer | needs-rework | 審查 planning artifacts 的 scope、contract、legacy/target truth、deferred API boundary、OAuth isolation 和 workflow readiness。 | PC-01 completed。 | 指出唯一 required correction：locked-contract ASCII flow 不可保留 `AuthFlow → Requester` dependency/data flow；response/semantic exchange 必須只經 `AuthRequester`。 | `needs-rework`；不構成 approval 或 IM-01 entry gate。 |
| PC-02 | Plan-Creator | completed | 只修正 PR-01 的 locked-contract ASCII flow。 | PR-01 = needs-rework。 | ASCII flow 改為 `AuthRequester → AuthFlow` response input、`AuthFlow → AuthRequester` semantic decision；僅 `AuthRequester → Requester` 執行 preserved original request、`Requester → AuthRequester` 回傳 raw response；deferred refresh boundary 僅由 `AuthRequester` 表達。 | 2026-09-17 single required correction；未改其他 artifacts、docs、diagrams、source 或 tests。 |
| PR-02 | Independent Plan-Reviewer | needs-rework | 獨立 re-review PR-01 required correction 與四份 planning artifacts 的一致性。 | PC-02 completed。 | 指出唯一 required correction：各 artifact 不得將 historical PR-01 或 PR-02 的 hypothetical `approved` 當作 implementation gate；必須定義一個 final replacement approval gate。 | `needs-rework`；不構成 approval 或 IM-01 entry gate。 |
| PC-03 | Plan-Creator | completed | 只修正 PR-02 的 approval-gate ID consistency finding。 | PR-02 = needs-rework。 | technical spec、plan 與 ledger 一致指定 PR-03 為 PR-01／PR-02 rework 後的 final replacement Plan Review；僅 PR-03 `approved` 滿足「Plan Review approved」並授權 IM-01。 | 2026-09-17 single required correction；未改其他 artifacts、docs、diagrams、source 或 tests。 |
| PR-03 | Independent Plan-Reviewer | approved | 執行 PR-01／PR-02 rework 後的 final replacement Plan Review，審查四份 planning artifacts 的 scope、contract、gate wording 與 workflow readiness。 | PC-03 completed。 | `approved`；滿足「Plan Review approved」並可進入 IM-01。 | Independent Plan-Reviewer 確認 Model C 仍鎖定、ASCII flow 經 `AuthRequester` 而非 `AuthFlow → Requester`、PR-03 是唯一 replacement gate、allowlist/deferred API/OAuth isolation 與 delivery/human boundary 一致。 |
| IM-01 | Independent Implementer | completed | 在 PR-03 approved 後，寫入 long-lived docs/diagram allowlist。 | PR-03 = approved。 | 新 document、target/legacy wording、canvas 和三份 Archify diagrams 完成，且沒有 Swift/OAuth scope drift；state diagram 的 narrow visual-check exception 必須如實保留給後續驗證。 | 2026-09-17：long-lived allowlist 已 materialize。一次獨立 widescreen layout 嘗試將 state diagram viewBox 改為 `[1120, 566]`，但 validate 報 `refresh-failed` 與 `second-401` 超出垂直 lifecycle area，因此未 deliver、未執行 candidate visual-check，並還原最後已交付版本。還原後 source SHA-256 為 `5ae0481a353811d176cb47ac6a0b74f5303b131f4f7713f8aaded6c585a00bf9`，HTML SHA-256 為 `13f6f1789d7ee5acfbd839f4d8e1405962861cdba3d73689beae41a11d328fdf`。最後已交付版本的 visual-check 僅有 vertical overflow：1440×900 的 scrollHeight 1035、1600×1000 的 1109、1920×1080 的 1109；2048×1320 passed。human 已明確接受此 state-diagram-only limitation；不得將它記為 visual-check pass，其他 diagram gates 不受影響。TE-01 correction：HTTP client package canvas 依既有 BUILD.md 的 validate → temporary build → enhance → verify pipeline 重建，canvas validate 為 5 bands／15 boxes／23 edges／0 errors／0 warnings，`verify-accessibility.js --input index.html` 通過；互動 fallback 已實際展開並列出 runtime nodes、relations 與 annotations，stage-scoped accessibility structure 保留。component canvas 的 scene.js 已將所有非 identifier 作者英文轉為繁體中文；canvas validate 為 5 bands／10 boxes／12 edges／0 errors／0 warnings，並成功重建 index.html。兩份 canvas 均在 1440×900 檢視 dark/light output，無新增重疊或裁切。本次圖表本地化校正：受影響的 package／component canvas、lifecycle、normal、401、state 的非識別字作者文案均為繁體中文；package canvas 仍經 enhance → verify，兩個 canvas 皆 validate/build 通過；四份 Archify 皆 showcase 9/9、0 errors、0 warnings。lifecycle、normal、401 visual-check 全通過；state 仍僅有已接受的 1440×900（1035）、1600×1000（1109）、1920×1080（1109）垂直 overflow，2048×1320 通過，維持 non-pass exception。 |
| TE-01 | Tester | needs-rework | 驗證 changed paths、`git diff --check`、matrix/wording consistency、OAuth isolation、diagram receipts 與人工 visual evidence。 | IM-01 completed。 | all allowlist and diagram gates pass；結果明示交 Reviewer。 | Tester 提出兩項限定 correction：package canvas 直接 build 後遺失 artifact-local accessibility enhancement；component canvas scene.js 保留非 identifier 英文作者文案。IM-01 已完成限定修正與其本地 gate；TE-01 必須由獨立 Tester 重新驗證，不可視為 passed。 |
| TE-02 | Independent Tester | approved | 獨立重新驗證 TE-01 的兩項限定 correction、allowlist、diagram gates、OAuth isolation 與 evidence truthfulness。 | IM-01 completed。 | `approved`；TE-01 corrections 已被獨立驗證，且 state-diagram accepted containment exception 維持 non-pass、非 visual-check pass。 | Independent Tester 確認 package canvas 已以既有 validate → temporary build → enhance → verify pipeline 恢復 artifact-local accessibility enhancement 與 interactive fallback；component canvas 作者文案已繁中化且 validate/build 無新增 warning；allowlist／OAuth isolation 維持。state diagram 的 1440×900、1600×1000、1920×1080 vertical containment limitation 仍按 human accepted exception 記錄，未提升為 pass。 |
| RV-01 | Independent Reviewer | needs-rework | 審查 documentation/diagram semantics、TE-02 evidence、scope/contract/workflow drift。 | TE-02 = approved。 | 提出兩項 finding：(1) planning artifacts 必須將 TE-02 定義為 TE-01 的唯一 replacement verification gate，並以 TE-02 `approved` 而非 TE-01 `passed` 作 delivery entry condition；(2) diagram-localization 必須完成後再經獨立 re-test。 | `needs-rework`；不構成 delivery approval。 |
| PC-04 | Plan-Creator | completed | 只修正 RV-01 的 verification/delivery gate consistency finding。 | RV-01 = needs-rework。 | requirements、technical spec、plan、ledger 一致定義 TE-02 是 TE-01 的唯一 independent replacement verification gate；TE-02 `approved` 等價 verification pass，state exception 維持 non-pass truth。 | 2026-09-17 single required correction；未改 docs、diagrams、source、tests 或 Git state。 |
| PR-04 | Independent Plan-Reviewer | approved | 獨立 re-review RV-01 required verification/delivery wording correction。 | PC-04 completed。 | `approved`；確認 TE-02 replacement gate 與 delivery wording 一致，授權進入 RV-01 的 diagram-localization correction/re-test path。 | Independent Plan-Reviewer approved；此為 planning correction approval，不取代 TE-03 或 RV-02。 |
| IM-02 | Independent Implementer | completed | 完成 RV-01 finding 的 diagram-localization correction。 | PR-04 = approved。 | 受影響 diagram-local authoring content 已依既定繁體中文要求校正；不改 architecture、scope、source 或 tests。 | Bounded diagram-localization correction completed；AuthFlow state diagram exact human accepted non-pass exception 未被更動或提升為 pass。 |
| TE-03 | Independent Tester | approved | 獨立 re-test IM-02 diagram-localization correction、既有 verification evidence 與 state exception truth。 | IM-02 completed。 | `approved`；確認 localization correction、allowlist/OAuth isolation 及 state exception 仍為 exact accepted non-pass。 | Independent Tester 確認 diagram-local authoring content 已依既定繁體中文要求校正，allowlist／OAuth isolation 與既有 verification evidence 維持；AuthFlow state diagram desktop containment limitation 仍依 human accepted non-pass exception 記錄，未提升為 visual-check pass。 |
| RV-02 | Independent Reviewer | approved | 在 PR-05 approved 後，重新審查 documentation/diagram semantics、verification evidence、scope/contract/workflow drift。 | PR-05 = approved；TE-02 = approved；TE-03 = approved。 | `approved`；與 TE-02／TE-03 approved 一起滿足 DL-01 entry condition。 | Independent Reviewer 確認 Model C contract、legacy/target wording、allowlist、OAuth isolation 與三重 delivery gate 一致；AuthFlow state diagram human accepted containment limitation 維持 exact non-pass truth，沒有 scope/contract/workflow drift。 |
| PC-05 | Plan-Creator | completed | 只修正 RV-02 的 delivery/no-major-issue gate consistency finding。 | RV-02 = needs-rework。 | requirements、technical spec、plan 與 ledger/RV completion condition 一致要求 TE-02 approved、TE-03 approved、RV-02 approved；TE-01 維持 historical needs-rework。 | 2026-09-17 minimal planning correction；未改 docs、diagrams、source、tests 或 Git state。 |
| PR-05 | Independent Plan-Reviewer | approved | 獨立 minimal re-review RV-02 required delivery/no-major-issue gate correction。 | PC-05 completed。 | `approved`；確認 requirements、technical spec、plan 與 ledger/RV completion condition 均要求 TE-02 = approved、TE-03 = approved、RV-02 = approved。 | Independent Plan-Reviewer approved；此 minimal planning correction 不取代 RV-02 outcome-review verdict。 |
| DL-01 | Implementer | active | 在 no-major-issue gate 後依 topic delivery intent 執行 git commit convention、human-confirmed message、commit、push、open **draft PR**。 | TE-02 = approved、TE-03 = approved、RV-02 = approved，且 commit message 已獲 human confirmation。 | 單一 topic commit、push、draft PR 已建立；不 merge、release 或處理 review comment。 | Entry gate 已滿足；尚未記錄 commit、push 或 draft PR completion。 |
| HC-01 | Human | pending | Review draft PR。 | DL-01 completed。 | human 明示下一步。 | draft PR 建立後的強制 human boundary；不得自動前進。 |

## Locked Contract Checklist

- [x] 現行 `.send(HTTPRequest)` contract 為 legacy Model A，不是 adopted target。
- [x] adopted Model C：`AuthFlow` 只擁有 auth policy/state/retry decision，能理解
  `HTTPResponse`，但沒有 original request、arbitrary request construction 或 I/O
  capability。
- [x] `AuthRequester` 是 original request 唯一 owner 與 semantic action interpreter；
  `Requester` 是 generic HTTP I/O owner。
- [x] `AuthAction`、decoration、failure、async、refresh component/result API 均
  deferred，不可在本 topic 推定。
- [x] `TokenFetcher`／`TokenProvider` 在 matrix 為 N/A；不宣稱現有 runtime。
- [x] OAuth dual-client lifecycle documents/diagrams 永遠 ReadOnly。
- [x] PR-03 是唯一 replacement Plan Review gate；只有 PR-03 approved 滿足「Plan
  Review approved」並授權 IM-01。Swift implementation 永遠不在本
  topic 範圍。
- [x] branch 建議為 `docs/redefine-auth-subsystem-responsibilities`；不執行 branch
  action。

## TestCase

- **TC-01**：PC-01 only-created paths 為四份 artifacts；沒有 long-lived docs、diagram、
  Swift、test 或 manifest 寫入。
- **TC-02**：四份 artifacts 與 plan.md 的 Swift Implementation Handoff 對 Goal、
  Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Modify、Deleted、TestCase 及
  Model C decision 一致。
- **TC-03**：matrix 明確賦予 flow policy/state/retry ownership、AuthRequester original
  request ownership、Requester I/O ownership，且 Token roles 為 N/A。
- **TC-04**：只有 PR-03 approved 滿足「Plan Review approved」並可寫入 Phase 2
  docs/diagrams；PR-01／PR-02 的 `needs-rework` 不授權 Swift runtime。
- **TC-05**：TE-02 是 TE-01 的唯一 independent replacement verification gate；它在
  architecture-canvas／Archify skill gates 後驗證 diagram evidence，且 401 圖不虛構
  credential runtime。state diagram accepted containment limitation 維持 non-pass。
- **TC-06**：TE-02 approval 維持 historical replacement verification truth；RV-01 的
  two findings 經 PR-04 approved、IM-02 localization correction 與 TE-03 approved 後，
  RV-02 才可依 verification evidence 重新判定 verdict。
- **TC-07**：只有 TE-02 = approved、TE-03 = approved 與 RV-02 = approved 才是
  「無重大問題」並可進入 DL-01；commit-convention human confirmation 後交付 topic
  commit/push/draft PR，完成後停 HC-01。

## Blockers

沒有 scope、locked decision、allowlist 或 OAuth isolation blocker。TE-01 的兩項限定
correction 已由 IM-01 完成並經 TE-02 approved；TE-02 是唯一 replacement verification
gate。PR-04／PR-05 與 RV-02 已 approved；RV-01 的 second finding 已由 IM-02
diagram-localization correction 與 TE-03 approved 完成。DL-01 entry gate 已滿足，待
topic delivery。AuthFlow state diagram 存在 human 已明確接受、且僅限該 artifact
desktop vertical containment 的 visual-check limitation；它是 exact accepted non-pass
exception，不是 visual-check pass。若發現其他 diagram contract 不一致，停止並交還
human 或對應規劃角色，不得自行推定 resolution。

## Human Check

HC-01 是強制 human boundary。draft PR 建立後，只有 human 可授權後續工作；不得
自行 merge、release 或開始 future Swift implementation。

## Last Updated

2026-09-17 — PR-01／PR-02 = `needs-rework`；PC-02／PC-03 completed；PR-03／PR-04 =
`approved`；IM-01 = `completed`（含 TE-01 兩項限定 correction）；TE-01 =
`needs-rework`；TE-02 = `approved`（唯一 replacement verification gate）；RV-01 =
`needs-rework`（two findings）；PC-04／IM-02 completed；TE-03 = `approved`；RV-02 =
`approved`；PC-05 completed；PR-05 = `approved`；DL-01 active。AuthFlow state diagram
exact accepted containment limitation 維持 non-pass exception。Plan-Creator 自身不產生
standard verdict（`null`）。
