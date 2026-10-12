/// 不保存認證狀態的 Bearer header 純轉換。
///
/// 此元件只處理字串與 dictionary，不取得 token、不發送 request。
public enum AuthorizationHeader {
  /// 依 RFC 6750 的 b64token 字元文法產生 Bearer value。
  ///
  /// 不 trim、解碼或檢查 token 的有效期限；允許任意數量的尾端等號。
  /// - Throws: 不符合文法時拋出不含 token 資訊的 AuthorizationHeaderError.invalidToken。
  public static func bearerValue(token: String) throws(AuthorizationHeaderError) -> String {
    guard !token.isEmpty else {
      throw .invalidToken
    }

    var hasBody = false
    var hasPadding = false

    for byte in token.utf8 {
      switch byte {
      case 65...90, 97...122, 48...57, 45, 46, 95, 126, 43, 47:
        guard !hasPadding else {
          throw .invalidToken
        }
        hasBody = true
      case 61:
        guard hasBody else {
          throw .invalidToken
        }
        hasPadding = true
      default:
        throw .invalidToken
      }
    }

    return "Bearer \(token)"
  }

  /// 回傳以單一 Authorization 取代所有 ASCII 大小寫變體後的新 headers。
  ///
  /// 其他 key 拼字與 value 保持原樣；成功或失敗皆不修改輸入。
  /// 回傳值保證 dictionary 內容確定，不保證列舉順序。
  /// - Throws: 與 bearerValue(token:) 相同的 token 驗證錯誤。
  public static func applyingBearer(
    token: String,
    to headers: [String: String]
  ) throws(AuthorizationHeaderError) -> [String: String] {
    let value = try bearerValue(token: token)
    var result = headers.filter { !isAuthorization($0.key) }
    result["Authorization"] = value
    return result
  }

  private static func isAuthorization(_ name: String) -> Bool {
    name.utf8.elementsEqual("authorization".utf8) { byte, expected in
      let folded = (65...90).contains(byte) ? byte + 32 : byte
      return folded == expected
    }
  }
}

/// Bearer token 格式錯誤；不攜帶 token 或其衍生資訊。
public enum AuthorizationHeaderError: Error, Equatable, Sendable {
  case invalidToken
}
