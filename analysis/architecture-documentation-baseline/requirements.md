# Architecture Documentation Baseline — Requirements

## Goal

建立公開、可追溯且 agent 可理解的 Rivet 架構知識基線，使後續每個 Bounded Context 都能從同一組文件、分析與計畫規則開始。

## In Scope

- 將 architecture 文件與互動式圖收斂至 `docs/architecture/`。
- 建立設計原則、根目錄 agent 入口與三個已確認 BC 的設計文件。
- 建立 analysis／plan 的正式 topic 基線。
- 保留既有 Bounded Context Map，新增 repository 知識全景與正式 topic 工作流程圖。

## Out Of Scope

- PR Inbox、PR Reader、GitHub Integration 的程式碼、target、API schema 或 OAuth 實作。
- 新增 app、context、backend 或 WebView 產品功能。
- GitHub Integration 的 API dataflow、OAuth sequence 或 PR lifecycle 圖。
- artifact.cafe 發布、GitHub release 或任何產品功能規格。

## Success Criteria

- 人與 agent 都能從 repository 根目錄找到設計原則、架構索引、相關 BC 文件與正式 topic 流程。
- 每個已確認 BC 有且只有一份長期設計主文件。
- 三張互動式圖分別回答 BC 邊界、repository 知識結構與 topic 工作流程。
