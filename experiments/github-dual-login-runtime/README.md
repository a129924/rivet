# 正式登入 runtime 獨立驗證入口

本目錄是可移除的獨立 Swift package，僅依賴 root 的 public GitHubIntegration。Root Package.swift 與 production 不依賴本入口；不是產品 UI／session。本次僅 build，不啟動真 OAuth／GitHub／Security。

## Human 停點

TC08 尚未執行。先確認當次來源、有效簽章／entitlements、GUI 使用者、OAuth App 配置、專用 namespace、其他 writer 已停止及 exact-owned 資料處置。純 SwiftPM build 不代表 signed DPK host 已準備完成；執行前必須另外建立並核對當次 signed host 與完整身分。本入口不簽章、不改 trust、不下載 profile、不 delete。

預設啟動只顯示未執行提示。實際模式須同時明示 `--human-ready` 與私有環境 `RIVET_LOGIN_LIVE_READY=human-confirmed`；這是操作確認，不是簽章／身分驗證器。

## 編譯

從本目錄執行 `swift build`。這只編譯 public consumer，不執行登入或 Keychain。

## 受限操作

由 Human 在本機私有環境提供 `RIVET_LOGIN_ACCESS_GROUP`、本次專屬且不同的 `RIVET_LOGIN_OAUTH_SERVICE`／`RIVET_LOGIN_PAT_SERVICE`；OAuth 模式另需 `RIVET_LOGIN_CLIENT_ID`。不要把真值寫入 repo、共享命令紀錄或證據。PAT 與 OAuth client secret 只從互動式隱藏輸入讀取，不接受命令列原值或管線 stdin。

確認當次準備完成後，signed 入口接受：

- `--human-ready login-pat`：隱藏輸入 PAT，以共同 Protocol 驗證後保存。
- `--human-ready login-oauth`：隱藏輸入 client secret，啟動正式瀏覽器／loopback 流程並驗證保存。
- `--human-ready readback-pat`／`readback-oauth`：新程序經相同 store 設定讀回，僅輸出 present／absent。

PAT-only 路徑的 OAuth configuration 為未使用占位值，不呼 OAuth、不建立假 OAuth credential。兩路憑證彼此保留，沒有 current-mode 選擇。Readback 的 present 僅證明當次可還原，不能單獨證明原帳號一致、完整逐欄位比對或遠端有效；真人驗收計畫須另記每段實際驗證與限制。

只輸出有限結果；不印 credential／account／callback／原始 error。沒有 cleanup／migration／delete 指令，也沒有自動 live runner。取消／競態由受控測試證明，不把程序終止當作 Swift Task 取消。
