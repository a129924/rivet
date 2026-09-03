# Dev 預設分支：技術規格

## Branch Transition

目前 `dev` 是 `main` 的祖先，因此以 `git merge --ff-only main` 更新 `dev`；此操作不產生 merge commit、也不重寫任一分支歷史。完成後推送 `dev` 至 `origin`。

GitHub repository 的 `default_branch` 設為 `dev`。此設定改變 GitHub 建立 Pull Request、比較分支與顯示 repository 首頁時的預設基線；它不會自行改動保護規則或已開啟 Pull Request 的目標分支。

## Working Agreement

- 日常功能與修正分支從最新 `dev` 建立，並以 `dev` 為 Pull Request 目標。
- 通過必要 review 與驗證的工作先整合至 `dev`。
- 只有在維護者確認整體內容適合穩定版本時，才以一個明確的 promotion Pull Request 將 `dev` 合併至 `main`。
- `main` 保留為較成熟、可發布的基線；不作為日常工作的預設起點或目標。

## Validation

- `git merge-base --is-ancestor main dev` 成功，且兩分支 commit SHA 相同。
- `git branch --show-current` 回傳 `dev`；`git status --branch` 顯示其 upstream 為 `origin/dev`。
- GitHub API 回傳的 `default_branch` 為 `dev`。
