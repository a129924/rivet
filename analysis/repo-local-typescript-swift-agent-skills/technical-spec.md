# Repo-local TypeScript / Swift Agent Skills — Technical Spec

## Locked Decisions

- 新增 skills 來自 `openai/skills` 的 `.curated`，pin 至 `49f948faa9258a0c61caceaf225e179651397431`。
- catalog 已 deprecated；本次採取 vendor 加遷移註記，等 OpenAI Plugins 出現完整等價項目才在明確 topic 中遷移。
- 所有新增內容位於 `.codex/skills/`，不寫入全域 skills 目錄，也不新增 plugin manifest 或 connector 設定。
- `playwright` 維持 upstream CLI-first 設計，但其 wrapper 改以 repo-local `.codex/skills/playwright/scripts/playwright_cli.sh` 執行，不依賴 `$CODEX_HOME`。
- `security-best-practices` 的報告輸出受 repository topic-artifact 規範優先約束；不接受 upstream 的根目錄預設檔名。
- 更新一律由人工明確發起：重新取得 exact pin、比較內容／licenses／local overlay、驗證 front matter 與 symbolic links。

## Boundaries

- `playwright` 不建立 `@playwright/test` 或變更 Bun scripts。
- `gh-fix-ci` 與 `gh-address-comments` 僅在實際使用時要求 `gh` authentication；不在安裝時讀取帳號或遠端 PR。
- `security-best-practices` 只宣稱支援 JavaScript／TypeScript、Python、Go；Swift workflow 繼續由既有 OpenAI Build macOS Apps bundle 與 `swift-tdd` 提供。
