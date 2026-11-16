# 本地登出與 OAuth 憑證清除：執行計畫

## 摘要與固定邊界

Topic `github-oauth-local-sign-out`；feature branch `feat/github-oauth-local-sign-out`；起始基線 `2973150b2789d63c10226b57150073ccc793c509`。正式 GitHubIntegration 提供本地登出，單一 owner／唯一 writer，保留 App configuration。成功返回後 credential 不存在，舊 provider 永久失效，晚到 refresh 不重建；指定環境重啟驗收須另有系統證據。

九欄 Goal／Non-Goal／In-Scope／Out-Of-Scope／ReadOnly／Written／Deleted／Modify／TestCase 的執行授權逐項依 [requirements](../../analysis/github-oauth-local-sign-out/requirements.md)。完整 API、retirement、pending-write、errors／cancellation／retry 依 [technical-spec](../../analysis/github-oauth-local-sign-out/technical-spec.md)，不重新設計。

## 受限檔案責任

- 新增 GitHubIntegration Contracts 下 OAuthCredentialClearingStore、OAuthSignOutError；新增 focused local sign-out tests。
- 修改同 target OAuthTokenProvider、GitHubOAuthDataProtectionStores，及 GitHubHTTPClient／GitHubGraphQLClient／GitHubClientScope 的必要 enum mapping。
- 修改對應 GitHubIntegration tests、external consumer tests、isolation checks；不擴張其他 BC／HTTPClient／Presentation。
- 長期結論回寫 OAuth dual-client／credential-persistence 文件，必要 README／architecture index 入口；新增最多一份 topic sequence 圖，不改歷史驗收結果。
- E016 既有目錄僅收隔離假憑證實驗必要 harness、八段 README 與安全 receipts；不得覆寫歷史證據。E001–E015 不修改。
- 無 repo 檔案刪除計畫；PR Lens 僅 repo 外 local-only 產物。不得因工具啟用修改 config／hooks／AGENTS／gitignore。

## 實作與驗收

先以 focused gated tests 固定交錯，再完成 clear capability、DPK delete、provider retirement／pending-write barrier 與 client mapping；依現有工具鏈執行必要 focused tests、consumer checks 及回歸，不用重複測試取代缺少的系統證據。

| ID | 必要觀察 |
| --- | --- |
| T01 | credential 有／無、重複／同時 signOut；共用清除、成功冪等。 |
| T02 | restore gate 中退休；晚到 load 不 publish，token demand 失敗。 |
| T03 | refresh gate 中退休；晚到 rotated pair 不開始 save／publish。 |
| T04 | save 已開始；證明 save settle 後才 delete，最後 load=nil。 |
| T05 | refresh/save failure 與退休交錯；退休不被晚到錯誤處理覆寫。 |
| T06 | unsupported store、denied/unavailable、identity mismatch/corrupt；永久退休，失敗不宣稱清除，可明確重試。 |
| T07 | 取消 signOut waiter、shared snapshot/401 waiters；不取消清除、不供應新 token。 |
| T08 | selector exact、not-found 冪等、configuration/sentinel 保持；舊 clients/scope 後續需求失敗；原 single-flight/expiry/rotation/401-only/public consumer 回歸。 |
| T09 | 正式 adapter 清除後 fresh process credential absent，configuration/sentinel 保持。 |

### T09 有限系統實驗

主要問題：指定有效簽章環境下，正式 adapter 的 exact clear 能否跨程序維持 absence 且不誤刪？假設：同 namespace 唯一 writer、有效 profile／entitlement／同機同使用者成立時可行。

執行前按 feasibility-validation 八段模板固定 environment、來源版本、日期、前提、命令、資料與證據。使用隔離 namespace／完整 fake credential／configuration／相鄰 sentinel，執行一次 seed→正式 signOut→程序結束→fresh-read。最多一次完整序列，不自動重試、不真 OAuth、不操作既有 items。

成功：credential absent、其他 items 保持；失敗：credential 仍在、晚到寫回或誤改 item；無法判定：簽章、程序或觀察前提不足。此段為原規劃判準；2026-11-16有限實驗已成功，見末段現行結果。build/tests 不是系統判準；不外推其他 signer／程序 writer／斷電 durability。缺 T09 不宣稱重啟驗收通過。

## 三項工具

### Graphify

只查既有可用 graph，最小 query/path/explain budget（query 以 1500 為上限起點）；每次 CLI（含 version/help）設 GRAPHIFY_NO_AUTO_REFRESH=1。核對 graph revision 與來源位置，重要關係讀 source。尚未確認 hidden/ignored graph，不宣稱完全不存在；無可用 graph／runtime 失敗則 targeted rg/read。未授權 build、不 refresh、不安裝、不整合、不寫 graph/config/hooks。

### Archify

