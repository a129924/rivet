# 將單一 GitHub 通知標記為已讀步驟帳本

最後更新 2026-11-27。Phase 為交付，當前步驟 NR-S06。分支 `feat/github-notification-mark-as-read`，基線 `a559f7a69f2fda6d25c6e50298905f777cd831b4`。發布前驗收基線快轉至 `4261f9c55faf5ce0194906fcea45fb47de5b2574`。

| ID | 狀態 | 角色 | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| NR-S01 | completed | Plan-Creator | 依對話計畫起草並讀回同 slug 四份正式文件 | Human 接受含 internal Endpoint 的對話計畫，四份文件已起草並讀回。 |
| NR-S02 | approved | Plan-Reviewer | 獨立審查工作樹上四份文件、九欄、兩個型別責任、產品驗收及授權 | 獨立 Plan-Reviewer 對實際四檔明示 approved，無必修項。Human 核准的兩組精確 allowlist 調整亦經獨立規劃複核 approved。 |
| NR-S03 | completed | Implementer | 依契約完成兩份 Swift 來源與測試，留下本機輔助證據 | 已新增兩份 Swift 來源及同一份測試。Focused red exit 1，因兩個型別尚未實作。Green exit 0，11 項通過。 |
| NR-S04 | completed | Tester | 獨立執行 NR01–NR04。產品驗收後由 Implementer 回寫 Catalog，Tester 再核對最終差異及本機證據 | 獨立 Tester 確認 NR01–NR03 通過。最終 PR 基線獨立回歸 340 項、39 suites 全過。Format、SwiftLint 619 檔零違規及差異檢核 exit 0。Catalog 已回寫，Tester 確認僅單筆 PATCH、既有讀取段落保留，最終九檔範圍通過。 |
| NR-S05 | approved | Reviewer | 依 Tester 證據核對九欄、實際差異與產品驗收 | 獨立 Reviewer 明示 approved，無必修項。 |
| NR-S06 | in-progress | Implementer | 依條件式授權完成單一 topic commit、push、Draft PR 與讀回 | 單一 topic，訊息為 `feat(github-integration): 支援將單筆 GitHub 通知標為已讀`。Commit SHA、Draft PR 與 PR Lens 收據在提交後記於本機交付證據。 |
| NR-S07 | pending | Human | 接手 Draft PR 審閱 | 待 Draft PR 建立及讀回。 |

## Blockers

目前無已知 blocker。Human 已於 2026-11-27 核准在 `StaticIsolationTests.swift` 的兩個允許清單各新增兩個本案來源。獨立規劃複核已批准，Tester 確認其餘來源與匯入規則保留。重大問題、驗收未達標或超出 topic 邊界時停在提交前。

## 證據

- Swift red、green 與獨立回歸紀錄放在 feature worktree 的 `.build/topic-evidence/github-notification-mark-as-read/`。原基線首次回歸僅 `targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports` 失敗。最新版回歸證據為 `tester-swift-pr-base.log`，該測試及其餘套件皆通過。
- Archify 本機 sequence 在同一證據目錄的 `archify/`，showcase 9/9、錯誤及警告均為零，四種尺寸的自動檢核通過，已檢視最小和最大尺寸亮暗截圖。Viewer 為英文。
- Graphify 0.9.73。預設位置沒有對應的本機圖，依計畫用 `rg` 與原碼核對直接依賴，證據為 `graphify-navigation.txt`。
- Floorplan 副本已更新，本案三份 Swift 卡片均有說明，Recent work 標記兩份產品碼。以最新基線刷新後再核對三個本案卡片。本機已開啟 HTML 預覽，全圖既有說明缺口另列。
- PR Lens 0.11.0 待提交後以實際 base/head 產出本機變更圖，保留驗證、渲染及 manifest 證據。
- `$show-me` 依兩份新 Swift 來源與 focused 測試核對。

```text
GitHubNotificationReadMarker.markAsRead(threadID:using:)
  GitHubNotificationMarkAsReadEndpoint.init(threadID:)
    無效 ID → adapter 回報無效識別，零 transport
    有效 ID → .patch 和固定 HTTPS URL，無 query
  adapter 取得目的地 → .standardREST 和 Bearer
    提交前已取消或組裝失敗 → 零 transport
    提交 raw HTTP transport 一次，無 body
      205 → 確認已讀
      其他回應或中斷 → 依契約映射
```

## Human Check

Human 已接受含 internal Endpoint 的對話版計畫，授權於獨立 feature worktree 實作，並明示使用 `$pr-lens` 與 `$graphify`。在產品驗收及獨立成果審查無重大問題、staged diff 符合九欄與單一 topic 語意邊界時，授權依 `$git-commit-convention` 核對 staged diff、提出並記錄訊息後，直接完成一個 topic commit、推送分支、建立以 `dev` 為目標的 Draft PR。Draft PR 建立並讀回後交還 Human Review。 [執行計畫](github-notification-mark-as-read.plan.md)
