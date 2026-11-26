# Design Language 視覺審閱

- Baseline 為 dev 2764e64a77732902693b7890b346b2f3fa3f487d。環境為 macOS 26.5.2（25F84）、Xcode 26.6（17F113）、Swift 6.3.3。
- 本輪審閱對象是 A／B 的候選。Phase C／D 的採用內容、Swift 路徑與 Login 前後等效測試，依 Human 採用結果修訂。
- I1 的 E024 是 9610830 上的獨立驗證。容器背景、測試紀錄區、fixture 狀態與尚待補證的 I1-08 各自保留原有來源。 [I1 Draft PR #97](https://github.com/a129924/rivet/pull/97)

## Login 色值盤點

| 角色 | Light | Dark | 基線用途與候選處置 |
|---|---|---|---|
| Background | #FCFDFF | #161C26 | Login 內容背景，候選用作控制項外的工作區背景 |
| Primary | #192533 | #F4F6FA | Login 內容主要文字，候選用於工作區標題及品牌 glyph |
| Secondary | #647386 | #9AA9B9 | Login 說明、連結與輔助文字，候選用於工作區說明 |
| Border | #E1E7EE | #323C49 | Footer 與 PAT 欄位邊界，先保留 Login 責任 |
| Surface | #F1F4F8 | #222C39 | Login 狀態圖示底色，先保留 Login 責任 |
| Field | #FFFFFF | #19232E | PAT 欄位，保留 Login 責任 |
| Button | #252B33 | #F3F6FA | Login 主要按鈕底色，保留按壓、停用與 Increase Contrast 行為 |
| Button label | #FFFFFF | #19212C | Login 主要按鈕文字，保留 Login 責任 |

八組值以 sRGB 從 RivetLoginArtwork.swift 的 RivetLoginPalette 核對。文字角色以 LoginStyles.swift 與 RivetLoginView.swift 的實際使用位置追溯。既有 branch mark 使用 36 pt tile、22 pt glyph、#CBE7FF 描邊。候選完整沿用 glyph 的三個圓、直線與曲線控制點，在 Light／Dark 表面比較 22／16 pt 與主要前景色。Login 的深色 tile、wordmark、插畫、裝飾和無障礙隱藏語意維持原有歸屬。

Login 的 heading、eyebrow、說明與按鈕使用依 13–21 pt 字級設定縮放的系統字體。40:60 採 Login 版面規則。Inbox Header 使用 title2／subheadline，Row 採 headline／subheadline／caption 與單行尾截斷，依 620／480／340 pt 降階。候選用標題、列標題及 metadata 比較工作區的密度，16／24 pt 分別示範元件內距與區塊間距。數值供審閱，字級、降階與 spacing 各由畫面持有。

## 比較圖

[Design Language 與 Inbox 基線](design-language-candidate.png)

| 格 | 畫面 | 來源 |
|---|---|---|
| 1–3 | Samples Light、Inbox Light 760／420 pt | 單檔候選原生視窗 |
| 4–6 | Samples Dark、Inbox Dark 760／420 pt | 單檔候選原生視窗 |
| 7、9 | InboxHeader Light／Dark | Xcode Canvas、RivetPresentation scheme、Standard · Needs Review |
| 8、10 | PullRequestList Light／Dark | Xcode Canvas、RivetPresentation scheme、Six PRs and Open probes |

候選的背景與標題帶入 Login 的冷灰藍色階，List 內容表面保留系統色，分隔線、選取與 Picker 隨原生外觀。420 pt 的長標題保留單行並出現尾端省略，metadata 仍可閱讀。Canvas 中 Header 的 filter 文字與 List 的 Open probes／紀錄區由各自的 preview wrapper 提供，產品元件使用其內的標題、控制項及列內容。

重現候選的編譯方式見執行契約。從 checkout 根目錄編譯後，用下列參數啟動視窗：

    "$preview_run/RivetDesignLanguagePreview" --view inbox --appearance dark --width 760

樣本切換為 samples，明暗使用 light 或 dark，Inbox 寬度使用 760 或 420。重現 Canvas 時選擇 RivetPresentation scheme，以 Device Settings 的 Color Scheme 覆寫切換明暗，分別匯出兩個指定的 preview。預設 Rivet-Package scheme 曾選到 RivetLoginDemo 並要求 ENABLE_DEBUG_DYLIB。指定 Presentation scheme 後，四張圖均成功匯出。

## 驗收結果

| ID | 結果 | 證據 |
|---|---|---|
| DL-01 | 通過 | 八組 sRGB 與既有責任可追溯，兩個指定 Preview 共四張 Canvas 匯出。 |
| DL-02 | 待 HC-01 | 現行獨立 Login 驗收 App 已建置。AB02 獨立來源審查比對 28 筆輸入 SHA、6 筆 bundle entries 與實際連結輸入。新 App 尚待本次精確啟動確認，login-baseline.png 待擷取。 |
| DL-03 | 通過 | 六張候選視窗擷取，同一 Swift 檔編譯。Light／Dark 及 760／420 pt 結果見比較圖。 |
| DL-04 | 部分覆蓋 | 選取在列焦點時使用原生 accent，焦點移到 Picker 時轉灰且保持選列。實機 accent 多色 → 綠色時，Picker 與 selected row 同步改用綠色。Increase Contrast 開啟時控制邊線及選取文字可辨識，Open pull request 保持 AX disabled。Reduce Motion 開啟時方向鍵選取正常。設定已還原多色，兩項輔助使用設定皆還原為 off。切至另一應用程式並返回後仍保留選列，跨應用程式時 window key 狀態沒有獨立證據，該項保留未驗。 |
| DL-05 | 部分覆蓋 | Tab 進入 Picker，下一次 Tab 進 List，Down 改選至第二列，Shift-Tab 返回 Picker。AX 觀察到列名、選取與停用語意。VoiceOver 實際朗讀待 Human，AX 觀察不支持聆聽判定。 |
| DL-06 | 通過 | 獨立 Tester 的 xcrun swiftc、swift format lint --strict 與 swiftlint lint --strict --no-cache 皆 exit 0。七種無效參數於建窗前 exit 64 並輸出 usage。otool 僅系統 dylib。寫入各為 A／B 精確路徑，正式 Presentation 與 root package 零差異。 |

候選 Swift SHA-256 為 2919c75558c203b89cd8bc87f3d5db648d1eaf8b252689d1a40ee80dad11a324。比較圖 SHA-256 為 4be80bc5b9515268b07ed094a4327b05e38a1908747fda17cabbc67e1b37180b。

### DL-02 的精確 artifact 與擷取矩陣

- App bundle 名稱為 RivetLoginAcceptance.app，ID 為 local.rivet.login-ui-acceptance。
- Source manifest SHA-256 為 006b7d017956fcf6b7a92f68ab56d3cff1b68dbdd3fdcb4b687eb4d99610249c。
- Binary SHA-256 為 338a4688fa210fc3939dd1c24b9c137b704f4856c2b2d1f0c1fd0842ffd189cc。
- App tree SHA-256 為 6115cff9a9ce9cab33d7a4ffb3d686b06836e115f27446e20ac62118d4401628。

以 780 × 500 pt、standard copy、同一 binary、同一台機器分別啟動。每組參數每次僅留下單一測試程序。

| --state | --appearance | --text-size |
|---|---|---|
| welcome | light | 17 |
| welcome | dark | 17 |
| pat | light | 17 |
| waiting | dark | 17 |
| browser-failure | light | 21 |
| token-failure | light | 21 |
| welcome | light | 13 |
| welcome | light | 21 |

## Human 採用項目

1. 審閱背景及主次前景在工作區的辨識和閱讀效果，決定可共用的角色與明暗值。
2. 審閱品牌 glyph 在淺／深表面及 16／22 pt 的呈現，確認哪些使用保留系統可及性語意。
3. 確認原生 List／Picker、選取、視窗失焦和 contrast 的邊界，以及 typography／spacing 採文件規範的做法。
4. Login 基線擷取、跨應用程式 key window 與 VoiceOver 實聽的缺口，按各自原生證據補齊或在採用決定中標記限制。
