# T02：原生 UI 互動補驗

- 日期：2026-11-17；owner=Tester（本輪由 root 執行，獨立於 Swift 元件作者）。
- 使用者明確要求重送原生視窗請求後，再要求完整原生 UI 互動驗證。
- 受測 source head：`83543b07577b548b5d30edf174f33d1d49a65cd9`，branch `feat/rivet-login-ui-adoption`。
- 正式 SwiftUI／E011／tests／Package 無修改；本輪只新增驗證證據及同步文件。
- 結果：本表列出的可觀察原生互動與48組呈現／AX案例通過，未發現可定位的正式元件 required fix。VoiceOver 實際聲音、宣告時序與最終 Human UI 接受保留 pending，交獨立 Reviewer 檢查此界線。

## 來源與 fixture

E011 既有 wrapper 使用本 feature 的正式 Demo binary，與 `.build/debug/RivetLoginDemo` SHA-256 相同：`7b63a99043763cad44fa48f2089cd39f00e6ea555acc0b6d7621f51fbc7ef669`。使用 E011 原生主窗與既有 Controls，只有假資料。

外部 public-consumer fixture 直接 symlink 本 feature 的正式 Presentation sources，Swift6／macOS15／resources 與原驗證 manifest 一致；fake parent 只提供 phase、content、字級、appearance、Create 可用性、root identity 與事件計數。Root 的測試 frame 固定780×500 pt；外側控制區不屬正式 UI。

為使控制項可被工具觀測，本輪只調整 repository 外 fixture：把既有兩個測試窗口合成同一測試窗，並加入該測試 App 的 Quit menu。正式 module／root View／元件沒有 test hook、Adapter 或認證改動。

| 識別 | SHA-256 |
| --- | --- |
| fixture manifest | `e50067f0ef71d1118825dcad8f74930a2774e536b1f31c41edf7f7f18b9370c2` |
| 調整後 fixture source | `46063795d53a7c797029974bb0c48574220acd6df71acb958330b32cf5359ff5` |
| fixture binary／wrapper executable | `d0f16e93973ef8debb2bf9f6a511756eafa02c9b4329b1bcee02ae8d0498f41b` |

最後使用獨立臨時 wrapper ID `local.rivet.login-native-retry.a99d4710ba9d4c03b19dccbc00d93ffc`，重用同一 binary；只改外部 wrapper 的檔名／Info.plist 識別，不改正式 source。fixtures／原始 sample 保留於 repository 外，以 `$NATIVE_SCRATCH` 表示，不記本機絕對路徑。

## 實際原生功能案例

UI 操作只使用 CUA；每步讀回 native AX，重要畫面另取 screenshot。假 token 明確為測試文字，沒有真憑證。下面事件計數來自畫面上的 fake parent，非 model 單元測試。

| ID | 實際操作與觀察 | 結果 |
| --- | --- | --- |
| N01 | E011 Welcome 初始焦點 Continue；Return 後出現 waiting，焦點 Cancel；Escape 回 Welcome／Continue | 通過 |
| N02 | E011 點 PAT：空 secure field、Submit／Create 停用；假文字 Show→可見、Hide→遮罩且欄位獲焦點 | 通過 |
| N03 | E011 Back 後重返 PAT：空 secure field、Show、Submit 停用 | 通過 |
| N04 | public consumer 點 PAT：Events 0→1，Last event `showTokenEntry` | 通過 |
| N05 | 空白輸入 Return 沒有提交事件；非空輸入才使 Submit 可用 | 通過 |
| N06 | `  fake alpha beta  ` 保持可見，在同 root identity 下 tokenEntry→token failure→tokenEntry，文字與 Hide 狀態保留；失敗訊息正確加入／移除 | 通過 |
| N07 | 同一表單的13→17→21 pt及 custom content 更新仍保留上述文字／顯示狀態；AX label 改為 `Custom fake token` | 通過 |
| N08 | 停用 Create 點擊沒有事件、文字保留；啟用後一次點擊 Events 1→2／Create count 0→1，文字保留，phase仍為表單 | 通過 |
| N09 | 點實際文字欄後 Return：Events 2→3，`submitToken=fake alpha beta`；外圍空白移除、內部空白保留；同一讀回畫面已是空 secure field、Show、Submit停用，parent沒有推進phase | 通過 |
| N10 | 再次空白 Return：Events仍3；填 ` mouse-only `後滑鼠提交：Events 3→4，`submitToken=mouse-only`，立即清空並隱藏 | 通過 |
| N11 | 填 `reset-survivor`並Show，fake parent Reset root identity後為空 secure field／Show／Submit停用，Events仍4 | 通過 |
| N12 | Back：Events 4→5／`backToWelcome`、焦點Continue；browser failure焦點Retry；Try again：5→6／`retry`、waiting焦點Cancel | 通過 |
| N13 | waiting Escape：6→7／`cancelSignIn`；Welcome Return：7→8／`beginGitHubSignIn`；滑鼠Cancel：8→9／`cancelSignIn`；錯誤頁改用PAT：9→10／`showTokenEntry` | 通過 |
| N14 | 填 `leave-survivor`並Show，parent直接切Welcome再Token entry：空 secure field／Show／Submit停用，沒有額外intent | 通過 |
| N15 | E011填 `e011-reset-fake`並Show；Cmd+0開Controls，點Reset demonstration後Display state=Welcome；重返PAT為空secure field／Show／Submit停用 | 通過 |
| N16 | verifying account→Welcome，以及waiting→PAT→Welcome的連續UI切態後，焦點為Continue；後續Tab移至測試控制區，沒有被舊Cancel／input／status拉回 | 通過，限已執行的可觀察鍵盤時序 |

