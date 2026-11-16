# PAT DPK：當次真人驗證紀錄

## 正式 setup 首次 attempt：unknown，Human 全程 0 提示

- Source commit：`0b0692ee9713c055b33d405075da413bae0949db`。
- Run UUID：`71d51ebe-1a97-4ec7-be4c-a8f802baaba7`。
- 這次由當段 Human 明確表示「已就緒，開始本段正式建置」，範圍只含 clean／build／sign，不 Run、不 DPK。
- Runner prepare 建立唯一 owned 0700 run，來源 hash／commit 凍結；settings、locator 與原 attempt 保存在私有 root。
- 實際 `xcodebuild clean build` 回 rc=65，machine=`unknown`，guard point=`formal-debug-clean-build-sign`。沒有重試或換 run；原 attempt／private outputs 保留。
- 原 setup-machine SHA-256：`3d5624666e8acef42b54028160dfaf8b806b32e8137f8747180eb4c9f46c4cda`。
- Human 隨後明確回報「全程觀察，0 次提示」。Tester 將 wholeStageObserved=true、promptCount=0 與上述 machine SHA 綁定，獨占／fsync 保存 private setup-human observation；這是 build／sign 視窗，不使用 runtime PHASES 的 observe CLI。

Human 觀察不提升 machine unknown 為成功；沒有因此形成 setup build proof、identity 通過或 live 存取證據。未執行 save A 或任何 DPK 操作。

### 後續新授權的唯讀錯誤分類

主 agent 另授權一次讀取同 run 原 private failure stdout／stderr；沒有重跑命令、改設定或查其他 roots。當次分類有 3 條 native error line，明確類別為：**既有 Xcode-managed profile 被 manual signing settings 拒絕**。

此節只增加對已保存輸出的分類，不回寫原 machine status／SHA，也不追補為原成功。最小修正方向是讓正式建置簽章 style 與已選的既有 managed profile 相容，同時保留最終 identity／group／certificate／profile 一致性驗證；具體 argv／project 策略仍交受限 Implementer 與獨立 Reviewer，不能自行新增 Apple assets 或自動重試。

本段沒有查 private key、sign 新 attempt、Run、真 DPK、清理 item 或更換 run。私人 Team／group／profile／certificate 名稱、argv、raw errors 與本機絕對路徑未寫入本文件。P06／提示門檻／跨程序／重建／owned cleanup 與整題完成仍未通過。


## 新 automatic round：正式 setup machine-completed，Human 觀察待回報

- Source commit：`55aa57ae2a9b466baca3b7968e7a4419e996a646`。
- Run UUID：`1a4c8e49-d574-4bff-8c7f-b195233880ac`。
- Human 當段明確表示「已就緒，開始新 run 建置」後，Tester 建立新的唯一 owned 0700 run，source commit／hash 凍結於上述版本，另以 0600 獨占保存 settings 與 automatic locator。
- Runner 以明確 automatic style 執行一次實際 Debug clean／build／sign；不帶 provisioning update／device registration，不新增或切換 selected assets。
- Machine 結果為 completed：完整 selected identity 相符，包含原 certificate SHA-256／profile SHA／Team／group／DR，以及新增 private profileName／certificateSHA1 pins；actual binary hash 與成功 build proof 相符，source freeze 與有效 profile 檢查通過。
- Setup-machine SHA-256：`36c76860b0ce1bf6ea79d97765c76bec41049d9469423761467f259e18942c39`。
- 舊 source `0b0692e`、run `71d51ebe-1a97-4ec7-be4c-a8f802baaba7` 的 source proof／unknown machine／Human 全程 0 提示／attempt／原 active locator 經前後 hash 比較保持不變。新 round 不覆寫或追補舊結果。

本段尚未收到 Human 的全程觀察／實際提示次數回報，Human observation 保持 pending，不自行填 0。沒有 Run、save A、任何 DPK 存取或 item 清理；成功 setup 不代表 runtime／跨程序／同身分重建／提示門檻／完整 P06 通過。停止於此，等待當段 Human observation 與下一段明確 ready。


### 新 automatic setup 的 Human 回報

