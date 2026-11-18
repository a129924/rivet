# E018：正式 OAuth 冷啟動還原 live 驗證

## 驗證什麼
設計日期2026-11-18。主要問題：e31a75a新增的GitHubOAuthStartupRestorer，能否在真DPK與GitHub.com上還原既存OAuth連線，完成必要刷新／完整保存，並由相同signed binary的新程序讀回同完整憑證。
假設：既有設定與完整credential可由正式stores讀取；正式owner只沿原provider policy準備scope，保存成功後ready，交付client可完成GET/user。

## 為什麼
原375tests與consumer22tests是受控證據，不能證明真DPK／簽章／GitHub可用性。本實驗測正式入口，不重跑E014 App或繼承其live通過，不改production。既有E014 App-local envelope與正式adapter欄位／schema相容只由source查核，真正相容性待live。

## 成功與失敗判準
成功：first透過正式owner為ready；實際DPK完整load/readback與six-field canonical HMAC一致；GET/user為200且id/login有效。若自然到期，另外記錄真refresh accepted及save；未發生refresh不能宣稱已驗。first actual process已退出後，fresh只呼一次還原，同binary/profile/source、先讀bundle與first final digest相同，ready與API成功。
失敗：已達有效前提而可觀察結果違反正式契約。無法判定：設定／憑證不存在、簽章／profile／程序／Human觀察或remote依賴不足；不將環境阻擋誤記成產品bug。
投入上限：first一次、fresh一次，任一啟動即耗該slot，錯誤／中斷不重試；fresh僅在first機器結果成功、退出證明與Human觀察完成後。各段120秒timeout，原provider內部有限refresh及client單次401 recovery保持，不額外prepare或snapshot。無初次授權、強制到期、登出、清除、migration或新certificate。

## 環境與前置條件
既有feature worktree，正式Sources／root manifests不改。唯讀查核：一個有效signing identity；一份profile至2026-11-23T06:19:04Z有效，profile AppID與舊E014不同，但其keychain group pattern允許舊App的exact group。實際entitlement只給該exact group，不給wildcard。
舊installed E014 profile已過期，舊App不啟動／覆寫。新驗證host使用現有有效profile允許的AppID／同原leaf certificate，於新私有輸出建置，讀既有E014 service。AppID不同，結果不證明舊App profile續期／同AppID延續性。每段啟動前重驗profile、source/binary與不存在相關writer。

## 重現步驟
先凍結source manifest，unsigned build及--self-test（fake stores/fetcher，零Security／network），controller mock tests與獨立review；再manual sign新私有App，不改Apple cache／trust／ACL／舊bundle。
Controller launch先核exact app/source/profile／無其他writer，O_EXCL消耗phase slot；host hello與actual PID/starttime/executable identity核對後才給authorize marker。Host授權前不建stores或碰DPK。
First使用ports-based正式owner＋正式stores/fetcher，wrappers只觀察真正load/refresh/save結果；ready時freeze準備計數，再透過交付REST client GET/user。結束前以同bound store讀回，canonical HMAC比較六欄（date為store milliseconds精度）。
Fresh新process比對first最後完整bundle digest，不重簽／重建。Public projection僅固定enum/bool/count/SHA/HMAC，不含raw token/secret/clientID/account/response／paths；Human觀察以receipt SHA綁定獨立attestation，不回填machine原文。
完整private paths／identity與run key只在owner-only新runroot；公開證據引用hash與repo相對路徑。

## 是否成功
執行日期2026-11-18。實驗狀態：成功；機器判準與Human觀察均有證據。本輪驗證任務完成：是；獨立Reviewer有限結果approved，仍不代表Human最終topic接受。first與fresh各1/1已用完，不再launch／重試。

## 結果與證據
first真refresh1／accepted1／save1後ready、完整readback與API成功；fresh不同process且同binary/profile/source，讀回同完整credential及同帳號，refresh0／save0。Human兩段皆全程0提示，獨立attestation綁各machine SHA；完整[結果及限制](../../plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)。Unsigned／fake／signature／live／Human觀察分列，不把離線通過當live證據。

## 結論與限制
舊E014/E015/E016/E017及PKCE各輪額度、來源與unknown不改；本輪不啟動舊harness。真refresh是否發生依實際counts，不強制到期、不推自然到期普遍保證。跨程序並行writer、profile renewal、不同機器／使用者／斷電durability及產品UI未驗證。未取得Human觀察則提示次數unknown。

完整readback oracle固定為GET/user完成後最後成功save的完整bundle；若無save則最後成功load。Prepare計數在ready交付時freeze，API階段計數另列，避免將401 recovery輪替歸入啟動prepare。Fresh最初load須比對first最後persisted digest，不拿初始或ready快照當最終oracle。

## 準備紀錄（非live）
最初unsigned build因HTTPHeaders需typed key而編譯失敗，修正為.accept後build及fake self-test通過。控制器15個pure mock tests曾以未知欄位／不一致ready證據得到2個red，補固定schema及證據一致性後15/15通過。Host format／strict lint後續修正通過；第一份unsigned準備source已因此過時，保留但不簽章或啟動，後續以審查後新版本準備最終pins，沒有消耗任何live phase。
六欄HMAC的token/type/scope逐字比較；兩到期日期正規化至整毫秒，不宣稱原始DPK JSON bytes相同。
