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
