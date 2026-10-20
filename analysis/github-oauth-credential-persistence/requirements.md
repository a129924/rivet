# GitHub OAuth 正式憑證儲存：需求

- Topic：`github-oauth-credential-persistence`
- 狀態：planning 初稿；尚未經獨立 Plan-Reviewer 核准。
- 配對：[技術契約](technical-spec.md)、[執行計畫](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.plan.md)、[帳本](../../plan/github-oauth-credential-persistence/github-oauth-credential-persistence.step.md)。

## 意圖與明確 scope override

使用者已明確指出既有 `feat/github-persistent-connection` 與 E007 是他人的整套驗證工作，本 topic 必須獨立；這項指示取代先前將儲存 slice 接到該 Mission 的假設。不修改其 worktree、artifacts、實驗、帳本或 gates；本 topic 的實作、驗證與 Draft PR 不依賴 E007、S04c／S04e 或任何 renewal live 結果。

交付 non-BC GitHubIntegration 的正式 DPK adapter：完整 configuration／credential 保存、inspect、clientID-bound store、完整六欄 strict codec、有限錯誤，以及受控 provider restore／rotation 整合。保留既有 bundle、ports、provider、clients 與 generic HTTP 契約。

## In Scope／Out of Scope

納入 DPK Security adapter、兩個 items、public configuration／stores surfaces、同步 fake Security seam、同一 facade 內 actor 序列化、完整替換／失敗分類、fake-only tests、public consumer checks、長期文件與一張儲存 sequence 圖。

不包含登入／callback／UI、signed host、新 certificate／profile／安全設定、E007 或任何 live DPK 操作、真跨程序／重建／系統提示驗證、遠端 OAuth、provider／ports／clients／Package.swift 改寫、完整 logout／revoke、多帳號／跨程序協調、遷移、公開分發或新 BC。

## 驗收

| ID | 結果 |
|---|---|
| AC01 | Configuration 與 credential envelope 都完整往返；六欄無遺失，允許過期日期、空 scope |
| AC02 | 完整有效 envelope 的 clientID 與 bound ID 相符才交付 bundle；bound save不覆寫不同ID或不可讀舊資料，損毀資料不能提供可信ID |
| AC03 | 只接受 schemaVersion=1、非空 tokens、bearer、有限日期及必要正確欄位；不公開 Codable |
| AC04 | Absent、denied、unavailable、corrupt、identityMismatch、invalidConfiguration 可區分，錯誤不含 payload／raw status |
| AC05 | 整筆 update；missing 才 add、duplicate 僅一次完整 update；失敗不 delete／補寫舊值或混合欄位 |
| AC06 | Fake seam 證明所有 query flags／add protection、shared actor、完整替換及錯誤行為；不呼叫 live Security |
| AC07 | Provider 以正式 adapter 加 fake backend 完成 restore、受控到期 rotation；保存失敗後沿用既有停止契約，無額外 refresh／save |
| AC08 | Public consumer 可跨 target 使用新增 surfaces；既有契約與 regression checks 維持 |
| AC09 | 文件與一張 sequence 經必要工具驗證，明列未執行 live／signing／prompts 的限制，無秘密入證據 |
| AC10 | 獨立 Tester／Reviewer 後，依既有授權完成 topic commit、push、Draft PR，停 Human review |

## 授權與證據界線

使用者已授權在本 topic feature worktree 實作，無重大問題時 topic commit → push → Draft PR → Human review；不重複索取一般確認。仍須 staged diff 語意／message 檢查、獨立審查及實際證據，不包含 merge。

DPK 是本 topic 的實作方向；fake tests 只證明本地 adapter 邏輯，不能證明真 DPK、簽章／entitlement、跨程序 durability 或系統提示。這些限制留在文件／Draft PR／Human review，不形成依賴別人實驗的 code gate。若未來需要 live 驗證，另給 bounded 授權與環境契約。
