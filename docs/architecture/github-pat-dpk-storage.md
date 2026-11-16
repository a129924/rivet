# GitHub PAT DPK 儲存

`GitHubPATDataProtectionStore` 是既有 non-BC GitHubIntegration 的 caller-owned actor，保存 GitHub.com 單一 PAT。不提供登入、遠端驗證、session／clients、遷移或產品 delete；不 conform 同步 `GitHubTokenStore`。

```swift
let store = try GitHubPATDataProtectionStore(accessGroup: entitledPrivateGroup)
let token = try PersonalAccessToken(rawValue: suppliedPAT)
try await store.save(token)
let restored = try await store.load()
```

Host 明確提供具有效簽章／entitlements 的 access group；constructor 不呼 Security，拒絕空白 group／service 或 wildcard group，不改寫 namespace。Service 預設 `local.rivet.github.pat.v1`，account 固定 `pat`；query 明選 DPK、禁止同步、限定 generic-password／group／service／account，新增採 `AfterFirstUnlockThisDeviceOnly`。即使 service 相同，account 仍與 OAuth `configuration`／`credential` 分離；legacy selector 不被操作。

Private JSON 僅 schemaVersion=1 與 token。還原嚴格檢查版本、型別與既有 PAT invariant，VO 建構後字串不同亦拒絕，不以 trim 修復壞資料。只有真正不存在為 nil；其餘錯誤為無 payload 的 denied／unavailable／corrupt／invalidConfiguration。Auth failure／user cancel 為 denied，decode 為 corrupt，其餘系統錯誤為 unavailable，不公開 NSError／userInfo。

Save 先安全讀取既存項目；壞資料／拒絕／不可用時零覆寫。完整 update，不存在才 add，duplicate 最多再 update 一次；保存失敗不刪舊 item、不回補。同步 Security calls 間不 suspension，只協調同 actor 實例，不保證跨實例／程序交易或斷電 durability。沿用既有 PAT 固定診斷遮蔽，不記原值、片段、長度或雜湊；明確讀 rawValue 仍可取得敏感值。

[保存與還原 sequence](diagrams/github-pat-dpk-storage/storage-sequence.html) 描述儲存契約；作者內容繁中，固定 Viewer UI／HTML lang 使用 English fallback。[圖形證據](diagrams/github-pat-dpk-storage/BUILD.md) 區分自動檢查、Agent 視覺檢視與 Human pending。

受控測試採 internal fake Security，一般 import consumer 不呼真 Security。獨立 [E017 host](../../experiments/E017/github-pat-dpk-storage/README.md) 直接使用 public adapter，並提供 run 專屬 exact cleanup；production 不反向依賴 host。OAuth store 與 E015 僅作機制採用來源，舊成功不當 PAT 證據。現行 E017 由原 E016 工具移轉；下節真人驗收仍屬原 `5465d3c` 的 E016 路徑，見[新舊證據鏈](../../plan/github-pat-dpk-storage/evidence/e016-e017-relocation.md)，不追補為新版本 live 通過。

## 指定簽章環境的真人驗收

2026-11-16，受測來源 `5465d3c7308e74bc2b3b51878acd190d4f2babda`、run `39c22b57-de4f-463c-aa4b-8de277c1f60a`，在當次有效 macOS／簽章／private group 環境，以正式 public adapter 完成非機密 A 保存→writer 結束→fresh A→整筆替換 B→fresh B→真正同身分 clean/build→rebuilt fresh B→exact-owned cleanup→正式 load=nil。六個 runtime 都 runnerAccepted=true，Human 每段 wholeStageObserved=true／0 提示；setup／rebuild 另各全程 0 提示。

真正 Rebuilt 使用獨立 DerivedData，實際 compiler log 核到 `-DPAT_STORAGE_REBUILT`；新 binary 與 Debug 不同，原 certificate／profile／Team／group／DR 及 private pins 保持。原 source `55aa57a` namespace 另以新 readonly recovery 正式 load=nil、accepted／Human 0，沒有再次 delete，也不提升原 read A／cleanup unknown；source `0b0692e` setup unknown 同樣保留。

[真人逐段證據](../../plan/github-pat-dpk-storage/evidence/live-validation.md)、[有限公開結果](../../plan/github-pat-dpk-storage/evidence/live-run-39c22b57.json)與[獨立 P07 審查](../../plan/github-pat-dpk-storage/evidence/live-review.md)界定本次成立範圍；P07 approved、required fixes 0。後續文件 commit 只同步 metadata，不冒充受測程式來源。

圖的 Human 視覺接受與 topic 最終 Human review 仍 pending，**整個 topic 不標 complete**。本次不驗 profile renewal、certificate rotation、其他環境或公開分發、斷電 durability、真 GitHub 遠端接受或產品登入。E007 profile renewal 的既有無法判定及 Human 接受限制不變。詳見本題 [需求](../../analysis/github-pat-dpk-storage/requirements.md)、[規格](../../analysis/github-pat-dpk-storage/technical-spec.md)、[計畫](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.plan.md) 與 [帳本](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md)。
