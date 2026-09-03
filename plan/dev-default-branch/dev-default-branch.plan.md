# Dev 預設分支

## Goal

將日常整合基線轉為 `dev`，並讓 `main` 僅承接經人為確認的成熟 promotion。

## Non-Goal

不變更 branch protection、CI、release 規則或任何既有分支歷史。

## ReadOnly

- `README.md`、`docs/design-principles.md` 與 `docs/toolchain.md`
- Git 分支拓撲、upstream 與 GitHub repository default branch

## Written

- `analysis/dev-default-branch/` 下的需求與技術規格
- `plan/dev-default-branch/` 下的執行契約與 step ledger
- `docs/development-workflow.md`

## Modify

- `README.md`：加入開發流程導覽。
- 本地與 `origin` 的 `dev` branch ref，以及 GitHub repository default branch。

## Deleted

無。

## Implementation

1. 確認 `dev` 為 `main` 的祖先，再 fast-forward `dev` 到 `main`。
2. 推送更新後的 `dev`，將 GitHub default branch 設為 `dev`。
3. 切換本地工作目錄至追蹤 `origin/dev` 的 `dev`。
4. 寫入並連結長期開發流程文件。

## TestCase

- TC-01：`dev` 可 fast-forward 至 `main`，沒有強制推送或歷史改寫。
- TC-02：GitHub repository 預設分支為 `dev`。
- TC-03：本地 checkout 為 `dev`，且 upstream 為 `origin/dev`。
- TC-04：文件清楚區分日常 `dev` 整合與人為確認的 `main` promotion。
