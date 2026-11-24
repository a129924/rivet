# 非同步請求生命週期驗證需求

Topic `async-request-lifecycle-commit-guard`。規劃基線 `dev` `c389454`，延續 PR #83 的 E021／E022 及 PR #84 的 Reader 背景讀取。E021 支持本地 HTTP/1.1 取消。E022 支持受控 REST 晚回成功時，Inbox 以 `.unavailable` 返回。完整 Reader 快照與產品狀態提交仍缺直接證據。 [取消基線](../../docs/architecture/swift-cancellation-baseline.md) · [Reader](../../docs/architecture/bounded-contexts/pr-reader.md)

## 目標與範圍

以獨立 Swift host 驗證應用／呈現 owner 在已取消請求仍交付成功或失敗時，能只接受當前有效結果，並保護當前的 loading 與 Task handle。實驗要分別證明 generation 與取消旗標的作用，也要保留有效 `.unavailable`。交付可重現證據與產品採用缺口。

正式 Swift、WebView、根 manifest、既有測試、實驗索引、Reader／Inbox Port、Outcome、Adapter、REST、OAuth 與 Transport 屬唯讀範圍。驗證使用合成資料與事件控制，產品接線、真實 I/O、HTTP 取消重驗、通用 TaskManager 與跨環境保證屬範圍外。

既有 nonthrowing Outcome 是候選產品路徑。若隔離契約成立，後續由 Presentation Session 驗證實際選取、刷新與退出入口。只有產品整合顯示 caller 必須辨識下層取消且 Outcome 無法表達時，另立 Port 契約議題。

[技術規格](technical-spec.md) · [執行計畫](../../plan/async-request-lifecycle-commit-guard/async-request-lifecycle-commit-guard.plan.md)
