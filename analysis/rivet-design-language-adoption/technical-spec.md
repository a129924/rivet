# Rivet Design Language Adoption — Technical Spec

## 鎖定的執行條件

Phase A／B 使用獨立 feature worktree 的 `feat/rivet-design-language-adoption`，基線 `2764e64a77732902693b7890b346b2f3fa3f487d`。只將候選預覽放入 topic evidence。單檔使用 SwiftUI／AppKit 及合成資料，和產品 targets、packages、網路及業務狀態隔離。正式 A／B 寫入清單見執行契約。

Phase A 基線取自現行 Login 原生 acceptance tool，以及 pinned Inbox Header／List 的指定 Xcode `#Preview`。受控 Login DEBUG preview 輔助查核 fixture。Login tool 維持既有 build、source review、精確 App／來源／binary SHA 和當下確認規則。真實登入及任何認證輸入皆在驗證範圍外。

## 視覺候選邊界

| 現有 Login 角色 | Dark | Light | 工作用途 |
|---|---|---|---|
| Background | `#161C26` | `#FCFDFF` | 評估工作區外層表面 |
| Primary | `#F4F6FA` | `#192533` | 評估非控制項主文字 |
| Secondary | `#9AA9B9` | `#647386` | 評估非控制項次文字 |
| Border | `#323C49` | `#E1E7EE` | Login footer／PAT 邊框 |
| Surface | `#222C39` | `#F1F4F8` | Login 狀態圖示底色 |
| Field | `#19232E` | `#FFFFFF` | Login 欄位 |
| Button | `#F3F6FA` | `#252B33` | Login 按鈕 |
| Button label | `#19212C` | `#FFFFFF` | Login 按鈕文字 |

候選的外層表面與非控制項文字可使用前三組色值。Workspace 表面及分隔線各以目前用法與實際畫面評估。保持 System accent、List selected／inactive、原生文字前景、disabled、focus ring、鍵盤與 VoiceOver 規則。以原生 segmented Picker 展示 fixture 選項，操作僅更新局部顯示選擇，不改列集合。

沿用既有 branch glyph Canvas 幾何，盤點 36 × 36 pt tile、22 × 22 pt glyph 及 `#CBE7FF` 描邊，評估在淺底與 compact 呈現的可讀性。Login 深色 tile、wordmark 排版、Diff artwork、文案與裝飾及整區無障礙隱藏規則仍由 Login 負責。Typography／Spacing 先記下語意和用法，繼續各自擁有 Login 13–21 pt、40:60 版面與 Inbox 單行尾截斷、620／480／340 pt 降階。

## 預覽與證據

候選可選 `--view samples|inbox`、`--appearance light|dark`、`--width 760|420`，寬度為內容區 pt。預覽用可取得原生焦點的 macOS 視窗，展示明暗 palette、表面、文字層級、間距和品牌，並以相同合成資料比較標準／窄版。使用原生 List、Picker、disabled 例和系統列內前景。將焦點實際移到另一應用程式視窗再切回，系統設定測後還原。

證據記錄來源 revision、工具／macOS 版本、截圖配置、逐格索引、操作結果及缺口。保留兩張標註比較圖在 topic evidence，原始個別截圖、binary 和 build/cache 放在 checkout 外。正式 Swift 不引用預覽。

## C／D 的後續邊界

以 Human 採用的語意和實際 consumer 建立最小 internal 能力。依賴只朝 SwiftUI／AppKit 和 Presentation 資源。保持 sRGB、glyph 幾何、登入狀態、焦點及 interface 等效，候選方法和檔案須經同 topic amendment 才成為正式 Swift 執行契約。

[需求](requirements.md) · [執行契約及後續 Swift admission](../../plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md)
