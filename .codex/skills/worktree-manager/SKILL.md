---
name: worktree-manager
description: 檢查 Git worktree 狀態並提供受限 lifecycle 指引；不自行變更 Git 狀態。
---

# Worktree 管理

使用此 skill 在工作開始、交接與完成前辨識 worktree 的路徑、branch、HEAD、乾淨狀態與與其他 worktree 的衝突。只有已驗證的唯讀狀態可進入 handoff context。

## 受限 lifecycle

- 開始前確認目標 worktree 與 branch 明確，且不與另一個工作中的 topic 混用。
- 交接前記錄未提交變更與其 topic 歸屬；不明歸屬時停止並交還 human。
- 完成後只回報可供 human 決定後續動作的狀態；不執行清理。

Observer/Dispatcher 對 Git 僅能接收或讀取此狀態並路由，不自行執行 Git。任何建立、移除、切換、修復或其他 worktree／branch 狀態變更，均需由獲授權的非-Dispatcher 角色在相應 human boundary 後執行。

本 skill 不執行會改變 Git 狀態的操作，不執行 commit、push、tag、release 或 post-merge 動作。
