# Rivet Design Language Adoption — Technical Spec

## 採用的能力

C 提取與 D 接線交付為同一項 bounded capability。兩個 internal 型別留在現有 SwiftPM `RivetPresentation` target，使用 SwiftUI。Login 是唯一正式 consumer。

| `RivetPalette` 角色 | Light sRGB | Dark sRGB | 語意 |
|---|---|---|---|
| `background` | `#FCFDFF` | `#161C26` | 非控制項視窗或工作區的外層底色 |
| `primary` | `#192533` | `#F4F6FA` | 非控制項的主要文字 |
| `secondary` | `#647386` | `#9AA9B9` | 非控制項的說明或次要文字 |
| `surface` | `#F1F4F8` | `#222C39` | 外層底色上的內層表面。Login 用於既有狀態圖示底 |

- `RivetPalette` 為 internal struct，提供 internal `init(dark: Bool)`、四個 `Color` 屬性與單一 internal `static func color(sRGB: UInt32) -> Color`。sRGB 轉換沿用 `RivetLoginArtwork.swift` 既有 8-bit RGB 位元拆解、除以 255 與 opacity 1。
- `RivetLoginPalette` 在原檔提供相同內部用法，將四色交給 `RivetPalette`。Login fileprivate `Color(hex:)` 可委派同一轉換。Border `#E1E7EE/#323C49`、Field `#FFFFFF/#19232E`、Button `#252B33/#F3F6FA`、Button label `#FFFFFF/#19212C` 均保留在 Login，順序為 Light／Dark。按壓、停用與對比規則繼續留在既有 styles／元件。
- `RivetBrandMark` 為 internal SwiftUI glyph-only View，提供 internal `init(size: CGFloat, foreground: Color)`。直接搬移既有 Canvas 的 24-unit 座標、三個圓、連線與 Bézier 控制點、`1.7 × scale` 描邊和 round cap。由 Login 以 22 pt、`#CBE7FF` 調用，保留 36 pt tile、背景與框線、RIVET wordmark、品牌面板、Diff artwork 及外層 `.accessibilityHidden(true)`。
- BrandMark 只負責繪製。與文字並列時 caller 可標為裝飾。單獨承擔辨識或操作時，caller 提供恰當名稱及語意。22 pt symbol-only 可行性來自 Phase B；使用位置由未來 feature 決定。

## 表面與原生互動

新 Visual Design Contract 記錄 Light／Dark 共用角色及表面層級、Variant B 的整體方向、native control 邊界和 feature-only 責任。Surface 與 Border 的個別視覺貢獻仍未驗，Border 留在 Login。Typography／Spacing 僅說明適用情境及密度，不建立共用 scale。保留 system appearance、List、selection、accent、focus ring、disabled、VoiceOver 與 keyboard semantics。

`RivetLoginView`、`LoginStyles`、公開 models 及 previews 皆使用原有介面。40:60、13–21 pt scaling、parent-owned phase／intent、局部 PAT 編輯、focus、狀態宣告及原生 controls 不跨入新的 internal 能力。Appearance 選擇維持現有 caller 所有權。

## 驗證設計

- 新增一個 Swift Testing 表格測試，覆蓋兩個 appearance × 四角色。以 `NSColor` 轉為 sRGB 比對各色通道與 alpha，或使用等價的 sRGB 數值解析。比較精度需辨識一個 RGB byte 的差異，並直接驗證target 內共用能力提供的真實色值。
- 以前測凍結的八張影像作比較。用同機、同 780 × 500 pt 窗內容、同 fixture、standard copy、appearance、字級及可比較渲染，逐一擷取 after。記錄可變的 progress frame、游標、焦點及 rendering scale 等條件，只將已辨識的擷取差異與實際畫面偏移分開說明。
- Login 原生操作使用獨立 acceptance package、合成資料及中性 copy。啟動新 artifact 前獨立審查來源、資源與精確 App／binary，取得當下 Human 確認。依受測型態記錄實際操作或真實未驗。AX tree 與截圖不能證明 VoiceOver 實際朗讀。
- 精確寫入範圍、身份與試例由執行契約鎖定。產品 runtime、二進位與原始 screenshots 不列為 repo 寫入。A／B 採用證據保留原始 SHA。

[需求](requirements.md) · [執行契約及測試](../../plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md) · [Login 驗收工具](../../tools/acceptance/login-ui/README.md)
