# E006 免費 Personal Team／DPK 執行計畫

> 2026-10-16 原始準備契約；最新執行結果見 [E006 README](../../experiments/E006/README.md)／[step](github-oauth-dpk-local-feasibility.step.md)。

本 plan 是受限實驗契約，非正式採用。[需求](../../analysis/github-oauth-dpk-local-feasibility/requirements.md)／[規格](../../analysis/github-oauth-dpk-local-feasibility/technical-spec.md)／[帳本](github-oauth-dpk-local-feasibility.step.md) 同一 topic。九欄契約以 requirements 為準，swift-implementation 必須逐項遵守。

## 執行與停點

1. Plan-Creator 落地四份 artifacts，獨立 Plan-Reviewer 審查；對話 draft approval 不等於四檔 approval。
2. approved 後 Implementer 只在 `chore/github-oauth-dpk-local-feasibility` feature worktree 準備 E006。再次確認 E006 未占用；新八段 README 固定為：定位與問題、既有證據與依據、假設與判準、前提與範圍、最小 host／操作、TestCase／結果、證據／清理、結論／限制／下一步。不得修改 root production/config/E005/docs。
3. 建立規格固定的獨立 Xcode App／純 core、live store guard、preflight parser、coordinator／phase protocol、mock tests及流程圖；只 unsigned build／純 mock，交 Tester，再獨立 Reviewer。準備測試通過不代表 DPK 成立。
4. 到 Human 邊界：提出 Personal Team／開發資產具體需求、另取授權，由 Human 操作 Xcode。不得 inventory 無關帳號、簽章、`-allowProvisioningUpdates` 或創建資產。取得 live proof／完整前提後另取 Human 全程 ready；未取得不得啟動真 App／Security。
5. 未來單輪實驗依固定 phase 0–4，各段 stop／觀察／新 ready；30 分鐘、25 分鐘 stop measure，35 分鐘有效性餘裕不延長。任一失敗 finally cleanup，不等 ready，不重跑或改判準。
6. Tester 核對 machine／Human SHA、資料、prompt、cleanup；Reviewer 獨立分類。遇缺口停於 Human。Git 發布需另有對應授權，停於 human review，不 merge、不核准 adapter。

## 檔案範圍

新增僅 `experiments/E006/`：`DPKProbe.xcodeproj`、`Sources/DPKProbe/`、`Resources/`（Info.plist／單 group entitlements）、`scripts/prepare.py`／`preflight.py`／`run_probe.py`／`ux_stages.py`、`Tests/`、README、`evidence/`、`diagrams/`。四份 topic artifacts 可隨真實進度修正；沒有 release/VERSION 或額外正式 planning artifacts。外部 scratch 不提交個人 raw proof／帳號 assets。Public API/provider ownership 不改。

## 本機圖工具

- Archify：新 E006 DPK workflow，最多 12 主節點、繁中、預設無動畫。`meta.quality_profile="showcase"`，validate／deliver 用 `--quality showcase`，九項零 errors／warnings；visual-check 四桌面尺寸及 light/dark captures，實際逐張視覺審查。繁中 omit locale，揭露 Viewer UI English fallback；不發布 artifact.cafe。圖在準備階段完成，不占真人 30 分鐘；不能沿用 E005 圖冒稱 DPK。
- PR Lens pin 0.11.0：有真實 commit base/head diff 才於外部 scratch 產 JSON validate/render＋head manifest；三步 walkthrough（前提→分段存取→清理）與未修改 ports/provider 鄰近脈絡。先讀 overlay，存在用 config，否則 `--no-config`。不 analyze/canvas/push/auth/provider/上傳/PR assets/repository `.pr-lens`；無 commit head 不造 head，不冒稱 review bot。
- Graphify pin 0.9.73：每 CLI `GRAPHIFY_NO_AUTO_REFRESH=1`；先查 existing graph revision/node/source，bounded query budget 1500後 source verify；無圖/runtime 用 targeted source fallback。不 build/refresh/install/provider/watch/upload/memory 修改或擴 scope。
- 工具失敗明列限制及可完成的安全替代，不重跑 Security 實驗、不宣稱所有交付完成。Archify 硬性品質未過須回修圖或停點，不能以記限制替代 gate。

## TestCase

| ID | 操作／證據／預期 |
|---|---|
| T01 | mock 免費來源／certificate/profile有效期≥35min、GUI/session／group wildcard授權；缺前提拒絕 live store、零 Security 呼叫。真人前提待授權。 |
| T02 | unsigned compile/typecheck＋純 requirement解析fixtures；live兩版不同hash、同certificate/profile/entitlements/DR、雙向requirements驗證待授權，不把mock當簽章證據。 |
| T03 | 未來 phase1完整A六欄相符，Human首次提示≤1；目前未執行。 |
| T04 | 未來 phase2同binary新process唯讀A，六欄相符、Human零提示；目前未執行。 |
| T05 | 未來 phase3真正重建版hash不同，六欄相符、Human零提示；目前未執行。 |
| T06 | puremock：缺proof/ready、stale/tamperedSHA、錯phase/namespace/synthetic、symlink、已存在收據、deadline/abort/訊號路徑均不續測，直接cleanup；六欄/invaliddata/missing/error不混報、redaction。 |
| T07 | puremock所有可能寫入的正常／失敗路徑精確delete-read-absent；真cleanup待授權。未完成保留recovery/殘留，不等下一段ready，不刪Appleassets。 |
| T08 | Archify九檢查／showcase交付／實際visual review；PR Lens有實際head才核mapping；Graphify來源核對或明標fallback。不得當UX證據。 |

## 驗收與保留缺口

資料、UX、驗證任務完成分開記錄，使用未執行／成功／失敗／無法判定。成功須免費前提、三段六欄、首次≤1/fresh0/rebuilt0、精確實驗清理。前提與觀察完整而超標即失敗；不足維持unknown。不輸出 token／個人識別資訊，保留逐段時間/hash/receiptSHA/Human觀察，不覆寫E005或null歷史。setup／cleanup與credential提示分離；未完成cleanup不得宣稱全完成。

免費profile續期／重新佈建、長期恢復、其他macOS／付費簽章／真OAuth／其他身份不測。Appleassets保留由Human管理，不等同殘留未清除的OAuthitem；兩者分開列。成功也不授權 adapter 或 Git merge。
