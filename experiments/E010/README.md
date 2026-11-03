# E010：DPK profile 自然到期與資料恢復可行性

## 驗證什麼

本 topic 的活動身分已由 DPK E008 遷為 E010；dev 的 E008 屬另一個 PKCE topic，不可查詢、resume 或清理。本輪只做 PR #67 離線遷移，沒有新真人／GUI／DPK 測量。主假設仍是同 Mac/user、免費 Personal Team、同 leaf certificate／完整 group 下，P0 自然到期後以不同有效 P1 讀回原假 A；狀態 **未執行**。

原契約見 [requirements](../../analysis/github-oauth-dpk-profile-continuity-feasibility/requirements.md)、[technical-spec](../../analysis/github-oauth-dpk-profile-continuity-feasibility/technical-spec.md)、[plan](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.plan.md) 與 [step](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.step.md)。遷移 M01 已獨立 approved；M02 是作者交付；M03獨立Tester已approved、required_fixes=[]、resolved M-RF01；56方法／Swift7／兩版unsigned與回修focused結果均保留。M04待獨立審實際staged diff，M05具體commit訊息待Human確認；尚未commit/整合/發布。

## 為什麼

PR #67 的原 DPK E008 與新 dev PKCE E008 路徑碰撞。Human 明確接受活動 E010、原始保全及失敗封存紀錄完整保留，topic／branch 不改。自然到期的未知與 profile-only／同 certificate 控制不變；本次遷移不回答 DPK 可行性，也不重新解讀歷史 prompt。

## 成功與失敗判準

遷移須原 193 檔逐筆 accounting，22 原檔快照保全，158 evidence＋13 frozen GUI 逐檔 SHA 不變，E010 身分一致且拒絕 E008，引用按原 blob／pointer／path／SHA 或 Markdown/HTML 原 context 解析。歧義、版本不符、缺少內容保持 unknown，不退回 PKCE 或新 active 近似 bytes。原自然週期判準仍為首次≤1、後續正常讀取零提示、六欄完整且精確清理；S06 human-check／S07 與完整 S08 pending 不變。

## 環境與前置條件

本輪只有離線 pure fixtures／必要 unsigned Debug 與 Rebuilt 編譯權限：Swift 6.3.3、Python 3.14.0。沒有新 grants、namespace、private runroot、clock arm、Apple account/profile/certificate、App launch 或 Security/SecItem 操作。Generic App/project、bundle UUID 前綴、六欄 A、同 certificate/full-group、三窗／十日期限、no-rewrite 與既有 guards 保持。E010 尚未完成整合／registry 登記或 PR 更新。

## 重現步驟

活動 source 僅在本目錄 `Sources/`、`Resources/`、`scripts/`、`Tests/` 與 project。純驗證：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s experiments/E010/Tests -p 'test_*.py' -v
```

必要 unsigned 準備入口：`python3 experiments/E010/scripts/prepare.py --out <fresh-private-tmp>/unsigned --unsigned-build`；兩版固定 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`，不得 launch 產物。這不是 live 命令授權。舊 receipts／腳本／凍結 GUI runbook 只供離線閱讀，不可執行舊 E008 recipe；歷史相對連結可能不再直接有效，請用 [typed map](history/renumbering-map.json) 核對原 context。

## 是否成功

- 自然 profile cycle／原 A 恢復／DPK UX：**未執行**；完整 feasibility 任務未完成。
- 兩輪歷史 controlled-stop：前提不足／無法判定，零 item 的 owned filesystem 清理完成；不是 DPK delete/read-absent。10/22 僅 cleanup 越 cutoff 3.954765 秒，仍在原 deadline 前；沒有 reset 或新測量。
- 本次 M02：遷移作者實作已交付；新 E010 離線證據見下方收據，M03原M-RF01 needs-rework歷史保留；修正後已由同Tester focused approved、required_fixes=[]，M04尚待獨立審查，不沿用原E008 approval。

## 結果與證據

[來源清冊](history/pr67-422d0c7/original-files.json) 以真實 origin commit `422d0c7dd07bf9a746a142d6a07a5cad60c947ed`／Git path／blob OID／SHA 記原 193 檔。[22 原檔 tree](history/pr67-422d0c7/tree/experiments/E008/README.md) 保留原 README、17 active 與四份 planning 文件；22 個檔案與 22 個可取得 source path/SHA 組合是不同統計。

M03 focused收據SHA `20ed1c8145c223cb26bd99aba65aa13243d3e870ef57bff8b497a66ac5594ad3` 明示approved、required_fixes=[]。只核已交付遷移：M-T05為批准base PKCE原blob保護，M-T06為首次占號既存記錄一致，沒有新的全球唯一/登記聲明。map／active manifest／準備收據保留受驗M-RF01快照；map內active-edited文件destinationSHA是當時版本，本文與step僅追加其後角色狀態，不能冒稱相同bytes。M04/後段stage、hooks、commit與整合發佈各依實際後續紀錄，不預填通過。

M-RF01只將三筆 `priorEvidenceManifestSHA256` 聚合指紋分列為 `non-file-digest`，不做file lookup、不列缺失檔案。檔案引用為1952筆（JSON1873／Markdown72／HTML7）：1726 resolved、185 unresolved、25歷史文件版本SHA mismatch、5個缺失source版本涉及16筆；另外三筆聚合摘要獨立記錄。原三筆均保留實際pointer／原值，沒有修改其receipt。

[renumbering-map.json](history/renumbering-map.json) 分開 JSON pointer 與 Markdown/HTML link context，不改舊 receipt、HTML、ID、時間或 index。27 種歷史 source 組合有 22 種可從 frozen original／prior-source bytes 解析，另外 5 種明列 `content-unavailable-in-published-snapshot`，不補造原 Git blob。另有舊文件版本 SHA 不符、無版本 path-only、已清理 private／外部產物等 unknown；每筆保留 expected SHA、context、候選版本與原因，unknown 不當 resolved。

[新 active manifest](evidence/renumbering-active-source-manifest.json) 與 [新離線準備收據](evidence/renumbering-preparation-check.json) 僅核本次 E010 source。定稿前 54 個 core／identity pure methods 已通過、0 skip；最終含 map 檢查結果記在新收據。兩版 unsigned 編譯成功、main SHA 不同、無 debug dylib；不是簽章、DR、profile 或真人重建證據。

兩個原 run 的 [10/21 final index](evidence/run-20261021T035701Z-8e279f70/final-addendum.index.json)／[10/22 final index](evidence/run-20261022T054623Z-dfc25e14/final-addendum.index.json)、全部 14 indexes 及 Human/machine 原 bytes 均保留。原 Human Build success／零 setup 提示與 matching Report/product provenance 缺口同時保留，不推 Human 沒 Build、全機無 App、DPK 失敗或需付費。[凍結 GUI 計畫](diagnostics/xcode-gui-inspection/README.md) 及圖／QA 維持原 bytes，只是未執行的歷史離線計畫；GUI T01–03 未執行。

## 結論與限制

本題仍停 S06 human-check；兩輪 closed grants/root 不可重用，沒有原 A item 或跨週 retention。新 live／GUI／資產／recovery 與逐段 ready 必須另由 Human 決策，不能因改號放行。M02 之後先交獨立 Tester／Reviewer，再依實際 staged diff 各取 Human 新 commit message 確認；尚未整合 dev、改兩 registry、commit/push 或更新 PR #67。E005 legacy UX、E006 的受限成功及既有 controlled-stop／逾時歷史不改。正式 Keychain adapter、真 token/OAuth、產品登入、certificate rotation、公開分發與 merge/adoption 均不在本次範圍。