Human 隨後明確回報「建置全程 0 次提示，已就緒保存 A」。Tester 以新 setup-machine SHA 綁定 wholeStageObserved=true、promptCount=0，耐久／獨占保存該 round 的 private setup-human observation。這是本 round build／sign 視窗，不挪用舊 unknown round 的 0 次紀錄。

### save A：正式 runtime machine-completed，觀察待回報

- Source：`55aa57ae2a9b466baca3b7968e7a4419e996a646`；run：`1a4c8e49-d574-4bff-8c7f-b195233880ac`。
- Human 本段 fresh ready 後，Tester 只執行一次 `save-a`。Runner 先核 source freeze、current app／build proof、有效 signature／identity 等 guards，再以固定 `open -W -a` 啟動；沒有 `-n` 或 raw live binary。
- 正式 public PAT adapter 先確認缺值，依序耐久記 absence 與 write-attempt ownership，保存非機密 A 並完整讀回 A。兩個 ownership marker 均核對為同一 run／精確 namespace。
- Host outcome=completed；runnerAccepted=true。OS PID／start time 與 process instance proof 存在且通過，binary／variant／run／phase guards 通過，acceptance proof 已耐久保存。
- 原 host receipt SHA-256：`36d434f711fc36d576b3b06d7c1ab1e8ed0ee550f6088617ccf53d83522565ff`；私人 process identifiers、group、PAT、原始資料與路徑不公開。

本段 save A 的 Human 全程觀察／提示次數尚待回報，不自行填 0 或判 UX 通過。未進入 read A、替換 B、重建或 cleanup；只操作本 run 新 PAT 項目，不觸碰舊 OAuth items。下一步需本段實際 Human observation 綁定與 read A 的新 ready。


### save A 的 Human 回報與 read A 當次 unknown

Human 明確回報 save A「全程 0 次提示，已就緒讀 A」。Tester 用 runner observe 綁定原 save-a host receipt SHA，記 wholeStageObserved=true／promptCount=0；observed gate 與同 run absence／write-attempt ownership 均通過。這支持 save A 該段提示門檻，不挪用到讀 A。

隨後只執行一次 fresh-ready `read-a`，同 source `55aa57ae2a9b466baca3b7968e7a4419e996a646`、run `1a4c8e49-d574-4bff-8c7f-b195233880ac`。固定 `open -W -a` 原生命令回 **rc=1**，因此 runner 在 `fresh-runtime-read-a` 停止，machine=unknown。

原 host receipt 的 outcome=completed；但 open 未正常完成，**runnerAccepted=false**，沒有 acceptance proof，不能將 raw host completed 提升為已通過 fresh-process 還原或讓相依段前進。原 host receipt SHA-256：`07061d7c997f50fb794e54e427c2962f0f936a6977e748ca09b694f88ecda787`。Attempt／raw receipt／private failure outputs 與 ownership markers 保留，未 retry、換 run 或 advance。

本段 read A 的 Human 全程觀察／提示次數仍待回報，不自行填零。沒有執行 replace B、重建或 cleanup，不觸碰舊 round／OAuth。若要定位 open rc=1，需另授權讀取本次原 private outputs 的 bounded 分類；本記錄不推論 PAT 儲存失敗，也不回寫原 unknown 為成功。


### read A 的 Human 回報與後續唯讀診斷

Human 明確回報 read A「全程觀察 0 次提示」。Tester 使用 runner observe 只綁原 raw host receipt SHA `07061d7c997f50fb794e54e427c2962f0f936a6977e748ca09b694f88ecda787`，保存 wholeStageObserved=true／promptCount=0；沒有製造 acceptance proof，machine unknown／runnerAccepted=false 原樣保持。

主 agent 另授權同 run private open outputs 的一次 bounded 唯讀分類。本次有限分類結果為 unclassified-open-failure，數值 nativeErrorCodes 清單為空；未取得可支持 LS-600 等具體數值歸因的分類結果，不猜測或將假設寫成根因。

