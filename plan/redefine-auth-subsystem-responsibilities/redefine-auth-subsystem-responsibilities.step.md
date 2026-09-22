# Auth 子系統責任重定義：Step Ledger

## Current Phase

`rv-14-canonical-containment-review-active`。IM-16 已完成，TE-13 已由 Independent Tester `approved`；DL-10 的 corrected delivery 已可見，CH-09 已重新取得
thread state，但 P1 `PRRT_kwDOUFu0Cc6kQlYl` 指出 `401-refresh-retry.delivery.json` 含有本機絕對路徑。
CH-09 因此為 `blocked`；這是 delivery receipt 的 provenance／privacy 回修，不是新需求、architecture
decision、401 flow contract 或 retry-policy change。RV-13 = `needs-rework`：IM-16 的 lexical
`--repo-root` containment 尚可接受 lexical 在 repository 內、但 canonical resolve 後逃逸到 root 外的 symlink
input／output，因此不足以滿足 P1 的 provenance boundary。IM-17 已完成 canonical containment：producer 先以
`realpath` canonicalize repository root 與 input／output，再判定實體 descendant 關係；direct-outside 與 in-root
symlink-escape rejection tests 均在 delivery／receipt-write 前通過 fail-closed 驗證。success path 已由 repository
root 的 relative input／output 重新產生同一份 401 receipt，未對 generated receipt 作 postprocess；receipt 的 path
與 provenance metadata 維持 canonical repository-relative 表達。TE-14 已由 Independent Tester `approved`；RV-14 已由 Independent
Reviewer `approved`；DL-12 是目前的 delivery gate（ledger status = `active`）。
目前 route 為 RV-14 → DL-12 → CH-11 → HC-11。不得建立新的 Plan-Creator／Plan-Reviewer cycle，
亦不得重開 Model C、deferred ownership 或任何既有 evidence；DL-12 corrected delivery visible 前仍不得 reply 或
resolve P1 thread。delivered head 的歷史只記錄 `RV-04 = approved` 與
`DL-03 = active`；不得將 commit/push、thread closure 或 HC-02 寫成已完成。current PR #37
comment preflight 為 `needs-rework`，有四個必要的 diagram／ledger findings。PC-08 已完成本
planning amendment；PR-08 已由 independent Plan-Reviewer `approved`。human 已接受
`auth-flow-state.json` Archify showcase crossing diagnostic `[850,307]` 的 narrowly scoped
accepted non-pass，故 IM-07 不再維持 human-decision `blocked`；PC-09 已完成，PR-09 已由
independent Plan-Reviewer `approved`；IM-07 已如實記錄 standard `deliver` 無法為 accepted-invalid
state source 產生 source-matched output／receipt 的 concrete blocked history。human 現已明確授權
state-artifact-only alternate delivery contract；PC-10 已修正 PR-10 指出的兩處 historical/current
contradiction，PR-10 已由 independent Plan-Reviewer `approved`。IM-08 已驗證 Archify public
validate／deliver／render 都在同一個 `[850,307]` proper-crossing 失敗；preview 沒有 source-matched
output，故 alternate-materialization path 已被 human 授權的 state topology/layout redesign supersede。
PC-11／PR-11 是已核准 state-redesign history。PC-12 已完成，將 IM-09 保持 state-only，新增
IM-10 source-ReadOnly materialization 與 TE-08 verification-only boundary；PR-12 已由 independent
Plan-Reviewer `approved`。IM-09 recovery 的 valid semantic candidate baseline proper-crossing 為
`[850,307]`（waiting-retry-response 與 second-401-terminal）；R1 `[900,479]`、R2 `[402,252]`
皆仍為 1 crossing，構成兩輪連續無改善，故 IM-09 `blocked`；所有 unproven changes 已還原，未更新
HTML、receipt 或 state evidence。human 已選擇 recommended state-diagram **expression** revision：retry
permission 必須是進入 `waiting-for-retry-response` 的 transition／event、不是 lifecycle node；waiting
state 將 retry response 交給 `response-policy`，後者才分支 normal success 與 second-401 terminal。
這不是 retry-policy change。PC-13 已完成此 planning amendment，supersede alternate HTML
materialization 與 IM-09 prior state-node formulation；PR-13 已由 independent Plan-Reviewer `approved`。
IM-11 已完成 standard 9/9、source-matched delivery 與 exact state non-pass visual evidence。IM-10 的
package materialization 已完整通過，但 fresh 401 visual-check 在 1440×900／1600×1000 垂直失敗，且不屬於
state exception，故 IM-10 `blocked`。human 現授權 bounded 401 layout/source adjustment（非新 exception）；
PC-14 已完成、PR-14 已由 independent Plan-Reviewer `approved`。IM-12 在兩次 reverted layout attempts
與 bounded renderer diagnosis 後 historical `blocked`：17 messages／28px gaps 需要約 700px timeline，但
1080×700 雖 validate 仍 visual overflow 1001／1073；1080×600 違反 geometry/readability；1250×700 的
context projection 只有 5.208px，小於 6px。human 已選擇 bounded participant-context presentation change：
PC-15 已完成，PR-15 已由 independent Plan-Reviewer `approved`；IM-13／IM-14 已完成；TE-11 re-test
已 `approved`，RV-11 = `needs-rework`，TE-12 initial = `needs-rework`，IM-15 rework = completed，
TE-12 re-test = approved、RV-12 = approved、DL-10 = completed、CH-09 = blocked、IM-16 = completed、
TE-13 = approved、RV-13 = needs-rework、IM-17 = completed、TE-14 = approved、RV-14 = approved、DL-12 = active；current route 為 RV-14 → DL-12 → CH-11 → HC-11。17 messages、flow/policy/component identities
與 package passed evidence 均鎖定、不重做。
PR #37 是既有 **OPEN、ready for review** PR；不得改變其 status，也不得在新的 delivery gate
前 reply/resolve thread。
既有 factory sequence、繁體中文作者文案、allowlist、OAuth ReadOnly 與 Model C decision 仍鎖定；
唯一 visual exception 仍是 state desktop containment 1035／1109／1109、2048 pass 的 exact
human accepted non-pass。現行 Model A runtime 仍保持 legacy；adopted Model C 是尚未實作的
architecture target。

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
和 final human review，以及 PR #37 narrow comment-fix 的 replacement review、bounded
documentation/diagram correction、independent verification/review、existing ready-for-review PR delivery、
thread reply/resolve 與 human review。

本 ledger 亦追蹤 current PR #37 comment preflight 的四個 bounded correction：401 的 caller
entry／factory round-trip、state 的 retry-response policy topology、package canvas 的 deferred
preparation ownership，以及 delivered-head/current-preflight workflow truth。它們不重開 Model C
或任何 deferred API。

本 ledger 亦追蹤 CH-09 後唯一新增的 P1：401 delivery receipt 不得保留本機絕對路徑。此回修只處理
receipt 的 repository-relative path provenance；401 source、HTML、17-message flow、factory prefix、
retry policy、visual evidence 與其他 diagram/canvas 均不在範圍內。

RV-13 指出的 symlink-escape 是同一 P1 的 canonical-containment gap：IM-17 只修正既有 receipt producer
對 canonical repository root／input／output 的 containment 判定，並新增 direct-outside 與 in-root symlink-escape
rejection tests；成功路徑才可重新產生同一份 401 receipt。這不改變 receipt schema、401 artifact source／HTML、
architecture、policy 或任何 product source。

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
及其 artifact-local evidence；PR #37 comment-fix 另僅可依 plan.md 使用既有 Written
 namespace，並在 Modify allowlist 中新增的 `BUILD.md` 固定作者 arguments。
- IM-16：只可修改 `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.delivery.json`
  與此 actual-step ledger evidence，以 repository-relative path 重新產生並 sanitize receipt；401 source、HTML、
  visual evidence、其他 diagrams/canvas、Swift、OAuth、Git 與 GH 均為 ReadOnly。
