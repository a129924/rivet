# Auth 子系統責任重定義：Step Ledger

## Current Phase

`comment-fix-delivery-active`。RV-04 independent re-review 已明示 `approved`，TE-05 re-test
與 RV-04 outcome 已共同滿足 DL-03 entry condition，DL-03 現為 active。既有 factory sequence、
繁體中文作者文案、allowlist、PR #37 status 與全部 passing review/validation evidence 維持；
唯一 visual exception 仍是 state desktop containment 1035／1109／1109、2048 pass 的 exact
human accepted non-pass。PR #37 是既有 **OPEN、ready for review** PR；不得改變其 status。
既有 PR-03／PR-04／PR-05／PR-06／PR-07、TE-02／TE-03／TE-04 的 approved 與 TE-01 historical
`needs-rework` 都保留為歷史事實，但不授權略過此次 replacement workflow。T01–T09 全部仍
unresolved，T06 reply-and-resolve 仍 pending；尚未完成 DL-03、CH-02 或任何 thread
reply/resolve。AuthFlow state diagram 的 desktop vertical containment limitation 仍是 exact
human accepted non-pass exception；不得誤記為 visual-check pass。現行 Model A runtime 仍保持
legacy；adopted Model C 是尚未實作的 architecture target。

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
| DL-03 | Implementer | active | 在 TE-05/RV-04 approved 後，依 topic delivery contract commit/push corrected delivery 至既有 OPEN、ready-for-review PR #37。 | TE-05 = approved、RV-04 = approved，且 commit message 已獲 human confirmation。 | corrected delivery 已 commit/push 至 PR #37；不得開新 PR、改變 PR status、merge 或 release。 | Entry gate satisfied；尚未記錄 commit/push 或 thread action completion。 |
| CH-02 | Implementer | pending | 依 PR #37 supplied evidence 回覆並 resolve nine threads。 | DL-03 completed。 | T06 在 independent Tester/Reviewer + commit/push 後 reply+resolve；T01/T02/T03/T05/T07/T08/T09 僅在對應 corrected delivery visible 時 resolve；T04 僅在 reproducibility fix visible 時 resolve。 | 未開始；現在不得 reply 或 resolve。 |
| HC-02 | Human | pending | Review corrected OPEN、ready-for-review PR #37。 | CH-02 completed。 | human 明示下一步。 | 強制 human boundary；不得自動 merge、release 或開始 Swift implementation。 |

## PR #37 Thread Mapping

| Thread | Required mapping | Resolve condition |
| --- | --- | --- |
| T01 | requirements、technical spec 與 canonical document 的 matrix：`AuthRequester`「Builds original request = 否」。 | corrected matrix delivery visible。 |
| T02 | `AuthRequester` 只保有 caller original request；selected／decorated representation deferred，沒有 decoration API 或新 runtime role。 | corrected canonical/documentation delivery visible。 |
| T03 | first 401 只有 refresh-capable 且 eligible 的 `AuthFlow` 可發 semantic refresh decision；noneligible flow 可 terminal。 | corrected lifecycle／401／state delivery visible。 |
| T04 | `http-client-package-structure/BUILD.md` 的固定 kicker／subtitle 作者 arguments 可重現 delivered 繁體中文 HTML；enhancement script/build semantics 不變。 | reproducibility fix visible。 |
| T05 | `Auth` factory 在 initial semantic send 前建立 one per-execution `AuthFlow`；其後 `AuthRequester ↔ AuthFlow` 才進行無 request-payload 的 response／semantic exchange。 | corrected lifecycle delivery visible。 |
| T06 | 對 supplied independent Tester/Reviewer evidence 的 comment closure。 | TE-05/RV-04 approved 且 DL-03 completed 後 reply+resolve。 |
| T07 | refresh 經 deferred boundary 執行，refresh result 經 `AuthRequester` 傳回 flow。 | corrected 401／state delivery visible。 |
| T08 | 移除 receive→retry shortcut；retry 必須是 flow 在結果後作出的 semantic decision。 | corrected 401／state delivery visible。 |
| T09 | 只有 refresh-success permits retry；ineligible、refresh-failure 與 second-401 terminal。 | corrected 401／state delivery visible。 |

PR #37 的 replacement workflow 固定為：**Plan Review amendment → Implementer → Tester →
Reviewer → topic commit/push → reply/resolve → human review**。對應 IDs 為
PC-07/PR-07 → IM-04 → TE-05 → RV-04 → DL-03 → CH-02 → HC-02；PR #37 維持 OPEN、ready for
review，任何前置 gate 未完成時不得改變 status 或提前處理 thread。

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
- **TC-07**：PC-07 後必經 PR-07 → IM-04 → TE-05 → RV-04 → DL-03 → CH-02 → HC-02；
  未經 TE-05/RV-04 與 follow-up delivery 不得 reply/resolve PR #37 threads 或改變 PR status。
- **TC-08**：T01–T09 mapping 全部具名記錄；T06 僅在 supplied evidence、independent
  Tester/Reviewer 與 commit/push 後 reply+resolve，T04 僅在 reproducibility fix visible。
- **TC-09**：lifecycle／401 sequence 由 `Auth` factory 在 semantic send 前建立 flow，
  無 `AuthRequester` 向預先存在 `AuthFlow` 取得 instance 的表述；lifecycle／401／state
  說明性文案為繁體中文，state exception 維持 non-pass。

## Blockers

PR-07／IM-04 與 IM-06 後的 TE-05 re-test 已完成；下一關必須是獨立 RV-04 re-review，歷史
PR-04／PR-05、PR-06、TE-04 與 RV-02 的 approved 均不取代 PR #37 correction 的
PR-07/IM-04/TE-05/RV-04 gates。AuthFlow state diagram 存在 human 已明確接受、且僅限該
artifact desktop vertical containment 的 visual-check limitation；它是 exact accepted non-pass
exception，不是 visual-check pass。若發現其他 diagram contract 不一致，停止並交還 human
或對應規劃角色，不得自行推定 resolution。

## Human Check

HC-02 是 PR #37 comment-fix replacement workflow 完成後的強制 human boundary。CH-02
完成前沒有 thread 可 resolve；PR #37 必須維持 OPEN、ready for review。其後只有 human
可授權後續工作。不得自行 merge、release 或開始 future Swift implementation。

## Last Updated

2026-09-18 — PR-01／PR-02／TE-01／RV-01／RV-03 與 PR #37 comment review =
`needs-rework`；PC-02／PC-03／PC-04／PC-05／PC-06／PC-07、IM-01／IM-02／IM-04／IM-05／
IM-06、DL-01 completed；PR-03／PR-04／PR-05／PR-06／PR-07、TE-02／TE-03／TE-04／TE-05、
RV-02／RV-04 = `approved`。RV-04 確認 `first-401 → ineligible-401` terminal transition、
T03/T09 topology 與既有 evidence；DL-03 active。PR #37 維持 OPEN、ready for review；
CH-02／HC-02 未開始，T01–T09 unresolved、T06 reply-and-resolve pending。AuthFlow state diagram
exact accepted containment limitation 維持 non-pass exception。Plan-Creator 自身不產生 standard
verdict（`null`）。
