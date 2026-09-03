# Repo-local TypeScript / Swift Agent Skills — Requirements

## Goal

將使用者已選定的四個 OpenAI curated skills 納入 `.codex/skills/`，補強 TypeScript WebView 驗證、GitHub PR 維護與 TypeScript 安全審查；既有 Swift skills 保持不變。

## In Scope

- Vendor `playwright`、`gh-fix-ci`、`gh-address-comments`、`security-best-practices`。
- 將來源、commit pin、授權、local overlay 與手動更新規則記錄在 repo。
- 保留現有 OpenAI Build macOS Apps Swift bundle 與本地 `swift-tdd`。

## Out of Scope

- 新增 Swift application code、Node/Bun dependency、Playwright test framework、GitHub token、connector 或全域 skill 安裝。
- 自動更新 upstream、Git commit、push、PR 或 release。

## Success Criteria

- 四個新增 skills 可由 repo-local discovery 取得，且各有完整上游檔案、有效 front matter 與零 symbolic links。
- Playwright 可從 repo-local path 使用 wrapper；GitHub skills 維持 `gh` auth preflight；安全 skill 僅在明確安全要求時觸發。
- 上游來源與 local overlay 不被混淆，未來遷移至 OpenAI Plugins 有明確依據。
