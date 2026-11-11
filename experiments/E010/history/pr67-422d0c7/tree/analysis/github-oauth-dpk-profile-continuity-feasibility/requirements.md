# DPK profile 自然到期與資料恢復需求

- Topic：`github-oauth-dpk-profile-continuity-feasibility`
- Branch：`chore/github-oauth-dpk-profile-continuity-feasibility`，僅本 topic feature worktree。
- 狀態：2026-10-22 S06 操作 checkpoint 文件補強待獨立 Plan-Reviewer；bootstrap／上輪 controlled-stop 受限 approval 保留，主假設未執行。
- 新實驗候選 E008：E007 已由旁支占用；Implementer 建立前須跨已登記 worktrees 再查占用。碰撞回 Plan-Creator 同步四檔並重審，不覆寫、不自行換號。

## 決策問題與主要假設

在同一 Mac／GUI user、免費 Personal Team、同 Apple Development leaf certificate、同完整 App ID prefix＋identifier／private access group 與必要 entitlements 下，P0 profile 自然到期後，換成有效且確實不同的 P1，能否不重寫原假 bundle A 而恢復六欄完整、正常讀取零提示？

唯一候選是 profile-only 的一次自然週期，不加入 certificate rotation。三項結果分開：資料恢復是否成立、到期期間 host／功能是否中斷、人工重新佈建負擔是否可接受。恢復成功不表示持續不中斷，也不等於正式採用；Apple 登入／Xcode／簽章授權不是 GitHub OAuth 再登入。

## 事實、推論與未知

[E006](../../experiments/E006/README.md) 2026-10-19 已支持同 Mac／已登入 GUI、Human 聲明免費 Personal Team、有效 profile、同 certificate/profile bytes/group/entitlements/DR 下完整假 A 首次／fresh-process／真正重建六欄相符，Human 0／0／0。原 item、Apps、raw proof、runroot 已清理；Apple 資產由 Human 保留，今日未盤點。不能接舊 namespace／receipt 或把歷史有效期當今日現況。舊契約鎖相同 profile、35分鐘前提及30分鐘單輪，不能直接跨週沿用或關閉 guard 冒充新證據。

官方文件支持 profile 綁 certificate/App ID/device/expiry/entitlement 授權、免費 profile 週期重新佈建；Xcode automatic signing 可能重用合適的 local profile，所以 build success 不等於 profile 更新。完整 prefix＋identifier/group 要核對，prefix 不必等於 Team ID。合理假設是同授權 group 可延續存取，但自然到期／新 profile 下本機行為仍未知。DR 相同為 E006 控制條件，不是 DPK 跨 certificate 必然相同的要求；輪替另案。

旁支 `feat/github-persistent-connection` 的未合併 E007 是有限背景，不是本 topic baseline／採用 gate／實作依賴。Caller Explorer 2026-10-20 已確認其即時 profile 更新嘗試在45分鐘內因 profile/binary SHA 均未變而 `profileDidNotChange` 停止；renewal read 未執行、結果無法判定、S04e human-check；owned 資料已清理。它未涵蓋自然到期，不能稱續期成功或失敗。本 topic 不匯入／修改旁支 source、raw receipts、資產或授權，亦不需要 E007 可在主 repo 重讀才能執行。

## 九欄契約

| 欄位 | 本 topic 契約 |
|---|---|
| Goal | 補一次 profile-only 自然到期後原假 A 恢復／零存取提示證據，另記中斷與維護負擔。 |
| Non-Goal | 正式 adapter／採用、真 GitHub OAuth/refresh、certificate rotation、長期可靠性保證。 |
| In-Scope | 現在四檔；審查後新實驗最小 App/harness、必要 pure tests/unsigned build；未來另獲授權才跨週／live。 |
| Out-Of-Scope | 改系統時間、偽造 profile、刪/revoke 資產騰 quota、付費/legacy fallback、identity migration、改 trust/ACL/partition/default/search-list。 |
| ReadOnly | E006 與18 source SHA/index/raw receipts、舊 topics、其他 worktrees、production/shared package/config/hooks、架構與官方來源；不盤點帳號資產。 |
| Written | 本四檔；S02 approved 後新 E008 的獨立 App、scripts、tests、八段 README、明標 synthetic 證據。 |
| Modify | 本 topic artifacts 與獲准的新實驗內容；不改 E006/E007/root production/config/docs。長期文件回寫另提明確範圍與審查。 |
| Deleted | 本 phase 無；未來另授權後僅新 UUID item、proven owned App/私有暫存。保留歷史證據，不刪 Apple 資產。 |
| TestCase | plan T01–T09；準備 mock/unsigned 不當真實 profile／SecItem／UX 證據。 |

## 授權分層與判準

Human 已接受受限提案並授權新 feature／四檔，獨立 approval 後準備 minimal harness。現在沒有跨週留存、Apple account/asset、簽章、live launch、Security/Keychain 操作、實際計時 arm 或 commit/push/PR 權限，不沿用 E006/PR59/E007 授權。