- IM-17：只可修改既有 Archify receipt producer 的以 `realpath` canonicalize repository root／input／output
  的 containment implementation 與其 direct-outside／in-root symlink-escape tests，並在 tests 通過後以
  repository-relative arguments 重新產生同一份
  `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.delivery.json` 與此
  actual-step ledger evidence；不得 postprocess generated receipt。401 source／HTML、receipt schema、visual evidence、其他 diagrams/canvas、
  architecture、product source、Swift、OAuth、Git 與 GH 均為 ReadOnly。

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
| DL-01 | Implementer | completed | 原 topic delivery：依 no-major-issue gate 執行 topic delivery 至 PR #37。 | TE-02 = approved、TE-03 = approved、RV-02 = approved。 | PR #37 已存在且為 OPEN、ready for review；不構成此次 comment-fix delivery completion。 | human 已執行 PR status decision；本 PC-07 amendment 不執行 Git/PR action，也不得改變 status。 |
| HC-01 | Human | needs-rework | 原 ready-for-review PR human review。 | DL-01 completed。 | PR #37 review finding 已交回 planning correction。 | PR #37 comment review verdict = `needs-rework`；不得當作 human approval。 |
| PC-06 | Plan-Creator | completed | 建立 PR #37 narrow comment-fix planning contract。 | PR #37 comment review = needs-rework，T04 planning-allowlist blocker。 | 四份 planning artifacts 一致記錄 matrix、eligible-refresh topology、diagram/reproducibility allowlist、thread workflow，且不寫入 long-lived docs/diagrams/source/tests/Git/PR。 | 2026-09-17 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-06 | Independent Plan-Reviewer | approved | 獨立審查 PC-06 的 narrow comment-fix contract、allowlist、thread routing 與 no-drift boundary。 | PC-06 completed。 | `approved` 授權 IM-03；`needs-rework` 只交回 Plan-Creator。 | Independent Plan-Reviewer 明示確認 matrix correction、eligible-refresh topology、既有 Written namespace 的 limited correction、僅 `BUILD.md` 的 fixed-author-arguments Modify allowance，以及 T01–T09/resolve gate 都維持 Model C、無新增 Swift/OAuth/runtime scope。 |
| IM-03 | Independent Implementer | completed | 在 PR-06 approved 後，依 narrow allowlist 修正 canonical document、lifecycle／401／state artifacts/evidence 與 package `BUILD.md` fixed author arguments。 | PR-06 = approved。 | T01–T09 對應 corrected delivery 可供獨立驗證；不改 Swift/OAuth、enhancement script 或其他 build semantics。 | 2026-09-17：T01／T02 已將 requirements、technical spec 與 canonical matrix 校正為 `AuthRequester` 不建構、只保有 caller original request，selected／decorated representation 維持 deferred。T03／T05／T07／T08／T09 的 lifecycle、401、state source/output/evidence 已表達 per-execution flow、無 request-payload exchange、eligible refresh、deferred result 回 flow、refresh-success-only retry 與 terminal branches。`BUILD.md` 僅固定繁中 kicker/subtitle 作者參數；package canvas 依 validate → temporary build → enhance → verify 重建，5 bands／15 boxes／23 edges／0 errors／0 warnings，accessibility verify passed。Archify deliver：lifecycle spec `709dbe8c64b629d5667b75482d02ac0b644be5978cdda0c46810e91c7feb4e67` → HTML `4827cc8f421f05cd78174784f879ecd62d683faf7a6d69e9689dfced6d7f8d34`；401 spec `dddeba1fe83651331ffc679a6f6cabd67d5b1c61a2bc80706c0ef5d0722b6fe5` → HTML `28ad7c990a0948d2557a2a04110b029526918b4b733c1e31c849927184594814`；state spec `f8fb0c2df37e719248b46468a3928df03d9be8a6cdb0b7db9ef83fc3596f429d` → HTML `350987b27a46f6caeec3bba3c43508dbcd6d22f7720b4a71e2d86da71552253c`；皆 showcase 9/9、0 errors、0 warnings。lifecycle 與 401 visual-check 全 viewport pass；state 保留 exact accepted non-pass：1440×900 scrollHeight 1035、1600×1000／1920×1080 均 1109、2048×1320 pass。已人工檢視三份 Archify 的 1440×900 light/dark 截圖與 package canvas 1440×900 output；T01–T09 維持 unresolved，T06 未觸碰，未進行 testing/review/commit/push/reply/resolve。 |
| TE-04 | Independent Tester | approved | 獨立驗證 IM-03 的 matrix、eligible-refresh topology、diagram source/output/evidence、BUILD reproducibility、allowlist 和 state exception truth。 | IM-03 completed。 | `approved` 才可進入 RV-03；state visual exception 維持 non-pass。 | Independent Tester 明示確認 matrix 的 `AuthRequester` 不建構 original request、eligible-refresh topology、lifecycle／401／state source-output-evidence、`BUILD.md` fixed-author-arguments reproducibility 與 allowlist/OAuth isolation；state desktop containment limitation 維持 exact accepted non-pass。 |
| RV-03 | Independent Reviewer | needs-rework | 獨立審查 corrected delivery 的 scope、contract、workflow drift 與 TE-04 evidence。 | TE-04 = approved。 | 提出三項限定 correction：(1) `Auth` factory 必須在 semantic send 前建立 per-execution `AuthFlow`，不畫 `AuthRequester` 取得預先存在 flow；(2) lifecycle／401／state 所有說明性文案為繁體中文，僅 identifier 保留英文；(3) PR #37 已為 OPEN、ready for review，後續 workflow 不得稱 draft 或改變 status。 | `needs-rework`；不構成 DL-02 approval。 |
| DL-02 | Implementer | superseded | 原 RV-03 approval 後的 follow-up delivery。 | TE-04 = approved、RV-03 = approved。 | 由 DL-03 replacement gate 取代。 | RV-03 = needs-rework；未開始 commit/push。 |
| CH-01 | Implementer | superseded | 原 RV-03 approval 後的 thread handling。 | DL-02 completed。 | 由 CH-02 replacement gate 取代。 | RV-03 = needs-rework；未 reply 或 resolve。 |
| PC-07 | Plan-Creator | completed | 建立 RV-03 三項限定 correction 的 planning amendment。 | RV-03 = needs-rework。 | 四份 planning artifacts 一致記錄 factory-created per-execution flow、diagram explanatory prose Chinese、PR #37 OPEN/ready-for-review wording 與 replacement gates；不寫 long-lived docs/diagrams/Git。 | 2026-09-17 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-07 | Independent Plan-Reviewer | approved | 獨立審查 PC-07 的 correction contract、allowlist、workflow/status wording 和 no-drift boundary。 | PC-07 completed。 | `approved` 授權 IM-04；`needs-rework` 只交回 Plan-Creator。 | Independent Plan-Reviewer 明示確認 `Auth` factory-before-flow sequence、lifecycle／401／state 繁體中文說明文案、PR #37 OPEN/ready-for-review wording 與 replacement gates 一致，且無 Swift/OAuth/PR-status scope drift。 |
| IM-04 | Independent Implementer | completed | 在 PR-07 approved 後，修正既有 allowlist 內 lifecycle／401 sequence，使 `Auth` factory 建立 flow，並將 lifecycle／401／state 說明性文案改為繁體中文。 | PR-07 = approved。 | 三項 RV-03 corrections 均可供獨立驗證；不改 Swift/OAuth/PR status 或其他 build semantics。 | 2026-09-18：只修改 allowlist 的 lifecycle／401／state Archify source、HTML 與 artifact-local visual-check evidence。401 sequence 現由 `Auth` 為本次 execution 建立新的 `AuthFlow`，再由 `AuthRequester ↔ AuthFlow` 以「無 request 資料」的初始語意交換；refresh result 經延後確定邊界回 flow，僅更新成功才允許一次重試。lifecycle／state 亦表達每次執行前由 `Auth` 建立流程，且所有說明性文案均改為繁體中文。Archify deliver：lifecycle spec `4b0737576d85dd880965f52d951742fcc5e2396537df57153ccd1e4f80e8e9e2` → HTML `c602d39cb0da9c770f799273b60e86b7a78417ec487f83a06a4e2045fe7114c1`；401 spec `9f7a884b24b80cc8cc04331ca61b0dd30dfd4742a98d64f22d7ae909c82745a8` → HTML `66e913f5012d149d2532d76fb4a4b946c8f7e1bc416b80034200c07c93aa8efd`；state spec `d39d157ab414f133f3225bc9799397db691da24eda3924e30b1f72f5939ab2a4` → HTML `a346265a8c8fcb06e2bbf7b26888f3f26774fadd89ee958d6642fd34ce030c24`；皆 showcase 9/9、0 errors、0 warnings。lifecycle 與 401 visual-check 在四個 viewport 全通過；state 維持 exact accepted non-pass：1440×900 scrollHeight 1035、1600×1000／1920×1080 均 1109、2048×1320 通過。已人工檢視三份 1440×900 light/dark 截圖；`git diff --check` 通過，dev clean，未改 Swift／OAuth、未執行 testing/review/commit/push/PR/thread action。 |
| TE-05 | Independent Tester | approved | 在 IM-06 後獨立 re-test factory sequence、繁體中文圖文、locked state topology、allowlist、PR status truth 和 state exception。 | IM-06 completed。 | `approved` 授權 RV-04 re-review；state visual exception 維持 non-pass。 | 2026-09-18 re-test：state 明確包含 `first-401 → ineligible-401`「不具資格／不具更新能力」終態轉移，以及具資格首次 401→待定憑證更新、更新結果回流程、僅成功才一次重試；不存在 receive→retry shortcut。T01–T09 remediation、matrix ownership、Auth factory 在無請求資料的 semantic exchange 前建立 per-execution `AuthFlow`、繁體中文說明文案與 Model C／OAuth ReadOnly 均一致。lifecycle、normal、401、state 的 Archify validation 均為 showcase 9/9、0 errors、0 warnings；lifecycle／401 visual-check 四 viewport pass。state 僅維持 human accepted non-pass：1440×900 scrollHeight 1035、1600×1000／1920×1080 均 1109、2048×1320 pass，未宣稱為通過。package canvas 以固定繁中 kicker／subtitle 參數在暫存路徑重建並與 delivered HTML byte-identical，architecture-canvas 5 bands／15 boxes／23 edges／0 errors／0 warnings、可近用性驗證通過。`git diff --check` 通過，無 Swift／OAuth／manifest 變更，dev clean。 |
| IM-05 | Independent Implementer | completed | 只在既有 diagram allowlist 中，將 lifecycle、401、state source 的作者說明文案之非 identifier 英文 `request` 改為「請求」。 | TE-05 = needs-rework。 | 三份 source 不再含該非 identifier 英文；不變更 architecture decision、factory sequence、scope、PR status 或既有 passing validation evidence。 | 2026-09-18：只將三份來源中的「無 request 資料」改為「無請求資料」；source 搜尋僅保留 identifier `client-sends-initial-request`。Archify deliver：lifecycle spec `3593ff99851f6b8838c813a0c1674aba9ccb15091aeec524dd59db208f64966f` → HTML `b33187ae3bfae9e8b9c15c695ffdec196d6edf2bbd1976b85d79ba198c6b4d8d`；401 spec `e331e906bac323c3a75e86f6a4e1d964b3d02005647d8b18c3efbea7e6ef6f99` → HTML `f4e4d9f546a7f772127b008a7e64f7e01b47bc0d7fb3b142155992d4697c73ca`；state spec `67a9b52a09f44ca9e0213913bae8f8107167f25a81601d7091a196896014d150` → HTML `e96dc0ad443b83f48c3fc4bf7e9d22ec46c030543ad16f4af04988f7820c2a6a`；三者皆 showcase 9/9、0 errors、0 warnings，unchanged normal sequence 亦 9/9、0 errors、0 warnings。lifecycle 與 401 visual-check 四個 viewport 通過；state 維持 exact accepted non-pass：1440×900 scrollHeight 1035、1600×1000／1920×1080 均 1109、2048×1320 通過，未稱為 pass。已檢視三份 1440×900 light/dark screenshots；未改 Swift／OAuth、未執行 testing/review/commit/push/PR/thread action。 |
| RV-04 | Independent Reviewer | approved | 獨立 re-review IM-04／IM-05／IM-06 corrected delivery 的 scope、contract、workflow/PR-status drift 與 TE-05 re-test evidence。 | TE-05 = approved。 | `approved` 授權 DL-03。 | Independent Reviewer 確認 `first-401 → ineligible-401` terminal transition 已完成 T03/T09 的 locked topology、factory sequence／繁體中文作者文案／allowlist／PR #37 OPEN-ready-for-review truth 一致，且 TE-05 evidence 與 state exact accepted non-pass 維持；無 scope、contract 或 workflow drift。 |
| IM-06 | Independent Implementer | completed | 只在 `auth-flow-state.json` 補入已鎖定的 first-401 ineligible-flow → terminal transition，並重建該 artifact 的 associated generated output／validation／visual evidence。 | RV-04 = needs-rework。 | transition 與 evidence 可供獨立 re-test；不改 architecture decision、其他 state policy、scope、PR status 或 state visual exception status。 | 2026-09-18：新增 `first-401 → ineligible-401` 的「不具資格／不具更新能力」終態轉移；具資格的首次 401→憑證更新、更新結果回策略狀態、僅成功才一次重試，以及無 receive→retry shortcut 均保持。Archify deliver：spec `b6f8b2a46ca9b493340885ad086a6f5cef9836d3be35a7fc07df9a8601c49e72` → HTML `552856a72c8b8d3abd1daf72552f225fa946fe611d3f0f507d487e4fe7cf12ad`；showcase 9/9、0 errors、0 warnings。visual-check 維持 human accepted non-pass：1440×900 scrollHeight 1035、1600×1000／1920×1080 均 1109、2048×1320 pass；已檢視 smallest/largest 的 light/dark 截圖，未宣稱 failed sizes pass。未改其他 diagrams、Swift、OAuth 或 manifests；未執行 testing/review/commit/push/PR/thread action。 |
| DL-03 | Implementer | active | 在 TE-05/RV-04 approved 後，依 topic delivery contract 作既有 OPEN、ready-for-review PR #37 的 delivery。 | TE-05 = approved、RV-04 = approved，且 commit message 已獲 human confirmation。 | 僅記錄 delivered head 的 active delivery state；不得由本 ledger 推定 commit/push、thread closure 或 human review 已完成。 | delivered head 歷史：RV-04 = approved、DL-03 = active。 |
| CH-02 | Implementer | superseded | 原 PR #37 supplied evidence 的 thread reply/resolve。 | historical delivery condition（未由本 ledger 記為完成）。 | 由 current-comment replacement route 的 CH-03 取代。 | current preflight = needs-rework；不得以此 historical step 提前 reply/resolve。 |
| HC-02 | Human | superseded | 原 corrected PR human review。 | historical CH-02 condition（未達成）。 | 由 HC-03 replacement human boundary 取代。 | current preflight = needs-rework；未構成 human approval。 |
| RV-05 | Independent Reviewer | needs-rework | Current PR #37 comment preflight：獨立分類四個新必要 thread 的 scope／contract／workflow drift。 | PR #37 新 comment evidence 已提供。 | required correction 僅限：(1) 401 caller entry 與 `AuthRequester → Auth → AuthRequester` factory round-trip；(2) retry permission → waiting-for-retry-response → response-policy topology；(3) package canvas 不指派 selected／decorated preparation 給 `AuthRequester`；(4) ledger delivered-head／current-preflight truth。 | `needs-rework`；不授權 implementation、delivery 或 thread resolution。 |
| PC-08 | Plan-Creator | completed | 建立 RV-05 四項 bounded correction 的 planning amendment。 | RV-05 = needs-rework。 | 四份 planning artifacts 一致記錄 diagram allowlist、deferred ownership、historical ledger truth、independent gates 與 CH-03 thread policy；不寫 long-lived docs/diagrams/Git。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-08 | Independent Plan-Reviewer | approved | 獨立審查 PC-08 的 four-thread correction contract、allowlist、state topology、workflow truth 與 no-drift boundary。 | PC-08 completed。 | `approved` 授權 IM-07；`needs-rework` 只交回 Plan-Creator；`blocked`／`human-check` 停止。 | Independent Plan-Reviewer 明示確認四個 correction 均維持 Model C、OAuth ReadOnly、original request ownership 與 deferred API boundary；401 factory prefix、retry-response topology、package canvas deferred preparation ownership、delivered-head/current-preflight ledger truth及 PR-08 replacement route 一致，無 scope／contract／workflow drift。 |
| IM-07 | Independent Implementer | superseded | 在 PR-08／PR-09 approved 後，只修正 401 sequence、AuthFlow state 與 package canvas 的 current-comment allowlist。 | PR-08 = approved、PR-09 = approved。 | standard source/output/evidence 一致滿足 F1–F3；不改 Swift/OAuth/PR status、deferred owner／representation、其他 diagrams 或 build semantics。 | historical concrete blocker：standard Archify `deliver` 必須所有 showcase checks 通過才會 atomically 寫入 source-matched state HTML／receipt；`[850,307]` accepted-invalid state 不能達成此條件。human acceptance 不改變 non-zero exit。human 後續只授權 state-only alternate contract，故由 IM-08 replacement route 取代；此 row 不是 pass 或 delivery approval。 |
| PC-09 | Plan-Creator | completed | 將 human-accepted state showcase crossing exception 與 output/evidence limitation 寫入四份 formal planning artifacts。 | human 明示接受 `[850,307]` crossing 的 narrowly scoped non-pass。 | 四份 artifacts 一致記錄 source、diagnostic、兩次 focused repair、一次 independent overall-layout attempt、attempts restored、distinct desktop containment exception、unchanged gates，以及無 source-matched delivery 時的 concrete blocker；不寫圖表／Git。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-09 | Independent Plan-Reviewer | approved | 獨立審查 PC-09 exception boundary、delivery limitation、unchanged gates 與 no-drift contract。 | PC-09 completed。 | `approved` 才可使 IM-07 進入 bounded materialization；`needs-rework` 只交回 Plan-Creator；`blocked`／`human-check` 停止。不得將 accepted non-pass 判為 showcase pass、zero-error validation 或 delivery approval。 | Independent Plan-Reviewer 明示確認 `[850,307]` 僅為 accepted non-pass、兩次 focused repair／一次 independent overall-layout attempt／attempts restored 如實記錄、desktop containment exception 獨立、其他 gates 不被豁免，且 standard `deliver` source-matching limitation 是 concrete blocker；無 architecture、scope 或 workflow drift。 |
| TE-06 | Independent Tester | superseded | 獨立驗證 IM-07 的 four-thread diagram correction、allowlist、artifact gates、state exception 與 no-drift boundary。 | IM-07 completed，且全部 affected artifacts 有 standard source-matched output/evidence。 | 由 TE-07 replacement route 取代。 | IM-07 standard-delivery blocker 已由 human-authorized state-only alternate contract 的 new route 取代；未開始。 |
| RV-06 | Independent Reviewer | superseded | 獨立審查 TE-06 evidence、scope、contract、workflow/PR-status drift 與 current-comment findings。 | TE-06 = approved。 | 由 RV-07 replacement route 取代。 | TE-06 未開始。 |
| DL-04 | Implementer | superseded | 在 TE-06/RV-06 approved 後，依 topic delivery contract commit/push corrected delivery 至既有 OPEN、ready-for-review PR #37。 | TE-06 = approved、RV-06 = approved，且 commit message 已獲 human confirmation。 | 由 DL-05 replacement route 取代。 | TE-06／RV-06 未完成；未執行 Git/PR action。 |
| CH-03 | Implementer | superseded | 在 DL-04 visible 後重新取得 PR #37 thread state，處理 current-comment threads。 | DL-04 completed。 | 由 CH-04 replacement route 取代。 | 未 reply/resolve。 |
| HC-03 | Human | superseded | Review corrected OPEN、ready-for-review PR #37。 | CH-03 completed。 | 由 HC-04 replacement human boundary 取代。 | 未進入 human review。 |
| PC-10 | Plan-Creator | completed | 將 human-authorized state-only alternate delivery contract 寫入四份 formal planning artifacts。 | human 明示僅 state 可在無 successful standard `deliver` receipt 時以 alternate path materialize。 | 四份 artifacts 一致記錄 Archify supported-tooling determination、`unavailable`／`non-pass` evidence truth、`[850,307]`／repair history、checksum/provenance、manual inspection-if-possible、unchanged desktop exception 與 all-other-gates；不寫 diagram/Git/GH。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-10 | Independent Plan-Reviewer | approved | 獨立 re-review PC-10 state-only alternate delivery boundary與可操作性。 | PC-10 completed，且 requirements 兩處已明確將 IM-07 standard-deliver rule 改記為 historical limitation。 | 確認僅 state 例外、只有 IM-08 先判定 supported-tool path、receipt/evidence 不宣稱 successful deliver／9/9／zero-error/pass、`unavailable`／`non-pass`、checksum/provenance、`[850,307]`／repair history 和 manual inspection-if-possible 明確，且 401/package/desktop exception/all other gates 未漂移；`approved` 授權 IM-08。 | Independent Plan-Reviewer re-review approved：PR-10 finding 已被 PC-10 correction 消除；state-only alternate contract 可操作，無 architecture、scope 或 workflow drift。 |
| IM-08 | Independent Implementer | superseded | 在 PR-10 approved 後，判定 state alternate-materialization path。 | PR-10 = approved。 | 由 IM-09 normal-delivery state redesign 取代。 | historical blocked：Archify public validate／deliver／render 全部在同一 `[850,307]` proper-crossing 失敗；preview 未產生 source-matched output。source SHA-256 `533dd212c4650adc07499cec415155e06e051619da6a9fcf379e0fb897f412bd`，existing HTML SHA-256 `552856a72c8b8d3abd1daf72552f225fa946fe611d3f0f507d487e4fe7cf12ad`，mismatch；無 output/evidence 寫入。human 現授權 topology/layout scope，故不再等待 alternate delivery authority。 |
| TE-07 | Independent Tester | superseded | 獨立驗證 IM-08 alternate evidence。 | IM-08 completed。 | 由 TE-08 replacement route 取代。 | IM-08 未完成；未開始。 |
| RV-07 | Independent Reviewer | superseded | 獨立審查 TE-07 evidence。 | TE-07 = approved。 | 由 RV-08 replacement route 取代。 | 未開始。 |
| DL-05 | Implementer | superseded | 在 TE-07/RV-07 approved 後 delivery。 | TE-07 = approved、RV-07 = approved。 | 由 DL-06 replacement route 取代。 | 未開始；未執行 Git/PR action。 |
| CH-04 | Implementer | superseded | 在 DL-05 visible 後處理 current-comment threads。 | DL-05 completed。 | 由 CH-05 replacement route 取代。 | 未 reply/resolve。 |
| HC-04 | Human | superseded | Review corrected PR #37。 | CH-04 completed。 | 由 HC-05 replacement human boundary 取代。 | 未進入 human review。 |
| PC-11 | Plan-Creator | completed | 將 human-authorized state topology/layout delivery-recovery redesign 寫入四份 formal planning artifacts。 | human 明示 scope 只可擴張 state presentation，以恢復 normal Archify delivery。 | 四份 artifacts 一致記錄 state-only restructure/merge/reposition allowance、五項 locked semantics、`[850,307]` 必須消除、state standard 9/9/0-error/0-warning/deliver/source-match、desktop exception unchanged、401/package/all-other-gates preserved 與 replacement route；不寫 diagram/Git/GH。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-11 | Independent Plan-Reviewer | approved | 獨立審查 PC-11 state delivery-recovery scope、locked semantics、normal delivery gate與 no-drift boundary。 | PC-11 completed。 | 確認 scope 只限 `auth-flow-state` topology/layout presentation、允許 restructure/merge/reposition 但不改 policy semantics；`[850,307]` 必須消除並 normal validate 9/9/0-error/0-warning/deliver/source-match；desktop exception、401/package、ReadOnly/PR/thread gates 不變；`approved` 授權 IM-09。 | Independent Plan-Reviewer approved：state-only redesign allowance、五項 locked semantics、restored mandatory standard delivery、desktop exact non-pass 及 all-other-gates preservation 一致；無 architecture、scope 或 workflow drift。 |
| IM-09 | Independent Implementer | superseded | PR-12 後的 state-node/topology/layout recovery。 | PR-12 = approved。 | 由 PC-13 expression-revision route 取代；不得視為 active policy or delivery path。 | historical blocked：baseline `[850,307]`（waiting-retry-response vs second-401-terminal）；R1 `[900,479]`、R2 `[402,252]` 均仍 1 crossing，滿足兩輪連續無改善；所有 unproven changes 已還原，未更新 HTML、receipt、state/visual evidence。 |
| PC-12 | Plan-Creator | completed | 將 state-only source change 與 independent 401/package output materialization 分離，寫入四份 formal planning artifacts。 | human 指定 IM-09 state-only、IM-10 source ReadOnly、TE-08 verification-only。 | 四份 artifacts 一致記錄 IM-10 的 401 standard validate→deliver→visual-check、package validate→temporary build→enhance→verify、BUILD.md/enhancement script ReadOnly、actual unproven source/output checksum observations，以及 PC-12→PR-12→IM-09→IM-10 route；不寫 diagram/Git/GH。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-12 | Independent Plan-Reviewer | approved | 獨立 re-review PC-12 source/output separation、actual mismatch observation、role boundary與 no-drift contract。 | PC-12 completed，且 ledger current route 已移除未開始的 post-PR-11 IM-09。 | 確認 IM-09 只改 state、IM-10 不改 source且只 materialize 401/package、TE-08 只 verify；401/package pipeline及 state locked/normal-delivery gates、BUILD.md/enhancement script ReadOnly、Model C/deferred decisions/other scopes 未漂移；`approved` 授權依序進入 IM-09、IM-10。 | Independent Plan-Reviewer re-review approved：PC-12 route correction、source/output separation、unproven checksum wording及 all boundary/gate preservation 一致，無 architecture、scope 或 workflow drift。 |
| PC-13 | Plan-Creator | completed | 將 human 選擇的 state expression revision 寫入四份 formal artifacts／ledger。 | human 明示這是 expression revision、不是 retry-policy change。 | retry permission 必是進入 `waiting-for-retry-response` 的 transition／event、非 lifecycle node；waiting state 再將 retry response 交給 `response-policy` 分支。supersede alternate HTML materialization 與 IM-09 prior state-node formulation；IM-10 scope untouched；不寫 diagram/Git/GH。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-13 | Independent Plan-Reviewer | approved | 獨立審查 PC-13 expression-only scope、locked semantics、normal standard state delivery、desktop exception與 no-drift boundary。 | PC-13 completed。 | 確認 retry permission 非 node、無 policy change、refresh-success-only exactly-one retry、waiting→response-policy split、無 receive→retry，且 401/package/IM-10 and all other gates unchanged；`approved` 授權 IM-11。 | Independent Plan-Reviewer approved：PC-13 將 retry permission 限為進入 waiting-for-retry-response 的 transition／event，非 lifecycle node；waiting state/response-policy 分流、locked semantics、standard delivery、desktop exception、IM-10 source-ReadOnly 與 all-other gates 一致，未發現 policy、scope、contract 或 workflow drift。 |
| IM-11 | Independent Implementer | completed | 在 PR-13 approved 後，只將 `auth-flow-state` 的 retry permission 改為進入 waiting state 的 transition／event，並做必要 presentation topology/layout 調整。 | PR-13 = approved。 | 保留 first-401 ineligible terminal、eligible refresh、outcome 回 Flow policy、refresh-success-only exactly-one retry、waiting-for-retry-response → response-policy normal-success/second-401 terminal，無 receive→retry；state standard validate 9/9、0 errors/warnings、successful deliver/source-matched receipt、visual evidence/manual light-dark inspection。 | 2026-09-18：只修改 state source、HTML 與 artifact-local visual evidence。移除 `retry-permission` lifecycle node；`refresh-success → waiting-for-retry-response` 的「更新成功：一次重試許可」transition／event 只在更新成功後進入等待重試回應，再回 `response-policy` 分流正常終態或第二次 401 終態。Archify validate／deliver 均為 showcase 9/9、0 errors、0 warnings；source SHA-256 `9ee9c0e466b5245355dd6c67f4da520928ed528c072bd90904c6d0aca45410fe`（4204 bytes）→ HTML SHA-256 `3267ff0257abfad1026e31fd765da93a827edeb49be0ccbba0eb5d3227486b5d`（708827 bytes）。visual-check 如實為 non-pass：1440×900 scrollHeight 1035、1600×1000／1920×1080 均 1109、2048×1320 pass；已檢視 1440×900 與 2048×1320 light/dark screenshots，未將既有 desktop containment exception 宣稱為通過。未重用 alternate-materialization path，未修改 401/package、Swift、OAuth、manifest、Git 或 PR/thread。 |
| IM-10 | Independent Implementer | superseded | IM-11 後的 401/package source-ReadOnly materialization step。 | PR-13 = approved、IM-11 completed。 | 401 source-ReadOnly restriction 只由 IM-12 的 bounded 401 repair supersede；package passed evidence 維持，不得重做。 | historical blocked：401 standard `deliver` 9/9、0 errors、0 warnings、source-matched，但 fresh visual-check 1440×900 scrollHeight 1001、1600×1000 1073，1920×1080／2048×1320 pass；不屬於 state exception。package materialization 完整通過：5 bands／15 boxes／22 edges、0 errors、0 warnings、build→enhance→verify、byte-identical output。 |
| TE-08 | Independent Tester | superseded | PC-12 route 的 verification-only gate。 | IM-09 completed、IM-10 completed。 | 由 TE-09 replacement route 取代。 | 未開始。 |
| RV-08 | Independent Reviewer | superseded | PC-12 route 的 review gate。 | TE-08 = approved。 | 由 RV-09 replacement route 取代。 | 未開始。 |
| DL-06 | Implementer | superseded | PC-12 route 的 delivery gate。 | TE-08 = approved、RV-08 = approved。 | 由 DL-07 replacement route 取代。 | 未開始。 |
| CH-05 | Implementer | superseded | PC-12 route 的 comment-resolution gate。 | DL-06 completed。 | 由 CH-06 replacement route 取代。 | 未開始；未 reply/resolve。 |
| HC-05 | Human | superseded | PC-12 route 的 human boundary。 | CH-05 completed。 | 由 HC-06 replacement human boundary 取代。 | 未開始。 |
| TE-09 | Independent Tester | superseded | PC-13 route 的 verification gate。 | IM-11 completed、IM-10 completed。 | 由 TE-10 replacement route 取代。 | 未開始。 |
| RV-09 | Independent Reviewer | superseded | PC-13 route 的 review gate。 | TE-09 = approved。 | 由 RV-10 replacement route 取代。 | 未開始。 |
| DL-07 | Implementer | superseded | PC-13 route 的 delivery gate。 | TE-09 = approved、RV-09 = approved。 | 由 DL-08 replacement route 取代。 | 未開始。 |
| CH-06 | Implementer | superseded | PC-13 route 的 comment-resolution gate。 | DL-07 completed。 | 由 CH-07 replacement route 取代。 | 未開始；未 reply/resolve。 |
| HC-06 | Human | superseded | PC-13 route 的 human boundary。 | CH-06 completed。 | 由 HC-07 replacement human boundary 取代。 | 未開始。 |
| PC-14 | Plan-Creator | completed | 將 human-authorized bounded 401 visual-pass layout/source repair 寫入四份 formal artifacts／ledger。 | human 明示不是 new exception，且只放寬 IM-12 的 401 source repair。 | 明確保留 caller/AuthRequester/Auth factory prefix、Flow 無 original request access、ineligible/eligible、refresh-result policy、success-only retry/no shortcut；package passed evidence 不重做，其他 scope/ReadOnly 不變；不寫 diagram/Git/GH。 | 2026-09-18 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-14 | Independent Plan-Reviewer | approved | 獨立審查 PC-14 bounded 401 repair、no-new-exception、flow semantics、package evidence preservation與 no-drift boundary。 | PC-14 completed。 | 確認只 IM-12 可改 401 layout/source、所有 desktop visual pass/standard delivery requirement、manual light/dark、other ReadOnly及 package evidence intact；`approved` 授權 IM-12。 | Independent Plan-Reviewer approved：bounded 401 repair 非 new exception，僅 supersede IM-10 的 401 source-ReadOnly；factory prefix、Flow original-request boundary、policy semantics、package passed evidence與其他 scope/ReadOnly/gates 一致，未發現 drift。 |
| IM-12 | Independent Implementer | superseded | PR-14 後的 401 layout/source repair。 | PR-14 = approved。 | all-sublabel-in-header constraint 只由 IM-13 participant-context presentation repair supersede；17 messages、flow/policy/component identities維持。 | historical blocked：兩次 reverted layout attempts；17 messages／28px gaps 約需 700px timeline；1080×700 overflow 1001／1073，1080×600 geometry/readability failure，1250×700 context projection 5.208px <6px。不得視為 exception 或 active path。 |
| TE-10 | Independent Tester | superseded | PC-14 route verification gate。 | IM-12 completed。 | 由 TE-11 replacement route 取代。 | 未開始。 |
| RV-10 | Independent Reviewer | superseded | PC-14 route review gate。 | TE-10 = approved。 | 由 RV-11 replacement route 取代。 | 未開始。 |
| DL-08 | Implementer | superseded | PC-14 route delivery gate。 | TE-10 = approved、RV-10 = approved。 | 由 DL-09 replacement route 取代。 | 未開始。 |
| CH-07 | Implementer | superseded | PC-14 route comment-resolution gate。 | DL-08 completed。 | 由 CH-08 replacement route 取代。 | 未開始；未 reply/resolve。 |
| HC-07 | Human | superseded | PC-14 route human boundary。 | CH-07 completed。 | 由 HC-08 replacement human boundary 取代。 | 未開始。 |
| PC-15 | Plan-Creator | completed | 將 human-authorized participant-context presentation change 寫入四份 formal artifacts／ledger。 | human 明示 participant sublabel expression 移至 external context/explanation area。 | 只 supersede IM-12 all-sublabel-in-header constraint；17 messages、caller/factory/no-payload contract、retry policy、component identities、package evidence維持；moved copy 保留 explanatory meaning且不 invent ownership；不寫 diagram/Git/GH。 | 2026-09-21 amendment；Plan-Creator 不產生 approval verdict。 |
| PR-15 | Independent Plan-Reviewer | approved | 獨立審查 PC-15 participant-context scope、no-exception、17-message/contract/policy/identity preservation與 no-drift boundary。 | PC-15 completed。 | 確認 external context copy完整保留 moved sublabel meaning、不 invent ownership，並保留 standard delivery/full visual-pass gate與 package evidence；`approved` 才授權 IM-13。 | Independent Plan-Reviewer verdict：`approved`。 |
| IM-13 | Independent Implementer | completed | PR-15 approved 後，只移動 `401-refresh-retry` participant sublabel expression 至 external context/explanation area。 | PR-15 = approved。 | 保留 17 messages、caller→AuthRequester→Auth→AuthRequester prefix、request-less exchange、Flow 無 original request access、ineligible/eligible、refresh result→policy、success-only retry/waiting→response-policy/no shortcut與 component identities。每個 moved copy保留意義、不 invent ownership。standard 9/9、0 errors/warnings、source-matched deliver、1440／1600／1920／2048 visual pass、manual light/dark。 | 2026-09-21：移除六個 participant header sublabel，改以三個 guided views 的圖外脈絡（原始請求／流程／I/O 邊界）逐項保留原意；只調整 viewBox 為 1250×700 的 presentation。17 則 message 未改。Archify deliver：spec `7d9b632bbf015a3c21dae4df372fb7ea3929df33093a815937cd96db4f0fc9a6` → HTML `21847c0d4cd80620f7debb9568dc43c8aad5d9b4c4c5fc0d0122fc5b3cb65362`；showcase 9/9、0 errors、0 warnings。visual-check 四 viewport 全 pass（1440×900、1600×1000、1920×1080、2048×1320），已檢視 1440／2048 的 light/dark 截圖；無新 exception，未改 package/state/Swift/OAuth/Git/GH。 |
| TE-11 | Independent Tester | approved | 獨立驗證 IM-13 participant-context repair、existing package evidence、17-message/contract/policy/identity preservation、full visual pass與 no-drift boundary。 | IM-13 completed；IM-14 completed 後須重新執行。 | 只 verify；不得 generate、build、deliver 或更新 output/evidence。僅在 fresh 401 delivery receipt 與既有 source／output semantics 一致時可 `approved` 並進入 RV-11。 | 2026-09-21 re-test：401 current JSON／HTML 與 IM-14 delivery receipt 的 spec `7d9b632bbf015a3c21dae4df372fb7ea3929df33093a815937cd96db4f0fc9a6`（5101 bytes）及 HTML `21847c0d4cd80620f7debb9568dc43c8aad5d9b4c4c5fc0d0122fc5b3cb65362`（709694 bytes）完全一致；showcase 9/9、0 errors／warnings，1440／1600／1920／2048 visual-check 全 pass，且已檢視最小／最大 light/dark evidence。六 participant header sublabel 均已移至三個 guided-view 圖外脈絡，17 messages、caller → AuthRequester → Auth → AuthRequester factory prefix、無請求資料 exchange、Flow 無 original request access、ineligible／eligible、refresh result→policy、success-only retry 與 no shortcut 均保持。state 重新 validate 9/9、0 errors／warnings，current source／HTML hash 仍與 IM-11 delivered evidence 一致；唯一 accepted desktop containment non-pass 如實為 1440×900=1035、1600×1000／1920×1080=1109、2048×1320 pass，絕未宣稱通過。package canvas validate 為 5 bands／15 boxes／22 edges、0 errors／warnings，fixed 繁中 kickoff/subtitle 與 HTML 一致且 accessibility verify pass；lifecycle／normal 亦 validate 9/9、visual receipts pass。`git diff --check` pass；changed-path allowlist 無 Swift、manifest 或 OAuth dual-client lifecycle，dev worktree clean。 |
| IM-14 | Independent Implementer | completed | 只重新產生 current `401-refresh-retry` 的 delivery receipt。 | TE-11 = needs-rework。 | receipt 重新產生並可對應 current source；不得修改 401 source、HTML/output semantics、17 messages、flow/policy/component identities、package/state/Swift/OAuth 或 Git/GH。完成後僅交回 TE-11 re-test。 | 2026-09-21：source pre/post SHA-256 均為 `7d9b632bbf015a3c21dae4df372fb7ea3929df33093a815937cd96db4f0fc9a6`；standard deliver spec 同 hash、HTML `21847c0d4cd80620f7debb9568dc43c8aad5d9b4c4c5fc0d0122fc5b3cb65362`，showcase 9/9、0 errors、0 warnings。fresh visual-check 四 viewport pass（1440×900、1600×1000、1920×1080、2048×1320），已檢視 1440／2048 light/dark；未改 source、messages/context、package/state/Swift/OAuth/Git/GH。 |
| RV-11 | Independent Reviewer | needs-rework | 獨立審查 TE-11 evidence、scope、contract、workflow/PR-status drift 與 current-comment findings。 | TE-11 = approved。 | findings 若未改變 locked contract，直接交由 bounded Implementer 回修；不得新增 substantive planning cycle。 | 兩項必要回修：component-dependency canvas wording／edge 不得將 selected／decorated request preparation 指派為 `AuthRequester` ownership；ledger current gate 不得仍宣告 `RV-11 pending`。其餘 final evidence 未發現 drift。 |
| IM-15 | Independent Implementer | completed | 只回修同一個 component-dependency canvas deferred-owner wording／edge finding，並維持 step ledger current gate truth。 | RV-11 = needs-rework、TE-12 initial = needs-rework。 | 完成後只授權 independent TE-12 re-test；不得將 prior rebuild evidence 誤述為 TE-12 approved 或 current delivery authorization。 | 2026-09-21 rework：移除 `request-instance` 與其兩條請求準備／傳遞邊；`AuthRequester` 只保有 caller original request 並解讀語意決策，selected／decorated request 的準備者與 representation 明示 deferred。僅保留 `AuthRequester → Requester` 的「泛用 I/O 委派；非請求準備」dependency，不指派 request preparation ownership。architecture-canvas validate = 5 bands／9 boxes／11 edges／0 errors／0 warnings；standard build 後，第二次獨立 temporary build 與交付 `index.html` byte-identical（SHA-256 `57ff00d7b69daac985100beaa2a4c7b6a69011d92c14773ea985c55f48ca4c33`）。generated template 含 document title、互動控制的 `aria-label` 與 keyboard handler；未聲稱獨立 accessibility verifier verdict。只更新 canvas source／HTML 與此 actual ledger evidence；未改 architecture contract、401/state、Swift、OAuth、Git 或 GH。TE-12 re-test 後由 RV-12 進行 final review。 |
| TE-12 | Independent Tester | approved | 獨立驗證 IM-15 rework 的 component-dependency canvas source/output、reproducibility、accessibility、deferred ownership 與 ledger current gate。 | IM-15 rework completed。 | `approved` 授權 RV-12；`needs-rework` 只可回交相同 bounded canvas finding，不建立新的 planning cycle。 | 2026-09-21 re-test：component-dependency canvas standard validate 為 5 bands／9 boxes／11 edges／0 errors／0 warnings；在暫存路徑獨立 standard build 後與交付 `index.html` byte-identical（SHA-256 `57ff00d7b69daac985100beaa2a4c7b6a69011d92c14773ea985c55f48ca4c33`）。source／output 無 `request-instance`、無 `AuthRequester → HTTPRequest` ownership edge；僅保留標示「泛用 I/O 委派；非請求準備」的 `AuthRequester → Requester` dependency，selected／decorated request 的 preparation owner／representation 均明示 deferred。generated viewer baseline 具 title、互動 control `aria-label` 與 keyboard handler。HTTP client package canvas 同樣 validate 5 bands／15 boxes／22 edges／0 errors／0 warnings，temporary build → enhance → accessibility verify 與交付 HTML byte-identical（SHA-256 `5e6fdd1226c84728fae4307d67d30780e67557980752cc111af5fdc9e2fdc5e3`）。401 delivery receipt 的 source／HTML hash 維持 `7d9b…c9a6`／`2184…5362`，state source／HTML hash 維持 IM-11 的 `9ee9…10fe`／`3267…6b5d`；兩者 showcase validate 均 9/9、0 errors／0 warnings。state desktop containment exception 仍如實為 1035／1109／1109，2048 pass。`git diff --check`、allowlist 與 dev clean 均通過；未 commit、push、reply 或 resolve thread。 |
| RV-12 | Independent Reviewer | approved | 獨立確認 RV-11 的兩項 finding 已消除，並審查 scope、contract、workflow/PR-status 與 final evidence drift。 | TE-12 = approved。 | `approved` 才授權 DL-10；`needs-rework` 回交對應產出角色。 | Independent Reviewer 確認 component-dependency 不再將 selected／decorated request preparation 指派給 `AuthRequester`，formal artifacts 與 step ledger 的 current state 一致；401、state、兩份 canvas、receipt、scope 與 dev clean 均未漂移。 |
| DL-09 | Implementer | superseded | 原 RV-11 後的 delivery gate。 | TE-11 = approved、RV-11 = approved。 | 由 DL-10 replacement delivery gate 取代；不得執行 Git/PR action。 | 未開始。 |
| DL-10 | Implementer | completed | 在 TE-12/RV-12 approved 後，依 topic delivery contract commit/push corrected delivery 至既有 OPEN、ready-for-review PR #37。 | TE-12 = approved、RV-12 = approved，且 commit message 已獲 human confirmation。 | corrected delivery visible；不得開新 PR、改變 PR status、merge 或 release。 | 2026-09-21：`196080b` 已 push 至既有 feature branch；PR #37 維持 OPEN、ready for review。 |
| CH-08 | Implementer | superseded | 原 RV-11 後的 comment-resolution gate。 | DL-09 completed。 | 由 CH-09 replacement comment-resolution gate 取代；不得 reply/resolve。 | 未開始。 |
| CH-09 | Implementer | blocked | 在 DL-10 visible 後重新取得 PR #37 thread state，處理 current-comment threads。 | DL-10 completed。 | 由 IM-17 canonical-containment remediation、independent verification/review 與 DL-12 visible delivery 解除；在此之前不得 reply/resolve P1。 | P1 `PRRT_kwDOUFu0Cc6kQlYl` 指出 `401-refresh-retry.delivery.json` 含本機絕對路徑；RV-13 另確認 lexical containment 未拒絕 canonical symlink escape；兩者皆非 source／policy finding。 |
| IM-16 | Independent Implementer | completed | 只重新產生並 sanitize current `401-refresh-retry` delivery receipt 的 path provenance。 | CH-09 = blocked，P1 已明確指出本機絕對路徑。 | `401-refresh-retry.delivery.json` 的 artifact/input/output path 均為 repository-relative；source 與 HTML hashes、17-message flow、factory prefix、retry policy、visual evidence 與所有 ReadOnly paths 不變。完成後只交回 independent TE-13。 | 2026-09-21：依 human producer-first contract，最小修正 Archify receipt producer：`--repo-root` 可用於 sequence delivery，並將受該 root 約束的 success receipt input/output 序列化為 POSIX repository-relative path；root 外路徑在 delivery 前失敗，不會回退記錄絕對路徑。從 repository root 以 relative input/output 與 `--repo-root .` 重新 `deliver`，沒有手改 JSON。新 receipt 的 input/output 為 `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/401-refresh-retry.{json,html}`；specification／artifact SHA-256 維持 `7d9b632bbf015a3c21dae4df372fb7ea3929df33093a815937cd96db4f0fc9a6`／`21847c0d4cd80620f7debb9568dc43c8aad5d9b4c4c5fc0d0122fc5b3cb65362`。獨立 validate 為 showcase 9/9、0 errors／0 warnings；既有 visual-check receipt 仍對應相同 HTML hash，四個 desktop viewport 均 pass。掃描整個 pending diff 的 receipt／HTML／planning evidence，未發現本機絕對路徑、使用者名稱、home 或 worktree 名稱；`git diff --check` 與 dev clean 通過。未改 401 source／HTML／visual evidence、其他 diagrams/canvas、Swift、OAuth、Git 或 GH。 |
| TE-13 | Independent Tester | approved | 獨立驗證 IM-16 receipt path normalization、source/output hash continuity、scope 與 absolute-path absence。 | IM-16 completed。 | `approved` 授權 RV-13；不得 generate/build/deliver 或更新 receipt/evidence。 | Independent Tester 已 `approved`；詳細 verification evidence 由獨立測試 handoff 保存，未在此 ledger 重複推論。 |
| RV-13 | Independent Reviewer | needs-rework | 獨立確認 P1 receipt-path finding 已消除，並審查 Model C／401 contract、scope、previous evidence 與 workflow drift。 | TE-13 = approved。 | 若 receipt producer 對 canonical repository-root containment、direct-outside rejection 或 in-root symlink-escape rejection 不足，交回同一 bounded producer remediation；不得改變 401 contract、architecture 或 product source。 | required finding：IM-16 僅保證 lexical `--repo-root` containment；lexical in-root symlink 可 canonical resolve 至 root 外，故 provenance boundary 未證明。DL-11 不獲授權。 |
| IM-17 | Independent Implementer | completed | 只回修既有 Archify receipt producer 的 canonical containment，新增 direct-outside／in-root symlink-escape rejection tests，並在 tests 通過後從 repository root 以 relative input／output 重新產生 current 401 receipt。 | RV-13 = needs-rework。 | 以 `realpath` canonicalize repository root、input 與 output 後才判定實體 descendant；direct-outside 與 lexical in-root 但 canonical root 外的 symlink-escape 必須於 deliver／receipt-write 前拒絕。成功 delivery 的 receipt input／output／artifact path 與 provenance metadata 只可使用 repository-relative POSIX path，且不得 postprocess generated receipt；401 source／HTML hash、17-message flow、factory prefix、retry policy、visual evidence 與全部 ReadOnly paths 不變。完成後只交回 independent TE-14。 | 2026-09-21：producer 已以 `realpath` canonicalize repository root、input、output 後執行 containment；direct-outside 與 in-root symlink-escape rejection tests 均在 artifact／receipt write 前 fail-closed 通過。從 repository root 使用 relative input／output 重跑 delivery，無 postprocess；401 receipt 的 input／output／provenance metadata 為 canonical repository-relative 表達，source／HTML hash、17-message flow、factory prefix、retry policy 與 visual evidence 未變。未改 401 source／HTML、receipt schema、diagram、architecture、product source、Swift、OAuth、Git 或 GH。 |
| TE-14 | Independent Tester | approved | 獨立驗證 IM-17 canonical containment、direct-outside／symlink-escape tests、relative-arg delivery、receipt path privacy、source／HTML／receipt hash continuity、visual evidence 與 scope no-drift。 | IM-17 completed。 | 只 verify；確認 two rejection tests 不產生 artifact／receipt，成功 401 receipt 所有 path／provenance metadata 均為 canonical repository-relative 表達、沒有 postprocess，並對 full pending diff 掃描 absolute path、使用者名稱、home 與 worktree 名稱。`approved` 才授權 RV-14；不得 generate/build/deliver 或更新 output/evidence。 | Independent Tester 已 `approved`；詳細 verification evidence 由獨立測試 handoff 保存，未在此 ledger 重複推論。 |
| RV-14 | Independent Reviewer | approved | 獨立確認 P1 的 absolute-path 與 canonical symlink-escape finding 已消除，並審查 Model C／401 contract、scope、previous evidence 與 workflow drift。 | TE-14 = approved。 | `approved` 才授權 DL-12；任何 producer containment、source/policy 或 scope drift 一律 needs-rework。 | Independent Reviewer 已 `approved`；P1 的 canonical containment 與 path privacy finding 已消除，授權 DL-12。 |
| DL-11 | Implementer | superseded | 原 TE-13／RV-13 後的 receipt-only delivery gate。 | TE-13 = approved、RV-13 = approved。 | 由 IM-17 → TE-14 → RV-14 → DL-12 canonical-containment replacement route 取代；不得執行 Git/PR action。 | RV-13 = needs-rework；未開始。 |
| DL-12 | Implementer | active | 在 TE-14/RV-14 approved 後，依 topic delivery contract commit/push canonical-containment receipt correction 至既有 OPEN、ready-for-review PR #37。 | TE-14 = approved、RV-14 = approved，且 commit message 已獲 human confirmation。 | corrected delivery visible；不得開新 PR、改變 PR status、merge 或 release。 | current delivery gate；尚未 commit 或 push。 |
| CH-10 | Implementer | superseded | 原 DL-11 後的 comment-resolution gate。 | DL-11 completed。 | 由 DL-12 → CH-11 replacement route 取代；不得 reply/resolve。 | 未開始。 |
| CH-11 | Implementer | pending | 在 DL-12 visible 後重新取得 PR #37 thread state，處理 P1 與任何新取得且已分類的 current-comment threads。 | DL-12 completed。 | 必要 threads 只在相應 corrected delivery visible 後 resolve；非必要 threads 先留言說明再 resolve；重新取得 evidence 確認沒有未分類 feedback。 | 未開始；不得 reply/resolve。 |
| HC-08 | Human | superseded | 原 RV-11 後的 human boundary。 | CH-08 completed。 | 由 HC-09 replacement human boundary 取代。 | 未開始。 |
| HC-09 | Human | superseded | 原 DL-10／CH-09 comment-resolution route 的 human boundary。 | CH-09 completed。 | 由 HC-10 replacement human boundary 取代；CH-09 已因 P1 blocked。 | 未開始。 |
| HC-10 | Human | superseded | 原 DL-11／CH-10 receipt-only replacement route 的 human boundary。 | CH-10 completed。 | 由 HC-11 replacement human boundary 取代。 | RV-13 = needs-rework；未開始。 |
| HC-11 | Human | pending | Review canonical-containment corrected OPEN、ready-for-review PR #37。 | CH-11 completed。 | human 明示下一步。 | 未開始；IM-17 producer remediation 不是 human review substitute。 |