事件證據摘錄：`Events: 2 Create count: 1 Last event: createPersonalAccessToken`；`Events: 3 Create count: 1 Last event: submitToken=fake alpha beta`；`Events: 4 Create count: 1 Last event: submitToken=mouse-only`；`Events: 10 Create count: 1 Last event: showTokenEntry`。呈現矩陣與parent直接切態後，仍為Events10／Create count1，沒有由UI自行新增登入工作。

## 原生呈現／AX矩陣

每組均由 fake parent 的原生控制項選擇輸入，讀回正式 View 的 AX；七態中的 failure 分兩種 origin，因此共有8×2×3=48組。

| 畫面變體 | Light13 | Light17 | Light21 | Dark13 | Dark17 | Dark21 |
| --- | --- | --- | --- | --- | --- | --- |
| welcome | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| tokenEntry | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| failure(token) | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| failure(browser) | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| waitingForBrowser | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| verifyingAccount | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| verifyingToken | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |
| connected | 通過 | 通過 | 通過 | 通過 | 通過 | 通過 |

每組確認對應heading／內容、error origin、相應操作可用性；Welcome、PAT、browser failure、waiting 分別觀察到 Continue、欄位、Retry、Cancel 的鍵盤焦點。Verifying／completed 有正確 AX heading，鍵盤焦點為window；這不構成 VoiceOver focus／聲音接受證據。

本矩陣是原生呈現／AX覆蓋。視覺檢查範圍為本輪CUA回傳的代表性截圖：Light13、Dark21 Welcome、Dark21 waiting、Light21 PAT failure上端／捲動到底、Light21 browser failure／verifying account／completed，以及E011 Dark21 PAT上端／底部。看過的畫面未見水平裁切或元件重疊；超出垂直內容使用正式ScrollView，21pt錯誤表單與E011 PAT皆實際捲到Submit與footer。截圖在本輪工具回傳中，沒有另造或重新合成原生UI圖，也沒有將48組AX結果冒稱48張逐像素視覺比較。

## 無效嘗試、工具限制與收斂

1. 原T01兩次cgWindowNotFound與468.7s aborted歷史保留。本輪首次E011視窗存取成功後才開始操作，不回填舊結果。
2. 初版fixture兩個窗口缺切換入口，只調整外部fixture可觀測性。第一次使用程式化AX回傳字串及批次索引的嘗試，立即讀值不同步／timeout，無法確定操作對應；這些嘗試不作產品pass或failure依據。
3. 該fixture process的1秒sample顯示main thread在NSApplication正常事件迴圈、CPU0%；這只限當次採樣，不證明所有時間都正常。E011同時仍可讀；CUA reset及重綁定未解除該次綁定問題。
4. 停止已核對的舊fixture process，重用同一binary建立獨立wrapper。首次getApp耗時272.124s；之後依工具顯示的最新AX逐步操作。公開consumer案例與48組矩陣均以最後獨立wrapper的可見回傳重驗；N01–N03及N15另以E011既有wrapper執行。這些結果不是沿用首次失同步讀值。
5. 本輪沒有繞過CUA去發送UI事件，沒有更改系統權限／OS外觀設定、沒有呼叫GitHub、browser登入、Keychain或建立session。

## 收尾與下一步

最後E011回到Light13 Welcome；額外fixture透過其Quit menu結束，後續CUA app inventory不再列該fixture，E011保留開啟供Human查看。已送出本輪CUA completion summary。

本次未修改正式Swift、測試或Package；先前361 root tests／46 suites與32 focused tests／7 suites證據仍對同一正式來源成立，本輪沒有為文件重跑或冒稱新增單元測試。

TC02／TC03原生缺口已取得上述證據；TC05的48組呈現／AX與所列鍵盤／視覺案例已補驗。TC06、VoiceOver實際朗讀內容／焦點與離開後宣告時序、Human最終視覺／UI接受仍pending，不以工具讀到heading代替。交獨立Reviewer審查補證與採用程度；沒有發現需修改正式元件的可定位問題，沒有放行merge。
