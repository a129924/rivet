# Dev 預設分支：Step Ledger

## Current Phase

Completed

## Ledger

| ID | Status | Work | Evidence |
|---|---|---|---|
| IM-01 | completed | 建立 topic artifacts 與長期工作流程文件。 | `analysis/dev-default-branch/`、`plan/dev-default-branch/` 與 `docs/development-workflow.md`。 |
| IM-02 | completed | 快轉並推送 `dev` 至目前 `main` 基線。 | `dev` 與 `main` 均為 `3ec3042`；`git push origin dev` 以 fast-forward 成功。 |
| IM-03 | completed | 將 GitHub repository 的預設分支改為 `dev`。 | GitHub API PATCH 與讀回結果均為 `dev`。 |
| IM-04 | completed | 切換本地工作目錄至追蹤 `origin/dev` 的 `dev`。 | `git branch --show-current` 為 `dev`，upstream 為 `origin/dev`。 |
| TE-01 | completed | 驗證分支 SHA、upstream 與 GitHub default branch。 | `dev`／`main` SHA 相同、本機 upstream 為 `origin/dev`，GitHub API 回傳 `default_branch: dev`。 |
| HUMAN-01 | pending | 確認何時將 `dev` promotion 至 `main`。 | 每次 promotion 前由維護者決定。 |

## Blockers

無。