## PR #37 Thread Mapping

| Thread | Required mapping | Resolve condition |
| --- | --- | --- |
| T01 | requirements、technical spec 與 canonical document 的 matrix：`AuthRequester`「Builds original request = 否」。 | corrected matrix delivery visible。 |
| T02 | `AuthRequester` 只保有 caller original request；selected／decorated representation deferred，沒有 decoration API 或新 runtime role。 | corrected canonical/documentation delivery visible。 |
| T03 | first 401 只有 refresh-capable 且 eligible 的 `AuthFlow` 可發 semantic refresh decision；noneligible flow 可 terminal。 | corrected lifecycle／401／state delivery visible。 |
| T04 | `http-client-package-structure/BUILD.md` 的固定 kicker／subtitle 作者 arguments 可重現 delivered 繁體中文 HTML；enhancement script/build semantics 不變。 | reproducibility fix visible。 |
| T05 | `Auth` factory 在 initial semantic send 前建立 one per-execution `AuthFlow`；其後 `AuthRequester ↔ AuthFlow` 才進行無 request-payload 的 response／semantic exchange。 | corrected lifecycle delivery visible。 |
| T06 | 對 supplied independent Tester/Reviewer evidence 的 comment closure。 | historical condition；current handling 以 CH-06 重新取得的 thread evidence 為準。 |
| T07 | refresh 經 deferred boundary 執行，refresh result 經 `AuthRequester` 傳回 flow。 | corrected 401／state delivery visible。 |
| T08 | 移除 receive→retry shortcut；retry 必須是 flow 在結果後作出的 semantic decision。 | corrected 401／state delivery visible。 |
| T09 | 只有 refresh-success permits retry；ineligible、refresh-failure 與 second-401 terminal。 | corrected 401／state delivery visible。 |
| P1 `PRRT_kwDOUFu0Cc6kQlYl` | `401-refresh-retry.delivery.json` 的 artifact/input/output path 與 provenance metadata 只可為 canonical repository-relative path，不能暴露本機絕對路徑，亦不得接受 canonical resolve 後逃逸 repository root 的 symlink。 | IM-17 canonical-containment correction 經 TE-14／RV-14 approved、DL-12 visible 後。 |

