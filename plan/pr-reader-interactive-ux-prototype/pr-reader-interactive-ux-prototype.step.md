# PR Reader 互動 UX 原型執行帳本

## Topic

- Slug：`pr-reader-interactive-ux-prototype`
- Primary BC：`PR Reader`
- Work branch：`codex/pr-reader-interactive-ux-prototype`
- Base branch：`codex/pr-inbox-static-visual-prototype`

## Current Phase

Delivery ready：RV-05 completed／`approved`，required/advisory findings均為none；commit gate open。DL-04 pending，仍待staged review、Human commit-message確認、commit與bounded non-force push；HC-03 pending。

## Planning Input

- Conversation-only v4 contract：上游已明示 Plan-Reviewer `approved`，作為 PC-01 寫入依據。
- 正式四份 artifacts：`PR-01` verdict為 `needs-rework`；required fixes已由 PC-02寫入，`PR-02` 已明示 `approved`。
- Base delivery prerequisite：`BP-01`，owner為 `Implementer`，status為 completed。上一 topic branch已完成 bounded non-force push並確認 remote/local HEAD；Observer/Dispatcher、Plan-Creator與 Reviewer未執行 push。
- Human adjustment：HC-01於2026-09-12明示選擇「調整」review progress/Finish UX；PC-03起始worktree clean，local HEAD與upstream均為`0865469`。
- Delivery baseline：DL-03已以commit`8c2facf`完成bounded non-force push；PC-05起始worktree clean，local HEAD與upstream均為`8c2facf`。
- Human adjustment：HC-02明示選擇「調整」，要求prototype-local unreview、三態Files footer及Overview native progress；RV-04只保留歷史。

## Artifacts

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/pr-reader-interactive-ux-prototype/requirements.md` | changed by PC-05 | 產品意圖、範圍、成功條件、Human Check |
| `analysis/pr-reader-interactive-ux-prototype/technical-spec.md` | changed by PC-05 | locked fixtures、state、interaction、technical verification mapping |
| `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md` | changed by PC-05 | 受限執行契約、allowlist、TC-01～TC-14、workflow |
| `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md` | changed by PC-05 | phase、steps、evidence、verdict、blocker、Human Check |

## Steps

### PC-01 — 建立正式 topic artifacts

- Status：completed
- Owner role：Plan-Creator
- Completion criteria：
  - 只建立同 slug 的四份正式 artifacts。
  - 四份文件一致映射 v4 contract 的 Goal、Non-Goal、In-Scope、Out-Of-Scope、ReadOnly、Written、Deleted、Modify、TC-01～TC-14、base prerequisite、roles、verdict 與 Human Gate。
  - 不建立 prototype、不修改既有檔案、不 commit/push。
- Verification evidence：
  - 四個指定 paths已建立，且本輪均為 untracked新檔。
  - Plan-Creator self-check：topic/BC/path、exact strings、allowlist、state、tests 與 workflow routing 已交叉核對。
  - `git status --short --untracked-files=all`已列出且只列出四個 allowlisted `??` paths，涵蓋目前 tracked/staged/unstaged/untracked狀態；普通 `git diff --name-status`空白輸出未被當作 untracked evidence。
  - 四個 untracked artifacts已逐檔以會實際讀取內容的 `git diff --no-index --check /dev/null <artifact>`檢查，沒有 whitespace diagnostics；普通 `git diff --check`空白輸出未被當作 untracked內容 evidence。若後續 staged，可再以 `git diff --cached --check`補強。
  - 上述 path/whitespace evidence只證明寫入範圍與基本格式，不構成 approval。
- Verdict：不適用；Plan-Creator 不自我核准。

### PR-01 — 獨立審查正式 planning artifacts

- Status：completed
- Owner role：Plan-Reviewer
- Completion criteria：
  - 獨立審查四份 artifacts 的一致性、decision completeness、scope/ownership、allowlist、TC-01～TC-14、base prerequisite 與 workflow。
  - 明示標準 verdict：`approved`、`needs-rework`、`blocked` 或 `human-check`。
- Verification evidence：Plan-Reviewer明示 `needs-rework`；required fixes為 base push owner/routing與 untracked allowlist/whitespace evidence。
- Routing：
  - `approved`：待 base delivery prerequisite 完成/確認後，建立 implementation baseline並進 IM-01。
  - `needs-rework`：只回 Plan-Creator修正四份 artifacts。
  - `blocked`／`human-check`：停止並交還 Human。
- Verdict：`needs-rework`

### PC-02 — 修正 PR-01 required fixes

- Status：completed
- Owner role：Plan-Creator
- Completion criteria：
  - 只修改四份同 topic artifacts。
  - 將上一 topic bounded non-force push明確交給 Implementer，並禁止 Observer/Dispatcher、Plan-Creator、Reviewer執行 push。
  - 將 PC-01與 TC-01 evidence改為可枚舉/檢查 untracked paths與內容的方法。
  - 不建立 HTML、不修改其他檔案、不 commit/push。
- Verification evidence：
  - `git status --short --untracked-files=all`已確認四份 artifacts仍為唯一 untracked paths，列出四個 allowlisted `??` paths。
  - 四份 artifacts已逐檔以 `git diff --no-index --check /dev/null <artifact>`實讀檢查，無 whitespace diagnostics；普通空白 diff不作為 untracked evidence。
- Verdict：不適用；Plan-Creator不自我核准。

### PR-02 — 獨立重審正式 planning artifacts

- Status：completed
- Owner role：Plan-Reviewer
- Completion criteria：
  - 獨立確認 PR-01 required fixes已在四份 artifacts一致完成，且無 scope/contract drift。
  - 明示標準 verdict。
- Verification evidence：已收到獨立 Plan-Reviewer 對四份正式 artifacts 的明示 `approved` verdict。
- Routing：
  - `approved`：交 Implementer執行 BP-01；BP-01完成後建立 TC-01 baseline並進 IM-01。
  - `needs-rework`：只回 Plan-Creator。
  - `blocked`／`human-check`：停止並交 Human。
- Verdict：`approved`

### BP-01 — 上一 topic branch bounded non-force push

- Status：completed
- Owner role：Implementer
- Completion criteria：
  - 只將上一 topic branch `codex/pr-inbox-static-visual-prototype`的既有 commits以 non-force方式推送至既定 remote。
  - 不建立或重寫 commit、不 force-push、不推送其他 branch/ref。
  - 確認 remote ref包含預期 base commits，使本 topic可建立穩定 TC-01 implementation baseline。
- Verification evidence：Implementer已執行 non-force push；local HEAD與 remote HEAD均為 `e9384e0`；upstream為 `origin/codex/pr-inbox-static-visual-prototype`；上一 topic/base worktree clean。
- Routing：completed後建立 TC-01 implementation baseline並進 IM-01；失敗或需擴權則停止交 Human。
- Guard：Observer/Dispatcher、Plan-Creator與 Reviewer不得執行 push；其他角色不得取代 Implementer。
- Verdict：不適用

### IM-01 — 建立互動 HTML 原型

- Status：completed；ready-for-test
- Owner role：Implementer
- Completion criteria：
  - PR-02 明示 `approved`，BP-01已由 Implementer完成/確認，且 TC-01 implementation baseline已建立。
  - 唯一新增 `prototypes/pr-reader-interactive-ux-prototype/index.html`。
  - 實作 plan 中 IM-01.1～IM-01.7，提供 TC-01～TC-14 evidence。
- Verification evidence：
  - 唯一新增 `prototypes/pr-reader-interactive-ux-prototype/index.html`；四份正式 planning artifacts維持 implementation baseline。
  - Node syntax check clean。
  - Untracked HTML已實際讀取並完成 file-specific whitespace check，結果 clean；未以空白普通 diff輸出代替 untracked evidence。
  - 32個 required values、48個 file identities、tab order與 canonical totals檢查 clean。
  - Forbidden external/network/storage/submit scan clean。
  - 未 commit、未 push。
- Routing：completed handoff 後交 Tester。
- Verdict：不適用

### TE-01 — 驗證互動原型

- Status：completed
- Owner role：Tester
- Completion criteria：
  - 收到 IM-01 明示完成交接。
  - 在真實 Chrome 1440 × 900，以 `file://` 驗證 TC-01～TC-14。
  - 檢查 offline、network、storage、console、overflow、所有 click/keyboard/modal/state flow。
