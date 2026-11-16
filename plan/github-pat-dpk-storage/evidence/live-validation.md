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
