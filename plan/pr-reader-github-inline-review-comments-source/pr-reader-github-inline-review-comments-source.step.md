# 單一 PR 的 REST 行內審閱留言步驟帳本

最後更新 2026-11-26。Phase 為交付，目前步驟 IC-S06。基線 `2764e64`，分支 `feat/pr-reader-github-inline-review-comments-source`。

| ID | 狀態 | 角色 | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| IC-S01 | completed | Plan-Creator | 建立同 slug 四檔、核對範圍 | 遠端 `dev` 比對一致，四檔在獨立工作樹建立。 |
| IC-S02 | approved | Plan-Reviewer | 獨立審查實際四檔及九欄 | 獨立審查核准，四檔、八路徑、驗收、五項工具及停點一致，無必修項。 |
| IC-S03 | completed | Implementer | 依九欄完成讀取、測試及本機審閱產物 | Red 確認缺少讀取入口與結果型別。Green 16 項通過。補齊五項本機審閱證據，驗收後回寫 BC 契約。 |
| IC-S04 | completed | Tester | 執行 IC01–IC04 並核對審閱證據 | 獨立 SwiftPM 117 項、11 組通過，涵蓋 16 項新測試、相鄰來源及 #99 端點。嚴格格式通過，SwiftLint 219 檔零違規，含未追蹤檔的空白與差異範圍核對通過。Show Me 與實際原碼一致。 |
| IC-S05 | approved | Reviewer | 獨立核對實際差異及 Tester 證據 | 獨立 Reviewer 核對八項路徑及兩支 Swift 檔案 SHA-256，分頁、結果及失敗契約一致，無必修項。 |
| IC-S06 | in-progress | Implementer | 單一 topic commit、推送及 Draft PR 讀回 | 驗證與成果審查已通過。此帳本記錄交付前證據，提交、遠端分支及 Draft 狀態以交付後讀回為準。 |
| IC-S07 | pending | Human | 接手 Draft PR 審閱 | Draft PR 讀回後交還 Human。 |

## 本機審閱證據

- **Archify**｜`.build/topic-evidence/pr-reader-github-inline-review-comments-source/archify/inline-review-comments.html`。sequence、繁中內容與英文 viewer。Showcase 9/9、零錯誤警告，四種桌面尺寸通過，最小與最大各亮暗畫面目視通過。修正兩輪。規格 SHA-256 `cdd59249081900b5f3ced7e651311a02f744176d4f526692016ec57cf9850c37`，HTML SHA-256 `2b57a26cefd188a86c71a5bf2bdd23107738e318c13545a4394474c7f4eefe5f`。
- **PR Lens**｜0.11.0 在外部暫存目錄對基線 `2764e64` 的八檔 bounded diff 完成 validate 與亮色 render。已讀回 manifest，1 張 SVG、2 lanes、7 nodes、6 edges。Draft PR 讀回後依實際 base／head 核對本機圖。
- **Graphify**｜確認固定版 0.9.73。沒有可追溯受查版本的現有 graph，以 `rg` 和原碼核對入口、既有 GET 端點、Link parser、原 PR 詳情與 client。
- **Show Me**｜已核對入口 → 端點 URL → 檢查取消後 GET → 映射留言 → 分頁核對 → 首次數字 ID 查核原 PR → 重建續頁或一次性交付。取消與後頁失敗皆只回單一 failure。
- **Floorplan**｜`floorplan/index.html` 在獨立工作樹重建並用本機預覽開啟。588/588 程式檔說明、62/62 模組、0 未分配。新增五步讀取流程，Recent work 僅兩張本 topic 卡。未偵測伺服器路由，路由登入檢查無資料可驗。

來源 SHA-256 `46aff331de505ee054cb1de100c6c482f85c8cef934aa5e4a640f24d80001f3c`，測試 SHA-256 `2fab4046b2694c0451f7ed61e5ffd68fa95153f305d29bbf64d8e2ddbd749e23`。

## Blockers

產品驗收與範圍審查無阻塞。

## Human Check

Human 已授權在無重大問題且差異符合九欄時，直接提交單一 topic commit、推送與開 Draft PR。語意提交訊息為 `feat(pr-reader): 讀取單一 PR 的行內審閱留言`。Draft PR 讀回後停在 Human Review。
