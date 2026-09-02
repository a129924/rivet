# pr-reader-webview-diff-rendering

## Goal

在 PR Reader WebView surface 選定並加入 `diff2html` `^3.4.56` 作為未來 concrete diff pipeline 的 runtime dependency；接受 MIT license、direct dependencies `diff` 與 `@profoundlogic/hogan`，並同步 Bun lockfile。

## Non-Goal

不實作或 import parser、renderer、Output、DOM、UI、CSS、syntax highlighting、Swift bridge、GitHub mapping、viewed behavior、patch normalization 或 raw HTML injection；不改變 public contract、PR Reader BC 文件或 architecture。

## In-Scope

- 同 slug 四份 artifacts 的 dependency-only revision。
- 在 PR-05 明示 approval 後，新增 `surfaces/pr-reader-webview/package.json` 的 `dependencies.diff2html: "^3.4.56"` 與必要 Bun lockfile resolution。

## Out-Of-Scope

- 任一 TypeScript source、test、import、package script、其他 dependency、toolchain、CI、BC 文件或 diagram。
- 既有 dirty source、test 與 BC 文件變更；它們不得被修改、stage、commit 或視為本輪產出。

## ReadOnly

- 現有 contracts、tests、package scripts、Bun／TypeScript config、PR Reader BC 文件與本 topic evidence。
- 現有 manifest 與 lockfile，只用於確認最小 dependency diff。

## Written

- 本 topic 四份 planning artifacts。
- 僅在 IM-05 gate 後的 `surfaces/pr-reader-webview/package.json` 與 `surfaces/pr-reader-webview/bun.lock`。

## Deleted

無。

## Modify

- 本 revision 僅撤除「零依賴／不得改 package manifest 或 lockfile」限制，改為授權一筆已鎖定的 runtime dependency 與必要 Bun resolution。
- 既定 architecture、path、`DiffSnapshot`、Ports、Facade、viewed ownership、failure outcomes 與 declaration-only boundary 不變。

## TestCase

- manifest 只新增 `dependencies.diff2html: "^3.4.56"`，不新增 scripts、imports 或其他 direct dependencies。
- lockfile 可由 Bun frozen-lockfile install 重現 `diff2html` 與必要 resolution。
- Tester 執行 `bun run check`、`bun test`、`bun test:coverage` 與 `git diff --check`；若 package install 或既有 gate 失敗，回報明確 blocker。
- 本輪 authorized diff 只含 manifest 與 lockfile；source、test、BC 文件或 diagram diff 一律是 scope drift。

## Phase and Gates

1. **PC-05 / Plan-Creator**：修訂同 slug 四份 artifacts，記錄已鎖定 package admission。
2. **PR-05 / independent Plan-Reviewer**：檢查 package、license、direct dependencies、runtime placement、lockfile、scope isolation 與 contract 不變；只有明示 `approved` 可前進。
3. **IM-05 / independent Implementer**：僅修改 manifest 與 Bun lockfile。
4. **TE-05 / Tester**：執行 dependency 與既有 validation evidence。
5. **RV-05 / independent Reviewer**：審查最小 diff、scope isolation 與 validation evidence。
6. **GH-05 → HC-04**：在 RV-05 明示 `approved` 後依 human-authorized Git 流程 handoff，隨即停止於 human review。

## Acceptance and Stop Conditions

- Acceptance 需要 PR-05、TE-05、RV-05 各自的明示 verdict，且 implementation diff 僅為指定 manifest entry 與 lockfile update。
- PR-04 是已完成的歷史 revision，已被 dependency-only PC-05／PR-05 chain superseded，不得作為 IM-05 approval。
- 在 PR-05 approval 前不得修改 package；發現未鎖定 version、license exception、額外 dependency、source/test/BC diff、安裝失敗或 contract drift 時停止並交回相應角色或 human。
