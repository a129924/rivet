# architecture-documentation-baseline

## Goal / Outcome

將 Rivet 由單一 architecture baseline 收斂為可供人與 agent 使用的架構知識基線：每個正式 topic 均有 analysis、plan 與 docs 的責任分工，且三個已確認 BC 都有獨立的長期設計文件。

## Scope

### In Scope

- 遷移 architecture 文件與既有 Bounded Context Map 至 `docs/architecture/`。
- 新增設計原則、AGENTS.md、三份 BC 文件、analysis／plan topic artifact。
- 建立 Repository Knowledge Map 與 Topic Lifecycle 互動式圖。

### Out Of Scope

- 所有產品程式碼、BC 實作、OAuth、GitHub API、WebView 功能與 module／target 設計。
- GitHub Integration dataflow、OAuth sequence、PR lifecycle 與 artifact.cafe 發布。

## Locked Decisions

- `docs`、`analysis`、`plan` 分別保存長期真相、研究依據與執行契約。
- 每個正式 topic 必須建立 `requirements.md`、`technical-spec.md` 與同 slug 的 `.plan.md`。
- 每個 Bounded Context 擁有一份位於 `docs/architecture/bounded-contexts/` 的主文件。
- `architecture-canvas` 用於全景／責任邊界；`archify` 用於 workflow、sequence、dataflow 與 lifecycle。
- 本次圖組固定為 Bounded Context Map、Repository Knowledge Map、Topic Lifecycle；GitHub dataflow 延後。

## Artifact Paths

| Artifact | Path | Role |
| --- | --- | --- |
| Agent 入口 | `AGENTS.md` | 文件與 skill routing 規範 |
| 設計原則 | `docs/design-principles.md` | 產品與工作方法 |
| Architecture index | `docs/architecture/README.md` | 跨 BC 不變量與索引 |
| BC files | `docs/architecture/bounded-contexts/*.md` | 三個 BC 的主文件 |
| Analysis | `analysis/architecture-documentation-baseline/` | requirements 與 technical spec |
| Plan | `plan/architecture-documentation-baseline/` | 本文件 |
| Diagrams | `docs/architecture/diagrams/` | 互動式架構 artifact |

## Implementation Steps

1. 建立 docs、analysis、plan 目錄並遷移既有 architecture 文件與 BC Map。
2. 撰寫設計原則、AGENTS.md 與三份 BC 文件，修正 README 與 architecture index 連結。
3. 建立並驗證 Repository Knowledge Map。
4. 建立並驗證 Topic Lifecycle workflow。
5. 驗證文件連結、Swift／Bun baseline 與三張圖；依 git-commit-convention 檢視 staged diff 後提交、push、開 Draft PR。

## Validation / Acceptance Checks

- 三個 BC 文件與 Bounded Context Map 不互相矛盾。
- 兩張 architecture-canvas 圖皆為 0 errors、0 warnings。
- Archify workflow 通過 showcase validation 與 deliver，並完成 visual-check。
- `swift package dump-package` 與 renderer `bun run check` 通過。
- 不存在產品功能、BC 實作或未授權的新增 module。
