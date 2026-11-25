# PR Reader 單一 PR raw unified diff 需求

Topic 為 `pr-reader-github-raw-unified-diff`。Human 核定獨立 diff Adapter、先驗證標頭再接線、離線驗收及本機審閱交付。

## 使用情境與範圍

持有 `ReaderPullRequestID` 與可讀取該 PR 的 GitHub REST client 的套件呼叫端，需要取得 GitHub.com 為指定 PR 提供的整份 raw unified diff。Adapter 交付原始 GitHub response body，失敗時交付既有 `PRReaderFailure`。範圍包含 diff 專用固定標頭、獨立讀取入口、受控驗收及兩份長期契約回寫。

Diff 解析與渲染、逐檔 patch 補抓、快照與 UI 接線、大型 diff 分段、通用媒體型別框架、live GitHub 驗收與資料遷移在範圍外。

## 成功條件

- 同一 PR 的 diff 與背景 JSON 請求使用同一 GET 路徑，並各帶一個不同的 `Accept`。先驗證兩種標頭組合，再接 diff Adapter。
- 成功結果以 `Data` 交付，與 `HTTPResponse.body` 逐位元組相同。
- `406`、權限拒絕與取消依既有 Reader failure 契約交付。使用受控 REST client 從正式套件入口重現行為，並回歸一般 REST 標頭。
- 依 [執行計畫](../../plan/pr-reader-github-raw-unified-diff/pr-reader-github-raw-unified-diff.plan.md) 記錄 RD01–RD04 與本機審閱證據。

## Endpoint family

Rivet API Catalog 的 **REST PR Reader → Unified Diff** 對應 GitHub REST 的 **Pull requests → Get a pull request**。Diff 與背景 JSON 共用 `GET /repos/{owner}/{repo}/pulls/{pull_number}`，分別選擇 `application/vnd.github.diff` 與 `application/vnd.github+json`。GitHub 列出 `406`，Reader 將它視為當次內容無法取得。 [Rivet API Catalog](../../docs/github-api/rest-pr-reader.md#unified-diff) · [GitHub REST 文件](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)

[技術規格](technical-spec.md)
