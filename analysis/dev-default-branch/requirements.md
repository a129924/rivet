# Dev 預設分支：需求

## Goal

將 Rivet 的日常整合基線由 `main` 改為 `dev`，讓新分支與 Pull Request 預設以 `dev` 為目標；僅在功能與驗證已達可發布狀態時，才將 `dev` 推進至 `main`。

## Non-Goal

- 不刪除或重新命名 `main`、`dev` 或既有 feature branch。
- 不變更 GitHub branch protection、required checks、Actions workflow、release、tag 或部署設定。
- 不建立自動將 `dev` 合併至 `main` 的機制。

## In-Scope

- 將本地 `dev` 快轉至目前的 `main` 基線。
- 將更新後的 `dev` 推送至 `origin`。
- 將 GitHub repository 的預設分支改為 `dev`。
- 將本地工作目錄切換至追蹤 `origin/dev` 的 `dev`。
- 記錄日常開發與 promotion 至 `main` 的規則。

## Acceptance Criteria

- `dev` 與 `main` 在切換當下指向相同 commit，且不改寫歷史。
- GitHub repository 的 default branch 是 `dev`。
- 本地目前分支為 `dev`，並追蹤 `origin/dev`。
- 文件明確規定 feature branch 從 `dev` 建立、PR 預設合併回 `dev`；推進 `main` 須由人為確認。
