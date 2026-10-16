# E005 workflow 視覺檢查

- 日期：2026-10-15。
- 類型：workflow；作者內容繁體中文，固定 Viewer UI 與 HTML lang 使用 English fallback。
- Showcase：9/9，0 errors、0 warnings；最終 spec SHA-256 `1b90a4cb1ebd33bafae4ca9d1f752a1a4eb886c2817cd47a656791fbf79b3655`；HTML SHA-256 `3f09922e6fb71471e1aadb3a10c2bbcf3cf63074b3f9d3712af456049052bcee`。
- 桌面 containment：1440×900、1600×1000、1920×1080、2048×1320 均通過，scrollWidth／scrollHeight 不超過 viewport。
- 實際檢視四張 captures：1440×900 light／dark、2048×1320 light／dark；主路徑、停止→整輪清理、標籤與必要結論卡均可讀，無截斷、遮蔽或明顯下方空帶。
- `visual_review: passed`；這是另行的視覺檢視，原始自動 receipt 的 `visualReview: pending` 未修改。
- `correction_rounds: 1`（桌面視覺修正）：初版五階段直排造成真實垂直溢出，縮合為兩階段並保留 T02–T05 順序、整輪停止清理及證據限制；重新 validate／deliver／visual-check 後通過。此前 schema／geometry 修正不冒充視覺通過。
- 最終 trusted HTML 未再修改；沒有發布、server、animation、overflow 隱藏、裁切或縮字補救。
