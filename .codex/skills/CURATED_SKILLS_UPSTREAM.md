# Vendored OpenAI Curated Skills

## Source

- Upstream repository: https://github.com/openai/skills
- Upstream commit: `49f948faa9258a0c61caceaf225e179651397431`
- Source paths:
  - `skills/.curated/playwright`
  - `skills/.curated/gh-fix-ci`
  - `skills/.curated/gh-address-comments`
  - `skills/.curated/security-best-practices`
- License: each vendored directory retains its upstream `LICENSE.txt`.

## Status and Migration

The upstream catalog is marked deprecated. These four skills remain vendored as a deliberate transition baseline because they are individually installable and match this repository's immediate TypeScript, WebView, and GitHub PR workflows. A future explicit topic must evaluate OpenAI Plugins replacements before changing this set; do not automatically follow upstream `main`.

## Local Overlay

- `playwright/SKILL.md`: replaces the upstream user-scoped `$CODEX_HOME` wrapper location with the repository-local `.codex/skills/playwright/scripts/playwright_cli.sh` path. This keeps the CLI-first workflow and does not install `@playwright/test`, a global CLI, or package dependencies.
- Vendored text files: normalize CRLF and trailing whitespace where necessary for this repository's `git diff --check`; this does not change instruction or license meaning.
- `security-best-practices`: its suggested root-level report filename is superseded by this repository's topic-artifact rules. No upstream content is otherwise changed.

## Update Procedure

For a user-authorized update topic:

1. Resolve and record an exact upstream commit.
2. Replace each complete vendored directory from that commit, retaining its license.
3. Reject symbolic links and validate every `SKILL.md` front matter before accepting the update.
4. Reapply only the documented overlay after comparing it with the new upstream content.
5. Re-evaluate whether a supported OpenAI Plugin now supersedes any curated skill.
