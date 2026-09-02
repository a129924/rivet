# PR Reader WebView Diff2Html Dependency — Requirements

## Goal

登錄 `diff2html` `^3.4.56` 為 PR Reader WebView 的 runtime dependency，接受 MIT license、`diff`、`@profoundlogic/hogan` 與 Bun lock resolution。

## Non-Goal

不實作或 import parser、renderer、DOM、UI、CSS、syntax highlighting、raw HTML／security、patch format、Swift bridge、GitHub mapping，且不修改 base 提供的 `DiffSnapshot`、Ports、Facade 或其他 public contracts。

## In-Scope

- 在 PR-01 approval 後，僅將 `diff2html: ^3.4.56` 加入 WebView runtime `dependencies`，並更新 Bun lockfile。
- 驗證 manifest／lockfile 為唯一 product diff，且保留所有 base interface。

## Out-Of-Scope

- TypeScript source、tests、package imports、scripts、其他 dependencies、BC docs、architecture、toolchain 與 CI。

## ReadOnly

- Base branch 的 PR Reader WebView interface、package scripts、Bun config、package manifest 與 lockfile。

## Written

- 本 topic 四份 artifacts；實作 gate 後僅 package manifest 與 Bun lockfile。

## Deleted

無。

## Modify

- 不修改 base interface；僅在 implementation gate 後新增已鎖定 dependency entry 與必要 lock resolution。

## TestCase

- manifest 僅包含指定 runtime dependency；lockfile 可 frozen install 重現。
- `bun run check`、`bun test`、`bun test:coverage` 與 `git diff --check` 由 Tester 驗證。
