# Bounded Context

此目錄保存 Rivet 已確認 Bounded Context 的長期設計真相。每個 BC 僅有一份主文件；實作 topic 的 `analysis/` 與 `plan/` 應連結它，而不是複製其責任邊界。

- [PR Inbox](pr-inbox.md)
- [PR Reader](pr-reader.md)

PR Inbox 與 PR Reader 保有各自的 Core、UseCase、Port 與 failure contract；BC 之間不建立 compile-time dependency。`GitHubIntegration` 是 BC 外的 shared GitHub-specific integration module，不是 Supporting BC；目前只實作可注入、同步、typed-throws 的 access-token store/provider contract，未保存 token 映射為 missing credential，store load failure 保留為 token-store error。每個 Domain BC 未來在自己的 Infra 隔離所需 GitHub 外部協定，並可依賴其 deferred raw transport、authentication、共通 request headers／API version、pagination、rate-limit、retry、GitHub error technical classification 與 shared configuration。endpoint-specific media type、DTO translation，以及 technical classification 到該 BC failure contract 的 mapping 與 business meaning，仍只屬該 BC Infra；`GitHubIntegration` 不依賴任何 BC，也不產生 shared BC failure contract。`github-integration-auth-boundary`／PR #17 的 Supporting BC 敘述僅保留為已 supersede 的歷史 traceability。
