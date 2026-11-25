# PR Reader 單一 PR raw unified diff 步驟帳本

最後更新 2026-11-25。當前 phase 為交付，當前步驟為 RD-S08。Topic 為 `pr-reader-github-raw-unified-diff`，執行基線為 `dev` 的 `612b97ed2ec1344b6bc39eb3b69ff7e245a83742`，分支為 `feat/pr-reader-github-raw-unified-diff`。對話階段的 Planner 規劃準備為 `approved`。正式四檔規劃審查及獨立成果審查均為 `approved`。

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| RD-S01 | completed | Planner | 核對執行基線、獨立 worktree 及詳情端點契約。 | Feature worktree 存在，建立規劃文件前分支乾淨，HEAD 與本機 `dev`、`origin/dev` 指向同一執行基線。唯讀比較確認 #91 保留詳情 GET、URL 與識別驗證契約。 |
| RD-S02 | completed | Plan-Creator | 建立同 slug 的四份正式規劃檔。 | `requirements.md`、`technical-spec.md`、`.plan.md`、`.step.md` 已寫入 feature worktree。 |
| RD-S03 | approved | Plan-Reviewer | 獨立審查四檔、九個欄位、檔案範圍、實作順序、驗收、工具交付及 Human 邊界。 | 獨立 Plan-Reviewer 複核 Archify 候選驗證及 PR Lens light 參數補正後明示 `approved`，無剩餘必修。 |
| RD-S04 | completed | Implementer | 只先落地組合及 factory 驗證，取得 RD01 通過證據再接 Adapter。 | 先加 factory 測試，red 為缺少 `.pullRequestUnifiedDiffREST`。實作固定標頭後，`swift test --only-use-versions-from-resolved-file --filter GitHubHeadersFactoryTests` exit 0，7 項通過，當時兩個 Adapter 檔案均未建立。 |
| RD-S05 | completed | Implementer | 完成獨立 Adapter、測試和長期文件回寫，提供本機工具產物及 fallback 證據。 | Adapter 測試 red 為找不到來源型別。新增套件入口、受控測試及兩份長期契約回寫後，三組回歸共 58 項通過。五項本機審閱證據見下。 |
| RD-S06 | completed | Tester | 驗證 RD01–RD04 及本機工具證據。 | 獨立 Tester 重跑 `RivetPRReaderGitHubTests`、`GitHubHeadersFactoryTests`、`GitHubRestClientTests`，58 項、7 套件全過。Swift format、SwiftLint（196 檔、零違規）及 11 個核定檔空白檢查均 exit 0。已核對本機工具各證據。 |
| RD-S07 | approved | Reviewer | 獨立審查實作、驗收、交付檔案及 Human 條件。 | 獨立 Reviewer 明示 `approved`。已核對 diff/JSON 路徑、原始 bytes、失敗及取消、路徑範圍、基線及本機證據，無必修項。 |
| RD-S08 | in-progress | Implementer | Human 授權條件成立後核對 staged diff 及建議訊息，執行單一 commit、推送分支並開啟及讀回 Draft PR。 | 成果審查完成，按既有 Human 授權核對最終 staged diff，交付單一 topic commit。推送與 Draft PR 的讀回於發布後交接。 |
| RD-S09 | pending | Human | 審閱 Draft PR。 | 待 Human Review。 |

## Blockers

無未解決的產品驗收或審查阻礙。

## 本機審閱證據

- Graphify 0.9.73 以 `GRAPHIFY_NO_AUTO_REFRESH=1` 確認版本。執行基線無相符圖，以原碼核對 `GitHubPullRequestDetailEndpoint`、`GitHubHeadersFactory`、`GitHubRestClient` 及失敗分類。
- Show Me 呼叫樹與實際 Adapter 相符，包含 GET 前後取消、詳情 URL、diff 標頭、REST client 與 Reader 失敗映射。
- Archify 的 `.build/topic-evidence/pr-reader-github-raw-unified-diff/archify/sequence.html` 通過 showcase 9/9，零錯誤與警告。四種桌面尺寸通過，已目視核對 1440×900 亮色與 2048×1320 暗色。獨立 Tester 確認規格／HTML 雜湊與回執一致。
- PR Lens 0.11.0 以同一執行基線與實際 feature worktree 受限 diff 建圖，11 個核定路徑與兩張 SVG 均經讀回。提交後以實際 base/head 重建本機圖。
- Floorplan `floorplan/index.html` 共 565 檔、565 份描述、3 個本 topic 高亮，已在本機瀏覽器開啟。工具未列高嚴重度項目，實驗伺服器的登入檢查因掃描器未辨識路由而略過。

## Human Check

Human 已核准完整對話計畫及執行。當驗收與獨立審查通過、無重大問題且 staged diff 僅包含核定範圍時，預先授權依 `git-commit-convention` 核對 staged diff 的單一語意與建議訊息後，執行一個 topic commit、推送 feature branch 並開啟以 `dev` 為 base 的 Draft PR。授權條件有異時停於提交前回報。Draft PR 建立並讀回後，停在 Human Review。

[執行計畫](pr-reader-github-raw-unified-diff.plan.md)
