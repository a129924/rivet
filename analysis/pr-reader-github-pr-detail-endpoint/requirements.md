# PR Reader GitHub PR 詳情端點需求

Topic `pr-reader-github-pr-detail-endpoint`。PR Reader 是本次能力的主責 Bounded Context。

## 目的

呼叫端提供 `ReaderPullRequestID` 與已認證的 `GitHubRestClient`。Reader Infra 以 GitHub REST 取得指定 PR 的標題、描述與作者，交付 `ReaderBackground` 供同一 Swift package 的後續快照組裝。此切片可獨立驗收參數化路徑、JSON 轉換及 Reader failure。 [Reader 資料契約](../../docs/architecture/bounded-contexts/pr-reader.md#core-content-source-contract) · [REST PR Reader 盤點](../../docs/github-api/rest-pr-reader.md#pull-request-detail)

## 範圍

- Reader Infra 擁有 `GET /repos/{owner}/{repo}/pulls/{pull_number}` 的路徑、端點及回應轉換。GitHubIntegration 提供既有目的地、標頭、認證及 REST 執行能力。
- Reader Infra 在送出前拒絕無法安全組成路徑的識別。可讀的詳情回傳背景資料，合法的描述與作者缺值得以呈現。PR 無法讀取、暫時失敗與必要資料無法轉換，各自沿用既有 Reader failure。
- 完整快照與 `PRContentSource` 的實作、討論、reviews、checks、Changed Files、Unified Diff、GraphQL、Reader UI、公開 library product、即時 GitHub 驗收、資料遷移及發布皆在本次交付範圍外。

## 驗收

- 端點以獨立預期值驗證 GET、完整 HTTPS URL、路徑參數及無 query，覆蓋無效識別。
- 受控 REST 回應走完識別至背景或 Reader failure。驗證有效流程一次呼叫、無效識別零次呼叫、實際交給 client 的 headers 與空 body，以及資料、失敗和取消。
- 保持 Reader Core 與 Infra 的 target 隔離。已交付能力及其責任回寫 Reader BC 文件。程式碼與文件可直接回退。
- 若必須改動公開 Reader 契約、放寬 REST 目的地或提前交付部分快照，停在 Human Check。

- [技術規格](technical-spec.md)
- [執行計畫](../../plan/pr-reader-github-pr-detail-endpoint/pr-reader-github-pr-detail-endpoint.plan.md)
