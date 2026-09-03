# repo-local-typescript-swift-agent-skills

## Summary

Vendor 四個已選 OpenAI curated skills，保留既有 Swift bundle，並把 deprecated catalog 的來源與未來遷移規則固定為可追溯 metadata。

## Changes

- 將 pinned curated directories 加入 `.codex/skills/`：`playwright`、`gh-fix-ci`、`gh-address-comments`、`security-best-practices`。
- 對 Playwright 套用最小 local overlay，改用 repo-local wrapper path；其餘上游內容保持原樣。
- 新增單一 curated-upstream metadata 文件，記錄 source、commit、paths、license、overlay、驗證與手動更新流程。
- 建立本 topic 四份 artifacts；不變更既有 Swift bundle、toolchain、application code 或 global Codex 設定。

## Acceptance

- 所有新增 skill directories 都有 `SKILL.md`、有效 YAML front matter，且不含 symbolic links。
- Playwright wrapper 可用現有 Node/npx 執行 help；不安裝全域 CLI 或 npm dependencies。
- GitHub skills 在未驗證 auth 時只要求登入；安全 skill 仍只在明確 security request 時適用。
