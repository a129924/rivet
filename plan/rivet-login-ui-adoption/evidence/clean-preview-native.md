# T05：取得當下確認後的乾淨預覽原生補驗

- 日期：2026-11-17；owner=Tester（root執行，獨立於I02元件／預覽作者）。
- 來源：`42e99faca1048c1278a498f2a1a147f2afdb5240`，feature branch `feat/rivet-login-ui-adoption`；本輪未修改Swift、tests、Package或wrapper。
- Human明確確認：「允許啟動這次 feature build 的 RivetLoginPreview.app（binary SHA：4d4cf13f719e…），完成必要原生補驗後交給你驗收」。這是啟動與補驗授權，沒有包含最終UI接受。
- 同一wrapper `.build/clean-preview-i02/RivetLoginPreview.app`，ID `local.rivet.login-ui-preview`；binary SHA-256仍為`4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`。
- **結果：下列必要native差異案例已補驗，未發現需修改程式的可定位問題；最終Human視覺／UI接受仍pending，不merge。**

## 原生操作證據

UI觀察／操作僅用CUA，依每步最新AX取索引，代表畫面另讀原生screenshot。初次直接`cua.getApp` exact wrapper、不附args，已成功取得主窗；沒有改走另一個app或變更已核准binary。Source中的單一NSWindow與本輪所見Rivet主窗一致，主窗AX／實際選單未見Controls或測試控制。

| ID | 實際觀察／操作 | 結果與界線 |
| --- | --- | --- |
| CP01 | 不附args啟動，讀回Rivet主窗；Welcome標題Review code, not clutter.、正式說明、Continue with GitHub／PAT入口及中性footer；焦點Continue。截圖見品牌／GitHub圖示，外觀system實際呈Dark／13pt | 通過預設乾淨入口；沒有讀到Demo Controls、fake、simulation、example input only或測試footer |
| CP02 | 點Continue，正式waiting內容含Finish the sign-in steps on GitHub、Waiting for authorization與可取消說明；焦點Cancel。Escape回Welcome／Continue | 通過新host的既有fake callbacks與正式copy，沒有開browser或認證 |
| CP03 | 點PAT，secure欄位label為Personal access token，沒有example input only；空值Submit停用，Create停用hint為Token creation is unavailable here | 通過正式欄位／可用性接線 |
| CP04 | 輸入假字串preview-check，Submit啟用；Show顯示原假文字、Hide恢復secure；點Submit後為Verifying token…，說明Please wait while this sign-in attempt is checked.與中性footer | 通過必要輸入／提交呈現；沒有重做舊完整identity／trim／VoiceOver案例，也沒有新事件計數控制 |
| CP05 | 實際開啟Rivet選單，只見Quit Rivet與系統Quit and Keep Windows；主menu bar為Rivet／Edit | 通過所見選單無測試控制；CUA inventory沒有提供window count，不憑空補造全系統視窗枚舉結果 |
| CP06 | 同binary受控重啟token-failure／Dark／21pt：錯誤The token couldn't be verified. Check it and try again.，欄位焦點；原生ScrollView從0捲到1，底部實際可見Submit與中性footer | 通過代表性大字級／Dark錯誤與捲動可達；只限所見組合，不稱48組重驗 |
| CP07 | 受控重啟browser-failure／Light／17pt：Couldn't connect to GitHub.與Sign-in couldn't be completed. Please try again.；焦點Try again。點Retry回正式waiting，再Escape回Welcome | 通過另一failure origin／正式copy與必要Retry接線 |
| CP08 | 受控重啟completed／Light／13pt：Sign-in completed.及This sign-in attempt completed successfully.，中性footer與完成圖示 | 通過正式完成呈現；只是假phase，不表示實際登入或session |
| CP09 | 最後重啟welcome／Light／13pt，讀回正式Welcome、PAT入口與中性footer；焦點Continue，再取原生截圖 | 已留開供Human查看；當次exact executable程序僅一個，PID5578，SHA不變；未宣稱Human已接受 |

原生新host涵蓋七個畫面變體；verifying-account未在T05另行native重驗，仍保留I02／T04配置測試及T03原來源結果，不回填成新host實際觀察。沒有重做48組矩陣，也沒有自行聆聽或錄製Human VoiceOver。

代表性screenshot為本輪工具回傳的Welcome system/Dark13、PAT system/Dark13、verifying-token system/Dark13、Dark21 token-failure頂端／底端、Light17 browser-failure、Light13 completed及最終Welcome。看過的畫面未見水平裁切或元件重疊；21pt垂直超出內容以捲動到達。圖片是原生工具回傳，沒有另造PNG檔、合成UI或冒稱逐像素比較／Human視覺接受。

## 啟動授權、重啟與歷史

T04的automatic approval review拒絕與當時沒有PID／AX／截圖的事實保留。R04只批准source／docs交付；之後取得上述Human當下確認，才於T05重試同一exact wrapper，CUA成功啟動並讀回UI。這不是以原授權推定可繞過拒絕。

第一個no-args程序用實際Rivet選單Quit；後續同一app用標準Quit快捷鍵結束。每次Quit後AX讀取回報procNotFound／App quit，屬已要求退出後target不再存在；未分類為產品crash或另行重試的軟體故障。確認前一預覽已結束、binary SHA相同，才用既有`open <same app> --args`選下一個state／appearance／text-size；未使用`open -n`、raw executable、其他wrapper或改寫設定。此CLI只在Human當下確認且CUA已成功啟動之後用於同binary已知測試配置，未繞過仍有效的拒絕。

最後以exact executable path加上可有args的程序比對，取得一個PID並核對comm與SHA；只有本次preview被Quit／重啟，原Demo／外部VoiceOver fixture未操作。沒有改系統外觀設定、沒有真憑證、browser、GitHub服務、Keychain或session。設定的Light／Dark只限preview視窗。假輸入在離開表單及程序退出時丟棄；最終Welcome是新的無輸入初始狀態。

CUA本輪completion summary「已補驗乾淨登入預覽」已送出；root沒有待完成native工具呼叫。App保持開啟，PID只是當次交接快照，未保證之後Human不會切換狀態／結束app。

## 交接與剩餘邊界

本輪不改source／tests／Package，不重跑既已通過的15tests／3suites、正式build／format／lint，亦不冒稱重跑root361或focused32。T02、T03、H01–H08原證據與限制保留。

交獨立Reviewer核對本輪證據及授權／接受界線，再依既有授權提交文件與更新Draft。HC01／TC06最終Human正式文案與視覺／UI接受仍pending；啟動許可、native差異通過及Reviewer verdict都不能代替Human接受，不merge。
