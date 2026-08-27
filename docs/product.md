# Rivet 產品規範

## Goal

集中查看目前等待使用者 review 的 GitHub Pull Requests，降低在 GitHub 網站、repository 與 PR 間切換的成本。

Rivet 的角色是個人 GitHub PR 工作台，不是 GitHub 或 Graphite 的完整替代品。

## Success Criteria

連續兩週以上，使用者挑選及開啟待 review PR 時優先使用 Rivet。

## In-Scope

- 個人使用情境。
- GitHub.com。
- 單一使用者。
- 核心集合為「目前等待使用者 review 的 open PR」。

## Out-Of-Scope

- GitHub Enterprise、多帳號、跨裝置同步與團隊協作。
- PR stack、merge queue 與任務管理。
- 完整 code review 寫入操作。
- GitHub 通知與 macOS 系統通知。
- 雲端 backend、帳號系統與公開發布需求。

## 延後原則

上述 Out-Of-Scope 項目是目前 MVP 與本階段不處理的事項，不代表 Rivet 永不支援。是否納入後續範圍，應以 Rivet 成為日常 PR 入口的實際使用結果為依據。
