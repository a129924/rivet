# Design Language 視覺審閱

環境為 macOS 26.5.2（25F84）、Xcode 26.6（17F113）及 Swift 6.3.3。正式畫面基線為 dev 2764e64a77732902693b7890b346b2f3fa3f487d。Phase A 盤點與責任分離已被接受。Phase B 依 HC-02「調整 — Minor」完成一輪視覺修整，待 Human 採用決策。

## 工作區表面比較

[Login 與 Inbox A／B 的明暗比較](design-language-candidate.png) · [完整八張 Login 基線](login-baseline.png)

| 比較條件 | 共同設定 | Variant A · 原生內容表面 | Variant B · Rivet 內容表面 |
|---|---|---|---|
| Workspace | 174 pt 視覺側欄、760 pt 內容區、左側標題與右側原生 Picker。外層沿用 Login-derived Background | List 使用原生內容底與原生區隔線 | List 置於 Rivet-derived Surface。面板輪廓、側欄邊界與 Header 分隔使用候選 Border |
| Dark | 同一組合成 PR（#72、#68、#61、#46），初始選列 #72，Picker 為 Needs Review | 中性深灰面板有清楚的區隔，與 Login 深藍灰相比呈兩種色調 | #222C39 讓內容區延續藍灰色階，#323C49 勾勒面板邊界。選列仍清楚可辨 |
| Light | 同一組資料、布局、初始選列與控制項狀態 | 原生白色內容底與接近白色的外層分界較弱 | #F1F4F8 提供淺灰藍分層，#E1E7EE 有低對比輪廓。列文字保留系統前景 |

建議在 HC-02 優先審閱 B 的 **Surface** 與 **Border**。Dark 的色調延續最明顯。Light 的分層也可見，差異主要來自低對比輪廓。這組圖只比較 Surface 與 Border 一起套用的結果，各自的跨畫面價值仍待決定。List 內部列分隔線由系統繪製。B 只隱藏捲動區底色並提供面板底與外框，使用與 A 相同的原生 List、Picker、列結構、選取 Binding 及系統前景。側欄以靜態文字呈現 Inbox 與 rivet repository 的脈絡，沒有導覽行為。

## 比較圖索引

| 格 | 內容 | 來源 |
|---|---|---|
| 1–3 | Login Welcome Light 17 pt、Inbox A Light、Inbox B Light | HC-01 的 Login 原生基線與這輪 workspace 候選 |
| 4–6 | Login Welcome Dark 17 pt、Inbox A Dark、Inbox B Dark | 同上 |
| 7–9 | 既有 Login tile、glyph、RIVET wordmark，並列 Light／Dark 的 16 pt compact 與 22 pt symbol-only | 第 7 格為第 4 格的原始畫面節錄。第 8、9 格為這輪 Samples |
| 10–11 | 保留的 420 pt Inbox 候選，Light／Dark | 原窄版布局，長標題仍為單行尾截斷 |
| 12–15 | InboxHeader 與 PullRequestList，各 Light／Dark | Xcode Canvas、RivetPresentation scheme、Standard · Needs Review 與 Six PRs and Open probes |

既有 Login 的 36 pt tile、22 pt glyph、描邊 #CBE7FF、wordmark 與品牌面板維持原有組合。Workspace 以相同 glyph 幾何配上側欄既有的 Rivet 文字，symbol-only 展示獨立 glyph。當 glyph 與文字並列時，候選將 glyph 視為裝飾。未來若 symbol-only 獨自承擔識別或操作，應依使用情境提供可及性名稱。Canvas 中的 filter 文字、Open probes 與事件區是預覽容器證據。E024 的獨立容器與 I1-08 缺口沿用原記錄。 [I1 Draft PR #97](https://github.com/a129924/rivet/pull/97)

## 提取決策矩陣

| 分類 | 項目 | 建議與界線 |
|---|---|---|
| **Shared Swift implementation** | Background #FCFDFF／#161C26、Primary #192533／#F4F6FA、Secondary #647386／#9AA9B9，順序為 Light／Dark。既有 branch glyph 幾何 | 優先供 C／D amendment 評估的最小候選。Login 有直接用途，保留 sRGB、幾何與既有外觀。實際提取範圍待 HC-02 及正式計畫審查 |
| **Documentation-only convention** | Onboarding／Workspace 的文字層級與密度、spacing、表面層級、圖示搭配與原生 controls 邊界 | 保留系統字體及 List、selection、accent、Picker、焦點與可及性語意。16／24 pt 僅為候選樣本，無全域 scale |
| **Feature-specific styling** | Login 的 Surface 狀態圖示底、Border footer／PAT、Field #FFFFFF／#19232E、Button #252B33／#F3F6FA、Button label #FFFFFF／#19212C、按壓／停用／對比、40:60、13–21 pt 縮放、tile、wordmark、完整 artwork。Inbox 自有窄列政策 | 比較及責任盤點源自現行用法。候選維持 420 pt 原樣及單行尾截斷。正式 Inbox 的 620／480／340 pt 降階留在該畫面 |
| **Deferred decision** | Workspace 是否採 B、Surface #F1F4F8／#222C39、Border #E1E7EE／#323C49 是否具獨立共用語意、symbol-only 的實際採用點 | B 提供明暗視覺依據，Surface 與 Border 分別由 Human 判斷。現階段只在隔離 fixture 使用。實際採用及可及性情境須貫穿 C／D 驗收 |

