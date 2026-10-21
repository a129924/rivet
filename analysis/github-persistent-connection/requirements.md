# GitHub 持續連線：整條流程可行性驗證需求

## 現行補充：RF-C01 匯出與清理失敗安全（待獨立規劃審查）

Human 已授權 PR comment review → 必要回修 → topic commit → push → 回覆及 resolve 已處理 thread，不重問是否開始，不 merge。獨立 Reviewer 的 `needs-rework` 指向 [評論 4333613564](https://github.com/a129924/rivet/pull/62#discussion_r4333613564)（thread `PRRT_kwDOUFu0Cc6upRad`）：E007 `export_clean` 在 final.index 完整保存前已刪私有來源，後續 hash／stat／index write 失敗失去證據，半成品公開目錄阻擋重試。

本補充優先於下方已完成歸屬回修的唯讀描述；下方與 R／S 步驟保留歷史，不重開 App／production scope。只修匯出可靠性，不跑第三輪實驗。

| 欄位 | 本輪受限契約 |
|---|---|
| In-Scope | E007 先完整耐久匯出再清理、無覆寫發布、真實 pending／completed、失敗恢復、合成測試與文件、獨立審查及原 thread 交付 |
| Out-Of-Scope | 新E007／Applecache或資產／Keychain／GitHub／新App真人重驗、production、PR61、去重合流、merge |
| ReadOnly | E007其餘29檔、原run／preparation收據、舊native圖29檔及全部新版native圖、production、新驗證App source/tests、R06真人證據、其他topic |
| Written | 只有owned synthetic temp／runtime staging／journal／發布物；無新repository leaf或歷史runreceipt |
| Deleted | 無trackedfile；只可清理本次synthetic ownedtemp，真run不操作 |
| Modify | plan C-M01–09精確九檔；僅解鎖E007 runner／protocoltests／README三檔，其餘是四artifacts與兩既有manifest/review |
| Goal | hash／write／fsync／publish／cleanup failure保有原來源或完整可恢復發布；不預填清理成功、半成品不永久阻重試 |
| Non-Goal | 改舊SHA／收據、冒稱新版runner已live、自然到期或profile更新已通過、新Human gate |
| TestCase | C-T01–07，合成temp／故障注入，不重跑無關Swift／真人／圖工具 |

舊 runner／tests／README 在 `62dece35` 可追溯；runner SHA `62ca01370b78578db5ac3e45836b747765d7b201dbbf77438458a6003b90c484`、tests SHA `7798a5c8463ebec7e0b8574247f81679cab07e56b52e4a311cc8bf985036e65f` 保持歷史，不能重算舊收據。profile更新後讀回仍「未驗證、Human已接受限制」，自然到期仍未驗證。

---

- Topic：`github-persistent-connection`；2026-10-21 回修 scope，待獨立 Plan-Reviewer。
- 現行定位：獨立驗證 App、可行性結果及限制；**不是 Rivet 正式產品登入能力**。
- 配對：[技術契約](technical-spec.md)、[計畫](../../plan/github-persistent-connection/github-persistent-connection.plan.md)、[帳本](../../plan/github-persistent-connection/github-persistent-connection.step.md)。

## 意圖與已撤回的結論

本 topic 只驗證 GitHub.com「登入 → DPK 保存 → 完整退出／重啟還原 → 同身分重建 → 自動刷新 → 輪替後新程序讀回 → API 使用」整條流程是否可行。交付完整可操作的獨立 `GitHubConnectionVerification.app`，畫面、scheme、module、product、測試與文件皆明示驗證用途。

先前將這些產物加入正式 Sources、共用 RivetPresentation 及 `apps/Rivet`，並宣稱正式產品持續連線完成，現依 Human 明確指示撤回。2026-10-20 的實際測量、當時獨立審查與 Human 接受作為原版本歷史保留，不是新 host 驗收，也不是正式產品能力採用證明。原提交 `ca00bc074f77fa21a7fac1aaae07dc1059de5b01` 可追溯舊 artifacts；原 source commit 為 `7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18`，實際真人 build 在提交前，必須保留原 source-hash provenance，不能偽稱當時由該已提交 commit 建置。

## 鎖定範圍與九欄

| 欄位 | 契約 |
|---|---|
| In-Scope | 完整獨立驗證 App；初次授權、兩 DPK items、restore／refresh／輪替保存、API、受控到期與脫敏收據、失效／修復／重新授權、適當測試及必要真人重驗；歸屬清單、文件圖與原 Draft PR 修正 |
| Out-Of-Scope | 正式產品登入整合；與 PR #61 去重／合流／共用抽象；多帳號／Enterprise／PAT／device flow／broker；PR 業務；logout／revoke；generic auth、一般 retry／pagination／rate limit；公開分發、certificate rotation、第三輪 E007 |
| ReadOnly | 本 topic 前既有正式能力、所有其他 topic／PR #61、Package.swift／lockfiles／既有工具設定；E007 全部 32 檔與舊 native 圖／凍結收據 |
| Written | 計畫精確 manifest 的 App-local source／UI／adapters／tests／project／資源／README、新版證據及 revision 圖面 |
| Deleted | 本 topic 新增於正式整合／共用 UI／root tests／Rivet host 的 19 檔；不刪原安裝 App、真 DPK、Apple 資產或歷史證據 |
| Modify | 本四 artifacts、四個正式檔僅撤本 topic delta、四份長期文件、舊 evidence／圖導覽的明示歷史 banner，原 PR #62 title／body |
| Goal | 完整可行性流程可由驗證 App 操作；production 對驗證 App 無反向依賴，整個移除仍 build／test；新舊真人結果可追溯 |
| Non-Goal | 保留驗證專用 production API／控制開關／收據工具、宣稱正式產品完成、用舊0次提示或 mocks 預填新 host、推論所有 profile／OS／cert 週期 |
| TestCase | 計畫 TC01–TC10；各 bounded handoff 帶精確檔案子集與適用 cases |

## 可核對的成功條件

| ID | 驗收 |
|---|---|
| AC01 | 名稱及常駐畫面明示「GitHubConnectionVerification／GitHub 持續連線驗證／非 Rivet 正式產品」；入口可完成真 OAuth 與 GET /user 有效帳號 |
| AC02 | 完整六欄 credential／自有 OAuth App 設定保存；同 binary 新程序不重授權即可查帳號 |
| AC03 | 同身分真正 Clean／Build、同位置替換後新程序讀回；原 certificate／AppID／private group 相同且 profile 有效 |
| AC04 | 受控到期僅改 provider 注入時鐘，真 GitHub refresh＋真 DPK 保存成功；下一個無強制到期新程序讀回相同輪替 digest 並查 API |
| AC05 | 取消、denied、invalid callback、暫時失敗、失效、terminal／accepted rotation 保存失敗有可區分結果；不覆寫 denied、不重建 stopped provider、不恢復退休連線 |
| AC06 | 使用原 provider／scope／雙 client lifecycle 及既有 HTTP 401 有限 retry，不加 production API；local tracker 不透過再呼叫 snapshot 偽裝觀察 |
| AC07 | 正式 source／root tests 精確恢復 topic 前基線；Package 與既有 PR UI 不變；排除整個驗證 App 的獨立 production build／test 通過 |
| AC08 | 名稱、module、target、scheme、product、TEST_HOST、import、資源與測試皆 App-local，無 RivetPresentation 依賴、無正式 target 反向依賴 |
| AC09 | 每項新增／搬移／刪除／修改／保留可對照 manifest；build／tests／格式／依賴／圖工具及獨立審查有實證 |
| AC10 | 新 host 真人結果逐段通知 Human、觀察後才記；首次 ≤1 提示、fresh／rebuild 0；不足即未驗證。不得以舊host0次或受控觸發冒充自然到期 |
| AC11 | 不保存原始 token／secret／code／完整 callback query／回應 body／Apple raw identity／本機絕對路徑 |

## 歷史與限制

E005 legacy 提示0／0／1未符合重建零提示；E006有效 profile 下0／0／0只屬受限實驗。E007兩輪更新後讀回均未執行、主假設 unknown：第一輪 profile bytes 相同；第二輪備份恢復預檢新增 provenance xattr，故原快取未移出、未 refetch、未 B build。兩輪安全收尾與32檔原證據 immutable，不開第三輪。

Human 已明確接受「profile 更新後讀回尚未驗證」的限制；此限制沿用，不能改成 pass。仍需有效 embedded development profile、同機同 GUI user、同 AppID／private group／原 certificate；免費 Personal Team profile 七日到期、過期期間不可用、已過期恢復／certificate rotation／公開分發未驗證。此次改歸屬不觸 Apple cache，也不刪／遷移舊 App 與真 DPK。

新 host 使用新的驗證 identity、group 與 service，不能讀取／移轉舊正式名義資料。保留舊5份 evidence 內容，頂部僅加版本歷史 banner；舊 native JSON／HTML／delivery／visual-check／PNG及E007逐 bytes保留。新版 evidence 使用 `verification-host-*` 名稱，新圖置 `verification-host-v2`。

## 授權與停點

沿用同 feature worktree、branch `feat/github-persistent-connection`、Draft PR #62、base `dev`。不在 dev 實作，不改 PR #61。Human 已授權本輪先修四 artifacts／必要獨立審查，再實作、測試、逐段必要真人驗證、topic commit → push → 更新原 Draft PR → human review；每次依 staged diff 檢查語意／message，不再詢問是否開始或重問已授權 commit，不 merge。

沿原免費 Personal Team 及既有 Apple Development certificate；需要新 certificate／付費／安全設定／cache變動、正式契約無法撤回或重大 scope gap，先停並提出具體必要性與範圍。未到 Human 操作段先完成可獨立工作，不預填真人結果。
