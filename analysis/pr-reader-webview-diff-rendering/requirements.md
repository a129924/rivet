# PR Reader WebView Diff Rendering — Requirements

## Goal

在既有 PR Reader WebView diff rendering topic 選定並加入 `diff2html` `^3.4.56` 作為未來 concrete diff pipeline 的 runtime dependency；接受 MIT license、direct dependencies `diff` 與 `@profoundlogic/hogan`，並同步 Bun lockfile。

## In-Scope

- 將同 slug 四份正式 artifacts 修訂為 dependency-only scope，記錄已鎖定 package admission 與 phase gates。
- 僅在獨立 Plan-Reviewer 明示 `approved` 後，於 PR Reader WebView package manifest 加入 `diff2html: ^3.4.56` runtime dependency，並更新 Bun lockfile。

## Out-Of-Scope

- 任一 parser、renderer、Output、DOM、UI、CSS、syntax highlighting、Swift bridge、GitHub mapping、viewed behavior、patch normalization 或 raw HTML injection。
- 對 `DiffSnapshot`、`DiffViewModel`、Ports、Facade、public barrel、failure outcomes、PR Reader BC 文件或 architecture 的任何修改。
- 任一 TypeScript source 或 test、其他 package、toolchain、CI、diagram，及既有未提交 source、test、BC 文件變更。

## Success Criteria

- `diff2html` `^3.4.56` 是 PR Reader WebView 的唯一新增 runtime dependency；Bun lockfile 完整解析該 package 與必要 transitive resolution。
- 本輪 authorized product diff 僅為 package manifest 與 lockfile；既有 public contract、source、tests、BC 文件與 diagrams 不變。
- 既有 package validation commands 與 `git diff --check` 可由後續 Tester 驗證；任何環境 blocker 必須明確回報。

## Non-Goals

- 不以加入 dependency 宣稱已能解析、render 或顯示 GitHub-like diff。
- `patch?: string` 的 wire-format、binary／rename／missing patch handling、HTML security 與 DOM ownership 仍是後續獨立實作 topic 的風險，不在本 revision 定義。
