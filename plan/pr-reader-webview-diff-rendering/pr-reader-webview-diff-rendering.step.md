# pr-reader-webview-diff-rendering — Step Ledger

## Topic and Current Phase

- Topic: `pr-reader-webview-diff-rendering`
- Current phase: RV-08 final recheck pending（初次 RV-08 `needs-rework` 的 stale ledger 與 verifier actual-injection marker finding 已完成 bounded rework，等待獨立 Reviewer 最終複審）
- Ledger rule: 此帳本只索引 handoff evidence 與目前狀態；checkbox、status 或 tracker 結果不構成 approval。只有指定獨立角色的明示 verdict 可通過 gate。

## Steps

| ID | Status | Owner role | Completion condition | Validation evidence |
| --- | --- | --- | --- | --- |
| PC-01 | completed | Plan-Creator | 建立四份正式 artifacts，記錄已鎖定的零依賴 interface-only scope、contract、驗收與 human boundary。 | 四份 artifacts 已建立；僅為 Plan-Creator handoff，不是 Plan-Reviewer approval。 |
| PR-01 | pending | Plan-Reviewer | 獨立檢查四份 artifacts 的一致性、PR Reader 邊界、scope、contract、test 與停止條件。 | 尚無；必須有 Plan-Reviewer 明示 verdict。 |
| IM-01 | pending | Implementer | 僅在 PR-01 明示 `approved` 後，新增已鎖定的 TypeScript declarations 與 type-level tests。 | 尚無；不得實作 parser、renderer、DOM、UI、bridge 或套件變更。 |
| TE-01 | pending | Tester | 執行既有 Bun typecheck、受影響 tests 與 coverage gate，並回報可重現結果或明確 blocker。 | 尚無；測試成功不取代 Reviewer approval。 |
| RV-01 | pending | Reviewer | 獨立審查 implementation、contract 與驗證 evidence；分類 approved、needs-rework、blocked 或 human-check。 | 尚無；必須有 Reviewer 明示 verdict。 |
| HC-01 | pending | Human | 審閱 IM-02 的 implementation、test evidence 與 Reviewer verdict。 | 已因 PR comment review-and-fix request 進入後續 revision chain；不得由 agent 或 ledger 取代。 |
| PC-02 | completed | Plan-Creator | 將同 topic artifacts 修正為 module-level declaration-only pipeline replacement plan，保留所有已鎖定 contract。 | 四份 artifacts 已更新；僅為 Plan-Creator handoff，不是 Plan-Reviewer approval。 |
| PR-02 | approved | Plan-Reviewer | 獨立檢查 PC-02 artifacts 與既定 model、viewed ownership、零依賴、public surface、layer boundary 及 gate 一致性。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-02 | completed | Implementer | 僅在 PR-02 明示 `approved` 後，將集中式 contract 換為已鎖定 module tree 與 module-level type tests。 | Implementer 已移除集中式檔案，並完成精確的模組化 declarations 與 tests；未實作 concrete behavior、DOM、UI、bridge 或套件變更。 |
| TE-02 | approved | Tester | 執行既有 Bun typecheck、受影響 tests 與 coverage gate，並回報可重現結果或明確 blocker。 | Independent Tester 明示 verdict：`approved`；`bun run typecheck`、`bun run check`、`bun test`、`bun test:coverage`、`git diff --check`。 |
| RV-02 | approved | Reviewer | 獨立審查 IM-02 implementation、contract 與驗證 evidence；分類 approved、needs-rework、blocked 或 human-check。 | Independent Reviewer 明示 verdict：`approved`；後續 PR comments 觸發 PC-03 revision chain。 |
| PC-03 | completed | Plan-Creator | 將同 topic 四份 artifacts 同步為 human 已鎖定的 `output-error`、viewed notification identity、Output ownership 與 architecture writeback 決策。 | 四份 artifacts 已更新；僅為 Plan-Creator handoff，不是 Plan-Reviewer approval。 |
| PR-03 | approved | Plan-Reviewer | 獨立檢查 PC-03 artifacts 與既定 DiffViewModel、viewed ownership、零依賴、Output failure／ownership、architecture writeback、scope 與 gate 一致性。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-03 | completed | Implementer | 僅在 PR-03 明示 `approved` 後，實作已鎖定 contract 修正、tests、PR Reader BC writeback 與經 `architecture-canvas` 驗證的責任邊界圖。 | Implementer 已完成已鎖定的 contract 修正、tests、PR Reader BC writeback 與經 `architecture-canvas` 驗證的責任邊界圖；未實作 concrete pipeline behavior、DOM、UI、bridge 或新增套件。 |
| TE-03 | approved | Tester | 執行既有 Bun typecheck、受影響 tests 與 coverage gate，並驗證 architecture-canvas artifact 的 required validation evidence。 | Independent Tester first verdict：`needs-rework`，原因為 reversed stage failure；minimal fix 後明示 verdict：`approved`。測試成功不取代 Reviewer approval。 |
| RV-03 | approved | Reviewer | 獨立審查 IM-03 implementation、contract、architecture writeback 與驗證 evidence；分類 approved、needs-rework、blocked 或 human-check。 | Independent Reviewer first verdict：`needs-rework`，原因為 non-Traditional-Chinese canvas；locale fix 後明示 verdict：`approved`。 |
| GH-03 | completed | Code-Implementer | 在 RV-03 明示 `approved` 後，依 human 已授權流程 commit、push 更新既有 PR #4，並 resolve 已修正的 PR threads。 | 已更新 PR #4 並完成當輪已修正 threads 的 handoff；後續 human review comments 啟動下一輪 revision。 |
| HC-02 | completed | Human | 審閱 PR #4 的 IM-03 修正、test／review evidence 與 resolved threads。 | Human review 產生後續 comments；不構成下一輪 implementation approval。 |
| PC-04 | completed | Plan-Creator | 將同 topic 四份 artifacts 修正為 `DiffSnapshot` envelope input 與 `ViewedStateChangeAdapter` 直接符合 Port 的既定 contract。 | 四份 artifacts 已更新；僅為 Plan-Creator handoff，不是 Plan-Reviewer approval。 |
| PR-04 | approved | Plan-Reviewer | 獨立檢查 PC-04 artifacts 是否保留既定 `DiffViewModel`、viewed ownership、零依賴、Output ownership，並正確鎖定 snapshot envelope、public surface、Adapter／Port 同構、BC writeback 與停止條件。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-04 | completed | Implementer | 僅在 PR-04 明示 `approved` 後，最小實作 `DiffSnapshot` declarations、所有已鎖定 input signatures、Adapter／Port 同構、type-level tests 與 PR Reader BC envelope writeback。 | Implementer 已完成已鎖定的 `DiffSnapshot` propagation、Adapter／Port 同構、type-level tests 與 PR Reader BC envelope writeback；未實作 concrete behavior、DOM、UI、bridge、新增套件或修改 architecture-canvas 圖。 |
| TE-04 | approved | Tester | 執行既有 Bun typecheck、受影響 tests 與 coverage gate，並驗證 snapshot envelope、barrel export、Adapter／Port assignability 與禁止跨層依賴的 evidence。 | Independent Tester first verdict：`needs-rework`，原因為 `DiffSnapshot` propagation 不完整；完成修正後明示 verdict：`approved`。測試成功不取代 Reviewer approval。 |
| RV-04 | approved | Reviewer | 獨立審查 IM-04 implementation、contract、PR Reader BC writeback 與驗證 evidence；分類 approved、needs-rework、blocked 或 human-check。 | Independent Reviewer 明示 verdict：`approved`。 |
| GH-04 | pending | Code-Implementer | 僅在 RV-04 明示 `approved` 後，依 human 已授權流程 commit、push 更新既有 PR #4，回覆並 resolve 已修正的本輪 PR threads。 | 尚無；不得在 RV-04 approval 前執行 GitHub handoff。 |
| HC-03 | pending | Human | 審閱 PR #4 的 IM-04 修正、test／review evidence 與 resolved threads。 | 尚無；GH-04 完成後停止於此 human boundary。 |
| PC-05 | completed | Plan-Creator | 將同 topic 四份 artifacts 修正為 human 已鎖定的 viewed notification best-effort `void` exception、architecture writeback 與 canvas main-flow alignment。 | 四份 artifacts 已更新；僅為 Plan-Creator handoff，不是 Plan-Reviewer approval。 |
| PR-05 | approved | Plan-Reviewer | 獨立檢查 PC-05 artifacts 是否將 `void` exception 限於 viewed notification、保留既定 snapshot／Output contract，並正確鎖定 architecture writeback、canvas flow、validation evidence、scope 與 gates。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-05 | completed | Implementer | 僅在 PR-05 明示 `approved` 後，最小修正既定 declarations／tests（如需）、架構 README、PR Reader BC 文件與 architecture-canvas scene／generated index。 | Implementer 已完成既定 declarations／tests（如需）、architecture writeback 與 architecture-canvas scene／generated index 修正；未實作 concrete pipeline behavior、DOM、UI、bridge、transport、reliability、套件變更或發布 artifact.cafe。 |
| TE-05 | approved | Tester | 執行既有 Bun typecheck、受影響 tests、coverage gate 與 architecture-canvas validate／build evidence 驗證。 | Independent Tester 前兩次明示 verdict：`needs-rework`，原因為 canvas 殘留非繁體中文文字與 locale／`lang` 設定；完成最終 locale／`lang` 修正後明示 verdict：`approved`。測試或 canvas 命令成功不取代 Reviewer approval。 |
| RV-05 | approved | Reviewer | 獨立審查 IM-05 implementation、`void` exception scope、architecture writeback、canvas main flow 與驗證 evidence；分類 approved、needs-rework、blocked 或 human-check。 | Independent Reviewer 明示 verdict：`approved`。 |
| GH-05 | pending | Implementer | 僅在 RV-05 明示 `approved` 後，依 human 已授權流程 commit、push 更新既有 PR #4，回覆並 resolve 本輪已修正 PR threads。 | 尚無；Reviewer approval 前不得 GitHub handoff 或 resolve threads。 |
| HC-04 | pending | Human | 審閱 PR #4 的 IM-05 修正、test／canvas evidence、Reviewer verdict 與 resolved threads。 | 尚無；GH-05 完成後停止於此 human boundary。 |
| PC-06 | completed | Plan-Creator | 將同 topic 四份 artifacts 收斂為 README dependency／flow wording 與單一 canvas artifact-local keyboard／screen-reader fallback 的既定契約。 | 四份 artifacts 已更新；只記錄已明示 decision 與 gate，並非 Plan-Reviewer approval。 |
| PR-06 | approved | Plan-Reviewer | 獨立審查 PC-06 artifacts：scope 僅限 README 與單一圖、scene data single source、stage-scoped keyboard／semantic fallback、既定 pipeline／ownership 未漂移，以及 gate 一致性。 | Independent Plan-Reviewer 明示 verdict：`approved`。 |
| IM-06 | completed | Implementer | 僅在 PR-06 明示 `approved` 後，最小修正 README wording，並對單一 diff canvas 實作 diagram-local、冪等 post-build accessibility enhancer／verifier。 | Implementer 已完成 README 與 diagram-local enhancement／verifier；未修改 TypeScript pipeline、Swift bridge、global template、其他 diagrams 或套件。 |
| TE-06 | approved | Tester | 執行既有 Bun gates、diff check、canvas validate／temp build、enhancer／verifier，並靜態驗證 locale、ARIA、stage-scoped keyboard、traversal、live status、動態 fallback 與 native semantic controls。 | Independent Tester 明示 verdict：`approved`；canvas validate、temp build byte-identical、enhancer／verifier、既有 Bun gates 與 diff check 均通過。實體 browser／VoiceOver 未在此 gate 宣稱完成。 |
| RV-06 | needs-rework | Reviewer | 獨立審查 IM-06 的 README 與 diagram-local accessibility scope、資料真相、keyboard／screen-reader fallback、既定 pipeline contract 與驗證 evidence。 | Independent Reviewer 明示 verdict：`needs-rework`；唯一 finding 為本 ledger 尚未記錄 PC-06 至 TE-06 的真實 workflow evidence。完成本次 ledger correction 後，必須重新交由獨立 Reviewer 審查。 |
| GH-06 | pending | Implementer | 僅在 RV-06 明示 `approved` 後，依 human 已授權流程 commit、push 更新既有 PR #4，回覆並 resolve R4 的四個已修正 threads。 | 尚無；不得在 RV-06 approval 前進行 GitHub handoff 或 resolve threads。 |
| HC-05 | pending | Human | 審閱 PR #4 的 IM-06 accessibility／wording 修正、驗證與 review evidence，以及 resolved R4 threads。 | GH-06 完成後停止於此 human boundary。 |
| PC-07 | completed | Plan-Creator | 將同 topic 四份 artifacts 收斂為 canvas ownership／boundary responsibility、Archify runtime `dataflow`、diagram-local single reproducible build entry、visible fallback 與 opaque phantom brand 的既定 revision contract；依 RV-07 recheck 唯一 finding，將所有 Archify validate／deliver 指令入口精確修正為 `<archify-skill>/bin/archify.mjs`。 | 四份 artifacts 已同步完成最小 PC-07 rework；此 Plan-Creator completion 不取代 Plan-Reviewer recheck。 |
| PR-07 | approved | Plan-Reviewer | 獨立 recheck PC-07 artifacts：所有 Archify validate／deliver（及若有 visual-check）指令均使用 `<archify-skill>/bin/archify.mjs`，且既定 canvas／`dataflow` responsibility、scope、contract、two-artifact atomic policy 與 gates 未漂移。 | Independent Plan-Reviewer 明示 verdict：`approved`。以 `<archify-skill>/bin/archify.mjs` 逐一重檢所有記載的 validate／deliver（及 visual-check）入口；未發現 contract、scope、責任邊界、two-artifact atomic policy 或 gate drift。 |
| IM-07 | completed | Implementer | 僅在 PR-07 明示 `approved` 後，最小實作 R5 的 canvas responsibility split、Archify `dataflow`、single build entry、visible fallback 與 opaque brand 修正。 | Implementer 已完成已鎖定的 diagram responsibility split、artifact-local build／a11y 行為、Archify `dataflow` 與 opaque brand 修正；未實作 concrete pipeline、Swift bridge、global template、其他圖、套件或新架構事實。 |
| TE-07 | completed | Tester | 驗證既有 Bun gates、opaque type-level assertions、canvas commands，以及 Archify `node <archify-skill>/bin/archify.mjs validate dataflow <spec> --quality showcase --json`／寫至 same-filesystem temporary target 的 `node <archify-skill>/bin/archify.mjs deliver dataflow <spec> <temporary-output.html> --quality showcase --json`、兩 artifact hash／consistency check、atomic rename、single build entry idempotence／failure safety 與 static accessibility assertions。 | Independent Tester 已完成既有 Bun gates、canvas／Archify command、rebuild safety 與 static accessibility evidence；runtime browser／screen-reader 未在此 gate 宣稱完成。 |
| RV-07 | approved | Reviewer | 在 PR-07 明示 `approved` 後，獨立 final recheck IM-07、Archify `dataflow` verify／delivery evidence、R5 四個 findings 與既定 contract／scope／workflow。 | 歷史 verdict：`needs-rework`；唯一 finding 為所有 Archify validate／deliver 指令錯誤指向 `<archify-skill>/scripts/archify.mjs`，正確入口為 `<archify-skill>/bin/archify.mjs`。PC-07 最小修正與 PR-07 bin-path／no-drift recheck 後，Independent Reviewer final verdict：`approved`；R5 findings、build transaction、CLI path 與既有 test evidence 均已 recheck，未發現 blocker 或 drift。 |
| GH-07 | pending | Code-Implementer | 僅在 RV-07 明示 `approved` 後，依 human 已授權流程 commit、push 更新既有 PR #4，回覆並 resolve 本輪四個 R5 threads。 | 尚無；不得在 RV-07 approval 前 Git handoff 或 resolve threads。 |
| HC-06 | pending | Human | 審閱 PR #4 的 IM-07 修正、驗證／review evidence 與 resolved R5 threads；實際 browser／screen-reader 行為在此確認。 | GH-07 完成後停止於此 human boundary。 |
| PC-08 | completed | Plan-Creator | 將同 topic 四份 artifacts 收斂為四個既定契約回修：fallback 展開後可捲動、`EDGES` 的來源→目標＋label 語意、`SIGINT`／`SIGTERM` 雙產物 rollback，以及 Archify success-only stage progression；並依 PR-08 finding 最小修正 Archify English chrome／`lang="en"` human check 的 gate 指向。RV-08 後，補正 workflow ledger，並將 verifier 必須驗證 generated artifact 的 actual injection marker 明確記入既定驗收。 | 初版四份 artifacts 已更新且未改變既定資料模型、ownership 或 failure contract；PR-08 首次 `needs-rework` 後，僅將 requirements:41、technical-spec:226、plan:40／59 的現行 human-check gate 由 HC-06 校正為 HC-07。RV-08 所需的 ledger correction 與 marker 驗收已完成；此 completion 不取代 RV-08 的獨立 final recheck。 |
| PR-08 | approved | Plan-Reviewer | 獨立檢查 PC-08 是否保留已鎖定 pipeline／failure contract／zero-deps／canvas boundary，並正確要求 fallback 可到達性、edge direction、interrupted two-output recovery、dataflow success-only edges、測試與 human boundary。 | Independent Plan-Reviewer recheck 明示 verdict：`approved`；確認 PR-08 的最小 human-check gate 校正未造成既定 contract、scope 或 gate drift。 |
| IM-08 | completed | Implementer | 僅在 PR-08 明示 `approved` 後，最小回修四個 finding：a11y scrollability、relationship direction text、interrupt rollback、failure-edge graph；並完成 RV-08 所指 verifier actual-injection marker 的 bounded rework。 | Implementer 已完成四項既定回修與 verifier marker rework；未實作 TypeScript pipeline、未改 global template、架構 contract 或新增依賴。等待獨立 Tester evidence 與 RV-08 final recheck。 |
| TE-08 | approved | Tester | 驗證既有 Bun gates、canvas／Archify validation、fallback static assertions、success-only dataflow edges，及 first／second publish 間受控 `SIGINT`／`SIGTERM` rollback 的 hash／cleanup evidence；另驗證 generated artifact 的 actual-injection marker 與 negative false-green scenario。 | Independent Tester 明示 verdict：`PASS`；既有 Bun gates、canvas／Archify validation、fallback／dataflow static assertions，以及受控 `SIGINT`／`SIGTERM` rollback 的 hash／cleanup evidence 均通過。actual-injection marker 正向情境通過，且刻意保留 source marker 而移除 generated artifact injection 的 negative false-green scenario 如預期失敗。browser／VoiceOver 實測不由此 gate 宣稱完成。 |
| RV-08 | pending | Reviewer | 對 IM-08 marker rework 與 TE-08 exact-scenario evidence 進行獨立 final recheck，連同既定 contract／scope／workflow 分類 approved、needs-rework、blocked 或 human-check。 | 歷史 verdict：Independent Reviewer 初次明示 `needs-rework`；finding 為：(1) 本 ledger 未反映 PR-08 approval、IM-08 completion 與 TE-08 PASS，造成 workflow state stale；(2) verifier 對 actual injection 的 marker 驗證不足。PC-08 ledger correction、IM-08 bounded marker rework 與 TE-08 independent `PASS` 已完成；尚待獨立 final recheck，故不得視為 RV-08 approved。 |
| GH-08 | pending | Implementer | 僅在 RV-08 明示 `approved` 後，依 human 已授權流程 commit、push 更新既有 PR #4，回覆並 resolve 精確四個 threads：`enhance-accessibility.js:35`、`build-diagram.sh:221`、`enhance-accessibility.js:121`、`diff-render-flow.dataflow.json:111`。 | 尚無；不得在 RV-08 approval 前 GitHub handoff 或 resolve threads。 |
| HC-07 | pending | Human | 審閱 PR #4 的 IM-08 回修、驗證／review evidence 與四個 resolved threads；實際 browser、VoiceOver／screen-reader 與 Archify English chrome 的可讀性在此確認。 | GH-08 完成後停止於此 human boundary。 |

## Blockers

- 無需 human 決策的未解析 blocker；初次 RV-08 的 `needs-rework` finding 已完成 ledger 與 bounded marker rework。現行下一關為獨立 RV-08 final recheck。
- PC-08、PR-08、IM-08 與 TE-08 已完成其各自 evidence gate；RV-08 final recheck 未 approval 前，GH-08 與 HC-07 保持 pending。PC-08 不得以本輪回修重開既定 contract。

## Human Check

- GH-08 完成後，停止於 HC-07；除實體 browser／screen-reader fallback 外，Archify 英文 global viewer chrome 與 `lang="en"` 在實際閱讀情境下的 visibility／readability 亦屬 human-check，不得由 agent 或 ledger 假稱已完成或已繁中化。

## Last Updated

- Updated by: Plan-Creator
- Update reason: 記錄 RV-08 marker finding 的 IM-08 bounded rework、TE-08 independent `PASS` 的 actual-injection 正向與 negative false-green scenarios，並將目前 gate 前進至 RV-08 final recheck。
- Update status: RV-08 final recheck pending；GH-08 與 HC-07 均未完成；checkbox、status 或 tracker 結果不構成 approval。
