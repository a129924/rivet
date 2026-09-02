# 暫定 Bounded Context Source Layout Baseline：技術規格

## Baseline Boundary

本 topic 僅確立已知責任可放置的檔案系統位置。它不承諾未來 SwiftPM target、module、依賴方向、interface、GitHub 資料形狀或 infrastructure feasibility。

## Written

### Planning Artifact Creation

僅可新建或更新：

- `analysis/bounded-context-source-layout-baseline/requirements.md`
- `analysis/bounded-context-source-layout-baseline/technical-spec.md`
- `plan/bounded-context-source-layout-baseline/bounded-context-source-layout-baseline.plan.md`
- `plan/bounded-context-source-layout-baseline/bounded-context-source-layout-baseline.step.md`

### Layout Implementation

僅可 create-only 接觸下列 directories：

- `Sources/`
- `Sources/BoundedContexts/`
- `Sources/BoundedContexts/PRInbox/`
- `Sources/BoundedContexts/PRReader/`
- `Sources/BoundedContexts/GitHubIntegration/`

僅可新建下列空白檔案：

- `Sources/BoundedContexts/PRInbox/.gitkeep`
- `Sources/BoundedContexts/PRReader/.gitkeep`
- `Sources/BoundedContexts/GitHubIntegration/.gitkeep`

Layout Implementation 開始後，除下列受限 ledger 維護例外外，四份 planning artifacts 全數為 ReadOnly。

### Local Dependency Preparation

在 feature worktree 的 `surfaces/pr-reader-webview/`，僅可執行 `bun install --frozen-lockfile`，以準備既有 renderer check 所需的本地 dependency。此動作只可建立 `.gitignore` 排除的 `node_modules/`；不得修改或提交 lockfile，亦不得將 `node_modules/` 納入 commit。

### PR Review Remediation Documentation

僅可修改下列既有 BC 文件，且每份只可加入一行暫定 source location baseline：

- `docs/architecture/bounded-contexts/pr-inbox.md`：`Sources/BoundedContexts/PRInbox/`
- `docs/architecture/bounded-contexts/pr-reader.md`：`Sources/BoundedContexts/PRReader/`
- `docs/architecture/bounded-contexts/github-integration.md`：`Sources/BoundedContexts/GitHubIntegration/`

該行必須明示不代表 Swift target、module、dependency 或 contract；不得修改 BC responsibility、Bounded Context Map、圖或既有 architecture/path decision。

## ReadOnly

- `AGENTS.md`
- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `requirements.md`、`technical-spec.md`、`bounded-context-source-layout-baseline.plan.md`
- `bounded-context-source-layout-baseline.step.md`，但僅適用下列受限 ledger 維護例外
- `.gitignore`，但僅在需檢查 `.gitkeep` 是否被忽略時讀取

## Post-Implementation Ledger Maintenance Exception

Human 明示授權後，僅 Plan-Creator 可在 Layout Implementation 後更新 `bounded-context-source-layout-baseline.step.md` 的：

- `Current Phase`
- 既有 Ledger steps 的 `status` 與 `validation evidence`
- `Blockers`
- `Last Updated`

每筆更新必須可追溯至已明示的上游角色結果。此例外不允許修改 `requirements.md`、BC/path、scope、Written、Deleted、Modify、acceptance 或 Human Check；也不得將 ledger 的 status 或 evidence 視為 approval、verdict、routing 或 gate pass。

## PR Review Planning-Artifact Amendment Exception

Human 已就 PR review 明示授權一次可追溯的 planning-artifact amendment。僅 Plan-Creator 可更新本 topic 的四份 artifacts，以記錄既已授權的三份 BC 文件 remediation、historical audit 與 delivery consistency；不得改變三 BC baseline、既定 paths、contract 或 C thread 的 non-actionable 結論。

`09043bf` 早於 REVIEW-002；此為 historical workflow deviation，必須如實記錄為未執行的 review gate，不得 backfill、rewrite history、force push，或宣稱該 commit 曾獲 REVIEW-002 核可。`94b6506` 的精確 gate mapping 由下列第二次 amendment 記錄。此 exception 本身不構成 approval、verdict 或 delivery 授權。

## Second Planning-Audit Amendment Exception

Human 已明示授權第二次、僅限四份 topic artifacts 的 planning-audit amendment。僅 Plan-Creator 可如實記錄：`94b6506` 早於 REVIEW-001，且 REVIEW-001 的歷史 verdict 為 `needs-rework`；`09043bf` 早於未執行的 REVIEW-002；`ed2bbcf` 早於未執行的 REVIEW-003。此 amendment 必須新增 ledger 的獨立 `verdict` 欄，且只有獨立角色明示的 `approved`、`needs-rework`、`blocked` 或 `human-check` 可填入；status、validation evidence 與 Tester 的 PASS 不得作為 verdict。它並建立 REVIEW-004 → DELIVERY-002 → HUMAN-002 新 gate。

此 exception 不允許修改其他檔案、重開三 BC、source paths、module 或 contract，亦不得 backfill、rewrite history 或 force push；它本身不構成 approval、verdict 或 delivery 授權。

## Third Planning-Audit Amendment Exception

