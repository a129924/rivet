# Swift / TypeScript TDD Skills — Requirements

## Goal

在 `.codex/skills/` 建立 `swift-tdd` 與 `typescript-tdd` 兩個可重用、可獨立運作的語言專用 TDD skills。兩者只協助各自語言的 red-green-refactor 實作與本地驗證，不理解或依賴 SDD、topic artifacts、`.step.md`、phase、verdict、角色路由或 Git workflow。

## In-Scope

- 建立 `swift-tdd` 與 `typescript-tdd` 兩個 skill 的 `SKILL.md`。
- 僅在精簡 entrypoint 無法承載必要且可重複的語言專屬決策時，為各 skill 新增一份 `references/` 文件。
- 使用 `skill-creator` 的 `quick_validate.py` 驗證兩個 skills。
- 以獨立 Reviewer 檢查兩者的責任分離、觸發條件與安全邊界。

## Out-Of-Scope

- Swift／TypeScript application code、`Package.swift`、WebView surface、產品測試、toolchain 設定與 CI。
- release、VERSION、branch、worktree、commit、push、PR 或任何 Git workflow 設定。
- 通用 SDD／Dispatcher 規則、approval、verdict、gate 或 workflow routing。
- 完整複製 `swiftpm-macos`、`build-run-debug`、`test-triage` 或其他既有 skill 的內容。

## Success Criteria

- `swift-tdd` 可在明確 Swift／SwiftPM 行為或 bug 情境下引導 red-green-refactor 與呼叫端指定的本地驗證。
- `typescript-tdd` 可在明確 strict TypeScript 行為或 bug 情境下引導 red-green-refactor、typecheck 與呼叫端指定的本地驗證。
- 兩者都在需求、可觀察行為、測試邊界或直接必要執行條件不明時停止，不臆測或擴張範圍。
- 兩者均不要求或讀取 SDD artifacts，不產生 approval、verdict、gate 或 routing，亦不執行 Git 操作。
- 兩個 skill 均通過 `quick_validate.py`，並獲獨立 Reviewer 明示審查結果。

## Non-Goal

- 不將 TDD 變成固定測試框架、coverage 門檻、runtime、module format、app 啟動方式或 CI policy。
- 不以 TDD skill 取代測試失敗診斷、SwiftPM build/run、Git 操作或 workflow orchestration。
