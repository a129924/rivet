# OAuth 啟動還原圖與受控證據

## 來源與界線
來源為本 topic technical-spec 與新增正式 actor/outcome；既有 provider／scope／store policy 不變。作者內容繁中；Archify 固定 Viewer UI／HTML lang 為 English fallback。
責任 canvas：scene.js → index.html。Lifecycle：restore-lifecycle-v3.json → restore-lifecycle-v3.html。

## 重現
於 repository root 使用已安裝 skills：
- architecture-canvas/scripts/validate.js 本目錄 scene.js；通過後 scripts/build.js 產本目錄 index.html。
- archify/bin/archify.mjs validate lifecycle 本目錄 restore-lifecycle-v3.json --quality showcase --json。
- 同 CLI deliver lifecycle 規格 HTML --quality showcase --json。
- 同 CLI visual-check HTML --repo-root . --json；不可修改已交付 HTML。

## 結果
責任 canvas：5 bands、11 boxes、10 edges，0 errors／warnings；已建置並以本機 Chrome 截圖目視檢查，節點與連線可辨識。圖為可縮放導覽，不宣稱產品 UI 已接線。
Lifecycle：完整 9 checks showcase，收據記錄原始 specification／artifact SHA-256。四尺寸 containment 與淺深主題 captures 由 visual-check sidecars 記錄；自動 visualReview 一律保持 pending，與 agent 目視及 Human 接受分開。Agent 已實際檢視 1440×900 light 與 2048×1320 dark，visual_review: passed；Human 視覺接受仍 pending。
初版 overflow／中間候選未作 trusted 交付；保留於系統暫存，不混入本次最終圖。

## 受控 Swift 驗證
獨立 Tester 親跑：root swift test 375 tests／46 suites；consumer 22 tests／6 suites；strict Swift format 通過；明確159個專案Swift檔 strict SwiftLint 0 violations；diff check 通過。
原 lint script 在 consumer build 後會遞迴第三方 .build/checkouts，初次 lint 失敗保留；未修改 script／config／vendor。替代證據為相同專案roots下tracked＋本topic新增Swift明確清單（排除build cache）的strict lint。後續正式consumer hook使用獨立scratch並清理fixture build後，原canonical lint再次執行亦為159檔、0violations。首次renderer hook因新worktree缺biome失敗；依現有frozen lockfile安裝本機依賴，未修改來源或lockfile。
首次 red：新入口未存在導致 cannot find GitHubOAuthStartupRestorer；新增正式實作後第一個測試 green，之後擴充到17個owner tests及3個consumer tests（另含參數case）。
既有 Sources 與 manifests zero diff；既存 StaticIsolation expectedPaths 僅登記兩個新增檔。

## Floorplan / Graphify / PR Lens
Floorplan 本機 ignored、不commit：先由technical-spec建立4planned-files blueprint，後轉13files bounded code-map（新增4＋直接依賴9），0 unassigned，13/13 descriptions；routes 0/0，無新增HTTP endpoint。全repo inventory掃描不等於全repo地圖；614項由ignore排除，docs/config/assets等不在map範圍。
Health無high severity finding；工具提示 E013 的既有診斷工具看似server但未解析到endpoint，故endpoint sign-in未檢查，不能宣稱安全審查通過。此topic不修其他研究工具。Swift同module呼叫不是完整靜態語義圖；重要連線均回原碼查核。
Graphify 0.9.73 可用，但無既有可用graph，依skill採rg／原碼fallback，未建立graph、未semantic/provider/network。
PR Lens 0.11.0 僅針對實際commit diff產本機暫存graph/SVG；不發布、上傳、修改config或代替review。實際base/head於完成commit後在交接中回報。

## Human boundary
未做live OAuth／DPK／E014、產品UI或遠端權限驗收。Human最終topic與圖視覺接受待Draft PR review。
