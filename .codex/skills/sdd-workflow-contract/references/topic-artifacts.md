# Topic Artifacts 契約

## 唯一正式 artifacts

正式 topic 使用同一個 `<topic>` slug，且只承認下列 artifacts：

| 路徑 | 責任 |
| --- | --- |
| `analysis/<topic>/requirements.md` | 產品意圖、範圍、成功條件與尚未鎖定的研究依據。 |
| `analysis/<topic>/technical-spec.md` | 已確認的執行設計、限制與 locked decisions。 |
| `plan/<topic>/<topic>.plan.md` | 本次受限執行契約、檔案影響範圍與驗收。 |
| `plan/<topic>/<topic>.step.md` | 執行狀態帳本：目前 phase、步驟、owner role、完成條件、驗證證據、blocker、verdict 與 human-check。 |

`.step.md` 是正式必備 artifact，不是選擇性附加檔，也不是 approval 的替代品。每個 step 必須具備 ID、status、owner role、完成條件與驗證證據；帳本必須包含 Blockers、Human Check 與最後更新資訊。checkbox、step status 或 tracker 檢查結果絕不等同 `approved`。

`analysis/` 不取代 execution contract；`plan/` 不取代長期文件。仍成立的架構結論依 repository 規範回寫 `docs/`。

不得將 release、VERSION、summary 或 correction artifacts 設為必要條件。

## 角色與階段

| Phase | 產出或檢查角色 | 下一步 |
| --- | --- | --- |
| 規劃準備 | Planner、Explorer | 交 Plan-Creator。 |
| 規劃編寫 | Plan-Creator | 交獨立 Plan-Reviewer。 |
| 規劃審查 | Plan-Reviewer | 依 verdict 前進、回修或停止。 |
| 實作 | Implementer | 交 Tester。 |
| 驗證 | Tester | 交獨立 Reviewer。 |
| 成果審查 | Reviewer | 依 verdict 前進、回修或停止。 |
| 人類邊界 | Human | 等待明確人類決策。 |

Plan-Creator 與 Plan-Reviewer 必須是獨立角色；Reviewer 不得審查自己的產出。Implementer、Tester 與 Reviewer 也須維持獨立審查關係。

## 最小交接內容

交接時提供下列 JSON；只填已驗證的資訊：

```json
{
  "topic": "<topic>",
  "phase": "<phase>",
  "artifacts": [{"path": "<path>", "status": "present|missing|changed"}],
  "current_step": {"id": "<step id>", "status": "<explicit status>"},
  "locked_decisions": ["<confirmed decision>"],
  "upstream_verdict": "approved|needs-rework|blocked|human-check|null",
  "blockers": ["<unresolved blocker>"],
  "assigned_role": "<role>",
  "next_objective": "<bounded objective>"
}
```

`artifacts` 必須列出四份正式 artifacts。`locked_decisions` 不得含未驗證推論；沒有上游 verdict 時使用 `null`。`current_step` 只記錄帳本中明示的值，不得由 Dispatcher 推導或修改。
