# 路由與 verdict

## 標準 verdict

只使用下列值：

| Verdict | Dispatcher 路由 |
| --- | --- |
| `approved` | 前進到下一個已定義 phase。 |
| `needs-rework` | 只交回對應產出角色，附上 required fix。 |
| `blocked` | 停止自動前進，交還 human。 |
| `human-check` | 停止自動前進，等待 human 決策或確認。 |

Dispatcher 只依上游角色已明示的 verdict 路由，不自行產生、計算或升降 verdict。

## 停止條件

遇到任一情況即停止並交還 human：

- scope、Bounded Context、path 或 locked decision 不明或互相衝突。
- handoff 缺少判斷下一步所需的已驗證資訊。
- 上游結果為 `blocked` 或 `human-check`。
- 所需 Git 狀態變更、外部協調或其他未授權動作。

## 獨立審查

審查者必須獨立於受審產出者。審查發現 drift 時回報 `needs-rework` 與可執行的 required fix，不得直接改寫產出。只有人類能跨越 human boundary 或鎖定新的決策。