另唯讀核對原 read-a receipt：run、phase、binary／debug variant 均匹配，OS PID／start tuple 與 instance 不同於 save-a writer，host outcome 為 completed。這些是後續新觀察，不追補原 open rc=1 為成功或放行 replace B。針對 receipt 指定的唯一 PID／start identity 做一次 proc_pidinfo 查詢，確認原 instance 已不存在；沒有 inventory 其他程序或 kill。

同 run absence／write-attempt ownership 證據仍成立；已保存 A 的 exact owned item 仍需清理，本次沒有重新讀 DPK 來確認目前內容，也沒有 cleanup fresh ready，因此不執行刪除。原 attempt／receipt／private outputs 與診斷保留；不 retry、不換 run、不改 source、不進 replace B。下一步先取得對本 run exact-owned cleanup 的當段 Human ready，再依受限流程處理。


### 新授權的去識別 open 錯誤診斷

主 agent 另授權只讀同一 exact private open failure log，限制 16 KiB，移除私人 identifiers／路徑後取得可判讀的原生理由。本次只有 stdout 0 bytes、stderr 83 bytes；有限 category 為 **open-wait-kevent-initialization-no-such-process**，沒有原生 error domain 或數值 code。Repository 不保存原文。

這定位到 `open -W` 的等待機制，不是 LS-600；先前有限分類未命中的紀錄保持。Child 在 wait 註冊前已退出是待判讀推論，不當成已證因果。Raw host completed、新 instance 與原 PID 已退出仍為分開證據，不能自行提升原 machine unknown／runnerAccepted=false。

此步沒有任何 native 重跑、launch、read DPK、cleanup、kill 或 source 修改。Owned A 項目的清理需求不變；未取得 cleanup 當段 ready 前不刪除。


### Exact-owned cleanup 當次 attempt：unknown，觀察待回報

Human 明確表示「已就緒，清理本 run 測試項目」後，Tester 對同 source `55aa57ae2a9b466baca3b7968e7a4419e996a646`、run `1a4c8e49-d574-4bff-8c7f-b195233880ac` 執行一次原 cleanup。先核 source freeze、same-run absence／write-attempt ownership、current identity／binary／profile，並以指定 PID／start identity 確認前 read-a instance 已退出；runner 原 no-active-host guard 保留。

固定 `open -W -a` 回 **rc=1**；machine=unknown、runnerAccepted=false，沒有 acceptance proof。原 host outcome=completed；依 frozen cleanup 分支，host 只有 exact-owned delete 與正式 store load=nil 返回後才記 completed，但這個 raw 結果不自行提升為整段 accepted cleanup。

Raw receipt 的 run／phase／binary／debug variant 匹配；OS PID／start tuple、instance 與先前 writer／reader 不同。一次指定 PID／start 查詢確認原 cleanup instance 已不存在。原 host receipt SHA-256：`9c2122209911d20557d663c6b6a21d5726671f6099d4a841e4b77c5573c54de3`。Attempt、private failure outputs、raw receipt、ownership 與所有舊觀察保持。

本段 Human 全程觀察／提示次數仍待回報，不自行填 0。未重試、不換 run、不改 launcher、不放寬 rc／acceptance gate，沒有再讀 DPK 或另刪項目，也沒有碰舊 round／OAuth items。清理驗收仍需獨立判讀；若需 recovery，必須另有明確受限操作與當段 ready，不可用新 attempt 覆寫本次 unknown。


### Cleanup 的 Human 回報與有限 wait 錯誤分類

Human 明確回報 cleanup「全程觀察 0 次提示」。Tester 透過 runner observe 只綁定原 cleanup raw host receipt SHA `9c2122209911d20557d663c6b6a21d5726671f6099d4a841e4b77c5573c54de3`，保存 wholeStageObserved=true／promptCount=0。前後核對原 machine summary／receipt bytes 不變；machine unknown／runnerAccepted=false 保持，沒有製造 acceptance proof。

另授權的同 run 既存 capture 唯讀分類確認 cleanup 與 read A 相同有限 category：**open-wait-kevent-initialization-no-such-process**。不保存原文、不將此新分類追補為原成功。原 exact-owned delete→正式 load=nil 的 raw completed、identity／binary／run／phase、新 OS instance 已退出與 ownership markers 證據全部保留，交獨立 Reviewer 判讀原 owned item 收尾。

