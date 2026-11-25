# 指定 repository 的 open PR Endpoint 需求

Topic `github-repository-open-pull-requests-endpoint`。使用者確認本次交付 Endpoint 型別。Headers 由另一個 Session 並行處理，兩項交付完成後再處理 Adapter。

## 目的與範圍

- 在 Swift package 內交付可建立、可獨立驗證的 `GET /repos/{owner}/{repo}/pulls` Endpoint，接收單一 repository 的 owner 與名稱，可為指定頁碼組成固定 open PR 查詢。
- 專用 SwiftPM target、Endpoint 型別、HTTP method、URL、輸入驗證與離線測試構成本次交付。GitHub API Catalog 記錄套件能力。
- Headers、Adapter、正式呼叫、REST 發送、Link 分頁、DTO 與清單映射、OAuth、BC、UI 擴充與即時 GitHub 驗收均由其他工作處理。

## 成功條件

1. 使用一般 `import`，同一 Swift package 的測試 target 可建立 Endpoint。GET、HTTPS host、path 與 query 由獨立預期值驗證。
2. 預設第 1 頁，呼叫端可明示正整數頁碼。無效路徑或頁碼在委派 URL 組裝前拋錯。
3. 新 target 只依賴共用 GitHub Integration 與 HTTP 套件。驗證 target graph 與既有 product 集合。
4. GitHub API Catalog 記錄 Endpoint 與後續 Adapter。產品 repository 瀏覽維持既定排程。

## 後續 Adapter

等 Headers 與 Endpoint 完成後，於同一 target 提供套件內的正式入口。後續透過注入的 REST client 和 `.standardREST` 使用 Endpoint，依 GitHub Link 取完整清單並保留 GitHub 順序，涵蓋 Draft 與其他作者。每筆只交付編號與標題。空清單為成功，任一頁失敗時整次回傳失敗。

- [技術規格](technical-spec.md)
- [執行計畫](../../plan/github-repository-open-pull-requests-endpoint/github-repository-open-pull-requests-endpoint.plan.md)
- [GitHub REST PR 清單](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)