- Verification evidence：
  - Tester明示 `approved`；TC-01～TC-14全部 PASS，無 severity issue。
  - Chrome 153 headed、1440 × 900、`file://`實際瀏覽器驗證完成。
  - External requests、console errors、console warnings、page errors、horizontal overflow均為 `0`。
  - Screenshots：
    - `output/playwright/pr-reader-interactive-ux-prototype/tc03-initial-inbox.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc06-atlas87-overview.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc08-atlas87-files-initial.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc11-atlas87-commits.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc11-atlas87-checks.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc12-atlas87-inline-conversation.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc12-nebula156-saved-draft.png`
    - `output/playwright/pr-reader-interactive-ux-prototype/tc13-reload-reset-inbox.png`
  - Playwright的 `file://` safety workaround屬 informational，不是 severity issue或產品 defect。
  - Tester未修改 tracked檔案。
- Routing：完成後連同 evidence 交獨立 Reviewer；Tester結果不等於 Reviewer approval。
- Verdict：`approved`

### RV-01 — 獨立成果審查

- Status：completed
- Owner role：Reviewer
- Completion criteria：
  - 審查唯一 prototype、Implementer handoff與 Tester evidence。
  - 驗證 scope、contract、allowlist、TC-01～TC-14與 capability boundary。
  - 明示標準 verdict。
- Verification evidence：唯一 Medium finding：`index.html` 的四筆 noncanonical Reader time 與 Inbox fixture不一致；#142顯示 `12m ago`而非`12m`、#315顯示`2h ago`而非`2h`、#54顯示`5h ago`而非`5h`、#156顯示`2d ago`而非`2d`。因此 TC-05 未完全成立；其他 finding無新增紀錄。
- Routing：
  - `approved`：進 HC-01。
  - `needs-rework`：只回 Implementer，仍限同一 `index.html`；超出則回 planning。
  - `blocked`／`human-check`：停止並交還 Human。
- Verdict：`needs-rework`

### IM-02 — 修正 noncanonical Reader time mapping

- Status：completed；ready-for-test
- Owner role：Implementer
- Completion criteria：
  - 只修改 `prototypes/pr-reader-interactive-ux-prototype/index.html`。
  - 將 #142、#315、#54、#156 的 Reader time分別修正為 `12m`、`2h`、`5h`、`2d`，與 Inbox fixture一致。
  - 保持 #87 Reader time `38m ago`與 #91 `Yesterday`不變；不修改其他內容、scope或 interaction。
  - 不 commit/push。
- Verification evidence：
  - #142、#315、#54、#156的 `readerTime` 已分別修正為 `12m`、`2h`、`5h`、`2d`。
  - #87維持`38m ago`，#91維持`Yesterday`。
  - Exact-value與 forbidden-value `rg` checks、Node syntax check、file-specific whitespace check、EOF newline check、allowlist enumeration全數 PASS。
  - 未 commit/push。
- Routing：completed handoff後交 TE-02。
- Verdict：不適用

