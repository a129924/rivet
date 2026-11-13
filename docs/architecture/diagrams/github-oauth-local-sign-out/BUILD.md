# 本地登出序列圖

此圖表達已核准的單一 owner 契約，不代表真 DPK 系統驗收完成。

- 規格：`sign-out.sequence.json`；產物：`sign-out.html`。
- Archify validate／deliver：showcase 9/9，0 errors、0 warnings。
- visual-check：1440×900、1600×1000、1920×1080、2048×1320 containment 通過。
- Agent 已檢視最小深色及最大淺色截圖，無裁切或路徑重疊；Human 圖面接受仍 pending。
- 作者內容為繁體中文；固定 Viewer UI 與 HTML lang 使用英文 fallback。
- 沒有發布或上傳。

重現：使用 Archify skill 的 pinned runtime，依序執行 validate sequence、deliver sequence、visual-check（repo-root 指向 feature checkout）。驗證時輸入規格與輸出 HTML 皆使用本目錄相對路徑。
