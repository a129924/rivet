# E022 Inbox 收到晚到的成功回應

## 驗證什麼

- 編號 E022，設計日期 2026-11-24。建立前確認本地目錄、索引與可達歷史未占用。
- 問題為取消等待最後一筆 REST 資料的 Inbox caller 後，若 REST 替身仍交付有效 HTTP 200，Facade 會得到什麼 Outcome，是否額外送出請求。
- 假設為 `PRInboxFacade.refresh()` 回 `.failure(.unavailable)`，請求僅包含 `/user` 與 `/search/issues`。

## 為什麼

原始碼基線 `386af9e`。Adapter 的 REST await 前後都有取消檢查，既有測試注入 `CancellationError` 檢查 failure mapping。用實際取消配對分辨成功資料返回時的 Adapter 邊界。若成立，技術取消可於 await 後攔下，但目前公開 Outcome 會失去取消區別。若回成功或加送請求，先調查該交界的行為缺口。 [Inbox Adapter](../../Sources/PRInboxGitHub/GitHubSelfReviewSource.swift) · [Facade](../../Sources/BoundedContexts/PRInbox/PRInboxFacade.swift) · [Inbox 測試](../../Tests/RivetPRInboxGitHubTests/GitHubSelfReviewSourceTests.swift)

## 成功與失敗判準

- 有效對照需回固定候選 `fixture-owner/fixture#17`，標題 `Fixture PR`，兩個取消旗標皆 false，順序恰為 `/user`、`/search/issues`。
- 取消組在等待事件後呼叫 `Task.cancel()`，才釋放同一 HTTP 200。兩個取消旗標皆 true，Facade 返回 `.failure(.unavailable)` 且路徑和對照相同則假設成立。
- 對照與事件順序有效時，取消組回任何成功候選、其他 failure 或有額外請求，對應假設失敗。對照不成立、等待證據遺失或 watchdog 終止時無法判定。
- 判準於執行前固定。上限一組對照與取消配對。設定故障修正後最多再執行一組。每案 10 秒 watchdog 專用於停止與清理。

## 環境與前置條件

目標 macOS 15 或更新版本、Swift 6、本機已快取的 Apollo 2.1.2。呼叫正式 Adapter、UseCase 與 Facade。REST 為 actor 替身，帳號、PR 和 HTTP body 是合成資料。程式只檢查本地 request 值及合成 HTTPResponse，不發出任何 HTTP 連線。Tester 記錄實際版本。

## 重現步驟

從 repository 根目錄執行。Swift 建置獨立完成。直接執行已建置程式一次，先對照後取消，每案輸出一筆 JSON。

```sh
swift build --skip-update --disable-automatic-resolution --package-path experiments/E022
probe_bin="$(swift build --skip-update --disable-automatic-resolution --package-path experiments/E022 --show-bin-path)"
"$probe_bin/InboxCancellationProbe"
```

Actor 將第二個請求停在 continuation，等待訊號由 AsyncStream 發送。驅動端收到訊號後依案例直接放行或先取消 caller。Stub 記錄釋放後、返回 HTTPResponse 前的 Task 取消旗標，觀察另外包含 caller handle 的取消旗標、完整請求路徑順序及 Facade Outcome。

## 是否成功

2026-11-24 獨立 Tester 執行一組配對，未重跑，實驗狀態為**成功**，本輪驗證任務完成。對照取得預期候選，取消組結果為 `.failure(.unavailable)`。兩組均恰好發出同樣的兩個 stub 請求，兩個取消旗標各自符合預期。

## 結果與證據

arm64 macOS 26.5.2、Apple Swift 6.3.3、Apollo 2.1.2。受審 production 基線 `386af9e`。執行前述建置產物一次，exit 0。

```jsonl
{"callerCancellationRequested":false,"paths":["/user","/search/issues"],"variant":"control","cancellationAtResponse":false,"outcome":"expectedCandidate"}
{"variant":"cancel","paths":["/user","/search/issues"],"outcome":"unavailable","callerCancellationRequested":true,"cancellationAtResponse":true}
```

Swift 來源 SHA-256 `d9c0c23bda412fcb0862b8709ecc23e57842a6fe5a2eee7cd5389585731debac`。測試 binary `9d414f616d652ee9418267b8783e6d356102d3cb49be04a85d066b3f695968e7`。

Stub 裝上 continuation 後才發出等待事件，驅動端先取消 caller 再放行。Stub 在交付相同合成 HTTP 200 前先觀察 Task flag。 [Swift probe](Sources/InboxCancellationProbe/InboxCancellationProbe.swift#L24-L35) · [事件順序](Sources/InboxCancellationProbe/InboxCancellationProbe.swift#L86-L110)

## 結論與限制

支持正式 Adapter／UseCase／Facade 在此受控 REST await 邊界將早於成功回應交付的取消折為 `.unavailable`，並無額外請求。同步 decode 中途取消、產品狀態提交及真實 transport 需各自證明。契約判讀見 [topic 技術報告](../../analysis/cancellation-trace-contract-review/technical-spec.md)。
