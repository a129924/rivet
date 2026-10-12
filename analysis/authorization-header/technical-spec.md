# AuthorizationHeader 技術規格

## 已鎖定公開介面

```swift
public enum AuthorizationHeader {
    public static func bearerValue(
        token: String
    ) throws(AuthorizationHeaderError) -> String

    public static func applyingBearer(
        token: String,
        to headers: [String: String]
    ) throws(AuthorizationHeaderError) -> [String: String]
}

public enum AuthorizationHeaderError: Error, Equatable, Sendable {
    case invalidToken
}
```

AuthorizationHeader 是無 cases 的 namespace，沒有 instances、stored state 或新增抽象。使用既有 Swift 6 package；不修改 manifest 或 dependency。

## Token 契約

完整匹配 [RFC 6750 §2.1](https://www.rfc-editor.org/rfc/rfc6750.html#section-2.1)：

```text
b64token = 1*( ALPHA / DIGIT / "-" / "." / "_" / "~" / "+" / "/" ) *"="
```

至少一個前段允許的 ASCII 字元，後接零個或任意數量的 `=`；`=` 不可在開頭或中間。不檢查 Base64 padding 長度或可解碼性。不 trim、不改寫、不解碼、不檢查 JWT／expiry。空字串、空白、控制字元、非 ASCII 與其他字元均拒絕。

bearerValue 成功回傳精確 `Bearer <token>`，只加入一個 ASCII space；失敗拋出 `.invalidToken`。Error 不帶 associated value、token、token 長度或其他衍生資訊，不以 fallback 產生 header。

## Replacement 契約

applyingBearer 呼叫唯一 bearerValue 驗證／formatting 實作。先建立 value，移除所有 ASCII 大小寫不敏感匹配 `Authorization` 的 key，寫入精確 `Authorization`。

- 保留其他 keys／values 原始內容；不 trim header name、不驗證無關 headers。
- 不透過會 lower-case 所有 keys 的既有 HTTPHeaders 中轉。
- 成功與失敗均不修改 input；相同 token 冪等，更換 token 替換舊值。
- 相同輸入保證 dictionary 內容相同，不保證 enumeration order。
- 純同步操作，沒有 I/O、logging、credential state 或外部 side effect。

## 架構與相容性

仍是 BC 外既有 RivetHTTPClient 的 additive technical API，不建立新 BC、module、dependency 或 failure framework。BearerAuth 的 locked nonthrowing contract 與所有既有 consumers 完全不改。未來整合屬另一 topic；新 API 不宣稱既有規則已遷移。

Archify 僅描述 token 驗證／Bearer value，以及 headers 去除變體／新增欄位／回傳與 invalidToken 分支。作者內容繁體中文；固定 Viewer UI／HTML lang fallback English。圖表、輔助工具與檔案界線遵守 [plan](../../plan/authorization-header/authorization-header.plan.md)。