previous T01–T09 mapping 是 historical correction reference，不是 current GitHub thread
state 的宣告。CH-09 已重新取得 P1 evidence 但因 receipt path finding `blocked`；current handling 只可在
DL-12 visible 後的 CH-11 重新取得 exact thread evidence 才開始。

PR #37 的 current replacement workflow 保留 historical prefix：**PC-08 → PR-08 → PC-09 → PR-09 →
IM-07 (historical blocked) → PC-10 → PR-10 → IM-08 (historical blocked) → PC-11 → PR-11**；
其精確 current replacement route 為：**PC-15 → PR-15 → IM-13 → TE-11 (needs-rework) → IM-14 →
TE-11 re-test → RV-11 (needs-rework) → IM-15 → TE-12 (needs-rework) → IM-15 rework → TE-12 re-test →
RV-12 → DL-10 (completed) → CH-09 (blocked) → IM-16 → TE-13 → RV-13 (needs-rework) → IM-17 → TE-14 →
RV-14 (approved) → DL-12 (active) → CH-11 → HC-11**。P1 只回修 delivery receipt canonical path provenance，未改變 locked
contract，故不建立新的 planning cycle。PR #37 維持
OPEN、ready for review；任何前置 gate 未完成時不得改變 status 或提前處理 thread。IM-11 只放行
`auth-flow-state` 的 retry permission transition／event expression 與必要 topology/layout presentation，
以消除 `[850,307]` 並恢復 normal Archify 9/9、0 errors/warnings、standard deliver/source-matched receipt；
必須保留 locked semantics。IM-10 package passed evidence 維持且不重做；IM-13 只把 participant sublabel
expression 移至 external context/explanation area，不是 new exception。TE-11 只 verify、不得生成 output/evidence；
IM-14 只可更新 stale 401 delivery receipt，不能修改 source／output semantics。
401 必須 normal deliver/visual pass，含
1440／1600；package canvas gates及既有 desktop containment 1035／1109／1109、2048 pass exact non-pass
都維持不變。

