# 實際視覺檢查

## 自動化結果與作者目視

三張 Archify 的原生 delivery receipts 均為 showcase 9/9、errors=0、warnings=0。visual-check 均 exit 0，1440×900、1600×1000、1920×1080、2048×1320 四尺寸無水平或垂直 overflow；最小與最大尺寸各 light／dark 真截圖成功，不能只由自動 containment 推定美觀。

Implementer 於 2026-10-20 逐張以 view_image 開啟以下 12 張實際截圖，並核對圖標題、關係、字與 legend／navigation dock、卡片及整體留白：

| basename | 1440×900 light | 1440×900 dark | 2048×1320 light | 2048×1320 dark |
| --- | --- | --- | --- | --- |
| authorization-sequence | 已親看 | 已親看 | 已親看 | 已親看 |
| restore-refresh-reauth-sequence | 已親看 | 已親看 | 已親看 | 已親看 |
| connection-lifecycle | 已親看 | 已親看 | 已親看 | 已親看 |

檔名為 `<basename>.visual-check.<尺寸>.<theme>.png`，與原生 `.visual-check.json`／`.html` 同目錄。三圖在最小尺寸保有完整圖與兩張重點卡片，沒有裁切或 dock 蓋住 legend；大尺寸同樣維持可辨識文字與分組。sequence 箭頭與標籤分離，lifecycle 暫時失敗重試／新授權 generation／舊 provider 停止可分辨。classic 無動畫，light／dark 均有清楚的邊界與對比。

Canvas 以 headless Chrome 實際開啟最終 HTML，在 1440×1100 擷取私有 scratch PNG，再由 view_image 親看。五層、17 元件、長距離 gutter 關係完整呈現；fit 是總覽，細節可用原生 zoom／click readout 檢視。最終僅把 REST protocol 名稱對齊 source，重建後重新截圖核對；截圖不另加 repository leaf。

## 診斷與修正紀錄

兩張 sequence 最初較窄且偏高，9checks 雖通過，1440×900 reader 的垂直 overflow 仍被真 visual-check 抓出。保留舊作者 bytes 於私有 scratch，依診斷將 viewBox 改為 1250×800、刪除重複 participant sublabels，重新 validate／freeze／deliver；未縮字、裁切或修補 viewer。最終四尺寸全部 containment pass。lifecycle 初稿擁擠，先收斂狀態與關係，再逐個修正 route／label clearance；末段最佳 errors 4→3→2→1→0，各必要語意仍保留於節點／卡片。不把中間失敗版當成交付。

## 接受邊界

上述是 Implementer 的實際視覺檢查與工具測量，不是獨立 Tester／Reviewer verdict 或 Human 接受。原生 receipts 的 `visualReview=pending` 未改寫；S10a／S10b 與 S11 Human 整體視覺接受仍待執行。作者內容繁體中文，固定 Viewer UI 與 HTML lang 為 English fallback；沒有自行發布、啟動 preview server 或觸碰可用產品。


## RF-D01 bounded 修正與新目視

獨立 Tester 指出原 Canvas 的 session→stores 箭頭不符合 source：`GitHubOAuthAuthorizationSession.complete` 只 return bundle，`GitHubConnectionCoordinator.authorize` 才呼叫 credentialStore.save。僅修正此一 edge 為 Coordinator→stores，實際路由也改從 Coordinator 左邊界經左 gutter 進 stores 左側，加入「初次授權 bundle 完整保存」標籤；移除原錯誤幾何與 from ID，沒有重複 edge。其餘圖／source／三張 Archify 及原凍結 receipts 不改。

重新執行 Canvas validator／build：5 bands／17 boxes／16 edges、0 errors／0 warnings、exit0。全新私有 Chrome profile 在 1440×1100、有界 2000ms 初始化預算擷取 `rivet-s09-canvas-rfd01.png`，作者已 view_image 親看：箭頭確由 Coordinator 指向 stores，未穿過 OAuth session，gutter 標籤與原瀏覽器授權線可分辨，沒有裁切或新增 box 重疊。原截圖與原 pointer 保留；新私有 0600 pointer 綁定新截圖與 scene／HTML SHA。這是 Implementer QA，RF-D01 是否解除交同一獨立 Tester 重驗，Human 接受仍 pending。


## S11 Human 實際接受

Human 已在主對話實際檢視四張 canonical 圖及成果，回答「圖面與成果可接受，繼續既定交付」；主對話收到時間為 2026-10-20 09:51:14 UTC。此為獨立於作者目視與自動化測量的實際 Human 圖面／整體接受，完成既定 S11。原生三張 Archify receipts 的 `visualReview=pending` 是當時工具狀態，保持原始 bytes，不回填為 Human pass。S12 依既有授權執行 topic commit／push／Draft PR，最後仍停 Human review、不 merge。
