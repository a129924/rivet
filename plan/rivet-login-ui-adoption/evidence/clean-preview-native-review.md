# R05：乾淨預覽 native 補證獨立審查

- 日期：2026-11-17；owner=Reviewer，獨立於I02作者及T05 Tester。
- 受審來源：`42e99faca1048c1278a498f2a1a147f2afdb5240`，branch `feat/rivet-login-ui-adoption`。
- **verdict: approved，僅限T05必要native補證與既有Draft文件更新；required fixes：無。**
- **最終Human正式文案／視覺／UI接受仍pending，TC06整體與topic不宣稱完成，不merge。**

## 有界審查

依 `sdd-workflow-contract` 核對四份artifacts的既有scope／I02 addendum／接受界線、T05文件與本輪UI說明／step差異，並對照繼承的Human當下許可、root實際CUA AX／原生截圖及程序／SHA工具回報。沿用R04 source審查，不重做source review，不執行GUI、build、tests或新的程序控制，也沒有自行聽取VoiceOver。

本輪 `git diff HEAD --name-only -- Sources Tests experiments Package.swift Package.resolved` 為空；HEAD確為上述SHA，`git diff --check`通過。變更限於補證及狀態文件，T04／R04歷史未改判。

## 證據判定

| 範圍 | 結論與限制 |
| --- | --- |
| 啟動許可與來源 | Human對SHA `4d4cf13f719e…`的同一preview app明確給予當下啟動／補驗許可；其後root直接CUA成功啟動exact wrapper並讀回UI。完整SHA仍為`4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`；沒有將R04 source批准或舊授權當成可繞過T04拒絕。 |
| CP01–CP05 | 原生AX／截圖支持無args乾淨Welcome、正式waiting／Cancel／Escape、PAT secure label及停用狀態、假字串Show／Hide／提交到verifying-token，與正式footer。Rivet menu實際只見一般Quit項目，bar為Rivet／Edit；未造出inventory未提供的window count。 |
| CP06–CP08 | Dark21 token-failure上／下端截圖與scroll 0→1支持Submit／中性footer可達；Light17 browser failure的中性訊息、Retry→waiting→Escape及Light13 completed正式copy均有實際回報。僅限這些代表，不是全48組或逐像素比較。 |
| CP09與交接 | 最後Light13 Welcome的AX／原生截圖與Continue焦點可核對；exact executable含args的程序比對支持當次一個PID5578、同SHA。留開狀態是當次快照，文件沒有保證後續不被Human切換／關閉。 |
| Quit／受控重啟 | Quit後procNotFound／App quit與後續同binary啟動的記錄一致；屬已要求結束的AX target，不作產品crash。CLI僅在新的Human確認且CUA已成功啟動之後，為同app既有launch參數切態，不是繞過尚有效的拒絕。 |
| 覆蓋與歷史 | 本輪七個畫面變體；verifying-account、完整矩陣與Human聲音未重驗有明列。T02／T03／H01–H08及T04未驗歷史保留；沒有用舊pass回填新preview，沒有捏造PNG檔、音檔、精確時序或真認證／session。 |

## 路由

T05必要native差異與授權／接受界線可支持本輪補證交付，未發現可定位的程式required fix。可依既有授權完成本topic文件commit／push及既有Draft更新；其後回HC01由Human檢視正式文案與視覺／UI並明確決定接受。Reviewer批准、啟動許可及native補驗均不替代Human最終接受；不merge。

`current_step: R05 completed`；`next_step: HC01 pending`（先完成已授權的補證文件交付）；`status: COMPLETE`（本輪有界獨立證據審查）；`verdict: approved`（僅T05補證／Draft更新）。
