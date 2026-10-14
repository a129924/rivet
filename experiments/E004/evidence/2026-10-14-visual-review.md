# Archify 視覺檢查

- 圖類型：sequence；作者內容繁體中文，固定 Viewer UI／html lang 採英文 fallback。
- 最終 validate／deliver：9/9 showcase、0 errors、0 warnings；雜湊見 diagrams/credential-sequence.delivery.json。
- visual-check：1440×900、1600×1000、1920×1080、2048×1320 均無水平／垂直溢出。
- 已人工檢視最小與最大尺寸的 light／dark 四張截圖：文字、節點、箭頭、卡片可讀，無裁切，最大尺寸保留完整主圖與必要結論。
- visual_review: passed。工具 visual-check receipt 的 visualReview: pending 保留原值，與本人工觀察分開。
- correction_rounds: 2（桌面高度修復）；前置 structural validation 另修正一次 viewBox 寬度。
- 曾觀察首版高度溢出；合併冗餘訊息、卡片及垂直間距後重做 validate／deliver／visual-check，未縮字、遮蔽或修改 renderer。
