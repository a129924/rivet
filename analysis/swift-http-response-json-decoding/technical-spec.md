# Swift HTTP Response JSON Decoding：技術規格

## Locked API Contract

`HTTPResponse` 新增下列 public synchronous throwing convenience：

```swift
public func json<T: Decodable>(
  _ type: T.Type,
  decoder: JSONDecoder
) throws -> T
```

此 API 以 `decoder.decode(type, from: body)` 解碼既有 raw `Data`。呼叫端必須傳入 `JSONDecoder`；`RivetHTTPClient` 不提供、儲存、快取或設定預設 decoder。

## Behavior and Error Contract

- API 不讀取或驗證 `statusCode`、`headers` 或 `Content-Type`；只對 `body` 嘗試解碼。
- 有效 body 即使搭配非成功 HTTP status、非 JSON `Content-Type` 或沒有 `Content-Type` 也必須能成功解碼。
- decoder 拋出的錯誤直接向呼叫端傳遞，包含 `DecodingError`；不得新增或使用 package-specific decoding error，也不得以 optional 表示失敗。
- API 不改寫、快取或消耗 `body`，也不改變 `statusCode`、`headers` 或既有 initializer 的行為。

## Architecture and Writeback

- `HTTPResponse` 保持 canonical raw response contract；`json(_:decoder:)` 是 caller-invoked convenience，不加入 `HTTPClient → Requester → Transport` 的 raw response 傳遞資料流。
- `docs/architecture/README.md` 與既有 HTTP client package-structure diagram 必須記錄：package 提供 caller-owned decoder 的 response convenience，但不擁有 decoder configuration、status validation 或 `Content-Type` validation policy。
- 已刪除的 `docs/architecture/bounded-contexts/github-integration.md` 與舊 GitHub Integration authorization boundary canvas 均不是 writeback target；此失效引用由 `github-integration-boundary-redefinition` topic supersede，且不指定 replacement target。
- package-structure diagram 僅修改其 `scene.js`，並依既定 artifact-local workflow rebuild generated `index.html`；不得直接手改生成檔或發布 artifact.cafe。

## Required Verification

- 有效 JSON 能解碼為指定 `Decodable` 型別。
- 具 caller configuration 的 `JSONDecoder` 能解碼需要該 configuration 的 JSON payload。
- 無效或不相容 JSON 由呼叫端收到原始 `DecodingError`。
- 非成功 status、非 JSON `Content-Type` 與缺少 `Content-Type` 都不影響 decode 嘗試。
- 既有 raw response regression tests 維持通過；執行 standalone `RivetHTTPClient` package checks。
- 兩張 diagram 執行各自既定 validate、build、enhance 與 accessibility verification。
