# OAuth 啟動／重連：來源驗證結論

觀察日期：2026-11-17。正式來源與本輪檢視的 E014 快照：`ab77391b73291deb1ce3d96cef72f981aeb3104a`。範圍見 [requirements](requirements.md)；本輪只讀原碼、現有測試定義及已保存證據，未執行 Swift 測試、GitHub OAuth、Security／DPK 或新實驗。

## 主要問題與結論

現有 public primitives 足以表達已鎖定的候選組裝：configuration load → bound store／fetcher → provider → prepare，以及成功 signOut → authenticate 完整成功 → 新 provider／scope。**有條件支持此組裝方案；不宣稱正式組裝已存在或 end-to-end 行為已驗證。** 本輪沒有必須用新實驗才能決定採用方式的未知，故不建立新 E 編號；這不是將新實驗記為成功。

必要條件是同一連線有唯一生命週期 owner、相關登入服務共享 coordinator、排除其他程序與仍可寫入的 provider，並由未來組裝端序列化啟動／重試／重新授權及丟棄舊世代結果。最後這些組裝責任尚未正式接入；不能因 primitives 有測試而推定已實現。正式接入須另有受限契約及組合行為測試。

## 來源、事實與決策影響

以下連結均以本文件位置為基準；行號為上述 source revision 的定位。

