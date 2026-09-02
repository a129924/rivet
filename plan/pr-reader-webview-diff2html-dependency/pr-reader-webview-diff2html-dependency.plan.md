# pr-reader-webview-diff2html-dependency

## Goal

在 PR Reader WebView 登錄 `diff2html` `^3.4.56` runtime dependency，接受 MIT、`diff`、`@profoundlogic/hogan` 與 Bun lock resolution；只依賴 base 的 interface，不修改或定義它。

## Non-Goal

不實作或 import parser、renderer、DOM、UI、CSS、highlight、raw HTML／security、patch format、Swift bridge、GitHub mapping；不改動 `DiffSnapshot`、Ports、Facade、public contracts、tests、BC docs、architecture、toolchain 或 CI。

## In-Scope

- 本 topic 四份 artifacts。
- PR-01 approval 後僅修改 `surfaces/pr-reader-webview/package.json` 與 `surfaces/pr-reader-webview/bun.lock`。

## Out-Of-Scope

- 任一 source、test、import、script、其他 dependency、base topic artifact 或文件圖。

## ReadOnly

- Base branch interface、manifest、lockfile、Bun config 與既有 validation commands。

## Written

- 本 topic artifacts；IM-01 後的 manifest 與 lockfile。

## Deleted

無。

## Modify

- manifest 僅新增 `dependencies.diff2html: "^3.4.56"`；lockfile 僅含必要 resolution。

## TestCase

- frozen-lockfile install、`bun run check`、`bun test`、`bun test:coverage`、`git diff --check`。
- implementation diff 僅可含 manifest 與 lockfile；其他 diff 一律 scope drift。

## Phase and Gates

1. **PC-01 / Plan-Creator**：建立四份 artifacts。
2. **PR-01 / independent Plan-Reviewer**：審查 scope、package admission、base-interface isolation 與 gates。
3. **IM-01 / Implementer**：僅新增 manifest dependency 與 Bun lock resolution。
4. **TE-01 / Tester**：執行 dependency 與既有 validation。
5. **RV-01 / independent Reviewer**：確認最小 implementation diff 與 validation evidence。
6. **GH-01 → HC-01**：RV-01 approval 後的 Git handoff，隨即停止於 human review。

## Acceptance and Stop Conditions

- 需要 PR-01、TE-01、RV-01 的明示 approval；implementation diff 僅為指定 manifest／lockfile。
- 任一 source、test、contract、BC／architecture diff，或未鎖定 version／dependency，均停止並交還相應角色或 human。
