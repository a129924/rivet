# 暫定 Bounded Context Source Layout Baseline

## Goal

建立可被 Git 追蹤、但不含行為的最小 Swift source layout，讓三個既有 Bounded Context 各自擁有 source location。

## Non-Goal

不驗證或實作 GitHub infrastructure；不建立 Swift code、SwiftPM target、product、module、tests、interface 或 cross-BC contract；不調整 BC Map，亦不將 `Presentation Session` 建為 BC。

## In-Scope

- `PRInbox`、`PRReader`、`GitHubIntegration` 三個空白 BC layout folders，以及各自唯一的 `.gitkeep`。
- 本 topic 的四份正式 planning artifacts。
- 僅修正 `scripts/check-swift-format.sh` 的目錄 lint 為 `--recursive`，讓既有 pre-commit gate 可正確檢查本 topic 的 source directories。
- 在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile`，僅準備既有 renderer check 所需的本地、ignored dependency。
- 僅為 PR review remediation，在三份既有 BC 文件各加入對應的一行暫定 source location baseline；明示不代表 target、module、dependency 或 contract。
- layout 完成後由獨立 Reviewer 驗證；其明示核可後執行已授權的 topic delivery actions，然後交還 human review。

## Out-Of-Scope

- `Package.swift`、所有 Swift source、測試、GitHub API feasibility 實驗。
- 新增、重命名或調整 Bounded Context、source target、module、依賴方向、資料契約或 failure contract。
- 修改圖、README、`AGENTS.md` 或 `.gitignore`，以及三份明列 BC 文件以外的架構文件。
- 變更任何 BC responsibility、Bounded Context Map、architecture path decision 或圖。
- 任何產品 Swift 行為、BC contract、SwiftPM target、product、module 或 GitHub integration。
- 修改 `scripts/check-swift-format.sh` 以外的既有 tracked path，或提交 lockfile、`surfaces/pr-reader-webview/node_modules/` 或其他本地 dependency 產物。
- 未經新的獨立 REVIEW-004 明示 `approved` 的 audit-correction commit、push、PR thread resolution、release，或進入下一個產品 slice。
- 本次 PR review 已明示授權的三份既有 BC 文件回寫為既有 remediation 例外；不得據此修改其他架構文件或改變既定三 BC baseline。
- `94b6506` 早於 REVIEW-001，且 REVIEW-001 的歷史 verdict 為 `needs-rework`；`09043bf` 與 `ed2bbcf` 分別早於未執行的 REVIEW-002 與 REVIEW-003。不得倒填、改寫、force push 或宣稱任一 commit 曾獲相應 review 核可。後續 DELIVERY-002 必須在新的獨立 REVIEW-004 明示 `approved` 後才可執行。

## ReadOnly

Layout Implementation 僅可讀取 `AGENTS.md`、`README.md`、設計原則、架構、本 topic planning artifacts、`scripts/check-swift-format.sh`、既有 renderer check 與必要時的 `.gitignore`。`requirements.md`、`technical-spec.md` 與本 plan 在 Layout Implementation 開始後一律為 ReadOnly；Human 明示授權的 PR review planning-artifact amendment 是唯一例外，且僅可記錄既已授權 remediation、historical audit 與 delivery consistency。

Human 明示授權後，僅 Plan-Creator 可受限更新 `.step.md` 的 `Current Phase`、既有 Ledger steps 的 `status` 與 `validation evidence`、`Blockers`、`Last Updated`。每筆更新必須可追溯至已明示的上游角色結果；不得改變 BC/path、scope、Written、Deleted、Modify、acceptance 或 Human Check，亦不得將 ledger status/evidence 視為 approval、verdict、routing 或 gate pass。

## Written

Plan-Creator 只可建立或更新本 topic 四份 artifacts。Human 明示授權的 PR review planning-artifact amendment 僅可記錄既已授權的 BC-document remediation、historical audit 與 delivery consistency；第二次 amendment 僅可如實記錄三個 commit 越過的 review gate、加入獨立 `verdict` 欄並建立 REVIEW-004 → DELIVERY-002 → HUMAN-002；不得重新定義三 BC baseline、paths 或 contracts。Implementer 只可 create-only 接觸：

- `Sources/`
- `Sources/BoundedContexts/`
- `Sources/BoundedContexts/PRInbox/.gitkeep`
- `Sources/BoundedContexts/PRReader/.gitkeep`
- `Sources/BoundedContexts/GitHubIntegration/.gitkeep`

三個 `.gitkeep` 必須空白。

為準備既有 renderer check，Implementer 只可在 feature worktree 的 `surfaces/pr-reader-webview/` 執行 `bun install --frozen-lockfile`；它只可建立被 `.gitignore` 排除的本地 `node_modules/`，不得修改或提交 lockfile，亦不得提交任何 dependency 產物。

PR review remediation 時，Implementer 僅可在下列三份文件各加入一行對應 source location baseline：

- `docs/architecture/bounded-contexts/pr-inbox.md` → `Sources/BoundedContexts/PRInbox/`
- `docs/architecture/bounded-contexts/pr-reader.md` → `Sources/BoundedContexts/PRReader/`
- `docs/architecture/bounded-contexts/github-integration.md` → `Sources/BoundedContexts/GitHubIntegration/`

每行必須明示不代表 target、module、dependency 或 contract；不得改動 BC responsibility、Map、圖或既有 architecture/path decision。

## Deleted

無；不得刪除任何檔案或資料夾。

## Modify

允許修改的既有 tracked paths 僅為 `scripts/check-swift-format.sh` 與三份明列 BC 文件。formatter 僅可將既有目錄 lint 調整為使用 `--recursive`；BC 文件僅可加入上述單行 baseline；不得變更其他 formatter 行為、設定、path、BC responsibility、Map 或圖。兩次 Human 明示授權的 planning-artifact amendment 是上述限制的唯一 artifacts 例外；第二次僅可記錄三個 historical deviations、獨立 verdict 與 REVIEW-004 → DELIVERY-002 → HUMAN-002，不得改變 scope 或 contract。

## TestCase

- 四份 planning artifacts 在 Layout Implementation 前已建立；實作 phase 不改動 `requirements.md`、`technical-spec.md` 或本 plan。兩次 Human 明示授權的 planning-artifact amendment 是唯一例外；第二次僅可如實記錄三個 historical deviations、獨立 verdict 與 REVIEW-004 → DELIVERY-002 → HUMAN-002；`.step.md` 僅可依明示 human 授權更新。
- 三個指定 `.gitkeep` 存在、空白，且在正確的 BC directory。
- `Sources/BoundedContexts/` 只含 `PRInbox`、`PRReader`、`GitHubIntegration`；每個 directory 只含 `.gitkeep`。
- 不存在 `PresentationSession` 或其他未確認 BC directory，亦沒有 Swift source、target、module、test 或 contract。
- Layout Implementation 不寫入、修改或刪除任何未列入 `Written`、`Modify` 或本地 dependency 準備例外的 repo path。
- `scripts/check-swift-format.sh` 的目錄 lint 使用 `--recursive`，formatter 成功完成。
- 在 `surfaces/pr-reader-webview/` 執行 frozen lockfile install 後，renderer check 與完整 pre-commit hook 成功完成；install 不變更 lockfile，且 `node_modules/` 維持 ignored、未追蹤。
- 原始 staged delivery 範圍只包含三個 `.gitkeep`、四份 topic artifacts 與 `scripts/check-swift-format.sh`；既授權 remediation commit 才另含三份 BC 文件的受限單行回寫。
- remediation commit 的範圍僅新增三份 BC 文件的受限單行回寫與 audit correction；三份文件均不可出現 responsibility、Map、圖、target、module、dependency 或 contract drift。
- 如實記錄 `94b6506` 早於 REVIEW-001，且 REVIEW-001 的歷史 verdict 為 `needs-rework`；`09043bf` 與 `ed2bbcf` 分別早於未執行的 REVIEW-002 與 REVIEW-003。不得倒填、宣稱 prior approval、rewrite history 或 force push。C thread 的 PR Inbox-only 要求是與 Human 鎖定三 BC decision 衝突的 non-actionable finding。
- ledger 使用獨立 `verdict` 欄：只有獨立角色明示的 `approved`、`needs-rework`、`blocked` 或 `human-check` 可填入；未執行與非-verdict steps 均為 `—`，status、validation evidence 與 PASS 不得作為 verdict。
- 第二次 planning-audit amendment 完成後，PLAN-008 必須明示 `approved`，TEST-005 必須獨立驗證 artifacts audit consistency；新的獨立 REVIEW-004 明示 `approved` 前，不得進行 DELIVERY-002 commit、push 或 PR thread resolution。
- DELIVERY-002 僅可包含本次 planning-audit amendment 的四份 topic artifacts；不得變更既有 commits、BC 文件、source layout 或其他 tracked path。
- 獨立 Reviewer 確認沒有 scope、contract 或 workflow drift。

## Stop Conditions

- hook 修正需要寫入 `scripts/check-swift-format.sh` 以外的 tracked path。
- dependency install 改變 lockfile，或產生可追蹤檔案。
- formatter、renderer check、pre-commit 或獨立 Tester／Reviewer 回報 scope、contract 或 workflow drift。
- 三份 BC 文件的回寫無法維持單行 baseline 限制。
- planning amendment 未獲獨立 Plan-Reviewer 明示核可。
- 第二次 planning-audit amendment 未經 PLAN-008 明示 `approved`，或 TEST-005 未完成驗證、REVIEW-004 未明示 `approved`。

## Human Check Gate

既有 PR review remediation 與第三次 audit-correction delivery皆為歷史；僅可在第二次 planning-audit amendment 經獨立 PLAN-008 與 REVIEW-004 明示 `approved`，並由 TEST-005 完成驗證後，建立 DELIVERY-002 commit、push branch 並處理已核可的 PR threads。不得重做、改寫或 force push `94b6506`／`09043bf`／`ed2bbcf`；完成 DELIVERY-002 後停止於 HUMAN-002 human review，不得 merge、release 或進入下一個產品 slice。
