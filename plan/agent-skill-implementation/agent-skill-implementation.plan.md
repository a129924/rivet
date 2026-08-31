# agent-skill-implementation

## Goal

將全部 21 個本地 Agent Skills 解耦為可獨立運作的能力；只有 `sdd-workflow-contract` 理解 SDD。其他 skills 僅依 caller 提供的最小 inputs、預期 output、直接限制／停止條件與直接授權工作。

## Non-Goal

不改 application code、release、post-merge、VERSION、summary、correction artifacts、tag lifecycle 或遠端 Git automation；不建立新 topic、worktree、branch 或 PR。

## In-Scope

- 更新既有四份 topic artifacts，記錄本次責任解耦 contract、PR fixes、兩項 rework constraints 與 gates。
- 依 technical spec Batch A–D 修正 13 個 skills，並保留八個 no-change skills。
- 依 Batch E 更新 `docs/design-principles.md` 的長期原則（含 SDD responsibility boundary）與 `.codex/skills/BUILD_MACOS_APPS_UPSTREAM.md` 的 local-overlay metadata；不改 upstream pin 或同步 vendored plugin。
- 驗證全部 21 個 skills，進行獨立 review，通過後才依 topic commit、push 既有 branch 並更新既有 draft PR。

## Out-Of-Scope

- 使每個 skill 預設理解 SDD、topic artifacts、`.step.md`、phase、verdict、其他角色、approval 或 Dispatcher routing。
- 用 general safety wording 取代各領域原有必要 safety contract，特別是 worktree destructive approval 與 commit human confirmation。
- 對既有 `sdd-workflow-contract` 改寫 SDD 內容；它保留為 SDD 專屬唯一真相。
- 任何其他 upstream plugin 更新、release／post-merge／tag lifecycle，或與本輪已列明 fixes 及 rework constraints 無關的 skill cleanup。

## ReadOnly

- Repository 規範、既有本 topic 四份 artifacts、21 個本地 skills 與其直接 references、`docs/design-principles.md` 與 `.codex/skills/BUILD_MACOS_APPS_UPSTREAM.md`。
- 上游 worktree-manager 結構（僅用於確認既有 lifecycle safety contract 不倒退）、`skill-creator` validator、Git／PR 狀態。

## Written

- 本 topic 的四份既有 planning artifacts。
- Batch A–D 列出的 13 個 skill `SKILL.md`，以及只有在 `worktree-manager` 需同步更新的直接 references。
- `docs/design-principles.md`。
- `.codex/skills/BUILD_MACOS_APPS_UPSTREAM.md`。

## Modify

- `build-run-debug`、`context-package-builder`、`git-branch-naming`、`git-commit-convention`、`handoff-routing-policy`、`plan-creator`、`plan-reviewer`、`plan-step-tracker`、`subagent-dispatch-policy`、`swiftui-patterns`、`telemetry`、`window-management`、`worktree-manager`。
- `docs/design-principles.md`、`.codex/skills/BUILD_MACOS_APPS_UPSTREAM.md`。

## Deleted

無檔案刪除。

## Implementation Changes

1. 依 Batch A 移除 context、dispatch、routing skills 的 SDD workflow 前提，改為處理 caller 明示資料與局部結果。
2. 依 Batch B 讓 planning／ledger skills 只依 caller 提供 contract 或 schema 工作，不固定任何 topic artifacts、role、phase、verdict 或 approval 語意。
3. 依 Batch C 將 Git／worktree skills 收斂到自身 Git responsibilities。`worktree-manager` 保持完整 lifecycle safety contract，但從角色／routing／planning 特化改為 caller authorization 與一般 shared-file coordination warning。
4. 依 Batch D 移除一般 Swift tooling skills 的強制 Git bootstrap 或唯一 run-path 假設，改用 caller 指定或既有 project entrypoint。
5. 不修改八個 no-change skills；不修改 `sdd-workflow-contract`，其既有 SDD contract 繼續只由該 skill 承擔。
6. 套用已界定 PR fixes 與兩項 rework constraints：修正已 attach branch 的 occupancy 語意、保護 macOS app relaunch、提供無 owner 的 branch-name fallback，並將 upstream/local overlay 與 SDD responsibility boundary 回寫為長期 design principle。非破壞性 release 不得被當作 branch 的 detach 或 reuse 前置動作；bootstrap 的 PID selector 零個匹配時繼續且不執行 `kill`，唯一匹配時才可停止該 PID，多重匹配時不執行 `kill`、停止並要求 human 提供明確唯一 selector 後重評。

## TestCase

- 每個修正 skill 都可在沒有 SDD repository、topic artifacts、`.step.md`、phase、verdict 或其他角色資訊時，依必要 caller inputs 完成自身工作或回報局部輸入不足。
- `context-package-builder` 不新增推論；`handoff-routing-policy` 不生成 result；`subagent-dispatch-policy` 不用 SDD readiness 或 Git lifecycle 選擇 specialist。
- `plan-creator`／`plan-reviewer` 只按 caller contract 工作；`plan-step-tracker` 只檢查 caller ledger schema，絕不將 checker 結果變成 approval。
- `git-branch-naming` 只建議名稱；`git-commit-convention` 只處理 staged diff、適用 commit convention 與 human confirmation；`worktree-manager` 仍正確停止於 destructive risk，且不自動 prune 或 delete。
- `build-run-debug`、`swiftui-patterns`、`telemetry`、`window-management` 不再強制 Git bootstrap 或特定 launch path。
- 已 attach branch 的 create 結果不建議以 release 釋放 occupancy；它保留既有 worktree 或要求新的 branch。`git-branch-naming` 在 owner 慣例缺失時回傳僅由 caller inputs 構成的 fallback。
- `build-run-debug` 的 relaunch 只在目標 process 與 launch method 可辨識時宣稱執行；否則回報局部輸入不足。PID selector 的零、唯一與多重匹配均有明確行為：零個匹配時繼續且不執行 `kill`，僅唯一匹配可 stop，多重匹配時不執行 `kill`、停止並要求 human 提供明確唯一 selector 後重評。`docs/design-principles.md` 同時明確表達本地 overlay 與 SDD responsibility boundary，upstream metadata 不改 upstream pin。
- 21 個 skills 均通過 `skill-creator` 的 `quick_validate.py`；獨立 Reviewer 對責任分離、Dispatcher boundary 和 Git/worktree boundary 給出 `approved` 才可進入 Git integration。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得修改 skills 或 Batch E 的兩個文件。
- 任一 skill 缺少其直接必要 input、authorization 或 destructive approval 時，只在該 skill 的 boundary 停止並回報原因。
- Tester validator 或 Reviewer 發現耦合、責任重疊或 safety regression 時，只回修相符的 Implementer scope；不得用 `.step.md` status、checkbox 或 tracker 結果放行。
- 未獲人類確認不得 commit；未獲直接授權不得 push 或更新 draft PR。
