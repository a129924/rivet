# macOS Native Interaction Contract 需求

## Topic

- Slug：`macos-native-interaction-contract`
- Ownership：non-BC Presentation contract
- Work branch：`docs/macos-native-interaction-contract`
- Durable output：`docs/presentation/native-interaction-contract.md`
- Status：completed／adopted。實際路徑為PR-04 `approved` → IM-01 completed → TE-01 Overall FAIL → RV-01 `needs-rework` → IM-02 completed → TE-02 Overall PASS → RV-02 `approved` → HC-01 completed；Human decision原值為`採用`。Human另要求`Ready PR`，僅屬採用後delivery request，不授權或自動開始Swift implementation。

## Goal

在不重設計已採用 HTML workflow 的前提下，建立一份可由 Human 採用的 native macOS interaction contract，將 focus、presentation state、command routing、native container、window／resize、large diff navigation、accessibility 與 SwiftUI acceptance criteria 定義成可觀察、可追溯的行為，使後續 Swift implementation topic 不需自行發明 UX semantics。

## Non-Goals

- 不實作 SwiftUI、AppKit bridge、production source、tests、prototype 或產品功能。
- 不重開已採用的 Inbox → Reader → Files／Diff → Finish Reading workflow、reviewed/current 正交狀態或 Presentation Session ownership。
- 不改變 PR Inbox、PR Reader、GitHub Integration 或其他 Bounded Context 的責任邊界。
- 不定義 Domain／Application model、DTO、Entity、Value Object、Repository、UseCase、Service、Mapper、Protocol、networking、persistence、cache、retry、review progress calculation、ReadingSession、ReviewedBaseline 或 GitHub review submission。
- 不決定未來 Swift implementation topic 的 slug、branch、檔案路徑、型別、API 或 implementation steps。
- 不修改 HTML prototype；視覺 polish 不構成回修 baseline 的理由。

## In-Scope

- Focus State Machine：Inbox PR List、Reader Overview、Reader Tabs、File Navigator、Diff／Change Reader、Review Actions 與 Comment Composer 的進入、轉移、恢復及 keyboard loop。
- Inbox／Reader Presentation State Matrix：loading、content、empty（僅 Inbox）、error、offline with existing/readable content、offline without content，以及 chrome、content、selection、focus、action、recovery 與 accessibility announcement。
- Keyboard／Command Matrix：既有 Enter、Arrow、Option+Arrow、C、Escape、reviewed／unreviewed、Finish Reading、Back to Inbox 行為的 context 與 native menu／context-menu 對應。
- Native macOS Container Contract：sidebar、list、toolbar、tabs/navigation、file navigator、diff reader、context menus 與 menu commands 的原生互動語意。
- Window／Resize Contract：1440 × 900 preferred initial presentation、minimum useful window、half-window、narrow、column degradation、filename overflow、sidebar collapse 與 diff scrolling。
- Large Diff Navigation Contract：change／file navigation、Page Up／Page Down、system Space／Shift-Space（若沿用）、trackpad、scrollbar、reveal 與 Overview ↔ Files scroll restoration。
- Accessibility Contract：VoiceOver file/diff/state semantics、非色彩狀態辨識、局部 announcement、Increase Contrast、inactive window、Reduce Motion 與 keyboard-only operation。
- 後續 SwiftUI implementation 可直接驗證的 observable acceptance criteria。
- 當 Presentation 缺少 Logic 資訊時，以 `UI Input Requirement` 記錄輸入需求、呈現與缺值退化，不定義來源或計算方式。
- 未來 Swift implementation topic 的 admission schema：`Goal`、`Non-Goal`、`In-Scope`、`Out-Of-Scope`、`ReadOnly`、`Written`、`Modify`、`Deleted`、`TestCase`。

## Out-Of-Scope

- Production SwiftUI／AppKit implementation、Swift package／target、public API、protocol 或 source/test changes。
- HTML/CSS/JavaScript prototype、fixture、workflow、visual direction 或 interaction redesign。
- PR Inbox membership／sorting、PR Reader data、Presentation Mapper、Logic／Domain／Integration contract 或 cross-BC dependency。
- GitHub API、GitHubIntegration、OAuth、Keychain、HTTP、network、persistence、cache、storage、retry policy 或 viewed-state write。
- Review progress、ReadingSession、ReviewedBaseline、Approve／Request Changes、comment submission 或其他新 product capability 的 business semantics。
- Architecture canvas、workflow diagram、release、commit、push、PR、merge 或 review comment resolution。

## Confirmed Baseline