### TE-02 — 驗證 bounded time mapping fix

- Status：completed
- Owner role：Tester
- Completion criteria：
  - 收到 IM-02 completed handoff。
  - 實讀 HTML並以 Chrome `file://`重驗 TC-05：六筆 Reader time必須與各自 Inbox fixture契約一致，且 #87維持`38m ago`、#91維持`Yesterday`。
  - 確認變更僅限同一 HTML time mapping，無互動或 runtime regression。
- Verification evidence：
  - Tester明示 `approved`；六筆 Reader time exact values全數 PASS，四筆 forbidden `ago` strings均不存在。
  - Workspace replacement與返回後 selection/count `6` PASS。
  - #87 `Review Changes →` 初次進 Files顯示 `3 / 8 files` PASS。
  - Keyboard smoke、runtime console/network/storage/overflow、reload reset與 scope hygiene全數 PASS。
- Routing：完成後交獨立 RV-02；Tester結果不等於 Reviewer approval。
- Verdict：`approved`

### RV-02 — 獨立審查 bounded rework

- Status：completed
- Owner role：Reviewer
- Completion criteria：
  - 審查 IM-02 change set與 TE-02 evidence。
  - 確認 Medium finding已解除、TC-05完整成立，且無 scope/contract drift。
  - 明示標準 verdict。
- Verification evidence：
  - Reviewer明示 `approved`；required findings為 none，advisory findings為 none。
  - Change set只有 #142/#315/#54/#156四筆 `readerTime`修正，無其他 implementation變更。
  - TE-02六筆 Reader time snapshot正確；TC-05、workspace replacement、return selection/count `6`、#87 `3 / 8 files`與 runtime diagnostics全數 PASS。
  - Allowlist與 excludes檢查 clean。
- Routing：
  - `approved`：進 HC-01。
  - `needs-rework`：仍只回 Implementer修改同一 HTML；超出則回 planning。
  - `blocked`／`human-check`：停止並交 Human。
- Verdict：`approved`

### HC-01 — Human UX 方向決策

- Status：completed
- Owner：Human
- Entry criteria：RV-02 明示 `approved`；其他狀態不得進入。
- Decision options：
  - 採用：只允許另開正式 SwiftUI topic，不自動實作。
  - 調整：回到本 topic 對應 planning/implementation phase。
  - 放棄：本 topic 結案。
- Verification evidence：Human於2026-09-12明示選擇「調整」；要求以`reviewedFileOrdinals`、Mark Reviewed、forward/wrap與8/8 Finish Reading取代舊visited/Done progress UX。
- Outcome：返回planning，由PC-03修改四份artifacts；舊PR/RV approval僅保留歷史，不能放行新contract。
- Decision：調整

### PC-03 — 寫入 Human adjustment contract

- Status：completed
- Owner role：Plan-Creator
- Completion criteria：
  - 只修改四份同topic artifacts；HTML與其他paths唯讀。
  - 以per-PR `reviewedFileOrdinals`取代visited progress，鎖定idempotent Mark、forward/wrap、full-set Finish與no-unreview。
  - 同步Goal/Non-Goal、In/Out、ReadOnly/Written/Deleted/Modify、state/edge/public impact、TC-01～TC-14與新workflow gates。
  - 不實作HTML、不commit/push。
- Verification evidence：
  - 起始worktree clean，local HEAD與upstream均為`0865469`。
  - `git status --short --untracked-files=all`與`git diff --name-status`都只列出四份allowlisted tracked artifact modifications；HTML與其他paths不變。
  - 四份artifacts的cross-artifact consistency、`git diff --check`、whitespace與EOF檢查clean。
  - Completed只表示planning write/self-check，不構成PR-03 approval。
- Verdict：不適用；Plan-Creator不自我核准。

### PR-03 — 獨立審查 Human adjustment contract

- Status：completed
- Owner role：Plan-Reviewer
- Completion criteria：
  - 審查四份artifacts對Human adjustment、state algorithm、edge cases、phase allowlists、updated TC與workflow的一致性及decision completeness。
  - 確認舊approval未被誤用、新contract沒有surface/domain/scope drift。
  - 明示標準verdict。
- Verification evidence：Plan-Reviewer明示`needs-rework`；唯一required finding為Overview未鎖定由`reviewedFileOrdinals.size`推導、三態皆可見且與Files footer同格式的逐字progress，會把0/8與8/8是否顯示留給Implementer決定。無需Human決策。
- Routing：
  - `needs-rework`：已只回Plan-Creator執行bounded PC-04，修改四份artifacts。
  - `blocked`／`human-check`：停止並交Human。
- Verdict：`needs-rework`

### PC-04 — 補足 Overview derived progress contract

- Status：completed
- Owner role：Plan-Creator
- Completion criteria：
  - 只修改四份同topic artifacts；HTML與其他paths唯讀。
  - 鎖定Overview在既有action附近、同一surface/layout中，於0/1...7/8 reviewed三態分別顯示`0 / 8 reviewed`、`n / 8 reviewed`、`8 / 8 reviewed`。
  - Progress與CTA都由`reviewedFileOrdinals.size`推導；CTA仍分別為Review Changes／Continue Review／Finish Reading。
  - 同步TC-06/TC-07/TC-13與PR-04 routing，不改其他approved defaults。
- Verification evidence：
  - PC-03/PC-04 combined diff仍只包含四份allowlisted tracked artifacts；HTML與其他paths不變。
  - 四份artifacts皆含PR-03 finding、PC-04/PR-04 gate與Overview三態progress contract；舊PR-03 approval/pending gate文字無殘留。
  - `git status --short --untracked-files=all`、`git diff --name-status`、`git diff --check`、whitespace與EOF checks clean。
  - Completed只表示planning write/self-check，不構成PR-04 approval。
