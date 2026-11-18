# R06：R3 驗收歸屬有界獨立審查

- 日期：2026-11-18；owner=獨立 Reviewer。
- 受審來源：feature HEAD `44ddbeea6235e9b785b41a9f787c92f52aa85eaf` ＋ I03／R3 未提交 diff；P03 approved、I03 明示完成、T06 自動／source 結果已交接。
- **verdict: needs-rework**。兩項 P2 required fixes 如下；沒有發現需重開架構或改變正式 API 的重大問題。修正後可只做對應差異驗證／復審，不需重做未改 core 的完整歷史測試。
- 本輪只讀 source／docs／build evidence，僅新增此 Reviewer evidence；未代改作者程式／契約、未 commit／push、未 build／test／launch／Canvas／GUI。

## Required fixes

### RF01（P2）：現行狀態所有權說明仍將 E011 Reset 當作當前驗收入口

位置：`docs/presentation/login-ui.md:29`，「組合與狀態所有權」段落中的「離開／消失／E011 Reset 同樣清除」。此段未標為歷史，但 R3 已將 E011 凍結、不再作現行 consumer；讀者會混淆目前受控 Preview／acceptance parent 的 Reset ownership。

修正方向：現況說明改用目前 wrapper／acceptance parent 的明確 Reset 更換 form generation，與正式 component 的離開／消失清除分開；實際新 rendered／native 結果仍待驗。歷史 I01／I02／E011 Reset 觀察及原接受不刪改，不因此改正式 View 行為。

### RF02（P2）：外部 run 路徑驗證發生在 mkdir 之後

位置：`tools/acceptance/login-ui/scripts/build-app.sh:7` 在第13行 `run.is_relative_to(root)` 拒絕 checkout 內 run 前，已建立 scratch／cache／modules／logs。

觸發：傳入位於 checkout 內、原本不存在的 `ACCEPTANCE_RUN`。腳本雖會拒絕，但已先在 source tree 寫出非 allowlist 目錄，違反工具輸出必須在 checkout 外的邊界。

修正方向：先完成 canonical path／外部位置與既有 app 衝突檢查，成功後才建立任何 run 目錄或 receipt。補一個有界 invalid-in-checkout run 檢查：命令拒絕且未建立指定目錄；不需要新增鏡像 consumer tests。腳本 bytes 將改變，須更新目前 source manifest／app build provenance，保留此次 pre-fix receipt 的適用來源，不將舊 manifest 假稱符合新版腳本。

## 其餘 source／scope 結果

- E011 working source 對 `d2332bf` diff 為空、untracked=0；指定 freeze tree `b6a1e6e1196e64999af9591ec32f09211f1936c6` 存在。六項定點 restore／delete 與 allowlist 一致，未見整目錄覆寫或 model／README 改動。這是工作區內容核對，未冒稱尚未提交 HEAD tree 已改變。
- Root manifest／lock／gitignore 與原 HEAD bytes 相同；Sources／Tests 唯一正式區 diff 是 DEBUG 私有 controlled #Preview，核心 API／content／children／helper／styles／artwork 保持。事件有限回寫、submit associated String 不綁定或保留，只記固定 kind／count；字級／copy／tokenEntry↔token failure 不改 generation，Reset 才更新。
- 獨立工具 package 只有 Support／executable／tests 三 targets，以 local product dependency 消費正式 Presentation；自有有限 parent／configuration／fixtures／host，不依賴 E011／LoginDemoModel／GitHubIntegration，不 copy View／VO，不加入 service／DI／Task／timer／認證／儲存／session／navigation。
- Host source 只組合一個乾淨 `.standard` 主窗，控制位於 Acceptance menu，沒有獨立 Controls／overlay 或自訂快捷鍵。Menu／callbacks 使用同 parent，Reset 保留設定；這是 source 判讀，不冒稱 runtime 點擊／focus 已驗。
- OAuth adoption registry 從其 topic heading 起逐 bytes 等原 HEAD，僅 Login UI 追加 R3 ownership。歷史凍結圖、HC01／T/R/H 證據不改；現行 lifecycle／intent 語義不變，不需為 consumer 搬移重產圖。
- Frozen E011 可編譯但現 `.standard` 與舊 simulation 語義不等效已清楚揭露；歷史重播需完整 revision／舊 binary，沒有新增 demo mode、footer／bundle 偵測。

## T06／artifact 證據的獨立有界核對

讀取 T06 raw logs，確認 root filter 為16 tests／4 suites（9 formal＋7 frozen Demo 分列）、tool為8 tests／2 suites、正式 Demo build0.86s與tool product build1.12s、8檔lint零違規。Reviewer沒有重跑這些命令。Format／plist／bash syntax／diff-check依 T06 的實跑紀錄保留，不擴為 native pass。

實際 product Objects.LinkFileList 為23 objects：Presentation18、Support4、executable1，沒有 E011／Demo／GitHubIntegration。SwiftPM planned commands 與 test plugin 編譯不當作實際產品 link／安裝執行；Apollo transitive 固定 cache 解析限制已揭露。

