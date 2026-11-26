# Rivet Design Language Adoption — Requirements

## 問題與目標

Login 已有 Human 採用的色彩、文字層級和品牌識別。Inbox Header／List／Row 使用原生 SwiftUI 元件，產品尚缺少兩者可共用的視覺角色與採用規則。本 topic 屬於 non-BC `RivetPresentation`。

Phase A／B 交付可重現的 Login 與 Inbox 正式元件基線、原生 Inbox 視覺候選及盤點紀錄，供 Human 決定採用的色彩、表面、文字、間距與品牌角色。保留已採用的 Login UI／UX、公開介面與 parent-owned phase／intent，以及 Inbox 原生互動契約。

## 來源與現況

- 凍結基線為 `dev` 的 `2764e64a77732902693b7890b346b2f3fa3f487d`。相對於草案的 `c9c9f17`，Presentation 原始碼、測試、根套件、相關文件與驗收工具無差異。
- Login 以正式 `RivetLoginView`、現行受控 DEBUG preview、既有原生 acceptance tool 與 Human 採用記錄為準。E011 的 frozen demo 作歷史來源。
- Inbox 採用凍結基線的正式 Header／List／Row 與其現行 `#Preview`。E024 只存在於另一分支 `9610830`，I1-08 待證。驗證 host 的容器、fixture 和 Open 紀錄區獨立標註。 [I1 Draft PR #97](https://github.com/a129924/rivet/pull/97)

## Phase A／B 成功條件

- 逐一記錄八組 Login Light／Dark sRGB 色值、使用位置、品牌幾何及依賴。同時交付正式 Login 擷取及 Inbox Header／List 明暗 baseline，列明 preview wrapper 與產品區。缺少 baseline 時記錄原因與判斷限制，交 Human。
- 交付可編譯的獨立原生預覽，以及兩份標註來源和配置的截圖比較圖。原生候選涵蓋明暗、760／420 pt、長標題及具代表性的選取、焦點、失焦、系統 accent、Increase Contrast、Reduce Motion 與 VoiceOver。
- 維持現行正式元件、套件與既有工具的檔案內容。執行及驗收只寫入計畫列出的精確路徑。截圖、靜態檢查、原生實測與 Human 聆聽各有對應紀錄。
- A／B 以 Draft PR 承載 Human 視覺 Review。Phase B 採用決策決定 C／D 的共用角色、品牌用法、原生邊界及待決項。

## 待決與後續

色彩優先評估背景、主／次前景的跨畫面語意。表面、分隔線、工作區字級密度、間距與品牌在淺色表面及 compact 用法，要依 Phase B 證據確認。抽象以已有 consumer 為優先。

Phase C／D 規劃在 Human 明示採用後，以同一 topic 完成 amendment 與獨立審查。PR Inbox 採用、Reader、Workspace、新產品邏輯、BC 變更、Theme Engine、新 package 與 framework 均在本次 A／B 範圍外。

[Technical spec](technical-spec.md) · [執行契約](../../plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md)