未來須另明確同意：一個 UUID 假 item、最小可恢復 host／私有 proof／namespace 的跨週保留位置與期限；Human 操作 Xcode 的具體資產需求；同 group 有效 cleanup host 的取得程序與可能殘留處理；每段完整觀察與 fresh ready。無可接受 recovery 設計不 seed。

預固定：首次存取≤1；baseline後正常讀、有效 P1讀原A、真正重建讀原A均0；六欄完整；精確清理完成。狀態使用未執行／成功／失敗／無法判定，資料恢復／可用性／維護成本／任務完成分開記。

官方來源（Explorer於2026-10-20查證；文件不取代本機測量）：
- [免費帳號與Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [更新profiles](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles/)
- [TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)，官方版本2024-02-06。
- [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)，官方JSON版本2026-09-24。
- [access groups](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps)
- [certificate種類](https://developer.apple.com/help/account/certificates/certificates-overview/)／[revoke影響](https://developer.apple.com/help/account/certificates/revoke-a-certificate/)。

不從 iOS/Developer ID 發佈證書推論免費 Mac certificate 固定期限、過期 launch 或特定 OSStatus。詳 [technical-spec](technical-spec.md)、[plan](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.plan.md)、[step](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.step.md)。

## 2026-10-21 S06-BOOTSTRAP 窄幅澄清

Planner 指出首次設定的循環前提：原 global 要先有實際 P0／certificate 日期，選定已簽素材 verifier 卻要已有 global／W1；unsigned prepare 無法提供該素材。Human 已明確「同意窄幅回修，獨立驗證／審查後回到 S06」。這只授權四檔契約與依序審查後的受限 preparation 回修，不授權真 clock arm、Apple assets／簽章／CMS／Security、App launch／SecItem、跨週留存／真人測量或 Git publication。

允許的未來流程改為：第一筆設定前 exclusive immutable anchor 固定原 t0／W1／global10日、namespace、凍結 source/config/query、Mac/user binding、三 grants 與 begin-ready SHA；原 W1 內用 setup-only 授權／fresh ready 檢查 Human 明選素材，取得實際日期，零 App executor／launch／SecItem；後建完整 global/proof 必須綁原 anchor/W1，沿用原 t0，不猜日期、不重設。完整 global＋actual proof＋另 seed-ready 才能保存假 A。其餘候選、判準、三窗與十日、retention/recovery 及 RF01–RF06 guards 不變。

本段是已獲 Human 同意的回修範圍，不表示修正版文件或程式已獨立通過。詳 technical-spec、plan；目前四檔編寫完成，新的 Plan-Reviewer／Implementer／Tester／Reviewer 結果仍未產生。

本revision獨立Plan-Reviewer另指出W1真App相容性缺口並正式needs-rework：既有LiveGate對三窗一律要求window.globalSHA256，會拒絕新W1單向anchor鏈。窄幅回修範圍因此明確包含且只包含LiveGate的W1鏈驗證相容修改；完整actualproof／另seed-ready仍必需，W2/W3維持原globalSHA binding。其他grant/ready/source/device/expiry/cleanup/RF01–RF06條件不弱化。相應純Swift鏈驗證測試及Debug/Rebuilt unsigned重建屬同窄幅準備回修，不擴App功能或live權限；四檔修正仍待獨立複審。

## 2026-10-22 S06 操作鏈補強（純文件）

本次 Human「可以繼續下一步了」在目前階段只推進文件規劃／獨立審查，不等於批准新輪、適用grants/S/namespace/root、begin-ready、Apple資產或簽章／App／Security／DPK。前真控制輪已closed，不能借其grants或重開時計；要開始新輪仍須Human明確決策與每段ready。

唯讀診斷支持：template/sharedscheme含單一application target與Debug設定，unsigned CLI的明確scheme/config/output不證GUI實際採用。上輪setup-project-open收據記open exit0但UI未觀察、設定未驗；project關閉後的CLI解析不是該次GUI transcript。Human Build成功/freeTeam/既有cert/未Run原話保留，owned App不完整與exact Local Report空亦保留；outside scope unknown，沒有足夠證據宣稱source配置bug、Human未Build或DPK失敗。

唯一補強是未來已獲授權原W1內的操作鏈：新begin→setup-ready→打開同私有project先選Team/合格既有cert但不Build/Run→exact-window GUI設定核對→另build-ready→Human一次⌘B不Run→保持同窗先取matching Report與actualproduct來源→host完整才進原setup-only／complete-global／完整setupHuman／另seed-ready。無法核對就停止，不另掃全域DD或資產、不自動重Build。今日Written/Modify僅本四檔及既有E008 README，Deleted無；不新增runtime收據或更動source/config。

Apple操作說明只作核對依據，不保證本機精確UI文字／位置：Explorer於2026-10-22查閱 [Monitor builds](https://help.apple.com/xcode/mac/current/en.lproj/devb7cf06445.html)、[Build settings](https://help.apple.com/xcode/mac/current/en.lproj/itcaec37c2a6.html)，文件版本current。本補強仍待獨立review，GUI核對即使成立也不等actualCMS/proof或DPK成立。
