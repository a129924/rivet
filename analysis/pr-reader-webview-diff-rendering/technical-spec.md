# PR Reader WebView Diff Rendering — Technical Spec

## Locked Decisions

- 新增 runtime dependency 僅為 `diff2html` `^3.4.56`；接受其 MIT license 與 direct dependencies `diff`、`@profoundlogic/hogan`，並由 Bun 更新 lockfile。
- 本 revision 不新增 package import 或 concrete Adapter、Validator、Parser、Renderer、Output、DOM、UI、CSS、syntax highlighting、Swift bridge 或 GitHub mapping。
- 現有 `DiffSnapshot`、`DiffViewModel`、Viewed-state ownership、stage results、Ports、UseCase、Facade、public barrel 與 PR Reader BC 邊界維持不變。
- `diff2html` 僅記錄為未來 internal concrete parser／renderer candidate；它不得洩漏進 public contracts，也不構成目前 `patch?: string` 能直接解析的承諾。

## Allowed File Changes

- Plan-Creator 僅修訂本 topic 四份 artifacts。
- 經 PR-05 approval 的 Implementer 僅可修改 `surfaces/pr-reader-webview/package.json` 與 `surfaces/pr-reader-webview/bun.lock`。
- 不刪除檔案；既有 dirty source、test 與 BC 文件變更不是本 revision 產出，禁止納入 stage、commit 或驗收。

## Package Contract

```json
{
  "dependencies": {
    "diff2html": "^3.4.56"
  }
}
```

- `diff2html` 必須位於 runtime `dependencies`，不新增 scripts、peer dependencies、dev dependencies 或其他 direct package。
- Bun lockfile 必須可重現已鎖定 package 及其必要 resolution；本 topic 不為 transitive dependency 定義額外 public API 或 behavior。

## Validation

- 檢查 manifest 僅加入指定 runtime dependency，lockfile 僅反映所需 dependency resolution，且本輪 diff 不包含 source、test、BC 文件或 diagram。
- Tester 執行 frozen-lockfile install、既有 `bun run check`、`bun test`、`bun test:coverage` 與 `git diff --check`；不能執行時回報可重現 blocker，不自行改變 scope。
