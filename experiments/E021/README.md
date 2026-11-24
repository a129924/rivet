# E021 Foundation 請求進行中的取消

## 驗證什麼

- 編號 E021，設計日期 2026-11-24。建立前確認本地目錄、索引與可達歷史未占用。
- 問題為 server 已收到請求且正扣留回應時，透過正式 HTTP client 取消 Swift Task，client 與 loopback peer 各出現什麼訊號。
- 假設為 client 以 `HTTPClientError.cancelled(underlying:)` 結束，server 在放行回應或開始清理前觀察到 peer EOF 或 reset。

## 為什麼

原始碼基線 `386af9e`。Transport 透過 Foundation async URLSession 傳送，既有測試以注入的 URLProtocol 錯誤查驗取消映射。決策缺口是實際本機 HTTP I/O 的終止與分類。若配對成立，已有 Transport 足以在受測條件傳遞取消，可優先檢討上層契約。若出現可重現的其他 client 結果，須先檢查 Transport 與 Foundation 的交界。若只取得 client 取消，仍保留 peer 行為未知。 [URLSessionTransport](../../packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/URLSessionTransport.swift) · [Transport 測試](../../packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/URLSessionTransportTests.swift) · [Apple async URLSession](https://developer.apple.com/videos/play/wwdc2021/10095/?time=473)

## 成功與失敗判準

- 對照必須完整收到請求、放行 HTTP 200 並由 client 回報預期 body 與無取消。取消組須完整收到相同請求才觸發取消，保持無回應。
- 成功需取消組同時觀察到實際 Task 取消、client 的 `HTTPClientError.cancelled` 與清理前的 peer EOF 或 reset。Underlying 型別、domain 與 code 原樣分類記錄。
- 有有效對照及事件順序，取消組若回明確的其他 client 結果，該 client 假設失敗。觀察缺失時無法判定相應邊界。只取得 client 訊號時，peer 邊界無法判定。
- 判準於執行前固定。上限一組對照與取消配對。設定故障修正後最多再執行一組。每案 10 秒 watchdog 專用於停止與清理。

## 環境與前置條件

目標為 macOS 15 或更新版本、Swift 6 與 Python 3。需要本機 loopback bind 與啟動程式權限。每案有獨立 ephemeral Foundation session 與本機 HTTP/1.1 listener。HTTPClient、Requester、URLSessionTransport 與 TCP 為真實執行。HTTP server 與內容是合成 fixture。環境的確切版本由 Tester 記錄。

## 重現步驟

從 repository 根目錄執行。Swift 建置獨立完成。Python driver 依序執行兩個案例並各輸出一筆 JSON。

```sh
swift build --package-path experiments/E021
probe_bin="$(swift build --package-path experiments/E021 --show-bin-path)"
python3 -B experiments/E021/run_pair.py "$probe_bin/TransportCancellationProbe"
```

Driver 收到完整 `GET /probe HTTP/1.1` header 後，才命令 Swift 進入 `release` 或 `cancel`。回應固定為 `ok`。在採集期間 Swift process 維持 session 活躍，採集完成才收到 `finish`。JSON 包含完整請求、回應是否送出、peer、client 類型及 Task 取消旗標。設定錯誤記錄類型，達到限時後收尾。

## 是否成功

2026-11-24 獨立 Tester 執行一組配對，未重跑，實驗狀態為**成功**，本輪驗證任務完成。兩案完整收到請求。對照收到 HTTP 200 與固定 body。取消組由真 Swift Task 取消，回傳 `HTTPClientError.cancelled`，server 在回應及清理前收到 EOF。

## 結果與證據

arm64 macOS 26.5.2、Apple Swift 6.3.3、Python 3.14.0。受審 production 基線 `386af9e`。執行前述建置產物的 Python 指令，exit 0。判定依兩筆 JSON 及事件順序。

```jsonl
{"case":"control","client":{"expectedBody":true,"kind":"response","status":200,"taskCancellationRequested":false},"exitCode":0,"fullRequest":true,"peer":null,"responseSent":true}
{"case":"cancel","client":{"kind":"cancelled","taskCancellationRequested":true,"underlyingCode":-999,"underlyingDomain":"NSURLErrorDomain","underlyingType":"NSURLError"},"exitCode":0,"fullRequest":true,"peer":"eof","responseSent":false}
```

`run_pair.py` SHA-256 `e2ba227335265876bec8d511d0ffa90961895e88d69d0cf2958e3572cfeba35b`。Swift 來源 `bd44f64445cd176aaf2ca3969195ead8fe4b31a3dafaa2bcad35c452d353214b`。測試 binary `33c91c91f2b2caafdda1d60d5a629f6802ae98eae14e8860fa959aaeede371ba`。

Driver 完整讀取 header 後才送出取消或放行指令，在 Swift 收到 `finish` 之前觀察 EOF。Swift 在 `finish` 後才清理 session。 [Driver](run_pair.py#L73-L89) · [Swift probe](Sources/TransportCancellationProbe/TransportCancellationProbe.swift#L17-L46)

## 結論與限制

在此受測環境，正式通用 HTTPClient／URLSessionTransport 可終止進行中的本機 HTTP/1.1 I/O，並保留 `NSURLErrorDomain/-999`。HTTP server 和內容為合成 fixture，證據只支持受測 macOS 與單一 loopback 請求。真 GitHub、HTTP/2、其他連線策略或跨環境的一般行為未驗證。契約判讀見 [topic 技術報告](../../analysis/cancellation-trace-contract-review/technical-spec.md)。
