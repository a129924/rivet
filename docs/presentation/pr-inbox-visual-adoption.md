# PR Inbox 視覺採用 · Variant B

2026-11-27，Human 確認正式採用 Variant B 作為 PR Inbox 工作區的視覺基準。這項採用將 HC-02 的分層方向落實到 `RivetPresentation.InboxWorkspace`。 [PR #97](https://github.com/a129924/rivet/pull/97) · [Rivet Visual Design Contract](visual-design-contract.md) · [HC-02 採用證據](../../plan/rivet-design-language-adoption/evidence/visual-review.md)

## 工作區外觀

- 外層工作區、側欄與 Header 使用 `RivetPalette` 的 Background，內容區使用 Surface。標題、品牌及次要靜態文字使用 Primary／Secondary，區域間以原生 Divider 分界。共用 Border 與 symbol-only 品牌應用仍待評估。
- 側欄將 16 pt 的 `RivetBrandMark` 與「Rivet」並列。Glyph 為裝飾，VoiceOver 只朗讀品牌文字一次。標題、副標與列文字採系統字體，由各元件依閱讀層級及資訊密度配置。
- 工作區在 620 pt 以下將靜態側欄收成上方橫列，Header 可將 Picker 移到標題區下方。寬窄切換維持同一內容 View，保留選取與焦點。420 pt 的完整工作區已驗證長列標題單行尾截斷，無障礙名稱仍保留完整標題與 PR 識別。

## 原生行為與責任

`InboxWorkspace` 由呼叫端提供 Header 資料、Picker 的綁定及啟用狀態，以及側欄、內容和 footer。List 與分段 Picker 沿用 macOS 的系統強調色、作用中／非作用中選取樣式、鍵盤焦點、停用及無障礙語意。呼叫端的 Presentation Session 仍負責選取、狀態焦點及安全的 Open PR 事件。 [macOS 原生互動契約](native-interaction-contract.md)

## 驗收範圍

E024 的獨立 macOS 驗證 App 使用合成清單，完成 I1-01～07 回歸及 A1 七項驗收，涵蓋 Light 鍵盤、非預設強調色、Increase Contrast、Reduce Motion、跨 App 作用中／非作用中、真人 VoiceOver 及 420 pt 完整工作區。獨立成果複審為 `approved`，根套件 599 項與 E024 7 項測試通過。 [E024 驗收紀錄](../../experiments/E024/evidence/variant-b-native.md) · [執行帳本](../../plan/pr-inbox-i1-verification/pr-inbox-i1-verification.step.md)

### I2 · 原生清單與 GitHub 資料

2026-11-27，Human 接受 E025 的 I2-01～07 驗收結果。E025 的獨立 macOS 驗證 App 沿用 Variant B `InboxWorkspace`，以原生清單顯示目前 GitHub 帳號自己建立且仍開啟的 PR。受控與真人模式共用既有 PR Inbox 查詢及畫面。

- **候選、欄位與選取（I2-01、02、06）**。符合條件的 Draft 依來源順序入列。420 pt 與 940 pt 原生視窗均核對標題、owner、repo 與 PR 編號。以 owner、repo 與編號辨識選取，重排或改名後保留同一列，移除後回到首列。 [E025 受控驗收紀錄](../../experiments/E025/evidence/acceptance.md)
- **空清單與失敗狀態（I2-03～05）**。完整空結果顯示空清單並清除選取，首次讀取失敗時只顯示錯誤。同一工作階段更新失敗時，可讀的完整舊清單及有效選取保留，並標示可能非最新。第二頁等待及失敗期間，畫面均未發布第一頁的部分結果。
- **真人驗收（I2-07）**。使用同一 OAuth App 重新登入後，獨立從 GitHub PR 詳情確認一筆樣本仍為 open，且作者與 E025 登入帳號一致。940 pt 原生清單的 owner、repo、編號與標題均相符。 [E025 真人驗收紀錄](../../experiments/E025/evidence/i2-07-live.md) · [I2 步驟帳本](../../plan/pr-inbox-i2-verification/pr-inbox-i2-verification.step.md)

正式 App 接線、Reader 與 repository 導覽、資料篩選與復原策略另行驗證。