獨立重算目前28份 source 與 app entries 的 bytes／mode／type／canonical digest，符合 pre-fix final receipt：

- source manifest：`00181908494c9cd347a5fb396b637e2aeea69533068bf2914616180be7e4de39`。
- binary：`5015e1621050fca4c5f048dea1ef08f0b1a96c743714dde256a5a44ae391312e`。
- app tree：`256256cb7805d79ad23803ba98210083b28641ef2d95c6e07f975d5e05a83e38`。
- receipt `nativeLaunch: not-run`；資源 bytes／包裝吻合不等於 runtime 圖示載入。

以上來源在 RF02 修正後須以新版 provenance 續記；不能把相同 Swift source 或舊 HC01 當作不同 binary 已獲啟動確認。

## 路由與限制

交 Implementer 修 RF01／RF02，再交有界 Tester 核非法 run 無副作用與新 source／app receipt，R06 只復審差異即可。沒有要求額外架構、root 設定、正式 API 或鏡像 consumer tests。

Canvas 連續操作、新 native host／menu／Return／Escape／callbacks／focus／字級捲動／runtime resources 與必要 Human 聲音仍未驗。原 HC01/source3c9baf3／preview42e99fa／binary4d4cf13...接受保留；新 T07／HC02 pending。Required fixes 關閉後才可提出 exact 新 app/source/binary 的操作當下確認，不沿用舊確認、不 launch、不 merge。

`current_step: R06 needs-rework`；`next_step: Implementer bounded RF01／RF02`；`status: COMPLETE`（本輪有界審查）；`verdict: needs-rework`。


## R06 RF01／RF02 有界復審：2026-11-18

原 needs-rework 與 pre-fix provenance 保留為歷史。本次只核兩項修正、T06 差異複驗與作者 I03 最新附錄，不重開其餘已審 scope，不重跑 build／unit／GUI／Canvas，也未改作者 source／contract。

**最新 verdict: approved（source／tests／docs 受限交付）；required fixes：無。RF01、RF02 均 closed。**

- RF01：現況段已分開正式 form 離開／消失清除與 controlled Preview／acceptance parent Reset 更換 generation，並明列新 consumer 的 rendered／native 結果待驗；不再將 E011 Reset 作現行驗收入口。歷史 E011／Human 紀錄保留。
- RF02：script 先 canonical 驗指定外部 run 與 app 輸出衝突；無指定 run 時先驗 TMPDIR parent 在 checkout 外且存在，才建立 temporary run。任何 mkdir／receipt 寫入都位於有效 run 確認之後。
- 讀取獨立 Tester 兩個 negative receipts：指定 checkout 內不存在 run，exit1／directoryCreated=false；TMPDIR 指 checkout 內，exit1／newEntries=[]。T06 明列為親跑結果，Reviewer沒有重跑或新增測試。
- 讀取新的外部正向 build log 與 receipt，核對目前28項 source bytes、canonical manifest、app 各 entries／bytes／mode／type 與 tree digest；全部吻合。和初版 source manifest 比較只有 build-app.sh 變更；Swift source 全同、root readonly hashes／resources 前後及兩版一致，因此不要求重跑未變 formal／tool unit tests。
- I03 最新附錄與 T06 差異段已分列初版與目前來源；沒有把原00181908…／5015e162…回填為修後結果。Script SHA 為 `7926ef779ade6a423dde2d00a8a39af2c5707cda302d75e2ec7f7adba004ec60`。

### 目前 exact artifact

目前外部 run 別名 `$R3_REVIEWED_RUN`，app 相對路徑 `native/RivetLoginAcceptance.app`，bundle ID `local.rivet.login-ui-acceptance`：

- Source manifest SHA-256：`6c1d5266c7f10f2340ed383604fd8a74b3ff7f00a0411c276bd9df86a195921d`。
- Binary SHA-256：`9219bd7656c55287ecb6ab1adc6d37f7f9b51e9b9217c15846cb27d8e0460b10`。
- App tree SHA-256：`6be23f92067767340b21cd00644943f7ffe72adbba3872de320ab94762c59eb3`。
- `nativeLaunch: not-run`。不同 binary 的 debug 路徑／build bytes 不沿用舊確認；舊 HC01/source3c9baf3／preview42e99fa／binary4d4cf13...接受仍限其原來源。

### 復審後路由

可依原 Human 授權完成本 topic source／tests／docs commit／push／既有 Draft #75 更新，並提出上述 exact 新 app／source／binary 及有限案例的操作當下確認。**本 verdict 不是 native 啟動許可，不 launch、不 merge。** T07／HC02、實際 Canvas 連續操作及新 host／resource 實載／callbacks／焦點／Human 差異仍 pending，不以舊 UI 接受或 unit tests 代填。

`current_step: R06 completed（復審 approved）`；`next_step: D03 受限交付與 exact 新 binary 當下確認；確認後才 T07`；`status: COMPLETE`（有界復審）；`verdict: approved`（僅 source／tests／docs 與提出確認）。
