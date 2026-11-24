# PR Reader GitHub PR 詳情端點步驟

最後更新 2026-11-24。基線 `dev` `386af9e`，執行分支 `feat/pr-reader-github-pr-detail-endpoint`。首版的獨立規劃與成果審查均已核准。Draft PR #84 的 Human Review 回修已完成驗證，當前步驟為 P09。

| ID | Status | Owner | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 四份同 slug 正式文件落地 | 本 topic requirements、technical-spec、plan 和 step 已於 feature worktree 建立。 |
| P02 | approved | Plan-Reviewer | 獨立核對四份文件、九欄、基線、授權、失敗映射和停止點 | 獨立審查核准，無必修項。 |
| P03 | completed | Implementer | 完成端點、adapter、測試、target 接線及 BC 能力回寫 | 測試先因新型別尚未實作而編譯失敗，實作後 14 項 focused 測試通過。回修後兩個取消競爭案例與 locked target graph 通過。 |
| P04 | completed | Tester | 獨立驗證 TC01–TC04 及計畫列出的 Swift 與 diff 檢查 | 最終 SwiftPM 415 項、54 組通過。Swift 格式、專案 SwiftLint 188 檔零違規、diff check 均 exit 0。全樹 SwiftLint exit 2 的 511 項逐一符合 `386af9e` 基線，新增零項。 |
| P05 | approved | Reviewer | 獨立審查實作、測試證據、文件及範圍 | 取消優先順序與新增 target 的精確依賴兩項必修已回修，獨立複審核准 11 檔，無重大問題。 |
| P06 | completed | Implementer | 提交首版、推送並開 Draft PR | `babf949` 已推送至 [Draft PR #84](https://github.com/a129924/rivet/pull/84)。 |
| P07 | completed | Human | 審閱首版並決定非 `200` 回應的技術分類規則 | Reader 與 PR #81 的 Inbox 共用分類器，Reader Infra 負責映射 `PRReaderFailure`。 |
| P08 | completed | Implementer | 落實 P07，更新 `403` 測試與文件並重驗 | 三個更新案例在首版實作皆失敗。改用共用分類後，Reader、Inbox 與分類器共 69 項測試、10 組通過。Swift 格式、專案 SwiftLint 188 檔零違規、diff check 均 exit 0。 |
| P09 | pending | Human | 審閱 Draft PR #84 的回修 | 待使用者審閱。 |

## Blockers

目前無已知須由 Human 先決定的 blocker。

## 本機工具證據

以下證據對應 Draft PR #84 首版 `babf949`。

- Show Me 以對話版呼叫樹呈現端點、標頭來源、REST 委派和回應映射。
- Graphify 0.9.73 以 `GRAPHIFY_NO_AUTO_REFRESH=1` 執行。feature worktree 缺既有圖，依計畫以限域原碼查證。
- Archify sequence 通過 showcase 9/9、零錯誤與零警告。交付後四種桌面尺寸均無溢出，已目視核對小尺寸亮色與大尺寸暗色截圖。
- Floorplan 涵蓋 546 個程式檔，已描述 546 檔，三個近期工作卡片有標示。本機 HTTP 預覽含 Reader 卡片。地圖的高嚴重度項目為零，實驗伺服器的登入檢查未涵蓋。
- PR Lens 依 topic commit 的實際 base/head 差異製作本機版本。

## Human Check

若須改動公開 Reader Core、放寬 REST 目的地或提前交付部分快照，停下交回 Human。使用者已確認實作無重大問題、staged diff 語意單一且符合範圍時，可以一個 topic commit 推送並開 Draft PR 至 `dev`。提交前須核對 staged diff。Draft PR 送出後讀回，停在 Human Review。
