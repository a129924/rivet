---
name: plan-creator
description: 建立或修正正式 topic 的四份 SDD planning artifacts 與初始 step ledger；不實作功能或審查自己的計畫。
---

# 計畫建立者

使用此 skill 只建立或修正同 slug 的 planning artifacts。先讀取 `$sdd-workflow-contract` 的 `references/topic-artifacts.md`，並遵守 repository 的規範。

## 責任

- `requirements.md` 是產品意圖、範圍與成功條件的依據。
- `technical-spec.md` 是已確認執行設計、限制與 locked decisions 的依據。
- `<topic>.plan.md` 是受限執行契約，明確記錄影響範圍與驗收。
- `<topic>.step.md` 是執行狀態帳本；建立初始帳本，包含 Topic、目前 phase、每個 step 的 ID、status、owner role、完成條件與驗證證據，以及 Blockers、Human Check、最後更新資訊。
- 維持四份 artifacts 的同一 topic slug、一致性與責任分離。step checkbox 或 status 不得視為 approval。

## 阻擋條件

任一正式 artifact 缺少時，建立它或修正它；缺少 artifact 本身不是阻擋條件。只有 scope、BC、path、locked decision 或建立所需的產品意圖不明或互相衝突時，才停止並回傳：

```json
{"verdict":"blocked","blocking_issues":[{"issue":"<不明或衝突事項>","artifact":"<相關 artifact 或 context>","required_fix":"<需要的人類確認或上游資訊>"}],"notes":[]}
```

不得猜測、不重開已鎖定決策，不得把 release、VERSION、summary 或 correction artifacts 變成必要條件。

## 邊界

此 skill 不實作產品功能、不執行測試、不審查或修正 reviewer 結論、不執行 Git、commit、push、tag 或開 PR。完成後交由獨立 Plan-Reviewer 審查。
