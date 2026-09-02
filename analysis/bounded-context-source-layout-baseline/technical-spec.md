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

## ReadOnly

- `AGENTS.md`
- `README.md`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/architecture/bounded-contexts/pr-reader.md`
- `docs/architecture/bounded-contexts/github-integration.md`
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

## Deleted

無。不得刪除任何檔案或資料夾。

## Modify

唯一允許修改的既有 tracked path 為 `scripts/check-swift-format.sh`。Implementer 僅可將目錄 lint 呼叫調整為使用 `--recursive`，使既有 Swift formatter 對 `Sources/` 或 `Tests/` 下的目錄正確遞迴檢查；不得進行其他 formatter 行為、設定或 path 變更。

除上述 path 外，不得修改既有檔案或既有資料夾內容；Planning Artifact Creation 只允許新增或更新 `Written` 所列的四份 artifacts。

## Failure Boundary

任何未列入 `Written`、`Modify` 或 Local Dependency Preparation 的檔案、資料夾或行為需求，均為 scope drift，停止並交回 Dispatcher 判定。若 formatter 修正需要修改其他 tracked path，或 dependency installation 變更 lockfile／產生可追蹤檔案，亦必須停止。此 topic 不定義或驗證 GitHub infrastructure，因此 infrastructure feasibility 不構成此 baseline 的實作前提。

## Hook Verification

- formatter 驗證必須確認目錄 lint 使用 `--recursive` 並成功完成。
- renderer check 必須在 frozen lockfile 的本地 dependency 準備後成功完成。
- 完整 pre-commit hook 必須成功完成；驗證前後 staged commit 範圍只可包含三個 `.gitkeep`、四份 topic artifacts 與 `scripts/check-swift-format.sh`。
