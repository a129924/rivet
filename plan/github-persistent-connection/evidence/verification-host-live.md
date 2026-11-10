# 新驗證 App：完整流程真人可行性結果

2026-10-21，新 `GitHubConnectionVerification.app`，R06a–f **approved；requiredFixes=[]**。只證本次獨立驗證工具與受限環境的可行性；不是正式 Rivet 產品登入交付，也不是全 topic 最終批准。R04／R05 獨立 approved 後才開始；每段先通知 Human、收到當段實答才記提示。無新的真人操作需求，Current R07 pending。

本輪開始 `2026-10-21T03:19:42Z`（臺灣11:19:42），未另設45分鐘窗口；availability本身未作結果。舊2026-10-20 Rivet名義host的測量／0提示／approval不混入本表。

## 真實操作與 Human 觀察

| 段 | 本輪機器與真人結果 | Human全段macOS授權提示 |
|---|---|---|
| R06a | 原免費Personal Team／既有Apple Development certificate；新AppID／privategroup、有效embedded profile/currentMac授權；一次GUI Product Build成功、未Run | setup→Team→build前0；授權Build→完成核對0 |
| R06b | 新個人Applications固定位置原不存在；安裝後samebinary／profilehash，observe程序80099。Human親自於新App輸入設定並完成GitHub授權，App顯示GET/user有效帳號 | 安裝／首次啟動→授權→帳號結果0 |
| R06c | 正常Quit80099、精確PID已結束；samebinary新observe82770還原完整bundle並顯示同帳號；refresh／accepted／save皆0 | 完整退出→新程序結果0 |
| R06d | 正常Quit82770；真GUI Clean Build Folder後舊builtproduct不存在，再一次GUI Build；真activitylog有SwiftCompile／Ld／CodeSign，不同binary。備份本輪owned驗證App並同位置替換，新observe85789還原同bundle／帳號，refresh／save0 | 退出→Clean／Build→替換→新程序結果0 |
| R06e | 正常Quit85789；同重建binary、新受控程序86552，只以provider注入clock觸發到期；真GitHub refresh attempt1／accepted1、真DPK save1，輪替六欄digest相符、clock回real、API同帳號 | 退出→受控到期→真刷新／保存→結果0 |
| R06f | 正常Quit86552；同binary新observe90031，未force／未重新授權，輪替後完整六欄restore=providerload，refresh／accepted／save皆0，API同帳號 | 退出→輪替後新程序結果0 |

Human原答：首授權「是，已在新驗證 App 完成授權」；build「0 次」；setup、R06b–f提示各「沒有，0 次」。來源為主對話逐段實答由Dispatcher交接，未另捏造每句receivedAt。所有關閉都先核精確installed executable／PID，再正常Quit並核原PID退出；僅從同固定installed bundle開新程序，無並行 `open -n` 或global environment。每次App視窗明示「GitHubConnectionVerification — GitHub 持續連線驗證」／「驗證用途，非 Rivet 正式產品」；同一positive ID／nonempty login的有效帳號由Tester親看CUA。瀏覽器靜態callback文字沒有單獨當成成功。

## Source、簽章與真正重建

- Repository App30檔hash與[逐檔manifest](verification-host-manifest.md)相符；R05受審source及61immutable（E00732＋舊native29）再核未改，production／tests／package對base零diff保持。不是從舊已提交sourcecommit假稱建置；本輪source為當時feature工作樹快照。
- 私有project的實際delta：App Debug設定原Team；App／Tests兩Debug的LD_RUNPATH_SEARCH_PATHS由字串重寫為等token陣列；Xcode objectVersion56→60。沒有Release設定變更；這些都只在私有副本，原repo project未改。signed A與Clean重建前後的私有project SHA相同，所有其他App source bytes仍符。
- deep／strict signature verify成功；leaf與原安裝App及原已記錄certificate SHA相同；Team相同、新bundle/privategroup正確。embedded profile在測量時有效，含原leaf、正確AppID／group，`system_profiler`的provisioning_UDID在授權裝置清單。IOPlatformUUID是另一識別值，未拿它宣稱device授權。
- Clean前保留原installed驗證App備份；03:39:23Z實際確認private builtproduct不存在，再Build。Build Succeeded、實際compile／link／codesign原生log及不同binary共同證實重新建置，不以timestamp推定。profile bytes維持相同，**不是profile更新驗證**。

| 可公開 hash | SHA-256 |
|---|---|
| App30逐檔manifest | `fc13ed33cf9ee480f500348e18f1d304fd03325ee3920658e7482d04f528baa0` |
| R05獨立Reviewer收據 | `eb17d6faaaabd86a0bec5be73334013db1202ddd409bd20b4ecc1de7416e84d8` |
| 原certificate leaf | `5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440` |
| private signed project | `ab28447135e9d56fb5f0158e7a2c72345f7d111b468311be7bf60b64c2ff2cf4` |
| 初build binary A | `f81133f102e95ce61474b7641478e17e04a2fafe3777fb7cc1b3cac62f83ad0f` |
| Clean rebuild binary B | `63319232522f8bd12dcc9aca0ca7b5bae3582f58481b0afc5947e61aa4217f67` |
| 有效embedded profile（兩build同bytes） | `f149b0da96c7e265aee818a663ba31eeba097e076265f3577110e1377f69a84d` |