- `analysis/pr-reader-interactive-ux-prototype/requirements.md` 鎖定 Inbox 與 Reader 為互斥 workspace、四個 Reader tabs、Files/Diff keyboard flow、reviewed/current 正交狀態、可逆 reviewed progress、8/8 Finish gate 與 Presentation Session boundary。
- `analysis/pr-reader-interactive-ux-prototype/technical-spec.md` 的 Presentation State、Review Progress Contract、Workspace State Machine 與 Interaction Contract 是既有 interaction evidence；其 HTML-specific runtime 細節不升格為 native implementation detail。
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.plan.md` 的 TC-05～TC-14 證明已接受 workflow 的可觀察範圍；本 topic 只能補足 native readiness，不得重寫該 workflow。
- `plan/pr-reader-interactive-ux-prototype/pr-reader-interactive-ux-prototype.step.md` 的 HC-03 記錄 Human 於 2026-09-15 明示原值 `採用`；該決策只允許另開正式 SwiftUI topic，不自動授權 Swift implementation。
- 使用者提供的 `Draft Plan — Rivet macOS Native Interaction Contract` 是本 topic 完整 UI/UX `SHOULD FIX` 來源；其 Mission、scope、boundary、deliverables、review gate 與 Definition of Done 均須映射至 durable output。

## Success Criteria

- Durable output 清楚聲明 non-BC Presentation ownership，且沒有改變 PR Inbox、PR Reader 或 Presentation Session 的既定責任。
- Focus State Machine 覆蓋所有七個 focus regions與F-01～F-17；每個 transition均鎖定唯一destination與destination失效時的唯一fallback，並明示Reader tabs進入Overview／Files／Commits／Checks內容、Diff Reader ↔ Review Actions的標準keyboard focus traversal，以及Mark Reviewed後不中斷的keyboard loop。
- Inbox 與 Reader matrices 完整覆蓋 Draft 指定 state，並將 `empty` 視為成功狀態；offline／error 不無條件清除可保留的 selection 或 progress。
- Command Matrix 對每個既有 command 定義 context、enabled／disabled、conflict、menu counterpart 與必要時的 context-menu counterpart；文字輸入、composer 與 VoiceOver 不被 Reader shortcut 攔截。
- Native container、resize、large diff、accessibility 與 SwiftUI acceptance criteria 均以 observable behavior 表達，不預先指定不必要實作細節。
- 所有 Logic 缺口只形成 `UI Input Requirement`，不引入 model、API、儲存或計算決策。
- 每一份 SwiftUI acceptance criterion 皆能追溯至已採用 baseline或 Draft contract section。
- Durable output 完成後經 Tester 與獨立 Reviewer；Reviewer 明示 `approved` 後停止於 Human Review，不自動開始 Swift implementation。

## Deliverables

- 唯一 durable output：`docs/presentation/native-interaction-contract.md`。
- 文件必須包含：baseline／ownership、normative language、Focus State Machine、Inbox／Reader Presentation State Matrix、Command Matrix、Native Container、Window／Resize、Large Diff Navigation、Accessibility、UI Input Requirement boundary、SwiftUI acceptance criteria、future Swift topic admission schema 與 traceability index。
- 四份 planning artifacts 只作本次 execution contract；不得被當成 durable native interaction truth。

## Future Swift Topic Admission Requirement

未來 Swift implementation topic 在進入 Plan-Reviewer 前，四份同 slug planning artifacts 必須明示：

- `Goal`：單一、可觀察、可驗收的 native implementation outcome。
- `Non-Goal`：明示不重設計 workflow、不重開已採用 contract、不順帶實作其他 layer。
- `In-Scope`：唯一 bounded capability；不得將多個可獨立驗收能力綁成一個 topic。
- `Out-Of-Scope`：其他 BC、Logic、Integration 與 deferred capability。
- `ReadOnly`：可讀但禁止修改的 exact repository-relative existing file paths。
- `Written`：允許新增的 exact repository-relative file paths；沒有時填 `None`。
- `Modify`：允許修改的 exact repository-relative existing file paths；沒有時填 `None`。
- `Deleted`：允許刪除的 exact repository-relative existing file paths與理由；預設 `None`。
- `TestCase`：具穩定 ID、trigger／context、observable expected result、evidence 與 adopted contract trace。

`ReadOnly`、`Written`、`Modify`、`Deleted` 必須互斥；不得使用 glob、directory-only scope、`相關檔案`、`必要時`或其他模糊 path。若 slug、capability、ownership 或 exact paths 未鎖定，該 future topic 必須回報 `blocked`，不得猜測 branch 或 implementation scope。

## Human Review Gate

只有最新獨立Reviewer明示 `approved` 才可進入 HC-01。實際執行中，RV-01明示`needs-rework`後只回Implementer完成IM-02，經TE-02 Overall PASS後由RV-02明示`approved`，因此HC-01 entry gate成立。Human Review 只判斷：

1. Focus workflow 是否完整。
2. Presentation states 是否完整。
3. 是否仍有 interaction ambiguity。
4. 是否符合已採用 HTML baseline。
5. 是否擴張 product workflow。
6. 是否越界進 Logic／Domain／Integration。
7. Acceptance criteria 是否足以讓後續 SwiftUI implementation 不自行猜測 UX。

Human decision 只可為：

- `採用`：本 topic 結案；只允許另開正式 Swift implementation topic。
- `調整`：回到本 topic 的 planning／documentation implementation flow並重新驗證／審查。
- `放棄`：本 topic 結案，不建立 downstream implementation topic。

HC-01已completed，Human decision原值為`採用`；本topic completed／adopted。後續`Ready PR`只處理本topic delivery，不改變Human outcome、Reviewer verdict或future Swift boundary。

## Last Updated

2026-09-16
