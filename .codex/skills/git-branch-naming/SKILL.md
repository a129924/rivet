---
name: git-branch-naming
description: 為受限 topic 提供可讀、可追溯的 Git branch 名稱建議；不執行 Git 操作。
---

# Git Branch 命名

使用此 skill 依已鎖定 topic slug 與工作類型建議 branch 名稱。只在需求已鎖定時提出單一建議；命名使用小寫 ASCII、以連字號分隔，避免空白、模糊日期或未驗證的 issue 編號。

偏好格式為 `<type>/<owner>/<topic>`；`type` 使用與工作性質相符的簡短值，例如 `feat`、`fix`、`docs` 或 `chore`。`owner` 僅在 repository 已有既定慣例時使用。

若 topic、工作類型或既有命名慣例不明，回報 `blocked`，不自行假設。

此 skill 僅提供建議；不建立、切換、刪除或推送 branch，不執行 worktree、commit、tag、release、post-merge 或其他 Git 操作。
