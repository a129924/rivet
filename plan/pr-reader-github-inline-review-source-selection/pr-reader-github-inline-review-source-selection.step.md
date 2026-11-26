# PR Reader 行內留言來源選擇步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 IS-S06。分支 `feat/pr-reader-github-inline-review-source-selection`，執行基線 `10610d0be88c1d2bce37d5418fa5bae3171f8526`。

| ID | 狀態 | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| IS-S01 | completed | Plan-Creator | 在獨立 worktree 建立四份同 slug 規劃文件 | 本機及遠端 dev 基線一致，四份文件已建立。 |
| IS-S02 | approved | Plan-Reviewer | 獨立審查四檔、九欄、範圍與驗收 | 獨立 Plan-Reviewer 明示 approved，無必要修正。 |
| IS-S03 | completed | Implementer | 交付入口、測試及本機審閱材料 | 兩種結果、切換、取消與文件回寫已完成，初次完整回歸 171 項通過。 |
| IS-S04 | completed | Tester | 獨立執行 IS01–IS06 並核對本機材料 | 親跑 171 項、16 suites，含 9 項新測試。嚴格格式、SwiftLint 585 檔零違規、兩種 diff check 均 exit 0。獨立核對 IS01–IS06、七個範圍內檔案與五項本機補充，無必要修正。 |
| IS-S05 | approved | Reviewer | 獨立核對驗收證據及完整差異 | 獨立 Reviewer 明示 approved，無必要修正。確認七個暫存路徑、同一 PR、原 Task 取消、完整分頁與五項本機證據。 |
| IS-S06 | pending | Implementer | 條件式單一提交、推送、開啟並讀回 Draft PR | 驗收及獨立審查已通過。建議訊息為「feat(pr-reader): 選擇行內留言讀取來源」。提交後以本機忽略的交付收據記錄實際 base／head、Draft PR 讀回與 PR Lens 重驗。 |
| IS-S07 | pending | Human | 接手 Draft PR 審閱 | 待交付。 |

## Blockers

目前無已知阻塞。

## 實作與本機證據

- 紅燈由空 GraphQL 案重現，當時占位入口回 `.unavailable` 且未發送 GraphQL。正式接線後，範圍內回歸共 171 項、16 suites 通過，含 9 項新入口測試。嚴格 Swift 格式及 SwiftLint 通過，SwiftLint 檢查 585 檔。
- Archify 交付 `.build/topic-evidence/pr-reader-github-inline-review-source-selection/archify/inline-review-source-selection.html`。繁中 sequence、英文 Viewer。Showcase 9/9、零錯誤警告。一次修正桌面溢出後，四尺寸 containment 通過，已目視最小和最大尺寸的亮暗四張畫面。規格 SHA-256 `61dbe8c605dea8c616e3f2f0fc2bb9890a4562af4f0d8d679da2f1c330c1a10e`，HTML SHA-256 `6bdf5a2faebb51851843d7bc8964d5cf6b14a77e956422e334111d0c3a029ec4`。
- PR Lens 0.11.0 以實際基線及本機差異驗證 graph，渲染 1 個淺色 SVG。留存 graph、SVG 與 manifest，待提交後以實際 base／head 更新。
- Graphify 0.9.73 已核對版本。工作樹與原工作樹的預設位置均無既有圖，使用 `rg` 與原碼核對兩個來源、同一識別、原 Task 及取消停點，並以受控請求確認。
- Floorplan 在獨立工作樹更新。檔案描述 956/956、模組 62/62、未分派 0、Recent work 2 張本題卡片、本機瀏覽器已開啟。Health 無高嚴重度項目，endpoint 登入掃描未涵蓋未辨識的實驗伺服器入口。地圖範圍為程式碼。

### Show Me

    fetchInlineReviewContent(for:)
      已取消 → .unavailable
      fetchReviewThreads(for:)
        返回後已取消 → .unavailable
        成功 → .graphQLThreads
        .notReadable／.contentNotRepresentable → 原失敗
        .unavailable 且尚未取消 → fetchInlineReviewComments(for:)
          返回後已取消 → .unavailable
          成功 → .restComments
          失敗 → 原失敗

## Human Check

Human 已確認對話計畫，授權獨立工作樹實作。驗收與獨立審查無重大問題且 staged diff 符合本 topic 時，按計畫完成單一 commit、推送和 Draft PR，讀回後交還 Human Review。公開契約、既有來源行為或 tracked 範圍有變動時停待裁決。 [執行計畫](pr-reader-github-inline-review-source-selection.plan.md)
