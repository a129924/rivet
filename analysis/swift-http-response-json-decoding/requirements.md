# Swift HTTP Response JSON Decoding：需求

## Goal

在 `RivetHTTPClient` 的既有 raw `HTTPResponse` 上提供 opt-in JSON decode convenience。呼叫端顯式提供 `JSONDecoder` 與目標 `Decodable` 型別，從 response 的 raw `body` 取得已解碼值。

這是獨立 topic，不併入 `swift-http-response-header-conveniences`。`RivetHTTPClient` 仍是 GitHub Integration 可採用的內部 transport foundation，不是新的 Bounded Context；`HTTPClient → Requester → Transport` 仍只傳遞 raw `HTTPResponse`。

## In Scope

- `HTTPResponse` 的泛型 `Decodable` JSON convenience。
- 呼叫端傳入 `JSONDecoder`，由該 decoder 解碼既有 raw `Data` body。
- 保留 decoder 的原始錯誤，包含 `DecodingError`。
- 對 HTTP response、decoder ownership 與既有 HTTP client architecture facts 的最小長期文件回寫；依既有 workflow 更新兩張 HTTP client diagram。
- 針對有效解碼、caller-supplied decoder configuration、原始錯誤、status／`Content-Type` 不參與解碼與 raw response regression 的測試。

## Out of Scope

- `swift-http-response-header-conveniences` 的 artifacts、scope 或 locked contract。
- `HTTPClient`、`Requester`、`Transport` 的介面、責任或資料流。
- 預設、共享、儲存或由 library 設定的 `JSONDecoder`。
- package decoding error、optional decode API、`JSONSerialization` 或動態 JSON API。
- HTTP status 或 `Content-Type` validation、retry、concrete transport、實際網路、token refresh、Endpoint／URL 組裝與統一 package error。

## Success Criteria

- 呼叫端能以顯式傳入的 `JSONDecoder` 將 `HTTPResponse.body` 解碼為指定 `Decodable` 型別。
- decoder configuration 由傳入 instance 決定且確實生效。
- 無效或不相容 JSON 保留原始 `DecodingError`；library 不包裝或轉換它。
- status、JSON 或非 JSON `Content-Type`、以及缺少 `Content-Type` 都不會阻止 decode 嘗試。
- `HTTPResponse` 的既有 raw body、status 與 headers contract，以及 `HTTPClient → Requester → Transport` chain 維持不變。
