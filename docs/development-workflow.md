# 開發分支流程

## 日常整合

`dev` 是 Rivet 的預設分支與日常整合基線。建立功能或修正時，先更新 `dev`，再從它建立工作分支；Pull Request 預設以 `dev` 為目標。完成必要 review 與驗證後，工作先合併回 `dev`。

## 推進穩定基線

`main` 保留為較成熟、可發布的基線，不用於日常工作分支的起點或 Pull Request 目標。只有在維護者確認 `dev` 的整體內容已適合進入穩定版本時，才建立明確的 promotion Pull Request，將 `dev` 合併至 `main`。

每次 promotion 仍須依當時需求決定 review、驗證、tag 與發布安排；本流程不會自動將 `dev` 推進 `main`。