本步沒有 native 命令、重 launch、再讀／再刪 DPK、kill、source 修改或換 run。沒有權限以推論再清理；任何後續 harness 修正／新 round 必須保留此 source `55aa57a`、原 proof 與 unknown／Human 觀察歷史。


## Exit-proof 新 source／第3正式 round：setup machine-completed

- Source commit：`5465d3c7308e74bc2b3b51878acd190d4f2babda`。
- Run UUID：`39c22b57-de4f-463c-aa4b-8de277c1f60a`。
- Human 對該 source 明確表示「已就緒，開始新 run 正式建置」，範圍為當段 clean／build／sign，全程觀察；不 Run／DPK。
- Tester 核對 HEAD 與 reviewed runner／host hashes，建立新的唯一 0700 root、600 settings 與獨立 exit-proof locator，沒有覆寫前兩個 locators／runs。
- 一次 automatic Debug clean／build／sign 成功，沒有 provisioning update／device registration 旗標。Full selected identity（含 profileName／certificateSHA1 private pins）與原 selected metadata 相符，actual binary／build proof、source commit／hash freeze 與有效 profile 均通過。
- 前兩 round／locators 與 selected metadata 共 42 個既有檔案的前後 hash 相同；原 unknown／accepted=false／Human 觀察歷史保持。
- 新 setup-machine SHA-256：`4296e77a844b33a720cd27049ec869c2c4a986dc1a89c18fbc66e9cfea28c603`。

Human 當段全程觀察／提示次數尚待回報，不自行填 0。未 launch app、save、load 舊 namespace、recover-absence 或操作 DPK；本段只提供新 source 正式 host 的 build／identity 準備證據。停止等待本段 Human observation 與唯讀 recovery 或其他 runtime 的新 ready，不能以 setup 成功宣稱 P06／cleanup／完整 topic 完成。


### 第3 round setup 的 Human 回報與原 namespace 唯讀補驗

Human 明確回報「建置全程 0 次提示，已就緒只讀補驗」。Tester 以 source `5465d3c`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 的 setup-machine SHA 綁定 wholeStageObserved=true／promptCount=0，沒有挪用前輪觀察。

