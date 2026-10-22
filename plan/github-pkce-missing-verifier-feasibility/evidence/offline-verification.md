# M05 獨立離線驗證

日期：2026-10-22。角色：獨立 Tester。受驗 branch：`chore/github-pkce-missing-verifier-feasibility`；來源基線 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`。驗證在本 topic feature worktree，沒有在 dev worktree 修改；本證據及帳本狀態不等於 M06 Reviewer approval。

## 結果

**本輪新增離線產物驗證 passed，無 required issue，交 M06 獨立 Reviewer。** 新真人實驗仍為「未執行」；OAuth／code／exchange／provider 原文傳遞均 0，未建立新 experiment。歷史 missing 的歸因仍無法判定。本結論不支持遠端 PKCE 已驗證，也不解除 L01 人類邊界。

## 實際檢查與結果

| 檢查 | 實際操作與結果 |
| --- | --- |
| Scope | 以 `git diff --name-only <base>` 與 `git ls-files --others --exclude-standard` 聯集檢查受驗路徑：18 個，全部符合本 topic allowlist，無 Deleted。只有既有 architecture README 最小索引修改；其他均是本 topic 新文件／圖。 |
| 唯讀範圍 | `git diff --name-only <base> -- Sources Tests apps experiments` 無輸出。完整 allowlist 亦排除所有舊 analysis／plan 變更，production、工具及歷史 evidence 未變。 |
| 相對連結 | 一次唯讀 `python3 -B` 腳本解析 8 份 Markdown 的 51 個相對連結目標，全部存在；未把外部 URL 當本機路徑。 |
| 公開資料 | 同腳本掃描 14 份 Markdown／JSON／HTML，未命中本機絕對路徑與 GitHub token／private-key 常見樣式；再人工閱讀新需求、技術設計、計畫、帳本、調查及長期文件，沒有實際 provider 原文、callback、配置值或秘密。樣式掃描不是任意秘密的完整辨識保證。 |
| 凍結來源 | 三工具以 `hashlib.sha256` 與調查表比較，3/3 相符；逐一以 `git show 4dbf3df:<tool>` 比 bytes，3/3 相同。沒有 import／執行 probe。 |
| 原碼語義 | 唯讀檢查 probe `:159–236`、`:314–326`、`:512–555`：missing 完全省略欄位；observer 是 prepared 本機資料；任一 token 鍵即 failed 是鍵存在分類，不是完整成功契約；missing 自動 passed 只對 verifier_required。調查／長期文件與此一致。 |
| 判準 | 人工核對四態、三層證據、mismatch 不冒稱缺少、CLI 原分類保留、未授權與 OAuth 0、本輪完成否與實驗狀態分離。TC01–TC03／TC08–TC10 的離線部分符合契約；TC04–TC07 僅核對文件，不宣稱真人分支已測。 |
| 格式 | `git diff --check` exit 0。此命令只覆蓋 tracked diff；新增文件另外人工閱讀與連結檢查。 |

以上為一輪檢查腳本與 source／文件閱讀，不宣稱是新建的單元測試套件。沒有執行 Swift build、67 項既有測試、synthetic 校準、正常登入或 wrong。

## archify receipts 與凍結 bytes

親跑 `node <archify-skill>/bin/archify.mjs validate workflow docs/architecture/diagrams/github-pkce-missing-verifier-feasibility/missing-verifier.workflow.json --quality showcase --json`，exit 0；9/9 artifact checks、composition showcase pass、0 errors／0 warnings。沒有重新 deliver、重繪 HTML 或重新截圖。

一次唯讀 Python 核對 delivery receipt 與實際 bytes：

| 產物 | 實際 SHA-256 | bytes／receipt |
| --- | --- | --- |
| spec | `149c5316f483cb20b91a7bfbe00db899a9422841eb2e88d20c069b0de5eba83c` | 3309，相符 |
| HTML | `242f1b39415282de81361f4e3773255cdf86398840260326ce22e35c5e09ce70` | 702647，相符 |

已保存 validation／delivery 均 9 checks、0 errors／warnings；visual-check artifact SHA 與 HTML 相同。自動 containment 四尺寸 1440×900、1600×1000、1920×1080、2048×1320 均 scrollWidth／scrollHeight 等於 viewport。此處核對現存 receipt，沒有重新量測。自動 receipt 的 `visualReview: pending` 保持原樣。

## 四張原 PNG 人工檢視

Tester 使用 `view_image` 依序親看已交付的四張原 PNG，沒有修改圖片：

| 截圖 | 人工結論 |
| --- | --- |
| 1440×900 light | 節點主文字、子文字及分支標籤可讀；沒有文字截斷或節點遮蔽；未執行與另准後路徑可辨。 |
| 1440×900 dark | 文字與路線保持可辨；泳道標題較低對比但仍可閱讀，無 required issue；停止分支的色彩與標籤可區分。 |
| 2048×1320 light | 主流程與停止分支仍清楚，沒有內容裁切；圖、legend、外框的垂直佈局可接受，沒有靠裁切隱藏溢出。 |
| 2048×1320 dark | 大畫面主文字與子文字可讀、線條到端點明確；留白與圖面比例可接受，無遮擋／裁切。 |

兩條通往「停止並記錄」的分支在終端區域匯合，但來源與各自的因果標籤仍可辨，未造成不同終點或執行順序的誤讀。人工完整檢視 passed 是 Tester 的視覺結論，沒有改稱自動 receipt 已完成人工檢視。

## 工具與停止界線

graphify 本輪沿用 M03 已記錄的無可用 graph／source fallback；沒有 build／query／安裝。pr-lens 實際 map 等 M07 真實 commit SHA 後處理，現在 pending，不算 M05 失敗。沒有對外上傳或發布圖、沒有 UI copy、沒有讀取實際 provider 描述。

可交 M06 bounded review；M07 publication 與 M08 Human review 尚未完成。L01 未授權，禁止據本證據排程新授權或原文傳遞。
