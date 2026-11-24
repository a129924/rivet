# GitHub REST 回應分類 Phase A 需求

PR Inbox 是目前唯一正式使用 GitHub REST 的業務 Adapter。帳號查詢與搜尋只接受 HTTP 200，其他狀態映射為 `.unavailable`。現有 Adapter 沒有專屬限流規則可搬移，PR Reader 尚無正式 GitHub Adapter。

Phase A 交付 GitHubIntegration 內部的 REST 回應分類與離線證據。Endpoint／Operation 持有成功狀態契約。分類器接收操作已拒絕的回應。Adapter 接線及跨模組 API 留待 Phase B 依實際消費需求評估。

驗收涵蓋 401、403、404、429、5xx、其他狀態與 403 的權限／限流證據優先序。GitHub 認證、raw response、DTO、分頁與取消的現行行為以既有測試重驗。Inbox 將取消轉成 `.unavailable` 的契約留作後續議題。
