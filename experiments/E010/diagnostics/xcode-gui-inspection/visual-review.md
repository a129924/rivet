# Workflow 目視檢查

- 唯一 final：`workflow.v2.html`；workflow 圖的是計畫，不是已執行 GUI／DPK 證據。
- specification SHA-256：`6e3223ea5b9c328c09dcdcedf8b36d29a273c23afe402229ab5b34342058a74d`。
- artifact SHA-256：`b8af738698e8d54e316f3094af4d41adb3a0cd14073fbec15756768c8a19eeb7`。
- showcase：9/9，0 composition errors、0 warnings；final validation 與 deliver 均 exit 0。
- automated containment：1440×900、1600×1000、1920×1080、2048×1320 全 pass；scrollWidth／scrollHeight 均不超 viewport。
- visual_review：**passed**（作者實際 `view_image` 查看 contact sheet 四張截圖，另查看 2048×1320 light／dark 原圖）。
- visual correction rounds：1；未再改 final specification／HTML。這是目視品質記錄，不是獨立 Reviewer 核准。

實際檢視 [contact sheet PNG](workflow.v2.contact-sheet.png)、[原 contact sheet HTML](workflow.v2.visual-check.html) 及最大尺寸 [light](workflow.v2.visual-check.2048x1320.light.png)／[dark](workflow.v2.visual-check.2048x1320.dark.png)。READ／Still 下文字與停止支線可讀，路線沒有穿過其他節點或遮住文字；最小與最大尺寸無截斷，兩 lane 的主體與 legend／navigation 保持正常 document flow。未操作 viewer search/focus/export 功能，也不聲稱做過 Xcode GUI 觀察。

v1 deterministic showcase 合格，但四尺寸均有 vertical overflow，所以沒有當作 final。視覺修正版去掉與 runbook 重複的結論 cards、合併冗餘 lane／短化重複節點文案，保留六個主步驟與不足即停支線；「前提不足」edge label 已由終點「不足即停」完整表達，刪去重複 label 不失條件。未設定小字級、overflow hidden、內部 scroller、裁切或拉伸 SVG。v1 已交付 spec／HTML／失敗 receipt 與 captures 共八檔先 exclusive 外部封存、逐檔 read/SHA verify、寫私有 path map 後，才移除本新目錄的失敗 QA 檔；舊180檔不動。

自動 [visual-check receipt](workflow.v2.visual-check.json) 的 `visualReview: pending` 原樣保留：它不會代做目視檢查，與本作者實際目視結果分開。contact sheet PNG 是對已生成的 contact sheet HTML 作 headless 截圖，沒有修改 trusted HTML，沒有開啟使用者 browser／Xcode 或 preview/server。繁體中文作者內容省略 locale，viewer UI 與 html lang 採 English fallback；static／classic，沒有 subtitle／animation／自訂 preset。