隨後只執行一次 approved recover-absence：原 namespace 來自 source `55aa57a`／run `1a4c8e49-d574-4bff-8c7f-b195233880ac`，新正式 host 來自 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a`。新 recovery ID：`19a43bec-f784-4613-8441-499339fb69c9`。

原 ownership／committed Git blobs／source hashes／identity／binary 與新 host full identity／context 全部核對；只新增 self-owned recovery child、immutable amendment／controller／attempt。正常 open rc=0，secure receipt SHA 穩定、run／phase／recovery ID、binary／source／new process 與 PID 已退出等 gates 通過，runnerAccepted=true。新 host 的實際 readonly admission 只允許 verify-absence，正式 store load=nil；沒有 save／delete。原 42 檔 proofs 及新 host 原 proofs 前後 hash 不變。

Recovery host receipt SHA-256：`e420e2fa59fd2667940877ac10fd79f6101579350d356cb94e1f5cccabcadba7`。Human 隨後明確回報「全程 0 次提示，已就緒保存 A」；Tester 只對 recovery child 綁定 wholeStageObserved=true／promptCount=0，observed gate 與 readonly export 均通過。這支持原 owned namespace 當次 qualified absence，不改寫原 read A／cleanup 的 unknown／accepted=false。

### 第3 round 正常 save A：machine-completed，觀察待回報

在同 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／新正常 run `39c22b57-de4f-463c-aa4b-8de277c1f60a`，依本段 fresh ready 只執行一次 save-a，沒有把普通 phase 放進 recovery child。

正式 adapter 先確認本 run namespace 缺值，耐久記 absence→write-attempt ownership，保存並完整讀回非機密 A。Normal open rc=0，secure stable receipt／PID 退出／source／identity／binary 等 gates 全過，runnerAccepted=true。原／recovery／新 host 既有 proofs 前後 hash 不變；新 normal-run host receipt SHA-256：`3b7894740bf2be1fae73bffcf12679612804b6aad49d680b0139b8dfbe2d28f4`。

本次 save A 的 Human 全程觀察／提示次數仍 pending，不自行填 0，未執行 read A／replace B／rebuild／cleanup。Readonly recovery 與本次新 round 儲存是兩個獨立段落，不能把前段 Human 0 提示移給後段，也不宣稱整個 P06／topic 已完成。


### 第3 round save A 的 Human 回報與 fresh read A

Human 明確回報新 run save A「全程 0 次提示，已就緒讀 A」。Tester 將 wholeStageObserved=true／promptCount=0 綁定該 save-a receipt，observed gate 通過。

依本段 fresh ready，在 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 只執行一次 read-a：normal open rc=0，正式 adapter 完整讀回 A。新 OS PID／start tuple 與 instance 不同於 writer，binary／variant／source／identity 匹配；secure receipt SHA 前後穩定、positive PID 的退出證據及 final guards 通過，runnerAccepted=true。

Read-a host receipt SHA-256：`d92472c39b15d64f65c77cf8c1eafdd4da9354dc30f73be38b03a3dfb0b45866`。本段 Human 全程觀察／提示次數仍 pending，不自行填 0；未執行 replace B。舊 source55／readonly recovery 的 proofs 與 unknown 歷史保持，本次新協定 accepted 不回寫舊 read A 結果。


### 第3 round read A 的 Human 回報與完整替換 B

Human 明確回報 read A「全程 0 次提示，已就緒替換 B」。Tester 以原 read-a receipt SHA 綁定 wholeStageObserved=true／promptCount=0，observed gate 通過。

在 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 只執行一次 replace-b：同一 owned namespace，正式 adapter 先完整讀回 A，再整筆保存 B，並完整讀回 B 相等。Normal open rc=0，新 OS tuple／instance、source／full identity／binary／debug variant、secure stable receipt 與 PID 退出證據全部通過，runnerAccepted=true。

Replace-b host receipt SHA-256：`d285b263d8ef32594b5ad4c7c9173fad5efe31400ec9fb7e33004f768a185e4e`。本段替換 B 的 Human 全程觀察／提示次數仍 pending，不自行填 0；未執行 fresh read B。舊 round／readonly recovery proofs 與歷史不變，沒有觸碰其他 namespace 或 OAuth item。


### 第3 round 替換 B 的 Human 回報與 fresh read B

Human 明確回報 replace B「全程 0 次提示，已就緒讀 B」。Tester 將 wholeStageObserved=true／promptCount=0 綁定原 replace-b receipt SHA，observed gate 通過。

在 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 只執行一次 fresh read-b，正式 adapter 完整讀回 B。Normal open rc=0，同 owned item／same binary，new OS tuple／instance、source／full identity／debug variant、secure stable receipt 及 PID 退出 gate 全過，runnerAccepted=true。

Read-b host receipt SHA-256：`2c110da3127e9aad84bcb815958860abd04a480d95a1f10230481ae44362fa39`。本段 Human 全程觀察／提示次數仍 pending，不自行填 0；尚未 rebuild 或清理。舊 round／readonly recovery proofs 不變，原 owned B 項目只讀取，沒有其它寫入或刪除。


### 第3 round read B 的 Human 回報與真正同身分重建

Human 明確回報 read B「全程 0 次提示，已就緒真正重建」。Tester 用 read-b receipt SHA 綁定 wholeStageObserved=true／promptCount=0，observed gate 通過。

在同 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a`，使用原本不存在的獨立 Rebuilt DerivedData，執行一次真正 `clean build`／automatic signing，沒有 provisioning updates／device registration。

機器結果 completed：新 built app 的 full identity 與 Debug 相等，含 certificate／profile／Team／group／DR 與 private pins；source freeze／有效 profile 通過，actual compiler log 核實 `-DPAT_STORAGE_REBUILT`。Postverify 成功後才替換固定 current app，再核與 Rebuilt build proof 相符；原 source／receipt／observation JSON proofs hash 不變。

