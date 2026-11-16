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

受控測試採 internal fake Security，一般 import consumer 不呼真 Security。獨立 [E016 host](../../experiments/E016/github-pat-dpk-storage/README.md) 直接使用 public adapter，並提供 run 專屬 exact cleanup；production 不反向依賴 host。OAuth store 與 E015 僅作機制採用來源，舊成功不當 PAT 證據。

目前交付為正式 adapter、受控驗證與 unsigned host 準備。**真 DPK、跨程序／同身分真正重建、Human 提示觀察及真項目清理均 pending；完整 topic 未完成。** 不推論 profile renewal、certificate rotation、公開分發或 GitHub 遠端接受。詳見本題 [需求](../../analysis/github-pat-dpk-storage/requirements.md)、[規格](../../analysis/github-pat-dpk-storage/technical-spec.md)、[計畫](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.plan.md) 與 [帳本](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md)。
