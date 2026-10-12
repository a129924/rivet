import Foundation

public enum ProbeOutcome: Equatable, Sendable {
  case success
  case invalidCallback
  case stateMismatch
  case authorizationDenied
  case listenerFailure
  case browserFailure
  case timeout
  case interrupted

  public var exitCode: Int32 {
    switch self {
    case .success: 0
    case .interrupted: 130
    default: 1
    }
  }

  public var message: String {
    switch self {
    case .success: "OAuth 重導向驗證成功：收到非空 code，state 相符。未交換 token。"
    case .invalidCallback: "驗證失敗：callback 缺少有效 code/state 或包含重複參數。"
    case .stateMismatch: "驗證失敗：state 不符。"
    case .authorizationDenied: "驗證失敗：GitHub 返回授權錯誤。"
    case .listenerFailure: "驗證失敗：無法啟動本機 listener。"
    case .browserFailure: "驗證失敗：無法開啟系統瀏覽器。"
    case .timeout: "驗證失敗：等待 callback 逾時。"
    case .interrupted: "驗證已中止。"
    }
  }
}

public enum CallbackDecision: Equatable, Sendable {
  case ignore(status: Int)
  case finish(ProbeOutcome)
}

public enum Callback {
  public static func evaluate(
    method: String,
    target: String,
    expectedState: String
  ) -> CallbackDecision {
    guard target.hasPrefix("/"), !target.hasPrefix("//"),
      let components = URLComponents(string: "http://127.0.0.1" + target),
      components.fragment == nil
    else { return .ignore(status: 400) }
    guard components.path == "/oauth/callback" else { return .ignore(status: 404) }
    guard method == "GET" else { return .ignore(status: 405) }
    let items = components.queryItems ?? []
    guard Set(items.map(\.name)).count == items.count else { return .finish(.invalidCallback) }
    guard let state = items.first(where: { $0.name == "state" })?.value, !state.isEmpty else {
      return .finish(.invalidCallback)
    }
    guard state == expectedState else { return .finish(.stateMismatch) }
    if items.contains(where: { $0.name == "error" }) { return .finish(.authorizationDenied) }
    guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
      return .finish(.invalidCallback)
    }
    return .finish(.success)
  }
}