## Locked Contract Checklist

- [x] 現行 `.send(HTTPRequest)` contract 為 legacy Model A，不是 adopted target。
- [x] adopted Model C：`AuthFlow` 只擁有 auth policy/state/retry decision，能理解
  `HTTPResponse`，但沒有 original request、arbitrary request construction 或 I/O
  capability。
- [x] `AuthRequester` 是 original request 唯一 owner 與 semantic action interpreter；
  `Requester` 是 generic HTTP I/O owner；`AuthRequester` 不建構 original request，
  selected／decorated representation 維持 deferred。
- [x] `AuthAction`、decoration、failure、async、refresh component/result API 均
  deferred，不可在本 topic 推定。
- [x] `TokenFetcher`／`TokenProvider` 在 matrix 為 N/A；不宣稱現有 runtime。
- [x] OAuth dual-client lifecycle documents/diagrams 永遠 ReadOnly。
- [x] PR-03 是唯一 replacement Plan Review gate；只有 PR-03 approved 滿足「Plan
  Review approved」並授權 IM-01。Swift implementation 永遠不在本
  topic 範圍。
- [x] branch 建議為 `docs/redefine-auth-subsystem-responsibilities`；不執行 branch
  action。
- [x] PR #37 comment-fix 不重開 Model C：eligible refresh、deferred refresh result、
  retry/terminal state 與 package-canvas reproducibility 均依 narrow allowlist 修正。
