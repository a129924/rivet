# PR Inbox 自查 REST Endpoint 需求

Topic 為 `pr-inbox-rest-endpoints`，基線為 `b7dac7e`。登入 probe 與 Inbox 曾各自組裝 `GET /user`，Inbox 首頁組裝及 Link 驗證則各有一份搜尋條件。

- 登入與 Inbox 共用固定 `GET /user` 的具名 Endpoint。OAuth／PAT 仍以候選 token 驗證帳號後才保存。
- Inbox 依有效登入名使用具名搜尋 Endpoint 找出自己開的 open PR，含 Draft，依來源排序。完整空清單成功，帳號、查詢或任一頁失敗一律回傳 `.unavailable`。
- 既有 caller、分頁邊界與 redirect 行為須相容。帳號、搜尋與目的地契約以獨立離線證據驗收。
- 本輪限兩支 Endpoint 與其 REST 目的地規則，詳見 [技術契約](technical-spec.md) 與 [執行計畫](../../plan/pr-inbox-rest-endpoints/pr-inbox-rest-endpoints.plan.md)。
