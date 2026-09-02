# pr-reader-webview-diff2html-dependency

## Goal

在 PR Reader WebView 登錄 manifest range `diff2html: ^3.4.56` runtime dependency，接受 MIT 與完整 Bun lock resolution；只依賴 base 的 interface，不修改或定義它。

## Non-Goal

不實作或 import parser、renderer、DOM、UI、CSS、highlight、raw HTML／security、patch format、Swift bridge、GitHub mapping；不改動 `DiffSnapshot`、Ports、Facade、public contracts、tests、BC docs、architecture、toolchain 或 CI。

## In-Scope

- 本 topic 四份 artifacts。
- PR-01 approval 後僅修改 `surfaces/pr-reader-webview/package.json` 與 `surfaces/pr-reader-webview/bun.lock`。

## Out-Of-Scope

- 任一 source、test、import、script、其他 dependency、base topic artifact 或文件圖。
- package selection、version 與 license 的 long-term docs writeback；人類已鎖定延後，故不改 docs／BC／architecture／toolchain。

## ReadOnly

- Base branch interface、manifest、lockfile、Bun config 與既有 validation commands。

## Written

- 本 topic artifacts；IM-01 後的 manifest 與 lockfile。

## Deleted

無。

## Modify

- manifest 僅新增 range `dependencies.diff2html: "^3.4.56"`；lockfile resolved `diff2html@3.4.56`、direct `diff@8.0.4`／`@profoundlogic/hogan@3.0.4`、optional `highlight.js@11.11.1` 與 `nopt@1.0.10`／`abbrev@1.1.1` necessary transitives。

## TestCase

- manifest range `^3.4.56`、lock resolved `diff2html@3.4.56` 與完整 admission tree；不得將 manifest range 驗證為 exact pin。
- `bun install --frozen-lockfile`、`bun run check`、`bun test`、`bun test:coverage`、`git diff --check`。
- implementation diff 僅可含 manifest 與 lockfile；其他 diff 一律 scope drift。

## Phase and Gates

1. **PC-01 → RV-01**：保留既有 dependency admission evidence；PC-02 correction chain 已凍結 GH-01／HC-01，即使 RV-01 approved 亦不得使用該 route。
2. **PC-02 / Plan-Creator**：修正 admission／evidence artifacts 與 workflow gate。
3. **PR-02 / independent Plan-Reviewer**：needs-rework 修正後重新審查 PC-02 artifacts。
4. **IM-02 / Implementer**：僅在 PR-02 明示 `approved` 後確認本 revision 不變更 product implementation。
5. **TE-02 / Tester → RV-02 / independent Reviewer**：依序驗證 artifact-only correction 與審查 evidence。
6. **GH-02 → HC-03**：僅在 RV-02 明示 `approved` 後進行 Git handoff，隨即停止於 human review。

## Acceptance and Stop Conditions

- PC-02 correction chain 只有在 PR-02、IM-02、TE-02、RV-02 依序取得所需明示 verdict／完成 evidence 後，才可走 GH-02 → HC-03；GH-01／HC-01 已 frozen。
- 任一 source、test、contract、BC／architecture diff，或未鎖定 version／dependency，均停止並交還相應角色或 human。
