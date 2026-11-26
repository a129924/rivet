# Rivet Visual Design Contract

Rivet 的 Login 與 Workspace 採用共同的冷色調、文字角色與 branch glyph。Login 保留 onboarding 的版面與字級。Workspace 以較高資訊密度呈現日常審閱工作。此視覺契約與 [Native Interaction Contract](native-interaction-contract.md) 並行，操作、焦點、鍵盤及可及性以原生互動契約為準。

## 採用的 Workspace 視覺方向

HC-02 採用 Variant B 的分層方向。以 Rivet 背景承接側欄和 Header，以內層表面區分內容。側欄、Header 與內容區的分界保持清楚而克制。Light 與 Dark 使用相同的語意角色，表面與分界可因 appearance 調整。A／B 比較圖是採用依據，正式 Workspace 的接線及驗收由 PR Inbox 自有 topic 處理。 [候選比較與採用證據](../../plan/rivet-design-language-adoption/evidence/design-language-candidate.png)

## 共用 Swift 能力

共用能力位於既有 non-BC RivetPresentation target，依賴 SwiftUI。Login 是目前的正式 consumer。畫面持有 appearance、產品狀態與操作責任。

| RivetPalette 角色 | Light sRGB | Dark sRGB | 使用位置 |
|---|---|---|---|
| Background | #FCFDFF | #161C26 | 視窗或工作區外層的非控制項背景 |
| Primary | #192533 | #F4F6FA | 非控制項的主要文字 |
| Secondary | #647386 | #9AA9B9 | 說明與次要文字 |
| Surface | #F1F4F8 | #222C39 | 外層之上的內部表面。Login 用於既有狀態圖示底色 |

RivetBrandMark 提供原有 branch glyph 的幾何、比例及描邊，讓 caller 指定尺寸與前景色。

| 用途 | 規範 |
|---|---|
| Login | 36 pt tile、22 pt glyph 與 RIVET wordmark 的組合留在現有 Login 品牌面板 |
| Compact Workspace | 16 pt glyph 與可辨識的 Rivet 文字並列 |
| Symbol-only | 22 pt glyph 已有視覺候選。使用端在符號單獨承擔識別或操作時提供適當的名稱與可及性語意 |

Glyph 與可辨識文字並列時可視為裝飾，避免重複朗讀。Login 保留整個品牌區既有的無障礙隱藏語意。

## 使用規範

Onboarding 可使用較大的標題、eyebrow 及較寬鬆的區塊間距。Workspace 以標題、列標題、說明及 metadata 分出層級，採系統字體並按資訊密度調整。16／24 pt 等候選間距供個別版面參考。字級、縮放、間距及 responsive 政策由各畫面持有。

List、Picker 與其他原生控制項沿用系統樣式與前景語意。Workspace 可設定控制項外的背景與表面，並在結構分界使用低對比輪廓。原生 selection、accent、焦點環、inactive 與 disabled 外觀仍由系統處理。驗收依使用情境確認 Increase Contrast、Reduce Motion、鍵盤與 VoiceOver。

## 畫面持有的樣式

- Login 持有 Border、Field、Button、Button label 及按壓、停用和對比行為。40:60 版面、13–21 pt 字級縮放、品牌 tile、wordmark、Diff artwork 與品牌面板留在 Login。
- PR Inbox 持有列佈局、truncation、responsive breakpoints、selection 與 focus 責任。採用視覺角色時，各原生控件繼續遵循 macOS 語意。

## 待決與後續採用

Variant B 的 Surface 與低對比分界一同呈現，Border 色值的獨立貢獻仍待驗。#E1E7EE／#323C49 留在 Login。PR Inbox 有明確共用需求時再評估。Symbol-only 的正式使用位置待決。

PR Inbox 將以更新後的 dev 基線檢查共用能力，修訂其自有的精確路徑與原生回歸計畫，通過獨立 Plan Review 後再採用。候選在 Light 鍵盤、非預設 accent、Increase Contrast、Reduce Motion、跨 App key-window／inactive、VoiceOver 實際朗讀及完整 Variant B 窄版仍待驗。既有 420 pt 畫面與首輪的系統設定測試各保留在原有證據範圍。 [完整驗證範圍](../../plan/rivet-design-language-adoption/evidence/visual-review.md)
