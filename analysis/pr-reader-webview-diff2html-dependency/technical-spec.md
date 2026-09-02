# PR Reader WebView Diff2Html Dependency — Technical Spec

## Goal

為 future internal concrete diff stage 登錄 manifest range `diff2html: ^3.4.56` runtime dependency，不改變 base interface。

## Non-Goal

不定義或實作 parser、renderer、DOM、UI、CSS、highlight、raw HTML／security、patch format、Swift 或 GitHub mapping，亦不修改 `DiffSnapshot`、Ports、Facade 或 public contracts。

## In-Scope

- MIT license；manifest range `diff2html: ^3.4.56`；lock resolved `diff2html@3.4.56`。
- direct `diff@8.0.4`／`@profoundlogic/hogan@3.0.4`、optional `highlight.js@11.11.1`，以及必要 transitive `nopt@1.0.10`／`abbrev@1.1.1` 的 Bun resolution。

## Out-Of-Scope

- package import、source、tests、scripts、其他 dependencies、BC docs、architecture、toolchain、CI。
- package selection、version 與 license 的 long-term docs writeback；人類已鎖定本 topic 將其延後，不修改 docs／BC／architecture／toolchain。

## ReadOnly

- Base branch 所提供的 WebView interface 與 package configuration。

## Written

- 本 topic artifacts；PR-01 approval 後的 manifest 與 lockfile。

## Deleted

無。

## Modify

- manifest runtime `dependencies` 僅加入 range `"diff2html": "^3.4.56"`；Bun lockfile resolved exact package 與完整 admission tree。
- package 不得透過此 revision 宣稱 `patch?: string` 可直接被解析，library model 不得進入 public contracts。

## TestCase

- 檢查 manifest range `^3.4.56`、lock resolved `diff2html@3.4.56`、MIT 與 complete admission tree；不得將 manifest range 稱為 exact pin。
- 檢查 `bun install --frozen-lockfile`、最小 manifest／lockfile diff 與既有 Bun checks。
