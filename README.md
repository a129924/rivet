# Rivet

Rivet 是一個個人 GitHub PR 工作台。

它的首版目標是集中查看目前等待使用者 review 的 GitHub.com open Pull Request，降低在 GitHub 網站、repository 與 PR 之間切換的成本，並成為日常挑選與開啟 PR 的優先入口。

## 成功標準

連續兩週以上，使用者在挑選及開啟待 review PR 時優先使用 Rivet。

## 文件導覽

- [產品規範](docs/product.md)
- [架構規範](docs/architecture/)
- [設計原則](docs/design-principles.md)
- [開發工具鏈](docs/toolchain.md)

## 目前狀態

Rivet 目前是可公開的 architecture baseline repository。它保留產品與架構決策、Bounded Context Map，以及 Swift／Node 版本基線；尚未開始任何產品功能實作。

未來將以一次一個 Bounded Context 的節奏，從 `PR Inbox` 的第一個最小切片開始實作。每個正式 topic 都以 `analysis/`、`plan/` 與 `docs/` 的配對文件留下可追溯的決策。