- [x] RV-03 rework 鎖定 `Auth` factory 先建立 per-execution `AuthFlow`、圖表說明性文案
  使用繁體中文，且 PR #37 status 維持 OPEN、ready for review。
- [x] RV-05 current preflight 只鎖定 401 factory prefix、retry-response state topology、
  package canvas deferred preparation ownership 與 ledger workflow truth；Model C、OAuth
  ReadOnly、original request ownership 與 deferred API 未被重開。
- [x] human 只接受 `auth-flow-state.json` `[850,307]` crossing 作為 accepted non-pass；兩次
  focused repair、一次 independent overall-layout attempt 均未消除它且已還原。它與 desktop
  containment non-pass 分離，且不構成 showcase pass、zero-error validation 或 delivery approval。
- [x] human 已明示 state-only topology/layout delivery-recovery redesign：只有 `auth-flow-state` 可由
  IM-11 將 retry permission 表達為進入 waiting state 的 transition／event並調整相連 presentation，以消除 `[850,307]`；state 必須回復 standard
  9/9／0 errors/warnings／deliver/source-match，且不豁免任何其他 gate或 locked semantics。
- [x] PC-12 分離 source changes 與 output materialization；PC-13 將 IM-09 prior node formulation
  supersede 為 IM-11 expression-only；IM-10 package materialization 已通過，401 source-ReadOnly visual
  failure為 historical blocked evidence。PC-14 僅允許 IM-12 修正 401 layout/source、不是 new exception；
  TE-10 僅驗證且絕不生成 output/evidence。