## 完整六欄 digest 與輪替鏈

初次observe收據在空設定的start就以exclusive寫出，accountConfirmed=false、refresh／save0，沒有restored digest；後續Human登入不覆寫它。**它不是登入後收據，不用其0計數否定已保存，也不聲稱初次grant process已觀測digest。** 首次已保存bundle的完整digest在R06c新程序才直接觀測，與provider-loaded相同；正常保存→新程序讀回因此有本輪實證。

| 觀測 | 完整六欄 SHA-256 |
|---|---|
| R06c restore＝providerload；R06d亦相同 | `19112c07ad90cba2c113a6443d8a5a2294019424c9f56e94daf6af4822565547` |
| R06e accepted＝persisted；R06f restore＝providerload | `b27c24f990ea82995b615478eef4c73fdc12d6dafcc94bd2a08cf072081c3e36` |

新digest異於舊digest；tokenPairChanged=true只證aggregate pair不同，不宣稱兩個token各自hash。R06e只改provider注入now，沒有改OSclock、HTTP fetcher收到response的realclock或persisted credential dates；accepted真response經真DPKsave才回real。R06f未force且refresh／save0，讀回相同新digest，沒有重新授權遮蓋結果。private receipt皆新owned0700parent／0600exclusive，不覆寫或記rawsecrets。

## 原生收據與機器來源 hash

下列為既有App原生finite process receipts及Tester觀察收據；機器receipt在各段完成時保留promptCount=null，Human真實答覆另以sidecar綁定，不反改機器原檔。完整私有paths、signature／profile輸出及activitylogs僅由Dispatcher私有pointer定位，不入版控。UI來源為親看live CUA states及有限觀察紀錄，不捏造未保存的screenshots。

| 來源 | SHA-256 |
|---|---|
| signedBuildAReceipt | `289608811f02a0919f5c6c30e8e4359d7fccb67dcbf0debea85e99dacfa05d7d` |
| sameBinaryRestoreReceipt | `270d4384ceca20bc62dab7faa9fb28f06290c241695d6d2bc33c1132c78fa5a3` |
| rebuildMachineReceipt | `6200efb591179560ca99375406431792a2095c804d6e4c26d7eced157467c0a6` |
| controlledRefreshMachineReceipt | `60c895f5b35c6120cb6394d04e0f1286c75f181602858a87f633fb74f175d6f6` |
| rotatedFreshMachineReceipt | `b9d2f7a330bfdcf5021929e2176a3e4fe6b55ff4c9c2543523ae6a8efc22762e` |
| firstObserveReceipt | `5a4f19791544f2d1c1f5587def9744a59925e5ca5fce47a597c355b2f4fbcedd` |
| sameBinaryObserveReceipt | `68674370e9d0da042372489015ed591fe08a31d0f1770afae47da542f865d0e1` |
| rebuildObserveReceipt | `04705882011cdba51ba7ce1ee22c4df2e46809164d8e4d5176cc9ae2b28e1121` |
| controlledRefreshReceipt | `9cd1fb057b5f8e3414a37d67b39de42ac46ec086bb8acd890ba99cc169dd834d` |
| rotatedFreshObserveReceipt | `beae01f578bc5e99a9283189b87b845929b54909c2e771339f8801e8320c85e5` |
| humanAndUI | `79cbec68858ec94ee12a48db29ceab428241f11e0dadfa972b2569dd71879138` |
| signed A activitylog 1 | `721a7f4f2db63dc0551d0758fa8c1e18c64e67aab9097e97b7ef6c6ef5576aba` |
| Clean／Build activitylog 1 | `d09f936a22e5e78d8bef6f123f14d261f65c3e3c41369a6790a5638f8796cba2` |
| Clean／Build activitylog 2 | `f88fab876b16c10759c8be5dca884fd2f9e6391a046ec02d40064c47245a53d4` |

## 保留與未驗限制

- 新驗證App與真DPK items保持可用；原Rivet.app／其真items、Apple profiles／certificate、私有project／DerivedData／ownedbackup／原生收據全保留供review。本輪未刪／遷移／revoke舊資料，未建立certificate、未改安全設定或Apple cache。
- 自然access-token到期等待、profile更新後讀回、已過期恢復、certificate rotation、跨機／跨使用者與公開分發未驗證。有效profile／同機同GUI user／相同AppID、privategroup及原certificate是前提；免費Personal Team profile有限有效期，不推論過期仍可用。
- E007兩輪主假設仍unknown，profile更新後讀回仍「未驗證、使用者已接受限制」，不開第三輪，不把同profile的Clean重建當renewal成功。
- 此結果是完整獨立驗證流程的受限可行性結果；R07長期docs／revision圖與工具、R08/R09獨立成果審查、R10原DraftPR交付及Humanreview尚未完成。沒有正式產品登入採用批准，未merge。

[R04自動契約](verification-host-contracts.md) · [production隔離](verification-host-isolation.md) · [獨立審查帳](verification-host-review.md)
