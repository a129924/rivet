# PR Inbox I1 驗證需求

開發者可在獨立 macOS Inbox 視窗掃讀、選取合成自查候選，並以 Enter 或雙擊記錄一筆正確 PR 的 Open。首次選取第一列，更新依完整識別保留選取，原列消失時選取並聚焦第一個可選列。

側欄與篩選採展示或停用語意。受控載入、空清單、錯誤和已知離線涵蓋選取、焦點及復原提示。明暗與 Login 對照，並以實際 VoiceOver 核對目前列及局部狀態提示。真實 GitHub 資料、實際 Reader、可操作篩選／導覽與重試、正式採用皆留待後續。

[PR Inbox 契約](../../docs/architecture/bounded-contexts/pr-inbox.md) · [原生互動契約](../../docs/presentation/native-interaction-contract.md)

## 2026-11-26 Plan Amendment · Variant B

沿用 PR #97 的合成自查清單與 Open 驗證。將 HC-02 採用的 Variant B 接到正式 Inbox 畫面元件，再由 E024 使用同一套正式組合取得原生證據。側欄與 Header 使用共用 Background，清單／狀態表面以 Surface 分層。主要與次要靜態文字沿用 Primary／Secondary。側欄將 16 pt branch glyph 與 Rivet 文字並列，保留原生 List、Picker、選取、系統強調色、焦點與無障礙語意。字體角色、密度與間距依 Visual Design Contract。Border 色值的獨立效益仍待評估。

補驗 Light 鍵盤、非預設系統強調色、Increase Contrast、Reduce Motion、跨 App 視窗啟用／非啟用、VoiceOver 實際朗讀及完整受限寬度。原 E024 證據和 I1-08 缺口保持歷史原狀。正式 App 接線、實際篩選及導覽、GitHub 資料與 Reader 仍在後續範圍。 [Visual Design Contract](../../docs/presentation/visual-design-contract.md) · [PR #101 Inbox 移交](../../plan/rivet-design-language-adoption/evidence/cd-verification.md)
