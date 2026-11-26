# C／D Design Language 驗證

## 基線與範圍

- Feature branch 為 feat/rivet-design-language-adoption。Git 基線為 ee836106e7256d2a209647916103dd5a73d4c8af，另封存 HC-02 採用的四份 A／B evidence 及 C02 複審通過的四份 planning artifacts。四份 A／B 證據和三份 planning ReadOnly 文件 SHA-256 逐檔吻合。Index 為空。
- 唯一修改的既有 production 檔是 Sources/Presentation/Login/RivetLoginArtwork.swift。其餘 Swift 變更為契約允許的兩個 internal 檔及一份必要的表格測試。套件、Inbox、Reader、原 Native Interaction Contract、Login 公開介面、既有驗收工具的 delta 為零。正式的視覺責任記錄在 [Visual Design Contract](../../../docs/presentation/visual-design-contract.md)。
- Canvas 原繪圖邏輯對照吻合，差異為顏色來自參數、frame 來自 size。Login 傳入 22 pt 與 #CBE7FF。原 36 pt tile、wordmark、無障礙隱藏及 Login-only 色值仍在原使用端。這項靜態對照留待原生 after 圖比對。

## 非互動驗證

環境為 macOS 26.5.2、Xcode 26.6、Swift 6.3.3，Apollo 固定 2.1.2。SwiftPM 建置與測試使用 checkout 外的 scratch、module cache 及既有 Apollo pinned cache，禁止 HTTP／HTTPS 依賴回退。

| 步驟 | 命令核心與結果 |
|---|---|
| Palette red | swift test --filter RivetPaletteTests，exit 1。新測試在提取前無法解析 RivetPalette。 |
| DL-S03A | swift test --filter RivetPaletteTests，exit 0。兩組 appearance 各驗證四角色解析成 sRGB RGB／alpha。 |
| DL-S03B Debug | swift build --target RivetPresentation，exit 0。 |
| DL-S03B Release | swift build -c release --target RivetPresentation，exit 0。 |
| DL-S02D focused Login | swift test --filter 'RivetLogin(Content\|Presentation\|Typography)Tests'，exit 0，9 tests／3 suites。 |
| DL-S03B target isolation | swift test --filter packageDeclaresTheLockedTargetGraph，exit 0。 |
| DL-S03B root | swift test，exit 0，545 tests／68 suites。 |
| 格式、lint 與 scope | 四個受影響 Swift 檔的 strict swift format、strict SwiftLint 及 git diff --check 均 exit 0。以合成基線逐路徑檢查 tracked、index 與 untracked，新增和修改限核准範圍。 |

## 新 Login 驗收 artifact

使用既有 tools/acceptance/login-ui/scripts/build-app.sh 建置，來源 manifest 錨定本次未提交的 feature worktree bytes，已封裝正式的 RivetPresentation 資源。

| 欄位 | 值 |
|---|---|
| App | login-after/native/RivetLoginAcceptance.app |
| Bundle ID | local.rivet.login-ui-acceptance |
| Source manifest SHA-256 | ba879638b5a75f12a732e6649722783ff686daff833a2b33cc7dc946dc0c7839 |
| Binary SHA-256 | 639447811f0640913da0d4c77ff74097308568f019c15acc5f667cb0cee7301a |
| App tree SHA-256 | 9eeba387f2e1ba55594d2647df961614f77bf5c5cf254aa9e25ddd8664e37e11 |

CD02 獨立來源審查為 approved，核對 30 份來源、25 個連結物件與資源。PDF 和 scratch／來源內容相符，App tree 及 binary SHA 複算相符。建置收據的 nativeLaunch: not-run 只記錄建置時狀態。HC-04 已另取得明示啟動授權，實際結果如下。

Graphify 0.9.73 以外部暫存的五份核准 Swift 來源建立 code-only AST 圖，81 nodes／132 edges。查詢後回查原始碼，來源 SHA 與命令留在外部收據。

## HC-04 與八組前後比對

Human 明示允許啟動上述 exact App。啟動前重算 binary、App tree 與 30 份 worktree source，結果符合 CD02。八組 after 逐一使用同一新 binary 的獨立程序，逐次只擷取該程序的 Login 視窗，擷取後關閉。使用同機、standard copy、相同的 780 × 500 pt 內容尺寸、appearance、fixture 與字級。[八張 before](login-baseline.png) 與 [八張 after](login-after.png) 順序一致。

| 格 | 場景 | Appearance | 字級 | 解碼為 sRGB 8-bit RGBA 像素後的比較 |
|---|---|---|---|---|
| 1 | Welcome | Light | 17 pt | 0 像素差異 |
| 2 | Welcome | Dark | 17 pt | 0 像素差異 |
| 3 | PAT | Light | 17 pt | 0 像素差異 |
| 4 | Waiting | Dark | 17 pt | 差異限進度轉圈動畫範圍，1,288 像素 |
| 5 | Browser failure | Light | 21 pt | 0 像素差異 |
| 6 | Token failure | Light | 21 pt | 0 像素差異 |
| 7 | Welcome | Light | 13 pt | 0 像素差異 |
| 8 | Welcome | Light | 21 pt | 0 像素差異 |

