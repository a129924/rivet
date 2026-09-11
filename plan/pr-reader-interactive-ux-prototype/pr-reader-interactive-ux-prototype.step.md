# PR Reader 互動 UX 原型執行帳本

## Topic

- Slug：`pr-reader-interactive-ux-prototype`
- Primary BC：`PR Reader`
- Work branch：`codex/pr-reader-interactive-ux-prototype`
- Base branch：`codex/pr-inbox-static-visual-prototype`

## Current Phase

Delivery：RV-02已 completed／approved，commit gate open；HC-01維持 pending，等待 staged review／commit／push完成後交 Human。

## Planning Input

- Conversation-only v4 contract：上游已明示 Plan-Reviewer `approved`，作為 PC-01 寫入依據。
- 正式四份 artifacts：`PR-01` verdict為 `needs-rework`；required fixes已由 PC-02寫入，`PR-02` 已明示 `approved`。
- Base delivery prerequisite：`BP-01`，owner為 `Implementer`，status為 completed。上一 topic branch已完成 bounded non-force push並確認 remote/local HEAD；Observer/Dispatcher、Plan-Creator與 Reviewer未執行 push。

## Artifacts

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/pr-reader-interactive-ux-prototype/requirements.md` | present | 產品意圖、範圍、成功條件、Human Check |
| `analysis/pr-reader-interactive-ux-prototype/technical-spec.md` | present | locked fixtures、state、interaction、technical verification mapping |
| `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md` | present | 受限執行契約、allowlist、TC-01～TC-14、workflow |
| `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md` | present | phase、steps、evidence、verdict、blocker、Human Check |

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

- Status：pending
- Owner：Human
- Entry criteria：RV-02 明示 `approved`；其他狀態不得進入。
- Decision options：
  - 採用：只允許另開正式 SwiftUI topic，不自動實作。
  - 調整：回到本 topic 對應 planning/implementation phase。
  - 放棄：本 topic 結案。
- Verification evidence：pending Human 明示決策。
- Stop condition：到此必須停止自動前進，不得推論或代替 Human選擇。

## TestCase Ledger

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

## Blockers

None。RV-02已 completed／approved；delivery待 staged review／commit／push。

## Commit Gate

- Current：open。
- Reason：RV-02已明示 `approved`，required/advisory findings均為 none。
- Boundary：仍須完成 staged review並依 repository commit convention取得 Human確認；本 ledger紀錄不自行執行 commit/push。

## Human Check

- Current：pending
- Gate：RV-02已 `approved`；等待 staged review／commit／push delivery完成後交 Human。
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

## Last Updated

2026-09-11