Human 已明示授權第三次、僅限四份 topic artifacts 的 planning-audit amendment。僅 Plan-Creator 可如實記錄：`768f6be` 早於未執行的 REVIEW-004。該 commit 不得 backfill 為 REVIEW-004 已核可的 DELIVERY-002；REVIEW-004 必須保留為 `historical-deviation-not-run`，並由新的 REVIEW-005 → DELIVERY-003 → HUMAN-003 取代後續 gate。

此 exception 不允許修改其他檔案、重開三 BC、source paths、module 或 contract，亦不得 backfill、rewrite history 或 force push；它本身不構成 approval、verdict 或 delivery 授權。

## Fourth Planning-Audit Amendment Exception

Human 已明示授權第四次、僅限四份 topic artifacts 的 planning-audit amendment。僅 Plan-Creator 可如實記錄：`1b44fd0` 早於未執行的 REVIEW-005。該 commit 不得 backfill 為 REVIEW-005 已核可的 DELIVERY-003；REVIEW-005 必須保留為 `historical-deviation-not-run`，DELIVERY-003 與 HUMAN-003 必須標為 historical-superseded，並由 PLAN-011 → PLAN-012 → TEST-007 → REVIEW-006 → DELIVERY-004 → HUMAN-004 取代後續 flow。

此 exception 不允許修改其他檔案、重開三 BC、source paths、module 或 contract，亦不得 backfill、rewrite history 或 force push；它本身不構成 approval、verdict 或 delivery 授權。

## Deleted

無。不得刪除任何檔案或資料夾。

## Modify

允許修改的既有 tracked paths 僅為 `scripts/check-swift-format.sh` 與 PR Review Remediation Documentation 所列三份 BC 文件。Implementer 僅可將 formatter 的目錄 lint 呼叫調整為使用 `--recursive`，使既有 Swift formatter 對 `Sources/` 或 `Tests/` 下的目錄正確遞迴檢查；不得進行其他 formatter 行為、設定或 path 變更。三份 BC 文件僅可依該 section 的單行限制回寫。四次明示授權的 planning-artifact amendment 是唯一四份 topic artifacts 例外，且第四次僅可作本節所定 `1b44fd0` audit 記錄與新 flow。

除上述 path 外，不得修改既有檔案或既有資料夾內容；Planning Artifact Creation 只允許新增或更新 `Written` 所列的四份 artifacts。四次明示授權的 planning-artifact amendment 是唯一四份 topic artifacts 例外；第四次僅可作本節所定 `1b44fd0` historical audit 記錄與新 flow。

## Failure Boundary

任何未列入 `Written`、`Modify` 或 Local Dependency Preparation 的檔案、資料夾或行為需求，均為 scope drift，停止並交回 Dispatcher 判定。若 formatter 修正需要修改其他 tracked path、BC 文件回寫需要超出單行 baseline，或 dependency installation 變更 lockfile／產生可追蹤檔案，亦必須停止。此 topic 不定義或驗證 GitHub infrastructure，因此 infrastructure feasibility 不構成此 baseline 的實作前提。

## Hook Verification

- formatter 驗證必須確認目錄 lint 使用 `--recursive` 並成功完成。
- renderer check 必須在 frozen lockfile 的本地 dependency 準備後成功完成。
- 完整 pre-commit hook 必須成功完成；驗證前後 staged commit 範圍只可包含三個 `.gitkeep`、四份 topic artifacts 與 `scripts/check-swift-format.sh`。
- PR review remediation 驗證必須確認三份 BC 文件各僅有對應的一行暫定 source location，且明示不代表 target、module、dependency 或 contract；不得有 BC responsibility、Map、圖或 path decision drift。
- `94b6506` 早於 REVIEW-001，且 REVIEW-001 的歷史 verdict 為 `needs-rework`；`09043bf`、`ed2bbcf` 與 `768f6be` 分別早於未執行的 REVIEW-002、REVIEW-003 與 REVIEW-004。四者必須如實記錄為 historical workflow deviations。
- ledger 必須使用獨立 `verdict` 欄；只有獨立角色明示的 `approved`、`needs-rework`、`blocked` 或 `human-check` 可填入，未執行與非-verdict step 均為 `—`。status、validation evidence 與 PASS 不得作為 verdict。
- REVIEW-004 原定為 DELIVERY-002 的獨立 gate，但 `768f6be` 早於該 review；因此 REVIEW-004 與其後續 DELIVERY-002／HUMAN-002 均不得視為已獲授權或已完成。PR Inbox-only C thread 為與 Human 鎖定三 BC decision 衝突的 non-actionable finding。
- `768f6be` 早於未執行的 REVIEW-004，必須如實記錄為 historical workflow deviation；不得將它倒填為 DELIVERY-002 或宣稱 REVIEW-004 曾核可。原定的 REVIEW-005 → DELIVERY-003 → HUMAN-003 flow 已由第四次 amendment 取代，該 commit 僅可包含四份 topic artifacts，禁止 backfill、rewrite history 或 force push。
- `1b44fd0` 早於未執行的 REVIEW-005，必須如實記錄為 historical workflow deviation；不得將它倒填為 DELIVERY-003 或宣稱 REVIEW-005 曾核可。REVIEW-005、DELIVERY-003 與 HUMAN-003 均不得視為已獲授權或已完成。只有新的獨立 REVIEW-006 明示 `approved` 後，才可建立 DELIVERY-004、push 與已核可 thread resolution，並交還 HUMAN-004。該 commit 僅可包含四份 topic artifacts，禁止 backfill、rewrite history 或 force push。
