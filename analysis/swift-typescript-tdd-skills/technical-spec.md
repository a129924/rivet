# Swift / TypeScript TDD Skills — Technical Spec

## Locked Decisions

- 本 topic 只新增 `.codex/skills/swift-tdd/SKILL.md` 與 `.codex/skills/typescript-tdd/SKILL.md`；不修改既有 skills 或 application／toolchain 設定。
- 兩個 skills 保持自包含與可獨立運作；不讀取、要求、輸出或定義 SDD、topic、`.step.md`、phase、verdict、角色、routing 或 Git workflow。
- resources 預設不建立；只有內容對日常使用確有必要且無法維持 entrypoint 精簡時，才新增單一 language-specific reference，並由 `SKILL.md` 條件式連結。
- 自動 skill discovery 維持預設行為；不新增 `agents/openai.yaml`、scripts、assets 或 metadata。
- 驗證使用 `skill-creator` 的 validator，透過隔離 `uv` 環境提供 PyYAML；validator 無法執行時只回報環境 blocker，不以手動檢查替代。

## Shared TDD Boundary

兩個 skill 只接收完成本次 TDD 工作所需的最小輸入：明確行為需求或 bug、目標 source／test 範圍（或可探索 repository），以及適用的驗證命令或設定。輸出限於測試邊界、red／green evidence、已執行驗證與局部 blocker。

共同流程為：辨識最小可測邊界、先建立可歸因的失敗測試、以最小實作轉綠、僅在持續通過時進行必要重構，最後執行受影響測試及 caller 指定驗證。

共同停止條件為：需求或可觀察行為不明、測試邊界不明、需未授權 public contract 或架構變更，或失敗無法區分環境問題與待實作行為。停止時只回報缺口，不推導 workflow 結果。

## `swift-tdd`

- 適用於 Swift／SwiftPM 的明確行為或 bug。
- 先辨識現有測試框架與最小可測邊界，再建立代表需求的 failing test；確認其失敗原因是目標行為尚未實作。
- 實作最小變更使測試通過，並只在測試持續通過時進行必要重構。
- 執行受影響測試，以及 caller 提供的 format、lint、coverage 命令；不得假設固定 framework、coverage threshold 或 app 啟動方式。
- 不取代 `swiftpm-macos` 的 build/run、`build-run-debug` 的診斷或 `test-triage` 的失敗分類。

## `typescript-tdd`

- 適用於 strict TypeScript 的明確行為或 bug。
- 先確認 package scripts、compiler options 與測試工具，再建立代表需求的 failing test。
- 以最小實作轉綠，維持 strict typecheck，並只在測試通過時重構。
- 執行受影響測試、typecheck，以及 caller 提供的 Biome、format、lint 或 coverage 命令；不得假設 package manager、Bun、Node、browser runtime、module format、target 或 coverage threshold。
- runtime、module format、target 或資料契約不明時停止；不得以 unconstrained `any` 或關閉 strict 設定逃避型別問題。

## Validation

Tester 對每個新 skill 執行：

```sh
uv run --isolated --with pyyaml python <quick_validate.py> <skill-dir>
```

兩項 validator 必須成功。若 PyYAML 或 validator 環境不可用，回報 `validator environment unavailable`，不可用手動檢查取代。獨立 Reviewer 以 Swift 與不同 TypeScript runtime／module target 的情境確認兩 skills 僅使用必要輸入、維持停止條件，且不混入 workflow 或 Git 責任。
