# P06：實際 E016 artifact 唯讀 preflight

日期：2026-11-16。角色：獨立 Tester `/root/tester`。本節只記錄 Human 已 Build 的私有 exact app 之唯讀 metadata 查核，不是正式 runner clean/build、live 或 DPK 驗收。

## 當次結果

- 私有 setup root 與 metadata 檔的 owner／0700、0600 條件符合。
- 私有 built-app metadata 的 sourceMatches=true；Tester 額外比較 private copy 與 feature worktree 的 host main SHA-256，相符。
- 從 exact app 讀到的 signed `keychain-access-groups` 恰有一個明確、非空、非 wildcard group；未公開其內容。
- 最終 E016 `inspect()` 在 `exact-artifact-inspect` guard point 拒絕。這是尚未細分的 helper 子條件失敗，本次沒有記錄 raw exception／system output，不能推論是哪個簽章、profile、certificate 或 DR 子條件造成。
- 沒有產生 `selected-signing.json`。Profile／certificate／DR 的整套通過與正式設定選擇仍未完成。

收到「任何 guard failure 不重試、不弱化驗證」限制後，Tester 停止，不重跑 helper、不選 fallback 或改條件。若要定位，應另交獨立 bounded metadata 診斷；目前不得以 Xcode Build succeeded 或部分 signed claims 當整套 preflight passed。

本次沒有查 Keychain 私鑰、簽章、build、Run、runner prepare、`--human-ready` 或真 DPK；沒有新建／更新 Apple assets，也不填 Human prompt counts。Signed app 的既有 build／操作狀態由原 Human setup 證據負責，本記錄不追補為測量通過。


## 新的 bounded metadata 重現診斷

2026-11-16，主 agent 另授權同一 exact app 的一次分段唯讀診斷；這不是 live 重試，也不追補前次未細分的 unknown 根因。Runner source SHA-256：`0ae98d793bede24c63dc134d68d176fa02d7e2eb811fddb9f9dd77c29b65ac6e`。

Tester 以外部記憶體 wrapper 記錄有限 command 分類與 require 的 caller function／line／布林，未改 runner。當次 `inspect` 的明確 group、非 ad-hoc、固定 bundle identifier、Team、signed exact group、profile 有效期／Team／group allowance，以及兩端 application identifier 條件均為 true。

當次停止點為 **`codesign-public-certificate-extract`，native return code=1**，不是上述 require=false。當時命令形狀為 `codesign -d --extract-certificates <private-prefix> <exact-app>`。Certificate membership／expiry 與 designated requirement 尚未執行，不能填為通過；沒有 selected settings 或 runner prepare。

下一個必要調查／修正限 certificate extraction 的 CLI 相容性；optional prefix 是否需以 `--extract-certificates=<prefix>` 傳遞目前只是待驗假設，不當作已證明原因，也不因本次診斷改寫前次結果。Tester 在拒絕後即停止，未再呼叫 native retry、不放寬 claims 或驗證條件。

沒有輸出／保存 raw native error、私人 Team／group／profile／certificate 名稱或 DER；沒有查 private key、簽章、build、Run、真 DPK，也未填 Human prompt counts。既有成功 claims 只屬這個當次重現，不能替代完整 preflight 或 live 通過。


## 新授權的當次完整 artifact preflight：passed

2026-11-16，主 agent 在 certificate extraction 修補的獨立 30 tests 通過後，另授權同一 exact app 的一次完整唯讀 metadata preflight。Runner source SHA-256 為 `67b250f8ed1972086d96c69603d14ef1b812ffc90f45cd6c4491a69385ec1c0d`；本節是新的當次結果，不改寫前兩次 unknown／診斷。

當次檢查全部通過：

- Private copy 的 host main 與 feature worktree 相符；exact app 的 signature verify 成功且非 ad-hoc。
- Signed claims 恰一個明確、非空白、無 wildcard group；profile 的 group allowance 與兩端固定 E016 App ID／Team 條件符合。
- Exact app 的公開 leaf certificate 與 embedded profile DeveloperCertificates 精確匹配；certificate 當前位於 notBefore／notAfter 內並具 Code Signing 用途。
- Embedded profile 到期：**2026-11-23 06:19:04 UTC**；certificate 到期：**2027-09-15 08:17:53 UTC**。
- 以修正後唯一 `--extract-certificates=<prefix>` option 成功讀公開 certificate；唯一 designated requirement 由 stdout 成功取得。

在相同 private setup root 以 0600、exclusive create 與 fsync 保存 `selected-signing.json`；內含 accessGroup、由 selected public profile certificate 計算的 SHA-1 identity、既有 team／profile settings、verified identity、actual binary hash、有效期與 source hashes。私人 identifiers／路徑／certificate 名稱與 raw metadata 不寫入 repository。

本次沒有查 private key、sign、build、Run、真 DPK、runner prepare 或 `--human-ready`，沒有填 Human prompt counts。新的完整 metadata passed 只支持準備後續正式驗證；P06 的 source freeze／正式 clean-build、跨程序、重建、提示與 owned cleanup 仍需各段當次 ready 與證據，不將本節提升成 P06／topic complete。
