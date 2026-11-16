# E016：本地 OAuth 登出精確刪除與新程序讀回

## 驗證什麼

- 原設計2026-11-13；2026-11-16補具體harness契約，執行日期尚無。
- E016於11/13確認未占用後建立，現延用本實驗，不覆寫其他編號或歷史。
- 唯一問題：正式 provider.signOut 經DPK exact clear後，fresh process是否credential absent，且configuration／相鄰sentinel完整保持？
- 假設：有效既有簽章、同機同GUI使用者、同namespace唯一writer下成立。in-flight refresh競態沿正式受控tests，不由本實驗重驗。

## 為什麼

決策位置為github-oauth-local-sign-out T09。起始來源2973150；11/13已完成受限code/tests審查，不能代替真DPK fresh-process證據。Apple SecItemDelete支持selector，但不證此signed host的提示或跨程序absence。E015保存還原結果不證刪除。

參照E015 public GitHubIntegration連結的macOS app target／單group entitlements／non-sandbox與ENABLE_DEBUG_DYLIB=NO形狀；不重用其ready、runroot、sourcefreeze、namespace、stage額度或收據，不更動E010/E015。完整簽章資產pin及協定見[technical-spec](../../analysis/github-oauth-local-sign-out/technical-spec.md)。

## 成功與失敗判準

執行前固定（11/13判準，11/16具體化可觀察證據）：

- 成功：seed absence/readback成立，正式signOut成功，first與fresh兩程序credential absent且configuration/sentinel逐欄相符；來源／signed binary／profile一致，actual程序歸屬與前程序退出證明及Human完整觀察齊備。
- 失敗：在前提可判定時credential仍在／恢復，或configuration/sentinel被誤改。
- 無法判定：簽章、profile、程序歸屬／終止、receipts或完整觀察不足；不能把環境阻礙記成假設失敗。任意操作失敗先停止，不以新run補救。
- 投入：一個新UUID、一次first→fresh序列；first啟動即消耗，即使中斷或無完整receipt仍保留write-attempted／停止點。不自動retry、換namespace重來、refresh/network或補cleanup。

## 環境與前置條件

- 11/16 Explorer inventory顯示既有E010 identity/profile可選，主session已選較晚expiry組。exact AppID/group、identity/profile pins見technical-spec；profile expiry 2026-11-17T07:28:08Z，每段實際啟動前仍需有效。inventory不等於E016簽章成功。
- 無新資產／automatic provisioning／trust或ACL修改，不修改舊bundle/profile/items。新E016專屬private build/output/DerivedData，root public GitHubIntegration source由feature worktree建置；不重開production API。
- 正式DPK為真依賴；configuration/完整credential/sentinel全固定synthetic。假fetcher被呼叫即fail，不建立網路client。
- source manifest凍結當前commit、dirty逐檔hash、root package/resolution／實際編譯source與E016host/project/resources/runner；signedbinary/embeddedprofile/cert/toolversion/signature receipt再凍結。fresh不得rebuild/resign。
- 同namespace唯一writer是獨立前提；相關舊app已退出、actual PID/starttime/path與binary hash須核對。無法判定不kill未知程序。

## 重現步驟

下列入口已由Implementer建立，unsigned／fakechecks先驗可執行；signed preflight／first／fresh尚未執行。完整命令見[COMMANDS.md](COMMANDS.md)：

1. `E016LogoutProbe.xcodeproj` shared scheme `E016LogoutProbe`、`Sources/main.swift`、`Resources/Info.plist`、`Resources/E016LogoutProbe.entitlements`；最小` scripts/e016_live.py`（實際路徑不含前導空白）僅preflight/first/fresh；`Tests/test_e016_protocol.py`。
2. unsigned build命令形狀：`xcodebuild -project experiments/E016/E016LogoutProbe.xcodeproj -scheme E016LogoutProbe -configuration Debug -derivedDataPath <E016-private-derived-data> CODE_SIGNING_ALLOWED=NO build`。fakechecks：`python3 -m unittest discover -s experiments/E016/Tests -p 'test_*.py'`。這些命令尚未執行；Implementer須在handoff補完整有效參數、fixture與hash，交獨立Reviewer。fakechecks覆蓋phase write policy、redaction、absence gate、retry拒絕與process/provenance mismatch；不存取真DPK。
3. 獨立harness審查後，manual signing指定已選資產與完整bundle；preflight核AppID/exactgroup/embeddedprofile/cert/signature/expiry/source-binary hashes，僅讀環境不seed/delete。將實際完整命令凍結於private provenance，公開只記hash。
4. 工具與命令可檢視後，主session安排Human完整觀察。run生成一個UUID：主service=`local.rivet.experiment.e016.logout.<UUID>`；sentinelservice=主service+`.sentinel`。first經完整App path bundle launch，不能bundleID lookup、open -n或raw GUI binary。runner核actual PID/starttime/executable path/binary hash；App在DPK前自核frozenidentity/phase/run。
5. first：主configuration/credential及sentinel credential先讀均absent，否則停止不覆寫；正式stores seed固定fixtures並讀回逐欄相符；建立正式provider僅signOut；同程序驗主credential absent/configuration/sentinel intact；write receipt並正常exit。
6. 核實first exact process已退出，再由相同App/signedbinary/profile/run launch fresh一次：只讀三項，相同absence/intact判準。fresh不得任何save/delete/seed。runner命令形狀為`python3 experiments/E016/scripts/e016_live.py <preflight|first|fresh> --app <E016-private-app> --run-root <private-run-root>`；實際private inputs由review凍結，不能臨場換app或run。
7. private runroot owner-only，保存actual paths/PID/starttime及identity/group/profile provenance，公開projection只allowlisted booleans/enums/SHA-256，包含phase/outcome/failureKind、run/process/provenance hashes、seed_absent/seed_readback/write_attempted/signout_returned/same_process_absent/configuration_intact/sentinel_intact/fresh_read_verified/previous_process_terminated/launch_identity_verified、source/binary/profile hashes。禁止payload／任意錯誤原文／raw本機路徑或identity。
8. Human每段實際promptcount與完整觀察綁machine receipt hash；private attestation保留數字，公開prompt_count_class為zero/nonzero/unknown enum，另observation_complete與attestation hash。未知不得填0。實際停止點與殘留要記錄；configuration/sentinel留下，不順手清除。

