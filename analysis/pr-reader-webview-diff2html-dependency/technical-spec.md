# PR Reader WebView Diff2Html Dependency — Technical Spec

## Goal

為 future internal concrete diff stage 登錄 `diff2html` `^3.4.56` runtime dependency，不改變 base interface。

## Non-Goal

不定義或實作 parser、renderer、DOM、UI、CSS、highlight、raw HTML／security、patch format、Swift 或 GitHub mapping，亦不修改 `DiffSnapshot`、Ports、Facade 或 public contracts。

## In-Scope

- `diff2html` `^3.4.56`、MIT、direct `diff`、`@profoundlogic/hogan` 與 Bun lock resolution。

## Out-Of-Scope

- package import、source、tests、scripts、其他 dependencies、BC docs、architecture、toolchain、CI。

## ReadOnly

- Base branch 所提供的 WebView interface 與 package configuration。

## Written

- 本 topic artifacts；PR-01 approval 後的 manifest 與 lockfile。

## Deleted

無。

## Modify

- manifest runtime `dependencies` 僅加入 `"diff2html": "^3.4.56"`；Bun lockfile 僅加入必要 resolution。
- package 不得透過此 revision 宣稱 `patch?: string` 可直接被解析，library model 不得進入 public contracts。

## TestCase

- 檢查 exact version、license／direct dependencies、最小 manifest／lockfile diff、frozen install 與既有 Bun checks。
