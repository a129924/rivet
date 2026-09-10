# Bounded Context

此目錄保存 Rivet 已確認 Bounded Context 的長期設計真相。每個 BC 僅有一份主文件；實作 topic 的 `analysis/` 與 `plan/` 應連結它，而不是複製其責任邊界。

- [PR Inbox](pr-inbox.md)
- [PR Reader](pr-reader.md)

PR Inbox 與 PR Reader 保有各自的 Core、UseCase、Port 與 failure contract；BC 之間不建立 compile-time dependency。`GithubIntegration` 是 BC 外、尚未實作的 shared GitHub-specific integration module，不是 Supporting BC；每個 Domain BC 未來在自己的 Infra 隔離所需 GitHub 外部協定，並可依賴此 shared module。endpoint、DTO translation、外部 failure 正規化、Domain failure mapping 與 business meaning 仍屬該 BC Infra；`GithubIntegration` 不依賴任何 BC。`github-integration-auth-boundary`／PR #17 的 Supporting BC 敘述僅保留為已 supersede 的歷史 traceability。
