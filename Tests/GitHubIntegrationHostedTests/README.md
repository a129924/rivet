# GitHubIntegration hosted 整合測試

正式測試 project 有薄 `GitHubIntegrationTestHost` App 與 `GitHubIntegrationHostedTests` Swift Testing bundle。Host 只提供 lifecycle，依賴組裝、正式 `GitHubOAuthStartupRestorer`、觀測、API 與 readback 斷言均在 test bundle。這是專案的測試設施配置，不是 Swift 要求的目錄結構，也不是正式產品 App。

## 離線入口

```sh
python3 -B scripts/check-github-integration-hosted-tests.py --offline
```

無參數預設離線。先執行 Python driver 契約測試，再由 `GitHubIntegration-Offline` scheme 建置一次，列舉實際 Swift Testing identifiers，分別執行 first／fresh。檔案 fake 跨程序保存完整合成 fixture，刷新為 fake；不呼叫 Security／GitHub。輸出 `.xcresult` 與 owner-only 證據於暫存目錄。Root `swift test`、consumer 及既有 hooks 不會自動執行此 Xcode project；CI 應明確使用上述離線命令。

Xcode 測試斷言、實際案例數、程序退出與 provenance 共同決定結果。兩次命令本身不證明新程序；driver 核對實際 PID／starttime，固定 host、test bundle、依賴、`.xctestrun` 及來源。沒有 parallel、retry 或 repetition 旗標，並核對每段只有一個測試。正向 first／fresh 後，另以隔離 fake run 驗證 assertion 與 throw 各一案確實回報原生 failed；這兩個預期失敗不視為整輪失敗。

## 手動 Live 介面（本輪未執行）

只有已獲明確新授權且環境就緒才可使用，不能重用舊 E018 額度。Context 本身不構成授權，內容為 `schemaVersion:1`、唯一 `runID`（16–100個英數或連字號）、`authorizationRef`、`bundleID`、`signingIdentitySHA1`、`profilePath`、`profileSHA256`、`accessGroup`、`service`、`fixture:"existing"`、`budget:{"first":1,"fresh":1}`。Context 及 journal／run-root 必須為同 owner、無其他使用者讀寫權限；不得放 token／client secret。配置不得從舊驗證 App 猜測。

```sh
python3 -B scripts/check-github-integration-hosted-tests.py --live --context PRIVATE_CONTEXT --run-root NEW_PRIVATE_DIR --phase first
python3 -B scripts/check-github-integration-hosted-tests.py --attest --context PRIVATE_CONTEXT --run-root PRIVATE_DIR --phase first --fully-observed --prompt-count 0
python3 -B scripts/check-github-integration-hosted-tests.py --live --context PRIVATE_CONTEXT --run-root PRIVATE_DIR --phase fresh
python3 -B scripts/check-github-integration-hosted-tests.py --attest --context PRIVATE_CONTEXT --run-root PRIVATE_DIR --phase fresh --fully-observed --prompt-count 0
```

人工觀察旗標及次數必須依實答填寫。First 完成且退出、人工 SHA 綁定且完整觀察 0 提示後才放行 fresh；沒有自動重試／登入／seed／clear／強制到期。Context 旁 journal 綁定第一個 run-root，換目錄不重設額度。每段最多120秒；test bundle 經實際程序握手與授權才可碰 DPK／網路。

Exit 0=指定驗證完整通過，1=測試／程序／結果失敗，2=工具鏈／簽章／context 前提不足，3=機器段完成待人工觀察。缺憑證只能讀取後得知，會由測試回報失敗。機器與人工資料分開保存，不回填原 receipt。

## 歷史與產品 E2E

原 E018 active 工具已遷移退役；[舊來源](https://github.com/a129924/rivet/tree/0debe0b8c088e60500b4a1e4969000666e495c97/experiments/E018)與 [原有限 live 證據](../../plan/github-oauth-startup-restore-runtime/evidence/e018-live.md)保留原版本、SHA 與人工觀察。舊 passed 不代表本設施 live 已通過。

本 revision 沒有正式 Rivet App target。未來產品 E2E 由獨立 XCTest／XCUIAutomation target 啟動正式 App，走其產品組裝並驗證使用者結果；不經此 host。

## Implementer 離線自驗（2026-11-18）

最終來源完整入口通過：17 個 driver mock tests；正向 first／fresh 各1個原生案例通過、不同實際程序且均退出；兩個隔離負向程序分別由 assertion／throw 形成 `.xcresult` 1案 failed，runner 正確辨識預期失敗。Strict format／SwiftLint exit0。獨立 Tester 已親跑同一 Offline 流程、root375／46及consumer22／6回歸、strict checks與歷史完整性核對通過；獨立 Reviewer approved、無 required finding。Human最終接受仍pending，不宣稱 Live 或產品 E2E 通過。