- Verdict：不適用；Plan-Creator不自我核准。

### PR-04 — 獨立重審 Overview progress fix

- Status：completed
- Owner role：Plan-Reviewer
- Completion criteria：
  - 驗證四份artifacts一致鎖定Overview三態derived progress、對應CTA、既有surface/layout限制與往返恢復。
  - 確認PR-03 finding已解除，且無其他scope/contract/workflow drift。
  - 明示標準verdict。
- Verification evidence：
  - Plan-Reviewer明示`approved`；required findings為none，advisory findings為none。
  - Overview 0／1...7／8 reviewed三態progress與CTA均由`reviewedFileOrdinals.size`推導，逐字格式、既有surface/layout限制一致。
  - TC-06、TC-07、TC-13已覆蓋三態顯示、action transition及Overview↔Files↔Inbox往返derived display；PR-03 finding已解除。
- Routing：
  - `approved`：建立approved planning handoff，進IM-03。
  - `needs-rework`：只回Plan-Creator修改四份artifacts。
  - `blocked`／`human-check`：停止並交Human。
- Verdict：`approved`

### IM-03 — 實作 reviewed progress adjustment

- Status：completed；ready-for-test
- Owner role：Implementer
- Completion criteria：
  - PR-04明示`approved`。
  - 只修改既有`prototypes/pr-reader-interactive-ux-prototype/index.html`；四份artifacts與其他paths唯讀。
  - 實作reviewed set、current/reviewed indicators、Mark/forward/wrap、三態derived Overview progress/action、Files footer與Finish/back invariants。
  - 提供更新後TC-01～TC-14 evidence；不commit/push。
- Verification evidence：
  - 唯一implementation修改為既有`prototypes/pr-reader-interactive-ux-prototype/index.html`；四份artifacts與其他paths保持不變，無新增或刪除檔案。
  - 已以per-PR reviewed set取代visited progress，並讓current selection overlay與reviewed membership正交呈現。
  - `Mark Reviewed`為idempotent，完成向後搜尋、尾端wrap、切檔change reset與full-set停留行為。
  - Overview已實作0／1...7／8 reviewed三態derived progress/action；Files footer顯示reviewed count、移除Done並依8/8切換Finish Reading。
  - Finish gate、neutral back、Inbox invariants與comment/composer/draft不改progress/navigation guard均已實作。
  - Implementer回報static checks clean；未commit/push。
- Routing：completed handoff後交TE-03。
- Verdict：不適用

### TE-03 — 驗證 reviewed progress adjustment

- Status：completed
- Owner role：Tester
- Completion criteria：
  - 收到IM-03 completed handoff。
  - 以真實Chrome 1440 × 900 `file://`驗證更新後TC-01～TC-14，包含idempotency、reselect、forward/wrap、last/full gate、comment isolation、multi-PR往返與reload。
  - 驗證runtime diagnostics、network/storage、scope/layout hygiene與path allowlist。
- Verification evidence：
  - Tester以Chrome 153 headed、1440 × 900、`file://`完成驗證；TC-01～TC-14全數PASS。
  - Overview在0／1／8 reviewed時分別顯示正確progress與Review Changes／Continue Review／Finish Reading action。
  - #87首次進Files選第3檔且為`0 / 8 reviewed`；Mark ordinal 3後前進至4，mark ordinal 8可wrap至1，最後在ordinal 2完成後留在該檔並顯示`8 / 8 reviewed`。
  - Comment/composer/draft不改progress/navigation；第二PR的state與#87隔離，Overview↔Files↔Inbox往返保留，reload完整reset。
  - No Done、no redesign、no storage/network/product/GitHub write；console/page runtime errors均為0，allowlist與scope hygiene通過。
- Routing：完成後交獨立RV-03；Tester結果不等於Reviewer approval。
- Verdict：`approved`

### RV-03 — 獨立審查 reviewed progress adjustment

- Status：completed
- Owner role：Reviewer
- Completion criteria：
  - 審查IM-03 change set與TE-03 evidence。
  - 確認Human adjustment與updated TC完整成立、只有HTML implementation change且無contract/scope drift。
  - 明示標準verdict。
- Verification evidence：
  - Reviewer明示`needs-rework`；唯一finding為Medium severity。
  - HTML在reviewed current且reviewed count為0...7時顯示disabled `Reviewed`並由handler early return；最新contract要求action維持可用且逐字為`Mark Reviewed`，重按雖不改set membership，仍須搜尋next unreviewed、必要時wrap並在切檔後令change=0。
  - 未reviewed current目前顯示`Mark as Reviewed`，也不符合鎖定逐字`Mark Reviewed`。
  - 其餘reviewed progress、Finish、comment isolation、scope與runtime未列finding。
- Routing：
  - `approved`：開啟final follow-up commit gate，進受限delivery。
  - `needs-rework`：只回Implementer修改同一HTML；超出則回planning。
  - `blocked`／`human-check`：停止並交Human。
- Verdict：`needs-rework`

### IM-04 — 修正 Mark Reviewed label 與 reviewed-current handler

- Status：completed；ready-for-test
- Owner role：Implementer
- Completion criteria：
  - 只修改既有`prototypes/pr-reader-interactive-ux-prototype/index.html`的Files footer/action handler；四份artifacts與其他paths唯讀。
  - Reviewed count為0...7時，不論current是否已reviewed，action都保持enabled且逐字顯示`Mark Reviewed`；不得顯示`Reviewed`或`Mark as Reviewed`。
  - Reviewed current重按時set membership保持不變，但不得early return；仍依鎖定順序搜尋next unreviewed、尾端wrap，切檔後change=0。
  - 保留未reviewed Mark、8/8 Finish Reading、Overview三態、comment isolation與其他已通過行為；不commit/push。
