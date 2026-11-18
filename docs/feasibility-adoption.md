# 可行性成果採用紀錄

## github-oauth-connection-orchestration — 2026-11-17

### 來源與目標

來源 revision `ab77391b73291deb1ce3d96cef72f981aeb3104a`；[需求](../analysis/github-oauth-connection-orchestration/requirements.md)、[來源驗證](../analysis/github-oauth-connection-orchestration/source-audit.md)、[有界盤點](../analysis/github-oauth-connection-orchestration/adoption-audit.md)。A01–A06 是本輪補建識別，沒有改寫 E014 的驗證四狀態或歷史 Human 結果。

目標是 OAuth 冷啟動與重新授權的可行性／採用方案。正式來源仍未接產品 owner；本次交付文件與地圖，production zero diff，不是正式組裝完成。

### 選擇性採用方案

| 能力 | 選擇與依賴 | 接入及預定驗證 | 完成程度 |
| --- | --- | --- | --- |
| A01 冷啟動 | 重用正式 configuration store、clientID-bound credential store、GitHubOAuth factory、OAuthTokenProvider、GitHubClientScope；不新建重複 storage 或改 public API。 | 未來組裝端載入 configuration，保留 nil／error 差異；prepare 後才交付本地 ready。正式接入位置尚未授權，不補造檔案。 | 部分採用：primitives 已有；正式 startup 未接。 |
| A02 錯誤區分 | 沿用 missingCredential／authenticationRequired／credentialLifecycle stage／invalidAuthorizationToken，保留 configuration store error。 | 未來測 absence、讀取／刷新／保存失敗、取消；不擴初次 authenticate Outcome。 | 部分採用：errors 已有；呈現與復原未接。 |
| A03 退休與交接 | 重用正式 signOut；依賴 clearing store、排除其他 writers、owner 序列化與舊世代結果丟棄。 | signOut 成功後才 authenticate；clear failure 停止；取消／失敗不復活舊連線。signOut 不代表所有舊網路工作 settled。 | 部分採用：退休 primitive 已有；整合未接。 |
| A04 新 provider | 完整 authenticate success 後，才用同 clientID-bound store 建新 provider／prepare；暫時錯誤 retry 原 provider。 | 未來驗完整交接；若 save 後才取消，新 credential 可能存在，不 rollback／不當成 absent。 | 未採用：正式 owner 不存在。 |
| A05 驗證專屬構件 | 排除 E014 UI／probe／clock／receipt／App-local adapter 及清 reference retire；不整包搬入。 | E014 僅有限歷史參考，不承接新 source 的 live 保證。 | 已排除。 |
| A06 來源關係 | 既有等效能力足以形成方案；未查明的實驗來源不作採用主張。 | 若需宣稱源自 E014，須另有歷史證據。 | 不確定。 |

### 依賴、限制與實際交付

既有登入服務建構仍需提供 PAT store（建構不操作 Security，OAuth 分支不讀寫 PAT）；這是既有 public initializer 依賴，不擴張成 PAT 連線。必要 primitives 已存在；尚缺正式 owner、產品接入、世代／並行策略實作與組合行為證據。沒有把方案、primitive 測試定義或 E014 成功當正式已採用；本輪沒有重跑 Swift tests 或 live，也沒有新可行性實驗。

後續正式實作須另鎖接入位置、allowlist、interfaces 與驗收。本紀錄保留「部分採用／未採用／已排除／不確定」分類；本輪採用方案交付 **COMPLETE**，正式 orchestration 實作未執行。

### 歷次更新

2026-11-17 首次記錄本 topic，依 source-audit 與 adoption-audit 建立方案；不覆寫其他 topic 或實驗歷史。圖面及製圖檢查見[執行帳本](../plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.step.md)。

## OAuth 冷啟動連線還原正式採用

Topic `github-oauth-startup-restore-runtime` 將既有configuration store、clientID-bound credential store、正式fetcher、provider與scope組裝為caller-owned入口；採用唯一provider、保存後發布、busy與取消settlement，不複製E014 App-local coordinator、UI、probe或驗證控制。

[正式契約](architecture/github-oauth-startup-restore-runtime.md)與[受控證據](architecture/diagrams/github-oauth-startup-restore-runtime/BUILD.md)獨立於E014真人結果。Root375tests／consumer22tests通過；未做新OAuth／DPK、不宣稱產品UI或遠端認證完成，Human review pending。

### 2026-11-18：正式入口 E018 live 追加

原e31a75a受控交付後，Human另行授權live。新E018直接連結正式restorer／stores／fetcher，沒有複製E014runtime或重開其額度；first自然到期真refresh/save各1，fresh同完整credential／同帳號且refresh/save0，兩段Human各全程0提示。實際新host AppID不同、現有profile授權exact舊group，不能回填舊App profile續期。資料保存不rollback、不cleanup；詳[獨立證據](../plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)。