| 識別 | 原碼與可觀察事實 | 決策影響與限制 |
| --- | --- | --- |
| S01 | [正式 DPK stores](../../Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift#L35)：configurationStore、inspectCredential、clientID-bound credentialStore；缺 item 回 nil，其他狀態拋 error，clientID mismatch 不覆寫。 | configuration nil 與讀取失敗、credential absent 與 restore 失敗可區分。使用具備 clear 的 bound store；不新建儲存抽象。未呼叫真 DPK。 |
| S02 | [公開 OAuth factory](../../Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift#L4) 回傳 any OAuthTokenFetcher，concrete internal。 | 外部組裝可用公開 factory，不需放寬 concrete visibility；constructor 不等於遠端可用。 |
| S03 | [provider](../../Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift#L55) signOut 先 retired，擷取 pendingWrite，等待其 result 再 clear；refresh／restore 在 await 後及發布前查 retired。 | 舊 provider 永久退休，晚到 refresh 不啟新 save；已開始 save 必須先 settle。signOut failure 也不復活，不得開始新登入；重試 clear 可沿原實例。signOut 不保證所有舊遠端工作已退出。 |
| S04 | [scope](../../Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientScope.swift#L12) 先 snapshot／Bearer 檢查才造 clients；[prepare errors](../../Sources/BoundedContexts/GitHubIntegration/Composition/GitHubClientPreparationError.swift) 分 missingCredential、authenticationRequired、restore／refresh／persist、invalidAuthorizationToken。 | 本地 ready 不做 account probe，不代表遠端身份／權限；取消不交付 scope。可重試錯誤沿原 provider，terminal 不自動重建。 |
| S05 | [登入服務](../../Sources/BoundedContexts/GitHubIntegration/Login/GitHubLoginService.swift#L45) 共享 coordinator 互斥，等待 worker 完整收尾；OAuth 先 authorize／validate 再 save，success 無 payload。 | success 後才建新 provider；初次登入 save failure 仍是 authenticationFailed（本輪不改）。取消可能發生在 save 完成後且不 rollback；不能將 cancelled 推論為 store absent，後續冷啟動仍可能讀到已保存的新 credential。 |
| S06 | [E014 coordinator](../../experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionCoordinator.swift#L204) retireConnection 只清 references；[E014 composition](../../experiments/E014/GitHubConnectionVerification/Sources/GitHubConnectionVerificationApp.swift#L47) 注入 stores、fetcher、prepare 與額外 account probe。 | 是驗證工具，不能搬入當正式 session 退休保證。App-local 同名 stores／DTO 與正式 stores 分開判讀，不由名稱推定來源關係。 |

登入服務組裝的必要依賴：現有 `GitHubLoginService` public initializer 同時要求 `GitHubPATDataProtectionStore`，即使只送 `.oauth` 也需提供此依賴。[PAT store](../../Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift#L12) 建構不呼叫 Security；OAuth 分支不使用 savePAT。此處只記既有建構依賴，不新增 PAT 連線、active-mode 或讀寫，也不為 OAuth-only 擴充登入 API。

GitHubIntegration 即使位於 `Sources/BoundedContexts/`，仍為已鎖定的 non-BC shared module。本輪沒有新增 BC 或責任邊界。

## 既有測試與歷史證據適用性

以下是**閱讀到的測試定義**，不是本輪親跑結果：

- [OAuthLocalSignOutTests](../../Tests/GitHubIntegrationTests/OAuthLocalSignOutTests.swift)：lateRefreshCannotSave、startedSaveSettlesBeforeDelete、failedPendingSaveStillClears、lateRestoreCannotPublish、failedClearCanRetryWithoutReviving、retiredProviderCannotPrepareScope。已涵蓋候選實驗兩種 barrier 的 primitive 不變量；未涵蓋不存在的產品組裝端。
- [GitHubClientScopeTests](../../Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift)：missingCredentialDoesNotReturnScope、lifecycleFailuresAreSanitized、persistenceFailureRemainsTerminalOnOriginalProvider、取消及不做 resource probe 的準備行為。
- [GitHubLoginServiceTests](../../Tests/GitHubIntegrationTests/GitHubLoginServiceTests.swift)：OAuth 完整 bundle 保存、有限 failure；cancellationWaitsForOriginalAndBlocksOverlap 的 during-save 分支使用 PAT，不能改稱 OAuth-specific barrier 已親測。OAuth cancellationDuringAuthorizationWaitsForCleanup 與共用 execute 原碼支持有限推論，完整交接仍待未來測試。
- [E014 live 歷史](../../plan/github-persistent-connection/evidence/verification-host-live.md)：2026-10-21 指定驗證 App 的登入、同版本新程序、同身分重建、受控到期刷新、輪替後讀回／API。該紀錄以當時 source manifest 凍結來源，不是本輪 HEAD 的新 live；保留原 source hashes／Human 範圍。自然到期、profile 更新、certificate rotation、跨機／公開分發均未證明。
- [本地 signOut 長期契約](../../docs/architecture/github-oauth-dual-client.md#本地登出)與[登入 runtime 契約](../../docs/architecture/github-dual-login-runtime.md)各有獨立證據邊界；不能用其他 topic 的 Human 結果當本 topic 批准。

## 是否需要新實驗

本輪驗證任務：**COMPLETE（文件／原碼即可支持有界採用方案）**。新實驗四狀態：**未執行**，沒有新 experiment，亦沒有成功／失敗觀測。主要結論僅為既有機制可供候選組合；組裝行為未驗證，不放行依賴它的正式實作。

若未來需以執行區分具體組裝策略，沿 [technical-spec](technical-spec.md) 的一輪 fake-only／兩 barrier 設計，固定原定成功、失敗、無法判定判準。投入上限不變，不重跑 E014，不以 build/test 成功替代交接判準。

## 未解項與後續限制

- 正式 owner／UI generation／並行 start-retry-reauthorize 的完整接線不存在；需要獨立實作契約及行為證據，不在此選定檔案落點。
- signOut 不能排除其他 provider／程序，且不撤銷已送出的遠端 HTTP。舊世代 UI 結果須另由 owner 過濾。
- configuration 缺漏、缺 credential、store denied／corrupt／identity mismatch 的呈現與復原策略仍是未來組裝端責任；本輪僅保留原 error 語義。
- 取消後 store 可能已保存新 credential，禁止以 cancelled 當不存在或自動清除／rollback。Human 已鎖定的不復活只適用舊連線。