- Debug binary SHA-256：`24943f980a0cf110d0b9c9c4a3651091ac401fe973eb00d5d2310d7c705c4f78`。
- Rebuilt binary SHA-256：`d10f23cb8d78bb98ed47d6087f097d1422cb16884956082942f8e98866584fd8`。
- Rebuild-machine SHA-256：`adb2f8dd90ad7e6f1a04f4fdcbf4504a241201ff773a0ceb14883b88218f807d`。

兩個 binary 確實不同，且有真 clean／build 命令及生效編譯條件證據，不只是重啟舊 binary。此段尚未 Run 或讀取 DPK，不能以建置成功宣稱重建後還原 B 通過。Human 本段建置／簽章全程觀察與提示次數仍 pending，不混入 runtime 次數、不自行填 0；等待新 ready 才能 rebuilt-read-b。


### 第3 round 重建 Human 回報與 rebuilt fresh B

Human 明確回報「重建全程 0 次提示，已就緒重建後讀 B」。Tester 以 rebuild-machine SHA `adb2f8dd90ad7e6f1a04f4fdcbf4504a241201ff773a0ceb14883b88218f807d` 耐久綁 wholeStageObserved=true／promptCount=0，不改原 proof。

同 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`／run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 只執行一次 rebuilt-read-b。正式 adapter 完整讀回 B；Rebuilt variant、與 Debug 不同 binary、new OS tuple／instance、source／full identity／fixed current、normal open rc=0、secure stable receipt 與 PID 退出等 gates 全過，runnerAccepted=true。Host receipt SHA-256：`e0b354ee945165ad40c6f1efe1d36eaed2113e7ef3f8d78d0bafe9aca13fd8cb`。

本 runtime 段 Human 觀察仍 pending，不自行填 0；未 cleanup 或操作其他項目。舊 history／proof 保持，等當段觀察與 cleanup fresh ready。


### 第3 round cleanup 與 P06 Tester 最終交接

Cleanup 只執行一次，normal open rc=0；exact-owned item 刪除後正式 store load=nil。Rebuilt binary／full identity／source／ownership、secure stable receipt、new OS instance 與 PID 退出 gates 全過，runnerAccepted=true。Human 最後明確回報「全程觀察，0 次提示」；Tester 精確綁原 cleanup receipt SHA `7836473e303f878636e2452158c400ccc04f11e328f38af1a658be516a03da6a`，observed gate 通過。

正式來源 `5465d3c7308e74bc2b3b51878acd190d4f2babda`，run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 的最終結果：

| Phase | Runner accepted | Human whole observed | Prompt count |
| --- | --- | --- | --- |
| save-a | true | true | 0 |
| read-a | true | true | 0 |
| replace-b | true | true | 0 |
| read-b | true | true | 0 |
| rebuilt-read-b | true | true | 0 |
| cleanup | true | true | 0 |

Setup／真正 Rebuilt clean/build/sign 另各全程觀察 0 次，不混入 runtime。Full identity 相同、Rebuilt binary 不同與 compiler flag 證據保持；新 owned item cleanup／load=nil accepted。原 source55 namespace 也有獨立新 readonly recovery 的正式 load=nil、accepted／Human0；原 read A／cleanup unknown 沒有升格，舊 source0b setup unknown 不變。最終核對 amendment referenced proofs 與已記 raw SHA 均未變，三個已知 host 路徑無 active host。

有限公開 export：[live-run-39c22b57.json](live-run-39c22b57.json)。已檢查不含 group／Team／profile／certificate settings、私人路徑、PAT／payload 或 raw errors；只含安全結果、來源／binary摘要與 Human 綁定。

**P06 Tester 證據交接完成，交獨立 P07 Reviewer 判讀。** 本結論只涵蓋指定當次 macOS／簽章／private group 環境與非機密樣本；不推及 profile renewal、certificate rotation、其他環境、斷電 durability、真 GitHub 驗證或產品登入。Tester 不發 Reviewer verdict，也不取代最終 Human 接受。
