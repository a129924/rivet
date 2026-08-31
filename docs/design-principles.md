# Rivet 設計原則

## 產品取捨

- Rivet 是個人 GitHub PR 工作台，不是 GitHub 或 Graphite 的完整替代品。
- 先解決「集中挑選並開啟目前等待我 review 的 open PR」，再考慮擴張功能。
- MVP 以唯讀工作流為優先；寫入 review、通知、團隊協作、多帳號與跨裝置同步均須以獨立 topic 重新評估。

## 架構取捨

- 一次只處理一個 Bounded Context；未經 topic 授權，不因為未來可能需要而預先建立 package、module 或抽象層。
- PR Inbox、PR Reader 與 GitHub Integration 的責任邊界優先於技術框架或目錄便利性。
- 外部 GitHub DTO、HTTP status、OAuth／Keychain 細節與 infrastructure failure 不得洩漏到核心 BC。
- 每個 BC 擁有自己的 failure contract；`InfraUnknownError` 僅在 Adapter／GitHub Integration 邊界產生或正規化。
- Presentation Session 是 UI 狀態，不是假裝成 Bounded Context。

## 工作方法

- `analysis/`、`plan/` 與 `docs/` 各有責任：研究、執行契約、長期真相。三者互相連結，但不可互相取代。
- 每個正式 topic 先鎖定範圍與驗收，再開始實作；scope 改變時先回到 analysis 與 plan。
- 架構圖不是裝飾：全景與責任邊界使用 `architecture-canvas`，流程與狀態變化使用 `archify`。
- 文件、圖與程式碼若不一致，優先修正能代表長期真相的文件與圖，再進行實作調整。
- 對上游來源作本地 skill overlay 時，必須清楚記錄 pin 與本地差異；同步上游時重新評估 overlay，不得將本地規則誤稱為 upstream 原文。
- 僅 `sdd-workflow-contract` 定義或理解 SDD；其他 skill 必須以完成自身工作所需的最小輸入、輸出與安全邊界獨立運作，不假設 topic artifacts、phase、verdict 或其他角色職責存在。
