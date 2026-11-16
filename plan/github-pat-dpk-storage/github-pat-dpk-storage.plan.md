# PAT DPK 儲存：受限執行計畫

Topic：`github-pat-dpk-storage`。基準 `origin/dev@5713025e3312c0fbc9a7b02a222db0b91d6e1b58`；唯一工作分支 `feat/github-pat-dpk-storage`。只在本 topic feature worktree 工作，不修改 dev worktree。需求與 AC 見 [requirements](../../analysis/github-pat-dpk-storage/requirements.md)，唯一技術與路徑清單見 [technical-spec](../../analysis/github-pat-dpk-storage/technical-spec.md)，狀態見 [step](github-pat-dpk-storage.step.md)。

## Goal／Non-Goal／In-Scope／Out-Of-Scope

Goal 是正式 PAT DPK 的保存、讀回、整筆替換與獨立補驗。Non-Goal 是登入產品化或遠端有效性證明。In-Scope 為 PAT 專用 async actor、有限錯誤／隔離／協調／遮蔽、受控測試、public consumer、E016 host、採用與清理證據。Out-Of-Scope 沿用 requirements 的登入 runtime／UI／session／clients／migration／產品 delete／同步與分發等排除項，不為實作便利擴張。

## ReadOnly／Written／Deleted／Modify／TestCase

四個檔案變更欄位及 TestCase 的精確清單只由 technical-spec 維護，本計畫以引用構成契約：ReadOnly 只能讀；Written 只新增；Modify 只作列明差異；Deleted 為無。TC01–TC04 是本輪必要離線驗證；TC05 與 AC2／3／9／10 的真人部分保留 pending。新增 store 所需 StaticIsolationTests 白名單變更已列 Modify，不修改 root package graph 或 OAuth 來源。

## 派遣與 gate

| Step | Owner | 工作與完成條件 | 下一步 |
| --- | --- | --- | --- |
| P01 | Plan-Creator | 四份正式 artifacts 一致落檔，保留 Human 決策、精確範圍與 live defer。 | 獨立 P02 |
| P02 | Plan-Reviewer | 檢查四文件、契約、scope、路徑與 readiness；明示 approved 才可實作。 | approved→P03；needs-rework→Plan-Creator |
| P03 | Implementer | 新 PAT actor／有限錯誤／internal fake seam、測試、consumer、E016 與使用說明完成；不呼真 Keychain。交付實際變更與待驗範圍。 | P04 |
| P04 | Tester | 親跑 TC01–04、受影響 OAuth／static 回歸、consumer、E016 runner 離線測試與 unsigned host compile、必要 format／lint／diff 檢查。記來源、命令、結果與 skip。 | P05 |
| P05 | Reviewer | 獨立檢查 bounded diff、公開／private 契約、隔離、證據與 live 準備，required fixes 清零。 | approved→P08／P09；needs-rework→Implementer |
| P06 | Human／Tester | 當前 deferred。未來 Human 明確就緒後，核當次 preflight，執行 TC05 並記全段提示與 owned cleanup。 | 本輪保持 pending，不啟動 live |
| P07 | Reviewer | 當前 pending。獨立判讀 PAT 真 DPK／UX／清理證據，不把 OAuth 或 fake 證據當通過。 | 未完成不宣稱 topic complete |
| P08 | Implementer → Tester → Reviewer | 回寫長期 PAT 契約、導覽、採用紀錄、Archify sequence 與工具結果，明列真人 pending；Tester 驗圖，Reviewer 獨立核對。離線文件可在 P06 前交付，未來補 live 結果仍需獨立 review。 | 離線 approved 可交 P09；最終 Human 接受仍 pending |
| P09 | Implementer | Human 本次已授權 topic commit／push／Draft PR。待 P02／P04／P05 與 P08 離線審查完成，檢查 staged diff、提出 semantic message 並依已明示直接 commit 授權提交；push topic branch、建立指向 dev 的 Draft PR、讀回核對。 | 交付可完成；整個 topic 不標 complete |

Reviewer／Tester 不審查自己的實作；需要修正只回對應產出角色。step status、checkbox 或 tracker 不替代獨立 approved。新 required fix 需 bounded 回修及對應補驗，不無條件重跑已通過檢查。

## 工具安排

### Graphify

目前無可用既存 `graphify-out/graph.json`，採 bounded source-search fallback。若後續有可用 graph，只做最小 query／path／explain，核對 revision 與來源。每次 CLI（包括 help／version）設 `GRAPHIFY_NO_AUTO_REFRESH=1`。不預設 extract／build、semantic/provider、刷新、安裝、修改 hooks／config 或寫 graph。Runtime 缺失／不相容／失敗記具體錯誤並回 source。

### Archify

執行階段在指定 diagram 目錄產一份 PAT 保存／還原 sequence；先讀 matching sequence schema、common schema、example，下一作者動作寫 candidate，不先研究 renderer internals。`meta.quality_profile=showcase`；繁中作者內容，省略不支援的 locale，固定 Viewer UI 與 HTML lang 使用 English fallback。每次 candidate 修改後及交付前 validate，必須完整 9 artifact checks、0 composition errors、0 warnings，最後以 deliver 產 HTML 與 receipt；不手改交付 HTML，保留 JSON、snapshot、hash／byte receipts。

對 delivered HTML 執行帶 repo-root 的 visual-check：1440×900、1600×1000、1920×1080、2048×1320 containment，保留最小／最大 light／dark 截圖、contact sheet 與 sidecars。Tester 實際檢視，不把 visualReview=pending 或 screenshots 當自動人工通過；Human 視覺接受另列 pending。非零、skipped 與未執行如實記錄。兩輪無改善依 skill 停止診斷，不擅自發布或啟動 preview。

### PR Lens

只在有真實 bounded diff 後讀實際 base／head 與必要 source，記真 commit IDs，依 references 建本機 change map，含 unchanged direct neighbors。固定 CLI 0.11.0 在 repository 外 scratch validate／render；目前無 `.github/pr-lens.yml`，使用 `--no-config`，若真 PR 階段已有 config 則只讀並使用。保留圖與 render manifest 的來源映射，不模擬未來 diff、不把 change map 視為 correctness verdict。Runtime 缺失回報具體錯誤，不 install／upgrade／npx；不在 repo 建 `.pr-lens`，不執行 analyze／provider／upload／publish／server。Draft PR 建立由 P09 的明示授權另行執行，不是 PR Lens 能力。

## 驗收序列與停止條件

未來 live 固定為 save A→writer 結束→fresh A→replace B→fresh B→真正同身分 clean/build→rebuilt fresh B→exact owned cleanup→正式 load=nil。Human 提示 save A ≤1，其餘四 runtime 各 0，build／sign 另計。失敗／unknown 不啟動相依段；marker／原收據保留，不換 run 或 namespace 掩蓋。

本輪不開始 P06；有效 profile／主機未核不阻塞已授權離線實作／Draft 交付。scope／path／contract 衝突、缺 required gate、runtime／圖驗證失敗或 required fix 未解時，依明示 verdict 回修或停止；不得把缺證據標成已通過。E007 profile renewal 的歷史與 OAuth 舊證據保持。

## 交付與 topic 完成分離

本次可先交付已測、獨立 reviewed 的正式程式／測試／host／文件、topic commits 與 Draft PR；PR 及最終回覆明列 live／UX／cleanup 尚未驗證，不宣稱完整 topic 完成。Human live、圖的 Human 視覺接受、topic 最終 Human review 維持 pending；merge、release、tag 不在本次授權。之後補驗仍沿同 topic 與原帳本追加，不重寫失敗歷史。
