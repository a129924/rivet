# GitHub PKCE missing-verifier 受限補證技術設計

相關：[需求](requirements.md)／[執行契約](../../plan/github-pkce-missing-verifier-feasibility/github-pkce-missing-verifier-feasibility.plan.md)／[帳本](../../plan/github-pkce-missing-verifier-feasibility/github-pkce-missing-verifier-feasibility.step.md)。

## 來源與 locked decisions

來源基線為 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`（2026-10-22 建立本 topic）；X wrong 的歷史來源 `4dbf3df` 不移作 missing 的支持。舊 topic planning／evidence、production source、CLI／Swift helper／tests／fixtures 全部唯讀。

以下為調查來源清單；Observer 已於 2026-10-22 唯讀查閱官方頁面並交接 required-verifier 契約。M03 尚需將實際查閱結果、source 及適用限制正式落地為證據；本文件不代替該交付：

- [GitHub OAuth Apps 授權](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)。
- [GitHub Apps user access token](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app)。
- [RFC 7636 §4.5–4.6](https://www.rfc-editor.org/rfc/rfc7636.html#section-4.5)：verifier／challenge 契約。
- [RFC 6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2)：token error 契約；一般 grant 錯誤不能單獨歸因 PKCE。

本輪不新增或改變 aggregate、entity、domain behavior、public API／型別、資料格式或 migration。`swift-implementation` 是既有 Implementer 的交接階段名稱，不代表本題必須新增 Swift 程式。

## 文件優先與條件式最小操作

先核對官方契約、現有工具來源與歷史限制，提出不同結果對既有採用／安全決策的有限影響；不自行重開既定決策。Human 可在不揭露 secret 下確認 client 註冊類型與配置適用性，不重做正常登入。文件已足以支持所需決策、前提不成立或沒有可靠資訊增益時，記錄結論／缺口，不建立實驗。

需要且另獲明確授權後，唯一建議上限為一次新授權、一個新 code、單次 exchange。開始授權即消耗唯一機會，取消、逾時、配置失敗、安全拒絕、無法判讀都不補次。執行前重新檢查 experiments 目錄與 Git 歷史；E001–E007 保留，不預占 E008，依 feasibility-validation 八段 README 建立未占用編號。工具須 frozen 且來源可追溯；若需要修改，先提出最小缺口並停止本契約以外的實作。

操作證據確認新 code、S256、client／redirect 關聯、單次交換及 verifier 欄位完全省略。prepared observer 只支持本機組裝，不是遠端 wire。不能新增正向對照或重跑 wrong。

## 固定假設與四態

主要假設：前提成立時，省略 verifier 的當次 token exchange 因 PKCE verifier 要求或 verifier／challenge 驗證而遭拒。

| 狀態 | 事前判準 |
| --- | --- |
| 未執行 | 尚未進行真人操作，包括未授權或前提不成立。 |
| 成功 | 前提成立、verifier 確實省略、交換拒絕且無成功 token 回應；完整描述明確把當次拒絕歸因於 verifier 要求或 verifier／challenge 驗證，兩名獨立判讀者一致。 |
| 失敗 | 前提成立，省略 verifier 仍取得符合既有成功回應契約的 token 回應。 |
| 無法判定 | 已嘗試，但配置、網路、格式、一般 grant 錯誤、描述不足、安全拒絕、成功契約證據不足或判讀分歧妨礙主要假設判定。 |

遠端是否拒絕、provider 聲稱什麼、本次實驗支持什麼分三層記錄。provider 若聲稱 mismatch，就不能改寫成明言缺少 verifier；明確的當次 mismatch 因果可支持本輪廣義假設，但不代表 GitHub 普遍 enforcement。現有 missing CLI 的 `verifier_required` 才自動 passed；語義結論不覆寫原 CLI `indeterminate`／`proven=false`。HTTP 400、`invalid_grant`、無 token、關鍵字、build／test 通過均非主要假設的充分證據。

任一 token 鍵存在立即停止，不使用 token 呼叫 API、不保存、不自行 revoke。`token_present` 僅表示鍵存在，CLI `outcome=failed` 不等於成功契約成立；有限輸出不足時記疑似反例及無法判定，不擴張閱覽／工具能力。

## 安全原文與兩名盲判

離線交付時未授權原文揭露；2026-10-22 Human 已另行明示本輪安全 gate 後手動傳遞／兩名獨立 AI 判讀，並接受剪貼簿／同步／history／其他程式及 AI 服務可能留存的殘餘風險。不承諾完全清除。

只允許可信純 error 的完整單欄描述，最多 4096 UTF-8 bytes，沿用既有 secret／URL／control／opaque gate；整段拒絕就停止，不截斷或繞過。cleanup 後透過匿名 pipe 交 native helper，Human 明確點擊一次 copy 並手動傳遞，沿用 30 秒 timeout，不自動送出。正常 copy 的歷史證據不延伸成 cancel、timeout、OS 清除已驗證。

兩名獨立 Reviewer 只收到相同完整單欄描述及固定語義判準，不收到 case、safe JSON、歷史結論或彼此答案。各自封存有限 enum 後，Tester 才整合。依完整因果、否定、條件、角色判讀；含糊／分歧保持無法判定。不保存原句、引文或可重建原文的理由。

原文、callback、code、state、secret、verifier、token、完整 response 不進 repo、本機檔案或 logs。公開證據只含允許的有限 enum／布林、HTTP 狀態、來源版本、操作次數及脫敏觀察。

## 導航、圖與 PR 理解工具

- graphify 固定 `graphifyy 0.9.73`，每次 CLI 均設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。沒有可用 graph 就定向 source fallback，不自動 build；既存 graph 先核對 revision／source，query budget 1500，重要關係回原始碼確認。不裝／升級，不啟用 provider、semantic、hooks、stamp、upload。
- pr-lens 固定 CLI `0.11.0`，以真實 base／head SHA 與 `git diff --find-renames <base>...<head>` 為依據；bounded map 保留必要 unchanged neighbors／source refs。於 repo 外暫存 validate／render 並讀 manifest，不安裝、不發布／上傳、不寫 repo config。實際 PR 有既存設定才沿用；無 diff 標 pending，失敗退回直接 diff。
- archify 只做本 topic 一張靜態 workflow，作者繁中、最多 12 主要節點、`meta.quality_profile=showcase`。逐次 validate 且交付前九項檢查零 error／warning；deliver 保存 spec／HTML SHA receipts，visual-check 四尺寸 1440×900、1600×1000、1920×1080、2048×1320，人工看 light／dark 截圖後才聲稱 visual review 完成。不寫秘密，不新增架構邊界，不發布 artifact.cafe。繁中省略 `meta.locale` 並揭露 Viewer UI／HTML lang 的英文 fallback。

## L01 執行前紀錄

Human 已授權本輪一次新 OAuth 並確認同一 OAuth App 配置適用性；不讀秘密、不修改工具。完整八段設計與固定人工語義要求見 [E008](../../experiments/E008/README.md)，四態／三層證據與停止條件沿用本設計。工具來源 `d067c2c`、三檔 SHA 凍結，0/1 使用，尚未執行。

## E008 執行結果與判準保持

[安全 JSON](../../experiments/E008/safe-result.json)已回報當次 HTTP400／invalid_grant／無 token、fresh／single、prepared consistent／omitted；這不是遠端 wire。兩名只見描述＋固定判準的全新 reader 已先封存，共同 verifier_required 聲明及不一致的當次因果分開保存。依原分歧停止規則，主要假設無法判定，不改判準、CLI 模板、原始 outcome／proof 或歷史結果。1/1 已用盡；原文不再保存、重建或重新判讀。此前未執行／0/1 文字是執行前快照，當前結果見 [E008](../../experiments/E008/README.md)。