- Verification evidence：
  - Files footer在0...7 reviewed時已統一使用enabled逐字`Mark Reviewed`；不再顯示disabled`Reviewed`或`Mark as Reviewed`。
  - Reviewed current重按時set count保持idempotent，但不再early return；仍向後搜尋next unreviewed、必要時wrap，切檔後change=0。
  - 8/8時只顯示`Finish Reading`；既有Finish gate與其他行為保持。
  - Implementer回報static checks全部PASS；未commit/push。
- Routing：completed handoff後交TE-04。
- Verdict：不適用

### TE-04 — 驗證 Mark Reviewed bounded fix

- Status：completed
- Owner role：Tester
- Completion criteria：
  - 收到IM-04 completed handoff。
  - 驗證0...7 reviewed時未reviewed/current-reviewed兩種current都顯示enabled逐字`Mark Reviewed`，且不存在`Reviewed`／`Mark as Reviewed`。
  - 驗證reviewed current重按為membership-idempotent但仍前進至next unreviewed；包含wrap與切檔change=0。
  - 重驗8/8 Finish、Overview progress/action、comment isolation、multi-PR/reload、allowlist與runtime diagnostics。
- Verification evidence：
  - Tester明示`approved`；TC-09 bounded re-verification PASS。
  - 已reviewed file 4顯示enabled且逐字`Mark Reviewed`；重新啟用時count維持2並前進至next file 5、change=0。
  - 已reviewed file 8重按後wrap至file 1且count維持6；最後在file 2、change 2完成時留在該位置，顯示`8 / 8 reviewed`且只提供`Finish Reading`。
  - Comment/composer/draft不影響progress或navigation；Overview三態、Finish、neutral return、per-PR state與reload reset回歸通過。
  - Runtime diagnostics、storage/network/write禁止項、allowlist與worktree status檢查通過。
- Routing：完成後交獨立RV-04；Tester結果不等於Reviewer approval。
- Verdict：`approved`

### RV-04 — 獨立審查 Mark Reviewed bounded fix

- Status：completed
- Owner role：Reviewer
- Completion criteria：
  - 審查IM-04唯一HTML change set與TE-04 evidence，確認RV-03 Medium finding完整解除且無regression/scope drift。
  - 明示標準verdict。
- Verification evidence：
  - Reviewer明示`approved`；required findings為none，advisory findings為none。
  - Source inspection確認0...7 reviewed統一enabled逐字`Mark Reviewed`、無disabled/early return，reviewed current仍執行idempotent forward/wrap/change0；8/8只顯示Finish Reading。
  - TE-04已`approved`且TC-09重新驗證PASS；指定reactivation、wrap、last-file、comment、Overview/Finish/return/reload與runtime diagnostics evidence成立。
  - Worktree status恰為五個tracked `M` paths：四份topic artifacts與既有HTML；無新增/刪除、redesign或scope drift。
- Routing：
  - `approved`：開啟final follow-up commit gate，進受限delivery。
  - `needs-rework`：只回Implementer修改同一HTML；超出則回planning。
  - `blocked`／`human-check`：停止並交Human。
- Verdict：`approved`

### DL-03 — Final follow-up delivery

- Status：completed
- Owner role：Implementer
- Entry criteria：RV-04明示`approved`、staged review clean、Human依repository commit convention確認commit message。
- Completion criteria：
  - 單一commit只包含四份topic artifacts與既有HTML，共五個tracked paths。
  - 無新增/刪除/其他path；non-force push目前branch並確認upstream。
- Verification evidence：
  - Human已依repository commit convention確認message；Implementer完成staged review與commit`8c2facf`（`feat(pr-reader): 調整檔案閱讀進度與完成流程`）。
  - Commit恰含四份topic artifacts與既有HTML共五個tracked modified paths，無新增/刪除或其他path。
  - 已bounded non-force push目前branch；local HEAD與upstream均為`8c2facf`，worktree clean。
- Routing：completed後進HC-02。
- Verdict：不適用

### HC-02 — Human UX 方向決策

- Status：completed
- Owner：Human
- Entry criteria：RV-04明示`approved`且DL-03 completed；其他狀態不得進入。
- Decision options：
  - 採用：只允許另開正式SwiftUI topic，不自動實作。
  - 調整：回到本topic對應planning/implementation phase。
  - 放棄：本topic結案。
- Verification evidence：Human明示選擇「調整」；要求加入prototype-local unreview、Files footer三態與Overview native progress accessibility。
- Outcome：返回planning並由PC-05修改四份artifacts；RV-04與舊TC evidence只保留歷史，不放行新contract。
- Decision：調整

### PC-05 — 寫入第二次 Human adjustment contract

- Status：completed
- Owner role：Plan-Creator
- Completion criteria：
  - 只修改四份同topic artifacts；HTML與其他paths唯讀。
  - 鎖定Files footer三態、Mark/Unreview非對稱state transition、Overview native progress與accessible metadata。
  - 明確supersede active no-unreview、monotonic set、reviewed-current reactivation-forward與TC-14 forbidden-unreview敘述；歷史evidence保留且標示不可放行。
  - 同步Goal/In/Out/ReadOnly/Written/Deleted/Modify/state/edges/public impact、TC-01～TC-14、baseline`8c2facf`與新workflow gates。