## 驗收及剩餘原生證據

| 項目 | 結果 |
|---|---|
| DL-01 | 八組 Login 色值與既有責任已盤點。兩個指定 Inbox Preview 的四張 Canvas 基線隨比較圖保留。 |
| DL-02／HC-01 | 八個限定 Login 狀態已用同一份審查通過的 App 分別啟動並擷取。780 × 500 pt 內容視窗、standard copy、同機、逐次獨立程序，擷取後全部關閉。 [八張基線](login-baseline.png) |
| DL-03／修整 | 以相同 fixtures 與初始狀態擷取 A／B × Light／Dark。兩組品牌樣本及既有 420 pt 窄版已核對。 |
| DL-04 | B Dark 實測 List 有焦點時以預設系統 accent 顯示藍色選列，返回 Picker 後保留同一選列。首輪候選曾實測綠色 accent、Increase Contrast、Reduce Motion 與設定還原。修整後 B 的非預設 accent、Increase Contrast、Reduce Motion，以及跨 App 切換時的原生 key window 狀態仍未重驗。 |
| DL-05 | B Dark 實測 Tab 進入 Picker、再次 Tab 進 List、Down 選到 #68、Shift-Tab 返回 Picker，Open pull request 仍為 AX disabled。AX 樹顯示列名與選取。VoiceOver 實際朗讀、B Light 的鍵盤與可及性仍待驗。 |
| DL-06 | 單檔 Swift 6 編譯、strict Swift format／SwiftLint 及九組無效參數通過。Workspace 的額外 CLI 選項與暫存 binary 只供 A／B。 |

Login 截圖是靜態基線，PAT 與 token failure 的長內容在初始 viewport 底端以外仍有內容。本輪截圖只核對該 viewport，尚無捲動、焦點或互動等效證據。正式 Swift 接線的 Login 前後比較保留至 C／D。

### Login baseline 來源

App 為 RivetLoginAcceptance.app，bundle ID 為 local.rivet.login-ui-acceptance。審查核對 28 筆來源及 6 筆 bundle entries。Source manifest SHA-256 為 006b7d017956fcf6b7a92f68ab56d3cff1b68dbdd3fdcb4b687eb4d99610249c，binary SHA-256 為 338a4688fa210fc3939dd1c24b9c137b704f4856c2b2d1f0c1fd0842ffd189cc，App tree SHA-256 為 6115cff9a9ce9cab33d7a4ffb3d686b06836e115f27446e20ac62118d4401628。

| 格 | --state | --appearance | --text-size |
|---|---|---|---|
| 1 | welcome | light | 17 |
| 2 | welcome | dark | 17 |
| 3 | pat | light | 17 |
| 4 | waiting | dark | 17 |
| 5 | browser-failure | light | 21 |
| 6 | token-failure | light | 21 |
| 7 | welcome | light | 13 |
| 8 | welcome | light | 21 |

### 重現 Workspace 候選

在 feature checkout 根目錄執行，binary 留在 checkout 外：

    preview_run="$(mktemp -d)"
    xcrun swiftc -swift-version 6 -parse-as-library -g \
      plan/rivet-design-language-adoption/evidence/VisualDesignPreview.swift \
      -o "$preview_run/RivetDesignLanguagePreview"
    "$preview_run/RivetDesignLanguagePreview" --view workspace --appearance dark --width 760 --surface native
    "$preview_run/RivetDesignLanguagePreview" --view workspace --appearance dark --width 760 --surface unified

Light 使用 --appearance light。樣本使用 --view samples --width 760。窄版使用 --view inbox --width 420，兩者省略 --surface。

## HC-02 Human Review

這一輪交付後停在 HC-02。待 Human 判斷 Workspace 表面方向、Surface 與 Border 的共用價值、glyph 使用方式與剩餘原生證據。確認最終 Design Language 後，才依採用結果形成 C／D amendment 並送正式 Plan Review。
