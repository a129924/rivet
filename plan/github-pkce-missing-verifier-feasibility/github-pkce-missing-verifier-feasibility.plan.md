# GitHub PKCE missing-verifier 受限補證執行契約

Topic：`github-pkce-missing-verifier-feasibility`。Branch：`chore/github-pkce-missing-verifier-feasibility`；基線／Draft PR target：`dev`，來源 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`。僅於本 topic feature worktree 實作，不在 dev worktree 修改。

相關：[需求](../../analysis/github-pkce-missing-verifier-feasibility/requirements.md)／[技術設計](../../analysis/github-pkce-missing-verifier-feasibility/technical-spec.md)／[狀態帳本](github-pkce-missing-verifier-feasibility.step.md)。

## Goal／Non-Goal 與 In-Scope／Out-Of-Scope

Goal 是有限、可追溯的 missing-verifier 歸因結論及其限制；本輪先完成離線調查與可 review 交付。Non-Goal 是正式 OAuth／登入 UI／public API 修改、通用工具及普遍 PKCE 保證。In-Scope 包含文件／source 核對、必要性判斷、workflow 圖、獨立驗證／審查及 topic publication。Out-Of-Scope 包含任何未另准 live、實際 provider 原文、工具修改、正向對照、wrong 重跑、舊 code／重試／補次及新研究輪次。

## ReadOnly／Written／Modify／Deleted

| 類型 | 契約 |
| --- | --- |
| ReadOnly | 舊 `analysis/`、`plan/`、歷史 evidence、production source、現有 CLI／Swift helper／tests／fixtures、root README 舊狀態。 |
| Written | 本 topic 四份新正式 artifacts；安全離線調查 evidence；`docs/architecture/github-pkce-missing-verifier-feasibility.md`；`docs/architecture/diagrams/github-pkce-missing-verifier-feasibility/` 的 spec／HTML／receipts／必要截圖。只有確定需要且獲准實驗才建立未占用編號。 |
| Modify | 本 topic 文件的後續狀態；`docs/architecture/README.md` 最小索引。 |
| Deleted | 無；不得覆寫、刪除或重新解讀歷史。 |

pr-lens map／render 僅放 repo 外暫存，不加入 commit；graphify 無 graph 時 source fallback，不 build。`swift-implementation` 為 Implementer 階段，本契約無 Swift 程式變更，不因名稱擴張工具。

## 步驟與角色

1. M01 Plan-Creator 建立四份 artifacts，M02 獨立 Plan-Reviewer 明示 verdict 後才進入實作；對話計畫已接受不等於四文件 gate approved。
2. M03 Explorer 完成有範圍的官方／source 調查，記來源、日期、適用配置與剩餘未知，交 Implementer 整合。不能從歷史 unknown 追認原因。
3. M04 Implementer 交付獨立長期文件、最小索引與一張 archify workflow；落實技術設計工具界線與 receipts。不改舊 topic 或正式程式。
4. M05 Tester 檢查新增產物／連結／scope／來源與圖 receipts、人工看圖；既有 67 項受控測試／synthetic 校準不預設重跑，build 不當遠端證據。
5. M06 獨立 Reviewer 檢查受限 diff、資料安全、三層結論與歷史保留，明示 verdict；required fix 回獨立 Implementer，不由審查者改寫自己的受審結論。
6. M07 依 staged diff 的單一 topic 語意邊界提出 commit message。Human 本次已明確要求直接 topic commit／push／Draft PR；完成檢查後依此授權執行，PR target dev，使用真實 SHA 產本機 pr-lens map。不得將 pr-lens 當發布工具或上傳其資產。
7. M08 交 Human review，不自動 merge 或 release。

條件式 L01 live 不屬已授權步驟：若 M03 確認必要性、配置與工具適配，記錄具體方案，在人類邊界另外取得一次新授權／一個新 code／一次 exchange 及原文可見性授權；開始授權即耗唯一機會，不補次。未准前不建立實驗或執行 case。其四態及安全方法完全依技術設計。

## TestCase 與驗收

| ID | 情境／預期 |
| --- | --- |
| TC01 | 文件足夠或無可靠資訊增益：保存有限結論，不建實驗、不耗 OAuth。 |
| TC02 | 前提、工具或配置不足：停止依賴動作，列具體缺口，不用任意失敗歸因。 |
| TC03 | 本機 prepared：只證明組裝；source、版本與「verifier 省略」證據界線明確。 |
| TC04 | 明確因果且盲判一致：依固定四態；provider mismatch 不改稱明言缺少。 |
| TC05 | 一般 grant／關鍵字／含糊／分歧：維持無法判定、不追加操作。 |
| TC06 | 安全 gate 拒絕／取消／逾時：整段停止、不截斷、不補次，不宣稱 OS 清除。 |
| TC07 | 任一 token 鍵：立即停、不 API／保存／revoke；成功契約不足只記疑似反例。 |
| TC08 | 新文件／相對連結／圖：契約一致、showcase 九項零 error／warning、deliver SHA、四尺寸 containment 與人工 light／dark 檢視證據。 |
| TC09 | pr-lens／graphify：真實 provenance、repo 外 map／無自動 graph build；失敗可 fallback，不能增加 OAuth。 |
| TC10 | 最終 diff：舊 planning／evidence 與 Swift source 零變更；四態與任務完成分開，本輪 OAuth 0、live 未執行。 |

TC04–TC07 的真人分支現在未執行；目前只驗證文件契約，不能記為 remote passed。只對新增產物做必要檢查，不為證明已知實作而擴大測試。

## 完成與停止

無須實驗則保留來源、版本、事實、推論、限制與決策影響；需要但未准 live 則保留具體缺口，以未執行及 Human boundary 交付。實驗四態與本輪任務完成否分開；無法判定須列缺失與限制，不能放行受阻的安全決策。可信反例只交原變更流程。所有歷史額度／原文同意不延續；正式登入 UI 仍依原計畫推進。