## TestCase

- **TC-01**：PC-01 only-created paths 為四份 artifacts；沒有 long-lived docs、diagram、
  Swift、test 或 manifest 寫入。
- **TC-02**：四份 artifacts 與 plan.md 的 Swift Implementation Handoff 對 Goal、
  Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Modify、Deleted、TestCase 及
  Model C decision 一致。
- **TC-03**：matrix 明確賦予 flow policy/state/retry ownership、AuthRequester original
  request ownership（不建構 original request）、Requester I/O ownership，且 Token roles 為 N/A。
- **TC-04**：只有 PR-03 approved 滿足「Plan Review approved」並可寫入 Phase 2
  docs/diagrams；PR-01／PR-02 的 `needs-rework` 不授權 Swift runtime。
- **TC-05**：TE-02 是 TE-01 的唯一 independent replacement verification gate；它在
  architecture-canvas／Archify skill gates 後驗證 diagram evidence，且 401 圖不虛構
  credential runtime。state diagram accepted containment limitation 維持 non-pass。
- **TC-06**：TE-02 approval 維持 historical replacement verification truth；RV-01 的
  two findings 經 PR-04 approved、IM-02 localization correction 與 TE-03 approved 後，
  RV-02 才可依 verification evidence 重新判定 verdict。
- **TC-07**：PC-07／PC-08 的 historical route 不取代 current PC-15 → PR-15 → IM-13 →
  TE-11 needs-rework → IM-14 → TE-11 re-test → RV-11 needs-rework → IM-15 → TE-12 needs-rework →
  IM-15 rework → TE-12 re-test → RV-12 → DL-10 completed → CH-09 blocked → IM-16 → TE-13 →
  RV-13 needs-rework → IM-17 → TE-14 → RV-14 → DL-12 → CH-11 → HC-11；RV-11／TE-12 只可回修既有 canvas
  deferred-owner wording／edge 與 stale ledger gate，不得建立新的 planning cycle。PC-10／PR-10／IM-08 blocked、IM-09 blocked、IM-10
  401 visual blocked與 IM-12 renderer blocked均如實保留為 historical evidence。未經 TE-12/RV-12 與 follow-up delivery 不得 reply/resolve
  current PR #37 threads 或改變 PR status。
- **TC-08**：T01–T09 mapping 全部具名記錄；T06 僅在 supplied evidence、independent
  Tester/Reviewer 與 commit/push 後 reply+resolve，T04 僅在 reproducibility fix visible。
- **TC-09**：lifecycle／401 sequence 由 `Auth` factory 在 semantic send 前建立 flow，
  無 `AuthRequester` 向預先存在 `AuthFlow` 取得 instance 的表述；lifecycle／401／state
  說明性文案為繁體中文，state exception 維持 non-pass。
- **TC-10**：401 圖先表達 caller original-execution entry、`AuthRequester → Auth` flow request、
  `Auth → AuthRequester` flow return，再開始無 request payload 的 semantic exchange；flow
  不取得 original request。
- **TC-11**：state 圖的 retry permission 必是進入 waiting-for-retry-response 的 transition／event，
  非 lifecycle node；waiting state 將 retry response 交給 response policy 才分支 normal-success／
  second-401 terminal；package canvas 不指派 selected／decorated
  preparation 給 `AuthRequester`，exact owner／representation 維持 deferred。
- **TC-12**：ledger 如實記錄 delivered head RV-04 approved／DL-03 active、IM-08 alternate path
  blocked、IM-09 prior-node blocked、IM-10 401 visual blocked與 package passed evidence、current preflight needs-rework；CH-07
  重新取得 thread evidence 後，必要項依修正 resolve，非必要項留言後 resolve。
- **TC-13**：IM-11 只可將 retry permission 表達為進入 waiting state 的 transition／event並調整相連
  state presentation，但保留 first-401 ineligible terminal、eligible refresh、result 回 Flow policy、
  refresh-success-only exactly-one retry、waiting-for-retry-response → response-policy normal-success／second-401 terminal，且無
  receive→retry shortcut。
- **TC-14**：`[850,307]` 必須消除；state standard validate 9/9、0 errors/warnings、successful
  deliver/source-matched receipt與 visual evidence/manual light-dark inspection 必須齊備。
- **TC-15**：desktop containment 1035／1109／1109、2048 pass 維持 exact distinct non-pass、不能稱
  visual pass，且不放寬其他 diagram/canvas、diff、scope、source-output matching、delivery 或 thread gate。
- **TC-16**：401 維持 standard 9/9、normal deliver／visual pass；package canvas 維持
  validate/build/reproducibility/accessibility；所有其他 failure 不得以 state redesign scope豁免。
- **TC-17**：IM-10 的 package materialization passed evidence不重做；IM-13 是唯一可把 participant sublabel
  expression 移至 external context/explanation area 的 step，不是 exception，並保留 17 messages、401 flow
  semantics、component identities與其他 ReadOnly boundary；BUILD.md/enhancement
  script ReadOnly。
- **TC-18**：IM-13 401 standard validate/deliver 必須 9/9、0 errors/warnings、source-match，1440×900、
  1600×1000、1920×1080、2048×1320 全數 visual pass並 manual light/dark。TE-11 只 verify、不
  generate/build/deliver/更新 output 或 evidence；若 receipt stale，僅 IM-14 可重新產生 receipt，且不得改變
  source／output semantics。
- **TC-19**：IM-16／TE-13 的 lexical repository-relative path normalization 是 historical evidence，不能視為
  canonical containment pass。P1 `PRRT_kwDOUFu0Cc6kQlYl` 只允許 IM-17 對既有 receipt producer canonicalize
  repository root、input 與 output，並在 deliver／receipt-write 前拒絕 direct-outside path 與 lexical in-root、
  canonical root 外的 symlink-escape。兩個拒絕 tests 均不得產生 receipt；成功路徑才可重建
  `401-refresh-retry.delivery.json` 的 repository-relative artifact/input/output/provenance metadata，且不得
  postprocess generated receipt。source／HTML
  hashes、17-message flow、factory prefix、retry policy、visual evidence、其他 diagrams/canvas、architecture、
  product source、Swift 與 OAuth 不得漂移。TE-14 只驗證 containment、path absence、source／HTML／receipt hash
  continuity、visual evidence 與 full pending-diff scan；
  RV-14 approved、DL-12 visible 後才可由 CH-11 reply/resolve。

## Blockers

IM-07／IM-08 的 state-delivery failures 均為 historical truth：standard `deliver` 的 all-checks
requirement 不變；alternate-materialization 的 public validate／deliver／render 在 `[850,307]`
proper-crossing 失敗，preview 無 source-matched output。它們由 human-authorized state topology/layout
redesign supersede，不能被重述為 delivery pass 或設計完成。

RV-11 已確認 401 receipt 的 historical stale finding 已由 IM-14／TE-11 re-test 消除。TE-12 initial
`needs-rework` 已交回 IM-15 的同一 bounded canvas finding；IM-15 rework 與 independent TE-12 re-test
均已完成並 approved。它只消除「`AuthRequester` 被表達為 selected／decorated request preparation owner」與
stale current-gate 兩項落差；component-dependency canvas 的 standard validate → build → temporary rebuild
reproducibility、generic I/O non-preparation dependency 與 deferred preparation boundary 均已獨立驗證。
RV-12 已 approved，DL-10 已完成；CH-09 已因 P1 `PRRT_kwDOUFu0Cc6kQlYl` 指出的 401 delivery receipt
本機絕對路徑而 `blocked`。IM-16 只可重新產生並 sanitize receipt path 為 repository-relative，不能修改
source／HTML／visual evidence 或任何 401 policy/contract。IM-16 已完成且 TE-13 已
`approved`；但 RV-13 = `needs-rework`：lexical repository-relative serialization 尚未拒絕 lexical in-root、
canonical resolve 後 root 外的 symlink-escape。IM-17 已完成既有 receipt producer 的 canonical containment，並以
direct-outside 與 in-root symlink-escape tests 證明 delivery／receipt-write 前拒絕，再以 repository-relative input／output
重新產生同一 receipt；current gate 為 DL-12 → CH-11 → HC-11。DL-12 visible 前不得 reply 或 resolve P1。不得新增 exception、
重做 package 以外 artifact、手改 HTML、
擴張 state/Swift/OAuth/other diagrams/runtime architecture scope 或重開 deferred ownership。既有 state desktop
containment exact accepted non-pass 與所有其他 gates 維持不變。