- Verification evidence：
  - 起始worktree clean，local HEAD與upstream均為`8c2facf`。
  - `git status --short --untracked-files=all`與`git diff --name-status`都只列出四份allowlisted tracked artifact modifications；HTML、其他tracked paths與untracked paths皆未變動。
  - `git diff --check`無diagnostic；四份artifacts的EOF byte皆為`0a`。
  - Cross-artifact檢查確認Goal/scope、review/unreview三態、Overview native progress、baseline/allowlist、TC-01～TC-14與PR-05→IM-05→TE-05→RV-05→DL-04→HC-03 gates一致；舊no-unreview等敘述只留在明確標示的歷史ledger。
  - Completed只表示planning write/self-check，不構成PR-05 approval。
- Verdict：不適用；Plan-Creator不自我核准。

### PR-05 — 獨立審查第二次 Human adjustment contract

- Status：completed
- Owner role：Plan-Reviewer
- Completion criteria：
  - 審查四份artifacts對review/unreview/footer三態、Overview progress a11y、edge cases、phase allowlists與updated TC的一致性及decision completeness。
  - 確認舊RV-04未被誤用、歷史no-unreview contract未洩漏為active requirement，且無surface/domain/scope drift。
  - 明示標準verdict。
- Verification evidence：獨立Plan-Reviewer明示`approved`；required findings為none，advisory findings為none。四份artifacts對Human adjustment、footer三態、Mark/Unreview transition、Overview native progress a11y、TC-01～TC-14、phase allowlists與workflow gates一致，無surface/domain/scope drift。
- Routing：
  - `approved`：建立approved planning handoff，進IM-05。
  - `needs-rework`：只回Plan-Creator修改四份artifacts。
  - `blocked`／`human-check`：停止並交Human。
- Verdict：`approved`

### IM-05 — 實作 reversible reviewed progress

- Status：completed；ready-for-test
- Owner role：Implementer
- Completion criteria：
  - PR-05明示`approved`。
  - 只修改既有`prototypes/pr-reader-interactive-ux-prototype/index.html`；四份artifacts與其他paths唯讀。
  - 實作Files footer三態、Mark/Unreview transition、Overview native progress/accessible metadata與8/8 completion transition。
  - 提供更新後TC-01～TC-14 evidence；不commit/push。
- Verification evidence：
  - Implementation只修改既有`prototypes/pr-reader-interactive-ux-prototype/index.html`；四份planning artifacts維持approved implementation baseline。
  - 已實作Files footer三態：未reviewed current顯示primary`Mark Reviewed`；partial reviewed current顯示非互動`Reviewed`與secondary`Mark as Unreviewed`；8/8顯示`✓ All files reviewed`、secondary Unreview與primary`Finish Reading`。
  - Unreview為remove-only：只移除selected ordinal，保持PR/tab/file/change/draft/Inbox selection，不搜尋、導覽或wrap；render後恢復`Mark Reviewed`與focus，並具stale/ineligible guards。
  - Overview同列native progress已含value/max、visible-label association與更新的accessible value；0/partial/full numeric/action及completion labels由reviewed set size推導，8→7與1→0 transition成立。
  - 既有未reviewed`Mark Reviewed`forward/wrap/change-reset與last-file行為保持不變；comment/draft仍不改progress/navigation。
  - Implementer回報contract-targeted static checks clean；`git status --short --untracked-files=all`恰為五個tracked `M` paths：四份topic artifacts與既有HTML，無其他path。
  - 未commit、未push；此handoff不構成Tester或Reviewer approval。
- Routing：completed handoff後交TE-05。
- Verdict：不適用

### TE-05 — 驗證 reversible reviewed progress

- Status：completed
- Owner role：Tester
- Completion criteria：
  - 收到IM-05 completed handoff。
  - 以真實Chrome 1440 × 900`file://`驗證TC-01～TC-14，包含footer三態、Mark forward/wrap、Unreview remove-only/focus、8→7、1→0、stale no-op、comment/multi-PR/reload與Overview progress a11y。
  - 驗證runtime diagnostics、network/storage、scope/layout hygiene與path allowlist。
- Verification evidence：
  - Tester明示`approved`；TC-01～TC-14全數PASS。
  - Overview在0/partial/full三態均顯示同列native progress，value/max、visible-label association、accessible value與numeric/action/completion衍生狀態正確。
  - Partial reviewed current顯示非互動`Reviewed`與secondary`Mark as Unreviewed`；Unreview的2→1、1→0與8→7皆只移除current membership，保持PR/tab/file/change/draft/Inbox selection，且render後focus回到`Mark Reviewed`；stale/ineligible event為no-op。
  - 未reviewed`Mark Reviewed`的forward/wrap、切檔change=0與最後一檔留位regression均PASS；8/8時Overview/Files的`✓ All files reviewed`與`Finish Reading`成立，Finish與中性返回語意正確。
  - Comment/composer/draft不改progress或navigation；multi-PR state隔離、Inbox/Reader往返保留與reload reset均PASS。
  - 無新增panel/tab/surface/shortcut或Files progress indicator；external network、storage與runtime errors均為零，scope/layout hygiene通過。
  - Worktree仍恰為四份topic artifacts加既有HTML共五個tracked `M` paths；Tester未修改受測檔案。
- Routing：完成後交獨立RV-05；Tester結果不等於Reviewer approval。
- Verdict：`approved`

### RV-05 — 獨立審查 reversible reviewed progress

- Status：completed
- Owner role：Reviewer
- Completion criteria：
  - 審查IM-05 change set與TE-05 evidence。
  - 確認Human adjustment與updated TC完整成立、只有HTML implementation change且無contract/scope/a11y drift。
  - 明示標準verdict。