## 是否成功

- 執行日期：未執行，不填。
- 實驗狀態：未執行。
- 本輪驗證任務完成：否。harness已建立且unsigned／7 fakechecks先驗通過；尚缺獨立驗證／審查、簽章preflight、唯一run與Human觀察。
- 本次planning補充不是系統觀察，不能宣稱T09通過。

## 結果與證據

目前無E016系統觀察、seed、delete或fresh-read。11/13受控tests與code審查證據保留原topic，不改寫為本實驗成功；11/16簽章inventory僅前提調查。具體source/binary/profile freeze、actual PID/path/processexit、machine receipt／Human attestation hashes與結果，待實際取得後寫回；未知不能補造。

## 結論與限制

T09仍pending。下一步先Implementer完成最小unsigned工具與fakechecks，再獨立Reviewer，preflight後才Human觀察兩程序唯一run，Tester按既定判準分類、獨立Reviewer核對。資產到期／需新資產／程序不明／任一中斷停止，不重試。configuration/sentinel可能殘留新隔離namespace，無額外cleanup授權。

結論只適用當次同機、同GUI使用者、既有簽章及唯一writer；不外推其他signer／profile更新／自然到期refresh／跨程序writer／斷電durability／正式產品UI。原11/13僅設計且缺harness的紀錄為歷史；11/16補契約後仍未執行，不因紀錄完整宣稱驗收完成。

## 11/16 Implementer unsigned 交接

獨立 E016 host 只 import public GitHubIntegration。7個fakechecks（absence、fresh policy、redaction、不可重試、process/provenance mismatch、prompt unknown）通過；初次red因runner尚不存在失敗。unsigned xcodebuild曾遇局部型別／命名compile錯誤，修正後通過；這些是工具開發歷史，不是系統實驗失敗。正式source沒有變更。

sourcefreeze helper在建置前後比較commit／dirty狀態／實際package與host逐檔hash，保存build-source companion、unsignedbinary／buildlog hash。signed preflight另核固定profileSHA256、profileUUID／expiry、actual leafcert、exact entitlement／AppID與來源，沒有簽章／trust修改。Runner first/fresh需actual PID/starttime/path/hash握手，App在授權前不碰DPK；實際receipt與Human attestation仍未取得。unsigned建置可能執行Xcode正常LaunchServices registration，沒有啟動App／seed／delete。

此處記錄的是Implementer先驗，不是獨立Tester／Reviewer approval，更不是T09成功。最終待驗source hash與實際建置命令由COMMANDS／private build-source companion可重現；本機絕對路徑、profile實際路徑及identity資料不寫公開收據。

## 11/16 harness Reviewer 回修

獨立Reviewer要求的兩項缺口已回修，尚待獨立重驗：

- 新增E016專用sign_prepared準備helper：簽前驗實際unsignedbinary與build-source/source一致，簽後記錄唯一轉換的signedbinary／bundle／profilehash；preflight與launch核該鏈。COMMANDS改用helper，未執行真簽章。
- 以mock實際launch_phase的測試取代未接流程的policy toy helpers：檢查launch前consume、啟動中斷後不可再Popen、source/binary/actualprocess不符不得authorize、fresh缺first通過／termination／provenance不得launch。另mock signing轉換檢查替換unsignedbuild不codesign，以及preflight拒絕缺鏈。

回修後16個fakechecks通過，全部使用暫存fixture與mock subprocess，沒有launch/sign/DPK。原7個先驗數字保留歷史，不能當本輪最新覆蓋。最終sourcefreeze須待最後文件／review完成後重建；先前unsigned companion不能代表後續回修來源。
