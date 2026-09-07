# Bounded Context

此目錄保存 Rivet 已確認 Bounded Context 的長期設計真相。每個 BC 僅有一份主文件；實作 topic 的 `analysis/` 與 `plan/` 應連結它，而不是複製其責任邊界。

- [PR Inbox](pr-inbox.md)
- [PR Reader](pr-reader.md)

GitHub Integration 已退役，不再是集中 GitHub adapter 的 Supporting BC。每個 Domain BC 未來在自己的 Infra 隔離所需 GitHub 外部協定；BC 之間不建立 compile-time dependency。