最多一份必要繁中 sequence 圖：退休→pending write settled→exact clear，長期入口位於 docs/architecture/diagrams/github-oauth-local-sign-out/。產圖階段才進 artifact-first，先讀 matching schema/common/example，下一工具動作寫 candidate；不事先挖 renderer。showcase 九項 artifact checks、0 errors／0 warnings；最後 deliver 凍結 bytes，visual-check 四尺寸 1440×900、1600×1000、1920×1080、2048×1320。保存 receipt／安全 screenshots，真實人工視覺 review 另記 pending/實際結果，不能以 exit0 冒充。繁中作者內容；固定 Viewer UI 英文 fallback 如實揭露。不發布 artifact.cafe。

### PR Lens

實作後待實際 bounded base/head commits 可確認時，記錄真 hashes，讀 git diff --find-renames <base>...<head>。只用 pinned CLI0.11.0，graph/rendered/manifest 放 repo 外 topic 專用暫存區，包含 unchanged neighbors/file refs。現有 .github/pr-lens.yml 若有只讀並套用；無 overlay 的 scratch 才 no-config。validate→render→核對 manifest／圖是否忠實。不得發布、上傳、provider call、canvas/auth/analyze、建立 repo .pr-lens 或修改 config。它是理解層，不是 correctness review；錯誤／失真則具體回報並改讀 bounded diff，不為產圖自行 commit。

## 派遣與停止

Plan-Creator 落四份→獨立 Plan-Reviewer 明示 approved→Implementer→Tester→獨立 Reviewer→Human review。scope／locked contract 衝突、跨 writer 要求及不能解除的簽章前提缺口交回原決策位置，不冒稱完成。2026-11-13 的18:20台北收斂界線作歷史保留；2026-11-16續行僅補T09。保留實際完成、未驗證與下一停點，不以舊時間界線宣稱 gate passed。Human 於本輪明確授權按 topic commit、push、開 Draft PR；執行前仍檢查 staged diff 語意邊界，由主 agent 處理，最後交 Human review。

[狀態帳本](github-oauth-local-sign-out.step.md)

## 2026-11-16：T09 有限執行安排

沿 technical-spec 的既有簽章資產與 E016 專屬 namespace／output 決策；不改已審查的 src。具體固定輸入、兩程序 ordering、簽章與程序 identity、收據 allowlist／殘留規則全部依該補充契約。

1. Implementer 僅在 E016 新增獨立 public-API host、Xcode project/resources、最小 preflight/first/fresh runner、fake protocol checks；補八段 README 的可重現命令。unsigned build 不得碰 DPK；fake checks 檢查 absence 前置、phase write policy、receipt redaction、不可重試及 process/provenance mismatch fail closed。
2. 交獨立 Reviewer 檢查 harness／fake evidence／精確命令與來源 freeze；不以舊 S05 的 code approved 取代新 harness 審查。
3. 審查後 manual signing，核新 E016 app 的 embedded profile/cert/exact group/AppID、signature、expiry/source/binary hashes，無新增資產／舊 app/profile 修改。preflight 只驗環境與 provenance，不 seed/delete。
4. 工具與命令均具體可檢視後，主 session 才安排 Human 兩程序完整提示觀察。first 一次 seed/readback→formal signOut→same-process readback→exit；證 exact process 結束後 fresh 相同 signed binary 一次只讀。實際 prompt count 未知不得填0，Human attestation 綁 receipt hash。
5. Tester 依原成功／失敗／無法判定分類，將 safe receipts 與執行日期／實際停止點回填 E016，交獨立 Reviewer。configuration/sentinel 殘留如實記錄，不增加清理序列。無新OAuth、無refresh/network；T09之外仍沿11/13受控證據。

任一first中斷即停止，不換run重試；fresh前置不足不能補跑。既有profile到期或需新資產則停止回Human，不擴張授權。此處保留執行前規劃狀態，不當作實驗證據；現行結果見下段。

## 現行交付狀態（2026-11-16）

T09有限實驗成功、驗證任務完成，獨立Reviewer approved，見[e016-live.md](evidence/e016-live.md)。歷史受測來源固定bb6752aa483a68043174723a6b3ff2653abe79ce；不得用本次文件commit替代來源pin或要求重跑來追逐文件hash。first/fresh同signedbinary/profile/source、兩exactprocess退出與Human各完整觀察zero有分列證據；原public Human unknown保留，由獨立attestation補充。

本結論受限於當次同機／GUI使用者／既有signer、有效profile、exactgroup、synthetic及uniquewriter；晚到refresh沿正式受控tests，未測trueOAuth／UI／otherprofile／crosswriter／durability。舊ff672c7 first無法判定與已耗額度原樣保留，Human新增序列first/fresh也已使用完。configuration/sentinel留存，無cleanup；不再執行App/build/sign/DPK/retry。後續只交文件一致性審查及S06 Human最終review，不擴張topic。
