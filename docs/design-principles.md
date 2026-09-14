# Rivet 設計原則

## 產品取捨

- Rivet 是個人 GitHub PR 工作台，不是 GitHub 或 Graphite 的完整替代品。
- 先解決「集中挑選並開啟目前等待我 review 的 open PR」，再考慮擴張功能。
- MVP 以唯讀工作流為優先；寫入 review、通知、團隊協作、多帳號與跨裝置同步均須以獨立 topic 重新評估。

## 架構取捨

- 一次只處理一個 Bounded Context；未經 topic 授權，不因為未來可能需要而預先建立 package、module 或抽象層。
- PR Inbox 與 PR Reader 的責任邊界優先於技術框架或目錄便利性；`GitHubIntegration` 是 BC 外的 shared GitHub-specific integration module，不是 Bounded Context。
- 每個 Domain BC 的 Core、UseCase 與 Port 不依賴 GitHub 外部協定或 transport；該 BC 未來自己的 Infra 負責 GitHub adapter、operation／endpoint、endpoint-specific media type、DTO 與 failure mapping。
- 外部 GitHub DTO、HTTP status、OAuth／Keychain 細節與 infrastructure failure 不得洩漏到核心 BC，也不得形成 BC-to-BC compile-time dependency。
- 每個 BC 擁有自己的 failure contract；即使 `GitHubIntegration` 未來對 raw transport 或 GitHub error 作 technical classification，也只有各 BC Infra 可將它映射為該 BC 語意，絕不形成 shared BC failure contract。
- `GitHubIntegration` 是已實作的 non-BC shared GitHub-specific integration module；目前只提供可注入、同步、typed-throws 的 access-token store/provider contract。未來只有各 BC Infra 可依賴其 deferred GitHub REST／GraphQL raw transport、authentication mechanism、共通 request headers／API version、pagination、rate limit、retry、GitHub error technical classification 與 shared configuration；它不進入 Core、UseCase 或 Port，也不依賴任何 BC。endpoint-specific media type、DTO translation、BC failure mapping 與 business meaning 留在各 BC Infra。
- Presentation Session 是 UI 狀態，不是假裝成 Bounded Context。

## 工作方法

- `analysis/`、`plan/` 與 `docs/` 各有責任：研究、執行契約、長期真相。三者互相連結，但不可互相取代。
- 每個正式 topic 先鎖定範圍與驗收，再開始實作；scope 改變時先回到 analysis 與 plan。
- 架構圖不是裝飾：全景與責任邊界使用 `architecture-canvas`，流程與狀態變化使用 `archify`。
- 文件、圖與程式碼若不一致，優先修正能代表長期真相的文件與圖，再進行實作調整。
- 對上游來源作本地 skill overlay 時，必須清楚記錄 pin 與本地差異；同步上游時重新評估 overlay，不得將本地規則誤稱為 upstream 原文。
- 僅 `sdd-workflow-contract` 定義或理解 SDD；其他 skill 必須以完成自身工作所需的最小輸入、輸出與安全邊界獨立運作，不假設 topic artifacts、phase、verdict 或其他角色職責存在。
