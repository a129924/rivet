# Bounded Context

此目錄保存 Rivet 已確認 Bounded Context 的長期設計真相。每個 BC 僅有一份主文件；實作 topic 的 `analysis/` 與 `plan/` 應連結它，而不是複製其責任邊界。

- [PR Inbox](pr-inbox.md)
- [PR Reader](pr-reader.md)
- [GitHub Integration](github-integration.md)

PR Inbox 與 PR Reader 保有各自的 Core、UseCase、Port 與 failure contract；BC 之間不建立 compile-time dependency。未來 GitHub REST／GraphQL adapter 屬 consuming Domain BC 的 local Infra，並各自擁有 endpoint、DTO、外部 failure 正規化與 Domain failure mapping。GitHub Integration 是只提供 lower shared authorization capability 的 Supporting BC；它不擁有、引用或符合任何 Domain Port，也不擁有 Domain adapter。