- Verification evidence：
  - Reviewer明示`approved`；required findings為none，advisory findings為none。
  - Source inspection確認implementation change只在既有HTML，Files footer三態、Unreview remove-only/preserve/focus/stale guards、Overview native progress a11y、0/partial/full completion transitions與既有Mark forward/wrap behavior符合active contract。
  - TE-05已`approved`且TC-01～TC-14全數PASS；2→1、1→0、8→7、full labels/Finish、comment/multi-PR/reload與no redesign/network/storage/runtime-error evidence成立。
  - Allowlist/status維持四份topic artifacts加既有HTML共五個tracked `M` paths，無其他path或scope drift。
- Routing：
  - `approved`：開啟DL-04 commit gate。
  - `needs-rework`：只回Implementer修改同一HTML；超出則回planning。
  - `blocked`／`human-check`：停止並交Human。
- Verdict：`approved`

### DL-04 — Final follow-up delivery

- Status：pending；ready-for-staged-review
- Owner role：Implementer
- Entry criteria：RV-05明示`approved`、staged review clean、Human依repository commit convention確認commit message。
- Completion criteria：
  - 單一commit只包含四份topic artifacts與既有HTML，共五個tracked paths。
  - 無新增/刪除/其他path；non-force push目前branch並確認upstream。
- Verification evidence：pending。
- Routing：completed後進HC-03。
- Verdict：不適用

### HC-03 — Human UX 方向決策

- Status：pending
- Owner：Human
- Entry criteria：RV-05明示`approved`且DL-04 completed；其他狀態不得進入。
- Decision options：
  - 採用：只允許另開正式SwiftUI topic，不自動實作。
  - 調整：回到本topic對應planning/implementation phase。
  - 放棄：本topic結案。
- Verification evidence：pending Human明示決策。
- Stop condition：到此停止自動前進，不得推論或代替Human選擇。

## Historical TestCase Ledger — pre-HC-01 contract

下列PASS只證明Human選擇調整前的舊contract；HC-01 outcome後不得用於放行PR-03/IM-03/TE-03/RV-03。

| ID | Scope | Status | Evidence owner |
| --- | --- | --- | --- |
| TC-01 | 以 status/equivalent枚舉 tracked/staged/unstaged/untracked後套 allowlist；untracked HTML需實讀 static/whitespace check，staged後可 cached check；空白普通 diff不是 evidence | PASS | Implementer / Tester / Reviewer |
| TC-02 | Offline/self-contained、zero storage、reload reset | PASS | Tester |
| TC-03 | 1440 × 900 fixed-dark native desktop visual | PASS | Tester / Reviewer |
| TC-04 | Inbox exact strings、static filter、compact metadata | PASS | Tester |
| TC-05 | Inbox selection/open 與 Reader replacement | PASS（TE-02 / RV-02） | Tester / Reviewer |
| TC-06 | #87 Overview exact content | PASS | Tester |
| TC-07 | 四 tabs、default Overview、Review Changes | PASS | Tester |
| TC-08 | Files雙欄、basename、8 files、初次 3/8、conversation | PASS | Tester |
| TC-09 | Files-only shortcuts、modifier/editable guard、bottom bar | PASS | Tester |
| TC-10 | Done/top back、membership與 continuity | PASS | Tester |
| TC-11 | Commits與 Checks | PASS | Tester |
| TC-12 | Inline conversation、modal、draft lifecycle | PASS | Tester |
| TC-13 | 六 PR state isolation與 reload | PASS | Tester |
| TC-14 | Capability boundary與 runtime stability | PASS | Tester / Reviewer |

## Historical TestCase Ledger — pre-HC-02 contract

下列PASS只證明HC-02選擇調整前的舊contract；其中no-unreview、monotonic set、reviewed-current enabled Mark/reactivation-forward與TC-14 forbidden-unreview皆已被HC-02 supersede，不得用於放行PR-05/IM-05/TE-05/RV-05。

| ID | Adjusted scope | Status | Evidence owner |
| --- | --- | --- | --- |
| TC-01 | Baseline `0865469`；PC-03/PC-04四artifacts、IM-03單一HTML、final五tracked paths allowlists | PASS | Plan-Creator / Implementer / Tester |
| TC-02 | Offline/self-contained、zero network/storage、reviewed reload reset | PASS | Tester |
| TC-03 | 1440 × 900 fixed-dark visual且無redesign | PASS | Tester |
| TC-04 | Inbox exact strings、compact hierarchy與static filter不變 | PASS | Tester |
| TC-05 | 六PR entry/time、workspace replacement不變 | PASS | Tester |
| TC-06 | #87 Overview exact content、0/1...7/8逐字progress與dynamic action labels | PASS | Tester |
| TC-07 | Four tabs、derived Overview progress/action transitions、8/8 Finish gate、no new surface/layout | PASS | Tester |
| TC-08 | Initial selected ordinal3但0/8 reviewed；current/reviewed indicators正交 | PASS | Tester |
| TC-09 | Files shortcuts、Mark idempotency、no-unreview、forward/wrap、last/full behavior | PASS（TE-04 revalidated） | Tester |
| TC-10 | Done removed；Finish/neutral back與Inbox invariants | PASS | Tester |
| TC-11 | Commits與Checks regression | PASS | Tester |
| TC-12 | Comment/composer/draft不改progress或navigation | PASS | Tester |
| TC-13 | Multi-PR state isolation、Overview↔Files↔Inbox保留、derived display與reload reset | PASS | Tester |
| TC-14 | No storage/network/domain/GitHub viewed write與scope/runtime hygiene | PASS | Tester |

## PC-05 TestCase Ledger — active contract

