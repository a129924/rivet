# Bounded Context

此目錄保存 Rivet 已確認 Bounded Context 的長期設計真相。每個 BC 僅有一份主文件；實作 topic 的 `analysis/` 與 `plan/` 應連結它，而不是複製其責任邊界。

- [PR Inbox](pr-inbox.md)
- [PR Reader](pr-reader.md)
- [GitHub Integration](github-integration.md)

GitHub Integration 是隔離 GitHub 外部協定、身分、DTO 與 infrastructure failure 的 Supporting BC。PR Inbox 與 PR Reader 保有各自的 Core、UseCase、Port 與 failure contract；BC 之間不建立 compile-time dependency。
