# Rivet Agent 規範

- 預設使用繁體中文；文件與回覆不得輸出使用者本機絕對路徑。
- `README.md` 是 repository 的 first-read 文件；開始任何任務前先讀它。
- 再讀 `docs/design-principles.md`。涉及架構或 Bounded Context 時，必須讀 `docs/architecture/README.md` 與相關 BC 文件。
- 每個正式 topic 都使用同一個 slug，並先建立：
  - `analysis/<topic>/requirements.md`
  - `analysis/<topic>/technical-spec.md`
  - `plan/<topic>/<topic>.plan.md`
  - `plan/<topic>/<topic>.step.md`
- `analysis/` 保存尚未鎖定的研究依據；`plan/` 是本次受限的執行契約；完成後仍成立的結論必須回寫 `docs/`。
- 系統或 BC 的責任邊界使用 `architecture-canvas`；workflow、sequence、dataflow、lifecycle 使用 `archify`。圖的作者內容使用繁體中文，並必須通過各 skill 的驗證；不得自行發布 artifact.cafe。
- `docs/architecture/bounded-contexts/` 是 BC 長期設計真相；一個 Bounded Context 對應一份文件。不得把暫時推論或未授權實作細節寫成既定架構。
- Git commit 前依 `$git-commit-convention` 從 staged diff 檢查語意邊界並提出 message；未經人類確認不得執行 commit。
