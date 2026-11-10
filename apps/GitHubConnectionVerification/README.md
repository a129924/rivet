# GitHubConnectionVerification — GitHub 持續連線驗證

這是完整流程的**獨立驗證工具，非 Rivet 正式產品**。它驗證登入 → DPK 保存 → 完整退出／重啟還原 → 同身分重建 → 自動刷新 → 輪替後讀回 → GET /user，沒有整合 PR 業務。App、UI、adapters、coordinator、受控時鐘、收據與 hosted tests 全在本目錄；production 僅提供 topic 前既有 public contracts。移除整個目錄不需修改 production。

## 建置與 fake-only 測試

在 repository 根執行，使用自行指定的私有 DerivedData；不要在另一個 worktree 寫入：

```sh
xcodebuild build -project apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj -scheme GitHubConnectionVerification -destination 'platform=macOS,arch=arm64' -derivedDataPath <private-derived-data> CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=
xcodebuild test -project apps/GitHubConnectionVerification/GitHubConnectionVerification.xcodeproj -scheme GitHubConnectionVerification -destination 'platform=macOS,arch=arm64' -derivedDataPath <private-derived-data> CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=
```

共享 test scheme 注入 `GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE=1`；entry 最先檢查此值，早於 DPK／listener／OAuth／restore／validation 建立。測試只使用 fake Security／transport／store，不代表真 DPK 或 GitHub 已驗收。macOS15+、Swift6，Debug 只建 active architecture、停用 debug dylib、non-Sandbox。外部 package pins 沿 root，沒有新增版本或 RivetPresentation 依賴。

## 真人驗證前提與逐段操作

使用原免費 Personal Team 與既有 Apple Development certificate，在本輪私有 Xcode 副本設定 Team；有效 embedded development profile、AppID 與 private group 必須一致。遇到新 certificate、付費或安全設定要求即停，不修改 Apple cache。固定在個人 Applications 的新 `GitHubConnectionVerification.app`，不覆蓋未知同名 App，也不碰原 `Rivet.app`。

每段執行前通知 Human 留意 macOS 授權視窗，收到實際回報才記提示次數：

1. 新 identity 簽章／profile／固定安裝位置核對。
2. 在 SecureField 輸入自己的 OAuth App secret，Client ID 及 callback `http://127.0.0.1/oauth/callback` 核對；完成真授權、保存並取得有效帳號。
3. 完整退出並確認原 PID 結束，同 binary／位置的新程序還原與 API。
4. 真正 Clean／Build，不同 binary、同 AppID／group／certificate、同位置替換，再新程序還原。
5. 明確 opt-in 受控 provider clock 觸發真 GitHub refresh／DPK save，驗證六欄 digest 輪替、clock 回 real、API。
6. 完整退出，再未強制到期的新 observe 程序讀回輪替 digest 與 API；不得把自然到期說成已驗證。

初次 ≤1 提示、fresh／rebuild 0 是本輪事前判準。2026-10-21 新 host 六段已由 Tester 實際驗證：真授權／DPK保存／API、同binaryfresh、真CleanBuild不同binary同身分還原、受控providerexpiry真refresh accepted1／DPKsave1、輪替後observefresh讀回同六欄digest與同帳號API。各段Human實答皆0次；依[本輪真人收據](../../plan/github-persistent-connection/evidence/verification-host-live.md)，不以舊Rivet名義host的2026-10-20數據替代。

## 儲存、控制與限制

本 App 的 bundle ID 為 `local.rivet.github-connection-verification`，private Keychain group 為 `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`，service 為 `local.rivet.github-connection-verification.oauth.v1`。DPK 兩 items：`configuration`／`credential`；無舊資料遷移、刪除、logout 或 revoke。

僅明確環境 `GITHUB_CONNECTION_VERIFICATION_MODE=expire-restored-once|observe` 及 `GITHUB_CONNECTION_VERIFICATION_RECEIPT` 啟用私有觀察。receipt parent 須 user-owned0700，檔案以0600 exclusive建立、不覆寫；只記有限 counts／hashes／booleans／PID／observationID，不記 raw token／secret／code／callback query。受控時鐘只改 provider 注入的 now，不改 OS clock／真 response receipt time／保存日期；真 accepted save 後回 real。test mode 忽略控制環境。

同 generation tracker 只觀察實際 refresh／save outcomes，查詢不再呼 snapshot／網路／store；不暴露 production terminal API。停止 provider 必須重新授權，新授權整份保存後才建新 provider；取消須等待實際 operation settlement 才釋放 admission，不復活退休連線。

profile 更新後讀回仍**未驗證、使用者已接受限制**；不開第三輪 E007。免費 profile 七日有效，過期期間不可用；certificate rotation、過期恢復、跨機、公開分發未驗證。不得把這份工具當作正式產品登入能力。

[本輪需求](../../analysis/github-persistent-connection/requirements.md) · [執行計畫](../../plan/github-persistent-connection/github-persistent-connection.plan.md) · [新 host 證據](../../plan/github-persistent-connection/evidence/verification-host-live.md)

## 本輪文件版本與觀察界線

此README於R07作doc-only現況修正；原R03／R05／R06當時30檔manifest／source-hash收據原樣保留，其餘29檔未變，不宣稱current30bytes皆相同。初grantprocess的observe receipt在emptyconfiguration階段已exclusive寫出，未觀測grant後digest；oldbundle的完整digest在R06c新程序才直接讀回。受控providerclock觸發真refresh不等自然到期；aggregatepairChanged不等個別tokenhash。新host真人source依當時feature工作樹hash與私有project／真buildlog追溯，不能偽稱自尚未產生的本輪commit建置。
