# 按需讀取 GitHub 未讀通知｜步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 `N-S06`。分支 `feat/github-unread-notifications-source`，執行基線 `fa3329bfe78be069633d8e08a74ecc4389ab386c`。 [需求](../../analysis/github-unread-notifications-source/requirements.md) · [技術規格](../../analysis/github-unread-notifications-source/technical-spec.md) · [執行計畫](github-unread-notifications-source.plan.md)

| ID | 狀態 | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| N-S01 | completed | Plan-Creator | 在獨立工作樹建立四份同 slug 檔案。 | 四檔已寫入並讀回，基線為當時的 `origin/dev`。 |
| N-S02 | completed | Plan-Reviewer | 獨立審查四檔及必要修訂。 | 四檔審查與兩次隔離測試清單修訂均為 `approved`，無 required fix。 |
| N-S03 | completed | Implementer | 先完成 Endpoint 與獨立測試，再串接 Source、PageLinks 與受控測試，回寫 Catalog。 | Endpoint 的 red 是缺少型別，green 為 3 項。來源的 green 為 11 項。既有隔離測試使用本題四筆精確來源與三筆匯入許可。 |
| N-S04 | completed | Tester | 獨立驗證 `N01`–`N04` 並覆核本機證據。 | 328 項測試、38 個 suite 全數通過。Swift format、嚴格 SwiftLint（610 檔、0 違規）及 staged／unstaged diff 檢查皆通過。 |
| N-S05 | completed | Reviewer | 核對實際差異、九欄、產品驗收與本機審閱證據。 | `approved`。14 個變更檔符合九欄，未發現須阻擋交付事項。 |
| N-S06 | in-progress | Implementer | 核對 staged diff 與訊息，依授權提交、推送及建立 Draft PR。 | 實際 commit 與 PR 狀態由 Git 與 GitHub 留存。 |
| N-S07 | pending | Human | 審閱 Draft PR。 | 待 Draft PR。 |

## Blockers

既有靜態隔離測試的來源清單與逐檔匯入清單已補齊，並移入通知專屬測試擴充檔以符合嚴格 SwiftLint。已獨立重跑通過。

## 本機證據

- **Archify 2.16**。Sequence 交付為 showcase 9/9、零錯誤／警告，四種桌面尺寸通過。已目視最小與最大尺寸的亮暗畫面。產物 SHA-256 `aea84d0ad6cdcdd85b2f94d43e16a4d6ea6d52b0d6cd25b22ed85ca59646115a`。
- **PR Lens 0.11.0**。待取得本題實際 commit 與 Draft PR 後，在外部暫存目錄製圖與驗證。
- **Graphify 0.9.73**。工作樹無可用既有圖，已用 `rg` 與原碼核對 Source、Endpoint、PageLinks、REST 標頭與轉址拒絕。
- **Floorplan**。feature worktree 副本已更新並預覽。Recent work 標示四個通知來源檔，本題七個 Swift 新檔都有說明。全圖說明 543/983，無高嚴重度 Health 項目。Endpoint sign-in 因掃描器未辨識驗證工具的端點而未檢查。

### Show Me

```text
Source.list(using:)
├─ Endpoint.makeURL() → 固定首頁
├─ 以標準 REST 標頭與同一 Bearer 送出並解碼每頁
├─ PageLinks.nextPage(link:after:) 驗證 Link
│  └─ 取得可信頁碼 → Endpoint.makeURL(page:) → 讀取續頁
├─ 確認終頁 → success(完整清單)
├─ 讀取或映射失敗 → failure(分類)
└─ 偵測取消 → cancelled
```

## Human Check

Human 已核准本計畫、獨立工作樹實作及本機 PR Lens／Graphify。若驗證或獨立成果審查發現重大問題，或 staged diff 超出單一 topic 語意，停在提交前。若條件成立，本輪授權涵蓋一次 commit、push 與開 Draft PR。讀回 Draft PR 後交 Human Review。真實 PAT 驗證未獲授權。