| ID | Adjusted scope | Status | Evidence owner |
| --- | --- | --- | --- |
| TC-01 | Baseline`8c2facf`；PC-05四artifacts、IM-05單一HTML、DL-04五tracked paths allowlists | PASS（TE-05）：目前status恰為四份artifacts＋單一HTML共五個tracked `M`；DL-04依其entry gate另行檢查 | Plan-Creator / Implementer / Tester / Reviewer |
| TC-02 | Offline/self-contained、zero network/storage、review/unreview reload reset | PASS | Tester |
| TC-03 | 1440 × 900 fixed-dark、native progress visual且無redesign | PASS | Tester / Reviewer |
| TC-04 | Inbox exact strings、compact hierarchy與static filter不變 | PASS | Tester |
| TC-05 | 六PR entry/time、workspace replacement不變 | PASS | Tester |
| TC-06 | #87 Overview exact content、numeric/native progress a11y、三態action/completion | PASS | Tester |
| TC-07 | Four tabs、derived transitions、8→7/1→0、no new surface/layout | PASS | Tester |
| TC-08 | Initial selected ordinal3但0/8 reviewed；current/reviewed indicators正交、no Files progress | PASS | Tester |
| TC-09 | Files footer三態、Mark forward/wrap、Unreview remove-only/focus、stale no-op、8→7/1→0 | PASS | Tester |
| TC-10 | Done removed；full completion/Finish/neutral back與Inbox invariants | PASS | Tester / Reviewer |
| TC-11 | Commits與Checks regression | PASS | Tester |
| TC-12 | Comment/composer/draft不改review/unreview progress或navigation | PASS | Tester |
| TC-13 | Multi-PR review/unreview/draft isolation、往返保留、derived display與reload reset | PASS | Tester |
| TC-14 | Prototype-local review/unreview、progress a11y、no product/storage/network/write/new UI與scope/runtime hygiene | PASS | Tester / Reviewer |

## Blockers

None for DL-04。RV-05已`approved`；仍須staged review與Human commit-message確認，之後才可由Implementer commit並bounded non-force push。

## Commit Gate

- Current：open。
- Reason：RV-05已明示`approved`，required/advisory findings均為none。
- Boundary：只有RV-05明示`approved`後才可進DL-04 staged review；Human確認commit message前不得commit，且只有Implementer可執行五path follow-up commit/non-force push。

## Human Check

- Historical HC-01：completed；Human decision為「調整」。
- Historical HC-02：completed；Human decision為「調整」。
- Current：HC-03 pending。
- Gate：只有RV-05`approved`且DL-04 completed才可進入。
- Required Human response：採用／調整／放棄。
- Boundary：不得自動建立或實作 SwiftUI topic。

## Verdict History

- Upstream conversation-only v4 contract review：`approved`；只作 PC-01 input，不是正式 artifacts 的 PR-01 verdict。
- PR-01：`needs-rework`；required fixes為 base push owner/routing與 untracked evidence。
- PR-02：`approved`；獨立 Plan-Reviewer 明示 verdict。
- TE-01：`approved`；TC-01～TC-14全部 PASS，無 severity issue。
- RV-01：`needs-rework`；唯一 Medium finding為 #142/#315/#54/#156 Reader time多出 `ago`，TC-05未完全成立；commit gate closed。
- TE-02：`approved`；bounded time mapping與指定 regression checks全部 PASS。
- RV-02：`approved`；required/advisory findings均為 none，commit gate open。
- HC-01：Human於2026-09-12選擇「調整」；舊approval不再放行新contract，commit gate重新closed。
- PC-03：completed；只表示四份artifacts已寫入與自檢，不是approval。
- PR-03：`needs-rework`；唯一required finding為Overview缺少三態皆可見、由reviewed set size推導的逐字progress；無需Human決策。
- PC-04：completed；只表示bounded artifact fix已寫入與自檢，不是approval。
- PR-04：`approved`；required/advisory findings均為none，PR-03 Overview progress finding已解除。
- IM-03：completed／ready-for-test；唯一HTML修改完成，Implementer回報reviewed progress、Finish/comment guards與static checks clean；未commit/push。
- TE-03：`approved`；Chrome 153 headed 1440 × 900 `file://`驗證TC-01～TC-14全數PASS，無runtime/network/storage/scope問題。
- RV-03：`needs-rework`；唯一Medium finding為reviewed current顯示disabled`Reviewed`並early return，且未reviewed label為`Mark as Reviewed`，違反統一enabled逐字`Mark Reviewed`及idempotent後仍搜尋next unreviewed的contract。
- IM-04：completed／ready-for-test；統一enabled`Mark Reviewed`、移除disabled/early return，並保留idempotent count後的forward/wrap/change0與8/8 Finish-only；static checks PASS。
- TE-04：`approved`；reviewed current enabled label、idempotent forward/wrap/change0、8/8 Finish-only及指定regression/status checks均PASS。
- RV-04：`approved`；required/advisory findings均為none，source與TE-04 evidence成立，exact five `M` paths且無redesign/scope drift；commit gate open。
- DL-03：completed；commit`8c2facf`恰含五個tracked modified paths，已bounded non-force push，local/upstream一致且worktree clean。
- HC-02：completed；Human選擇「調整」，要求prototype-local unreview、Files footer三態與Overview native progress；舊RV-04 approval不放行新contract。
- PC-05：completed；只表示四份artifacts已寫入與自檢，不是approval。
- PR-05：`approved`；required/advisory findings均為none。
- IM-05：completed／ready-for-test；HTML-only implementation與static checks完成，未commit/push。
- TE-05：`approved`；TC-01～TC-14全數PASS，代表性interaction、a11y、state isolation與runtime/scope evidence成立。
- RV-05：`approved`；required/advisory findings均為none，source與TE-05 evidence成立。
- DL-04：pending。
- HC-03：pending。

## Last Updated

2026-09-14
