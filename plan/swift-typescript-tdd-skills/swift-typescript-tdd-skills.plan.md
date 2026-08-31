# swift-typescript-tdd-skills

## Goal

以 `skill-creator` 建立獨立的 `swift-tdd` 與 `typescript-tdd` skills，讓語言專屬 TDD 實作具備明確 red-green-refactor 流程與本地驗證邊界。

## Non-Goal

不修改產品程式碼、`Package.swift`、WebView、產品測試、toolchain 或 CI；不修改既有 skills；不建立 SDD／Dispatcher／Git workflow；不執行 commit、push、PR、release、branch 或 worktree 操作。

## In-Scope

- 新增 `.codex/skills/swift-tdd/SKILL.md`。
- 新增 `.codex/skills/typescript-tdd/SKILL.md`。
- 僅在不可避免時為各自 skill 新增一份 language-specific `references/` 文件。
- 驗證兩個 skills 並執行獨立審查。

## Out-Of-Scope

- 複製或改寫 `swiftpm-macos`、`build-run-debug`、`test-triage` 的既有職責。
- 固定任何測試框架、coverage 門檻、package manager、runtime、module format 或 app 啟動方式。
- 產生或推導 approval、verdict、gate、routing、topic artifacts 或其他角色責任。

## ReadOnly

- `AGENTS.md`、`README.md`、`docs/design-principles.md`、`docs/toolchain.md`。
- 現有相關 local skills、SwiftPM 與 TypeScript toolchain 設定。
- `skill-creator` 指引與 validator。

## Written

- `analysis/swift-typescript-tdd-skills/requirements.md`
- `analysis/swift-typescript-tdd-skills/technical-spec.md`
- `plan/swift-typescript-tdd-skills/swift-typescript-tdd-skills.plan.md`
- `plan/swift-typescript-tdd-skills/swift-typescript-tdd-skills.step.md`
- `.codex/skills/swift-tdd/SKILL.md`
- `.codex/skills/typescript-tdd/SKILL.md`
- 僅在確有必要時，各 skill 一份 language-specific `references/` 文件。

## Modify

本 topic 的四份 planning artifacts 僅可由 Plan-Creator 在相符 review rework 時修正。其餘現有 repository 檔案不修改。

## Deleted

無。

## Implementation Changes

1. Implementer 依 locked decisions 建立兩個精簡 `SKILL.md`，各自聲明適用情境、最小輸入、red-green-refactor 行為、局部輸出、停止條件與禁止事項。
2. `swift-tdd` 僅處理 Swift／SwiftPM TDD；不假設測試 framework、coverage 或 app launch。
3. `typescript-tdd` 僅處理 strict TypeScript TDD；不假設 package manager、runtime、module format、target 或 coverage，並禁止以 unconstrained `any` 或關閉 strict 規避問題。
4. 兩者皆不含 SDD、topic、ledger、phase、verdict、routing、Git 或其他角色資訊。

## TestCase

- 每個 skill 的 frontmatter、名稱與目錄一致，description 可區分適用語言與工作情境。
- Swift 情境先建立可歸因 failing test，再最小實作轉綠並執行 caller 指定的受影響驗證。
- TypeScript 情境維持 strict typecheck，並在 runtime 或 module target 未提供時停止，而不假設 Bun／Node／browser。
- 兩 skills 都在需求、可觀察行為或測試邊界不足時回報局部 blocker，不擴張 scope。
- 兩 skills 均不要求或產生 SDD／Git／workflow 資訊。
- Tester 對兩個 skills 個別執行：

  ```sh
  uv run --isolated --with pyyaml python <quick_validate.py> <skill-dir>
  ```

  validator 全數成功；若 validator 環境不可用，回報 `validator environment unavailable`，不以手動結果替代。
- 獨立 Reviewer 以 Swift 與不同 TypeScript runtime／module target 的 forward-review，確認責任分離、觸發條件與安全邊界。

## Stop Conditions

- Plan-Reviewer 未明示 `approved` 前，不得建立或修改兩個 skills。
- 任一 skill 所需的行為需求、可測邊界、runtime／module target 或直接驗證條件不明時，僅回報局部 blocker。
- validator 失敗或 Reviewer 發現 workflow／Git 耦合、責任重疊或 safety regression 時，只交回 Implementer 修正相符範圍。
- 獨立 Reviewer 未明示結果前，不得交由 human-check 視為完成。
