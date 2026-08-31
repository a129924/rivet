# Agent Skill Implementation — Requirements

## Goal

使 repository 內 21 個本地 Agent Skills 都能以完成自身工作所需的最小輸入、輸出與安全邊界獨立運作。SDD 是可選 workflow：僅 `sdd-workflow-contract` 可以定義或理解 SDD artifacts、phase、roles、verdict 與 human boundary。

## In Scope

- 完整審視並最小化 `.codex/skills/` 內 21 個本地 skills 的責任、輸入、輸出與停止條件。
- 將 SDD、topic artifacts、`.step.md`、phase、verdict、其他角色職責與 workflow gate 從非 SDD skills 移除；保留在 `sdd-workflow-contract`。
- 將 handoff 收斂為 caller 提供的明確任務、必要輸入、預期輸出、直接限制／停止條件與直接授權；不得傳遞整個 workflow 或無關 artifacts。
- 修正 13 個有耦合或不必要 bootstrap 假設的 skills：`build-run-debug`、`context-package-builder`、`git-branch-naming`、`git-commit-convention`、`handoff-routing-policy`、`plan-creator`、`plan-reviewer`、`plan-step-tracker`、`subagent-dispatch-policy`、`swiftui-patterns`、`telemetry`、`window-management`、`worktree-manager`。
- 保持八個無需修改的 skills：`appkit-interop`、`liquid-glass`、`packaging-notarization`、`sdd-workflow-contract`、`signing-entitlements`、`swiftpm-macos`、`test-triage`、`view-refactor`。
- 驗證全部 21 個 skills，並由獨立 Reviewer 審查責任分離、Dispatcher 邊界與 Git／worktree 邊界。
- 處理本輪 PR review 已明確界定的五項有界修正：abandoned worktree 的非破壞性 release evidence、stale Git registration 的 `prune-candidate` routing、completed worktree 在存在 unpushed commits 或為 current HEAD 所在 worktree 時拒絕 release、將 run-button bootstrap reference 明確列入 Written／Modify，以及主 `SKILL.md` 僅在需要 run-button bootstrap 時條件式連結該 reference。
- 更新 `docs/design-principles.md`，記錄本地 skill 維護原則與長期 SDD responsibility boundary：只有 `sdd-workflow-contract` 定義 SDD；其他 skills 維持可獨立運作，不將 SDD workflow 當成共同前提。
- 更新 `.codex/skills/BUILD_MACOS_APPS_UPSTREAM.md`，讓 upstream pin 與本地 overlay 可追溯而不將 overlay 假裝成 upstream 原文。
- 維護 `build-run-debug/references/run-button-bootstrap.md`，使 run-button bootstrap 的 PID selector 規則與主 skill 的 relaunch safety contract 一致。
- 修正 build/run bootstrap 的 PID selector safety：零個匹配時繼續且不執行 `kill`；唯一匹配時才可停止該 PID；多重匹配時不執行 `kill`、停止並要求 human 提供明確唯一 selector 後重評。

## Out Of Scope

- Application code、Bounded Context 實作、產品功能、release、post-merge、VERSION、summary、correction artifacts 或 tag lifecycle。
- Python、Swift、TypeScript 實作、TDD、測試框架或型別規範。
- 自動 commit、push、開 PR，或任何未獲直接授權的 Git／worktree mutation。
- 將 SDD workflow 變成所有 skill 的先決條件，或以防呆為由重複其他 skill 的責任。
- 擴張為 upstream plugin 升版、vendored skill 全量同步、release／post-merge／tag lifecycle，或任何與本輪已列明 PR fixes 及兩項 rework constraints 無直接關係的 cleanup。

## Success Criteria

- 除 `sdd-workflow-contract` 外，任何 skill 在沒有 SDD repository、topic artifact、`.step.md`、phase 或 verdict 的情況下仍可依 caller 輸入完成自身工作。
- 非 SDD skill 不自行產生、改寫、推導 verdict／approval，不把 checkbox、status 或 tracker 結果視為 approval，也不判斷其他角色的 gate 或 workflow 狀態。
- `context-package-builder` 只整理 caller 已提供的 context；`handoff-routing-policy` 只路由 caller 已明示的 result；`subagent-dispatch-policy` 只選擇單一適當 specialist。
- `plan-creator` 與 `plan-reviewer` 只依 caller 明確提供的 planning contract、documents、criteria 與 output format 工作，不假設固定 SDD artifacts 或 workflow。
- `plan-step-tracker` 僅檢查 caller 提供 ledger 的 schema／必要欄位／狀態完整性，不判斷證據真實性、不產生 approval 或 verdict、不取代 Tester／Reviewer。
- Git skills 不讀取 SDD artifacts 或 routing：`git-branch-naming` 只根據 caller 命名輸入建議名稱；`git-commit-convention` 只檢查 staged diff、適用 commit 規範並等待 human confirmation；`worktree-manager` 只處理自身 lifecycle、安全檢查與 destructive approval。
- `worktree-manager` 保持 create、get-worktree、release worktree、remove worktree 的完整 safety contract；release 不隱含刪除，remove 保留明確 human destructive approval 與既有 stop states，unmanaged worktree 預設 inspect-only，stale registration 僅標示 `prune-candidate`。
- 全部 21 個 skills 通過 validator，獨立審查沒有未解 blocker。
- 已 attach branch 的 worktree 不會被錯誤描述成可透過非破壞性 release 釋放 occupancy；create 結果明確保留既有 worktree 或改用新 branch 的 human 選擇。
- `build-run-debug` 在 relaunch 前確認目標 app/process，並以可辨識的既有 `.app` bundle 或 caller 指定 launch method 重新啟動；不以不明 process 或 raw GUI executable 假裝已 relaunch。PID selector 零個匹配時繼續且不執行 `kill`，唯一匹配時才可停止該 PID，多重匹配時停止並要求 human 提供明確唯一 selector 後重評，絕不直接 `kill` 全部匹配 PID。
- worktree lifecycle 對 completed、abandoned／paused 與 stale registration 的處理可分辨且可追溯：completed 僅在 clean、無 untracked、無 unpushed commits、非 current HEAD 所在 worktree，且 merged 或人類明示不需 merge 時可建議 release；abandoned／paused 需要保存 lineage、無 active mutation 與本次直接 release 授權；stale registration 僅回傳 `prune-candidate`，不得 auto-prune。
- 本輪五項修正可獨立驗證：abandoned worktree 具備所需 release evidence；stale registration 只回傳 `prune-candidate`；completed worktree 在 unpushed commits 或 current HEAD 情況拒絕 release；bootstrap reference 明確列於 Written／Modify；主 `SKILL.md` 僅在 run-button bootstrap 需要時連結該 reference。
- `git-branch-naming` 在 repository 沒有 owner 慣例時，能以 caller 已提供 type 與 work item 回傳 `<type>/<work-item>` fallback，而不捏造 owner。
- Build macOS Apps vendor metadata 明確區分 pinned upstream 與本地 overlay；`docs/design-principles.md` 包含不與單次 PR 綁定的長期維護原則，以及「僅 SDD contract skill 理解 SDD」的長期責任邊界。

## Recovery Baseline

既有 `v0.1.0-architecture-baseline` 是本 topic 的實作前回溯點。不得建立、移動或推送 tag 作為本次工作的一部分。