原始尺寸均為 1,560 × 1,064 px（含 titlebar）。等待轉圈差異位於原始圖的 x=730–793、y=241–304，已視檢對應動畫圖示。其餘 Waiting 畫面維持相同；八組畫面的 glyph、tile、wordmark、排版、色彩與前景未觀察到非預期差異。四組 Welcome 的 GitHub 圖示均可見且與 before 像素一致，建置時 PDF bundle 也已獨立核對。此觀察涵蓋當次 fresh process 的資源顯示，未另行隔離 SwiftPM bundle fallback。

After 合成圖 SHA-256 為 3a57a9066b30f254e2626f3131ef5bd5b22d209d801faa4ca4e3e7b7019b76e8。原始單張、擷取參數、程序／window 記錄及每格像素差異報告留在 checkout 外。

獨立 Tester 已核對八組配置、獨立程序／視窗、七張原始圖、Waiting 差異範圍、合成圖 SHA、各建置／測試結果及凍結的 A／B 證據。獨立 Tester 核對可觀察的非語音證據。VoiceOver 結論依下列 Human 實聽回報。

## 合成原生互動

以下案例以同一 exact App 的 Light／21 pt、standard copy，運用既有工具 fixture，沒有真實 PAT、GitHub 頁面或認證服務。

| 項目 | 觸發與觀察 | 範圍 |
|---|---|---|
| DL-S02A 空欄與顯隱 | 由 Browser failure 的 PAT 入口到達空 secure 欄位，欄位取得焦點，Connect to GitHub 為 disabled。空欄按 Return 保持 showTokenEntry／Count 3。輸入合成內容後可提交。Show 顯示並選取原合成內容，可直接輸入替換，未點欄位。Hide 回到具焦點的 secure 欄位，內容保留且仍可提交。 | AX、實際按鍵與控制項狀態。只記結果及 event kind／count。 |
| DL-S02A 提交、失敗與返回 | 具合成內容時以 Return 進入 Verifying token，工具記 submitToken／Count 4。由 Acceptance 選單切換 Token failure，錯誤可讀且焦點回到空 secure 欄位，提交停用。Back 回 Welcome 且主要按鈕取得焦點，重進 PAT 可直接編輯。 | 正式 View 的 intents 經受控 parent，不涉及真登入。 |
| DL-S02B Retry／Cancel | Browser failure 的 Try again 進 Waiting，Cancel sign in 取得焦點。Escape 回 Welcome，主要按鈕取得焦點，工具記 cancelSignIn／Count 2。另由 browser failure 的 Use a personal access token 進 PAT，工具記 showTokenEntry。 | 實際按鍵、階段、focus 與 receipt。代表性 Cancel 走 Escape。 |
| DL-S02B 長內容與對比 | 21 pt 的 PAT 與 Token failure 捲動到最底，scrollbar 值為 1，可見底部提交控制與 footer。Increase Contrast 由 off 切到 on，PAT 焦點環、欄位文字與停用提交在已擷取的畫面中可辨。之後確認 Increase Contrast 與隨動的 Reduce Transparency 均回到原本 off。 | 原生 AX 與工具畫面。測的是 Login，Variant B 的原始缺口不在此驗收結果內。 |
| DL-S02C VoiceOver | Human 已回報三項實聽皆通過。案例涵蓋 Welcome／Waiting／Escape 返回 Welcome、PAT Show／Hide、Browser failure 與 Token failure。 | 直接採用 Human 的通過回報。回報粒度為三組結果，未提供逐字朗讀或各控制項的詳細語音紀錄。 |
| DL-S02D API／資源 | 公開介面及 phase／intent 接線的來源無差異，既有 9 項測試通過。已授權 fresh process 的 Welcome 實際顯示 GitHub 圖示。 | 該 App／該環境，未隔離 bundle fallback。 |

原生操作結束時，App 留在 Welcome，焦點為 Continue with GitHub，最後事件為 backToWelcome／Count 7。Human 再依三組案例實聽。我協助切到 Browser failure，原生 AX 顯示焦點為 Try again。Human 回報「上述 三個測試 皆為通過」。Variant B 的七項原生缺口維持 [A／B 採用範圍](visual-review.md)，交由未來 Inbox 自有規劃處理。

## Phase E 審閱與 Inbox 移交

獨立 CD04 審查為 approved，無必要修正。審查核對 scope、A／B 證據、Swift 依賴、八組圖片、建置與測試、合成原生案例及三組 Human 實聽回報。結果供 HC-05 最終審閱。

Human 審閱 [Visual Design Contract](../../../docs/presentation/visual-design-contract.md)、[Native Interaction Contract](../../../docs/presentation/native-interaction-contract.md)、[八張 before](login-baseline.png) 與 [八張 after](login-after.png)，並依本文件的原生、測試及差異證據作最終接受決定。

後續 PR Inbox topic 的移交清單：

1. 於本 topic 合併後同步 dev，核對已採用的 Variant B 與 internal Design Language。
2. 依自有範圍修訂計畫，鎖定使用的四色及 compact glyph、精確路徑與原生互動驗收，完成獨立 Plan Review。低對比 Border 方向及 symbol-only 的位置各按現有待決界線處理。
3. 在 Inbox 自有驗收逐案處理 Variant B Light 鍵盤、非預設 accent、Increase Contrast、Reduce Motion、跨 App key-window／inactive、VoiceOver 實際朗讀與完整 Variant B 窄版。既有 420 pt 候選及 Login 的實聽證據各保留本身的涵蓋範圍。
