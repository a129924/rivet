# GitHub REST method 契約需求

- Topic：`github-rest-client-method-contract`
- 責任歸屬：既有 non-BC `GitHubIntegration`
- 狀態：實作與獨立驗證已完成；Plan-Reviewer／Reviewer approved，等待已授權交付及 human review。
- 對應：[技術規格](technical-spec.md)、[執行契約](../../plan/github-rest-client-method-contract/github-rest-client-method-contract.plan.md)、[步驟帳本](../../plan/github-rest-client-method-contract/github-rest-client-method-contract.step.md)。

## 意圖與唯一結果

讓同一 target 的呼叫端透過可替換契約執行 GET／POST／PUT／PATCH，以 request builder 或完整 request 雙入口取得 raw response／既有 technical failure，並統一處理首次 HTTP 401 的最多一次 recovery。

這是既有 non-BC 的技術能力切片，不是新的 BC Mission。不宣稱交付建立 review、合併 PR、通知已讀、產品登入或其他 BC 業務能力。

## 範圍

包含 internal、Sendable、正式 client 與替身均可符合的八入口契約、四 methods 組裝、完整 request method 一致性、既有 GitHub URL guard、request-local Bearer、一次 401 replay、technical errors、取消行為、GET 相容調整及長期文件／既有圖表同步。

不包含 DELETE／HEAD／OPTIONS、stream body、跨 target 公開、BC Adapter／Port／DTO／failure mapping、產品寫入／UI、新 token 類型、credential lifecycle／Keychain／generic HTTP client 重構、新 package／BC、一般 retry／backoff／pagination／rate-limit policy、共通 headers／API-version policy。

## 已鎖定限制

- `GitHubRestClient` 為 internal，八入口完整 signatures 見技術規格；body 為可重播的 `Data?`。
- builder 的 headers／body 一律由 caller 明確傳入，包括 `HTTPHeaders()`／`nil`；沒有 default arguments 或其他 arity overload。
- provider 擁有 credential lifecycle、snapshot version 與 single-flight；client 擁有 HTTP status 判定及原始 request replay。
- 不修改 provider、GraphQL、generic HTTP runtime、BC 或 public API。
- 取消單一 caller 不取消 shared refresh，不保證 provider await 立即返回。
- 工具輔助限執行契約指定的 graphify 唯讀導航、既有圖表修訂與 PR Lens 本機 change map；不因此新增產品要求或 approval gate。

## Acceptance Criteria

| ID | 驗收條件 | 驗證對應 |
| --- | --- | --- |
| AC01 | 四 methods 均可透過 builder／完整 request 雙入口執行，method 符合意圖；八入口可由 existential 呼叫。 | TC01、TC02 |
| AC02 | method mismatch／非法 GitHub URL 在 credential acquisition／send 前回 `.invalidRequest`。 | TC03 |
| AC03 | 首次 HTTP 401 將實際用於首次發送的完整 snapshot 交給 provider。 | TC04、TC09 |
| AC04 | 每次 execution 最多追加一次發送，不進行一般 retry。 | TC04、TC05、TC06 |
| AC05 | replay 保留 method、URL、Data body 與其他 headers，只更換 Authorization。 | TC02、TC04、TC09 |
| AC06 | 第二次 HTTP 401 回 `.authenticationRequired`，無第三次發送。 | TC05 |
| AC07 | provider recovery failure 沿用既有分類，不再發送。 | TC07 |
| AC08 | 非 401 raw response 原樣回傳；timeout／transport failure 不 recovery／replay。 | TC06 |
| AC09 | 已觀察取消後，不開始後續 recovery／send；取消正規化為 `CancellationError`。 | TC08 |
| AC10 | 並發 recovery 沿用既有 snapshot／single-flight；late stale 401 不重複 refresh。 | TC09 |
| AC11 | caller 可注入替身，無需 GitHub 連線；明傳參數時使用替身 builder witness，預設 builder 委派 execution witness。 | TC01 |
| AC12 | 保留 GET regression，包括 body；不新增跨 target public 能力或 BC dependency。 | TC02、TC10、TC11 |

## 失敗、影響與回復

method／URL 不符直接拒絕；只有實際首次 HTTP 401 可 recovery。provider failure、第二 401、transport failure 與取消皆依既有邊界結束，不隱含第三次發送。

Domain invariant、資料持久化、BC Port 與公開能力不變。後續 Adapter 仍自行擁有 endpoint、DTO 與 BC failure mapping。本次可回復契約／client／tests／docs 變更，無資料遷移，不以真實 GitHub 寫入作為驗收。

## 授權與未決事項

無新增產品／架構決策。使用者已明確授權在 feature worktree 完成 topic，無重大問題時直接 topic commit、push、開 Draft PR，最後交 human review；這是交付動作授權，未擴張產品範圍。詳細角色、條件與 Human Check 見帳本。

目前沒有已知 scope／技術 blocker。工具 runtime 尚未驗證；其 fallback 與 evidence 依執行契約，不推論工具可用或驗證通過。
