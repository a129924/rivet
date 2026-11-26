# Rivet Design Language Adoption — Requirements

## 問題與目標

Login 已有 Human 採用的色彩、文字層級和品牌識別。Inbox 使用原生 SwiftUI 元件，兩者需要共用的視覺語意與採用規則。本 topic 屬於 non-BC `RivetPresentation`。Phase C／D 將 Human 採用的四色與 branch glyph 提取成 internal 能力，並讓 Login 以最小接線使用。以同一組 fixture 驗收既有外觀、介面、鍵盤、焦點及 VoiceOver 等效。

## 已採用的 Phase A／B 結果

- HC-02 明示 **Accepted**。採用 Variant B 的藍灰表面層級與低對比輪廓方向。Light／Dark 使用相同的語意角色，可依 appearance 採不同視覺處理。比較以 Surface 與 Border 一併套用，個別貢獻未單獨驗證。
- 核准 Background、Primary、Secondary、Surface 共用值與既有 branch glyph。Border 及 Login Field、Button、Button label、按壓／停用／對比留在 Login。Border 是否有共用需求，由未來 Inbox 另以實際需求評估。
- 22 pt symbol-only 的視覺可行性已採用。實際位置待決，避開 Toolbar、navigation 和 collapsed sidebar 的接線決策。文字並列時 glyph 為裝飾，glyph 單獨表達識別或操作時由使用端提供無障礙語意。
- Typography 使用系統字體，區分 onboarding 與 workspace 的資訊密度。Spacing、表面層級與品牌搭配以文件規範交付。現行 Login 40:60 版面、13–21 pt 縮放及 Inbox 單行尾截斷、620／480／340 pt 降階仍由各畫面負責。
- 原生 List／Picker、焦點、選取、系統 accent、disabled 與 VoiceOver 的互動邊界沿用 Native Interaction Contract。Variant B 是視覺方向。正式 Inbox 採用與驗收由原 Inbox topic 另行規劃。

## 成功條件

1. 四個共用色角色保留採用的 sRGB 值與色彩語意。唯一正式 consumer 是 Login；其 tile、wordmark、品牌面板及 Diff artwork 保留既有外觀。
2. Login 八組前後畫面在同一 780 × 500 pt 視窗內容、同 fixture、standard copy、appearance、字級及可比較的渲染條件下核對。必要互動逐例保留原生實測與 Human 聆聽結果。任何非預期改變暫停交 Human。
3. 可追溯的 Visual Design Contract 與驗證紀錄交付。四個已採用 A／B 檔案以 SHA-256 保全。後續 Inbox 採用在同步新 `dev` 後另做現況核對、Plan Amendment 及獨立審查。

A／B 修整後仍有七項原生證據缺口，包含 Light 鍵盤、非預設 accent、Increase Contrast、Reduce Motion、跨 App key-window、VoiceOver 實際朗讀與 constrained-width 完整 Variant B。列入 Inbox 後續移交，C／D Login 原生驗收獨立追蹤。

本輪 Human 授權涵蓋正式 amendment 及獨立 Plan Review。開始 Swift 實作須再取得明示授權。

[技術規格](technical-spec.md) · [C／D 執行契約](../../plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md) · [A／B 視覺證據](../../plan/rivet-design-language-adoption/evidence/visual-review.md) · [Draft PR #101](https://github.com/a129924/rivet/pull/101)