## Human Check

HC-11 是 current PR #37 canonical-containment replacement workflow 完成後的強制 human boundary。
CH-11 完成前不得 resolve current P1 thread；PR #37 必須維持 OPEN、ready for review。其後只有
human 可授權後續工作。IM-17 producer remediation 不是 HC-11 的替代，也不授權 merge、release
或 future Swift implementation。

## Last Updated

2026-09-18 — PR-01／PR-02／TE-01／RV-01／RV-03 與 current PR #37 comment preflight =
`needs-rework`；PC-02／PC-03／PC-04／PC-05／PC-06／PC-07／PC-08、IM-01／IM-02／IM-04／
IM-05／IM-06、DL-01 completed；PR-03／PR-04／PR-05／PR-06／PR-07、TE-02／TE-03／TE-04／
TE-05、RV-02／RV-04 = `approved`。delivered head 歷史為 RV-04 approved、DL-03 active；
不宣稱 commit/push、thread resolution 或 HC-02 已完成。PC-08 為四個 bounded new-comment
findings 建立 replacement route；PR-08／PR-09 = approved。human 接受
`auth-flow-state.json` 的 `[850,307]` crossing 作為 narrowly scoped accepted non-pass，但這不
改變 standard `deliver` 的 all-checks requirement。兩次 focused repair 與一次 independent
overall-layout attempt 均未消除 diagnostic，且所有未證實 attempts 已還原；IM-07 standard-delivery
blocker 保留為 historical truth。human 後續明確授權只限 state artifact 的 alternate delivery
contract；PC-10 已完成，PR-10 re-review = approved。IM-08 以 Archify public validate／deliver／
render 檢查同一 accepted `[850,307]` proper-crossing，皆失敗；preview 沒有 source-matched output，
故不構成 delivery alternative。current source SHA-256 為
`533dd212c4650adc07499cec415155e06e051619da6a9fcf379e0fb897f412bd`，existing HTML SHA-256 為
`552856a72c8b8d3abd1daf72552f225fa946fe611d3f0f507d487e4fe7cf12ad`，兩者 mismatch；沒有 output/
evidence 寫入。IM-08 blocked 現為 historical alternate-materialization failure。human 已明確授權
只限 state topology/layout presentation 的 delivery-recovery redesign；PC-11 completed、PR-11 = approved。
IM-09 recovery valid semantic candidate baseline `[850,307]`（waiting-retry-response vs second-401-terminal）
後，R1 `[900,479]`、R2 `[402,252]` 均仍有 1 crossing，已達兩輪連續無改善 stop condition；所有 unproven
changes 已還原，且未更新 HTML、receipt、state/visual evidence。IM-09 historical blocked；既有 desktop
containment limitation維持 distinct exact accepted non-pass。human 已選擇 PC-13 state-expression revision：
retry permission 是進入 waiting-for-retry-response 的 transition／event，非 node，並非 policy change。
PC-13 completed、PR-13 approved、IM-11 completed：state standard validate/deliver 為 9/9、0 errors、
0 warnings、source-matched，desktop containment 1035／1109／1109、2048 pass 維持 distinct non-pass。
IM-10 的 package materialization 已全數通過；401 source ReadOnly standard deliver 同為 9/9、0 errors、
0 warnings、source-matched，但 fresh visual-check 1440×900 scrollHeight 1001、1600×1000 1073，僅
1920×1080／2048×1320 pass，且不屬於 state exception，因此 IM-10 historical blocked。human 現已授權
bounded 401 layout/source adjustment，明示不是 new exception；PC-14 completed、PR-14 approved。IM-12 經兩次
reverted layout attempts 與 bounded renderer diagnosis後 blocked：17 messages／28px gaps 約需 700px timeline，
1080×700 仍 overflow 1001／1073，1080×600 geometry/readability 不合格，1250×700 context projection 5.208px <6px。
normal pass 需 human 授權 modify/move sublabel、reduce/merge messages或 split sequence，否則新 exception。
package passed evidence 維持且不重做；TE-10 onward unadvanced。PR #37 維持 OPEN、ready for review；CH-07
前必須重新取得 thread evidence。Plan-Creator 自身不產生
standard verdict（`null`）。

2026-09-21 — IM-13 將 401 sequence 的 six participant sublabel 改為三個 guided-view 圖外脈絡，
並以 1250×700 presentation 恢復四個 desktop viewport containment。Archify showcase validate／deliver
為 9/9、0 errors、0 warnings、source-matched；visual-check 四個 viewport 全 pass，且已檢視
1440／2048 light/dark 截圖。下一關為 TE-11 independent verification；未進行 commit、push、PR 或 thread action。

2026-09-21 — TE-11 = `needs-rework`：current 401 delivery receipt stale。此 finding 不改變
401 source／output semantics、17-message flow contract、retry policy、component identities或既有 visual-pass
evidence。IM-14 pending，僅重新產生 401 delivery receipt；完成後必須由獨立 Tester 重跑 TE-11，
在此之前不得 commit、push、PR 或 thread action。

2026-09-21 — IM-14 completed，TE-11 re-test = `approved`：fresh 401 delivery receipt 已與 current
JSON／HTML source-match，既有 17-message flow contract、retry policy、component identities與 visual-pass
evidence 未漂移。RV-11 = `needs-rework`，但只有兩項既有契約內的落差：component-dependency canvas wording／edge
不得把 selected／decorated request preparation 指派為 `AuthRequester` ownership，及 ledger current gate
不得仍寫成 RV-11 pending。依 human direction，不建立新的 planning cycle；initial IM-15 = active，後續 route 為
TE-12 → RV-12 → DL-10 → CH-09 → HC-09。PR #37 維持 OPEN、ready for review；未 commit、push、reply
或 resolve thread。

2026-09-21 — TE-12 initial = `needs-rework` 只回交同一個 component-dependency canvas deferred-owner
wording／edge finding，不改變 Model C、deferred ownership、401/state、Swift、OAuth 或 PR status，也不建立新的
planning cycle。IM-15 rework 已移除 `request-instance` 及其請求準備路徑，改為明示 deferred ownership 與
「泛用 I/O 委派；非請求準備」dependency；architecture-canvas validate 為 5 bands／9 boxes／11 edges／0 errors／0
warnings，兩次 build 的 generated HTML byte-identical（SHA-256
`57ff00d7b69daac985100beaa2a4c7b6a69011d92c14773ea985c55f48ca4c33`）。當時待 independent TE-12 re-test；
在 TE-12/RV-12 approved 前不得 commit、push、reply 或 resolve thread。

2026-09-21 — TE-12 re-test = `approved`：component-dependency canvas 與 HTTP client package canvas
分別通過 architecture-canvas validate、獨立 temporary rebuild reproducibility；package 的 enhance／accessibility
verify 亦通過。兩份 canvas 均不指派 `AuthRequester` selected／decorated request preparation ownership，僅以
「泛用 I/O 委派；非請求準備」表達其對 Requester 的 dependency，exact preparation owner／representation 保持
deferred。401／state source-output evidence 未漂移；state 既有 desktop containment limitation 維持 non-pass。
`git diff --check`、allowlist 與 dev clean 均通過。下一關為 RV-12；未 commit、push、reply 或 resolve thread。

2026-09-21 — RV-12 = `approved`：Independent Reviewer 確認 RV-11 的兩項 finding 均已消除：
component-dependency 不再把 selected／decorated request preparation 指派給 `AuthRequester`，且 formal
artifacts／step ledger 的 current state 一致。401、state、兩份 canvas、receipt、scope 與 dev clean 未漂移。
current gate 為 DL-10；尚未 commit、push、reply 或 resolve thread。

2026-09-21 — DL-10 completed 後，CH-09 重新取得 P1 `PRRT_kwDOUFu0Cc6kQlYl`：
`401-refresh-retry.delivery.json` 仍含本機絕對路徑。這是 receipt provenance／privacy finding，不改變
401 source、HTML、17-message flow、factory prefix、retry policy、visual evidence 或任何 locked contract。
依最小閉環，CH-09 = `blocked`、IM-16 = `active`；IM-16 只可重建並 sanitize receipt path 為
repository-relative，後續為 TE-13 → RV-13 → DL-11 → CH-10 → HC-10。不建立新的 planning cycle，
也不得在 corrected delivery visible 前 reply 或 resolve P1。

2026-09-21 — TE-13 = `approved`：Independent Tester 已完成 IM-16 receipt path normalization、source/output
hash continuity、scope 與 absolute-path absence 的獨立驗證；current gate 為 RV-13。此 state sync 不修改
receipt、diagram、contract 或其他 formal artifact。

2026-09-21 — RV-13 = `needs-rework`：review 發現 IM-16 的 `--repo-root` containment 為 lexical，未能證明
lexical 在 repository 內但 canonical resolve 後逃逸 root 的 symlink input／output 會被拒絕；因此不能把
repository-relative receipt serialization 視為完整 provenance boundary。這是同一 P1 的 producer-only
canonical-containment finding，不改變 receipt schema、401 source／HTML、17-message flow、factory prefix、retry
policy、visual evidence、architecture 或 product source。IM-17 = `completed`：以 `realpath` canonicalize repository
root／input／output，拒絕 direct-outside 與 in-root symlink-escape，並以兩個 rejection tests 證明在 delivery／receipt-write
前失敗；success path 已從 repository root 以 relative path 重新產生同一 401 receipt，沒有 postprocess。
TE-14 已驗證 source／HTML／receipt hash、visual evidence 與 full pending-diff path scan；RV-14 已 approved。後續固定為
DL-12 → CH-11 → HC-11；不建立新的 planning cycle，也不得在 DL-12 visible 前 reply 或
resolve P1。

2026-09-21 — IM-17 = `completed`：canonical receipt producer 已先以 `realpath` 解析 repository root、input 與
output，再判定實體 descendant containment。direct-outside 與 in-root symlink-escape rejection tests 均確認在
delivery／receipt-write 前 fail-closed，且不產生 artifact 或 receipt。success path 由 repository root 的 relative
input／output 重新 `deliver` 同一份 401 receipt，沒有 postprocess；receipt 的 input／output／artifact path 與
provenance metadata 均為 canonical repository-relative 表達。401 source／HTML hash、17-message flow、factory prefix、
retry policy 與 visual evidence 未漂移。current gate 為 TE-14 independent verification（ledger status = `pending`）；
TE-14 未 `approved` 前不得 commit、push、reply 或 resolve P1。

2026-09-21 — TE-14 = `approved`：Independent Tester 已完成 IM-17 canonical containment、direct-outside／
symlink-escape rejection、repository-relative delivery、receipt path privacy、hash continuity、visual evidence 與
scope no-drift 的獨立驗證。此 state sync 不修改 producer、receipt、diagram、contract 或其他 formal artifact；current
gate 為 DL-12。
