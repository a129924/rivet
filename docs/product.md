# Rivet 產品規範

## Goal

集中查看目前登入帳號自己開的 open GitHub Pull Requests，降低在 GitHub 網站、repository 與 PR 間切換的成本。

Rivet 的角色是個人 GitHub PR 工作台，不是 GitHub 或 Graphite 的完整替代品。

## Success Criteria

連續兩週以上，使用者挑選及開啟自查候選 PR 時優先使用 Rivet。

## In-Scope

- 個人使用情境。
- GitHub.com。
- 單一使用者。
- 核心集合為目前登入帳號自己開的 open PR，包含符合條件的 Draft。
- 清單提供合併前的自查候選。自查完成狀態留待後續定義。

## Out-Of-Scope

- GitHub Enterprise、多帳號、跨裝置同步與團隊協作。
- PR stack、merge queue 與任務管理。
- 完整 code review 寫入操作。
- GitHub 通知與 macOS 系統通知。
- 雲端 backend、帳號系統與公開發布需求。

## 延後原則

上述 Out-Of-Scope 項目是目前 MVP 與本階段不處理的事項，不代表 Rivet 永不支援。是否納入後續範圍，應以 Rivet 成為日常 PR 入口的實際使用結果為依據。
