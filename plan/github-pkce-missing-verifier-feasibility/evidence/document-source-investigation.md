# Missing-verifier 文件與原始碼調查

日期：2026-10-22。來源基線：`fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`，branch `chore/github-pkce-missing-verifier-feasibility`。本輪只查公開文件、repo 原始碼及歷史安全紀錄；未讀配置、秘密、callback 或 provider 原文。

## 主要問題、假設與決策影響

主要問題是帶有效 S256 challenge 的新授權，在交換省略 verifier 時，當次拒絕是否可歸因 PKCE。假設與四態維持[事前技術設計](../../../analysis/github-pkce-missing-verifier-feasibility/technical-spec.md)。

支持證據只增加特定條件下的信心；可信反例交原安全變更流程；仍未知則維持缺口。不改正式 OAuth，不阻塞既有登入 UI，不自行核准採用。

## 官方契約：已查閱，未實測

| 來源／定位 | 觀察事實 | 適用限制 |
| --- | --- | --- |
| [GitHub OAuth Apps：web application flow，authorization 與 token exchange 參數表](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#web-application-flow) | 授權支援 S256；送 challenge 時，交換需要對應原 verifier。 | 是公開契約，不是當次服務端執行證據。 |
| [GitHub Apps：web application flow 參數表](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app#using-the-web-application-flow-to-generate-a-user-access-token) | 同樣記載 challenge／verifier 要求。 | 不能從舊文件的 OAuth App 用語推定真 client 類型。 |
| [RFC 7636 §4.5–4.6](https://www.rfc-editor.org/rfc/rfc7636.html#section-4.5) | client 提交 verifier；server 依已綁定方法核對 challenge，錯配時回 grant 錯誤。 | 協定規範不證明 GitHub 當次拒絕實際走到此檢查。 |
| [RFC 6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2) | invalid_grant 亦包含 code／grant 過期、撤銷或 client／redirect 不符。 | 錯誤碼不足以排除其他原因。 |

本輪以 web 讀取官方頁面並定位 `code_verifier`、§4.5–4.6、§5.2；GitHub 是查閱日的動態文件，未聲稱其具有 repo commit 版本。只保存上述定位與摘要，沒有複製公開範例 token。

## 現有工具來源核對

以下位置均相對 repo，行號對應本輪基線；只讀，未 import／執行 probe：

| 位置 | 原碼觀察與限制 |
| --- | --- |
| `apps/GitHubSignInVerification/tools/pkce_negative_probe.py:314–326` | URL 組裝包含 S256 challenge；exchange_fields 只有 wrong 分支加入 code_verifier，因此 missing 完全省略欄位。 |
| 同檔 `:159–236` | observer 核對 authorization／prepared POST 的 shape、client、redirect、code 與 omitted；只是 prepared inputs，未擷取遠端 wire。 |
| 同檔 `:250–274`、`:865–920` | 每個 attempt 的 callback claim／exchange guard 及有限 fresh／single 結果存在；本輪沒有實際 attempt，不能將 source facts 當成當次成功。 |
| 同檔 `:512–555` | 任一 token 鍵即提早標記存在；missing 只有 verifier_required 自動 passed。CLI failed 不能當作完整成功 token 契約已成立。 |
| 同檔 `:590–680`、`:734–820`、`:929–985` | 有限 privacy gate、cleanup、匿名 pipe 與 opt-in copy；gate 不是未知秘密的完全辨識器，copy 不等於 AI 自動傳送。 |
| `apps/GitHubSignInVerification/tools/pkce_semantic_review.swift:270–400` | protocol 3 不顯示原文，Human 明確滑鼠 copy 一次，30 秒 timeout。原碼存在不代表本輪執行 UI／clipboard／OS 清除。 |

以 `shasum -a 256` 親查三檔，逐一與[歷史 X 安全紀錄](../../github-first-sign-in/evidence/pkce-semantic-review.md)的 frozen SHA 相同：

| 檔案（上述 tools 目錄） | SHA-256 |
| --- | --- |
| `pkce_negative_probe.py` | `26894482d275636d4e736a648b0366ee6ce6b980e5fafb0683b80b40544ff0b9` |
| `pkce_semantic_review.swift` | `8505134d2130f1f99a1339cb9abbccabe894c2db73575c60d759d542a5a5e405` |
| `test_pkce_negative_probe.py` | `62d1849c1d1b16351b27b4b6ea1247c75a24a8c6fdf9b3c32908e733c3fde0c5` |

X 的正常 native copy 與 wrong mismatch 只沿用其原始條件與限制；未重跑 67 tests、synthetic、正常登入、wrong 或翻譯。歷史 missing 仍是無法判定，不追補原回應。

## 最小方法與資訊增益

現有 missing＋opt-in copy 可作候選，沒有查得必須修改工具的 source 缺口。新的完整、通過 gate 的當次描述，可能相對歷史 unknown 增加 provider 因果聲明資訊；不能保證會取得清楚描述或成功通過安全檢查。

但真 client 註冊類型、目前配置適用性與本輪 Human 的真人／原文授權均未確認。文件只能回答規範，不能回答本配置的當次行為。故不開始真人授權、不輸入配置、不產生新 code、不交換 token，也不建立新 experiment；沒有為補前提增加正向對照。

若未來另准，仍依固定判準：一次新授權／新 code／單 exchange，開始授權即耗唯一機會；兩名 reader 只收同完整單欄及判準，先封存結果後整合。若 mismatch 就記 mismatch，不改為明言缺少；CLI 自動結果保持原樣。任一 token 鍵即停，有限輸出不足時不能宣稱假設失敗。

## 工具導航與操作量

- `GRAPHIFY_NO_AUTO_REFRESH=1 graphify --version`：實際回 `graphify 0.9.73`。限定 repo 定向檔案清單查無可用 graph，因此 source fallback，未 query／extract、未 build 或刷新 skill。
- 固定 pr-lens runtime `--version`：實際回 `0.11.0`；本機 change map 待 M07 真 commit base／head 後建立，不冒充當下已存在的 PR 圖。
- 三項工具、workflow 圖與文件檢查均非遠端 PKCE 證據。

## 結果與完成界線

| 項目 | 本輪狀態 |
| --- | --- |
| 新真人實驗四態 | **未執行**。 |
| 本輪遠端拒絕／provider 聲明／實驗支持 | 都沒有新增觀察；歷史 missing 的歸因仍無法判定。 |
| 投入 | 一輪文件／source 調查；新 OAuth 0、code 0、exchange 0、原文傳遞 0。 |
| M03 離線調查 | 已完成：來源、方法適配、缺口與決策限制已交付。 |
| 特定配置真人補證 | 未完成、未授權；不是假設失敗，也不是正式 OAuth 漏洞。 |

結論交[長期文件](../../../docs/architecture/github-pkce-missing-verifier-feasibility.md)。後續只完成本輪已授權的圖、驗證、審查與 Draft PR，停 Human review；不自動安排下一輪或解除 L01 人類邊界。
